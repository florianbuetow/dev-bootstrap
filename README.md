# dev-bootstrap

My notes for setting up my dev and coding environment on a new Mac.

## Quick Start — shell integration

Clone this repo (and the `ai-guardrails` templates) into `~/scripts`:

```bash
mkdir -p ~/scripts
git clone https://github.com/florianbuetow/dev-bootstrap.git ~/scripts/dev-bootstrap
git clone https://github.com/florianbuetow/ai-guardrails.git ~/scripts/ai-guardrails
```

Then add a single line to your `~/.zshrc` (before any `compinit` line) and reload:

```zsh
[ -f "$HOME/scripts/dev-bootstrap/scripts/source.sh" ] && source "$HOME/scripts/dev-bootstrap/scripts/source.sh"
```

```bash
source ~/.zshrc
```

[`scripts/source.sh`](scripts/source.sh) sources every shared alias and helper
function, puts `~/scripts/dev-bootstrap/scripts` on your `PATH`, and adds the
bundled zsh completions to `fpath`. The rest of this document is install detail
and per-tool setup.

## Phase 1: System Foundation

### Homebrew Installation

Install Homebrew - the package manager for macOS that we'll use for everything else:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installation, follow the instructions to add Homebrew to your PATH. Typically for Apple Silicon Macs:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### macOS Settings

#### Screenshot Format

Change the screenshot file format to JPG (default is PNG):
```bash
defaults write com.apple.screencapture type jpg; killall SystemUIServer
```

### Fonts

Download and install fonts for development and terminal use.

#### Development Fonts

Download, unpack and then open these fonts to install them:

1. [IBM Plex Mono](https://fonts.google.com/specimen/IBM+Plex+Mono)
2. [JetBrains Mono](https://www.jetbrains.com/lp/mono/)

#### Nerd Fonts for Terminal

**IMPORTANT**: Many terminal tools and themes (including tmux with Nord theme) use special glyphs and icons that require a Nerd Font to display correctly.

Install a Nerd Font via Homebrew:

```bash
# Install one of these popular Nerd Fonts
brew install --cask font-jetbrains-mono-nerd-font
# or
brew install --cask font-hack-nerd-font
# or
brew install --cask font-meslo-lg-nerd-font

# Browse all available Nerd Fonts:
brew search '/font-.*-nerd-font/'
```

### Terminal Setup

Get the Nord theme for the macOS Terminal app.

Get the code and import the xml file through Terminal settings:

[Code and Instructions on Github](https://github.com/nordtheme/terminal-app)

[An arctic, north-bluish color palette.](https://www.nordtheme.com)

#### Configure Terminal Font

Configure macOS Terminal to use a Nerd Font:
- Open Terminal → Preferences (Cmd+,)
- Go to Profiles → Text
- Click "Change" under Font
- Select one of the Nerd Fonts you installed (e.g., "JetBrainsMono Nerd Font")
- Set size to 12-14pt

Without a Nerd Font, you'll see broken characters and missing icons in tmux and other tools.

![gotop running in a terminal with the nordtheme](https://raw.githubusercontent.com/florianbuetow/dev-bootstrap/main/images/gotop.jpg)
gotop running in a terminal with the nordtheme

## Phase 2: Core Development Tools

### Git

Install Git:

```bash
brew install git
```

Configure your Git identity:

```bash
# Configure git user
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Optional: Set default branch name
git config --global init.defaultBranch main
```

Install GitHub CLI:

```bash
brew install gh
brew install git-lfs
```

### Shell Configuration

The current curated shell template lives in [`zshrc.example`](zshrc.example).
It captures the live setup shape from this machine while keeping API keys and
private machine state out of version control.

```bash
# Review first, then copy or merge selected blocks into your own shell config.
less zshrc.example
```

#### Essential PATH Configuration

Add to your `.zshrc`:

```bash
# Local bin directory for user-installed tools (uv, pipx, etc.)
export PATH="$HOME/.local/bin:$PATH"
```

#### Shell Completions

Add to your `.zshrc`:

```bash
# Shell completions
fpath=(~/scripts/completions $fpath)
autoload -Uz compinit
compinit
```

Note: Create `~/scripts/completions` directory if you want to add custom completion scripts.

This repo includes a zsh completion for `guard`:

```bash
mkdir -p ~/scripts/completions
cp scripts/completions/_guard ~/scripts/completions/
```

#### Zsh History Settings

Add to your `.zshrc` for better history management:

```zsh
# History Configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY          # Save history when each session exits
unsetopt SHARE_HISTORY         # Do not share history live between sessions
setopt EXTENDED_HISTORY        # Include timestamps in history entries
setopt HIST_EXPIRE_DUPS_FIRST  # Remove duplicates when trimming full history
setopt extendedglob            # Enable case-insensitive and modifier globs
```

#### Shell Functions from Scripts

These load automatically via [`scripts/source.sh`](scripts/source.sh) (see
[Quick Start](#quick-start--shell-integration)). It sources:

- `aliases.sh` — interactive aliases plus Claude/Codex model wrappers (`q`, `j`, `sonnet`/`haiku`/`opus`, `work`, `rest`, `loop`, `mux`, `png2jpg`, `ytt`, `tmon`/`tstat`, `findt`/`findtt`, ...)
- `wrap_functions.sh` — `wrap` (tmux sessions keyed to the working directory)
- `func_*.sh` — `cdr` (cd to git repo root), `boop`, `murder`, `natobar`, `tryna`, `trynafail`
- `yt-download/functions.sh` — `video-download` (YouTube downloader with browser cookies)
- `claude-lmstudio.sh` / `pi-lmstudio.sh` — `claudex` / `pix` (agents via local LM Studio)

`source.sh` globs **all** `scripts/func_*.sh`, so every helper above loads
automatically.

#### Useful Aliases

Most aliases live in [`scripts/aliases.sh`](scripts/aliases.sh), loaded for you by
`source.sh` (see [Quick Start](#quick-start--shell-integration)). To source it on
its own:

```zsh
[ -f ~/scripts/dev-bootstrap/scripts/aliases.sh ] && source ~/scripts/dev-bootstrap/scripts/aliases.sh
```

Highlights include:

```zsh
# Quick shortcuts
alias q='exit'
alias cls='clear && showGitStatusWhenInRepo'

# Common command shortcuts
alias j='just'
alias jj='just'
alias ci='just ci-quiet && git status'
alias 888='npx n8n start'
alias ccusage='uvx sniffly@latest init'
alias cusage='uvx sniffly@latest init'
alias ccc='uvx sniffly@latest init'

# Enhanced ls commands
alias ld='echo && ls -Alhd */ && echo'  # List only directories
alias dsdestroy='find . -name .DS_Store -delete'  # Remove all .DS_Store files
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias lt='eza --tree --level=2 --icons'

# Personal cd* navigation shortcuts (cdd/cdp/cdg/cdx/cdb/cdlc) reference
# user-specific directories, so they live in ~/scripts/local-aliases.sh, not here.

# Claude Code wrappers
sonnet "prompt"
haiku "prompt"
opus "prompt"
Sonnet "prompt"
SONNET "prompt"
Opus "prompt"
OPUS "prompt"
Haiku "prompt"
HAIKU "prompt"
```

#### Adding More Zsh Helpers

Keep reusable aliases and interactive wrappers in [`scripts/aliases.sh`](scripts/aliases.sh).
Keep reusable shell functions in `scripts/func_*.sh` or another sourced helper file,
then source that file from [`zshrc.example`](zshrc.example). Avoid duplicating
function bodies directly in `.zshrc`.

#### Useful Functions

The useful interactive helpers from the live `.zshrc` are kept in
[`scripts/aliases.sh`](scripts/aliases.sh) and loaded through
[`zshrc.example`](zshrc.example). This keeps the setup additive without copying
stale function bodies into multiple places.

Highlights include:

```zsh
l                 # Enhanced ls with blank lines
ld                # List directories
ss                # Clear screen and show git status when inside a repo
x "prompt"        # Quick Claude wrapper
xx "prompt"       # Raw Claude wrapper
cc "prompt"       # Claude project onboarding wrapper
work 20m          # Work timer
rest 5m           # Break timer
loop 10s "date"   # Repeat a command at an interval
mux mysession     # Create/attach a tmux work layout
png2jpg           # Convert PNG files in the current directory to JPG
ytt URL           # Start the YouTube transcription workflow
```

The live `.zshrc` helpers that used to be copied inline are represented in
[`scripts/aliases.sh`](scripts/aliases.sh), including `l`, `ld`, `ss`, `x`,
`xx`, `cc`, `work`, `rest`, `loop`, `mux`, `png2jpg`, `ytt`, `snow`, and the
Claude/Codex model wrappers.

#### Secrets

Keep API keys and machine-private values outside this repo. Source them from a
private file:

```zsh
mkdir -p ~/.config/dev-bootstrap
touch ~/.config/dev-bootstrap/secrets.zsh
chmod 600 ~/.config/dev-bootstrap/secrets.zsh

# In ~/.zshrc
[ -f "$HOME/.config/dev-bootstrap/secrets.zsh" ] && source "$HOME/.config/dev-bootstrap/secrets.zsh"
```

Suggested private values from the live machine setup: `PERPLEXITY_API_KEY`,
`HEX_API_KEY`, and `HF_TOKEN`.

### fzf

Install fzf (fuzzy finder - required for tmux plugins):

```bash
brew install fzf
# To install useful key bindings and fuzzy completion:
$(brew --prefix)/opt/fzf/install
```

### tmux

See [tmux-cheatsheet.md](tmux-cheatsheet.md) for a quick reference of tmux commands and keybindings.

#### Install tmux

```bash
brew install tmux
```

#### Install TPM (Tmux Plugin Manager)

Install the plugin manager for tmux [TPM](https://github.com/tmux-plugins/tpm):
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

#### Configure tmux

Create or edit `~/.tmux.conf` with the following configuration:

```bash
# Tmux Plugin Manager
set -g @plugin 'tmux-plugins/tpm'

# Session Management & Persistence
set -g @plugin 'tmux-plugins/tmux-resurrect'      # Save/restore sessions
set -g @plugin 'tmux-plugins/tmux-continuum'      # Auto-save sessions
set -g @plugin '27medkamal/tmux-session-wizard'   # Session wizard

# Search & Navigation
set -g @plugin "tmux-plugins/tmux-copycat"         # Enhanced search
set -g @plugin "sainnhe/tmux-fzf"                  # FZF integration
set -g @plugin "wfxr/tmux-fzf-url"                 # Open URLs with FZF

# Clipboard & Copying
set -g @plugin "tmux-plugins/tmux-yank"            # Enhanced copy/paste

# Visual & Theme
set -g @plugin "nordtheme/tmux"                    # Nord theme
set -g @plugin "tmux-plugins/tmux-prefix-highlight" # Show prefix key
set -g @plugin "ofirgall/tmux-window-name"         # Auto-name windows

# Utilities
set -g @plugin "tmux-plugins/tmux-logging"         # Log sessions
set -g @plugin "thewtex/tmux-mem-cpu-load"         # System monitoring
set -g @plugin "tmux-plugins/tmux-sidebar"         # File tree sidebar
set -g @plugin "jaclu/tmux-menus"                  # Menu system
set -g @plugin "alexwforsythe/tmux-which-key"      # Key binding help
set -g @plugin "tassaron/tmux-df"                  # Disk usage

# Auto-save and auto-restore configuration
set -g @continuum-save-interval '1'                # Auto-save every 1 minute
set -g @continuum-restore 'on'                     # Auto-restore on tmux start

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
```

#### Install Plugins

After creating/editing `~/.tmux.conf`:

1. Start tmux: `tmux`
2. Press `Ctrl+b` then `Shift+I` to fetch and install plugins
3. You should see download and installation messages on screen

#### Key Plugin Features

- **tmux-resurrect/continuum**: Sessions auto-save every minute and restore on restart
- **tmux-session-wizard**: Quick session creation/switching with `prefix + T`
- **tmux-fzf**: Fuzzy find sessions, windows, panes with `prefix + F`
- **tmux-fzf-url**: Open URLs from terminal with `prefix + u`
- **tmux-which-key**: Show available keybindings with `prefix + Space`
- **tmux-yank**: Copy to system clipboard with `y` in copy mode
- **Nord theme**: Consistent color scheme across terminal, tmux, and editors

## Phase 3: Programming Languages & Runtimes

### Go

```bash
brew install go
```

Add to your `.zshrc`:
```bash
# Go configuration
export GOPATH=$HOME/go
export PATH="$GOPATH/bin:$PATH"
```

### Node.js (via NVM)

Install NVM (Node Version Manager) - check [nvm GitHub](https://github.com/nvm-sh/nvm) for latest version:
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
```

Add to your `.zshrc`:
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
```

Then install Node.js:
```bash
nvm install --lts
nvm use --lts
```

For shells that need `node`, `npm`, or `npx` available to non-interactive
processes before full NVM initialization, use the lazy-load NVM block in
[`zshrc.example`](zshrc.example). This is useful for agent tools and MCP
servers launched from shells that do not source all interactive startup code.

### Python Tooling

Install uv (fast Python package installer):
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
# Or if you don't have curl:
# wget -qO- https://astral.sh/uv/install.sh | sh
```

Install pyenv (Python version manager):
```bash
brew install pyenv
```

Add to your `.zshrc`:
```bash
# Pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
```

Then install Python versions:
```bash
pyenv install 3.12
pyenv global 3.12
```

### Java

Note: This might not be needed, because you can install Java and Gradle through IntelliJ (if you use it). Otherwise install manually using:

```bash
brew install openjdk

# Add export PATH="/usr/local/opt/openjdk/bin:$PATH" to zsh shell config
echo '' >> ~/.zshrc
echo 'export PATH="/usr/local/opt/openjdk/bin:$PATH"' >> ~/.zshrc

brew install gradle
```

## Phase 4: Development Environment

### Docker

[Download](https://www.docker.com/products/docker-desktop/) and install docker desktop.
Then start it once. The starting ensures that docker and docker-compose are available in the CLI.

### CLI Tools Overview

```text
┌──────────────────┬────────────────────────────────────────────────────────────────────────────────┐
│      Tool        │                                  Description                                   │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│                  │                       SYSTEM MONITORING & UTILITIES                            │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ tmux             │ Terminal multiplexer for managing multiple terminal sessions                   │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ screen           │ Terminal multiplexer (older alternative to tmux)                               │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ watch            │ Execute a program periodically, showing output fullscreen                      │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ htop             │ Interactive process viewer (better than top)                                   │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ gotop            │ Terminal based graphical activity monitor                                      │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ mactop           │ Apple Silicon performance monitoring tool                                      │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ bottom (btm)     │ Modern system monitor with graphs and process management                       │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ iftop            │ Network bandwidth monitor (like htop for network)                              │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│                  │                         FILE & SEARCH UTILITIES                                │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ bat              │ A better cat with syntax highlighting and Git integration                      │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ ripgrep (rg)     │ Blazingly fast search tool, better than grep                                   │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ fd               │ A better find command, simpler and faster                                      │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ tree             │ Display directory structure as a tree                                          │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ dust             │ A better du for disk usage visualization                                       │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ mc               │ Midnight Commander - text-based file manager                                   │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│                  │                              GIT TOOLS                                         │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ gh               │ GitHub CLI for managing repos, PRs, and issues                                 │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ git-lfs          │ Git Large File Storage extension for versioning large files                    │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│                  │                       NETWORK & DEVELOPMENT                                    │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ wget             │ Network downloader for retrieving files via HTTP/HTTPS/FTP                     │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ grpcurl          │ cURL-like tool for interacting with gRPC servers                               │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│                  │                          DATA PROCESSING                                       │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ jq               │ Command-line JSON processor for parsing and manipulating JSON                  │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ yq               │ Command-line YAML processor (like jq for YAML)                                 │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│                  │                        CODE & PROJECT TOOLS                                    │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ cloc             │ Count lines of code in projects with language breakdown                        │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ just             │ Command runner (like make but simpler)                                         │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ semgrep          │ Static analysis tool for finding bugs and security issues                      │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│                  │                            MEDIA TOOLS                                         │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ yt-dlp           │ Download videos from YouTube and other sites                                   │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ exiftool         │ Read and write metadata in files (images, videos, PDFs)                        │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│                  │                          PYTHON TOOLING                                        │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ uv               │ Fast Python package installer and resolver (Rust-based)                        │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ pyenv            │ Python version management tool - switch between multiple Python versions       │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│                  │                    CONTAINER & KUBERNETES TOOLS                                │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ helm             │ Package manager for Kubernetes applications                                    │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│                  │                       VERSION MANAGERS                                         │
├──────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ mise             │ Universal version manager (replaces asdf, manages node/python/ruby/go)         │
└──────────────────┴────────────────────────────────────────────────────────────────────────────────┘
```

### CLI Tools

```bash
# System monitoring & utilities
brew install screen
brew install watch
brew install htop
brew install gotop
brew install mactop
brew install bottom
brew install iftop

# File & search utilities
brew install bat
brew install ripgrep
brew install fd
brew install tree
brew install dust
brew install mc

# Network & development
brew install wget
brew install grpcurl

# Data processing
brew install jq
brew install yq

# Code & project tools
brew install cloc
brew install just
brew install semgrep

# Media tools
brew install yt-dlp
brew install exiftool

# Shell quality-of-life
brew install eza
brew install glow
brew install tldr
brew install zoxide

# Media and transcription helpers
brew install ffmpeg

# tmux-auto-attach dependency
brew install flock
```

### Media Helpers

This repository includes script-safe media helpers copied from the live machine
setup:

```bash
# Download a YouTube audio stream. stdout is only the downloaded path.
scripts/ytdl-audio.sh "https://youtu.be/VIDEO_ID"

# Download a YouTube video. stdout is only the downloaded path.
scripts/ytdl-video.sh "https://youtu.be/VIDEO_ID"

# Transcribe a local file or URL through the local Whisper/MLX pipeline.
scripts/transcribe.sh INPUT [OUTPUT] [NAMESPACE] [MODEL] [LANGUAGE]
```

`scripts/transcribe.sh` expects the separate transcription project at
`~/Developer/github/batch-transcribe-with-whisper-mlx-local-apple-silicon`.
Keep that project as its own repo; this bootstrap repo only carries the wrapper.

```bash
mkdir -p ~/Developer/github
git clone https://github.com/florianbuetow/batch-transcribe-with-whisper-mlx-local-apple-silicon.git ~/Developer/github/batch-transcribe-with-whisper-mlx-local-apple-silicon
```

### Container & Kubernetes Tools

Install helm (Kubernetes package manager):
```bash
brew install helm
```

### Version Managers

Install mise (universal version manager):
```bash
brew install mise
```

Add to your `.zshrc`:
```bash
# Mise configuration
eval "$(mise activate zsh)"
```

Mise can manage versions of Node.js, Python, Ruby, Go, and many other tools. Example usage:
```bash
mise install node@20
mise use node@20
```

## Phase 5: Code Editors

### Sublime Text

1. Download [Sublime Text](https://www.sublimetext.com)

2. Create a symlink to launch Sublime Text from the CLI:
```bash
sudo ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
```

Now you can use `subl .` to open the current folder in Sublime Text.

TIP: When package control is not working, do this and restart sublimetext.
```bash
ln -sf /usr/local/Cellar/openssl@1.1/1.1.1o/lib/libcrypto.dylib /usr/local/lib/
```

3. Install [Nord theme for Sublimetext](https://www.nordtheme.com/ports/sublime-text) via package control. Then 'Select UI Color Scheme' via command palette to activate it.

![sublime text with the nordtheme](https://raw.githubusercontent.com/florianbuetow/dev-bootstrap/main/images/sublimetext.jpg)
sublime text with the nordtheme

4. Set the font face to IBM Plex Mono by opening Sublime Text settings (Preferences → Settings) and adding:
```json
{
    "font_face": "IBM Plex Mono"
}
```

![sublime text font face settings](https://raw.githubusercontent.com/florianbuetow/dev-bootstrap/main/images/sublimetext_fontface.jpg)
sublime text font face settings

### VSCode

Download VSCode at [code.visualstudio.com](https://code.visualstudio.com)

#### Themes

Unless otherwise noted, they can be installed through the Extension menu in VSCode. I like these themes:

1. Horizon Theme
2. Jetbrains Mono Typeface
3. [Nord Theme](https://marketplace.visualstudio.com/items?itemName=arcticicestudio.nord-visual-studio-code)

#### Extensions

1. Extension: Font Switcher
2. Docker

#### Copilot

1. GitHub Copilot
2. GitHub Copilot Chat

#### GOLANG

**Installing Extensions for VSCode**

Just install the Go extension from Google.

**Getting go tools installed via VSCODE popup**

The popup will show as soon as you start editing .go files in VSCode.

To install the go tools, you need the apple's developer tools, which can be installed from CLI without installing XCODE (>4GB). Simply run the following in the terminal, and a new installation UI window should pop up specifically for the xcode developer tools:

```bash
xcode-select --install
```

**Running fmt for Go on save automatically**

To avoid having to manually run fmt every time:

1. Install vs code extension "runonsave" from "emeraldwalk"
2. Edit the settings.json and add:

```json
"emeraldwalk.runonsave": {
    "commands": [
      {
        "match": "\\.go$",
        "cmd": "gofmt -w ${file}"
      }
    ]
}
```

## Phase 6: Optional Tools

### Slack

Install [Nord theme for Slack](https://www.nordtheme.com/ports/slack)

### Pomodoro Timer

A simple CLI Pomodoro timer for macOS.

Requires [timer](https://github.com/caarlos0/timer) and [terminal-notifier](https://github.com/julienXX/terminal-notifier) to be installed:

```bash
brew install caarlos0/tap/timer
brew install terminal-notifier
```

Then add these functions to your `.zshrc`:

```bash
work() {
  # usage: work 10m, work 60s etc. Default is 20m
  timer "${1:-20m}" && terminal-notifier -message 'Pomodoro'\
        -title 'Work Timer is up! Take a Break 😊'\
        -sound Crystal
}

rest() {
  # usage: rest 10m, rest 60s etc. Default is 5m
  timer "${1:-5m}" && terminal-notifier -message 'Pomodoro'\
        -title 'Break is over! Get back to work 😬'\
        -sound Crystal
}
```

### Create Project Directories

Create standard directories for development work:

```bash
mkdir -p ~/Developer
mkdir -p ~/Projects
mkdir -p ~/scripts
```

### External Script Repositories

Some live `~/scripts` content is substantial enough to remain separate and be
cloned during bootstrap instead of vendored here.

#### AI Guardrails

Project bootstrap templates for AI-assisted development:

```bash
mkdir -p ~/scripts
git clone https://github.com/florianbuetow/ai-guardrails.git ~/scripts/ai-guardrails
```

Then add the aliases from [`scripts/aliases.sh`](scripts/aliases.sh), such as
`newpy`, `newgo`, `newjava`, `newelixir`, `newrust`, `newcpp`, `newkotlin`,
`newgamecpp`, and `update-templates`.

#### tmux-auto-attach

Watcher utilities for attaching multiple terminals to different tmux sessions.
These are now bundled in this repo at
[`scripts/tmux-auto-attach/`](scripts/tmux-auto-attach), and the `tmon` / `tstat`
aliases ship in [`scripts/aliases.sh`](scripts/aliases.sh) (loaded via
`source.sh`). Initialise the lock folder once:

```bash
cd ~/scripts/dev-bootstrap/scripts/tmux-auto-attach && just init
```

## Phase 7: AI Coding Tools

### Claude Code

[Claude Code](https://code.claude.com/docs) is Anthropic's CLI coding agent.

#### Install

Install with the official installer (not Homebrew):

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

#### Global Settings

My global settings are in [`claude-code/settings.json`](claude-code/settings.json). They apply to every project (per-project overrides go in a repo's own `.claude/settings.json`). Copy the file into place:

```bash
# from the dev-bootstrap repo root — merge into your existing settings.json if you already have one
cp claude-code/settings.json ~/.claude/settings.json
```

The `permissions.allow` list pre-approves the read-only and project commands I use constantly so Claude Code stops prompting for each one; `permissions.deny` blocks broad or risky commands (raw `pip`/`python`, `find -exec`/`-delete`, `sqlite3`). The remaining keys:

| Key | Effect |
|-----|--------|
| `alwaysThinkingEnabled` | Extended thinking on by default |
| `effortLevel: "xhigh"` | Maximum reasoning effort |
| `advisorModel: "opus"` | Use Opus for the advisor tool |
| `env.ENABLE_LSP_TOOL` | Enable the LSP tool (language-server code intelligence); restart Claude Code after changing |
| `theme: "auto"` | Follow the terminal's light/dark mode |
| `voice` / `voiceEnabled` | Hold-to-talk voice dictation |

> The `Read(//Users/flo/.claude/**)` allow rule hard-codes my home path — replace `/Users/flo` with your own. Permission rules don't expand `~`.

#### Status Line (context window bar)

A colored context-window progress bar for the status line (green → yellow → red as usage climbs). This repo includes a local version at [`scripts/claude-context-status.sh`](scripts/claude-context-status.sh). Point `statusLine.command` in `~/.claude/settings.json` at its absolute path.

#### Plugins & Skills

My Claude Code plugins and skills (architecture audits, spec-driven development, session tooling, and more) are published as a marketplace in [florianbuetow/claude-code](https://github.com/florianbuetow/claude-code):

```bash
# Add the marketplace (one time)
claude plugin marketplace add florianbuetow/claude-code

# Install any plugin by name, then restart Claude Code
claude plugin install <plugin-name>
```

The observed user-level plugin inventory and install commands are documented in
[`claude-code/plugins.md`](claude-code/plugins.md). That file lists plugin IDs
and marketplace install commands only; plugin source/cache directories are not
included in this repo.

### LM Studio Agent Wrappers

The live shell setup includes wrappers for running agent CLIs against local LM
Studio models:

- [`scripts/claude-lmstudio.sh`](scripts/claude-lmstudio.sh) provides `claudex`
  for Claude Code.
- [`scripts/pi-lmstudio.sh`](scripts/pi-lmstudio.sh) provides `pix` for Pi.

Both wrappers expect LM Studio's `lms` CLI at `~/.lmstudio/bin/lms`, require
`jq`, and require the LM Studio server to be running:

```bash
lms server start
```

Source the scripts from `.zshrc` as shown in [`zshrc.example`](zshrc.example).

### Codex CLI Shortcuts

[`zshrc.example`](zshrc.example) includes model/effort aliases for Codex CLI,
for example `codex-55`, `codex-55-low`, `codex-55-med`, and `codex-55-high`.
Keep these aliases in the shell template rather than hard-coding them into
project-local scripts.
