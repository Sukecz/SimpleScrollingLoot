local addonName, ns = ...

ns.CompatibilityProbe = {}

local CompatibilityProbe = ns.CompatibilityProbe

function CompatibilityProbe.RunReport()
    local env = ns.ApiCompat.GetEnvironmentInfo()
    local reportLines = {}

    table.insert(reportLines, "=== Simple Scrolling Loot API Compatibility Report ===")
    -- Read version from TOC metadata at runtime so the probe is always accurate.
    local addonVersion = "Unknown"
    if type(C_AddOns) == "table" and type(C_AddOns.GetAddOnMetadata) == "function" then
        addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or "Unknown"
    elseif type(GetAddOnMetadata) == "function" then
        addonVersion = GetAddOnMetadata(addonName, "Version") or "Unknown"
    end
    table.insert(reportLines, string.format("Addon Version: %s", addonVersion))
    table.insert(reportLines, string.format("Client Version: %s (Build: %s, Date: %s)", env.version, env.build, env.date))
    table.insert(reportLines, string.format("TOC Interface: %s", tostring(env.interface)))
    table.insert(reportLines, string.format("WOW_PROJECT_ID: %s", tostring(env.projectID)))
    table.insert(reportLines, string.format("Client Locale: %s", env.locale))
    table.insert(reportLines, "---------------------------------------------------")

    -- Check APIs
    local apis = {
        { name = "GetItemInfo (Legacy)", available = type(GetItemInfo) == "function" },
        { name = "C_Item.GetItemInfo (Modern)", available = C_Item and type(C_Item.GetItemInfo) == "function" },
        { name = "Item icon API", available = (C_Item and type(C_Item.GetItemIconByID) == "function") or type(GetItemIcon) == "function" },
        { name = "C_Item.RequestLoadItemDataByID", available = C_Item and type(C_Item.RequestLoadItemDataByID) == "function" },
        { name = "GetItemQualityColor", available = type(GetItemQualityColor) == "function" or (C_Item and type(C_Item.GetItemQualityColor) == "function") },
        { name = "GetMoney", available = type(GetMoney) == "function" },
        { name = "CreateFrame", available = type(CreateFrame) == "function" },
        { name = "Settings API (Modern)", available = Settings and type(Settings.RegisterAddOnCategory) == "function" },
        { name = "InterfaceOptions_AddCategory (Legacy)", available = type(InterfaceOptions_AddCategory) == "function" },
        { name = "LOOT_ITEM_SELF string", available = _G.LOOT_ITEM_SELF ~= nil },
        { name = "LOOT_ITEM_SELF_MULTIPLE string", available = _G.LOOT_ITEM_SELF_MULTIPLE ~= nil },
    }

    for _, check in ipairs(apis) do
        table.insert(reportLines, string.format("  [%s] %s", check.available and "OK" or "MISSING", check.name))
    end

    table.insert(reportLines, "===================================================")

    local fullReport = table.concat(reportLines, "\n")
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(fullReport)
    else
        print(fullReport)
    end

    return env, apis
end
