## What the phylosophy here ?

A dotfile project is nice but what install the tools and setup the autocompletion. 

Actually, there is several layers in this workstation automation:
- Some minimal OS prerequisities
- OS update
- ZSH as default shell + config/plugins 
- tmux install and config
- tools installation and auto-completions

Why some bash script and not ansible (specially if we need idempotency) ? 
Bash scripts have no dependencies and usable in any shell. Eventually it could be reused to reset our config. 
There is a possibility to move in a far future, to *cloud-init*, left to be tested... 

For the tools, we try as much as possible to install them with `arkade` which brings benefits like:
- Uniform way to install github tools (which usually have different install methods)
- Packages by default installed in user homedir
- Easy to update
- Include most of the devops tools


## The technical choice

I don't want to challenge all the stack but good to be in mind few technical choice...

* *tmux* - Why ?
* *neovim* - Why ?
    - junegunn/vim-plug vs lazy.vim ?
    - init.lua only for neovim
    - why not AstroVIM ?
* *ZSH* - Why ? 
    - Znap manages Oh My Zsh libraries/plugins and the existing Bira theme.
    - `just install_zsh` backs up and installs shell dotfiles; `just update_zsh`
      updates plugins explicitly.
* *Podman* - Why not *docker* ?
* *uv* - Why not *pyenv* ?

## Some guidlines

Shell configuration regression checks run with `bash tests/zsh.sh` from
`linux/` (requires Bash and Zsh). They use a temporary home and mocked privileged
commands; they do not install packages or change your real dotfiles.

`python3 tests/cd-menu.py` exercises the actual directory menu in an isolated
pseudo-terminal, including arrow navigation and prefix filtering. This optional
integration check requires Git, Zsh, Python 3, and network access to download the
configured plugins into a temporary home; it does not change your real dotfiles.

* Ideally, the `just` should run on any Linux distro... but if works on *debian-like*, it's already great.

* Try to keep everything in the user homedir as much as possible.

* Make each script as much autonomious as possible. 

* Make those script as much idempotent as possible.

* Follow Ansible color output:

```bash
printf "\e[1;33mCHANGED\e[m: Yellow for CHANGED, when action changed something.\n"
printf "\e[1;33mWARN\e[m: Yellow for WARN as well.\n"
printf "\e[1;32mOK\e[m: Green for OK when it was already done.\n"
printf "\e[1;34mINFO\e[m: Blue for real INFO.\n"
printf "\e[1;31mERROR\e[m: Red for ERRORS when something went wrong.\n"
```

* **[Important]** Install new tool following those rules:   
  - For most of tools which have the auto-completion and are installable with `arkade`, use the standard `install_tools.sh`.
  - For the tools installable with `arkade` but without auto-completion included, use `annoying_tools.sh` and eventually create a custom completion script.
  - For the tools non-installable with `arkade`, create your own custom installer script.
   

## Some helpers

```bash
# Colors
BLUE="\e[1;34m"
YELLOW="\e[1;33m"
GREEN="\e[1;32m"
RED="\e[1;31m"
RESET="\e[m"

# Helper: print colored info
info() {
  echo -e "${BLUE}INFO:${RESET} $1"
}
warn() {
  echo -e "${YELLOW}WARN:${RESET} $1"
}
changed() {
  echo -e "${YELLOW}CHANGED:${RESET} $1"
}
ok() {
  echo -e "${GREEN}OK:${RESET} $1"
}
error() {
  echo -e "${RED}ERROR:${RESET} $1"
}
```