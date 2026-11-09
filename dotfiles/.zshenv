export ZSH_CONFIG="${ZSH_CONFIG:-$HOME/.zsh-config}"

# Preserve the original PATH precedence, including in nested shells.
typeset -U path PATH
path=(
  "$HOME/.arkade/bin"
  "$HOME/.local/share/gem/ruby/3.3.0/bin"
  "$HOME/bin"
  /usr/local/bin
  $path
  /usr/local/go/bin
  "$HOME/.local/bin"
  "${KREW_ROOT:-$HOME/.krew}/bin"
)

# zsh-autocomplete owns completion initialization, including on Ubuntu.
skip_global_compinit=1

# Go
export GOPATH="$HOME/.local"

# Rust
export CARGO_HOME="$HOME/.local"

# Nvim
export EDITOR=nvim
export VISUAL=nvim
export MANPAGER='nvim +Man!'
