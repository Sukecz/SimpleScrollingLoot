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
}

ns.Database.Initialize()

assert(SimpleScrollingLootDB.version == 2, "database must migrate to version 2")
assert(SimpleScrollingLootDB.backgroundRounded == false, "rounded corners must default safely")
assert(SimpleScrollingLootDB.backgroundStyle == nil, "obsolete style must be removed")
assert(SimpleScrollingLootDB.backgroundRed == nil, "obsolete red must be removed")
assert(SimpleScrollingLootDB.backgroundGreen == nil, "obsolete green must be removed")
assert(SimpleScrollingLootDB.backgroundBlue == nil, "obsolete blue must be removed")
assert(SimpleScrollingLootDB.backgroundPadding == nil, "obsolete padding must be removed")
assert(SimpleScrollingLootDB.backgroundBorderOpacity == nil, "obsolete border opacity must be removed")

print("Database migration tests passed")
