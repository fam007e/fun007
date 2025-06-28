# WP Cleaner

**WP Cleaner** is a Python tool designed to clean wallpapers by removing unnecessary metadata (such as EXIF data) and filtering based on specific dimensions. This tool is particularly useful for users who want to optimize their wallpaper collections by reducing file size and maintaining only high-quality images.

## Features

- **Interactive**: Allows the user to specify the wallpaper directory and minimum dimensions interactively.
- **Confirmation**: Prompts the user to confirm or change the entered dimensions before proceeding with the cleanup process.
- **File Type Support**: Handles `.jpg`, `.jpeg`, `.png`, and `.svg` image files.
- **Metadata Removal**: Removes all metadata from images that meet the minimum dimension criteria.
- **Batch Processing**: Clean multiple wallpapers at once.
- **ExifTool Integration**: Utilizes `ExifTool` for efficient metadata removal.

## Prerequisites

- **Python** 3.6 or higher
- **ExifTool** must be installed for metadata removal. You can install it using your system's package manager:
  - **Debian/Ubuntu**: `sudo apt-get install exiftool`
  - **Fedora**: `sudo dnf install perl-Image-ExifTool`
  - **Arch**: `sudo pacman -S exiftool`
  - **macOS**: `brew install exiftool`
  
  Alternatively, you can download ExifTool from the [ExifTool website](https://exiftool.org/) for other platforms.

## Installation

1. Fork/clone or download the `wp_cleaner` repository to your local machine:
   ```sh
   git clone https://github.com/yourusername/fun007/wp_cleaner.git
   cd wp_cleaner
   ```
2. Install the package:
   ```sh
   python3 setup.py install
   ```
   During the installation process, the script will attempt to install `ExifTool` if it's not already present on your system.   

## Usage

- Run the wp_cleaner command:
  ```sh
  wp_cleaner
  ```
- Follow the on-screen prompts to specify the wallpaper directory relative to your home directory, as well as the minimum width and height in pixels for the images. Confirm or change the entered dimensions before proceeding with the clean-up process.

## License
This project is licensed under the [LICENSE](../LICENSE).
