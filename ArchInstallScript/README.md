# Automated Arch Linux Installer

This project provides an automated installation process for Arch Linux, with support for various configurations including Btrfs, ext4, and LUKS encryption. It now features both an interactive and a non-interactive installation method.

## Features

- User-friendly interface with menu-driven options
- Support for both BIOS and UEFI systems
- Filesystem options: Btrfs, ext4, and LUKS encryption
- Automatic detection and installation of appropriate microcode (Intel/AMD)
- NVIDIA driver installation with options for LTS and latest kernels
- Secondary disk setup for user directories
- Customizable username, password, and hostname
- Automatic timezone and keyboard layout detection
- GRUB bootloader installation and theming
- New: Interactive configuration generation
- New: Non-interactive installation using JSON configuration

## Prerequisites

- A bootable Arch Linux ISO
- Internet connection
- Basic knowledge of Arch Linux and its installation process

## Usage

### Interactive Installation

1. Boot into the Arch Linux live environment
2. Download the interactive installation script:
   ```
   curl -O https://raw.githubusercontent.com/fam007e/fun007/master/ArchInstallScript/Interactive_install/archinstall_interactive.sh
   ```
3. Make the script executable:
   ```
   chmod +x archinstall_interactive.sh
   ```
4. Run the script:
   ```
   ./archinstall_interactive.sh
   ```
5. Follow the on-screen prompts to configure your installation

### Non-Interactive Installation

1. Generate a configuration file:
   ```
   curl -O https://raw.githubusercontent.com/fam007e/fun007/master/ArchInstallScript/Interactive_install/generate_config.sh
   chmod +x generate_config.sh
   ./generate_config.sh
   ```
2. Download the main installation script:
   ```
   curl -O https://raw.githubusercontent.com/fam007e/fun007/master/ArchInstallScript/archinstall.sh
   ```
3. Make the script executable:
   ```
   chmod +x archinstall.sh
   ```
4. Set the necessary environment variables:
   ```
   export PASSWORD='your_password'
   export LUKS_PASSWORD='your_luks_password'
   ```
5. Run the installation script with the generated config:
   ```
   ./archinstall.sh config.json
   ```

## Customization

You can modify the scripts to add or remove packages, change default settings, or add additional configuration steps as needed.

## Caution

This script will format the selected disk(s) and install Arch Linux. Make sure to back up any important data before running the script.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This script is distributed under the MIT License. Please see the [LICENSE](../LICENSE) file for more details.

## Credits

This Arch Linux automated installation script is adapted from the work of [Chris Titus Tech](https://github.com/ChrisTitusTech). The original script can be found in the [linutil repository](https://github.com/ChrisTitusTech/linutil/blob/main/src/commands/system-setup/arch/server-setup.sh).

Special thanks to Chris Titus for providing a comprehensive and flexible installation script that has been a valuable reference for creating this version with added support for Btrfs and LUKS encryption.

Additional improvements and the new interactive/non-interactive approach were inspired by suggestions from [J_H on Stack Exchange](https://codereview.stackexchange.com/users/145459/j-h). We greatly appreciate their valuable input and recommendations for enhancing the script's functionality and user experience.

For more information and contributions, please visit [Chris Titus Tech's GitHub](https://github.com/ChrisTitusTech).