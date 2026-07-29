-- Pure regression checks for notification travel direction.
-- Run with: lua tests/test_notification_animation.lua

local ns = {}
assert(loadfile("NotificationManager.lua"))("SimpleScrollingLoot", ns)
local TravelY = ns.NotificationManager.CalculateTravelY

assert(not ns.NotificationManager.IsAnchorUnlocked(), "notification position must start locked")

assert(TravelY(0, 0.5, 100, "UP") == 50, "UP must move toward positive Y")
assert(TravelY(0, 0.5, 100, "DOWN") == -50, "DOWN must move toward negative Y")
assert(TravelY(-30, 1, 100, "DOWN") == -130, "DOWN must continue away from its negative base slot")

local LayoutOffset = ns.NotificationManager.CalculateLayoutOffset
assert(LayoutOffset(10, 50, 0) == 10, "layout transition must start at the current position")
assert(LayoutOffset(10, 50, 0.5) == 30, "layout transition must move smoothly between slots")
assert(LayoutOffset(10, 50, 1) == 50, "layout transition must finish at its target")
assert(LayoutOffset(10, 50, 2) == 50, "layout transition progress must be clamped")

local RowFrameLevel = ns.NotificationManager.CalculateRowFrameLevel
assert(RowFrameLevel(10, 4, 1) == 14, "newest row must render above all older rows")
assert(RowFrameLevel(10, 4, 2) == 13, "row frame levels must follow notification age")
assert(RowFrameLevel(10, 4, 4) == 11, "oldest row must remain above the anchor")

local BagsAndBank = ns.NotificationManager.CalculateLocationCounts
local bags, bank = BagsAndBank(22, 42, 5)
assert(bags == 22 and bank == 20, "bank count must be total minus bags")

bags, bank = BagsAndBank(0, 25, 5)
assert(bags == 5 and bank == 20, "fresh loot must floor bags before deriving bank")

bags, bank = BagsAndBank(7, 5, 1)
assert(bags == 7 and bank == 0, "inconsistent snapshots must never produce a negative bank count")

print("Notification animation tests passed")
