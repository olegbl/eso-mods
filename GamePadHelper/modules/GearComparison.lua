local function GamepadInventory_SwitchActiveList_Before(self, listDescriptor)
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv or not sv.gearComparisonEnabled then return end
    if listDescriptor == self.currentListType then return end
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_QUAD3_TOOLTIP)
end

local function GamepadInventory_UpdateRightTooltip_After(self, list, selectedData, oldSelectedData)
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv or not sv.gearComparisonEnabled then return end
    local targetCategoryData = self.categoryList:GetTargetData()
    if targetCategoryData and targetCategoryData.equipSlot then
        local selectedItemData = self.currentlySelectedData
        local equipSlotHasItem = select(2, GetEquippedItemInfo(targetCategoryData.equipSlot))
        if selectedItemData and (not equipSlotHasItem or self.savedVars.useStatComparisonTooltip) then
            if GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_QUAD3_TOOLTIP, BAG_WORN, targetCategoryData.equipSlot) then
                self:UpdateTooltipEquippedIndicatorText(GAMEPAD_QUAD3_TOOLTIP, targetCategoryData.equipSlot)
            end
        else
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_QUAD3_TOOLTIP)
        end
    else
        GAMEPAD_TOOLTIPS:Reset(GAMEPAD_QUAD3_TOOLTIP)
    end
end

EVENT_MANAGER:RegisterForEvent("GearComparison", EVENT_ADD_ON_LOADED, function(_, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("GearComparison", EVENT_ADD_ON_LOADED)
    if GAMEPAD_INVENTORY then
        ZO_PreHook(GAMEPAD_INVENTORY, "SwitchActiveList", GamepadInventory_SwitchActiveList_Before)
        ZO_PostHook(GAMEPAD_INVENTORY, "UpdateRightTooltip", GamepadInventory_UpdateRightTooltip_After)
    end
end)
