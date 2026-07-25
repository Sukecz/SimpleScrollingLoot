local addonName, ns = ...

ns.SlashCommands = {}

local SlashCommands = ns.SlashCommands

local function PrintHelp()
    local L = ns.L
    local msg = {
        "|cff00ccff" .. (L.ADDON_NAME or "Simple Scrolling Loot") .. "|r",
        L.COMMAND_HELP or "Available slash commands:",
        L.HELP_ON     or " - /ssl on : Enable addon",
        L.HELP_OFF    or " - /ssl off : Disable addon",
        L.HELP_TEST   or " - /ssl test : Display test notifications",
        L.HELP_UNLOCK or " - /ssl unlock : Unlock and drag notification anchor",
        L.HELP_LOCK   or " - /ssl lock : Lock notification anchor",
        L.HELP_RESET  or " - /ssl reset : Reset options to default values",
        L.HELP_DEBUG  or " - /ssl debug : Toggle debug mode",
        L.HELP_DEBUG_API or " - /ssl debug api : Print API compatibility report",
        L.HELP_HELP   or " - /ssl help : Show command help",
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
        -- AGENTS.md requires a confirmation step before wiping settings.
        StaticPopup_Show("SSL_CONFIRM_RESET")
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
    -- Register the confirmation popup once.
    -- This must be set up before any slash command is processed.
    StaticPopupDialogs["SSL_CONFIRM_RESET"] = {
        text = "Reset all Simple Scrolling Loot settings to defaults?\nThis cannot be undone.",
        button1 = "Reset",
        button2 = "Cancel",
        OnAccept = function()
            ns.Database.Reset()
            ns.Debug.Warn(ns.L.RESET_CONFIRM or "Settings reset to defaults.")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    _G.SLASH_SIMPLESCROLLINGLOOT1 = "/simplescrollingloot"
    _G.SLASH_SIMPLESCROLLINGLOOT2 = "/ssloot"
    _G.SLASH_SIMPLESCROLLINGLOOT3 = "/ssl"
    SlashCmdList["SIMPLESCROLLINGLOOT"] = HandleSlashCommand
end
