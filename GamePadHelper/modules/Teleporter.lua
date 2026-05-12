-- CHAT_SYSTEM is a PC-only alias for KEYBOARD_CHAT_SYSTEM; nil on console
local _ChatSystem = KEYBOARD_CHAT_SYSTEM or CHAT_SYSTEM

local MAP_NAME_TO_ZONE_ID = {}

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

    local success, resultTable = pcall(BMU.createTable, {index=6, fZoneId=zoneId, dontDisplay=true})
    if success and resultTable and resultTable[1] then
        local entry = resultTable[1]

        if entry.displayName and entry.displayName ~= "" and not string.match(entry.displayName, "^%(%d+%)$") then
            return "bmu", entry
        end

        if entry.houseId or entry.isOwnHouse then
            return "bmu", entry
        end
    end

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

    if allowHouses and entry.isOwnHouse then
        local houseName = entry.houseNameFormatted or "Primary Residence"
        local travelOutside = entry.forceOutside or false
        if _ChatSystem then _ChatSystem:AddMessage("[Teleport] your house: " .. houseName) end
        RequestJumpToHouse(entry.houseId, travelOutside)
        return true
    elseif allowHouses and entry.houseId then
        local owner = entry.displayName or "Friend"
        local houseName = entry.houseNameFormatted or (owner .. "'s house")
        if _ChatSystem then _ChatSystem:AddMessage("[Teleport] " .. owner .. "'s house: " .. houseName) end
        RequestJumpToHouse(entry.houseId, entry.forceOutside)
        return true
    elseif IsFriend(entry.displayName) then
        if _ChatSystem then _ChatSystem:AddMessage("[Teleport] friend " .. entry.displayName) end
        JumpToFriend(entry.displayName)
        return true
    elseif entry.category == BMU.ZONE_CATEGORY_GROUP then
        if _ChatSystem then _ChatSystem:AddMessage("[Teleport] group member " .. entry.displayName) end
        JumpToGroupMember(entry.displayName)
        return true
    else
        if _ChatSystem then _ChatSystem:AddMessage("[Teleport] guild member " .. entry.displayName) end
        JumpToGuildMember(entry.displayName)
        return true
    end
end

local function CreateTeleportCallback()
    local normalizedMouseX, normalizedMouseY = GetNormalizedMousePositionToMap()
    local success, locationName = pcall(GetMapMouseoverInfo, normalizedMouseX, normalizedMouseY)
    if not success then
        d("[GamePadHelper] Error getting map mouseover info: " .. tostring(locationName))
        return
    end

    local zoneId = MAP_NAME_TO_ZONE_ID[locationName]
    if not zoneId then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "No zone data for " .. locationName)
        return
    end

    if not BMU or not BMU.createTable then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "BeamMeUp is required for map teleportation")
        return
    end

    local jumpType, entry = FindJumpablePlayerInZone(zoneId)
    if jumpType ~= "bmu" or not entry then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "No players or houses found to port to")
        return
    end

    ExecuteTeleportFromEntry(entry, true)
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
    local sv = _G["GamePadHelper_SavedVars"]
    if not sv or not sv.teleporterEnabled then return end
    KEYBIND_STRIP:RemoveKeybindButtonGroup(GAMEPAD_KEYBIND_STRIP_DESCRIPTOR)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(KEYBOARD_KEYBIND_STRIP_DESCRIPTOR)

    if IsInGamepadPreferredMode() then
        KEYBIND_STRIP:AddKeybindButtonGroup(GAMEPAD_KEYBIND_STRIP_DESCRIPTOR)
    else
        KEYBIND_STRIP:AddKeybindButtonGroup(KEYBOARD_KEYBIND_STRIP_DESCRIPTOR)
    end
end

local function OnWorldMapSceneHide()
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
    return IsFriendJumpable() or IsGuildJumpable() or IsGroupJumpable()
end

local _keybindInitialized = nil
local function GamepadChatInit()
    local sv = _G["GamePadHelper_SavedVars"]
    if not sv or not sv.teleporterEnabled then return false end
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

                    ExecuteTeleportFromEntry(data, false)
                end,
            }
        }
    end

    KEYBIND_STRIP:AddKeybindButtonGroup(CHAT_KEYBIND_STRIP_DESCRIPTOR)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(CHAT_KEYBIND_STRIP_DESCRIPTOR)
    return false
end

local function OnAddonLoaded(event, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("Teleporter", EVENT_ADD_ON_LOADED)

    PopulateMapNameToZoneIdMapping()
    PopulateKeybindStripDescriptor()

    WORLD_MAP_SCENE:RegisterCallback("StateChange", OnWorldMapSceneStateChange)
    GAMEPAD_WORLD_MAP_SCENE:RegisterCallback("StateChange", OnWorldMapSceneStateChange)
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", OnWorldMapChanged)

    ZO_PreHook(CHAT_MENU_GAMEPAD, "OnShow", GamepadChatInit)

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

EVENT_MANAGER:RegisterForEvent("Teleporter", EVENT_ADD_ON_LOADED, OnAddonLoaded)
