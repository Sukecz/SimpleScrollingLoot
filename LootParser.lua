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

    -- Do not fall back to extracting any item link from the chat text. Party,
    -- raid, and nearby-player loot messages contain identical links. Only the
    -- verified Blizzard *_SELF formats above are allowed to create a row.
    -- Failing closed is preferable to displaying loot that does not belong to
    -- the player when Blizzard changes a message format.
    ns.Debug.LogUnrecognizedLoot(event, msg)
    return nil
end

-- Parse raw chat message from CHAT_MSG_COMBAT_HONOR_GAIN
function LootParser.ParseHonorMessage(msg, event)
    if not msg or type(msg) ~= "string" then return nil end

    local amount = string.match(msg, "(%d+)%s+[Hh]onor") or string.match(msg, "[Hh]onor.-(%d+)") or string.match(msg, "(%d+)")
    amount = tonumber(amount)
    if amount and amount > 0 then
        local faction = UnitFactionGroup and UnitFactionGroup("player") or "Horde"
        local honorIcon = (faction == "Alliance") and "Interface\\Icons\\PVPCurrency_Honor_Alliance" or "Interface\\Icons\\PVPCurrency_Honor_Horde"
        return {
            kind = "honor",
            amount = amount,
            formattedText = string.format("+%d Honor", amount),
            texture = honorIcon,
            sourceEvent = event or "CHAT_MSG_COMBAT_HONOR_GAIN",
            timestamp = GetTime(),
        }
    end

    ns.Debug.LogUnrecognizedLoot(event, msg)
    return nil
end
