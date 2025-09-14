local ADDON_NAME = "LibTraitResearch"
local ADDON_VERSION = 1.02

-- Ensure ESO API compatibility
if GetAPIVersion() < 101047 then return end

LibTraitResearch = {}

local COLOR_LOCAL = ZO_CURRENCY_HIGHLIGHT_TEXT -- ZO_ColorDef:New("FFD900")
local COLOR_REMOTE = ZO_ERROR_COLOR -- ZO_ColorDef:New("FF8000")
local COLOR_UNIQUE = GetItemQualityColor(ITEM_QUALITY_MAGIC)
local COLOR_LOCKED = LOCKED_COLOR

local BAG_LOCAL = 1 -- inventory / worn
local BAG_REMOTE = 2 -- bank

local BAGS = {
  {bagId = BAG_BACKPACK, bagType = BAG_LOCAL},
  {bagId = BAG_BANK, bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_EIGHT, bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_FIVE, bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_FOUR, bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_NINE, bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_ONE, bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_SEVEN, bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_SIX, bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_TEN, bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_THREE, bagType = BAG_REMOTE},
  {bagId = BAG_HOUSE_BANK_TWO, bagType = BAG_REMOTE},
  {bagId = BAG_SUBSCRIBER_BANK, bagType = BAG_REMOTE},
  -- {bagId = BAG_WORN, bagType = BAG_LOCAL} -- ignore items that are in use
}

local items = {}

local function GetItemTraitList(itemLink)
  if not itemLink then return nil end
  local canBeResearched = CanItemLinkBeTraitResearched(itemLink)
  if not canBeResearched then return nil end
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
  local canBeResearched = CanItemLinkBeTraitResearched(itemLink)
  local duplicateRemoteItems = 0
  local duplicateLocalItems = 0
  local isLocked = false
  if itemLink ~= nil then
    if canBeResearched then
      local list = GetItemTraitList(itemLink)
      for index, item in ipairs(list) do
        if item.itemLink ~= itemLink and not item.isLocked then
          if item.bagType == BAG_REMOTE then
            duplicateRemoteItems = duplicateRemoteItems + 1
          elseif item.bagType == BAG_LOCAL then
            duplicateLocalItems = duplicateLocalItems + 1
          end
        end
        if item.itemLink == itemLink and item.isLocked then
          isLocked = true
        end
      end
    end
  end
  local color =
    duplicateRemoteItems > 0 and COLOR_REMOTE or
    duplicateLocalItems > 0 and COLOR_LOCAL or
    isLocked and COLOR_LOCKED or
    COLOR_UNIQUE
  return canBeResearched, color, duplicateRemoteItems, COLOR_REMOTE, duplicateLocalItems, COLOR_LOCAL
end

function LibTraitResearch:Update()
  -- reset all previous counts
  items = {}
  -- iterate through all the bags to update counts
  for bagIndex, bag in ipairs(BAGS) do
    local bagId = bag.bagId
    local bagType = bag.bagType
    local bagSize = GetBagSize(bagId)
    for slotIndex = 0, bagSize do
      local itemLink = GetItemLink(bagId, slotIndex)
      local list = GetItemTraitList(itemLink)
      local isLocked = IsItemPlayerLocked(bagId, slotIndex)
      if list ~= nil then
        table.insert(list, {
          bagId = bagId,
          bagType = bagType,
          slotIndex = slotIndex,
          itemLink = itemLink,
          isLocked = isLocked
        })
      end
    end
  end
end

local function OnInventorySlotLocked(event, bagId, slotId)
  LibTraitResearch:Update()
end
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SLOT_LOCKED, OnInventorySlotLocked)

local function OnInventorySlotUnlocked(event, bagId, slotId)
  LibTraitResearch:Update()
end
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SLOT_UNLOCKED, OnInventorySlotUnlocked)

local function OnInventoryItemDestroyed(event, itemSoundCategory)
  LibTraitResearch:Update()
end
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_ITEM_DESTROYED, OnInventoryItemDestroyed)

local function OnInventorySingleSlotUpdate(event, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
  if stackCountChange == 1 then
    local itemLink = GetItemLink(bagId, slotId)
    if itemLink ~= nil then
      local canBeResearched = CanItemLinkBeTraitResearched(itemLink)
      if canBeResearched then
        LibTraitResearch:Update()
      end
    end
  elseif stackCountChange == -1 then
    LibTraitResearch:Update()
  end
end
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySingleSlotUpdate)

local function OnCraftCompleted(event, craftSkill)
  LibTraitResearch:Update()
end
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_CRAFT_COMPLETED, OnCraftCompleted)

local function OnCraftingStationInteract(event, craftSkill, sameStation)
  LibTraitResearch:Update()
  EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
end
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_CRAFTING_STATION_INTERACT, OnCraftingStationInteract)

local function OnEndCraftingStationInteract(event, craftSkill)
  EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnCraftingStationInteract)
end
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_END_CRAFTING_STATION_INTERACT, OnEndCraftingStationInteract)

local function onInventoryFullUpdate()
  LibTraitResearch:Update()
end
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_FULL_UPDATE, onInventoryFullUpdate)

local function onPlayerActivated()
  LibTraitResearch:Update()
end
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, onPlayerActivated)
