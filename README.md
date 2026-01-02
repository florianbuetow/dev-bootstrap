# dev-bootstrap

My notes for setting up my dev and coding environment on a new Mac.

## Fonts

Download, unpack and then open these fonts to install them:

1. [IBM_Plex_Mono](https://fonts.google.com/specimen/IBM+Plex+Mono)
2. [JetBrainsMono](https://www.jetbrains.com/lp/mono/)

## macOS Settings

### Screenshot Format

Change the screenshot file format to JPG (default is PNG):
```bash
defaults write com.apple.screencapture type jpg; killall SystemUIServer
```

## Sublimetext

1. Download [Subilme Text](https://www.sublimetext.com)

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

## Java

Note: This might not be needed, because you can install Java and Gradle through IntelliJ (if you use it). Otherwise install manually using:

```bash
brew install openjdk

# Add export PATH="/usr/local/opt/openjdk/bin:$PATH" to zsh shell config
echo '' >> ~/.zshrc
echo 'export PATH="/usr/local/opt/openjdk/bin:$PATH"' >> ~/.zshrc

brew install gradle
```

## VSCODE

Download VSCode at [code.visualstudio.com](https://code.visualstudio.com)

### Themes

Unless otherwhise noted, they can be installed through the Extension menu in VSCode. I like these themes:

1. Horizon Theme  
2. Jetbrains Mono Typeface
3. [Nord Theme](https://marketplace.visualstudio.com/items?itemName=arcticicestudio.nord-visual-studio-code)

### Extensions

1. Extension: Font Switcher 
2. Docker

### Copilot

1. GitHub Copilot
2. GitHub Copilot Chat

### GOLANG

***Installing Extensions for VSCode***

Just install the Go extension from Google.

***Getting go tools installed via VSCODE popup***

The popup will show as soon as you start editing .go files in VSCode.

To install the go tools, you need the apple's developer tools, which can be installed from CLI without installing XCODE (>4GB). Simply run the following in the terminal, and a new installation UI window should pop up specifically for the xcode developer tools:

```bash
xcode-select --install
```

***Running fmt for Go on save automatically***

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
## Docker

[Download](https://www.docker.com/products/docker-desktop/) and install docker desktop. 
Then start it once. The starting ensures that docker and docker-compose are available in the CLI.

## Terminal

A nice theme for the OSX Terminal.

Get the code and import the xml file through Terminal settings

[Code and Instructions on Github](https://github.com/nordtheme/terminal-app)

[An arctic, north-bluish color palette.](https://www.nordtheme.com)


![gotop running in a terminal with the nordtheme](https://raw.githubusercontent.com/florianbuetow/dev-bootstrap/main/images/gotop.jpg)
gotop running in a terminal with the nordtheme


### tmux

```bash
brew install tmux
```

Install the plugin manager for tmux [TPM](https://github.com/tmux-plugins/tpm)
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Put this at the bottom of ~/.tmux.conf:

```text
# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'

# Other examples:
# set -g @plugin 'github_username/plugin_name'
# set -g @plugin 'github_username/plugin_name#branch'
# set -g @plugin 'git@github.com:user/plugin'
# set -g @plugin 'git@bitbucket.com:user/plugin'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
```

[Install Nord theme for tmux](https://github.com/nordtheme/tmux) to match the VSCode theme installed earlier.

1. Add
```bash
set -g @plugin "nordtheme/tmux"
```
to your tmux.conf, by default .tmux.conf located in your home directory.

2. press the default key binding prefix + I to fetch- and install the plugin.

Note: On a Mac its CTRL+b then press SHIFT+i. You should see a download and installed message on screen.


### fzf
```bash
brew install fzf
# To install useful key bindings and fuzzy completion:
$(brew --prefix)/opt/fzf/install
```

### git

```bash
brew install git
```

TODO: How to setup github user and email in CLI

### others CLI tools

```bash
brew install screen
brew install watch
brew install wget
brew install htop
brew install gotop
brew install mc
```

## Shell Functions

This repo includes useful shell functions that can be sourced in your `.bashrc` or `.zshrc`:

```bash
for script in ~/Developer/github/dev-bootstrap/scripts/func_*.sh; do
  source "$script"
done
```

Available functions: `boop` (command completion announcements), `murder` (kill processes by PID/name/port), `natobar` (NATO phonetic converter), `tryna` (retry until success), and `trynafail` (run until failure). See the individual script files for detailed usage.

## Slack

Install [Nord theme for Slack](https://www.nordtheme.com/ports/slack)
