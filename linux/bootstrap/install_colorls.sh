#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

if ! command -v ruby >/dev/null 2>&1 || ! command -v gem >/dev/null 2>&1; then
    sudo apt install -y ruby ruby-dev build-essential libyaml-dev
    printf "\e[1;33mCHANGED\e[m: Installed Ruby and gem build dependencies.\n"
fi

if gem list --local --installed --exact colorls >/dev/null &&
   command -v colorls >/dev/null 2>&1; then
    colorls --version
    printf "\e[1;32mOK\e[m: colorls is already installed through RubyGems.\n"
    exit 0
fi

# Native gem dependencies need Ruby headers and a compiler on a fresh machine.
sudo apt install -y ruby-dev build-essential libyaml-dev
mkdir -p -- "$HOME/.local/bin"
gem install --user-install --bindir "$HOME/.local/bin" --no-document colorls
hash -r
colorls --version
printf "\e[1;33mCHANGED\e[m: Installed colorls through RubyGems in ~/.local/bin.\n"
