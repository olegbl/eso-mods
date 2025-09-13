local ADDON_NAME = "GamePadHelper_TooltipTrait"
local ADDON_VERSION = 1.01

local RESEARCH_ICON = zo_iconFormatInheritColor(GetPlatformTraitInformationIcon(ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED), 32, 32)
local BAG_ICON = zo_iconFormatInheritColor("esoui/art/tooltips/icon_bag.dds", 20, 20)
local BANK_ICON = zo_iconFormatInheritColor("esoui/art/tooltips/icon_bank.dds", 20, 20)

local function Tooltip_AddTrait_Before(self, itemLink, extraData)
  local traitType, traitDescription = GetItemLinkTraitInfo(itemLink)
  if traitType ~= ITEM_TRAIT_TYPE_NONE and traitDescription ~= "" then
    local traitName = GetString("SI_ITEMTRAITTYPE", traitType)
    if traitName ~= "" then
      local traitSection = self:AcquireSection(self:GetStyle("bodySection"))
      local traitInformation = GetItemTraitInformationFromItemLink(itemLink)
      local traitInformationIcon = GetPlatformTraitInformationIcon(traitInformation)

      local canBeResearched, colorOverall, duplicateRemoteItems, colorRemote, duplicateLocalItems, colorLocal = LibTraitResearch:GetItemLinkTraitResearchState(itemLink)

      local additionalTooltipStyle
      if extraData and extraData.showTraitAsNew then
        additionalTooltipStyle = self:GetStyle("succeeded")
      end

      local title = zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_HEADER, traitName)
    
      if traitInformationIcon and traitInformation ~= ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED then
        traitInformationIcon = zo_iconFormat(traitInformationIcon, 32, 32)
        title = string.format("%s %s", title, traitInformationIcon)
      end

      if canBeResearched then
        local researchIcon = colorOverall:Colorize(RESEARCH_ICON)
        local duplicateRemoteText = colorRemote:Colorize(duplicateRemoteItems)
        local duplicateLocalText = colorLocal:Colorize(duplicateLocalItems)

        if duplicateRemoteItems > 0 and duplicateLocalItems > 0 then
          title = string.format("%s (%s%s%s%s%s)", title, researchIcon, BANK_ICON, duplicateRemoteText, BAG_ICON, duplicateLocalText)
        elseif duplicateRemoteItems > 0 then
          title = string.format("%s (%s%s%s)", title, researchIcon, BANK_ICON, duplicateRemoteText)
        elseif duplicateLocalItems > 0 then
          title = string.format("%s (%s%s%s)", title, researchIcon, BAG_ICON, duplicateLocalText)
        else
          title = string.format("%s (%s)", title, researchIcon)
        end
      end

      traitSection:AddLine(title, self:GetStyle("bodyHeader"), additionalTooltipStyle)
      traitSection:AddLine(traitDescription, self:GetStyle("bodyDescription"), additionalTooltipStyle)
      self:AddSection(traitSection)
    end
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
  ZO_PreHook(GAMEPAD_TOOLTIPS:GetTooltip(tooltip), "AddTrait", Tooltip_AddTrait_Before)
end
