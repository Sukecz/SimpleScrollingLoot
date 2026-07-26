local addonName, ns = ...

ns.ItemResolver = {}

local ItemResolver = ns.ItemResolver
local pendingQueue = {}
local requestedItems = {}
local TIMEOUT_SECONDS = 5.0

local function GetRequestKey(itemRecord)
    return itemRecord.itemID or itemRecord.itemLink
end

local function HasPendingRequest(requestKey)
    for _, record in ipairs(pendingQueue) do
        if GetRequestKey(record) == requestKey then
            return true
        end
    end
    return false
end

local function FinishRecord(record, callback)
    record.callback = nil
    if callback then
        callback(record)
    end
end

local function PopulateRecord(record)
    local name, link, quality, _, _, _, _, _, _, texture, sellPrice =
        ns.ApiCompat.GetItemInfo(record.itemLink)
    if not name then
        return false
    end

    record.name = name
    record.itemLink = link or record.itemLink
    record.quality = quality or 1
    record.texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark"
    record.sellPrice = (sellPrice or 0) * (record.quantity or 1)
    record.resolved = true
    return true
end

local function EnsureTimeoutCheck()
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(TIMEOUT_SECONDS, function()
            ItemResolver.ProcessPending()
        end)
    end
end

function ItemResolver.Resolve(itemRecord, callback)
    if not itemRecord or not itemRecord.itemLink then return end

    if PopulateRecord(itemRecord) then
        FinishRecord(itemRecord, callback)
        return itemRecord
    end

    itemRecord.requestedTime = GetTime()
    itemRecord.callback = callback
    table.insert(pendingQueue, itemRecord)

    local requestKey = GetRequestKey(itemRecord)
    if not requestedItems[requestKey] then
        requestedItems[requestKey] = true
        ns.ApiCompat.RequestItemData(itemRecord.itemLink)
        ns.Debug.Log("Item %s not cached yet, requested server load.", tostring(itemRecord.itemLink))
    end
    EnsureTimeoutCheck()

    return nil
end

function ItemResolver.ProcessPending(now)
    if #pendingQueue == 0 then return end

    now = now or GetTime()
    local i = 1
    while i <= #pendingQueue do
        local rec = pendingQueue[i]
        local requestKey = GetRequestKey(rec)
        if PopulateRecord(rec) then
            table.remove(pendingQueue, i)
            local callback = rec.callback
            if not HasPendingRequest(requestKey) then
                requestedItems[requestKey] = nil
            end
            FinishRecord(rec, callback)
        elseif (now - rec.requestedTime) >= TIMEOUT_SECONDS then
            table.remove(pendingQueue, i)
            rec.name = rec.itemLink
            rec.quality = 1
            rec.texture = "Interface\\Icons\\INV_Misc_QuestionMark"
            rec.sellPrice = 0
            rec.resolved = false

            local callback = rec.callback
            if not HasPendingRequest(requestKey) then
                requestedItems[requestKey] = nil
            end
            FinishRecord(rec, callback)
        else
            i = i + 1
        end
    end
end

function ItemResolver.OnItemInfoReceived(itemID, success)
    if success == false then
        ns.Debug.Log("Item data request failed for item ID %s; waiting for timeout.", tostring(itemID))
    end
    ItemResolver.ProcessPending()
end

function ItemResolver.GetPendingCount()
    return #pendingQueue
end
