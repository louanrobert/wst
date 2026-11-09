#!/usr/bin/env bash
set -euo pipefail

# Initialize the same plugin list used interactively, without starting tmux.
zsh -dfi -c 'source "$HOME/.zshenv" && source "$HOME/.zshrc" && znap status'
printf "\e[1;32mOK\e[m: Znap plugins initialized.\n"
