# Wallpaper Cleaner Script

The Wallpaper Cleaner Script (`wp_cleaner.sh`) is a Bash script designed to help users manage their wallpaper collections by removing images that do not meet specified minimum dimensions and removing metadata from the remaining images.

## Features

- **Interactive**: Allows the user to specify the wallpaper directory and minimum dimensions interactively.
- **Confirmation**: Prompts the user to confirm or change the entered dimensions before proceeding with the cleanup process.
- **File Type Support**: Handles `.jpg`, `.jpeg`, `.png`, and `.svg` image files.
- **Metadata Removal**: Removes all metadata from images that meet the minimum dimension criteria.
- **Ease of Use**: Simple to run and understand, with clear prompts and messages.

## Prerequisites

- **Bash**: The script is written in Bash, so it requires a Bash-compatible shell environment.
- **exiftool**: The script uses `exiftool` to extract image dimensions and remove metadata. Make sure `exiftool` is installed on your system. You can install it using your system's package manager (`sudo apt-get install exiftool` for Debian/Ubuntu or `brew install exiftool` for macOS).

## Usage

1. Clone or download the `wp_cleaner.sh` script to your local machine.
2. Make the script executable:
   ```sh chmod +x wp_cleaner.sh```
3. Run the script:
  ```sh ./wp_cleaner.sh```

Follow the on-screen prompts to specify the wallpaper directory relative to your home directory, as well as the minimum width and height in pixels for the images. Confirm or change the entered dimensions before proceeding with the cleanup process.

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request on GitHub.

## License

This project is licensed under the [MIT License](LICENSE).
