#!/usr/bin/env bash
# rutil - "run until": wait until a wall-clock time, then run the command right
# here. Same time specs as wutil, but nothing is handed to at(1): the wait
# happens in this shell and the output lands in this terminal.
# Usage: rutil 19:20 'say done' | rutil +30m make test | rutil --dry-run +90s
#
# Writes nothing to disk - no log, no history, no queue. The only trace is the
# countdown on stderr while waiting, which is erased before the command runs.
# The trade against wutil: you see the output live, but the wait dies with the
# terminal and nothing is recorded afterwards.
#
# Time parsing is shared with func_wutil.sh; source.sh sources both.

rutil() {
  [ -n "${ZSH_VERSION:-}" ] && setopt localoptions localtraps 2>/dev/null

  if ! command -v _wutil_target_epoch >/dev/null 2>&1; then
    echo "rutil: needs func_wutil.sh for the shared time parsing" >&2
    return 1
  fi

  local dry=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run) dry=1; shift ;;
      -h|--help|help) set -- ;;
      --) shift; break ;;
      *) break ;;
    esac
  done

  if [ $# -lt 1 ]; then
    cat <<'EOF'
rutil - wait until a wall-clock time, then run a command in this terminal

usage:
  rutil <time> [command ...]
  rutil --dry-run <time>   # resolve the time, wait for nothing
  rutil help               # this text

time:
  19:20                    # next 19:20 (rolls to tomorrow if already past)
  9:05:30                  # seconds are optional
  +30m                     # relative: s/m/h/d, bare number means minutes
  tomorrow 09:00           # quote it: rutil 'tomorrow 09:00' cmd
  2026-08-11T09:00         # absolute date, T or space separated
  2026-08-11               # midnight on that date

command:
  one argument   -> a shell line (pipes, redirects, && all work)
  several        -> quoted for you, no escaping games
  omitted        -> just wait, a sleep that takes a clock time

The command runs in this shell, so its output arrives here and its exit status
becomes rutil's. Ctrl-C during the wait cancels without running it (exit 130).
Nothing is written to disk, and nothing survives closing the terminal.

examples:
  rutil 19:20 'say "deploy window open"'
  rutil +45m make test
  rutil 07:00 && echo "good morning"
EOF
    return 0
  fi

  # Dynamically scoped, so the shared parser's errors say "rutil", not "wutil".
  local _WUTIL_CMD=rutil

  local target
  target=$(_wutil_target_epoch "$1") || return 1
  shift

  local when
  when=$(_wutil_fmt "$target" '%a %Y-%m-%d %H:%M:%S')

  if [ "$dry" -eq 1 ]; then
    echo "$when (in $(_wutil_human $((target - $(date +%s)))))"
    return 0
  fi

  local tty=0
  [ -t 2 ] && tty=1

  # The handler only raises a flag; the loop below does the actual bailing out.
  # `return` from inside a trap is read differently by bash and zsh, so keeping
  # the control flow in the loop makes cancellation behave the same in both.
  _RUTIL_INT=0
  trap '_RUTIL_INT=1' INT

  local rem chunk rc=0
  while :; do
    # Re-read the clock every pass rather than sleeping the whole span in one
    # go: a single long sleep does not advance while the machine is asleep and
    # would fire late after a wake.
    rem=$((target - $(date +%s)))
    [ "$rem" -le 0 ] && break
    [ "$tty" -eq 1 ] && printf '\r\033[Krutil: %s  (%s)' "$when" "$(_wutil_human "$rem")" >&2
    if [ "$rem" -gt 60 ]; then chunk=10; else chunk=1; fi
    [ "$chunk" -gt "$rem" ] && chunk="$rem"
    sleep "$chunk"
    if [ "$_RUTIL_INT" -eq 1 ]; then rc=130; break; fi
  done

  trap - INT
  unset _RUTIL_INT
  [ "$tty" -eq 1 ] && printf '\r\033[K' >&2

  if [ "$rc" -eq 130 ]; then
    echo "rutil: cancelled" >&2
    return 130
  fi

  [ $# -eq 0 ] && return 0
  if [ $# -eq 1 ]; then
    eval "$1"
  else
    "$@"
  fi
}
