# Simple Scrolling Loot

**Simple Scrolling Loot** (`SimpleScrollingLoot`) is a lightweight, zero-dependency loot notification addon for World of Warcraft Classic Era.

## Features

- **Item Loot Notifications**: Displays item icon, rarity-colored name, and stack quantity.
- **Money Notifications**: Formatted gold, silver, and copper gains with coin icons.
- **Honor Gain Notifications**: Formatted honor gain notifications.
- **Optional Vendor Value**: Shows total vendor sell price for looted items.
- **Standalone Rendering**: Completely independent frame rendering (does NOT rely on Blizzard Scrolling Combat Text or `CombatText_AddMessage`).
- **Movable & Configurable Anchor**: Unlock and position your loot notifications anywhere on screen.
- **Customizable Appearance & Animation**: Adjust font size, icon size, scroll direction (UP/DOWN), duration, travel distance, opacity, max visible rows, and optional static mode.
- **Optional Loot Frame Hiding**: Configurable behavior for hiding the standard Blizzard loot window during auto-looting, with modifier key bypass (e.g. SHIFT) and safety checks for quest items, BoP, and group loot.
- **Diagnostic Compatibility Probe**: Included `/ssl debug api` command to verify client API compatibility.

## Slash Commands

You can use `/ssl`, `/ssloot`, or `/simplescrollingloot`:

- `/ssl` or `/ssloot` - Open options window
- `/ssl on` - Enable addon
- `/ssl off` - Disable addon
- `/ssl test` - Display test/preview notifications
- `/ssl unlock` - Unlock and display notification anchor for dragging
- `/ssl lock` - Lock notification anchor
- `/ssl reset` - Reset configuration to default settings
- `/ssl debug` - Toggle debug logging
- `/ssl debug api` - Print client API compatibility report
- `/ssl help` - Show slash command help

## Installation

Extract the `SimpleScrollingLoot` directory into your World of Warcraft installation folder:
`World of Warcraft/_classic_era_/Interface/AddOns/`

Restart WoW or reload UI with `/reload`.

## Releases

Version tags in the form `v*` trigger GitHub Actions. The workflow packages a
single `SimpleScrollingLoot` folder, creates the matching GitHub release, and
uploads it to CurseForge project `1624616`.

Before creating the first release tag, add a repository Actions secret named
`CF_API_TOKEN` with a CurseForge author upload token. The token is never stored
in this repository. Use `alpha` tags while the addon is in development; only
publish a Release after testing it in the current WoW Classic Era client.

## License

MIT License
