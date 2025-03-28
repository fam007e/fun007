#!/bin/bash
#-------------------------------------------------------------------------------
# 1. Initial Setup
#-------------------------------------------------------------------------------

set -e  # Exit immediately if a command exits with a non-zero status

# Check if config file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <config.json>"
    exit 1
fi

config_file="$1"
log_file="/tmp/arch_install.log"

# Function definitions
get_config_value() {
    local key=$1
    local value
    value=$(grep "\"$key\":" "$config_file" | cut -d'"' -f4)
    echo "$value"
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
    local drive=$1
    [ "$(cat /sys/block/"${drive##*/}"/queue/rotational)" = "0" ]
}

get_partition_name() {
    local disk=$1
    local num=$2
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

# Set mount options based on drive type
if [ "$IS_SSD" = "y" ] || is_ssd "$DISK"; then
    MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120"
    log "Configuring mount options for SSD"
else
    MOUNT_OPTIONS="noatime,compress=zstd,commit=120"
    log "Configuring mount options for HDD"
fi

# Check LUKS password if using LUKS
if [ "$FS" = "luks" ] && [ -z "$LUKS_PASSWORD" ]; then
    error "LUKS password is required for LUKS filesystem"
fi

# Redirect stdout and stderr to log file and still output to console
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

# Initial system checks
background_checks() {
    log "Performing background checks"

    if [ ! -f /usr/bin/pacstrap ]; then
        error "This script must be run from an Arch Linux ISO environment."
    fi

    if [ "$(id -u)" != "0" ]; then
        error "This script must be run under the 'root' user!"
    fi

    if awk -F/ '$2 == "docker"' /proc/self/cgroup | read -r || [ -f /.dockerenv ]; then
        error "Docker container is not supported (at the moment)"
    fi

    if [ ! -e /etc/arch-release ]; then
        error "This script must be run in Arch Linux!"
    fi

    if [ -f /var/lib/pacman/db.lck ]; then
        error "Pacman is blocked. If not running remove /var/lib/pacman/db.lck."
    fi
}

background_checks

#-------------------------------------------------------------------------------
# 2. System Preparation
#-------------------------------------------------------------------------------

# Mirror selection function
get_region_from_timezone() {
    local timezone=$1
    local continent
    local country
    continent=$(echo "$timezone" | cut -d'/' -f1)
    country=$(echo "$timezone" | cut -d'/' -f1)
    
    case "$continent" in
        "Asia")
            case "$country" in
                "Dhaka"|"Kolkata"|"Colombo"|"Karachi")
                    echo "Bangladesh,India,Pakistan,Sri Lanka,Singapore,Japan"
                    ;;
                "Singapore"|"Kuala_Lumpur"|"Bangkok"|"Jakarta")
                    echo "Singapore,Malaysia,Thailand,Indonesia,Japan"
                    ;;
                "Tokyo"|"Seoul"|"Shanghai")
                    echo "Japan,Korea,China,Taiwan,Hong Kong"
                    ;;
                *)
                    echo "Japan,Singapore,India,China,Korea"
                    ;;
            esac
            ;;
        "Europe")
            echo "Germany,Netherlands,France,United Kingdom,Sweden"
            ;;
        "America")
            case "$country" in
                *"New_York"|*"Toronto"|*"Chicago")
                    echo "United States,Canada"
                    ;;
                *"Los_Angeles"|*"Vancouver"|*"Seattle")
                    echo "United States,Canada"
                    ;;
                *)
                    echo "United States,Canada,Brazil"
                    ;;
            esac
            ;;
        "Australia")
            echo "Australia,New Zealand,Singapore,Japan"
            ;;
        "Africa")
            echo "South Africa,Kenya,Morocco,Egypt"
            ;;
        *)
            echo "Germany,United States,Japan,Singapore"
            ;;
    esac
}

# Mirror update function
update_mirrorlist() {
    local timezone=$TIMEZONE
    local mirror_countries
    mirror_countries=$(get_region_from_timezone "$timezone")
    log "Selected mirror countries: $mirror_countries"
    
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

    log "Updating mirrorlist with fastest regional mirrors"
    if reflector --country "${mirror_countries}" \
                 --protocol https \
                 --latest 20 \
                 --sort rate \
                 --download-timeout 5 \
                 --save /etc/pacman.d/mirrorlist; then
        log "Regional mirrors updated successfully"
        return 0
    fi

    log "Trying continental mirrors..."
    local continent
    continent=$(echo "$timezone" | cut -d'/' -f1)
    if reflector --continent "$continent" \
                 --protocol https \
                 --latest 10 \
                 --sort rate \
                 --download-timeout 5 \
                 --save /etc/pacman.d/mirrorlist; then
        log "Continental mirrors updated successfully"
        return 0
    fi

    log "Trying worldwide mirrors..."
    if reflector --protocol https \
                 --latest 5 \
                 --sort rate \
                 --download-timeout 5 \
                 --save /etc/pacman.d/mirrorlist; then
        log "Worldwide mirrors updated successfully"
        return 0
    fi

    log "Mirror update failed, restoring backup"
    cp /etc/pacman.d/mirrorlist.backup /etc/pacman.d/mirrorlist
}

# System preparation
log "Preparing system for installation"
timedatectl set-ntp true
log "System clock synchronized"

# Update system and install basic packages
log "Updating system and installing required packages"
pacman -Sy --noconfirm archlinux-keyring
pacman -S --noconfirm --needed pacman-contrib terminus-font reflector rsync grub
setfont ter-v16b
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# Update mirrors
update_mirrorlist

# Create mount point
mkdir -p /mnt

# Install prerequisites
log "Installing prerequisites"
pacman -S --noconfirm --needed --ignore linux gptfdisk btrfs-progs glibc

# Disk preparation functions
format_secondary_disk() {
    if [ -n "$SECONDARY_DISK" ]; then
        log "Preparing to format secondary disk $SECONDARY_DISK"
        if ! confirm_action "Are you sure you want to format $SECONDARY_DISK? This will erase all data."; then
            error "Secondary disk formatting cancelled by user"
        fi

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
        
        log "Secondary disk formatted successfully"
    fi
}

prepare_main_disk() {
    log "Formatting Disk"
    if mountpoint -q /mnt; then
        umount -R /mnt
    fi

    log "Preparing to format disk $DISK"
    if ! confirm_action "Are you sure you want to format $DISK? This will erase all data."; then
        error "Disk formatting cancelled by user"
    fi

    sgdisk -Z "$DISK"
    sgdisk -a 2048 -o "$DISK"
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' "$DISK"
    sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' "$DISK"
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' "$DISK"

    if [ ! -d "/sys/firmware/efi" ]; then
        sgdisk -A 1:set:2 "$DISK"
    fi

    partprobe "$DISK"
    log "Disk partitioning completed"
}

# Execute disk preparation
prepare_main_disk
format_secondary_disk

#-------------------------------------------------------------------------------
# 3. Installation
#-------------------------------------------------------------------------------

# Setup filesystems
setup_filesystems() {
    partition2=$(get_partition_name "$DISK" 2)
    partition3=$(get_partition_name "$DISK" 3)

    log "Creating filesystems on partitions:"
    log "EFI partition: $partition2"
    log "Root partition: $partition3"

    case "$FS" in
        btrfs)
            mkfs.vfat -F32 -n "EFIBOOT" "$partition2"
            mkfs.btrfs -L ROOT "$partition3" -f
            mount -t btrfs "$partition3" /mnt
            
            # Create subvolumes
            btrfs subvolume create /mnt/@
            btrfs subvolume create /mnt/@home
            btrfs subvolume create /mnt/@var
            btrfs subvolume create /mnt/@tmp
            btrfs subvolume create /mnt/@.snapshots
            
            umount /mnt
            
            # Mount subvolumes
            mount -o "$MOUNT_OPTIONS",subvol=@ "$partition3" /mnt
            mkdir -p /mnt/{home,var,tmp,.snapshots,boot/efi}
            mount -o "$MOUNT_OPTIONS",subvol=@home "$partition3" /mnt/home
            mount -o "$MOUNT_OPTIONS",subvol=@var "$partition3" /mnt/var
            mount -o "$MOUNT_OPTIONS",subvol=@tmp "$partition3" /mnt/tmp
            mount -o "$MOUNT_OPTIONS",subvol=@.snapshots "$partition3" /mnt/.snapshots
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
            
            # Create and mount BTRFS subvolumes
            btrfs subvolume create /mnt/@
            btrfs subvolume create /mnt/@home
            btrfs subvolume create /mnt/@var
            btrfs subvolume create /mnt/@tmp
            btrfs subvolume create /mnt/@.snapshots
            
            umount /mnt
            
            mount -o "$MOUNT_OPTIONS",subvol=@ /dev/mapper/ROOT /mnt
            mkdir -p /mnt/{home,var,tmp,.snapshots,boot/efi}
            mount -o "$MOUNT_OPTIONS",subvol=@home /dev/mapper/ROOT /mnt/home
            mount -o "$MOUNT_OPTIONS",subvol=@var /dev/mapper/ROOT /mnt/var
            mount -o "$MOUNT_OPTIONS",subvol=@tmp /dev/mapper/ROOT /mnt/tmp
            mount -o "$MOUNT_OPTIONS",subvol=@.snapshots /dev/mapper/ROOT /mnt/.snapshots
            ;;
            
        *)
            error "Unsupported filesystem: $FS"
            ;;
    esac

    # Mount EFI partition
    mount -t vfat -L EFIBOOT /mnt/boot/efi
    
    # Verify mounts
    if ! grep -qs '/mnt' /proc/mounts; then
        error "Drive is not mounted, cannot continue"
    fi
}

# Configure secondary disk
configure_secondary_disk() {
    if [ -n "$SECONDARY_DISK" ]; then
        log "Configuring secondary disk mount points"
        local data_partition
        if echo "$SECONDARY_DISK" | grep -q "nvme"; then
            data_partition="${SECONDARY_DISK}p1"
        else
            data_partition="${SECONDARY_DISK}1"
        fi

        if [ "$FS" = "luks" ]; then
            data_partition="/dev/mapper/DATA"
        fi

        # Add secondary disk mount points to fstab
        echo "
# Secondary disk mount points
$data_partition    /mnt/data    btrfs    ${MOUNT_OPTIONS}    0 0
/mnt/data/Downloads    /home/${USERNAME}/Downloads    none    bind    0 0
/mnt/data/Documents    /home/${USERNAME}/Documents    none    bind    0 0
/mnt/data/Music        /home/${USERNAME}/Music        none    bind    0 0
/mnt/data/Pictures     /home/${USERNAME}/Pictures     none    bind    0 0
/mnt/data/Videos       /home/${USERNAME}/Videos       none    bind    0 0
/mnt/data/Public       /home/${USERNAME}/Public       none    bind    0 0
" >> /mnt/etc/fstab

        # Create mount points and set permissions
        mkdir -p /mnt/mnt/data
        mkdir -p /mnt/mnt/data/{Downloads,Documents,Music,Pictures,Videos,Public}
        chown -R "${USERNAME}:${USERNAME}" /mnt/mnt/data
    fi
}

# Execute filesystem setup
setup_filesystems

# Rebuild the package database if necessary
log "Rebuilding the package database (if needed)"
pacman -Q --list | sed 's/ /\n/g' | grep -v ^$ > /tmp/pkglist 
pacman -Syu --noconfirm 
pacman -S --noconfirm --needed $(cat /tmp/pkglist)

# Install base system
log "Beginning system installation"
log "Installing base system packages"
if [ "$KERNEL" = "linux-lts" ]; then
    pacstrap -K /mnt base base-devel \
        linux-lts linux-lts-headers linux-firmware \
        sof-firmware nano efibootmgr \
        networkmanager dhclient \
        git ntp wget \
        fsck btrfs-progs e2fsprogs dosfstools \
        terminus-font
else
    pacstrap -K /mnt base base-devel \
        linux linux-headers linux-firmware \
        sof-firmware nano efibootmgr \
        networkmanager dhclient \
        git ntp wget \
        fsck btrfs-progs e2fsprogs dosfstools \
        terminus-font
fi

# Generate fstab
log "Generating fstab"
genfstab -L /mnt >> /mnt/etc/fstab
log "Current fstab contents:"
cat /mnt/etc/fstab

# Configure secondary disk if present
configure_secondary_disk

#-------------------------------------------------------------------------------
# 4. System Configuration
#-------------------------------------------------------------------------------

log "Configuring base system"
arch-chroot /mnt /bin/bash <<EOCHROOT
# Set up logging inside chroot
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] \$1"
}

# Set timezone and clock
log "Setting up timezone and hardware clock"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Configure locale and console font
log "Configuring locale settings"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "FONT=ter-v16b" >> /etc/vconsole.conf

# Set hostname and hosts file
log "Configuring hostname and hosts"
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

# User setup
log "Creating user account"
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Network setup
log "Configuring network"
systemctl enable NetworkManager

# GRUB installation and configuration
log "Installing and configuring GRUB"
if [ ! -d "/sys/firmware/efi" ]; then
    grub-install --target=i386-pc "$DISK"
else
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
fi

TOTAL_MEM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)   
if [ "$TOTAL_MEM" -lt 8000000 ]; then
    mkdir -p /mnt/opt/swap
    if findmnt -n -o FSTYPE /mnt | grep -q btrfs; then
        chattr +C /mnt/opt/swap
    fi
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile   
    swapon /mnt/opt/swap/swapfile
    printf "%s\n" "/opt/swap/swapfile   none    swap    sw  0   0" >> /mnt/etc/fstab
fi

# Configure GRUB
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash /' /etc/default/grub
if [ "$FS" = "luks" ]; then
    # Add LUKS support to GRUB
    UUID=$(blkid -s UUID -o value "$partition3")
    sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${UUID}:ROOT\"|" /etc/default/grub
fi
grub-mkconfig -o /boot/grub/grub.cfg

# Install and configure additional packages
log "Installing additional system packages"
systemctl enable fstrim.timer

# Install microcode updates
if grep -q "GenuineIntel" /proc/cpuinfo; then
    log "Installing Intel microcode"
    pacman -S --noconfirm intel-ucode
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    log "Installing AMD microcode"
    pacman -S --noconfirm amd-ucode
fi

# Install appropriate graphics drivers
log "Installing graphics drivers"
gpu_type=\$(lspci | grep -E "VGA|3D|Display")

if echo "\$gpu_type" | grep -E "NVIDIA|GeForce"; then
    log "NVIDIA GPU detected"
    if [ "$KERNEL" = "linux-lts" ]; then
        log "Installing NVIDIA LTS drivers"
        pacman -S --noconfirm nvidia-lts nvidia-utils nvidia-settings
    else
        log "Installing standard NVIDIA drivers"
        pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
    fi
elif echo "\$gpu_type" | grep -E "Radeon|AMD"; then
    log "AMD GPU detected"
    pacman -S --noconfirm xf86-video-amdgpu
elif echo "\$gpu_type" | grep -E "Integrated Graphics Controller|Intel Corporation UHD"; then
    log "Intel GPU detected"
    pacman -S --noconfirm libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel
fi

# Install yay AUR helper and AUR firmware packages
install_aur_packages() {
    log "Installing yay AUR helper"
    
    # Install necessary build packages
    pacman -S --noconfirm git base-devel
    
    # Create build directory and set ownership
    mkdir -p /tmp/yay-build
    chown -R $USERNAME:$USERNAME /tmp/yay-build
    cd /tmp/yay-build
    
    # Clone and build yay as the user
    su - $USERNAME -c "
        cd /tmp/yay-build
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
    "
    
    log "Installing AUR firmware packages"
    # Install AUR firmware packages using yay as the user
    su - $USERNAME -c "
        yay -S --noconfirm \
            upd72020x-fw \
            ast-firmware \
            aic94xx-firmware
    "
    
    # Cleanup
    cd /
    rm -rf /tmp/yay-build
}

# Install firmware packages first
log "Installing firmware packages"
pacman -S --noconfirm \
    linux-firmware \
    linux-firmware-whence \
    linux-firmware-qlogic \
    linux-firmware-bnx2x \
    linux-firmware-liquidio \
    linux-firmware-mellanox \
    linux-firmware-nfp

# Install yay and AUR packages
log "Installing AUR helper and firmware packages"
install_aur_packages

# Update mkinitcpio after all firmware installation
mkinitcpio -P

# Configure mkinitcpio for LUKS if needed
if [ "$FS" = "luks" ]; then
    log "Configuring mkinitcpio for LUKS"
    sed -i 's/^HOOKS.*/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
    mkinitcpio -P
fi

EOCHROOT

# Configure user directories if secondary disk is present
if [ -n "$SECONDARY_DISK" ]; then
    log "Setting up user directory configuration"
    mkdir -p "/mnt/home/${USERNAME}/.config"
    cat > "/mnt/home/${USERNAME}/.config/user-dirs.dirs" <<EOF
XDG_DESKTOP_DIR="\$HOME/Desktop"
XDG_DOWNLOAD_DIR="\$HOME/Downloads"
XDG_TEMPLATES_DIR="\$HOME/Templates"
XDG_PUBLICSHARE_DIR="\$HOME/Public"
XDG_DOCUMENTS_DIR="\$HOME/Documents"
XDG_MUSIC_DIR="\$HOME/Music"
XDG_PICTURES_DIR="\$HOME/Pictures"
XDG_VIDEOS_DIR="\$HOME/Videos"
EOF
    chown -R "${USERNAME}:${USERNAME}" "/mnt/home/${USERNAME}/.config"
fi

# Final steps
log "Installation Complete!"
umount -R /mnt
log "System will reboot in 5 seconds..."
sleep 5
reboot
