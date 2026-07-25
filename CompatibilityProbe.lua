local addonName, ns = ...

ns.CompatibilityProbe = {}

local CompatibilityProbe = ns.CompatibilityProbe

function CompatibilityProbe.RunReport()
    local env = ns.ApiCompat.GetEnvironmentInfo()
    local reportLines = {}

    table.insert(reportLines, "=== Simple Scrolling Loot API Compatibility Report ===")
    table.insert(reportLines, string.format("Addon Version: %s", "0.1.0"))
    table.insert(reportLines, string.format("Client Version: %s (Build: %s, Date: %s)", env.version, env.build, env.date))
    table.insert(reportLines, string.format("TOC Interface: %s", tostring(env.interface)))
    table.insert(reportLines, string.format("WOW_PROJECT_ID: %s", tostring(env.projectID)))
    table.insert(reportLines, string.format("Client Locale: %s", env.locale))
    table.insert(reportLines, "---------------------------------------------------")

    -- Check APIs
    local apis = {
        { name = "GetItemInfo (Legacy)", available = type(GetItemInfo) == "function" },
        { name = "C_Item.GetItemInfo (Modern)", available = C_Item and type(C_Item.GetItemInfo) == "function" },
        { name = "C_Item.RequestLoadItemDataByID", available = C_Item and type(C_Item.RequestLoadItemDataByID) == "function" },
        { name = "GetItemQualityColor", available = type(GetItemQualityColor) == "function" or (C_Item and type(C_Item.GetItemQualityColor) == "function") },
        { name = "GetMoney", available = type(GetMoney) == "function" },
        { name = "CreateFrame", available = type(CreateFrame) == "function" },
        { name = "Settings API (Modern)", available = Settings and type(Settings.RegisterAddOnCategory) == "function" },
        { name = "InterfaceOptions_AddCategory (Legacy)", available = type(InterfaceOptions_AddCategory) == "function" },
        { name = "LootFrame global", available = LootFrame ~= nil },
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
