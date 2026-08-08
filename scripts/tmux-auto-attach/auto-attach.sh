#!/usr/bin/env bash
set -u

# One-shot attach attempt. Does no waiting of its own - loop.sh owns all retry
# pacing. The exit code tells loop.sh what happened:
#   0  - attached to a session (and has since detached): reset the retry index
#   10 - no session was free: advance the retry index
ATTACHED=0
NOTHING_FREE=10

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_DIR="$HERE/LOCKS"
mkdir -p "$LOCK_DIR"

status_output=$("$HERE/status.sh")
clear
printf '%s\n' "$status_output"
echo ""

"$HERE/maybe-clean.sh"

names=$(tmux list-sessions -F '#{session_created} #{session_name}' 2>/dev/null \
    | sort -rn -k1,1 \
    | cut -d' ' -f2)

if [ -z "$names" ]; then
    exit "$NOTHING_FREE"
fi

exec 3<&0

while IFS= read -r session; do
    lock_key=$(printf '%s' "$session" | tr -c 'a-zA-Z0-9._-' '_')
    exec 9>"$LOCK_DIR/$lock_key"
    if flock -n -E 75 9; then
        echo "attaching to: $session"
        tmux attach -t "$session" <&3
        exec 9>&-
        exec 3<&-
        echo "Detached from $session."
        echo ""
        exit "$ATTACHED"
    fi
    exec 9>&-
done <<< "$names"

exec 3<&-

echo "All sessions already attached."
echo ""
exit "$NOTHING_FREE"
