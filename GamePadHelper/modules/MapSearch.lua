-- ============================================================
-- GPH Map Search
-- Navigation model: list owns d-pad, edit box for text only.
-- Full feature set: POI/House/Lift types, fuzzy search, teleport,
-- bookmarks with confirmation, narration, post-teleport restore.
-- ============================================================

local function CleanName(s)
    return (s and s ~= "") and zo_strformat("<<C:1>>", s) or (s or "")
end

local function GetCleanZoneName(zoneId, fallback)
    return (zoneId and zoneId > 0) and CleanName(GetZoneNameById(zoneId)) or (fallback or "")
end

local function TruncateDetail(s, maxLen)
    if not s or #s <= maxLen then return s end
    local cut = s:sub(1, maxLen):match("^(.+)%s") or s:sub(1, maxLen)
    return cut .. "..."
end

local TYPE_WAYSHRINE        = 1
local TYPE_ZONE             = 2
local TYPE_POI              = 3
local TYPE_HOUSE_OWNED      = 4
local TYPE_HOUSE_UNOWNED    = 5
local TYPE_LIFT             = 6
local TYPE_CUSTOM           = 7
local TYPE_NPC              = 8
local TYPE_TRADER           = 9
local TYPE_TRAVEL           = 10
local TYPE_CYRODIIL_KEEP    = 11

local function IsServiceMapTarget(c)
    return c and (c.type == TYPE_CUSTOM or c.type == TYPE_NPC or c.type == TYPE_TRADER or c.type == TYPE_TRAVEL)
end

local function IsTravelService(service, displayName, category, detailLabel)
    local haystack = table.concat({
        displayName or "",
        category or "",
        detailLabel or "",
        service and service.name or "",
        service and service.aliases or "",
    }, " "):lower()
    return haystack:find("ferry", 1, true)
        or haystack:find("caravan", 1, true)
        or haystack:find("boat", 1, true)
        or haystack:find("navigator", 1, true)
        or haystack:find("silt strider", 1, true)
        or haystack:find("cart", 1, true)
end

local TAB_SEARCH    = 1
local TAB_BOOKMARKS = 2
local TAB_RECENT    = 3
local TAB_HOUSES    = 4
local TAB_LOCATIONS = 5

local ICON_WAYSHRINE_KNOWN   = "/esoui/art/icons/poi/poi_wayshrine_complete.dds"
local ICON_WAYSHRINE_UNKNOWN = "/esoui/art/icons/poi/poi_wayshrine_incomplete.dds"
local ICON_POI_GENERIC       = "/esoui/art/icons/poi/poi_landmark_complete.dds"

local GPH_SEARCH_FRAGMENT     = nil
local GPH_SEARCH_TAB_INSERTED = false
local gphSearchTabIndex       = nil
local wasOnGPHSearch          = nil

local scannedData = nil
local candidates  = nil
local results     = {}
local currentTerm = ""
local lastSearchTerm = nil

local listObject        = nil
local editControl       = nil
local tabsControl       = nil
local searchBarControl  = nil
local recallRowControl  = nil
local tabTitleControl   = nil
local searchBarBG       = nil
local recallCostLabel   = nil
local tabControls       = {}
local keybindDescriptor = nil
local GetBookmarkKey
local RunSearch
local RebuildList

local lastSelectedIndex = 1
local currentTab = TAB_SEARCH
local pendingNarration  = nil
local postTeleportMsg   = nil
local listCostLoopId = 0
local zoneMapCounts   = nil
local zoneLeadCounts  = nil
local zoneQuestCounts = nil

local cityServicesCache = nil  -- { locations=[], tradersByNodeIndex={} }, populated on first use
local traderGuildMap    = nil  -- trader/guild tooltip data, built with city cache
local CITY_SCAN_BATCH   = 12   -- maps scanned per frame during background pre-warm
local clickableSubMapCache = nil
local craftingPOIIndex = {}  -- "zoneId:pxKey:pyKey" -> poiIndex, built during PreScan

local function GetCraftingSetPOIEntry(zoneId, poiIndex)
    local byZone = GamePadHelper_MapSearchData
        and GamePadHelper_MapSearchData.CRAFTING_SET_POIS
        and GamePadHelper_MapSearchData.CRAFTING_SET_POIS[zoneId]
    return byZone and byZone[poiIndex] or nil
end

local function GetCraftingSetIdForPOI(zoneId, poiIndex)
    local entry = GetCraftingSetPOIEntry(zoneId, poiIndex)
    if type(entry) == "table" then return entry.setId end
    return entry
end

local function GetCraftingSetLocationEntry(zoneId, locationName)
    if not zoneId or not locationName then return nil end
    local byZone = GamePadHelper_MapSearchData
        and GamePadHelper_MapSearchData.CRAFTING_SET_LOCATIONS
        and GamePadHelper_MapSearchData.CRAFTING_SET_LOCATIONS[zoneId]
    return byZone and byZone[locationName] or nil
end

local function GetCraftingSetTraitCount(setId, zoneId, poiIndex)
    local poiEntry = GetCraftingSetPOIEntry(zoneId, poiIndex)
    if type(poiEntry) == "table" and poiEntry.traits then return poiEntry.traits end
    return nil
end

local function GetCraftingSetName(setId)
    if not setId or not GetItemSetInfo then return nil end
    local hasSet, setName = GetItemSetInfo(setId)
    if hasSet and setName and setName ~= "" then
        return CleanName(setName)
    end
    return nil
end

local function GetCraftingSetSearchAlias(setId)
    local setName = GetCraftingSetName(setId)
    if setName and setName ~= "" then return setName end
    return ""
end

local function AddCraftingSetNarration(c, narrationBase)
    if not c or not c.setId then return narrationBase end

    local traitCount = c.traitCount
    if not traitCount or traitCount == 0 then
        traitCount = GetCraftingSetTraitCount(c.setId, c.zoneId, c.poiIndex)
    end
    if IsServiceMapTarget(c) and traitCount and traitCount > 0 then
        narrationBase = narrationBase .. ", " .. traitCount .. " " .. GetString(traitCount == 1 and SI_GPH_MAPSEARCH_CRAFTING_TRAIT or SI_GPH_MAPSEARCH_CRAFTING_TRAITS)
    end

    local setName = c.setName
    if not setName or setName == "" then
        setName = GetCraftingSetName(c.setId)
    end
    if setName and setName ~= "" then
        narrationBase = narrationBase .. ", " .. setName
    end

    if GetItemSetInfo and GetItemSetBonusInfo then
        local hasSet, _, numBonuses = GetItemSetInfo(c.setId)
        if hasSet and numBonuses and numBonuses > 0 then
            for i = 1, numBonuses do
                local _, desc, isPerfected = GetItemSetBonusInfo(c.setId, i)
                if not isPerfected and desc and desc ~= "" then
                    narrationBase = narrationBase .. ", " .. desc
                end
            end
        end
    end

    return narrationBase
end

local function ExtractCraftingSetInfo(icon, isCraftingStation, zoneId, poiIndex)
    if not isCraftingStation and (not icon or not icon:find("crafting")) then return nil, nil, nil end

    local stations = _G["GamePadHelperMapData"] and _G["GamePadHelperMapData"].craftingStations
    local entry = stations and zoneId and poiIndex and stations[tostring(zoneId) .. ":" .. tostring(poiIndex)]
    local staticSetId = GetCraftingSetIdForPOI(zoneId, poiIndex)
    local tc = entry and entry.traitCount or nil
    local sn = entry and entry.setName   or nil
    local si = staticSetId or (entry and entry.setId) or nil

    if si then
        if not tc or tc == 0 then
            tc = GetCraftingSetTraitCount(si, zoneId, poiIndex)
        end
        if not sn or sn == "" then
            sn = GetCraftingSetName(si)
        end
    end

    return tc, sn, si
end

local function BuildSearchName(name, aliases)
    local searchName = (name and name ~= "") and name:lower() or ""
    if aliases and aliases ~= "" then
        searchName = searchName .. " " .. aliases
    end
    return searchName
end

local function GetGuildSearchAliases(name, nodeIndex)
    local aliases = {}
    local lowerName = name and name:lower() or ""

    if lowerName:find("fighters guild", 1, true) or lowerName:find("fighters guildhall", 1, true) then
        aliases[#aliases + 1] = "fighter guild fighters guild fighters guildhall fighter guildhall fg"
    end
    if lowerName:find("mages guild", 1, true) or lowerName:find("mages guildhall", 1, true) then
        aliases[#aliases + 1] = "mage guild mages guild mages guildhall mage guildhall mg"
    end
    return table.concat(aliases, " ")
end

local function IsFragmentShowing()
    return GPH_SEARCH_FRAGMENT ~= nil and GPH_SEARCH_FRAGMENT:IsShowing()
end

_G["GamePadHelper_MapSearch_IsShowing"] = IsFragmentShowing

local function GetSavedVars()
    return _G["GamePadHelper_CharSavedVars"]
end

local function UpdateKeybinds()
    if keybindDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(keybindDescriptor)
    end
end

local MAP_SEARCH_TABS = {
    { label = SI_GPH_MAPSEARCH_TAB_SEARCH },
    { label = SI_GPH_MAPSEARCH_TAB_BOOKMARKS },
    { label = SI_GPH_MAPSEARCH_TAB_RECENT },
    { label = SI_GPH_MAPSEARCH_TAB_HOUSES },
    { label = SI_GPH_MAPSEARCH_TAB_ZONES },
}

local function UpdateTabLabels()
    if not tabControls.selected then return end

    local previousIndex = currentTab - 1
    if previousIndex < 1 then previousIndex = #MAP_SEARCH_TABS end

    local nextIndex = currentTab + 1
    if nextIndex > #MAP_SEARCH_TABS then nextIndex = 1 end

    local ltIcon = ZO_Keybindings_GetHighestPriorityBindingStringFromAction("UI_SHORTCUT_LEFT_TRIGGER",  KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP, true, false, 120) or "<"
    local rtIcon = ZO_Keybindings_GetHighestPriorityBindingStringFromAction("UI_SHORTCUT_RIGHT_TRIGGER", KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP, true, false, 120) or ">"

    if tabControls.previous then
        tabControls.previous:SetText(ltIcon .. " " .. GetString(MAP_SEARCH_TABS[previousIndex].label))
    end
    tabControls.selected:SetText(GetString(MAP_SEARCH_TABS[currentTab].label))
    if tabControls.next then
        tabControls.next:SetText(GetString(MAP_SEARCH_TABS[nextIndex].label) .. " " .. rtIcon)
    end
    if tabTitleControl then
        tabTitleControl:SetText(GetString(MAP_SEARCH_TABS[currentTab].label))
    end
end

local function UpdateSearchBarVisibility()
    if not searchBarControl then return end

    local showSearch = currentTab == TAB_SEARCH
    searchBarControl:SetHidden(not showSearch)
    if not showSearch and editControl and editControl:HasFocus() then
        editControl:LoseFocus()
    end

    local listCtrl = listObject and listObject.control
    if listCtrl and tabTitleControl then
        local anchorTarget = showSearch and searchBarControl or tabTitleControl
        local offsetY = showSearch and 6 or 20
        listCtrl:ClearAnchors()
        listCtrl:SetAnchor(TOPLEFT,     anchorTarget, BOTTOMLEFT,  0, offsetY)
        listCtrl:SetAnchor(BOTTOMRIGHT, nil,          BOTTOMRIGHT, 0, 0)
    end
end

local function IsCandidateInCurrentTab(c, bookmarkedByKey)
    if currentTab == TAB_SEARCH then
        return true
    elseif currentTab == TAB_BOOKMARKS then
        return bookmarkedByKey and bookmarkedByKey[GetBookmarkKey(c)] == true
    elseif currentTab == TAB_RECENT then
        return true
    elseif currentTab == TAB_HOUSES then
        return c.type == TYPE_HOUSE_OWNED
    elseif currentTab == TAB_LOCATIONS then
        return c.type == TYPE_ZONE
    end
    return true
end

local function SwitchTab(delta)
    currentTab = currentTab + delta
    if currentTab < 1 then currentTab = #MAP_SEARCH_TABS end
    if currentTab > #MAP_SEARCH_TABS then currentTab = 1 end
    lastSelectedIndex = 1
    lastSearchTerm = nil
    UpdateSearchBarVisibility()
    RunSearch(currentTerm)
    UpdateTabLabels()
    RebuildList()
    pendingNarration = GetString(MAP_SEARCH_TABS[currentTab].label)
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("GPH_MapSearch_Narration")
end


-- bookmarks

local function MakeBookmarkKey(c)
    return c.type .. ":" .. tostring(c.nodeIndex or c.zoneId or "") .. ":" .. c.name
end

GetBookmarkKey = function(c)
    if not c then return "" end
    if c.key and c.key ~= "" then return c.key end
    if c.bookmarkKey and c.bookmarkKey ~= "" then return c.bookmarkKey end
    local k = MakeBookmarkKey(c)
    c.bookmarkKey = k
    return k
end

local function GetBookmarksArray()
    local sv = GetSavedVars()
    if not sv then return {} end
    if sv.mapSearchBookmarksAccountWide == true then
        local acct = _G["GamePadHelper_SavedVars"]
        if not acct then return {} end
        if not acct.mapSearchBookmarksAll then
            acct.mapSearchBookmarksAll = {}
        end
        return acct.mapSearchBookmarksAll
    end
    if not sv.mapSearchBookmarks then
        sv.mapSearchBookmarks = {}
    end
    return sv.mapSearchBookmarks
end

local function GetRecentArray()
    local sv = GetSavedVars()
    if not sv then return {} end
    if not sv.mapSearchRecent then
        sv.mapSearchRecent = {}
    end
    return sv.mapSearchRecent
end

local function MakeSavedCandidate(c, key)
    return {
        key          = key or GetBookmarkKey(c),
        name         = c.name,
        searchName   = c.name and c.name:lower() or "",
        type         = c.type,
        icon         = c.icon,
        nodeIndex    = c.nodeIndex,
        zoneId       = c.zoneId,
        poiIndex     = c.poiIndex,
        zoneName     = c.zoneName,
        placeName    = c.placeName,
        cityName     = c.cityName,
        cityMapId    = c.cityMapId,
        destinationX = c.destinationX,
        destinationY = c.destinationY,
        poiTypeLabel = c.poiTypeLabel,
        narrationLabel = c.narrationLabel,
        detailLabel  = c.detailLabel,
        isTrader     = c.isTrader,
        isLocked     = c.isLocked,
        known        = c.known,
        houseId      = c.houseId,
        traitCount   = c.traitCount,
        setName      = c.setName,
        setId        = c.setId,
        traderCount  = c.traderCount,
        traderNames  = c.traderNames,
    }
end

local function AddRecent(c)
    if not c then return end
    local key = GetBookmarkKey(c)
    local recents = GetRecentArray()
    for i = #recents, 1, -1 do
        if GetBookmarkKey(recents[i]) == key then
            table.remove(recents, i)
        end
    end
    table.insert(recents, 1, MakeSavedCandidate(c, key))
    while #recents > 20 do
        table.remove(recents)
    end
end

local function IsBookmarked(c)
    local key = GetBookmarkKey(c)
    for _, bm in ipairs(GetBookmarksArray()) do
        if GetBookmarkKey(bm) == key then return true end
    end
    return false
end

local function RemoveBookmark(c)
    local key = GetBookmarkKey(c)
    local arr = GetBookmarksArray()
    for i, bm in ipairs(arr) do
        if GetBookmarkKey(bm) == key then
            table.remove(arr, i)
            return
        end
    end
end

local function AddBookmark(c)
    local arr = GetBookmarksArray()
    arr[#arr + 1] = MakeSavedCandidate(c)
end

-- POI type labels

local function GetPOITypeLabel(icon, poiType)
    local data = GamePadHelper_MapSearchData
    if not data then return nil end
    if poiType and data.POI_TYPE_DIRECT[poiType] then
        return data.POI_TYPE_DIRECT[poiType]
    end
    if not icon or icon == "" then return nil end
    local name = (icon:match("([^/]+)%.dds$") or icon)
        :gsub("_complete$",   "")
        :gsub("_incomplete$", "")
        :gsub("_owned$",      "")
        :gsub("_unowned$",    "")
        :gsub("^u%d+_poi_",   "")
        :gsub("^u%d+_",       "")
        :gsub("^poi_",        "")
    return data.POI_TYPE_NAMES[name]
end

-- narration

local function BuildCandidateNarrationText(c, isBookmark)
    local parts = { c.name }
    if isBookmark then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_BOOKMARKED) end
    if c.type == TYPE_HOUSE_OWNED or c.type == TYPE_HOUSE_UNOWNED then
        parts[#parts + 1] = c.type == TYPE_HOUSE_UNOWNED and GetString(SI_GPH_MAPSEARCH_NARRATION_UNOWNED) or GetString(SI_GPH_MAPSEARCH_NARRATION_OWNED)
        parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_LABEL_HOUSE)
    elseif c.type == TYPE_POI then
        if c.isLocked      then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_LOCKED)
        elseif not c.known then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_UNDISCOVERED) end
        if c.icon and c.icon:find("poi_mundus") and c.zoneName and c.zoneName ~= "" then
            parts[#parts + 1] = c.zoneName
        end
        parts[#parts + 1] = c.poiTypeLabel or GetString(SI_GPH_MAPSEARCH_NARRATION_POI)
        if c.traitCount and c.traitCount > 0 then
            parts[#parts + 1] = c.traitCount .. " " .. GetString(c.traitCount == 1 and SI_GPH_MAPSEARCH_CRAFTING_TRAIT or SI_GPH_MAPSEARCH_CRAFTING_TRAITS)
        end
    elseif IsServiceMapTarget(c) then
        if c.isLocked      then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_LOCKED)
        elseif not c.known then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_UNDISCOVERED) end
        if c.cityName and c.cityName ~= "" then parts[#parts + 1] = c.cityName end
        if c.detailLabel and c.detailLabel ~= "" then
            parts[#parts + 1] = c.detailLabel
        elseif c.narrationLabel and c.narrationLabel ~= "" then
            parts[#parts + 1] = c.narrationLabel
        end
    elseif c.type == TYPE_ZONE then
        if c.isLocked then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_LOCKED) end
        parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_ZONE)
    elseif c.type == TYPE_CYRODIIL_KEEP then
        if c.groupCount and c.groupCount > 0 then
            parts[#parts + 1] = c.groupCount .. " " .. GetString(SI_GPH_CYRODIIL_MEMBERS_NEARBY)
        end
        if c.isLeaderKeep then
            parts[#parts + 1] = GetString(SI_GPH_CYRODIIL_LEADER_NEARBY)
        end
    elseif c.type == TYPE_LIFT then
        if not c.known     then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_UNDISCOVERED)
        elseif c.isLocked  then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_LOCKED) end
        parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_LABEL_LIFT)
    elseif c.type == TYPE_WAYSHRINE then
        if c.isLocked      then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_LOCKED)
        elseif not c.known then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_UNDISCOVERED) end
        if c.zoneName and c.zoneName ~= "" then parts[#parts + 1] = c.zoneName end
        local mp = c.mapPriority or 0
        if mp >= 2 then     parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_LABEL_WAYSHRINE_CAPITAL)
        elseif mp == 1 then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_LABEL_WAYSHRINE_MAJOR) end
    else
        if c.isLocked      then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_LOCKED)
        elseif not c.known then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_UNDISCOVERED) end
    end
    return table.concat(parts, ", ")
end

-- pre-scan 

local function AddClickableSubMap(maps, seen, parentZoneId, x, y, fallbackName)
    if not x or not y or x <= 0 or y <= 0 then return end
    local locationName, _, _, _, _, _, mapId = GetMapMouseoverInfo(x, y)
    if mapId and mapId ~= 0 and not seen[mapId] then
        seen[mapId] = true
        maps[#maps + 1] = {
            mapId = mapId,
            name = CleanName((locationName and locationName ~= "") and locationName or (fallbackName or "")),
            parentZoneId = parentZoneId,
        }
    end
end

local function GetClickableSubMaps()
    if clickableSubMapCache then return clickableSubMapCache end

    local originalMapId = GetCurrentMapId and GetCurrentMapId() or nil
    local maps = {}
    local seen = {}

    for mapIndex = 1, GetNumMaps() do
        local mapName, mapType, _, zoneIndex = GetMapInfoByIndex(mapIndex)
        if mapName and mapName ~= "" and (mapType == MAPTYPE_ZONE or mapType == MAPTYPE_SUBZONE or mapType == MAPTYPE_WORLD) then
            SetMapToMapListIndex(mapIndex)
            local parentZoneId = (zoneIndex and zoneIndex > 0) and GetZoneId(zoneIndex) or 0

            if zoneIndex and zoneIndex > 0 then
                for poiIndex = 1, GetNumPOIs(zoneIndex) do
                    local poiName = GetPOIInfo(zoneIndex, poiIndex)
                    local nx, ny = GetPOIMapInfo(zoneIndex, poiIndex)
                    AddClickableSubMap(maps, seen, parentZoneId, nx, ny, poiName)
                end
            end

            for blobIndex = 1, GetNumMapBlobs() do
                local blobName, nx, nz = GetMapBlobNameInfo(blobIndex)
                AddClickableSubMap(maps, seen, parentZoneId, nx, nz, blobName)
            end
        end
    end

    if originalMapId then SetMapToMapId(originalMapId) end
    clickableSubMapCache = maps
    return maps
end

local function PreScan()
    craftingPOIIndex = {}
    local nameToZoneId = {}
    for mi = 1, GetNumMaps() do
        local mapName, _, _, zi = GetMapInfoByIndex(mi)
        if zi and zi > 0 then
            nameToZoneId[mapName] = GetZoneId(zi)
        end
    end

    local data = { wayshrines = {}, zones = {}, pois = {}, poisByZoneId = {}, nameToZoneId = nameToZoneId }

    local lockedZoneIndex = {}
    for nodeIndex = 1, GetNumFastTravelNodes() do
        local _, _, _, _, _, _, typePOI, _, isLocked = GetFastTravelNodeInfo(nodeIndex)
        if isLocked and typePOI == POI_TYPE_WAYSHRINE then
            local zi = GetFastTravelNodePOIIndicies(nodeIndex)
            if zi then lockedZoneIndex[zi] = true end
        end
    end

    for nodeIndex = 1, GetNumFastTravelNodes() do
        local drawLevelOffset = GetFastTravelNodeDrawLevelOffset(nodeIndex)
        if drawLevelOffset ~= 0 then
            local known, name, _, _, _, _, typePOI, _, isLocked = GetFastTravelNodeInfo(nodeIndex)
            local isWayshrine = typePOI == POI_TYPE_WAYSHRINE
            local isHouse     = typePOI == POI_TYPE_HOUSE
            if isWayshrine or isHouse then
                local zoneIndex, poiIndex = GetFastTravelNodePOIIndicies(nodeIndex)
                local zoneId = GetZoneId(zoneIndex)
                local _, _, _, poiIcon = GetPOIMapInfo(zoneIndex, poiIndex)
                local defaultIcon = known and ICON_WAYSHRINE_KNOWN or ICON_WAYSHRINE_UNKNOWN
                local icon = (poiIcon and poiIcon ~= "") and poiIcon or defaultIcon
                -- HasCompletedFastTravelNodePOI is how ESO itself determines house ownership.
                local isOwnedHouse = isHouse and HasCompletedFastTravelNodePOI(nodeIndex)
                local houseId      = isHouse and GetFastTravelNodeHouseId(nodeIndex) or nil
                local mapPriority  = GetFastTravelNodeMapPriority(nodeIndex) or 0
                data.wayshrines[#data.wayshrines + 1] = {
                    name         = CleanName(name),
                    icon         = icon,
                    nodeIndex    = nodeIndex,
                    zoneId       = zoneId,
                    poiIndex     = poiIndex,
                    zoneName     = CleanName(GetZoneNameById(zoneId)),
                    known        = known,
                    isLocked     = isLocked,
                    isHouse      = isHouse,
                    isOwnedHouse = isOwnedHouse,
                    houseId      = houseId,
                    mapPriority  = mapPriority,
                }
            end
        end
    end

    local seenZone = {}
    local function AddZoneEntry(zoneId, zoneIndex, zoneName)
        if not zoneId or zoneId <= 0 or seenZone[zoneId] then return end
        seenZone[zoneId] = true

        local cleanZoneName = CleanName(zoneName or "")
        data.zones[#data.zones + 1] = {
            name     = cleanZoneName,
            zoneId   = zoneId,
            isLocked = lockedZoneIndex[zoneIndex] or false,
        }
        nameToZoneId[cleanZoneName] = zoneId
    end

    local seenPOI = {}
    local function AddPOIEntry(zoneIndex, zoneId, poiIndex, zoneName)
        local uid = zoneIndex .. ":" .. poiIndex
        if seenPOI[uid] then return end
        seenPOI[uid] = true

        local name = GetPOIInfo(zoneIndex, poiIndex)
        if not name or name == "" then return end

        local nx, ny, _, icon, _, collectibleLocked, isDiscovered = GetPOIMapInfo(zoneIndex, poiIndex)
        local poiType = GetPOIType(zoneIndex, poiIndex)
        if icon and icon:find("wayshrine") then return end

        local poiIcon  = (icon and icon ~= "") and icon or nil
        local isLocked = collectibleLocked or lockedZoneIndex[zoneIndex] or false
        local poiTypeLabel = GetPOITypeLabel(poiIcon, poiType)
        local isCraftingStation = poiTypeLabel == GetString(SI_GPH_MAPSEARCH_LABEL_CRAFTING_STATION)
        if isCraftingStation and nx and nx > 0 then
            local pk = tostring(zoneId) .. ":" .. string.format("%d", nx * 10000 + 0.5) .. ":" .. string.format("%d", ny * 10000 + 0.5)
            craftingPOIIndex[pk] = poiIndex
        end

        local traitCount, setName, setId = ExtractCraftingSetInfo(poiIcon, isCraftingStation, zoneId, poiIndex)
        local poiEntry = {
            name       = CleanName(name),
            icon       = poiIcon or ICON_POI_GENERIC,
            -- Only _owned suffix means you own it; _complete/_incomplete do not.
            isOwned    = poiIcon ~= nil and poiIcon:find("_owned") ~= nil and poiIcon:find("_unowned") == nil,
            poiType    = poiType,
            zoneId     = zoneId,
            poiIndex   = poiIndex,
            zoneName   = zoneName,
            known      = isDiscovered,
            isLocked   = isLocked,
            traitCount = traitCount,
            setName    = setName,
            setId      = setId,
            x          = (nx and nx > 0) and nx or nil,
            y          = (ny and ny > 0) and ny or nil,
        }
        data.pois[#data.pois + 1] = poiEntry
        if poiEntry.x then
            if not data.poisByZoneId[zoneId] then data.poisByZoneId[zoneId] = {} end
            data.poisByZoneId[zoneId][#data.poisByZoneId[zoneId] + 1] = poiEntry
        end
    end

    local function ScanZonePOIs(zoneIndex, zoneId, zoneName)
        for poiIndex = 1, GetNumPOIs(zoneIndex) do
            AddPOIEntry(zoneIndex, zoneId, poiIndex, zoneName)
        end
    end

    for mapIndex = 1, GetNumMaps() do
        local mapName, mapType, _, zoneIndex = GetMapInfoByIndex(mapIndex)
        if mapName ~= "" and zoneIndex and zoneIndex > 0 then
            local zoneId = GetZoneId(zoneIndex)
            if not seenZone[zoneId] and (mapType == MAPTYPE_ZONE or mapType == MAPTYPE_WORLD) then
                AddZoneEntry(zoneId, zoneIndex, mapName)
            end
        end
    end

    for mapIndex = 1, GetNumMaps() do
        local _, _, _, zoneIndex = GetMapInfoByIndex(mapIndex)
        if zoneIndex and zoneIndex > 0 then
            local zoneId   = GetZoneId(zoneIndex)
            local zoneName = CleanName(GetZoneNameById(zoneId))
            ScanZonePOIs(zoneIndex, zoneId, zoneName)
        end
    end

    local originalMapId = GetCurrentMapId and GetCurrentMapId() or nil
    for _, subMap in ipairs(GetClickableSubMaps()) do
        if subMap.mapId and subMap.mapId ~= 0 then
            SetMapToMapId(subMap.mapId)
            local zoneIndex = GetCurrentMapZoneIndex()
            if zoneIndex and zoneIndex > 0 then
                local zoneId = GetZoneId(zoneIndex)
                local zoneName = CleanName(GetZoneNameById(zoneId))
                if zoneId and zoneId > 0 and not seenZone[zoneId] then
                    AddZoneEntry(zoneId, zoneIndex, zoneName ~= "" and zoneName or CleanName(GetMapName()))
                end

                ScanZonePOIs(zoneIndex, zoneId, zoneName)
            end
        end
    end
    if originalMapId then SetMapToMapId(originalMapId) end

    scannedData = data
    candidates  = nil
    lastSearchTerm = nil
end

-- candidates

local function FindNearestWayshrineToPos(px, py, minDist, filterZoneIndex)
    if not px or not py or px == 0 or py == 0 then return nil end
    local bestNode, bestDist = nil, math.huge
    for nodeIndex = 1, GetNumFastTravelNodes() do
        local known, _, wsNx, wsNy, _, _, typePOI, _, isLocked = GetFastTravelNodeInfo(nodeIndex)
        if known and not isLocked and typePOI == POI_TYPE_WAYSHRINE and wsNx and wsNy then
            local wsZoneIndex = filterZoneIndex and GetFastTravelNodePOIIndicies(nodeIndex)
            if not filterZoneIndex or wsZoneIndex == filterZoneIndex then
                local dx, dy = wsNx - px, wsNy - py
                local dist = dx * dx + dy * dy
                if dist < bestDist and dist >= (minDist or 0) then
                    bestDist = dist
                    bestNode = nodeIndex
                end
            end
        end
    end
    return bestNode
end

local function FindBestDiscoveredWayshrineFromScan(candidate)
    -- scannedData is freed after BuildCandidates; search the candidates list instead.
    local list = candidates
    if not list then return nil end

    local filterZoneId    = candidate and candidate.zoneId
    local filterZoneIndex = GetResolvedZoneIndex(candidate)
    local filterZoneName  = candidate and candidate.name and candidate.name:lower() or nil

    local function pickBest(matchFn)
        local bestNode     = nil
        local bestPriority = -math.huge
        for _, c in ipairs(list) do
            if c.type == TYPE_WAYSHRINE and c.nodeIndex and c.known and not c.isLocked and matchFn(c) then
                local prio = c.mapPriority or 0
                if prio > bestPriority then
                    bestPriority = prio
                    bestNode = c.nodeIndex
                end
            end
        end
        return bestNode
    end

    if filterZoneId then
        local byZoneId = pickBest(function(c) return c.zoneId == filterZoneId end)
        if byZoneId then return byZoneId end
    end

    if filterZoneIndex then
        local byZoneIndex = pickBest(function(c) return GetResolvedZoneIndex(c) == filterZoneIndex end)
        if byZoneIndex then return byZoneIndex end
    end

    if filterZoneName and filterZoneName ~= "" then
        local byZoneName = pickBest(function(c)
            return c.zoneName and c.zoneName:lower() == filterZoneName
        end)
        if byZoneName then return byZoneName end
    end

    return nil
end

local LOCATION_TRADER_ICONS = { ["servicepin_guildkiosk.dds"] = true }

local function GetLocationIconFile(icon)
    return icon and icon:match("([^/]+)$") or ""
end

local function AddUnique(list, seen, value)
    if not value or value == "" then return end
    local key = zo_strlower(value)
    if seen[key] then return end
    seen[key] = true
    list[#list + 1] = value
end

local function GetFirstLineText(value)
    if not value or value == "" then return nil end
    local text = (value:match("^([^\n]+)") or value):match("^%s*(.-)%s*$")
    return text ~= "" and text or nil
end

local function GetTraderNamesFromService(service, displayName)
    if not service or not service.isTrader then return nil end

    local names, seen = {}, {}
    local matchedDisplayName = false

    local function addName(value)
        local name = GetFirstLineText(value)
        if not name or name == "" then return end
        if displayName and name == displayName then
            matchedDisplayName = true
            return
        end
        AddUnique(names, seen, name)
    end

    for _, npcName in ipairs(service.npcLines or {}) do
        addName(npcName)
    end
    if matchedDisplayName then return { displayName } end
    if #names == 0 then
        addName(service.name)
    end

    return #names > 0 and names or nil
end

local function ReadMapLocationLines(locIndex)
    local lines = {}
    for lineIndex = 1, GetNumMapLocationTooltipLines(locIndex) do
        local _, lineName, grouping, category = GetMapLocationTooltipLineInfo(locIndex, lineIndex)
        lines[#lines + 1] = {
            CleanName(lineName or ""),
            grouping,
            CleanName(category or ""),
            IsMapLocationTooltipLineVisible(locIndex, lineIndex),
        }
    end
    return lines
end

local function GetMapLocationText(header, lines)
    local name = CleanName(header or "")
    local aliases = {}

    for _, line in ipairs(lines or {}) do
        local lineName = line[1]
        local category = line[3]
        if lineName and lineName ~= "" then
            if name == "" then
                name = lineName
            elseif lineName ~= name then
                aliases[#aliases + 1] = lineName
            end
        end
        if category and category ~= "" then
            if category ~= name then
                aliases[#aliases + 1] = category
            end
        end
    end

    return name, table.concat(aliases, " ")
end

local function GetMapLocationCategory(lines, fallbackName)
    fallbackName = CleanName(fallbackName or "")
    local sameAsName = nil
    for _, line in ipairs(lines or {}) do
        local category = line[3]
        if category and category ~= "" then
            if category ~= fallbackName then
                return category
            elseif not sameAsName then
                sameAsName = category
            end
        end
    end
    return sameAsName
end

local function AddScannedLocation(locations, seenLocations, loc)
    if not loc.name or loc.name == "" or not loc.destinationX or not loc.destinationY then return end

    local key = table.concat({
        tostring(loc.cityMapId or ""),
        tostring(loc.icon or ""),
        tostring(loc.destinationX or ""),
        tostring(loc.destinationY or ""),
        loc.name:lower(),
    }, "|")
    if seenLocations[key] then return end
    seenLocations[key] = true

    locations[#locations + 1] = loc
end

local function ScanCurrentMapLocations(scan)
    local traderCount = 0
    for locIndex = 1, GetNumMapLocations() do
        local locIcon, lx, lz = GetMapLocationIcon(locIndex)
        local iconFile = GetLocationIconFile(locIcon)
        local header = GetMapLocationTooltipHeader(locIndex)
        local lines = ReadMapLocationLines(locIndex)
        local name, aliases = GetMapLocationText(header, lines)
        local category = GetMapLocationCategory(lines, name)
        local isTrader = LOCATION_TRADER_ICONS[iconFile] == true
        local traderNode = nil

        if isTrader then
            traderCount = traderCount + 1
            if scan.fixedTraderNode then
                traderNode = scan.fixedTraderNode
            elseif scan.zoneIndex then
                traderNode = FindNearestWayshrineToPos(lx, lz, 0, scan.zoneIndex)
            end
            if traderNode then
                scan.tradersByNodeIndex[traderNode] = (scan.tradersByNodeIndex[traderNode] or 0) + 1
            end
        end

        local npcLines = nil
        if #lines > 0 then
            npcLines = {}
            for _, line in ipairs(lines) do
                local n = line[1] or ""
                if n ~= "" then npcLines[#npcLines + 1] = n end
            end
            if #npcLines == 0 then npcLines = nil end
        end

        AddScannedLocation(scan.locations, scan.seenLocations, {
            name         = name,
            category     = category,
            aliases      = aliases,
            icon         = locIcon,
            zoneId       = scan.zoneId,
            cityMapId    = scan.cityMapId,
            cityName     = scan.cityName,
            destinationX = lx,
            destinationY = lz,
            isTrader     = isTrader,
            nearestNode  = traderNode,
            npcLines     = npcLines,
        })
    end

    return traderCount
end

local function ScanCityServices(yielder)
    local apiVersion = GetAPIVersion and GetAPIVersion() or 0
    local originalMapId = GetCurrentMapId and GetCurrentMapId() or nil
    local locations = {}
    local tradersByNodeIndex = {}
    local seenCityMapIds = {}
    local seenLocations = {}

    -- When a yielder is supplied (background pre-warm) the scan runs in small
    -- batches per frame so it never blows the console per-frame budget. The map
    -- is restored to the batch-start position before yielding so an open world
    -- map never visibly jumps. Without a yielder this runs synchronously as before.
    local batchStartMap = originalMapId
    local sinceYield = 0

    for mapIndex = 1, GetNumMaps() do
        local mapName, mapType, _, zoneIndex = GetMapInfoByIndex(mapIndex)
        if mapName and mapName ~= "" and (mapType == MAPTYPE_ZONE or mapType == MAPTYPE_SUBZONE) then
            SetMapToMapListIndex(mapIndex)
            local parentZoneId = (zoneIndex and zoneIndex > 0) and GetZoneId(zoneIndex) or 0

            -- count traders placed directly on the zone map (outside any city zoom)
            if parentZoneId > 0 then
                ScanCurrentMapLocations({
                    locations = locations,
                    seenLocations = seenLocations,
                    tradersByNodeIndex = tradersByNodeIndex,
                    zoneId = parentZoneId,
                    zoneIndex = zoneIndex,
                    cityMapId = GetCurrentMapId and GetCurrentMapId() or 0,
                    cityName = CleanName(GetMapName()),
                })
            end

            if zoneIndex and zoneIndex > 0 then
                for poiIndex = 1, GetNumPOIs(zoneIndex) do
                    local nx, ny, _, icon = GetPOIMapInfo(zoneIndex, poiIndex)
                    if icon and (icon:find("poi_city") or icon:find("poi_town")) and nx and nx > 0 then
                        local cityName = CleanName(GetPOIInfo(zoneIndex, poiIndex) or "")
                        local _, _, _, _, _, _, cityMapId = GetMapMouseoverInfo(nx, ny)
                        if cityMapId and cityMapId ~= 0 and not seenCityMapIds[cityMapId] then
                            seenCityMapIds[cityMapId] = true
                            local nearestNode = FindNearestWayshrineToPos(nx, ny, 0, zoneIndex)
                            SetMapToMapId(cityMapId)
                            ScanCurrentMapLocations({
                                locations = locations,
                                seenLocations = seenLocations,
                                tradersByNodeIndex = tradersByNodeIndex,
                                zoneId = parentZoneId,
                                cityMapId = cityMapId,
                                cityName = cityName,
                                fixedTraderNode = nearestNode,
                            })
                            SetMapToMapListIndex(mapIndex)
                        end
                    end
                end
            end
        end

        if yielder then
            sinceYield = sinceYield + 1
            if sinceYield >= CITY_SCAN_BATCH then
                sinceYield = 0
                if batchStartMap then SetMapToMapId(batchStartMap) end
                yielder()
                batchStartMap = GetCurrentMapId and GetCurrentMapId() or nil
            end
        end
    end

    for _, subMap in ipairs(GetClickableSubMaps()) do
        local mapId = subMap.mapId
        if mapId and mapId ~= 0 and not seenCityMapIds[mapId] then
            seenCityMapIds[mapId] = true
            SetMapToMapId(mapId)
            local zoneIndex = GetCurrentMapZoneIndex()
            local zoneId = (zoneIndex and zoneIndex > 0) and GetZoneId(zoneIndex) or subMap.parentZoneId
            local mapName = CleanName(GetMapName())
            ScanCurrentMapLocations({
                locations = locations,
                seenLocations = seenLocations,
                tradersByNodeIndex = tradersByNodeIndex,
                zoneId = zoneId,
                zoneIndex = zoneIndex,
                cityMapId = mapId,
                cityName = mapName ~= "" and mapName or subMap.name,
            })
        end
    end

    -- Restore to where we were at the start of the final batch (= scan start for
    -- the synchronous path, since batchStartMap is never advanced without a yielder).
    if batchStartMap then SetMapToMapId(batchStartMap) end
    return {
        locations = locations,
        tradersByNodeIndex = tradersByNodeIndex,
        apiVersion = apiVersion,
    }
end

-- --- Saved-cache compaction -------------------------------------------------
-- The in-memory city cache stays "rich" (all consumers read it unchanged). Only
-- the on-disk copy is compacted to keep the console autosave small: icon paths
-- are interned into a shared list, the redundant `aliases` string is dropped
-- (rebuilt from npcLines + category on load), and float coords are rounded.

local function RoundCoord(v)
    if type(v) ~= "number" then return v end
    return math.floor(v * 10000 + 0.5) / 10000
end

local function BuildAliasesFromLines(name, category, npcLines)
    local parts = {}
    name = name or ""
    if npcLines then
        for _, line in ipairs(npcLines) do
            if line and line ~= "" and line ~= name then parts[#parts + 1] = line end
        end
    end
    if category and category ~= "" and category ~= name then parts[#parts + 1] = category end
    return table.concat(parts, " ")
end

local function CompactCityScanForSave(cache)
    if not cache or not cache.locations then return cache end

    local iconList, iconIndex = {}, {}
    local function internIcon(icon)
        icon = icon or ""
        local idx = iconIndex[icon]
        if not idx then
            iconList[#iconList + 1] = icon
            idx = #iconList
            iconIndex[icon] = idx
        end
        return idx
    end

    local outLocations = {}
    for i = 1, #cache.locations do
        local loc = cache.locations[i]
        local copy = {}
        for k, v in pairs(loc) do copy[k] = v end
        copy.aliases     = nil                      -- rebuilt on load
        copy.icon        = internIcon(loc.icon)     -- index into iconList
        copy.destinationX = RoundCoord(loc.destinationX)
        copy.destinationY = RoundCoord(loc.destinationY)
        outLocations[i] = copy
    end

    return {
        apiVersion         = cache.apiVersion,
        locations          = outLocations,
        tradersByNodeIndex = cache.tradersByNodeIndex,
        icons              = iconList,
    }
end

local function RehydrateCityScan(saved)
    if not saved or not saved.locations then return nil end
    local iconList = saved.icons or {}
    local outLocations = {}
    for i = 1, #saved.locations do
        local loc = saved.locations[i]
        local copy = {}
        for k, v in pairs(loc) do copy[k] = v end
        if type(copy.icon) == "number" then
            copy.icon = iconList[copy.icon] or ""
        end
        copy.aliases = BuildAliasesFromLines(copy.name, copy.category, copy.npcLines)
        outLocations[i] = copy
    end
    return {
        apiVersion         = saved.apiVersion,
        locations          = outLocations,
        tradersByNodeIndex = saved.tradersByNodeIndex,
    }
end

local function LoadCityScanFromSavedVars()
    local mapData = _G["GamePadHelperMapData"]
    local apiVersion = GetAPIVersion and GetAPIVersion() or 0
    if mapData and mapData.cityScanCache
        and mapData.cityScanCache.apiVersion == apiVersion
        and mapData.cityScanCache.locations
        and mapData.cityScanCache.tradersByNodeIndex then
        cityServicesCache = RehydrateCityScan(mapData.cityScanCache)
    end
end

local function BuildTraderOwnershipLookup()
    -- ESO only exposes current guild ownership for guilds the player belongs to.
    -- Map-location scans provide the trader NPC names, so keep both and merge
    -- owner guilds in when an exact kiosk-name match is available.
    local byName = {}
    local function addGuildNameKey(key, guildName)
        if not key or key == "" or not guildName or guildName == "" then return end
        key = zo_strlower(CleanName(key))
        if not byName[key] then byName[key] = {} end
        byName[key][#byName[key] + 1] = guildName
    end

    for i = 1, GetNumGuilds() do
        local guildId   = GetGuildId(i)
        local kioskName = GetGuildOwnedKioskInfo(guildId)
        if kioskName and kioskName ~= "" then
            local guildName = GetGuildName(guildId)
            local npc, loc  = kioskName:match("^(.+) in (.+)$")
            addGuildNameKey(kioskName, guildName)
            addGuildNameKey(npc, guildName)
            addGuildNameKey(loc, guildName)
        end
    end

    local byNode = {}
    local traderNamesByNode = {}

    local function addGuildsToNode(nodeIndex, guilds)
        if not nodeIndex or not guilds then return end
        if not byNode[nodeIndex] then byNode[nodeIndex] = {} end
        local seen = {}
        for _, g in ipairs(byNode[nodeIndex]) do seen[g] = true end
        for _, g in ipairs(guilds) do
            if not seen[g] then
                seen[g] = true
                byNode[nodeIndex][#byNode[nodeIndex] + 1] = g
            end
        end
    end

    local cache  = cityServicesCache
    if cache and cache.locations then
        for _, loc in ipairs(cache.locations) do
            if loc.isTrader then
                local names = GetTraderNamesFromService(loc)

                if loc.nearestNode and names and #names > 0 then
                    if not traderNamesByNode[loc.nearestNode] then traderNamesByNode[loc.nearestNode] = {} end
                    local nodeSeen = {}
                    for _, name in ipairs(traderNamesByNode[loc.nearestNode]) do nodeSeen[zo_strlower(name)] = true end
                    for _, name in ipairs(names) do
                        AddUnique(traderNamesByNode[loc.nearestNode], nodeSeen, name)
                    end
                end

                if names then
                    for _, name in ipairs(names) do
                        addGuildsToNode(loc.nearestNode, byName[zo_strlower(CleanName(name))])
                    end
                end
            end
        end
    end
    return {
        byName = byName,
        byNode = byNode,
        traderNamesByNode = traderNamesByNode,
    }
end

local function GetCityServices()
    local apiVersion = GetAPIVersion and GetAPIVersion() or 0
    if not cityServicesCache
        or cityServicesCache.apiVersion ~= apiVersion
        or not cityServicesCache.locations
        or not cityServicesCache.tradersByNodeIndex then
        cityServicesCache = ScanCityServices()
        if not _G["GamePadHelperMapData"] then _G["GamePadHelperMapData"] = {} end
        _G["GamePadHelperMapData"].cityScanCache = CompactCityScanForSave(cityServicesCache)
    end
    if not traderGuildMap then
        traderGuildMap = BuildTraderOwnershipLookup()
    end
    return cityServicesCache
end

local function GetTraderOwnershipLookup()
    if not traderGuildMap then GetCityServices() end
    return traderGuildMap
end

local function IsCityCacheReady()
    local apiVersion = GetAPIVersion and GetAPIVersion() or 0
    return cityServicesCache
        and cityServicesCache.apiVersion == apiVersion
        and cityServicesCache.locations
        and cityServicesCache.tradersByNodeIndex
end

local SCAN_PREWARM_UPDATE = "GamePadHelper_CityScanPrewarm"
local cityScanPrewarmActive = false

-- Build the city-services cache in the background, a few maps per frame,
-- instead of one big synchronous scan. GetCityServices() still has the
-- synchronous scan as a fallback, so a search that fires before the prewarm
-- finishes is never blocked.
local function StartCityScanPrewarm(onComplete)
    if cityScanPrewarmActive then return end
    if IsCityCacheReady() then
        if onComplete then onComplete() end
        return
    end

    cityScanPrewarmActive = true
    local co = coroutine.create(function()
        return ScanCityServices(coroutine.yield)
    end)

    EVENT_MANAGER:RegisterForUpdate(SCAN_PREWARM_UPDATE, 0, function()
        -- Something else (e.g. a search forcing a synchronous scan) finished first.
        if IsCityCacheReady() then
            EVENT_MANAGER:UnregisterForUpdate(SCAN_PREWARM_UPDATE)
            cityScanPrewarmActive = false
            return
        end

        local ok, result = coroutine.resume(co)
        if not ok then
            EVENT_MANAGER:UnregisterForUpdate(SCAN_PREWARM_UPDATE)
            cityScanPrewarmActive = false
            return
        end

        if coroutine.status(co) == "dead" then
            EVENT_MANAGER:UnregisterForUpdate(SCAN_PREWARM_UPDATE)
            cityScanPrewarmActive = false
            cityServicesCache = result
            if not _G["GamePadHelperMapData"] then _G["GamePadHelperMapData"] = {} end
            _G["GamePadHelperMapData"].cityScanCache = CompactCityScanForSave(result)
            traderGuildMap = BuildTraderOwnershipLookup()
            if onComplete then onComplete() end
        end
    end)
end

local function GetOwnedGuildNamesForCandidate(c)
    if not c then return nil end
    local traderLookup = GetTraderOwnershipLookup()
    if not traderLookup then return nil end

    local guilds, seen = {}, {}
    local function addGuilds(list)
        if not list then return end
        for _, guildName in ipairs(list) do
            AddUnique(guilds, seen, guildName)
        end
    end

    if c.nodeIndex and not c.isTrader then
        addGuilds(traderLookup.byNode[c.nodeIndex])
    end

    if c.isTrader and c.traderNames then
        for _, traderName in ipairs(c.traderNames) do
            if traderName and traderName ~= "" then
                addGuilds(traderLookup.byName[zo_strlower(CleanName(traderName))])
            end
        end
        return #guilds > 0 and guilds or nil
    elseif c.isTrader then
        return nil
    end

    local function addByNameKey(value)
        if not value or value == "" then return end
        addGuilds(traderLookup.byName[zo_strlower(CleanName(value))])
    end
    addByNameKey(c.name)
    addByNameKey(c.cityName)

    return #guilds > 0 and guilds or nil
end

local function GetTraderNamesForCandidate(c)
    if not c then return nil end
    if c.isTrader and c.traderNames then return c.traderNames end
    local traderLookup = GetTraderOwnershipLookup()
    if not traderLookup then return nil end
    if c.nodeIndex and traderLookup.traderNamesByNode then
        local names = traderLookup.traderNamesByNode[c.nodeIndex]
        if names and #names > 0 then return names end
    end
    return nil
end

local function GetTraderCountForCandidate(c)
    if not c then return nil end
    if c.type == TYPE_WAYSHRINE then
        local traderNames = GetTraderNamesForCandidate(c)
        if traderNames and #traderNames > 0 then
            return #traderNames
        elseif c.traderCount then
            return c.traderCount
        elseif cityServicesCache and cityServicesCache.tradersByNodeIndex and c.nodeIndex then
            return cityServicesCache.tradersByNodeIndex[c.nodeIndex]
        end
    elseif c.isTrader then
        return c.traderCount or 1
    end
    return nil
end


local function GetGroupCountsPerKeep(keepNodes)
    local counts     = {}
    local leaderTag  = nil
    local leaderKeep = nil

    for i = 1, GetGroupSize() do
        local tag = GetGroupUnitTagByIndex(i)
        if tag and DoesUnitExist(tag) and IsUnitOnline(tag) then
            if IsUnitGroupLeader(tag) then leaderTag = tag end
        end
    end

    local function nearestKeep(nx, ny)
        local best, bestDist = nil, math.huge
        for _, node in ipairs(keepNodes) do
            local d = (nx - node.normX)^2 + (ny - node.normY)^2
            if d < bestDist then best, bestDist = node.keepId, d end
        end
        return best
    end

    for i = 1, GetGroupSize() do
        local tag = GetGroupUnitTagByIndex(i)
        if tag and DoesUnitExist(tag) and IsUnitOnline(tag) then
            local x, y, _, isInMap = GetMapPlayerPosition(tag)
            if isInMap then
                local kid = nearestKeep(x, y)
                if kid then counts[kid] = (counts[kid] or 0) + 1 end
            end
        end
    end

    local leaderX, leaderY
    if leaderTag then
        local lx, ly, _, isInMap = GetMapPlayerPosition(leaderTag)
        if isInMap then
            leaderKeep = nearestKeep(lx, ly)
            leaderX, leaderY = lx, ly
        end
    end

    return counts, leaderKeep, leaderX, leaderY
end

local function IsCyrodiilKeepSearchEnabled()
    local sv = _G["GamePadHelper_CharSavedVars"]
    if sv and sv.cyrodiilKeepSearchEnabled == false then return false end
    return true
end


local cyrodiilMainMapId = nil  -- captured when main Cyrodiil map is open, reused for sub-map panning

local function BuildCyrodiilKeepCandidates(list)
    if not IsCyrodiilKeepSearchEnabled() then return end
    if not GetMapContentType or GetMapContentType() ~= MAP_CONTENT_AVA then return end

    -- Store Cyrodiil main map ID only when on the zone-level map (not a gate sub-map)
    if GetCurrentMapId and GetMapType and GetMapType() == MAPTYPE_ZONE then
        cyrodiilMainMapId = GetCurrentMapId()
    end

    local bgContext = BGQUERY_ASSIGNED_AND_LOCAL
    local VALID_TYPES = {
        [KEEPTYPE_KEEP]        = true,
        [KEEPTYPE_OUTPOST]     = true,
        [KEEPTYPE_BORDER_KEEP] = true,
    }

    local keepNodes = {}
    for i = 1, GetNumKeepTravelNetworkNodes(bgContext) do
        local keepId, accessible, normX, normY = GetKeepTravelNetworkNodeInfo(i, bgContext)
        if accessible then
            local kt = GetKeepType(keepId)
            if VALID_TYPES[kt] then
                keepNodes[#keepNodes + 1] = { keepId = keepId, normX = normX, normY = normY }
            end
        end
    end

    if #keepNodes == 0 then return end

    local groupCounts, leaderKeepId, leaderX, leaderY = GetGroupCountsPerKeep(keepNodes)

    table.sort(keepNodes, function(a, b)
        local aIsLeader = (a.keepId == leaderKeepId)
        local bIsLeader = (b.keepId == leaderKeepId)
        if aIsLeader ~= bIsLeader then return aIsLeader end
        local ac = groupCounts[a.keepId] or 0
        local bc = groupCounts[b.keepId] or 0
        if ac ~= bc then return ac > bc end
        return CleanName(GetKeepName(a.keepId)) < CleanName(GetKeepName(b.keepId))
    end)

    for _, node in ipairs(keepNodes) do
        local keepId   = node.keepId
        local name     = CleanName(GetKeepName(keepId))
        local alliance = GetKeepAlliance(keepId, bgContext)
        local pinType  = GetKeepPinInfo(keepId, bgContext)
        local pinData  = ZO_MapPin and ZO_MapPin.PIN_DATA and ZO_MapPin.PIN_DATA[pinType]
        list[#list + 1] = {
            name         = name,
            searchName   = name:lower(),
            type         = TYPE_CYRODIIL_KEEP,
            icon         = pinData and pinData.texture,
            keepId       = keepId,
            alliance     = alliance,
            groupCount   = groupCounts[keepId] or 0,
            isLeaderKeep = (keepId == leaderKeepId),
            leaderNormX  = (keepId == leaderKeepId) and leaderX or nil,
            leaderNormY  = (keepId == leaderKeepId) and leaderY or nil,
            normX        = node.normX,
            normY        = node.normY,
            cityMapId    = cyrodiilMainMapId,
            known        = true,
            isLocked     = false,
        }
    end
end

local function BuildCandidates()
    if not scannedData then PreScan() end

    local nameToZoneId = scannedData.nameToZoneId
    local list = {}
    local cityServiceSetEntryCache = {}
    local cityServiceTraderNamesCache = {}
    local ownedHouseByKey = {}
    local ownedHouseByName = {}
    local wayshrineNames = {}

    for _, ws in ipairs(scannedData.wayshrines) do
        if ws.isHouse and ws.isOwnedHouse and ws.houseId and ws.name then
            local key = (ws.name:lower()) .. "|" .. tostring(ws.zoneId or 0)
            ownedHouseByKey[key] = ws
            ownedHouseByName[ws.name:lower()] = ownedHouseByName[ws.name:lower()] or ws
        end
        if ws.name then wayshrineNames[ws.name:lower()] = true end
        local searchAliases = GetGuildSearchAliases(ws.name, ws.nodeIndex)
        list[#list + 1] = {
            name        = ws.name,
            searchName  = BuildSearchName(ws.name, searchAliases),
            type        = ws.isHouse and (ws.isOwnedHouse and TYPE_HOUSE_OWNED or TYPE_HOUSE_UNOWNED)
                       or TYPE_WAYSHRINE,
            icon        = ws.icon,
            nodeIndex   = ws.nodeIndex,
            zoneId      = ws.zoneId,
            poiIndex    = ws.poiIndex,
            zoneName    = ws.zoneName,
            known       = ws.known,
            isLocked    = ws.isLocked,
            houseId     = ws.houseId,
            mapPriority = ws.mapPriority,
        }
    end

    for _, z in ipairs(scannedData.zones) do
        list[#list + 1] = {
            name       = z.name,
            searchName = z.name:lower(),
            type       = TYPE_ZONE,
            icon       = "EsoUI/Art/Icons/mapKey/mapKey_zoneStory.dds",
            zoneId     = z.zoneId,
            zoneName   = z.name,
            known      = true,
            isLocked   = z.isLocked,
        }
    end

    for _, poi in ipairs(scannedData.pois) do
        if poi.name and not wayshrineNames[poi.name:lower()] then
            local poiTypeLabel = GetPOITypeLabel(poi.icon, poi.poiType)
            local isHousePOI   = poiTypeLabel == GetString(SI_GPH_MAPSEARCH_LABEL_HOUSE)
            local searchAliases = GetGuildSearchAliases(poi.name, nil)
            local matchedOwnedHouse = nil
            if isHousePOI and poi.isOwned and poi.name then
                local key = (poi.name:lower()) .. "|" .. tostring(poi.zoneId or 0)
                matchedOwnedHouse = ownedHouseByKey[key] or ownedHouseByName[poi.name:lower()]
            end
            local entryType = isHousePOI
                and (poi.isOwned and TYPE_HOUSE_OWNED or TYPE_HOUSE_UNOWNED)
                or TYPE_POI

            local cityZoneId = (poi.icon:find("poi_city") and nameToZoneId[poi.name]) or nil
            local entry = {
                name         = poi.name,
                searchName   = BuildSearchName(poi.name, searchAliases),
                type         = entryType,
                poiTypeLabel = poiTypeLabel,
                icon         = poi.icon,
                nodeIndex    = matchedOwnedHouse and matchedOwnedHouse.nodeIndex or nil,
                houseId      = matchedOwnedHouse and matchedOwnedHouse.houseId or nil,
                isLocked     = poi.isLocked,
            }
            if cityZoneId then
                entry.zoneId   = cityZoneId
            else
                entry.searchName = BuildSearchName(poi.name, (searchAliases ~= "" and searchAliases .. " " or "") .. GetCraftingSetSearchAlias(poi.setId))
                entry.zoneId   = poi.zoneId
                entry.poiIndex = poi.poiIndex
                entry.zoneName   = poi.zoneName
                entry.known      = poi.known
                entry.traitCount = poi.traitCount
                entry.setName    = poi.setName
                entry.setId      = poi.setId
            end
            list[#list + 1] = entry
        end
    end

    local cityServices = GetCityServices()
    local seenCustom = {}
    local function AddCityServiceCandidate(service, zoneName, displayName, searchAliases, placeName, category, detailLabel, entryType)
        if not displayName or displayName == "" then return end
        local metadataCacheKey = table.concat({
            tostring(service.zoneId or ""),
            displayName,
            tostring(service.isTrader or false),
        }, "|")

        local setEntry = cityServiceSetEntryCache[metadataCacheKey]
        if setEntry == nil then
            setEntry = GetCraftingSetLocationEntry(service.zoneId, displayName) or false
            cityServiceSetEntryCache[metadataCacheKey] = setEntry
        end
        if setEntry == false then
            setEntry = nil
        end

        local traderNames = cityServiceTraderNamesCache[metadataCacheKey]
        if traderNames == nil then
            traderNames = GetTraderNamesFromService(service, displayName) or false
            cityServiceTraderNamesCache[metadataCacheKey] = traderNames
        end
        if traderNames == false then
            traderNames = nil
        end

        entryType = entryType or (service.isTrader and TYPE_TRADER)
            or (IsTravelService(service, displayName, category, detailLabel) and TYPE_TRAVEL)
            or TYPE_CUSTOM
        local key = table.concat({
            displayName:lower(),
            placeName and placeName:lower() or "",
            category and category:lower() or "",
            zoneName:lower(),
            tostring(service.cityMapId or ""),
            tostring(service.icon or ""),
            tostring(service.destinationX or ""),
            tostring(service.destinationY or ""),
        }, "|")
        if seenCustom[key] then return end
        seenCustom[key] = true
        list[#list + 1] = {
            name         = displayName,
            searchName   = BuildSearchName(displayName, table.concat({
                searchAliases or "",
                zoneName,
                service.cityName or "",
                placeName or "",
                category or "",
                detailLabel or "",
                setEntry and GetCraftingSetSearchAlias(setEntry.setId) or "",
            }, " ")),
            type         = entryType,
            icon         = (service.icon and service.icon ~= "") and service.icon or ICON_POI_GENERIC,
            zoneId       = service.zoneId,
            zoneName     = zoneName,
            placeName    = placeName,
            cityName     = service.cityName,
            cityMapId    = service.cityMapId,
            destinationX = service.destinationX,
            destinationY = service.destinationY,
            poiTypeLabel = category,
            narrationLabel = category,
            detailLabel  = detailLabel,
            isTrader     = service.isTrader,
            traderCount  = traderNames and #traderNames or nil,
            traderNames  = traderNames,
            known        = true,
            isLocked     = false,
            traitCount   = setEntry and setEntry.traits or nil,
            setName      = setEntry and GetCraftingSetName(setEntry.setId) or nil,
            setId        = setEntry and setEntry.setId or nil,
        }
    end

    local function ExtractDestinations(npcLine)
        local parts = {}
        for dest in (npcLine:gsub("^[^\n]+\n", "")):gmatch("[^\n]+") do
            local d = dest:match("^%s*(.-)%s*$")
            if d and d ~= "" then parts[#parts + 1] = d end
        end
        return #parts > 0 and table.concat(parts, "; ") or nil
    end

    for _, service in ipairs(cityServices.locations or {}) do
        local zoneName = GetCleanZoneName(service.zoneId)
        local name     = service.name
        if name and name ~= "" then
            -- Names on ferry/caravan services may embed the first destination after \n — keep only the NPC name
            local displayName = GetFirstLineText(name)
            local aliases = GetGuildSearchAliases(displayName, nil)
            local detailLabel = nil
            local serviceDetailParts = {}
            local npcAliases = {}
            for _, npcName in ipairs(service.npcLines or {}) do
                local n = GetFirstLineText(npcName)
                if n then
                    serviceDetailParts[#serviceDetailParts + 1] = n
                    npcAliases[#npcAliases + 1] = n
                end
            end
            if #serviceDetailParts > 0 then detailLabel = table.concat(serviceDetailParts, "; ") end
            AddCityServiceCandidate(service, zoneName, displayName, table.concat({
                aliases,
                service.aliases or "",
                table.concat(npcAliases, " "),
            }, " "), nil, service.category, detailLabel)

            if not service.isTrader then
                for _, npcName in ipairs(service.npcLines or {}) do
                    if npcName:find("\n", 1, true) then
                        local cleanNpcName = GetFirstLineText(npcName)
                        if cleanNpcName and cleanNpcName ~= displayName then
                            local destinations = ExtractDestinations(npcName)
                            local lineType = IsTravelService(service, cleanNpcName, service.category, destinations) and TYPE_TRAVEL or TYPE_NPC
                            AddCityServiceCandidate(service, zoneName, cleanNpcName, name, nil, service.category, destinations, lineType)
                        end
                    end
                end
            end
        end
    end
    local dailyGivers = GamePadHelper_MapSearchData and GamePadHelper_MapSearchData.DAILY_QUEST_GIVERS
    if dailyGivers then
        local playerAlliance = GetUnitAlliance and GetUnitAlliance("player") or 0
        local seenDaily = {}
        for _, entry in ipairs(dailyGivers) do
            local locs = entry.locations or {}
            if playerAlliance ~= 0 and #locs > 1 then
                local sorted = {}
                for i = 1, #locs do sorted[i] = locs[i] end
                table.sort(sorted, function(a, b)
                    local aMatch = (a.alliance == playerAlliance) and 0 or 1
                    local bMatch = (b.alliance == playerAlliance) and 0 or 1
                    return aMatch < bMatch
                end)
                locs = sorted
            end
            for _, loc in ipairs(locs) do
                local zoneName = GetCleanZoneName(loc.zoneId)
                local key = (entry.name or ""):lower() .. "|" .. (loc.placeName or ""):lower() .. "|" .. (loc.cityName or ""):lower()
                if not seenDaily[key] then
                    seenDaily[key] = true
                    list[#list + 1] = {
                        name         = entry.name,
                        searchName   = BuildSearchName(entry.name, table.concat({
                            entry.category or "",
                            loc.cityName or "",
                            loc.placeName or "",
                            zoneName,
                        }, " ")),
                        type         = TYPE_NPC,
                        icon         = "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_repeatable.dds",
                        zoneId       = loc.zoneId,
                        zoneName     = zoneName,
                        placeName    = loc.placeName,
                        cityName     = loc.cityName,
                        cityMapId    = loc.cityMapId,
                        destinationX = loc.x,
                        destinationY = loc.y,
                        poiTypeLabel = "Daily",
                        detailLabel  = entry.category,
                        known        = true,
                        isLocked     = false,
                    }
                end
            end
        end
    end

    BuildCyrodiilKeepCandidates(list)

    scannedData = nil  -- free raw scan data; candidates table has everything needed
    return list
end

-- search

local function ScoreMatch(nameLower, termLower)
    if termLower == "" then return 1.0 end
    local ni, ti     = 1, 1
    local consec     = 0
    local score      = 0
    local nLen, tLen = #nameLower, #termLower

    while ni <= nLen and ti <= tLen do
        if nameLower:sub(ni, ni) == termLower:sub(ti, ti) then
            ti     = ti + 1
            consec = consec + 1
            score  = score + consec * consec
        else
            consec = 0
        end
        ni = ni + 1
    end

    if ti <= tLen then return 0 end
    if nameLower:sub(1, tLen) == termLower then score = score + 200 end
    if nameLower == termLower               then score = score + 500 end
    return score
end

RunSearch = function(term)
    if not candidates then candidates = BuildCandidates() end

    term = currentTab == TAB_SEARCH and (term or "") or ""
    local searchKey = currentTab .. ":" .. term
    if searchKey == lastSearchTerm then return end
    lastSearchTerm = searchKey

    local termLower = term:lower()
    local scored    = {}
    local bookmarks = GetBookmarksArray()
    local bookmarkedByKey = {}
    for _, bm in ipairs(bookmarks) do
        bookmarkedByKey[GetBookmarkKey(bm)] = true
    end

    local source = candidates
    if currentTab == TAB_BOOKMARKS then
        source = bookmarks
    elseif currentTab == TAB_RECENT then
        source = GetRecentArray()
    end

    if termLower == "" and currentTab == TAB_SEARCH then
        results = {}
        if IsCyrodiilKeepSearchEnabled() and GetMapContentType and GetMapContentType() == MAP_CONTENT_AVA then
            for i = 1, #source do
                local c = source[i]
                if c.type == TYPE_CYRODIIL_KEEP then
                    results[#results + 1] = c
                end
            end
        end
        return
    end

    if termLower == "" and currentTab ~= TAB_SEARCH then
        results = {}
        local cap = (currentTab == TAB_RECENT) and 20 or nil
        for i = 1, cap and math.min(#source, cap) or #source do
            local c = source[i]
            if IsCandidateInCurrentTab(c, bookmarkedByKey) then
                results[#results + 1] = c
            end
        end
        return
    end

    for i = 1, #source do
        local c = source[i]
        if IsCandidateInCurrentTab(c, bookmarkedByKey) then
            local searchName = c.searchName or (c.name and c.name:lower()) or ""
            local s = ScoreMatch(searchName, termLower)
            if s > 0 then scored[#scored + 1] = { score = s, c = c } end
        end
    end

    table.sort(scored, function(a, b)
        if a.score ~= b.score   then return a.score > b.score end
        if a.c.type ~= b.c.type then return a.c.type < b.c.type end
        return (a.c.searchName or a.c.name or "") < (b.c.searchName or b.c.name or "")
    end)

    -- bucket by type, preserving score order within each bucket
    local buckets  = {}
    local typeKeys = {}
    for _, item in ipairs(scored) do
        local t = item.c.type
        if not buckets[t] then
            buckets[t]            = {}
            typeKeys[#typeKeys+1] = t
        end
        buckets[t][#buckets[t]+1] = item.c
    end
    table.sort(typeKeys)

    -- round-robin across types so no single type dominates; total cap 50
    results = {}
    local indices = {}
    for _, t in ipairs(typeKeys) do indices[t] = 1 end
    local progress = true
    while #results < 50 and progress do
        progress = false
        for _, t in ipairs(typeKeys) do
            if #results >= 50 then break end
            local idx = indices[t]
            if idx <= #buckets[t] then
                results[#results+1] = buckets[t][idx]
                indices[t]          = idx + 1
                progress            = true
            end
        end
    end
end

-- zone map counts (surveys / treasure maps in inventory)

local function BuildZoneMapCounts()
    if not candidates then candidates = BuildCandidates() end

    -- Build a sorted list of zone searchNames (longest first) for greedy matching
    local zoneKeys = {}
    for _, c in ipairs(candidates) do
        if c.type == TYPE_ZONE and c.searchName and #c.searchName > 2 then
            zoneKeys[#zoneKeys + 1] = c.searchName
        end
    end
    table.sort(zoneKeys, function(a, b) return #a > #b end)

    local counts = {}
    local bags = { BAG_BACKPACK, BAG_BANK, BAG_SUBSCRIBER_BANK, BAG_VIRTUAL }
    for _, bagId in ipairs(bags) do
        for slotIndex = 0, GetBagSize(bagId) - 1 do
            if GetItemId(bagId, slotIndex) > 0 then
                local _, specializedItemType = GetItemType(bagId, slotIndex)
                local isSurvey   = specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT
                local isTreasure = specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP and not IsItemLinkUnique(GetItemLink(bagId, slotIndex))
                if isSurvey or isTreasure then
                    local itemName = GetItemName(bagId, slotIndex)
                    local itemLower = itemName and itemName:lower()
                    if itemLower then
                        -- Match against known zone names (language-agnostic)
                        local zoneKey = nil
                        for _, key in ipairs(zoneKeys) do
                            if itemLower:find(key, 1, true) then
                                zoneKey = key
                                break
                            end
                        end
                        if zoneKey then
                            if not counts[zoneKey] then counts[zoneKey] = { surveys = 0, treasures = 0 } end
                            local qty = GetSlotStackSize(bagId, slotIndex)
                            if isSurvey   then counts[zoneKey].surveys   = counts[zoneKey].surveys   + qty end
                            if isTreasure then counts[zoneKey].treasures = counts[zoneKey].treasures + qty end
                        end
                    end
                end
            end
        end
    end
    zoneMapCounts = counts
end

local function GetZoneMapCountText(searchName)
    if not zoneMapCounts or not searchName then return nil end
    local entry = zoneMapCounts[searchName]
    if not entry then
        -- fallback: check if any key is contained within the zone name or vice versa
        for k, v in pairs(zoneMapCounts) do
            if searchName:find(k, 1, true) or k:find(searchName, 1, true) then
                entry = v
                break
            end
        end
    end
    if not entry then return nil end
    local parts = {}
    if entry.surveys   > 0 then parts[#parts + 1] = entry.surveys   .. " " .. GetString(entry.surveys   == 1 and SI_GPH_MAPSEARCH_ZONE_SURVEY      or SI_GPH_MAPSEARCH_ZONE_SURVEYS)      end
    if entry.treasures > 0 then parts[#parts + 1] = entry.treasures .. " " .. GetString(entry.treasures == 1 and SI_GPH_MAPSEARCH_ZONE_TREASURE_MAP or SI_GPH_MAPSEARCH_ZONE_TREASURE_MAPS) end
    return #parts > 0 and table.concat(parts, " · ") or nil
end

-- zone quest counts

local zoneQuestCounts = nil

local function BuildZoneQuestCounts()
    local counts = {}
    for i = 1, MAX_JOURNAL_QUESTS do
        if IsValidQuestIndex(i) then
            local _, _, zoneIndex = GetJournalQuestLocationInfo(i)
            if zoneIndex and zoneIndex > 0 and zoneIndex < 100000 then
                local zoneId = GetZoneId(zoneIndex)
                if zoneId and zoneId > 0 then
                    counts[zoneId] = (counts[zoneId] or 0) + 1
                end
            end
        end
    end
    zoneQuestCounts = counts
end

local function GetZoneQuestCountText(zoneId)
    if not zoneQuestCounts or not zoneId then return nil end
    local n = zoneQuestCounts[zoneId]
    if not n or n <= 0 then return nil end
    return n .. " " .. GetString(n == 1 and SI_GPH_MAPSEARCH_ZONE_QUEST or SI_GPH_MAPSEARCH_ZONE_QUESTS)
end

-- zone lead counts (antiquity leads)

local function BuildZoneLeadCounts()
    if not ANTIQUITY_DATA_MANAGER then zoneLeadCounts = {} return end
    local counts = {}
    local antiquityId = GetNextAntiquityId()
    while antiquityId do
        local data = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)
        if data and data:HasLead() and data:MeetsScryingSkillRequirements() and not data:HasAchievedAllGoals() then
            local zoneId = data:GetZoneId()
            if zoneId and zoneId > 0 then
                counts[zoneId] = (counts[zoneId] or 0) + 1
            end
        end
        antiquityId = GetNextAntiquityId(antiquityId)
    end
    zoneLeadCounts = counts
end

local function GetZoneLeadCountText(zoneId)
    if not zoneLeadCounts or not zoneId then return nil end
    local n = zoneLeadCounts[zoneId]
    if not n or n <= 0 then return nil end
    return n .. " " .. GetString(n == 1 and SI_GPH_MAPSEARCH_ZONE_LEAD or SI_GPH_MAPSEARCH_ZONE_LEADS)
end

-- list

local function GetCandidateSubText(c)
    local parts = {}
    if c.zoneName and c.zoneName ~= "" then
        parts[#parts + 1] = c.zoneName
    end
    if (c.type == TYPE_POI or IsServiceMapTarget(c)) and c.poiTypeLabel then
        parts[#parts + 1] = c.poiTypeLabel
    elseif c.type == TYPE_WAYSHRINE then
        local mp = c.mapPriority or 0
        if mp >= 2 then
            parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_LABEL_WAYSHRINE_CAPITAL)
        elseif mp == 1 then
            parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_LABEL_WAYSHRINE_MAJOR)
        else
            parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_LABEL_WAYSHRINE)
        end
    elseif c.type == TYPE_HOUSE_OWNED or c.type == TYPE_HOUSE_UNOWNED then
        parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_LABEL_HOUSE)
    elseif c.type == TYPE_LIFT then
        parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_LABEL_LIFT)
    elseif c.type == TYPE_ZONE then
        parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_ZONE)
    elseif c.type == TYPE_CYRODIIL_KEEP then
        local allianceLabel = c.alliance and GetString("SI_ALLIANCE", c.alliance) or ""
        parts[#parts + 1] = allianceLabel ~= "" and allianceLabel or GetString(SI_GPH_MAPSEARCH_GROUP_CYRODIIL_KEEPS)
    end
    return #parts > 0 and table.concat(parts, ", ") or nil
end

local function ResolveOwnedHouseId(candidate)
    if not candidate then return nil end
    if candidate.houseId and candidate.houseId ~= 0 then
        return candidate.houseId
    end
    if candidate.nodeIndex then
        local hid = GetFastTravelNodeHouseId(candidate.nodeIndex)
        if hid and hid ~= 0 then return hid end
    end
    local targetName = candidate.name and candidate.name:lower()
    if not targetName then return nil end
    for nodeIndex = 1, GetNumFastTravelNodes() do
        local known, name, _, _, _, _, typePOI, _, _ = GetFastTravelNodeInfo(nodeIndex)
        if known and typePOI == POI_TYPE_HOUSE and name and name:lower() == targetName then
            local hid = GetFastTravelNodeHouseId(nodeIndex)
            if hid and hid ~= 0 and HasCompletedFastTravelNodePOI(nodeIndex) then
                return hid
            end
        end
    end
    return nil
end

local cachedRecallNode = nil

local function FindRecallNode()
    if not GetRecallCost then return nil end
    for nodeIndex = 1, GetNumFastTravelNodes() do
        local known, _, _, _, _, _, typePOI, _, isLocked = GetFastTravelNodeInfo(nodeIndex)
        if known and not isLocked and typePOI == POI_TYPE_WAYSHRINE then
            return nodeIndex
        end
    end
    return nil
end

local function GetStableRecallCost()
    if GetInteractionType and GetInteractionType() == INTERACTION_FAST_TRAVEL then
        return 0
    end
    if not GetRecallCost then return 0 end
    if not cachedRecallNode then
        cachedRecallNode = FindRecallNode()
    end
    return cachedRecallNode and (GetRecallCost(cachedRecallNode) or 0) or 0
end

local function FormatRecallCostAmount(cost)
    local canAfford = cost == 0 or cost <= GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
    local coloredNum = (canAfford and "|cFFFFFF" or "|cff4444") .. ZO_CommaDelimitNumber(cost) .. "|r"
    return zo_strformat(SI_GPH_MAPSEARCH_RECALL_COST_AMOUNT, coloredNum)
end

local function UpdateRecallCostLabel()
    if not recallCostLabel then return end
    recallCostLabel:SetText(FormatRecallCostAmount(GetStableRecallCost()))
end

local function StopListCostLoop()
    listCostLoopId = listCostLoopId + 1
end

local function StartListCostLoop()
    StopListCostLoop()
    local myId = listCostLoopId
    local function loop()
        if listCostLoopId ~= myId or not IsFragmentShowing() then return end
        UpdateRecallCostLabel()
        zo_callLater(loop, 1000)
    end
    zo_callLater(loop, 1000)
end


local CAT_NAMES = {
    [TYPE_WAYSHRINE]        = GetString(SI_GPH_MAPSEARCH_GROUP_WAYSHRINES),
    [TYPE_LIFT]             = GetString(SI_GPH_MAPSEARCH_GROUP_LIFTS),
    [TYPE_ZONE]             = GetString(SI_GPH_MAPSEARCH_GROUP_ZONES),
    [TYPE_POI]              = GetString(SI_GPH_MAPSEARCH_GROUP_LOCATIONS),
    [TYPE_HOUSE_OWNED]      = GetString(SI_GPH_MAPSEARCH_GROUP_OWNED_HOUSES),
    [TYPE_HOUSE_UNOWNED]    = GetString(SI_GPH_MAPSEARCH_GROUP_UNOWNED_HOUSES),
    [TYPE_CUSTOM]           = GetString(SI_GPH_MAPSEARCH_GROUP_CITY_LOCATIONS),
    [TYPE_NPC]              = GetString(SI_GPH_MAPSEARCH_GROUP_NPCS),
    [TYPE_TRADER]           = GetString(SI_GPH_MAPSEARCH_GROUP_GUILD_TRADERS),
    [TYPE_TRAVEL]           = GetString(SI_GPH_MAPSEARCH_GROUP_TRAVEL_SERVICES),
    [TYPE_CYRODIIL_KEEP]    = GetString(SI_GPH_MAPSEARCH_GROUP_CYRODIIL_KEEPS),
}

local function BuildListEntryData(c, displayName, isBookmarked, narrationBookmark)
    local entryData = ZO_GamepadEntryData:New(displayName or c.name, c.icon)
    entryData.candidate     = c
    local narrationBase = BuildCandidateNarrationText(c, narrationBookmark == true)
    local zoneMapText, zoneLeadText, zoneQuestText
    if c.type == TYPE_ZONE then
        zoneMapText   = GetZoneMapCountText(c.searchName)
        zoneLeadText  = GetZoneLeadCountText(c.zoneId)
        zoneQuestText = GetZoneQuestCountText(c.zoneId)
        if zoneMapText   then narrationBase = narrationBase .. ", " .. zoneMapText   end
        if zoneLeadText  then narrationBase = narrationBase .. ", " .. zoneLeadText  end
        if zoneQuestText then narrationBase = narrationBase .. ", " .. zoneQuestText end
    end
    local traderCount = GetTraderCountForCandidate(c)
    local ownedGuilds = (traderCount or c.isTrader) and GetOwnedGuildNamesForCandidate(c) or nil
    if traderCount then
        local traderText = traderCount .. " " .. GetString(traderCount == 1 and SI_GPH_MAPSEARCH_WAYSHRINE_TRADER or SI_GPH_MAPSEARCH_WAYSHRINE_TRADERS)
        narrationBase = narrationBase .. ", " .. traderText
    end
    if ownedGuilds then
        local n = #ownedGuilds
        narrationBase = narrationBase .. ", " .. n .. " " .. GetString(n == 1 and SI_GPH_MAPSEARCH_YOUR_GUILD_TRADER or SI_GPH_MAPSEARCH_YOUR_GUILD_TRADERS) .. ", " .. table.concat(ownedGuilds, ", ")
    end
    narrationBase = AddCraftingSetNarration(c, narrationBase)
    entryData.narrationText = narrationBase
    entryData:SetIconTintOnSelection(true)
    entryData:SetShowUnselectedSublabels(true)
    if isBookmarked then
        entryData.isBookmark = true
    end
    if c.isLocked then
        entryData:AddIcon("EsoUI/Art/Miscellaneous/status_locked.dds")
    end
    if IsServiceMapTarget(c) then
        local line1 = {}
        if c.zoneName and c.zoneName ~= "" then line1[#line1 + 1] = c.zoneName end
        if c.poiTypeLabel and c.poiTypeLabel ~= "" then line1[#line1 + 1] = c.poiTypeLabel end
        if #line1 > 0 then entryData:AddSubLabel(table.concat(line1, ", ")) end
        if c.cityName and c.cityName ~= "" then entryData:AddSubLabel(c.cityName) end
        if c.detailLabel and c.detailLabel ~= "" then
            entryData:AddSubLabel("|cFFD700" .. TruncateDetail(c.detailLabel, 60) .. "|r")
        end
    end
    if not IsServiceMapTarget(c) or c.setId then
        local sub = GetCandidateSubText(c)
        if not IsServiceMapTarget(c) and sub then entryData:AddSubLabel(sub) end
        local displayTraitCount = c.traitCount
        local displaySetName    = c.setName
        if c.setId and (not displayTraitCount or displayTraitCount == 0 or not displaySetName or displaySetName == "") then
            if not displayTraitCount or displayTraitCount == 0 then
                displayTraitCount = GetCraftingSetTraitCount(c.setId, c.zoneId, c.poiIndex)
            end
            if not displaySetName or displaySetName == "" then
                displaySetName = GetCraftingSetName(c.setId)
            end
        end
        if displayTraitCount and displayTraitCount > 0 then
            local traitStr = displayTraitCount .. " " .. GetString(displayTraitCount == 1 and SI_GPH_MAPSEARCH_CRAFTING_TRAIT or SI_GPH_MAPSEARCH_CRAFTING_TRAITS)
            entryData:AddSubLabel("|cFFD700" .. traitStr .. "|r")
        end
        if displaySetName and displaySetName ~= "" then
            entryData:AddSubLabel("|cFFD700" .. displaySetName .. "|r")
            if c.setId then
                entryData.gphSetId   = c.setId
                entryData.gphSetName = displaySetName
            end
        end
    end
    if c.type == TYPE_ZONE then
        if zoneMapText then entryData:AddSubLabel("|cFFD700" .. zoneMapText .. "|r") end
        if zoneLeadText then entryData:AddSubLabel("|cFFD700" .. zoneLeadText .. "|r") end
        if zoneQuestText then entryData:AddSubLabel("|cFFD700" .. zoneQuestText .. "|r") end
    end
    if c.type == TYPE_CYRODIIL_KEEP then
        if c.groupCount and c.groupCount > 0 then
            entryData:AddSubLabel("|cFFD700" .. c.groupCount .. " " .. GetString(SI_GPH_CYRODIIL_MEMBERS_NEARBY) .. "|r")
        end
        if c.isLeaderKeep then
            entryData:AddSubLabel("|c66FF99" .. GetString(SI_GPH_CYRODIIL_LEADER_NEARBY) .. "|r")
        end
    end
    if traderCount then
        local traderText = traderCount .. " " .. GetString(traderCount == 1 and SI_GPH_MAPSEARCH_WAYSHRINE_TRADER or SI_GPH_MAPSEARCH_WAYSHRINE_TRADERS)
        entryData:AddSubLabel("|cFFD700" .. traderText .. "|r")
    end
    if ownedGuilds then
        local n = #ownedGuilds
        local ownedText = n .. " " .. GetString(n == 1 and SI_GPH_MAPSEARCH_YOUR_GUILD_TRADER or SI_GPH_MAPSEARCH_YOUR_GUILD_TRADERS) .. ": " .. table.concat(ownedGuilds, ", ")
        entryData:AddSubLabel("|c66FF99" .. ownedText .. "|r")
    end
    return entryData
end

RebuildList = function()
    if not listObject then return end
    listObject:Clear()

    local bookmarks = GetBookmarksArray()
    local bookmarkedByKey = {}
    for _, bm in ipairs(bookmarks) do
        bookmarkedByKey[GetBookmarkKey(bm)] = true
    end

    if #results > 0 then
        local sv = GetSavedVars()
        local groupByLocation = sv and sv.mapSearchGroupByLocation == true

        local function GetDisplayName(c, isBookmarked)
            return isBookmarked
                and zo_iconTextFormat("EsoUI/Art/Collections/Favorite_StarOnly.dds", 24, 24, c.name)
                or c.name
        end

        local function AddCandidateEntry(c, header, isBookmarkList)
            local isBookmarked = bookmarkedByKey[GetBookmarkKey(c)] == true
            local displayName = GetDisplayName(c, isBookmarked and not isBookmarkList)
            local entryData = BuildListEntryData(c, displayName, isBookmarkList == true, isBookmarked)
            if header then
                entryData:SetHeader(header)
                listObject:AddEntryWithHeader("ZO_GamepadMenuEntryTemplateLowercase34", entryData)
            else
                listObject:AddEntry("ZO_GamepadMenuEntryTemplateLowercase34", entryData)
            end
        end

        if currentTab == TAB_BOOKMARKS or currentTab == TAB_RECENT then
            local headerText = GetString(MAP_SEARCH_TABS[currentTab].label)
            for i, c in ipairs(results) do
                AddCandidateEntry(c, i == 1 and headerText or nil, currentTab == TAB_BOOKMARKS)
            end
        elseif groupByLocation then

            local groupedByLocation = {}
            local locationOrder = {}
            for _, c in ipairs(results) do
                local key = (c.zoneName and c.zoneName ~= "") and c.zoneName or GetString(SI_GPH_MAPSEARCH_GROUP_OTHER)
                if not groupedByLocation[key] then
                    groupedByLocation[key] = {}
                    locationOrder[#locationOrder + 1] = key
                end
                groupedByLocation[key][#groupedByLocation[key] + 1] = c
            end

            for _, location in ipairs(locationOrder) do
                local bucket = groupedByLocation[location]
                local firstInLocation = true
                for _, c in ipairs(bucket) do
                    AddCandidateEntry(c, firstInLocation and location or nil, false)
                    firstInLocation = false
                end
            end
        else
            local grouped = {}
            for _, c in ipairs(results) do
                if not grouped[c.type] then grouped[c.type] = {} end
                grouped[c.type][#grouped[c.type] + 1] = c
            end
            local typeOrder = {
                TYPE_CYRODIIL_KEEP,
                TYPE_WAYSHRINE,
                TYPE_LIFT,
                TYPE_ZONE,
                TYPE_NPC,
                TYPE_TRADER,
                TYPE_TRAVEL,
                TYPE_POI,
                TYPE_CUSTOM,
                TYPE_HOUSE_OWNED,
                TYPE_HOUSE_UNOWNED,
            }
            for _, t in ipairs(typeOrder) do
                local bucket = grouped[t]
                if bucket and #bucket > 0 then
                    local firstInType = true
                    for _, c in ipairs(bucket) do
                        AddCandidateEntry(c, firstInType and (CAT_NAMES[c.type] or GetString(SI_GPH_MAPSEARCH_GROUP_OTHER)) or nil, false)
                        firstInType = false
                    end
                end
            end
        end
    end

    listObject:Commit()

    local numItems = listObject:GetNumItems()
    if numItems > 0 then
        lastSelectedIndex = zo_clamp(lastSelectedIndex, 1, numItems)
        listObject:SetSelectedIndex(lastSelectedIndex)
    end

    UpdateKeybinds()
end

-- map interaction

local postTeleportDestination = nil
local postTeleportCandidate   = nil

local function GetResolvedZoneIndex(c)
    if not c or not c.zoneId or c.zoneId <= 0 then return nil end
    local zoneIndex = GetZoneIndex and GetZoneIndex(c.zoneId)
    return (zoneIndex and zoneIndex > 0) and zoneIndex or nil
end

local function AddMapPin(x, y)
    local sv = GetSavedVars()
    if sv ~= nil and sv.mapSearchMapPin == false then return end
    local pinMgr = ZO_WorldMap_GetPinManager and ZO_WorldMap_GetPinManager()
    if not pinMgr then return end
    pinMgr:RemovePins("pings")
    pinMgr:CreatePin(MAP_PIN_TYPE_AUTO_MAP_NAVIGATION_PING, "pings", x, y)
end


local function PlaceDestinationDiamondPre(c)
    local sv = GetSavedVars()
    if sv ~= nil and sv.mapSearchSetDestination == false then return end
    local x, y
    local zoneIndex = GetResolvedZoneIndex(c)
    if c.type == TYPE_CYRODIIL_KEEP then
        if c.isLeaderKeep and c.leaderNormX and c.leaderNormY then
            x, y = c.leaderNormX, c.leaderNormY
        elseif c.normX and c.normY then
            x, y = c.normX, c.normY
        end
    elseif c.destinationX and c.destinationY then
        x, y = c.destinationX, c.destinationY
    elseif zoneIndex and c.poiIndex then
        x, y = GetPOIMapInfo(zoneIndex, c.poiIndex)
    elseif c.nodeIndex then
        local _, _, nx, ny = GetFastTravelNodeInfo(c.nodeIndex)
        x, y = nx, ny
    end
    if not x or x <= 0 or not y or y <= 0 then return end
    if ZO_WorldMap_RemovePlayerWaypoint then
        ZO_WorldMap_RemovePlayerWaypoint()
    elseif RemovePlayerWaypoint then
        RemovePlayerWaypoint()
    end
    PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, x, y)
end

local function StorePostTeleportDestination(c)
    local sv = GetSavedVars()
    if sv ~= nil and sv.mapSearchSetDestination == false then return end
    if c.type == TYPE_CYRODIIL_KEEP then
        local cyrodiilMapId = GetCurrentMapId and GetCurrentMapId()
        if c.isLeaderKeep and c.leaderNormX and c.leaderNormY then
            postTeleportDestination = { x = c.leaderNormX, y = c.leaderNormY, mapId = cyrodiilMapId }
        elseif c.normX and c.normY then
            postTeleportDestination = { x = c.normX, y = c.normY, mapId = cyrodiilMapId }
        end
        return
    end
    local mapId = c.cityMapId
        or (c.zoneId and GetMapIdByZoneId and GetMapIdByZoneId(c.zoneId) or nil)
    local zoneIndex = GetResolvedZoneIndex(c)
    if c.destinationX and c.destinationY then
        postTeleportDestination = { x = c.destinationX, y = c.destinationY, mapId = mapId }
        return
    end
    if zoneIndex and c.poiIndex then
        local nx, ny = GetPOIMapInfo(zoneIndex, c.poiIndex)
        if nx and nx > 0 then
            postTeleportDestination = { x = nx, y = ny, mapId = mapId }
            return
        end
    end
    if c.nodeIndex then
        local _, _, nx, ny = GetFastTravelNodeInfo(c.nodeIndex)
        if nx and nx > 0 then
            postTeleportDestination = { x = nx, y = ny, mapId = mapId }
        end
    end
end

local function CenterMapOnCandidate(c)
    if not c then return end

    local zoneId       = c.zoneId
    local zoneIndex    = GetResolvedZoneIndex(c)
    local mapId        = c.cityMapId or (zoneId and GetMapIdByZoneId(zoneId))
    local currentMapId = GetCurrentMapId and GetCurrentMapId()

    local function doPan()
        if c.icon and c.icon:find("poi_city") then
            ZO_WorldMap_PanToNormalizedPosition(0.5, 0.5)
            return
        end
        if c.destinationX and c.destinationY then
            ZO_WorldMap_PanToNormalizedPosition(c.destinationX, c.destinationY)
            AddMapPin(c.destinationX, c.destinationY)
            return
        end
        if IsServiceMapTarget(c) and c.nodeIndex then
            local _, _, nx, ny = GetFastTravelNodeInfo(c.nodeIndex)
            if nx and nx > 0 then
                AddMapPin(nx, ny)
            end
            ZO_WorldMap_PanToWayshrine(c.nodeIndex)
            return
        end
        if zoneIndex and c.poiIndex then
            local nx, ny = GetPOIMapInfo(zoneIndex, c.poiIndex)
            if nx and nx > 0 then
                ZO_WorldMap_PanToNormalizedPosition(nx, ny)
                AddMapPin(nx, ny)
                return
            end
        end
        if c.type == TYPE_WAYSHRINE and c.nodeIndex then
            local _, _, nx, ny = GetFastTravelNodeInfo(c.nodeIndex)
            if nx and nx > 0 then
                AddMapPin(nx, ny)
            end
            ZO_WorldMap_PanToWayshrine(c.nodeIndex)
        end
        if c.type == TYPE_CYRODIIL_KEEP and c.normX and c.normY then
            ZO_WorldMap_PanToNormalizedPosition(c.normX, c.normY)
            if c.isLeaderKeep and c.leaderNormX and c.leaderNormY then
                AddMapPin(c.leaderNormX, c.leaderNormY)
            else
                AddMapPin(c.normX, c.normY)
            end
        end
    end

    if mapId and mapId > 0 and mapId ~= currentMapId then
        WORLD_MAP_MANAGER:SetMapById(mapId)
        zo_callLater(doPan, 100)
    else
        doPan()
    end
end

local pendingWaypointDest = nil

local function ApplyWaypointNow(dest)
    if not dest or not dest.x or not dest.y then return end
    if dest.mapId and dest.mapId > 0 then
        if WORLD_MAP_MANAGER and WORLD_MAP_MANAGER.SetMapById then
            WORLD_MAP_MANAGER:SetMapById(dest.mapId)
        end
    end
    if ZO_WorldMap_IsNormalizedPointInsideMapBounds and not ZO_WorldMap_IsNormalizedPointInsideMapBounds(dest.x, dest.y) then
        return
    end
    if ZO_WorldMap_RemovePlayerWaypoint then
        ZO_WorldMap_RemovePlayerWaypoint()
    elseif RemovePlayerWaypoint then
        RemovePlayerWaypoint()
    end
    PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, dest.x, dest.y)
    if WORLD_MAP_MANAGER and WORLD_MAP_MANAGER.RefreshMapPings then
        WORLD_MAP_MANAGER:RefreshMapPings()
    end
    AddMapPin(dest.x, dest.y)
end

local function PlacePostTeleportDestination(dest)
    if not dest or not dest.x or not dest.y then return end
    local mapScene = IsInGamepadPreferredMode() and GAMEPAD_WORLD_MAP_SCENE or WORLD_MAP_SCENE
    if mapScene and mapScene:IsShowing() then
        ApplyWaypointNow(dest)
        pendingWaypointDest = nil
    else
        pendingWaypointDest = dest
    end
end

-- keybinds

local function BuildKeybindDescriptor()
    keybindDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind  = "UI_SHORTCUT_PRIMARY",
            name     = function()
                if editControl and editControl:HasFocus() then return GetString(SI_GPH_MAPSEARCH_KEYBIND_DONE) end
                local td = listObject and listObject:GetTargetData()
                return (td and td.candidate) and GetString(SI_GPH_MAPSEARCH_KEYBIND_SHOW_ON_MAP) or GetString(SI_GPH_MAPSEARCH_KEYBIND_DONE)
            end,
            callback = function()
                if editControl and editControl:HasFocus() then
                    editControl:LoseFocus()
                    if listObject and IsFragmentShowing() then
                        listObject:SetSelectedIndex(1)
                        listObject:Activate()
                    end
                    return
                end
                local td = listObject and listObject:GetTargetData()
                if td and td.candidate then
                    local sv = GetSavedVars()
                    if sv then sv.lastSelectedPOI = MakeSavedCandidate(td.candidate) end
                    CenterMapOnCandidate(td.candidate)
                    local keybindName = ZO_Keybindings_GetBindingStringFromAction("UI_SHORTCUT_QUINARY") or GetString(SI_GPH_TELEPORT)
                    pendingNarration = BuildCandidateNarrationText(td.candidate, td.isBookmark) .. ". " .. zo_strformat(SI_GPH_MAPSEARCH_SHOWN_ON_MAP, keybindName)
                    SCREEN_NARRATION_MANAGER:QueueCustomEntry("GPH_MapSearch_Narration")
                end
            end,
            visible  = function()
                if editControl and editControl:HasFocus() then return true end
                local td = listObject and listObject:GetTargetData()
                return td ~= nil and td.candidate ~= nil
            end,
        },
        {
            keybind  = "UI_SHORTCUT_LEFT_TRIGGER",
            name     = function()
                local i = currentTab - 1
                if i < 1 then i = #MAP_SEARCH_TABS end
                return GetString(MAP_SEARCH_TABS[i].label)
            end,
            callback = function()
                if editControl and editControl:HasFocus() then editControl:LoseFocus() end
                SwitchTab(-1)
            end,
            visible  = function() return IsFragmentShowing() end,
        },
        {
            keybind  = "UI_SHORTCUT_RIGHT_TRIGGER",
            name     = function()
                local i = currentTab + 1
                if i > #MAP_SEARCH_TABS then i = 1 end
                return GetString(MAP_SEARCH_TABS[i].label)
            end,
            callback = function()
                if editControl and editControl:HasFocus() then editControl:LoseFocus() end
                SwitchTab(1)
            end,
            visible  = function() return IsFragmentShowing() end,
        },
        {
            -- In text mode: X = Clear (clears text, stays in search box)
            -- In list mode: X = Search (opens text mode)
            keybind  = "UI_SHORTCUT_SECONDARY",
            name     = function()
                return (editControl and editControl:HasFocus()) and GetString(SI_GPH_MAPSEARCH_CLEAR) or GetString(SI_SCREEN_NARRATION_EDIT_BOX_SEARCH_NAME)
            end,
            callback = function()
                if currentTab ~= TAB_SEARCH then return end
                if editControl and editControl:HasFocus() then
                    currentTerm = ""
                    editControl:SetText("")
                    lastSearchTerm = nil
                    RunSearch(currentTerm)
                    RebuildList()
                    pendingNarration = GetString(SI_GPH_MAPSEARCH_SEARCH_CLEARED)
                    SCREEN_NARRATION_MANAGER:QueueCustomEntry("GPH_MapSearch_Narration")
                else
                    if editControl then editControl:TakeFocus() end
                end
            end,
            visible  = function() return IsFragmentShowing() and currentTab == TAB_SEARCH end,
        },
        {
            keybind  = "UI_SHORTCUT_QUATERNARY",
            name     = function()
                local td = listObject and listObject:GetTargetData()
                if td and td.candidate then
                    return IsBookmarked(td.candidate) and GetString(SI_GPH_MAPSEARCH_UNBOOKMARK) or GetString(SI_GPH_MAPSEARCH_BOOKMARK)
                end
                return GetString(SI_GPH_MAPSEARCH_BOOKMARK)
            end,
            callback = function()
                local td = listObject and listObject:GetTargetData()
                if not td or not td.candidate then return end
                local c = td.candidate
                local idx = listObject:GetSelectedIndex()
                if IsBookmarked(c) then
                    ZO_Dialogs_ShowGamepadDialog("GPH_UNBOOKMARK_CONFIRM", c)
                else
                    AddBookmark(c)
                    pendingNarration = zo_strformat(SI_GPH_MAPSEARCH_BOOKMARKED, c.name)
                    SCREEN_NARRATION_MANAGER:QueueCustomEntry("GPH_MapSearch_Narration")
                    RunSearch(currentTerm)
                    RebuildList()
                    if idx and idx > 0 and listObject:GetNumItems() > 0 then
                        listObject:SetSelectedIndex(zo_clamp(idx, 1, listObject:GetNumItems()))
                    end
                end
            end,
            visible  = function()
                if editControl and editControl:HasFocus() then return false end
                local td = listObject and listObject:GetTargetData()
                return td ~= nil and td.candidate ~= nil
            end,
        },
        {
            keybind  = "UI_SHORTCUT_QUINARY",
            name     = function()
                local td = listObject and listObject:GetTargetData()
                if td and td.candidate then
                    local c = td.candidate
                    if (c.type == TYPE_WAYSHRINE and c.known and not c.isLocked)
                    or c.type == TYPE_HOUSE_OWNED
                    or c.type == TYPE_CYRODIIL_KEEP then
                        return GetString(SI_GPH_TELEPORT)
                    end
                end
                return GetString(SI_GPH_MAPSEARCH_TELEPORT_NEAREST)
            end,
            enabled  = function()
                local td = listObject and listObject:GetTargetData()
                if td and td.candidate then
                    local c = td.candidate
                    -- Keep enabled for wayshrines locked by DLC/chapter so pressing opens the shop
                    if c.isLocked and not c.nodeIndex then return false end
                end
                return true
            end,
            visible  = function()
                if editControl and editControl:HasFocus() then return false end
                local td = listObject and listObject:GetTargetData()
                return td ~= nil and td.candidate ~= nil
            end,
            callback = function()
                local td = listObject and listObject:GetTargetData()
                if not td or not td.candidate then return end
                local c = td.candidate
                local sv = GetSavedVars()
                if sv then sv.lastSelectedPOI = MakeSavedCandidate(c) end

                if c.isLocked then
                    local collectibleData
                    if c.nodeIndex then
                        local collectibleId = GetFastTravelNodeLinkedCollectibleId(c.nodeIndex)
                        collectibleData     = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
                    end
                    if collectibleData then
                        ZO_Dialogs_ShowCollectibleRequirementFailedPlatformDialog(collectibleData, c.name, MARKET_OPEN_OPERATION_DLC_FAILURE_TELEPORT_TO_ZONE)
                    else
                        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_GPH_MAPSEARCH_ZONE_LOCKED))
                    end
                    return
                end

                if c.type == TYPE_HOUSE_OWNED then
                    local houseId = ResolveOwnedHouseId(c)
                    if houseId then c.houseId = houseId end
                    if not CanJumpToHouseFromCurrentLocation() then
                        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_GPH_MAPSEARCH_NO_HOUSE_TRAVEL))
                        return
                    end
                    if not c.houseId then
                        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_GPH_MAPSEARCH_NO_HOUSE_TRAVEL))
                        return
                    end
                    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_TRAVEL_TO_HOUSE_OPTIONS_DIALOG", { GetReferenceId = function() return c.houseId end })
                    return
                end

                if c.type == TYPE_CYRODIIL_KEEP then
                    if WORLD_MAP_MANAGER and WORLD_MAP_MANAGER:IsInMode(MAP_MODE_KEEP_TRAVEL) then
                        for i = 1, GetGroupSize() do
                            local tag = GetGroupUnitTagByIndex(i)
                            if tag and DoesUnitExist(tag) and IsUnitOnline(tag) and IsUnitGroupLeader(tag) then
                                local lx, ly, _, isInMap = GetMapPlayerPosition(tag)
                                if isInMap then
                                    c.leaderNormX, c.leaderNormY = lx, ly
                                    c.isLeaderKeep = true
                                end
                                break
                            end
                        end
                        StorePostTeleportDestination(c)
                        TravelToKeep(c.keepId)
                    else
                        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_GPH_CYRODIIL_TRAVEL_REQUIRES_SHRINE))
                    end
                    return
                end

                local nodeIndex, failReason = nil, nil
                if c.type == TYPE_WAYSHRINE and c.known then
                    nodeIndex = c.nodeIndex
                elseif c.type == TYPE_ZONE and c.zoneId then
                    nodeIndex = FindBestDiscoveredWayshrineFromScan(c)
                    if not nodeIndex then failReason = GetString(SI_GPH_MAPSEARCH_NARRATION_UNDISCOVERED) end
                elseif IsServiceMapTarget(c) then
                    nodeIndex = c.nodeIndex
                    if not nodeIndex then
                        nodeIndex = FindBestDiscoveredWayshrineFromScan(c)
                    end
                    if not nodeIndex then failReason = GetString(SI_GPH_MAPSEARCH_NARRATION_UNDISCOVERED) end
                elseif c.poiIndex then
                    local zoneIndex = GetResolvedZoneIndex(c)
                    local nx, ny = zoneIndex and GetPOIMapInfo(zoneIndex, c.poiIndex)
                    if nx and ny then
                        nodeIndex = FindNearestWayshrineToPos(nx, ny, 0, zoneIndex)
                    end
                    if not nodeIndex then failReason = GetString(SI_GPH_MAPSEARCH_NARRATION_UNDISCOVERED) end
                elseif c.nodeIndex then
                    nodeIndex = c.nodeIndex
                end

                if not nodeIndex then
                    local msg = failReason == GetString(SI_GPH_MAPSEARCH_NARRATION_LOCKED)
                        and GetString(SI_GPH_MAPSEARCH_ZONE_LOCKED)
                        or  GetString(SI_GPH_MAPSEARCH_NO_DISCOVERED_WAYSHRINE)
                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, msg)
                    return
                end

                local atWayshrine = GetInteractionType() == INTERACTION_FAST_TRAVEL
                local cost = (not atWayshrine) and GetRecallCost(nodeIndex) or 0
                CenterMapOnCandidate(c)
                PlaceDestinationDiamondPre(c)
                StorePostTeleportDestination(c)
                postTeleportCandidate = c
                if cost > 0 then
                    local tryFree = _G["GamePadHelper_MapTeleporter_TryFreeTeleport"]
                    local handled = tryFree and c.zoneId and tryFree({
                        zoneId    = c.zoneId,
                        name      = c.name,
                        nodeIndex = nodeIndex,
                        cost      = cost,
                        onWayshrine = function()
                            local sv = GetSavedVars()
                            if sv == nil or sv.mapSearchNarratePostTeleport ~= false then
                                postTeleportMsg = zo_strformat(SI_GPH_MAPSEARCH_TELEPORTED_TO, c.name)
                            end
                            PlaceDestinationDiamondPre(c)
                            FastTravelToNode(nodeIndex)
                            SCENE_MANAGER:ShowBaseScene()
                        end,
                    })
                    if not handled then
                        ZO_Dialogs_ShowGamepadDialog("GPH_TELEPORT_CONFIRM", {
                            nodeIndex = nodeIndex,
                            candidate = c,
                            name      = c.name,
                            cost      = cost,
                        })
                    end
                else
                    local sv = GetSavedVars()
                    if sv == nil or sv.mapSearchNarratePostTeleport ~= false then
                        postTeleportMsg = zo_strformat(SI_GPH_MAPSEARCH_TELEPORTED_TO, c.name)
                    end
                    FastTravelToNode(nodeIndex)
                    ZO_WorldMap_HideWorldMap()
                end
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(keybindDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        if editControl and editControl:HasFocus() then
            editControl:LoseFocus()
        elseif GAMEPAD_WORLD_MAP_INFO then
            GAMEPAD_WORLD_MAP_INFO:Hide()
        end
    end)

end

-- XML callbacks

function GPH_MapSearch_OnShown(edit)
    editControl = edit
    edit:SetDefaultText(GetString(SI_GPH_MAPSEARCH_SEARCH_HINT))
    UpdateSearchBarVisibility()
    RunSearch(currentTerm)
    RebuildList()
    UpdateRecallCostLabel()
end

function GPH_MapSearch_OnTextChanged(text)
    if not IsFragmentShowing() or currentTab ~= TAB_SEARCH then return end
    currentTerm = text or ""
    RunSearch(currentTerm)
    RebuildList()
end

function GPH_MapSearch_OnSearchFocused(focused)
    if currentTab ~= TAB_SEARCH then
        if editControl and editControl:HasFocus() then editControl:LoseFocus() end
        return
    end
    if searchBarBG then searchBarBG:SetHidden(not focused) end
    if listObject then
        if focused then
            listObject:Deactivate()
        elseif IsFragmentShowing() then
            listObject:Activate()
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("GPH_MapSearch_Narration")
        end
    end
    UpdateKeybinds()
    if focused then
        currentTerm = (editControl and editControl:GetText()) or currentTerm or ""
        local label = currentTerm ~= "" and (zo_strformat(SI_GPH_MAPSEARCH_SEARCHING_FOR, currentTerm)) or GetString(SI_GPH_MAPSEARCH_SEARCH_READY)
        pendingNarration = label .. ". " .. GetString(SI_GPH_MAPSEARCH_FILTER_HINT)
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("GPH_MapSearch_Narration")
    end
end

function GPH_MapSearch_SelectCurrent()
    if not IsFragmentShowing() then return end
    if editControl and editControl:HasFocus() then editControl:LoseFocus() end
    local td = listObject and listObject:GetTargetData()
    if td and td.candidate then
        local sv = GetSavedVars()
        if sv then sv.lastSelectedPOI = MakeSavedCandidate(td.candidate) end
        CenterMapOnCandidate(td.candidate)
    end
end

-- UI init

local function InitList(control)
    local listCtrl = control:GetNamedChild("Main"):GetNamedChild("List")
    listObject = ZO_GamepadVerticalParametricScrollList:New(listCtrl)
    listObject:SetAlignToScreenCenter(true)

    local function GPHEntrySetup(control, data, selected, ...)
        local c = data.candidate
        if c and c.detailLabel and c.detailLabel ~= "" and data.subLabels then
            local full  = "|cFFD700" .. c.detailLabel .. "|r"
            local trunc = "|cFFD700" .. TruncateDetail(c.detailLabel, 60) .. "|r"
            for i = 1, #data.subLabels do
                if data.subLabels[i] == full or data.subLabels[i] == trunc then
                    data.subLabels[i] = selected and full or trunc
                    break
                end
            end
        end
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, ...)
    end

    listObject:AddDataTemplate(
        "ZO_GamepadMenuEntryTemplateLowercase34",
        GPHEntrySetup,
        ZO_GamepadMenuEntryTemplateParametricListFunction)
    listObject:AddDataTemplateWithHeader(
        "ZO_GamepadMenuEntryTemplateLowercase34",
        GPHEntrySetup,
        ZO_GamepadMenuEntryTemplateParametricListFunction,
        nil, "ZO_GamepadMenuEntryHeaderTemplate")

    local function DetailTooltip()
        local td = listObject and listObject:GetTargetData()
        if td and td.gphSetId then
            local hasSet, _, numBonuses = GetItemSetInfo(td.gphSetId)
            if hasSet and numBonuses and numBonuses > 0 then
                local lines = {}
                for i = 1, numBonuses do
                    local numRequired, desc, isPerfected = GetItemSetBonusInfo(td.gphSetId, i)
                    if not isPerfected and desc and desc ~= "" then
                        lines[#lines + 1] = desc
                    end
                end
                if #lines > 0 then
                    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(
                        GAMEPAD_MOVABLE_TOOLTIP,
                        "|cDAA520" .. td.gphSetName .. "|r",
                        table.concat(lines, "\n"))
                    return
                end
            end
        end
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_MOVABLE_TOOLTIP)
    end

    listObject:SetOnTargetDataChangedCallback(function()
        local idx = listObject:GetSelectedIndex()
        if idx and idx > 0 then lastSelectedIndex = idx end
        UpdateKeybinds()
        if not (editControl and editControl:HasFocus()) then
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("GPH_MapSearch_Narration")
        end
        local td = listObject:GetTargetData()
        if not (td and td.candidate) then
            ZO_WorldMap_HideAllTooltips()
        end
        DetailTooltip()
        listObject:RefreshVisible()
    end)
end

local function FocusSearchEditSoon()
    zo_callLater(function()
        if not IsFragmentShowing() then return end
        if currentTab ~= TAB_SEARCH then
            currentTab = TAB_SEARCH
            UpdateSearchBarVisibility()
            UpdateTabLabels()
            RunSearch(currentTerm)
            RebuildList()
        end
        if editControl then
            currentTerm = editControl:GetText() or currentTerm or ""
            if searchBarBG then searchBarBG:SetHidden(false) end
            if listObject and IsFragmentShowing() then
                listObject:Activate()
            end
        end
    end, 100)
end

local function SwitchToSearchTabIfNeeded()
    local sv = GetSavedVars()
    if not (wasOnGPHSearch or (sv and sv.mapSearchOpenOnSearch)) then return end
    local mapInfo = GAMEPAD_WORLD_MAP_INFO
    if not (mapInfo and GPH_SEARCH_FRAGMENT) then return end
    if mapInfo.Show then
        mapInfo:Show()
    end
    currentTab = TAB_SEARCH
    UpdateSearchBarVisibility()
    UpdateTabLabels()
    mapInfo:SwitchToFragment(GPH_SEARCH_FRAGMENT, false)
    if gphSearchTabIndex and mapInfo.header then
        ZO_GamepadGenericHeader_SetActiveTabIndex(mapInfo.header, gphSearchTabIndex)
    end
    if sv and sv.mapSearchAutoFocusSearch then
        FocusSearchEditSoon()
    end
end

local function InsertMapSearchTab()
    if GPH_SEARCH_TAB_INSERTED then
        SwitchToSearchTabIfNeeded()
        return
    end
    local sv = GetSavedVars()
    if sv ~= nil and sv.mapSearchEnabled == false then return end

    local mapInfo = GAMEPAD_WORLD_MAP_INFO
    if not mapInfo or not mapInfo.tabBarEntries or not mapInfo.header then return end

    local control = GPH_MapSearch_Gamepad
    if not control then return end

    InitList(control)

    local mainControl = control:GetNamedChild("Main")
    searchBarControl  = mainControl:GetNamedChild("SearchBar")
    searchBarBG       = searchBarControl:GetNamedChild("BG")
    tabsControl       = mainControl:GetNamedChild("Tabs")
    tabTitleControl   = mainControl:GetNamedChild("TabTitle")
    tabControls.previous = tabsControl and tabsControl:GetNamedChild("Previous") or nil
    tabControls.selected = tabsControl and tabsControl:GetNamedChild("Selected") or nil
    tabControls.next     = tabsControl and tabsControl:GetNamedChild("Next") or nil
    UpdateTabLabels()
    recallRowControl = mainControl:GetNamedChild("RecallRow")
    UpdateSearchBarVisibility()
    local recallTitle = recallRowControl and recallRowControl:GetNamedChild("RecallCostTitle") or nil
    if recallTitle then recallTitle:SetText(GetString(SI_GPH_MAPSEARCH_RECALL_COST)) end
    recallCostLabel = recallRowControl and recallRowControl:GetNamedChild("RecallCostValue") or nil
    UpdateRecallCostLabel()

    BuildKeybindDescriptor()

    GPH_SEARCH_FRAGMENT = ZO_SimpleSceneFragment:New(control)

    SCREEN_NARRATION_MANAGER:RegisterCustomObject("GPH_MapSearch_Narration", {
        narrationType = NARRATION_TYPE_UI_INTERACTIONS,
        canNarrate    = function() return IsFragmentShowing() end,
        selectedNarrationFunction = function()
            local narrations = {}
            if pendingNarration then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(pendingNarration))
                pendingNarration = nil
                local td = listObject and listObject:GetTargetData()
                local entryText = td and (td.narrationText or (td.candidate and BuildCandidateNarrationText(td.candidate, td.isBookmark)))
                if entryText then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryText))
                end
                return narrations
            end
            local td = listObject and listObject:GetTargetData()
            local text = td and (td.narrationText or (td.candidate and BuildCandidateNarrationText(td.candidate, td.isBookmark)))
            if not text then
                text = currentTerm ~= "" and (zo_strformat(SI_GPH_MAPSEARCH_SEARCHING_FOR, currentTerm)) or GetString(SI_GPH_MAPSEARCH_SEARCH_LOCATIONS)
            end
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(text))
            return narrations
        end,
    })

    GPH_SEARCH_FRAGMENT:RegisterCallback("StateChange", function(_, newState)
        if newState == SCENE_SHOWING then
            if _G["GamePadHelper_MapTeleporter_SetSuppressed"] then
                _G["GamePadHelper_MapTeleporter_SetSuppressed"](true)
            end
            candidates = nil  -- rebuild keep group counts fresh each time the list opens
            if IsCyrodiilKeepSearchEnabled() and GetMapContentType and GetMapContentType() == MAP_CONTENT_AVA then
                for i = 1, GetGroupSize() do
                    local tag = GetGroupUnitTagByIndex(i)
                    if tag and DoesUnitExist(tag) and IsUnitOnline(tag) and IsUnitGroupLeader(tag) then
                        local lx, ly, _, isInMap = GetMapPlayerPosition(tag)
                        if isInMap then AddMapPin(lx, ly) end
                        break
                    end
                end
            end
            RunSearch(currentTerm)
            if not zoneMapCounts   then BuildZoneMapCounts()   end
            if not zoneLeadCounts  then BuildZoneLeadCounts()  end
            if not zoneQuestCounts then BuildZoneQuestCounts() end
            RebuildList()
            UpdateRecallCostLabel()
            StartListCostLoop()
            if listObject then
                listObject:Activate()
                local numItems = listObject:GetNumItems()
                if numItems > 0 then
                    listObject:SetSelectedIndex(zo_clamp(lastSelectedIndex, 1, numItems))
                end
                listObject:RefreshVisible()
            end
            KEYBIND_STRIP:AddKeybindButtonGroup(keybindDescriptor)
            UpdateKeybinds()
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("GPH_MapSearch_Narration")
            local sv = GetSavedVars()
            if sv and sv.mapSearchAutoFocusSearch and currentTab == TAB_SEARCH then
                if searchBarBG then searchBarBG:SetHidden(false) end
                local hint = currentTerm ~= "" and zo_strformat(SI_GPH_MAPSEARCH_SEARCHING_FOR, currentTerm) or GetString(SI_GPH_MAPSEARCH_SEARCH_HINT)
                pendingNarration = hint .. ". " .. GetString(SI_GPH_MAPSEARCH_FILTER_HINT)
                FocusSearchEditSoon()
            end
        elseif newState == SCENE_HIDING or newState == SCENE_HIDDEN then
            if listObject then
                local idx = listObject:GetSelectedIndex()
                if idx and idx > 0 then lastSelectedIndex = idx end
                listObject:Deactivate()
            end
            KEYBIND_STRIP:RemoveKeybindButtonGroup(keybindDescriptor)
            if editControl then editControl:LoseFocus() end
            pendingNarration = nil
            StopListCostLoop()
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_MOVABLE_TOOLTIP)
            if _G["GamePadHelper_MapTeleporter_SetSuppressed"] then
                _G["GamePadHelper_MapTeleporter_SetSuppressed"](false)
            end
        end
    end)

    local bmuActive = BMU ~= nil
                   and BMU_savedVarsAcc ~= nil
                   and BMU_savedVarsAcc.ShowOnMapOpen == true
    local tabIndex = bmuActive and 2 or 1
    table.insert(mapInfo.tabBarEntries, tabIndex, {
        text     = GetString(SI_GPH_MAPSEARCH_TAB),
        callback = function()
            mapInfo:SwitchToFragment(GPH_SEARCH_FRAGMENT, false)
        end,
    })

    gphSearchTabIndex = tabIndex
    ZO_GamepadGenericHeader_Refresh(mapInfo.header, mapInfo.baseHeaderData)
    GPH_SEARCH_TAB_INSERTED = true
    SwitchToSearchTabIfNeeded()
end

local function SanitizeSavedMapSearchCandidate(c)
    if type(c) ~= "table" then return end
    c.searchName = c.name and c.name:lower() or ""
    c.zoneIndex  = nil
    if IsServiceMapTarget(c) and not c.placeName then
        c.narrationLabel = nil
        c.poiTypeLabel = nil
    end
end

local function SanitizeSavedMapSearchData()
    local sv = _G["GamePadHelper_CharSavedVars"]
    local acctSv = _G["GamePadHelper_SavedVars"]
    if sv then
        if type(sv.mapSearchRecent) == "table" then
            for _, c in ipairs(sv.mapSearchRecent) do
                SanitizeSavedMapSearchCandidate(c)
            end
        end
        if type(sv.lastSelectedPOI) == "table" then
            SanitizeSavedMapSearchCandidate(sv.lastSelectedPOI)
        end
        if type(sv.mapSearchBookmarks) == "table" then
            for _, c in ipairs(sv.mapSearchBookmarks) do
                SanitizeSavedMapSearchCandidate(c)
            end
        end
    end
    if acctSv and type(acctSv.mapSearchBookmarksAll) == "table" then
        for _, c in ipairs(acctSv.mapSearchBookmarksAll) do
            SanitizeSavedMapSearchCandidate(c)
        end
    end
end

-- addon loaded

local function OnAddonLoaded(_, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("MapSearch", EVENT_ADD_ON_LOADED)
    SanitizeSavedMapSearchData()
    LoadCityScanFromSavedVars()

    EVENT_MANAGER:RegisterForEvent("MapSearch_PreScan", EVENT_PLAYER_ACTIVATED, function()
        EVENT_MANAGER:UnregisterForEvent("MapSearch_PreScan", EVENT_PLAYER_ACTIVATED)
        if not scannedData then PreScan() end
        -- Start the city-services cache build in the background if no valid cache
        -- was loaded from disk, so the first search doesn't trigger a sync freeze.
        if not IsCityCacheReady() then
            StartCityScanPrewarm(nil)
        end
    end)

    EVENT_MANAGER:RegisterForEvent("MapSearch_RecallNodeReset", EVENT_PLAYER_ACTIVATED, function()
        cachedRecallNode = nil
        traderGuildMap   = nil
    end)
    EVENT_MANAGER:RegisterForEvent("MapSearch_InventoryChanged", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function()
        zoneMapCounts = nil
    end)
    EVENT_MANAGER:RegisterForEvent("MapSearch_AntiquityUpdated", EVENT_ANTIQUITY_UPDATED, function()
        zoneLeadCounts = nil
    end)
    EVENT_MANAGER:RegisterForEvent("MapSearch_QuestUpdated", EVENT_QUEST_ADDED, function()
        zoneQuestCounts = nil
    end)
    EVENT_MANAGER:RegisterForEvent("MapSearch_QuestRemoved", EVENT_QUEST_REMOVED, function()
        zoneQuestCounts = nil
    end)
    EVENT_MANAGER:RegisterForEvent("MapSearch_POIUpdated", EVENT_POI_UPDATED, function()
        cachedRecallNode = nil
    end)
    EVENT_MANAGER:RegisterForEvent("MapSearch_KeepNetworkUpdated", EVENT_FAST_TRAVEL_KEEP_NETWORK_UPDATED, function()
        candidates = nil
    end)

    -- Auto-capture crafting set trait data when player visits a crafting station
    local SMITHING_TYPES = {
        [CRAFTING_TYPE_BLACKSMITHING] = true,
        [CRAFTING_TYPE_CLOTHIER]      = true,
        [CRAFTING_TYPE_WOODWORKING]   = true,
    }
    EVENT_MANAGER:RegisterForEvent("MapSearch_CraftingStation", EVENT_CRAFTING_STATION_INTERACT, function(_, craftingType)
        if not SMITHING_TYPES[craftingType] then return end
        zo_callLater(function()
            local numPatterns = GetNumSmithingPatterns()
            if numPatterns == 0 then return end
            local _, _, _, _, numTraitsRequired = GetSmithingPatternInfo(1)
            if not numTraitsRequired or numTraitsRequired == 0 then return end

            -- get set ID via result link
            local setName, setId = nil, nil
            local numMaterials = select(4, GetSmithingPatternInfo(1))
            for matIdx = 1, (numMaterials or 5) do
                local resultLink = GetSmithingPatternResultLink(1, matIdx, 1, 1, ITEM_TRAIT_TYPE_NONE, LINK_STYLE_DEFAULT)
                if resultLink and resultLink ~= "" then
                    local hasSet, sName, _, _, _, sId = GetItemLinkSetInfo(resultLink, false)
                    if hasSet and sId and sId ~= 0 then
                        setName = CleanName(sName)
                        setId   = sId
                        break
                    end
                end
            end
            if not setId then return end

            -- find matching POI index from the lookup built during PreScan
            local nx, ny = GetMapPlayerPosition("player")
            if not nx or nx == 0 then return end
            local zoneIndex = GetCurrentMapZoneIndex()
            local zoneId    = (zoneIndex and zoneIndex > 0) and GetZoneId(zoneIndex) or 0
            if zoneId == 0 then return end

            local pk = tostring(zoneId) .. ":" .. string.format("%d", nx * 10000 + 0.5) .. ":" .. string.format("%d", ny * 10000 + 0.5)
            local bestPoiIndex = craftingPOIIndex[pk]
            if not bestPoiIndex then
                -- fallback for special-access zones not in PreScan (Eyevea, The Earth Forge, etc.)
                local bestDist = math.huge
                for pi = 1, GetNumPOIs(zoneIndex) do
                    local px, py = GetPOIMapInfo(zoneIndex, pi)
                    if px and px > 0 then
                        local dx, dy = px - nx, py - ny
                        local d = dx * dx + dy * dy
                        if d < bestDist then
                            bestDist     = d
                            bestPoiIndex = pi
                        end
                    end
                end
                if not bestPoiIndex or bestDist > 0.0004 then return end
            end

            local mapData = _G["GamePadHelperMapData"]
            if not mapData then mapData = {} _G["GamePadHelperMapData"] = mapData end
            if not mapData.craftingStations then mapData.craftingStations = {} end

            local key = tostring(zoneId) .. ":" .. tostring(bestPoiIndex)
            mapData.craftingStations[key] = {
                setId      = setId,
                setName    = setName,
                traitCount = numTraitsRequired,
            }
            candidates = nil  -- refresh list so new data shows
        end, 300)
    end)

    EVENT_MANAGER:RegisterForEvent("MapSearch_Teleport", EVENT_PLAYER_ACTIVATED, function()
        if postTeleportMsg then
            local msg = postTeleportMsg
            postTeleportMsg = nil
            zo_callLater(function()
                local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT)
                params:SetText(msg)
                CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
            end, 500)
        end
        if postTeleportCandidate then
            AddRecent(postTeleportCandidate)
            postTeleportCandidate = nil
        end
        if postTeleportDestination then
            local dest = postTeleportDestination
            postTeleportDestination = nil
            zo_callLater(function()
                PlacePostTeleportDestination(dest)
            end, 500)
        else
            pendingWaypointDest = nil
        end
    end)

    ZO_Dialogs_RegisterCustomDialog("GPH_UNBOOKMARK_CONFIRM", {
        gamepadInfo = { dialogType = GAMEPAD_DIALOGS.BASIC },
        title       = { text = SI_GPH_MAPSEARCH_REMOVE_BOOKMARK },
        mainText    = {
            text = function(dialog)
                local n = dialog.data and dialog.data.name or GetString(SI_GPH_MAPSEARCH_SEARCH_LOCATIONS)
                return zo_strformat(GetString(SI_GPH_MAPSEARCH_REMOVE_BOOKMARK_PROMPT), n)
            end,
        },
        buttons = {
            {
                keybind  = "DIALOG_PRIMARY",
                text     = SI_YES,
                callback = function(dialog)
                    if dialog.data then
                        local idx = listObject and listObject:GetSelectedIndex()
                        RemoveBookmark(dialog.data)
                        pendingNarration = zo_strformat(SI_GPH_MAPSEARCH_BOOKMARK_REMOVED, (dialog.data.name or ""))
                        SCREEN_NARRATION_MANAGER:QueueCustomEntry("GPH_MapSearch_Narration")
                        RunSearch(currentTerm)
                        RebuildList()
                        if idx and idx > 0 and listObject:GetNumItems() > 0 then
                            listObject:SetSelectedIndex(zo_clamp(idx, 1, listObject:GetNumItems()))
                        end
                    end
                end,
            },
            { keybind = "DIALOG_NEGATIVE", text = SI_NO },
        },
    })

    ZO_Dialogs_RegisterCustomDialog("GPH_TELEPORT_CONFIRM", {
        gamepadInfo = { dialogType = GAMEPAD_DIALOGS.BASIC },
        canQueue    = true,
        title = {
            text = SI_PROMPT_TITLE_FAST_TRAVEL_CONFIRM,
        },
        mainText = {
            text = function(dialog)
                if not dialog.data then return "" end
                local destination   = dialog.data.nodeIndex
                local wayshrineName = dialog.data.name
                local cost          = GetRecallCost(destination)
                local currency      = GetRecallCurrency(destination)
                local canAfford     = cost <= GetCurrencyAmount(currency, CURRENCY_LOCATION_CHARACTER)
                local cooldown      = GetRecallCooldown()
                local cooldownStr   = ZO_FormatTimeMilliseconds(cooldown, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_SECONDS)

                local baseId
                if cost == 0 then
                    baseId = SI_GAMEPAD_FAST_TRAVEL_DIALOG_MAIN_TEXT
                elseif cooldown == 0 then
                    baseId = canAfford and SI_GAMEPAD_FAST_TRAVEL_DIALOG_RECALL_MAIN_TEXT
                                       or SI_GAMEPAD_FAST_TRAVEL_DIALOG_CANT_AFFORD
                else
                    baseId = canAfford and SI_GAMEPAD_FAST_TRAVEL_DIALOG_PREMIUM
                                       or SI_GAMEPAD_FAST_TRAVEL_DIALOG_CANT_AFFORD_PREMIUM
                end

                local text = zo_strformat(baseId, wayshrineName, cooldownStr)

                if cost > 0 then
                    text = text
                        .. "\n\n" .. GetString(SI_GPH_MAPSEARCH_RECALL_COST)
                        .. "\n"   .. FormatRecallCostAmount(cost)
                end
                return text
            end,
        },
        buttons = {
            {
                text     = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    if not dialog.data then return end
                    local d  = dialog.data
                    local sv = GetSavedVars()
                    if sv == nil or sv.mapSearchNarratePostTeleport ~= false then
                        postTeleportMsg = zo_strformat(SI_GPH_MAPSEARCH_TELEPORTED_TO, d.name)
                    end
                    if d.candidate then
                        PlaceDestinationDiamondPre(d.candidate)
                        postTeleportCandidate = d.candidate
                    end
                    FastTravelToNode(d.nodeIndex)
                    SCENE_MANAGER:ShowBaseScene()
                end,
                visible = function(dialog)
                    if not dialog.data then return false end
                    local destination = dialog.data.nodeIndex
                    local currency    = GetRecallCurrency(destination)
                    return GetRecallCost(destination) <= GetCurrencyAmount(currency, CURRENCY_LOCATION_CHARACTER)
                end,
            },
            {
                text = SI_DIALOG_CANCEL,
            },
        },
        updateFn = function(dialog)
            if not dialog.data then return end
            local remainingTime = GetRecallCooldown()
            local onCooldown    = remainingTime > 0
            if onCooldown or dialog.onCooldown ~= onCooldown then
                ZO_Dialogs_UpdateDialogMainText(dialog)
                dialog.onCooldown = onCooldown
            end
            KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
        end,
    })

    GAMEPAD_WORLD_MAP_SCENE:RegisterCallback("StateChange", function(_, newState)
        if newState == SCENE_HIDING then
            wasOnGPHSearch = IsFragmentShowing()
        elseif newState == SCENE_SHOWING then
            zo_callLater(InsertMapSearchTab, 0)
            local sv = _G["GamePadHelper_CharSavedVars"]
            if sv and sv.lastSelectedPOI then
                zo_callLater(function()
                    CenterMapOnCandidate(sv.lastSelectedPOI)
                    sv.lastSelectedPOI = nil
                end, 100)
            end
            if pendingWaypointDest then
                local dest = pendingWaypointDest
                pendingWaypointDest = nil
                zo_callLater(function() ApplyWaypointNow(dest) end, 150)
            end
        end
    end)

    if WORLD_MAP_SCENE then
        WORLD_MAP_SCENE:RegisterCallback("StateChange", function(_, newState)
            if newState == SCENE_SHOWING and pendingWaypointDest then
                local dest = pendingWaypointDest
                pendingWaypointDest = nil
                zo_callLater(function() ApplyWaypointNow(dest) end, 150)
            end
        end)
    end

    -- Enlarge the group leader pin to 64×64 when viewing the Cyrodiil map
    if ZO_MapPin and ZO_PostHook and MAP_CONTENT_AVA then
        ZO_PostHook(ZO_MapPin, "UpdateSize", function(self)
            if self.m_PinType == MAP_PIN_TYPE_GROUP_LEADER
            and GetMapContentType
            and GetMapContentType() == MAP_CONTENT_AVA
            and IsCyrodiilKeepSearchEnabled()
            then
                self:GetControl():SetDimensions(64, 64)
            end
        end)
    end
end

_G["GamePadHelper_ClearCityCache"] = function()
    cityServicesCache = nil
    traderGuildMap    = nil
    candidates = nil
    lastSearchTerm = nil
    local mapData = _G["GamePadHelperMapData"]
    if mapData then mapData.cityScanCache = nil end
    -- Rebuild the cache in the background, then refresh the candidate list.
    StartCityScanPrewarm(function()
        candidates = BuildCandidates()
    end)
end

EVENT_MANAGER:RegisterForEvent("MapSearch", EVENT_ADD_ON_LOADED, OnAddonLoaded)
