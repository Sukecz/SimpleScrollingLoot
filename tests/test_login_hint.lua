local messages = {}

local ns = {
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

print("Login hint tests passed")
