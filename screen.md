# tmux Screen Cheat Sheet

## Sessions

| Terminal | Purpose |
| --- | --- |
| `tmux new -s main` | Start session `main` |
| `tmux new -s other` | Start session `other` |
| `tmux attach -t main` | Attach to session `main` |
| `tmux attach -t dev` | Attach to session `dev` |
| `tmux ls` | List sessions |
| `tmux kill-server` | Stop tmux and all sessions |
| `tmux new -A -s dev` | Start or attach to session `dev` |

## Keybindings

| Shortcut | Purpose |
| --- | --- |
| `ctrl-b d` | Detach |
| `ctrl-b c` | New window |
| `ctrl-b ,` | Rename window |
| `ctrl-b w` | Window list |
| `ctrl-b %` | Split pane left/right |
| `ctrl-b "` | Split pane top/bottom |
| `ctrl-b + Arrows` | Move between panes |
| `ctrl-b z` | Zoom or unzoom pane |
| `ctrl-b x`, `y` | Kill pane |
| `ctrl-b ?` | Keybinding help |
| `ctrl-b n` | Next window |
| `ctrl-b p` | Previous window |
| `ctrl-b 0..9` | Jump to window number |
| `ctrl-b >` | Show pane menu |
| `ctrl-b :` | tmux command prompt |
| `rename-session dev` | Rename current session, typed at prompt |
| `ctrl-b ctrl-s` | Save with resurrect |
| `ctrl-b ctrl-r` | Restore with resurrect |

## Reloading Config

| State | What to do |
| --- | --- |
| tmux running | Press `ctrl-b :`, then run `source-file ~/.tmux.conf` |
| tmux not running | Do nothing; tmux auto-loads config on start |
