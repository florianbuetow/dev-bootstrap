# Tmux Auto Attach

Two small tmux helpers for managing many sessions at once:

- **[`watcher`](#usage)** - auto-attaches each terminal to a different
  unattached tmux session (newest first) via `just attach`, and shows a
  live status table of all sessions via `just status`. No manual
  session-picking.
- **[`wrap`](#wrap-per-directory-tmux-sessions)** - a zsh function that
  creates sessions named `WRAP-*` so agents and other automation can find
  them with `tmux ls | grep '^WRAP-'` and remote-control them by name.

## Requirements

- `tmux`
- `flock` (on macOS: `brew install flock`)
- `just` (optional, for the `just` interface - on macOS: `brew install just`)

## Install

```sh
mkdir -p ~/scripts
cd ~/scripts
git clone https://github.com/florianbuetow/tmux-auto-attach.git
cd tmux-auto-attach
just init
```

To launch `attach` and `status` from any terminal without changing directory,
add these aliases to `~/.zshrc` (or `~/.bashrc`):

```sh
alias tmon='(cd ~/scripts/tmux-auto-attach && just attach)'
alias tstat='(cd ~/scripts/tmux-auto-attach && just status)'
```

When the command exits you are returned to your original working directory.
Reload your shell (`source ~/.zshrc`) and you're done.

## Usage

Run the watcher in a terminal:

```sh
just attach
```

Open additional terminals and run the same command - each one attaches to the
next-newest session.

Check which sessions are under watch:

```sh
just status        # refresh every 10s (default)
just status 5      # refresh every 5s
just status once   # render once and exit
```

Remove lockfiles whose tmux session no longer exists:

```sh
just cleanup
```

## Scripts

The `just` targets wrap four scripts you can also invoke directly:

- `auto-attach.sh` - one-shot. Captures the current `status.sh` output, clears
  the screen, prints it, then lists tmux sessions sorted by creation time
  (newest first) and attaches to the first one no other watcher has locked.
  Uses `flock` files under `./LOCKS/` for mutual exclusion. Sleeps a random
  0-199 ms after detaching (so racing watchers don't collide), and
  `RETRY_SECS` seconds (default 3) when no session was available.
- `loop.sh` - checks that `flock` is installed, then repeatedly re-runs
  `auto-attach.sh`. All inter-attempt pacing and screen clearing lives in
  `auto-attach.sh` (the clear happens *after* the next status frame is
  buffered, so the screen never goes blank between iterations).
- `status.sh` - renders the status table to stdout (no looping, no header).
  Used by both `just status` and `auto-attach.sh`. Columns: Session Name,
  Path (rendered relative to `~` when inside `$HOME`), Watching, Attached,
  Created (`YYYY-MM-DD HH:MM:SS`).
- `cleanup.sh` - removes every lockfile in `./LOCKS/` whose name no longer
  matches an active tmux session (after the same sanitization the watcher
  applies). Prints one line per file (`kept` / `removed` / `held`) and a
  count summary. Two safety layers run before any deletion: the lockfile's
  key must not match an active session, and `flock -n` must succeed against
  the file (no other process holds it). If `tmux list-sessions` fails for
  any reason other than "no server running", cleanup exits non-zero without
  deleting anything - earlier behavior treated that case as "every lock is
  orphaned" and could destroy live locks.

## How the locking works

For each session name, the watcher opens `LOCKS/<sanitized-name>` and tries
`flock -n` on it. The lock is held only while that terminal is attached, so
when a session is detached or killed, the slot frees up for the next watcher.

The sanitization is `tr -c 'a-zA-Z0-9._-' '_'` - anything outside that
character class becomes `_`. This is **lossy**: distinct session names that
differ only in those characters (e.g. `my session` and `my_session`, or
`a/b` and `a_b`) collapse to the same lock key and therefore share a single
lock. Two watchers can never attach to such a pair concurrently. If you
need them to be watched in parallel, name them so they differ in
`[A-Za-z0-9._-]` characters.

`just status` reflects two independent states:

- **Watching** - a live `flock -n` probe against `LOCKS/<key>`. `yes` means
  a watcher process is currently inside `tmux attach` for this session;
  `-` means no flock is held.
- **Attached** - tmux's own `#{session_attached}` count. `yes` means at
  least one tmux client (the watcher or a manual `tmux attach`) is
  connected; `-` means none.

They usually agree, but disagree when you attach manually (Attached=yes,
Watching=-) or when a watcher is mid-iteration outside its `tmux attach`.
Sessions in normal color come from `tmux list-sessions`; greyed rows are
stale lockfiles whose tmux session no longer exists (and which `just cleanup`
will remove on its next run, provided no process still holds the flock).

## Wrap (per-directory tmux sessions)

`wrapfunc.sh` is a zsh function that creates and manages tmux sessions
tied to your current working directory. Every session name starts with
`WRAP-`, which is the point: agents and other automation can list and
remote-control them via:

```sh
tmux ls | grep '^WRAP-'
```

### Install

`wrapfunc.sh` is a sourced library, not a runnable script. Add to
`~/.zshrc`:

```sh
[ -f "$HOME/scripts/tmux-auto-attach/wrapfunc.sh" ] && \
    source "$HOME/scripts/tmux-auto-attach/wrapfunc.sh"
```

Reopen your shell or run `source ~/.zshrc` to load the function.

### Usage

```sh
wrap        # list all wrap sessions, show usage
wrap new    # create a new wrap session for $PWD (refuses inside tmux)
wrap -r     # reattach to a wrap session for $PWD
wrap -d     # kill a wrap session for $PWD
```

`wrap -r` and `wrap -d` filter the candidate list by current working
directory: only sessions whose embedded directory matches `$PWD` are
offered. If exactly one match exists, `wrap -r` attaches directly;
otherwise it prompts for a number. `wrap new` refuses to run from inside
an existing tmux session.

Session names follow `WRAP-[N]-<dir>`, where `<dir>` is `$PWD` with
`$HOME` rewritten to `~` and `.` characters replaced by `_` (matching
tmux's own session-name normalization). `N` auto-increments globally
across all wrap sessions.

### Requirements

- `zsh` - uses zsh-specific syntax (`${match[N]}` regex captures, `local
  -A` associative arrays, `read "var?prompt"`); will not run in bash
  without modification.
- `tmux`.
