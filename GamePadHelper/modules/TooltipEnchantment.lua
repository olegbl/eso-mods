local COLOR_WHITE = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, GENERAL_COLOR_WHITE))
local COLOR_FAILED = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, GAMEPAD_TOOLTIP_COLOR_FAILED))

local function Tooltip_AddEnchant_Before(self, itemLink, enchantDiffMode, equipSlot)
  local sv = _G["GamePadHelper_SavedVars"]
  if not sv or not sv.tooltipEnchantmentEnabled then return end
  enchantDiffMode = enchantDiffMode or ZO_ENCHANT_DIFF_NONE
  local enchantSection = self:AcquireSection(self:GetStyle("bodySection"))
  local hasEnchant, enchantHeader, enchantDescription = GetItemLinkEnchantInfo(itemLink)

  if hasEnchant and LibItemLinkDecoder then
    local decodedItemLink = LibItemLinkDecoder:Decode(itemLink)
    local quality = decodedItemLink.enchantQuality
    local qualityColor = GetItemQualityColor(decodedItemLink.enchantQuality)

    local headerText = qualityColor:Colorize(enchantHeader)

    headerText = string.format(
      "%s (%s %s)",
      headerText,
      decodedItemLink.enchantChampionLevel > 0 and "CP" or GetString(SI_GPH_TOOLTIPENCHANTMENT_LEVEL),
      COLOR_WHITE:Colorize(tostring(decodedItemLink.enchantChampionLevel > 0 and decodedItemLink.enchantChampionLevel or decodedItemLink.enchantLevel))
    )

    local bodyColor =
      enchantDiffMode == ZO_ENCHANT_DIFF_ADD and GAMEPAD_TOOLTIP_COLOR_ABILITY_UPGRADE or
      enchantDiffMode == ZO_ENCHANT_DIFF_REMOVE and GAMEPAD_TOOLTIP_COLOR_FAILED or
      IsItemAffectedByPairedPoison(equipSlot) and GAMEPAD_TOOLTIP_COLOR_INACTIVE or
      GENERAL_COLOR_OFF_WHITE
    local bodyText = enchantDescription:gsub("\n\n", " "):gsub("\n", " ")

    if enchantDiffMode == ZO_ENCHANT_DIFF_NONE and IsItemAffectedByPairedPoison(equipSlot) then
      bodyText = string.format(
        "%s %s",
        bodyText,
        COLOR_FAILED:Colorize(GetString(SI_TOOLTIP_ENCHANT_SUPPRESSED_BY_POISON))
      )
    end

    enchantSection:AddLine(headerText, self:GetStyle("bodyHeader"))
    enchantSection:AddLine(bodyText, self:GetStyle("bodyDescription"))
  end
  self:AddSection(enchantSection)

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

EVENT_MANAGER:RegisterForEvent("TooltipEnchantment", EVENT_ADD_ON_LOADED, function(_, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("TooltipEnchantment", EVENT_ADD_ON_LOADED)
    for _, tooltip in ipairs(tooltips) do
        ZO_PreHook(GAMEPAD_TOOLTIPS:GetTooltip(tooltip), "AddEnchant", Tooltip_AddEnchant_Before)
    end
end)
