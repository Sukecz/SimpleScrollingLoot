local state = {
    welcomeShown = false,
}
local messages = {}

local ns = {
    Database = {
        Get = function(key)
            return state[key]
        end,
        Set = function(key, value)
            state[key] = value
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
        WELCOME_MESSAGE = "Simple Scrolling Loot is ready.",
    },
}

assert(loadfile("Core.lua"))("SimpleScrollingLoot", ns)

assert(not ns.Core.ShowWelcomeIfNeeded(false), "unsupported clients must not show the ready hint")
assert(not state.welcomeShown, "unsupported clients must leave the hint pending")
assert(#messages == 0, "unsupported clients must not print the hint")

assert(ns.Core.ShowWelcomeIfNeeded(true), "supported clients must show the pending hint")
assert(state.welcomeShown, "shown hint must be persisted")
assert(#messages == 1 and messages[1] == ns.L.WELCOME_MESSAGE, "hint must use the localized message")

assert(not ns.Core.ShowWelcomeIfNeeded(true), "the hint must not repeat")
assert(#messages == 1, "only one hint may be printed")

print("First-run hint tests passed")
