local addonName, ns = ...

ns.Events = {}

local Events = ns.Events
local eventFrame = nil

function Events.Initialize()
    if eventFrame then return end

    eventFrame = CreateFrame("Frame", "SimpleScrollingLootEventFrame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("CHAT_MSG_LOOT")
    eventFrame:RegisterEvent("CHAT_MSG_MONEY")
    eventFrame:RegisterEvent("PLAYER_MONEY")
    eventFrame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
    eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        Events.OnEvent(event, ...)
    end)
end

function Events.OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            ns.Core.OnAddonLoaded()
            -- Unregister immediately; we have no further interest in other addons loading.
            eventFrame:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        ns.Core.OnPlayerLogin()
    elseif event == "CHAT_MSG_LOOT" then
        if not ns.Database.Get("enabled") then return end
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
    elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
        if not ns.Database.Get("enabled") then return end
        if not ns.Database.Get("showHonor") then return end
        local text = ...
        local record = ns.LootParser.ParseHonorMessage(text, event)
        if record then
            ns.NotificationManager.AddNotification(record)
        end
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        local itemID, success = ...
        ns.ItemResolver.OnItemInfoReceived(itemID, success)
    end
end
