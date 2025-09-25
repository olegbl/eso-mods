local ADDON_NAME = "GamePadHelper_Teleporter"
local ADDON_VERSION = 1.04

-- Ensure ESO API compatibility
if GetAPIVersion() < 101047 then
    d("[" .. ADDON_NAME .. "] ESO API version too old. Requires API 101047 or higher.")
    return
end

local MAP_NAME_TO_ZONE_ID = {}

-- Helper function to get normalized mouse position for map interactions
local function GetNormalizedMousePositionToMap()
    if IsInGamepadPreferredMode() then
        local x, y = ZO_WorldMapScroll:GetCenter()
        return NormalizePointToControl(x, y, ZO_WorldMapContainer)
    else
        return NormalizeMousePositionToControl(ZO_WorldMapContainer)
    end
end

local function PopulateMapNameToZoneIdMapping()
    for mapIndex = 1, GetNumMaps() do
        local mapName, mapType, mapContentType, zoneIndex, description = GetMapInfoByIndex(mapIndex)
        local zoneId = GetZoneId(zoneIndex)
        MAP_NAME_TO_ZONE_ID[mapName] = zoneId
    end
end

local function FindJumpablePlayerInZone(zoneId)
    if not BMU or not BMU.createTable then return nil end
    
    -- Try players first
    local success, resultTable = pcall(BMU.createTable, {index=6, fZoneId=zoneId, dontDisplay=true})
    if success and resultTable and resultTable[1] then
        local entry = resultTable[1]
        
        -- Check for valid player
        if entry.displayName and entry.displayName ~= "" and not string.match(entry.displayName, "^%(%d+%)$") then
            return "bmu", entry
        end
        
        -- Check for house
        if entry.houseId or entry.isOwnHouse then
            return "bmu", entry
        end
    end

    -- Fallback to houses
    success, resultTable = pcall(BMU.createTable, {index=7, fZoneId=zoneId, dontDisplay=true})
    if success and resultTable and resultTable[1] then
        local entry = resultTable[1]
        if entry.houseId or entry.isOwnHouse or entry.category == BMU.ZONE_CATEGORY_HOUSE then
            return "bmu", entry
        end
    end

    return nil
end

local KEYBOARD_KEYBIND_STRIP_DESCRIPTOR = nil
local GAMEPAD_KEYBIND_STRIP_DESCRIPTOR = nil
local CHAT_KEYBIND_STRIP_DESCRIPTOR = nil
local function ExecuteTeleportFromEntry(entry, allowHouses)
    if not entry then return false end
    
    SCENE_MANAGER:HideCurrentScene()

    -- House teleportation only allowed from map, not from chat menu
    if allowHouses and entry.isOwnHouse then
        local houseName = entry.houseNameFormatted or "Primary Residence"
        local travelOutside = entry.forceOutside or false
        CHAT_SYSTEM:AddMessage("[Teleport] your house: " .. houseName)

        RequestJumpToHouse(entry.houseId, travelOutside)
        return true
    elseif allowHouses and entry.houseId then
        local owner = entry.displayName or "Friend"
        local houseName = entry.houseNameFormatted or (owner .. "'s house")
        CHAT_SYSTEM:AddMessage("[Teleport] " .. owner .. "'s house: " .. houseName)

        RequestJumpToHouse(entry.houseId, entry.forceOutside)
        return true
    elseif IsFriend(entry.displayName) then
        CHAT_SYSTEM:AddMessage("[Teleport] friend " .. entry.displayName)
        JumpToFriend(entry.displayName)
        return true
    elseif entry.category == BMU.ZONE_CATEGORY_GROUP then
        CHAT_SYSTEM:AddMessage("[Teleport] group member " .. entry.displayName)
        JumpToGroupMember(entry.displayName)
        return true
    else
        CHAT_SYSTEM:AddMessage("[Teleport] guild member " .. entry.displayName)
        JumpToGuildMember(entry.displayName)
        return true
    end
end

local function CreateTeleportCallback()
    local normalizedMouseX, normalizedMouseY = GetNormalizedMousePositionToMap()
    local success, locationName = pcall(GetMapMouseoverInfo, normalizedMouseX, normalizedMouseY)
    if not success then
        d("[" .. ADDON_NAME .. "] Error getting map mouseover info: " .. tostring(locationName))
        return
    end

    local zoneId = MAP_NAME_TO_ZONE_ID[locationName]
    if not zoneId then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "No zone data for " .. locationName)
        return
    end

    local jumpType, entry = FindJumpablePlayerInZone(zoneId)
    if jumpType ~= "bmu" or not entry then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "No players or houses found to port to")
        return
    end

    ExecuteTeleportFromEntry(entry, true)  -- Allow houses for map teleportation
end

local function PopulateKeybindStripDescriptor()
  local keybind = {
    name = "Teleport",
    keybind = "UI_SHORTCUT_QUINARY",
    enabled = function()
      return CanLeaveCurrentLocationViaTeleport() and not IsUnitDead("player") and BMU and BMU.createTable
    end,
    visible = function() return true end,
    callback = CreateTeleportCallback,
  }

  KEYBOARD_KEYBIND_STRIP_DESCRIPTOR = { alignment = KEYBIND_STRIP_ALIGN_CENTER, keybind }
  GAMEPAD_KEYBIND_STRIP_DESCRIPTOR  = { alignment = KEYBIND_STRIP_ALIGN_LEFT,   keybind }
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

-- Helper functions for teleportation eligibility
local function IsFriendJumpable()
    if not CHAT_MENU_GAMEPAD.socialData or not CHAT_MENU_GAMEPAD.socialData.displayName then return false end
    return IsFriend(CHAT_MENU_GAMEPAD.socialData.displayName)
end

local function IsGuildJumpable()
    if IsFriendJumpable() then return false end
    if not CHAT_MENU_GAMEPAD.socialData or not CHAT_MENU_GAMEPAD.socialData.category then return false end

    if CHAT_MENU_GAMEPAD.socialData.category == CHAT_CATEGORY_GUILD_1 or
        CHAT_MENU_GAMEPAD.socialData.category == CHAT_CATEGORY_GUILD_2 or
        CHAT_MENU_GAMEPAD.socialData.category == CHAT_CATEGORY_GUILD_3 or
        CHAT_MENU_GAMEPAD.socialData.category == CHAT_CATEGORY_GUILD_4 or
        CHAT_MENU_GAMEPAD.socialData.category == CHAT_CATEGORY_GUILD_5 or
        CHAT_MENU_GAMEPAD.socialData.category == CHAT_CATEGORY_OFFICER_1 or
        CHAT_MENU_GAMEPAD.socialData.category == CHAT_CATEGORY_OFFICER_2 or
        CHAT_MENU_GAMEPAD.socialData.category == CHAT_CATEGORY_OFFICER_3 or
        CHAT_MENU_GAMEPAD.socialData.category == CHAT_CATEGORY_OFFICER_4 or
        CHAT_MENU_GAMEPAD.socialData.category == CHAT_CATEGORY_OFFICER_5
    then
        return CHAT_MENU_GAMEPAD:SelectedDataIsNotPlayer()
    end

    return false
end

local function IsGroupJumpable()
    if IsFriendJumpable() then return false end
    if not CHAT_MENU_GAMEPAD.socialData or not CHAT_MENU_GAMEPAD.socialData.category then return false end
    return CHAT_MENU_GAMEPAD.socialData.category == CHAT_CATEGORY_PARTY
end

local function IsAnyJumpable()
    if not CHAT_MENU_GAMEPAD.socialData then return false end
    
    local data = CHAT_MENU_GAMEPAD.socialData
    
    -- For chat menu, only allow teleporting to friends, guild members, and group members
    -- House teleportation is disabled for chat menu
    return IsFriendJumpable() or IsGuildJumpable() or IsGroupJumpable()
end

local _keybindInitialized = nil
local function GamepadChatInit()
    if not _keybindInitialized then
        _keybindInitialized = true
        CHAT_KEYBIND_STRIP_DESCRIPTOR = {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            {
                name = "Teleport",
                keybind = "UI_SHORTCUT_QUINARY",
                enabled = function()
                    return CanLeaveCurrentLocationViaTeleport() and not IsUnitDead("player")
                end,
                visible = function() return true end,
                callback = function()
                    local data = CHAT_MENU_GAMEPAD.socialData
                    
                    if not data or not IsAnyJumpable() then
                        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "No valid teleportable target selected")
                        return
                    end
                    
                    ExecuteTeleportFromEntry(data, false)  -- Disable houses for chat menu teleportation
                end,
            }
        }
    end

    KEYBIND_STRIP:AddKeybindButtonGroup(CHAT_KEYBIND_STRIP_DESCRIPTOR)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(CHAT_KEYBIND_STRIP_DESCRIPTOR)
    return false
end

local function OnAddOnLoaded(event, name)
  if name ~= ADDON_NAME then return end

  PopulateMapNameToZoneIdMapping()
  PopulateKeybindStripDescriptor()

  WORLD_MAP_SCENE:RegisterCallback("StateChange", OnWorldMapSceneStateChange)
  GAMEPAD_WORLD_MAP_SCENE:RegisterCallback("StateChange", OnWorldMapSceneStateChange)
  CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", OnWorldMapChanged)

  -- Initialize chat teleporting
  ZO_PreHook(CHAT_MENU_GAMEPAD, "OnShow", GamepadChatInit)

   -- Hook into selection changes to update teleport button state
  ZO_PreHook(CHAT_MENU_GAMEPAD, "OnTargetChanged", function(self, list, targetData, oldTargetData, reachedTarget, targetSelectedIndex)
    CHAT_MENU_GAMEPAD.socialData = targetData and (targetData.data or targetData) or nil
    if CHAT_KEYBIND_STRIP_DESCRIPTOR then
      KEYBIND_STRIP:UpdateKeybindButtonGroup(CHAT_KEYBIND_STRIP_DESCRIPTOR)
    end
  end)

  ZO_PreHook(CHAT_MENU_GAMEPAD, "OnHide", function() 
      KEYBIND_STRIP:RemoveKeybindButtonGroup(CHAT_KEYBIND_STRIP_DESCRIPTOR) 
  end)

end

-- Event handler for addon loaded
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, function(event, addonName)
    if addonName == ADDON_NAME then
        OnAddOnLoaded(event, addonName)
        EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
    end
end)