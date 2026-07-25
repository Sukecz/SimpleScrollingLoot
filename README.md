# Simple Scrolling Loot

**Simple Scrolling Loot** (`SimpleScrollingLoot`) is a lightweight, zero-dependency loot notification addon for World of Warcraft Classic Era.

## Features

- **Item Loot Notifications**: Displays item icon, rarity-colored name, and stack quantity.
- **Money Notifications**: Formatted gold, silver, and copper gains with coin icons.
- **Optional Vendor Value**: Shows total vendor sell price for looted items.
- **Standalone Rendering**: Completely independent frame rendering (does NOT rely on Blizzard Scrolling Combat Text or `CombatText_AddMessage`).
- **Movable & Configurable Anchor**: Unlock and position your loot notifications anywhere on screen.
- **Customizable Appearance & Animation**: Adjust font size, icon size, scroll direction (UP/DOWN), duration, travel distance, opacity, max visible rows, and optional static mode.
- **Optional Loot Frame Hiding**: Configurable behavior for hiding the standard Blizzard loot window during auto-looting, with modifier key bypass (e.g. SHIFT) and safety checks for quest items, BoP, and group loot.
- **Diagnostic Compatibility Probe**: Included `/ssloot debug api` command to verify client API compatibility.

## Slash Commands

- `/simplescrollingloot` or `/ssloot` - Open options panel
- `/ssloot on` - Enable addon
- `/ssloot off` - Disable addon
- `/ssloot test` - Display test/preview notifications
- `/ssloot unlock` - Unlock and display notification anchor for dragging
- `/ssloot lock` - Lock notification anchor
- `/ssloot reset` - Reset configuration to default settings
- `/ssloot debug` - Toggle debug logging
- `/ssloot debug api` - Print client API compatibility report
- `/ssloot help` - Show slash command help

## Installation

Extract the `SimpleScrollingLoot` directory into your World of Warcraft installation folder:
`World of Warcraft/_classic_era_/Interface/AddOns/`

Restart WoW or reload UI with `/reload`.

## License

MIT License
