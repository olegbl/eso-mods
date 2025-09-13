local ADDON_NAME = "GamePadHelper_InventoryTrait"
local ADDON_VERSION = 1.01

-- TODO: when inventory is updated, rows don't necessarily re-render
-- so while local state is correct, the rendered state can be stale
-- selecting / unselecting item refreshes whole list - should mimic

local function IsInCraftBagTab()
  if GAMEPAD_INVENTORY and GAMEPAD_INVENTORY.header then
    local tabBar = GAMEPAD_INVENTORY.header.tabBar
    if tabBar then
      local selectedData = tabBar:GetSelectedData()
      if selectedData and selectedData.text == GetString(SI_GAMEPAD_INVENTORY_CRAFT_BAG_HEADER) then
        return true
      end
    end
  end
  return false
end

local function GetItemLinkFromData(data)
  if type(data) ~= "table" then
    return nil
  end

  local itemLink
  if data.bagId ~= nil and data.slotIndex ~= nil then
    itemLink = GetItemLink(data.bagId, data.slotIndex)
  elseif data.lootId ~= nil then
    itemLink = GetLootItemLink(data.lootId)
  end
  return itemLink
end

local function ZO_SharedGamepadEntry_OnSetup_Before(self, data, ...)
  -- Always check if we're in craft bag tab - if so, don't do anything
  if IsInCraftBagTab() then
    return
  end

  if type(data) ~= "table" then return end

  if data.ignoreTraitInformation then
    data.ignoreTraitInformation = false
  end
end

local function ZO_SharedGamepadEntry_OnSetup_After(self, data, ...)
  -- Check if we're in craft bag tab at the very beginning - if so, don't do anything
  if IsInCraftBagTab() then
    return
  end

  if type(data) ~= "table" then return end

  local itemLink = GetItemLinkFromData(data)
  if not itemLink then return end

  local canBeResearched, colorOverall, duplicateRemoteItems, colorRemote, duplicateLocalItems, colorLocal = LibTraitResearch:GetItemLinkTraitResearchState(itemLink)

  local researchIcon = GetPlatformTraitInformationIcon(ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED)
  local icon = self:GetNamedChild("StatusIndicator")
  if not icon or not icon.HasIcon then return end
  local hasResearchIcon = icon:HasIcon(researchIcon)

  local researchLabel = self:GetNamedChild("StatusIndicatorLabel")
  if researchLabel == nil then
    researchLabel = CreateControl("$(parent)StatusIndicatorLabel", self, CT_LABEL)
    researchLabel:SetFont("ZoFontGameSmall")
    researchLabel:SetMaxLineCount(1)
    researchLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    researchLabel:SetVerticalAlignment(TEXT_ALIGN_BOTTOM)
    researchLabel:ClearAnchors()
    researchLabel:SetAnchor(BOTTOMLEFT, icon, BOTTOMLEFT, 0, 14)
    researchLabel:SetAnchor(BOTTOMRIGHT, icon, BOTTOMRIGHT, 0, 14)
  end

  -- TODO: sometimes MultiIcon is not initialized property for some reason
  if not icon.SetIconColor then
    ZO_MultiIcon_Initialize(icon)
  end

  if hasResearchIcon and canBeResearched then
    local duplicateRemoteText = colorRemote:Colorize(duplicateRemoteItems)
    local duplicateLocalText = colorLocal:Colorize(duplicateLocalItems)

    if icon.SetIconColor then
      icon:SetIconColor(researchIcon, colorOverall:UnpackRGBA())
    end

    researchLabel:SetHidden(duplicateRemoteItems == 0 and duplicateLocalItems == 0)

    if duplicateRemoteItems > 0 and duplicateLocalItems > 0 then
      researchLabel:SetText(duplicateRemoteText.." "..duplicateLocalText)
    elseif duplicateRemoteItems > 0 then
      researchLabel:SetText(duplicateRemoteText)
    elseif duplicateLocalItems > 0 then
      researchLabel:SetText(duplicateLocalText)
    end
  else
    researchLabel:SetHidden(true)
  end
end

-- even though we hook ZO_SharedGamepadEntry_OnSetup, references to the original
-- version of the function can exist in some already initialized scroll lists
-- so we fix those references here
local function ZO_ParametricScrollList_GetSetupFunctionForDataIndex_Before(self, dataIndex)
  -- Check if we're in craft bag tab - if so, don't do anything
  if IsInCraftBagTab() then
    return
  end

  local templateName = self.templateList[dataIndex]
  if not templateName then return end

  if templateName ~= "ZO_GamepadItemSubEntryTemplate"
    and templateName ~= "ZO_GamepadItemSubEntryTemplateWithHeader"
    then return end

  local dataType = self.dataTypes[templateName]
  if not dataType then return end

  local setupFunction = dataType.setupFunction
  if setupFunction == ZO_SharedGamepadEntry_OnSetup then return end

  dataType.setupFunction = ZO_SharedGamepadEntry_OnSetup
end

-- Only register hooks if we're not in craft bag tab
if not IsInCraftBagTab() then
  ZO_PreHook("ZO_SharedGamepadEntry_OnSetup", ZO_SharedGamepadEntry_OnSetup_Before)
  ZO_PostHook("ZO_SharedGamepadEntry_OnSetup", ZO_SharedGamepadEntry_OnSetup_After)
  ZO_PreHook(ZO_ParametricScrollList, "GetSetupFunctionForDataIndex", ZO_ParametricScrollList_GetSetupFunctionForDataIndex_Before)
end

