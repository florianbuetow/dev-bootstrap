#!/usr/bin/env bash
# Count stale lockfiles (lockfiles whose tmux session no longer exists) and run
# cleanup.sh once the count reaches the threshold. Shared by tmon
# (auto-attach.sh) and tstat (justfile `status`) so the trigger logic lives in
# one place. Override the threshold with the CLEANING_THRESHOLD env var.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_DIR="$HERE/LOCKS"
THRESHOLD="${CLEANING_THRESHOLD:-8}"

[ -d "$LOCK_DIR" ] || exit 0

active_keys=$(tmux list-sessions -F '#{session_name}' 2>/dev/null \
    | while IFS= read -r n; do printf '%s\n' "$(printf '%s' "$n" | tr -c 'a-zA-Z0-9._-' '_')"; done || true)

stale_count=0
shopt -s nullglob
for lockfile in "$LOCK_DIR"/*; do
    [ -f "$lockfile" ] || continue
    key=$(basename "$lockfile")
    if [ -z "$active_keys" ] || ! printf '%s\n' "$active_keys" | grep -Fxq "$key"; then
        stale_count=$((stale_count + 1))
    fi
done
shopt -u nullglob

if [ "$stale_count" -ge "$THRESHOLD" ]; then
    printf "\033[0;33m⚠ %d stale session(s) reached threshold %d — running clean\033[0m\n" "$stale_count" "$THRESHOLD"
    echo ""
    "$HERE/cleanup.sh"
    echo ""
fi
