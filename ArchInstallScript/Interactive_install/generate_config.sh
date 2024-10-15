#!/bin/sh

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
    printf "Enter disk for installation: "
    read disk
    printf "Use secondary disk? (y/n): "
    read use_secondary_disk
    if [ "$use_secondary_disk" = "y" ]; then
        printf "Enter secondary disk: "
        read secondary_disk
    fi
    printf "Is this an SSD? (y/n): "
    read is_ssd
    printf "Select kernel (linux-lts/linux): "
    read kernel
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

collect_user_input
generate_json_config
printf "%b\n" "Configuration saved to config.json"