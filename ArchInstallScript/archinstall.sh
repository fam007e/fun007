#!/bin/bash

# Redirect stdout and stderr to archsetup.txt and still output to console
exec > >(tee -i archsetup.txt)
exec 2>&1

printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
    _____                .__      .___                 __         .__  .__      _________            .__        __
   /  _  \_______   ____ |  |__   |   | ____   _______/  |______  |  | |  |    /   _____/ ___________|__|______/  |
  /  /_\  \_  __ \_/ ___\|  |  \  |   |/    \ /  ___/\   __\__  \ |  | |  |    \_____  \_/ ___\_  __ \  \____ \   __\
 /    |    \  | \/\  \___|   Y  \ |   |   |  \\___ \  |  |  / __ \|  |_|  |__  /        \  \___|  | \/  |  |_> >  |
 \____|__  /__|    \___  >___|  / |___|___|  /____  > |__| (____  /____/____/ /_______  /\___  >__|  |__|   __/|__|
         \/            \/     \/           \/     \/            \/                    \/     \/         |__|
----------------------------------------------------------------------------------------------------------------------
                                        Automated Arch Linux Installer
----------------------------------------------------------------------------------------------------------------------

Verifying Arch Linux ISO is Booted
"

if [ ! -f /usr/bin/pacstrap ]; then
    printf "%b\n" "This script must be run from an Arch Linux ISO environment."
    exit 1
fi

root_check() {
    if [ "$(id -u)" != "0" ]; then
        printf "%b\n" "ERROR! This script must be run under the 'root' user!"
        exit 0
    fi
}

docker_check() {
    if awk -F/ '$2 == "docker"' /proc/self/cgroup | read -r; then
        printf "%b\n" "ERROR! Docker container is not supported (at the moment)"
        exit 0
    elif [ -f /.dockerenv ]; then
        printf "%b\n" "ERROR! Docker container is not supported (at the moment)"
        exit 0
    fi
}

arch_check() {
    if [ ! -e /etc/arch-release ]; then
        printf "%b\n" "ERROR! This script must be run in Arch Linux!"
        exit 0
    fi
}

pacman_check() {
    if [ -f /var/lib/pacman/db.lck ]; then
        printf "%b\n" "ERROR! Pacman is blocked."
        printf "%b\n" "If not running remove /var/lib/pacman/db.lck."
        exit 0
    fi
}

background_checks() {
    root_check
    arch_check
    pacman_check
    docker_check
}

select_option() {
    local options="$@"
    local num_options=$(echo "$options" | wc -w)
    local selected=0
    local last_selected=-1

    while true; do
        if [ $last_selected -ne -1 ]; then
            printf "\033[%sA" "$num_options"
        fi

        if [ $last_selected -eq -1 ]; then
            printf "%b\n" "Please select an option using the arrow keys and Enter:"
        fi
        i=0
        for option in $options; do
            if [ $i -eq $selected ]; then
                printf "> %s\n" "$option"
            else
                printf "  %s\n" "$option"
            fi
            i=$((i + 1))
        done

        last_selected=$selected

        read -r -n1 key
        case $key in
            A) # Up arrow
                selected=$((selected - 1))
                if [ $selected -lt 0 ]; then
                    selected=$((num_options - 1))
                fi
                ;;
            B) # Down arrow
                selected=$((selected + 1))
                if [ $selected -ge $num_options ]; then
                    selected=0
                fi
                ;;
            '') # Enter key
                break
                ;;
        esac
    done

    return $selected
}

logo() {
    printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
    _____                .__      .___                 __         .__  .__      _________            .__        __
   /  _  \_______   ____ |  |__   |   | ____   _______/  |______  |  | |  |    /   _____/ ___________|__|______/  |
  /  /_\  \_  __ \_/ ___\|  |  \  |   |/    \ /  ___/\   __\__  \ |  | |  |    \_____  \_/ ___\_  __ \  \____ \   __\
 /    |    \  | \/\  \___|   Y  \ |   |   |  \\___ \  |  |  / __ \|  |_|  |__  /        \  \___|  | \/  |  |_> >  |
 \____|__  /__|    \___  >___|  / |___|___|  /____  > |__| (____  /____/____/ /_______  /\___  >__|  |__|   __/|__|
         \/            \/     \/           \/     \/            \/                    \/     \/         |__|
----------------------------------------------------------------------------------------------------------------------
                                Please select presetup settings for your system              
----------------------------------------------------------------------------------------------------------------------
"
}

filesystem() {
    printf "%b\n" "
    Please Select your file system for both boot and root
    "
    options="btrfs ext4 luks exit"
    select_option $options

    case $? in
    0) FS=btrfs;;
    1) FS=ext4;;
    2) 
        set_password "LUKS_PASSWORD"
        FS=luks
        ;;
    3) exit ;;
    *) printf "%b\n" "Wrong option please select again"; filesystem;;
    esac

    if [ -n "$SECONDARY_DISK" ]; then
        printf "%b\n" "
        Formatting secondary disk with the same filesystem...
        "
        case $FS in
            btrfs) mkfs.btrfs -L DATA "$SECONDARY_DISK" -f ;;
            ext4) mkfs.ext4 -L DATA "$SECONDARY_DISK" ;;
            luks) 
                printf "%s" "$LUKS_PASSWORD" | cryptsetup -y -v luksFormat "$SECONDARY_DISK" -
                printf "%s" "$LUKS_PASSWORD" | cryptsetup open "$SECONDARY_DISK" DATA -
                mkfs.btrfs -L DATA /dev/mapper/DATA
                ;;
        esac
    fi
}

timezone() {
    time_zone="$(curl --fail https://ipapi.co/timezone)"
    printf "%b\n" "
    System detected your timezone to be '$time_zone'"
    printf "%b\n" "Is this correct?"
    options="Yes No"
    select_option $options

    case $? in
        0)
        printf "%b\n" "${time_zone} set as timezone"
        TIMEZONE=$time_zone;;
        1)
        printf "Please enter your desired timezone e.g. Europe/London: "
        read -r new_timezone
        printf "%b\n" "${new_timezone} set as timezone"
        TIMEZONE=$new_timezone;;
        *) printf "%b\n" "Wrong option. Try again"; timezone;;
    esac
}

keymap() {
    printf "%b\n" "
    Please select keyboard layout from this list"
    options="us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru se sg ua uk"
    select_option $options
    keymap=${options[$?]}

    printf "%b\n" "Your keyboard layout: ${keymap}"
    KEYMAP=$keymap
}

drivessd() {
    printf "%b\n" "
    Is this an ssd? yes/no:
    "

    options="Yes No"
    select_option $options

    case $? in
        0) MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120";;
        1) MOUNT_OPTIONS="noatime,compress=zstd,commit=120";;
        *) printf "%b\n" "Wrong option. Try again"; drivessd;;
    esac
}

select_secondary_disk() {
    printf "%b\n" "
    Select the secondary disk (HDD) for user directories:
    "
    PS3='Select the disk: '
    options=$(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk" && $2!="'"${DISK#/dev/}"'" {print "/dev/"$2"|"$3}')
    select_option $options
    secondary_disk=${options[$?]%|*}
    SECONDARY_DISK=${secondary_disk%|*}
}

diskpart() {
    printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK                                
    Please make sure you know what you are doing because after formatting your disk there is no way to get data back
                                  *****BACKUP YOUR DATA BEFORE CONTINUING*****
                                  ***I AM NOT RESPONSIBLE FOR ANY DATA LOSS***
----------------------------------------------------------------------------------------------------------------------
"

    PS3='
    Select the disk to install on: '
    options=$(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}')

    select_option $options
    disk=${options[$?]%|*}

    printf "%b\n" "\n${disk%|*} selected \n"
    DISK=${disk%|*}

    printf "%b\n" "
    Do you want to use a secondary disk (HDD) for user directories?
    "
    options="Yes No"
    select_option $options
    case $? in
        0) 
            select_secondary_disk
            drivessd
            ;;
        1) 
            drivessd
            ;;
    esac
}

userinfo() {
    while true
    do 
            printf "Please enter username: "
            read -r username
            if printf "%s" "$username" | grep -qE '^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$'; then 
                    break
            fi 
            printf "%b\n" "Incorrect username."
    done 
    USERNAME=$username

    while true
    do
        printf "Please enter password: "
        stty -echo
        read -r PASSWORD1
        stty echo
        printf "\n"
        printf "Please re-enter password: "
        stty -echo
        read -r PASSWORD2
        stty echo
        printf "\n"
        if [ "$PASSWORD1" = "$PASSWORD2" ]; then
            break
        else
            printf "%b\n" "ERROR! Passwords do not match."
        fi
    done
    PASSWORD=$PASSWORD1

    while true
    do 
            printf "Please name your machine: "
            read -r name_of_machine
            if printf "%s" "$name_of_machine" | grep -qE '^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$'; then 
                    break 
            fi 
            printf "Hostname doesn't seem correct. Do you still want to save it? (y/n) "
            read -r force 
            if [ "$force" = "y" ]; then 
                    break 
            fi 
    done 
    NAME_OF_MACHINE=$name_of_machine
}

choose_kernel() {
    printf "%b\n" "
    Please select the kernel you want to install:
    "
    options="linux-lts linux"
    select_option $options
    case $? in
    0) KERNEL="linux-lts";;
    1) KERNEL="linux";;
    *) printf "%b\n" "Invalid option. Defaulting to linux-lts."; KERNEL="linux-lts";;
    esac
    printf "%b\n" "Selected kernel: $KERNEL"
}

# Starting functions
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
choose_kernel

printf "%b\n" "Setting up mirrors for optimal download"
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -Syu --noconfirm archlinux-keyring #update keyrings to latest to prevent packages failing to install
pacman -S --noconfirm --needed pacman-contrib terminus-font
setfont ter-v18b
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm --needed reflector rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                    Setting up $iso mirrors for faster downloads
----------------------------------------------------------------------------------------------------------------------
"
reflector -a 48 -c "$iso" -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir -p /mnt
printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                            Installing Prerequisites
----------------------------------------------------------------------------------------------------------------------
"
pacman -S --noconfirm --needed gptfdisk btrfs-progs glibc
printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                                Formatting Disk
----------------------------------------------------------------------------------------------------------------------
"
umount -A --recursive /mnt # make sure everything is unmounted before we start
# disk prep
sgdisk -Z "$DISK" # zap all on disk
sgdisk -a 2048 -o "$DISK" # new gpt disk 2048 alignment

# create partitions
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' "$DISK" # partition 1 (BIOS Boot Partition)
sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' "$DISK" # partition 2 (UEFI Boot Partition)
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' "$DISK" # partition 3 (Root), default start, remaining
if [ ! -d "/sys/firmware/efi" ]; then # Checking for bios system
    sgdisk -A 1:set:2 "$DISK"
fi
partprobe "$DISK" # reread partition table to ensure it is correct

# make filesystems
printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                            Creating Filesystems
----------------------------------------------------------------------------------------------------------------------
"
createsubvolumes() {
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@tmp
    btrfs subvolume create /mnt/@.snapshots
}

mountallsubvol() {
    mount -o "$MOUNT_OPTIONS",subvol=@home "$partition3" /mnt/home
    mount -o "$MOUNT_OPTIONS",subvol=@tmp "$partition3" /mnt/tmp
    mount -o "$MOUNT_OPTIONS",subvol=@var "$partition3" /mnt/var
    mount -o "$MOUNT_OPTIONS",subvol=@.snapshots "$partition3" /mnt/.snapshots

    if [ -n "$SECONDARY_DISK" ]; then
        mkdir -p /mnt/mnt/data
        if [ "$FS" = "luks" ]; then
            mount -o "$MOUNT_OPTIONS" /dev/mapper/DATA /mnt/mnt/data
        else
            mount -o "$MOUNT_OPTIONS" "$SECONDARY_DISK" /mnt/mnt/data
        fi
        mkdir -p /mnt/mnt/data/{Downloads,Documents,Music,Pictures,Videos,Public}
    fi
}

subvolumesetup() {
    createsubvolumes
    umount /mnt
    mount -o "$MOUNT_OPTIONS",subvol=@ "$partition3" /mnt
    mkdir -p /mnt/{home,var,tmp,.snapshots}
    mountallsubvol
}

if echo "$DISK" | grep -q "nvme"; then
    partition2=${DISK}p2
    partition3=${DISK}p3
else
    partition2=${DISK}2
    partition3=${DISK}3
fi

if [ "$FS" = "btrfs" ]; then
    mkfs.vfat -F32 -n "EFIBOOT" "$partition2"
    mkfs.btrfs -L ROOT "$partition3" -f
    mount -t btrfs "$partition3" /mnt
    subvolumesetup
elif [ "$FS" = "ext4" ]; then
    mkfs.vfat -F32 -n "EFIBOOT" "$partition2"
    mkfs.ext4 -L ROOT "$partition3"
    mount -t ext4 "$partition3" /mnt
elif [ "$FS" = "luks" ]; then
    mkfs.vfat -F32 -n "EFIBOOT" "$partition2"
    printf "%s" "$LUKS_PASSWORD" | cryptsetup -y -v luksFormat "$partition3" -
    printf "%s" "$LUKS_PASSWORD" | cryptsetup open "$partition3" ROOT -
    mkfs.btrfs -L ROOT /dev/mapper/ROOT
    mount -t btrfs /dev/mapper/ROOT /mnt
    subvolumesetup
fi

sync
if ! mountpoint -q /mnt; then
    printf "%b\n" "ERROR! Failed to mount $partition3 to /mnt after multiple attempts."
    exit 1
fi
mkdir -p /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

if ! grep -qs '/mnt' /proc/mounts; then
    printf "%b\n" "Drive is not mounted can not continue"
    printf "%b\n" "Rebooting in 3 Seconds ..." && sleep 1
    printf "%b\n" "Rebooting in 2 Seconds ..." && sleep 1
    printf "%b\n" "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi
printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                            Arch Install on Main Drive
----------------------------------------------------------------------------------------------------------------------
"
if [ ! -d "/sys/firmware/efi" ]; then
    pacstrap /mnt base base-devel "$KERNEL" linux-firmware sof-firmware nano --noconfirm --needed
else
    pacstrap /mnt base base-devel "$KERNEL" linux-firmware sof-firmware nano efibootmgr --noconfirm --needed
fi

printf "%s\n" "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

genfstab -L /mnt >> /mnt/etc/fstab
printf "%b\n" " 
  Generated /etc/fstab:
"
cat /mnt/etc/fstab
printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                        GRUB BIOS Bootloader Install & Check                                    
----------------------------------------------------------------------------------------------------------------------
"
if [ ! -d "/sys/firmware/efi" ]; then
    grub-install --boot-directory=/mnt/boot "$DISK"
fi
printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                        Checking for low memory systems <8G
----------------------------------------------------------------------------------------------------------------------
"
TOTAL_MEM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
if [ "$TOTAL_MEM" -lt 8000000 ]; then
    mkdir -p /mnt/opt/swap
    if findmnt -n -o FSTYPE /mnt | grep -q btrfs; then
        chattr +C /mnt/opt/swap
    fi
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    printf "%s\n" "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab
fi

gpu_type=$(lspci | grep -E "VGA|3D|Display")

arch-chroot /mnt /bin/sh <<EOF
printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                                Network Setup 
----------------------------------------------------------------------------------------------------------------------
"
pacman -S --noconfirm --needed networkmanager dhclient
systemctl enable --now NetworkManager
printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                    Setting up mirrors for optimal download 
----------------------------------------------------------------------------------------------------------------------
"
pacman -S --noconfirm --needed pacman-contrib curl
pacman -S --noconfirm --needed reflector rsync grub arch-install-scripts git ntp wget
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

nc=$(grep -c ^processor /proc/cpuinfo)
printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                        You have " $nc" cores. And changing the makeflags for " $nc" cores. 
                                As well as changing the compression settings.
----------------------------------------------------------------------------------------------------------------------
"
TOTAL_MEM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
if [ "$TOTAL_MEM" -gt 8000000 ]; then
sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
fi
printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                        Setup Language to US and set locale  
----------------------------------------------------------------------------------------------------------------------
"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone ${TIMEZONE}
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
# Set keymaps
localectl --no-ask-password set-keymap ${KEYMAP}

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

#Add parallel downloading
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

#Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Syu --noconfirm --needed

printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                                Installing Microcode
----------------------------------------------------------------------------------------------------------------------
"
# determine processor type and install microcode
if grep -q "GenuineIntel" /proc/cpuinfo; then
    printf "%b\n" "Installing Intel microcode"
    pacman -S --noconfirm --needed intel-ucode
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    printf "%b\n" "Installing AMD microcode"
    pacman -S --noconfirm --needed amd-ucode
else
    printf "%b\n" "Unable to determine CPU vendor. Skipping microcode installation."
fi

printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                            Installing Graphics Drivers
----------------------------------------------------------------------------------------------------------------------
"
# Graphics Drivers find and install
if echo "${gpu_type}" | grep -E "NVIDIA|GeForce"; then
    if [ "${KERNEL}" = "linux-lts" ]; then
        printf "%b\n" "Installing NVIDIA drivers: nvidia-lts"
        pacman -S --noconfirm --needed nvidia-lts nvidia-settings cuda
    else
        printf "%b\n" "Installing NVIDIA drivers: nvidia-dkms"
        pacman -S --noconfirm --needed nvidia-dkms nvidia-settings cuda

        # Enable early KMS for NVIDIA
        printf "%b\n" "Configuring early KMS for NVIDIA..."

        # Add NVIDIA modules to initramfs configuration
        printf "%b\n" "Adding NVIDIA modules to /etc/mkinitcpio.conf..."
        sed -i '/^MODULES=/s/(/(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf

        # Regenerate the initramfs
        printf "%b\n" "Regenerating initramfs..."
        mkinitcpio -P

        # Enable persistent DRM (Direct Rendering Manager)
        printf "%b\n" "Enabling DRM modesetting for NVIDIA..."
        if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
            sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&nvidia-drm.modeset=1 /' /etc/default/grub
            grub-mkconfig -o /boot/grub/grub.cfg
        fi

        # Blacklist Nouveau driver (optional but recommended)
        printf "%b\n" "Blacklisting Nouveau driver..."
        cat > /etc/modprobe.d/blacklist-nouveau.conf << EOT
blacklist nouveau
options nouveau modeset=0
EOT

        # Rebuild initramfs again for the blacklisting to take effect
        mkinitcpio -P

        # Enable the nvidia-persistenced service
        printf "%b\n" "Enabling NVIDIA persistence daemon..."
        systemctl enable nvidia-persistenced.service
        systemctl start nvidia-persistenced.service

        # Install Vulkan packages for better performance (optional)
        printf "%b\n" "Installing Vulkan packages for enhanced performance..."
        pacman -S --noconfirm vulkan-icd-loader lib32-vulkan-icd-loader
        
        # Verify NVIDIA driver installation
        printf "%b\n" "Verifying NVIDIA driver installation..."
        nvidia-smi

        # Setup pacman hook for NVIDIA driver updates
        printf "%b\n" "Setting up pacman hook for NVIDIA driver updates..."

        # Create the pacman hook
        cat > /etc/pacman.d/hooks/nvidia.hook << EOT
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=linux

[Action]
Description=Updating NVIDIA module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case \$trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'
EOT
    fi
elif echo "${gpu_type}" | grep 'VGA' | grep -E "Radeon|AMD"; then
    printf "%b\n" "Installing AMD drivers: xf86-video-amdgpu"
    pacman -S --noconfirm --needed xf86-video-amdgpu
elif echo "${gpu_type}" | grep -E "Integrated Graphics Controller"; then
    printf "%b\n" "Installing Intel drivers:"
    pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
elif echo "${gpu_type}" | grep -E "Intel Corporation UHD"; then
    printf "%b\n" "Installing Intel UHD drivers:"
    pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
fi

printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                                    Adding User
----------------------------------------------------------------------------------------------------------------------
"
groupadd libvirt
useradd -m -G wheel,libvirt -s /bin/bash "$USERNAME"
printf "%b\n" "$USERNAME created, home directory created, added to wheel and libvirt group, default shell set to /bin/bash"
printf "%s\n" "$USERNAME:$PASSWORD" | chpasswd
printf "%b\n" "$USERNAME password set"
printf "%s\n" "$NAME_OF_MACHINE" > /etc/hostname

if [ "${FS}" = "luks" ]; then
    # Making sure to edit mkinitcpio conf if luks is selected
    # add encrypt in mkinitcpio.conf before filesystems in hooks
    sed -i 's/filesystems/encrypt filesystems/g' /etc/mkinitcpio.conf
    # making mkinitcpio with selected kernel
    mkinitcpio -p "${KERNEL}"
fi

if [ -n "$SECONDARY_DISK" ]; then
    printf "%b\n" "
# Mount points for secondary disk
/dev/mapper/DATA    /mnt/data    btrfs    ${MOUNT_OPTIONS}    0 0
/mnt/data/Downloads    /home/${USERNAME}/Downloads    none    bind    0 0
/mnt/data/Documents    /home/${USERNAME}/Documents    none    bind    0 0
/mnt/data/Music        /home/${USERNAME}/Music        none    bind    0 0
/mnt/data/Pictures     /home/${USERNAME}/Pictures     none    bind    0 0
/mnt/data/Videos       /home/${USERNAME}/Videos       none    bind    0 0
/mnt/data/Public       /home/${USERNAME}/Public       none    bind    0 0
" >> /etc/fstab

    # Create XDG user directories config
    mkdir -p "/home/${USERNAME}/.config"
    printf "%b\n" "
XDG_DESKTOP_DIR=\"\$HOME/Desktop\"
XDG_DOWNLOAD_DIR=\"\$HOME/Downloads\"
XDG_TEMPLATES_DIR=\"\$HOME/Videos\"
XDG_PUBLICSHARE_DIR=\"\$HOME/Public\"
XDG_DOCUMENTS_DIR=\"\$HOME/Documents\"
XDG_MUSIC_DIR=\"\$HOME/Music\"
XDG_PICTURES_DIR=\"\$HOME/Pictures\"
" > "/home/${USERNAME}/.config/user-dirs.dirs"
fi

printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
    _____                .__      .___                 __         .__  .__      _________            .__        __
   /  _  \_______   ____ |  |__   |   | ____   _______/  |______  |  | |  |    /   _____/ ___________|__|______/  |
  /  /_\  \_  __ \_/ ___\|  |  \  |   |/    \ /  ___/\   __\__  \ |  | |  |    \_____  \_/ ___\_  __ \  \____ \   __\
 /    |    \  | \/\  \___|   Y  \ |   |   |  \\___ \  |  |  / __ \|  |_|  |__  /        \  \___|  | \/  |  |_> >  |
 \____|__  /__|    \___  >___|  / |___|___|  /____  > |__| (____  /____/____/ /_______  /\___  >__|  |__|   __/|__|
         \/            \/     \/           \/     \/            \/                    \/     \/         |__|
----------------------------------------------------------------------------------------------------------------------
                                        Automated Arch Linux Installer
----------------------------------------------------------------------------------------------------------------------

Final Setup and Configurations
GRUB EFI Bootloader Install & Check
"

if [ -d "/sys/firmware/efi" ]; then
    grub-install --efi-directory=/boot "${DISK}"
fi

printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                        Creating (and Theming) Grub Boot Menu
----------------------------------------------------------------------------------------------------------------------
"
# set kernel parameter for decrypting the drive
if [ "${FS}" = "luks" ]; then
    sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub
fi
# set kernel parameter for adding splash screen
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash /' /etc/default/grub

printf "%b\n" "Installing CyberRe Grub theme..."
THEME_DIR="/boot/grub/themes/CyberRe"
printf "%b\n" "Creating the theme directory..."
mkdir -p "${THEME_DIR}"

# Clone the theme
cd "${THEME_DIR}" || exit
git init
git remote add -f origin https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes.git
git config core.sparseCheckout true
echo "themes/CyberRe/*" >> .git/info/sparse-checkout
git pull origin main
mv themes/CyberRe/* .
rm -rf themes
rm -rf .git

printf "%b\n" "CyberRe theme has been cloned to ${THEME_DIR}"
printf "%b\n" "Backing up Grub config..."
cp -an /etc/default/grub /etc/default/grub.bak
printf "%b\n" "Setting the theme as the default..."
grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub
printf "%s\n" "GRUB_THEME=\"${THEME_DIR}/theme.txt\"" >> /etc/default/grub
printf "%b\n" "Updating grub..."
grub-mkconfig -o /boot/grub/grub.cfg
printf "%b\n" "All set!"

printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                            Enabling Essential Services
----------------------------------------------------------------------------------------------------------------------
"
ntpd -qg
systemctl enable ntpd.service
printf "%b\n" "  NTP enabled"
systemctl disable dhcpcd.service
printf "%b\n" "  DHCP disabled"
systemctl stop dhcpcd.service
printf "%b\n" "  DHCP stopped"
systemctl enable NetworkManager.service
printf "%b\n" "  NetworkManager enabled"

printf "%b\n" "
----------------------------------------------------------------------------------------------------------------------
                                                    Cleaning
----------------------------------------------------------------------------------------------------------------------
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
EOF

# If using LUKS, add secondary disk to crypttab
if [ "${FS}" = "luks" ] && [ -n "$SECONDARY_DISK" ]; then
    SECONDARY_UUID=$(blkid -s UUID -o value "${SECONDARY_DISK}")
    printf "%s\n" "DATA UUID=${SECONDARY_UUID} none luks" >> /mnt/etc/crypttab
fi