#!/usr/bin/env bash
# murder - Kill stubborn processes with escalating force
# Tries gentle signals first (TERM, INT, HUP) before resorting to KILL signal.
# Especially useful for killing by port (murder :3000) without looking up PIDs.
# Usage: murder 1234 (by PID) | murder ruby (by name, interactive) | murder :3000 (by port)
# inspired by: https://robotpaper.ai/useful-bash-scripts/

_murder_is_int_nonzero() {
  local s="${1:-}"
  [[ "$s" =~ ^[0-9]+$ ]] && [[ "$s" != "0" ]]
}

_murder_running_pid() {
  local pid="$1"
  ps -p "$pid" >/dev/null 2>&1
}

_murder_go_ahead() {
  local ans
  IFS= read -r ans || return 1
  ans="$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]' | xargs)"
  [[ "$ans" == "y" || "$ans" == "yes" || "$ans" == "yas" ]]
}

_murder_kill_pid_signal() {
  local pid="$1" code="$2"
  kill "-$code" "$pid" >/dev/null 2>&1 || true
}

_murder_pid() {
  local pid="$1"
  local code wait
  local SIGNALS=(
    "15 3"
    "2 3"
    "1 4"
    "9 0"
  )

  for sig in "${SIGNALS[@]}"; do
    _murder_running_pid "$pid" || break

    code="${sig%% *}"
    wait="${sig##* }"

    _murder_kill_pid_signal "$pid" "$code"
    sleep 0.5
    if _murder_running_pid "$pid"; then
      sleep "$wait"
    fi
  done
}

_murder_names() {
  local name="$1"

  while true; do
    local should_loop=0

    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      local pid fullname
      pid="${line%% *}"
      fullname="${line#* }"

      [[ "$pid" == "$$" ]] && continue

      printf "murder %s (pid %s)? " "$fullname" "$pid"
      if _murder_go_ahead; then
        _murder_pid "$pid"
        should_loop=1
        break
      fi
    done < <(ps -eo pid=,command= | grep -Fiw -- "$name" || true)

    [[ "$should_loop" -eq 1 ]] || break
  done
}

_murder_port() {
  local arg="$1"

  while true; do
    local should_loop=0

    local lsofs
    lsofs="$(lsof -i "$arg" 2>/dev/null || true)"
    [[ -z "$lsofs" ]] && break

    while IFS= read -r line; do
      local pid
      pid="$(awk '{print $2}' <<<"$line")"
      [[ -z "${pid:-}" ]] && continue

      local fullname
      fullname="$(ps -eo command= -p "$pid" 2>/dev/null | head -n 1 || true)"
      [[ -z "$fullname" ]] && continue

      printf "murder %s (pid %s)? " "$fullname" "$pid"
      if _murder_go_ahead; then
        _murder_pid "$pid"
        should_loop=1
        break
      fi
    done < <(printf '%s\n' "$lsofs" | tail -n +2)

    [[ "$should_loop" -eq 1 ]] || break
  done
}

murder() {
  if [[ $# -lt 1 ]]; then
    cat <<'EOF'
usage:
murder 123    # kill by pid
murder ruby   # kill by process name
murder :3000  # kill by port
EOF
    return 1
  fi

  local arg
  for arg in "$@"; do
    local is_pid=0 is_port=0
    if _murder_is_int_nonzero "$arg"; then
      is_pid=1
    elif [[ "${arg:0:1}" == ":" ]] && _murder_is_int_nonzero "${arg:1}"; then
      is_port=1
    fi

    if [[ "$is_pid" -eq 1 ]]; then
      _murder_pid "$arg"
    elif [[ "$is_port" -eq 1 ]]; then
      _murder_port "$arg"
    else
      _murder_names "$arg"
    fi
  done
}
