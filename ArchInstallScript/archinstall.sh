#!/bin/bash

# Redirect stdout and stderr to archsetup.txt and still output to console
exec > >(tee -i archsetup.txt)
exec 2>&1

# Functions for system checks
root_check() {
    if [ "$(id -u)" != "0" ]; then
        printf "%b\n" "ERROR! This script must be run under the 'root' user!"
        exit 1
    fi
}

docker_check() {
    if awk -F/ '$2 == "docker"' /proc/self/cgroup | read -r || [ -f /.dockerenv ]; then
        printf "%b\n" "ERROR! Docker container is not supported"
        exit 1
    fi
}

arch_check() {
    if [ ! -e /etc/arch-release ]; then
        printf "%b\n" "ERROR! This script must be run in Arch Linux!"
        exit 1
    fi
}

pacman_check() {
    if [ -f /var/lib/pacman/db.lck ]; then
        printf "%b\n" "ERROR! Pacman is blocked."
        printf "%b\n" "If not running remove /var/lib/pacman/db.lck"
        exit 1
    fi
}

set_password() {
    while true; do
        printf "Please enter %s password: " "$1"
        read -rs password1
        printf "\n"
        printf "Please re-enter %s password: " "$1"
        read -rs password2
        printf "\n"
        if [ "$password1" = "$password2" ]; then
            eval "export $1='$password1'"
            break
        else
            printf "%b\n" "Passwords do not match. Please try again."
        fi
    done
}

background_checks() {
    root_check
    arch_check
    pacman_check
    docker_check
}

# Selection menu function
select_option() {
    # Parameters
    local options=("$@")
    local num_options=${#options[@]}
    local selected=0
    local last_selected=-1

    # Hide cursor
    printf "\e[?25l"

    while true; do
        # Clear previous menu if needed
        if [ "$last_selected" -ne -1 ]; then
            printf "\033[%sA" "$num_options"
        fi

        if [ "$last_selected" -eq -1 ]; then
            printf "%b\n" "Please select an option using arrow keys and Enter:"
        fi

        # Print menu
        for i in "${!options[@]}"; do
            if [ "$i" -eq "$selected" ]; then
                printf "> %s\n" "${options[$i]}"
            else
                printf "  %s\n" "${options[$i]}"
            fi
        done

        last_selected=$selected

        # Read user input
        read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 -t 0.1 key
                case "$key" in
                    '[A') # Up arrow
                        ((selected--))
                        if [ "$selected" -lt 0 ]; then
                            selected=$((num_options - 1))
                        fi
                        ;;
                    '[B') # Down arrow
                        ((selected++))
                        if [ "$selected" -ge "$num_options" ]; then
                            selected=0
                        fi
                        ;;
                esac
                ;;
            '') # Enter key
                # Show cursor
                printf "\e[?25h"
                return "$selected"
                ;;
        esac
    done
}

# Banner function
logo() {
    clear
    printf "%b\n" "----------------------------------------------------------------------------------------------------------------------"
    printf "%b\n" "   _____                .__      .___                 __         .__  .__      _________            .__        __"
    printf "%b\n" "  /  _  \_______   ____ |  |__   |   | ____   _______/  |______  |  | |  |    /   _____/ ___________|__|______/  |"
    printf "%b\n" " /  /_\  \_  __ \_/ ___\|  |  \  |   |/    \ /  ___/\   __\__  \ |  | |  |    \_____  \_/ ___\_  __ \  \____ \   __\\"
    printf "%b\n" "/    |    \  | \/\  \___|   Y  \ |   |   |  \\___ \  |  |  / __ \|  |_|  |__  /        \  \___|  | \/  |  |_> >  |"
    printf "%b\n" "\____|__  /__|    \___  >___|  / |___|___|  /____  > |__| (____  /____/____/ /_______  /\___  >__|  |__|   __/|__|"
    printf "%b\n" "        \/            \/     \/           \/     \/            \/                    \/     \/         |__|"
    printf "%b\n" "----------------------------------------------------------------------------------------------------------------------"
    printf "%b\n" "                                        Automated Arch Linux Installer"
    printf "%b\n" "----------------------------------------------------------------------------------------------------------------------"
}

# Filesystem selection function
filesystem() {
    printf "%b\n" "
    Please Select your file system for both boot and root
    "
    options=("btrfs" "ext4" "luks" "exit")
    select_option "${options[@]}"
    choice=$?

    case $choice in
        0) export FS="btrfs";;
        1) export FS="ext4";;
        2)
            set_password "LUKS_PASSWORD"
            export FS="luks"
            ;;
        3) 
            printf "%b\n" "Exiting..."
            exit 0 
            ;;
        *) 
            printf "%b\n" "Wrong option please select again"
            filesystem
            ;;
    esac
}

# Timezone detection and selection
timezone() {
    if ! time_zone=$(curl --fail --silent https://ipapi.co/timezone); then
        printf "%b\n" "Error: Could not detect timezone automatically"
        printf "Please enter your timezone (e.g., Europe/London): "
        read -r time_zone
    else
        printf "%b\n" "System detected your timezone to be '$time_zone'"
        printf "%b\n" "Is this correct?"
        
        options=("Yes" "No")
        select_option "${options[@]}"
        choice=$?

        case $choice in
            0)
                printf "%b\n" "${time_zone} set as timezone"
                ;;
            1)
                printf "Please enter your timezone (e.g., Europe/London): "
                read -r time_zone
                ;;
            *)
                printf "%b\n" "Wrong option. Try again"
                timezone
                return
                ;;
        esac
    fi

    # Verify timezone exists
    if [ ! -f "/usr/share/zoneinfo/${time_zone}" ]; then
        printf "%b\n" "Error: Invalid timezone '${time_zone}'"
        timezone
        return
    fi

    export TIMEZONE="${time_zone}"
}

# Keyboard layout selection
keymap() {
    printf "%b\n" "Please select keyboard layout from this list"
    
    options=(
        "us" "by" "ca" "cf" "cz" "de" "dk" "es" "et" "fa" 
        "fi" "fr" "gr" "hu" "il" "it" "lt" "lv" "mk" "nl" 
        "no" "pl" "ro" "ru" "se" "sg" "ua" "uk"
    )
    
    select_option "${options[@]}"
    selected_keymap=${options[$?]}

    # Verify keymap exists
    if ! localectl list-keymaps | grep -q "^${selected_keymap}$"; then
        printf "%b\n" "Error: Invalid keymap '${selected_keymap}'"
        keymap
        return
    fi

    printf "%b\n" "Your keyboard layout: ${selected_keymap}"
    export KEYMAP="${selected_keymap}"
}

# Drive type detection
drivessd() {
    local rotational_file="/sys/block/${DISK##*/}/queue/rotational"
    
    # Automatically detect if the drive is an SSD
    if [ -f "$rotational_file" ]; then
        if [ "$(cat "$rotational_file")" -eq 0 ]; then
            printf "%b\n" "SSD detected automatically"
            export MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120"
            return
        fi
    fi

    # If automatic detection fails, ask user
    printf "%b\n" "Is this an SSD? (yes/no)"
    options=("Yes" "No")
    select_option "${options[@]}"
    choice=$?

    case $choice in
        0) export MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120";;
        1) export MOUNT_OPTIONS="noatime,compress=zstd,commit=120";;
        *) 
            printf "%b\n" "Wrong option. Try again"
            drivessd
            ;;
    esac
}

# Disk selection
diskpart() {
    printf "%b\n" "------------------------------------------------------------------------"
    printf "%b\n" "    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"
    printf "%b\n" "    Please make sure you know what you are doing because"
    printf "%b\n" "    after formatting your disk there is no way to get data back"
    printf "%b\n" "    *****BACKUP YOUR DATA BEFORE CONTINUING*****"
    printf "%b\n" "------------------------------------------------------------------------"

    # Get available disks
    mapfile -t available_disks < <(lsblk -dpnoNAME,SIZE,TYPE | grep 'disk' | awk '{print $1"|"$2}')
    
    if [ ${#available_disks[@]} -eq 0 ]; then
        printf "%b\n" "Error: No available disks found"
        exit 1
    fi

    printf "%b\n" "Available disks:"
    select_option "${available_disks[@]}"
    selected_disk=${available_disks[$?]%|*}

    if [ ! -b "$selected_disk" ]; then
        printf "%b\n" "Error: Invalid disk selection"
        exit 1
    fi

    printf "%b\n" "Selected disk: ${selected_disk}"
    export DISK="${selected_disk}"

    drivessd
}

# User information collection
userinfo() {
    local username password1 password2 hostname

    while true; do
        printf "Please enter username: "
        read -r username
        if printf "%s" "$username" | grep -q '^[a-z_][a-z0-9_-]*[$]?$'; then
            break
        fi
        printf "%b\n" "Error: Invalid username format. Username must start with a letter or underscore,"
        printf "%b\n" "followed by letters, numbers, dashes, or underscores."
    done
    export USERNAME="$username"

    while true; do
        printf "Please enter password: "
        read -rs password1
        printf "\n"
        printf "Please re-enter password: "
        read -rs password2
        printf "\n"
        if [ "$password1" = "$password2" ]; then
            break
        else
            printf "%b\n" "Error: Passwords do not match."
        fi
    done
    export PASSWORD="$password1"

    while true; do
        printf "Please name your machine: "
        read -r hostname
        if printf "%s" "$hostname" | grep -q '^[a-z][a-z0-9_.-]*[a-z0-9]$'; then
            break
        fi
        printf "Hostname doesn't seem correct. Do you still want to save it? (y/n): "
        read -r force
        if [ "${force,,}" = "y" ]; then
            break
        fi
    done
    export NAME_OF_MACHINE="$hostname"
}

# Mirror setup function
setup_mirrors() {
    printf "%b\n" "Setting up mirrors for optimal download..."
    
    if ! iso=$(curl -s4 ifconfig.co/country-iso); then
        printf "%b\n" "Warning: Could not detect country. Using default mirrors."
        return 1
    fi

    # Backup existing mirrorlist
    if [ -f /etc/pacman.d/mirrorlist ]; then
        cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    fi

    # Update system clock
    if ! timedatectl set-ntp true; then
        printf "%b\n" "Warning: Failed to set network time."
    fi

    # Install necessary packages
    if ! pacman -Sy --noconfirm archlinux-keyring; then
        printf "%b\n" "Error: Failed to update keyring."
        exit 1
    fi

    if ! pacman -S --noconfirm --needed reflector rsync grub gptfdisk btrfs-progs; then
        printf "%b\n" "Error: Failed to install necessary packages."
        exit 1
    fi

    # Generate mirrorlist
    printf "%b\n" "Generating mirror list for country: $iso"
    if ! reflector -a 48 -c "$iso" -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist; then
        printf "%b\n" "Warning: Failed to generate optimal mirror list."
        return 1
    fi
}

# Partition preparation function
prepare_disk() {
    printf "%b\n" "-------------------------------------------------------------------------"
    printf "%b\n" "                    Formatting Disk"
    printf "%b\n" "-------------------------------------------------------------------------"

    # Unmount any existing mounts
    umount -R /mnt 2>/dev/null || true

    # Create mount point
    mkdir -p /mnt || {
        printf "%b\n" "Error: Failed to create mount point"
        exit 1
    }

    # Zap disk
    if ! sgdisk -Z "${DISK}"; then
        printf "%b\n" "Error: Failed to zap disk"
        exit 1
    }

    # Create new GPT table
    if ! sgdisk -a 2048 -o "${DISK}"; then
        printf "%b\n" "Error: Failed to create GPT table"
        exit 1
    }

    # Create partitions
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' "${DISK}" || exit 1  # BIOS boot partition
    sgdisk -n 2::+512M --typecode=2:ef00 --change-name=2:'EFIBOOT' "${DISK}" || exit 1 # EFI partition
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' "${DISK}" || exit 1       # Root partition

    # Set legacy boot flag if needed
    if [ ! -d /sys/firmware/efi ]; then
        sgdisk -A 1:set:2 "${DISK}" || exit 1
    fi

    # Inform kernel of partition table changes
    partprobe "${DISK}" || {
        printf "%b\n" "Error: Failed to inform kernel of partition changes"
        exit 1
    }

    # Set up partition variables
    case "${DISK}" in
        /dev/nvme*)
            partition2="${DISK}p2"
            partition3="${DISK}p3"
            ;;
        /dev/[sv]d*)
            partition2="${DISK}2"
            partition3="${DISK}3"
            ;;
        *)
            printf "%b\n" "Error: Unknown drive type: ${DISK}"
            exit 1
            ;;
    esac

    export PARTITION2="$partition2"
    export PARTITION3="$partition3"
}

# Main installation sequence
main() {
    background_checks
    clear
    logo
    userinfo
    clear
    logo
    diskpart
    clear
    logo
    filesystem
    clear
    logo
    timezone
    clear
    logo
    keymap
    clear
    logo
    
    setup_mirrors || printf "%b\n" "Warning: Mirror setup encountered issues"
    prepare_disk
}

# BTRFS subvolume creation function
createsubvolumes() {
    local subvolumes=("@" "@home" "@var" "@tmp" "@.snapshots")
    
    for subvolume in "${subvolumes[@]}"; do
        if ! btrfs subvolume create "/mnt/${subvolume}"; then
            printf "%b\n" "Error: Failed to create subvolume ${subvolume}"
            return 1
        fi
    done
    return 0
}

# Mount subvolumes function
mountallsubvol() {
    local subvols=(
        "home"
        "var"
        "tmp"
        ".snapshots"
    )
    
    for subvol in "${subvols[@]}"; do
        mkdir -p "/mnt/${subvol}"
        if ! mount -o "${MOUNT_OPTIONS},subvol=@${subvol}" "${PARTITION3}" "/mnt/${subvol}"; then
            printf "%b\n" "Error: Failed to mount @${subvol} subvolume"
            return 1
        fi
    done
    return 0
}

# Subvolume setup function
subvolumesetup() {
    if ! createsubvolumes; then
        printf "%b\n" "Error: Subvolume creation failed"
        exit 1
    fi

    # Unmount root to remount with subvolume
    if ! umount /mnt; then
        printf "%b\n" "Error: Failed to unmount /mnt"
        exit 1
    fi

    # Mount @ subvolume
    if ! mount -o "${MOUNT_OPTIONS},subvol=@" "${PARTITION3}" /mnt; then
        printf "%b\n" "Error: Failed to mount @ subvolume"
        exit 1
    fi

    # Create mount points
    local dirs=("home" "var" "tmp" ".snapshots")
    for dir in "${dirs[@]}"; do
        if ! mkdir -p "/mnt/${dir}"; then
            printf "%b\n" "Error: Failed to create directory /mnt/${dir}"
            exit 1
        fi
    done

    # Mount other subvolumes
    if ! mountallsubvol; then
        printf "%b\n" "Error: Failed to mount subvolumes"
        exit 1
    fi
}

# Format and mount filesystems
setup_filesystems() {
    printf "%b\n" "-------------------------------------------------------------------------"
    printf "%b\n" "                    Creating Filesystems"
    printf "%b\n" "-------------------------------------------------------------------------"

    # Format EFI partition
    if ! mkfs.fat -F32 "${PARTITION2}"; then
        printf "%b\n" "Error: Failed to format EFI partition"
        exit 1
    fi

    case "${FS}" in
        btrfs)
            if ! mkfs.btrfs -f "${PARTITION3}"; then
                printf "%b\n" "Error: Failed to format root partition"
                exit 1
            fi
            if ! mount -t btrfs "${PARTITION3}" /mnt; then
                printf "%b\n" "Error: Failed to mount root partition"
                exit 1
            fi
            subvolumesetup
            ;;
        ext4)
            if ! mkfs.ext4 -F "${PARTITION3}"; then
                printf "%b\n" "Error: Failed to format root partition"
                exit 1
            fi
            if ! mount -t ext4 "${PARTITION3}" /mnt; then
                printf "%b\n" "Error: Failed to mount root partition"
                exit 1
            fi
            ;;
        luks)
            printf "%b\n" "Setting up LUKS encryption..."
            if ! printf "%s" "${LUKS_PASSWORD}" | cryptsetup -q luksFormat "${PARTITION3}"; then
                printf "%b\n" "Error: Failed to encrypt partition"
                exit 1
            fi
            if ! printf "%s" "${LUKS_PASSWORD}" | cryptsetup open "${PARTITION3}" ROOT -; then
                printf "%b\n" "Error: Failed to open encrypted partition"
                exit 1
            fi
            if ! mkfs.btrfs -f /dev/mapper/ROOT; then
                printf "%b\n" "Error: Failed to format encrypted partition"
                exit 1
            fi
            if ! mount -t btrfs /dev/mapper/ROOT /mnt; then
                printf "%b\n" "Error: Failed to mount encrypted partition"
                exit 1
            fi
            subvolumesetup
            ENCRYPTED_PARTITION_UUID=$(blkid -s UUID -o value "${PARTITION3}")
            export ENCRYPTED_PARTITION_UUID
            ;;
        *)
            printf "%b\n" "Error: Invalid filesystem type"
            exit 1
            ;;
    esac

    # Create and mount EFI partition
    if ! mkdir -p /mnt/boot/efi; then
        printf "%b\n" "Error: Failed to create EFI directory"
        exit 1
    fi
    if ! mount "${PARTITION2}" /mnt/boot/efi; then
        printf "%b\n" "Error: Failed to mount EFI partition"
        exit 1
    fi

    # Verify mounts
    if ! mountpoint -q /mnt; then
        printf "%b\n" "Error: Root partition mount failed"
        exit 1
    fi
}

# Additional storage setup
setup_storage() {
    printf "%b\n" "-------------------------------------------------------------------------"
    printf "%b\n" "                    Additional Storage Setup"
    printf "%b\n" "-------------------------------------------------------------------------"

    # Get available drives excluding system drive
    mapfile -t available_drives < <(lsblk -dpnoNAME,SIZE,TYPE | grep -v "${DISK##*/}" | grep "disk" | awk '{print $1"|"$2}')
    
    if [ ${#available_drives[@]} -eq 0 ]; then
        printf "%b\n" "No additional drives found for storage setup"
        return 0
    fi

    printf "%b\n" "Available drives for storage:"
    select_option "${available_drives[@]}"
    storage_disk=${available_drives[$?]%|*}

    # Prepare storage disk
    if ! sgdisk -Z "${storage_disk}"; then
        printf "%b\n" "Error: Failed to zap storage disk"
        return 1
    fi
    if ! sgdisk -n 1::0 -t 1:8300 "${storage_disk}"; then
        printf "%b\n" "Error: Failed to create storage partition"
        return 1
    fi

    # Get partition name
    case "${storage_disk}" in
        /dev/nvme*)
            storage_part="${storage_disk}p1"
            ;;
        /dev/[sv]d*)
            storage_part="${storage_disk}1"
            ;;
        *)
            printf "%b\n" "Error: Unknown storage drive type"
            return 1
            ;;
    esac

    # Check if SSD
    if [ -f "/sys/block/${storage_disk##*/}/queue/rotational" ] && 
       [ "$(cat "/sys/block/${storage_disk##*/}/queue/rotational")" -eq 0 ]; then
        storage_options="noatime,compress=zstd,ssd,commit=120"
    else
        storage_options="noatime,compress=zstd,commit=120"
    fi

    # Format and mount
    if ! mkfs.btrfs -f "${storage_part}"; then
        printf "%b\n" "Error: Failed to format storage partition"
        return 1
    fi

    STORAGE_UUID=$(blkid -s UUID -o value "${storage_part}")
    
    # Create mount points and directories
    if ! mkdir -p "/mnt/home/${USERNAME}/Storage"; then
        printf "%b\n" "Error: Failed to create storage mount point"
        return 1
    fi
    
    if ! mount "${storage_part}" "/mnt/home/${USERNAME}/Storage"; then
        printf "%b\n" "Error: Failed to mount storage partition"
        return 1
    fi

    local user_dirs=("Documents" "Downloads" "Pictures" "Videos")
    for dir in "${user_dirs[@]}"; do
        if ! mkdir -p "/mnt/home/${USERNAME}/Storage/${dir}"; then
            printf "%b\n" "Error: Failed to create ${dir} directory"
            return 1
        fi
    done

    # Add to fstab
    printf "UUID=%s /home/%s/Storage btrfs %s 0 2\n" \
        "${STORAGE_UUID}" "${USERNAME}" "${storage_options}" >> /mnt/etc/fstab

    # Create symlinks after chroot
    return 0
}

# Install base system packages
install_base_system() {
    printf "%b\n" "-------------------------------------------------------------------------"
    printf "%b\n" "                    Installing Base System"
    printf "%b\n" "-------------------------------------------------------------------------"

    # Detect CPU vendor for microcode
    CPU_VENDOR=$(grep -m1 "vendor_id" /proc/cpuinfo | cut -d: -f2 | tr -d ' ')
    case "$CPU_VENDOR" in
        "GenuineIntel") MICROCODE="intel-ucode" ;;
        "AuthenticAMD") MICROCODE="amd-ucode" ;;
        *) MICROCODE="" ;;
    esac

    # Base package list
    local base_packages=(
        "base" "base-devel" "linux" "linux-firmware" "linux-headers"
        "xorg" "xorg-server" "xorg-xinit" "xorg-xrandr" "xorg-xsetroot"
        "noto-fonts" "noto-fonts-emoji" "noto-fonts-cjk" 
        "ttf-meslo-nerd" "ttf-nerd-fonts-symbols"
        "ttf-jetbrains-mono" "ttf-font-awesome" "rofi-emoji"
        "libx11" "libxft" "libxinerama" "libxcb" "imlib2"
        "networkmanager" "network-manager-applet" "rofi"
        "bc" "jq" "sof-firmware" "timeshift" "rofi-calc"
        "grub" "efibootmgr" "dosfstools" "os-prober" "mtools"
        "git" "vim" "nano" "unzip" "flameshot" 
        "lxappearance" "feh" "mate-polkit" "dunst"
        "meson" "libev" "uthash" "libconfig" "dmenu"
    )

    # Add microcode if detected
    if [ -n "$MICROCODE" ]; then
        base_packages+=("$MICROCODE")
    fi

    # Install packages
    if ! pacstrap -K /mnt "${base_packages[@]}" --noconfirm --needed; then
        printf "%b\n" "Error: Failed to install base packages"
        return 1
    fi

    return 0
}

# Generate and configure fstab
setup_fstab() {
    printf "%b\n" "Generating fstab..."
    
    # Get UUIDs
    local root_uuid
    local boot_uuid
    
    if [ "${FS}" = "luks" ]; then
        root_uuid=$(blkid -s UUID -o value /dev/mapper/ROOT)
    else
        root_uuid=$(blkid -s UUID -o value "${PARTITION3}")
    fi
    boot_uuid=$(blkid -s UUID -o value "${PARTITION2}")

    # Create fstab header
    cat > /mnt/etc/fstab << EOF
# Static information about the filesystems
# <file system>        <dir>        <type>        <options>                <dump> <pass>
UUID=${boot_uuid}      /boot/efi    vfat          defaults                0      2
EOF

    # Add root partition
    if [ "${FS}" = "luks" ]; then
        printf "UUID=%s      /            btrfs         %s                0      1\n" \
            "$root_uuid" "${MOUNT_OPTIONS}" >> /mnt/etc/fstab
    else
        printf "UUID=%s      /            %s         %s                0      1\n" \
            "$root_uuid" "${FS}" "${MOUNT_OPTIONS}" >> /mnt/etc/fstab
    fi

    # Add subvolumes if using btrfs
    if [ "${FS}" = "btrfs" ] || [ "${FS}" = "luks" ]; then
        local subvols=("home" "var" "tmp" ".snapshots")
        for subvol in "${subvols[@]}"; do
            printf "UUID=%s      /%s        btrfs         %s,subvol=@%s     0      2\n" \
                "$root_uuid" "${subvol}" "${MOUNT_OPTIONS}" "${subvol}" >> /mnt/etc/fstab
        done
    fi
}

# Initial system configuration
configure_system() {
    printf "%b\n" "Configuring base system..."

    # Basic configuration using arch-chroot
    arch-chroot /mnt /bin/bash -c "$(cat << EOF
    # Set timezone
    ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime || exit 1
    hwclock --systohc || exit 1

    # Set locale
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen || exit 1
    locale-gen || exit 1
    echo "LANG=en_US.UTF-8" > /etc/locale.conf || exit 1

    # Set keymap
    echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf || exit 1

    # Set hostname
    echo "${NAME_OF_MACHINE}" > /etc/hostname || exit 1

    # Set hosts file
    cat > /etc/hosts << HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${NAME_OF_MACHINE}.localdomain ${NAME_OF_MACHINE}
HOSTS

    # Configure pacman
    sed -i 's/^#Color/Color/' /etc/pacman.conf
    sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
    sed -i '/^#VerbosePkgLists/a ILoveCandy' /etc/pacman.conf
    sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

    # Update package database
    pacman -Sy || exit 1

    # Create user and set permissions
    useradd -m -G wheel -s /bin/bash ${USERNAME} || exit 1
    printf "%s\\n%s" "${PASSWORD}" "${PASSWORD}" | passwd ${USERNAME} || exit 1
    printf "%s\\n%s" "${PASSWORD}" "${PASSWORD}" | passwd root || exit 1
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers || exit 1

    # Create necessary directories
    mkdir -p /home/${USERNAME}/.config || exit 1
    mkdir -p /home/${USERNAME}/.local/share || exit 1
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} || exit 1
EOF
)"
}

# Install and configure yay
install_yay() {
    printf "%b\n" "Installing yay AUR helper..."
    
    arch-chroot /mnt /bin/bash -c "$(cat << EOF
    cd /opt || exit 1
    git clone https://aur.archlinux.org/yay-bin.git || exit 1
    chown -R ${USERNAME}:${USERNAME} ./yay-bin || exit 1
    cd yay-bin || exit 1
    sudo -u ${USERNAME} makepkg -si --noconfirm || exit 1
    cd .. && rm -rf yay-bin || exit 1

    # Configure yay for the user
    sudo -u ${USERNAME} bash -c 'yay --save --answerclean All --answerdiff None --answeredit None' || exit 1
EOF
)"
}

# Install and configure FT-Labs picom
install_picom() {
    printf "%b\n" "Installing FT-Labs picom..."
    
    arch-chroot /mnt /bin/bash -c "$(cat << EOF
    # Install build dependencies
    pacman -S --needed --noconfirm meson ninja gcc cmake || exit 1
    
    # Clone and build picom
    cd /home/${USERNAME} || exit 1
    sudo -u ${USERNAME} git clone https://github.com/FT-Labs/picom.git || exit 1
    cd picom || exit 1
    
    # Build and install
    sudo -u ${USERNAME} meson --buildtype=release build || exit 1
    sudo -u ${USERNAME} ninja -C build || exit 1
    ninja -C build install || exit 1
    
    # Cleanup
    cd .. && rm -rf picom || exit 1
EOF
)"
}

# Install and configure DWM
install_dwm() {
    printf "%b\n" "Installing DWM..."
    
    arch-chroot /mnt /bin/bash -c "$(cat << EOF
    # Install DWM dependencies
    pacman -S --needed --noconfirm base-devel libx11 libxinerama libxft imlib2 || exit 1
    
    # Clone DWM repository
    cd /opt || exit 1
    git clone https://github.com/fam007e/DWM.git || exit 1
    chown -R ${USERNAME}:${USERNAME} ./DWM || exit 1
    
    # Build and install DWM
    cd DWM || exit 1
    make clean install || exit 1
    
    # Create xinitrc
    cat > /home/${USERNAME}/.xinitrc << 'XINITRC'
#!/bin/sh

# Start DWM
exec dwm
XINITRC

    chmod +x /home/${USERNAME}/.xinitrc || exit 1
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.xinitrc || exit 1
EOF
)"
}

# Setup NVIDIA drivers if needed
setup_nvidia() {
    printf "%b\n" "Checking for NVIDIA GPU..."
    
    arch-chroot /mnt /bin/bash -c "$(cat << EOF
    if lspci | grep -i nvidia > /dev/null; then
        # Detect GPU model
        model=\$(lspci -k | grep -A 2 -E "(VGA|3D)" | grep NVIDIA | sed 's/.*Corporation //;s/ .*//' | cut -c 1-2)
        
        # Install dependencies
        pacman -S --noconfirm --needed base-devel dkms nvidia-utils nvidia-settings || exit 1
        
        # Install appropriate driver based on GPU model
        case "\$model" in
            GM|GP|GV)
                printf "%b\n" "Installing NVIDIA proprietary DKMS driver for older GPU..."
                pacman -S --noconfirm --needed nvidia-dkms || exit 1
                ;;
            TU|GA|AD)
                printf "%b\n" "Installing NVIDIA open source DKMS driver for newer GPU..."
                pacman -S --noconfirm --needed nvidia-open-dkms || exit 1
                ;;
            *)
                printf "%b\n" "Installing default NVIDIA DKMS driver..."
                pacman -S --noconfirm --needed nvidia-dkms || exit 1
                ;;
        esac
        
        # Check for Intel CPU IBT settings
        if grep -q "model name" /proc/cpuinfo | grep -q "11th\|12th\|13th\|14th"; then
            sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="ibt=off /' /etc/default/grub
        fi
        
        # Add NVIDIA kernel parameters
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia.NVreg_PreserveVideoMemoryAllocations=1 /' /etc/default/grub
        
        # Create Xorg configuration
        mkdir -p /etc/X11/xorg.conf.d
        cat > /etc/X11/xorg.conf.d/10-nvidia.conf << NVIDIA
Section "Device"
    Identifier "NVIDIA Card"
    Driver     "nvidia"
    Option     "NoLogo" "true"
    Option     "UseEDID" "false"
    Option     "ConnectedMonitor" "DFP"
EndSection
NVIDIA
        
        # Enable NVIDIA services
        systemctl enable nvidia-suspend.service
        systemctl enable nvidia-hibernate.service
        systemctl enable nvidia-resume.service
        
        # Setup hardware acceleration
        pacman -S --noconfirm --needed libva-nvidia-driver || exit 1
        
        # Configure environment variables
        echo "LIBVA_DRIVER_NAME=nvidia" >> /etc/environment
        echo "MOZ_DISABLE_RDD_SANDBOX=1" >> /etc/environment
        
        # Update GRUB
        grub-mkconfig -o /boot/grub/grub.cfg || exit 1
    fi
EOF
)"
}

# Final system configuration
final_configuration() {
    printf "%b\n" "Performing final system configuration..."
    
    arch-chroot /mnt /bin/bash -c "$(cat << EOF
    # Enable essential services
    systemctl enable NetworkManager || exit 1
    systemctl enable fstrim.timer || exit 1
    
    # Install SDDM and dependencies
    pacman -S --noconfirm --needed \
        sddm gst-libav phonon-qt5-gstreamer gst-plugins-good \
        qt5-quickcontrols qt5-graphicaleffects qt5-multimedia || exit 1

    # Enable SDDM
    systemctl enable sddm

    # Install SDDM theme
    cd /tmp
    git clone https://github.com/3ximus/aerial-sddm-theme.git
    mv aerial-sddm-theme /usr/share/sddm/themes/
    
    # Configure SDDM
    cat > /etc/sddm.conf << SDDMCONF
[Theme]
Current=aerial-sddm-theme
SDDMCONF

    # Generate initramfs
    mkinitcpio -P || exit 1
    
    # Install and configure GRUB
    if [ -d /sys/firmware/efi ]; then
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB || exit 1
    else
        grub-install --target=i386-pc ${DISK} || exit 1
    fi
    
    # Configure GRUB
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash"/' /etc/default/grub
    
    # Add LUKS support if needed
    if [ "${FS}" = "luks" ]; then
        sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"\"/GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:ROOT root=\/dev\/mapper\/ROOT\"/" /etc/default/grub
    fi

    # Install GRUB theme
    THEME_DIR="/boot/grub/themes/Cyberpunk"
    mkdir -p "\${THEME_DIR}"
    cd "\${THEME_DIR}" || exit 1
    git init
    git remote add -f origin https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes.git
    git config core.sparseCheckout true
    echo "themes/Cyberpunk/*" >> .git/info/sparse-checkout
    git pull origin main
    mv themes/Cyberpunk/* .
    rm -rf themes
    rm -rf .git

    # Apply GRUB theme
    grep "GRUB_THEME=" /etc/default/grub && sed -i '/GRUB_THEME=/d' /etc/default/grub
    echo "GRUB_THEME=\"\${THEME_DIR}/theme.txt\"" >> /etc/default/grub
    
    # Generate GRUB config
    grub-mkconfig -o /boot/grub/grub.cfg || exit 1

    # Set up firmware if system has less than 8GB RAM
    TOTAL_MEM=\$(awk '/MemTotal/ {print \$2}' /proc/meminfo)   
    if [ "\$TOTAL_MEM" -lt 8000000 ]; then
        mkdir -p /opt/swap
        if findmnt -n -o FSTYPE / | grep -q btrfs; then
            chattr +C /opt/swap
        fi
        dd if=/dev/zero of=/opt/swap/swapfile bs=1M count=2048 status=progress
        chmod 600 /opt/swap/swapfile
        chown root /opt/swap/swapfile
        mkswap /opt/swap/swapfile   
        swapon /opt/swap/swapfile
        echo "/opt/swap/swapfile   none    swap    sw  0   0" >> /etc/fstab
    fi
EOF
)"
}

# Main installation function
install_system() {
    install_base_system || exit 1
    setup_fstab || exit 1
    configure_system || exit 1
    install_yay || exit 1
    install_picom || exit 1
    install_dwm || exit 1
    setup_nvidia || exit 1
    final_configuration || exit 1
    
    printf "%b\n" "-------------------------------------------------------------------------"
    printf "%b\n" "                    Installation Complete!"
    printf "%b\n" "-------------------------------------------------------------------------"
    printf "%b\n" "The system will now reboot in 5 seconds..."
    
    for i in 5 4 3 2 1; do
        printf "%d...\n" "$i"
        sleep 1
    done
    
    # Unmount all partitions
    umount -R /mnt
    
    # Reboot
    reboot
}