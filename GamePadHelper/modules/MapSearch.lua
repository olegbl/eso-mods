-- ============================================================
-- GPH Map Search
-- Navigation model: list owns d-pad, edit box for text only.
-- Full feature set: POI/House/Lift types, fuzzy search, teleport,
-- bookmarks with confirmation, narration, post-teleport restore.
-- ============================================================

local function CleanName(s)
    return (s and s ~= "") and zo_strformat("<<C:1>>", s) or (s or "")
end

local TYPE_WAYSHRINE     = 1
local TYPE_ZONE          = 2
local TYPE_POI           = 3
local TYPE_HOUSE_OWNED   = 4
local TYPE_HOUSE_UNOWNED = 5
local TYPE_LIFT          = 6

-- Use ESO's named constants - never hardcode poiType numbers.
-- POI_TYPE_WAYSHRINE / POI_TYPE_HOUSE / POI_TYPE_GROUP_DUNGEON etc. are defined by the game client.

local ICON_WAYSHRINE_KNOWN   = "/esoui/art/icons/poi/poi_wayshrine_complete.dds"
local ICON_WAYSHRINE_UNKNOWN = "/esoui/art/icons/poi/poi_wayshrine_incomplete.dds"
local ICON_LIFT              = "/esoui/art/icons/poi/poi_transit_complete.dds"
local ICON_POI_GENERIC       = "/esoui/art/icons/poi/poi_landmark_complete.dds"

local GPH_SEARCH_FRAGMENT     = nil
local GPH_SEARCH_TAB_INSERTED = false
local gphSearchTabIndex       = nil
local wasOnGPHSearch          = nil

local scannedData = nil
local candidates  = nil
local results     = {}
local currentTerm = ""

local listObject        = nil
local editControl       = nil
local searchBarBG       = nil
local keybindDescriptor = nil

local lastSelectedIndex = 1
local pendingNarration  = nil
local postTeleportMsg   = nil

local function IsFragmentShowing()
    return GPH_SEARCH_FRAGMENT ~= nil and GPH_SEARCH_FRAGMENT:IsShowing()
end

local function UpdateKeybinds()
    if keybindDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(keybindDescriptor)
    end
end

-- bookmarks

local function MakeBookmarkKey(c)
    return c.type .. ":" .. tostring(c.nodeIndex or c.zoneId or "") .. ":" .. c.name
end

local function GetBookmarksArray()
    if not GamePadHelperSavedVars then GamePadHelperSavedVars = {} end
    local charName = GetUnitName("player")
    if not GamePadHelperSavedVars.mapSearchBookmarks then
        GamePadHelperSavedVars.mapSearchBookmarks = {}
    end
    if not GamePadHelperSavedVars.mapSearchBookmarks[charName] then
        GamePadHelperSavedVars.mapSearchBookmarks[charName] = {}
    end
    return GamePadHelperSavedVars.mapSearchBookmarks[charName]
end

local function IsBookmarked(c)
    local key = MakeBookmarkKey(c)
    for _, bm in ipairs(GetBookmarksArray()) do
        if bm.key == key then return true end
    end
    return false
end

local function RemoveBookmark(c)
    local key = MakeBookmarkKey(c)
    local arr = GetBookmarksArray()
    for i, bm in ipairs(arr) do
        if bm.key == key then
            table.remove(arr, i)
            return
        end
    end
end

local function AddBookmark(c)
    local arr = GetBookmarksArray()
    arr[#arr + 1] = {
        key        = MakeBookmarkKey(c),
        name       = c.name,
        searchName = c.name:lower(),
        type       = c.type,
        icon       = c.icon,
        nodeIndex  = c.nodeIndex,
        zoneId     = c.zoneId,
        zoneIndex  = c.zoneIndex,
        mapIndex   = c.mapIndex,
        poiIndex   = c.poiIndex,
        zoneName   = c.zoneName,
        isLocked   = c.isLocked,
        known      = c.known,
    }
end

-- POI type labels

local POI_TYPE_NAMES = {
    areaofinterest  = GetString(SI_GPH_MAPSEARCH_LABEL_AREA_OF_INTEREST),
    adventurezone   = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    ayleidruin      = GetString(SI_GPH_MAPSEARCH_LABEL_AYLEID_RUIN),
    ayliedruin      = GetString(SI_GPH_MAPSEARCH_LABEL_AYLEID_RUIN),
    battlefield     = GetString(SI_GPH_MAPSEARCH_LABEL_BATTLEFIELD),
    battleground    = GetString(SI_GPH_MAPSEARCH_LABEL_BATTLEFIELD),
    boss            = GetString(SI_GPH_MAPSEARCH_LABEL_WORLD_BOSS),
    camp            = GetString(SI_GPH_MAPSEARCH_LABEL_CAMP),
    cave            = GetString(SI_GPH_MAPSEARCH_LABEL_CAVE),
    cemetery        = GetString(SI_GPH_MAPSEARCH_LABEL_CEMETERY),
    cemetary        = GetString(SI_GPH_MAPSEARCH_LABEL_CEMETERY),
    city            = GetString(SI_GPH_MAPSEARCH_LABEL_CITY),
    crafting        = GetString(SI_GPH_MAPSEARCH_LABEL_CRAFTING_STATION),
    crypt           = GetString(SI_GPH_MAPSEARCH_LABEL_CRYPT),
    daedricruin     = GetString(SI_GPH_MAPSEARCH_LABEL_DAEDRIC_RUIN),
    darkbrotherhood = GetString(SI_GPH_MAPSEARCH_LABEL_DARK_BROTHERHOOD),
    delve           = GetString(SI_GPH_MAPSEARCH_LABEL_DELVE),
    dock            = GetString(SI_GPH_MAPSEARCH_LABEL_DOCK),
    dungeon         = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_DUNGEON),
    dwemerruin      = GetString(SI_GPH_MAPSEARCH_LABEL_DWEMER_RUIN),
    endlessdungeon  = GetString(SI_GPH_MAPSEARCH_LABEL_ENDLESS_DUNGEON),
    estate          = GetString(SI_GPH_MAPSEARCH_LABEL_ESTATE),
    explorable      = GetString(SI_GPH_MAPSEARCH_LABEL_EXPLORABLE),
    farm            = GetString(SI_GPH_MAPSEARCH_LABEL_FARM),
    gate            = GetString(SI_GPH_MAPSEARCH_LABEL_GATE),
    grove           = GetString(SI_GPH_MAPSEARCH_LABEL_GROVE),
    harborage       = GetString(SI_GPH_MAPSEARCH_LABEL_HARBORAGE),
    house           = GetString(SI_GPH_MAPSEARCH_LABEL_HOUSE),
    instance        = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_DUNGEON),
    groupboss       = GetString(SI_GPH_MAPSEARCH_LABEL_WORLD_BOSS),
    groupdelve      = GetString(SI_GPH_MAPSEARCH_LABEL_DELVE),
    groupinstance   = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_DUNGEON),
    -- explicit group_ keys so poi_group_house doesn't collapse to "house"
    group_boss      = GetString(SI_GPH_MAPSEARCH_LABEL_WORLD_BOSS),
    group_delve     = GetString(SI_GPH_MAPSEARCH_LABEL_DELVE),
    group_instance  = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_DUNGEON),
    group_dungeon   = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_DUNGEON),
    group_house     = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_INSTANCE),   -- group housing content, not a player home
    keep            = GetString(SI_GPH_MAPSEARCH_LABEL_KEEP),
    lighthouse      = GetString(SI_GPH_MAPSEARCH_LABEL_LIGHTHOUSE),
    mine            = GetString(SI_GPH_MAPSEARCH_LABEL_MINE),
    mine_compete    = GetString(SI_GPH_MAPSEARCH_LABEL_MINE),
    mine_incompete  = GetString(SI_GPH_MAPSEARCH_LABEL_MINE),
    mundus          = GetString(SI_GPH_MAPSEARCH_LABEL_MUNDUS_STONE),
    mushromtower    = GetString(SI_GPH_MAPSEARCH_LABEL_MUSHROOM_TOWER),
    portal          = GetString(SI_GPH_MAPSEARCH_LABEL_DOLMEN),
    raiddungeon     = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_TRIAL),
    ruin            = GetString(SI_GPH_MAPSEARCH_LABEL_RUIN),
    sewer           = GetString(SI_GPH_MAPSEARCH_LABEL_SEWER),
    shrine          = GetString(SI_GPH_MAPSEARCH_LABEL_SHRINE),
    shrine_vampire  = GetString(SI_GPH_MAPSEARCH_LABEL_VAMPIRE_SHRINE),
    shrine_werewolf = GetString(SI_GPH_MAPSEARCH_LABEL_WEREWOLF_SHRINE),
    solotrial       = GetString(SI_GPH_MAPSEARCH_LABEL_SOLO_TRIAL),
    tower           = GetString(SI_GPH_MAPSEARCH_LABEL_TOWER),
    town            = GetString(SI_GPH_MAPSEARCH_LABEL_TOWN),
    transit         = GetString(SI_GPH_MAPSEARCH_LABEL_LIFT),
    lift            = GetString(SI_GPH_MAPSEARCH_LABEL_LIFT),
    nord_boat       = GetString(SI_GPH_MAPSEARCH_LABEL_NORD_BOAT),
    dwemergear      = GetString(SI_GPH_MAPSEARCH_LABEL_LIFT),
    ic_boneshard         = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    ic_darkether         = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    ic_tinyclaw          = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    ic_marklegion        = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    ic_monstrousteeth    = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    ic_planararmorscraps = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    ic_daedricshackles   = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    ic_daedricembers     = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    adventurezone_entrance             = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    adventurezone_jumppad              = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    adventurezone_faction_ruckus       = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    adventurezone_faction_thousandeyes = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    adventurezone_faction_glittering   = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    adventurezone_skirmish             = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    adventurezone_contentgrouptimed    = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    wayshrine    = GetString(SI_GPH_MAPSEARCH_LABEL_WAYSHRINE),
    icon_missing = GetString(SI_GPH_MAPSEARCH_LABEL_UNKNOWN),
    unknown      = GetString(SI_GPH_MAPSEARCH_LABEL_UNKNOWN),
}

local function GetPOITypeLabel(icon)
    if not icon or icon == "" then return nil end
    local name = (icon:match("([^/]+)%.dds$") or icon)
        :gsub("_complete$",   "")
        :gsub("_incomplete$", "")
        :gsub("_owned$",      "")
        :gsub("_unowned$",    "")
        :gsub("^u%d+_poi_",   "")
        :gsub("^u%d+_",       "")
    -- Try with full poi_group_ prefix first so group_house/group_dungeon
    -- don't collapse to "house"/"dungeon" via the generic poi_ strip.
    local grouped = name:gsub("^poi_group_", "group_")
    if POI_TYPE_NAMES[grouped] then return POI_TYPE_NAMES[grouped] end
    local plain = name:gsub("^poi_", "")
    return POI_TYPE_NAMES[plain]
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
        parts[#parts + 1] = c.poiTypeLabel or GetString(SI_GPH_MAPSEARCH_NARRATION_POI)
    elseif c.type == TYPE_ZONE then
        if c.isLocked then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_LOCKED) end
        parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_ZONE)
    elseif c.type == TYPE_LIFT then
        if not c.known     then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_UNDISCOVERED)
        elseif c.isLocked  then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_LOCKED) end
        parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_LABEL_LIFT)
    else
        if c.isLocked      then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_LOCKED)
        elseif not c.known then parts[#parts + 1] = GetString(SI_GPH_MAPSEARCH_NARRATION_UNDISCOVERED) end
    end
    return table.concat(parts, ", ")
end

-- pre-scan 

local function PreScan()
    local zoneToMap    = {}
    local nameToZoneId = {}
    for mi = 1, GetNumMaps() do
        local mapName, mapType, _, zi = GetMapInfoByIndex(mi)
        if zi and zi > 0 then
            if not zoneToMap[zi] or mapType == MAPTYPE_ZONE then
                zoneToMap[zi] = mi
            end
            nameToZoneId[mapName] = GetZoneId(zi)
        end
    end

    local data = { wayshrines = {}, zones = {}, pois = {}, nameToZoneId = nameToZoneId }

    local lockedZoneIndex = {}
    for nodeIndex = 1, GetNumFastTravelNodes() do
        local _, _, _, _, _, _, typePOI, _, isLocked = GetFastTravelNodeInfo(nodeIndex)
        if isLocked and typePOI == POI_TYPE_WAYSHRINE then
            local zi = GetFastTravelNodePOIIndicies(nodeIndex)
            if zi then lockedZoneIndex[zi] = true end
        end
    end

    for nodeIndex = 1, GetNumFastTravelNodes() do
        local known, name, _, _, _, _, typePOI, _, isLocked = GetFastTravelNodeInfo(nodeIndex)
        local isWayshrine = typePOI == POI_TYPE_WAYSHRINE
        local isHouse     = typePOI == POI_TYPE_HOUSE
        if name ~= "" and (isWayshrine or isHouse) then
            local zoneIndex, poiIndex = GetFastTravelNodePOIIndicies(nodeIndex)
            local zoneId = GetZoneId(zoneIndex)
            local _, _, _, poiIcon = GetPOIMapInfo(zoneIndex, poiIndex)
            local defaultIcon = known and ICON_WAYSHRINE_KNOWN or ICON_WAYSHRINE_UNKNOWN
            local icon = (poiIcon and poiIcon ~= "") and poiIcon or defaultIcon
            -- HasCompletedFastTravelNodePOI is how ESO itself determines house ownership.
            local isOwnedHouse = isHouse and HasCompletedFastTravelNodePOI(nodeIndex)
            local houseId = isHouse and GetFastTravelNodeHouseId(nodeIndex) or nil
            data.wayshrines[#data.wayshrines + 1] = {
                name         = CleanName(name),
                icon         = icon,
                nodeIndex    = nodeIndex,
                zoneIndex    = zoneIndex,
                zoneId       = zoneId,
                poiIndex     = poiIndex,
                mapIndex     = zoneToMap[zoneIndex],
                zoneName     = CleanName(GetZoneNameById(zoneId)),
                known        = known,
                isLocked     = isLocked,
                isHouse      = isHouse,
                isOwnedHouse = isOwnedHouse,
                houseId      = houseId,
            }
        end
    end

    local seenZone = {}
    for mapIndex = 1, GetNumMaps() do
        local mapName, mapType, _, zoneIndex = GetMapInfoByIndex(mapIndex)
        if mapName ~= "" and zoneIndex and zoneIndex > 0 then
            local zoneId = GetZoneId(zoneIndex)
            if not seenZone[zoneId] and (mapType == MAPTYPE_ZONE or mapType == MAPTYPE_WORLD) then
                seenZone[zoneId] = true
                local cleanZoneName = CleanName(mapName)
                data.zones[#data.zones + 1] = {
                    name      = cleanZoneName,
                    zoneId    = zoneId,
                    zoneIndex = zoneIndex,
                    mapIndex  = mapIndex,
                    isLocked  = lockedZoneIndex[zoneIndex] or false,
                }
                nameToZoneId[cleanZoneName] = zoneId
            end
        end
    end

    local seenPOI = {}
    for mapIndex = 1, GetNumMaps() do
        local _, _, _, zoneIndex = GetMapInfoByIndex(mapIndex)
        if zoneIndex and zoneIndex > 0 then
            local zoneId   = GetZoneId(zoneIndex)
            local zoneName = CleanName(GetZoneNameById(zoneId))
            for poiIndex = 1, GetNumPOIs(zoneIndex) do
                local uid = zoneIndex .. ":" .. poiIndex
                if not seenPOI[uid] then
                    seenPOI[uid] = true
                    local name = GetPOIInfo(zoneIndex, poiIndex)
                    if name and name ~= "" then
                        local _, _, _, icon, _, linkedCollectibleIsLocked, known = GetPOIMapInfo(zoneIndex, poiIndex)
                        if not icon or not icon:find("wayshrine") then
                            local poiIcon  = (icon and icon ~= "") and icon or nil
                            local isLocked = linkedCollectibleIsLocked or lockedZoneIndex[zoneIndex] or false
                            data.pois[#data.pois + 1] = {
                                name      = CleanName(name),
                                icon      = poiIcon or ICON_POI_GENERIC,
                                -- Only _owned suffix means you own it; _complete/_incomplete do not.
                                isOwned = poiIcon ~= nil and poiIcon:find("_owned") ~= nil and poiIcon:find("_unowned") == nil,
                                zoneIndex = zoneIndex,
                                zoneId    = zoneId,
                                poiIndex  = poiIndex,
                                mapIndex  = zoneToMap[zoneIndex],
                                zoneName  = zoneName,
                                known     = known,
                                isLocked  = isLocked,
                            }
                        end
                    end
                end
            end
        end
    end

    scannedData = data
    candidates  = nil
end

-- candidates

local function FindNearestWayshrineToPos(px, py, minDist, filterZoneIndex)
    if not px or not py or px == 0 then return nil end
    local bestNode, bestDist = nil, math.huge
    for nodeIndex = 1, GetNumFastTravelNodes() do
        local known, _, wsNx, wsNy, _, _, typePOI, _, isLocked = GetFastTravelNodeInfo(nodeIndex)
        if known and not isLocked and typePOI == 1 and wsNx and wsNy then
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

local function BuildCandidates()
    if not scannedData then PreScan() end

    local nameToZoneId = scannedData.nameToZoneId
    local list = {}

    for _, ws in ipairs(scannedData.wayshrines) do
        list[#list + 1] = {
            name       = ws.name,
            searchName = ws.name:lower(),
            type       = ws.isHouse and (ws.isOwnedHouse and TYPE_HOUSE_OWNED or TYPE_HOUSE_UNOWNED)
                      or TYPE_WAYSHRINE,
            icon       = ws.icon,
            nodeIndex  = ws.nodeIndex,
            zoneId     = ws.zoneId,
            zoneIndex  = ws.zoneIndex,
            poiIndex   = ws.poiIndex,
            mapIndex   = ws.mapIndex,
            zoneName   = ws.zoneName,
            known      = ws.known,
            isLocked   = ws.isLocked,
            houseId    = ws.houseId,
        }
    end

    for _, z in ipairs(scannedData.zones) do
        list[#list + 1] = {
            name       = z.name,
            searchName = z.name:lower(),
            type       = TYPE_ZONE,
            icon       = "/esoui/art/worldmap/map_indexicon_locations_up.dds",
            zoneId     = z.zoneId,
            zoneIndex  = z.zoneIndex,
            mapIndex   = z.mapIndex,
            zoneName   = z.name,
            known      = true,
            isLocked   = z.isLocked,
        }
    end

    for _, poi in ipairs(scannedData.pois) do
        local poiTypeLabel = GetPOITypeLabel(poi.icon)
        local isHousePOI   = poiTypeLabel == GetString(SI_GPH_MAPSEARCH_LABEL_HOUSE)
        local entryType    = isHousePOI
            and (poi.isOwned and TYPE_HOUSE_OWNED or TYPE_HOUSE_UNOWNED)
            or TYPE_POI

        local cityZoneId = (poi.icon:find("poi_city") and nameToZoneId[poi.name]) or nil
        if cityZoneId then
            list[#list + 1] = {
                name         = poi.name,
                searchName   = poi.name:lower(),
                type         = entryType,
                poiTypeLabel = poiTypeLabel,
                icon         = poi.icon,
                zoneId       = cityZoneId,
                zoneIndex    = GetZoneIndex(cityZoneId),
                mapIndex     = GetMapIndexByZoneId(cityZoneId),
                isLocked     = poi.isLocked,
            }
        else
            list[#list + 1] = {
                name         = poi.name,
                searchName   = poi.name:lower(),
                type         = entryType,
                poiTypeLabel = poiTypeLabel,
                icon         = poi.icon,
                zoneId       = poi.zoneId,
                zoneIndex    = poi.zoneIndex,
                poiIndex     = poi.poiIndex,
                mapIndex     = poi.mapIndex,
                zoneName     = poi.zoneName,
                known        = poi.known,
                isLocked     = poi.isLocked,
            }
        end
    end

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

local function RunSearch(term)
    if not candidates then candidates = BuildCandidates() end

    local termLower = term:lower()
    local scored    = {}

    for i = 1, #candidates do
        local c = candidates[i]
        local s = ScoreMatch(c.searchName, termLower)
        if s > 0 then scored[#scored + 1] = { score = s, c = c } end
    end

    table.sort(scored, function(a, b)
        if a.score ~= b.score   then return a.score > b.score end
        if a.c.type ~= b.c.type then return a.c.type < b.c.type end
        return a.c.searchName < b.c.searchName
    end)

    results = {}
    for i = 1, math.min(#scored, 60) do
        results[#results + 1] = scored[i].c
    end
end

-- list

local CAT_NAMES = {
    [TYPE_WAYSHRINE]     = GetString(SI_GPH_MAPSEARCH_GROUP_WAYSHRINES),
    [TYPE_LIFT]          = GetString(SI_GPH_MAPSEARCH_GROUP_LIFTS),
    [TYPE_ZONE]          = GetString(SI_GPH_MAPSEARCH_GROUP_ZONES),
    [TYPE_POI]           = GetString(SI_GPH_MAPSEARCH_GROUP_LOCATIONS),
    [TYPE_HOUSE_OWNED]   = GetString(SI_GPH_MAPSEARCH_GROUP_OWNED_HOUSES),
    [TYPE_HOUSE_UNOWNED] = GetString(SI_GPH_MAPSEARCH_GROUP_UNOWNED_HOUSES),
}

local function RebuildList()
    if not listObject then return end
    listObject:Clear()

    local bookmarks = GetBookmarksArray()

    if currentTerm == "" then
        for i, bm in ipairs(bookmarks) do
            local entryData = ZO_GamepadEntryData:New(bm.name, bm.icon)
            entryData.candidate     = bm
            entryData.isBookmark    = true
            entryData.narrationText = BuildCandidateNarrationText(bm, true)
            entryData:SetIconTintOnSelection(true)
            if bm.isLocked then entryData:AddIcon("EsoUI/Art/Miscellaneous/status_locked.dds") end
            if i == 1 then
                entryData:SetHeader(GetString(SI_GPH_MAPSEARCH_GROUP_BOOKMARKS))
                listObject:AddEntryWithHeader("ZO_GamepadMenuEntryTemplateLowercase34", entryData)
            else
                listObject:AddEntry("ZO_GamepadMenuEntryTemplateLowercase34", entryData)
            end
        end

        -- Owned houses below bookmarks when no search term
        if candidates then
            local bookmarkKeys = {}
            for _, bm in ipairs(bookmarks) do bookmarkKeys[MakeBookmarkKey(bm)] = true end
            local firstHouse = true
            for _, c in ipairs(candidates) do
                if c.type == TYPE_HOUSE_OWNED and not bookmarkKeys[MakeBookmarkKey(c)] then
                    local entryData = ZO_GamepadEntryData:New(c.name, c.icon)
                    entryData.candidate     = c
                    entryData.narrationText = BuildCandidateNarrationText(c, false)
                    entryData:SetIconTintOnSelection(true)
                    if firstHouse then
                        firstHouse = false
                        entryData:SetHeader(GetString(SI_GPH_MAPSEARCH_GROUP_OWNED_HOUSES))
                        listObject:AddEntryWithHeader("ZO_GamepadMenuEntryTemplateLowercase34", entryData)
                    else
                        listObject:AddEntry("ZO_GamepadMenuEntryTemplateLowercase34", entryData)
                    end
                end
            end
        end
    elseif #results > 0 then
        local lastType = nil
        for _, c in ipairs(results) do
            local displayName = IsBookmarked(c)
                and zo_iconTextFormat("EsoUI/Art/Collections/Favorite_StarOnly.dds", 24, 24, c.name)
                or c.name
            local entryData = ZO_GamepadEntryData:New(displayName, c.icon)
            entryData.candidate     = c
            entryData.narrationText = BuildCandidateNarrationText(c, IsBookmarked(c))
            entryData:SetIconTintOnSelection(true)
            if c.isLocked then entryData:AddIcon("EsoUI/Art/Miscellaneous/status_locked.dds") end
            if c.type ~= lastType then
                lastType = c.type
                entryData:SetHeader(CAT_NAMES[c.type] or GetString(SI_GPH_MAPSEARCH_GROUP_OTHER))
                listObject:AddEntryWithHeader("ZO_GamepadMenuEntryTemplateLowercase34", entryData)
            else
                listObject:AddEntry("ZO_GamepadMenuEntryTemplateLowercase34", entryData)
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

local function AddPing(x, y)
    local pinMgr = ZO_WorldMap_GetPinManager and ZO_WorldMap_GetPinManager()
    if not pinMgr then return end
    pinMgr:RemovePins("pings")
    pinMgr:CreatePin(MAP_PIN_TYPE_AUTO_MAP_NAVIGATION_PING, "pings", x, y)
    local sv = _G["GamePadHelper_SavedVars"]
    if sv == nil or sv.mapSearchSetDestination ~= false then
        PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, x, y)
    end
end

local function CenterMapOnCandidate(c)
    if not c then return end

    local zoneId       = c.zoneId
    local mapId        = zoneId and GetMapIdByZoneId(zoneId)
    local currentMapId = GetCurrentMapId and GetCurrentMapId()

    local function doPan()
        if c.icon and c.icon:find("poi_city") then
            ZO_WorldMap_PanToNormalizedPosition(0.5, 0.5)
            return
        end
        if c.zoneIndex and c.poiIndex then
            local nx, ny = GetPOIMapInfo(c.zoneIndex, c.poiIndex)
            if nx and nx > 0 then
                ZO_WorldMap_PanToNormalizedPosition(nx, ny)
                AddPing(nx, ny)
                return
            end
        end
        if c.type == TYPE_WAYSHRINE and c.nodeIndex then
            ZO_WorldMap_PanToWayshrine(c.nodeIndex)
        end
    end

    if mapId and mapId > 0 and mapId ~= currentMapId then
        WORLD_MAP_MANAGER:SetMapById(mapId)
        zo_callLater(doPan, 100)
    else
        doPan()
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
                    if not GamePadHelperSavedVars then GamePadHelperSavedVars = {} end
                    GamePadHelperSavedVars.lastSelectedPOI = td.candidate
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
            -- In text mode: X = Clear (clears text, stays in search box)
            -- In list mode: X = Search (opens text mode)
            keybind  = "UI_SHORTCUT_SECONDARY",
            name     = function()
                return (editControl and editControl:HasFocus()) and GetString(SI_GPH_MAPSEARCH_CLEAR) or GetString(SI_SCREEN_NARRATION_EDIT_BOX_SEARCH_NAME)
            end,
            callback = function()
                if editControl and editControl:HasFocus() then
                    currentTerm = ""
                    editControl:SetText("")
                    results = {}
                    RebuildList()
                    pendingNarration = GetString(SI_GPH_MAPSEARCH_SEARCH_CLEARED)
                    SCREEN_NARRATION_MANAGER:QueueCustomEntry("GPH_MapSearch_Narration")
                else
                    if editControl then editControl:TakeFocus() end
                end
            end,
            visible  = function() return IsFragmentShowing() end,
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
                    or c.type == TYPE_HOUSE_OWNED then
                        return GetString(SI_GPH_TELEPORT)
                    end
                end
                return GetString(SI_GPH_MAPSEARCH_TELEPORT_NEAREST)
            end,
            enabled  = function()
                local td = listObject and listObject:GetTargetData()
                if td and td.candidate then
                    local c = td.candidate
                    if c.isLocked then return false end
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

                if not GamePadHelperSavedVars then GamePadHelperSavedVars = {} end
                GamePadHelperSavedVars.lastSelectedPOI = c

                if c.isLocked then
                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_GPH_MAPSEARCH_ZONE_LOCKED))
                    return
                end

                if c.type == TYPE_HOUSE_OWNED and c.houseId then
                    if not CanJumpToHouseFromCurrentLocation() then
                        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_GPH_MAPSEARCH_NO_HOUSE_TRAVEL))
                        return
                    end
                    ZO_Dialogs_ShowGamepadDialog("GPH_HOUSE_TRAVEL", { candidate = c })
                    return
                end

                local nodeIndex, failReason = nil, nil
                if c.type == TYPE_WAYSHRINE and c.known then
                    nodeIndex = c.nodeIndex
                elseif c.zoneIndex and c.poiIndex then
                    local nx, ny = GetPOIMapInfo(c.zoneIndex, c.poiIndex)
                    if nx and ny then
                        nodeIndex = FindNearestWayshrineToPos(nx, ny, 0, c.zoneIndex)
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
                if cost > 0 then
                    ZO_Dialogs_ShowGamepadDialog("GPH_TELEPORT_CONFIRM", { nodeIndex = nodeIndex, cost = cost })
                else
                    local sv = _G["GamePadHelper_SavedVars"]
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

    ZO_Gamepad_AddListTriggerKeybindDescriptors(keybindDescriptor, listObject)
end

-- XML callbacks

function GPH_MapSearch_OnShown(edit)
    editControl = edit
    edit:SetDefaultText(GetString(SI_GPH_MAPSEARCH_SEARCH_HINT))
    edit:SetHandler("OnKeyDown", function(_, key)
        if key == KEY_GAMEPAD_DPAD_LEFT then
            edit:LoseFocus()
        end
    end)
    RunSearch(currentTerm)
    RebuildList()
end

function GPH_MapSearch_OnTextChanged(text)
    if not IsFragmentShowing() then return end
    currentTerm = text or ""
    if currentTerm ~= "" then RunSearch(currentTerm) else results = {} end
    RebuildList()
end

function GPH_MapSearch_OnSearchFocused(focused)
    if searchBarBG then searchBarBG:SetHidden(not focused) end
    if listObject then
        if focused then
            listObject:Deactivate()
        elseif IsFragmentShowing() then
            listObject:Activate()
        end
    end
    UpdateKeybinds()
    if focused then
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
        if not GamePadHelperSavedVars then GamePadHelperSavedVars = {} end
        GamePadHelperSavedVars.lastSelectedPOI = td.candidate
        CenterMapOnCandidate(td.candidate)
    end
end

-- UI init

local function InitList(control)
    local listCtrl = control:GetNamedChild("Main"):GetNamedChild("List")
    listObject = ZO_GamepadVerticalParametricScrollList:New(listCtrl)
    listObject:SetAlignToScreenCenter(true)

    listObject:AddDataTemplate(
        "ZO_GamepadMenuEntryTemplateLowercase34",
        ZO_SharedGamepadEntry_OnSetup,
        ZO_GamepadMenuEntryTemplateParametricListFunction)
    listObject:AddDataTemplateWithHeader(
        "ZO_GamepadMenuEntryTemplateLowercase34",
        ZO_SharedGamepadEntry_OnSetup,
        ZO_GamepadMenuEntryTemplateParametricListFunction,
        nil, "ZO_GamepadMenuEntryHeaderTemplate")

    listObject:SetOnTargetDataChangedCallback(function()
        local idx = listObject:GetSelectedIndex()
        if idx and idx > 0 then lastSelectedIndex = idx end
        UpdateKeybinds()
        if not (editControl and editControl:HasFocus()) then
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("GPH_MapSearch_Narration")
        end
    end)
end

local function InsertMapSearchTab()
    if GPH_SEARCH_TAB_INSERTED then return end

    local mapInfo = GAMEPAD_WORLD_MAP_INFO
    if not mapInfo or not mapInfo.tabBarEntries or not mapInfo.header then return end

    local control = GPH_MapSearch_Gamepad
    if not control then return end

    InitList(control)

    local searchBar = control:GetNamedChild("Main"):GetNamedChild("SearchBar")
    searchBarBG     = searchBar:GetNamedChild("BG")

    BuildKeybindDescriptor()

    GPH_SEARCH_FRAGMENT = ZO_SimpleSceneFragment:New(control)

    SCREEN_NARRATION_MANAGER:RegisterCustomObject("GPH_MapSearch_PostTeleport", {
        narrationType = NARRATION_TYPE_UI_INTERACTIONS,
        canNarrate    = function() return pendingNarration ~= nil end,
        selectedNarrationFunction = function()
            local narrations = {}
            if pendingNarration then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(pendingNarration))
                pendingNarration = nil
            end
            return narrations
        end,
    })

    SCREEN_NARRATION_MANAGER:RegisterCustomObject("GPH_MapSearch_Narration", {
        narrationType = NARRATION_TYPE_UI_INTERACTIONS,
        canNarrate    = function() return IsFragmentShowing() end,
        selectedNarrationFunction = function()
            local narrations = {}
            if pendingNarration then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(pendingNarration))
                pendingNarration = nil
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
            RunSearch(currentTerm)
            RebuildList()
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
        elseif newState == SCENE_HIDING or newState == SCENE_HIDDEN then
            if listObject then
                local idx = listObject:GetSelectedIndex()
                if idx and idx > 0 then lastSelectedIndex = idx end
                listObject:Deactivate()
            end
            KEYBIND_STRIP:RemoveKeybindButtonGroup(keybindDescriptor)
            if editControl then editControl:LoseFocus() end
            pendingNarration = nil
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
end

-- addon loaded

local function OnAddonLoaded(_, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("MapSearch", EVENT_ADD_ON_LOADED)

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
    end)

    ZO_Dialogs_RegisterCustomDialog("GPH_TELEPORT_CONFIRM", {
        gamepadInfo = { dialogType = GAMEPAD_DIALOGS.BASIC },
        title       = { text = SI_GPH_MAPSEARCH_CONFIRM_TELEPORT },
        mainText    = {
            text = function(dialog)
                local cost = dialog.data and dialog.data.cost or 0
                return zo_strformat(GetString(SI_GPH_MAPSEARCH_TELEPORT_COST), cost)
            end,
        },
        buttons = {
            {
                keybind  = "DIALOG_PRIMARY",
                text     = SI_YES,
                callback = function(dialog)
                    if dialog.data and dialog.data.nodeIndex then
                        local sv = _G["GamePadHelper_SavedVars"]
                        if sv == nil or sv.mapSearchNarratePostTeleport ~= false then
                            local poi = GamePadHelperSavedVars and GamePadHelperSavedVars.lastSelectedPOI
                            postTeleportMsg = poi and zo_strformat(SI_GPH_MAPSEARCH_TELEPORTED_TO, poi.name) or GetString(SI_GPH_MAPSEARCH_TELEPORTED)
                        end
                        FastTravelToNode(dialog.data.nodeIndex)
                        ZO_WorldMap_HideWorldMap()
                    end
                end,
            },
            { keybind = "DIALOG_NEGATIVE", text = SI_NO },
        },
    })

    ZO_Dialogs_RegisterCustomDialog("GPH_HOUSE_TRAVEL", {
        gamepadInfo = { dialogType = GAMEPAD_DIALOGS.BASIC },
        title       = { text = SI_GPH_MAPSEARCH_TRAVEL_TO_HOUSE },
        mainText    = {
            text = function(dialog)
                local name = dialog.data and dialog.data.candidate and dialog.data.candidate.name or GetString(SI_GPH_MAPSEARCH_THIS_HOUSE)
                return zo_strformat(GetString(SI_GPH_MAPSEARCH_TRAVEL_HOUSE_PROMPT), name)
            end,
        },
        buttons = {
            {
                keybind  = "DIALOG_PRIMARY",
                text     = SI_GPH_MAPSEARCH_ENTER_HOUSE,
                callback = function(dialog)
                    local c = dialog.data and dialog.data.candidate
                    if c and c.houseId then
                        RequestJumpToHouse(c.houseId, false) -- false = TRAVEL_INSIDE
                        ZO_WorldMap_HideWorldMap()
                    end
                end,
            },
            {
                keybind  = "DIALOG_SECONDARY",
                text     = SI_GPH_MAPSEARCH_TRAVEL_EXTERIOR,
                callback = function(dialog)
                    local c = dialog.data and dialog.data.candidate
                    if c and c.houseId then
                        RequestJumpToHouse(c.houseId, true) -- true = TRAVEL_OUTSIDE
                        ZO_WorldMap_HideWorldMap()
                    end
                end,
            },
            { keybind = "DIALOG_NEGATIVE", text = SI_CANCEL },
        },
    })

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

    GAMEPAD_WORLD_MAP_SCENE:RegisterCallback("StateChange", function(_, newState)
        if newState == SCENE_HIDING then
            wasOnGPHSearch = IsFragmentShowing()
        elseif newState == SCENE_SHOWING then
            zo_callLater(InsertMapSearchTab, 0)
            zo_callLater(function()
                if wasOnGPHSearch and gphSearchTabIndex and GAMEPAD_WORLD_MAP_INFO and GAMEPAD_WORLD_MAP_INFO.header then
                    ZO_GamepadGenericHeader_SetActiveTabIndex(GAMEPAD_WORLD_MAP_INFO.header, gphSearchTabIndex)
                end
            end, 0)
            if GamePadHelperSavedVars and GamePadHelperSavedVars.lastSelectedPOI then
                zo_callLater(function()
                    local poi = GamePadHelperSavedVars.lastSelectedPOI
                    CenterMapOnCandidate(poi)
                    GamePadHelperSavedVars.lastSelectedPOI = nil
                end, 100)
            end
        end
    end)
end

EVENT_MANAGER:RegisterForEvent("MapSearch", EVENT_ADD_ON_LOADED, OnAddonLoaded)
