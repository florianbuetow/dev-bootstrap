# Helper: collect wrap sessions as tab-separated "dir\tnum\tname" lines
# Usage: _wrap_sessions [session_base]
#   With session_base: returns sessions matching that path
#   Without: returns all wrap sessions
_wrap_sessions() {
    local filter="$1"
    local sessions
    sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)
    [ -z "$sessions" ] && return

    while IFS= read -r name; do
        if [[ "$name" =~ '^WRAP-\[([0-9]+)\]-(.+)$' ]]; then
            local num="${match[1]}" dir="${match[2]}"
            if [ -z "$filter" ] || [ "$dir" = "$filter" ]; then
                echo "${dir}	${num}	${name}"
            fi
        fi
    done <<< "$sessions"
}

# Wrap: tmux session manager keyed to working directory
wrap() {
    if ! command -v tmux >/dev/null 2>&1; then
        echo "tmux not installed." >&2
        return 1
    fi

    echo

    local cwd="$PWD"
    local home="$HOME"
    local session_base

    if [[ "$cwd" == "$home" || "$cwd" == "$home/"* ]]; then
        session_base="~${cwd#$home}"
    else
        session_base="$cwd"
    fi
    # tmux replaces dots with underscores in session names
    session_base="${session_base//\./_}"

    # Default: list all wrap sessions + usage
    if [[ -z "$1" ]]; then
        local results
        results=$(_wrap_sessions)

        if [ -z "$results" ]; then
            echo "No wrap sessions found."
        else
            echo "Wrap sessions:"
            echo
            printf '%s\n' "$results" | sort -t$'\t' -k1,1 -k2,2n | while IFS=$'\t' read -r dir num name; do
                echo "  $name"
            done
        fi

        echo
        echo "Usage: wrap new     — create new session for current directory"
        echo "       wrap -r      — reattach to session in current directory"
        echo "       wrap -d      — kill a session in current directory"
        echo
        return 0
    fi

    # New: create session for current directory
    if [[ "$1" == "new" ]]; then
        if [ -n "$TMUX" ]; then
            echo "Already inside a tmux session. Use 'wrap -r' to switch to another." >&2
            return 1
        fi

        local max_num=0
        local results
        results=$(_wrap_sessions)

        if [ -n "$results" ]; then
            while IFS=$'\t' read -r dir num name; do
                (( num > max_num )) && max_num=$num
            done <<< "$results"
        fi

        local next_num=$((max_num + 1))
        local session_name="WRAP-[${next_num}]-${session_base}"

        tmux new-session -s "$session_name"
        return
    fi

    # Reattach: pick session in current directory
    if [[ "$1" == "-r" ]]; then
        local results
        results=$(_wrap_sessions "$session_base")

        if [ -z "$results" ]; then
            echo "No wrap sessions for this directory." >&2
            return 1
        fi

        local -A session_by_num=()
        local -a nums=()
        while IFS=$'\t' read -r dir num name; do
            session_by_num[$num]="$name"
            nums+=("$num")
        done < <(printf '%s\n' "$results" | sort -t$'\t' -k2,2n)

        local target
        if (( ${#nums[@]} == 1 )); then
            target="${session_by_num[${nums[1]}]}"
            echo "Attaching: $target"
        else
            echo "Wrap sessions in ${session_base}:"
            for n in "${nums[@]}"; do
                echo "  [$n] ${session_by_num[$n]}"
            done
            echo

            local choice
            read "choice?Select session #: "
            if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ -z "${session_by_num[$choice]}" ]]; then
                echo "Invalid selection." >&2
                return 1
            fi
            target="${session_by_num[$choice]}"
        fi

        local escaped="${target//\[/\\[}"
        escaped="${escaped//\]/\\]}"
        if [ -n "$TMUX" ]; then
            tmux switch-client -t "$escaped"
        else
            tmux attach-session -t "$escaped"
        fi
        return
    fi

    # Delete: kill a session in current directory
    if [[ "$1" == "-d" ]]; then
        local results
        results=$(_wrap_sessions "$session_base")

        if [ -z "$results" ]; then
            echo "No wrap sessions for this directory." >&2
            return 1
        fi

        local -A session_by_num=()
        local -a nums=()
        while IFS=$'\t' read -r dir num name; do
            session_by_num[$num]="$name"
            nums+=("$num")
        done < <(printf '%s\n' "$results" | sort -t$'\t' -k2,2n)

        echo "Wrap sessions in ${session_base}:"
        for n in "${nums[@]}"; do
            echo "  [$n] ${session_by_num[$n]}"
        done
        echo

        local choice
        read "choice?Select session to kill #: "
        if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ -z "${session_by_num[$choice]}" ]]; then
            echo "Invalid selection." >&2
            return 1
        fi

        local target="${session_by_num[$choice]}"
        local escaped="${target//\[/\\[}"
        escaped="${escaped//\]/\\]}"
        if tmux kill-session -t "$escaped"; then
            echo "Killed: $target"
        else
            echo "Failed to kill: $target" >&2
            return 1
        fi
        return
    fi

    echo "Unknown option: $1" >&2
    echo "Usage: wrap [new|-r|-d]" >&2
    return 1
}
