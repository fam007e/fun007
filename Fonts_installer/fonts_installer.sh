#!/usr/bin/env zsh

# Function to display font selection menu
show_font_menu() {
    echo "Select fonts to install (separate with spaces):"
    echo "---------------------------------------------"
    echo " 0  -  0xProto Nerd Font"
    echo " 1  -  3270 Nerd Font"
    echo " 2  -  Agave Nerd Font"
    echo " 3  -  AnonymicePro Nerd Font"
    echo " 4  -  Arimo Nerd Font"
    echo " 5  -  BlexMono Nerd Font"
    echo " 6  -  CascadiaCode Nerd Font"
    echo " 7  -  CascadiaMono Nerd Font"
    echo " 8  -  CodeNewRoman Nerd Font"
    echo " 9  -  ComicShannsMono Nerd Font"
    echo "10  -  CommitMono Nerd Font"
    echo "11  -  Cousine Nerd Font"
    echo "12  -  D2Coding Nerd Font"
    echo "13  -  DaddyTimeMono Nerd Font"
    echo "14  -  DejaVuSansMono Nerd Font"
    echo "15  -  EnvyCodeR Nerd Font"
    echo "16  -  FantasqueSansMono Nerd Font"
    echo "17  -  FiraCode Nerd Font"
    echo "18  -  FiraMono Nerd Font"
    echo "19  -  GeistMono Nerd Font"
    echo "20  -  GoMono Nerd Font"
    echo "21  -  Gohu Nerd Font"
    echo "22  -  Hack Nerd Font"
    echo "23  -  Hasklug Nerd Font"
    echo "24  -  Hurmit Nerd Font"
    echo "25  -  iM-Writing Nerd Font"
    echo "26  -  Inconsolata Nerd Font"
    echo "27  -  InconsolataGo Nerd Font"
    echo "28  -  Inconsolata LGC Nerd Font"
    echo "29  -  IntoneMono Nerd Font"
    echo "30  -  Iosevka Nerd Font"
    echo "31  -  IosevkaTerm Nerd Font"
    echo "32  -  IosevkaTermSlab Nerd Font"
    echo "33  -  JetBrainsMono Nerd Font"
    echo "34  -  Lekton Nerd Font"
    echo "35  -  Literation Nerd Font"
    echo "36  -  Lilex Nerd Font"
    echo "37  -  MartianMono Nerd Font"
    echo "38  -  Meslo Nerd Font"
    echo "39  -  Monaspice Nerd Font"
    echo "40  -  Monofur Nerd Font"
    echo "41  -  Monoid Nerd Font"
    echo "42  -  Mononoki Nerd Font"
    echo "43  -  Noto Nerd Font"
    echo "44  -  OpenDyslexic Nerd Font"
    echo "45  -  Overpass Nerd Font"
    echo "46  -  ProFont Nerd Font"
    echo "47  -  ProggyClean Nerd Font"
    echo "48  -  RobotoMono Nerd Font"
    echo "49  -  SauceCodePro Nerd Font"
    echo "50  -  ShureTechMono Nerd Font"
    echo "51  -  SpaceMono Nerd Font"
    echo "52  -  Terminess Nerd Font"
    echo "53  -  Tinos Nerd Font"
    echo "54  -  Ubuntu Nerd Font"
    echo "55  -  UbuntuMono Nerd Font"
    echo "56  -  VictorMono Nerd Font"
    echo "---------------------------------------------"
}

# Install required packages
sudo apt install -y unzip fonts-recommended fonts-ubuntu fonts-font-awesome fonts-terminus

# Create directory for fonts if it doesn't exist
mkdir -p ~/.local/share/fonts

# Display font selection menu
show_font_menu

# Prompt user to select fonts
read -rp "Enter the numbers of the fonts to install (e.g., '0 1 2'): " font_selection

# Define fonts array based on user selection
fonts=()
for index in ${(z)font_selection}
do
    case $index in
        0) fonts+="'0xProto'";;
        1) fonts+="'3270'";;
        2) fonts+="'Agave'";;
        3) fonts+="'AnonymicePro'";;
        4) fonts+="'Arimo'";;
        5) fonts+="'BlexMono'";;
        6) fonts+="'CascadiaCode'";;
        7) fonts+="'CascadiaMono'";;
        8) fonts+="'CodeNewRoman'";;
        9) fonts+="'ComicShannsMono'";;
        10) fonts+="'CommitMono'";;
        11) fonts+="'Cousine'";;
        12) fonts+="'D2Coding'";;
        13) fonts+="'DaddyTimeMono'";;
        14) fonts+="'DejaVuSansMono'";;
        15) fonts+="'EnvyCodeR'";;
        16) fonts+="'FantasqueSansMono'";;
        17) fonts+="'FiraCode'";;
        18) fonts+="'FiraMono'";;
        19) fonts+="'GeistMono'";;
        20) fonts+="'GoMono'";;
        21) fonts+="'Gohu'";;
        22) fonts+="'Hack'";;
        23) fonts+="'Hasklug'";;
        24) fonts+="'Hurmit'";;
        25) fonts+="'iM-Writing'";;
        26) fonts+="'Inconsolata'";;
        27) fonts+="'InconsolataGo'";;
        28) fonts+="'Inconsolata LGC'";;
        29) fonts+="'IntoneMono'";;
        30) fonts+="'Iosevka'";;
        31) fonts+="'IosevkaTerm'";;
        32) fonts+="'IosevkaTermSlab'";;
        33) fonts+="'JetBrainsMono'";;
        34) fonts+="'Lekton'";;
        35) fonts+="'Literation'";;
        36) fonts+="'Lilex'";;
        37) fonts+="'MartianMono'";;
        38) fonts+="'Meslo'";;
        39) fonts+="'Monaspice'";;
        40) fonts+="'Monofur'";;
        41) fonts+="'Monoid'";;
        42) fonts+="'Mononoki'";;
        43) fonts+="'Noto'";;
        44) fonts+="'OpenDyslexic'";;
        45) fonts+="'Overpass'";;
        46) fonts+="'ProFont'";;
        47) fonts+="'ProggyClean'";;
        48) fonts+="'RobotoMono'";;
        49) fonts+="'SauceCodePro'";;
        50) fonts+="'ShureTechMono'";;
        51) fonts+="'SpaceMono'";;
        52) fonts+="'Terminess'";;
        53) fonts+="'Tinos'";;
        54) fonts+="'Ubuntu'";;
        55) fonts+="'UbuntuMono'";;
        56) fonts+="'VictorMono'";;
    esac
done

# Download and install selected fonts
for font in ${fonts[@]}
do
    wget "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.tar.xz"
    tar -xf "$font.tar.xz" -C "$HOME/.local/share/fonts/"
    rm "$font.tar.xz"
done

# Update font cache
fc-cache -fv
