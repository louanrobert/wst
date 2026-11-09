#!/usr/bin/env bash
set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT
export HOME="$test_dir/home"
export ZSH_CONFIG="$HOME/.zsh-config"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$HOME" "$test_dir/bin" "$ZSH_CONFIG/znap"

for file in "$repo"/linux/bootstrap/*.sh; do
    bash -n "$file"
done
for file in .zshrc .zshenv .aliases; do
    zsh -n "$repo/dotfiles/$file"
done

export WST_TEST_REPO="$repo"
zsh -dfc '
    source "$WST_TEST_REPO/dotfiles/.zshenv"
    original=("$path[@]")
    source "$WST_TEST_REPO/dotfiles/.zshenv"
    [[ "$path" == "$original" ]] || exit 1
    [[ $path[1] == "$HOME/.arkade/bin" ]] || exit 1
    [[ $EDITOR == nvim && $VISUAL == nvim && $MANPAGER == "nvim +Man!" ]] || exit 1
    [[ $skip_global_compinit == 1 ]] || exit 1
    alias gc="git commit -v" gl="git pull" l="colorls"
    source "$WST_TEST_REPO/dotfiles/.aliases"
    [[ $aliases[gc] == "git commit -v" && $aliases[gl] == "git pull" ]] || exit 1
    [[ $aliases[l] == colorls && -n $aliases[inv] && -n $aliases[xat] ]] || exit 1
'

cat > "$test_dir/bin/getent" <<'EOF'
#!/usr/bin/env bash
printf 'test:x:1000:1000::%s:%s\n' "$HOME" "$(command -v zsh)"
EOF
cat > "$test_dir/bin/sudo" <<'EOF'
#!/usr/bin/env bash
echo "ERROR: Unexpected privileged command: $*" >&2
exit 1
EOF
chmod +x "$test_dir/bin/getent" "$test_dir/bin/sudo"
export PATH="$test_dir/bin:$PATH"
touch "$ZSH_CONFIG/znap/znap.zsh"
printf 'original zshrc\n' > "$HOME/.zshrc"
printf 'original zshenv\n' > "$HOME/.zshenv"
printf 'original aliases\n' > "$HOME/.aliases"
printf 'export LOCAL_SETTING=preserved\n' > "$HOME/.zshrc.local"

bash "$repo/linux/bootstrap/add_zsh.sh" >/dev/null
for name in .zshrc .zshenv .aliases; do
    cmp "$repo/dotfiles/$name" "$HOME/$name"
    backup="$(find "$HOME" -maxdepth 1 -name "$name.backup.*")"
    [[ -n "$backup" ]]
    grep -q '^original ' "$backup"
done
bash "$repo/linux/bootstrap/add_zsh.sh" >/dev/null
[[ "$(find "$HOME" -maxdepth 1 -name '*.backup.*' | wc -l)" -eq 3 ]]
grep -q LOCAL_SETTING "$HOME/.zshrc.local"
bash "$repo/linux/bootstrap/krew_path.sh" >/dev/null
cmp "$repo/dotfiles/.zshenv" "$HOME/.zshenv"

bash "$repo/linux/bootstrap/completion_jq.sh" >/dev/null
bash "$repo/linux/bootstrap/completion_harshicorp.sh" >/dev/null
for name in jq tofu vault; do
    zsh -n "$XDG_DATA_HOME/zsh/site-functions/_$name"
    grep -q "^#compdef $name$" "$XDG_DATA_HOME/zsh/site-functions/_$name"
done
cmp "$repo/dotfiles/.zshrc" "$HOME/.zshrc"

cat > "$test_dir/bin/tofu" <<'EOF'
#!/usr/bin/env bash
printf 'completion-result\n'
EOF
cp "$test_dir/bin/tofu" "$test_dir/bin/vault"
chmod +x "$test_dir/bin/tofu" "$test_dir/bin/vault"
export WST_COMPLETION_RESULTS="$test_dir/completion-results"
zsh -dfc '
    autoload -Uz compinit
    fpath=("$XDG_DATA_HOME/zsh/site-functions" $fpath)
    compinit -d "$HOME/.zcompdump"
    compadd() { print -rl -- "$@" >> "$WST_COMPLETION_RESULTS" }
    words=(tofu c)
    CURRENT=2
    PREFIX=c
    autoload -Uz _tofu _vault
    _tofu || exit 1
    words=(vault c)
    _vault || exit 1
'
[[ "$(grep -c '^completion-result$' "$WST_COMPLETION_RESULTS")" -eq 2 ]]

# A minimal fzf executable checks setup without downloading or installing tools.
cat > "$test_dir/bin/fzf" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == --zsh ]]
EOF
chmod +x "$test_dir/bin/fzf"
bash "$repo/linux/bootstrap/completion_fzf.sh" >/dev/null
cmp "$repo/dotfiles/.zshrc" "$HOME/.zshrc"

# Exercise RubyGems installation without changing the host's packages or gems.
cat > "$test_dir/bin/ruby" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$test_dir/bin/gem" <<'EOF'
#!/usr/bin/env bash
set -eu
case "$1" in
    list) [[ -f "$HOME/colorls-installed" ]] ;;
    install)
        [[ "$*" == 'install --user-install --bindir '"$HOME"'/.local/bin --no-document colorls' ]]
        printf 'install\n' >> "$HOME/gem-installs"
        [[ ! -f "$HOME/fail-gem-install" ]] || exit 1
        printf '#!/bin/sh\nprintf "colorls test\\n"\n' > "$HOME/.local/bin/colorls"
        chmod +x "$HOME/.local/bin/colorls"
        touch "$HOME/colorls-installed"
        ;;
    *) exit 1 ;;
esac
EOF
cat > "$test_dir/bin/sudo" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == 'apt install -y ruby-dev build-essential libyaml-dev' ]] || exit 1
printf 'apt\n' >> "$HOME/apt-installs"
EOF
chmod +x "$test_dir/bin/ruby" "$test_dir/bin/gem" "$test_dir/bin/sudo"
bash "$repo/linux/bootstrap/install_colorls.sh" >/dev/null
[[ -x "$HOME/.local/bin/colorls" ]]
bash "$repo/linux/bootstrap/install_colorls.sh" >/dev/null
[[ "$(wc -l < "$HOME/gem-installs")" -eq 1 ]]
[[ "$(wc -l < "$HOME/apt-installs")" -eq 1 ]]
rm -- "$HOME/colorls-installed"
touch "$HOME/fail-gem-install"
if bash "$repo/linux/bootstrap/install_colorls.sh" >"$test_dir/failure.log" 2>&1; then
    printf 'ERROR: Failed gem installation incorrectly reported success.\n' >&2
    exit 1
fi

printf 'OK: Zsh syntax, PATH, aliases, backups, completions, and colorls installation.\n'
