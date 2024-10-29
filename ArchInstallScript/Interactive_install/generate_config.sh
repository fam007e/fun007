#!/bin/sh

# Function to detect if a drive is an SSD
is_ssd() {
    local drive=$1
    [ "$(cat /sys/block/"${drive##*/}"/queue/rotational)" = "0" ]
}

collect_user_input() {
    printf "Enter username: "
    read username
    printf "Enter password: "
    stty -echo
    read password
    stty echo
    printf "\n"
    printf "Enter hostname: "
    read hostname
    printf "Enter timezone (e.g., Europe/London): "
    read timezone
    printf "Enter keyboard layout: "
    read keymap
    printf "Select filesystem (btrfs/ext4/luks): "
    read filesystem
    
    # Get installation disk and verify it exists
    while true; do
        printf "Enter disk for installation (e.g., /dev/sda): "
        read disk
        if [ -b "$disk" ]; then
            break
        else
            printf "Error: %s is not a valid block device. Please try again.\n" "$disk"
        fi
    done
    
    # Automatically detect if it's an SSD
    if is_ssd "$disk"; then
        printf "Detected %s as an SSD\n" "$disk"
        is_ssd="y"
    else
        printf "Detected %s as a regular HDD\n" "$disk"
        is_ssd="n"
    fi

    printf "Use secondary disk? (y/n): "
    read use_secondary_disk
    if [ "$use_secondary_disk" = "y" ]; then
        while true; do
            printf "Enter secondary disk: "
            read secondary_disk
            if [ -b "$secondary_disk" ]; then
                break
            else
                printf "Error: %s is not a valid block device. Please try again.\n" "$secondary_disk"
            fi
        done
    fi
    
    printf "Select kernel (linux-lts/linux): "
    read kernel
    while [ "$kernel" != "linux" ] && [ "$kernel" != "linux-lts" ]; do
        printf "Invalid kernel selection. Please choose 'linux' or 'linux-lts': "
        read kernel
    done
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
    "disk": "$disk",
    "secondary_disk": "$secondary_disk",
    "is_ssd": "$is_ssd",
    "kernel": "$kernel"
}
EOF
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    printf "This script must be run as root\n"
    exit 1
fi

collect_user_input
generate_json_config
printf "%b\n" "Configuration saved to config.json"