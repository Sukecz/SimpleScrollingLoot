# Simple Scrolling Loot

Simple Scrolling Loot is a lightweight, standalone loot notification addon for
World of Warcraft. It shows your own item and money gains near the
center of the screen without relying on Blizzard Scrolling Combat Text.

## Features

- Shows only loot received by your character; party and raid member loot is
  never displayed.
- Displays item icon, rarity-coloured item name, stack quantity, and optional
  total vendor value.
- Shows positive money gains with gold, silver, and copper formatting.
- Supports configurable minimum item quality, icon size, font size, opacity,
  spacing, duration, travel distance, scale, and maximum visible rows.
- Includes an optional Blizzard-styled rounded-corner frame with configurable
  opacity.
- Offers upward, downward, and static-fade notification modes.
- Includes a movable, previewable anchor and test notifications.
- Can safely hide the Blizzard loot window only when the selected mode permits
  it, with a modifier-key bypass and fail-open handling for unsafe loot.
- Uses no external libraries and does not depend on Blizzard Scrolling Combat
  Text.

## Client coverage

Simple Scrolling Loot uses capability checks instead of a runtime client-version
gate. Run `/ssloot debug api` on each target client before relying on a build;
compatibility is only claimed after that client has been tested.

## Commands

`/ssloot` or `/simplescrollingloot` opens settings.

- `/ssloot on` or `/ssloot off` enables or disables notifications.
- `/ssloot test` shows sample notifications.
- `/ssloot unlock` and `/ssloot lock` control the notification anchor.
- `/ssloot reset` resets settings after confirmation.
- `/ssloot debug` toggles diagnostic logging.
- `/ssloot debug api` prints the client/API compatibility report.
- `/ssloot help` lists commands in game.

## Installation

Extract the `SimpleScrollingLoot` folder into
`World of Warcraft/<client>/Interface/AddOns/`, then restart the game or run
`/reload`.

## Development status and support

This project is currently in Alpha. Please report reproducible issues, your
WoW client build, locale, and the output of `/ssloot debug api` at the GitHub
repository: https://github.com/Sukecz/SimpleScrollingLoot

The addon is original code and is not affiliated with, copied from, or
dependent on SLoTe or Blizzard Scrolling Combat Text.
