local ADDON_NAME = "GamePadHelper_TooltipPoison"
local ADDON_VERSION = 1.01

local function Tooltip_AddPoisonInfo_Before(self, itemLink, equipSlot)
  local hasPoison, poisonCount, poisonHeader, poisonItemLink = GetItemPairedPoisonInfo(equipSlot)
  if hasPoison then
    local poisonQuality = GetItemLinkQuality(poisonItemLink)
    local poisonQualityColor = GetItemQualityColor(poisonQuality)

    local poisonNameString = poisonQualityColor:Colorize(poisonHeader)
    local poisonCountString = tostring(poisonCount)

    local equippedPoisonSection = self:AcquireSection(self:GetStyle("equippedPoisonSection"))

    equippedPoisonSection:AddLine(
      string.format(
        "%s (%s)",
        poisonNameString,
        poisonCountString
      ),
      self:GetStyle("bodyHeader")
    )

    self:AddSection(equippedPoisonSection)

    self:AddOnUseAbility(poisonItemLink)
  end

  return true
end

local tooltips = {
  GAMEPAD_LEFT_DIALOG_TOOLTIP,
  GAMEPAD_LEFT_TOOLTIP,
  GAMEPAD_MOVABLE_TOOLTIP,
  GAMEPAD_QUAD1_TOOLTIP,
  GAMEPAD_QUAD3_TOOLTIP,
  GAMEPAD_RIGHT_TOOLTIP
}

for index, tooltip in ipairs(tooltips) do
  ZO_PreHook(GAMEPAD_TOOLTIPS:GetTooltip(tooltip), "AddPoisonInfo", Tooltip_AddPoisonInfo_Before)
end
