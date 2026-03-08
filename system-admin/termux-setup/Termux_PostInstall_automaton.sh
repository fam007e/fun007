#!/data/data/com.termux/files/usr/bin/env bash

# ==============================================================================
# Termux Post-Installation Automaton
# Purpose: Bootstraps a fresh Termux environment with fun007 dotfiles & tools.
# Structure:
#   1. System Update & Essential Tools
#   2. GitHub/SSH Identity Setup
#   3. fun007 Repo Cloning (The Source of Truth)
#   4. Package & Tool Installation (fzf, adb, etc.)
#   5. Configuration Deployment (Bash, Starship, Fastfetch)
#   6. Advanced Nerd Font Management (GitHub API + Interactive Selection)
#   7. Visual Customization (Themes & Finalization)
# ==============================================================================

set -e

# --- Configuration & Styling ---
REPO_URL="git@github.com:fam007e/fun007.git"
LOCAL_REPO="$HOME/dev/fun007"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
PAGER="${PAGER:-less -R -X -F}"

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Helper: Print Fonts in Columns ---
print_fonts_in_columns() {
    local fonts=("$@")
    local term_width=$(tput cols)
    local max_len=0
    for font in "${fonts[@]}"; do
        (( ${#font} > max_len )) && max_len=${#font}
    done

    local col_width=$((max_len + 6))
    local columns=$((term_width / col_width))
    (( columns == 0 )) && columns=1
    local total=${#fonts[@]}
    local rows=$(( (total + columns - 1) / columns ))

    for ((i=0; i<rows; i++)); do
        for ((j=0; j<columns; j++)); do
            local idx=$(( i + j * rows ))
            (( idx < total )) && printf "%-$(echo $col_width)s" "$((idx + 1)). ${fonts[idx]}"
        done
        echo
    done
}

# --- Phase 1: System Bootstrap ---
phase1_bootstrap() {
    log "Phase 1: Updating system and installing essential tools..."
    touch ~/.hushlogin
    mkdir -p ~/.termux ~/.local/share/fonts ~/tmp ~/.config ~/.ssh ~/dev
    pkg update && pkg upgrade -y
    pkg install -y git curl wget openssh termux-api termux-tools build-essential binutils unzip fontconfig
}

# --- Phase 2: Identity Setup ---
phase2_git_ssh() {
    log "Phase 2: Setting up Git and SSH identity..."
    if [[ ! -f ~/.ssh/id_ed25519 ]]; then
        read -rp "Enter your GitHub username: " username
        read -rp "Enter your GitHub email: " email
        git config --global user.name "$username"
        git config --global user.email "$email"
        git config --global init.defaultBranch main
        ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
        cat ~/.ssh/id_ed25519.pub | termux-clipboard-set
        log "SSH Public Key copied to clipboard."
        echo -e "${BLUE}============================================${NC}"
        echo "ACTION REQUIRED: Add key to GitHub"
        echo "URL: https://github.com/settings/keys"
        echo -e "${BLUE}============================================${NC}"
        read -rp "Press Enter once the key is added to GitHub..."
    else
        log "SSH identity already exists. Skipping generation."
    fi
}

# --- Phase 3: Repository Cloning ---
phase3_clone_repo() {
    log "Phase 3: Cloning fun007 configuration repository..."
    if [[ ! -d "$LOCAL_REPO" ]]; then
        git clone "$REPO_URL" "$LOCAL_REPO" || error "Failed to clone repository. Check SSH/Network."
    else
        log "Repository already exists at $LOCAL_REPO. Pulling updates..."
        cd "$LOCAL_REPO" && git pull && cd -
    fi
}

# --- Phase 4: Package & Tool Installation ---
phase4_install_tools() {
    log "Phase 4: Installing development packages and tools..."
    pkg install -y \
        root-repo x11-repo tur-repo \
        bash-completion bat eza fastfetch starship \
        neovim tmux jq fd ripgrep zoxide tree \
        python python-pip htop ncdu cmake make \
        freetype fontconfig-utils

    pip install trash-cli requests beautifulsoup4

    if [[ ! -d ~/.fzf ]]; then
        log "Installing fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all --no-bash --no-zsh --no-fish
    fi
    
    if [[ ! -d ~/dev/termux-adb-fastboot ]]; then
        log "Installing termux-adb-fastboot..."
        git clone https://github.com/offici5l/termux-adb-fastboot.git ~/dev/termux-adb-fastboot
        bash ~/dev/termux-adb-fastboot/install
    fi
}

# --- Phase 5: Configuration Deployment ---
phase5_deploy_configs() {
    log "Phase 5: Deploying configuration files from fun007..."
    DOT_DIR="$LOCAL_REPO/system-admin/dotfiles"
    
    [[ -f "$DOT_DIR/termux/bashrc_SAFE_TMX" ]] && cp "$DOT_DIR/termux/bashrc_SAFE_TMX" ~/.bashrc
    [[ -f "$DOT_DIR/starship.toml" ]] && cp "$DOT_DIR/starship.toml" ~/.config/
    
    mkdir -p ~/.config/fastfetch
    if [[ -f "$DOT_DIR/fastfetch/ff_SAFE_config.jsonc" ]]; then
        cp "$DOT_DIR/fastfetch/ff_SAFE_config.jsonc" ~/.config/fastfetch/config.jsonc
        cp "$DOT_DIR/fastfetch/ascii.txt" ~/.config/fastfetch/ascii.txt
    fi
    
    [[ -f "$DOT_DIR/nanorc_SAFE" ]] && sed 's|/usr/share/nano/|/data/data/com.termux/files/usr/share/nano/|g' "$DOT_DIR/nanorc_SAFE" > ~/.nanorc
    
    if [[ ! -d ~/.config/nvim ]]; then
        git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
    fi
}

# --- Phase 6: Nerd Font Management ---
phase6_fonts() {
    log "Phase 6: Advanced Nerd Font management..."
    
    log "Fetching available fonts from GitHub..."
    local api_response
    api_response=$(curl -s --connect-timeout 10 --max-time 30 \
        "https://api.github.com/repos/ryanoasis/nerd-fonts/contents/patched-fonts?ref=master")

    if [[ $? -ne 0 || -z "$api_response" ]]; then
        warn "Failed to fetch font list. Fallback to JetBrainsMono."
        selected_fonts=("JetBrainsMono")
    else
        fonts=($(echo "$api_response" | awk -F'"' '/name/ {print $4}' | sort))
        printf "%b\n" "${GREEN}Found ${#fonts[@]} available fonts.${NC}"
        
        echo -e "${BLUE}Select fonts (e.g. 1 5), 'all', or 'list':${NC}"
        print_fonts_in_columns "${fonts[@]}" | $PAGER

        while true; do
            echo -ne "${YELLOW}Selection: ${NC}"
            read -r font_selection < /dev/tty
            [[ "$font_selection" == "all" ]] && { selected_fonts=("${fonts[@]}"); break; }
            [[ "$font_selection" == "list" ]] && { print_fonts_in_columns "${fonts[@]}" | $PAGER; continue; }
            
            if [[ -n "$font_selection" ]]; then
                valid=true; selected_fonts=()
                for sel in $font_selection; do
                    if [[ "$sel" =~ ^[0-9]+$ ]] && (( sel > 0 && sel <= ${#fonts[@]} )); then
                        selected_fonts+=("${fonts[sel-1]}")
                    else
                        warn "Invalid index: $sel"; valid=false; break
                    fi
                done
                [[ "$valid" == true ]] && break
            fi
        done
    fi

    for font in "${selected_fonts[@]}"; do
        log "Downloading $font..."
        font_id=$(echo "$font" | awk '{print $1}')
        if curl -s --head --fail "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_id}.zip" >/dev/null 2>&1; then
            curl -sSLo "$HOME/tmp/${font_id}.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_id}.zip"
            unzip -oq "$HOME/tmp/${font_id}.zip" -d ~/.local/share/fonts/
            rm "$HOME/tmp/${font_id}.zip"
        else
            warn "Font $font not found in latest release. Skipping."
        fi
    done
    
    fc-cache -f
    
    log "Setting primary Termux font..."
    # Attempt to find a suitable regular ttf from the installed selection
    find ~/.local/share/fonts -name "*NerdFont*Regular.ttf" | head -n 1 | xargs -I {} cp {} ~/.termux/font.ttf
}

# --- Phase 7: Visual Customization & Finalization ---
phase7_finalize() {
    log "Phase 7: Finalizing visuals and themes..."
    
    THEME_DIR="$LOCAL_REPO/system-admin/termux-setup/colors"
    if [[ -d "$THEME_DIR" ]]; then
        themes=("$THEME_DIR"/*.properties)
        echo "Available themes:"
        for i in "${!themes[@]}"; do
            echo "$((i+1)). $(basename "${themes[$i]}" .properties)"
        done
        read -rp "Select theme number [default: 1]: " t_choice
        selected_theme="${themes[$((t_choice-1))]}"
        [[ -f "$selected_theme" ]] && cp "$selected_theme" ~/.termux/colors.properties
    fi

    termux-reload-settings
    log "Setup Complete! Restart Termux to apply changes."
}

# --- Main Execution ---
main() {
    phase1_bootstrap
    phase2_git_ssh
    phase3_clone_repo
    phase4_install_tools
    phase5_deploy_configs
    phase6_fonts
    phase7_finalize
}

main "$@"
