local addonName, ns = ...

ns.Database = {}

local Database = ns.Database
local callbacks = {}
local validDirections = {
    UP = true,
    DOWN = true,
}

local function CopyTable(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            copy[k] = CopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function MergeDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = CopyTable(value)
            else
                target[key] = value
            end
        elseif type(value) == "table" and type(target[key]) == "table" then
            MergeDefaults(target[key], value)
        end
    end
end

local function NotifyCallbacks(key, value)
    if callbacks[key] then
        for _, cb in ipairs(callbacks[key]) do
            cb(value)
        end
    end
    if callbacks["*"] then
        for _, cb in ipairs(callbacks["*"]) do
            cb(key, value)
        end
    end
end

local function SanitizeTypes(target, defaults)
    for key, defaultValue in pairs(defaults) do
        local value = target[key]
        if type(value) ~= type(defaultValue) then
            target[key] = CopyTable(defaultValue)
        elseif type(defaultValue) == "table" then
            SanitizeTypes(value, defaultValue)
        end
    end
end

local function ValidateSettings(db)
    SanitizeTypes(db, ns.Defaults)

    for key, range in pairs(ns.ValidationRanges) do
        local val = db[key]
        if val < range.min then db[key] = range.min end
        if val > range.max then db[key] = range.max end
    end

    if not validDirections[db.direction] then
        db.direction = ns.Defaults.direction
    end

    if db.fadeDuration > db.duration then
        db.fadeDuration = db.duration
    end

    local anchor = db.anchor
    local validPoints = {
        TOPLEFT = true,
        TOP = true,
        TOPRIGHT = true,
        LEFT = true,
        CENTER = true,
        RIGHT = true,
        BOTTOMLEFT = true,
        BOTTOM = true,
        BOTTOMRIGHT = true,
    }
    if not validPoints[anchor.point] then
        anchor.point = ns.Defaults.anchor.point
    end
    if not validPoints[anchor.relativePoint] then
        anchor.relativePoint = ns.Defaults.anchor.relativePoint
    end
    anchor.x = math.max(-10000, math.min(10000, anchor.x))
    anchor.y = math.max(-10000, math.min(10000, anchor.y))
end

local function RunMigrations(db)
    local version = tonumber(db.version) or 0

    if version < 2 then
        -- Version 1 exposed colour/style controls that were never passed to
        -- rendered rows. Remove those ineffective saved values and retain the
        -- single supported rounded-corner setting instead.
        db.backgroundStyle = nil
        db.backgroundRed = nil
        db.backgroundGreen = nil
        db.backgroundBlue = nil
        db.backgroundPadding = nil
        db.backgroundBorderOpacity = nil
        version = 2
    end

    if version < 3 then
        -- The addon must never alter the Blizzard loot window. These settings
        -- were retired together with the controller that used them.
        db.lootFrameMode = nil
        db.lootFrameBypassModifier = nil
        version = 3
    end

    if version < 4 then
        -- Version 4 adds bounded rows, overall opacity, and opt-in mouse
        -- interaction. MergeDefaults has already supplied safe defaults.
        version = 4
    end

    if version < 5 then
        -- Honor notifications were an unverified post-MVP experiment. Remove
        -- the saved toggle until a localized, live-tested module is added.
        db.showHonor = nil
        version = 5
    end

    db.version = version
end

function Database.Initialize()
    if type(_G.SimpleScrollingLootDB) ~= "table" then
        _G.SimpleScrollingLootDB = CopyTable(ns.Defaults)
    else
        MergeDefaults(_G.SimpleScrollingLootDB, ns.Defaults)
    end

    RunMigrations(_G.SimpleScrollingLootDB)
    if _G.SimpleScrollingLootDB.version < ns.Defaults.version then
        _G.SimpleScrollingLootDB.version = ns.Defaults.version
    end

    ValidateSettings(_G.SimpleScrollingLootDB)
end

function Database.Get(key)
    if not _G.SimpleScrollingLootDB then
        return ns.Defaults[key]
    end
    local val = _G.SimpleScrollingLootDB[key]
    -- Fall back to default for keys not yet present in the saved table
    -- (e.g. after adding a new setting in a future version).
    if val == nil then
        return ns.Defaults[key]
    end
    return val
end

function Database.Set(key, value)
    if not _G.SimpleScrollingLootDB then
        Database.Initialize()
    end

    local defaultValue = ns.Defaults[key]
    if defaultValue ~= nil and type(value) ~= type(defaultValue) then
        value = CopyTable(defaultValue)
    end

    if ns.ValidationRanges and ns.ValidationRanges[key] then
        local range = ns.ValidationRanges[key]
        value = math.max(range.min, math.min(range.max, value))
    end

    if key == "direction" and not validDirections[value] then
        value = ns.Defaults.direction
    elseif key == "anchor" then
        local wrapper = CopyTable(_G.SimpleScrollingLootDB)
        wrapper.anchor = CopyTable(value)
        ValidateSettings(wrapper)
        value = wrapper.anchor
    elseif key == "duration" then
        local fadeDuration = _G.SimpleScrollingLootDB.fadeDuration
        if fadeDuration > value then
            _G.SimpleScrollingLootDB.fadeDuration = value
            NotifyCallbacks("fadeDuration", value)
        end
    elseif key == "fadeDuration" then
        value = math.min(value, _G.SimpleScrollingLootDB.duration)
    end

    _G.SimpleScrollingLootDB[key] = value
    NotifyCallbacks(key, value)
end

function Database.RegisterCallback(key, fn)
    if type(fn) ~= "function" then return end
    callbacks[key] = callbacks[key] or {}
    table.insert(callbacks[key], fn)
end

function Database.Reset()
    _G.SimpleScrollingLootDB = CopyTable(ns.Defaults)
    for key, value in pairs(_G.SimpleScrollingLootDB) do
        if callbacks[key] then
            for _, cb in ipairs(callbacks[key]) do
                cb(value)
            end
        end
    end
    NotifyCallbacks("__reset__", nil)
end
