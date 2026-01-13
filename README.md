# dev-bootstrap

My notes for setting up my dev and coding environment on a new Mac.

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

#### Zsh History Settings

Add to your `.zshrc` for better history management:

```bash
# History Configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt INC_APPEND_HISTORY      # Append history incrementally as commands are entered
setopt SHARE_HISTORY           # Share history across all open zsh sessions
setopt EXTENDED_HISTORY        # Include timestamps in history entries
setopt HIST_EXPIRE_DUPS_FIRST  # Remove duplicates when trimming full history
setopt extendedglob            # Enable case-insensitive and modifier globs
```

#### Shell Functions from Scripts

This repo includes useful shell functions that can be sourced in your `.bashrc` or `.zshrc`:

```bash
for script in ~/Developer/github/dev-bootstrap/scripts/func_*.sh; do
  source "$script"
done
```

Available functions: `boop` (command completion announcements), `murder` (kill processes by PID/name/port), `natobar` (NATO phonetic converter), `tryna` (retry until success), and `trynafail` (run until failure). See the individual script files for detailed usage.

#### Useful Aliases

Add to your `.bashrc` or `.zshrc`:

```bash
# Quick shortcuts
alias q='exit'
alias cls='clear && git rev-parse --is-inside-work-tree &>/dev/null && git status'

# Enhanced ls commands
alias ld='echo && ls -Alhd */ && echo'  # List only directories
alias dsdestroy='find . -name .DS_Store -delete'  # Remove all .DS_Store files

# Quick navigation to project directories
alias cdd='clear && cd ~/Developer/ && ls -Alhd */ && echo'
alias cdp='clear && cd ~/Projects/ && ls -Alhd */ && echo'
```

#### Useful Functions

Add to your `.bashrc` or `.zshrc`:

```bash
# Enhanced ls with blank lines for readability
l() {
    echo
    ls -A "$@"
    echo
}

ll() {
    echo
    ls -Alh "$@"
    echo
}

# Clear and show git status
ss() {
    clear
    echo
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        git status
    else
        echo "Not inside a git repository."
    fi
    echo
}

# Quick Claude wrapper: x do something → claude "Please do something"
x() {
    claude "Please $*"
}

# Claude Code project starter with optional additional prompt
# Usage: cc [additional prompt text]
cc() {
    if [ -z "$*" ]; then
        claude "Please read @CLAUDE.md and familiarize yourself with all other markdown files in the current folder. Let me know when you are ready to continue working on this project."
    else
        claude "Please read @CLAUDE.md and familiarize yourself with all other markdown files in the current folder. Let me know when you are ready to continue working on this project. $*"
    fi
}

# Convert all PNGs to JPGs (macOS only - uses sips)
png2jpg() {
    local file filename
    local converted_count=0

    # Loop over all files ending in .png (case-insensitive)
    for file in (#i)*.png(.); do
        filename="${file%.*}"
        sips -s format jpeg -s formatOptions 98 "$file" --out "${filename}.jpg"
        echo "Converted $file to ${filename}.jpg"
        rm "$file"
        ((converted_count++))
    done

    if (( converted_count > 0 )); then
        echo "Conversion complete! Converted $converted_count files."
    else
        echo "No .png files found to convert."
    fi
}
```

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

### Create Project Directories

Create standard directories for development work:

```bash
mkdir -p ~/Developer
mkdir -p ~/Projects
```
