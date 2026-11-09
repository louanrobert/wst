#!/usr/bin/env bash

# Installs podman and generates its command completion file.

ZSH="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"

# Install
sudo apt install -y podman cockpit cockpit-podman >/dev/null 2>&1

# Auto-completion
mkdir -p "$ZSH/site-functions"
if [[ -s "$ZSH/site-functions/_podman" ]]; then
    printf "\e[1;32mOK\e[m: podman completion already exists.\n" >/dev/null 2>&1
else
    printf "\e[1;33mCHANGED\e[m: Generating command completion file _podman...\n"
    podman completion zsh > "$ZSH/site-functions/_podman"
fi

# Config rootless podman ?