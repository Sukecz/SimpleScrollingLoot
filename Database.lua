local addonName, ns = ...

ns.Database = {}

local Database = ns.Database
local callbacks = {}

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

local function ValidateSettings(db)
    if not ns.ValidationRanges then return end
    for key, range in pairs(ns.ValidationRanges) do
        local val = db[key]
        if type(val) == "number" then
            if val < range.min then db[key] = range.min end
            if val > range.max then db[key] = range.max end
        end
    end
end

function Database.Initialize()
    if not _G.SimpleScrollingLootDB then
        _G.SimpleScrollingLootDB = CopyTable(ns.Defaults)
    else
        MergeDefaults(_G.SimpleScrollingLootDB, ns.Defaults)
    end

    -- Run migrations if version changes in future
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

    -- Validate range if numeric
    if ns.ValidationRanges and ns.ValidationRanges[key] and type(value) == "number" then
        local range = ns.ValidationRanges[key]
        value = math.max(range.min, math.min(range.max, value))
    end

    _G.SimpleScrollingLootDB[key] = value

    -- Notify callbacks
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

function Database.RegisterCallback(key, fn)
    if type(fn) ~= "function" then return end
    callbacks[key] = callbacks[key] or {}
    table.insert(callbacks[key], fn)
end

function Database.Reset()
    _G.SimpleScrollingLootDB = CopyTable(ns.Defaults)
    if callbacks["*"] then
        for _, cb in ipairs(callbacks["*"]) do
            cb("__reset__", nil)
        end
    end
end
