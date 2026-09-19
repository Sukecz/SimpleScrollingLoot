local addonName, ns = ...

ns.Options = {}

local Options = ns.Options
local optionsWindowFrame = nil
local blizzardOptionsCategory = nil
local allWidgets = {}
local pages = {}
local tabButtons = {}
local selectedPage = nil
local moveButton = nil
local moveHelpText = nil
local moveSaveButton = nil
local movePreviewButton = nil

local PAGE_ORDER = {
    "general",
    "appearance",
    "movement",
    "advanced",
}

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

local function SetEnabledText(text, enabled, normalColor)
    if not text then return end
    if enabled then
        text:SetTextColor(normalColor[1], normalColor[2], normalColor[3])
    else
        text:SetTextColor(0.45, 0.45, 0.45)
    end
end

local function CreateSection(parent, titleText, y)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, y)
    title:SetText(titleText)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.45, 0.35, 0.16, 0.8)
    line:SetPoint("LEFT", title, "RIGHT", 10, 0)
    line:SetPoint("RIGHT", parent, "RIGHT", -18, 0)
    line:SetHeight(1)
end

local function CreateCheckButton(parent, labelText, dbKey, y, description)
    local button = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, y)
    button.Text:SetText(labelText)
    button.Text:SetWidth(math.max(1, parent:GetWidth() - 70))
    parent:HookScript("OnSizeChanged", function(self, width)
        button.Text:SetWidth(math.max(1, width - 70))
    end)
    button.Text:SetJustifyH("LEFT")
    button.dbKey = dbKey
    AddTooltip(button, labelText, description)

    button:SetScript("OnClick", function(self)
        ns.Database.Set(self.dbKey, self:GetChecked() and true or false)
    end)

    button.Refresh = function(self)
        self:SetChecked(ns.Database.Get(self.dbKey) and true or false)
    end

    button.SetSettingEnabled = function(self, enabled)
        if enabled then
            self:Enable()
        else
            self:Disable()
        end
        SetEnabledText(self.Text, enabled, { 1.0, 0.82, 0.0 })
    end

    button:Refresh()
    allWidgets[#allWidgets + 1] = button
    return button
end

local function CreateSlider(parent, name, labelText, dbKey, y, minValue, maxValue, step, description, formatValue)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, y)
    label:SetWidth(220)
    label:SetJustifyH("LEFT")

    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -28, y - 5)
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 270, y - 5)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.dbKey = dbKey
    slider.label = label
    slider.formatValue = formatValue or tostring
    AddTooltip(slider, labelText, description)

    _G[name .. "Low"]:SetText(tostring(minValue))
    _G[name .. "High"]:SetText(tostring(maxValue))
    _G[name .. "Text"]:SetText("")

    local function UpdateLabel(value)
        label:SetText(string.format("%s: |cffffffff%s|r", labelText, slider.formatValue(value)))
    end

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor((value / step) + 0.5) * step
        UpdateLabel(value)
        if not self.refreshing then
            ns.Database.Set(self.dbKey, value)
        end
    end)

    slider.Refresh = function(self)
        self.refreshing = true
        local value = ns.Database.Get(self.dbKey) or minValue
        self:SetValue(value)
        UpdateLabel(value)
        self.refreshing = false
    end

    slider.SetSettingEnabled = function(self, enabled)
        if enabled then
            self:Enable()
            self:SetAlpha(1)
        else
            self:Disable()
            self:SetAlpha(0.45)
        end
        SetEnabledText(self.label, enabled, { 1.0, 0.82, 0.0 })
    end

    slider:Refresh()
    allWidgets[#allWidgets + 1] = slider
    return slider
end

local function CreateDropdown(parent, labelText, dbKey, items, y, description)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, y)
    label:SetWidth(220)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)

    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, y + 8)
    dropdown.dbKey = dbKey
    dropdown.label = label
    dropdown.items = items
    UIDropDownMenu_SetWidth(dropdown, 190)
    AddTooltip(dropdown, labelText, description)

    local function Refresh()
        local currentValue = ns.Database.Get(dbKey)
        for _, item in ipairs(items) do
            if item.value == currentValue then
                UIDropDownMenu_SetSelectedValue(dropdown, item.value)
                UIDropDownMenu_SetText(dropdown, item.label)
                return
            end
        end
    end

    UIDropDownMenu_Initialize(dropdown, function()
        local currentValue = ns.Database.Get(dbKey)
        for _, item in ipairs(items) do
            local selectedItem = item
            local info = UIDropDownMenu_CreateInfo()
            info.text = selectedItem.label
            info.value = selectedItem.value
            info.checked = currentValue == selectedItem.value
            info.func = function()
                ns.Database.Set(dbKey, selectedItem.value)
                Refresh()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    dropdown.Refresh = Refresh
    dropdown.SetSettingEnabled = function(self, enabled)
        if enabled then
            UIDropDownMenu_EnableDropDown(self)
            self:SetAlpha(1)
        else
            UIDropDownMenu_DisableDropDown(self)
            self:SetAlpha(0.45)
        end
        SetEnabledText(self.label, enabled, { 1.0, 0.82, 0.0 })
    end

    dropdown:Refresh()
    allWidgets[#allWidgets + 1] = dropdown
    return dropdown
end

local function CreatePage(parent)
    local viewport = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    viewport:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -96)
    viewport:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -42, 126)
    local page = CreateFrame("Frame", nil, viewport)
    page:SetSize(500, 510)
    viewport:SetScrollChild(page)
    viewport:HookScript("OnSizeChanged", function(self, width)
        page:SetWidth(math.max(1, width))
    end)
    viewport:HookScript("OnShow", function(self)
        page:SetWidth(math.max(1, self:GetWidth()))
    end)
    page.viewport = viewport

    local background = page:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(page)
    background:SetColorTexture(0.02, 0.02, 0.02, 0.25)

    viewport:Hide()
    return page
end

local function QualityItems()
    return {
        { value = 0, label = ns.L.QUALITY_ALL or "|cff9d9d9dAll qualities|r" },
        { value = 1, label = ns.L.QUALITY_COMMON or "|cffffffffCommon or better|r" },
        { value = 2, label = ns.L.QUALITY_UNCOMMON or "|cff1eff00Uncommon or better|r" },
        { value = 3, label = ns.L.QUALITY_RARE or "|cff0070ddRare or better|r" },
        { value = 4, label = ns.L.QUALITY_EPIC or "|cffa335eeEpic or better|r" },
        { value = 5, label = ns.L.QUALITY_LEGENDARY or "|cffff8000Legendary only|r" },
    }
end

local function BuildGeneralPage(frame)
    local page = CreatePage(frame)
    pages.general = page

    CreateSection(page, ns.L.SECTION_NOTIFICATIONS or "What should appear?", -16)
    CreateCheckButton(page, ns.L.OPT_ENABLE, "enabled", -42, ns.L.OPT_ENABLE_DESC)
    CreateCheckButton(page, ns.L.OPT_SHOW_ITEMS, "showItems", -92, ns.L.OPT_SHOW_ITEMS_DESC)
    CreateCheckButton(page, ns.L.OPT_SHOW_MONEY, "showMoney", -142, ns.L.OPT_SHOW_MONEY_DESC)
    local minimumQuality = CreateDropdown(
        page,
        ns.L.OPT_MIN_QUALITY,
        "minQuality",
        QualityItems(),
        -196,
        ns.L.OPT_MIN_QUALITY_DESC
    )

    CreateSection(page, ns.L.SECTION_ITEM_DETAILS or "Information shown with items", -258)
    local quantity = CreateCheckButton(page, ns.L.OPT_SHOW_QUANTITY, "showQuantity", -284, ns.L.OPT_SHOW_QUANTITY_DESC)
    local vendor = CreateCheckButton(page, ns.L.OPT_SHOW_VENDOR, "showVendorValue", -334, ns.L.OPT_SHOW_VENDOR_DESC)
    local owned = CreateCheckButton(page, ns.L.OPT_SHOW_OWNED_COUNT, "showOwnedCount", -384, ns.L.OPT_SHOW_OWNED_COUNT_DESC)

    page.itemWidgets = { minimumQuality, quantity, vendor, owned }
end

local function FormatPercent(value)
    return string.format("%d%%", math.floor((value * 100) + 0.5))
end

local function FormatScale(value)
    return string.format("%.1fx", value)
end

local function BuildAppearancePage(frame)
    local page = CreatePage(frame)
    pages.appearance = page

    CreateSection(page, ns.L.SECTION_SIZE or "Text and icon size", -16)
    CreateCheckButton(page, ns.L.OPT_SHOW_ICONS, "showIcons", -42, ns.L.OPT_SHOW_ICONS_DESC)
    CreateSlider(page, "SSLSliderFontSize", ns.L.OPT_FONT_SIZE, "fontSize", -96, 8, 32, 1, ns.L.OPT_FONT_SIZE_DESC)
    local iconSize = CreateSlider(
        page,
        "SSLSliderIconSize",
        ns.L.OPT_ICON_SIZE,
        "iconSize",
        -146,
        12,
        64,
        2,
        ns.L.OPT_ICON_SIZE_DESC
    )
    CreateSlider(page, "SSLSliderScale", ns.L.OPT_SCALE, "scale", -196, 0.5, 3.0, 0.1, ns.L.OPT_SCALE_DESC, FormatScale)

    CreateSection(page, ns.L.SECTION_BACKGROUND or "Background and transparency", -256)
    local showBackground = CreateCheckButton(page, ns.L.OPT_SHOW_BG, "showBackground", -282, ns.L.OPT_SHOW_BG_DESC)
    local rounded = CreateCheckButton(page, ns.L.OPT_BG_ROUNDED, "backgroundRounded", -332, ns.L.OPT_BG_ROUNDED_DESC)
    local backgroundOpacity = CreateSlider(page, "SSLSliderBgOpacity", ns.L.OPT_BG_OPACITY, "backgroundOpacity", -382, 0, 1, 0.1, ns.L.OPT_BG_OPACITY_DESC, FormatPercent)

    page.showBackgroundWidget = showBackground
    page.iconWidgets = { iconSize }
    page.backgroundWidgets = { rounded, backgroundOpacity }
end

local function BuildMovementPage(frame)
    local page = CreatePage(frame)
    pages.movement = page

    CreateSection(page, ns.L.SECTION_POSITION or "Position on your screen", -16)
    local help = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    help:SetPoint("TOPLEFT", page, "TOPLEFT", 24, -43)
    help:SetPoint("TOPRIGHT", page, "TOPRIGHT", -24, -43)
    help:SetJustifyH("LEFT")
    help:SetText(ns.L.POSITION_EXPLANATION or "Use Move Notifications below, drag the blue box, then click Finish Moving.")
    help:SetTextColor(0.9, 0.9, 0.9)

    local resetPosition = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    resetPosition:SetSize(150, 24)
    resetPosition:SetPoint("TOPLEFT", page, "TOPLEFT", 24, -78)
    resetPosition:SetText(ns.L.OPT_RESET_POSITION)
    AddTooltip(resetPosition, ns.L.OPT_RESET_POSITION, ns.L.OPT_RESET_POSITION_DESC)
    resetPosition:SetScript("OnClick", function()
        ns.NotificationManager.ResetAnchor()
        ns.NotificationManager.ShowTestNotifications()
    end)

    CreateSection(page, ns.L.SECTION_MOVEMENT or "Movement and timing", -124)
    local direction = CreateDropdown(page,
        ns.L.OPT_DIRECTION,
        "direction",
        {
            { value = "UP", label = ns.L.OPT_DIRECTION_UP },
            { value = "DOWN", label = ns.L.OPT_DIRECTION_DOWN },
        },
        -150,
        ns.L.OPT_DIRECTION_DESC
    )
    CreateCheckButton(page, ns.L.OPT_STATIC_MODE, "staticMode", -204, ns.L.OPT_STATIC_MODE_DESC)
    CreateSlider(page, "SSLSliderDuration", ns.L.OPT_DURATION, "duration", -258, 0.5, 15, 0.5, ns.L.OPT_DURATION_DESC)
    CreateSlider(page, "SSLSliderMaxVisible", ns.L.OPT_MAX_VISIBLE, "maxVisible", -308, 1, 15, 1, ns.L.OPT_MAX_VISIBLE_DESC)

    page.scrollingWidgets = { direction }
end

local function BuildAdvancedPage(frame)
    local page = CreatePage(frame)
    pages.advanced = page

    CreateSection(page, ns.L.SECTION_ADVANCED or "Optional controls", -16)
    CreateCheckButton(page, ns.L.OPT_MOUSE_INTERACTION, "mouseInteraction", -42, ns.L.OPT_MOUSE_INTERACTION_DESC)
    CreateSlider(page, "SSLSliderRowOpacity", ns.L.OPT_ROW_OPACITY, "rowOpacity", -86, 0.1, 1, 0.1, ns.L.OPT_ROW_OPACITY_DESC, FormatPercent)
    CreateSlider(page, "SSLSliderMaxWidth", ns.L.OPT_MAX_WIDTH, "maxWidth", -130, 160, 800, 20, ns.L.OPT_MAX_WIDTH_DESC)
    CreateSlider(page, "SSLSliderFadeDuration", ns.L.OPT_FADE_DURATION, "fadeDuration", -174, 0.1, 5, 0.1, ns.L.OPT_FADE_DURATION_DESC)
    local travel = CreateSlider(page, "SSLSliderTravel", ns.L.OPT_TRAVEL_DIST, "travelDistance", -218, 10, 300, 10, ns.L.OPT_TRAVEL_DIST_DESC)
    CreateSlider(page, "SSLSliderRowSpacing", ns.L.OPT_ROW_SPACING, "rowSpacing", -262, 0, 30, 1, ns.L.OPT_ROW_SPACING_DESC)
    CreateCheckButton(page, ns.L.OPT_DEBUG, "debug", -306, ns.L.OPT_DEBUG_DESC)
    pages.movement.scrollingWidgets[#pages.movement.scrollingWidgets + 1] = travel

    CreateSection(page, ns.L.SECTION_RESET or "Start over", -358)
    local resetDescription = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resetDescription:SetPoint("TOPLEFT", page, "TOPLEFT", 24, -386)
    resetDescription:SetPoint("TOPRIGHT", page, "TOPRIGHT", -24, -386)
    resetDescription:SetJustifyH("LEFT")
    resetDescription:SetText(ns.L.OPT_RESET_DEFAULTS_DESC)
    resetDescription:SetTextColor(0.72, 0.72, 0.72)

    local resetButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    resetButton:SetSize(170, 24)
    resetButton:SetPoint("TOPLEFT", page, "TOPLEFT", 24, -430)
    resetButton:SetText(ns.L.OPT_RESET_DEFAULTS)
    AddTooltip(resetButton, ns.L.OPT_RESET_DEFAULTS, ns.L.OPT_RESET_DEFAULTS_DESC)
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("SSL_CONFIRM_RESET")
    end)
end

local function RefreshDependencies()
    local generalPage = pages.general
    local appearancePage = pages.appearance
    local movementPage = pages.movement
    if not generalPage or not appearancePage or not movementPage then return end

    local enabled = ns.Database.Get("enabled") and true or false
    for _, widget in ipairs(allWidgets) do
        -- Keep the master switch and diagnostics available while disabled.
        widget:SetSettingEnabled(enabled or widget.dbKey == "enabled" or widget.dbKey == "debug")
    end

    local itemsEnabled = enabled and ns.Database.Get("showItems") and true or false
    for _, widget in ipairs(generalPage.itemWidgets or {}) do
        widget:SetSettingEnabled(itemsEnabled)
    end

    local backgroundEnabled = enabled and ns.Database.Get("showBackground") and true or false
    for _, widget in ipairs(appearancePage.backgroundWidgets or {}) do
        widget:SetSettingEnabled(backgroundEnabled)
    end

    local iconsEnabled = itemsEnabled and ns.Database.Get("showIcons") and true or false
    for _, widget in ipairs(appearancePage.iconWidgets or {}) do
        widget:SetSettingEnabled(iconsEnabled)
    end

    local scrollingEnabled = enabled and not ns.Database.Get("staticMode")
    for _, widget in ipairs(movementPage.scrollingWidgets or {}) do
        widget:SetSettingEnabled(scrollingEnabled)
    end
end

local function SelectPage(pageKey)
    if not pages[pageKey] then return end

    selectedPage = pageKey
    for _, key in ipairs(PAGE_ORDER) do
        if key == pageKey then
            pages[key].viewport:Show()
            tabButtons[key]:Disable()
            tabButtons[key]:LockHighlight()
        else
            pages[key].viewport:Hide()
            tabButtons[key]:Enable()
            tabButtons[key]:UnlockHighlight()
        end
    end
end

local function CreateTabs(frame)
    local tabLabels = {
        general = ns.L.TAB_GENERAL or "General",
        appearance = ns.L.TAB_APPEARANCE or "Appearance",
        movement = ns.L.TAB_MOVEMENT or "Movement & Position",
        advanced = ns.L.TAB_ADVANCED or "Advanced",
    }

    local previous = nil
    for _, key in ipairs(PAGE_ORDER) do
        local tabKey = key
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetSize(120, 26)
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 8, 0)
        else
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -58)
        end
        button:SetText(tabLabels[tabKey])
        button:SetScript("OnClick", function()
            SelectPage(tabKey)
        end)
        tabButtons[tabKey] = button
        previous = button
    end
    local function ResizeTabs()
        local width = math.max(1, (frame:GetWidth() - 80) / #PAGE_ORDER)
        for _, button in pairs(tabButtons) do
            button:SetWidth(width)
        end
    end
    frame:HookScript("OnSizeChanged", ResizeTabs)
    ResizeTabs()
end

local function FinishMovingNotifications()
    ns.NotificationManager.LockAnchor()
    if optionsWindowFrame then
        optionsWindowFrame:Show()
    end
end

local function CreateMoveSaveButton()
    if moveSaveButton then return moveSaveButton end

    local button = CreateFrame("Button", "SimpleScrollingLootSavePositionButton", UIParent, "UIPanelButtonTemplate")
    button:SetSize(150, 32)
    button:SetPoint("BOTTOM", UIParent, "BOTTOM", 95, 80)
    button:SetFrameStrata("TOOLTIP")
    button:SetText(ns.L.OPT_SAVE_POSITION or "Save")
    AddTooltip(button, ns.L.OPT_SAVE_POSITION or "Save", ns.L.OPT_LOCK_ANCHOR_DESC)
    button:SetScript("OnClick", FinishMovingNotifications)
    button:Hide()

    moveSaveButton = button
    return moveSaveButton
end

local function CreateMovePreviewButton()
    if movePreviewButton then return movePreviewButton end

    local button = CreateFrame("Button", "SimpleScrollingLootMovePreviewButton", UIParent, "UIPanelButtonTemplate")
    button:SetSize(180, 32)
    button:SetPoint("RIGHT", CreateMoveSaveButton(), "LEFT", -10, 0)
    button:SetFrameStrata("TOOLTIP")
    button:SetText(ns.L.OPT_TEST_WHILE_MOVING or "Test Notifications")
    AddTooltip(
        button,
        ns.L.OPT_TEST_WHILE_MOVING or "Test Notifications",
        ns.L.OPT_TEST_WHILE_MOVING_DESC or ns.L.OPT_TEST_NOTIF_DESC
    )
    button:SetScript("OnClick", function()
        ns.NotificationManager.ShowTestNotifications()
    end)
    button:Hide()

    movePreviewButton = button
    return movePreviewButton
end

function Options.RefreshPositionControl()
    if not moveButton or not moveHelpText then return end

    if ns.NotificationManager.IsAnchorUnlocked() then
        moveButton:SetText(ns.L.OPT_FINISH_MOVING or "Finish Moving")
        moveHelpText:SetText(ns.L.MOVE_HELP_ACTIVE or "Drag the blue box to the desired position, then click Finish Moving.")
        moveHelpText:SetTextColor(1.0, 0.82, 0.0)
        CreateMoveSaveButton():Show()
        CreateMovePreviewButton():Show()
    else
        moveButton:SetText(ns.L.OPT_MOVE_NOTIFICATIONS or "Move Notifications")
        moveHelpText:SetText(ns.L.MOVE_HELP_IDLE or "Not sure how it will look? Preview your current settings at any time.")
        moveHelpText:SetTextColor(0.72, 0.72, 0.72)
        if moveSaveButton then
            moveSaveButton:Hide()
        end
        if movePreviewButton then
            movePreviewButton:Hide()
        end
    end
end

local function CreateFooter(frame)
    moveHelpText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    moveHelpText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 28, 98)
    moveHelpText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 98)
    moveHelpText:SetJustifyH("LEFT")

    moveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    moveButton:SetSize(165, 26)
    moveButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 28, 60)
    AddTooltip(moveButton, ns.L.OPT_MOVE_NOTIFICATIONS, ns.L.OPT_MOVE_NOTIFICATIONS_DESC)
    moveButton:SetScript("OnClick", function()
        if ns.NotificationManager.IsAnchorUnlocked() then
            FinishMovingNotifications()
        else
            frame:Hide()
            ns.NotificationManager.UnlockAnchor()
        end
    end)

    local previewButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    previewButton:SetSize(165, 26)
    previewButton:SetPoint("LEFT", moveButton, "RIGHT", 10, 0)
    previewButton:SetText(ns.L.OPT_TEST_NOTIF or "Preview Notifications")
    AddTooltip(previewButton, ns.L.OPT_TEST_NOTIF, ns.L.OPT_TEST_NOTIF_DESC)
    previewButton:SetScript("OnClick", function()
        ns.NotificationManager.ShowTestNotifications()
    end)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(110, 26)
    closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 24)
    closeButton:SetText(ns.L.OPT_CLOSE or "Close")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    Options.RefreshPositionControl()
end

local function RefreshAllWidgets()
    for _, widget in ipairs(allWidgets) do
        if widget.Refresh then
            widget:Refresh()
        end
    end
    RefreshDependencies()
    Options.RefreshPositionControl()
end

local function CreateOptionsWindow()
    if optionsWindowFrame then return optionsWindowFrame end

    local frame = CreateFrame("Frame", "SimpleScrollingLootOptionsWindow", UIParent, "DialogBoxFrame")
    frame.name = ns.L.ADDON_NAME or "Simple Scrolling Loot"
    frame:SetSize(760, 680)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    tinsert(UISpecialFrames, "SimpleScrollingLootOptionsWindow")

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -17)
    title:SetText(ns.L.ADDON_NAME or "Simple Scrolling Loot")

    local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    subtitle:SetText(ns.L.OPTIONS_SUBTITLE or "Choose what your loot notifications show and how they look.")
    subtitle:SetTextColor(0.72, 0.72, 0.72)

    BuildGeneralPage(frame)
    BuildAppearancePage(frame)
    BuildMovementPage(frame)
    BuildAdvancedPage(frame)
    CreateTabs(frame)
    CreateFooter(frame)
    SelectPage("general")

    frame:SetScript("OnShow", function()
        RefreshAllWidgets()
        SelectPage(selectedPage or "general")
    end)

    optionsWindowFrame = frame
    return optionsWindowFrame
end

function Options.Initialize()
    local panel = CreateOptionsWindow()
    panel:Hide()

    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function" then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        blizzardOptionsCategory = category
    elseif type(InterfaceOptions_AddCategory) == "function" then
        InterfaceOptions_AddCategory(panel)
    end

    ns.Database.RegisterCallback("*", function(key)
        if key == "__reset__" then
            RefreshAllWidgets()
            return
        end
        if optionsWindowFrame and optionsWindowFrame:IsShown() then
            RefreshDependencies()
        end
    end)
end

function Options.Open()
    local window = CreateOptionsWindow()
    if window:IsShown() then
        window:Hide()
    else
        window:Show()
    end
end
