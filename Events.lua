local addonName, ns = ...

ns.Events = {}

local Events = ns.Events
local eventFrame = nil
local registeredEvents = {}
local notificationEvents = {
    "CHAT_MSG_LOOT",
    "CHAT_MSG_MONEY",
    "PLAYER_MONEY",
    "LOOT_OPENED",
    "LOOT_CLOSED",
    "GET_ITEM_INFO_RECEIVED",
    "BAG_UPDATE_DELAYED",
}

local function RegisterEvent(event)
    if registeredEvents[event] then return end
    eventFrame:RegisterEvent(event)
    registeredEvents[event] = true
end

local function UnregisterEvent(event)
    if not registeredEvents[event] then return end
    eventFrame:UnregisterEvent(event)
    registeredEvents[event] = nil
end

function Events.Initialize()
    if eventFrame then return end

    eventFrame = CreateFrame("Frame", "SimpleScrollingLootEventFrame")
    RegisterEvent("ADDON_LOADED")
    RegisterEvent("PLAYER_LOGIN")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        Events.OnEvent(event, ...)
    end)
end

function Events.OnEvent(event, ...)
    if ns.Debug and ns.Debug.LogEvent then
        ns.Debug.LogEvent(event, ...)
    end

    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            ns.Core.OnAddonLoaded()
            -- Unregister immediately; we have no further interest in other addons loading.
            UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        ns.Core.OnPlayerLogin()
    elseif event == "CHAT_MSG_LOOT" then
        if not ns.Core.IsOperational() then return end
        local text = ...
        local record = ns.LootParser.ParseLootMessage(text, event)
        if record then
            ns.ItemResolver.Resolve(record, function(resolvedRecord)
                ns.NotificationManager.AddNotification(resolvedRecord)
            end)
        end
    elseif event == "CHAT_MSG_MONEY" then
        local text = ...
        ns.MoneyTracker.OnChatMessageMoney(text, function(record)
            if record and ns.Database.Get("enabled") then
                ns.NotificationManager.AddNotification(record)
            end
        end)
    elseif event == "PLAYER_MONEY" then
        ns.MoneyTracker.OnPlayerMoney(function(record)
            if record and ns.Database.Get("enabled") then
                ns.NotificationManager.AddNotification(record)
            end
        end)
    elseif event == "LOOT_OPENED" then
        ns.MoneyTracker.OnLootOpened()
    elseif event == "LOOT_CLOSED" then
        ns.MoneyTracker.OnLootClosed()
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        local itemID, success = ...
        ns.ItemResolver.OnItemInfoReceived(itemID, success)
    elseif event == "BAG_UPDATE_DELAYED" then
        ns.NotificationManager.RefreshOwnedCounts()
    end
end

function Events.SetOperational(operational)
    if not eventFrame then return end
    for _, event in ipairs(notificationEvents) do
        if operational then
            RegisterEvent(event)
        else
            UnregisterEvent(event)
        end
    end
end

function Events.GetRegisteredEvents()
    local events = {}
    for event in pairs(registeredEvents) do
        table.insert(events, event)
    end
    table.sort(events)
    return events
end
