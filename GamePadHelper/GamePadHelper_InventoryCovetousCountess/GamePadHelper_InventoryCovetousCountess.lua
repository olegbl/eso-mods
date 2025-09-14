local ADDON_NAME = "GamePadHelper_InventoryCovetousCountess"
local ADDON_VERSION = 1.01

local COLOR_USEFUL_ACTIVE = ZO_ColorDef:New(1, 1, 0)
local COLOR_USEFUL_INACTIVE = ZO_ColorDef:New(1, 1, 1)

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

local function SharedGamepadEntry_OnSetup_After(control, data, ...)
  local statusIndicator = control:GetNamedChild("StatusIndicator")
  if not statusIndicator then return end

  local itemLink = GetItemLinkFromData(data)
  if not itemLink then return end

  local itemType = GetItemLinkItemType(itemLink)
  if itemType ~= ITEMTYPE_TREASURE then return end

  local researchIcon = GetPlatformTraitInformationIcon(ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED)
  local isUsefulForActiveQuest, isUsefulForQuest = false, false
  if LibCovetousCountess and LibCovetousCountess.IsItemUseful then
      local success, result1, result2 = pcall(LibCovetousCountess.IsItemUseful, LibCovetousCountess, itemLink)
      if success then
          isUsefulForActiveQuest, isUsefulForQuest = result1, result2
      else
          d("[" .. ADDON_NAME .. "] Error calling LibCovetousCountess:IsItemUseful: " .. tostring(result1))
      end
  end

  -- sometimes MultiIcon is not initialized property for some reason
  -- TODO: WTF?
  if not statusIndicator.SetIconColor then
    ZO_MultiIcon_Initialize(statusIndicator)
  end

  if isUsefulForQuest then
    if not statusIndicator:HasIcon(researchIcon) then
      -- animation will not kick in if MultiIcon is already shown when second icon is added
      statusIndicator:Hide()
      statusIndicator:AddIcon(researchIcon)
      statusIndicator:Show()
    end
  else
    if statusIndicator.RemoveIcon then
      statusIndicator:RemoveIcon(researchIcon)
    end
    if statusIndicator.RemoveIconColor then
      statusIndicator:RemoveIconColor(researchIcon)
    end
  end

  if isUsefulForActiveQuest then
    if statusIndicator.SetIconColor then
      statusIndicator:SetIconColor(researchIcon, COLOR_USEFUL_ACTIVE:UnpackRGBA())
    end
  elseif isUsefulForQuest then
    if statusIndicator.SetIconColor then
      statusIndicator:SetIconColor(researchIcon, COLOR_USEFUL_INACTIVE:UnpackRGBA())
    end
  end
end

ZO_PostHook("ZO_SharedGamepadEntry_OnSetup", SharedGamepadEntry_OnSetup_After)
