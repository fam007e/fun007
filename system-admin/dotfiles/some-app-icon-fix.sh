#!/bin/bash
set -e

declare -A ICONS=(
    ["proton-vpn-logo"]="/usr/share/icons/hicolor/scalable/apps/proton-vpn-logo.svg"
    ["fr.handbrake.ghb"]="/usr/share/icons/hicolor/scalable/apps/fr.handbrake.ghb.svg"
    ["gammastep"]="/usr/share/icons/hicolor/scalable/apps/gammastep.svg"
    ["looking-glass"]="/usr/share/icons/hicolor/scalable/apps/looking-glass.svg"
    ["rofi"]="/usr/share/icons/hicolor/scalable/apps/rofi.svg"
)

for name in "${!ICONS[@]}"; do
    svg="${ICONS[$name]}"
    png="/usr/share/icons/hicolor/64x64/apps/${name}.png"
    if [[ -f "$svg" && ! -f "$png" ]]; then
        rsvg-convert -w 64 -h 64 "$svg" -o "/tmp/${name}.png"
        sudo install -Dm644 "/tmp/${name}.png" "$png"
        echo "Installed: $png"
    fi
done

# JADX
sudo curl -L "https://raw.githubusercontent.com/skylot/jadx/master/jadx-gui/src/main/resources/logos/jadx-logo.png" \
    -o /usr/share/icons/hicolor/64x64/apps/jadx.png

sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor
echo "Cache rebuilt."
