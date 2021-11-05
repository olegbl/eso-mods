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
    PinHelper_camp_complete = false,
    PinHelper_camp_incomplete = true,
    PinHelper_cemetery_complete = false,
    PinHelper_cemetery_incomplete = true,
    PinHelper_city_complete = false,
    PinHelper_city_incomplete = true,
    PinHelper_crafting_complete = true,
    PinHelper_crafting_incomplete = true,
    PinHelper_delve_complete = false,
    PinHelper_delve_incomplete = true,
    PinHelper_dock_complete = false,
    PinHelper_dock_incomplete = true,
    PinHelper_dungeon_complete = false,
    PinHelper_dungeon_incomplete = true,
    PinHelper_group_house_complete = true,
    PinHelper_group_house_incomplete = true,
    PinHelper_groupboss_complete = false,
    PinHelper_groupboss_incomplete = true,
    PinHelper_groupinstance_complete = false,
    PinHelper_groupinstance_incomplete = false,
    PinHelper_grove_complete = false,
    PinHelper_grove_incomplete = true,
    PinHelper_mine_complete = false,
    PinHelper_mine_incomplete = true,
    PinHelper_mundus_complete = true,
    PinHelper_mundus_incomplete = true,
    PinHelper_portal_complete = true,
    PinHelper_portal_incomplete = true,
    PinHelper_ruin_complete = false,
    PinHelper_ruin_incomplete = true,
    PinHelper_town_complete = false,
    PinHelper_town_incomplete = true,
    PinHelper_unknown_complete = true,
    PinHelper_unknown_incomplete = true,
    PinHelper_wayshrine_complete = false,
    PinHelper_wayshrine_incomplete = false,
  }
}

local function GetPinTypeFromTexture(texture)
  -- "poi_mine_compete" is a fun typo
  texture = string.gsub(texture, "_compete", "_complete")

  local pinBaseType =
    string.match(texture, "^/esoui/art/icons/poi/poi_(.+)_i?n?complete.?d?d?s?$") or
    string.match(texture, "^/esoui/art/icons/poi/poi_(.+)_u?n?owned.?d?d?s?$")

  local isComplete =
    string.match(texture, "^/esoui/art/icons/poi/poi_.+_(incomplete).?d?d?s?$") == nil and
    string.match(texture, "^/esoui/art/icons/poi/poi_.+_(unowned).?d?d?s?$") == nil

  local pinType = nil
  if pinBaseType ~= nil then
    pinType = "PinHelper_" .. pinBaseType .. (isComplete and "_complete" or "_incomplete")
  end

  if pinType == nil then
    d("[|c3399FFPinHelper|r] |cFF9933Warning|r: nil pin type \"" .. texture .. "\"")
  elseif SAVED_DATA.mapFilters[pinType] == nil then
    d("[|c3399FFPinHelper|r] |cFF9933Warning|r: unknown pin type \"" .. pinBaseType .. "\"")
    pinType = "PinHelper_unknown_" .. (isComplete and "complete" or "incomplete")
  end

  return pinType
end

local function GetCategoryNameFromPinType(pinType)
  local pinBaseType = string.match(pinType, "^PinHelper_(.+)_i?n?complete$")
  local isComplete = string.match(pinType, "^PinHelper_.+_incomplete$") == nil

  local texture = ""
  if pinBaseType == "unknown" then
    texture = "/esoui/art/icons/u26_unknown_antiquity_questionmark.dds"
  else
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

  if pinBaseType ~= nil then
    pinBaseType = string.gsub(pinBaseType, "areaofinterest", "area_of_interest")
    pinBaseType = string.gsub(pinBaseType, "ayleidruin", "ayleid_ruin")
    pinBaseType = string.gsub(pinBaseType, "groupboss", "group_boss")
    pinBaseType = string.gsub(pinBaseType, "groupinstance", "group_instance")
  end

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
  for pinType, _isEnabled in pairs(SAVED_DATA.mapFilters) do
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
