# tmux Cheatsheet

Quick reference guide for tmux commands and keybindings.

```text
+------------------------+----------------------------------------------+
| Terminal               | Purpose                                      |
+------------------------+----------------------------------------------+
| tmux new -s main       | start session "main"                         |
| tmux new -s other      | start session "other"                        |
| tmux attach -t main    | attach to session "main"                     |
| tmux attach -t dev     | attach to session "dev"                      |
| tmux ls                | list sessions                                |
| tmux kill-server       | stop tmux (all sessions)                     |
| tmux new -A -s dev     | start/attach session "dev"                   |
+------------------------+----------------------------------------------+
| ctrl-b d               | detach                                       |
| ctrl-b c               | new window                                   |
| ctrl-b ,               | rename window                                |
| ctrl-b w               | window list                                  |
| ctrl-b %               | split pane left/right                        |
| ctrl-b "               | split pane top/bottom                        |
| ctrl-b + Arrows        | move between panes                           |
| ctrl-b z               | zoom/unzoom pane                             |
| ctrl-b x, y            | kill pane                                    |
| ctrl-b ?               | keybinding help                              |
| ctrl-b n               | next window                                  |
| ctrl-b p               | previous window                              |
| ctrl-b 0..9            | jump to window number                        |
| ctrl-b >               | show menu pane                               |
| ctrl-b :               | tmux command prompt                          |
| rename-session dev     | rename current session (typed at prompt)     |
| ctrl-b ctrl-s          | save (resurrect)                             |
| ctrl-b ctrl-r          | restore (resurrect)                          |
+------------------------+----------------------------------------------+
| Editing ~/.tmux.conf   | What to do                                   |
+------------------------+----------------------------------------------+
| tmux running           | ctrl-b : then `source-file ~/.tmux.conf`     |
| tmux not running       | nothing (auto-load on start)                 |
+------------------------+----------------------------------------------+
```
