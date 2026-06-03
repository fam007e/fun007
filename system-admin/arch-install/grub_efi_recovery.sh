#!/bin/bash
# ==============================================================================
# fun007 GRUB EFI Recovery Script
# Purpose: Recover GRUB EFI boot entry after BIOS update wipes NVRAM.
#          Supports plain BTRFS and LUKS-encrypted BTRFS installs.
# Usage:   Run from ArchISO live environment as root.
#          ./grub_efi_recovery.sh
# ==============================================================================

set -euo pipefail

log()   { echo -e "\033[1;34m[$(date '+%H:%M:%S')]\033[0m $1"; }
warn()  { echo -e "\033[1;33m[$(date '+%H:%M:%S')] [WARN]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; exit 1; }
ok()    { echo -e "\033[1;32m[$(date '+%H:%M:%S')] [OK]\033[0m $1"; }

# Must run as root
[[ "$EUID" -ne 0 ]] && error "Run as root."

# Must run from ArchISO (or any live env), not from an installed system
mountpoint -q /mnt && error "/mnt is already in use. Unmount first."

echo "======================================================"
echo "        fun007 GRUB EFI Recovery - ArchISO           "
echo "======================================================"

# =============================================================================
# Step 1: Disk selection
# =============================================================================
echo ""
log "Available disks:"
lsblk -dpno NAME,SIZE,ROTA,TYPE,MODEL | awk '$4=="disk" {
    type = ($3 == "0") ? "SSD/NVMe" : "HDD"
    model = ""
    for(i=5; i<=NF; i++) model = model (i==5 ? "" : " ") $i
    if(model == "") model = "-"
    printf "  %-15s %-8s %-30s %s\n", $1, $2, model, type
}'

echo ""
read -rp "Enter the installation disk (e.g., /dev/sda, /dev/nvme0n1): " DISK < /dev/tty

[[ ! -b "$DISK" ]] && error "Device '$DISK' not found."

# Derive partition names (NVMe/eMMC use 'p' suffix)
if [[ "$DISK" =~ nvme|mmcblk ]]; then
    PART_EFI="${DISK}p1"
    PART_ROOT="${DISK}p2"
else
    PART_EFI="${DISK}1"
    PART_ROOT="${DISK}2"
fi

log "EFI  partition : $PART_EFI"
log "Root partition : $PART_ROOT"

[[ ! -b "$PART_EFI"  ]] && error "EFI partition '$PART_EFI' not found."
[[ ! -b "$PART_ROOT" ]] && error "Root partition '$PART_ROOT' not found."

# =============================================================================
# Step 2: Filesystem type (LUKS or plain BTRFS)
# =============================================================================
echo ""
echo "Select the filesystem type used during installation:"
echo "  1) btrfs  (Standard, no encryption)"
echo "  2) luks   (Encrypted BTRFS)"
read -rp "Choice [1-2]: " FS_CHOICE < /dev/tty

TARGET_ROOT=""
LUKS_OPENED=false

case "$FS_CHOICE" in
    2)
        log "LUKS selected. Opening encrypted partition..."
        read -rs -p "Enter LUKS password: " LUKS_PASS < /dev/tty; echo

        # Close any stale mapping from a previous failed attempt
        if [[ -b /dev/mapper/cryptroot ]]; then
            warn "Stale /dev/mapper/cryptroot found. Closing it first..."
            cryptsetup close cryptroot || error "Could not close stale cryptroot."
        fi

        echo -n "$LUKS_PASS" | cryptsetup open "$PART_ROOT" cryptroot - \
            || error "Failed to open LUKS container. Wrong password or not a LUKS partition."

        TARGET_ROOT="/dev/mapper/cryptroot"
        LUKS_OPENED=true
        ok "LUKS container opened → $TARGET_ROOT"
        ;;
    *)
        TARGET_ROOT="$PART_ROOT"
        log "Plain BTRFS selected. Target: $TARGET_ROOT"
        ;;
esac

# =============================================================================
# Step 3: Mount BTRFS subvolumes
# =============================================================================
log "Mounting BTRFS subvolumes..."

MOUNT_OPTS="noatime,compress=zstd:1,space_cache=v2"

mount -o "${MOUNT_OPTS},subvol=@"           "$TARGET_ROOT" /mnt
mkdir -p /mnt/{boot,home,var,tmp,.snapshots,swap}
mount -o "${MOUNT_OPTS},subvol=@home"       "$TARGET_ROOT" /mnt/home
mount -o "${MOUNT_OPTS},subvol=@var"        "$TARGET_ROOT" /mnt/var
mount -o "${MOUNT_OPTS},subvol=@tmp"        "$TARGET_ROOT" /mnt/tmp
mount -o "${MOUNT_OPTS},subvol=@.snapshots" "$TARGET_ROOT" /mnt/.snapshots
mount "$PART_EFI" /mnt/boot

ok "Mounts complete:"
lsblk "$DISK"

# =============================================================================
# Step 4: Chroot — reinstall GRUB and regenerate config
# =============================================================================
log "Entering chroot to reinstall GRUB..."

# Build the chroot script inline
CHROOT_SCRIPT=$(cat <<'CHROOT'
#!/bin/bash
set -euo pipefail
log()  { echo -e "\033[1;32m[CHROOT]\033[0m $1"; }
ok()   { echo -e "\033[1;32m[CHROOT][OK]\033[0m $1"; }
warn() { echo -e "\033[1;33m[CHROOT][WARN]\033[0m $1"; }

log "Installing/updating grub and efibootmgr if missing..."
pacman -Sy --noconfirm --needed grub efibootmgr

log "Reinstalling GRUB to EFI..."
grub-install --target=x86_64-efi \
             --efi-directory=/boot \
             --bootloader-id=GRUB \
             --recheck \
    || { echo "[ERROR] grub-install failed."; exit 1; }

log "Regenerating GRUB config..."
grub-mkconfig -o /boot/grub/grub.cfg

echo ""
log "EFI boot entries:"
efibootmgr | grep -i grub && ok "GRUB entry registered." \
    || warn "GRUB entry not found in efibootmgr — see fallback step below."

CHROOT
)

echo "$CHROOT_SCRIPT" > /mnt/tmp/grub_recovery_chroot.sh
chmod 700 /mnt/tmp/grub_recovery_chroot.sh
arch-chroot /mnt /tmp/grub_recovery_chroot.sh
rm /mnt/tmp/grub_recovery_chroot.sh

# =============================================================================
# Step 5: Fallback — copy GRUB to the default EFI path
# =============================================================================
echo ""
echo "------------------------------------------------------"
echo " Optional: Install GRUB to the EFI fallback path."
echo " Required if your motherboard ignores custom NVRAM"
echo " entries after a BIOS update (common on Gigabyte boards)."
echo "------------------------------------------------------"
read -rp "Copy grubx64.efi to /EFI/BOOT/BOOTX64.EFI? [y/N]: " FALLBACK < /dev/tty

if [[ "${FALLBACK,,}" == "y" ]]; then
    GRUB_EFI="/mnt/boot/EFI/GRUB/grubx64.efi"
    FALLBACK_DIR="/mnt/boot/EFI/BOOT"
    FALLBACK_EFI="$FALLBACK_DIR/BOOTX64.EFI"

    if [[ ! -f "$GRUB_EFI" ]]; then
        warn "grubx64.efi not found at expected path: $GRUB_EFI"
        warn "Skipping fallback copy."
    else
        mkdir -p "$FALLBACK_DIR"
        cp "$GRUB_EFI" "$FALLBACK_EFI"
        ok "Fallback EFI installed: $FALLBACK_EFI"
    fi
fi

# =============================================================================
# Step 6: Unmount and cleanup
# =============================================================================
log "Unmounting filesystems..."
umount -R /mnt

if [[ "$LUKS_OPENED" == true ]]; then
    log "Closing LUKS container..."
    cryptsetup close cryptroot
fi

echo ""
ok "Recovery complete."
echo ""
echo "  Next steps:"
echo "  1. Reboot: reboot"
echo "  2. At POST press F12 (or your board's one-time boot key)"
echo "     and select GRUB / the SSD to verify boot works."
echo "  3. Then set it as default in BIOS boot order."
echo ""
