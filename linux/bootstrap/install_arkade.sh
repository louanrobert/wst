#!/usr/bin/env bash

# This script provides steps to install and update arkade on Ubuntu
## conditionals are used to check if the step is already done or not
# Installs or updates arkade and adds its bin path to $PATH.

set -euo pipefail

# GitHub release info
LATEST_VERSION_URL="https://api.github.com/repos/alexellis/arkade/releases/latest"
LATEST_VERSION=$(curl -s "${LATEST_VERSION_URL}" | grep '"tag_name":' | cut -d'"' -f4)
DOWNLOAD_URL="https://github.com/alexellis/arkade/releases/download/${LATEST_VERSION}/arkade"

# Download arkade binary
printf "\e[1;33mCHANGED\e[m: Downloading arkade %s...\n" "$LATEST_VERSION"
curl -sL -o "$HOME/arkade" "$DOWNLOAD_URL"
chmod +x "$HOME/arkade"

# Try installing to /usr/local/bin
if sudo mv "$HOME/arkade" /usr/local/bin/ 2>/dev/null; then
    printf "\e[1;33mCHANGED\e[m: arkade installed to /usr/local/bin\n"
else
    # Fallback to ~/.arkade/bin
    printf "\e[1;33mWARN\e[m: Could not move to /usr/local/bin. Installing to ~/.arkade/bin...\n"
    mkdir -p "$HOME/.arkade/bin"
    mv "$HOME/arkade" "$HOME/.arkade/bin/"
    export PATH="$PATH:$HOME/.arkade/bin"
    printf "\e[1;33mCHANGED\e[m: arkade installed to ~/.arkade/bin\n"
fi

# Confirm installation
if ! command -v arkade >/dev/null 2>&1; then
    printf "\e[1;31mERROR\e[m: arkade still not found in PATH after installation.\n"
    exit 1
fi

ARKADE_VERSION=$(arkade version | awk '/Version:/ { print $2 }')
printf "\e[1;34mINFO\e[m: arkade version %s present.\n" "$ARKADE_VERSION"

# Append ~/.arkade/bin to shell config if not already present
if ! grep -qF '$HOME/.arkade/bin' "$HOME/.zshenv" >/dev/null 2>&1; then
    echo 'export PATH=$PATH:$HOME/.arkade/bin' >> "$HOME/.zshenv"
    printf "\e[1;33mCHANGED\e[m: Added ~/.arkade/bin to PATH in .zshenv\n"
fi

# Immediate session export
export PATH="$PATH:$HOME/.arkade/bin"
