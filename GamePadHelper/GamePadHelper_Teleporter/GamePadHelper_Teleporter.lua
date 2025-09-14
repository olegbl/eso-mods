local ADDON_NAME = "GamePadHelper_Teleporter"
local ADDON_VERSION = 1.03

-- Ensure ESO API compatibility
if GetAPIVersion() < 101047 then
    d("[" .. ADDON_NAME .. "] ESO API version too old. Requires API 101047 or higher.")
    return
end

-- https://github.com/esoui/esoui/blob/e966309767c2158e1ad22c326f6562bae365efa5/esoui/ingame/map/worldmap.lua#L210
local function GetNormalizedMousePositionToMap()
    if IsInGamepadPreferredMode() then
        local x, y = ZO_WorldMapScroll:GetCenter()
        return NormalizePointToControl(x, y, ZO_WorldMapContainer)
    else
        return NormalizeMousePositionToControl(ZO_WorldMapContainer)
    end
end

local MAP_NAME_TO_ZONE_ID = {}
local function PopulateMapNameToZoneIdMapping()
  for mapIndex = 1, GetNumMaps() do
    local mapName, mapType, mapContentType, zoneIndex, description = GetMapInfoByIndex(mapIndex)
    local zoneId = GetZoneId(zoneIndex)
    MAP_NAME_TO_ZONE_ID[mapName] = zoneId
  end
end

local function GetIsTeleportKeybindEnabled()
  local mapType = GetMapType()
  return mapType == MAPTYPE_WORLD or mapType == MAPTYPE_COSMIC
end

local KEYBOARD_KEYBIND_STRIP_DESCRIPTOR = nil
local GAMEPAD_KEYBIND_STRIP_DESCRIPTOR = nil
local function PopulateKeybindStripDescriptor()
  local keybind = {
    name = "Teleport",

    -- this keybind is really finicky since it does not show up in the UI
    -- if it duplicates any base game shortcut (even if the base game shortcut
    -- is being hidden)
    keybind = "UI_SHORTCUT_QUINARY",

    enabled = function()
      return GetIsTeleportKeybindEnabled() and CanLeaveCurrentLocationViaTeleport() and not IsUnitDead("player")
    end,

    visible = function()
      return GetIsTeleportKeybindEnabled()
    end,

    callback = function()
       if not GetIsTeleportKeybindEnabled() then return end

       -- Check if BeamMeUp is available
       if not BMU or not BMU.createTable or not BMU.PortalToPlayer then
           ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "BeamMeUp addon not found or incompatible")
           return
       end

       local normalizedMouseX, normalizedMouseY = GetNormalizedMousePositionToMap()
       local success, locationName, textureFile, textureWidthNormalized, textureHeightNormalized, textureXOffsetNormalized, textureYOffsetNormalized = pcall(GetMapMouseoverInfo, normalizedMouseX, normalizedMouseY)
       if not success then
           d("[" .. ADDON_NAME .. "] Error getting map mouseover info: " .. tostring(locationName))
           return
       end

       local zoneId = MAP_NAME_TO_ZONE_ID[locationName]

       if zoneId ~= nil then
         -- use BeamMeUp to teleport
         -- using BMU.sc_porting(zoneId) would be even cleaner
         -- but there's no way to know if it worked or not
         local success2, resultTable = pcall(BMU.createTable, {index=6, fZoneId=zoneId, dontDisplay=true})
         if not success2 then
             d("[" .. ADDON_NAME .. "] Error creating BeamMeUp table: " .. tostring(resultTable))
             ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "Error accessing BeamMeUp teleport data")
             return
         end

         local entry = resultTable and resultTable[1]

         if entry and entry.displayName ~= nil and entry.displayName ~= "" then
           local success3 = pcall(BMU.PortalToPlayer, entry.displayName, entry.sourceIndexLeading, entry.zoneName, entry.zoneId, entry.category, true, true, true)
           if success3 then
               SCENE_MANAGER:HideCurrentScene()
           else
               ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "Teleport failed")
           end
         else
           ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "No players found to port to")
         end
       end
     end,
  }

  KEYBOARD_KEYBIND_STRIP_DESCRIPTOR = {
    alignment = KEYBIND_STRIP_ALIGN_CENTER,
    keybind
  }

  GAMEPAD_KEYBIND_STRIP_DESCRIPTOR = {
    alignment = KEYBIND_STRIP_ALIGN_LEFT,
    keybind
  }
end

local function OnWorldMapSceneShow()
  -- make sure to not add the strip twice by accident
  KEYBIND_STRIP:RemoveKeybindButtonGroup(GAMEPAD_KEYBIND_STRIP_DESCRIPTOR)
  KEYBIND_STRIP:RemoveKeybindButtonGroup(KEYBOARD_KEYBIND_STRIP_DESCRIPTOR)

  if IsInGamepadPreferredMode() then
    KEYBIND_STRIP:AddKeybindButtonGroup(GAMEPAD_KEYBIND_STRIP_DESCRIPTOR)
  else
    KEYBIND_STRIP:AddKeybindButtonGroup(KEYBOARD_KEYBIND_STRIP_DESCRIPTOR)
  end
end

local function OnWorldMapSceneHide()
  -- hide both strips in case gamepad mode was toggled which on the world map
  KEYBIND_STRIP:RemoveKeybindButtonGroup(GAMEPAD_KEYBIND_STRIP_DESCRIPTOR)
  KEYBIND_STRIP:RemoveKeybindButtonGroup(KEYBOARD_KEYBIND_STRIP_DESCRIPTOR)
end

local function OnWorldMapSceneStateChange(oldState, newState)
  if newState == SCENE_SHOWING then
    OnWorldMapSceneShow()
  elseif newState == SCENE_HIDING then
    OnWorldMapSceneHide()
  end
end

local function OnWorldMapChanged(event, zoneName, subZoneName, newSubzone, zoneId, subZoneId)
  KEYBIND_STRIP:UpdateKeybindButtonGroup(GAMEPAD_KEYBIND_STRIP_DESCRIPTOR)
  KEYBIND_STRIP:UpdateKeybindButtonGroup(KEYBOARD_KEYBIND_STRIP_DESCRIPTOR)
end

local function OnAddOnLoaded(event, name)
  if name ~= ADDON_NAME then return end

  PopulateMapNameToZoneIdMapping()
  PopulateKeybindStripDescriptor()

  WORLD_MAP_SCENE:RegisterCallback("StateChange", OnWorldMapSceneStateChange)
  GAMEPAD_WORLD_MAP_SCENE:RegisterCallback("StateChange", OnWorldMapSceneStateChange)
  CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", OnWorldMapChanged)
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
