#!/bin/bash

# ==============================================================================
# fun007 Ecosystem One-Click Bootstrap
# Purpose: Detects environment and launches the appropriate installer.
# Usage: curl -fsSL https://fam007e.github.io/fun007/bootstrap.sh | bash
# ==============================================================================

set -euo pipefail

# --- Styles ---
BOLD="\033[1m"
CYAN="\033[1;36m"
LIME="\033[1;32m"
RESET="\033[0m"

echo -e "${CYAN}${BOLD}fun007 Ecosystem Bootstrap${RESET}"
echo "--------------------------------------------------------"

# --- Environment Detection ---
SUDO=""
[ "$EUID" -ne 0 ] && command -v sudo >/dev/null 2>&1 && SUDO="sudo"

if [ -d "/data/data/com.termux" ]; then
    echo -e "Detected environment: ${LIME}Termux (Android)${RESET}"
    echo "Fetching Termux Automaton..."
    bash <(curl -fsSL https://raw.githubusercontent.com/fam007e/fun007/main/system-admin/termux-setup/Termux_PostInstall_automaton.sh)
elif [ -f "/etc/arch-release" ]; then
    echo -e "Detected environment: ${CYAN}Arch Linux${RESET}"
    echo "Select your deployment role:"
    echo "1) Fresh System Install (BTRFS/LUKS - For Live ISO)"
    echo "2) Mirror Server Setup (Tier-2 Hardened + Monitoring)"
    echo "3) Desktop Environment Bootstrap (Zsh/Dev Tools/Configs)"
    read -p "Selection [1-3]: " choice < /dev/tty

    case $choice in
        1)
            echo "Fetching Arch Modular Installer suite..."
            curl -fsSL -H "Cache-Control: no-cache" https://raw.githubusercontent.com/fam007e/fun007/main/system-admin/arch-install/generate_config.sh -o /tmp/gen_config.sh
            curl -fsSL -H "Cache-Control: no-cache" https://raw.githubusercontent.com/fam007e/fun007/main/system-admin/arch-install/archinstall_interactive.sh -o /tmp/archinstall.sh
            chmod +x /tmp/gen_config.sh /tmp/archinstall.sh
            
            echo "Launching configuration wizard..."
            bash /tmp/gen_config.sh
            
            if [ -f "config.json" ]; then
                echo "Starting installation..."
                $SUDO bash /tmp/archinstall.sh "$(pwd)/config.json"
            else
                echo "Error: config.json was not generated. Aborting."
                exit 1
            fi
            ;;
        2)
            echo "Fetching Hardened Mirror Suite..."
            # Run setup first, then suggest hardening
            curl -fsSL -H "Cache-Control: no-cache" https://raw.githubusercontent.com/fam007e/fun007/main/system-admin/arch-install/arch-mirror-setup.sh -o /tmp/mirror_setup.sh
            chmod +x /tmp/mirror_setup.sh
            $SUDO bash /tmp/mirror_setup.sh
            echo -e "\nSetup complete. Run hardening script? (y/n)"
            read -r harden < /dev/tty
            if [[ "$harden" =~ ^[Yy]$ ]]; then
                curl -fsSL -H "Cache-Control: no-cache" https://raw.githubusercontent.com/fam007e/fun007/main/system-admin/arch-install/arch-mirror-hardened.sh | $SUDO bash
            fi
            ;;
        3)
            echo "Fetching Zsh/Ecosystem Bootstrap..."
            bash <(curl -fsSL -H "Cache-Control: no-cache" https://raw.githubusercontent.com/fam007e/fun007/main/system-admin/dotfiles/zsh/zshrc_pkg_prep.sh)
            ;;
        *)
            echo "Invalid selection. Aborting."
            exit 1
            ;;
    esac
else
    echo "Error: Unsupported environment. This script supports Arch Linux and Termux."
    exit 1
fi
