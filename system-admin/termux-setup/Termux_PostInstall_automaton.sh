#!/data/data/com.termux/files/usr/bin/env bash

# Enhanced Termux Post-Installation Configuration Script

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to install essential packages first
install_essential_packages() {
    log "Installing essential packages required for this script..."
    
    # Ensure basic functionality
    touch ~/.hushlogin
    
    # Update repositories and upgrade system
    log "Updating package repositories..."
    termux-change-repo
    apt update && apt upgrade -y
    
    # Install essential packages needed for script functionality
    log "Installing core packages..."
    apt install -y \
        bash \
        curl \
        wget \
        git \
        openssh \
        termux-api \
        termux-services \
        termux-tools \
        which \
        tar \
        xz-utils \
        build-essential \
        cmake \
        pkg-config
    
    # Setup storage access
    log "Setting up storage access..."
    termux-setup-storage
    
    # Create necessary directories
    mkdir -p ~/.termux ~/.local/share/fonts ~/tmp ~/.config
}

# Function to add additional repositories
setup_repositories() {
    log "Setting up additional repositories..."
    apt install -y \
        root-repo \
        x11-repo \
        tur-repo \
        glibc-repo \
        myrepos \
        termux-apt-repo
    
    apt update
}

# Function to prompt for GitHub configuration
setup_git_config() {
    log "Setting up Git and SSH configuration..."
    
    read -rp "Enter your GitHub username: " username
    read -rp "Enter your GitHub email address: " email
    
    # Configure git globally
    git config --global user.name "$username"
    git config --global user.email "$email"
    git config --global init.defaultBranch main
    
    echo "Choose your SSH key type:"
    echo "1. Ed25519 (recommended)"
    echo "2. RSA (legacy)"
    read -rp "Enter your choice (1 or 2): " key_type

    case $key_type in
        1) key_algo="ed25519" ;;
        2) key_algo="rsa" ;;
        *)
            error "Invalid choice. Exiting."
            exit 1
            ;;
    esac

    read -rp "Enter a custom SSH key name (leave blank for default): " key_name
    ssh_key_path="${HOME}/.ssh/${key_name:-id_$key_algo}"
    
    # Create .ssh directory if it doesn't exist
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    # Generate SSH key
    if [[ "$key_algo" == "ed25519" ]]; then
        ssh-keygen -t ed25519 -C "$email" -f "$ssh_key_path" -N ""
    else
        ssh-keygen -t rsa -b 4096 -C "$email" -f "$ssh_key_path" -N ""
    fi

    # Start ssh-agent and add key
    eval "$(ssh-agent -s)"
    ssh-add "$ssh_key_path"
    
    # Set proper permissions
    chmod 600 "$ssh_key_path"
    chmod 644 "${ssh_key_path}.pub"

    log "SSH key generation completed."
}

# Copy SSH public key to clipboard and prompt user to add it to GitHub
copy_and_confirm_ssh_key() {
    log "Copying SSH public key to clipboard..."
    
    # Copy the generated public key to the clipboard
    cat "${ssh_key_path}.pub" | termux-clipboard-set
    log "Your SSH public key has been copied to the clipboard."
    
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo "IMPORTANT: Add your SSH key to GitHub"
    echo -e "${BLUE}============================================${NC}"
    echo "1. Go to https://github.com/settings/keys"
    echo "2. Click 'New SSH key'"
    echo "3. Paste the key from your clipboard"
    echo "4. Give it a title (e.g., 'Termux Device')"
    echo "5. Click 'Add SSH key'"
    echo -e "${BLUE}============================================${NC}"
    echo ""

    while true; do
        read -rp "Have you added your SSH public key to your GitHub account? (y/n): " yn
        case $yn in
            [Yy]* ) 
                log "Testing SSH connection to GitHub..."
                if ssh -o StrictHostKeyChecking=no -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
                    log "SSH connection to GitHub successful!"
                    break
                else
                    warn "SSH connection test failed. Please check your key setup."
                fi
                ;;
            [Nn]* ) 
                warn "Please add your SSH public key to GitHub and try again."
                exit 1
                ;;
            * ) 
                echo "Please answer yes (y) or no (n)."
                ;;
        esac
    done
}

# Function to install development and utility packages
install_development_packages() {
    log "Installing development and utility packages..."
    
    apt install -y \
        bash-completion \
        bat \
        python \
        python-pip \
        sudo \
        mesa \
        mesa-dev \
        vulkan-headers \
        ocl-icd \
        opencl-headers \
        freetype \
        libandroid-wordexp \
        chafa \
        imagemagick \
        fastfetch \
        eza \
        multitail \
        tree \
        zoxide \
        fontconfig-utils \
        tmux \
        ripgrep \
        make \
        unzip \
        neovim \
        elfutils \
        termux-elf-cleaner \
        starship \
        jq \
        fd \
        htop \
        ncdu
    
    # Install Python packages
    log "Installing Python packages..."
    pip install trash-cli requests beautifulsoup4
}

# Function to install and setup tools
setup_development_tools() {
    log "Setting up development tools..."
    
    # Install fzf
    if [[ ! -d ~/.fzf ]]; then
        log "Installing fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        sed -i '1s|.*|#!/data/data/com.termux/files/usr/bin/env bash|' ~/.fzf/install
        ~/.fzf/install --all
    fi
    
    # Create Github directory and clone repositories
    mkdir -p ~/dev && cd ~/dev
    
    # Clone fun007 repository
    if [[ ! -d ~/dev/fun007 ]]; then
        log "Cloning fun007 repository..."
        git clone git@github.com:fam007e/fun007.git
    fi
    
    # Clone termux-adb-fastboot repository
    if [[ ! -d ~/dev/termux-adb-fastboot ]]; then
        log "Cloning termux-adb-fastboot repository..."
        git clone git@github.com:offici5l/termux-adb-fastboot.git
    fi
    
    # Install termux-adb-fastboot
    if [[ -d ~/dev/termux-adb-fastboot ]]; then
        log "Installing termux-adb-fastboot..."
        cd ~/dev/termux-adb-fastboot
        chmod +x install
        ./install
        cd
    fi
}

# Function to setup configuration files
setup_configurations() {
    log "Setting up configuration files..."
    
    # Copy bashrc configuration - USING TERMUX-SPECIFIC VERSION
    if [[ -f ~/dev/fun007/configs/termux/bashrc_SAFE_TMX ]]; then
        cp ~/dev/fun007/configs/termux/bashrc_SAFE_TMX ~/.bashrc
        log "Termux-specific bashrc configuration copied."
    elif [[ -f ~/dev/fun007/configs/bash/bashrc_SAFE ]]; then
        cp ~/dev/fun007/configs/bash/bashrc_SAFE ~/.bashrc
        log "General bashrc configuration copied."
    fi
    
    # Copy starship configuration
    if [[ -f ~/dev/fun007/configs/starship.toml ]]; then
        mkdir -p ~/.config
        cp ~/dev/fun007/configs/starship.toml ~/.config/
        log "Starship configuration copied."
    fi
    
    # Setup nano configuration
    if [[ -f ~/dev/fun007/configs/nanorc_SAFE ]]; then
        sed 's|/usr/share/nano/|/data/data/com.termux/files/usr/share/nano/|g' \
            ~/dev/fun007/configs/nanorc_SAFE > ~/.nanorc
        log "Nano configuration setup completed."
    fi
    
    # Setup fastfetch configuration
    mkdir -p ~/.config/fastfetch
    if [[ -f ~/dev/fun007/configs/fastfetch/ff_SAFE_config.jsonc ]]; then
        cp ~/dev/fun007/configs/fastfetch/ff_SAFE_config.jsonc ~/.config/fastfetch/config.jsonc
        cp ~/dev/fun007/configs/fastfetch/ascii.txt ~/.config/fastfetch/ascii.txt
        log "Fastfetch configuration copied."
    fi
    
    # Setup Termux colors (if available)
    if [[ -f ~/dev/fun007/configs/termux/colors.properties_tmx ]]; then
        mkdir -p ~/.termux
        cp ~/dev/fun007/configs/termux/colors.properties_tmx ~/.termux/colors.properties
        log "Termux-specific colors configuration copied."
    fi
    
    # Setup Neovim configuration
    if [[ ! -d ~/.config/nvim ]]; then
        log "Setting up Neovim configuration..."
        git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
    fi
}

# Function to install selected fonts
install_fonts() {
    log "Setting up font installation..."
    
    fonts=(
        "0xProto"
        "3270" 
        "Agave"
        "AnonymicePro"
        "Arimo"
        "BlexMono"
        "CascadiaCode"
        "CascadiaMono"
        "CodeNewRoman"
        "ComicShannsMono"
        "CommitMono"
        "Cousine"
        "D2Coding"
        "DaddyTimeMono"
        "DejaVuSansMono"
        "EnvyCodeR"
        "FantasqueSansMono"
        "FiraCode"
        "FiraMono"
        "GeistMono"
        "Go-Mono"
        "Gohu"
        "Hack"
        "Hasklig"
        "Hermit"
        "iA-Writer"
        "Inconsolata"
        "InconsolataGo"
        "InconsolataLGC"
        "IntoneMono"
        "Iosevka"
        "IosevkaTerm"
        "IosevkaTermSlab"
        "JetBrainsMono"
        "Lekton"
        "LiberationMono"
        "Lilex"
        "MartianMono"
        "Meslo"
        "Monaspice"
        "Monofur"
        "Monoid"
        "Mononoki"
        "Noto"
        "OpenDyslexic"
        "Overpass"
        "ProFont"
        "ProggyClean"
        "RobotoMono"
        "SourceCodePro"
        "SpaceMono"
        "Terminus"
        "Tinos"
        "Ubuntu"
        "UbuntuMono"
        "VictorMono"
    )

    echo ""
    echo -e "${BLUE}==========================================${NC}"
    echo "Font Installation"
    echo -e "${BLUE}==========================================${NC}"
    echo "Select fonts to install (separate with spaces):"
    echo "Example: 0 15 33 (for 0xProto, FantasqueSansMono, JetBrainsMono)"
    echo "------------------------------------------"
    for i in "${!fonts[@]}"; do
        printf "%2d - %s\n" "$i" "${fonts[i]}"
    done
    echo "------------------------------------------"
    read -rp "Enter the numbers of fonts to install: " font_selection

    if [[ -z "$font_selection" ]]; then
        warn "No fonts selected. Installing JetBrainsMono as default..."
        font_selection="33"
    fi

    mkdir -p ~/.local/share/fonts

    for selection in $font_selection; do
        if [[ "$selection" -ge 0 && "$selection" -lt "${#fonts[@]}" ]]; then
            font=${fonts[$selection]}
            log "Downloading and installing $font Nerd Font..."
            
            wget -q --show-progress \
                "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.tar.xz" \
                -P ~/tmp
                
            if [[ -f ~/tmp/"${font}".tar.xz ]]; then
                tar -xf ~/tmp/"${font}".tar.xz -C ~/.local/share/fonts/
                rm ~/tmp/"${font}".tar.xz
                log "$font installed successfully."
            else
                error "Failed to download $font"
            fi
        else
            warn "Invalid selection: $selection"
        fi
    done

    log "Refreshing font cache..."
    fc-cache -fv
}

# Function to select a font for use in Termux
select_font_for_termux() {
    log "Setting up Termux font selection..."
    
    local font_dir="$HOME/.local/share/fonts"
    if [[ ! -d "$font_dir" || -z "$(ls -A "$font_dir" 2>/dev/null)" ]]; then
        warn "No fonts found in $font_dir"
        return 1
    fi
    
    local fonts=("$font_dir"/*.ttf)
    
    if [[ ${#fonts[@]} -eq 0 ]]; then
        warn "No TTF fonts found."
        return 1
    fi

    echo ""
    echo "Available fonts:"
    echo "----------------"
    for i in "${!fonts[@]}"; do
        echo "$((i + 1)). $(basename "${fonts[$i]}" .ttf)"
    done
    echo "----------------"

    local choice
    read -rp "Enter the number of the font for Termux (or press Enter for first font): " choice
    
    if [[ -z "$choice" ]]; then
        choice=1
    fi

    local selected_font="${fonts[$((choice - 1))]}"

    if [[ -z "$selected_font" || ! -f "$selected_font" ]]; then
        error "Invalid selection. Using first available font."
        selected_font="${fonts[0]}"
    fi

    log "Selected font: $(basename "$selected_font")"
    cp "$selected_font" ~/.termux/font.ttf
}

# Function to list and select a theme
select_theme_for_termux() {
    log "Setting up Termux theme selection..."
    
    local theme_dir="$HOME/dev/fun007/Termux_postinstallconfig_script/colors"
    
    if [[ ! -d "$theme_dir" ]]; then
        error "Theme directory not found: $theme_dir"
        return 1
    fi
    
    local themes=("$theme_dir"/*.properties)

    if [[ ${#themes[@]} -eq 0 ]]; then
        error "No theme files found."
        return 1
    fi

    echo ""
    echo "Available themes:"
    echo "-----------------"
    for i in "${!themes[@]}"; do
        echo "$((i + 1)). $(basename "${themes[$i]}" .properties)"
    done
    echo "-----------------"

    local choice
    read -rp "Enter theme number (or press Enter for 'nord'): " choice
    
    # Default to nord theme if available
    if [[ -z "$choice" ]]; then
        for i in "${!themes[@]}"; do
            if [[ "$(basename "${themes[$i]}")" == "nord.properties" ]]; then
                choice=$((i + 1))
                break
            fi
        done
        # If nord not found, use first theme
        if [[ -z "$choice" ]]; then
            choice=1
        fi
    fi

    local selected_theme="${themes[$((choice - 1))]}"

    if [[ -z "$selected_theme" || ! -f "$selected_theme" ]]; then
        error "Invalid selection. Using first available theme."
        selected_theme="${themes[0]}"
    fi

    log "Selected theme: $(basename "$selected_theme" .properties)"
    cp "$selected_theme" ~/.termux/colors.properties
}

# Function to finalize setup
finalize_setup() {
    log "Finalizing setup..."
    
    # Reload termux settings
    termux-reload-settings 2>/dev/null || true
    
    # shellcheck disable=SC1090
    source ~/.bashrc 2>/dev/null || true
    
    log "Setup completed successfully!"
    echo ""
    echo -e "${BLUE}==============================================${NC}"
    echo "SETUP COMPLETE!"
    echo -e "${BLUE}==============================================${NC}"
    echo "Please restart Termux to apply all changes."
    echo ""
    echo -e "${BLUE}Installed tools:${NC}"
    echo "  - Git with SSH setup"
    echo "  - Neovim with kickstart config"
    echo "  - Starship prompt"
    echo "  - Fastfetch system info"
    echo "  - FZF fuzzy finder"
    echo "  - Various CLI utilities"
    echo ""
    echo -e "${BLUE}Configuration files are in:${NC}"
    echo "  - ~/.bashrc (main shell config)"
    echo "  - ~/.config/starship.toml (prompt config)"
    echo "  - ~/.config/nvim/ (Neovim config)"
    echo "  - ~/.config/fastfetch/ (system info config)"
    echo ""
    echo -e "${BLUE}Repositories cloned to:${NC}"
    echo "  - ~/dev/fun007 (your dotfiles)"
    echo -e "${BLUE}==============================================${NC}"
}

# Main execution
main() {
    log "Starting Enhanced Termux Post-Installation Setup..."
    
    # Install essential packages first
    install_essential_packages
    
    # Setup additional repositories
    setup_repositories
    
    # Setup Git and SSH
    setup_git_config
    copy_and_confirm_ssh_key
    
    # Install development packages
    install_development_packages
    
    # Setup development tools
    setup_development_tools
    
    # Setup configuration files
    setup_configurations
    
    # Install fonts
    install_fonts
    
    # Select font for Termux
    select_font_for_termux
    
    # Select theme for Termux
    select_theme_for_termux
    
    # Finalize setup
    finalize_setup
}

# Run main function
main "$@"
