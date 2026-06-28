#!/usr/bin/env bash
set -e

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_DIR="$HERE/LOCKS"

printf "\033[0;34m=== Tmux Session Status ===\033[0m\n"
echo ""

# Display a path relative to $HOME (as ~/...) when it lives inside $HOME,
# otherwise keep it absolute.
prettify_path() {
    local p="$1"
    if [ -z "$p" ]; then
        printf ''
        return
    fi
    if [ "$p" = "$HOME" ]; then
        printf '~'
    elif [ "${p#$HOME/}" != "$p" ]; then
        printf '~/%s' "${p#$HOME/}"
    else
        printf '%s' "$p"
    fi
}

raw_sessions=$(tmux list-sessions -F '#{session_created}|#{session_name}|#{session_path}|#{session_attached}' 2>/dev/null | sort -rn -t'|' -k1,1)

sessions=""
if [ -n "$raw_sessions" ]; then
    while IFS='|' read -r ts name path attached; do
        pretty=$(prettify_path "$path")
        created=$(date -r "$ts" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "")
        line="$ts|$name|$created|$pretty|$attached"
        if [ -z "$sessions" ]; then
            sessions="$line"
        else
            sessions="$sessions"$'\n'"$line"
        fi
    done <<< "$raw_sessions"
fi

active_keys=""
if [ -n "$sessions" ]; then
    active_keys=$(printf '%s\n' "$sessions" | awk -F'|' '{print $2}' | while IFS= read -r n; do
        printf '%s\n' "$(printf '%s' "$n" | tr -c 'a-zA-Z0-9._-' '_')"
    done)
fi

stale=""
if [ -d "$LOCK_DIR" ]; then
    shopt -s nullglob
    for lockfile in "$LOCK_DIR"/*; do
        [ -f "$lockfile" ] || continue
        key=$(basename "$lockfile")
        if [ -z "$active_keys" ] || ! printf '%s\n' "$active_keys" | grep -Fxq "$key"; then
            created=$(date -r "$lockfile" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "")
            if [ -z "$stale" ]; then
                stale="$key|$created||0"
            else
                stale="$stale"$'\n'"$key|$created||0"
            fi
        fi
    done
    shopt -u nullglob
fi

if [ -z "$sessions" ] && [ -z "$stale" ]; then
    printf "\033[0;33mNo tmux sessions\033[0m\n"
    exit 0
fi

header_watch="Watching"
header_att="Attached"
header_name="Session Name"
header_created="Created"
header_path="Path"

watch_w=${#header_watch}
att_w=${#header_att}
name_w=${#header_name}
created_w=${#header_created}
path_w=${#header_path}

if [ -n "$sessions" ]; then
    while IFS='|' read -r _ name created path attached; do
        [ ${#name} -gt $name_w ] && name_w=${#name}
        [ ${#created} -gt $created_w ] && created_w=${#created}
        [ ${#path} -gt $path_w ] && path_w=${#path}
    done <<< "$sessions"
fi

if [ -n "$stale" ]; then
    while IFS='|' read -r name created path attached; do
        [ ${#name} -gt $name_w ] && name_w=${#name}
        [ ${#created} -gt $created_w ] && created_w=${#created}
        [ ${#path} -gt $path_w ] && path_w=${#path}
    done <<< "$stale"
fi

h_watch=$(printf '─%.0s' $(seq 1 $((watch_w + 2))))
h_att=$(printf '─%.0s' $(seq 1 $((att_w + 2))))
h_name=$(printf '─%.0s' $(seq 1 $((name_w + 2))))
h_created=$(printf '─%.0s' $(seq 1 $((created_w + 2))))
h_path=$(printf '─%.0s' $(seq 1 $((path_w + 2))))

printf "┌%s┬%s┬%s┬%s┬%s┐\n" "$h_name" "$h_path" "$h_watch" "$h_att" "$h_created"
printf "│ %-*s │ %-*s │ %-*s │ %-*s │ %-*s │\n" "$name_w" "$header_name" "$path_w" "$header_path" "$watch_w" "$header_watch" "$att_w" "$header_att" "$created_w" "$header_created"
printf "├%s┼%s┼%s┼%s┼%s┤\n" "$h_name" "$h_path" "$h_watch" "$h_att" "$h_created"

centered_mark() {
    local sym="$1" width="$2"
    local sym_w=${#sym}
    local lpad=$(( (width - sym_w) / 2 ))
    local rpad=$(( width - sym_w - lpad ))
    printf '%*s%s%*s' "$lpad" '' "$sym" "$rpad" ''
}

render_row() {
    local name="$1" created="$2" path="$3" attached="$4" grey="$5"
    local lock_key=$(printf '%s' "$name" | tr -c 'a-zA-Z0-9._-' '_')
    local lockfile="$LOCK_DIR/$lock_key"
    local locked=no
    if [ -e "$lockfile" ]; then
        flock -n "$lockfile" true 2>/dev/null || locked=yes
    fi
    local watch_sym att_sym
    if [ "$locked" = yes ]; then
        watch_sym="yes"
    else
        watch_sym="-"
    fi
    if [ "${attached:-0}" != "0" ] && [ -n "$attached" ]; then
        att_sym="yes"
    else
        att_sym="-"
    fi
    local watch_mark=$(centered_mark "$watch_sym" "$watch_w")
    local att_mark=$(centered_mark "$att_sym" "$att_w")
    local name_padded=$(printf '%-*s' "$name_w" "$name")
    local path_padded=$(printf '%-*s' "$path_w" "$path")
    local created_padded=$(printf '%-*s' "$created_w" "$created")
    if [ "$grey" = yes ]; then
        name_padded=$(printf '\033[0;90m%s\033[0m' "$name_padded")
        path_padded=$(printf '\033[0;90m%s\033[0m' "$path_padded")
        watch_mark=$(printf '\033[0;90m%s\033[0m' "$watch_mark")
        att_mark=$(printf '\033[0;90m%s\033[0m' "$att_mark")
        created_padded=$(printf '\033[0;90m%s\033[0m' "$created_padded")
    fi
    printf "│ %s │ %s │ %s │ %s │ %s │\n" "$name_padded" "$path_padded" "$watch_mark" "$att_mark" "$created_padded"
}

if [ -n "$sessions" ]; then
    while IFS='|' read -r _ name created path attached; do
        render_row "$name" "$created" "$path" "$attached" no
    done <<< "$sessions"
fi

if [ -n "$stale" ]; then
    while IFS='|' read -r name created path attached; do
        render_row "$name" "$created" "$path" "$attached" yes
    done <<< "$stale"
fi

printf "└%s┴%s┴%s┴%s┴%s┘\n" "$h_name" "$h_path" "$h_watch" "$h_att" "$h_created"
