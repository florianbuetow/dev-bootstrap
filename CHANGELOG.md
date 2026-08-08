# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added `scripts/timestamp-as-str.sh`, an executable zsh command that renders the current date and time as a readable sentence.

### Changed

- Renamed the `tstat` tmux status shortcut to `tsys` to make its purpose unambiguous.
- Updated `tmon` to retry with Fibonacci delays by default, accept an optional fixed delay such as `tmon 5`, and avoid unpaced retry loops after sessions detach.
