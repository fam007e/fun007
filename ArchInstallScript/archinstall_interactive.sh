#!/bin/bash -x
#-------------------------------------------------------------------------------
# 1. Initial Setup
#-------------------------------------------------------------------------------

set -e  # Exit on error

# Check if config file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <config.json>"
    exit 1
fi

config_file="$1"
log_file="/tmp/arch_install_$(date +%Y%m%d_%H%M%S).log"

# Function definitions
get_config_value() {
    jq -r ".$1" "$config_file"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$log_file"
}

error() {
    log "ERROR: $1"
    exit 1
}

confirm_action() {
    read -r -p "$1 (y/n): " choice
    case "$choice" in
        y|Y ) return 0;;
        n|N ) return 1;;
        * ) echo "Invalid input"; confirm_action "$1";;
    esac
}

is_ssd() {
    local drive="$1"
    [ -e "/sys/block/${drive##*/}/queue/rotational" ] && [ "$(cat "/sys/block/${drive##*/}/queue/rotational")" = "0" ]
}

get_partition_name() {
    local disk="$1"
    local num="$2"
    if echo "$disk" | grep -q "nvme"; then
        echo "${disk}p${num}"
    else
        echo "${disk}${num}"
    fi
}

# Read configuration
USERNAME=$(get_config_value "username")
PASSWORD=$(get_config_value "password")
HOSTNAME=$(get_config_value "hostname")
TIMEZONE=$(get_config_value "timezone")
KEYMAP=$(get_config_value "keymap")
FS=$(get_config_value "filesystem")
DESKTOP=$(get_config_value "desktop")
USE_SDDM=$(get_config_value "use_sddm")
DISK=$(get_config_value "disk")
SECONDARY_DISK=$(get_config_value "secondary_disk")
IS_SSD=$(get_config_value "is_ssd")
KERNEL=$(get_config_value "kernel")
LUKS_PASSWORD=$(get_config_value "luks_password")

# Verify required values
for var in USERNAME PASSWORD HOSTNAME TIMEZONE KEYMAP FS DISK KERNEL; do
    if [ -z "${!var}" ]; then
        error "Configuration value for ${var,,} is missing or empty"
    fi
done

# Set mount options
MOUNT_OPTIONS="noatime,compress=zstd:1,space_cache=v2"
[ "$IS_SSD" = "y" ] || is_ssd "$DISK" && MOUNT_OPTIONS="$MOUNT_OPTIONS,ssd"

# Check LUKS password
[ "$FS" = "luks" ] && [ -z "$LUKS_PASSWORD" ] && error "LUKS password required"

# Redirect output to log file
exec > >(tee -a "$log_file") 2>&1

# Display banner
log "$(cat <<'EOF'

----------------------------------------------------------------------------------------------------------------------
   _____                .__      .___                 __         .__  .__      _________            .__        __
  /  _  \_______   ____ |  |__   |   | ____   _______/  |______  |  | |  |    /   _____/ ___________|__|______/  |
 /  /_\  \_  __ \_/ ___\|  |  \  |   |/    \ /  ___/\   __\__  \ |  | |  |    \_____  \_/ ___\_  __ \  \____ \   __\
/    |    \  | \/\  \___|   Y  \ |   |   |  \\___ \  |  |  / __ \|  |_|  |__  /        \  \___|  | \/  |  |_> >  |
\____|__  /__|    \___  >___|  / |___|___|  /____  > |__| (____  /____/____/ /_______  /\___  >__|  |__|   __/|__|
        \/            \/     \/           \/     \/            \/                    \/     \/         |__|
----------------------------------------------------------------------------------------------------------------------
                                        Automated Arch Linux Installer
----------------------------------------------------------------------------------------------------------------------

EOF
)"


# Detect GPU type before chroot
log "Detecting GPU type"
declare -g gpu_type
gpu_type=$(lspci | grep -E "VGA|3D|Display" || true)

#-------------------------------------------------------------------------------
# 2. System Preparation
#-------------------------------------------------------------------------------

# Mirror selection
get_region_from_timezone() {
    local timezone="$1"
    local region

    # Check if timezone contains a slash (e.g., Asia/Tokyo)
    if [[ "$timezone" =~ / ]]; then
        region=$(echo "$timezone" | cut -d'/' -f1)
    else
        region="$timezone"
    fi

    case "$region" in
        Africa) echo "South Africa,Kenya,Morocco,Egypt";;
        America) echo "United States,Canada,Brazil,Mexico,Chile,Colombia,Ecuador,Paraguay";;
        Antarctica) echo "Australia,New Zealand";;
        Arctic) echo "Norway,Canada,Finland";;
        Asia) echo "Japan,Singapore,India,China,South Korea,Taiwan,Hong Kong,Indonesia,Thailand,Vietnam,Bangladesh,Nepal";;
        Atlantic) echo "United Kingdom,Portugal,Canada,Iceland";;
        Australia) echo "Australia,New Zealand";;
        Brazil) echo "Brazil";;
        Canada) echo "Canada";;
        Chile) echo "Chile";;
        Etc) echo "Germany,United States,Japan,Singapore";;
        Europe) echo "Germany,Netherlands,France,United Kingdom,Sweden,Poland,Portugal,Turkey,Austria,Belgium,Bulgaria,Czechia,Denmark,Estonia,Finland,Greece,Hungary,Iceland,Italy,Latvia,Lithuania,Luxembourg,Norway,Romania,Russia,Serbia,Slovakia,Slovenia,Spain,Switzerland,Ukraine";;
        Indian) echo "Mauritius,India,Singapore,Réunion";;
        Mexico) echo "Mexico";;
        Pacific) echo "United States,Australia,New Zealand,New Caledonia";;
        posix | right) echo "Germany,United States,Japan,Singapore";;
        US) echo "United States";;
        CET | MET | EET | WET) echo "Germany,Netherlands,France,United Kingdom,Sweden,Poland,Portugal";;
        CST6CDT | EST5EDT | MST7MDT | PST8PDT) echo "United States,Canada,Mexico";;
        Cuba) echo "United States,Canada";;
        Egypt) echo "Egypt,Morocco";;
        Eire | GB | GB-Eire) echo "United Kingdom,Ireland";;
        EST | MST | HST) echo "United States,Canada";;
        Factory | GMT | GMT+0 | GMT-0 | GMT0 | Greenwich | UCT | Universal | UTC | Zulu) echo "Germany,United States,Japan,Singapore";;
        Hongkong) echo "Hong Kong,China,Singapore";;
        Iceland) echo "Iceland,United Kingdom";;
        Iran) echo "Iran";;
        Israel) echo "Israel";;
        Jamaica) echo "United States,Canada";;
        Japan) echo "Japan";;
        Kwajalein) echo "Australia,New Zealand";;
        Libya) echo "Egypt,Morocco";;
        Navajo) echo "United States";;
        NZ | NZ-CHAT) echo "New Zealand,Australia";;
        Poland) echo "Poland";;
        Portugal) echo "Portugal";;
        PRC) echo "China";;
        ROC) echo "Taiwan";;
        ROK) echo "South Korea";;
        Singapore) echo "Singapore,Indonesia";;
        Turkey) echo "Turkey";;
        W-SU) echo "Russia,Belarus,Kazakhstan,Uzbekistan";;
        *) echo "Germany,United States,Japan,Singapore";;
    esac
}

update_mirrorlist() {
    log "Updating mirrorlist"
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    reflector --country "$(get_region_from_timezone "$TIMEZONE")" \
        --protocol https --latest 10 --sort rate --save /etc/pacman.d/mirrorlist || {
        log "Mirror update failed, restoring backup"
        cp /etc/pacman.d/mirrorlist.backup /etc/pacman.d/mirrorlist
    }
}

# System preparation
log "Preparing system"
timedatectl set-ntp true
pacman -Sy --noconfirm archlinux-keyring reflector
pacman -S --noconfirm --needed pacman-contrib terminus-font rsync grub gptfdisk btrfs-progs
setfont ter-v16b
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
update_mirrorlist

# Disk preparation
prepare_main_disk() {
    log "Preparing main disk: $DISK"
    log "Formatting $DISK - all data will be erased"

    umount -R /mnt 2>/dev/null || true
    sgdisk -Z "$DISK"
    sgdisk -a 2048 -o "$DISK"
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' "$DISK"
    sgdisk -n 2::+512M --typecode=2:ef00 --change-name=2:'EFIBOOT' "$DISK"
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' "$DISK"
    [ ! -d "/sys/firmware/efi" ] && sgdisk -A 1:set:2 "$DISK"
    partprobe "$DISK"
}

format_secondary_disk() {
    [ -z "$SECONDARY_DISK" ] && return
    log "Preparing secondary disk: $SECONDARY_DISK"
    log "Formatting $SECONDARY_DISK - all data will be erased"

    sgdisk -Z "$SECONDARY_DISK"
    sgdisk -a 2048 -o "$SECONDARY_DISK"
    sgdisk -n 1::-0 --typecode=1:8300 --change-name=1:'DATA' "$SECONDARY_DISK"
    partprobe "$SECONDARY_DISK"

    local data_partition
    data_partition=$(get_partition_name "$SECONDARY_DISK" 1)
    if [ "$FS" = "luks" ]; then
        echo -n "$LUKS_PASSWORD" | cryptsetup -y -v luksFormat "$data_partition" -
        echo -n "$LUKS_PASSWORD" | cryptsetup open "$data_partition" DATA -
        mkfs.btrfs -L DATA /dev/mapper/DATA
    else
        mkfs.btrfs -L DATA "$data_partition" -f
    fi
}


# Execute disk preparation
mkdir -p /mnt
prepare_main_disk
format_secondary_disk

#-------------------------------------------------------------------------------
# 3. Filesystem Setup
#-------------------------------------------------------------------------------

setup_filesystems() {
    local partition2
    local partition3
    partition2=$(get_partition_name "$DISK" 2)
    partition3=$(get_partition_name "$DISK" 3)

    log "Creating filesystems"
    case "$FS" in
        btrfs)
            mkfs.vfat -F32 -n "EFIBOOT" "$partition2"
            mkfs.btrfs -L ROOT "$partition3" -f
            mount -t btrfs "$partition3" /mnt

            btrfs subvolume create /mnt/@
            btrfs subvolume create /mnt/@home
            btrfs subvolume create /mnt/@var
            btrfs subvolume create /mnt/@tmp
            btrfs subvolume create /mnt/@.snapshots
            umount /mnt

            mount -o "$MOUNT_OPTIONS,subvol=@" "$partition3" /mnt
            mkdir -p /mnt/{home,var,tmp,.snapshots,boot/efi}
            mount -o "$MOUNT_OPTIONS,subvol=@home" "$partition3" /mnt/home
            mount -o "$MOUNT_OPTIONS,subvol=@var" "$partition3" /mnt/var
            mount -o "$MOUNT_OPTIONS,subvol=@tmp" "$partition3" /mnt/tmp
            mount -o "$MOUNT_OPTIONS,subvol=@.snapshots" "$partition3" /mnt/.snapshots
            ;;
        ext4)
            mkfs.vfat -F32 -n "EFIBOOT" "$partition2"
            mkfs.ext4 -L ROOT "$partition3"
            mount -t ext4 "$partition3" /mnt
            mkdir -p /mnt/boot/efi
            ;;
        luks)
            mkfs.vfat -F32 -n "EFIBOOT" "$partition2"
            echo -n "$LUKS_PASSWORD" | cryptsetup -y -v luksFormat "$partition3" -
            echo -n "$LUKS_PASSWORD" | cryptsetup open "$partition3" ROOT -
            mkfs.btrfs -L ROOT /dev/mapper/ROOT
            mount -t btrfs /dev/mapper/ROOT /mnt

            btrfs subvolume create /mnt/@
            btrfs subvolume create /mnt/@home
            btrfs subvolume create /mnt/@var
            btrfs subvolume create /mnt/@tmp
            btrfs subvolume create /mnt/@.snapshots
            umount /mnt

            mount -o "$MOUNT_OPTIONS,subvol=@" /dev/mapper/ROOT /mnt
            mkdir -p /mnt/{home,var,tmp,.snapshots,boot/efi}
            mount -o "$MOUNT_OPTIONS,subvol=@home" /dev/mapper/ROOT /mnt/home
            mount -o "$MOUNT_OPTIONS,subvol=@var" /dev/mapper/ROOT /mnt/var
            mount -o "$MOUNT_OPTIONS,subvol=@tmp" /dev/mapper/ROOT /mnt/tmp
            mount -o "$MOUNT_OPTIONS,subvol=@.snapshots" /dev/mapper/ROOT /mnt/.snapshots
            ;;
        *)
            error "Unsupported filesystem: $FS"
            ;;
    esac

    mount -t vfat -L EFIBOOT /mnt/boot/efi
    grep -qs '/mnt' /proc/mounts || error "Drive not mounted"
}

configure_secondary_disk() {
    [ -z "$SECONDARY_DISK" ] && return
    log "Configuring secondary disk"

    local data_partition
    data_partition=$(get_partition_name "$SECONDARY_DISK" 1)
    [ "$FS" = "luks" ] && data_partition="/dev/mapper/DATA"

    mkdir -p /mnt/mnt/data
    mount -o "$MOUNT_OPTIONS" "$data_partition" /mnt/mnt/data

    local dirs=(Downloads Documents Music Pictures Videos Public)
    for dir in "${dirs[@]}"; do
        mkdir -p "/mnt/mnt/data/$dir"
    done
}

setup_filesystems
configure_secondary_disk

#-------------------------------------------------------------------------------
# 4. System Installation
#-------------------------------------------------------------------------------

log "Installing base system"
BASE_PACKAGES=(
    base base-devel linux-firmware sof-firmware
    nano efibootmgr networkmanager dhclient git ntp wget
    btrfs-progs e2fsprogs dosfstools terminus-font grub
)
[ "$KERNEL" = "linux-lts" ] && BASE_PACKAGES+=(linux-lts linux-lts-headers) || BASE_PACKAGES+=(linux linux-headers)

pacstrap -K /mnt "${BASE_PACKAGES[@]}"
genfstab -U /mnt >> /mnt/etc/fstab

#-------------------------------------------------------------------------------
# 5. System Configuration
#-------------------------------------------------------------------------------

# Create a temporary script to run inside chroot
cat > /mnt/chroot_setup.sh << 'EOCHROOT'
#!/bin/bash
set -e

# Get variables from environment
USERNAME="$1"
PASSWORD="$2"
HOSTNAME="$3"
TIMEZONE="$4"
KEYMAP="$5"
FS="$6"
DESKTOP="$7"
USE_SDDM="$8"
DISK="$9"
SECONDARY_DISK="${10}"
KERNEL="${11}"
LUKS_PASSWORD="${12}"
gpu_type="${13}"
log_file="${14}"

# Function to get partition name
get_partition_name() {
    local disk="$1"
    local num="$2"
    if echo "$disk" | grep -q "nvme"; then
        echo "${disk}p${num}"
    else
        echo "${disk}${num}"
    fi
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$log_file"
}

# Timezone and clock
log "Configuring timezone"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Locale
log "Configuring locale"
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "FONT=ter-v16b" >> /etc/vconsole.conf

# Hostname
log "Configuring hostname"
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

# User setup
log "Creating user"
groupadd -r autologin 2>/dev/null || true
if ! id "$USERNAME" &>/dev/null; then
    useradd -m -G wheel,autologin -s /bin/bash "$USERNAME"
    echo "$USERNAME:$PASSWORD" | chpasswd
else
    log "User $USERNAME already exists, skipping creation"
    usermod -a -G wheel,autologin "$USERNAME"
    echo "$USERNAME:$PASSWORD" | chpasswd
fi

# Temporarily allow passwordless sudo for installation
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Network
log "Enabling NetworkManager"
systemctl enable NetworkManager

# Swap file
log "Configuring swap"
TOTAL_MEM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
if [ "$TOTAL_MEM" -lt 8000000 ]; then
    mkdir -p /opt/swap
    [ "$(findmnt -n -o FSTYPE /)" = "btrfs" ] && chattr +C /opt/swap
    dd if=/dev/zero of=/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /opt/swap/swapfile
    mkswap /opt/swap/swapfile
    swapon /opt/swap/swapfile
    echo "/opt/swap/swapfile none swap sw 0 0" >> /etc/fstab
fi

# GRUB
log "Installing GRUB"
if [ -d "/sys/firmware/efi" ]; then
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
else
    grub-install --target=i386-pc "$DISK"
fi
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash/' /etc/default/grub
if [ "$FS" = "luks" ]; then
    partition3=$(get_partition_name "$DISK" 3)
    sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$(blkid -s UUID -o value "$partition3"):ROOT\"|" /etc/default/grub
fi
grub-mkconfig -o /boot/grub/grub.cfg

# Microcode
log "Installing microcode"
if grep -q "GenuineIntel" /proc/cpuinfo; then
    pacman -S --noconfirm intel-ucode
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    pacman -S --noconfirm amd-ucode
fi

# Graphics drivers
log "Installing graphics drivers"
if [ -n "$gpu_type" ]; then
    if echo "$gpu_type" | grep -qE "NVIDIA|GeForce"; then
        if [ "$KERNEL" = "linux-lts" ]; then
            pacman -S --noconfirm nvidia-lts nvidia-utils nvidia-settings
        else
            pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
        fi
    elif echo "$gpu_type" | grep -qE "Radeon|AMD"; then
        pacman -S --noconfirm xf86-video-amdgpu
    elif echo "$gpu_type" | grep -qE "Intel"; then
        pacman -S --noconfirm libva-intel-driver vulkan-intel
    fi
else
    log "No GPU detected, skipping graphics driver installation"
fi

# Install yay
log "Installing yay"
pacman -S --noconfirm git base-devel
sudo -u "$USERNAME" bash -c "
    cd /tmp
    git clone https://aur.archlinux.org/yay.git || { echo 'Failed to clone yay repository'; exit 1; }
    cd yay
    makepkg -si --noconfirm
    cd /
    rm -rf /tmp/yay
"

# Install firmware packages
log "Installing firmware packages via AUR"
sudo -u "$USERNAME" yay -S --noconfirm --needed \
    aic94xx-firmware \
    ast-firmware \
    wd719x-firmware \
    upd72020x-fw \
    linux-firmware-qlogic || {
    log "Some firmware packages failed to install, continuing..."
}

# Rebuild initramfs after firmware installation
log "Rebuilding initramfs with new firmware"
mkinitcpio -P

# Desktop environment
case "$DESKTOP" in
    dwm)
        log "Installing DWM dependencies"
        pacman -S --noconfirm xorg xorg-xinit xorg-xset xorg-xrandr libx11 libxinerama libxft libxpm libxrandr fontconfig \
            noto-fonts-emoji flameshot dunst alacritty rofi alsa-utils pulseaudio playerctl vlc slock thunar feh dbus polkit mate-polkit \
            nodejs alsa-lib curl gcc-libs glibc libxcb libxkbcommon libxkbcommon-x11 netcat openssl sqlite vulkan-icd-loader vulkan-tools wayland zlib zstd \
            cargo cargo-about clang cmake protobuf vulkan-headers vulkan-validation-layers bc jq imlib2 \
            libxext xcb-util xcb-util-image xcb-util-renderutil pixman libev libevdev libconfig libepoxy pcre2 meson ninja uthash

        log "Installing AUR packages"
        sudo -u "$USERNAME" yay -S --noconfirm ttf-meslo-nerd brave-nightly-bin tor-browser looking-glass || true

        log "Installing DWM, picom, slstatus, and dwmblocks"
        sudo -u "$USERNAME" bash -c "
            mkdir -p /home/$USERNAME/DWM
            cd /home/$USERNAME
            git clone https://github.com/fam007e/DWM DWM || { echo 'Failed to clone DWM repository'; exit 1; }
            cd DWM
            make clean && make && sudo make install || { echo 'Failed to build or install DWM'; exit 1; }

            yay -S --noconfirm slock picom-ftlabs-git
        "

        # Setup DWM scripts and directories
        log "Setting up DWM scripts and directories"
        sudo -u "$USERNAME" bash -c "
            mkdir -p /home/$USERNAME/DWM/scripts /home/$USERNAME/Pictures/Screenshots /home/$USERNAME/Pictures/Wallpapers /home/$USERNAME/.local/bin
            if [ -d /home/$USERNAME/DWM/scripts ]; then
                chmod +x /home/$USERNAME/DWM/scripts/* 2>/dev/null || true
            fi
        "

        # Create .xinitrc
        echo "exec dwm" > "/home/$USERNAME/.xinitrc"
        chown "$USERNAME:$USERNAME" "/home/$USERNAME/.xinitrc"

        # Create DWM desktop entry for SDDM
        if [ "$USE_SDDM" = "y" ]; then
            cat > /usr/share/xsessions/dwm.desktop <<EOF
[Desktop Entry]
Name=DWM
Comment=Dynamic Window Manager
Exec=/usr/local/bin/dwm
Type=Application
EOF
        fi
        ;;
    hyprland)
        log "Installing Hyprland"
        pacman -S --noconfirm hyprland xdg-desktop-portal-hyprland wayland-protocols
        sudo -u "$USERNAME" yay -S --noconfirm hyprpaper hyprlock || true
        ;;
esac

# SDDM
if [ "$USE_SDDM" = "y" ]; then
    log "Installing and configuring SDDM"
    pacman -S --noconfirm sddm
    systemctl enable sddm
    mkdir -p /etc/sddm.conf.d
    echo "[Autologin]" > /etc/sddm.conf.d/autologin.conf
    echo "User=$USERNAME" >> /etc/sddm.conf.d/autologin.conf
    echo "Session=${DESKTOP}.desktop" >> /etc/sddm.conf.d/autologin.conf
fi

# Timeshift for BTRFS
if [ "$FS" = "btrfs" ] || [ "$FS" = "luks" ]; then
    log "Installing and configuring Timeshift"
    sudo -u "$USERNAME" yay -S --noconfirm timeshift || true
    mkdir -p /etc/timeshift
    partition3=$(get_partition_name "$DISK" 3)
    cat > /etc/timeshift/timeshift.json <<EOF
{
    "backup_device_uuid": "$(blkid -s UUID -o value "$partition3")",
    "parent_device_uuid": "",
    "do_first_run": "true",
    "btrfs_mode": "true",
    "include_btrfs_home_for_backup": "false",
    "include_btrfs_home_for_restore": "false",
    "schedule_monthly": "false",
    "schedule_weekly": "true",
    "schedule_daily": "true",
    "schedule_hourly": "false",
    "schedule_boot": "true",
    "count_monthly": "2",
    "count_weekly": "3",
    "count_daily": "5",
    "count_hourly": "6",
    "count_boot": "5",
    "snapshot_size": "0",
    "exclude": [],
    "exclude-apps": []
}
EOF
    systemctl enable cronie
fi

# LUKS mkinitcpio
if [ "$FS" = "luks" ]; then
    log "Configuring mkinitcpio for LUKS"
    sed -i 's/^HOOKS.*/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
    mkinitcpio -P
fi

# System services
log "Enabling system services"
systemctl enable fstrim.timer

# Restore sudo password requirement
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Fix for the secondary disk configuration in the script
# Replace the problematic section in the chroot_setup.sh with this:

# User directories (FIXED VERSION)
if [ -n "$SECONDARY_DISK" ]; then
    log "Configuring user directories"
    mkdir -p "/home/$USERNAME/.config"
    cat > "/home/$USERNAME/.config/user-dirs.dirs" <<EOF
XDG_DESKTOP_DIR="\$HOME/Desktop"
XDG_DOWNLOAD_DIR="\$HOME/Downloads"
XDG_TEMPLATES_DIR="\$HOME/Templates"
XDG_PUBLICSHARE_DIR="\$HOME/Public"
XDG_DOCUMENTS_DIR="\$HOME/Documents"
XDG_MUSIC_DIR="\$HOME/Music"
XDG_PICTURES_DIR="\$HOME/Pictures"
XDG_VIDEOS_DIR="\$HOME/Videos"
EOF
    chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.config"

    # Add secondary disk mount to fstab (FIXED)
    data_partition=$(get_partition_name "$SECONDARY_DISK" 1)
    [ "$FS" = "luks" ] && data_partition="/dev/mapper/DATA"

    # Mount the data partition to /mnt/data (consistent path)
    echo "$data_partition /mnt/data btrfs $MOUNT_OPTIONS 0 0" >> /etc/fstab
    
    # Create bind mounts for user directories with proper dependencies
    dirs=(Downloads Documents Music Pictures Videos Public)
    for dir in "${dirs[@]}"; do
        # Add bind mounts with x-systemd.requires to ensure proper ordering
        echo "/mnt/data/$dir /home/$USERNAME/$dir none bind,x-systemd.requires=mnt-data.mount 0 0" >> /etc/fstab
    done

    # Ensure directories exist and have correct ownership
    mkdir -p /mnt/data
    for dir in "${dirs[@]}"; do
        mkdir -p "/mnt/data/$dir"
        mkdir -p "/home/$USERNAME/$dir"
    done
    chown -R "$USERNAME:$USERNAME" "/mnt/data" "/home/$USERNAME"
fi

EOCHROOT

# Make the script executable
chmod +x /mnt/chroot_setup.sh

# Run the chroot setup script
arch-chroot /mnt /chroot_setup.sh "$USERNAME" "$PASSWORD" "$HOSTNAME" "$TIMEZONE" "$KEYMAP" "$FS" "$DESKTOP" "$USE_SDDM" "$DISK" "$SECONDARY_DISK" "$KERNEL" "$LUKS_PASSWORD" "$gpu_type" "$log_file"

# Clean up the temporary script
rm /mnt/chroot_setup.sh

# Final steps
log "Installation complete"
umount -R /mnt
log "Rebooting in 5 seconds..."
sleep 5
reboot