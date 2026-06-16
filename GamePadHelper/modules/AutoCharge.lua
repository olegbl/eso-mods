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

local function IsFilledSoulGem(bagId, slotIndex)
    return IsItemSoulGem(SOUL_GEM_TYPE_FILLED, bagId, slotIndex)
end

local function FindSoulGem()
    local bagId = BAG_BACKPACK
    for slotIndex = 0, GetBagSize(bagId) - 1 do
        if IsFilledSoulGem(bagId, slotIndex) and not IsItemFromCrownStore(bagId, slotIndex) then
            return bagId, slotIndex
        end
    end
    return nil, nil
end

local WEAPON_SLOTS = {
    EQUIP_SLOT_MAIN_HAND,
    EQUIP_SLOT_OFF_HAND,
    EQUIP_SLOT_BACKUP_MAIN,
    EQUIP_SLOT_BACKUP_OFF,
}

local WEAPON_SLOT_LOOKUP = {
    [EQUIP_SLOT_MAIN_HAND] = true,
    [EQUIP_SLOT_OFF_HAND] = true,
    [EQUIP_SLOT_BACKUP_MAIN] = true,
    [EQUIP_SLOT_BACKUP_OFF] = true,
}

local autoChargeQueued = false

local function AutoCharge()
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv or not sv.autoChargeEnabled then
        return
    end

    for _, equipSlot in ipairs(WEAPON_SLOTS) do
        local charges, maxCharges = GetChargeInfoForItem(BAG_WORN, equipSlot)
        if charges and maxCharges and maxCharges > 0 then
            local chargePercentage = (charges / maxCharges) * 100
            local threshold = sv.autoChargeThreshold or 25
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

local function QueueAutoCharge()
    if autoChargeQueued then
        return
    end

    autoChargeQueued = true
    zo_callLater(function()
        autoChargeQueued = false
        AutoCharge()
    end, 0)
end

local function OnCombatStateChanged()
    QueueAutoCharge()
end

local function OnActiveWeaponPairChanged()
    QueueAutoCharge()
end

local function OnInventorySingleSlotUpdate(event, bagId, slotIndex)
    if bagId == BAG_WORN and WEAPON_SLOT_LOOKUP[slotIndex] then
        QueueAutoCharge()
    elseif bagId == BAG_BACKPACK and IsFilledSoulGem(bagId, slotIndex) then
        QueueAutoCharge()
    end
end

local function OnAddonLoaded(event, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("AutoCharge", EVENT_ADD_ON_LOADED)
    EVENT_MANAGER:RegisterForEvent("AutoCharge", EVENT_PLAYER_COMBAT_STATE, OnCombatStateChanged)
    EVENT_MANAGER:RegisterForEvent("AutoCharge", EVENT_ACTIVE_WEAPON_PAIR_CHANGED, OnActiveWeaponPairChanged)
    EVENT_MANAGER:RegisterForEvent("AutoCharge", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySingleSlotUpdate)
    QueueAutoCharge()
end

EVENT_MANAGER:RegisterForEvent("AutoCharge", EVENT_ADD_ON_LOADED, OnAddonLoaded)
