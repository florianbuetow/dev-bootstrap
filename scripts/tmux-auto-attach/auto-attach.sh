#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_DIR="$HERE/LOCKS"
RETRY_SECS=3
COOLDOWN_SECS=10
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
    printf "\033[0;90m[%s] retrying in ${RETRY_SECS}s - Ctrl-C to stop\033[0m\n" "$(date +%H:%M:%S)"
    echo ""
    sleep "$RETRY_SECS"
    exit 0
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
        # detached: cooldown so the user can break out of the loop
        echo "Detached from $session."
        echo ""
        for i in $(seq "$COOLDOWN_SECS" -1 1); do
            printf "\r\033[K\033[0;90m[%s] Attempting to attach to the next session in %ds - Ctrl-C to stop\033[0m" "$(date +%H:%M:%S)" "$i"
            sleep 1
        done
        printf "\r\033[K"
        exit 0
    fi
    exec 9>&-
done <<< "$names"

exec 3<&-

# no session was free: wait longer before retrying
echo "All sessions already attached."
echo ""
printf "\033[0;90m[%s] retrying in ${RETRY_SECS}s - Ctrl-C to stop\033[0m\n" "$(date +%H:%M:%S)"
echo ""
sleep "$RETRY_SECS"
