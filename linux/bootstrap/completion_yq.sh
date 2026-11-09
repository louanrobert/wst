#!/usr/bin/env bash

# Adds command completion for yq.
set -euo pipefail
ZSH="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
mkdir -p "$ZSH/site-functions"
if [[ -s "$ZSH/site-functions/_yq" ]]; then
    printf "\e[1;32mOK\e[m: yq completion already exists.\n" >/dev/null 2>&1
else
    yq shell-completion zsh > "$ZSH/site-functions/_yq"
    printf "\e[1;33mCHANGED\e[m: Generated command completion file _yq.\n"
fi