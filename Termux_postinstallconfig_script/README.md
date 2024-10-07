# Termux Post-Install Automation Script

This script automates the setup of a Termux environment, including GitHub SSH key configuration, installation of essential dependencies, font management, and final customizations.

## Features

- **GitHub SSH Key Setup:**
  - Prompts for GitHub email address.
  - Allows selection of SSH key type (Ed25519 or RSA).
  - Option to use a passphrase for the SSH key.

- **Dependency Installation:**
  - Installs various Termux repositories and essential packages like `bash-completion`, `git`, `curl`, `wget`, `tmux`, `neovim`, and more.
  - Clones and installs [fzf](https://github.com/junegunn/fzf) and [fastfetch](https://github.com/fastfetch-cli/fastfetch).

- **Font Management:**
  - Allows the user to select and install Nerd Fonts from a predefined list.
  - Provides a menu to choose the default font for Termux from installed fonts.

- **Final Customizations:**
  - Copies custom configuration files for Bash, Starship prompt, Nano editor, and Termux color scheme.
  - Sets up a fastfetch configuration for system information display.

## Usage

1. **Run the script:**
   - Execute the script in Termux after installation. It will guide you through each step, including GitHub SSH key setup and font selection.

2. **GitHub SSH Key Setup:**
   - Enter your GitHub email.
   - Choose your preferred SSH key type.
   - Optionally set a passphrase for added security.

3. **Dependency Installation:**
   - The script will automatically install necessary packages and clone relevant repositories.

4. **Font Management:**
   - Choose the fonts you want to install from the list.
   - Select a font to use as the default for Termux.

5. **Final Customizations:**
   - The script will copy configuration files and set up the environment as per your preferences.

## Customization

You can modify the script to suit your specific needs, such as changing the list of fonts, dependencies, or configuration files.

## Requirements

- Termux and its API app installed on your Android device.

## License

This script is provided as-is, without any warranty. Feel free to modify and distribute it according to your needs. See the [LICENSE](../LICENSE) file for more information.
