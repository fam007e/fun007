#!/bin/bash
# ==============================================================================
# fun007 Configuration Generator
# Purpose: Interactive wizard to generate config.json for the Arch Installer.
# ==============================================================================

set -euo pipefail

log() { echo -e "\033[1;34m[CONFIG]\033[0m $1"; }
warn() { echo -e "\033[1;33m[CONFIG][WARN]\033[0m $1"; }

if ! command -v python >/dev/null 2>&1; then
    log "Error: Python is required. Should be pre-installed on ArchISO."
    exit 1
fi

echo "--------------------------------------------------"
echo "    Arch Linux Installation Config Wizard         "
echo "--------------------------------------------------"

# --- 1. Identity ---
read -rp "Enter username: " username < /dev/tty

while true; do
    read -rs -p "Enter password: " password < /dev/tty; echo
    read -rs -p "Verify password: " password_verify < /dev/tty; echo
    [ "$password" == "$password_verify" ] && break
    echo "Passwords do not match. Try again."
done

read -rp "Enter hostname: " hostname < /dev/tty
read -rp "Enter timezone (e.g., Asia/Dhaka): " timezone < /dev/tty

# --- 2. Disk Selection ---
echo ""
echo "Available disks:"
lsblk -dpno NAME,SIZE,ROTA,TYPE,MODEL | awk '$4=="disk" {
    type = ($3 == "0") ? "SSD/NVMe" : "HDD"
    model = ""
    for(i=5; i<=NF; i++) model = model (i==5 ? "" : " ") $i
    if(model == "") model = "-"
    printf "  %-15s %-8s %-30s %s\n", $1, $2, model, type
}'
read -rp "Enter installation disk (e.g., /dev/nvme0n1): " disk < /dev/tty

# --- 3. Filesystem & Encryption ---
echo ""
echo "Select Filesystem Type:"
echo "1) btrfs (Standard)"
echo "2) luks (Encrypted BTRFS)"
read -rp "Choice [1-2]: " fs_choice < /dev/tty
case $fs_choice in
    2)
        filesystem="luks"
        while true; do
            read -rs -p "Enter LUKS encryption password: " luks_password < /dev/tty; echo
            read -rs -p "Verify LUKS encryption password: " luks_password_verify < /dev/tty; echo
            [ "$luks_password" == "$luks_password_verify" ] && break
            echo "Passwords do not match. Try again."
        done
        ;;
    *) filesystem="btrfs"; luks_password="" ;;
esac

# --- 4. Kernel ---
echo ""
echo "Select Kernel:"
echo "1) linux (Stable/Latest)"
echo "2) linux-lts (Long Term Support)"
read -rp "Choice [1-2]: " k_choice < /dev/tty
[[ "$k_choice" == "2" ]] && kernel="linux-lts" || kernel="linux"

# --- 5. Swap Size ---
TOTAL_RAM_GiB=$(awk '/MemTotal/ {printf "%d", $2/1024/1024 + 0.5}' /proc/meminfo)
echo ""
echo "Detected RAM: ${TOTAL_RAM_GiB}GiB"
echo "Recommended swap: equal to RAM (for hibernation) or 4-8G (no hibernation)."
read -rp "Swap size in GiB [${TOTAL_RAM_GiB}]: " swap_input < /dev/tty
swap_size="${swap_input:-$TOTAL_RAM_GiB}"
if ! [[ "$swap_size" =~ ^[0-9]+$ ]] || [[ "$swap_size" -lt 1 ]]; then
    warn "Invalid swap size. Using default: ${TOTAL_RAM_GiB}G"
    swap_size="$TOTAL_RAM_GiB"
fi

# --- 6. Secondary / Media Drive ---
# Detect all block devices that are NOT the installation disk or its partitions.
echo ""
echo "Scanning for additional drives..."
media_drive=""
EXTRA_DISKS=()

while IFS= read -r dev; do
    # Skip the installation disk itself and any of its partitions
    [[ "$dev" == "$disk" ]] && continue
    [[ "$dev" == "${disk}p"* ]] && continue
    [[ "$dev" == "${disk}"[0-9]* ]] && continue
    # Skip loop devices and optical drives
    [[ "$dev" == /dev/loop* ]] && continue
    [[ "$dev" == /dev/sr* ]] && continue
    EXTRA_DISKS+=("$dev")
done < <(lsblk -dpno NAME,TYPE | awk '$2=="disk"{print $1}')

if [[ ${#EXTRA_DISKS[@]} -gt 0 ]]; then
    echo "Additional drives found:"
    for dev in "${EXTRA_DISKS[@]}"; do
        SIZE=$(lsblk -dno SIZE "$dev" 2>/dev/null || echo "?")
        MODEL=$(lsblk -dno MODEL "$dev" 2>/dev/null | xargs || echo "Unknown")
        ROTATIONAL=$(cat "/sys/block/$(basename "$dev")/queue/rotational" 2>/dev/null || echo "1")
        [[ "$ROTATIONAL" == "0" ]] && DTYPE="SSD/NVMe" || DTYPE="HDD"
        printf "  %-15s %-8s %-10s %s\n" "$dev" "$SIZE" "$DTYPE" "$MODEL"
    done
    echo ""
    echo "You can dedicate one of these drives for home media directories:"
    echo "  Videos, Downloads, Music, Pictures"
    echo "  (Drive will be formatted as BTRFS with one subvolume per directory)"
    echo ""
    read -rp "Enter media drive path, or press Enter to skip: " media_drive_input < /dev/tty

    if [[ -n "$media_drive_input" ]]; then
        if ! lsblk "$media_drive_input" &>/dev/null; then
            warn "Device $media_drive_input not found. Skipping media drive."
        elif [[ "$media_drive_input" == "$disk" ]]; then
            warn "Cannot use the installation disk as media drive. Skipping."
        else
            echo ""
            echo "WARNING: ALL data on $media_drive_input will be permanently erased."
            read -rp "Type 'yes' to confirm: " confirm < /dev/tty
            if [[ "$confirm" == "yes" ]]; then
                media_drive="$media_drive_input"
                log "Media drive set to: $media_drive"
            else
                warn "Skipping media drive configuration."
            fi
        fi
    fi
else
    log "No additional drives detected."
fi

# --- 7. Secure Wipe ---
echo ""
echo "Secure wipe (urandom overwrite) before formatting:"
echo "  Applies to: installation disk + media drive (if configured)"
echo "  SSD note: urandom wipe is slow and doesn't guarantee full coverage due"
echo "  to wear leveling — use LUKS instead for SSD security."
echo "  HDD: urandom is effective but slow (~100 MB/s, ~50 min per 300 GiB)."
echo ""
read -rp "Enable secure wipe? [y/N]: " wipe_input < /dev/tty
[[ "$wipe_input" =~ ^[Yy]$ ]] && wipe_disk="true" || wipe_disk="false"
log "Secure wipe: $wipe_disk"

# --- Generate JSON ---
python -c "
import json, sys

data = {
    'username':     sys.argv[1],
    'password':     sys.argv[2],
    'hostname':     sys.argv[3],
    'timezone':     sys.argv[4],
    'disk':         sys.argv[5],
    'filesystem':   sys.argv[6],
    'luks_password':sys.argv[7],
    'kernel':       sys.argv[8],
    'swap_size':    int(sys.argv[9]),
    'media_drive':  sys.argv[10],
    'wipe_disk':    sys.argv[11],
}

with open('config.json', 'w') as f:
    json.dump(data, f, indent=4)
" "$username" "$password" "$hostname" "$timezone" \
  "$disk" "$filesystem" "$luks_password" "$kernel" \
  "$swap_size" "$media_drive" "$wipe_disk"

# Restrict config.json permissions — it contains plaintext passwords.
chmod 600 config.json

log "config.json generated (permissions: 600)."
log "Next step: sudo ./archinstall_interactive.sh config.json"
