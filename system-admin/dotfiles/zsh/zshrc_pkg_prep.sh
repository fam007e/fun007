#!/bin/bash

set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install AUR helper
install_aur_helper() {
    local aur_helper="$1"
    local aur_repo="https://aur.archlinux.org/${aur_helper}.git"
    local temp_dir="/tmp/${aur_helper}"

    if command_exists "$aur_helper"; then
        echo "${aur_helper^} is already installed."
        return 0
    fi

    echo "Installing $aur_helper..."
    git clone "$aur_repo" "$temp_dir"
    (cd "$temp_dir" && makepkg -si --noconfirm)
    rm -rf "$temp_dir"
    if ! command_exists "$aur_helper"; then
        echo "Error: Failed to install $aur_helper."
        exit 1
    fi
}

echo "Checking for AUR helper..."

# Check for yay or paru, or prompt for user selection
if command_exists yay; then
    AUR_HELPER="yay"
elif command_exists paru; then
    AUR_HELPER="paru"
else
    echo "Neither yay nor paru is installed. Please select an AUR helper to install and use:"
    select choice in "yay" "paru"; do
        case $choice in
            yay|paru)
                install_aur_helper "$choice"
                AUR_HELPER="$choice"
                break
                ;;
            *)
                echo "Invalid option. Please select 1 or 2."
                ;;
        esac
    done
fi

echo "Using $AUR_HELPER as AUR helper."

# Update the system
echo "Updating system with $AUR_HELPER..."
if ! "$AUR_HELPER" -Syu --noconfirm; then
    echo "Error: System update failed."
    exit 1
fi

# Define package lists
PACMAN_PACKAGES=(
    zsh
    git
    curl
    wget
    jq
    cmake
    neovim
    xclip
    fzf
    zoxide
    bat
    eza
    multitail
    python
    python-pip
    thefuck
    tldr
    unzip
    tar
    gzip
    net-tools
    ripgrep
    fd
    zsh-completions
    zsh-autosuggestions
    p7zip
    unrar
    qbittorrent
    xdotool
    libnotify
)

AUR_PACKAGES=(
    oh-my-posh
    rate-mirrors
    khal
)

# Install pacman packages
echo "Installing essential packages via pacman..."
if ! sudo pacman -S --noconfirm --needed "${PACMAN_PACKAGES[@]}"; then
    echo "Error: Failed to install some pacman packages."
    exit 1
fi

# Install AUR packages
echo "Installing AUR packages with $AUR_HELPER..."
if ! "$AUR_HELPER" -S --noconfirm --needed "${AUR_PACKAGES[@]}"; then
    echo "Error: Failed to install some AUR packages."
    exit 1
fi

# Install SDKMAN
SDKMAN_INIT="$HOME/.sdkman/bin/sdkman-init.sh"
if [ ! -d "$HOME/.sdkman" ]; then
    echo "Installing SDKMAN..."
    if ! curl -s "https://get.sdkman.io" | bash; then
        echo "Error: Failed to install SDKMAN."
        exit 1
    fi
    # Source SDKMAN init script if it exists
    if [ -f "$SDKMAN_INIT" ]; then
        # shellcheck disable=SC1091,SC1090
        source "$SDKMAN_INIT"
    else
        echo "Warning: SDKMAN init script not found at $SDKMAN_INIT"
    fi
else
    echo "SDKMAN is already installed."
    if [ -f "$SDKMAN_INIT" ]; then
        # shellcheck disable=SC1091,SC1090
        source "$SDKMAN_INIT"
    else
        echo "Warning: SDKMAN init script not found at $SDKMAN_INIT"
    fi
fi

# Install fastfetch from source
FASTFETCH_DIR="$HOME/fastfetch"
if [ ! -d "$FASTFETCH_DIR" ]; then
    echo "Cloning and building fastfetch from source..."
    if ! git clone https://github.com/fastfetch-cli/fastfetch.git "$FASTFETCH_DIR"; then
        echo "Error: Failed to clone fastfetch repository."
        exit 1
    fi
    mkdir -p "$FASTFETCH_DIR/build"
    cd "$FASTFETCH_DIR/build"
    if ! cmake ..; then
        echo "Error: Failed to configure fastfetch with cmake."
        exit 1
    fi
    if ! cmake --build . --target package; then
        echo "Error: Failed to build fastfetch."
        exit 1
    fi
    if ! sudo cmake --install . --prefix /usr; then
        echo "Error: Failed to install fastfetch."
        exit 1
    fi
    cd
else
    echo "Fastfetch repository already exists at $FASTFETCH_DIR."
    echo "Run 'ff-upd' to update fastfetch manually if needed."
fi

# Install Oh-My-Posh dependencies (ensure dotnet-runtime is installed)
if ! command_exists dotnet; then
    echo "Installing dotnet-runtime for Oh-My-Posh..."
    sudo pacman -S --noconfirm --needed dotnet-runtime
fi

# Ensure Zsh is the default shell
if [[ "$SHELL" != "$(which zsh)" ]]; then
    echo "Changing default shell to Zsh..."
    if ! chsh -s "$(which zsh)"; then
        echo "Error: Failed to change default shell to Zsh."
        exit 1
    fi
fi

# Clone and setup Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    echo "Installing Zinit..."
    mkdir -p "$(dirname "$ZINIT_HOME")"
    if ! git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"; then
        echo "Error: Failed to clone Zinit."
        exit 1
    fi
else
    echo "Zinit is already installed."
fi

# Ensure .zshrc exists and is backed up
ZSHRC="$HOME/.zshrc"
if [ -f "$ZSHRC" ]; then
    echo "Backing up existing .zshrc to .zshrc.bak..."
    cp "$ZSHRC" "${ZSHRC}.bak"
fi

# Notify user of completion
echo "All packages and tools installed successfully."
echo "Fastfetch has been built and installed from source."
echo "Zsh is set as the default shell."
echo "You can now use your ~/.zshrc configuration by starting a new Zsh session."
