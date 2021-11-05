local ADDON_NAME = "PinHelper"
local ADDON_VERSION = 1.00

if LibStub then
  PinHelper = LibStub:NewLibrary(ADDON_NAME, ADDON_VERSION)
else
  PinHelper = {}
end

local LMP = LibMapPins -- LibStub("LibMapPins-1.0")

local PIN_TYPE_POI = "PinHelper_POI"

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
    InformationTooltip:AddLine(pinTag.texture, "", ZO_HIGHLIGHT_TEXT:UnpackRGB());
  end
end

local function OnCreatePins()
  if GetMapType() > MAPTYPE_ZONE then return end
  -- if not LMP:IsEnabled(PIN_TYPE_POI) or GetMapType() > MAPTYPE_ZONE then return end

  local zoneIndex = GetCurrentMapZoneIndex()
  for poiIndex = 1, GetNumPOIs(zoneIndex) do
    local isWayshrine = IsPOIWayshrine(zoneIndex, poiIndex)
    local isPublicDungeon = IsPOIPublicDungeon(zoneIndex, poiIndex)
    local isGroupDungeon = IsPOIGroupDungeon(zoneIndex, poiIndex)
    local objectiveName, objectiveLevel, startDescription, finishedDescription = GetPOIInfo(zoneIndex, poiIndex)
    local normalizedX, normalizedY, poiType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = GetPOIMapInfo(zoneIndex, poiIndex)

    local pinTag = {
      pinTypeString = PIN_TYPE_POI,
      zoneIndex = zoneIndex,
      poiIndex = poiIndex,
      poiType = poiType, -- https://wiki.esoui.com/Globals#MapDisplayPinType
      texture = icon,
      name = objectiveName,
      description = isDiscovered and finishedDescription or startDescription,
    }

    if not isWayshrine and not isPublicDungeon and not isGroupDungeon then
      LMP:CreatePin(PIN_TYPE_POI, pinTag, normalizedX, normalizedY)
    end
  end
end

-- TODO: save to disk with ZO_SavedVars
local filters = {
  [PIN_TYPE_POI] = true
}

local function OnAddOnLoaded(event, name)
  if name ~= ADDON_NAME then return end

  EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

  LMP:AddPinType(
    PIN_TYPE_POI,
    OnCreatePins,
    nil,
    {
      level = 50, -- POI
      texture = GetPinTexture,
      size = 40,
      isAnimated = true,
    },
    {
      creator = GetPinTooltip,
      tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
    }
  )

  LMP:Enable(PIN_TYPE_POI)

  -- TODO: allow toggling on/off different types of pins
  -- LMP:AddPinFilter(
  --   PIN_TYPE_POI,
  --   "PinHelper: Unknown POIs",
  --   false,
  --   filters
  -- )
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
