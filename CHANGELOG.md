# Changelog

All notable changes to Simple Scrolling Loot will be documented in this file.

## [Unreleased]

### Fixed
- Ignore party and raid member loot messages; notifications now accept only
  verified Blizzard self-loot formats.
- Add spacing between Debug Logging and the Scroll Direction dropdown.

### Changed
- Publish an Alpha build to CurseForge for every push to `main`.
- Add complete installation, configuration, support, and CurseForge project
  descriptions.

## [0.1.0-alpha.2] - 2026-07-25

### Added
- Initial project structure for Simple Scrolling Loot.
- WoW Classic Era API compatibility probe (`/ssloot debug api`).
- Standalone notification rendering engine with frame pooling.
- Configurable notification anchor with unlock and drag mode.
- Item loot parser with localized format string matching and quality coloring.
- Money gain tracking with coin icon formatting and duplicate suppression.
- Optional vendor value calculation.
- Modern & Classic Options UI integration.
- Optional Blizzard Loot Frame hiding controller with safe fail-open rules.
- SavedVariables persistence (`SimpleScrollingLootDB`).
- Slash command handler (`/simplescrollingloot`, `/ssloot`).
