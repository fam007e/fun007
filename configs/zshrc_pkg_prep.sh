#!/bin/bash

set -e

echo "Updating system and installing required packages..."

# Update the system
sudo pacman -Syu --noconfirm

# Install essential packages
sudo pacman -S --noconfirm --needed \
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
    zsh-completions

# Install Oh-My-Posh dependencies
sudo pacman -S --noconfirm --needed dotnet-runtime

# Install AUR helper (yay) if not installed
if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
fi

# Install additional tools from AUR
yay -S --noconfirm \
    oh-my-posh-bin \
    fastfetch

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
