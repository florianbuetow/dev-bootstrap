#!/usr/bin/env bash
# term-switch.sh - Interactive switcher for terminal sessions on macOS.
#
# Lists every Terminal.app tab, iTerm2 session, and tmux session, grouped by
# working directory, in an fzf picker (falls back to a numbered menu when fzf
# is absent). Selecting one brings it to the foreground:
#   * GUI tab          -> raises its window and selects its tab/pane.
#   * tmux (attached)  -> switches that client to the session and foregrounds
#                         the GUI tab hosting it.
#   * tmux (detached)  -> switches/attaches it into the current terminal.
#
# Usage: term-switch.sh
#
# Requires: macOS Automation permission to control Terminal/iTerm2 (you will be
# prompted on first run). Optional dependencies: fzf, tmux.

# Field separator embedded inside the hidden key (unlikely to appear in ttys,
# app names or session names).
KSEP=$'\x1f'

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------
LIST_ONLY=0
case "${1:-}" in
  -l|--list)  LIST_ONLY=1 ;;          # print what would be shown, then exit
  -h|--help)  awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"; exit 0 ;;
  "")         ;;
  *)          echo "Unknown option: $1 (try --help)" >&2; exit 2 ;;
esac

# ---------------------------------------------------------------------------
# Detect which GUI terminal apps are running.  We ask System Events for the
# names of all foreground processes in ONE call and test membership locally.
# (pgrep is unreliable for .app bundles and blocked in some sandboxes; and a
# per-name "exists process X" hangs when X is not running.)
# ---------------------------------------------------------------------------
GUI_PROCS=$(osascript -e 'tell application "System Events" to get name of every process whose background only is false' 2>/dev/null \
  | tr ',' '\n' | sed 's/^[[:space:]]*//')

proc_running() { printf '%s\n' "$GUI_PROCS" | grep -Fxq "$1"; }

TERM_RUNNING=0
ITERM_RUNNING=0
ITERM_APP=""

proc_running "Terminal" && TERM_RUNNING=1
if proc_running "iTerm2"; then
  ITERM_RUNNING=1
  ITERM_APP="iTerm2"
elif proc_running "iTerm"; then
  ITERM_RUNNING=1
  ITERM_APP="iTerm"
fi

have_tmux=0
command -v tmux >/dev/null 2>&1 && tmux info >/dev/null 2>&1 && have_tmux=1

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Shorten an absolute path by replacing $HOME with ~.
shorten() {
  case "$1" in
    "$HOME") printf '~' ;;
    "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;;
    *) printf '%s' "$1" ;;
  esac
}

# Resolve working directory + foreground command for many ttys at once: one ps
# snapshot picks the foreground (or last) process per tty, and a single lsof
# maps those pids to their cwd.  Per-tty would mean one slow lsof per tab.
#   stdin:  /dev/ttysNNN lines    stdout: "ttysNNN<TAB>/cwd<TAB>command" lines
resolve_cwds() {
  local want snap short res pid comm pids="" pairs=""
  want=$(grep -oE 'ttys[0-9]+')
  [ -z "$want" ] && return 0
  snap=$(ps -Ao pid=,tty=,stat=,ucomm= 2>/dev/null)
  while IFS= read -r short; do
    [ -z "$short" ] && continue
    res=$(printf '%s\n' "$snap" | awk -v a="$short" '
      $2==a { c=$4; for(i=5;i<=NF;i++) c=c" "$i
              if($3 ~ /\+/){print $1"\t"c; f=1; exit} lp=$1; lc=c }
      END { if(!f && lp!="") print lp"\t"lc }')
    pid=${res%%	*}; comm=${res#*	}
    [ -n "$pid" ] && { pairs="${pairs}${pid}	${short}	${comm}
"; pids="${pids},${pid}"; }
  done <<EOF
$want
EOF
  pids=${pids#,}
  [ -z "$pids" ] && return 0
  # Join the pid->(tty,command) pairs with one lsof's pid->cwd output.
  { printf '%s' "$pairs"
    lsof -w -a -d cwd -p "$pids" -Fpn 2>/dev/null \
      | awk '/^p/{p=substr($0,2)} /^n/{print p"\tCWD\t"substr($0,2)}'
  } | awk -F'\t' '
    $2=="CWD" { cwd[$1]=$3; next }
    { short[$1]=$2; comm[$1]=$3 }
    END { for (p in short) print short[p]"\t"(p in cwd?cwd[p]:"(unknown)")"\t"comm[p] }
  '
}

# Look up a tty (short form, e.g. ttys004) in CWD_MAP -> "cwd<TAB>command".
lookup_cwd() {
  printf '%s\n' "$CWD_MAP" | awk -F'\t' -v t="$1" '$1==t{print $2"\t"$3; exit}'
}

# ---------------------------------------------------------------------------
# Enumerate GUI sessions -> lines of "App<TAB>/dev/ttysNNN".
#
# A single bulk accessor ("tty of tabs of windows") is used instead of nested
# repeat loops: it is far faster over many tabs and, unlike a per-tab loop, it
# does not abort on a window that cannot report its tabs (error -1728).  The
# command label is filled in later from the ps snapshot, so no per-tab
# AppleScript property reads are needed.
# ---------------------------------------------------------------------------
enum_terminal() {
  [ "$TERM_RUNNING" = 1 ] || return 0
  osascript -e 'tell application "Terminal" to get tty of tabs of windows' 2>/dev/null \
    | tr ',' '\n' | grep -oE 'ttys[0-9]+' \
    | while IFS= read -r s; do printf 'Terminal\t/dev/%s\n' "$s"; done
}

enum_iterm() {
  [ "$ITERM_RUNNING" = 1 ] || return 0
  osascript -e "tell application \"$ITERM_APP\" to get tty of sessions of tabs of windows" 2>/dev/null \
    | tr ',' '\n' | grep -oE 'ttys[0-9]+' \
    | while IFS= read -r s; do printf 'iTerm2\t/dev/%s\n' "$s"; done
}

# ---------------------------------------------------------------------------
# Activation
# ---------------------------------------------------------------------------

# Bring the GUI tab/pane that owns a tty to the front (no-op if not found).
activate_gui() {
  local app="$1" tty_dev="$2"
  if [ "$app" = "Terminal" ]; then
    osascript - "$tty_dev" 2>/dev/null <<'OSA'
on run argv
  set theTty to item 1 of argv
  tell application "Terminal"
    repeat with w in windows
      try
        repeat with t in tabs of w
          if tty of t is theTty then
            set selected of t to true
            set index of w to 1
            activate
            return
          end if
        end repeat
      end try
    end repeat
  end tell
end run
OSA
  else
    osascript - "$app" "$tty_dev" 2>/dev/null <<'OSA'
on run argv
  set appName to item 1 of argv
  set theTty to item 2 of argv
  tell application appName
    repeat with w in windows
      try
        repeat with t in tabs of w
          repeat with s in sessions of t
            if tty of s is theTty then
              tell w to select
              tell t to select
              tell s to select
              activate
              return
            end if
          end repeat
        end repeat
      end try
    end repeat
  end tell
end run
OSA
  fi
}

# Foreground whichever GUI app owns a tty.
foreground_tty() {
  local tty_dev="$1"
  [ "$TERM_RUNNING" = 1 ] && activate_gui "Terminal" "$tty_dev"
  [ "$ITERM_RUNNING" = 1 ] && activate_gui "$ITERM_APP" "$tty_dev"
}

activate_tmux() {
  local session="$1" clienttty="$2"
  if [ -n "$clienttty" ]; then
    # Attached: point that client at the session, then raise its GUI tab.
    tmux switch-client -c "$clienttty" -t "$session" 2>/dev/null
    foreground_tty "$clienttty"
  elif [ -n "${TMUX:-}" ]; then
    # Detached, but we are inside tmux: switch the current client.
    tmux switch-client -t "$session"
  else
    # Detached and we are outside tmux: attach in this terminal.
    tmux attach -t "$session"
  fi
}

# ---------------------------------------------------------------------------
# Gather tmux data first so GUI tabs hosting a tmux client can be deduped.
# ---------------------------------------------------------------------------
tmux_clients=""
if [ "$have_tmux" = 1 ]; then
  tmux_clients=$(tmux list-clients -F '#{client_session}::#{client_tty}' 2>/dev/null)
fi
client_ttys=$(printf '%s\n' "$tmux_clients" | awk -F'::' 'NF>1{print $2}')

is_client_tty() {
  [ -n "$1" ] || return 1
  printf '%s\n' "$client_ttys" | grep -Fxq "$1"
}

# ---------------------------------------------------------------------------
# Build picker rows: each row is "DISPLAY<TAB>KEY".
# ---------------------------------------------------------------------------
rows=()

add_row() {
  local folder="$1" source="$2" title="$3" location="$4" key="$5"
  local fshort display
  fshort=$(shorten "$folder")
  display=$(printf '%-40.40s  %-8s  %-28.28s  %s' "$fshort" "$source" "$title" "$location")
  rows+=("${display}"$'\t'"${key}")
}

# Enumerate GUI tabs once, then resolve all their cwds + commands in one batch.
gui_lines=$(enum_terminal; enum_iterm)
CWD_MAP=$(printf '%s\n' "$gui_lines" | awk -F'\t' 'NF>=2 && $2!=""{print $2}' | resolve_cwds)

# GUI rows (skip tabs that host a tmux client; they appear as tmux rows).
while IFS=$'\t' read -r app ttyName; do
  [ -z "$ttyName" ] && continue
  is_client_tty "$ttyName" && continue
  info=$(lookup_cwd "${ttyName#/dev/}")
  cwd=${info%%	*}
  title=${info#*	}
  [ -z "$cwd" ] && cwd="(unknown)"
  [ -z "$title" ] && title="-"
  add_row "$cwd" "$app" "$title" "${ttyName#/dev/}" "gui${KSEP}${app}${KSEP}${ttyName}"
done <<EOF
$gui_lines
EOF

# tmux rows.
if [ "$have_tmux" = 1 ]; then
  while IFS=$'\t' read -r sname sattached; do
    [ -z "$sname" ] && continue
    clienttty=$(printf '%s\n' "$tmux_clients" | awk -F'::' -v s="$sname" '$1==s{print $2; exit}')
    cwd=$(tmux display-message -p -t "$sname" '#{pane_current_path}' 2>/dev/null)
    [ -z "$cwd" ] && cwd="(unknown)"
    if [ -n "$clienttty" ]; then
      loc="attached ${clienttty#/dev/}"
    else
      loc="detached"
    fi
    add_row "$cwd" "tmux" "$sname" "$loc" "tmux${KSEP}${sname}${KSEP}${clienttty}"
  done < <(tmux list-sessions -F '#{session_name}	#{session_attached}' 2>/dev/null)
fi

if [ "${#rows[@]}" -eq 0 ]; then
  echo "No terminal, iTerm2 or tmux sessions found." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Present (sorted by folder), select, dispatch.
# ---------------------------------------------------------------------------
sorted_rows=$(printf '%s\n' "${rows[@]}" | sort)

# Dry-run: print the visible columns (folder / source / title / location) only.
if [ "$LIST_ONLY" = 1 ]; then
  printf '%s\n' "$sorted_rows" | cut -f1
  exit 0
fi

selection=""
if command -v fzf >/dev/null 2>&1; then
  selection=$(printf '%s\n' "$sorted_rows" \
    | fzf --reverse --delimiter=$'\t' --with-nth=1 \
          --prompt='session> ' \
          --header='Enter: jump to session    ESC: cancel') || exit 1
else
  echo "(fzf not found - install with 'brew install fzf' for fuzzy search)" >&2
  echo "Select a session:" >&2
  disp=()
  keys=()
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    disp+=("${line%%$'\t'*}")
    keys+=("${line##*$'\t'}")
  done <<EOF
$sorted_rows
EOF
  PS3="number> "
  select choice in "${disp[@]}"; do
    [ -n "$choice" ] || { echo "Cancelled." >&2; exit 1; }
    selection="${choice}"$'\t'"${keys[$((REPLY-1))]}"
    break
  done
  [ -z "$selection" ] && exit 1
fi

key="${selection##*$'\t'}"

oldIFS=$IFS
set -f
IFS=$KSEP
set -- $key
set +f
IFS=$oldIFS

ktype="$1"
case "$ktype" in
  gui)
    activate_gui "$2" "$3"
    ;;
  tmux)
    activate_tmux "$2" "${3:-}"
    ;;
  *)
    echo "Unrecognized selection." >&2
    exit 1
    ;;
esac

# Reaching here means a session was selected and activated.  Exit 0 signals
# "a jump happened"; the findtt alias uses this to close the launching terminal
# only on a real jump (ESC / cancel / no sessions all exit non-zero).
exit 0
