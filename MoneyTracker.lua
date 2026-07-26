local addonName, ns = ...

ns.MoneyTracker = {}

local MoneyTracker = ns.MoneyTracker
local lastMoney = nil
local pendingGain = 0
local pendingGainTime = 0
local pendingCallback = nil
local lootSignalUntil = 0
local CORRELATION_WINDOW = 1.0

local function CaptureDelta()
    local currentMoney = GetMoney()
    if lastMoney == nil then
        lastMoney = currentMoney
        return 0
    end

    local delta = currentMoney - lastMoney
    lastMoney = currentMoney
    return math.max(0, delta)
end

local function EmitPending(callback, sourceEvent)
    if pendingGain <= 0 then return nil end

    local amount = pendingGain
    pendingGain = 0
    pendingGainTime = 0
    callback = callback or pendingCallback
    pendingCallback = nil

    local record = {
        kind = "money",
        copper = amount,
        formattedText = ns.ApiCompat.FormatMoney(amount),
        coinIconsText = ns.ApiCompat.GetCoinIconsText(amount),
        texture = ns.ApiCompat.GetMoneyIconTexture(amount),
        sourceEvent = sourceEvent,
        timestamp = GetTime(),
    }

    if callback then
        callback(record)
    end
    return record
end

local function ExpirePending(expectedTime)
    if pendingGainTime ~= expectedTime then return end
    if (GetTime() - pendingGainTime) < CORRELATION_WINDOW then return end

    ns.Debug.Log("Ignored uncorrelated positive money gain of %d copper.", pendingGain)
    pendingGain = 0
    pendingGainTime = 0
    pendingCallback = nil
end

local function QueueDelta(delta, callback)
    if delta <= 0 then return end
    pendingGain = pendingGain + delta
    pendingGainTime = GetTime()
    pendingCallback = callback or pendingCallback

    if C_Timer and type(C_Timer.After) == "function" then
        local expectedTime = pendingGainTime
        C_Timer.After(CORRELATION_WINDOW, function()
            ExpirePending(expectedTime)
        end)
    end
end

function MoneyTracker.Initialize()
    lastMoney = GetMoney()
end

function MoneyTracker.OnPlayerMoney(callback)
    local now = GetTime()
    QueueDelta(CaptureDelta(), callback)
    if pendingGain > 0 and now <= lootSignalUntil then
        return EmitPending(callback, "PLAYER_MONEY")
    end
    return nil
end

function MoneyTracker.OnChatMessageMoney(msg, callback)
    local now = GetTime()
    lootSignalUntil = now + CORRELATION_WINDOW
    QueueDelta(CaptureDelta(), callback)

    if pendingGain > 0 then
        return EmitPending(callback, "CHAT_MSG_MONEY")
    end

    -- CHAT_MSG_MONEY can precede the wallet update. PLAYER_MONEY will consume
    -- the signal; the zero-delay retry covers clients that update without it.
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, function()
            QueueDelta(CaptureDelta(), callback)
            if pendingGain > 0 and GetTime() <= lootSignalUntil then
                EmitPending(callback, "CHAT_MSG_MONEY")
            end
        end)
    end
    return nil
end

function MoneyTracker.Synchronize()
    lastMoney = GetMoney()
    pendingGain = 0
    pendingGainTime = 0
    pendingCallback = nil
    lootSignalUntil = 0
end
