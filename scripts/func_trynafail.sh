#!/usr/bin/env bash
# trynafail - Run a command repeatedly until it fails
# Usage: trynafail curl https://api.com/health
# Runs the command repeatedly with 0.5 second delays until it returns a non-zero exit code.
# source: https://robotpaper.ai/useful-bash-scripts/

trynafail() {
  "$@"
  while [[ "$?" -eq 0 ]]; do
    sleep 0.5
    "$@"
  done
}
