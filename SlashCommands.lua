local addonName, ns = ...

ns.SlashCommands = {}

local SlashCommands = ns.SlashCommands

local function PrintHelp()
    local L = ns.L
    local msg = {
        "|cff00ccff" .. (L.ADDON_NAME or "Simple Scrolling Loot") .. "|r",
        L.COMMAND_HELP or "Available slash commands:",
        " - /ssl or /ssloot : Open options window",
        " - /ssl on : Enable addon",
        " - /ssl off : Disable addon",
        " - /ssl test : Display test notifications",
        " - /ssl unlock : Unlock and drag notification anchor",
        " - /ssl lock : Lock notification anchor",
        " - /ssl reset : Reset options to default values",
        " - /ssl debug : Toggle debug mode",
        " - /ssl debug api : Print API compatibility report",
        " - /ssl help : Show command help",
    }
    for _, line in ipairs(msg) do
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage(line)
        else
            print(line)
        end
    end
end

local function HandleSlashCommand(msg)
    msg = string.lower(string.gsub(msg or "", "^%s*(.-)%s*$", "%1"))

    if msg == "" then
        ns.Options.Open()
    elseif msg == "on" or msg == "enable" then
        ns.Database.Set("enabled", true)
        ns.Debug.Warn(ns.L.ENABLED or "Simple Scrolling Loot enabled.")
    elseif msg == "off" or msg == "disable" then
        ns.Database.Set("enabled", false)
        ns.Debug.Warn(ns.L.DISABLED or "Simple Scrolling Loot disabled.")
    elseif msg == "test" or msg == "preview" then
        ns.NotificationManager.ShowTestNotifications()
    elseif msg == "unlock" then
        ns.NotificationManager.UnlockAnchor()
    elseif msg == "lock" then
        ns.NotificationManager.LockAnchor()
    elseif msg == "reset" then
        ns.Database.Reset()
        ns.Debug.Warn(ns.L.RESET_CONFIRM or "Settings reset to defaults.")
    elseif msg == "debug" then
        local current = ns.Database.Get("debug")
        ns.Database.Set("debug", not current)
        ns.Debug.Warn("Debug mode set to %s", tostring(not current))
    elseif msg == "debug api" or msg == "api" then
        ns.CompatibilityProbe.RunReport()
    elseif msg == "help" then
        PrintHelp()
    else
        PrintHelp()
    end
end

function SlashCommands.Initialize()
    _G.SLASH_SIMPLESCROLLINGLOOT1 = "/simplescrollingloot"
    _G.SLASH_SIMPLESCROLLINGLOOT2 = "/ssloot"
    _G.SLASH_SIMPLESCROLLINGLOOT3 = "/ssl"
    SlashCmdList["SIMPLESCROLLINGLOOT"] = HandleSlashCommand
end
