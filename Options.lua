local addonName, ns = ...

ns.Options = {}

local Options = ns.Options
local optionsWindowFrame = nil
local blizzardOptionsCategory = nil

local function CreateSlider(parent, name, labelText, minVal, maxVal, step, dbKey, x, y)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    local currentVal = ns.Database.Get(dbKey) or minVal
    slider:SetValue(currentVal)

    _G[name .. 'Low']:SetText(tostring(minVal))
    _G[name .. 'High']:SetText(tostring(maxVal))
    _G[name .. 'Text']:SetText(string.format("%s: %s", labelText, tostring(currentVal)))

    slider:SetScript("OnValueChanged", function(self, value)
        if step >= 1 then
            value = math.floor(value + 0.5)
        else
            value = math.floor(value * 10 + 0.5) / 10
        end
        _G[name .. 'Text']:SetText(string.format("%s: %s", labelText, tostring(value)))
        ns.Database.Set(dbKey, value)
    end)

    return slider
end

local function CreateCheckButton(parent, labelText, dbKey, x, y)
    local btn = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn.Text:SetText(labelText)
    btn:SetChecked(ns.Database.Get(dbKey) and true or false)

    btn:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        ns.Database.Set(dbKey, isChecked)
    end)

    return btn
end

local function CreateOptionsWindow()
    if optionsWindowFrame then return optionsWindowFrame end

    local frame = CreateFrame("Frame", "SimpleScrollingLootOptionsWindow", UIParent, "DialogBoxFrame")
    frame:SetSize(520, 580)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    tinsert(UISpecialFrames, "SimpleScrollingLootOptionsWindow") -- Allows ESC to close

    -- Header Title
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -14)
    title:SetText(ns.L.ADDON_NAME or "Simple Scrolling Loot Options")

    -- Column 1 (Left) - Toggles
    local xLeft = 24
    local yLeft = -50

    CreateCheckButton(frame, ns.L.OPT_ENABLE or "Enable Addon", "enabled", xLeft, yLeft)
    yLeft = yLeft - 30
    CreateCheckButton(frame, ns.L.OPT_SHOW_ITEMS or "Show Item Loot", "showItems", xLeft, yLeft)
    yLeft = yLeft - 30
    CreateCheckButton(frame, ns.L.OPT_SHOW_MONEY or "Show Money Loot", "showMoney", xLeft, yLeft)
    yLeft = yLeft - 30
    CreateCheckButton(frame, ns.L.OPT_SHOW_HONOR or "Show Honor Gains", "showHonor", xLeft, yLeft)
    yLeft = yLeft - 30
    CreateCheckButton(frame, ns.L.OPT_SHOW_VENDOR or "Show Vendor Value", "showVendorValue", xLeft, yLeft)
    yLeft = yLeft - 30
    CreateCheckButton(frame, ns.L.OPT_SHOW_QUANTITY or "Show Stack Quantity", "showQuantity", xLeft, yLeft)
    yLeft = yLeft - 30
    CreateCheckButton(frame, ns.L.OPT_SHOW_ICONS or "Show Item Icons", "showIcons", xLeft, yLeft)
    yLeft = yLeft - 30
    CreateCheckButton(frame, ns.L.OPT_SHOW_BG or "Show Background", "showBackground", xLeft, yLeft)
    yLeft = yLeft - 30
    CreateCheckButton(frame, ns.L.OPT_STATIC_MODE or "Static Mode (No scroll)", "staticMode", xLeft, yLeft)
    yLeft = yLeft - 30
    CreateCheckButton(frame, ns.L.OPT_DEBUG or "Enable Debug Logging", "debug", xLeft, yLeft)

    -- Column 2 (Right) - Sliders
    local xRight = 270
    local yRight = -60

    CreateSlider(frame, "SSLSliderFontSize", ns.L.OPT_FONT_SIZE or "Font Size", 8, 32, 1, "fontSize", xRight, yRight)
    yRight = yRight - 45
    CreateSlider(frame, "SSLSliderIconSize", ns.L.OPT_ICON_SIZE or "Icon Size", 12, 64, 2, "iconSize", xRight, yRight)
    yRight = yRight - 45
    CreateSlider(frame, "SSLSliderDuration", ns.L.OPT_DURATION or "Duration (s)", 0.5, 15, 0.5, "duration", xRight, yRight)
    yRight = yRight - 45
    CreateSlider(frame, "SSLSliderFadeDuration", ns.L.OPT_FADE_DURATION or "Fade Duration (s)", 0.1, 5, 0.1, "fadeDuration", xRight, yRight)
    yRight = yRight - 45
    CreateSlider(frame, "SSLSliderTravel", ns.L.OPT_TRAVEL_DIST or "Travel Distance", 10, 300, 10, "travelDistance", xRight, yRight)
    yRight = yRight - 45
    CreateSlider(frame, "SSLSliderMaxVisible", ns.L.OPT_MAX_VISIBLE or "Max Visible Rows", 1, 15, 1, "maxVisible", xRight, yRight)
    yRight = yRight - 45
    CreateSlider(frame, "SSLSliderRowSpacing", ns.L.OPT_ROW_SPACING or "Row Spacing", 0, 30, 1, "rowSpacing", xRight, yRight)
    yRight = yRight - 45
    CreateSlider(frame, "SSLSliderMinQuality", ns.L.OPT_MIN_QUALITY or "Min Quality (0-4)", 0, 4, 1, "minQuality", xRight, yRight)

    -- Bottom Action Buttons
    local btnUnlock = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnUnlock:SetSize(110, 24)
    btnUnlock:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 50)
    btnUnlock:SetText(ns.L.OPT_UNLOCK_ANCHOR or "Unlock Anchor")
    btnUnlock:SetScript("OnClick", function()
        ns.NotificationManager.UnlockAnchor()
    end)

    local btnLock = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnLock:SetSize(110, 24)
    btnLock:SetPoint("LEFT", btnUnlock, "RIGHT", 10, 0)
    btnLock:SetText(ns.L.OPT_LOCK_ANCHOR or "Lock Anchor")
    btnLock:SetScript("OnClick", function()
        ns.NotificationManager.LockAnchor()
    end)

    local btnTest = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnTest:SetSize(120, 24)
    btnTest:SetPoint("LEFT", btnLock, "RIGHT", 10, 0)
    btnTest:SetText(ns.L.OPT_TEST_NOTIF or "Test Loot")
    btnTest:SetScript("OnClick", function()
        ns.NotificationManager.ShowTestNotifications()
    end)

    local btnReset = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnReset:SetSize(110, 24)
    btnReset:SetPoint("LEFT", btnTest, "RIGHT", 10, 0)
    btnReset:SetText(ns.L.OPT_RESET_DEFAULTS or "Reset Defaults")
    btnReset:SetScript("OnClick", function()
        ns.Database.Reset()
        frame:Hide()
        optionsWindowFrame = nil
        Options.Open()
    end)

    optionsWindowFrame = frame
    return optionsWindowFrame
end

function Options.Initialize()
    local panel = CreateOptionsWindow()
    panel:Hide()

    -- Register with Blizzard settings panel as well
    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function" then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name or "Simple Scrolling Loot")
        Settings.RegisterAddOnCategory(category)
        blizzardOptionsCategory = category
    elseif type(InterfaceOptions_AddCategory) == "function" then
        InterfaceOptions_AddCategory(panel)
    end
end

function Options.Open()
    local win = CreateOptionsWindow()
    if win:IsShown() then
        win:Hide()
    else
        win:Show()
    end
end
