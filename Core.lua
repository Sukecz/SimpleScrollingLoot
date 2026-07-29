local addonName, ns = ...

ns.Core = {}

local Core = ns.Core
local isInitialized = false
local clientSupported = false

function Core.IsOperational()
    return isInitialized
        and clientSupported
        and ns.Database.Get("enabled")
end

function Core.ShowLoginHint(isSupported)
    if not isSupported then
        return false
    end

    ns.Debug.Info(ns.L.LOGIN_HINT)
    return true
end

function Core.OnAddonLoaded()
    if isInitialized then return end
    isInitialized = true

    ns.Database.Initialize()
    ns.MoneyTracker.Initialize()
    ns.NotificationManager.Initialize()
    ns.Options.Initialize()
    ns.SlashCommands.Initialize()

    clientSupported = ns.ApiCompat.IsSupportedClient()
        and ns.ApiCompat.HasCriticalCapabilities()

    ns.Database.RegisterCallback("enabled", function(enabled)
        if enabled and clientSupported then
            ns.MoneyTracker.Synchronize()
        end
        ns.Events.SetOperational(enabled and clientSupported)
    end)

    ns.Events.SetOperational(Core.IsOperational())

    if not clientSupported then
        ns.Debug.Error(ns.L.UNSUPPORTED_CLIENT)
        ns.CompatibilityProbe.RunReport()
    elseif ns.Database.Get("debug") then
        ns.CompatibilityProbe.RunReport()
    end

    ns.Debug.Log("Simple Scrolling Loot initialized.")
end

function Core.OnPlayerLogin()
    Core.ShowLoginHint(clientSupported)
    ns.Debug.Log(
        "Player logged in. Notification processing is %s.",
        Core.IsOperational() and "active" or "inactive"
    )
end

-- Initialize event frame immediately
ns.Events.Initialize()
