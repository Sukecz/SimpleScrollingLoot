local addonName, ns = ...

ns.NotificationManager = {}

local NotificationManager = ns.NotificationManager
local anchorFrame = nil
local activeRows = {}
local rowPool = {}
local animDriverFrame = nil

local function GetRowConfig()
    return {
        showIcons = ns.Database.Get("showIcons"),
        showQuantity = ns.Database.Get("showQuantity"),
        showVendorValue = ns.Database.Get("showVendorValue"),
        showBackground = ns.Database.Get("showBackground"),
        backgroundOpacity = ns.Database.Get("backgroundOpacity"),
        backgroundRounded = ns.Database.Get("backgroundRounded"),
        iconSize = ns.Database.Get("iconSize") or 24,
        fontSize = ns.Database.Get("fontSize") or 14,
        scale = ns.Database.Get("scale") or 1.0,
    }
end

local function CreateAnchor()
    if anchorFrame then return anchorFrame end

    anchorFrame = CreateFrame("Frame", "SimpleScrollingLootAnchor", UIParent)
    anchorFrame:SetSize(220, 30)

    local savedAnchor = ns.Database.Get("anchor") or { point = "CENTER", relativePoint = "CENTER", x = 0, y = 120 }
    anchorFrame:SetPoint(savedAnchor.point or "CENTER", UIParent, savedAnchor.relativePoint or "CENTER", savedAnchor.x or 0, savedAnchor.y or 120)
    anchorFrame:SetMovable(true)
    anchorFrame:EnableMouse(false)
    anchorFrame:SetClampedToScreen(true)

    -- Anchor visual backdrop when unlocked
    local bg = anchorFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(anchorFrame)
    bg:SetColorTexture(0, 0.4, 0.8, 0.5)
    bg:Hide()
    anchorFrame.bg = bg

    local title = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    title:SetPoint("CENTER", anchorFrame, "CENTER", 0, 0)
    title:SetText(ns.L.ANCHOR_TITLE or "Simple Scrolling Loot")
    title:Hide()
    anchorFrame.title = title

    anchorFrame:RegisterForDrag("LeftButton")
    anchorFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    anchorFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        ns.Database.Set("anchor", {
            point = point,
            relativePoint = relativePoint,
            x = math.floor(x + 0.5),
            y = math.floor(y + 0.5),
        })
    end)

    return anchorFrame
end

local function GetRowFromPool()
    if #rowPool > 0 then
        local row = table.remove(rowPool)
        return row
    end
    return ns.NotificationRow.Create(CreateAnchor())
end

local function RecycleRow(row)
    row:Reset()
    table.insert(rowPool, row)
end

function NotificationManager.Initialize()
    CreateAnchor()

    -- Animation driver frame
    animDriverFrame = CreateFrame("Frame", "SimpleScrollingLootAnimDriver", UIParent)
    animDriverFrame:SetScript("OnUpdate", function(self, elapsed)
        NotificationManager.OnUpdate(elapsed)
    end)

    local appearanceSettings = {
        "showBackground",
        "backgroundOpacity",
        "backgroundRounded",
    }
    for _, key in ipairs(appearanceSettings) do
        ns.Database.RegisterCallback(key, NotificationManager.RefreshActiveRows)
    end
end

function NotificationManager.AddNotification(record)
    if not ns.Database.Get("enabled") then return end
    if not record then return end

    -- Filter checks
    if record.kind == "item" then
        if not ns.Database.Get("showItems") then return end
        local minQuality = ns.Database.Get("minQuality") or 0
        if (record.quality or 1) < minQuality then
            ns.Debug.Log("Item %s filtered out by minQuality (%d < %d)", tostring(record.name), record.quality or 1, minQuality)
            return
        end
    elseif record.kind == "money" then
        if not ns.Database.Get("showMoney") then return end
    elseif record.kind == "honor" then
        if not ns.Database.Get("showHonor") then return end
    end

    CreateAnchor()
    local config = GetRowConfig()

    local row = GetRowFromPool()
    row:SetScale(config.scale)
    row:SetRecord(record, config)

    local entry = {
        row = row,
        spawnTime = GetTime(),
        duration = ns.Database.Get("duration") or 4.0,
        fadeDuration = ns.Database.Get("fadeDuration") or 0.8,
        travelDistance = ns.Database.Get("travelDistance") or 90,
        -- baseOffset is assigned by UpdateLayout() after insert.
        baseOffset = 0,
    }

    table.insert(activeRows, 1, entry)

    -- Limit visible rows
    local maxVisible = ns.Database.Get("maxVisible") or 6
    while #activeRows > maxVisible do
        local oldest = table.remove(activeRows)
        RecycleRow(oldest.row)
    end

    NotificationManager.UpdateLayout()
end

function NotificationManager.RefreshActiveRows()
    local config = GetRowConfig()
    for _, entry in ipairs(activeRows) do
        entry.row:SetScale(config.scale)
        entry.row:SetRecord(entry.row.record, config)
    end
    NotificationManager.UpdateLayout()
end

function NotificationManager.UpdateLayout()
    local direction = ns.Database.Get("direction") or "UP"
    local rowSpacing = ns.Database.Get("rowSpacing") or 4
    local staticMode = ns.Database.Get("staticMode") or false
    local dirMultiplier = (direction == "UP") and 1 or -1

    local currentOffset = 0
    for i, entry in ipairs(activeRows) do
        local row = entry.row
        local rowHeight = row:GetHeight()

        row:ClearAllPoints()

        if staticMode then
            -- In static mode rows are stacked from the anchor; no animation offset.
            local yPos = (i - 1) * (rowHeight + rowSpacing) * dirMultiplier
            entry.baseOffset = yPos
            row:SetPoint("CENTER", anchorFrame, "CENTER", 0, yPos)
        else
            -- Record the base slot position; OnUpdate will add the travel offset on top.
            entry.baseOffset = currentOffset * dirMultiplier
            currentOffset = currentOffset + rowHeight + rowSpacing
            -- Position will be applied by the next OnUpdate tick.
        end
    end
end

function NotificationManager.OnUpdate(elapsed)
    if #activeRows == 0 then return end

    local now = GetTime()
    local staticMode = ns.Database.Get("staticMode") or false

    local needsLayoutUpdate = false
    local i = 1
    while i <= #activeRows do
        local entry = activeRows[i]
        local age = now - entry.spawnTime
        local totalDuration = entry.duration
        local fadeDuration = entry.fadeDuration

        if age >= totalDuration then
            RecycleRow(entry.row)
            table.remove(activeRows, i)
            needsLayoutUpdate = true
            -- Do not increment i; the next entry slides into index i.
        else
            -- Fade: full opacity for most of the lifetime, fade at the end.
            local remaining = totalDuration - age
            local alpha = (remaining < fadeDuration)
                and math.max(0.0, remaining / fadeDuration)
                or 1.0
            entry.row:SetAlpha(alpha)

            -- Smooth linear travel: interpolate from baseOffset to baseOffset+travelDistance.
            -- baseOffset is set by UpdateLayout() and does not change here.
            if not staticMode then
                local progress = math.min(1.0, age / totalDuration)
                local animY = entry.baseOffset + progress * entry.travelDistance
                entry.row:ClearAllPoints()
                entry.row:SetPoint("CENTER", anchorFrame, "CENTER", 0, animY)
            end

            i = i + 1
        end
    end

    -- Rebuild layout once after removing expired rows, not inside the loop.
    if needsLayoutUpdate then
        NotificationManager.UpdateLayout()
    end
end

function NotificationManager.UnlockAnchor()
    local anchor = CreateAnchor()
    anchor:EnableMouse(true)
    anchor.bg:Show()
    anchor.title:Show()
    ns.NotificationManager.ShowTestNotifications()
end

function NotificationManager.LockAnchor()
    local anchor = CreateAnchor()
    anchor:EnableMouse(false)
    anchor.bg:Hide()
    anchor.title:Hide()
end

function NotificationManager.ShowTestNotifications()
    local testItems = {
        { kind = "item", name = ns.L.TEST_ITEM_1 or "Runecloth", itemLink = "|cffffffff|Hitem:14047:0:0:0:0:0:0:0|h[Runecloth]|h|r", quality = 1, quantity = 5, sellPrice = 250, texture = "Interface\\Icons\\INV_Fabric_PurpleRag_01" },
        { kind = "item", name = ns.L.TEST_ITEM_2 or "Heavy Leather", itemLink = "|cffffffff|Hitem:4234:0:0:0:0:0:0:0|h[Heavy Leather]|h|r", quality = 1, quantity = 2, sellPrice = 150, texture = "Interface\\Icons\\INV_Misc_LeatherScrap_03" },
        { kind = "item", name = ns.L.TEST_ITEM_3 or "Arcanite Bar", itemLink = "|cffa335ee|Hitem:12360:0:0:0:0:0:0:0|h[Arcanite Bar]|h|r", quality = 4, quantity = 1, sellPrice = 50000, texture = "Interface\\Icons\\INV_Misc_Bar_03" },
        { kind = "money", copper = 12580, formattedText = ns.ApiCompat.FormatMoney(12580), coinIconsText = ns.ApiCompat.GetCoinIconsText(12580), texture = "Interface\\Icons\\INV_Misc_Coin_01" },
        { kind = "honor", amount = 142, formattedText = "+142 Honor", texture = "Interface\\Icons\\PVPCurrency_Honor_Horde" },
    }

    for _, rec in ipairs(testItems) do
        NotificationManager.AddNotification(rec)
    end
end
