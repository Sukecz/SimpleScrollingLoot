# Changelog

All notable changes to Simple Scrolling Loot will be documented in this file.

## [Unreleased]

### Fixed
- Ignore party and raid member loot messages; notifications now accept only
  verified Blizzard self-loot formats.
- Add spacing between Debug Logging and the Scroll Direction dropdown.
- Resolve preview-item icons from the active client instead of relying on
  hard-coded texture paths.

### Changed
- Publish an Alpha build to CurseForge for every push to `main`.
- Add complete installation, configuration, support, and CurseForge project
  descriptions.
- Replace ineffective background colour and style controls with a working
  Rounded Corners option and immediate preview updates.
- Update default notification settings to the tested configuration.
- Remove every Blizzard loot-window manipulation feature and setting.

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
