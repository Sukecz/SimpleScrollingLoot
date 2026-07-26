local addonName, ns = ...

ns.Options = {}

local Options = ns.Options
local optionsWindowFrame = nil
local blizzardOptionsCategory = nil

local function AddTooltip(frame, title, description)
    frame:HookScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1.0, 0.82, 0.0)
        GameTooltip:AddLine(description or title, 1.0, 1.0, 1.0, true)
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end

-- ---------------------------------------------------------------------------
-- Widget helpers
-- ---------------------------------------------------------------------------

local function CreateSlider(parent, name, labelText, minVal, maxVal, step, dbKey, x, y, description)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.dbKey = dbKey
    slider.labelText = labelText
    slider.step = step
    AddTooltip(slider, labelText, description)

    local currentVal = ns.Database.Get(dbKey) or minVal
    slider:SetValue(currentVal)

    _G[name .. "Low"]:SetText(tostring(minVal))
    _G[name .. "High"]:SetText(tostring(maxVal))
    _G[name .. "Text"]:SetText(string.format("%s: %s", labelText, tostring(currentVal)))

    slider:SetScript("OnValueChanged", function(self, value)
        if step >= 1 then
            value = math.floor(value + 0.5)
        else
            value = math.floor(value * 10 + 0.5) / 10
        end
        _G[name .. "Text"]:SetText(string.format("%s: %s", labelText, tostring(value)))
        ns.Database.Set(dbKey, value)
    end)

    -- Expose a refresh helper so we can update the widget after a settings reset.
    slider.Refresh = function(self)
        local val = ns.Database.Get(self.dbKey) or minVal
        self:SetValue(val)
        _G[name .. "Text"]:SetText(string.format("%s: %s", self.labelText, tostring(val)))
    end

    return slider
end

local function CreateCheckButton(parent, labelText, dbKey, x, y, description)
    local btn = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn.Text:SetText(labelText)
    btn.dbKey = dbKey
    AddTooltip(btn, labelText, description)
    btn:SetChecked(ns.Database.Get(dbKey) and true or false)

    btn:SetScript("OnClick", function(self)
        ns.Database.Set(dbKey, self:GetChecked())
    end)

    btn.Refresh = function(self)
        self:SetChecked(ns.Database.Get(self.dbKey) and true or false)
    end

    return btn
end

-- Creates a simple dropdown for a fixed list of {value, label} pairs.
-- Returns the frame; frame.Refresh() re-reads the DB key.
local function CreateDropdown(parent, labelText, dbKey, items, x, y, description)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 16, y)
    dropdown.dbKey = dbKey
    AddTooltip(dropdown, labelText, description)

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 16, 2)
    label:SetText(labelText)

    local function BuildMenu()
        local currentVal = ns.Database.Get(dbKey)
        for _, item in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.label
            info.value = item.value
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                UIDropDownMenu_SetText(dropdown, self:GetText())
                ns.Database.Set(dbKey, self.value)
            end
            info.checked = (currentVal == item.value)
            UIDropDownMenu_AddButton(info)
        end
    end

    UIDropDownMenu_Initialize(dropdown, BuildMenu)

    -- Set initial display text
    local currentVal = ns.Database.Get(dbKey)
    for _, item in ipairs(items) do
        if item.value == currentVal then
            UIDropDownMenu_SetText(dropdown, item.label)
            UIDropDownMenu_SetSelectedValue(dropdown, item.value)
            break
        end
    end
    UIDropDownMenu_SetWidth(dropdown, 160)

    dropdown.Refresh = function(self)
        local val = ns.Database.Get(self.dbKey)
        for _, item in ipairs(items) do
            if item.value == val then
                UIDropDownMenu_SetText(self, item.label)
                UIDropDownMenu_SetSelectedValue(self, val)
                break
            end
        end
    end

    return dropdown
end

-- ---------------------------------------------------------------------------
-- Tracked widgets list for refresh-on-reset
-- ---------------------------------------------------------------------------
local allWidgets = {}

-- ---------------------------------------------------------------------------
-- Options window construction
-- ---------------------------------------------------------------------------

local function CreateOptionsWindow()
    if optionsWindowFrame then return optionsWindowFrame end

    local frame = CreateFrame("Frame", "SimpleScrollingLootOptionsWindow", UIParent, "DialogBoxFrame")
    frame:SetSize(760, 660)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    tinsert(UISpecialFrames, "SimpleScrollingLootOptionsWindow") -- ESC closes the window

    -- Header
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -14)
    title:SetText(ns.L.ADDON_NAME or "Simple Scrolling Loot Options")

    -- -----------------------------------------------------------------------
    -- Column 1 (Left) – Toggle checkboxes
    -- -----------------------------------------------------------------------
    local xLeft = 24
    local yLeft = -50

    local widgets = {}

    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_ENABLE, "enabled", xLeft, yLeft, ns.L.OPT_ENABLE_DESC)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_SHOW_ITEMS, "showItems", xLeft, yLeft, ns.L.OPT_SHOW_ITEMS_DESC)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_SHOW_MONEY, "showMoney", xLeft, yLeft, ns.L.OPT_SHOW_MONEY_DESC)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_SHOW_VENDOR, "showVendorValue", xLeft, yLeft, ns.L.OPT_SHOW_VENDOR_DESC)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_SHOW_QUANTITY, "showQuantity", xLeft, yLeft, ns.L.OPT_SHOW_QUANTITY_DESC)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_SHOW_ICONS, "showIcons", xLeft, yLeft, ns.L.OPT_SHOW_ICONS_DESC)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_SHOW_BG, "showBackground", xLeft, yLeft, ns.L.OPT_SHOW_BG_DESC)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_BG_ROUNDED, "backgroundRounded", xLeft, yLeft, ns.L.OPT_BG_ROUNDED_DESC)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_STATIC_MODE, "staticMode", xLeft, yLeft, ns.L.OPT_STATIC_MODE_DESC)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_DEBUG, "debug", xLeft, yLeft, ns.L.OPT_DEBUG_DESC)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_MOUSE_INTERACTION, "mouseInteraction", xLeft, yLeft, ns.L.OPT_MOUSE_INTERACTION_DESC)

    -- -----------------------------------------------------------------------
    -- Column 2 – compact sliders
    -- -----------------------------------------------------------------------
    local xMiddle = 320
    local yMiddle = -55

    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderFontSize", ns.L.OPT_FONT_SIZE, 8, 32, 1, "fontSize", xMiddle, yMiddle, ns.L.OPT_FONT_SIZE_DESC) ; yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderIconSize", ns.L.OPT_ICON_SIZE, 12, 64, 2, "iconSize", xMiddle, yMiddle, ns.L.OPT_ICON_SIZE_DESC) ; yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderScale", ns.L.OPT_SCALE, 5, 30, 1, "scale", xMiddle, yMiddle, ns.L.OPT_SCALE_DESC)
    -- Note: scale stored as 0.5–3.0 but slider uses 5–30 (×0.1) for step granularity.
    -- Override OnValueChanged for scale to divide by 10.
    do
        local s = widgets[#widgets]
        s:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value + 0.5)
            local realVal = value / 10
            _G["SSLSliderScaleText"]:SetText(string.format("%s: %.1f", s.labelText, realVal))
            ns.Database.Set("scale", realVal)
        end)
        s.Refresh = function(self)
            local val = ns.Database.Get("scale") or 1.0
            self:SetValue(math.floor(val * 10 + 0.5))
            _G["SSLSliderScaleText"]:SetText(string.format("%s: %.1f", self.labelText, val))
        end
        -- Initialise display correctly
        local initVal = ns.Database.Get("scale") or 1.0
        s:SetValue(math.floor(initVal * 10 + 0.5))
        _G["SSLSliderScaleText"]:SetText(string.format("%s: %.1f", s.labelText, initVal))
        _G["SSLSliderScaleLow"]:SetText("0.5")
        _G["SSLSliderScaleHigh"]:SetText("3.0")
    end
    yMiddle = yMiddle - 42

    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderDuration", ns.L.OPT_DURATION, 0.5, 15, 0.5, "duration", xMiddle, yMiddle, ns.L.OPT_DURATION_DESC) ; yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderFadeDuration", ns.L.OPT_FADE_DURATION, 0.1, 5, 0.1, "fadeDuration", xMiddle, yMiddle, ns.L.OPT_FADE_DURATION_DESC) ; yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderTravel", ns.L.OPT_TRAVEL_DIST, 10, 300, 10, "travelDistance", xMiddle, yMiddle, ns.L.OPT_TRAVEL_DIST_DESC) ; yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderMaxVisible", ns.L.OPT_MAX_VISIBLE, 1, 15, 1, "maxVisible", xMiddle, yMiddle, ns.L.OPT_MAX_VISIBLE_DESC) ; yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderRowSpacing", ns.L.OPT_ROW_SPACING, 0, 30, 1, "rowSpacing", xMiddle, yMiddle, ns.L.OPT_ROW_SPACING_DESC) ; yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderMinQuality", ns.L.OPT_MIN_QUALITY, 0, 5, 1, "minQuality", xMiddle, yMiddle, ns.L.OPT_MIN_QUALITY_DESC)
    yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderMaxWidth", ns.L.OPT_MAX_WIDTH, 160, 800, 20, "maxWidth", xMiddle, yMiddle, ns.L.OPT_MAX_WIDTH_DESC)
    yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderRowOpacity", ns.L.OPT_ROW_OPACITY, 1, 10, 1, "rowOpacity", xMiddle, yMiddle, ns.L.OPT_ROW_OPACITY_DESC)
    do
        local s = widgets[#widgets]
        s:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value + 0.5)
            local realVal = value / 10
            _G["SSLSliderRowOpacityText"]:SetText(string.format("%s: %.1f", s.labelText, realVal))
            ns.Database.Set("rowOpacity", realVal)
        end)
        s.Refresh = function(self)
            local val = ns.Database.Get("rowOpacity")
            self:SetValue(math.floor(val * 10 + 0.5))
            _G["SSLSliderRowOpacityText"]:SetText(string.format("%s: %.1f", self.labelText, val))
        end
        s:Refresh()
        _G["SSLSliderRowOpacityLow"]:SetText("0.1")
        _G["SSLSliderRowOpacityHigh"]:SetText("1.0")
    end
    yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderBgOpacity", ns.L.OPT_BG_OPACITY, 0, 10, 1, "backgroundOpacity", xMiddle, yMiddle, ns.L.OPT_BG_OPACITY_DESC)
    -- Override for backgroundOpacity (stored 0–1, slider 0–10)
    do
        local s = widgets[#widgets]
        s:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value + 0.5)
            local realVal = value / 10
            _G["SSLSliderBgOpacityText"]:SetText(string.format("%s: %.1f", s.labelText, realVal))
            ns.Database.Set("backgroundOpacity", realVal)
        end)
        s.Refresh = function(self)
            local val = ns.Database.Get("backgroundOpacity") or 0.35
            self:SetValue(math.floor(val * 10 + 0.5))
            _G["SSLSliderBgOpacityText"]:SetText(string.format("%s: %.1f", self.labelText, val))
        end
        local initVal = ns.Database.Get("backgroundOpacity") or 0.35
        s:SetValue(math.floor(initVal * 10 + 0.5))
        _G["SSLSliderBgOpacityText"]:SetText(string.format("%s: %.1f", s.labelText, initVal))
        _G["SSLSliderBgOpacityLow"]:SetText("0.0")
        _G["SSLSliderBgOpacityHigh"]:SetText("1.0")
    end
    -- -----------------------------------------------------------------------
    -- Dropdowns – beneath column 1
    -- -----------------------------------------------------------------------
    -- Leave a full row between the final checkbox and the first dropdown;
    -- the dropdown label otherwise overlaps the Debug Logging text.
    yLeft = yLeft - 40

    widgets[#widgets + 1] = CreateDropdown(frame,
        ns.L.OPT_DIRECTION or "Scroll Direction",
        "direction",
        {
            { value = "UP",   label = ns.L.OPT_DIRECTION_UP   or "Upwards"   },
            { value = "DOWN", label = ns.L.OPT_DIRECTION_DOWN or "Downwards" },
        },
        xLeft, yLeft, ns.L.OPT_DIRECTION_DESC)
    -- -----------------------------------------------------------------------
    -- Bottom action buttons
    -- -----------------------------------------------------------------------
    local btnUnlock = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnUnlock:SetSize(110, 24)
    btnUnlock:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 50)
    btnUnlock:SetText(ns.L.OPT_UNLOCK_ANCHOR or "Unlock Anchor")
    AddTooltip(btnUnlock, ns.L.OPT_UNLOCK_ANCHOR, ns.L.OPT_UNLOCK_ANCHOR_DESC)
    btnUnlock:SetScript("OnClick", function()
        ns.NotificationManager.UnlockAnchor()
    end)

    local btnLock = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnLock:SetSize(110, 24)
    btnLock:SetPoint("LEFT", btnUnlock, "RIGHT", 10, 0)
    btnLock:SetText(ns.L.OPT_LOCK_ANCHOR or "Lock Anchor")
    AddTooltip(btnLock, ns.L.OPT_LOCK_ANCHOR, ns.L.OPT_LOCK_ANCHOR_DESC)
    btnLock:SetScript("OnClick", function()
        ns.NotificationManager.LockAnchor()
    end)

    local btnTest = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnTest:SetSize(120, 24)
    btnTest:SetPoint("LEFT", btnLock, "RIGHT", 10, 0)
    btnTest:SetText(ns.L.OPT_TEST_NOTIF or "Test Loot")
    AddTooltip(btnTest, ns.L.OPT_TEST_NOTIF, ns.L.OPT_TEST_NOTIF_DESC)
    btnTest:SetScript("OnClick", function()
        ns.NotificationManager.ShowTestNotifications()
    end)

    local btnReset = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnReset:SetSize(110, 24)
    btnReset:SetPoint("LEFT", btnTest, "RIGHT", 10, 0)
    btnReset:SetText(ns.L.OPT_RESET_DEFAULTS or "Reset Defaults")
    AddTooltip(btnReset, ns.L.OPT_RESET_DEFAULTS, ns.L.OPT_RESET_DEFAULTS_DESC)
    btnReset:SetScript("OnClick", function()
        StaticPopup_Show("SSL_CONFIRM_RESET")
    end)

    local btnResetPosition = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnResetPosition:SetSize(120, 24)
    btnResetPosition:SetPoint("LEFT", btnReset, "RIGHT", 10, 0)
    btnResetPosition:SetText(ns.L.OPT_RESET_POSITION)
    AddTooltip(btnResetPosition, ns.L.OPT_RESET_POSITION, ns.L.OPT_RESET_POSITION_DESC)
    btnResetPosition:SetScript("OnClick", function()
        ns.NotificationManager.ResetAnchor()
    end)

    -- Track all widgets for refresh after reset.
    allWidgets = widgets

    optionsWindowFrame = frame
    return optionsWindowFrame
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function Options.Initialize()
    local panel = CreateOptionsWindow()
    panel:Hide()

    -- Register with the Blizzard Settings / Interface Options panel.
    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function" then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name or "Simple Scrolling Loot")
        Settings.RegisterAddOnCategory(category)
        blizzardOptionsCategory = category
    elseif type(InterfaceOptions_AddCategory) == "function" then
        InterfaceOptions_AddCategory(panel)
    end

    ns.Database.RegisterCallback("*", function(key)
        if key ~= "__reset__" then return end
        for _, widget in ipairs(allWidgets) do
            if widget.Refresh then widget:Refresh() end
        end
    end)
end

function Options.Open()
    local win = CreateOptionsWindow()
    if win:IsShown() then
        win:Hide()
    else
        win:Show()
    end
end
