#!/bin/bash
# ==============================================================================
# fun007 Arch Linux Modular Installer
# Purpose: Automated Arch installation with LUKS/BTRFS and fun007 integration.
# Logic:
#   1. Pre-flight checks & Hardware detection
#   2. Disk partitioning & Encryption (LUKS/BTRFS)
#   2b. Optional secondary media drive (Videos/Downloads/Music/Pictures)
#   3. Base system bootstrap (pacstrap)
#   4. Chroot phase (Configuration & fun007 Bootstrap)
# ==============================================================================

set -euo pipefail

# --- Arg check ---
if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 <config.json>"
    exit 1
fi

CONFIG_FILE="$1"

# Log file is root-only — it will echo config values during install.
LOG_FILE="/tmp/arch_install_$(date +%Y%m%d_%H%M%S).log"
touch "$LOG_FILE" && chmod 600 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

log()   { echo -e "\033[1;34m[$(date '+%H:%M:%S')]\033[0m $1"; }
warn()  { echo -e "\033[1;33m[$(date '+%H:%M:%S')] [WARN]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; exit 1; }

# --- Config helpers ---
get_config() {
    python -c "import json,sys; v=json.load(open('$CONFIG_FILE')).get('$1',''); print(v if v is not None else '')"
}

USERNAME=$(get_config "username")
PASSWORD=$(get_config "password")
HOSTNAME=$(get_config "hostname")
TIMEZONE=$(get_config "timezone")
FS=$(get_config "filesystem")
DISK=$(get_config "disk")
LUKS_PASSWORD=$(get_config "luks_password")
KERNEL=$(get_config "kernel")
MEDIA_DRIVE=$(get_config "media_drive")

SWAP_SIZE_GiB=$(get_config "swap_size")
[[ -z "$SWAP_SIZE_GiB" || "$SWAP_SIZE_GiB" == "null" ]] && SWAP_SIZE_GiB=8

[[ -z "$USERNAME" || "$USERNAME" == "null" ]] && error "Invalid config: 'username' is required."
[[ -z "$DISK"     || "$DISK"     == "null" ]] && error "Invalid config: 'disk' is required."

# =============================================================================
# Phase 1: Hardware & Mirror Setup
# =============================================================================
log "Phase 1: Hardware detection and mirror optimization..."

GPU_TYPE=$(lspci | grep -E "VGA|3D|Display" || true)
log "Detected GPU: $GPU_TYPE"

# Detect CPU for microcode
UCODE_PKG=""
if grep -q "GenuineIntel" /proc/cpuinfo; then
    UCODE_PKG="intel-ucode"
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    UCODE_PKG="amd-ucode"
fi
[[ -n "$UCODE_PKG" ]] && log "Detected CPU: Installing $UCODE_PKG"

log "Updating Arch Linux Keyring..."
pacman -Sy --noconfirm archlinux-keyring || {
    warn "Keyring update failed. Re-initializing pacman-key..."
    pacman-key --init
    pacman-key --populate archlinux
    pacman -Sy --noconfirm archlinux-keyring
}

log "Optimizing mirrors..."
if command -v reflector >/dev/null 2>&1; then
    if ! reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null; then
        warn "Reflector failed. Falling back to trimmed default mirrorlist."
        head -n 10 /etc/pacman.d/mirrorlist > /tmp/mirrorlist.tmp \
            && mv /tmp/mirrorlist.tmp /etc/pacman.d/mirrorlist
    fi
else
    warn "Reflector not found. Using default mirrorlist."
fi

[[ ! -s /etc/pacman.d/mirrorlist ]] && error "Mirrorlist is empty. Cannot continue."

# =============================================================================
# Phase 2: Disk Partitioning & Formatting
# =============================================================================
log "Phase 2: Preparing storage on $DISK..."

sgdisk -Z "$DISK"
sgdisk -a 2048 -o "$DISK"
# 1. EFI (2 GiB)
sgdisk -n 1::+2G --typecode=1:ef00 --change-name=1:'EFIBOOT' "$DISK"
# 2. Root (remainder)
sgdisk -n 2::-0  --typecode=2:8300 --change-name=2:'ROOT'    "$DISK"

# Partition naming: NVMe and eMMC use 'p' suffix; SATA/SCSI do not.
if [[ "$DISK" =~ nvme|mmcblk ]]; then
    PART_EFI="${DISK}p1"
    PART_ROOT="${DISK}p2"
else
    PART_EFI="${DISK}1"
    PART_ROOT="${DISK}2"
fi

# LUKS or plain BTRFS
if [[ "$FS" == "luks" ]]; then
    log "Setting up LUKS on $PART_ROOT..."
    echo -n "$LUKS_PASSWORD" | cryptsetup luksFormat "$PART_ROOT" -
    echo -n "$LUKS_PASSWORD" | cryptsetup open    "$PART_ROOT" cryptroot -
    TARGET_ROOT="/dev/mapper/cryptroot"
else
    TARGET_ROOT="$PART_ROOT"
fi

log "Formatting and creating BTRFS subvolumes..."
mkfs.vfat -F32 -n "EFIBOOT" "$PART_EFI"
mkfs.btrfs -L "ROOT" "$TARGET_ROOT" -f

# Create all subvolumes on bare volume
mount "$TARGET_ROOT" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@.snapshots
btrfs subvolume create /mnt/@swap     # isolated from Timeshift
umount /mnt

# Mount with SSD/compression optimisations
MOUNT_OPTS="noatime,compress=zstd:1,space_cache=v2"
mount -o "$MOUNT_OPTS,subvol=@"           "$TARGET_ROOT" /mnt
mkdir -p /mnt/{boot,home,var,tmp,.snapshots,swap}
mount -o "$MOUNT_OPTS,subvol=@home"       "$TARGET_ROOT" /mnt/home
mount -o "$MOUNT_OPTS,subvol=@var"        "$TARGET_ROOT" /mnt/var
mount -o "$MOUNT_OPTS,subvol=@tmp"        "$TARGET_ROOT" /mnt/tmp
mount -o "$MOUNT_OPTS,subvol=@.snapshots" "$TARGET_ROOT" /mnt/.snapshots
mount "$PART_EFI" /mnt/boot

# @swap: NO compress, NO COW (required for kernel swapfile on BTRFS)
mount -o "noatime,space_cache=v2,subvol=@swap" "$TARGET_ROOT" /mnt/swap
log "Disabling COW on @swap (chattr +C)..."
chattr +C /mnt/swap

log "Creating ${SWAP_SIZE_GiB}GiB swapfile (dd, not fallocate — BTRFS requirement)..."
dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=$((SWAP_SIZE_GiB * 1024)) status=progress
chmod 600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
log "Swapfile: $(ls -lh /mnt/swap/swapfile | awk '{print $5}')"

# =============================================================================
# Phase 2b: Optional Secondary Media Drive
# =============================================================================
if [[ -n "$MEDIA_DRIVE" && "$MEDIA_DRIVE" != "null" && -b "$MEDIA_DRIVE" ]]; then
    log "Phase 2b: Configuring media drive: $MEDIA_DRIVE"

    # Detect SSD/NVMe for discard mount option
    MEDIA_ROTATIONAL=$(cat "/sys/block/$(basename "$MEDIA_DRIVE")/queue/rotational" 2>/dev/null || echo "1")
    MEDIA_OPTS="noatime,compress=zstd:1,space_cache=v2"
    [[ "$MEDIA_ROTATIONAL" == "0" ]] && MEDIA_OPTS="${MEDIA_OPTS},discard=async"

    log "Formatting $MEDIA_DRIVE as BTRFS (label: MEDIA)..."
    mkfs.btrfs -L "MEDIA" "$MEDIA_DRIVE" -f

    log "Creating media subvolumes..."
    mkdir -p /mnt/tmp_media_setup
    mount "$MEDIA_DRIVE" /mnt/tmp_media_setup
    btrfs subvolume create /mnt/tmp_media_setup/@Videos
    btrfs subvolume create /mnt/tmp_media_setup/@Downloads
    btrfs subvolume create /mnt/tmp_media_setup/@Music
    btrfs subvolume create /mnt/tmp_media_setup/@Pictures
    umount /mnt/tmp_media_setup
    rmdir  /mnt/tmp_media_setup

    log "Mounting media subvolumes under /home/$USERNAME/..."
    mkdir -p /mnt/home/$USERNAME/{Videos,Downloads,Music,Pictures}

    mount -o "${MEDIA_OPTS},subvol=@Videos"    "$MEDIA_DRIVE" /mnt/home/$USERNAME/Videos
    mount -o "${MEDIA_OPTS},subvol=@Downloads" "$MEDIA_DRIVE" /mnt/home/$USERNAME/Downloads
    mount -o "${MEDIA_OPTS},subvol=@Music"     "$MEDIA_DRIVE" /mnt/home/$USERNAME/Music
    mount -o "${MEDIA_OPTS},subvol=@Pictures"  "$MEDIA_DRIVE" /mnt/home/$USERNAME/Pictures

    # UID 1000 = first non-root user (what useradd will assign)
    chown 1000:1000 /mnt/home/$USERNAME/{Videos,Downloads,Music,Pictures}
    log "Media drive mounted. genfstab will capture these mounts automatically."
else
    if [[ -n "$MEDIA_DRIVE" && "$MEDIA_DRIVE" != "null" ]]; then
        warn "Media drive '$MEDIA_DRIVE' specified but device not found. Skipping."
    fi
fi

# =============================================================================
# Phase 3: Base System Bootstrap
# =============================================================================
log "Phase 3: Bootstrapping base system..."
BASE_PKGS=(
    base base-devel dkms linux-firmware
    "$KERNEL" "${KERNEL}-headers"
    git neovim networkmanager sudo
    btrfs-progs
)
[[ -n "$UCODE_PKG" ]] && BASE_PKGS+=("$UCODE_PKG")
pacstrap -K /mnt "${BASE_PKGS[@]}"

log "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
# genfstab picks up all mounted filesystems by UUID, including the media drive
# subvolumes (if configured) and the @swap subvolume.
# Append the swapfile entry manually — genfstab only detects active swap,
# and we intentionally do not activate swap during install.
echo "# BTRFS swapfile (no-COW @swap subvolume)" >> /mnt/etc/fstab
echo "/swap/swapfile none swap defaults 0 0"      >> /mnt/etc/fstab

# =============================================================================
# Phase 4: Chroot Configuration
# =============================================================================
log "Phase 4: Entering chroot for system configuration..."

# Credentials are passed via environment variables so they are never written
# into the chroot script file or the install log.
cat > /mnt/chroot_setup.sh <<EOF
#!/bin/bash
set -euo pipefail
log() { echo -e "\033[1;32m[CHROOT]\033[0m \$1"; }

# Credentials injected via environment — never stored in this file.
_USERNAME="\${INST_USER:?INST_USER not set}"
_PASSWORD="\${INST_PASS:?INST_PASS not set}"

pacman -Sy --noconfirm

# ── 1. Localisation ──────────────────────────────────────────────────────────
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8"  > /etc/locale.conf
echo "KEYMAP=us"          > /etc/vconsole.conf
echo "$HOSTNAME"          > /etc/hostname

# ── 2. User & sudo ───────────────────────────────────────────────────────────
useradd -m -G wheel -s /bin/bash "\$_USERNAME"

# Copy skeleton if home dir pre-existed (media drive mounts create it early)
cp -rn /etc/skel/. "/home/\$_USERNAME/" 2>/dev/null || true
chown -R "\$_USERNAME:\$_USERNAME" "/home/\$_USERNAME"

# Set password without exposing it in process list or log
echo "\$_PASSWORD" | passwd --stdin "\$_USERNAME" 2>/dev/null \
    || echo "\$_USERNAME:\$_PASSWORD" | chpasswd

# Permanent wheel sudo (requires password)
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Temporary NOPASSWD for automated install steps; removed at end of chroot.
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/10-installer

# ── 3. Bootloader (GRUB) ─────────────────────────────────────────────────────
pacman -S --noconfirm grub efibootmgr
if [[ "$FS" == "luks" ]]; then
    ROOT_UUID=\$(blkid -s UUID -o value "$PART_ROOT")
    sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet cryptdevice=UUID=\$ROOT_UUID:cryptroot root=/dev/mapper/cryptroot splash\"|" /etc/default/grub
    sed -i 's|^HOOKS=.*|HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)|' /etc/mkinitcpio.conf
    mkinitcpio -P
fi
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# ── 4. GPU Drivers ───────────────────────────────────────────────────────────
log "Installing GPU drivers..."
if echo "$GPU_TYPE" | grep -iq "nvidia"; then
    pacman -S --noconfirm nvidia-dkms nvidia-utils \
        || log "nvidia-dkms install failed — skipping."
fi
if echo "$GPU_TYPE" | grep -iq "amd"; then
    pacman -S --noconfirm xf86-video-amdgpu mesa vulkan-radeon \
        || log "AMD driver install failed — skipping."
fi
if echo "$GPU_TYPE" | grep -iq "intel"; then
    pacman -S --noconfirm mesa vulkan-intel intel-media-driver \
        || log "Intel driver install failed — skipping."
fi

# ── 5. Core Services ─────────────────────────────────────────────────────────
log "Enabling core services..."
systemctl enable NetworkManager

pacman -S --noconfirm timeshift cronie
systemctl enable cronie

# Pre-configure Timeshift (BTRFS mode, daily + weekly snapshots)
mkdir -p /etc/timeshift
ROOT_UUID=\$(blkid -s UUID -o value "$PART_ROOT")
cat > /etc/timeshift/timeshift.json <<TS_EOF
{
  "backup_device_uuid" : "\$ROOT_UUID",
  "parent_device_uuid" : "\$ROOT_UUID",
  "do_first_run"       : "false",
  "btrfs_mode"         : "true",
  "include_btrfs_home" : "false",
  "stop_cron_emails"   : "true",
  "schedule_monthly"   : "false",
  "schedule_weekly"    : "true",
  "schedule_daily"     : "true",
  "schedule_hourly"    : "false",
  "schedule_boot"      : "true",
  "count_monthly"      : "0",
  "count_weekly"       : "2",
  "count_daily"        : "3",
  "count_hourly"       : "0",
  "count_boot"         : "2"
}
TS_EOF

# ── 6. fun007 Ecosystem Bootstrap ────────────────────────────────────────────
log "Cloning fun007 and bootstrapping ecosystem..."
su - "\$_USERNAME" <<UEOF
mkdir -p "/home/\$_USERNAME/dev"
git clone --depth 1 https://github.com/fam007e/fun007.git "/home/\$_USERNAME/dev/fun007"
bash "/home/\$_USERNAME/dev/fun007/system-admin/dotfiles/zsh/zshrc_pkg_prep.sh"
UEOF

# ── 7. Cleanup: revert temporary NOPASSWD ────────────────────────────────────
rm -f /etc/sudoers.d/10-installer
chmod 440 /etc/sudoers.d/../sudoers  # ensure base sudoers perms are correct

log "Chroot configuration complete."
EOF

chmod 700 /mnt/chroot_setup.sh

# Pass credentials via environment — they never touch the script file.
INST_USER="$USERNAME" INST_PASS="$PASSWORD" INST_LUKS="$LUKS_PASSWORD" \
    arch-chroot /mnt /chroot_setup.sh

rm /mnt/chroot_setup.sh

log "Installation complete. Unmounting and rebooting..."
umount -R /mnt
[[ "$FS" == "luks" ]] && cryptsetup close cryptroot
reboot -f
