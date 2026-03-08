#!/bin/bash

# ==============================================================================
# Zsh Environment Preparation Script
# Purpose: Bootstraps an Arch Linux system for the 'fun007' Zsh configuration.
# Logic: 
#   1. Bootstrap essentials (Git/Base-Devel)
#   2. Setup AUR helper (Yay/Paru)
#   3. Install Repo & AUR packages
#   4. Install Version Managers (SDKMAN) & Plugin Managers (Zinit)
#   5. Build Fastfetch from source (Custom Requirement)
#   6. Deploy configuration files to $HOME
# ==============================================================================

set -e

# --- Helper Functions ---
command_exists() {
    command -v "$1" &> /dev/null
}

info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
    exit 1
}

# --- Phase 1: Bootstrapping Essentials ---
info "Phase 1: Bootstrapping essentials..."
sudo pacman -S --noconfirm --needed git base-devel

# --- Phase 2: AUR Helper Setup ---
info "Phase 2: Setting up AUR helper..."
AUR_HELPER=""
if command_exists yay; then
    AUR_HELPER="yay"
elif command_exists paru; then
    AUR_HELPER="paru"
else
    echo "Select an AUR helper to install:"
    select choice in "yay" "paru"; do
        case $choice in
            yay|paru)
                info "Installing $choice..."
                temp_dir=$(mktemp -d)
                git clone "https://aur.archlinux.org/${choice}.git" "$temp_dir"
                (cd "$temp_dir" && makepkg -si --noconfirm)
                rm -rf "$temp_dir"
                AUR_HELPER="$choice"
                break
                ;;
            *) warn "Invalid option. Please select 1 or 2." ;;
        esac
    done
fi

# --- Phase 3: Bulk Package Installation ---
info "Phase 3: Installing packages via $AUR_HELPER..."

PACMAN_PACKAGES=(
    zsh curl wget jq cmake ninja neovim xclip fzf zoxide bat eza 
    multitail python python-pip thefuck tldr unzip tar gzip 
    net-tools ripgrep fd zsh-completions zsh-autosuggestions 
    p7zip unrar qbittorrent xdotool libnotify
)

AUR_PACKAGES=(
    oh-my-posh rate-mirrors khal
)

sudo pacman -S --noconfirm --needed "${PACMAN_PACKAGES[@]}"
"$AUR_HELPER" -S --noconfirm --needed "${AUR_PACKAGES[@]}"

# --- Phase 4: Version & Plugin Managers ---
info "Phase 4: Installing SDKMAN and Zinit..."

# SDKMAN
if [ ! -d "$HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash || warn "SDKMAN installation failed"
fi

# Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# --- Phase 5: Source Builds (Fastfetch) ---
info "Phase 5: Building Fastfetch from source..."
FASTFETCH_DIR="$HOME/fastfetch"
if [ ! -d "$FASTFETCH_DIR" ]; then
    git clone https://github.com/fastfetch-cli/fastfetch.git "$FASTFETCH_DIR"
    mkdir -p "$FASTFETCH_DIR/build"
    (
        cd "$FASTFETCH_DIR/build"
        cmake .. -GNinja
        ninja package
        sudo ninja install
    )
else
    info "Fastfetch source already exists at $FASTFETCH_DIR. Skipping build."
fi

# --- Phase 6: Config Deployment ---
info "Phase 6: Deploying configuration files..."
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ZSH_DOT_DIR="$REPO_ROOT/system-admin/dotfiles/zsh"

# Backup and symlink .zshrc
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    info "Existing .zshrc backed up to .zshrc.bak"
fi
ln -sf "$ZSH_DOT_DIR/zshrc_SAFE" "$HOME/.zshrc"

# Link help file (referenced by 'hlp' alias in zshrc_SAFE)
ln -sf "$ZSH_DOT_DIR/zshrc_aliases.md" "$HOME/zshrc_aliases.md"

# --- Phase 7: System Integration ---
info "Phase 7: Finalizing..."
if [[ "$SHELL" != "$(which zsh)" ]]; then
    info "Changing default shell to Zsh..."
    sudo chsh -s "$(which zsh)" "$USER"
fi

info "Success! Restart your terminal or run 'source ~/.zshrc' to begin."
