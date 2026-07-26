-- Pure regression checks for notification travel direction.
-- Run with: lua tests/test_notification_animation.lua

local ns = {}
assert(loadfile("NotificationManager.lua"))("SimpleScrollingLoot", ns)
local TravelY = ns.NotificationManager.CalculateTravelY

assert(TravelY(0, 0.5, 100, "UP") == 50, "UP must move toward positive Y")
assert(TravelY(0, 0.5, 100, "DOWN") == -50, "DOWN must move toward negative Y")
assert(TravelY(-30, 1, 100, "DOWN") == -130, "DOWN must continue away from its negative base slot")

print("Notification animation tests passed")
