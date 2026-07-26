-- Regression tests for notification-event registration and bag-count refresh.
-- Run with: lua tests/test_events.lua

local registered = {}
local refreshCount = 0

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
}

assert(loadfile("Events.lua"))("SimpleScrollingLoot", ns)
ns.Events.Initialize()
ns.Events.SetOperational(true)

assert(registered.BAG_UPDATE_DELAYED == true, "bag updates must be registered while operational")
ns.Events.OnEvent("BAG_UPDATE_DELAYED")
assert(refreshCount == 1, "bag updates must refresh active owned counts")

ns.Events.SetOperational(false)
assert(registered.BAG_UPDATE_DELAYED == nil, "bag updates must unregister while disabled")

print("Event bag-count refresh tests passed")
