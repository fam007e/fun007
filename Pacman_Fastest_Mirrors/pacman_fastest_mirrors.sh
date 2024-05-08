#!/usr/bin/zsh

rate-mirrors --allow-root --protocol https arch | awk '/^# FINISHED AT:/ {p=1} p' | sudo tee /etc/pacman.d/mirrorlist


# Alias mode for BASHRC or ZSHRC
# alias httpsmirrors='rate-mirrors --allow-root --protocol https arch | awk "/^# FINISHED AT:/ {p=1} p" | sudo tee /etc/pacman.d/mirrorlist'

