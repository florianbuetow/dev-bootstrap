#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v flock >/dev/null 2>&1; then
    echo "error: flock not found. install it with: brew install flock" >&2
    exit 1
fi

while true; do
    "$HERE/auto-attach.sh"
done
