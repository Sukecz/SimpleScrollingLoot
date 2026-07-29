# Changelog

All notable changes to Simple Scrolling Loot will be documented in this file.

## [Unreleased]

### Added
- Show a short settings and preview hint after every login on a supported
  client.

### Changed
- Hide the settings window while preview notifications are visible and provide
  a standalone **Back to Settings** action.
- Close the settings window while moving notification position, show a
  standalone **Save** button, and reopen settings after saving.
- Redesign the options window into focused General, Appearance, Movement &
  Position, and Advanced pages.
- Replace technical labels such as `Anchor`, numeric item-quality values, and
  row opacity with plain-language controls, visible explanations, named rarity
  choices, and a guided Move Notifications workflow.
- Keep preview and position controls available from every options page, and
  disable settings that have no effect in the current configuration.

## [0.3.6] - 2026-07-27

### Fixed
- Display `PLAYER_MONEY` gains immediately while the player is actively
  looting, including a short grace period for auto-loot event ordering, instead
  of waiting for a later `CHAT_MSG_MONEY` event.
- Preserve chat correlation outside loot so unrelated gains such as selling,
  mail, or trades are not mislabeled as looted money.

## [0.3.5] - 2026-07-27

### Fixed
- Keep the newest notification above older rows while they move away from the
  anchor, preventing smooth reflow from looking like delayed loot display.
- Shorten row reflow to 120 ms so rapid bursts remain smooth and responsive.

## [0.3.4] - 2026-07-27

### Fixed
- Smooth row reflow during rapid item and money loot bursts instead of jumping
  active notifications by a full row at a time.
- Prevent content refreshes and pooled-row setup from briefly flashing
  notifications at full opacity or before their first position is assigned.

## [0.3.3] - 2026-07-26

### Changed
- Remove the redundant large money-row icon; denomination icons remain beside
  each gold, silver, and copper value.

## [0.3.2] - 2026-07-26

### Fixed
- Match the money-notification row icon to the highest denomination received
  instead of always showing gold coins.

## [0.3.1] - 2026-07-26

### Changed
- Replace the combined owned-item total with separate non-zero `Bags` and
  `Bank` counts.
- Refresh active item counts after the client's delayed bag update so the
  looted quantity is included.

## [0.3.0] - 2026-07-26

### Added
- Add an opt-in notification total for copies of the looted item held in bags
  and bank.

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
