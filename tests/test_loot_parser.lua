-- Minimal offline regression tests for the locale-aware self-loot parser.
-- Run with: lua tests/test_loot_parser.lua

local ns = {
    Debug = {
        LogUnrecognizedLoot = function() end,
    },
}

function GetTime()
    return 42
end

LOOT_ITEM_SELF = "You receive loot: %s."
LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %s x%d."
LOOT_ITEM_PUSHED_SELF = "You receive item: %s."
LOOT_ITEM_PUSHED_SELF_MULTIPLE = "You receive item: %s x%d."

local loadParser = assert(loadfile("LootParser.lua"))
loadParser("SimpleScrollingLoot", ns)

local itemLink = "|cff1eff00|Hitem:12345:0:0:0|h[Test Item]|h|r"

local single = ns.LootParser.ParseLootMessage("You receive loot: " .. itemLink .. ".", "CHAT_MSG_LOOT")
assert(single and single.itemID == 12345 and single.quantity == 1, "self single loot must be displayed")

local stack = ns.LootParser.ParseLootMessage("You receive loot: " .. itemLink .. " x3.", "CHAT_MSG_LOOT")
assert(stack and stack.itemID == 12345 and stack.quantity == 3, "self stack loot must be displayed")

local party = ns.LootParser.ParseLootMessage("PartyMember receives loot: " .. itemLink .. ".", "CHAT_MSG_LOOT")
assert(party == nil, "party member loot must never be displayed")

print("LootParser tests passed")
