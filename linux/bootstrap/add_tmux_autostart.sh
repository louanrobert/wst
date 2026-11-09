#!/usr/bin/env bash
set -euo pipefail

if ! command -v tmux >/dev/null 2>&1; then
    sudo apt install -y tmux
    printf "\e[1;33mCHANGED\e[m: Installed tmux.\n"
fi

tmux_config_file="$HOME/.config/tmux/tmux.conf"
if [[ ! -f "$tmux_config_file" ]]; then
    script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    mkdir -p -- "$(dirname -- "$tmux_config_file")"
    cp -- "$script_dir/../../dotfiles/.config/tmux/tmux.conf" "$tmux_config_file"
    printf "\e[1;33mCHANGED\e[m: Installed tmux configuration.\n"
else
    printf "\e[1;32mOK\e[m: tmux configuration already exists.\n"
fi
printf "\e[1;32mOK\e[m: Interactive tmux autostart is managed by .zshrc.\n"
