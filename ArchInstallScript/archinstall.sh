#!/bin/bash

# Redirect stdout and stderr to archsetup.txt and still output to console
exec > >(tee -i archsetup.txt)
exec 2>&1

echo -ne "
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
    echo "This script must be run from an Arch Linux ISO environment."
    exit 1
fi

root_check() {
    if [[ "$(id -u)" != "0" ]]; then
        echo -ne "ERROR! This script must be run under the 'root' user!\n"
        exit 0
    fi
}

docker_check() {
    if awk -F/ '$2 == "docker"' /proc/self/cgroup | read -r; then
        echo -ne "ERROR! Docker container is not supported (at the moment)\n"
        exit 0
    elif [[ -f /.dockerenv ]]; then
        echo -ne "ERROR! Docker container is not supported (at the moment)\n"
        exit 0
    fi
}

arch_check() {
    if [[ ! -e /etc/arch-release ]]; then
        echo -ne "ERROR! This script must be run in Arch Linux!\n"
        exit 0
    fi
}

pacman_check() {
    if [[ -f /var/lib/pacman/db.lck ]]; then
        echo "ERROR! Pacman is blocked."
        echo -ne "If not running remove /var/lib/pacman/db.lck.\n"
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
    local options=("$@")
    local num_options=${#options[@]}
    local selected=0
    local last_selected=-1

    while true; do
        # Move cursor up to the start of the menu
        if [ $last_selected -ne -1 ]; then
            echo -ne "\033[${num_options}A"
        fi

        if [ $last_selected -eq -1 ]; then
            echo "Please select an option using the arrow keys and Enter:"
        fi
        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
                echo "> ${options[$i]}"
            else
                echo "  ${options[$i]}"
            fi
        done

        last_selected=$selected

        # Read user input
        read -rsn1 key
        case $key in
            $'\x1b') # ESC sequence
                read -rsn2 -t 0.1 key
                case $key in
                    '[A') # Up arrow
                        ((selected--))
                        if [ $selected -lt 0 ]; then
                            selected=$((num_options - 1))
                        fi
                        ;;
                    '[B') # Down arrow
                        ((selected++))
                        if [ $selected -ge $num_options ]; then
                            selected=0
                        fi
                        ;;
                esac
                ;;
            '') # Enter key
                break
                ;;
        esac
    done

    return $selected
}

# @description Displays Arch Linux Installer
# @noargs
logo () {
# This will be shown on every set as user is progressing
echo -ne "
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
# @description This function will handle file systems. At this movement we are handling only
# btrfs and ext4. Others will be added in future.
filesystem() {
    echo -ne "
    Please Select your file system for both boot and root
    "
    options=("btrfs" "ext4" "luks" "exit")
    select_option "${options[@]}"

    case $? in
    0) export FS=btrfs;;
    1) export FS=ext4;;
    2) 
        set_password "LUKS_PASSWORD"
        export FS=luks
        ;;
    3) exit ;;
    *) echo "Wrong option please select again"; filesystem;;
    esac

    if [[ -n $SECONDARY_DISK ]]; then
        echo -ne "
        Formatting secondary disk with the same filesystem...
        "
        case $FS in
            btrfs) mkfs.btrfs -L DATA ${SECONDARY_DISK} -f ;;
            ext4) mkfs.ext4 -L DATA ${SECONDARY_DISK} ;;
            luks) 
                echo -n "${LUKS_PASSWORD}" | cryptsetup -y -v luksFormat ${SECONDARY_DISK} -
                echo -n "${LUKS_PASSWORD}" | cryptsetup open ${SECONDARY_DISK} DATA -
                mkfs.btrfs -L DATA /dev/mapper/DATA
                ;;
        esac
    fi
}

# @description Detects and sets timezone. 
timezone () {
    # Added this from arch wiki https://wiki.archlinux.org/title/System_time
    time_zone="$(curl --fail https://ipapi.co/timezone)"
    echo -ne "
    System detected your timezone to be '$time_zone' \n"
    echo -ne "Is this correct?
    " 
    options=("Yes" "No")
    select_option "${options[@]}"

    case ${options[$?]} in
        y|Y|yes|Yes|YES)
        echo "${time_zone} set as timezone"
        export TIMEZONE=$time_zone;;
        n|N|no|NO|No)
        echo "Please enter your desired timezone e.g. Europe/London :" 
        read new_timezone
        echo "${new_timezone} set as timezone"
        export TIMEZONE=$new_timezone;;
        *) echo "Wrong option. Try again";timezone;;
    esac
}
# @description Set user's keyboard mapping. 
keymap () {
    echo -ne "
    Please select key board layout from this list"
    # These are default key maps as presented in official arch repo archinstall
    options=(us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru se sg ua uk)

    select_option "${options[@]}"
    keymap=${options[$?]}

    echo -ne "Your key boards layout: ${keymap} \n"
    export KEYMAP=$keymap
}

# @description Choose whether drive is SSD or not.
drivessd () {
    echo -ne "
    Is this an ssd? yes/no:
    "

    options=("Yes" "No")
    select_option "${options[@]}"

    case ${options[$?]} in
        y|Y|yes|Yes|YES)
        export MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120";;
        n|N|no|NO|No)
        export MOUNT_OPTIONS="noatime,compress=zstd,commit=120";;
        *) echo "Wrong option. Try again";drivessd;;
    esac
}

select_secondary_disk() {
    echo -ne "
    Select the secondary disk (HDD) for user directories:
    "
    PS3='Select the disk: '
    options=($(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk" && $2!="'${DISK#/dev/}'" {print "/dev/"$2"|"$3}'))
    select_option "${options[@]}"
    secondary_disk=${options[$?]%|*}
    export SECONDARY_DISK=${secondary_disk%|*}
}

# @description Disk selection for drive to be used with installation.
diskpart() {
    echo -ne "
----------------------------------------------------------------------------------------------------------------------
                                THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK                                
    Please make sure you know what you are doing because after formating your disk there is no way to get data back
                                  *****BACKUP YOUR DATA BEFORE CONTINUING*****
                                  ***I AM NOT RESPONSIBLE FOR ANY DATA LOSS***
----------------------------------------------------------------------------------------------------------------------
"

    PS3='
    Select the disk to install on: '
    options=($(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}'))

    select_option "${options[@]}"
    disk=${options[$?]%|*}

    echo -e "\n${disk%|*} selected \n"
    export DISK=${disk%|*}

    echo -ne "
    Do you want to use a secondary disk (HDD) for user directories?
    "
    options=("Yes" "No")
    select_option "${options[@]}"
    case ${options[$?]} in
        Yes) 
            select_secondary_disk
            drivessd
            ;;
        No) 
            drivessd
            ;;
    esac
}


# @description Gather username and password to be used for installation. 
userinfo () {
    # Loop through user input until the user gives a valid username
    while true
    do 
            read -p "Please enter username:" username
            if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]
            then 
                    break
            fi 
            echo "Incorrect username."
    done 
    export USERNAME=$username

    while true
    do
        read -rs -p "Please enter password: " PASSWORD1
        echo -ne "\n"
        read -rs -p "Please re-enter password: " PASSWORD2
        echo -ne "\n"
        if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
            break
        else
            echo -ne "ERROR! Passwords do not match. \n"
        fi
    done
    export PASSWORD=$PASSWORD1

     # Loop through user input until the user gives a valid hostname, but allow the user to force save 
    while true
    do 
            read -p "Please name your machine:" name_of_machine
            # hostname regex (!!couldn't find spec for computer name!!)
            if [[ "${name_of_machine,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]
            then 
                    break 
            fi 
            # if validation fails allow the user to force saving of the hostname
            read -p "Hostname doesn't seem correct. Do you still want to save it? (y/n)" force 
            if [[ "${force,,}" = "y" ]]
            then 
                    break 
            fi 
    done 
    export NAME_OF_MACHINE=$name_of_machine
}

choose_kernel() {
    echo -ne "
    Please select the kernel you want to install:
    "
    options=("linux-lts" "linux")
    select_option "${options[@]}"
    case $? in
    0) export KERNEL="linux-lts";;
    1) export KERNEL="linux";;
    *) echo "Invalid option. Defaulting to linux-lts."; export KERNEL="linux-lts";;
    esac
    echo "Selected kernel: $KERNEL"
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


echo "Setting up mirrors for optimal download"
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm archlinux-keyring #update keyrings to latest to prevent packages failing to install
pacman -S --noconfirm --needed pacman-contrib terminus-font
setfont ter-v18b
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm --needed reflector rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -ne "
----------------------------------------------------------------------------------------------------------------------
                                    Setting up $iso mirrors for faster downloads
----------------------------------------------------------------------------------------------------------------------
"
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
if [ ! -d "/mnt" ]; then
    mkdir /mnt
fi
echo -ne "
----------------------------------------------------------------------------------------------------------------------
                                            Installing Prerequisites
----------------------------------------------------------------------------------------------------------------------
"
pacman -S --noconfirm --needed gptfdisk btrfs-progs glibc
echo -ne "
----------------------------------------------------------------------------------------------------------------------
                                                Formating Disk
----------------------------------------------------------------------------------------------------------------------
"
umount -A --recursive /mnt # make sure everything is unmounted before we start
# disk prep
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# create partitions
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
    sgdisk -A 1:set:2 ${DISK}
fi
partprobe ${DISK} # reread partition table to ensure it is correct

# make filesystems
echo -ne "
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
    mount -o ${MOUNT_OPTIONS},subvol=@home ${partition3} /mnt/home
    mount -o ${MOUNT_OPTIONS},subvol=@tmp ${partition3} /mnt/tmp
    mount -o ${MOUNT_OPTIONS},subvol=@var ${partition3} /mnt/var
    mount -o ${MOUNT_OPTIONS},subvol=@.snapshots ${partition3} /mnt/.snapshots

    if [[ -n $SECONDARY_DISK ]]; then
        mkdir -p /mnt/mnt/data
        if [[ "${FS}" == "luks" ]]; then
            mount -o ${MOUNT_OPTIONS} /dev/mapper/DATA /mnt/mnt/data
        else
            mount -o ${MOUNT_OPTIONS} ${SECONDARY_DISK} /mnt/mnt/data
        fi
        mkdir -p /mnt/mnt/data/{Downloads,Documents,Music,Pictures,Videos,Public}
    fi
}

subvolumesetup() {
    createsubvolumes
    umount /mnt
    mount -o ${MOUNT_OPTIONS},subvol=@ ${partition3} /mnt
    mkdir -p /mnt/{home,var,tmp,.snapshots}
    mountallsubvol
}

if [[ "${DISK}" =~ "nvme" ]]; then
    partition2=${DISK}p2
    partition3=${DISK}p3
else
    partition2=${DISK}2
    partition3=${DISK}3
fi

if [[ "${FS}" == "btrfs" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
    mkfs.btrfs -L ROOT ${partition3} -f
    mount -t btrfs ${partition3} /mnt
    subvolumesetup
elif [[ "${FS}" == "ext4" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
    mkfs.ext4 -L ROOT ${partition3}
    mount -t ext4 ${partition3} /mnt
elif [[ "${FS}" == "luks" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
    echo -n "${LUKS_PASSWORD}" | cryptsetup -y -v luksFormat ${partition3} -
    echo -n "${LUKS_PASSWORD}" | cryptsetup open ${partition3} ROOT -
    mkfs.btrfs -L ROOT /dev/mapper/ROOT
    mount -t btrfs /dev/mapper/ROOT /mnt
    subvolumesetup
fi

sync
if ! mountpoint -q /mnt; then
    echo "ERROR! Failed to mount ${partition3} to /mnt after multiple attempts."
    exit 1
fi
mkdir -p /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted can not continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi
echo -ne "
----------------------------------------------------------------------------------------------------------------------
                                            Arch Install on Main Drive
----------------------------------------------------------------------------------------------------------------------
"
if [[ ! -d "/sys/firmware/efi" ]]; then
    pacstrap /mnt base base-devel ${KERNEL} linux-firmware sof-firmware nano --noconfirm --needed
else
    pacstrap /mnt base base-devel ${KERNEL} linux-firmware sof-firmware nano efibootmgr --noconfirm --needed
fi

echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

genfstab -L /mnt >> /mnt/etc/fstab
echo " 
  Generated /etc/fstab:
"
cat /mnt/etc/fstab
echo -ne "
----------------------------------------------------------------------------------------------------------------------
                                        GRUB BIOS Bootloader Install & Check                                    
----------------------------------------------------------------------------------------------------------------------
"
if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot ${DISK}
fi
echo -ne "
----------------------------------------------------------------------------------------------------------------------
                                        Checking for low memory systems <8G
----------------------------------------------------------------------------------------------------------------------
"
TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTAL_MEM -lt 8000000 ]]; then
    # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
    mkdir -p /mnt/opt/swap # make a dir that we can apply NOCOW to to make it btrfs-friendly.
    if findmnt -n -o FSTYPE /mnt | grep -q btrfs; then
        chattr +C /mnt/opt/swap # apply NOCOW, btrfs needs that.
    fi
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile # set permissions.
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    # The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the system itself.
    echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab # Add swap to fstab, so it KEEPS working after installation.
fi

gpu_type=$(lspci | grep -E "VGA|3D|Display")

arch-chroot /mnt /bin/bash <<EOF

echo -ne "
----------------------------------------------------------------------------------------------------------------------
                                                Network Setup 
----------------------------------------------------------------------------------------------------------------------
"
pacman -S --noconfirm --needed networkmanager dhclient
systemctl enable --now NetworkManager
echo -ne "
----------------------------------------------------------------------------------------------------------------------
                                    Setting up mirrors for optimal download 
----------------------------------------------------------------------------------------------------------------------
"
pacman -S --noconfirm --needed pacman-contrib curl
pacman -S --noconfirm --needed reflector rsync grub arch-install-scripts git ntp wget
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

nc=$(grep -c ^processor /proc/cpuinfo)
echo -ne "
----------------------------------------------------------------------------------------------------------------------
                        You have " $nc" cores. And changing the makeflags for " $nc" cores. 
                                As well as changing the compression settings.
----------------------------------------------------------------------------------------------------------------------
"
TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTAL_MEM -gt 8000000 ]]; then
sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
fi
echo -ne "
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
pacman -Sy --noconfirm --needed

echo -ne "
----------------------------------------------------------------------------------------------------------------------
                                                Installing Microcode
----------------------------------------------------------------------------------------------------------------------
"
# determine processor type and install microcode
if grep -q "GenuineIntel" /proc/cpuinfo; then
    echo "Installing Intel microcode"
    pacman -S --noconfirm --needed intel-ucode
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    echo "Installing AMD microcode"
    pacman -S --noconfirm --needed amd-ucode
else
    echo "Unable to determine CPU vendor. Skipping microcode installation."
fi

echo -ne "
----------------------------------------------------------------------------------------------------------------------
                                            Installing Graphics Drivers
----------------------------------------------------------------------------------------------------------------------
"
# Graphics Drivers find and install
if echo "${gpu_type}" | grep -E "NVIDIA|GeForce"; then
    if [[ "${KERNEL}" == "linux-lts" ]]; then
        echo "Installing NVIDIA drivers: nvidia-lts"
        pacman -S --noconfirm --needed nvidia-lts nvidia-settings cuda
    else
        echo "Installing NVIDIA drivers: nvidia-dkms"
        pacman -S --noconfirm --needed nvidia-dkms nvidia-settings cuda

        # Enable early KMS for NVIDIA
        echo "Configuring early KMS for NVIDIA..."

        # Add NVIDIA modules to initramfs configuration
        echo "Adding NVIDIA modules to /etc/mkinitcpio.conf..."
        sed -i '/^MODULES=/s/(/(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf

        # Regenerate the initramfs
        echo "Regenerating initramfs..."
        mkinitcpio -P

        # Enable persistent DRM (Direct Rendering Manager)
        echo "Enabling DRM modesetting for NVIDIA..."
        if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
            sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&nvidia-drm.modeset=1 /' /etc/default/grub
            grub-mkconfig -o /boot/grub/grub.cfg
        fi

        # Blacklist Nouveau driver (optional but recommended)
        echo "Blacklisting Nouveau driver..."
        cat > /etc/modprobe.d/blacklist-nouveau.conf << EOT
blacklist nouveau
options nouveau modeset=0
EOT

        # Rebuild initramfs again for the blacklisting to take effect
        mkinitcpio -P

        # Enable the nvidia-persistenced service
        echo "Enabling NVIDIA persistence daemon..."
        systemctl enable nvidia-persistenced.service
        systemctl start nvidia-persistenced.service

        # Install Vulkan packages for better performance (optional)
        echo "Installing Vulkan packages for enhanced performance..."
        pacman -S --noconfirm vulkan-icd-loader lib32-vulkan-icd-loader
        
        # Verify NVIDIA driver installation
        echo "Verifying NVIDIA driver installation..."
        nvidia-smi

        # Setup pacman hook for NVIDIA driver updates
        echo "Setting up pacman hook for NVIDIA driver updates..."

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
    echo "Installing AMD drivers: xf86-video-amdgpu"
    pacman -S --noconfirm --needed xf86-video-amdgpu
elif echo "${gpu_type}" | grep -E "Integrated Graphics Controller"; then
    echo "Installing Intel drivers:"
    pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
elif echo "${gpu_type}" | grep -E "Intel Corporation UHD"; then
    echo "Installing Intel UHD drivers:"
    pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
fi


echo -ne "
----------------------------------------------------------------------------------------------------------------------
                                                    Adding User
----------------------------------------------------------------------------------------------------------------------
"
groupadd libvirt
useradd -m -G wheel,libvirt -s /bin/bash $USERNAME 
echo "$USERNAME created, home directory created, added to wheel and libvirt group, default shell set to /bin/bash"
echo "$USERNAME:$PASSWORD" | chpasswd
echo "$USERNAME password set"
echo $NAME_OF_MACHINE > /etc/hostname

if [[ ${FS} == "luks" ]]; then
    # Making sure to edit mkinitcpio conf if luks is selected
    # add encrypt in mkinitcpio.conf before filesystems in hooks
    sed -i 's/filesystems/encrypt filesystems/g' /etc/mkinitcpio.conf
    # making mkinitcpio with selected kernel
    mkinitcpio -p ${KERNEL}
fi

if [[ -n $SECONDARY_DISK ]]; then
    echo "
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
    mkdir -p /home/${USERNAME}/.config
    echo "
XDG_DESKTOP_DIR=\"\$HOME/Desktop\"
XDG_DOWNLOAD_DIR=\"\$HOME/Downloads\"
XDG_TEMPLATES_DIR=\"\$HOME/Videos\"
XDG_PUBLICSHARE_DIR=\"\$HOME/Public\"
XDG_DOCUMENTS_DIR=\"\$HOME/Documents\"
XDG_MUSIC_DIR=\"\$HOME/Music\"
XDG_PICTURES_DIR=\"\$HOME/Pictures\"
" > /home/${USERNAME}/.config/user-dirs.dirs
fi

echo -ne "
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

if [[ -d "/sys/firmware/efi" ]]; then
    grub-install --efi-directory=/boot ${DISK}
fi

echo -ne "
----------------------------------------------------------------------------------------------------------------------
                                        Creating (and Theming) Grub Boot Menu
----------------------------------------------------------------------------------------------------------------------
"
# set kernel parameter for decrypting the drive
if [[ "${FS}" == "luks" ]]; then
sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub
fi
# set kernel parameter for adding splash screen
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash /' /etc/default/grub

echo -e "Installing CyberRe Grub theme..."
THEME_DIR="/boot/grub/themes/CyberRe"
echo -e "Creating the theme directory..."
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

echo "CyberRe theme has been cloned to ${THEME_DIR}"
echo -e "Backing up Grub config..."
cp -an /etc/default/grub /etc/default/grub.bak
echo -e "Setting the theme as the default..."
grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub
echo "GRUB_THEME=\"${THEME_DIR}/theme.txt\"" >> /etc/default/grub
echo -e "Updating grub..."
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "All set!"

echo -ne "
----------------------------------------------------------------------------------------------------------------------
                                            Enabling Essential Services
----------------------------------------------------------------------------------------------------------------------
"
ntpd -qg
systemctl enable ntpd.service
echo "  NTP enabled"
systemctl disable dhcpcd.service
echo "  DHCP disabled"
systemctl stop dhcpcd.service
echo "  DHCP stopped"
systemctl enable NetworkManager.service
echo "  NetworkManager enabled"

echo -ne "
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
if [[ "${FS}" == "luks" && -n $SECONDARY_DISK ]]; then
    SECONDARY_UUID=$(blkid -s UUID -o value ${SECONDARY_DISK})
    echo "DATA UUID=${SECONDARY_UUID} none luks" >> /mnt/etc/crypttab
fi
