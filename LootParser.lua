local addonName, ns = ...

ns.LootParser = {}

local LootParser = ns.LootParser

local compiledPatterns = nil

-- Helper to convert WoW format strings (like "You receive loot: %s x%d.") to Lua regex patterns
local function FormatStringToRegex(fmt)
    if not fmt or type(fmt) ~= "string" then return nil end
    -- Escape special regex chars except %s and %d
    local pattern = fmt:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    -- Replace %s and %d pattern placeholders
    -- Note: in WoW loot strings, usually %s is itemLink and %d is quantity, or %s is player and second %s is itemLink.
    pattern = pattern:gsub("%%%%s", "(.-)"):gsub("%%%%d", "(%%d+)")
    return "^" .. pattern .. "$"
end

-- Initialize dynamic parser patterns from active client global strings
local function GetLootPatterns()
    if compiledPatterns then return compiledPatterns end
    compiledPatterns = {}

    local formatGlobals = {
        { key = "LOOT_ITEM_SELF_MULTIPLE", hasQuantity = true },
        { key = "LOOT_ITEM_SELF", hasQuantity = false },
        { key = "LOOT_ITEM_PUSHED_SELF_MULTIPLE", hasQuantity = true },
        { key = "LOOT_ITEM_PUSHED_SELF", hasQuantity = false },
        { key = "LOOT_ITEM_CREATED_SELF_MULTIPLE", hasQuantity = true },
        { key = "LOOT_ITEM_CREATED_SELF", hasQuantity = false },
        { key = "LOOT_ITEM_REFUND_SELF_MULTIPLE", hasQuantity = true },
        { key = "LOOT_ITEM_REFUND_SELF", hasQuantity = false },
    }

    for _, entry in ipairs(formatGlobals) do
        local fmt = _G[entry.key]
        if fmt then
            local regex = FormatStringToRegex(fmt)
            if regex then
                table.insert(compiledPatterns, {
                    regex = regex,
                    hasQuantity = entry.hasQuantity,
                    key = entry.key,
                })
            end
        end
    end

    return compiledPatterns
end

-- Extract itemID from itemLink
function LootParser.ExtractItemID(itemLink)
    if not itemLink then return nil end
    local itemID = string.match(itemLink, "item:(%d+)")
    return tonumber(itemID)
end

-- Parse raw chat message from CHAT_MSG_LOOT
function LootParser.ParseLootMessage(msg, event)
    if not msg or type(msg) ~= "string" then return nil end

    local patterns = GetLootPatterns()

    -- First try matching compiled Blizzard format string patterns
    for _, p in ipairs(patterns) do
        local match1, match2 = string.match(msg, p.regex)
        if match1 then
            local itemLink, quantity
            if p.hasQuantity then
                -- Could be match1 = link, match2 = count OR vice-versa depending on localized format string
                if string.find(match1, "|Hitem:") or string.find(match1, "|c") then
                    itemLink = match1
                    quantity = tonumber(match2) or 1
                else
                    itemLink = match2
                    quantity = tonumber(match1) or 1
                end
            else
                itemLink = match1
                quantity = 1
            end

            if itemLink and (string.find(itemLink, "|Hitem:") or string.find(itemLink, "|c")) then
                local itemID = LootParser.ExtractItemID(itemLink)
                return {
                    kind = "item",
                    itemLink = itemLink,
                    itemID = itemID,
                    quantity = math.max(1, quantity or 1),
                    sourceEvent = event or "CHAT_MSG_LOOT",
                    timestamp = GetTime(),
                }
            end
        end
    end

    -- Fallback: Regex search directly for item link and quantity suffix
    local itemLink = string.match(msg, "(|c%x+|Hitem:%d+:.-|h%[.-%] |h|r)") or string.match(msg, "(|c%x+|Hitem:%d+:.-|h.-|h|r)")
    if itemLink then
        local quantity = string.match(msg, "x(%d+)") or string.match(msg, "(%d+)x") or 1
        local itemID = LootParser.ExtractItemID(itemLink)
        return {
            kind = "item",
            itemLink = itemLink,
            itemID = itemID,
            quantity = math.max(1, tonumber(quantity) or 1),
            sourceEvent = event or "CHAT_MSG_LOOT",
            timestamp = GetTime(),
        }
    end

    -- If unparsed, report to debug log
    ns.Debug.LogUnrecognizedLoot(event, msg)
    return nil
end
