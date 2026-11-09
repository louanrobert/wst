#!/usr/bin/env bash
set -euo pipefail

if ! command -v fzf >/dev/null 2>&1 || ! fzf --zsh >/dev/null; then
    printf "\e[1;31mERROR\e[m: fzf 0.48.0 or newer is required for Zsh integration.\n" >&2
    exit 1
fi
printf "\e[1;32mOK\e[m: fzf completion and key bindings are managed by .zshrc through Znap.\n"
