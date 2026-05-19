local function GetSlotName(equipSlot)
    if equipSlot == EQUIP_SLOT_MAIN_HAND then
        return GetString(SI_GPH_AUTOCHARGE_MAIN_HAND)
    elseif equipSlot == EQUIP_SLOT_OFF_HAND then
        return GetString(SI_GPH_AUTOCHARGE_OFF_HAND)
    elseif equipSlot == EQUIP_SLOT_BACKUP_MAIN then
        return GetString(SI_GPH_AUTOCHARGE_BACKUP_MAIN)
    elseif equipSlot == EQUIP_SLOT_BACKUP_OFF then
        return GetString(SI_GPH_AUTOCHARGE_BACKUP_OFF)
    else
        return GetString(SI_GPH_AUTOCHARGE_UNKNOWN_SLOT)
    end
end

local function FindSoulGem()
    -- Find the best soul gem in inventory
    local bestGem = nil
    local bestBagId, bestSlotIndex = nil, nil

    local bagId = BAG_BACKPACK
    for slotIndex = 0, GetBagSize(bagId) - 1 do
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

local WEAPON_SLOTS = {
    EQUIP_SLOT_MAIN_HAND,
    EQUIP_SLOT_OFF_HAND,
    EQUIP_SLOT_BACKUP_MAIN,
    EQUIP_SLOT_BACKUP_OFF,
}

local function AutoCharge()
    local savedVars = _G["GamePadHelper_SavedVars"]
    if not savedVars or not savedVars.autoChargeEnabled then
        return
    end

    for _, equipSlot in ipairs(WEAPON_SLOTS) do
        local charges, maxCharges = GetChargeInfoForItem(BAG_WORN, equipSlot)
        if charges and maxCharges and maxCharges > 0 then
            local chargePercentage = (charges / maxCharges) * 100
            local threshold = savedVars.autoChargeThreshold or 25
            if chargePercentage < threshold then
                local gemBagId, gemSlotIndex = FindSoulGem()
                if gemBagId and gemSlotIndex then
                    ChargeItemWithSoulGem(BAG_WORN, equipSlot, gemBagId, gemSlotIndex)
                    local slotName = GetSlotName(equipSlot)
                    zo_callLater(function()
                        local newCharges, newMaxCharges = GetChargeInfoForItem(BAG_WORN, equipSlot)
                        local newPercentage = (newMaxCharges and newMaxCharges > 0) and (newCharges / newMaxCharges * 100) or 0
                        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT)
                        messageParams:SetText(zo_strformat(SI_GPH_AUTOCHARGE_CHARGED, slotName, string.format("%.0f", newPercentage)))
                        CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
                    end, 200)
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

local function OnAddonLoaded(event, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("AutoCharge", EVENT_ADD_ON_LOADED)
    EVENT_MANAGER:RegisterForEvent("AutoCharge", EVENT_PLAYER_COMBAT_STATE, OnCombatStateChanged)
end

EVENT_MANAGER:RegisterForEvent("AutoCharge", EVENT_ADD_ON_LOADED, OnAddonLoaded)
