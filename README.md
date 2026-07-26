# Simple Scrolling Loot

<p align="center">
  <img src="assets/ssl.png" alt="Simple Scrolling Loot logo" width="280">
</p>

**Simple Scrolling Loot** (`SimpleScrollingLoot`) is a lightweight,
zero-dependency loot notification addon for World of Warcraft. It
renders its own notification rows and never uses Blizzard Scrolling Combat
Text.

> Current release: 0.3.1.

## Client coverage

The 0.2 release targets the complete current Classic family:

- WoW Classic Era, including Hardcore realms (`Interface 11509`);
- Burning Crusade Classic Anniversary Edition (`Interface 20506`).

The package contains separate Vanilla and TBC TOC metadata while sharing one
Lua implementation. Runtime checks use both the loaded TOC flavor and Blizzard
project constants, then verify every critical API before registering loot
events. Retail, Mists of Pandaria Classic, and other clients remain disabled.

Offline Lua and metadata tests cover both target families. Version 0.3.1 has
not yet been verified in a live WoW client; see
[`COMPATIBILITY.md`](COMPATIBILITY.md) for the outstanding test matrix.

## Features

- **Your Loot Only**: Displays only item loot received by your character; party
  and raid member loot is always ignored.
- **Item Loot Notifications**: Displays item icon, rarity-colored name, and stack quantity.
- **Money Notifications**: Formatted gold, silver, and copper gains with coin icons.
- **Optional Vendor Value**: Shows total vendor sell price for looted items.
- **Optional Bag & Bank Counts**: Shows separate non-zero quantities of the
  looted item held in bags and bank.
- **Standalone Rendering**: Completely independent frame rendering (does NOT rely on Blizzard Scrolling Combat Text or `CombatText_AddMessage`).
- **Movable & Configurable Anchor**: Unlock, position, and reset your loot notifications anywhere on screen.
- **Customizable Appearance & Animation**: Adjust font size, icon size, maximum width, scroll direction (UP/DOWN), duration, travel distance, opacity, max visible rows, and optional static mode.
- **Optional Item Interaction**: Enable normal item tooltips and standard modified item-link clicks without intercepting the mouse by default.
- **Background Styling**: Enable a Blizzard-styled rounded-corner frame and
  adjust its opacity.
- **Untouched Loot Window**: Never hooks, hides, or otherwise changes the Blizzard loot window.
- **Diagnostic Compatibility Probe**: Included `/ssl debug api` command to verify client API compatibility.

## Slash Commands

You can use `/ssl`, `/ssloot`, or `/simplescrollingloot`:

- `/ssl`, `/ssloot`, or `/simplescrollingloot` - Open options window
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

Extract the `SimpleScrollingLoot` directory into your World of Warcraft
installation folder:

```text
World of Warcraft/<client>/Interface/AddOns/
```

Restart WoW or reload UI with `/reload`.

## Configuration

Open settings with `/ssloot`. The panel includes controls for item-quality
filtering, icons, vendor value, bag and bank counts, background, row opacity,
maximum width, scale, font/icon sizes, duration, fade, travel distance,
spacing, scrolling direction, static mode, mouse interaction, and visible-row
limit. Enable **Rounded
Corners** for a Blizzard-styled rounded frame, then adjust its background
opacity separately.

Use `/ssloot unlock` to place the anchor, `/ssloot test` to preview the result,
and `/ssloot lock` when finished.

## Support

Report a reproducible issue at
https://github.com/Sukecz/SimpleScrollingLoot/issues. Include your WoW version,
locale, exact loot scenario, and `/ssloot debug api` output. Do not include
account, API, or authentication secrets in a report.

## Releases

Every push and pull request runs Lua 5.1 syntax, regression, and TOC consistency
checks. Only version tags in the form `v*` package and upload a build to
CurseForge project `1624616` and create a matching GitHub release. Tags
containing `alpha` or `beta` publish that release type; other version tags
publish a Release.

Before creating a release tag, add a repository Actions secret named
`CF_API_TOKEN` with a CurseForge author upload token. The token is never stored
in this repository. Only publish a Release after testing it in the intended WoW
client.

## License

MIT License
