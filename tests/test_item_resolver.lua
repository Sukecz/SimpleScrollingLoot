-- Regression tests for uncached item request de-duplication and timeout.
-- Run with: lua tests/test_item_resolver.lua

local now = 10
local requestCount = 0
local resolved = {}
local itemCache = {}

function GetTime()
    return now
end

local ns = {
    ApiCompat = {
        GetItemInfo = function(itemLink)
            local data = itemCache[itemLink]
            if not data then return nil end
            return data.name, itemLink, data.quality, nil, nil, nil, nil, nil, nil, data.texture, data.sellPrice
        end,
        RequestItemData = function()
            requestCount = requestCount + 1
            return true
        end,
    },
    Debug = {
        Log = function() end,
    },
}

assert(loadfile("ItemResolver.lua"))("SimpleScrollingLoot", ns)

local link = "|cff1eff00|Hitem:12345:0|h[Test]|h|r"
for quantity = 1, 2 do
    ns.ItemResolver.Resolve({
        itemLink = link,
        itemID = 12345,
        quantity = quantity,
    }, function(record)
        table.insert(resolved, record)
    end)
end

assert(requestCount == 1, "the same uncached item must only be requested once")
assert(ns.ItemResolver.GetPendingCount() == 2, "each loot record must remain queued")

now = 16
ns.ItemResolver.ProcessPending(now)
assert(#resolved == 2, "all pending records must fall back after timeout")
assert(ns.ItemResolver.GetPendingCount() == 0, "timed-out records must leave the queue")

local cachedLink = "|cff0070dd|Hitem:54321:0|h[Cached]|h|r"
itemCache[cachedLink] = {
    name = "Cached",
    quality = 3,
    texture = "cached-icon",
    sellPrice = 25,
}
ns.ItemResolver.Resolve({
    itemLink = cachedLink,
    itemID = 54321,
    quantity = 4,
}, function(record)
    table.insert(resolved, record)
end)

assert(resolved[#resolved].sellPrice == 100, "vendor value must include quantity")
assert(resolved[#resolved].resolved == true, "cached item must resolve immediately")

print("ItemResolver tests passed")
