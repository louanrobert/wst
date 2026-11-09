#!/usr/bin/env bash

set -euo pipefail
# Create tmux config file if it does not exist
tmux_config_path="$HOME/.config/tmux"
tmux_config_file="$tmux_config_path/tmux.conf"
# Install tmux plugin manager (tpm) if not already installed
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    printf "\e[1;33mCHANGED\e[m: tmux plugin manager (tpm) has been installed.\n"
else
    printf "\e[1;32mOK\e[m: tmux plugin manager (tpm) \e[1;32mis already installed.\n"
fi
# Ensure tpm is sourced in .tmux.conf
if ! grep -q "run -b ~/.tmux/plugins/tpm/tpm" "$tmux_config_file"; then
    echo "run -b ~/.tmux/plugins/tpm/tpm" >> "$tmux_config_file"
    printf "\e[1;33mCHANGED\e[m: tpm has been added to $tmux_config_file.\n"
else
    printf "\e[1;32mOK\e[m: tpm is already present in $tmux_config_file.\n" >/dev/null 2>&1
fi
# Enable mouse mode in tmux config if not already present
if ! grep -q "set-option -g mouse on" "$tmux_config_file"; then
    echo "set-option -g mouse on" >> "$tmux_config_file"
    printf "\e[1;33mCHANGED\e[m: Mouse mode has been added to $tmux_config_file.\n"
else
    printf "\e[1;32mOK\e[m: Mouse mode is already present in $tmux_config_file.\n"
fi
