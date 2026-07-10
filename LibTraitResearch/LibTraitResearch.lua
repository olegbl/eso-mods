local ADDON_NAME = "LibTraitResearch"

if GetAPIVersion() < 101047 then return end

LibTraitResearch = {}

local COLOR_LOCAL  = ZO_CURRENCY_HIGHLIGHT_TEXT
local COLOR_REMOTE = ZO_ERROR_COLOR
local COLOR_UNIQUE = GetItemQualityColor(ITEM_DISPLAY_QUALITY_MAGIC or ITEM_QUALITY_MAGIC)
local COLOR_LOCKED = LOCKED_COLOR or ZO_ColorDef:New(0.5, 0.5, 0.5, 1.0)
local COLOR_EQUIPPED = ZO_ColorDef:New(0.2, 0.6, 1.0)

local BAG_LOCAL = 1
local BAG_REMOTE = 2

local BAGS = {
  {bagId = BAG_BACKPACK,        bagType = BAG_LOCAL},
  {bagId = BAG_BANK,            bagType = BAG_REMOTE},
  {bagId = BAG_SUBSCRIBER_BANK, bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_ONE,   bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_TWO,   bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_THREE, bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_FOUR,  bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_FIVE,  bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_SIX,   bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_SEVEN, bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_EIGHT, bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_NINE,  bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_TEN,   bagType = BAG_REMOTE},
}

local items = {}

local function GetItemTraitList(itemLink)
  if not itemLink then return nil end
  if GetItemTraitInformationFromItemLink(itemLink) ~= ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED then return nil end
  local key = string.format(
    "%s:%s:%s:%s",
    tostring(GetItemLinkTraitInfo(itemLink)),
    tostring(GetItemLinkEquipType(itemLink)),
    tostring(GetItemLinkArmorType(itemLink)),
    tostring(GetItemLinkWeaponType(itemLink))
  )
  items[key] = items[key] or {}
  return items[key]
end

function LibTraitResearch:GetItemLinkTraitResearchState(itemLink)
  local canBeResearched = GetItemTraitInformationFromItemLink(itemLink) == ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED
  return self:GetItemLinkTraitResearchStateForSlot(itemLink, nil, nil, canBeResearched)
end

function LibTraitResearch:GetItemLinkTraitResearchStateForSlot(itemLink, bagId, slotIndex, canBeResearchedOverride)
  local canBeResearched = canBeResearchedOverride
  if canBeResearched == nil then
    canBeResearched = GetItemTraitInformationFromItemLink(itemLink) == ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED
  end

  local duplicateRemoteItems = 0
  local duplicateLocalItems = 0
  if itemLink ~= nil and canBeResearched then
    local list = GetItemTraitList(itemLink)
    if list ~= nil then
      local localUnlocked = 0
      local remoteUnlocked = 0
      local currentBagType = nil
      local currentIsLocked = nil

      for _, item in ipairs(list) do
        local itemIsLocked = IsItemPlayerLocked(item.bagId, item.slotIndex)
        if item.bagType == BAG_REMOTE then
          if not itemIsLocked then remoteUnlocked = remoteUnlocked + 1 end
        elseif item.bagType == BAG_LOCAL then
          if not itemIsLocked then localUnlocked = localUnlocked + 1 end
        end
        if bagId ~= nil and slotIndex ~= nil and item.bagId == bagId and item.slotIndex == slotIndex then
          currentBagType = item.bagType
          currentIsLocked = itemIsLocked
        end
      end

      if currentBagType ~= nil and currentIsLocked == false then
        if currentBagType == BAG_REMOTE then
          remoteUnlocked = zo_max(0, remoteUnlocked - 1)
        elseif currentBagType == BAG_LOCAL then
          localUnlocked = zo_max(0, localUnlocked - 1)
        end
      end

      if bagId == BAG_WORN then
        return canBeResearched, COLOR_EQUIPPED, 0, COLOR_REMOTE, 0, COLOR_LOCAL
      end
      if bagId ~= nil and slotIndex ~= nil and IsItemPlayerLocked(bagId, slotIndex) then
        return canBeResearched, COLOR_LOCKED, 0, COLOR_REMOTE, 0, COLOR_LOCAL
      end

      duplicateLocalItems = localUnlocked
      duplicateRemoteItems = remoteUnlocked
    end
  end
  local color =
    duplicateRemoteItems > 0 and COLOR_REMOTE or
    duplicateLocalItems > 0 and COLOR_LOCAL or
    COLOR_UNIQUE
  return canBeResearched, color, duplicateRemoteItems, COLOR_REMOTE, duplicateLocalItems, COLOR_LOCAL
end

function LibTraitResearch:Update()
  items = {}
  for _, bag in ipairs(BAGS) do
    local bagId = bag.bagId
    local bagType = bag.bagType
    for slotIndex = 0, GetBagSize(bagId) - 1 do
      local itemLink = GetItemLink(bagId, slotIndex)
      local list = GetItemTraitList(itemLink)
      if list ~= nil then
        table.insert(list, {bagId = bagId, bagType = bagType, slotIndex = slotIndex, itemLink = itemLink})
      end
    end
  end
end

local function OnUpdate() LibTraitResearch:Update() end

local function OnSlotUpdate(_, bagId, slotId, _, _, _, stackCountChange)
  if stackCountChange == -1 or (stackCountChange == 1 and GetItemTraitInformationFromItemLink(GetItemLink(bagId, slotId)) == ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED) then
    LibTraitResearch:Update()
  end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SLOT_LOCKED,    OnUpdate)
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SLOT_UNLOCKED,  OnUpdate)
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_ITEM_DESTROYED, OnUpdate)
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_CRAFT_COMPLETED,          OnUpdate)
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_FULL_UPDATE,    OnUpdate)
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED,         OnUpdate)

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_CRAFTING_STATION_INTERACT, function()
  LibTraitResearch:Update()
  EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
end)

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_END_CRAFTING_STATION_INTERACT, function()
  EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnSlotUpdate)
end)

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnSlotUpdate)
