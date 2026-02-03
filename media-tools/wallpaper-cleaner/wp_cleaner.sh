#!/usr/bin/bash

# Prompt user for the wallpaper directory relative to home
read -rp "Enter the wallpaper directory relative to \$HOME/: " RELATIVE_WALLPAPER_DIR
WALLPAPER_DIR="$HOME/$RELATIVE_WALLPAPER_DIR"

# Check if the directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Directory not found: $WALLPAPER_DIR"
    exit 1
fi

# Function to get dimensions with validation
get_dimensions() {
    read -rp "Enter the minimum width in pixels: " MIN_WIDTH
    read -rp "Enter the minimum height in pixels: " MIN_HEIGHT
}

# Get initial dimensions from the user
get_dimensions

# Prompt user to confirm or change dimensions
while true; do
    echo "You have entered:"
    echo "Minimum width: $MIN_WIDTH pixels"
    echo "Minimum height: $MIN_HEIGHT pixels"
    read -rp "Do you want to proceed with these values? (yes/no): " CONFIRMATION
    case $CONFIRMATION in
        [Yy]* ) break;;
        [Nn]* ) get_dimensions;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Change to the wallpaper directory
cd "$WALLPAPER_DIR" || { echo "Failed to change directory to $WALLPAPER_DIR"; exit 1; }

# Loop through each image in the directory
find . -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.svg' \) | while read -r image; do
    # Get image dimensions
    width=$(exiftool -ImageWidth -b "$image")
    height=$(exiftool -ImageHeight -b "$image")

    # Check if dimensions are less than specified
    if [ "$width" -lt "$MIN_WIDTH" ] || [ "$height" -lt "$MIN_HEIGHT" ]; then
        echo "Deleting $image with dimensions ${width}x${height}"
        rm "$image"
    else
        # Remove all metadata from the image
        exiftool -all= "$image"
        # Overwrite the original file without creating a backup
        exiftool -overwrite_original "$image"
        echo "Metadata removed from $image with dimensions ${width}x${height}"
    fi
done
