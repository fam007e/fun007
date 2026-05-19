#!/bin/bash
# ==============================================================================
# fun007 Configuration Generator
# Purpose: Interactive wizard to generate config.json for the Arch Installer.
# ==============================================================================

set -e

log() { echo -e "\033[1;34m[CONFIG]\033[0m $1"; }

# Pre-requisite: Python (Pre-installed on ArchISO)
if ! command -v python >/dev/null 2>&1; then
    log "Error: Python is required for JSON generation. This should be pre-installed on ArchISO."
    exit 1
fi

echo "--------------------------------------------------"
echo "    Arch Linux Installation Config Wizard         "
echo "--------------------------------------------------"

# 1. Identity
read -rp "Enter username: " username < /dev/tty

while true; do
    read -rs -p "Enter password: " password < /dev/tty; echo
    read -rs -p "Verify password: " password_verify < /dev/tty; echo
    [ "$password" == "$password_verify" ] && break
    echo "Passwords do not match. Please try again."
done

read -rp "Enter hostname: " hostname < /dev/tty
read -rp "Enter timezone (e.g., Asia/Dhaka): " timezone < /dev/tty

# 2. Disk Selection
lsblk -dpno NAME,SIZE,MODEL
read -rp "Enter installation disk (e.g., /dev/nvme0n1): " disk < /dev/tty

# 3. Filesystem & Encryption
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
            echo "Passwords do not match. Please try again."
        done
        ;;
    *) filesystem="btrfs"; luks_password="" ;;
esac

# 4. Kernel
echo "Select Kernel:"
echo "1) linux (Stable/Latest)"
echo "2) linux-lts (Long Term Support)"
read -rp "Choice [1-2]: " k_choice < /dev/tty
[[ "$k_choice" == "2" ]] && kernel="linux-lts" || kernel="linux"

# 5. Swap Size
# Rule of thumb: RAM <= 8G → match RAM; RAM > 8G → 8G is enough unless hibernation needed
TOTAL_RAM_GiB=$(awk '/MemTotal/ {printf "%d", $2/1024/1024 + 0.5}' /proc/meminfo)
echo ""
echo "Detected RAM: ${TOTAL_RAM_GiB}GiB"
echo "Enter swap size in GiB (press Enter to use ${TOTAL_RAM_GiB}G default):"
read -rp "Swap size [${TOTAL_RAM_GiB}]: " swap_input < /dev/tty
swap_size="${swap_input:-$TOTAL_RAM_GiB}"

# Validate numeric
if ! [[ "$swap_size" =~ ^[0-9]+$ ]] || [[ "$swap_size" -lt 1 ]]; then
    echo "Invalid swap size, using default: ${TOTAL_RAM_GiB}G"
    swap_size="$TOTAL_RAM_GiB"
fi

# Generate JSON using Python
python -c "
import json, sys
data = {
    'username': sys.argv[1],
    'password': sys.argv[2],
    'hostname': sys.argv[3],
    'timezone': sys.argv[4],
    'disk': sys.argv[5],
    'filesystem': sys.argv[6],
    'luks_password': sys.argv[7],
    'kernel': sys.argv[8],
    'swap_size': int(sys.argv[9])
}
with open('config.json', 'w') as f:
    json.dump(data, f, indent=4)
" "$username" "$password" "$hostname" "$timezone" "$disk" "$filesystem" "$luks_password" "$kernel" "$swap_size"

log "Success! config.json generated. Now run: sudo ./archinstall_interactive.sh config.json"
