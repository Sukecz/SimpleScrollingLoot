# Changelog

All notable changes to Simple Scrolling Loot will be documented in this file.

## [Unreleased]

## [0.2.0] - 2026-07-26

### Fixed
- Recover safely from corrupt SavedVariables and validate nested, enum, and
  cross-field settings.
- Parse Blizzard loot formats with positional arguments used by reordered
  localizations.
- De-duplicate uncached item requests and reliably expire unresolved records.
- Correlate wallet deltas with money-loot messages without dropping separate
  rapid gains.
- Apply downward travel to animation, make item interaction reachable, bound
  long rows, and prevent stale frame anchors.
- Stop the animation driver while idle and unregister notification events while
  the addon is disabled.

### Added
- Explicit WoW Classic Era, Hardcore, and Burning Crusade Classic client-family
  detection.
- Separate Vanilla (`11509`) and TBC (`20506`) TOC metadata.
- Expanded API report with client family, loaded modules, registered events,
  critical capabilities, and debug event arguments.
- Configurable row opacity, maximum width, mouse interaction, and position
  reset.
- Lua 5.1 regression tests and mandatory CI validation before packaging.

### Changed
- Remove the unverified, English-only honor notification experiment from the
  current release scope.
- Publish packages only from version tags.

## [0.1.0] - 2026-07-25

### Fixed
- Ignore party and raid member loot messages; notifications now accept only
  verified Blizzard self-loot formats.
- Add spacing between Debug Logging and the Scroll Direction dropdown.
- Resolve preview-item icons from the active client instead of relying on
  hard-coded texture paths.

### Changed
- Publish Alpha development builds to CurseForge for every push to `main`.
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
