-- Regression tests for the item-icon compatibility wrapper.
-- Run with: lua tests/test_api_compat_icons.lua

C_Item = {
    GetItemIconByID = function(itemID)
        if itemID == 14047 then
            return "modern:runecloth"
        end
        return nil
    end,
}

GetItemIcon = function(itemIdentifier)
    return "legacy:" .. tostring(itemIdentifier)
end

local ns = {}
assert(loadfile("ApiCompat.lua"))("SimpleScrollingLoot", ns)

assert(ns.ApiCompat.GetItemIcon(14047) == "modern:runecloth", "modern item icon must be preferred")
assert(ns.ApiCompat.GetItemIcon(4234) == "legacy:4234", "legacy item icon must be used as fallback")
assert(ns.ApiCompat.GetItemIcon("|Hitem:14047:0|h[Test]|h") == "modern:runecloth", "item links must resolve to item IDs")

print("ApiCompat icon tests passed")
