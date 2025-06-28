# Zsh Configuration README

This README provides an overview of the custom aliases and functions defined in the zshrc configuration file.

## Table of Contents
1. [File Management](#file-management)
2. [System Commands](#system-commands)
3. [Network and Internet](#network-and-internet)
4. [Development Tools](#development-tools)
5. [Archiving and Compression](#archiving-and-compression)
6. [Miscellaneous](#miscellaneous)

## File Management

- `ls`: List directory contents using `eza`
- `ll`: List directory contents in long format using `eza`
- `tree`: Display directory structure as a tree using `eza`
- `cp`: Copy with interactive mode and reflink
- `rcp`: Copy using rsync with progress
- `rmv`: Move using rsync with progress and remove source
- `mv`: Move with interactive mode
- `mkdir`: Create directory with verbose output
- `chmod`, `chown`: Change permissions/ownership with verbose output
- `cpp`: Copy file with progress bar
- `cpg`: Copy and go to the directory
- `mvg`: Move and go to the directory
- `mkdirg`: Create and go to the directory

## System Commands

- `reboot`, `shutdown`: System reboot and shutdown
- `ezrc`: Edit zshrc file
- `hlp`: Display zshrc aliases help
- `c`: Clear terminal
- `x`: Exit terminal
- `da`: Display current date and time
- `ff`: Run fastfetch with custom configuration
- `ff-upd`: Update and rebuild fastfetch

## Network and Internet

- `ping`: Ping with 10 count limit
- `whatismyip`, `external_ip`: Show external IP address
- `show_connections`: Display established connections with resolved names
- `openports`: Show open ports
- `kssh`: SSH using kitty terminal

## Development Tools

- `vi`, `vim`: Open Neovim
- `svi`: Open Neovim with sudo
- `vis`: Open Neovim with 'set si' option
- `genSRCINFO`: Generate SRCINFO file for AUR packages
- `gcom`: Git add and commit
- `lazyg`: Git add, commit, and push

## Archiving and Compression

- `mktar`, `mkbz2`, `mkgz`: Create various archive types
- `untar`, `unbz2`, `ungz`: Extract various archive types
- `extract`: Universal extraction function for multiple archive types
- `mkcryptgz`: Compress, encrypt, and remove original directory
- `ungpgextract`: Decrypt, extract, and remove decrypted archive

## Miscellaneous

- `ftext`: Search for text in all files in current folder
- `up`: Go up multiple directory levels
- `distribution`, `ver`: Show system distribution and version
- `apachelog`, `apacheconfig`: View/edit Apache logs and configuration
- `phpconfig`, `mysqlconfig`: Edit PHP and MySQL configurations
- `trim`: Trim leading and trailing spaces
- `cloudflare_dns`, `quad9_dns`: Switch to specified DNS servers

Note: This README doesn't cover all aliases and functions. Refer to the zshrc file for a complete list and additional details.