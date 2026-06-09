#!/usr/bin/env bash
# cdb - Change directory to the root of the current git repository
# Usage: cdb

cdb() {
  # First check if we're inside a git working tree (handles worktrees, branches, etc.)
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo 'not inside a git repository'
    return 1
  fi

  # Get the repository root path
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo 'not inside a git repository'
    return 1
  }

  # Verify we got a valid path
  if [[ -z $repo_root ]]; then
    echo 'not inside a git repository'
    return 1
  fi

  cd "$repo_root"
}
