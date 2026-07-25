local addonName, ns = ...

ns.NotificationRow = {}

local NotificationRow = ns.NotificationRow
local rowIdCounter = 0

function NotificationRow.Create(parent)
    rowIdCounter = rowIdCounter + 1
    local frame = CreateFrame("Button", "SimpleScrollingLootRow" .. rowIdCounter, parent)
    frame:SetSize(400, 28)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    frame:RegisterForClicks("AnyUp")

    -- Background texture
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetColorTexture(0, 0, 0, 0.35)
    bg:Hide()
    frame.bg = bg

    -- Icon texture
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", frame, "LEFT", 4, 0)
    frame.icon = icon

    -- Main text (Item Name or Money String)
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
        if self.itemLink and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)

    frame:SetScript("OnLeave", function(self)
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
            self.mainText:SetPoint("LEFT", self, "LEFT", 4, 0)
        end

        -- Font sizing
        local fontPath, _, fontFlags = GameFontHighlight:GetFont()
        self.mainText:SetFont(fontPath, fontSize, fontFlags)
        self.quantityText:SetFont(fontPath, fontSize, fontFlags)
        self.vendorText:SetFont(fontPath, math.max(9, fontSize - 2), fontFlags)

        -- Background
        if config.showBackground then
            self.bg:SetColorTexture(0, 0, 0, config.backgroundOpacity or 0.35)
            self.bg:Show()
        else
            self.bg:Hide()
        end

        if record.kind == "item" then
            local r, g, b = ns.ApiCompat.GetItemQualityColor(record.quality)
            self.mainText:SetText(record.name or record.itemLink or "Unknown Item")
            self.mainText:SetTextColor(r, g, b, 1.0)

            -- Quantity (do not show x1)
            if config.showQuantity and record.quantity and record.quantity > 1 then
                self.quantityText:SetText("x" .. record.quantity)
                self.quantityText:Show()
            else
                self.quantityText:Hide()
                self.quantityText:SetText("")
            end

            -- Vendor Value
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
        end

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
