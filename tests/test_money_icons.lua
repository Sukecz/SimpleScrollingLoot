-- Regression tests for denomination-aware money row icons.
-- Run with: lua tests/test_money_icons.lua

local ns = {}
assert(loadfile("ApiCompat.lua"))("SimpleScrollingLoot", ns)

local MoneyIcon = ns.ApiCompat.GetMoneyIconTexture
assert(MoneyIcon(1) == "Interface\\MoneyFrame\\UI-CopperIcon", "copper-only gains need copper icon")
assert(MoneyIcon(99) == "Interface\\MoneyFrame\\UI-CopperIcon", "99 copper must remain copper")
assert(MoneyIcon(100) == "Interface\\MoneyFrame\\UI-SilverIcon", "one silver needs silver icon")
assert(MoneyIcon(9999) == "Interface\\MoneyFrame\\UI-SilverIcon", "sub-gold gains need silver icon")
assert(MoneyIcon(10000) == "Interface\\MoneyFrame\\UI-GoldIcon", "one gold needs gold icon")

print("Money icon tests passed")
