<p align="center">
 <img src="assets/logo.png" alt="Project Logo" width="120">
</p>

<p align="center">
  WST is a reproducible way to bootstrap a clean and consistent admin or development environment on WSL.
</p>


## ✨ What’s inside?

This repository provides tools to quickly set up a workstation using **WSL**:

- 🪟 **PowerShell script** to :
  - install and configure WSL distributions via an interactive menu
  - Few cleanup or setup actions on Windows
- 🐧 **Bash scripts** to bootstrap a Linux environment using  
  - [`arkade`](https://github.com/alexellis/arkade) for tool installation  
  - [`just`](https://github.com/casey/just) as a task runner
  - Znap-managed Zsh plugins with the Bira theme
- 🧰 **Dotfiles** optimized for Linux.
The shell configuration requires Zsh; the bootstrap scripts target Debian/Ubuntu.

---

## 🧑‍💻 Who is this for?

- Developers or administrators who want a **clean, consistent WSL setup**
- Teams that need a **reproducible environment** across all members
- Anyone tired of manually configuring tools on every new machine

---

## 📋 Requirements

- Git
- Windows Subsystem for Linux (WSL)

## 🚀 Getting Started

1. Clone the repository on your windows (or Fork it if you want to customize dotfile)

2. From powershell, just run the *menu*, it should show the way...

```powershell
.\menu.ps1

# if Powershell block for some rights
powershell -NoProfile -ExecutionPolicy Bypass -File menu.ps1
```  

3. If you already have Ubuntu installed on WSL (or not), you can still clone this project and use `bootstrap.sh` from terminal...

```bash
git clone https://github.com/louanrobert/wst.git
cd wst/linux

just all        # Runs the full setup
just --list     # These commands show all available tasks defined in your justfile
just update_zsh # Updates Znap and its managed plugins
```

## 📁 Repository Structure

```bash
tree -L 2
.
├── menu.ps1              # Menu and main orchestrator
├── dotfiles              # Dotfiles shared across Linux systems
│   ├── .config
│   ├── .local/bin
├── linux                 # Everything related to Linux OS
│   ├── bootstrap         # Linux installation logic
│   ├── bootstrap.sh      # Prepares prerequisites before running just
│   └── justfile
├── nixos                 # Everything related to NixOS
└── windows               # Everything related to Windows
    ├── localSettings     # Script to setup Windows (debloating, install apps, etc)
    └── manageDistrib     # WSL distribution management scripts
```

## Measure Perf

* Open ZSH 

```BASH
time zsh -i -c exit
zsh -i -c exit  0.53s user 0.79s system 87% cpu 1.518 total
```

## Zsh configuration

`just install_zsh` installs `.zshenv`, `.zshrc`, and `.aliases` from this
repository, backing up each existing differing file as `<name>.backup.XXXXXXXX`
before replacement. Re-running it with unchanged files does not create backups.
It preserves `~/.zshrc.local`; use that file for private or machine-specific
settings. For the Windows Ubuntu installer, dotfiles are staged beside
`~/workstation` so the same backup/install process is used.

The configuration keeps **Bira**, the custom colored `TIMEFMT`, `ccps`, the
alias-finder settings, autocomplete's 0.2-second delay/two-character minimum,
and the original plugin repositories. Znap lives in `~/.zsh-config/znap`;
it replaces the fork's separate `~/.oh-my-zsh` installation. Nothing deletes an
existing Oh My Zsh installation.

`just install_zsh` first runs `just install_colorls`: it installs Ruby and native
gem build dependencies when needed, then installs `colorls` with RubyGems using
`--user-install --bindir "$HOME/.local/bin"`. Gems stay user-owned, and the
executable is on the existing PATH regardless of Ruby's versioned gem directory.
You can also run `just install_colorls` independently from `linux/`.

Retained repository features:

- Type `cd ` to show directory completions below the prompt after the existing
  0.2-second delay. Press Down to enter the menu, navigate with the arrow keys,
  and press Enter to accept the selected directory; press Enter again to run
  `cd`. Typing part of a directory name filters the suggestions.
  The async worker (`marlonrichert/zasync`) is initialized explicitly and managed
  by Znap, so `just update_zsh` updates it alongside the other plugins.
- fzf completion and key bindings, with **Ctrl-R using fzf instead of Zaw**.
  fzf 0.48.0 or newer is required. Zaw remains installed but is no longer bound
  to Ctrl-R.
- fzf file selection with bat previews (`inv`, `xat`), shared helpers, and Git
  aliases that do not override existing Oh My Zsh Git aliases.
- Automatic tmux startup in interactive terminals, without nesting tmux/screen
  or replacing `zsh -c` commands. TPM, sensible defaults, logging, and mouse
  support remain available. Install tmux plugins with prefix + Shift-I.
- Neovim as `EDITOR`, `VISUAL`, and `MANPAGER`.
- Tool completions in `${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions`,
  registered before completion initialization.

`PATH` uses Zsh's unique array to avoid duplicates while retaining the original
Arkade/Ruby/user-bin precedence. Znap and zsh-autocomplete coordinate completion
initialization; no extra `compinit` is appended by installers. fzf's generated
integration is cached by Znap. Updates are explicit: run `just update_zsh`
from `linux/`, then open a fresh shell rather than sourcing `.zshrc` again.

### Optional improvements

- Zaw, history-substring-search, autosuggestions, and autocomplete overlap.
  They remain enabled to preserve behavior; consider removing unused ones after
  trying fzf history.
- Replace the Ruby `3.3.0` bin path in `.zshenv` with your Ruby version manager's
  shim directory if you switch Ruby versions frequently.
- Measure warm startup before removing or deferring plugins. First startup
  includes downloads and compilation and is not representative. Compare several
  runs of `time zsh -i -c exit`; no speedup is assumed without measurements.
- Docker and colorls aliases load only when their commands are available;
  otherwise startup prints a warning and continues.
  `Kallahan23/zsh-colorls` uses the automatically installed `colorls` gem.
  `ccps` uses Oh My Zsh's
  `clipcopy`, which needs a supported clipboard backend (for example `clip.exe`
  on WSL).


## Nice Inspirations

* [Khuedoan dotfiles](https://github.com/khuedoan/dotfiles)

* [Hamvocke dotfiles](https://github.com/hamvocke/dotfiles)

* [How core git dev configure their git?](https://blog.gitbutler.com/how-git-core-devs-configure-git)

* [Foot Terminal](https://medspx.fr/blog/Sysadmin/foot_terminal/): This one could be fun to create some custom popup...

* [Customize k9s skin](https://k9scli.io/topics/skins/)