# functions-dev.zsh : git helpers, password generator, ISO download/flash

# GitHub Additions
gcom() {
    git add .
    git commit -m "$1"
}

lazyg() {
    git pull --rebase
    git add .
    git commit -m "$1"
    git push
}

# Passwd Generator
passwdGEN() {
    local length=${1:-19}  # Default length: 19
    local case_variance=""
    local numbers=""
    local special=""

    # Only shift if there are arguments beyond the first one
    if [ $# -gt 1 ]; then
        shift  # Remove length argument
    elif [ $# -eq 1 ]; then
        # If only one argument (length), clear the argument list
        set --
    fi

    # Parse additional arguments for character set flags
    while [ $# -gt 0 ]; do
        case "$1" in
            -c|--case-variance) case_variance="-c" ;;
            -n|--numbers) numbers="-n" ;;
            -s|--special) special="-s" ;;
            *) echo "Error: Invalid option $1. Use -c, -n, or -s." ; return 1 ;;
        esac
        shift
    done

    # Validate length
    if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 12 ]; then
        echo "Error: Length must be a number >= 12"
        return 1
    fi

    # Check if at least one character set is enabled (script requires at least lowercase)
    if [ -z "$case_variance" ] && [ -z "$numbers" ] && [ -z "$special" ]; then
        echo "Warning: No character sets specified. Defaulting to lowercase + uppercase + numbers + special."
        case_variance="-c"
        numbers="-n"
        special="-s"
    fi

    # Locate the generator (FUN007_DIR is set in env.zsh / local.zsh)
    local script="${FUN007_DIR:-$HOME/Github/fun007}/security/password-gen/passwd_gen.py"
    if [[ ! -r $script ]]; then
        print -u2 "passwdGEN: generator not found: $script (set FUN007_DIR in local.zsh)"
        return 1
    fi

    # Run the password generator and extract the password
    python3 "$script" $case_variance $numbers $special "$length" | grep "Generated Password:" | awk '{for(i=3;i<=NF;i++)printf "%s", $i}' | tee >(pbcopy)
    echo  # Add newline after password
}

# dwn_iso : download latest Arch and Tails ISOs and verify them (needs iso_verify)
dwn_iso() {
    local iso_dir="${ISO_DIR:-$HOME/Downloads/ISO}"
    mkdir -p "$iso_dir" || return 1

    local arch_url_base1="https://mirror.rackspace.com/archlinux/iso/latest/"
    local arch_url_base2="https://geo.mirror.pkgbuild.com/iso/latest/"
    local tails_url_base="https://mirrors.edge.kernel.org/tails/stable/"

    # _dl <url> <dest> : fail on HTTP errors, write to .part first so a failed
    # download never leaves a file that looks complete
    _dl() {
        local url=$1 dest=$2
        if curl -fL --progress-bar -o "$dest.part" "$url"; then
            mv -f "$dest.part" "$dest"
        else
            rm -f "$dest.part"
            return 1
        fi
    }

    # _prune_old <glob> <keep-filename> : remove older ISOs of one distro plus their .sig
    # files. Only called after the new ISO has been downloaded AND verified.
    _prune_old() {
        local pattern=$1 keep=$2 f
        for f in "$iso_dir"/${~pattern}(N); do
            [[ ${f:t} == $keep ]] && continue
            echo "Removing old ISO: ${f:t}"
            rm -f -- "$f" "$f.sig"
        done
    }

    # ==================== ARCH LINUX ====================
    download_arch_iso() {
        local arch_latest_ver
        arch_latest_ver=$(curl -fsL "${arch_url_base1}" \
            | grep -oP 'archlinux-\K[0-9]{4}\.[0-9]{2}\.[0-9]{2}(?=-x86_64\.iso)' \
            | sort -Vu | tail -n 1)

        if [[ -z $arch_latest_ver ]]; then
            echo "Could not detect Arch ISO version."
            return 1
        fi

        local iso_filename="archlinux-${arch_latest_ver}-x86_64.iso"

        if [[ -f "$iso_dir/$iso_filename" ]]; then
            echo "Arch ISO is already the latest version: $iso_filename"
            return 0
        fi

        echo "Downloading latest Arch Linux ISO: $iso_filename"

        if ! _dl "${arch_url_base1}${iso_filename}" "$iso_dir/$iso_filename"; then
            echo "Primary mirror failed, trying fallback..."
            _dl "${arch_url_base2}${iso_filename}" "$iso_dir/$iso_filename" || {
                echo "Download failed."
                return 1
            }
        fi

        # checksums and signature are fetched from the main mirror list
        _dl "${arch_url_base2}sha256sums.txt"          "$iso_dir/sha256sums.txt"          || echo "Warning: sha256sums.txt not downloaded"
        _dl "${arch_url_base2}b2sums.txt"              "$iso_dir/b2sums.txt"              || echo "Warning: b2sums.txt not downloaded"
        _dl "${arch_url_base2}${iso_filename}.sig"     "$iso_dir/${iso_filename}.sig"     || echo "Warning: signature not downloaded"

        if ! gpg --list-keys 76A5EF9054449A5C &>/dev/null; then
            gpg --auto-key-locate clear,wkd -v --locate-external-key pierre@archlinux.org
        fi

        iso_verify "$iso_dir/$iso_filename" || {
            echo "Verification failed, removing $iso_filename"
            rm -f "$iso_dir/$iso_filename"
            return 1
        }

        _prune_old 'archlinux-*-x86_64.iso' "$iso_filename"
    }

    # ==================== TAILS ====================
    download_tails_iso() {
        echo "Fetching latest Tails version..."

        local tails_latest_ver
        tails_latest_ver=$(curl -fsL "${tails_url_base}" \
            | grep -oP 'tails-amd64-\K[0-9]+\.[0-9]+(\.[0-9]+)?(?=/)' | sort -Vu | tail -n 1)

        if [[ -z $tails_latest_ver ]]; then
            echo "Could not detect Tails version."
            return 1
        fi

        local iso_filename="tails-amd64-${tails_latest_ver}.iso"
        local version_dir="${tails_url_base}tails-amd64-${tails_latest_ver}/"

        echo "Latest Tails version detected: ${tails_latest_ver}"

        if [[ -f "$iso_dir/$iso_filename" ]]; then
            echo "Tails ISO is already the latest version: $iso_filename"
            return 0
        fi

        echo "Downloading Tails ISO: $iso_filename"

        _dl "${version_dir}${iso_filename}"     "$iso_dir/$iso_filename"     || { echo "ISO download failed.";       return 1 }
        _dl "${version_dir}${iso_filename}.sig" "$iso_dir/$iso_filename.sig" || { echo "Signature download failed."; rm -f "$iso_dir/$iso_filename"; return 1 }

        # key import is not trusted on its own: iso_verify pins the fingerprint
        if ! gpg --list-keys DBB802B258ACD84F &>/dev/null; then
            echo "Downloading Tails signing key..."
            _dl "https://tails.net/tails-signing.key" "$iso_dir/tails-signing.key" || return 1
            gpg --import "$iso_dir/tails-signing.key"
        fi

        iso_verify "$iso_dir/$iso_filename" || {
            echo "Verification failed, removing $iso_filename"
            rm -f "$iso_dir/$iso_filename"
            return 1
        }

        _prune_old 'tails-amd64-*.iso' "$iso_filename"
    }

    echo "Checking for new Arch and Tails ISO versions..."
    download_arch_iso
    download_tails_iso
}

# Flash ISO to drive
flashiso() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: flashiso <image.iso> <device>"
        echo "Example: flashiso archlinux.iso /dev/sdb"
        return 1
    fi

    local iso="$1"
    local dev="$2"

    [[ ! -f "$iso" ]] && echo "Error: ISO not found: $iso" && return 1
    [[ ! -b "$dev" ]] && echo "Error: Not a block device: $dev" && return 1

    echo "ISO: $iso"
    echo "Device: $dev"
    lsblk "$dev"
    echo "\nThis will DESTROY all data on $dev. Continue? [y/N]"
    read -r confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && echo "Aborted." && return 1

    sudo dd if="$iso" of="$dev" bs=4M status=progress oflag=sync && sync
}
