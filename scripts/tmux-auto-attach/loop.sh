#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"

# Retry delays in seconds. The index starts at the shell's native array base,
# advances by one on every failed retry, and stays on the final entry.
RETRY_LADDER=(1 1 2 3 5 8 13 21)

# Bash arrays start at index 0 and Zsh arrays start at index 1. Use the native
# base so both shells visit every entry in the ladder.
if [ -n "${ZSH_VERSION:-}" ]; then
    LADDER_BASE=1
else
    LADDER_BASE=0
fi

# auto-attach.sh exit code meaning "attached to a session".
ATTACHED=0

# An optional argument replaces the ladder with two copies of that value, so
# every retry waits the same. It must be a whole number of seconds, at least 1;
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
    RETRY_LADDER=("$1" "$1")
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

last=$((${#RETRY_LADDER[@]} - 1 + LADDER_BASE))
idx=$LADDER_BASE

while true; do
    "$HERE/auto-attach.sh"
    rc=$?

    # A successful attach resets the ladder. After the user detaches, try the
    # next session immediately; delays are only for failed attach attempts.
    if [ "$rc" -eq "$ATTACHED" ]; then
        idx=$LADDER_BASE
        continue
    fi

    countdown "${RETRY_LADDER[$idx]}"

    if [ "$idx" -lt "$last" ]; then
        idx=$((idx + 1))
    fi
done
