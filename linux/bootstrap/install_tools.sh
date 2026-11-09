#!/usr/bin/env bash

# Checks for a tool, installs with arkade if needed, and creates its command completion.

# --- CONFIG ---
TOOL="$1"
ZSH="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
ARKADE_BIN="$HOME/.arkade/bin"

# --- FIX PATH ---
export PATH="$PATH:$HOME/.arkade/bin:/usr/local/bin"

# --- CHECK ARG ---
if [ -z "$TOOL" ]; then
    printf "\e[1;31mERROR\e[m: No tool name provided.\n"
    exit 1
fi

# --- INSTALL TOOL ---
if command -v "$TOOL" >/dev/null 2>&1; then
    printf "\e[1;32mOK\e[m: %s is already installed.\n" "$TOOL"
else
    printf "\e[1;33mCHANGED\e[m: %s not found. Installing with arkade...\n" "$TOOL"

    if command -v arkade >/dev/null 2>&1; then
        arkade get "$TOOL" --quiet
    else
        printf "\e[1;31mERROR\e[m: arkade is not installed or not in PATH.\n"
        exit 1
    fi

    hash -r

    if ! command -v "$TOOL" >/dev/null 2>&1; then
        printf "\e[1;31mERROR\e[m: %s was installed but is still not in PATH.\n" "$TOOL"
        exit 1
    fi
fi

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
