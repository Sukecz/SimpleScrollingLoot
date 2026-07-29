local addonName, ns = ...

ns.Debug = {}

local Debug = ns.Debug
local PREFIX = "|cff00ccff[Simple Scrolling Loot]|r "

function Debug.Log(fmt, ...)
    if ns.Database and ns.Database.Get and ns.Database.Get("debug") then
        local msg = select("#", ...) > 0 and string.format(fmt, ...) or tostring(fmt)
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
        else
            print(PREFIX .. msg)
        end
    end
end

function Debug.Info(fmt, ...)
    local msg = select("#", ...) > 0 and string.format(fmt, ...) or tostring(fmt)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
    else
        print(PREFIX .. msg)
    end
end

function Debug.Warn(fmt, ...)
    local msg = select("#", ...) > 0 and string.format(fmt, ...) or tostring(fmt)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. "|cffffcc00[WARN]|r " .. msg)
    else
        print(PREFIX .. "[WARN] " .. msg)
    end
end

function Debug.Error(fmt, ...)
    local msg = select("#", ...) > 0 and string.format(fmt, ...) or tostring(fmt)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. "|cffff3333[ERROR]|r " .. msg)
    else
        print(PREFIX .. "[ERROR] " .. msg)
    end
end

function Debug.LogUnrecognizedLoot(event, rawMessage)
    if ns.Database and ns.Database.Get and ns.Database.Get("debug") then
        Debug.Log("Unrecognized loot format in %s: '%s'", tostring(event), tostring(rawMessage))
    end
end

function Debug.LogEvent(event, ...)
    if not ns.Database or not ns.Database.Get or not ns.Database.Get("debug") then
        return
    end

    local values = {}
    for index = 1, select("#", ...) do
        values[index] = string.format("%d=%s", index, tostring(select(index, ...)))
    end
    Debug.Log("Event %s args: %s", tostring(event), table.concat(values, ", "))
end
