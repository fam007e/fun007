# fun007 Arch Linux Installer

## Overview

`archinstall_interactive.sh` is a modular, automated installer designed to deploy a "Ready-to-Work" Arch Linux system. It specializes in **LUKS-encrypted BTRFS** setups and is tightly integrated with the `fun007` ecosystem.

Unlike traditional monolithic installers, this suite follows a phased approach:
1.  **Hardware & Disk Phase**: Handles partitioning, LUKS encryption, and BTRFS subvolume mapping.
2.  **Bootstrap Phase**: Installs the core Arch Linux base and kernel.
3.  **fun007 Handover**: Clones the `fun007` repository and executes the `zshrc_pkg_prep.sh` script to configure your shell, packages, and desktop.

## Features

- **Storage Architecture**: 
  - Supports standard **BTRFS** or **LUKS-on-BTRFS**.
  - Creates the `@`, `@home`, `@var`, `@tmp`, and `@.snapshots` subvolume layout required for **Timeshift**.
- **Hardware Optimization**: 
  - Automatic GPU detection (NVIDIA/AMD/Intel).
  - Handles NVIDIA-LTS driver mapping if the LTS kernel is selected.
  - Applies `zstd` compression and `noatime` mount options for SSD longevity.
- **fun007 Integration**: 
  - Automatically clones your dotfiles and runs the environment preparation script.
  - Sets up your Zsh configuration, Oh-My-Posh, and essential CLI tools.
- **Reliable Boot**: 
  - Handles UUID-based LUKS mapping in GRUB.
  - Configures the necessary `encrypt` hooks in `mkinitcpio`.

## Requirements

- **Environment**: Must be run from an Arch Linux Live ISO.
- **Dependencies**: The script will automatically install `jq` and `reflector` in the live environment.
- **Internet**: Required for `pacstrap` and cloning the `fun007` repository.

## Installation Steps

### 1. Generate Configuration
Run the interactive wizard to define your system identity and disk layout:
```bash
sudo ./generate_config.sh
```

### 2. Run the Installer
Execute the main installer using the generated `config.json`:
```bash
sudo ./archinstall_interactive.sh config.json
```

### 3. Log Tracking
The installation process is logged in real-time to:
`/tmp/arch_install_YYYYMMDD_HHMMSS.log`

## Configuration Schema

The `config.json` produced by the wizard includes:
```json
{
    "username": "your_user",
    "password": "your_password",
    "hostname": "your_host",
    "timezone": "Region/City",
    "disk": "/dev/nvme0n1",
    "filesystem": "luks|btrfs",
    "luks_password": "your_secret_password",
    "kernel": "linux|linux-lts"
}
```

## Post-Installation

Once the system reboots:
1.  **Shell**: Your Zsh environment will be ready with the `fun007` prompt.
2.  **Snapshots**: Timeshift is pre-installed. Run `sudo timeshift --list` to verify.
3.  **Packages**: The system will have all essential CLI tools (eza, bat, fzf, zoxide) pre-configured via the `zshrc_pkg_prep.sh` routine.

## Support & Troubleshooting
If the installation fails during the **Chroot Phase**, check the logs in the live environment's `/tmp/` directory. The most common failures are network timeouts during the AUR build phase of the `fun007` handover.
