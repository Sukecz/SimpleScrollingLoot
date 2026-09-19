local addonName, ns = ...

ns.Media = {}
local Media = ns.Media
local library
local initialized = false

function Media.GetFontPath(name)
    local defaultPath, _, flags = GameFontHighlight:GetFont()
    local path = name ~= "" and library and library:Fetch("font", name, true)
    return path or defaultPath, flags, defaultPath
end

function Media.GetFontItems()
    local items = { { value = "", label = ns.L.FONT_DEFAULT } }
    local selected = ns.Database.Get("fontName")
    local found = selected == ""
    if library then
        for _, name in ipairs(library:List("font") or {}) do
            items[#items + 1] = { value = name, label = name }
            if name == selected then found = true end
        end
    end
    if not found then
        items[#items + 1] = {
            value = selected,
            label = string.format(ns.L.FONT_UNAVAILABLE, selected),
        }
    end
    return items
end

function Media:OnRegistered(event, mediaType)
    if mediaType ~= "font" then return end
    ns.NotificationManager.RefreshActiveRows()
end

function Media.TryConnect()
    if library or not LibStub then return end
    library = LibStub:GetLibrary("LibSharedMedia-3.0", true)
    if library then
        library.RegisterCallback(Media, "LibSharedMedia_Registered", "OnRegistered")
        library.RegisterCallback(Media, "LibSharedMedia_SetGlobal", "OnRegistered")
        ns.NotificationManager.RefreshActiveRows()
    end
end

function Media.Initialize()
    if initialized then return end
    initialized = true
    Media.TryConnect()
    -- A provider may load after SSL, including on demand during the session.
    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:SetScript("OnEvent", Media.TryConnect)
end
