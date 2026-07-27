-- Regression tests for notification-event registration and bag-count refresh.
-- Run with: lua tests/test_events.lua

local registered = {}
local refreshCount = 0
local lootOpenedCount = 0
local lootClosedCount = 0

function CreateFrame()
    return {
        RegisterEvent = function(self, event)
            registered[event] = true
        end,
        UnregisterEvent = function(self, event)
            registered[event] = nil
        end,
        SetScript = function() end,
    }
end

local ns = {
    Debug = {
        LogEvent = function() end,
    },
    NotificationManager = {
        RefreshOwnedCounts = function()
            refreshCount = refreshCount + 1
        end,
    },
    MoneyTracker = {
        OnLootOpened = function()
            lootOpenedCount = lootOpenedCount + 1
        end,
        OnLootClosed = function()
            lootClosedCount = lootClosedCount + 1
        end,
    },
}

assert(loadfile("Events.lua"))("SimpleScrollingLoot", ns)
ns.Events.Initialize()
ns.Events.SetOperational(true)

assert(registered.BAG_UPDATE_DELAYED == true, "bag updates must be registered while operational")
assert(registered.LOOT_OPENED == true, "loot-open context must be registered while operational")
assert(registered.LOOT_CLOSED == true, "loot-close context must be registered while operational")
ns.Events.OnEvent("BAG_UPDATE_DELAYED")
assert(refreshCount == 1, "bag updates must refresh active owned counts")
ns.Events.OnEvent("LOOT_OPENED")
ns.Events.OnEvent("LOOT_CLOSED")
assert(lootOpenedCount == 1, "loot-open events must reach the money tracker")
assert(lootClosedCount == 1, "loot-close events must reach the money tracker")

ns.Events.SetOperational(false)
assert(registered.BAG_UPDATE_DELAYED == nil, "bag updates must unregister while disabled")
assert(registered.LOOT_OPENED == nil, "loot-open context must unregister while disabled")
assert(registered.LOOT_CLOSED == nil, "loot-close context must unregister while disabled")

print("Event bag-count refresh tests passed")
