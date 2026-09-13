# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added `js`, which runs `just stats` and falls back to `just status`.
- Added `wutil` for scheduling a command to run at a wall-clock time.
- Added `rutil`, a foreground sibling of `wutil` that runs in the calling shell.
- Added `Luna` and `LUNA` variants of the max-effort `luna` codex wrapper.
- Added `scripts/timestamp-as-str.sh`, an executable zsh command that renders the current date and time as a readable sentence.
- Added install instructions for `qsearch`, the ripgrep/clawgrep file search.

### Changed

- Renamed the `tstat` tmux status shortcut to `tsys` to make its purpose unambiguous.
- Updated `tmon` to retry with Fibonacci delays by default, accept an optional fixed delay such as `tmon 5`, and avoid unpaced retry loops after sessions detach.

### Fixed

- Fixed timestamp output running into the shell prompt.
- Fixed `ls` consuming its first path argument as an icon mode.
- Fixed `js` output running into the next shell prompt on every path.
