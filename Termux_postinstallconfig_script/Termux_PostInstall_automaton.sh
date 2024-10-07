#!/data/data/com.termux/files/usr/bin/env bash

# Function to prompt for GitHub configuration
setup_git_config() {
    read -p "Enter your GitHub email address: " email

    echo "Choose your SSH key type:"
    echo "1. Ed25519 (recommended)"
    echo "2. RSA (legacy)"
    read -p "Enter your choice (1 or 2): " key_type

    case $key_type in
        1) key_algo="ed25519" ;;
        2) key_algo="rsa" ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac

    read -p "Enter a custom SSH key name (leave blank for default): " key_name

    ssh_key_path="${HOME}/.ssh/${key_name:-id_$key_algo}"

    ssh-keygen -t $key_algo -C "$email" -f "$ssh_key_path"

    read -p "Do you want to use a passphrase? (y/n): " use_passphrase

    if [ "$use_passphrase" == "y" ]; then
        ssh-add -l &>/dev/null || eval "$(ssh-agent -s)"
        ssh-add "$ssh_key_path"
    else
        echo "Skipping passphrase setup."
    fi

    echo "SSH key generation and setup completed."
}

# Copy SSH public key to clipboard and prompt user to add it to GitHub
copy_and_confirm_ssh_key() {
    # Copy the generated public key to the clipboard
    cat "${ssh_key_path}.pub" | termux-clipboard-set
    echo "Your SSH public key has been copied to the clipboard."

    while true; do
        read -p "Have you pasted your SSH public key into your GitHub account? (y/n): " yn
        case $yn in
            [Yy]* ) echo "Proceeding..."; break;;
            [Nn]* ) echo "Please paste your SSH public key into GitHub and try again."; exit;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done

    # Test the SSH connection with GitHub
    ssh -T git@github.com
}

# Function to install and configure dependencies
install_dependencies() {
    touch ~/.hushlogin
    termux-change-repo
    termux-setup-storage

    apt update && apt upgrade -y
    apt install -y root-repo x11-repo tur-repo glibc-repo myrepos termux-apt-repo \
    bash-completion termux-api bat python python-pip xclip build-essential which \
    openssh curl wget getconf exa multitail tree zoxide fontconfig-utils tmux ripgrep \
    make unzip neovim git elfutils termux-elf-cleaner

    setup_git_config
    copy_and_confirm_ssh_key

    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    sed -i '1s|.*|#!/data/data/com.termux/files/usr/bin/env bash|' ~/.fzf/install
    ~/.fzf/install

    apt install -y starship
    mkdir -p ~/Github && cd ~/Github
    git clone git@github.com:fastfetch-cli/fastfetch.git

    apt install -y mesa mesa-dev vulkan-headers ocl-icd opencl-headers freetype \
    libandroid-wordexp
    cd fastfetch && mkdir -p build && cd build
    cmake .. && cmake --build . --target package && cmake --install . --prefix /data/data/com.termux/files/usr

    cd ~/Github && git clone https://github.com/fam007e/fun007.git
    cp ~/Github/fun007/configs/bashrc_SAFE ~/.bashrc
    mkdir -p ~/.config
    cp ~/Github/fun007/configs/starship.toml ~/.config/
    cd ~/Github/fun007/configs/ && sed 's|/usr/share/nano/|/data/data/com.termux/files/usr/share/nano/|g' nanorc_SAFE > ~/.nanorc

    pip install trash-cli
    source ~/.bashrc
}

# Function to install selected fonts
install_fonts() {
    fonts=(
        "0xProto Nerd Font"
        "3270 Nerd Font"
        "Agave Nerd Font"
        "AnonymicePro Nerd Font"
        "Arimo Nerd Font"
        "BlexMono Nerd Font"
        "CaskaydiaCove Nerd Font"
        "CaskaydiaMono Nerd Font"
        "CodeNewRoman Nerd Font"
        "ComicShannsMono Nerd Font"
        "CommitMono Nerd Font"
        "Cousine Nerd Font"
        "D2Coding Nerd Font"
        "DaddyTimeMono Nerd Font"
        "DejaVuSansMono Nerd Font"
        "EnvyCodeR Nerd Font"
        "FantasqueSansMono Nerd Font"
        "FiraCode Nerd Font"
        "FiraMono Nerd Font"
        "GeistMono Nerd Font"
        "GoMono Nerd Font"
        "Gohu Nerd Font"
        "Hack Nerd Font"
        "Hasklug Nerd Font"
        "Hurmit Nerd Font"
        "iM-Writing Nerd Font"
        "Inconsolata Nerd Font"
        "InconsolataGo Nerd Font"
        "Inconsolata LGC Nerd Font"
        "IntoneMono Nerd Font"
        "Iosevka Nerd Font"
        "IosevkaTerm Nerd Font"
        "IosevkaTermSlab Nerd Font"
        "JetBrainsMono Nerd Font"
        "Lekton Nerd Font"
        "Literation Nerd Font"
        "Lilex Nerd Font"
        "MartianMono Nerd Font"
        "Meslo Nerd Font"
        "Monaspice Nerd Font"
        "Monofur Nerd Font"
        "Monoid Nerd Font"
        "Mononoki Nerd Font"
        "Noto Nerd Font"
        "OpenDyslexic Nerd Font"
        "Overpass Nerd Font"
        "ProFont Nerd Font"
        "ProggyClean Nerd Font"
        "RobotoMono Nerd Font"
        "SauceCodePro Nerd Font"
        "ShureTechMono Nerd Font"
        "SpaceMono Nerd Font"
        "Terminess Nerd Font"
        "Tinos Nerd Font"
        "Ubuntu Nerd Font"
        "UbuntuMono Nerd Font"
        "VictorMono Nerd Font"
    )

    echo "Select fonts to install (separate with spaces):"
    echo "---------------------------------------------"
    for i in "${!fonts[@]}"; do
        echo " $i  -  ${fonts[i]}"
    done
    echo "---------------------------------------------"
    read -rp "Enter the numbers of the fonts to install (e.g., '0 1 2'): " font_selection

    for selection in $font_selection; do
        font=${fonts[$selection]}
        echo "Downloading and installing $font..."
        font_name=$(echo "$font" | awk '{print $1}')
        wget -q --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font_name.tar.xz" -P $HOME/tmp
        tar -xf "$HOME/tmp/$font_name.tar.xz" -C "$HOME/.local/share/fonts"
        rm "$HOME/tmp/$font_name.tar.xz"
    done

    fc-cache -vf
}

# Function to select a font for use in Termux
select_font_for_termux() {
    local font_dir="$HOME/.local/share/fonts"
    local fonts=("$font_dir"/*)

    echo "Available fonts:"
    for i in "${!fonts[@]}"; do
        echo "$((i + 1)). $(basename "${fonts[$i]}")"
    done

    local choice
    read -p "Enter the number of the font you want to use for Termux: " choice

    local selected_font="${fonts[$((choice - 1))]}"

    if [[ -z "$selected_font" || ! -f "$selected_font" ]]; then
        echo "Invalid selection. Exiting."
        exit 1
    fi

    echo "You selected: $(basename "$selected_font")"
    cp "$selected_font" ~/.termux/font.ttf
}

# Function to list and select a theme
select_theme_for_termux() {
    local theme_dir="$HOME/Github/fun007/Termux_postinstallconfig_script/colors"
    local themes=("$theme_dir"/*.properties)

    echo "Available themes:"
    for i in "${!themes[@]}"; do
        echo "$((i + 1)). $(basename "${themes[$i]}" .properties)"
    done

    local choice
    read -p "Enter the number of the theme you want to use for Termux: " choice

    local selected_theme="${themes[$((choice - 1))]}"

    if [[ -z "$selected_theme" || ! -f "$selected_theme" ]]; then
        echo "Invalid selection. Exiting."
        exit 1
    fi

    echo "You selected: $(basename "$selected_theme" .properties)"
    cp "$selected_theme" ~/.termux/colors.properties
}

# Main execution
install_dependencies
install_fonts
select_font_for_termux
select_theme_for_termux

# Final setup
git clone https://github.com/christitustech/mybash.git ~/Github/mybash
mkdir -p ~/.config/{fastfetch,nvim}
cp ~/Github/mybash/config.jsonc ~/.config/fastfetch/
git clone https://github.com/nvim-lua/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
