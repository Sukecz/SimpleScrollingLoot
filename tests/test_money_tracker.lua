-- Regression tests for money event ordering, de-duplication, and correlation.
-- Run with: lua tests/test_money_tracker.lua

local now = 10
local money = 1000
local emitted = {}

function GetTime()
    return now
end

function GetMoney()
    return money
end

local ns = {
    ApiCompat = {
        FormatMoney = function(value) return tostring(value) end,
        GetCoinIconsText = function(value) return tostring(value) end,
        GetMoneyIconTexture = function(value) return "money:" .. tostring(value) end,
    },
    Debug = {
        Log = function() end,
    },
}

assert(loadfile("MoneyTracker.lua"))("SimpleScrollingLoot", ns)
ns.MoneyTracker.Initialize()

local function Capture(record)
    table.insert(emitted, record)
end

-- PLAYER_MONEY first, then CHAT_MSG_MONEY.
money = 1100
ns.MoneyTracker.OnPlayerMoney(Capture)
assert(#emitted == 0, "uncorrelated gain must wait for a loot signal")
ns.MoneyTracker.OnChatMessageMoney("loot", Capture)
assert(#emitted == 1 and emitted[1].copper == 100, "loot signal must release the pending gain")
assert(emitted[1].texture == "money:100", "money records must use the denomination-aware icon")

-- CHAT_MSG_MONEY first, then PLAYER_MONEY.
now = 11
ns.MoneyTracker.OnChatMessageMoney("loot", Capture)
money = 1150
ns.MoneyTracker.OnPlayerMoney(Capture)
assert(#emitted == 2 and emitted[2].copper == 50, "reverse event order must emit exactly once")

-- Two real gains inside the old 500 ms suppression window must both survive.
now = 12
money = 1175
ns.MoneyTracker.OnPlayerMoney(Capture)
ns.MoneyTracker.OnChatMessageMoney("loot", Capture)
now = 12.2
money = 1200
ns.MoneyTracker.OnPlayerMoney(Capture)
ns.MoneyTracker.OnChatMessageMoney("loot", Capture)
assert(#emitted == 4, "quick independent loot gains must not be suppressed")

-- A non-loot positive change is never emitted.
now = 20
money = 2200
ns.MoneyTracker.OnPlayerMoney(Capture)
assert(#emitted == 4, "uncorrelated positive money must not display as loot")

print("MoneyTracker tests passed")
