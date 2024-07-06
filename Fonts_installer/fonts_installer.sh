#!/data/data/com.termux/files/usr/bin/env bash

# Install necessary packages
#sudo apt install -y unzip fonts-recommended fonts-ubuntu fonts-font-awesome fonts-terminus

# Create directory for fonts
mkdir -p ~/.local/share/fonts

# List of available fonts
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

# Display menu of available fonts
echo "Select fonts to install (separate with spaces):"
echo "---------------------------------------------"
for i in "${!fonts[@]}"; do
    echo " $i  -  ${fonts[i]}"
done
echo "---------------------------------------------"

# Prompt user to select fonts
read -rp "Enter the numbers of the fonts to install (e.g., '0 1 2'): " font_selection

# Download and install selected fonts
for selection in $font_selection; do
    font=${fonts[$selection]}
    echo "Downloading and installing $font..."
    font_name=$(echo "$font" | awk '{print $1}')
    wget -q --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font_name.tar.xz" -P $HOME/tmp
    tar -xf "$HOME/tmp/$font_name.tar.xz" -C "$HOME/.local/share/fonts"
    rm "$HOME/tmp/$font_name.tar.xz"
done

# Update font cache
fc-cache -vf
