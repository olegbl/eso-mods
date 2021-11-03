local ADDON_NAME = "GamePadHelper_GearComparison"
local ADDON_VERSION = 1.00

local function GamepadInventory_SwitchActiveList_Before(self, listDescriptor)
  if listDescriptor == self.currentListType then return end
  GAMEPAD_TOOLTIPS:Reset(GAMEPAD_QUAD3_TOOLTIP)
end

local function GamepadInventory_UpdateRightTooltip_After(self, list, selectedData, oldSelectedData)
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

ZO_PreHook(GAMEPAD_INVENTORY, "SwitchActiveList", GamepadInventory_SwitchActiveList_Before)
ZO_PostHook(GAMEPAD_INVENTORY, "UpdateRightTooltip", GamepadInventory_UpdateRightTooltip_After)
