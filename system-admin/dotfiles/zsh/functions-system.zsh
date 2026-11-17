# functions-system.zsh : distro info, service configs, network, DNS, mirrors, fastfetch

# fastfetch utils
ff-upd() {
    local src="${FASTFETCH_SRC:-$HOME/fastfetch}"
    cd "$src" || return

    output=$(git pull --rebase)

    # Check if the output indicates "Already up to date."
    if [[ $output == *"Already up to date."* ]]; then
        printf "Fastfetch is already up to date. No need to rebuild.\n"
        cd
    else
        cd "$src/build" || return

        # Remove all contents in the build directory
        rm -rf *

        # Rebuild and install Fastfetch
        cmake .. && cmake --build . --target package && sudo cmake --install . --prefix /usr/

        cd
    fi
}

# Finds and adds fastest mirror lists for pacman
httpsmirrors() {
    temp_mirrorlist=$(mktemp)  # Correctly create a temporary file

    # Generate the new mirrorlist
    rate-mirrors --allow-root --protocol https arch | awk "/^# FINISHED AT:/ {p=1} p" > "$temp_mirrorlist"

    # Check if the output is non-empty
    if [ -s "$temp_mirrorlist" ]; then
        # Attempt to update the mirrorlist with sudo
        if sudo tee /etc/pacman.d/mirrorlist < "$temp_mirrorlist" > /dev/null; then
            printf "Mirrorlist updated successfully.\n"
        else
            printf "Failed to update mirrorlist due to sudo error.\n"
        fi
    else
        printf "Failed to generate new mirrorlist. Retaining the previous list.\n"
    fi

    rm -f "$temp_mirrorlist"  # Always remove the temporary file
}

# Show the installation date of the system
install_date() {
  install_date=$(sudo btrfs subvolume show / | grep "Creation time" | awk -F": " '{print $2}' | xargs)
  printf "Your Arch Linux OS was installed on %s.\n" "$install_date"
}

# IP address lookup
function whatsmyip ()
{
    # Internal IP Lookup.
    if [ -e /usr/bin/ip ]; then
        printf "Internal IP: "
        /usr/bin/ip addr show wlp0s20f3 | grep "inet " | awk -F: '{print $1}' | awk '{print $2}'
    else
        printf "Internal IP: "
        /usr/bin/ifconfig wlp0s20f3 | grep "inet " | awk -F: '{print $1} |' | awk '{print $2}'
    fi

    # External IP Lookup
    printf "External IP: "
    printf "%s\n" "$(curl -s ifconfig.me)"
}

# Show the current distribution
distribution ()
{
    local dtype="unknown"  # Default to unknown

    # Use /etc/os-release for modern distro identification
    if [ -r /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            fedora|rhel|centos)
                dtype="redhat"
                ;;
            sles|opensuse*)
                dtype="suse"
                ;;
            ubuntu|debian)
                dtype="debian"
                ;;
            gentoo)
                dtype="gentoo"
                ;;
            arch)
                dtype="arch"
                ;;
            slackware)
                dtype="slackware"
                ;;
            *)
                # If ID is not recognized, keep dtype as unknown
                ;;
        esac
    fi

    printf "%s\n" "$dtype"
}

# Show the current version of the operating system
ver() {
    local dtype
    dtype=$(distribution)

    case $dtype in
        "redhat")
            if [ -s /etc/redhat-release ]; then
                cat /etc/redhat-release
            else
                cat /etc/issue
            fi
            uname -a
            ;;
        "suse")
            cat /etc/SuSE-release
            ;;
        "debian")
            lsb_release -a
            ;;
        "gentoo")
            cat /etc/gentoo-release
            ;;
        "arch")
            cat /etc/os-release
            ;;
        "slackware")
            cat /etc/slackware-version
            ;;
        *)
            if [ -s /etc/issue ]; then
                cat /etc/issue
            else
                printf "Error: Unknown distribution\n"
                exit 1
            fi
            ;;
    esac
}

# View Apache logs
apachelog() {
    if [ -f /etc/httpd/conf/httpd.conf ]; then
        cd /var/log/httpd && ls -xAh && multitail --no-repeat -c -s 2 /var/log/httpd/*_log
    else
        cd /var/log/apache2 && ls -xAh && multitail --no-repeat -c -s 2 /var/log/apache2/*.log
    fi
}

# Edit the Apache configuration
apacheconfig() {
    if [ -f /etc/httpd/conf/httpd.conf ]; then
        nano /etc/httpd/conf/httpd.conf
    elif [ -f /etc/apache2/apache2.conf ]; then
        nano /etc/apache2/apache2.conf
    else
        printf "Error: Apache config file could not be found.\n"
        printf "Searching for possible locations:\n"
        sudo updatedb && locate httpd.conf && locate apache2.conf
    fi
}

# Edit the PHP configuration file
phpconfig() {
    if [ -f /etc/php.ini ]; then
        nano /etc/php.ini
    elif [ -f /etc/php/php.ini ]; then
        nano /etc/php/php.ini
    elif [ -f /etc/php5/php.ini ]; then
        nano /etc/php5/php.ini
    elif [ -f /usr/bin/php5/bin/php.ini ]; then
        nano /usr/bin/php5/bin/php.ini
    elif [ -f /etc/php5/apache2/php.ini ]; then
        nano /etc/php5/apache2/php.ini
    else
        printf "Error: php.ini file could not be found.\n"
        printf "Searching for possible locations:\n"
        sudo updatedb && locate php.ini
    fi
}

# Edit the MySQL configuration file
mysqlconfig() {
    if [ -f /etc/my.cnf ]; then
        nano /etc/my.cnf
    elif [ -f /etc/mysql/my.cnf ]; then
        nano /etc/mysql/my.cnf
    elif [ -f /usr/local/etc/my.cnf ]; then
        nano /usr/local/etc/my.cnf
    elif [ -f /usr/bin/mysql/my.cnf ]; then
        nano /usr/bin/mysql/my.cnf
    elif [ -f $HOME/my.cnf ]; then
        nano $HOME/my.cnf
    elif [ -f $HOME/.my.cnf ]; then
        nano $HOME/.my.cnf
    else
        printf "Error: my.cnf file could not be found.\n"
        printf "Searching for possible locations:\n"
        sudo updatedb && locate my.cnf
    fi
}

# Function to switch to Cloudflare DNS
cloudflare_dns() {
    printf "nameserver 1.1.1.2\nnameserver 1.0.0.2\n" | sudo tee /etc/resolv.conf > /dev/null
    printf "Switched to Cloudflare DNS\n"
}

# Function to switch to Quad9 DNS
quad9_dns() {
    printf "nameserver 2620:fe::11\nnameserver 2620:fe::fe:11\nnameserver 9.9.9.11\nnameserver 149.112.112.11\n" | sudo tee /etc/resolv.conf > /dev/null
    printf "Switched to Quad9 DNS\n"
}
