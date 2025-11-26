#!/bin/bash

# Function to detect if a drive is an SSD
is_ssd() {
    local drive="$1"
    [ -e "/sys/block/${drive##*/}/queue/rotational" ] && [ "$(cat "/sys/block/${drive##*/}/queue/rotational")" = "0" ]
}

collect_user_input() {
    local valid_filesystems=("btrfs" "ext4" "luks")
    local valid_kernels=("linux" "linux-lts")
    local valid_desktops=("dwm" "hyprland" "none")

    echo "Collecting system configuration..."
    
    # Username validation
    while true; do
        read -r -p "Enter username (lowercase, alphanumeric): " username
        if [[ "$username" =~ ^[a-z][a-z0-9]*$ ]]; then break; else echo "Invalid username"; fi
    done

    # Password input
    while true; do
        read -r -s -p "Enter password: " password
        echo
        read -r -s -p "Confirm password: " password_confirm
        echo
        [ "$password" = "$password_confirm" ] && break
        echo "Passwords do not match. Try again."
    done

    # Hostname validation
    while true; do
        read -r -p "Enter hostname (alphanumeric, no spaces): " hostname
        if [[ "$hostname" =~ ^[a-zA-Z0-9-]+$ ]]; then break; else echo "Invalid hostname"; fi
    done

    # Timezone validation
    while true; do
        read -r -p "Enter timezone (e.g., Europe/London): " timezone
        if [ -f "/usr/share/zoneinfo/$timezone" ]; then break; else echo "Invalid timezone"; fi
    done

    # Keyboard layout
    read -r -p "Enter keyboard layout (default: us): " keymap
    keymap=${keymap:-us}

    # Filesystem selection
    echo "Select filesystem:"
    select filesystem in "${valid_filesystems[@]}"; do
        if [[ ${valid_filesystems[*]} =~ ${filesystem} ]]; then break; fi
    done

    # Desktop environment selection
    echo "Select desktop environment:"
    select desktop in "${valid_desktops[@]}"; do
        if [[ ${valid_desktops[*]} =~ ${desktop} ]]; then break; fi
    done

    # SDDM login manager
    read -r -p "Install SDDM login manager? (y/n): " use_sddm
    use_sddm=${use_sddm:-n}

    # Disk selection and validation
    while true; do
        read -r -p "Enter disk for installation (e.g., /dev/sda): " disk
        if [ -b "$disk" ]; then break; else echo "Error: $disk is not a valid block device"; fi
    done

    # SSD detection
    if is_ssd "$disk"; then
        echo "Detected $disk as an SSD"
        is_ssd="y"
    else
        echo "Detected $disk as a regular HDD"
        is_ssd="n"
    fi

    # Secondary disk
    read -r -p "Use secondary disk for /home? (y/n): " use_secondary_disk
    if [ "$use_secondary_disk" = "y" ]; then
        while true; do
            read -r -p "Enter secondary disk (e.g., /dev/sdb): " secondary_disk
            if [ -b "$secondary_disk" ]; then break; else echo "Error: $secondary_disk is not a valid block device"; fi
        done
    else
        secondary_disk=""
    fi

    # Kernel selection
    echo "Select kernel:"
    select kernel in "${valid_kernels[@]}"; do
        if [[ ${valid_kernels[*]} =~ ${kernel} ]]; then break; fi
    done

    # LUKS password if needed
    if [ "$filesystem" = "luks" ]; then
        while true; do
            read -r -s -p "Enter LUKS password: " luks_password
            echo
            read -r -s -p "Confirm LUKS password: " luks_password_confirm
            echo
            [ "$luks_password" = "$luks_password_confirm" ] && break
            echo "Passwords do not match. Try again."
        done
    else
        luks_password=""
    fi
}

generate_json_config() {
    cat <<EOF > config.json
{
    "username": "$username",
    "password": "$password",
    "hostname": "$hostname",
    "timezone": "$timezone",
    "keymap": "$keymap",
    "filesystem": "$filesystem",
    "desktop": "$desktop",
    "use_sddm": "$use_sddm",
    "disk": "$disk",
    "secondary_disk": "$secondary_disk",
    "is_ssd": "$is_ssd",
    "kernel": "$kernel",
    "luks_password": "$luks_password"
}
EOF
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "Installing jq for JSON parsing"
    pacman -Sy --noconfirm jq
fi

collect_user_input
generate_json_config
echo "Configuration saved to config.json"
