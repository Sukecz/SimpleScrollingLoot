local addonName, ns = ...

ns.Core = {}

local Core = ns.Core
local isInitialized = false

function Core.OnAddonLoaded()
    if isInitialized then return end
    isInitialized = true

    ns.Database.Initialize()
    ns.MoneyTracker.Initialize()
    ns.NotificationManager.Initialize()
    ns.Options.Initialize()
    ns.SlashCommands.Initialize()

    ns.Debug.Log("Simple Scrolling Loot DB initialized.")
end

function Core.OnPlayerLogin()
    ns.Debug.Log("Player logged in. Simple Scrolling Loot is active.")
end

-- Initialize event frame immediately
ns.Events.Initialize()
