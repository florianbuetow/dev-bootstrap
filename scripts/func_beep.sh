#!/usr/bin/env bash
# boop - Announces command completion status with text-to-speech (macOS)
# Usage: some-long-command; boop
# Will say "Command completed" if the previous command succeeded, or "Command failed" if it failed.
# Note: On non-Mac systems, replace 'say' with 'play' or 'sfx' for sound effects.
# inspired by: https://robotpaper.ai/useful-bash-scripts/

boop () {
  local last="$?"
  if [[ "$last" == '0' ]]; then
    say "Command completed"
  else
    say "Command failed"
  fi
  $(exit "$last")
}
