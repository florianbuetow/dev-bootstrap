#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Retry delays in seconds. The index starts at 0, advances by one on every
# failed retry, and stays on the last entry once it gets there.
RETRY_LADDER=(1 1 2 3 5 8 13 21)

# auto-attach.sh exit code meaning "attached to a session".
ATTACHED=0

# An optional argument replaces the ladder with that single value, so every
# retry waits the same. It must be a whole number of seconds, at least 1;
# anything else aborts and is never corrected.
if [ "$#" -gt 0 ]; then
    valid=yes
    [ "$#" -eq 1 ] || valid=no
    if [ "$valid" = yes ]; then
        case "$1" in
            '' | *[!0-9]*) valid=no ;;
        esac
    fi
    if [ "$valid" = yes ] && [ "$1" -lt 1 ]; then
        valid=no
    fi
    if [ "$valid" = no ]; then
        printf "\033[0;31m✗ attach failed: retry delay must be a whole number of seconds, minimum 1 (got: %s)\033[0m\n" "$*" >&2
        exit 1
    fi
    RETRY_LADDER=("$1")
fi

if ! command -v flock >/dev/null 2>&1; then
    echo "error: flock not found. install it with: brew install flock" >&2
    exit 1
fi

# Count down one second at a time so the wait is visible and interruptible.
countdown() {
    local secs="$1" i
    for ((i = secs; i >= 1; i--)); do
        printf "\r\033[K\033[0;90m[%s] retrying in %ds - Ctrl-C to stop\033[0m" "$(date +%H:%M:%S)" "$i"
        sleep 1
    done
    printf "\r\033[K"
}

last=$((${#RETRY_LADDER[@]} - 1))
idx=0

while true; do
    "$HERE/auto-attach.sh"
    rc=$?

    # Attaching to a session puts the index back to the start.
    if [ "$rc" -eq "$ATTACHED" ]; then
        idx=0
    fi

    countdown "${RETRY_LADDER[$idx]}"

    if [ "$idx" -lt "$last" ]; then
        idx=$((idx + 1))
    fi
done
