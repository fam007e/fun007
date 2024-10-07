#!/usr/bin/env python3

import os
from pathlib import Path
import subprocess
from itertools import chain

# Prompt user for the wallpaper directory relative to home
RELATIVE_WALLPAPER_DIR = input("Enter the wallpaper directory relative to $HOME/: ")
WALLPAPER_DIR = os.path.join(str(Path.home()), RELATIVE_WALLPAPER_DIR)

# Check if the directory exists
if not os.path.isdir(WALLPAPER_DIR):
    print(f"Directory not found: {WALLPAPER_DIR}")
    exit(1)

# Function to get dimensions with validation
def get_dimensions():
    MIN_WIDTH = int(input("Enter the minimum width in pixels: "))
    MIN_HEIGHT = int(input("Enter the minimum height in pixels: "))
    return MIN_WIDTH, MIN_HEIGHT

# Get initial dimensions from the user
MIN_WIDTH, MIN_HEIGHT = get_dimensions()

# Prompt user to confirm or change dimensions
while True:
    print(f"You have entered:\nMinimum width: {MIN_WIDTH} pixels\nMinimum height: {MIN_HEIGHT} pixels")
    CONFIRMATION = input("Do you want to proceed with these values? (yes/no): ").lower()
    if CONFIRMATION.startswith('y'):
        break
    elif CONFIRMATION.startswith('n'):
        MIN_WIDTH, MIN_HEIGHT = get_dimensions()
    else:
        print("Please answer yes or no.")

# Change to the wallpaper directory
os.chdir(WALLPAPER_DIR)

# Loop through each image in the directory
for image in chain(Path(".").glob("*.jpg"), Path(".").glob("*.jpeg"), Path(".").glob("*.png"), Path(".").glob("*.svg")):
    image = str(image)
    try:
        # Get image dimensions
        width = subprocess.check_output(["exiftool", "-ImageWidth", "-b", image]).strip().decode()
        height = subprocess.check_output(["exiftool", "-ImageHeight", "-b", image]).strip().decode()

        # Check if dimensions are less than specified
        if int(width) < MIN_WIDTH or int(height) < MIN_HEIGHT:
            print(f"Deleting {image} with dimensions {width}x{height}")
            os.remove(image)
        else:
            # Remove all metadata from the image
            subprocess.run(["exiftool", "-all=", image])
            # Overwrite the original file without creating a backup
            subprocess.run(["exiftool", "-overwrite_original", image])
            print(f"Metadata removed from {image} with dimensions {width}x{height}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to process {image}: {e}")
    except ValueError as e:
        print(f"Invalid dimensions for {image}: {e}")
