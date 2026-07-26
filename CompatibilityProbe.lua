local addonName, ns = ...

ns.CompatibilityProbe = {}

local CompatibilityProbe = ns.CompatibilityProbe

function CompatibilityProbe.RunReport()
    local env = ns.ApiCompat.GetEnvironmentInfo()
    local reportLines = {}
    local capabilities = ns.ApiCompat.GetCapabilities()

    table.insert(reportLines, "=== Simple Scrolling Loot API Compatibility Report ===")
    -- Read version from TOC metadata at runtime so the probe is always accurate.
    local addonVersion = ns.ApiCompat.GetAddonMetadata("Version") or "Unknown"
    table.insert(reportLines, string.format("Addon Version: %s", addonVersion))
    table.insert(reportLines, string.format("Client Version: %s (Build: %s, Date: %s)", env.version, env.build, env.date))
    table.insert(reportLines, string.format("TOC Interface: %s", tostring(env.interface)))
    table.insert(reportLines, string.format("WOW_PROJECT_ID: %s", tostring(env.projectID)))
    table.insert(reportLines, string.format("Client Family: %s", env.clientFamily))
    table.insert(reportLines, string.format("Supported Client: %s", tostring(env.supportedClient)))
    table.insert(reportLines, string.format("Client Locale: %s", env.locale))
    local enabledModules = {}
    local moduleNames = {
        "ApiCompat",
        "LootParser",
        "ItemResolver",
        "MoneyTracker",
        "NotificationManager",
        "Options",
        "SlashCommands",
        "Events",
    }
    for _, moduleName in ipairs(moduleNames) do
        if type(ns[moduleName]) == "table" then
            table.insert(enabledModules, moduleName)
        end
    end
    table.insert(reportLines, "Loaded Modules: " .. table.concat(enabledModules, ","))
    if ns.Events and ns.Events.GetRegisteredEvents then
        table.insert(reportLines, "Registered Events: " .. table.concat(ns.Events.GetRegisteredEvents(), ","))
    end
    table.insert(reportLines, "---------------------------------------------------")

    local apis = {
        { name = "Addon metadata", available = capabilities.addonMetadata },
        { name = "Item info", available = capabilities.itemInfo },
        { name = "Item load request", available = capabilities.itemLoadRequest, optional = true },
        { name = "GET_ITEM_INFO_RECEIVED", available = capabilities.itemInfoEvent },
        { name = "Item icon", available = capabilities.itemIcon },
        { name = "Item count (bags and bank)", available = capabilities.itemCount, optional = true },
        { name = "Item quality color", available = capabilities.itemQualityColor },
        { name = "GetMoney", available = capabilities.money },
        { name = "CreateFrame", available = capabilities.frame },
        { name = "C_Timer.After", available = capabilities.timer },
        { name = "GetTime", available = capabilities.time },
        { name = "Settings panel API", available = capabilities.settings },
        { name = "GameTooltip", available = capabilities.tooltip, optional = true },
        { name = "HandleModifiedItemClick", available = capabilities.modifiedItemClick, optional = true },
        { name = "LOOT_ITEM_SELF", available = capabilities.lootSelfSingle },
        { name = "LOOT_ITEM_SELF_MULTIPLE", available = capabilities.lootSelfMultiple },
    }

    for _, check in ipairs(apis) do
        local status = check.available and "OK" or (check.optional and "OPTIONAL-MISSING" or "MISSING")
        table.insert(reportLines, string.format("  [%s] %s", status, check.name))
    end

    table.insert(reportLines, string.format(
        "Critical API Set: %s",
        ns.ApiCompat.HasCriticalCapabilities() and "OK" or "MISSING"
    ))
    table.insert(reportLines, "===================================================")

    local fullReport = table.concat(reportLines, "\n")
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(fullReport)
    else
        print(fullReport)
    end

    return env, apis
end
