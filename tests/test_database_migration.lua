-- Regression test for removal of obsolete background-style settings.
-- Run with: lua tests/test_database_migration.lua

local ns = {}
assert(loadfile("Defaults.lua"))("SimpleScrollingLoot", ns)
assert(loadfile("Database.lua"))("SimpleScrollingLoot", ns)

SimpleScrollingLootDB = {
    version = 1,
    backgroundStyle = "DIALOG",
    backgroundRed = 0.8,
    backgroundGreen = 0.2,
    backgroundBlue = 0.1,
    backgroundPadding = 12,
    backgroundBorderOpacity = 0.4,
    lootFrameMode = "ALWAYS_HIDE",
    lootFrameBypassModifier = "SHIFT",
}

ns.Database.Initialize()

assert(SimpleScrollingLootDB.version == 3, "database must migrate to version 3")
assert(SimpleScrollingLootDB.backgroundRounded == false, "rounded corners must default safely")
assert(SimpleScrollingLootDB.backgroundStyle == nil, "obsolete style must be removed")
assert(SimpleScrollingLootDB.backgroundRed == nil, "obsolete red must be removed")
assert(SimpleScrollingLootDB.backgroundGreen == nil, "obsolete green must be removed")
assert(SimpleScrollingLootDB.backgroundBlue == nil, "obsolete blue must be removed")
assert(SimpleScrollingLootDB.backgroundPadding == nil, "obsolete padding must be removed")
assert(SimpleScrollingLootDB.backgroundBorderOpacity == nil, "obsolete border opacity must be removed")
assert(SimpleScrollingLootDB.lootFrameMode == nil, "loot frame mode must be removed")
assert(SimpleScrollingLootDB.lootFrameBypassModifier == nil, "loot frame bypass must be removed")

print("Database migration tests passed")

SimpleScrollingLootDB = "corrupt"
ns.Database.Initialize()
assert(type(SimpleScrollingLootDB) == "table", "corrupt root must be replaced")
assert(SimpleScrollingLootDB.anchor.point == "CENTER", "replacement must include a valid anchor")

SimpleScrollingLootDB = {
    version = 3,
    direction = "SIDEWAYS",
    duration = "bad",
    fadeDuration = 99,
    anchor = "bad",
}
ns.Database.Initialize()
assert(SimpleScrollingLootDB.direction == "UP", "invalid enum must use its default")
assert(SimpleScrollingLootDB.duration == ns.Defaults.duration, "invalid numeric type must use its default")
assert(SimpleScrollingLootDB.fadeDuration <= SimpleScrollingLootDB.duration, "fade must not exceed duration")
assert(type(SimpleScrollingLootDB.anchor) == "table", "invalid nested table must be replaced")

print("Database corruption tests passed")
