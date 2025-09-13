local ADDON_NAME = "GamePadHelper_TooltipEnchantment"
local ADDON_VERSION = 1.01

local COLOR_WHITE = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, GENERAL_COLOR_WHITE))
local COLOR_FAILED = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, GAMEPAD_TOOLTIP_COLOR_FAILED))

local function Tooltip_AddEnchant_Before(self, itemLink, enchantDiffMode, equipSlot)
  enchantDiffMode = enchantDiffMode or ZO_ENCHANT_DIFF_NONE
  local enchantSection = self:AcquireSection(self:GetStyle("bodySection"))
  local hasEnchant, enchantHeader, enchantDescription = GetItemLinkEnchantInfo(itemLink)

  if hasEnchant then
    local decodedItemLink = LibItemLinkDecoder:Decode(itemLink)
    local quality = decodedItemLink.enchantQuality
    local qualityColor = GetItemQualityColor(decodedItemLink.enchantQuality)

    -- add enchantment name colored by quality
    local headerText = qualityColor:Colorize(enchantHeader:gsub(" Enchantment", ""))

    -- add level requirement
    headerText = string.format(
      "%s (%s %s)",
      headerText,
      decodedItemLink.enchantChampionLevel > 0 and "CP" or "LEVEL",
      COLOR_WHITE:Colorize(tostring(decodedItemLink.enchantChampionLevel > 0 and decodedItemLink.enchantChampionLevel or decodedItemLink.enchantLevel))
    )

    -- add enchantment description
    local bodyColor =
      enchantDiffMode == ZO_ENCHANT_DIFF_ADD and GAMEPAD_TOOLTIP_COLOR_ABILITY_UPGRADE or
      enchantDiffMode == ZO_ENCHANT_DIFF_REMOVE and GAMEPAD_TOOLTIP_COLOR_FAILED or
      IsItemAffectedByPairedPoison(equipSlot) and GAMEPAD_TOOLTIP_COLOR_INACTIVE or
      GENERAL_COLOR_OFF_WHITE
    local bodyText = enchantDescription:gsub("\n\n", " "):gsub("\n", " ")

    -- add poison status
    if enchantDiffMode == ZO_ENCHANT_DIFF_NONE and IsItemAffectedByPairedPoison(equipSlot) then
      bodyText = string.format(
        "%s %s",
        bodyText,
        COLOR_FAILED:Colorize(GetString(SI_TOOLTIP_ENCHANT_SUPPRESSED_BY_POISON))
      )
    end

    -- insert the lines into the section
    enchantSection:AddLine(headerText, self:GetStyle("bodyHeader"))
    enchantSection:AddLine(bodyText, self:GetStyle("bodyDescription"))
    -- {
    --   fontFace = "$(GAMEPAD_LIGHT_FONT)",
    --   fontSize = "$(GP_27)",
    --   fontColorField = bodyColor,
    -- }
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

for index, tooltip in ipairs(tooltips) do
  ZO_PreHook(GAMEPAD_TOOLTIPS:GetTooltip(tooltip), "AddEnchant", Tooltip_AddEnchant_Before)
end
