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
        local mapName, _, _, zoneIndex = GetMapInfoByIndex(mapIndex)
        local zoneId = GetZoneId(zoneIndex)
        if zoneId and zoneId ~= 0 then
            AddMapZoneLookup(mapName, zoneId)
            AddMapZoneLookup(GetZoneNameById(zoneId), zoneId)
        end
    end
end

local function GetFallbackZoneId()
    local saved = _G["GamePadHelper_SavedVars"]
    local candidate = saved and saved.lastSelectedPOI
    if type(candidate) == "table" then
        if candidate.zoneId and candidate.zoneId ~= 0 then
            return candidate.zoneId, candidate.name
        end
        if candidate.zoneIndex and candidate.zoneIndex ~= 0 then
            local zoneId = GetZoneId(candidate.zoneIndex)
            if zoneId and zoneId ~= 0 then return zoneId, candidate.name end
        end
        if candidate.nodeIndex then
            local zoneIndex = GetFastTravelNodePOIIndicies(candidate.nodeIndex)
            if zoneIndex and zoneIndex ~= 0 then
                local zoneId = GetZoneId(zoneIndex)
                if zoneId and zoneId ~= 0 then return zoneId, candidate.name end
            end
        end
    end
    if GetCurrentMapZoneIndex then
        local zoneIndex = GetCurrentMapZoneIndex()
        if zoneIndex and zoneIndex ~= 0 then
            local zoneId = GetZoneId(zoneIndex)
            if zoneId and zoneId ~= 0 then
                return zoneId, GetZoneNameById(zoneId)
            end
        end
    end
    return nil
end

-- zone / social helpers

local function ZonesOverlap(zoneA, zoneB)
    if not zoneA or not zoneB or zoneA == 0 or zoneB == 0 then return false end
    if zoneA == zoneB then return true end
    local pA = GetParentZoneId(zoneA)
    local pB = GetParentZoneId(zoneB)
    if pA and pA ~= 0 and pA ~= zoneA then
        if pA == zoneB then return true end
    end
    if pB and pB ~= 0 and pB ~= zoneB then
        if pB == zoneA then return true end
        if pA and pA == pB then return true end
    end
    return false
end

local teleportChainId = 0

local function FindPlayersInZone(targetZoneId)
    local myName = GetDisplayName()
    local results, seen = {}, {}

    -- friends first
    for j = 1, GetNumFriends() do
        local displayName, _, status = GetFriendInfo(j)
        if displayName and displayName ~= "" and displayName ~= myName and status ~= PLAYER_STATUS_OFFLINE and not seen[displayName] then
            local hasChar, charName, _, _, _, _, _, zoneId = GetFriendCharacterInfo(j)
            if hasChar and zoneId and zoneId ~= 0 and ZonesOverlap(zoneId, targetZoneId) then
                seen[displayName] = true
                results[#results + 1] = { displayName = displayName, charName = charName }
            end
        end
    end

    -- then group/party members
    for i = 1, GetGroupSize() do
        local tag = GetGroupUnitTagByIndex(i)
        if tag and IsUnitOnline(tag) and not IsGroupMemberInRemoteRegion(tag) then
            local displayName = GetUnitDisplayName(tag)
            if displayName and displayName ~= "" and displayName ~= myName and not seen[displayName] then
                local zoneIndex = GetUnitZoneIndex(tag)
                if zoneIndex and zoneIndex ~= 0 then
                    local zoneId = GetZoneId(zoneIndex)
                    if zoneId and zoneId ~= 0 and ZonesOverlap(zoneId, targetZoneId) then
                        seen[displayName] = true
                        results[#results + 1] = { displayName = displayName, charName = GetUnitName(tag), isGroup = true }
                    end
                end
            end
        end
    end

    -- then guild members
    for i = 1, GetNumGuilds() do
        local guildId = GetGuildId(i)
        for j = 1, GetNumGuildMembers(guildId) do
            local displayName, _, _, status = GetGuildMemberInfo(guildId, j)
            if displayName ~= myName and status ~= PLAYER_STATUS_OFFLINE and not seen[displayName] then
                local _, charName, _, _, _, _, _, zoneId = GetGuildMemberCharacterInfo(guildId, j)
                if zoneId and zoneId ~= 0 and ZonesOverlap(zoneId, targetZoneId) then
                    seen[displayName] = true
                    results[#results + 1] = { displayName = displayName, charName = charName }
                end
            end
        end
    end

    return #results > 0 and results or nil
end

local TryPlayersFromIndex  -- forward declaration

local function TeleportToPlayer(player)
    local displayName = type(player) == "table" and player.displayName or player
    local alertName = (type(player) == "table" and player.charName and player.charName ~= "") and player.charName or displayName
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GPH_TELEPORTING_TO, alertName))
    if type(player) == "table" and player.isGroup then
        JumpToGroupMember(displayName)
    elseif IsFriend(displayName) then
        JumpToFriend(displayName)
    else
        JumpToGuildMember(displayName)
    end
end

TryPlayersFromIndex = function(players, index, onAllFailed)
    if index == 1 then
        teleportChainId = teleportChainId + 1
    end
    if index > #players then
        if onAllFailed then onAllFailed() end
        return
    end
    local chainId   = teleportChainId
    local jumpName  = "TryPlayers_Jump_"  .. chainId
    local activName = "TryPlayers_Activ_" .. chainId
    local done        = false
    local jumpStarted = false

    local function cleanup()
        EVENT_MANAGER:UnregisterForEvent(jumpName,  EVENT_JUMP_FAILED)
        EVENT_MANAGER:UnregisterForEvent(activName, EVENT_PLAYER_ACTIVATED)
    end

    local function onFail()
        done = true
        cleanup()
        local p = players[index]
        local name = type(p) == "table" and ((p.charName ~= "" and p.charName) or p.displayName) or tostring(p)
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, zo_strformat(SI_GPH_TELEPORT_PLAYER_UNREACHABLE, name))
        TryPlayersFromIndex(players, index + 1, onAllFailed)
    end

    -- success: zone loaded
    EVENT_MANAGER:RegisterForEvent(activName, EVENT_PLAYER_ACTIVATED, function()
        if done then return end
        done = true
        cleanup()
    end)

    -- EVENT_JUMP_FAILED fires for all jump results (success-initiation and failures)
    EVENT_MANAGER:RegisterForEvent(jumpName, EVENT_JUMP_FAILED, function(_, reason)
        if done then return end
        if reason == JUMP_RESULT_REMOTE_JUMP_INITIATED
        or reason == JUMP_RESULT_LOCAL_JUMP_SUCCESSFUL
        or reason == JUMP_RESULT_JUMP_CONVERTED_TO_REMOTE
        or reason == JUMP_RESULT_JUMP_CONVERTED_TO_LOCAL then
            jumpStarted = true  -- jump confirmed started, wait for EVENT_PLAYER_ACTIVATED
            EVENT_MANAGER:UnregisterForEvent(jumpName, EVENT_JUMP_FAILED)
            return
        end
        onFail()
    end)

    TeleportToPlayer(players[index])

    -- fallback: if EVENT_JUMP_FAILED never fires and jump never started after 4s = silent drop
    zo_callLater(function()
        if done or jumpStarted then return end
        onFail()
    end, 4000)
end

local function FindWayshrineInZone(targetZoneId)
    local best, bestPriority = nil, -math.huge
    for nodeIndex = 1, GetNumFastTravelNodes() do
        local known, _, _, _, _, _, typePOI, _, isLocked = GetFastTravelNodeInfo(nodeIndex)
        if known and not isLocked and typePOI == POI_TYPE_WAYSHRINE then
            local zoneIndex = GetFastTravelNodePOIIndicies(nodeIndex)
            if zoneIndex and zoneIndex ~= 0 then
                local zoneId = GetZoneId(zoneIndex)
                if ZonesOverlap(zoneId, targetZoneId) then
                    local priority = GetFastTravelNodeMapPriority(nodeIndex) or 0
                    if priority > bestPriority then
                        bestPriority = priority
                        best = nodeIndex
                    end
                end
            end
        end
    end
    return best
end

local function FindOwnedHouseInZone(targetZoneId)
    local houses = ZO_COLLECTIBLE_DATA_MANAGER:GetAllCollectibleDataObjects(
        { ZO_CollectibleCategoryData.IsHousingCategory },
        { ZO_CollectibleData.IsUnlocked }
    )
    for _, house in ipairs(houses) do
        local houseId = house:GetReferenceId()
        if ZonesOverlap(GetHouseZoneId(houseId), targetZoneId) then
            local collectibleId = GetCollectibleIdForHouse(houseId)
            local houseName = GetCollectibleNickname(collectibleId)
            if not houseName or houseName == "" then
                houseName = GetCollectibleDefaultNickname(collectibleId)
            end
            return houseId, houseName
        end
    end
end

-- world map teleport

local function CreateTeleportCallback()
    local normalizedMouseX, normalizedMouseY = GetNormalizedMousePositionToMap()
    local success, locationName = pcall(GetMapMouseoverInfo, normalizedMouseX, normalizedMouseY)
    if not success then return end

    local cleanLocation = CleanName(locationName)
    local zoneId = MAP_NAME_TO_ZONE_ID[cleanLocation] or MAP_NAME_TO_ZONE_ID[NormalizeName(locationName)]
    if not zoneId then
        local fallbackName
        zoneId, fallbackName = GetFallbackZoneId()
        if zoneId then cleanLocation = CleanName(fallbackName) end
    end
    if not zoneId then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, zo_strformat(SI_GPH_TELEPORT_NO_ZONE_DATA, cleanLocation))
        return
    end

    local players  = FindPlayersInZone(zoneId)
    local houseId, houseName = FindOwnedHouseInZone(zoneId)
    local nodeIndex = (not players and not houseId) and FindWayshrineInZone(zoneId)

    if not players and not houseId and not nodeIndex then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_GPH_TELEPORT_NO_TARGET))
        return
    end

    if not players and not houseId then
        ZO_Dialogs_ShowGamepadDialog("GPH_HOVER_WAYSHRINE_CONFIRM", { nodeIndex = nodeIndex, name = cleanLocation })
        return
    end

    SCENE_MANAGER:HideCurrentScene()

    local function onAllFailed()
        if houseId then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GPH_TELEPORTING_TO, houseName or cleanLocation))
            RequestJumpToHouse(houseId, true)
        elseif nodeIndex then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GPH_TELEPORTING_TO, cleanLocation))
            FastTravelToNode(nodeIndex)
        else
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_GPH_MAPSEARCH_FREE_TRAVEL_FAILED))
        end
    end

    if players then
        TryPlayersFromIndex(players, 1, onAllFailed)
    else
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GPH_TELEPORTING_TO, houseName or cleanLocation))
        RequestJumpToHouse(houseId, true)
    end
end

local KEYBOARD_KEYBIND_STRIP_DESCRIPTOR = nil
local GAMEPAD_KEYBIND_STRIP_DESCRIPTOR  = nil
local CHAT_KEYBIND_STRIP_DESCRIPTOR     = nil

local function IsMapSearchTeleportSuppressed()
    if mapSearchSuppressingTeleport then return true end
    local isMapSearchShowing = _G["GamePadHelper_MapSearch_IsShowing"]
    return type(isMapSearchShowing) == "function" and isMapSearchShowing() == true
end

local function PopulateKeybindStripDescriptor()
    local keybind = {
        name    = GetString(SI_GPH_TELEPORT),
        keybind = "UI_SHORTCUT_QUINARY",
        enabled = function()
            return not IsMapSearchTeleportSuppressed()
                and CanLeaveCurrentLocationViaTeleport()
                and not IsUnitDead("player")
        end,
        visible  = function() return not IsMapSearchTeleportSuppressed() end,
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

local function OnWorldMapSceneStateChange(_, newState)
    if newState == SCENE_SHOWING then
        OnWorldMapSceneShow()
    elseif newState == SCENE_HIDING then
        OnWorldMapSceneHide()
    end
end

local function OnWorldMapChanged()
    if IsMapSearchTeleportSuppressed() then return end
    KEYBIND_STRIP:UpdateKeybindButtonGroup(GAMEPAD_KEYBIND_STRIP_DESCRIPTOR)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(KEYBOARD_KEYBIND_STRIP_DESCRIPTOR)
end

-- shared teleport API (called by MapSearch)

_G["GamePadHelper_MapTeleporter_TryFreeTeleport"] = function(params)
    if not params or not params.zoneId then return false end
    local players            = FindPlayersInZone(params.zoneId)
    local houseId, houseName = FindOwnedHouseInZone(params.zoneId)
    if not players and not houseId then return false end
    local first = players and players[1]
    ZO_Dialogs_ShowGamepadDialog("GPH_FREE_TRAVEL_OPTIONS", {
        name          = params.name,
        nodeIndex     = params.nodeIndex,
        cost          = params.cost,
        players       = players,
        memberDisplay = first and first.displayName,
        memberChar    = first and first.charName,
        houseId       = houseId,
        houseName     = houseName,
        onWayshrine   = params.onWayshrine,
    })
    return true
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

-- chat teleport

local function IsFriendJumpable()
    if not CHAT_MENU_GAMEPAD.socialData or not CHAT_MENU_GAMEPAD.socialData.displayName then return false end
    return IsFriend(CHAT_MENU_GAMEPAD.socialData.displayName)
end

local function IsGuildJumpable()
    if IsFriendJumpable() then return false end
    if not CHAT_MENU_GAMEPAD.socialData or not CHAT_MENU_GAMEPAD.socialData.category then return false end
    local cat = CHAT_MENU_GAMEPAD.socialData.category
    if cat == CHAT_CATEGORY_GUILD_1   or cat == CHAT_CATEGORY_GUILD_2   or cat == CHAT_CATEGORY_GUILD_3   or
       cat == CHAT_CATEGORY_GUILD_4   or cat == CHAT_CATEGORY_GUILD_5   or
       cat == CHAT_CATEGORY_OFFICER_1 or cat == CHAT_CATEGORY_OFFICER_2 or cat == CHAT_CATEGORY_OFFICER_3 or
       cat == CHAT_CATEGORY_OFFICER_4 or cat == CHAT_CATEGORY_OFFICER_5
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
                name    = GetString(SI_GPH_TELEPORT),
                keybind = "UI_SHORTCUT_QUINARY",
                enabled = function()
                    return CanLeaveCurrentLocationViaTeleport() and not IsUnitDead("player")
                end,
                visible  = function() return true end,
                callback = function()
                    local data = CHAT_MENU_GAMEPAD.socialData
                    if not data or not IsAnyJumpable() then
                        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_GPH_TELEPORT_NO_VALID_TARGET))
                        return
                    end
                    SCENE_MANAGER:HideCurrentScene()
                    local displayName = data.displayName
                    ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GPH_TELEPORTING_TO, displayName))
                    if IsFriendJumpable() then
                        JumpToFriend(displayName)
                    elseif IsGroupJumpable() then
                        JumpToGroupMember(displayName)
                    else
                        JumpToGuildMember(displayName)
                    end
                end,
            }
        }
    end
    KEYBIND_STRIP:AddKeybindButtonGroup(CHAT_KEYBIND_STRIP_DESCRIPTOR)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(CHAT_KEYBIND_STRIP_DESCRIPTOR)
    return false
end

local function OnAddonLoaded(_, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("MapTeleporter", EVENT_ADD_ON_LOADED)

    PopulateMapNameToZoneIdMapping()
    PopulateKeybindStripDescriptor()

    ZO_Dialogs_RegisterCustomDialog("GPH_HOVER_WAYSHRINE_CONFIRM", {
        gamepadInfo = { dialogType = GAMEPAD_DIALOGS.BASIC },
        canQueue    = true,
        title       = { text = SI_PROMPT_TITLE_FAST_TRAVEL_CONFIRM },
        mainText    = {
            text = function(dialog)
                if not dialog.data then return "" end
                local d        = dialog.data
                local cost     = GetRecallCost(d.nodeIndex)
                local currency = GetRecallCurrency(d.nodeIndex)
                local canAfford = cost <= GetCurrencyAmount(currency, CURRENCY_LOCATION_CHARACTER)
                local cooldown = GetRecallCooldown()
                local cooldownStr = ZO_FormatTimeMilliseconds(cooldown, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_SECONDS)
                local baseId
                if cost == 0 then
                    baseId = SI_GAMEPAD_FAST_TRAVEL_DIALOG_MAIN_TEXT
                elseif cooldown == 0 then
                    baseId = canAfford and SI_GAMEPAD_FAST_TRAVEL_DIALOG_RECALL_MAIN_TEXT or SI_GAMEPAD_FAST_TRAVEL_DIALOG_CANT_AFFORD
                else
                    baseId = canAfford and SI_GAMEPAD_FAST_TRAVEL_DIALOG_PREMIUM or SI_GAMEPAD_FAST_TRAVEL_DIALOG_CANT_AFFORD_PREMIUM
                end
                return zo_strformat(baseId, d.name, cooldownStr)
            end,
        },
        buttons = {
            {
                text     = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    if not dialog.data then return end
                    ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GPH_TELEPORTING_TO, dialog.data.name))
                    FastTravelToNode(dialog.data.nodeIndex)
                    SCENE_MANAGER:ShowBaseScene()
                end,
            },
            { keybind = "DIALOG_NEGATIVE", text = SI_DIALOG_CANCEL },
        },
    })

    ZO_Dialogs_RegisterCustomDialog("GPH_FREE_TRAVEL_OPTIONS", {
        gamepadInfo             = { dialogType = GAMEPAD_DIALOGS.PARAMETRIC },
        canQueue                = true,
        blockDialogReleaseOnPress = true,
        title          = { text = SI_GPH_MAPSEARCH_FREE_TRAVEL_TITLE },
        mainText       = {
            text = function(dialog)
                if not dialog.data then return "" end
                return zo_strformat(SI_GPH_MAPSEARCH_FREE_TRAVEL_PROMPT, dialog.data.name)
            end,
        },
        parametricList = {},
        setup = function(dialog)
            local d    = dialog.data
            local list = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(list)

            if d.memberDisplay then
                local label = (d.memberChar and d.memberChar ~= "") and d.memberChar or d.memberDisplay
                table.insert(list, {
                    template     = "ZO_GamepadTextFieldSubmitItem",
                    templateData = {
                        text  = zo_strformat(SI_GPH_MAPSEARCH_FREE_TRAVEL_MEMBER, label),
                        setup = ZO_SharedGamepadEntry_OnSetup,
                        callback = function()
                            ZO_Dialogs_ReleaseDialogOnButtonPress("GPH_FREE_TRAVEL_OPTIONS")
                            SCENE_MANAGER:ShowBaseScene()
                            TryPlayersFromIndex(d.players, 1, function()
                                if d.houseId then
                                    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_TRAVEL_TO_HOUSE_OPTIONS_DIALOG",
                                        { GetReferenceId = function() return d.houseId end })
                                else
                                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_GPH_MAPSEARCH_FREE_TRAVEL_FAILED))
                                end
                            end)
                        end,
                    },
                })
            end

            if d.houseId then
                table.insert(list, {
                    template     = "ZO_GamepadTextFieldSubmitItem",
                    templateData = {
                        text  = zo_strformat(SI_GPH_MAPSEARCH_FREE_TRAVEL_HOUSE, d.houseName),
                        setup = ZO_SharedGamepadEntry_OnSetup,
                        callback = function()
                            ZO_Dialogs_ReleaseDialogOnButtonPress("GPH_FREE_TRAVEL_OPTIONS")
                            SCENE_MANAGER:ShowBaseScene()
                            RequestJumpToHouse(d.houseId, true)
                        end,
                    },
                })
            end

            if d.nodeIndex then
                table.insert(list, {
                    template     = "ZO_GamepadTextFieldSubmitItem",
                    templateData = {
                        text  = zo_strformat(SI_GPH_MAPSEARCH_FREE_TRAVEL_WAYSHRINE, d.cost),
                        setup = ZO_SharedGamepadEntry_OnSetup,
                        callback = function()
                            ZO_Dialogs_ReleaseDialogOnButtonPress("GPH_FREE_TRAVEL_OPTIONS")
                            if d.onWayshrine then d.onWayshrine() end
                        end,
                    },
                })
            end

            dialog:setupFunc()
        end,
        buttons = {
            {
                keybind  = "DIALOG_PRIMARY",
                text     = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    if data and data.callback then data.callback() end
                end,
            },
            {
                keybind  = "DIALOG_NEGATIVE",
                text     = SI_GAMEPAD_BACK_OPTION,
                callback = function() ZO_Dialogs_ReleaseDialogOnButtonPress("GPH_FREE_TRAVEL_OPTIONS") end,
            },
        },
    })

    WORLD_MAP_SCENE:RegisterCallback("StateChange", OnWorldMapSceneStateChange)
    GAMEPAD_WORLD_MAP_SCENE:RegisterCallback("StateChange", OnWorldMapSceneStateChange)
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", OnWorldMapChanged)

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

    if CHAT_MENU_GAMEPAD then
        ZO_PreHook(CHAT_MENU_GAMEPAD, "OnShow", GamepadChatInit)

        ZO_PreHook(CHAT_MENU_GAMEPAD, "OnTargetChanged", function(_, _, targetData)
            CHAT_MENU_GAMEPAD.socialData = targetData and (targetData.data or targetData) or nil
            if CHAT_KEYBIND_STRIP_DESCRIPTOR then
                KEYBIND_STRIP:UpdateKeybindButtonGroup(CHAT_KEYBIND_STRIP_DESCRIPTOR)
            end
        end)

        ZO_PreHook(CHAT_MENU_GAMEPAD, "OnHide", function()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(CHAT_KEYBIND_STRIP_DESCRIPTOR)
        end)
    end
end

EVENT_MANAGER:RegisterForEvent("MapTeleporter", EVENT_ADD_ON_LOADED, OnAddonLoaded)
