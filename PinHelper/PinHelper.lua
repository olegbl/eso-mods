local ADDON_NAME = "PinHelper"
local ADDON_VERSION = 1.00

-- TODO: allow controlling compass pin visible via LibAddonMenu-2.0
-- TODO: allow teleporting to wayshrines
-- TODO: allow teleporting to group instances
-- TODO: allow teleporting to houses
-- TODO: control size and color of pins via LibAddonMenu-2.0
-- TODO: animate active dark anchors
-- TODO: refresh compass / map pins automatically based on events

local SAVED_DATA

local DEFAULT_DATA = {
  mapFilters = {
    PinHelper_areaofinterest_complete = false,
    PinHelper_areaofinterest_incomplete = true,
    PinHelper_ayleidruin_complete = false,
    PinHelper_ayleidruin_incomplete = true,
    PinHelper_battlefield_complete = false,
    PinHelper_battlefield_incomplete = true,
    PinHelper_boss_complete = false,
    PinHelper_boss_incomplete = true,
    PinHelper_camp_complete = false,
    PinHelper_camp_incomplete = true,
    PinHelper_cave_complete = false,
    PinHelper_cave_incomplete = true,
    PinHelper_cemetery_complete = false,
    PinHelper_cemetery_incomplete = true,
    PinHelper_city_complete = false,
    PinHelper_city_incomplete = true,
    PinHelper_crafting_complete = true,
    PinHelper_crafting_incomplete = true,
    PinHelper_crypt_complete = false,
    PinHelper_crypt_incomplete = true,
    PinHelper_daedricruin_complete = false,
    PinHelper_daedricruin_incomplete = true,
    PinHelper_darkbrotherhood_complete = true,
    PinHelper_darkbrotherhood_incomplete = true,
    PinHelper_delve_complete = false,
    PinHelper_delve_incomplete = true,
    PinHelper_dock_complete = false,
    PinHelper_dock_incomplete = true,
    PinHelper_dungeon_complete = false,
    PinHelper_dungeon_incomplete = true,
    PinHelper_dwemerruin_complete = false,
    PinHelper_dwemerruin_incomplete = true,
    PinHelper_estate_complete = false,
    PinHelper_estate_incomplete = true,
    PinHelper_explorable_complete = false,
    PinHelper_explorable_incomplete = true,
    PinHelper_farm_complete = false,
    PinHelper_farm_incomplete = true,
    PinHelper_gate_complete = false,
    PinHelper_gate_incomplete = true,
    PinHelper_grove_complete = false,
    PinHelper_grove_incomplete = true,
    PinHelper_house_complete = false,
    PinHelper_instance_complete = false,
    PinHelper_instance_incomplete = false,
    PinHelper_keep_complete = false,
    PinHelper_keep_incomplete = true,
    PinHelper_lighthouse_complete = false,
    PinHelper_lighthouse_incomplete = true,
    PinHelper_mine_complete = false,
    PinHelper_mine_incomplete = true,
    PinHelper_mundus_complete = true,
    PinHelper_mundus_incomplete = true,
    PinHelper_portal_complete = true,
    PinHelper_portal_incomplete = true,
    PinHelper_raiddungeon_complete = false,
    PinHelper_raiddungeon_incomplete = true,
    PinHelper_ruin_complete = false,
    PinHelper_ruin_incomplete = true,
    PinHelper_sewer_complete = false,
    PinHelper_sewer_incomplete = true,
    PinHelper_solotrial_complete = false,
    PinHelper_solotrial_incomplete = true,
    PinHelper_tower_complete = false,
    PinHelper_tower_incomplete = true,
    PinHelper_town_complete = false,
    PinHelper_town_incomplete = true,
    PinHelper_u26_dwemergear_complete = false,
    PinHelper_u26_dwemergear_incomplete = true,
    PinHelper_u26_nord_boat_complete = false,
    PinHelper_u26_nord_boat_incomplete = true,
    PinHelper_unknown = true,
    PinHelper_wayshrine_complete = false,
    PinHelper_wayshrine_incomplete = true,
  },
  compassFilters = {
    PinHelper_areaofinterest_complete = false,
    PinHelper_areaofinterest_incomplete = false,
    PinHelper_ayleidruin_complete = false,
    PinHelper_ayleidruin_incomplete = false,
    PinHelper_battlefield_complete = false,
    PinHelper_battlefield_incomplete = false,
    PinHelper_boss_complete = false,
    PinHelper_boss_incomplete = false,
    PinHelper_camp_complete = false,
    PinHelper_camp_incomplete = false,
    PinHelper_cave_complete = false,
    PinHelper_cave_incomplete = false,
    PinHelper_cemetery_complete = false,
    PinHelper_cemetery_incomplete = false,
    PinHelper_city_complete = false,
    PinHelper_city_incomplete = false,
    PinHelper_crafting_complete = false,
    PinHelper_crafting_incomplete = false,
    PinHelper_crypt_complete = false,
    PinHelper_crypt_incomplete = false,
    PinHelper_daedricruin_complete = false,
    PinHelper_daedricruin_incomplete = false,
    PinHelper_darkbrotherhood_complete = false,
    PinHelper_darkbrotherhood_incomplete = false,
    PinHelper_delve_complete = false,
    PinHelper_delve_incomplete = false,
    PinHelper_dock_complete = false,
    PinHelper_dock_incomplete = false,
    PinHelper_dungeon_complete = false,
    PinHelper_dungeon_incomplete = false,
    PinHelper_dwemerruin_complete = false,
    PinHelper_dwemerruin_incomplete = false,
    PinHelper_estate_complete = false,
    PinHelper_estate_incomplete = false,
    PinHelper_explorable_complete = false,
    PinHelper_explorable_incomplete = false,
    PinHelper_farm_complete = false,
    PinHelper_farm_incomplete = false,
    PinHelper_gate_complete = false,
    PinHelper_gate_incomplete = false,
    PinHelper_grove_complete = false,
    PinHelper_grove_incomplete = false,
    PinHelper_house_complete = false,
    PinHelper_instance_complete = false,
    PinHelper_instance_incomplete = false,
    PinHelper_keep_complete = false,
    PinHelper_keep_incomplete = false,
    PinHelper_lighthouse_complete = false,
    PinHelper_lighthouse_incomplete = false,
    PinHelper_mine_complete = false,
    PinHelper_mine_incomplete = false,
    PinHelper_mundus_complete = false,
    PinHelper_mundus_incomplete = false,
    PinHelper_portal_complete = false,
    PinHelper_portal_incomplete = false,
    PinHelper_raiddungeon_complete = false,
    PinHelper_raiddungeon_incomplete = false,
    PinHelper_ruin_complete = false,
    PinHelper_ruin_incomplete = false,
    PinHelper_sewer_complete = false,
    PinHelper_sewer_incomplete = false,
    PinHelper_solotrial_complete = false,
    PinHelper_solotrial_incomplete = false,
    PinHelper_tower_complete = false,
    PinHelper_tower_incomplete = false,
    PinHelper_town_complete = false,
    PinHelper_town_incomplete = false,
    PinHelper_u26_dwemergear_complete = false,
    PinHelper_u26_dwemergear_incomplete = false,
    PinHelper_u26_nord_boat_complete = false,
    PinHelper_u26_nord_boat_incomplete = false,
    PinHelper_unknown = false,
    PinHelper_wayshrine_complete = true,
    PinHelper_wayshrine_incomplete = false,
  },
}

local function GetPinTexture(pin)
  local pinTag = pin.m_PinTag
  return pinTag.texture
end

local function GetPinTooltip(pin)
  local pinTag = pin.m_PinTag

  if IsInGamepadPreferredMode() then
    ZO_MapLocationTooltip_Gamepad:LayoutIconStringLine(
      ZO_MapLocationTooltip_Gamepad.tooltip,
      pinTag.texture,
      pinTag.name,
      ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("mapLocationTooltipWayshrineHeader")
    )
    if pinTag.description ~= "" then
      ZO_MapLocationTooltip_Gamepad:LayoutIconStringLine(
        ZO_MapLocationTooltip_Gamepad.tooltip,
        nil,
        pinTag.description,
        ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("mapRecallCost")
      )
    end
  else
    InformationTooltip:AddLine(pinTag.name, "ZoFontGameOutline", ZO_HIGHLIGHT_TEXT:UnpackRGB());
    if pinTag.description ~= "" then
      InformationTooltip:AddLine(pinTag.description, "", ZO_HIGHLIGHT_TEXT:UnpackRGB());
    end
  end
end

local function GetPins(targetPinType, callback)
  if GetMapType() > MAPTYPE_ZONE then return end

  local zoneIndex = GetCurrentMapZoneIndex()
  for poiIndex = 1, GetNumPOIs(zoneIndex) do
    local objectiveName, objectiveLevel, startDescription, finishedDescription = GetPOIInfo(zoneIndex, poiIndex)
    local normalizedX, normalizedY, poiType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = GetPOIMapInfo(zoneIndex, poiIndex)
    local poiCategory = LibPOI:GetPOICategory(zoneIndex, poiIndex)
    local isComplete = LibPOI:IsComplete(zoneIndex, poiIndex)
    local pinType = "PinHelper_" .. poiCategory.id .. (poiCategory.id == "unknown" and "" or (isComplete and "_complete" or "_incomplete"))

    local pinTag = {
      pinType = pinType,
      zoneIndex = zoneIndex,
      poiIndex = poiIndex,
      normalizedX = normalizedX,
      normalizedY = normalizedY,
      texture = icon,
      name = objectiveName,
      description = LibPOI:GetDescription(zoneIndex, poiIndex),
      isVisibleOnMap = LibMapPins:IsEnabled(targetPinType),
      isVisibleOnCompass = SAVED_DATA.compassFilters[pinType] == true,
    }

    if pinType == targetPinType then
      callback(pinTag)
    end
  end
end

local function CreateMapPins(pinType)
  GetPins(pinType, function(pinTag)
    if pinTag.isVisibleOnMap then
      LibMapPins:CreatePin(pinType, pinTag, pinTag.normalizedX, pinTag.normalizedY)
    end
  end)
end

local function CreateCompassPins(pinType)
  GetPins(pinType, function(pinTag)
    if pinTag.isVisibleOnCompass then
      COMPASS_PINS.pinManager:CreatePin(pinType, pinTag, pinTag.normalizedX, pinTag.normalizedY)
    else
      COMPASS_PINS.pinManager:RemovePins(pinType)
    end
  end)
end

local function OnAddOnLoaded(event, name)
  if name ~= ADDON_NAME then return end

  EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

  SAVED_DATA = ZO_SavedVars:NewAccountWide("PinHelper_SavedVariables", 1, nil, DEFAULT_DATA)

  local mapPinLayout = {
    level = 50,
    texture = GetPinTexture,
    size = 40,
    isAnimated = true,
  }

  local compassPinLayout = {
    level = 30,
    texture = "/esoui/art/antiquities/digsite_unknown.dds",
    maxDistance = 0.05,
    sizeCallback = function(pin, angle, normalizedAngle, normalizedDistance)
      if zo_abs(normalizedAngle) > 0.25 then
        pin:SetDimensions(54 - 24 * zo_abs(normalizedAngle), 54 - 24 * zo_abs(normalizedAngle))
      else
        pin:SetDimensions(48, 48)
      end
    end,
    additionalLayout = {
      function(pin, angle, normalizedAngle, normalizedDistance)
       local icon = pin:GetNamedChild("Background")
       icon:SetTexture(pin.pinTag.texture)
      end,
      function(pin)
      end,
    },
  }

  local tooltip = {
    creator = GetPinTooltip,
    tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
  }

  local pinTypes = {}
  for pinType, _isEnabled in pairs(DEFAULT_DATA.mapFilters) do
    table.insert(pinTypes, pinType)
  end
  table.sort(pinTypes)
  for _, pinType in ipairs(pinTypes) do
    local poiCategories = LibPOI:GetPOICategories()
    local poiCategoryID = string.match(pinType, "^PinHelper_(.+)_i?n?complete$") or "unknown"
    local poiCategory = poiCategories[poiCategoryID] or poiCategories.unknown
    local isComplete = string.match(pinType, "^PinHelper_.+_incomplete$") == nil
    local poiCategoryIcon = isComplete
      and poiCategory.completeIcons[1]
      or poiCategory.incompleteIcons[1]
    local poiCategoryName =
      zo_iconFormat(poiCategoryIcon, 20, 20)
      .. poiCategory.categoryName
      .. (isComplete and "" or " (Incomplete)")

    LibMapPins:AddPinType(pinType, function() CreateMapPins(pinType) end, nil, mapPinLayout, tooltip)
    LibMapPins:AddPinFilter(pinType, poiCategoryName, false, SAVED_DATA.mapFilters)

    COMPASS_PINS:AddCustomPin(pinType, function() CreateCompassPins(pinType) end, compassPinLayout)
    COMPASS_PINS:RefreshPins(pinType)
  end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
