#!/bin/bash

set -e

echo "Checking for AUR helper..."

# Check for yay or paru, or prompt for user selection if neither is found
if command -v yay &> /dev/null; then
    AUR_HELPER="yay"
elif command -v paru &> /dev/null; then
    AUR_HELPER="paru"
else
    echo "Neither yay nor paru is installed. Please select an AUR helper to install and use:"
    select choice in "yay" "paru"; do
        case $choice in
            yay)
                echo "Installing yay..."
                git clone https://aur.archlinux.org/yay.git /tmp/yay
                (cd /tmp/yay && makepkg -si --noconfirm)
                rm -rf /tmp/yay
                AUR_HELPER="yay"
                break
                ;;
            paru)
                echo "Installing paru..."
                git clone https://aur.archlinux.org/paru.git /tmp/paru
                (cd /tmp/paru && makepkg -si --noconfirm)
                rm -rf /tmp/paru
                AUR_HELPER="paru"
                break
                ;;
            *)
                echo "Invalid option. Please select 1 or 2."
                ;;
        esac
    done
fi

echo "Updating system and installing required packages using $AUR_HELPER..."

# Update the system (use AUR helper instead of pacman)
$AUR_HELPER -Syu --noconfirm

# Install essential packages
$AUR_HELPER -S --noconfirm --needed \
    zsh \
    git \
    curl \
    wget \
    jq \
    cmake \
    neovim \
    xclip \
    fzf \
    zoxide \
    bat \
    eza \
    multitail \
    python \
    python-pip \
    thefuck \
    tldr \
    sdkman \
    kitty \
    rate-mirrors \
    gpg \
    unzip \
    tar \
    gzip \
    net-tools \
    notify-osd \
    ripgrep \
    fd \
    zsh-completions \
    zsh-autosuggestions \
    zsh-autocomplete

# Install Oh-My-Posh dependencies
$AUR_HELPER -S --noconfirm --needed dotnet-runtime

# Install additional tools from AUR
$AUR_HELPER -S --noconfirm \
    oh-my-posh

# Ensure Zsh is the default shell
if [[ "$SHELL" != "$(which zsh)" ]]; then
    echo "Changing default shell to Zsh..."
    chsh -s "$(which zsh)"
fi

# Clone and setup Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    echo "Installing Zinit..."
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

echo "All packages and tools installed successfully."
echo "You can now start using Zsh with your ~/.zshrc configuration."
