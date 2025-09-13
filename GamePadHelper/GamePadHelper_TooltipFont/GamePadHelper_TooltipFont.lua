local ADDON_NAME = "GamePadHelper_TooltipFont"
local ADDON_VERSION = 1.01

local tooltips = {
  GAMEPAD_LEFT_DIALOG_TOOLTIP,
  GAMEPAD_LEFT_TOOLTIP,
  GAMEPAD_MOVABLE_TOOLTIP,
  GAMEPAD_QUAD1_TOOLTIP,
  GAMEPAD_QUAD3_TOOLTIP,
  GAMEPAD_RIGHT_TOOLTIP
}

for index, tooltipID in ipairs(tooltips) do
  local tooltip = GAMEPAD_TOOLTIPS:GetTooltip(tooltipID)
  tooltip:GetStyle("bodyDescription").fontSize = "$(GP_34)"
  tooltip:GetStyle("flavorText").fontSize = "$(GP_34)"
  tooltip:GetStyle("poisonCount").fontSize = "$(GP_34)"
  tooltip:GetStyle("prioritySellText").fontSize = "$(GP_34)"
end
