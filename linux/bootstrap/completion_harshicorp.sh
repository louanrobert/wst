#!/usr/bin/env bash
set -euo pipefail

completion_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions"
mkdir -p -- "$completion_dir"
for tool in tofu vault; do
    cat > "$completion_dir/_$tool" <<EOF
#compdef $tool
autoload -Uz bashcompinit
bashcompinit
_bash_complete -o nospace -C $tool "\$@"
EOF
done
printf "\e[1;32mOK\e[m: Registered OpenTofu and Vault completion adapters.\n"
