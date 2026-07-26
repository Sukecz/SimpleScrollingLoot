local addonName, ns = ...

ns.ApiCompat = {}

local ApiCompat = ns.ApiCompat

-- Cache capability checks once at load time to avoid repeated evaluation per call.
local hasModernItemAPI      = C_Item and type(C_Item.GetItemInfo) == "function"
local hasLegacyItemAPI      = type(GetItemInfo) == "function"
local hasModernQualityAPI   = C_Item and type(C_Item.GetItemQualityColor) == "function"
local hasLegacyQualityAPI   = type(GetItemQualityColor) == "function"
local hasModernItemLoadAPI  = C_Item and type(C_Item.RequestLoadItemDataByID) == "function"
local hasModernItemIconAPI  = C_Item and type(C_Item.GetItemIconByID) == "function"
local hasLegacyItemIconAPI  = type(GetItemIcon) == "function"

function ApiCompat.GetAddonMetadata(field)
    if type(C_AddOns) == "table" and type(C_AddOns.GetAddOnMetadata) == "function" then
        return C_AddOns.GetAddOnMetadata(addonName, field)
    end
    if type(GetAddOnMetadata) == "function" then
        return GetAddOnMetadata(addonName, field)
    end
    return nil
end

function ApiCompat.GetClientFamily()
    local declaredFlavor = ApiCompat.GetAddonMetadata("X-Flavor")
    if declaredFlavor == "Vanilla" then
        return "CLASSIC_ERA"
    end
    if declaredFlavor == "TBC" then
        return "TBC_CLASSIC"
    end

    if WOW_PROJECT_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        return "CLASSIC_ERA"
    end
    if WOW_PROJECT_BURNING_CRUSADE_CLASSIC
        and WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
        return "TBC_CLASSIC"
    end
    return "UNSUPPORTED"
end

function ApiCompat.IsSupportedClient()
    return ApiCompat.GetClientFamily() ~= "UNSUPPORTED"
end

function ApiCompat.GetCapabilities()
    return {
        addonMetadata = (type(C_AddOns) == "table" and type(C_AddOns.GetAddOnMetadata) == "function")
            or type(GetAddOnMetadata) == "function",
        itemInfo = hasModernItemAPI or hasLegacyItemAPI,
        itemLoadRequest = hasModernItemLoadAPI,
        itemInfoEvent = true,
        itemIcon = hasModernItemIconAPI or hasLegacyItemIconAPI,
        itemQualityColor = hasModernQualityAPI or hasLegacyQualityAPI,
        money = type(GetMoney) == "function",
        frame = type(CreateFrame) == "function",
        timer = type(C_Timer) == "table" and type(C_Timer.After) == "function",
        time = type(GetTime) == "function",
        settings = (type(Settings) == "table"
            and type(Settings.RegisterCanvasLayoutCategory) == "function"
            and type(Settings.RegisterAddOnCategory) == "function")
            or type(InterfaceOptions_AddCategory) == "function",
        tooltip = type(GameTooltip) == "table",
        modifiedItemClick = type(HandleModifiedItemClick) == "function",
        lootSelfSingle = type(_G.LOOT_ITEM_SELF) == "string",
        lootSelfMultiple = type(_G.LOOT_ITEM_SELF_MULTIPLE) == "string",
    }
end

function ApiCompat.HasCriticalCapabilities()
    local capabilities = ApiCompat.GetCapabilities()
    return capabilities.itemInfo
        and capabilities.itemIcon
        and capabilities.itemQualityColor
        and capabilities.money
        and capabilities.frame
        and capabilities.timer
        and capabilities.time
        and capabilities.settings
        and capabilities.lootSelfSingle
        and capabilities.lootSelfMultiple
end

-- Capture environment information
function ApiCompat.GetEnvironmentInfo()
    local version, build, date, interface = GetBuildInfo()
    local projectID = WOW_PROJECT_ID or 0
    local locale = GetLocale()
    return {
        version = version or "Unknown",
        build = build or "Unknown",
        date = date or "Unknown",
        interface = interface or 0,
        projectID = projectID,
        clientFamily = ApiCompat.GetClientFamily(),
        supportedClient = ApiCompat.IsSupportedClient(),
        locale = locale or "enUS",
    }
end

-- Item Info wrapper
function ApiCompat.GetItemInfo(itemIdentifier)
    if not itemIdentifier then return nil end

    if hasModernItemAPI then
        local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
              itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID,
              bindType, expacID, setID, isCraftingReagent = C_Item.GetItemInfo(itemIdentifier)
        if itemName then
            return itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
                   itemStackCount, itemEquipLoc, itemTexture, sellPrice
        end
    end

    if hasLegacyItemAPI then
        return GetItemInfo(itemIdentifier)
    end

    return nil
end

-- Item Info Request Load wrapper (for uncached item data)
function ApiCompat.RequestItemData(itemIdentifier)
    if hasModernItemLoadAPI then
        local itemID = tonumber(itemIdentifier) or tonumber(string.match(tostring(itemIdentifier), "item:(%d+)"))
        if itemID then
            C_Item.RequestLoadItemDataByID(itemID)
            return true
        end
    end
    return false
end

-- Returns the client-provided icon for an item ID or link. Test notifications
-- use this wrapper too, so their visuals match real resolved item records.
function ApiCompat.GetItemIcon(itemIdentifier)
    if not itemIdentifier then return nil end

    local itemID = tonumber(itemIdentifier) or tonumber(string.match(tostring(itemIdentifier), "item:(%d+)"))
    if hasModernItemIconAPI and itemID then
        local icon = C_Item.GetItemIconByID(itemID)
        if icon then return icon end
    end

    if hasLegacyItemIconAPI then
        return GetItemIcon(itemIdentifier)
    end

    return nil
end

-- Item Quality Colors wrapper
function ApiCompat.GetItemQualityColor(quality)
    quality = tonumber(quality) or 1
    if hasModernQualityAPI then
        local r, g, b, hex = C_Item.GetItemQualityColor(quality)
        if r and g and b then
            return r, g, b, hex
        end
    end

    if hasLegacyQualityAPI then
        local r, g, b, hex = GetItemQualityColor(quality)
        if r and g and b then
            return r, g, b, hex
        end
    end

    -- Fallback quality color table (Poor, Common, Uncommon, Rare, Epic, Legendary)
    local fallbackColors = {
        [0] = { r = 0.62, g = 0.62, b = 0.62, hex = "ff9d9d9d" }, -- Grey
        [1] = { r = 1.00, g = 1.00, b = 1.00, hex = "ffffffff" }, -- White
        [2] = { r = 0.12, g = 1.00, b = 0.00, hex = "ff1eff00" }, -- Green
        [3] = { r = 0.00, g = 0.44, b = 0.87, hex = "ff0070dd" }, -- Blue
        [4] = { r = 0.64, g = 0.21, b = 0.93, hex = "ffa335ee" }, -- Purple
        [5] = { r = 1.00, g = 0.50, b = 0.00, hex = "ffff8000" }, -- Orange
    }
    local color = fallbackColors[quality] or fallbackColors[1]
    return color.r, color.g, color.b, color.hex
end

-- Coin texture / money formatting
function ApiCompat.FormatMoney(copper)
    copper = tonumber(copper) or 0
    if copper <= 0 then return "0c" end

    local gold   = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop    = copper % 100

    -- Only include denominations that are non-zero for compact output.
    local parts = {}
    if gold   > 0 then table.insert(parts, gold   .. "|cffffd700g|r") end
    if silver > 0 then table.insert(parts, silver .. "|cffc7c7c1s|r") end
    if cop    > 0 or #parts == 0 then table.insert(parts, cop .. "|cffb87333c|r") end

    return table.concat(parts, " ")
end

-- Formats coin icons for money notification header
function ApiCompat.GetCoinIconsText(copper)
    copper = tonumber(copper) or 0
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100

    local parts = {}
    if gold > 0 then
        table.insert(parts, string.format("%d |TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t", gold))
    end
    if silver > 0 then
        table.insert(parts, string.format("%d |TInterface\\MoneyFrame\\UI-SilverIcon:12:12:0:0|t", silver))
    end
    if cop > 0 or #parts == 0 then
        table.insert(parts, string.format("%d |TInterface\\MoneyFrame\\UI-CopperIcon:12:12:0:0|t", cop))
    end

    return table.concat(parts, " ")
end
