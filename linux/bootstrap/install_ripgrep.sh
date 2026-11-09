#!/usr/bin/env bash

# Installs ripgrep and generates its command completion file.

ZSH="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"

sudo apt install -y ripgrep >/dev/null 2>&1
mkdir -p "$ZSH/site-functions"
if [[ -s "$ZSH/site-functions/_rg" ]]; then
    printf "\e[1;32mOK\e[m: rg completion already exists.\n" >/dev/null 2>&1
else
    url="https://raw.githubusercontent.com/BurntSushi/ripgrep/master/complete/_rg"
    curl "$url" > "$ZSH/site-functions/_rg"
    printf "\e[1;33mCHANGED\e[m: Generated command completion file _rg...\n"
fi