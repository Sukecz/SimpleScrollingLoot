local addonName, ns = ...

ns.MoneyTracker = {}

local MoneyTracker = ns.MoneyTracker
local lastMoney = nil
local lastMoneyGainTime = 0
local DUP_WINDOW = 0.5 -- 500ms window to suppress duplicate CHAT_MSG_MONEY / PLAYER_MONEY events

function MoneyTracker.Initialize()
    lastMoney = GetMoney()
end

function MoneyTracker.OnPlayerMoney(callback)
    if not lastMoney then
        lastMoney = GetMoney()
        return nil
    end

    local currentMoney = GetMoney()
    local delta = currentMoney - lastMoney
    lastMoney = currentMoney

    if delta <= 0 then
        return nil
    end

    local now = GetTime()
    if (now - lastMoneyGainTime) < DUP_WINDOW then
        -- Duplicate event caught within suppression window
        ns.Debug.Log("Duplicate money event suppressed (delta=%d)", delta)
        return nil
    end

    lastMoneyGainTime = now

    local record = {
        kind = "money",
        copper = delta,
        formattedText = ns.ApiCompat.FormatMoney(delta),
        coinIconsText = ns.ApiCompat.GetCoinIconsText(delta),
        texture = "Interface\\Icons\\INV_Misc_Coin_01",
        timestamp = now,
    }

    if callback then
        callback(record)
    end

    return record
end

function MoneyTracker.OnChatMessageMoney(msg, callback)
    -- If chat message for money arrives, we can also extract or rely on PLAYER_MONEY
    -- We process via OnPlayerMoney for absolute accurate deltas
    return MoneyTracker.OnPlayerMoney(callback)
end
