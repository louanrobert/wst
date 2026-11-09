#!/usr/bin/env bash
set -euo pipefail

completion_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions"
mkdir -p -- "$completion_dir"
printf '#compdef jq\n_gnu_generic "$@"\n' > "$completion_dir/_jq"
printf "\e[1;32mOK\e[m: Registered jq completion.\n"
