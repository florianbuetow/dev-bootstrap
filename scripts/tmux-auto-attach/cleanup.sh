#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_DIR="$HERE/LOCKS"

if [ ! -d "$LOCK_DIR" ]; then
    echo "no lock folder ($LOCK_DIR) - nothing to clean"
    exit 0
fi

# Enumerate active sessions. Distinguish "tmux has no server running"
# (legitimate cleanup target - empty active set) from any other tmux
# failure (must NOT delete anything: an empty active set would otherwise
# look like every lock is orphaned and we'd delete locks held by live
# watchers attached on a different socket).
if tmux_out=$(tmux list-sessions -F '#{session_name}' 2>&1); then
    tmux_names="$tmux_out"
elif printf '%s' "$tmux_out" | grep -qi 'no server running'; then
    tmux_names=""
else
    printf 'error: tmux list-sessions failed:\n%s\n' "$tmux_out" >&2
    exit 1
fi

active_keys=""
if [ -n "$tmux_names" ]; then
    active_keys=$(printf '%s\n' "$tmux_names" \
        | while IFS= read -r name; do
              printf '%s\n' "$(printf '%s' "$name" | tr -c 'a-zA-Z0-9._-' '_')"
          done)
fi

removed=0
kept=0
held=0
shopt -s nullglob
for lockfile in "$LOCK_DIR"/*; do
    [ -f "$lockfile" ] || continue
    key=$(basename "$lockfile")
    if [ -n "$active_keys" ] && printf '%s\n' "$active_keys" | grep -Fxq "$key"; then
        printf '  %-40s %s\n' "$key" "kept (session active)"
        kept=$((kept + 1))
    elif ! flock -n "$lockfile" true 2>/dev/null; then
        # Defense in depth: a process is holding the flock even though tmux
        # didn't list a matching session. Could be a different tmux socket,
        # a race against an in-flight detach, or the lossy sanitization
        # mapping the held name to a key we didn't recognize. Never delete.
        printf '  %-40s %s\n' "$key" "kept (lock held)"
        held=$((held + 1))
    else
        rm -f "$lockfile"
        printf '  %-40s %s\n' "$key" "removed (no matching session)"
        removed=$((removed + 1))
    fi
done

echo ""
printf '  %-40s %s\n' "removed" "$removed"
printf '  %-40s %s\n' "kept" "$kept"
printf '  %-40s %s\n' "held" "$held"
