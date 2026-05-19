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

log()   { echo -e "\033[1;34m[$(date '+%H:%M:%S')]\033[0m $1"; }
warn()  { echo -e "\033[1;33m[$(date '+%H:%M:%S')] [WARN]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; exit 1; }

# --- Configuration Retrieval ---
get_config() {
    python -c "import json, sys; print(json.load(open('$CONFIG_FILE')).get('$1', ''))"
}

USERNAME=$(get_config "username")
PASSWORD=$(get_config "password")
HOSTNAME=$(get_config "hostname")
TIMEZONE=$(get_config "timezone")
FS=$(get_config "filesystem")
DISK=$(get_config "disk")
LUKS_PASSWORD=$(get_config "luks_password")
KERNEL=$(get_config "kernel")
DESKTOP=$(get_config "desktop")
# swap_size in GiB; fallback to 8 if not set in config (backwards compat)
SWAP_SIZE_GiB=$(get_config "swap_size")
[[ -z "$SWAP_SIZE_GiB" || "$SWAP_SIZE_GiB" == "null" ]] && SWAP_SIZE_GiB=8

[[ -z "$USERNAME" || "$USERNAME" == "null" ]] && error "Invalid config: 'username' is required."

# --- Phase 1: Hardware & Mirror Setup ---
log "Phase 1: Hardware detection and mirror optimization..."

# GPU Detection
GPU_TYPE=$(lspci | grep -E "VGA|3D|Display" || true)
log "Detected GPU: $GPU_TYPE"

# Keyring & Mirror Optimization
# On older ISOs, we might need to initialize the keyring first
log "Updating Arch Linux Keyring..."
pacman -Sy --noconfirm archlinux-keyring || {
    warn "Keyring update failed. Attempting to re-initialize pacman-key..."
    pacman-key --init
    pacman-key --populate archlinux
    pacman -Sy --noconfirm archlinux-keyring
}

log "Optimizing mirrors..."
# Reflector is notoriously buggy in some ArchISO versions due to Python module paths.
# We attempt it, but if it fails, we provide a reliable fallback.
if command -v reflector >/dev/null 2>&1; then
    log "Attempting mirror optimization with Reflector..."
    if ! reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null; then
        warn "Reflector failed (likely a module path issue in ArchISO). Falling back to basic mirror update."
        # Basic fallback: keep only the top 5 mirrors from the existing list to speed up pacstrap
        head -n 10 /etc/pacman.d/mirrorlist > /tmp/mirrorlist.tmp && mv /tmp/mirrorlist.tmp /etc/pacman.d/mirrorlist
    fi
else
    warn "Reflector not found. Using default mirrorlist."
fi

# Final check: ensure mirrorlist is not empty
if [[ ! -s /etc/pacman.d/mirrorlist ]]; then
    error "Mirrorlist is empty. Cannot proceed with installation."
fi

# --- Phase 2: Disk Partitioning & Formatting ---
log "Phase 2: Preparing storage on $DISK..."

# Clear partition table
sgdisk -Z "$DISK"
sgdisk -a 2048 -o "$DISK"

# 1. EFI System Partition (2GB)
sgdisk -n 1::+2G --typecode=1:ef00 --change-name=1:'EFIBOOT' "$DISK"
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

log "Creating BTRFS filesystem and subvolumes..."
mkfs.vfat -F32 -n "EFIBOOT" "$PART_EFI"
mkfs.btrfs -L "ROOT" "$TARGET_ROOT" -f

# Create all subvolumes on the bare volume first
mount "$TARGET_ROOT" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@.snapshots
# Dedicated swap subvolume — isolated so Timeshift never touches it
btrfs subvolume create /mnt/@swap
umount /mnt

# Mount subvolumes with SSD/compression optimizations
MOUNT_OPTS="noatime,compress=zstd:1,space_cache=v2"
mount -o "$MOUNT_OPTS,subvol=@" "$TARGET_ROOT" /mnt
mkdir -p /mnt/{boot,home,var,tmp,.snapshots,swap}
mount -o "$MOUNT_OPTS,subvol=@home"        "$TARGET_ROOT" /mnt/home
mount -o "$MOUNT_OPTS,subvol=@var"         "$TARGET_ROOT" /mnt/var
mount -o "$MOUNT_OPTS,subvol=@tmp"         "$TARGET_ROOT" /mnt/tmp
mount -o "$MOUNT_OPTS,subvol=@.snapshots"  "$TARGET_ROOT" /mnt/.snapshots
mount "$PART_EFI" /mnt/boot

# @swap gets its own mount — NO compress, NO COW.
# compress on a swapfile subvolume is silently ignored by the kernel but
# chattr +C must be set BEFORE the file is created; mounting without
# compress keeps the intent clear and avoids future surprises.
mount -o "noatime,space_cache=v2,subvol=@swap" "$TARGET_ROOT" /mnt/swap

log "Configuring @swap subvolume: disabling COW (required for BTRFS swapfile)..."
# chattr +C disables copy-on-write on the directory; inherited by new files.
# This is what prevents "Text file busy" errors in Timeshift.
chattr +C /mnt/swap

log "Creating ${SWAP_SIZE_GiB}GiB swapfile using dd (fallocate is unsafe on BTRFS)..."
# fallocate creates sparse/non-contiguous extents on BTRFS which the kernel
# rejects at swapon time. dd forces actual zero-filled contiguous allocation.
dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=$((SWAP_SIZE_GiB * 1024)) status=progress
chmod 600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
log "Swapfile created: $(ls -lh /mnt/swap/swapfile | awk '{print $5}')"

# --- Phase 3: Base Installation ---
log "Phase 3: Bootstrapping base system..."
BASE_PKGS=(base base-devel dkms linux-firmware $KERNEL ${KERNEL}-headers git neovim networkmanager sudo btrfs-progs)
pacstrap -K /mnt "${BASE_PKGS[@]}"

# genfstab captures all currently mounted filesystems by UUID — including
# the @swap subvolume mount at /swap. The swapfile line is appended manually
# because genfstab only detects active swap (we intentionally skip swapon
# during install to keep the live environment clean).
log "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
echo "# Swapfile on no-COW @swap subvolume" >> /mnt/etc/fstab
echo "/swap/swapfile none swap defaults 0 0" >> /mnt/etc/fstab

# --- Phase 4: The Chroot Setup ---
log "Phase 4: Entering Chroot for system configuration..."

cat > /mnt/chroot_setup.sh <<EOF
#!/bin/bash
set -e
log() { echo -e "\033[1;32m[CHROOT]\033[0m \$1"; }

# Sync package databases
pacman -Sy --noconfirm

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
# Enable standard sudo for wheel group (requires password)
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
# Grant temporary NOPASSWD to wheel group to ensure automated installation scripts don't hang
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/10-installer

# 3. Bootloader (GRUB)
pacman -S --noconfirm grub efibootmgr
if [[ "$FS" == "luks" ]]; then
    ROOT_UUID=\$(blkid -s UUID -o value "$PART_ROOT")
    sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet cryptdevice=UUID=\$ROOT_UUID:cryptroot root=/dev/mapper/cryptroot splash\"|" /etc/default/grub
    sed -i 's|^HOOKS=.*|HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)|' /etc/mkinitcpio.conf
    mkinitcpio -P
fi
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# 4. GPU Drivers
log "Installing GPU drivers for $GPU_TYPE..."
if echo "$GPU_TYPE" | grep -iq "nvidia"; then
    pacman -S --noconfirm nvidia-dkms nvidia-utils || log "Failed to install nvidia-dkms, skipping..."
fi

if echo "$GPU_TYPE" | grep -iq "amd"; then
    pacman -S --noconfirm xf86-video-amdgpu mesa vulkan-radeon || log "Failed to install AMD drivers, skipping..."
fi

if echo "$GPU_TYPE" | grep -iq "intel"; then
    pacman -S --noconfirm mesa vulkan-intel intel-media-driver || log "Failed to install Intel drivers, skipping..."
fi

# 5. fun007 Ecosystem Bootstrap
log "Cloning fun007 and bootstrapping ecosystem..."
# Ensure home directory permissions are correct
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"

# Run the remaining steps as the user with a full login shell to ensure correct environment
su - "$USERNAME" <<UEOF
mkdir -p "/home/$USERNAME/dev"
git clone --depth 1 https://github.com/fam007e/fun007.git "/home/$USERNAME/dev/fun007"
bash "/home/$USERNAME/dev/fun007/system-admin/dotfiles/zsh/zshrc_pkg_prep.sh"
UEOF

# 6. Timeshift Setup
# cronie drives scheduled snapshots; timeshift-autosnap triggers on pacman.
pacman -S --noconfirm timeshift cronie
systemctl enable cronie

# Cleanup: Remove temporary passwordless sudo access
rm /etc/sudoers.d/10-installer

log "Chroot configuration complete."
EOF

chmod +x /mnt/chroot_setup.sh
arch-chroot /mnt /chroot_setup.sh
rm /mnt/chroot_setup.sh

log "Installation Successful! Unmounting and rebooting..."
umount -R /mnt
[[ "$FS" == "luks" ]] && cryptsetup close cryptroot
# Use -f for a forced reboot if standard reboot hangs in ArchISO
reboot -f
