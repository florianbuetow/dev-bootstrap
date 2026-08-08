# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `CLEANING_THRESHOLD` variable in `just status` triggers auto-clean when stale session count is reached.
- `just attach [SECS]` takes an optional fixed retry delay, replacing the Fibonacci sequence with that single value. Values below 1 second, decimals, non-numbers, and multiple values exit 1 and are never corrected.

### Changed

- Stale session rows now grey out all columns, not just session name and path.
- Retry delays now follow the Fibonacci sequence `1 1 2 3 5 8 13 21` seconds, holding at 21. Bash and Zsh use their native array bases, and a fixed delay is stored twice so both shells address it safely.
- Status refreshes use a fixed two-entry delay array: `10 10` by default, or two copies of the user-supplied interval.
- The retry index resets when a session is attached. After detaching, the watcher immediately tries to attach again and waits only when no session is free; `auto-attach.sh` reports the outcome and `loop.sh` owns all pacing.

## 2026-05-17

### Added

- Auto-attach watcher that locks sessions with flock for mutual exclusion.
- Live session status table showing watch and attachment state per session.
- Post-detach retry with countdown before attempting the next session.
- `wrap` shell function creating per-directory WRAP-named tmux sessions.
- `just clean` command to remove stale lockfiles from orphaned sessions.
