#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Check if config file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <config.json>"
    exit 1
fi

config_file="$1"
log_file="/tmp/arch_install.log"

# Function to read JSON values
get_json_value() {
    key=$1
    jq -r ".$key" "$config_file"
}

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$log_file"
}

# Error handling function
error() {
    log "ERROR: $1"
    exit 1
}

# Confirmation function
confirm_action() {
    read -p "$1 (y/n): " choice
    case "$choice" in
        y|Y ) return 0;;
        n|N ) return 1;;
        * ) echo "Invalid input"; confirm_action "$1";;
    esac
}

# Check if running in a virtualized environment
is_virtual() {
    systemd-detect-virt --quiet
}

# Read configuration
USERNAME=$(get_json_value "username")
HOSTNAME=$(get_json_value "hostname")
TIMEZONE=$(get_json_value "timezone")
KEYMAP=$(get_json_value "keymap")
FS=$(get_json_value "filesystem")
DISK=$(get_json_value "disk")
SECONDARY_DISK=$(get_json_value "secondary_disk")
IS_SSD=$(get_json_value "is_ssd")
KERNEL=$(get_json_value "kernel")

if [ "$IS_SSD" = "y" ]; then
    MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120"
else
    MOUNT_OPTIONS="noatime,compress=zstd,commit=120"
fi

# Get sensitive information from environment variables
PASSWORD=${PASSWORD:-}
LUKS_PASSWORD=${LUKS_PASSWORD:-}

if [ -z "$PASSWORD" ]; then
    error "PASSWORD environment variable is not set"
fi

if [ "$FS" = "luks" ] && [ -z "$LUKS_PASSWORD" ]; then
    error "LUKS_PASSWORD environment variable is not set"
fi

# Redirect stdout and stderr to log file and still output to console
exec > >(tee -a "$log_file") 2>&1

log "
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

Verifying Arch Linux ISO is Booted
"

if [ ! -f /usr/bin/pacstrap ]; then
    error "This script must be run from an Arch Linux ISO environment."
fi

# System checks
background_checks() {
    log "Performing background checks"

    # Root check
    if [ "$(id -u)" != "0" ]; then
        error "This script must be run under the 'root' user!"
    fi

    # Docker check
    if awk -F/ '$2 == "docker"' /proc/self/cgroup | read -r; then
        error "Docker container is not supported (at the moment)"
    elif [ -f /.dockerenv ]; then
        error "Docker container is not supported (at the moment)"
    fi

    # Arch check
    if [ ! -e /etc/arch-release ]; then
        error "This script must be run in Arch Linux!"
    fi

    # Pacman check
    if [ -f /var/lib/pacman/db.lck ]; then
        error "Pacman is blocked. If not running remove /var/lib/pacman/db.lck."
    fi
}

background_checks

log "Setting up mirrors for optimal download"
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -Sy --noconfirm archlinux-keyring
pacman -S --noconfirm --needed pacman-contrib terminus-font
setfont ter-v18b
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm --needed reflector rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
log "Setting up $iso mirrors for faster downloads"
reflector -a 48 -c "$iso" -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir -p /mnt

log "Installing Prerequisites"
pacman -S --noconfirm --needed gptfdisk btrfs-progs glibc

log "Formatting Disk"
umount -A --recursive /mnt # make sure everything is unmounted before we start

# Disk prep
log "Preparing to format disk $DISK"
if ! confirm_action "Are you sure you want to format $DISK? This will erase all data."; then
    error "Disk formatting cancelled by user"
fi

sgdisk -Z "$DISK" # zap all on disk
sgdisk -a 2048 -o "$DISK" # new gpt disk 2048 alignment

# create partitions
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' "$DISK" # partition 1 (BIOS Boot Partition)
sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' "$DISK" # partition 2 (UEFI Boot Partition)
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' "$DISK" # partition 3 (Root), default start, remaining
if [ ! -d "/sys/firmware/efi" ]; then # Checking for BIOS system
    sgdisk -A 1:set:2 "$DISK"
fi
partprobe "$DISK" # reread partition table to ensure it is correct

log "Creating Filesystems"

# Define variables for partitions
get_partition_name() {
    local disk=$1
    local num=$2
    if echo "$disk" | grep -q "nvme"; then
        echo "${disk}p${num}"
    else
        echo "${disk}${num}"
    fi
}

# Detect SSD
is_ssd() {
    local drive=$1
    [ "$(cat /sys/block/${drive##*/}/queue/rotational)" = "0" ]
}

# Verify the specified disk is an SSD
if ! is_ssd "$DISK"; then
    error "The specified disk $DISK is not an SSD. Please check your configuration."
fi

partition2=$(get_partition_name "$DISK" 2)
partition3=$(get_partition_name "$DISK" 3)

log "Using $DISK as the installation drive (SSD)"
log "EFI partition: $partition2"
log "Root partition: $partition3"

# Function to create BTRFS subvolumes
createsubvolumes() {
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@tmp
    btrfs subvolume create /mnt/@.snapshots
}

# Function to mount all subvolumes
mountallsubvol() {
    mount -o "$MOUNT_OPTIONS",subvol=@home "$partition3" /mnt/home
    mount -o "$MOUNT_OPTIONS",subvol=@tmp "$partition3" /mnt/tmp
    mount -o "$MOUNT_OPTIONS",subvol=@var "$partition3" /mnt/var
    mount -o "$MOUNT_OPTIONS",subvol=@.snapshots "$partition3" /mnt/.snapshots

    # Mount secondary disk if present
    if [ -n "$SECONDARY_DISK" ]; then
        mkdir -p /mnt/mnt/data
        if [ "$FS" = "luks" ]; then
            mount -o "$MOUNT_OPTIONS" /dev/mapper/DATA /mnt/mnt/data
        else
            mount -o "$MOUNT_OPTIONS" "$SECONDARY_DISK" /mnt/mnt/data
        fi
        mkdir -p /mnt/mnt/data/{Downloads,Documents,Music,Pictures,Videos,Public}
    fi
}

# Function to setup BTRFS subvolumes
subvolumesetup() {
    createsubvolumes
    umount /mnt
    mount -o "$MOUNT_OPTIONS",subvol=@ "$partition3" /mnt
    mkdir -p /mnt/{home,var,tmp,.snapshots}
    mountallsubvol
}

# Create filesystems
case "$FS" in
    btrfs)
        mkfs.vfat -F32 -n "EFIBOOT" "$partition2"
        mkfs.btrfs -L ROOT "$partition3" -f
        mount -t btrfs "$partition3" /mnt
        subvolumesetup
        ;;
    ext4)
        mkfs.vfat -F32 -n "EFIBOOT" "$partition2"
        mkfs.ext4 -L ROOT "$partition3"
        mount -t ext4 "$partition3" /mnt
        ;;
    luks)
        mkfs.vfat -F32 -n "EFIBOOT" "$partition2"
        echo -n "$LUKS_PASSWORD" | cryptsetup -y -v luksFormat "$partition3" -
        echo -n "$LUKS_PASSWORD" | cryptsetup open "$partition3" ROOT -
        mkfs.btrfs -L ROOT /dev/mapper/ROOT
        mount -t btrfs /dev/mapper/ROOT /mnt
        subvolumesetup
        ;;
    *)
        error "Unsupported filesystem: $FS"
        ;;
esac

# Mount the boot partition
mkdir -p /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

if ! grep -qs '/mnt' /proc/mounts; then
    error "Drive is not mounted, cannot continue"
fi

log "Arch Install on Main Drive"
pacstrap /mnt base base-devel "$KERNEL" linux-firmware sof-firmware nano efibootmgr networkmanager dhclient git ntp wget

log "Generating /etc/fstab"
genfstab -L /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

log "Setting up GRUB"
if [ ! -d "/sys/firmware/efi" ]; then
    arch-chroot /mnt grub-install --target=i386-pc "$DISK"
else
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
fi

log "Checking for low memory systems"
TOTAL_MEM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
if [ "$TOTAL_MEM" -lt 8000000 ]; then
    log "Low memory detected. Creating swap file."
    mkdir -p /mnt/opt/swap
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab
fi

log "Configuring the system"
arch-chroot /mnt /bin/bash <<EOF
log "Setting up timezone and locale"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

log "Setting up hostname"
echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

log "Setting up user"
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

log "Setting up network"
systemctl enable NetworkManager

log "Configuring GRUB"
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash /' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

log "Installing and configuring additional packages"
pacman -S --noconfirm reflector
systemctl enable reflector.timer
systemctl enable fstrim.timer

# Determine and install microcode
if grep -q "GenuineIntel" /proc/cpuinfo; then
    pacman -S --noconfirm intel-ucode
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    pacman -S --noconfirm amd-ucode
fi

# Install graphics drivers
gpu_type=\$(lspci | grep -E "VGA|3D|Display")
if echo "\${gpu_type}" | grep -E "NVIDIA|GeForce"; then
    pacman -S --noconfirm nvidia nvidia-utils
elif echo "\${gpu_type}" | grep -E "Radeon|AMD"; then
    pacman -S --noconfirm xf86-video-amdgpu
elif echo "\${gpu_type}" | grep -E "Integrated Graphics Controller|Intel Corporation UHD"; then
    pacman -S --noconfirm libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel
fi

EOF

if [ "$FS" = "luks" ]; then
    log "Configuring mkinitcpio for LUKS"
    sed -i 's/^HOOKS.*/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt filesystems fsck)/' /mnt/etc/mkinitcpio.conf
    arch-chroot /mnt mkinitcpio -p linux
fi

if [ -n "$SECONDARY_DISK" ]; then
    log "Configuring secondary disk"
    echo "
# Mount points for secondary disk
$SECONDARY_DISK    /mnt/data    auto    ${MOUNT_OPTIONS}    0 0
/mnt/data/Downloads    /home/${USERNAME}/Downloads    none    bind    0 0
/mnt/data/Documents    /home/${USERNAME}/Documents    none    bind    0 0
/mnt/data/Music        /home/${USERNAME}/Music        none    bind    0 0
/mnt/data/Pictures     /home/${USERNAME}/Pictures     none    bind    0 0
/mnt/data/Videos       /home/${USERNAME}/Videos       none    bind    0 0
/mnt/data/Public       /home/${USERNAME}/Public       none    bind    0 0
" >> /mnt/etc/fstab

    mkdir -p "/mnt/home/${USERNAME}/.config"
    echo "
XDG_DESKTOP_DIR=\"\$HOME/Desktop\"
XDG_DOWNLOAD_DIR=\"\$HOME/Downloads\"
XDG_TEMPLATES_DIR=\"\$HOME/Templates\"
XDG_PUBLICSHARE_DIR=\"\$HOME/Public\"
XDG_DOCUMENTS_DIR=\"\$HOME/Documents\"
XDG_MUSIC_DIR=\"\$HOME/Music\"
XDG_PICTURES_DIR=\"\$HOME/Pictures\"
XDG_VIDEOS_DIR=\"\$HOME/Videos\"
" > "/mnt/home/${USERNAME}/.config/user-dirs.dirs"
fi

log "Installation Complete!"
umount -R /mnt
log "System will reboot in 5 seconds..."
sleep 5
reboot