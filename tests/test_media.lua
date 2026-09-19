local selected = "Missing"
local refreshes = 0
local eventFrame
function CreateFrame()
    eventFrame = {
        RegisterEvent = function() end,
        SetScript = function(self, _, callback) self.callback = callback end,
    }
    return eventFrame
end
GameFontHighlight = { GetFont = function() return "default.ttf", 14, "OUTLINE" end }
local ns = {
    L = { FONT_DEFAULT = "Default", FONT_UNAVAILABLE = "%s (unavailable)" },
    Database = { Get = function() return selected end },
    NotificationManager = { RefreshActiveRows = function() refreshes = refreshes + 1 end },
}
assert(loadfile("Media.lua"))("SimpleScrollingLoot", ns)
ns.Media.Initialize()
assert(ns.Media.GetFontPath(selected) == "default.ttf")
assert(#ns.Media.GetFontItems() == 2)
local fonts = { Custom = "custom.ttf" }
local callbacks = {}
local library = {
    Fetch = function(_, kind, name, noDefault)
        assert(kind == "font" and noDefault)
        return fonts[name]
    end,
    List = function() return { "Custom" } end,
    RegisterCallback = function(owner, event, method)
        callbacks[event] = function(kind) owner[method](owner, event, kind) end
    end,
}
LibStub = { GetLibrary = function() return library end }
eventFrame.callback()
assert(refreshes == 1, "late provider refreshes rows")
eventFrame.callback()
assert(refreshes == 1, "connection is only made once")
selected = "Custom"
assert(ns.Media.GetFontPath(selected) == "custom.ttf")
assert(ns.Media.GetFontPath("") == "default.ttf", "default ignores shared fonts")
assert(#ns.Media.GetFontItems() == 2)
callbacks.LibSharedMedia_Registered("sound")
assert(refreshes == 1)
fonts.Missing = "restored.ttf"
callbacks.LibSharedMedia_Registered("font")
assert(refreshes == 2)
assert(ns.Media.GetFontPath("Missing") == "restored.ttf")
print("Shared font tests passed")
