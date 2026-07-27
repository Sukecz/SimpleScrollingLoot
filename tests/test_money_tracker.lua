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
assert(emitted[1].texture == nil, "money records must rely on inline denomination icons")

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

-- PLAYER_MONEY during an open loot window must display immediately instead of
-- waiting for CHAT_MSG_MONEY.
now = 13
ns.MoneyTracker.OnLootOpened()
money = 1230
ns.MoneyTracker.OnPlayerMoney(Capture)
assert(#emitted == 5 and emitted[5].copper == 30, "open loot must release the wallet delta immediately")
ns.MoneyTracker.OnLootClosed()

-- Auto-loot can close the loot window before PLAYER_MONEY arrives. A short
-- close grace must still allow immediate display.
now = 14
ns.MoneyTracker.OnLootOpened()
ns.MoneyTracker.OnLootClosed()
now = 14.2
money = 1250
ns.MoneyTracker.OnPlayerMoney(Capture)
assert(#emitted == 6 and emitted[6].copper == 20, "recently closed auto-loot must display immediately")

-- A non-loot positive change is never emitted.
now = 20
money = 2250
ns.MoneyTracker.OnPlayerMoney(Capture)
assert(#emitted == 6, "uncorrelated positive money must not display as loot")

print("MoneyTracker tests passed")
