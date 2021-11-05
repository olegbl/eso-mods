local ADDON_NAME = "PinHelper"
local ADDON_VERSION = 1.00

-- TODO: allow teleporting to wayshrines
-- TODO: allow teleporting to group instances
-- TODO: custom descriptions for Mundus Stones
-- TODO: custom descriptions for Crafting Stations
-- TODO: control size and color of pins via LibAddonMenu-2.0
-- TODO: control compass pins via CustomCompassPins
-- TODO: unowned group house icon is not rendering correctly in filter panel

if LibStub then
  PinHelper = LibStub:NewLibrary(ADDON_NAME, ADDON_VERSION)
else
  PinHelper = {}
end

local LMP = LibMapPins -- LibStub("LibMapPins-1.0")
-- local CCP = COMPASS_PINS -- LibStub("CustomCompassPins")

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
    PinHelper_cemetary_complete = false,
    PinHelper_cemetary_incomplete = true,
    PinHelper_city_complete = false,
    PinHelper_city_incomplete = true,
    PinHelper_crafting_complete = true,
    PinHelper_crafting_incomplete = true,
    PinHelper_crypt_complete = false,
    PinHelper_crypt_incomplete = true,
    PinHelper_daedricruin_complete = false,
    PinHelper_daedricruin_incomplete = true,
    PinHelper_darkbrotherhood_complete = false,
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
    PinHelper_house_complete = true,
    PinHelper_house_incomplete = true,
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
    PinHelper_wayshrine_incomplete = false,
  }
}

local function GetPinTypeFromTexture(texture)
  if texture == "/esoui/art/icons/icon_missing.dds" then
    return "PinHelper_unknown"
  end

  -- fix ESO typos
  texture = string.gsub(texture, "_compete", "_complete")
  texture = string.gsub(texture, "aylied", "ayleid")
  texture = string.gsub(texture, "cemetery", "cemetary")

  local pinBaseType =
    string.match(texture, "^/esoui/art/icons/poi/poi_(.+)_i?n?complete.?d?d?s?$") or
    string.match(texture, "^/esoui/art/icons/poi/poi_(.+)_u?n?owned.?d?d?s?$") or
    "unknown"

  local isComplete =
    string.match(texture, "^/esoui/art/icons/poi/poi_.+_(incomplete).?d?d?s?$") == nil and
    string.match(texture, "^/esoui/art/icons/poi/poi_.+_(unowned).?d?d?s?$") == nil

  -- share filters between group and solo content
  pinBaseType = string.gsub(pinBaseType, "^group_", "")
  pinBaseType = string.gsub(pinBaseType, "^group", "")

  local pinType = nil
  if pinBaseType ~= nil then
    pinType = "PinHelper_" .. pinBaseType .. (isComplete and "_complete" or "_incomplete")
  end

  if pinType == nil then
    d("[|c3399FFPinHelper|r] |cFF9933Warning|r: nil pin type \"" .. texture .. "\"")
  elseif SAVED_DATA.mapFilters[pinType] == nil then
    d("[|c3399FFPinHelper|r] |cFF9933Warning|r: unknown pin type \"" .. pinBaseType .. "\"")
    pinType = "PinHelper_unknown"
  end

  return pinType
end

local function GetCategoryNameFromPinType(pinType)
  local pinBaseType = string.match(pinType, "^PinHelper_(.+)_i?n?complete$") or "unknown"
  local isComplete = string.match(pinType, "^PinHelper_.+_incomplete$") == nil

  local texture = ""
  if pinBaseType == "unknown" then
    texture = "/esoui/art/icons/u26_unknown_antiquity_questionmark.dds"
  else
    -- fix icons for activities that don't have a solo counterpart
    if pinBaseType == "boss" then pinBaseType = "groupboss" end
    if pinBaseType == "house" then pinBaseType = "group_house" end
    if pinBaseType == "instance" then pinBaseType = "groupinstance" end

    if pinBaseType == "group_house" then
      texture = isComplete
        and ("/esoui/art/icons/poi/poi_" .. pinBaseType .. "_owned.dds")
        or ("/esoui/art/icons/poi/poi_" .. pinBaseType .. "_unowned.dds")
    else
      texture = isComplete
        and ("/esoui/art/icons/poi/poi_" .. pinBaseType .. "_complete.dds")
        or ("/esoui/art/icons/poi/poi_" .. pinBaseType .. "_incomplete.dds")
    end
  end
  local textureString = zo_iconFormat(texture, 20, 20)

  -- improve readability of some one off types
  pinBaseType = string.gsub(pinBaseType, "areaofinterest", "area_of_interest")
  pinBaseType = string.gsub(pinBaseType, "ayleidruin", "ayleid_ruin")
  pinBaseType = string.gsub(pinBaseType, "daedricruin", "daedric_ruin")
  pinBaseType = string.gsub(pinBaseType, "darkbrotherhood", "darkbrother_hood")
  pinBaseType = string.gsub(pinBaseType, "dwemergear", "dwemer_gear")
  pinBaseType = string.gsub(pinBaseType, "dwemerruin", "dwemer_ruin")
  pinBaseType = string.gsub(pinBaseType, "groupboss", "group_boss")
  pinBaseType = string.gsub(pinBaseType, "groupinstance", "group_instance")
  pinBaseType = string.gsub(pinBaseType, "u26_", "")

  local prettyName = ""
  for word in string.gmatch(pinBaseType, "[^_]+") do
    if prettyName ~= "" then
      prettyName = prettyName .. " "
    end
    prettyName = prettyName .. string.upper(string.sub(word, 1, 1)) .. string.lower(string.sub(word, 2, -1))
  end
  prettyName = textureString .. prettyName .. (isComplete and "" or " (Incomplete)")

  return prettyName
end

local function GetPinTexture(pin)
  local pinTag = pin.m_PinTag
  return pinTag.texture
end

local function GetPinTooltip(pin)
  local pinTag = pin.m_PinTag

  if IsInGamepadPreferredMode() then
    ZO_MapLocationTooltip_Gamepad:LayoutIconStringLine(
      ZO_MapLocationTooltip_Gamepad.tooltip,
      nil,
      pinTag.startDescription,
      ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("mapLocationTooltipContentName")
    )
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
    local pinType = GetPinTypeFromTexture(icon)

    local pinTag = {
      pinType = pinType,
      zoneIndex = zoneIndex,
      poiIndex = poiIndex,
      normalizedX = normalizedX,
      normalizedY = normalizedY,
      texture = icon,
      name = objectiveName,
      description = finishedDescription or startDescription,
      isVisibleOnMap = LMP:IsEnabled(targetPinType),
      isVisibleOnCompass = true,
    }

    if pinType == targetPinType then
      callback(pinTag)
    end
  end

end

local function CreateMapPins(pinType)
  GetPins(pinType, function(pinTag)
    if pinTag.isVisibleOnMap then
      LMP:CreatePin(pinType, pinTag, pinTag.normalizedX, pinTag.normalizedY)
    end
  end)
end

local function CreateCompassPins(pinType)
 GetPins(pinType, function(pinTag)
   if pinTag.isVisibleOnCompass then
     -- CCP.pinManager:CreatePin(pinType, pinTag, pinTag.normalizedX, pinTag.normalizedY)
   end
 end)
end

local function OnAddOnLoaded(event, name)
  if name ~= ADDON_NAME then return end

  EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

  SAVED_DATA = ZO_SavedVars:NewAccountWide("PinHelper_SavedVariables", 1, nil, DEFAULT_DATA)

  local layout = {
    level = 50,
    texture = GetPinTexture,
    size = 40,
    isAnimated = true,
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
    LMP:AddPinType(pinType, function() CreateMapPins(pinType) end, nil, layout, tooltip)
    LMP:AddPinFilter(pinType, GetCategoryNameFromPinType(pinType), false, SAVED_DATA.mapFilters)
  end

  -- TODO: POI pins are already being shown by something?
  -- CCP:AddCustomPin(
  --   pinType,
  --   function() CreateCompassPins(pinType) end,
  --   {
  --     maxDistance = 0.04,
  --     texture = "/esoui/art/icons/u26_unknown_antiquity_questionmark.dds",
  --     sizeCallback = function(pin, angle, normalizedAngle, normalizedDistance)
  --       pin:SetDimensions(pin.pinTag.size, pin.pinTag.size)
  --     end,
  --     additionalLayout = {
  --       function(pin, angle, normalizedAngle, normalizedDistance)
  --         local icon = pin:GetNamedChild("Background")
  --         icon:SetTexture(pin.pinTag.texture)
  --       end,
  --       function(pin)
  --       end
  --     }
  --   }
  -- )
  -- CCP:RefreshPins(pinType)
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
