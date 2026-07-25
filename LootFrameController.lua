local addonName, ns = ...

ns.LootFrameController = {}

local LootFrameController = ns.LootFrameController
local isHooked = false

-- Failsafe check: evaluate if loot window contains special/protected items (BoP, Quest items, Master loot)
local function ShouldForceShowLootFrame()
    -- Bypass modifier key check
    local bypassMod = ns.Database.Get("lootFrameBypassModifier") or "SHIFT"
    if ns.ApiCompat.IsBypassModifierPressed(bypassMod) then
        return true
    end

    -- Check if loot is active
    local numLootItems = GetNumLootItems and GetNumLootItems() or 0
    if numLootItems == 0 then
        return true
    end

    -- Scan loot slots for special items
    for slot = 1, numLootItems do
        if GetLootSlotInfo then
            local texture, item, quantity, currency, quality, locked, isQuest, questID, isActive = GetLootSlotInfo(slot)
            if isQuest or locked then
                return true
            end
        end
        if GetLootSlotLink then
            local link = GetLootSlotLink(slot)
            if link then
                local _, _, quality, _, _, _, _, _, _, _, _, _, _, bindType = ns.ApiCompat.GetItemInfo(link)
                -- Bind on Pickup (bindType == 1 or LE_ITEM_BIND_ON_PICKUP)
                if bindType == 1 then
                    return true
                end
            end
        end
    end

    -- Check loot threshold / group loot / master loot
    local lootMethod = GetLootMethod and GetLootMethod()
    if lootMethod and lootMethod ~= "freeforall" and lootMethod ~= "personalloot" then
        return true
    end

    return false
end

function LootFrameController.Initialize()
    if isHooked then return end
    isHooked = true

    if LootFrame then
        LootFrame:HookScript("OnShow", function(self)
            if not ns.Database.Get("enabled") then return end

            local mode = ns.Database.Get("lootFrameMode") or "DEFAULT"
            if mode == "DEFAULT" then return end

            if ShouldForceShowLootFrame() then
                ns.Debug.Log("LootFrame bypass or safety check triggered; showing Blizzard LootFrame.")
                return
            end

            local isAutoLoot = (GetCVar("autoLootDefault") == "1") or IsModifiedClick("AUTOLOOTTOGGLE")
            if mode == "HIDE_AUTO" and isAutoLoot then
                ns.Debug.Log("Hiding LootFrame (HIDE_AUTO mode)")
                self:Hide()
            elseif mode == "ALWAYS_HIDE" then
                ns.Debug.Log("Hiding LootFrame (ALWAYS_HIDE mode)")
                self:Hide()
            end
        end)
    end
end
