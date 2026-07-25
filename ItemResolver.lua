local addonName, ns = ...

ns.ItemResolver = {}

local ItemResolver = ns.ItemResolver
local pendingQueue = {}
local TIMEOUT_SECONDS = 5.0

function ItemResolver.Resolve(itemRecord, callback)
    if not itemRecord or not itemRecord.itemLink then return end

    local name, link, quality, iLevel, minLevel, itemType, itemSubType, stackCount, equipLoc, texture, sellPrice = ns.ApiCompat.GetItemInfo(itemRecord.itemLink)

    if name then
        itemRecord.name = name
        itemRecord.quality = quality or 1
        itemRecord.texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark"
        itemRecord.sellPrice = (sellPrice or 0) * (itemRecord.quantity or 1)
        itemRecord.resolved = true

        if callback then
            callback(itemRecord)
        end
        return itemRecord
    end

    -- Item is not cached yet! Queue item record.
    itemRecord.requestedTime = GetTime()
    itemRecord.callback = callback
    table.insert(pendingQueue, itemRecord)

    -- Request item load from WoW server API
    ns.ApiCompat.RequestItemData(itemRecord.itemLink)
    ns.Debug.Log("Item %s not cached yet, requested server load.", tostring(itemRecord.itemLink))

    return nil
end

function ItemResolver.OnItemInfoReceived(itemID)
    if #pendingQueue == 0 then return end

    local now = GetTime()
    local i = 1
    while i <= #pendingQueue do
        local rec = pendingQueue[i]
        local isMatch = false

        if rec.itemID and rec.itemID == itemID then
            isMatch = true
        else
            -- Check if item is now cached
            local name = ns.ApiCompat.GetItemInfo(rec.itemLink)
            if name then isMatch = true end
        end

        if isMatch then
            table.remove(pendingQueue, i)
            local name, link, quality, _, _, _, _, _, _, texture, sellPrice = ns.ApiCompat.GetItemInfo(rec.itemLink)
            rec.name = name or rec.itemLink
            rec.quality = quality or 1
            rec.texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark"
            rec.sellPrice = (sellPrice or 0) * (rec.quantity or 1)
            rec.resolved = true

            if rec.callback then
                rec.callback(rec)
            end
        elseif (now - rec.requestedTime) > TIMEOUT_SECONDS then
            -- Timed out: produce fallback notification
            table.remove(pendingQueue, i)
            rec.name = rec.itemLink
            rec.quality = 1
            rec.texture = "Interface\\Icons\\INV_Misc_QuestionMark"
            rec.sellPrice = 0
            rec.resolved = false

            if rec.callback then
                rec.callback(rec)
            end
        else
            i = i + 1
        end
    end
end
