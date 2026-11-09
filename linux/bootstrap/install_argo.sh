#!/usr/bin/env bash

# VARS
TOOL="argo"
ARGO_OS="linux"
ZSH="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"

# Get the latest first
curl -sLO "https://github.com/argoproj/argo-workflows/releases/download/v4.0.0/argo-$ARGO_OS-amd64.gz"
gunzip "argo-$ARGO_OS-amd64.gz"
chmod +x "argo-$ARGO_OS-amd64"
mv "./argo-$ARGO_OS-amd64" /usr/local/bin/argo
sudo mv "./argo-$ARGO_OS-amd64" /usr/local/bin/argo

# --- ZSH COMPLETION ---
COMPLETION_OUTPUT=$("$TOOL" completion zsh 2>/dev/null || true)

if [ -n "$COMPLETION_OUTPUT" ]; then
    mkdir -p "$ZSH/site-functions"
    COMPLETION_FILE="$ZSH/site-functions/_$TOOL"

    if [[ -s "$COMPLETION_FILE" ]]; then
        printf "\e[1;32mOK\e[m: %s completion already exists.\n" "$TOOL"
    else
        printf "\e[1;33mCHANGED\e[m: Generating command completion file _%s...\n" "$TOOL"
        echo "$COMPLETION_OUTPUT" > "$COMPLETION_FILE"
    fi
    else
        printf "\e[1;33mWARNING\e[m: %s does not support zsh completions or command failed.\n" "$TOOL"
fi