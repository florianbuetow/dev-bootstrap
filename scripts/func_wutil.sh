#!/usr/bin/env bash
# wutil - "wait until": schedule a command with at(1), with logging and history
# Adds to plain at: friendlier time specs (+30m, tomorrow 09:00, ISO dates), a
# per-run log of stdout/stderr, an append-only history of finished runs, and a
# pending list that shows the actual command instead of just a job number.
# Usage: wutil 19:20 'say done' | wutil ls | wutil log | wutil log RUNID
#
# Jobs run detached under atrun, so output goes to the log, not this terminal.
# Requires atrun to be enabled:
#   sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist

WUTIL_LOG_DIR="${WUTIL_LOG_DIR:-$HOME/Library/Logs/wutil}"

# ---------------------------------------------------------------- time parsing

_wutil_tomorrow() {
  date -v+1d +%Y-%m-%d 2>/dev/null || date -d tomorrow +%Y-%m-%d 2>/dev/null
}

_wutil_epoch() {
  # "YYYY-MM-DD HH:MM:SS" (local time) -> epoch seconds. BSD date first, then GNU.
  date -j -f '%Y-%m-%d %H:%M:%S' "$1" +%s 2>/dev/null \
    || date -d "$1" +%s 2>/dev/null
}

_wutil_fmt() {
  # epoch seconds -> display string, per the given strftime format
  date -r "$1" +"$2" 2>/dev/null || date -d "@$1" +"$2" 2>/dev/null
}

_wutil_atq_epoch() {
  # atq's "Mon Aug 10 19:02:00 2026" -> epoch seconds
  date -j -f '%a %b %d %T %Y' "$1" +%s 2>/dev/null || echo 0
}

_wutil_norm_hms() {
  # "9:00" | "09:00:30" -> "09:00:30", rejecting anything out of range
  local t="$1" h m s
  h="${t%%:*}"
  t="${t#*:}"
  case "$t" in
    *:*) m="${t%%:*}"; s="${t##*:}" ;;
    *)   m="$t"; s="00" ;;
  esac
  case "$h$m$s" in ''|*[!0-9]*) return 1 ;; esac
  h=$((10#$h)); m=$((10#$m)); s=$((10#$s))
  [ "$h" -le 23 ] && [ "$m" -le 59 ] && [ "$s" -le 59 ] || return 1
  printf '%02d:%02d:%02d' "$h" "$m" "$s"
}

_wutil_human() {
  # seconds -> "1d 02h 14m 03s", dropping units above the largest non-zero one
  local left="$1" d h m s out=""
  d=$((left / 86400)); left=$((left % 86400))
  h=$((left / 3600));  left=$((left % 3600))
  m=$((left / 60));    s=$((left % 60))
  [ "$d" -gt 0 ] && out="${d}d "
  [ -n "$out" ] && out="${out}$(printf '%02dh ' "$h")"
  [ -z "$out" ] && [ "$h" -gt 0 ] && out="${h}h "
  if [ -n "$out" ]; then
    out="${out}$(printf '%02dm %02ds' "$m" "$s")"
  elif [ "$m" -gt 0 ]; then
    out="$(printf '%dm %02ds' "$m" "$s")"
  else
    out="${s}s"
  fi
  printf '%s' "$out"
}

_wutil_target_epoch() {
  # time spec -> epoch seconds on stdout; message on stderr and 1 on failure.
  # rutil shares this parser, so errors name whichever command was actually typed.
  local spec="$1" now day hms epoch rollable=0 num unit mult body
  local me="${_WUTIL_CMD:-wutil}"
  now=$(date +%s)

  case "$spec" in
    +*)
      body="${spec#+}"
      case "$body" in
        *[sS]) unit=s; num="${body%?}" ;;
        *[mM]) unit=m; num="${body%?}" ;;
        *[hH]) unit=h; num="${body%?}" ;;
        *[dD]) unit=d; num="${body%?}" ;;
        *)     unit=m; num="$body" ;;
      esac
      case "$num" in ''|*[!0-9]*) echo "$me: bad offset: $spec" >&2; return 1 ;; esac
      case "$unit" in
        s) mult=1 ;; m) mult=60 ;; h) mult=3600 ;; d) mult=86400 ;;
      esac
      echo $((now + 10#$num * mult))
      return 0
      ;;
  esac

  spec="${spec/T/ }"
  local w1 w2
  w1="${spec%% *}"
  case "$spec" in
    *' '*) w2="${spec#* }" ;;
    *)     w2="" ;;
  esac

  case "$w1" in
    today)
      day=$(date +%Y-%m-%d); hms=$(_wutil_norm_hms "${w2:-00:00}") ;;
    tomorrow)
      day=$(_wutil_tomorrow); hms=$(_wutil_norm_hms "${w2:-00:00}") ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      day="$w1"; hms=$(_wutil_norm_hms "${w2:-00:00}") ;;
    *:*)
      day=$(date +%Y-%m-%d); hms=$(_wutil_norm_hms "$w1"); rollable=1 ;;
    *)
      echo "$me: unrecognised time: $spec" >&2; return 1 ;;
  esac
  [ -n "$hms" ] || { echo "$me: bad time of day: $spec" >&2; return 1; }

  epoch=$(_wutil_epoch "$day $hms")
  [ -n "$epoch" ] || { echo "$me: cannot resolve: $day $hms" >&2; return 1; }

  if [ "$epoch" -le "$now" ]; then
    if [ "$rollable" -eq 1 ]; then
      # Re-derive from tomorrow's date rather than adding 86400, so the wall-clock
      # time still lands correctly across a DST transition.
      epoch=$(_wutil_epoch "$(_wutil_tomorrow) $hms")
    else
      echo "$me: that time is in the past: $day $hms" >&2
      return 1
    fi
  fi

  echo "$epoch"
}

# ---------------------------------------------------------------------- helpers

_wutil_shquote() {
  # wrap in single quotes so the result survives another round of shell parsing
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

_wutil_oneline() {
  printf '%s' "$1" | tr '\n\t' '  '
}

_wutil_marker() {
  # read a "# wutil-<key>: value" marker back out of a queued job's script
  at -c "$1" 2>/dev/null | sed -n "s/^# wutil-$2: //p" | tail -1
}

_wutil_at_lastline() {
  # The command for a job wutil did not schedule. at(1) appends the user's script
  # after its own preamble, so the last non-blank line is the command. NF skips
  # the trailing blank lines at(1) leaves behind, which a plain tail -1 would hit.
  at -c "$1" 2>/dev/null |
    awk 'NF { last = $0 } END { sub(/[[:space:]]+$/, "", last); print last }'
}

# --------------------------------------------------------------- subcommands

_wutil_ls() {
  local queue
  queue=$(atq 2>/dev/null)
  if [ -z "$queue" ]; then
    echo "  (none)"
    return 0
  fi

  # No `local` below: these loops run in a pipeline subshell, where zsh echoes the
  # declaration instead of quietly scoping it. Subshell scope is enough anyway.
  printf '%-5s  %-23s  %s\n' JOB WHEN COMMAND
  printf '%s\n' "$queue" | while IFS='	' read -r id when; do
    [ -n "$id" ] || continue
    printf '%s\t%s\t%s\n' "$(_wutil_atq_epoch "$when")" "$id" "$when"
  done | sort -n | while IFS='	' read -r epoch id when; do
    # No marker means the job came from somewhere other than wutil - fall back to
    # reading at(1)'s own script.
    wu_cmd=$(_wutil_marker "$id" cmd)
    [ -n "$wu_cmd" ] || wu_cmd=$(_wutil_at_lastline "$id")
    printf '%-5s  %-23s  %s\n' \
      "$id" "$(_wutil_fmt "$epoch" '%a %Y-%m-%d %H:%M:%S')" \
      "${wu_cmd:-(cannot read job script)}"
  done
}

_wutil_log() {
  local hist="$WUTIL_LOG_DIR/history.tsv"

  # A run id argument means "show that run's full output"
  if [ -n "${1:-}" ] && [ "${1#-}" = "$1" ]; then
    local f="$WUTIL_LOG_DIR/runs/$1.log"
    if [ -f "$f" ]; then
      cat "$f"
      return 0
    fi
    echo "wutil: no such run: $1" >&2
    return 1
  fi

  local count=20
  case "${1:-}" in
    -n) count="${2:-20}" ;;
  esac

  if [ ! -s "$hist" ]; then
    echo "  (none)"
    return 0
  fi

  printf '%-23s  %-4s  %-17s  %s\n' STARTED EXIT RUN COMMAND
  tail -n "$count" "$hist" | while IFS='	' read -r started fin rc runid cmd; do
    printf '%-23s  %-4s  %-17s  %s\n' "$started" "$rc" "$runid" "$cmd"
  done
}

_wutil_detail() {
  # Details for one at(1) job number, or for one run id.
  local id="$1"

  if [ -f "$WUTIL_LOG_DIR/runs/$id.log" ]; then
    cat "$WUTIL_LOG_DIR/runs/$id.log"
    return 0
  fi

  case "$id" in
    ''|*[!0-9]*) echo "wutil: not a job number or run id: $id" >&2; return 1 ;;
  esac

  # The live queue wins: at(1) recycles job numbers, so an old run log claiming
  # this number is only trustworthy once the number is no longer queued.
  local when
  when=$(atq 2>/dev/null | awk -F'\t' -v j="$id" '$1 == j {print $2}')

  if [ -n "$when" ]; then
    local epoch cmd
    epoch=$(_wutil_atq_epoch "$when")
    cmd=$(_wutil_marker "$id" cmd)
    [ -n "$cmd" ] || cmd=$(_wutil_at_lastline "$id")

    printf 'job      : %s\n' "$id"
    printf 'scheduled: %s (in %s)\n' \
      "$(_wutil_fmt "$epoch" '%a %Y-%m-%d %H:%M:%S')" \
      "$(_wutil_human $((epoch - $(date +%s))))"
    printf 'command  : %s\n' "${cmd:-(cannot read job script)}"
    printf 'completed: no\n'
    return 0
  fi

  # Gone from the queue, so it has most likely already run. Run logs record the
  # job number they were given; newest wins, since ids get reused.
  local f
  f=$(grep -l "^job  *: $id\$" "$WUTIL_LOG_DIR"/runs/*.log 2>/dev/null | tail -1)
  if [ -n "$f" ]; then
    cat "$f"
    return 0
  fi

  echo "wutil: job $id is not queued and no run log records it" >&2
  return 1
}

_wutil_overview() {
  # What bare `wutil` shows: what is still coming, then what already happened.
  local hist="$WUTIL_LOG_DIR/history.tsv" pending=0 total=0 failed=0 show=10

  pending=$(atq 2>/dev/null | grep -c . | tr -d ' ')
  if [ -s "$hist" ]; then
    total=$(grep -c . "$hist" | tr -d ' ')
    failed=$(tail -n "$show" "$hist" | awk -F'\t' '$3 != 0' | grep -c . | tr -d ' ')
  fi

  # Only on a terminal: redirecting or piping the overview must stay plain text.
  [ -t 1 ] && command clear 2>/dev/null

  printf 'pending (%s)\n' "$pending"
  _wutil_ls

  echo
  if [ "$total" -gt "$show" ]; then
    printf 'recent runs (last %s of %s)' "$show" "$total"
  else
    printf 'recent runs (%s)' "$total"
  fi
  [ "$failed" -gt 0 ] && printf ' - %s failed' "$failed"
  echo
  _wutil_log -n "$show"
}

# --------------------------------------------------------------------- wutil

# The trailing blank line belongs to every path out of wutil, so it lives in the
# wrapper below rather than being repeated at each of the many return points.
wutil() {
  _wutil_main "$@"
  local rc=$?
  echo
  return "$rc"
}

_wutil_main() {
  local dry=0

  # Bare `wutil` is the dashboard. Checked before option parsing, so that a call
  # like `wutil --dry-run` with no time still reports the missing time instead.
  if [ $# -eq 0 ]; then
    _wutil_overview
    return 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run) dry=1; shift ;;
      -h|--help|help)
        cat <<'EOF'
wutil - schedule a command with at(1), with logging and history

scheduling:
  wutil <time> [command ...]
  wutil --dry-run <time>   # resolve the time, schedule nothing

inspecting:
  wutil                    # overview: what is pending, then what already ran
  wutil help               # this text
  wutil ls                 # pending jobs, with their commands
  wutil <job>              # details for one job, queued or already run
  wutil <run-id>           # the same, addressed by run id
  wutil log                # recent finished runs (add -n N for more)
  wutil log <run-id>       # full stdout/stderr of one run
  wutil show <job>         # the script at(1) will actually execute
  wutil rm <job>           # cancel a pending job

time:
  19:20                    # next 19:20 (rolls to tomorrow if already past)
  9:05:30                  # seconds are optional
  +30m                     # relative: s/m/h/d, bare number means minutes
  tomorrow 09:00           # quote it: wutil 'tomorrow 09:00' cmd
  2026-08-11T09:00         # absolute date, T or space separated
  2026-08-11               # midnight on that date

command:
  one argument   -> a shell line (pipes, redirects, && all work)
  several        -> quoted for you, no escaping games

Jobs run detached under atrun; stdout and stderr go to the run log, not here.
Logs live in $WUTIL_LOG_DIR (default ~/Library/Logs/wutil).

examples:
  wutil 19:20 'say "deploy window open"'
  wutil 'tomorrow 02:00' ./nightly.sh
  wutil +45m make test
EOF
        return 0
        ;;
      ls|list)  shift; _wutil_ls "$@"; return $? ;;
      log|runs) shift; _wutil_log "$@"; return $? ;;
      show|cat) shift; [ -n "${1:-}" ] || { echo "wutil: show needs a job number" >&2; return 1; }
                at -c "$1"; return $? ;;
      rm|cancel) shift; [ -n "${1:-}" ] || { echo "wutil: rm needs a job number" >&2; return 1; }
                atrm "$@"; return $? ;;
      --) shift; break ;;
      *) break ;;
    esac
  done

  if [ $# -lt 1 ]; then
    echo "wutil: no time given (try: wutil --help)" >&2
    return 1
  fi

  # A lone identifier means "tell me about that one". No time spec is a bare
  # number, so job numbers are unambiguous; run ids are taken only if one exists.
  if [ $# -eq 1 ]; then
    case "$1" in
      ''|*[!0-9]*)
        [ -f "$WUTIL_LOG_DIR/runs/$1.log" ] && { _wutil_detail "$1"; return $?; }
        ;;
      *)
        _wutil_detail "$1"; return $?
        ;;
    esac
  fi

  local target
  target=$(_wutil_target_epoch "$1") || return 1
  shift

  # at(1) only stores whole minutes and floors what it is given, which would fire
  # early. Round up instead: a sub-minute request slips later, never sooner.
  target=$(( (target + 59) / 60 * 60 ))

  local when
  when=$(_wutil_fmt "$target" '%a %Y-%m-%d %H:%M:%S')

  if [ "$dry" -eq 1 ]; then
    echo "$when (in $(_wutil_human $((target - $(date +%s)))))"
    return 0
  fi

  if [ $# -lt 1 ]; then
    echo "wutil: no command given (try: wutil --dry-run for time checks)" >&2
    return 1
  fi

  # One argument is taken verbatim as a shell line; several are quoted together.
  local cmdline arg
  if [ $# -eq 1 ]; then
    cmdline="$1"
  else
    cmdline=""
    for arg in "$@"; do
      cmdline="${cmdline}${cmdline:+ }$(_wutil_shquote "$arg")"
    done
  fi

  local display runid base i=1
  display=$(_wutil_oneline "$cmdline")

  mkdir -p "$WUTIL_LOG_DIR/runs" || return 1

  # The run log doubles as the claim on the id: created now, appended to when the
  # job fires. Two jobs aimed at the same second therefore cannot share a log.
  base="$(_wutil_fmt "$target" '%Y%m%d-%H%M%S')"
  runid="$base"
  while [ -e "$WUTIL_LOG_DIR/runs/$runid.log" ]; do
    runid="$base-$i"
    i=$((i + 1))
  done
  {
    printf 'scheduled: %s\n' "$when"
    printf 'command  : %s\n' "$display"
  } > "$WUTIL_LOG_DIR/runs/$runid.log"

  local job
  job=$(mktemp "${TMPDIR:-/tmp}/wutil.XXXXXX") || return 1

  # Everything below runs later under /bin/sh, which is what atrun invokes.
  # Runtime expansions are escaped (\$); anything unescaped is baked in now.
  cat > "$job" <<EOF
# wutil job
# wutil-runid: $runid
# wutil-sched: $(_wutil_fmt "$target" '%Y-%m-%dT%H:%M:%S')
# wutil-cmd: $display
_wu_dir=$(_wutil_shquote "$WUTIL_LOG_DIR")
_wu_run="\$_wu_dir/runs/$runid.log"
mkdir -p "\$_wu_dir/runs"
_wu_t0=\$(date +%s)
_wu_started=\$(date '+%a %Y-%m-%d %H:%M:%S')
{
  printf 'started  : %s\n' "\$_wu_started"
  printf -- '----\n'
} >> "\$_wu_run"
( eval $(_wutil_shquote "$cmdline") ) >> "\$_wu_run" 2>&1
_wu_rc=\$?
_wu_fin=\$(date '+%a %Y-%m-%d %H:%M:%S')
_wu_el=\$(( \$(date +%s) - _wu_t0 ))
{
  printf -- '----\n'
  printf 'completed: yes (exit %s)\n' "\$_wu_rc"
  printf 'finished : %s (took %ss)\n' "\$_wu_fin" "\$_wu_el"
} >> "\$_wu_run"
printf '%s\t%s\t%s\t%s\t%s\n' \\
  "\$_wu_started" "\$_wu_fin" "\$_wu_rc" $(_wutil_shquote "$runid") \\
  $(_wutil_shquote "$display") >> "\$_wu_dir/history.tsv"
exit "\$_wu_rc"
EOF

  local out
  out=$(at -f "$job" -t "$(_wutil_fmt "$target" '%Y%m%d%H%M.%S')" 2>&1)
  local rc=$?
  rm -f "$job"

  if [ "$rc" -ne 0 ]; then
    rm -f "$WUTIL_LOG_DIR/runs/$runid.log"
    printf '%s\n' "$out" >&2
    echo "wutil: at(1) refused the job (is atrun enabled?)" >&2
    return "$rc"
  fi

  local jobno
  jobno=$(printf '%s\n' "$out" | sed -n 's/^job \([0-9][0-9]*\).*/\1/p' | tail -1)

  # Recorded so that `wutil <jobno>` keeps working after the job leaves the queue.
  [ -n "$jobno" ] && printf 'job      : %s\n' "$jobno" >> "$WUTIL_LOG_DIR/runs/$runid.log"

  echo "job ${jobno:-?} at $when (in $(_wutil_human $((target - $(date +%s)))))"
}
