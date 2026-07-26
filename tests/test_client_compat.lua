-- Regression tests for supported Classic client-family detection.
-- Run with: lua tests/test_client_compat.lua

WOW_PROJECT_CLASSIC = 2
WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5
WOW_PROJECT_MAINLINE = 1
WOW_PROJECT_ID = WOW_PROJECT_CLASSIC

C_Item = {
    GetItemInfo = function() end,
    GetItemIconByID = function() end,
    GetItemQualityColor = function() end,
    RequestLoadItemDataByID = function() end,
}
C_Timer = {
    After = function() end,
}
local declaredFlavor = nil
C_AddOns = {
    GetAddOnMetadata = function(addonName, field)
        if field == "X-Flavor" then return declaredFlavor end
        if field == "Version" then return "test" end
    end,
}
Settings = {
    RegisterCanvasLayoutCategory = function() end,
    RegisterAddOnCategory = function() end,
}
GameTooltip = {}
HandleModifiedItemClick = function() end
GetMoney = function() return 0 end
CreateFrame = function() end
GetTime = function() return 0 end
GetBuildInfo = function() return "1.15.9", "60000", "Jul 26 2026", 11509 end
GetLocale = function() return "enUS" end
LOOT_ITEM_SELF = "You receive loot: %s."
LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %s x%d."

local ns = {}
assert(loadfile("ApiCompat.lua"))("SimpleScrollingLoot", ns)

assert(ns.ApiCompat.GetClientFamily() == "CLASSIC_ERA", "Era and Hardcore must use the Classic family")
assert(ns.ApiCompat.IsSupportedClient(), "Classic Era must be supported")
assert(ns.ApiCompat.HasCriticalCapabilities(), "complete Classic API surface must pass")

WOW_PROJECT_ID = WOW_PROJECT_BURNING_CRUSADE_CLASSIC
assert(ns.ApiCompat.GetClientFamily() == "TBC_CLASSIC", "TBC Classic must use its own family")
assert(ns.ApiCompat.IsSupportedClient(), "TBC Classic must be supported")

WOW_PROJECT_ID = WOW_PROJECT_MAINLINE
assert(ns.ApiCompat.GetClientFamily() == "UNSUPPORTED", "Retail must not be enabled accidentally")
assert(not ns.ApiCompat.IsSupportedClient(), "Retail must remain unsupported")

WOW_PROJECT_BURNING_CRUSADE_CLASSIC = nil
declaredFlavor = "TBC"
assert(ns.ApiCompat.GetClientFamily() == "TBC_CLASSIC", "TBC TOC metadata must work without a project constant")

print("Client compatibility tests passed")
