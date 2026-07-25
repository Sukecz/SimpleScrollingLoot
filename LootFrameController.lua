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
    local numLootItems = ns.ApiCompat.GetNumLootItems()
    if numLootItems == 0 then
        return true
    end

    -- Scan loot slots for special items (quest items, locked/BoP items).
    -- All loot APIs are routed through ApiCompat for safe version-agnostic access.
    for slot = 1, numLootItems do
        local texture, item, quantity, currency, quality, locked, isQuest = ns.ApiCompat.GetLootSlotInfo(slot)
        if isQuest or locked then
            return true
        end

        local link = ns.ApiCompat.GetLootSlotLink(slot)
        if link then
            local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType = ns.ApiCompat.GetItemInfo(link)
            -- Bind on Pickup (bindType == 1 or LE_ITEM_BIND_ON_PICKUP)
            if bindType == 1 then
                return true
            end
        end
    end

    -- Show the frame for group/master loot so players can interact normally.
    local lootMethod = ns.ApiCompat.GetLootMethod()
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
            if mode == "HIDE_AUTO" and not isAutoLoot then return end

            -- Defer Hide() to the next frame tick.
            -- Hiding inside OnShow can cause Blizzard layout scripts to see an
            -- inconsistent state and raise UI taint.  C_Timer.After(0) lets the
            -- current OnShow execution path finish before we intervene.
            C_Timer.After(0, function()
                if LootFrame:IsShown() then
                    ns.Debug.Log("Hiding LootFrame (mode=%s)", mode)
                    LootFrame:Hide()
                end
            end)
        end)
    end
end
