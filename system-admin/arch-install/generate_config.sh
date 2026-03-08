#!/bin/bash
# ==============================================================================
# fun007 Configuration Generator
# Purpose: Interactive wizard to generate config.json for the Arch Installer.
# ==============================================================================

set -e

log() { echo -e "\033[1;34m[CONFIG]\033[0m $1"; }

# Pre-requisite: jq
command -v jq >/dev/null 2>&1 || sudo pacman -Sy --noconfirm jq

echo "--------------------------------------------------"
echo "    Arch Linux Installation Config Wizard         "
echo "--------------------------------------------------"

# 1. Identity
read -rp "Enter username: " username
read -rs -p "Enter password: " password; echo
read -rp "Enter hostname: " hostname
read -rp "Enter timezone (e.g., Asia/Dhaka): " timezone

# 2. Disk Selection
lsblk -dpno NAME,SIZE,MODEL
read -rp "Enter installation disk (e.g., /dev/nvme0n1): " disk

# 3. Filesystem & Encryption
echo "Select Filesystem Type:"
echo "1) btrfs (Standard)"
echo "2) luks (Encrypted BTRFS)"
read -rp "Choice [1-2]: " fs_choice
case $fs_choice in
    2) filesystem="luks"; read -rs -p "Enter LUKS encryption password: " luks_password; echo ;;
    *) filesystem="btrfs"; luks_password="" ;;
esac

# 4. Kernel
echo "Select Kernel:"
echo "1) linux (Stable/Latest)"
echo "2) linux-lts (Long Term Support)"
read -rp "Choice [1-2]: " k_choice
[[ "$k_choice" == "2" ]] && kernel="linux-lts" || kernel="linux"

# Generate JSON
jq -n \
  --arg un "$username" \
  --arg pw "$password" \
  --arg hn "$hostname" \
  --arg tz "$timezone" \
  --arg dk "$disk" \
  --arg fs "$filesystem" \
  --arg lp "$luks_password" \
  --arg kn "$kernel" \
  '{username: $un, password: $pw, hostname: $hn, timezone: $tz, disk: $dk, filesystem: $fs, luks_password: $lp, kernel: $kn}' \
  > config.json

log "Success! config.json generated. Now run: sudo ./archinstall_interactive.sh config.json"
