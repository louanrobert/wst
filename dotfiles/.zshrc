export ZSH_CONFIG="${ZSH_CONFIG:-$HOME/.zsh-config}"
export TIMEFMT=$'\n\x1b[48;5;28m\x1b[38;5;15mcmd: %J\033[0m\n%U user\n%S system\n\x1b[48;5;226m\x1b[38;5;16m%P cpu\033[0m\n\x1b[48;5;220m\x1b[38;5;16m%*E total\033[0m'

# Start the multiplexer before plugin initialization to avoid doing that twice.
if [[ -o interactive && -t 0 && -t 1 && -z "$ZSH_EXECUTION_STRING" && -z "$TMUX" &&
      "$TERM" != (screen*|tmux*|dumb) ]] && (( $+commands[tmux] )); then
  exec tmux
fi

if [[ ! -r "$ZSH_CONFIG/znap/znap.zsh" ]]; then
  mkdir -p -- "$ZSH_CONFIG" || return
  git clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git "$ZSH_CONFIG/znap" || return
fi
source "$ZSH_CONFIG/znap/znap.zsh" || return

zstyle ':omz:plugins:alias-finder' autoload yes
zstyle ':omz:plugins:alias-finder' longer no
zstyle ':omz:plugins:alias-finder' exact yes
zstyle ':omz:plugins:alias-finder' cheaper yes
zstyle ':autocomplete:*' delay 0.2
zstyle ':autocomplete:*' min-input 2

# Load OMZ libraries, not its framework: Znap manages plugins and updates.
znap clone ohmyzsh/ohmyzsh || return
export ZSH=~[ohmyzsh/ohmyzsh]
ZSH_CUSTOM="$ZSH/custom"
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
mkdir -p -- "$ZSH_CACHE_DIR/completions" || return
typeset -U fpath
fpath=(
  "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions"
  "$ZSH_CACHE_DIR/completions"
  "$ZSH/functions"
  "$ZSH/completions"
  $fpath
)
znap source ohmyzsh/ohmyzsh lib/{git,theme-and-appearance} || return
ZSH_THEME="bira"

# Register completion directories before autocomplete initializes compinit.
znap source zsh-users/zsh-completions || return
znap source zdharma-continuum/fast-syntax-highlighting || return
# Initialize the async dispatcher before autocomplete's first ZLE callback.
znap clone marlonrichert/zasync || return
fpath=(~[marlonrichert/zasync] $fpath)
autoload -Uz zasync
zasync cancel complete || return
znap source marlonrichert/zsh-autocomplete || return
for omz_library in "$ZSH"/lib/*.zsh; do
  [[ "${omz_library:t}" == (git.zsh|theme-and-appearance.zsh) ]] && continue
  znap source ohmyzsh/ohmyzsh "lib/${omz_library:t}" || return
done
unset omz_library
znap source ohmyzsh/ohmyzsh plugins/{git,alias-finder,command-not-found,sudo} || return
znap source ohmyzsh/ohmyzsh themes/bira.zsh-theme || return
if [[ -t 0 && -t 1 && -z "$ZSH_EXECUTION_STRING" ]]; then
  znap prompt || return
fi

typeset -a wst_plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-history-substring-search
  zsh-users/zaw
  akarzim/zsh-docker-aliases
  Kallahan23/zsh-colorls
  zpm-zsh/colorize
)
for plugin in "${wst_plugins[@]}"; do
  if [[ "$plugin" == akarzim/zsh-docker-aliases ]] && ! (( $+commands[docker] )); then
    print -u2 'WARN: Docker aliases skipped: docker is not installed.'
    continue
  fi
  if [[ "$plugin" == Kallahan23/zsh-colorls ]] && ! (( $+commands[colorls] )); then
    print -u2 'WARN: colorls aliases skipped: install the colorls gem to enable them.'
    continue
  fi
  znap source "$plugin" || return
done
unset plugin

# DWIM ends with an optional Wine probe, so its status alone is not a load check.
znap source oknowton/zsh-dwim
if ! (( $+widgets[dwim] )); then
  print -u2 'ERROR: zsh-dwim did not register its widget.'
  return 1
fi

[[ ! -r "$HOME/.aliases" ]] || source "$HOME/.aliases"
alias ccps='tr -d "[:space:]" | clipcopy'

if (( $+commands[fzf] )); then
  # Cache generated shell integration; Znap invalidates it when fzf changes.
  znap eval fzf 'fzf --zsh' || return
  if ! (( $+widgets[fzf-history-widget] )); then
    print -u2 'ERROR: fzf did not register its history widget; fzf 0.48.0 or newer is required.'
    return 1
  fi
  bindkey '^R' fzf-history-widget
  bindkey -M emacs '^R' fzf-history-widget
  bindkey -M viins '^R' fzf-history-widget
fi

# OMZ's key-bindings library overrides autocomplete's arrow-key widgets.
for keymap in emacs viins; do
  bindkey -M "$keymap" \
    '^[[A' up-line-or-search '^[OA' up-line-or-search \
    '^[[B' down-line-or-select '^[OB' down-line-or-select
done
bindkey -M menuselect \
  '^[[A' up-history '^[OA' up-history \
  '^[[B' down-history '^[OB' down-history \
  '^[[D' backward-char '^[OD' backward-char \
  '^[[C' forward-char '^[OC' forward-char
unset keymap

[[ ! -r "$HOME/.zshrc.local" ]] || source "$HOME/.zshrc.local"
