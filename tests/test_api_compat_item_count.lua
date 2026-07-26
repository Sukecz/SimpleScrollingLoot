-- Regression tests for bags-and-bank item count compatibility.
-- Run with: lua tests/test_api_compat_item_count.lua

local modernCalls = {}
C_Item = {
    GetItemCount = function(itemIdentifier, includeBank)
        table.insert(modernCalls, {
            itemIdentifier = itemIdentifier,
            includeBank = includeBank,
        })
        return includeBank and 42 or 22
    end,
}

local ns = {}
assert(loadfile("ApiCompat.lua"))("SimpleScrollingLoot", ns)

local itemLink = "|cff1eff00|Hitem:12345:0|h[Test Item]|h|r"
assert(ns.ApiCompat.GetItemCount(itemLink, false) == 22, "bag item count must exclude bank")
assert(ns.ApiCompat.GetItemCount(itemLink, true) == 42, "total item count must include bank")
assert(#modernCalls == 2 and modernCalls[1].includeBank == false, "bag count must pass includeBank=false")
assert(modernCalls[2].includeBank == true, "total count must pass includeBank=true")
assert(ns.ApiCompat.GetCapabilities().itemCount == true, "item count capability must be reported")

-- Missing optional API must fail closed without affecting core capabilities.
C_Item = {}
local missingNs = {}
assert(loadfile("ApiCompat.lua"))("SimpleScrollingLoot", missingNs)
assert(missingNs.ApiCompat.GetItemCount(12345, true) == nil, "missing item count API must return nil")
assert(missingNs.ApiCompat.GetCapabilities().itemCount == false, "missing item count must be reported")

print("ApiCompat owned item count tests passed")
