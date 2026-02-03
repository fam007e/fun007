# Arch Linux Installation Script

## Overview

`archinstall_interactive.sh` is an automated script for installing Arch Linux with support for BTRFS or LUKS-encrypted BTRFS filesystems, and either the DWM (Dynamic Window Manager) or Hyprland desktop environments. It configures a minimal system with essential packages, graphics drivers, and customizations for the DWM setup from `https://github.com/fam007e/DWM`. The script supports SDDM for autologin, Timeshift for BTRFS snapshots, and a secondary disk for data storage.

## Features

- **Filesystem Options**: Supports BTRFS, LUKS-encrypted BTRFS, or ext4.
- **Desktop Environments**: Installs DWM (`fam007e/DWM`) or Hyprland.
- **DWM Customization**:
  - Clones `https://github.com/fam007e/DWM` to `/home/$USERNAME/DWM`.
  - Builds `picom`, `slstatus`, and `dwmblocks` in `/home/$USERNAME/dev`.
  - Installs dependencies: `xorg`, `libx11`, `libxinerama`, `libxft`, `libxpm`, `libxrandr`, `libxcb`, `imlib2`, `fontconfig`, `noto-fonts-emoji`, `flameshot`, `dunst`, `alacritty`, `rofi`, `alsa-utils`, `pulseaudio`, `playerctl`, `vlc`, `slock`, `thunar`, `feh`, `dbus`, `polkit`, `mate-polkit`, `bc`, `jq`.
  - Installs AUR packages: `nerd-fonts-complete`, `brave-browser-nightly`, `tor-browser`, `looking-glass-client`, `zed-git`.
  - Sets up `zed` symlink (`/usr/bin/zeditor` to `/home/$USERNAME/.local/bin/zed`).
  - Configures DWM scripts in `/home/$USERNAME/DWM/scripts/`.
- **System Configuration**: Sets up timezone, locale, hostname, user account, NetworkManager, GRUB, microcode, and graphics drivers (NVIDIA, AMD, or Intel).
- **Secondary Disk**: Optionally configures a data disk with bind mounts for user directories.
- **Timeshift**: Configures BTRFS snapshots with daily, weekly, and boot schedules.
- **SDDM**: Optional autologin with SDDM for DWM or Hyprland.

## Requirements

- **Environment**: Must be run from an Arch Linux ISO (live environment).
- **Root Access**: Run as root (`sudo ./archinstall_interactive.sh config.json`).
- **Internet Connection**: Required for package installation and AUR builds.
- **Disk Space**: At least 20GB for the root partition; additional space for AUR builds (e.g., `nerd-fonts-complete`, `zed-git`).
- **Configuration File**: A `config.json` file with the following fields:
  ```json
  {
    "username": "your_username",
    "password": "your_password",
    "hostname": "your_hostname",
    "timezone": "Region/City",
    "keymap": "us",
    "filesystem": "btrfs|ext4|luks",
    "desktop": "dwm|hyprland",
    "use_sddm": "y|n",
    "disk": "/dev/sdX|/dev/nvmeXn1",
    "secondary_disk": "/dev/sdY|/dev/nvmeXn1|",
    "is_ssd": "y|n",
    "kernel": "linux|linux-lts",
    "luks_password": "your_luks_password"
  }
  ```
  Use `generate_config.sh` to create this file.

## Usage

- **Boot Arch Linux ISO**: Boot into the Arch Linux live environment.
- **Prepare Config**: Prepare the configuration file `config.json` with the desired settings.
- **Run generate_config.sh**: Run `generate_config.sh` to create the `config.json` file.
- **Edit config.json**: Edit the `config.json` file with your desired settings (e.g., `desktop="dwm"`, `filesystem="btrfs"`).
- **Run Script**: Run the script with
  ```sh
  ./archinstall_interactive.sh config.json
  ```
  - The script will prompt for confirmation before formatting disks.
  - Logs are saved to /tmp/arch_install_YYYYMMDD_HHMMSS.log.
- **Reboot**: The system reboots automatically after installation.

## Post-Installation Steps

- **Verify DWM Setup** (if `desktop="dwm"`):
  - Log in via `SDDM` (if `use_sddm="y"`) or run startx from the console.
  - Check autostart programs: `alacritty`, `dunst`, `flameshot`, `picom`, `slstatus`, `dwmblocks`.
  - Test keybindings (from `config.def.h`):
    - `Mod4+r`: Launch `rofi -show drun`.
    - `Mod4+z`: Launch `zed`.
    - `Mod4+Shift+w`: Launch `brave-browser-nightly`.
    - `Mod4+Shift+v`: Launch `vlc`.
  - Verify scripts in `/home/$USERNAME/DWM/scripts/` (e.g., `wallpapersSS`, `status`).
- **Add Wallpapers**:
  - The script creates `/home/$USERNAME/Pictures/Wallpapers/` but does not populate it.
  - Add wallpaper images to this directory for use with `wallpapersSS` and `feh`.
- **Check Timeshift** (if `filesystem="btrfs"` or `luks`):
  - Run `sudo timeshift --list` to verify snapshot schedules.
- **Troubleshooting**:
  - **Missing Scripts**: If `/home/$USERNAME/DWM/scripts/` is empty, manually add scripts (`wallpapersSS`, `status`, `sounds`, `wifimenu`, `powermenu`, `protonrestart`) from the DWM repository or your source.
  - **Zed Failure**: If `Mod4+z` fails, verify `/usr/bin/zeditor` exists and the symlink `/home/$USERNAME/.local/bin/zed` is correct.
  - **AUR Build Issues**: If `zed-git` or `nerd-fonts-complete` fails, ensure sufficient disk space and network connectivity. Re-run `yay -S zed-git` manually.
  - **Vulkan Drivers**: If `zed` crashes, install GPU-specific Vulkan drivers (e.g., `vulkan-intel`, `vulkan-radeon`).

## Notes

- **DWM Scripts**: The script assumes `https://github.com/fam007e/DWM` includes a `scripts/` directory. If missing, keybindings and autostart programs may fail.
- **Zed Editor**: `zed-git` installs zeditor in `/usr/bin/`. A symlink to `/home/$USERNAME/.local/bin/zed` is created for compatibility with `config.def.h`.
- **AUR Builds**: Building `zed-git` and `nerd-fonts-complete` may take significant time and disk space.
- **Vulkan Drivers**: The script installs `vulkan-icd-loader` and `vulkan-tools`. Install GPU-specific drivers if needed.
- **Dwmblocks**: Uses `torrinfail/dwmblocks`. If a different fork is required, update the script with the correct repository URL.

## License

This script is provided under the MIT License. See the [fam007e/DWM](https://github.com/fam007e/DWM) repository for its license details.

## Support

For issues or customizations (e.g., alternative `dwmblocks` fork, `protonvpn-app` integration), check the log file in `/tmp/` or contact the script maintainer.
