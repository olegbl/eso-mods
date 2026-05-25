-- CHAT_SYSTEM is a PC-only alias for KEYBOARD_CHAT_SYSTEM; nil on console
local _ChatSystem = KEYBOARD_CHAT_SYSTEM or CHAT_SYSTEM

local MAP_NAME_TO_ZONE_ID = {}
local mapSearchSuppressingTeleport = false

local function CleanName(s)
    return (s and s ~= "") and zo_strformat("<<C:1>>", s) or (s or "")
end

local function NormalizeName(s)
    s = zo_strlower(CleanName(s))
    s = s:gsub("[%p]", " ")
    s = s:gsub("%s+", " ")
    return zo_strtrim(s)
end

local function AddMapZoneLookup(name, zoneId)
    if not name or name == "" or not zoneId or zoneId == 0 then return end
    MAP_NAME_TO_ZONE_ID[CleanName(name)] = zoneId
    MAP_NAME_TO_ZONE_ID[NormalizeName(name)] = zoneId
end

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
        if zoneId and zoneId ~= 0 then
            AddMapZoneLookup(mapName, zoneId)
            AddMapZoneLookup(GetZoneNameById(zoneId), zoneId)
        end
    end
end

local function GetZoneIdFromCandidate(candidate)
    if type(candidate) ~= "table" then return nil end
    if candidate.zoneId and candidate.zoneId ~= 0 then
        return candidate.zoneId, candidate.name
    end
    if candidate.zoneIndex and candidate.zoneIndex ~= 0 then
        local zoneId = GetZoneId(candidate.zoneIndex)
        if zoneId and zoneId ~= 0 then
            return zoneId, candidate.name
        end
    end
    if candidate.nodeIndex then
        local zoneIndex = GetFastTravelNodePOIIndicies(candidate.nodeIndex)
        if zoneIndex and zoneIndex ~= 0 then
            local zoneId = GetZoneId(zoneIndex)
            if zoneId and zoneId ~= 0 then
                return zoneId, candidate.name
            end
        end
    end
    return nil
end

local function GetFallbackZoneId()
    local saved = _G["GamePadHelperSavedVars"]
    local zoneId, name = GetZoneIdFromCandidate(saved and saved.lastSelectedPOI)
    if zoneId then return zoneId, name end

    if GetCurrentMapZoneIndex then
        local zoneIndex = GetCurrentMapZoneIndex()
        if zoneIndex and zoneIndex ~= 0 then
            zoneId = GetZoneId(zoneIndex)
            if zoneId and zoneId ~= 0 then
                return zoneId, GetZoneNameById(zoneId)
            end
        end
    end

    return nil
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

local function ExecuteTeleportFromEntry(entry, allowHouses)
    if not entry then return false end

    SCENE_MANAGER:HideCurrentScene()

    if allowHouses and entry.isOwnHouse then
        local houseName = entry.houseNameFormatted or GetString(SI_GPH_TELEPORT_PRIMARY_RESIDENCE)
        local travelOutside = entry.forceOutside or false
        if _ChatSystem then _ChatSystem:AddMessage(zo_strformat(GetString(SI_GPH_TELEPORT_CHAT_OWN_HOUSE), houseName)) end
        RequestJumpToHouse(entry.houseId, travelOutside)
        return true
    elseif allowHouses and entry.houseId then
        local owner = entry.displayName or GetString(SI_GPH_TELEPORT_FRIEND)
        local houseName = entry.houseNameFormatted or zo_strformat(GetString(SI_GPH_TELEPORT_FRIEND_HOUSE_FALLBACK), owner)
        if _ChatSystem then _ChatSystem:AddMessage(zo_strformat(GetString(SI_GPH_TELEPORT_CHAT_FRIEND_HOUSE), owner, houseName)) end
        RequestJumpToHouse(entry.houseId, entry.forceOutside)
        return true
    elseif IsFriend(entry.displayName) then
        if _ChatSystem then _ChatSystem:AddMessage(zo_strformat(GetString(SI_GPH_TELEPORT_CHAT_FRIEND), entry.displayName)) end
        JumpToFriend(entry.displayName)
        return true
    elseif entry.category == BMU.ZONE_CATEGORY_GROUP then
        if _ChatSystem then _ChatSystem:AddMessage(zo_strformat(GetString(SI_GPH_TELEPORT_CHAT_GROUP), entry.displayName)) end
        JumpToGroupMember(entry.displayName)
        return true
    else
        if _ChatSystem then _ChatSystem:AddMessage(zo_strformat(GetString(SI_GPH_TELEPORT_CHAT_GUILD), entry.displayName)) end
        JumpToGuildMember(entry.displayName)
        return true
    end
end

local function CreateTeleportCallback()
    local normalizedMouseX, normalizedMouseY = GetNormalizedMousePositionToMap()
    local success, locationName = pcall(GetMapMouseoverInfo, normalizedMouseX, normalizedMouseY)
    if not success then
        return
    end

    local cleanLocation = CleanName(locationName)
    local zoneId = MAP_NAME_TO_ZONE_ID[cleanLocation] or MAP_NAME_TO_ZONE_ID[NormalizeName(locationName)]
    if not zoneId then
        local fallbackName
        zoneId, fallbackName = GetFallbackZoneId()
        if zoneId then
            cleanLocation = CleanName(fallbackName)
        end
    end
    if not zoneId then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, zo_strformat(SI_GPH_TELEPORT_NO_ZONE_DATA, cleanLocation))
        return
    end

    if not BMU or not BMU.createTable then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_GPH_TELEPORT_BMU_REQUIRED))
        return
    end

    local jumpType, entry = FindJumpablePlayerInZone(zoneId)
    if jumpType ~= "bmu" or not entry then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_GPH_TELEPORT_NO_TARGET))
        return
    end

    ExecuteTeleportFromEntry(entry, true)
end

local KEYBOARD_KEYBIND_STRIP_DESCRIPTOR = nil
local GAMEPAD_KEYBIND_STRIP_DESCRIPTOR = nil
local CHAT_KEYBIND_STRIP_DESCRIPTOR = nil

local function IsMapSearchTeleportSuppressed()
    if mapSearchSuppressingTeleport then return true end
    local isMapSearchShowing = _G["GamePadHelper_MapSearch_IsShowing"]
    return type(isMapSearchShowing) == "function" and isMapSearchShowing() == true
end

local function PopulateKeybindStripDescriptor()
    local keybind = {
        name = GetString(SI_GPH_TELEPORT),
        keybind = "UI_SHORTCUT_QUINARY",
        enabled = function()
            return not IsMapSearchTeleportSuppressed()
                and CanLeaveCurrentLocationViaTeleport()
                and not IsUnitDead("player")
                and BMU
                and BMU.createTable
        end,
        visible = function() return not IsMapSearchTeleportSuppressed() end,
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
    if IsMapSearchTeleportSuppressed() then return end

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
    if IsMapSearchTeleportSuppressed() then return end
    KEYBIND_STRIP:UpdateKeybindButtonGroup(GAMEPAD_KEYBIND_STRIP_DESCRIPTOR)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(KEYBOARD_KEYBIND_STRIP_DESCRIPTOR)
end

_G["GamePadHelper_MapTeleporter_SetSuppressed"] = function(suppressed)
    mapSearchSuppressingTeleport = suppressed == true
    if not KEYBIND_STRIP then return end

    KEYBIND_STRIP:RemoveKeybindButtonGroup(GAMEPAD_KEYBIND_STRIP_DESCRIPTOR)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(KEYBOARD_KEYBIND_STRIP_DESCRIPTOR)

    if not mapSearchSuppressingTeleport then
        if GAMEPAD_WORLD_MAP_SCENE and GAMEPAD_WORLD_MAP_SCENE:IsShowing() then
            OnWorldMapSceneShow()
        elseif WORLD_MAP_SCENE and WORLD_MAP_SCENE:IsShowing() then
            OnWorldMapSceneShow()
        end
    end
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
                name = GetString(SI_GPH_TELEPORT),
                keybind = "UI_SHORTCUT_QUINARY",
                enabled = function()
                    return CanLeaveCurrentLocationViaTeleport() and not IsUnitDead("player")
                end,
                visible = function() return true end,
                callback = function()
                    local data = CHAT_MENU_GAMEPAD.socialData

                    if not data or not IsAnyJumpable() then
                        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_GPH_TELEPORT_NO_VALID_TARGET))
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
    EVENT_MANAGER:UnregisterForEvent("MapTeleporter", EVENT_ADD_ON_LOADED)

    PopulateMapNameToZoneIdMapping()
    PopulateKeybindStripDescriptor()

    WORLD_MAP_SCENE:RegisterCallback("StateChange", OnWorldMapSceneStateChange)
    GAMEPAD_WORLD_MAP_SCENE:RegisterCallback("StateChange", OnWorldMapSceneStateChange)
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", OnWorldMapChanged)

    -- Hide Teleport keybind when any info panel tab opens; restore when it closes
    CALLBACK_MANAGER:RegisterCallback("WorldMapInfo_Gamepad_Showing", function()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(GAMEPAD_KEYBIND_STRIP_DESCRIPTOR)
    end)
    CALLBACK_MANAGER:RegisterCallback("WorldMapInfo_Gamepad_Hidden", function()
        local sv = _G["GamePadHelper_SavedVars"]
        if sv and sv.teleporterEnabled and IsInGamepadPreferredMode()
           and GAMEPAD_WORLD_MAP_SCENE:IsShowing() then
            KEYBIND_STRIP:AddKeybindButtonGroup(GAMEPAD_KEYBIND_STRIP_DESCRIPTOR)
        end
    end)

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

EVENT_MANAGER:RegisterForEvent("MapTeleporter", EVENT_ADD_ON_LOADED, OnAddonLoaded)
