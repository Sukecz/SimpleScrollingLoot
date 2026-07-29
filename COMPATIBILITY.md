# Compatibility

Simple Scrolling Loot 0.4.0 uses one Lua implementation with client-specific TOC
metadata.

| Client family | TOC | Interface | Offline checks | Live verification |
| --- | --- | ---: | --- | --- |
| WoW Classic Era | `SimpleScrollingLoot.toc` | 11509 | Passed | Settings and positioning confirmed; full loot matrix pending |
| WoW Classic Hardcore | `SimpleScrollingLoot.toc` | 11509 | Passed; shares the Era client | Pending |
| Burning Crusade Classic Anniversary | `SimpleScrollingLoot_TBC.toc` | 20506 | Passed | Pending |

The interface values were refreshed on 2026-07-26 against current maintained
Vanilla and TBC addon metadata. They are packaging inputs, not proof of runtime
compatibility.

Version 0.4.0 received user confirmation for its redesigned settings,
notification preview controls, and positioning workflow in the current Classic
Era client. The exact `/ssloot debug api` output was not captured, and the
complete compatibility matrix below was not rerun. Before claiming full live
compatibility, record the exact report and test at least:

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

The addon never hooks, hides, closes, or unregisters events from Blizzard's loot
window. This keeps confirmation, group-loot, quest, and protected UI behavior
under Blizzard's control.
