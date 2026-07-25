local addonName, ns = ...

ns.NotificationRow = {}

local NotificationRow = ns.NotificationRow
local rowIdCounter = 0

local ROUNDED_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

function NotificationRow.Create(parent)
    rowIdCounter = rowIdCounter + 1
    local frame = CreateFrame("Button", "SimpleScrollingLootRow" .. rowIdCounter, parent, "BackdropTemplate")
    frame:SetSize(200, 28)
    frame:SetFrameStrata("HIGH")
    -- Mouse interaction is disabled by default so notifications do not block
    -- camera rotation or character clicks.  OnEnter re-enables it temporarily
    -- to allow tooltip and shift-click behaviour.
    frame:EnableMouse(false)
    frame:RegisterForClicks("AnyUp")

    -- Background texture
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetColorTexture(0, 0, 0, 0.35)
    bg:Hide()
    frame.bg = bg

    function frame:ApplyBackground(config)
        local opacity = config.backgroundOpacity or 0.35

        self.bg:ClearAllPoints()
        self.bg:SetAllPoints(self)

        if not config.showBackground then
            self.bg:Hide()
            self:SetBackdrop(nil)
            return
        end

        if config.backgroundRounded then
            self.bg:Hide()
            self:SetBackdrop(ROUNDED_BACKDROP)
            self:SetBackdropColor(0.0, 0.0, 0.0, opacity)
            self:SetBackdropBorderColor(1.0, 1.0, 1.0, opacity)
            return
        end

        self:SetBackdrop(nil)
        self.bg:SetColorTexture(0.0, 0.0, 0.0, opacity)
        self.bg:Show()
    end

    -- Icon texture
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", frame, "LEFT", 4, 0)
    frame.icon = icon

    -- Main text (Item Name, Money String, or Honor String)
    local mainText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    mainText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    mainText:SetJustifyH("LEFT")
    frame.mainText = mainText

    -- Quantity text
    local quantityText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    quantityText:SetPoint("LEFT", mainText, "RIGHT", 6, 0)
    quantityText:SetTextColor(0.8, 0.8, 0.8, 1.0)
    frame.quantityText = quantityText

    -- Vendor value text
    local vendorText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    vendorText:SetPoint("LEFT", quantityText, "RIGHT", 10, 0)
    vendorText:SetTextColor(0.7, 0.7, 0.7, 1.0)
    frame.vendorText = vendorText

    -- Tooltip events
    frame:SetScript("OnEnter", function(self)
        -- Enable mouse on hover so the tooltip and click handler work,
        -- without blocking the camera when the cursor is not over the row.
        self:EnableMouse(true)
        if self.itemLink and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)

    frame:SetScript("OnLeave", function(self)
        self:EnableMouse(false)
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    -- Click event (standard item link chat insertion if shift-clicked)
    frame:SetScript("OnClick", function(self, button)
        if self.itemLink and IsModifiedClick("CHATLINK") then
            HandleModifiedItemClick(self.itemLink)
        end
    end)

    function frame:SetRecord(record, config)
        self.record = record
        self.itemLink = record.itemLink

        local iconSize = config.iconSize or 24
        local fontSize = config.fontSize or 14

        self:SetHeight(iconSize + 4)

        -- Icon
        if config.showIcons and record.texture then
            self.icon:SetTexture(record.texture)
            self.icon:SetSize(iconSize, iconSize)
            self.icon:Show()
            self.mainText:SetPoint("LEFT", self.icon, "RIGHT", 6, 0)
        else
            self.icon:Hide()
            self.mainText:SetPoint("LEFT", self, "LEFT", 6, 0)
        end

        -- Font sizing
        local fontPath, _, fontFlags = GameFontHighlight:GetFont()
        self.mainText:SetFont(fontPath, fontSize, fontFlags)
        self.quantityText:SetFont(fontPath, fontSize, fontFlags)
        -- Scale vendor text proportionally; no arbitrary fixed floor.
        self.vendorText:SetFont(fontPath, math.max(6, fontSize - 2), fontFlags)

        self:ApplyBackground(config)

        if record.kind == "item" then
            local r, g, b = ns.ApiCompat.GetItemQualityColor(record.quality)
            self.mainText:SetText(record.name or record.itemLink or "Unknown Item")
            self.mainText:SetTextColor(r, g, b, 1.0)

            if config.showQuantity and record.quantity and record.quantity > 1 then
                self.quantityText:SetText("x" .. record.quantity)
                self.quantityText:Show()
            else
                self.quantityText:Hide()
                self.quantityText:SetText("")
            end

            if config.showVendorValue and record.sellPrice and record.sellPrice > 0 then
                self.vendorText:SetText(ns.ApiCompat.FormatMoney(record.sellPrice))
                self.vendorText:Show()
            else
                self.vendorText:Hide()
                self.vendorText:SetText("")
            end

        elseif record.kind == "money" then
            self.mainText:SetText(record.coinIconsText or record.formattedText or "Money")
            self.mainText:SetTextColor(1.0, 1.0, 1.0, 1.0)
            self.quantityText:Hide()
            self.vendorText:Hide()

        elseif record.kind == "honor" then
            self.mainText:SetText(record.formattedText or "+ Honor")
            self.mainText:SetTextColor(1.0, 0.82, 0.0, 1.0) -- Gold/yellow honor color
            self.quantityText:Hide()
            self.vendorText:Hide()
        end

        -- Calculate content width dynamically to center row perfectly on anchor
        local mainWidth = self.mainText:GetStringWidth() or 0
        local quantWidth = self.quantityText:IsShown() and (self.quantityText:GetStringWidth() or 0) or 0
        local vendorWidth = self.vendorText:IsShown() and (self.vendorText:GetStringWidth() or 0) or 0
        local iconWidth = self.icon:IsShown() and iconSize or 0

        local contentWidth = iconWidth
        if iconWidth > 0 then contentWidth = contentWidth + 6 end
        contentWidth = contentWidth + mainWidth
        if quantWidth > 0 then contentWidth = contentWidth + 6 + quantWidth end
        if vendorWidth > 0 then contentWidth = contentWidth + 10 + vendorWidth end

        self:SetWidth(math.max(80, contentWidth + 12))

        self:SetAlpha(1.0)
        self:Show()
    end

    function frame:Reset()
        self.record = nil
        self.itemLink = nil
        self:Hide()
        self:ClearAllPoints()
        self:SetAlpha(1.0)
    end

    return frame
end
