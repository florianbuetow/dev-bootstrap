# Shared shell aliases and interactive helper functions for dev-bootstrap.
#
# Intended to be sourced from zsh:
#   source ~/scripts/dev-bootstrap/scripts/aliases.sh

# Quick shortcuts
alias q='exit'
alias dsdestroy='find . -name .DS_Store -delete'
alias 888='npx n8n start'

# Claude usage shortcuts
alias ccusage='uvx sniffly@latest init'
alias cusage='uvx sniffly@latest init'
alias ccc='uvx sniffly@latest init'

# Just shortcuts
alias j='just'
alias jj='just'
alias jus='just'
alias jsut='just'
alias ci='just ci-quiet && git status'

# Better defaults
alias cat='bat'
alias less='glow'
alias man='tldr'
alias manpage='/usr/bin/man'
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias lt='eza --tree --level=2 --icons'
# li: list only the gitignored files and folders (fully ignored dirs collapse to one entry)
alias li='git ls-files --others --ignored --exclude-standard --directory'

# Navigation
# NOTE: personal `cd*` shortcuts (cdx/cdp/cdd/cdg/cdb/cdlc) reference user-specific
# directories and live in the local-only ~/scripts/local-aliases.sh, not here.
alias attach='tmux attach-session -t'
alias tmon='(cd ~/scripts/dev-bootstrap/scripts/tmux-auto-attach && just attach)'
alias tstat='(cd ~/scripts/dev-bootstrap/scripts/tmux-auto-attach && just status)'
alias findt='~/scripts/dev-bootstrap/scripts/term-switch.sh'
# findtt: same picker, but close the launching terminal after a successful jump
# (the script exits 0 only when it jumped, so a cancel/ESC leaves the shell open)
alias findtt='~/scripts/dev-bootstrap/scripts/term-switch.sh && exit'

# Guard
alias ginit='guard init 0750 root users'

# AI project templates. Clone ai-guardrails into ~/scripts first.
alias newpy='~/scripts/ai-guardrails/project-setup/setup-project-python-claude.sh'
alias newgo='~/scripts/ai-guardrails/project-setup/setup-project-go-claude.sh'
alias newjava='~/scripts/ai-guardrails/project-setup/setup-project-java-claude.sh'
alias newelixir='~/scripts/ai-guardrails/project-setup/setup-project-elixir-claude.sh'
alias newrust='~/scripts/ai-guardrails/project-setup/setup-project-rust-claude.sh'
alias newcpp='~/scripts/ai-guardrails/project-setup/setup-project-cpp-claude.sh'
alias newkotlin='~/scripts/ai-guardrails/project-setup/setup-project-kotlin-claude.sh'
alias newgamecpp='~/scripts/ai-guardrails/project-setup/setup-project-gamecpp-claude.sh'
alias update-templates='cd ~/scripts/ai-guardrails && git pull && cd - >/dev/null'
alias changelog='sonnet "load and use the changelog skill, then commit the updated CHANGELOG.md file and push it if a remote repository is configured, otherwise skip pushing"'

# NOTE: the printcodingprojects / printxragproject / printprojects banner functions
# are user-specific (used only by the personal cd* aliases) and now live in
# ~/scripts/local-aliases.sh, not here.

snow() {
  trap 'printf "\033[?25h"; clear; return' INT

  printf "\033[?25l"
  clear
  typeset -A posY posX stepCount stepDir speed

  get_term_size() {
    LINES=$(tput lines)
    COLUMNS=$(tput cols)
  }

  get_term_size

  update_snow() {
    col=$1
    y=${posY[$col]:-0}
    x=${posX[$col]}
    steps=${stepCount[$col]}
    dir=${stepDir[$col]}
    spd=${speed[$col]}

    get_term_size

    [[ $y -gt 0 ]] && printf "\033[%s;%sH " $y $x

    steps=$((steps + 1))
    max_steps=$((RANDOM % 3 + 1))
    if [[ $steps -gt $max_steps ]]; then
      stepDir[$col]=$(((RANDOM % 3) - 1))
      stepCount[$col]=0
    fi

    new_x=$((x + dir))
    [[ $new_x -ge $COLUMNS ]] && new_x=$((COLUMNS - 2))
    [[ $new_x -lt 0 ]] && new_x=1
    new_y=$((y + spd))

    if [[ $new_y -ge $LINES ]]; then
      posY[$col]=0
      posX[$col]=$((RANDOM % ((COLUMNS > 40 ? COLUMNS - 20 : 20)) + 10))
      stepCount[$col]=0
      stepDir[$col]=0
      speed[$col]=$(((RANDOM % 2) + 1))
      return
    fi

    posY[$col]=$new_y
    posX[$col]=$new_x
    stepCount[$col]=$steps

    flake_idx=$((RANDOM % 5))
    case $flake_idx in
      0) printf "\033[%s;%sH*" $new_y $new_x ;;
      1) printf "\033[%s;%sH+" $new_y $new_x ;;
      2) printf "\033[%s;%sH." $new_y $new_x ;;
      3) printf "\033[%s;%sHo" $new_y $new_x ;;
      *) printf "\033[%s;%sHx" $new_y $new_x ;;
    esac
  }

  while true; do
    get_term_size
    [[ $((RANDOM % 10)) -lt 2 ]] && {
      col=$((RANDOM % ((COLUMNS > 40 ? COLUMNS - 20 : 20)) + 10))
      posY[$col]=0
      posX[$col]=$col
      stepCount[$col]=0
      stepDir[$col]=0
      speed[$col]=$(((RANDOM % 2) + 1))
    }

    for col in ${(k)posY}; do update_snow $col; done
    sleep 0.18
  done
}

showGitStatusWhenInRepo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git status && echo
}

alias cls='clear && showGitStatusWhenInRepo'

l() {
  echo
  ls -A "$@"
  echo
}

ld() {
  echo
  ls -Alhd */
  echo
}

ss() {
  clear
  echo
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git status
  else
    echo "Not inside a git repository."
  fi
  echo
}

llr() {
  find -P . \( -flags +schg -o -flags +uchg \) -print0 2>/dev/null |
    perl -0 -pe 's|^|sprintf("%04d\t", tr{/}{})|e' |
    sort -z -t$'\t' -k1,1n -k2,2 |
    perl -0 -pe 's/^\d+\t//' |
    xargs -0 ls -alhO 2>/dev/null
}

lk() {
  cd "$(walk --icons "$@")"
}

cursor() {
  open -a "/Applications/Cursor.app" "$@"
}

png2jpg() {
  local file filename
  local converted_count=0

  for file in (#i)*.png(.); do
    filename="${file%.*}"
    sips -s format jpeg -s formatOptions 98 "$file" --out "${filename}.jpg"
    echo "Converted $file to ${filename}.jpg"
    rm "$file"
    ((converted_count++))
  done

  if (( converted_count > 0 )); then
    echo "Conversion complete! Converted $converted_count files."
  else
    echo "No .png files found to convert."
  fi
}

work() {
  timer "${1:-20m}" && terminal-notifier -message 'Pomodoro' \
    -title 'Work Timer is up! Take a Break' \
    -sound Crystal
  say "Hi"
}

rest() {
  timer "${1:-5m}" && terminal-notifier -message 'Pomodoro' \
    -title 'Break is over! Get back to work' \
    -sound Crystal
}

loop() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: loop <time> <command...>" >&2
    echo "  time: positive number + unit (s=seconds, m=minutes, h=hours)" >&2
    echo "  Examples: loop 10s echo hi  |  loop 5m ls -la" >&2
    return 1
  fi

  local interval="$1"; shift
  local unit="${interval: -1}"
  local num="${interval%?}"

  if [[ ! "$num" =~ ^[0-9]+$ ]] || [[ "$num" -le 0 ]]; then
    echo "Error: time must be a positive number, got '$num'" >&2
    return 1
  fi

  local seconds
  case "$unit" in
    s) seconds=$num ;;
    m) seconds=$((num * 60)) ;;
    h) seconds=$((num * 3600)) ;;
    *) echo "Error: unknown time unit '$unit' (use s, m, or h)" >&2; return 1 ;;
  esac

  echo "Running every ${num}${unit} (${seconds}s): $*"
  echo "Press Ctrl+C to stop"
  echo
  while true; do
    eval "$@"
    echo
    echo "[$(date +%H:%M:%S)] The following command is re-run every ${num}${unit}: $*"
    sleep "$seconds"
  done
}

mux() {
  local session="${1:-mysession}"

  if tmux has-session -t "$session" 2>/dev/null; then
    tmux attach-session -t "$session"
    return
  fi

  tmux new-session -d -s "$session"
  tmux split-window -h -t "$session"
  tmux split-window -h -t "$session"
  tmux select-layout -t "$session" even-horizontal
  tmux split-window -v -p 67 -t "$session:0.0"
  tmux send-keys -t "$session:0.0" "watch -n15 'git status'" Enter
  tmux send-keys -t "$session:0.1" "watch -n30 'just ci-quiet | tail -20'" Enter
  tmux send-keys -t "$session:0.2" "ls -alh" Enter
  tmux send-keys -t "$session:0.3" "ls -alh" Enter
  tmux attach-session -t "$session"
}

# NOTE: the `ytt` workflow cd's into a user-specific repo path, so it now lives
# in ~/scripts/local-aliases.sh, not here.

# Claude Code wrappers
x() {
  local msg="Please run /cache-money first, then onboard onto this project."
  [ -n "$*" ] && msg="$*"
  claude "$msg"
}

xx() {
  if [ -n "$*" ]; then
    claude "$*"
  else
    claude
  fi
}

cc() {
  local msg="Please onboard onto this project."
  [ -n "$*" ] && msg="$msg And then: $*"
  claude "$msg"
}

haiku() {
  if [ -n "$*" ]; then
    claude --model haiku "$*"
  else
    claude --model haiku
  fi
}

Haiku() { haiku "$@" }
HAIKU() { haiku "$@" }

sonnet() {
  if [ -n "$*" ]; then
    claude --model sonnet "$*"
  else
    claude --model sonnet
  fi
}

Sonnet() { sonnet "$@" }
SONNET() { sonnet "$@" }

opus() {
  if [ -n "$*" ]; then
    claude --model "claude-opus-4-8" --effort max "$*"
  else
    claude --model "claude-opus-4-8" --effort max
  fi
}

Opus() { opus "$@" }
OPUS() { opus "$@" }

ffhaiku() {
  if [ -n "$*" ]; then
    claude --model haiku "$* . When you are done utter the following phrase exactly with no modifications \"I'll be back!\""
  else
    claude --model haiku
  fi
}

ffsonnet() {
  if [ -n "$*" ]; then
    claude --model sonnet --effort max "$* . When you are done utter the following phrase exactly with no modifications \"I'll be back!\""
  else
    claude --model sonnet
  fi
}

ffopus() {
  if [ -n "$*" ]; then
    claude --model "claude-opus-4-8" --effort max "$* . When you are done utter the following phrase exactly with no modifications \"I'll be back!\""
  else
    claude --model "claude-opus-4-8" --effort max
  fi
}

push() {
  local base="Stage all tracked modified files. Do not stage untracked files. If there is nothing to stage or commit, say so and stop. Otherwise, commit the staged files, then push. In both cases at the very end say these exact words: I'll be back!"
  if [ -n "$*" ]; then
    haiku "$base $*"
  else
    haiku "$base"
  fi
}

commit() {
  local base="Stage all tracked modified files. Do not stage untracked files. If there is nothing to stage or commit, say so and stop. Otherwise, commit the staged files. Do not push. In both cases at the very end say these exact words: I'll be back!"
  if [ -n "$*" ]; then
    haiku "$base $*"
  else
    haiku "$base"
  fi
}

_codex_run() {
  local model="$1" effort="$2"; shift 2
  if [ -n "$effort" ]; then
    if [ -n "$*" ]; then
      codex -m "$model" -c model_reasoning_effort="$effort" "$*"
    else
      codex -m "$model" -c model_reasoning_effort="$effort"
    fi
  else
    if [ -n "$*" ]; then
      codex -m "$model" "$*"
    else
      codex -m "$model"
    fi
  fi
}

codex-55()          { _codex_run gpt-5.5 "" "$@" }
codex-55-low()      { _codex_run gpt-5.5 low "$@" }
codex-55-med()      { _codex_run gpt-5.5 medium "$@" }
codex-55-high()     { _codex_run gpt-5.5 high "$@" }
codex-54()          { _codex_run gpt-5.4 "" "$@" }
codex-54-low()      { _codex_run gpt-5.4 low "$@" }
codex-54-med()      { _codex_run gpt-5.4 medium "$@" }
codex-54-high()     { _codex_run gpt-5.4 high "$@" }
codex-54-mini()     { _codex_run gpt-5.4-mini "" "$@" }
codex-54-mini-low() { _codex_run gpt-5.4-mini low "$@" }
codex-54-mini-med() { _codex_run gpt-5.4-mini medium "$@" }
codex-54-mini-high(){ _codex_run gpt-5.4-mini high "$@" }
codex-53-codex()      { _codex_run gpt-5.3-codex "" "$@" }
codex-53-codex-low()  { _codex_run gpt-5.3-codex low "$@" }
codex-53-codex-med()  { _codex_run gpt-5.3-codex medium "$@" }
codex-53-codex-high() { _codex_run gpt-5.3-codex high "$@" }
codex-52()          { _codex_run gpt-5.2 "" "$@" }
codex-52-low()      { _codex_run gpt-5.2 low "$@" }
codex-52-med()      { _codex_run gpt-5.2 medium "$@" }
codex-52-high()     { _codex_run gpt-5.2 high "$@" }
