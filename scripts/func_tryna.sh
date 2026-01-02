#!/usr/bin/env bash
# tryna - Retry a command until it succeeds
# Usage: tryna curl https://flaky-api.com/endpoint
# Runs the command repeatedly with 0.5 second delays until it returns exit code 0.
# source: https://robotpaper.ai/useful-bash-scripts/

tryna() {
  "$@"
  while [[ ! "$?" -eq 0 ]]; do
    sleep 0.5
    "$@"
  done
}
