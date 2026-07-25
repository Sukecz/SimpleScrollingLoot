local addonName, ns = ...

ns.Options = {}

local Options = ns.Options
local optionsPanel = nil

local function CreateOptionsPanel()
    if optionsPanel then return optionsPanel end

    optionsPanel = CreateFrame("Frame", "SimpleScrollingLootOptionsPanel", UIParent)
    optionsPanel.name = ns.L.ADDON_NAME or "Simple Scrolling Loot"

    -- Title
    local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(ns.L.ADDON_NAME or "Simple Scrolling Loot")

    local desc = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    desc:SetText(ns.L.OPT_ENABLE_DESC or "Lightweight loot and money notifications for WoW Classic Era.")

    -- Y Offset counter for stacking controls
    local yOffset = -60

    -- Helper to create Checkbuttons
    local function CreateCheckButton(labelText, dbKey, tooltipText)
        local btn = CreateFrame("CheckButton", nil, optionsPanel, "InterfaceOptionsCheckButtonTemplate")
        btn:SetPoint("TOPLEFT", 16, yOffset)
        btn.Text:SetText(labelText)
        btn:SetChecked(ns.Database.Get(dbKey))

        btn:SetScript("OnClick", function(self)
            local isChecked = self:GetChecked()
            ns.Database.Set(dbKey, isChecked)
        end)

        yOffset = yOffset - 32
        return btn
    end

    -- Helper to create Buttons
    local function CreateButton(text, onClick)
        local btn = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
        btn:SetSize(140, 24)
        btn:SetText(text)
        btn:SetScript("OnClick", onClick)
        return btn
    end

    -- Controls
    CreateCheckButton(ns.L.OPT_ENABLE or "Enable Addon", "enabled")
    CreateCheckButton(ns.L.OPT_SHOW_ITEMS or "Show Item Loot", "showItems")
    CreateCheckButton(ns.L.OPT_SHOW_MONEY or "Show Money Loot", "showMoney")
    CreateCheckButton(ns.L.OPT_SHOW_VENDOR or "Show Vendor Value", "showVendorValue")
    CreateCheckButton(ns.L.OPT_SHOW_QUANTITY or "Show Stack Quantity", "showQuantity")
    CreateCheckButton(ns.L.OPT_SHOW_ICONS or "Show Item Icons", "showIcons")
    CreateCheckButton(ns.L.OPT_STATIC_MODE or "Static Mode (Fade without scrolling)", "staticMode")
    CreateCheckButton(ns.L.OPT_DEBUG or "Enable Debug Logging", "debug")

    -- Action buttons row
    local btnUnlock = CreateButton(ns.L.OPT_UNLOCK_ANCHOR or "Unlock Anchor", function()
        ns.NotificationManager.UnlockAnchor()
    end)
    btnUnlock:SetPoint("TOPLEFT", 16, yOffset)

    local btnLock = CreateButton(ns.L.OPT_LOCK_ANCHOR or "Lock Anchor", function()
        ns.NotificationManager.LockAnchor()
    end)
    btnLock:SetPoint("LEFT", btnUnlock, "RIGHT", 10, 0)

    local btnTest = CreateButton(ns.L.OPT_TEST_NOTIF or "Test Notifications", function()
        ns.NotificationManager.ShowTestNotifications()
    end)
    btnTest:SetPoint("LEFT", btnLock, "RIGHT", 10, 0)

    return optionsPanel
end

function Options.Initialize()
    local panel = CreateOptionsPanel()

    -- Check modern Settings API vs Legacy InterfaceOptions
    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function" then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif type(InterfaceOptions_AddCategory) == "function" then
        InterfaceOptions_AddCategory(panel)
    end
end

function Options.Open()
    local panel = CreateOptionsPanel()
    if Settings and type(Settings.OpenToCategory) == "function" then
        Settings.OpenToCategory(panel.name)
    elseif type(InterfaceOptionsFrame_OpenToCategory) == "function" then
        InterfaceOptionsFrame_OpenToCategory(panel)
    end
end
