#!/bin/bash

# ==============================================================================
# fun007 Ecosystem One-Click Bootstrap
# Purpose: Detects environment and launches the appropriate installer.
# Usage: curl -fsSL https://fam007e.github.io/fun007/bootstrap.sh | bash
# ==============================================================================

set -e

# --- Styles ---
BOLD="\033[1m"
CYAN="\033[1;36m"
LIME="\033[1;32m"
RESET="\033[0m"

echo -e "${CYAN}${BOLD}fun007 Ecosystem Bootstrap${RESET}"
echo "--------------------------------------------------------"

# --- Environment Detection ---
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
    read -p "Selection [1-3]: " choice

    case $choice in
        1)
            echo "Fetching Arch Modular Installer..."
            curl -fsSL https://raw.githubusercontent.com/fam007e/fun007/main/system-admin/arch-install/archinstall_interactive.sh -o /tmp/archinstall.sh
            chmod +x /tmp/archinstall.sh
            sudo /tmp/archinstall.sh
            ;;
        2)
            echo "Fetching Hardened Mirror Suite..."
            # Run setup first, then suggest hardening
            curl -fsSL https://raw.githubusercontent.com/fam007e/fun007/main/system-admin/arch-install/arch-mirror-setup.sh -o /tmp/mirror_setup.sh
            chmod +x /tmp/mirror_setup.sh
            sudo /tmp/mirror_setup.sh
            echo -e "\nSetup complete. Run hardening script? (y/n)"
            read -r harden
            if [[ "$harden" =~ ^[Yy]$ ]]; then
                curl -fsSL https://raw.githubusercontent.com/fam007e/fun007/main/system-admin/arch-install/arch-mirror-hardened.sh | sudo bash
            fi
            ;;
        3)
            echo "Fetching Zsh/Ecosystem Bootstrap..."
            bash <(curl -fsSL https://raw.githubusercontent.com/fam007e/fun007/main/system-admin/dotfiles/zsh/zshrc_pkg_prep.sh)
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
