local addonName, ns = ...

ns.Options = {}

local Options = ns.Options
local optionsWindowFrame = nil
local blizzardOptionsCategory = nil

-- ---------------------------------------------------------------------------
-- Widget helpers
-- ---------------------------------------------------------------------------

local function CreateSlider(parent, name, labelText, minVal, maxVal, step, dbKey, x, y)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.dbKey = dbKey
    slider.labelText = labelText
    slider.step = step

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

-- Settings stored as 0.0–1.0 use an integer 0–10 slider for precise,
-- readable controls in the Blizzard options template.
local function CreateUnitIntervalSlider(parent, name, labelText, dbKey, x, y)
    local slider = CreateSlider(parent, name, labelText, 0, 10, 1, dbKey, x, y)

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        local realValue = value / 10
        _G[name .. "Text"]:SetText(string.format("%s: %.1f", labelText, realValue))
        ns.Database.Set(dbKey, realValue)
    end)

    slider.Refresh = function(self)
        local value = ns.Database.Get(dbKey) or 0
        self:SetValue(math.floor(value * 10 + 0.5))
        _G[name .. "Text"]:SetText(string.format("%s: %.1f", labelText, value))
    end

    local initialValue = ns.Database.Get(dbKey) or 0
    slider:SetValue(math.floor(initialValue * 10 + 0.5))
    _G[name .. "Text"]:SetText(string.format("%s: %.1f", labelText, initialValue))
    _G[name .. "Low"]:SetText("0.0")
    _G[name .. "High"]:SetText("1.0")

    return slider
end

local function CreateCheckButton(parent, labelText, dbKey, x, y)
    local btn = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn.Text:SetText(labelText)
    btn.dbKey = dbKey
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
local function CreateDropdown(parent, labelText, dbKey, items, x, y)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 16, y)
    dropdown.dbKey = dbKey

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
    frame:SetSize(850, 640)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
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

    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_ENABLE or "Enable Addon", "enabled", xLeft, yLeft)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_SHOW_ITEMS or "Show Item Loot", "showItems", xLeft, yLeft)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_SHOW_MONEY or "Show Money Loot", "showMoney", xLeft, yLeft)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_SHOW_HONOR or "Show Honor Gains", "showHonor", xLeft, yLeft)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_SHOW_VENDOR or "Show Vendor Value", "showVendorValue", xLeft, yLeft)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_SHOW_QUANTITY or "Show Stack Quantity", "showQuantity", xLeft, yLeft)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_SHOW_ICONS or "Show Item Icons", "showIcons", xLeft, yLeft)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_SHOW_BG or "Show Background", "showBackground", xLeft, yLeft)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_STATIC_MODE or "Static Mode (No scroll)", "staticMode", xLeft, yLeft)
    yLeft = yLeft - 25
    widgets[#widgets + 1] = CreateCheckButton(frame, ns.L.OPT_DEBUG or "Enable Debug Logging", "debug", xLeft, yLeft)

    -- -----------------------------------------------------------------------
    -- Columns 2 and 3 – compact sliders
    -- -----------------------------------------------------------------------
    local xMiddle = 285
    local yMiddle = -55
    local xBackground = 570
    local yBackground = -55

    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderFontSize",    ns.L.OPT_FONT_SIZE    or "Font Size",        8,   32, 1,   "fontSize",        xMiddle, yMiddle) ; yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderIconSize",    ns.L.OPT_ICON_SIZE    or "Icon Size",       12,   64, 2,   "iconSize",        xMiddle, yMiddle) ; yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderScale",       ns.L.OPT_SCALE        or "UI Scale (x10)",   5,   30, 1,   "scale",           xMiddle, yMiddle)
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

    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderDuration",    ns.L.OPT_DURATION     or "Duration (s)",    0.5,  15,  0.5, "duration",        xMiddle, yMiddle) ; yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderFadeDuration",ns.L.OPT_FADE_DURATION or "Fade (s)",       0.1,   5,  0.1, "fadeDuration",    xMiddle, yMiddle) ; yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderTravel",      ns.L.OPT_TRAVEL_DIST  or "Travel (px)",      10, 300, 10,  "travelDistance",  xMiddle, yMiddle) ; yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderMaxVisible",  ns.L.OPT_MAX_VISIBLE  or "Max Visible",       1,  15,  1,   "maxVisible",      xMiddle, yMiddle) ; yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderRowSpacing",  ns.L.OPT_ROW_SPACING  or "Row Spacing (px)",  0,  30,  1,   "rowSpacing",      xMiddle, yMiddle) ; yMiddle = yMiddle - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderMinQuality",  ns.L.OPT_MIN_QUALITY  or "Min Quality (0-5)", 0,   5,  1,   "minQuality",      xMiddle, yMiddle)
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderBgOpacity",   ns.L.OPT_BG_OPACITY   or "BG Opacity",        0,  10,  1,   "backgroundOpacity", xBackground, yBackground)
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
    yBackground = yBackground - 42

    widgets[#widgets + 1] = CreateUnitIntervalSlider(frame, "SSLSliderBgRed", ns.L.OPT_BG_RED or "Background Red", "backgroundRed", xBackground, yBackground)
    yBackground = yBackground - 42
    widgets[#widgets + 1] = CreateUnitIntervalSlider(frame, "SSLSliderBgGreen", ns.L.OPT_BG_GREEN or "Background Green", "backgroundGreen", xBackground, yBackground)
    yBackground = yBackground - 42
    widgets[#widgets + 1] = CreateUnitIntervalSlider(frame, "SSLSliderBgBlue", ns.L.OPT_BG_BLUE or "Background Blue", "backgroundBlue", xBackground, yBackground)
    yBackground = yBackground - 42
    widgets[#widgets + 1] = CreateSlider(frame, "SSLSliderBgPadding", ns.L.OPT_BG_PADDING or "Background Padding (px)", 0, 16, 1, "backgroundPadding", xBackground, yBackground)
    yBackground = yBackground - 42
    widgets[#widgets + 1] = CreateUnitIntervalSlider(frame, "SSLSliderBgBorderOpacity", ns.L.OPT_BG_BORDER_OPACITY or "Border Opacity", "backgroundBorderOpacity", xBackground, yBackground)

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
        xLeft, yLeft)
    yLeft = yLeft - 50

    widgets[#widgets + 1] = CreateDropdown(frame,
        ns.L.OPT_LOOT_FRAME or "Blizzard Loot Frame",
        "lootFrameMode",
        {
            { value = "DEFAULT",     label = ns.L.OPT_LOOT_FRAME_DEFAULT    or "Default (keep)"         },
            { value = "HIDE_AUTO",   label = ns.L.OPT_LOOT_FRAME_HIDE_AUTO  or "Hide while auto-looting" },
            { value = "ALWAYS_HIDE", label = ns.L.OPT_LOOT_FRAME_ALWAYS_HIDE or "Always hide (where safe)" },
        },
        xLeft, yLeft)
    yLeft = yLeft - 50

    widgets[#widgets + 1] = CreateDropdown(frame,
        ns.L.OPT_BYPASS_MOD or "Bypass Modifier Key",
        "lootFrameBypassModifier",
        {
            { value = "SHIFT", label = "Shift" },
            { value = "CTRL",  label = "Ctrl"  },
            { value = "ALT",   label = "Alt"   },
        },
        xLeft, yLeft)
    yLeft = yLeft - 50

    widgets[#widgets + 1] = CreateDropdown(frame,
        ns.L.OPT_BG_STYLE or "Background Style",
        "backgroundStyle",
        {
            { value = "SOLID", label = ns.L.OPT_BG_STYLE_SOLID or "Solid" },
            { value = "TOOLTIP", label = ns.L.OPT_BG_STYLE_TOOLTIP or "Rounded Tooltip" },
            { value = "DIALOG", label = ns.L.OPT_BG_STYLE_DIALOG or "Dark Dialog" },
        },
        xLeft, yLeft)

    -- -----------------------------------------------------------------------
    -- Bottom action buttons
    -- -----------------------------------------------------------------------
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
        -- Use the shared confirmation popup (also used by /ssl reset).
        -- After OnAccept fires, refresh all widgets in place without
        -- destroying and recreating the window.
        local savedOnAccept = StaticPopupDialogs["SSL_CONFIRM_RESET"].OnAccept
        StaticPopupDialogs["SSL_CONFIRM_RESET"].OnAccept = function()
            if savedOnAccept then savedOnAccept() end
            -- Refresh every tracked widget to reflect restored defaults.
            for _, w in ipairs(allWidgets) do
                if w.Refresh then w:Refresh() end
            end
        end
        StaticPopup_Show("SSL_CONFIRM_RESET")
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
end

function Options.Open()
    local win = CreateOptionsWindow()
    if win:IsShown() then
        win:Hide()
    else
        win:Show()
    end
end
