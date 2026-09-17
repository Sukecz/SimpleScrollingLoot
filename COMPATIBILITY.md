# Compatibility

Simple Scrolling Loot 0.6.0-beta.1 uses one Lua implementation with client-specific TOC
metadata.

| Client family | TOC | Interface | Offline checks | Live verification |
| --- | --- | ---: | --- | --- |
| WoW Classic Era | `SimpleScrollingLoot.toc` | 11509 | Passed | Settings and positioning confirmed; full loot matrix pending |
| WoW Classic Hardcore | `SimpleScrollingLoot.toc` | 11509 | Passed; shares the Era client | Pending |
| Burning Crusade Classic Anniversary | `SimpleScrollingLoot_TBC.toc` | 20506 | Passed | Pending |
| WoW Forever beta | `SimpleScrollingLoot_Camelot.toc` | 16001 | Passed | Pending user beta test |

The Forever interface value was verified on 2026-09-17 against beta build
`1.60.1.69893`, current maintained addon metadata, and the CurseForge Forever
game version. Interface metadata and offline checks are not proof of runtime
compatibility.

Version 0.4.0 received user confirmation for its redesigned settings,
notification preview controls, and positioning workflow in the current Classic
Era client. Version 0.5.0 adds a repeatable test-notification action to that
positioning mode and passed offline validation. The exact `/ssloot debug api`
output was not captured, and the complete compatibility matrix below was not
rerun. Before claiming full live compatibility, record the exact report and
test at least:

- addon startup and settings on each client family;
- single and stacked item loot;
- cached and uncached item data;
- money loot in both observed event orders;
- upward, downward, and static notifications;
- anchor movement, reset, and persistence;
- optional tooltip and modified item click;
- one non-English client locale;
- normal, automatic, group, quest, gathering, fishing, container, full-bag,
  and combat loot behavior.

For the Forever beta, first capture `/ssloot debug api`, then verify addon
startup, the settings panel, one single item, one stack, one positive money
gain, an uncached item, preview/position controls, and the absence of blocked or
taint errors. Beta APIs and interface numbers may change before launch.

The addon never hooks, hides, closes, or unregisters events from Blizzard's loot
window. This keeps confirmation, group-loot, quest, and protected UI behavior
under Blizzard's control.
