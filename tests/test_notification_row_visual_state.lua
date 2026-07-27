-- Regression test for content refreshes preserving manager-owned visual state.
-- Run with: lua tests/test_notification_row_visual_state.lua

local function NewRegion()
    local region = {
        shown = true,
        text = "",
    }

    function region:SetAllPoints() end
    function region:ClearAllPoints() end
    function region:SetColorTexture() end
    function region:SetTexture() end
    function region:SetSize() end
    function region:SetPoint() end
    function region:SetJustifyH() end
    function region:SetWordWrap() end
    function region:SetMaxLines() end
    function region:SetTextColor() end
    function region:SetFont() end
    function region:SetWidth() end
    function region:SetText(text) self.text = text or "" end
    function region:GetStringWidth() return #self.text * 8 end
    function region:Show() self.shown = true end
    function region:Hide() self.shown = false end
    function region:IsShown() return self.shown end

    return region
end

function CreateFrame()
    local frame = {
        alpha = 1,
        shown = false,
    }

    function frame:SetSize() end
    function frame:SetFrameStrata() end
    function frame:EnableMouse() end
    function frame:RegisterForClicks() end
    function frame:CreateTexture() return NewRegion() end
    function frame:CreateFontString() return NewRegion() end
    function frame:SetScript() end
    function frame:SetBackdrop() end
    function frame:SetBackdropColor() end
    function frame:SetBackdropBorderColor() end
    function frame:SetHeight() end
    function frame:SetWidth() end
    function frame:SetAlpha(alpha) self.alpha = alpha end
    function frame:GetAlpha() return self.alpha end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    function frame:IsShown() return self.shown end

    return frame
end

GameFontHighlight = {
    GetFont = function()
        return "Fonts\\FRIZQT__.TTF", 14, ""
    end,
}

local ns = {
    ApiCompat = {
        GetItemQualityColor = function() return 1, 1, 1 end,
    },
}

assert(loadfile("NotificationRow.lua"))("SimpleScrollingLoot", ns)

local row = ns.NotificationRow.Create({})
row:SetAlpha(0.25)
row:Hide()
row:SetRecord({
    kind = "money",
    formattedText = "12 Silver",
}, {
    showIcons = true,
    iconSize = 24,
    fontSize = 14,
    maxWidth = 480,
    rowOpacity = 1,
})

assert(row:GetAlpha() == 0.25, "content refresh must preserve the current fade alpha")
assert(not row:IsShown(), "content setup must not show a pooled row before positioning")

print("Notification row visual-state tests passed")
