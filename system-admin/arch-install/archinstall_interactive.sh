#!/bin/bash
# ==============================================================================
# fun007 Arch Linux Modular Installer
# Purpose: Automated Arch installation with LUKS/BTRFS and fun007 integration.
# Logic: 
#   1. Pre-flight checks & Hardware detection
#   2. Disk partitioning & Encryption (LUKS/BTRFS)
#   3. Base system bootstrap (pacstrap)
#   4. Chroot phase (Configuration & fun007 Bootstrap)
# ==============================================================================

set -e

# --- Initial Setup & Logging ---
if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 <config.json>"
    exit 1
fi

CONFIG_FILE="$1"
LOG_FILE="/tmp/arch_install_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() { echo -e "\033[1;34m[$(date '+%H:%M:%S')]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; exit 1; }

# --- Configuration Retrieval ---
get_config() { jq -r ".$1" "$CONFIG_FILE"; }

USERNAME=$(get_config "username")
PASSWORD=$(get_config "password")
HOSTNAME=$(get_config "hostname")
TIMEZONE=$(get_config "timezone")
FS=$(get_config "filesystem")
DISK=$(get_config "disk")
LUKS_PASSWORD=$(get_config "luks_password")
KERNEL=$(get_config "kernel")
DESKTOP=$(get_config "desktop")

[[ -z "$USERNAME" || "$USERNAME" == "null" ]] && error "Invalid config: 'username' is required."

# --- Phase 1: Hardware & Mirror Setup ---
log "Phase 1: Hardware detection and mirror optimization..."

# GPU Detection
GPU_TYPE=$(lspci | grep -E "VGA|3D|Display" || true)
log "Detected GPU: $GPU_TYPE"

# Mirror Optimization (Reflector)
pacman -Sy --noconfirm archlinux-keyring reflector jq
reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# --- Phase 2: Disk Partitioning & Formatting ---
log "Phase 2: Preparing storage on $DISK..."

# Clear partition table
sgdisk -Z "$DISK"
sgdisk -a 2048 -o "$DISK"

# 1. EFI System Partition (512MB)
sgdisk -n 1::+512M --typecode=1:ef00 --change-name=1:'EFIBOOT' "$DISK"
# 2. Root Partition (Remainder)
sgdisk -n 2::-0 --typecode=2:8300 --change-name=2:'ROOT' "$DISK"

PART_EFI=$(echo "$DISK" | grep -q "nvme" && echo "${DISK}p1" || echo "${DISK}1")
PART_ROOT=$(echo "$DISK" | grep -q "nvme" && echo "${DISK}p2" || echo "${DISK}2")

# Filesystem Setup (LUKS/BTRFS focus)
if [[ "$FS" == "luks" ]]; then
    log "Setting up LUKS Encryption on $PART_ROOT..."
    echo -n "$LUKS_PASSWORD" | cryptsetup luksFormat "$PART_ROOT" -
    echo -n "$LUKS_PASSWORD" | cryptsetup open "$PART_ROOT" cryptroot -
    TARGET_ROOT="/dev/mapper/cryptroot"
else
    TARGET_ROOT="$PART_ROOT"
fi

log "Creating BTRFS subvolumes for Timeshift compatibility..."
mkfs.vfat -F32 -n "EFIBOOT" "$PART_EFI"
mkfs.btrfs -L "ROOT" "$TARGET_ROOT" -f

mount "$TARGET_ROOT" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@.snapshots
umount /mnt

# Mount with optimization
MOUNT_OPTS="noatime,compress=zstd:1,space_cache=v2"
mount -o "$MOUNT_OPTS,subvol=@" "$TARGET_ROOT" /mnt
mkdir -p /mnt/{boot/efi,home,var,tmp,.snapshots}
mount -o "$MOUNT_OPTS,subvol=@home" "$TARGET_ROOT" /mnt/home
mount -o "$MOUNT_OPTS,subvol=@var" "$TARGET_ROOT" /mnt/var
mount -o "$MOUNT_OPTS,subvol=@tmp" "$TARGET_ROOT" /mnt/tmp
mount -o "$MOUNT_OPTS,subvol=@.snapshots" "$TARGET_ROOT" /mnt/.snapshots
mount "$PART_EFI" /mnt/boot/efi

# --- Phase 3: Base Installation ---
log "Phase 3: Bootstrapping base system..."
BASE_PKGS=(base base-devel linux-firmware $KERNEL ${KERNEL}-headers git neovim networkmanager sudo btrfs-progs jq)
pacstrap -K /mnt "${BASE_PKGS[@]}"
genfstab -U /mnt >> /mnt/etc/fstab

# --- Phase 4: The Chroot Setup ---
log "Phase 4: Entering Chroot for system configuration..."

# Generate the chroot script
cat > /mnt/chroot_setup.sh <<EOF
#!/bin/bash
set -e
log() { echo -e "\033[1;32m[CHROOT]\033[0m \$1"; }

# 1. System Localization
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname

# 2. User & Sudo
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# 3. Bootloader (GRUB)
pacman -S --noconfirm grub efibootmgr
if [[ "$FS" == "luks" ]]; then
    ROOT_UUID=\$(blkid -s UUID -o value "$PART_ROOT")
    sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet cryptdevice=UUID=\$ROOT_UUID:cryptroot root=/dev/mapper/cryptroot splash\"|" /etc/default/grub
    sed -i 's|^HOOKS=.*|HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)|' /etc/mkinitcpio.conf
    mkinitcpio -P
fi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# 4. GPU Drivers
if echo "$GPU_TYPE" | grep -iq "nvidia"; then
    [[ "$KERNEL" == "linux-lts" ]] && pacman -S --noconfirm nvidia-lts || pacman -S --noconfirm nvidia
elif echo "$GPU_TYPE" | grep -iq "amd"; then
    pacman -S --noconfirm xf86-video-amdgpu
fi

# 5. fun007 Ecosystem Bootstrap
log "Cloning fun007 and bootstrapping ecosystem..."
sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/dev"
sudo -u "$USERNAME" git clone https://github.com/fam007e/fun007.git "/home/$USERNAME/dev/fun007"
# Run the optimized prep script from fun007
bash "/home/$USERNAME/dev/fun007/system-admin/dotfiles/zsh/zshrc_pkg_prep.sh"

# 6. Timeshift Setup
pacman -S --noconfirm timeshift cronie
systemctl enable cronie

log "Chroot configuration complete."
EOF

chmod +x /mnt/chroot_setup.sh
arch-chroot /mnt /chroot_setup.sh
rm /mnt/chroot_setup.sh

log "Installation Successful! Unmounting and rebooting..."
umount -R /mnt
[[ "$FS" == "luks" ]] && cryptsetup close cryptroot
reboot
