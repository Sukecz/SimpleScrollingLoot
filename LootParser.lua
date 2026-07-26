local addonName, ns = ...

ns.LootParser = {}

local LootParser = ns.LootParser

local compiledPatterns = nil

local luaPatternMagic = {
    ["("] = true,
    [")"] = true,
    ["."] = true,
    ["%"] = true,
    ["+"] = true,
    ["-"] = true,
    ["*"] = true,
    ["?"] = true,
    ["["] = true,
    ["]"] = true,
    ["^"] = true,
    ["$"] = true,
}

-- Convert Blizzard format strings to Lua patterns while preserving positional
-- parameters. Some locales reorder arguments with forms such as %2$d and %1$s.
local function FormatStringToPattern(fmt)
    if not fmt or type(fmt) ~= "string" then return nil end

    local patternParts = {}
    local captures = {}
    local nextArgument = 1
    local index = 1

    while index <= #fmt do
        local char = string.sub(fmt, index, index)
        if char == "%" then
            local positionalIndex, positionalType, positionalEnd =
                string.match(fmt, "^%%(%d+)%$([sd])()", index)
            if positionalIndex then
                table.insert(patternParts, positionalType == "d" and "(%d+)" or "(.-)")
                table.insert(captures, {
                    argument = tonumber(positionalIndex),
                    valueType = positionalType,
                })
                index = positionalEnd
            else
                local valueType = string.match(fmt, "^%%([sd])", index)
                if valueType then
                    table.insert(patternParts, valueType == "d" and "(%d+)" or "(.-)")
                    table.insert(captures, {
                        argument = nextArgument,
                        valueType = valueType,
                    })
                    nextArgument = nextArgument + 1
                    index = index + 2
                elseif string.sub(fmt, index + 1, index + 1) == "%" then
                    table.insert(patternParts, "%%")
                    index = index + 2
                else
                    table.insert(patternParts, "%%")
                    index = index + 1
                end
            end
        else
            table.insert(patternParts, luaPatternMagic[char] and ("%" .. char) or char)
            index = index + 1
        end
    end

    return "^" .. table.concat(patternParts) .. "$", captures
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
            local pattern, captures = FormatStringToPattern(fmt)
            if pattern then
                table.insert(compiledPatterns, {
                    pattern = pattern,
                    captures = captures,
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
        local matchedValues = { string.match(msg, p.pattern) }
        if #matchedValues > 0 then
            local arguments = {}
            for captureIndex, capture in ipairs(p.captures) do
                arguments[capture.argument] = matchedValues[captureIndex]
            end

            local itemLink = arguments[1]
            local quantity = p.hasQuantity and (tonumber(arguments[2]) or 1) or 1

            if itemLink and string.find(itemLink, "|Hitem:", 1, true) then
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

    -- Do not fall back to extracting any item link from the chat text. Party,
    -- raid, and nearby-player loot messages contain identical links. Only the
    -- verified Blizzard *_SELF formats above are allowed to create a row.
    -- Failing closed is preferable to displaying loot that does not belong to
    -- the player when Blizzard changes a message format.
    ns.Debug.LogUnrecognizedLoot(event, msg)
    return nil
end
