# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `CLEANING_THRESHOLD` variable in `just status` triggers auto-clean when stale session count is reached.

### Changed

- Stale session rows now grey out all columns, not just session name and path.

## 2026-05-17

### Added

- Auto-attach watcher that locks sessions with flock for mutual exclusion.
- Live session status table showing watch and attachment state per session.
- Post-detach cooldown with countdown before attempting the next session.
- `wrap` shell function creating per-directory WRAP-named tmux sessions.
- `just clean` command to remove stale lockfiles from orphaned sessions.
