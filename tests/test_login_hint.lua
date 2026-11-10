local messages = {}
local showLoginMessage = true

local ns = {
    Database = {
        Get = function(key)
            assert(key == "showLoginMessage")
            return showLoginMessage
        end,
    },
    Debug = {
        Info = function(message)
            messages[#messages + 1] = message
        end,
    },
    Events = {
        Initialize = function() end,
    },
    L = {
        LOGIN_HINT = "Simple Scrolling Loot is ready.",
    },
}

assert(loadfile("Core.lua"))("SimpleScrollingLoot", ns)

assert(not ns.Core.ShowLoginHint(false), "unsupported clients must not show the login hint")
assert(#messages == 0, "unsupported clients must not print the hint")

assert(ns.Core.ShowLoginHint(true), "supported clients must show the login hint")
assert(#messages == 1 and messages[1] == ns.L.LOGIN_HINT, "hint must use the localized message")

assert(ns.Core.ShowLoginHint(true), "supported clients must show the hint again on another login")
assert(#messages == 2, "the hint must print once per supported login")

showLoginMessage = false
assert(not ns.Core.ShowLoginHint(true), "disabled login messages must stay silent")
assert(#messages == 2, "disabling the hint must not print anything")
showLoginMessage = true
assert(ns.Core.ShowLoginHint(true), "the hint can be enabled again")
assert(#messages == 3, "re-enabling must restore the hint")

-- Exercise saved defaults, upgrades, and reload persistence through the real database.
assert(loadfile("Defaults.lua"))("SimpleScrollingLoot", ns)
assert(loadfile("Database.lua"))("SimpleScrollingLoot", ns)
SimpleScrollingLootDB = { version = 7 }
ns.Database.Initialize()
assert(ns.Database.Get("showLoginMessage") == true, "existing settings retain the startup hint")
ns.Database.Set("showLoginMessage", false)
ns.Database.Initialize()
assert(not ns.Core.ShowLoginHint(true), "the disabled preference survives database initialization")
ns.Database.Reset()
assert(ns.Database.Get("showLoginMessage") == true, "reset restores the default hint")

print("Login hint tests passed")
