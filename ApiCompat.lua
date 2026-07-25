local addonName, ns = ...

ns.ApiCompat = {}

local ApiCompat = ns.ApiCompat

-- Capture environment information
function ApiCompat.GetEnvironmentInfo()
    local version, build, date, interface = GetBuildInfo()
    local projectID = WOW_PROJECT_ID or (LE_EXPANSION_LEVEL_CURRENT or 0)
    local locale = GetLocale()
    return {
        version = version or "Unknown",
        build = build or "Unknown",
        date = date or "Unknown",
        interface = interface or 0,
        projectID = projectID,
        locale = locale or "enUS",
    }
end

-- Item Info wrapper
function ApiCompat.GetItemInfo(itemIdentifier)
    if not itemIdentifier then return nil end

    if C_Item and type(C_Item.GetItemInfo) == "function" then
        local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
              itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID,
              bindType, expacID, setID, isCraftingReagent = C_Item.GetItemInfo(itemIdentifier)
        if itemName then
            return itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
                   itemStackCount, itemEquipLoc, itemTexture, sellPrice
        end
    end

    if type(GetItemInfo) == "function" then
        return GetItemInfo(itemIdentifier)
    end

    return nil
end

-- Item Info Request Load wrapper (for uncached item data)
function ApiCompat.RequestItemData(itemIdentifier)
    if C_Item and type(C_Item.RequestLoadItemDataByID) == "function" then
        local itemID = tonumber(itemIdentifier) or tonumber(string.match(tostring(itemIdentifier), "item:(%d+)"))
        if itemID then
            C_Item.RequestLoadItemDataByID(itemID)
            return true
        end
    end
    return false
end

-- Item Quality Colors wrapper
function ApiCompat.GetItemQualityColor(quality)
    quality = tonumber(quality) or 1
    if C_Item and type(C_Item.GetItemQualityColor) == "function" then
        local r, g, b, hex = C_Item.GetItemQualityColor(quality)
        if r and g and b then
            return r, g, b, hex
        end
    end

    if type(GetItemQualityColor) == "function" then
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

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100

    local result = ""
    if gold > 0 then
        result = result .. gold .. "|cffffd700g|r "
    end
    if silver > 0 or gold > 0 then
        result = result .. silver .. "|cffc7c7c1s|r "
    end
    result = result .. cop .. "|cffb87333c|r"

    return result
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

-- Modifier key state check
function ApiCompat.IsBypassModifierPressed(modifierName)
    if modifierName == "CTRL" then
        return IsControlKeyDown()
    elseif modifierName == "ALT" then
        return IsAltKeyDown()
    else
        return IsShiftKeyDown()
    end
end
