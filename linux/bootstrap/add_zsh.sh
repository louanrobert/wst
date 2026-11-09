#!/usr/bin/env bash
set -euo pipefail

if command -v zsh >/dev/null 2>&1; then
    printf "\e[1;32mOK\e[m: zsh is already installed.\n"
else
    sudo apt install -y zsh
    printf "\e[1;33mCHANGED\e[m: Installed zsh.\n"
fi

zsh_path="$(command -v zsh)"
current_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
if [[ "$current_shell" == "$zsh_path" ]]; then
    printf "\e[1;32mOK\e[m: zsh is already the default shell.\n"
else
    sudo chsh -s "$zsh_path" "$(id -un)"
    printf "\e[1;33mCHANGED\e[m: Set zsh as the default shell.\n"
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
dotfiles="$script_dir/../../dotfiles"
if [[ ! -d "$dotfiles" ]]; then
    printf "\e[1;31mERROR\e[m: Dotfiles not found at %s. Keep dotfiles beside linux/ or workstation/.\n" "$dotfiles" >&2
    exit 1
fi

for name in .zshenv .zshrc .aliases; do
    source_file="$dotfiles/$name"
    target="$HOME/$name"
    if cmp -s -- "$source_file" "$target"; then
        printf "\e[1;32mOK\e[m: %s is already installed.\n" "$name"
        continue
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        backup="$(mktemp "$target.backup.XXXXXXXX")"
        cp -p -- "$target" "$backup"
        printf "\e[1;33mCHANGED\e[m: Backed up %s to %s.\n" "$target" "$backup"
    fi
    cp --remove-destination -- "$source_file" "$target"
    printf "\e[1;33mCHANGED\e[m: Installed %s.\n" "$name"
done

export ZSH_CONFIG="${ZSH_CONFIG:-$HOME/.zsh-config}"
if [[ ! -r "$ZSH_CONFIG/znap/znap.zsh" ]]; then
    mkdir -p -- "$ZSH_CONFIG"
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git "$ZSH_CONFIG/znap"
    printf "\e[1;33mCHANGED\e[m: Installed Znap.\n"
else
    printf "\e[1;32mOK\e[m: Znap is already installed.\n"
fi
