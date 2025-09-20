local ADDON_NAME = "GamePadHelper_AutoCharge"
local ADDON_VERSION = 1.00

local function GetSlotName(equipSlot)
    if equipSlot == EQUIP_SLOT_MAIN_HAND then
        return "main hand"
    elseif equipSlot == EQUIP_SLOT_OFF_HAND then
        return "off hand"
    elseif equipSlot == EQUIP_SLOT_BACKUP_MAIN then
        return "backup main hand"
    elseif equipSlot == EQUIP_SLOT_BACKUP_OFF then
        return "backup off hand"
    else
        return "unknown slot"
    end
end

local function FindSoulGem()
    -- Find the best soul gem in inventory
    local bestGem = nil
    local bestBagId, bestSlotIndex = nil, nil

    local bagId = BAG_BACKPACK
    for slotIndex = 1, GetBagSize(bagId) do
        local itemLink = GetItemLink(bagId, slotIndex)
        if itemLink and itemLink ~= "" then
            local itemType = GetItemLinkItemType(itemLink)
            if itemType == ITEMTYPE_SOUL_GEM then
                local soulGemType, gemLevel, isFilledSoulGem = GetSoulGemInfo(bagId, slotIndex)
                if isFilledSoulGem then
                    if not bestGem or gemLevel > bestGem then
                        bestGem = gemLevel
                        bestBagId = bagId
                        bestSlotIndex = slotIndex
                    end
                end
            end
        end
    end

    return bestBagId, bestSlotIndex
end

local function AutoCharge()
    local savedVars = _G["GamePadHelper_SavedVars"]
    if not savedVars or not savedVars.autoChargeEnabled then
        return
    end

    -- Check all equipped weapons for charge (main + backup)
    for equipSlot = EQUIP_SLOT_MAIN_HAND, EQUIP_SLOT_BACKUP_OFF do
        local charges, maxCharges = GetChargeInfoForItem(BAG_WORN, equipSlot)
        if charges and maxCharges and maxCharges > 0 then
            local chargePercentage = (charges / maxCharges) * 100
            -- Only charge if below 25%
            if chargePercentage < 25 then
                local gemBagId, gemSlotIndex = FindSoulGem()
                if gemBagId and gemSlotIndex then
                    ChargeItemWithSoulGem(BAG_WORN, equipSlot, gemBagId, gemSlotIndex)
                    d("|c3399FFGamePadHelper|r: " .. GetSlotName(equipSlot) .. " charged (" .. string.format("%.1f", chargePercentage) .. "% → 100%)")
                end
            end
        end
    end
end

local function OnCombatStateChanged(event, inCombat)
    -- Check for weapon charge when leaving combat
    if not inCombat then
        zo_callLater(AutoCharge, 1000)
    end
end

local function OnAddonLoaded(event, addonName)
    if addonName ~= ADDON_NAME then return end
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_COMBAT_STATE, OnCombatStateChanged)

    -- Set global flag to indicate module is loaded
    _G["GamePadHelper_AutoCharge_Loaded"] = true
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)