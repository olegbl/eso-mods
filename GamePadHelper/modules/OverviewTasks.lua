GPH_Overview = GPH_Overview or {}
GPH_Overview.Tasks = GPH_Overview.Tasks or {}

local Tasks = GPH_Overview.Tasks

local CRAFTING = {
    -- researchable (alphabetical)
    CRAFTING_TYPE_BLACKSMITHING,
    CRAFTING_TYPE_CLOTHIER,
    CRAFTING_TYPE_WOODWORKING,
    CRAFTING_TYPE_JEWELRYCRAFTING,
    -- no research (alphabetical)
    CRAFTING_TYPE_ALCHEMY,
    CRAFTING_TYPE_ENCHANTING,
    CRAFTING_TYPE_PROVISIONING,
}

local CRAFTING_TYPE_TO_WRIT_KEY = {
    [CRAFTING_TYPE_BLACKSMITHING]  = "blacksmith",
    [CRAFTING_TYPE_CLOTHIER]       = "clothier",
    [CRAFTING_TYPE_WOODWORKING]    = "woodworker",
    [CRAFTING_TYPE_ENCHANTING]     = "enchanter",
    [CRAFTING_TYPE_PROVISIONING]   = "provisioner",
    [CRAFTING_TYPE_ALCHEMY]        = "alchemist",
    [CRAFTING_TYPE_JEWELRYCRAFTING] = "jewelry",
}

local GPH_COMPANION_TRACKER_KEY = "overviewCompanionTracker"
local GPH_DAILY_WRIT_TRACKER_KEY = "overviewDailyWritTracker"
local GPH_DAILY_QUEST_TRACKER_KEY = "overviewDailyQuestTracker"
local TASKS_CACHE_TTL_MS = 30000
local DAILY_RESET_REFRESH_NAMESPACE = "GPH_OverviewTasks_DailyResetRefresh"
local SECONDS_IN_DAY = 86400
local SERVER_RESET_HOURS = {
    ["EU Megaserver"] = 3, ["XB1live-eu"] = 3, ["PS4live-eu"] = 3,
    ["NA Megaserver"] = 10, ["PTS"] = 10,
}
local tasksCacheTimeText = nil
local tasksCacheHorseLines = nil
local tasksCacheMapLines = nil
local tasksCacheCompanionData = nil
local tasksCacheCraftingLines = nil
local tasksCacheTimeMs = 0
local tasksCacheDirty = true
local EnsureCompanionTrackerState
local EnsureDailyWritTrackerState
local EnsureDailyQuestTrackerState
local RAPPORT_GRADIENT_START = ZO_ColorDef:New("722323")
local RAPPORT_GRADIENT_END = ZO_ColorDef:New("009966")
local RAPPORT_GRADIENT_MIDDLE = ZO_ColorDef:New("9D840D")

local DAILY_WRIT_GROUPS = {
    { id = "blacksmith", displayQuestId = 5377, questIds = { 5368, 5377, 5392 } },
    { id = "clothier", displayQuestId = 5374, questIds = { 5374, 5388, 5389 } },
    { id = "woodworker", displayQuestId = 5395, questIds = { 5394, 5395, 5396 } },
    { id = "enchanter", displayQuestId = 5407, questIds = { 5400, 5406, 5407 } },
    { id = "provisioner", displayQuestId = 5414, questIds = { 5409, 5412, 5413, 5414 } },
    { id = "alchemist", displayQuestId = 6105, questIds = { 5415, 5416, 5417, 5418, 6098, 6099, 6100, 6101, 6102, 6103, 6104, 6105 } },
    { id = "jewelry", displayQuestId = 6228, questIds = { 6218, 6227, 6228 } },
}

local function GetBoolSetting(key, default)
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv then return default end
    local v = sv[key]
    if v == nil then return default end
    return v
end

local function GetNowMs()
    if GetGameTimeMilliseconds then
        return GetGameTimeMilliseconds()
    end
    if GetFrameTimeMilliseconds then
        return GetFrameTimeMilliseconds()
    end
    if GetTimeStamp then
        return GetTimeStamp() * 1000
    end
    return 0
end

function Tasks.InvalidateCache()
    tasksCacheDirty = true
    tasksCacheTimeText = nil
    tasksCacheHorseLines = nil
    tasksCacheMapLines = nil
    tasksCacheCompanionData = nil
    tasksCacheCraftingLines = nil
    tasksCacheTimeMs = 0
end

local function GetServerDayNumber()
    local now = GetTimeStamp()
    local worldName = GetWorldName and GetWorldName() or ""
    local resetHour = SERVER_RESET_HOURS[worldName] or 10
    local dateTable = os.date("!*t", now)
    if dateTable.hour < resetHour then
        now = now - SECONDS_IN_DAY
    end
    return math.floor(now / SECONDS_IN_DAY)
end

local function GetSecondsUntilReset()
    local s = GetTimeUntilNextDailyLoginRewardClaimS and GetTimeUntilNextDailyLoginRewardClaimS()
    if s and s > 0 and s <= 172800 then return s end
    return SECONDS_IN_DAY
end

local function ScheduleDailyResetRefresh()
    if not EVENT_MANAGER then return end
    local secondsUntilReset = GetSecondsUntilReset()
    EVENT_MANAGER:UnregisterForUpdate(DAILY_RESET_REFRESH_NAMESPACE)
    EVENT_MANAGER:RegisterForUpdate(DAILY_RESET_REFRESH_NAMESPACE, (secondsUntilReset + 2) * 1000, function()
        EVENT_MANAGER:UnregisterForUpdate(DAILY_RESET_REFRESH_NAMESPACE)
        EnsureCompanionTrackerState()
        EnsureDailyWritTrackerState()
        EnsureDailyQuestTrackerState()
        Tasks.InvalidateCache()
        ScheduleDailyResetRefresh()
    end)
end

local function GPH_NormalizeLowerText(text)
    return zo_strlower(zo_strformat("<<1>>", text or ""))
end

local COMPANION_RAPPORT_RECOMMENDATIONS = {
    ["bastian"] = {
        { id = "mages_daily", questIds = { 5814, 5816, 5818, 5819, 5820, 5822, 5823, 5824, 5825, 5826, 5827, 5828, 5829, 5830, 5831 } },
    },
    ["mirri"] = {
        { id = "fighters_daily", questIds = { 5786, 5793, 5787, 5789, 5791, 5833, 5794, 5796, 5795, 5797, 5785, 5790, 5788, 5784, 5792 } },
        { id = "ashlander_hunt_sorim_nakar", questIds = { 5907, 5908, 5909, 5910, 5911, 5912, 5913 } },
        { id = "ashlander_relic_numani_rasi", questIds = { 5924, 5925, 5926, 5927, 5928, 5929, 5930 } },
    },
    ["ember"] = {
        { id = "mages_daily", questIds = { 5814, 5816, 5818, 5819, 5820, 5822, 5823, 5824, 5825, 5826, 5827, 5828, 5829, 5830, 5831 } },
        { id = "heist_daily", questIds = { 5536, 5575, 5572, 5577, 5573 } },
        { id = "highisle_delve", questIds = { 6809, 6826, 6805, 6825, 6818, 6815 } },
    },
    ["isobel"] = {
        { id = "undaunted_daily", questIds = { 5735, 5733, 5738, 5853, 5800, 5808, 5737, 5778, 5779, 5802, 5744, 5745, 5739, 5734, 5798 } },
        { id = "highisle_worldboss", questIds = { 6821, 6803, 6807, 6816, 6822, 6808 } },
    },
    ["azandar"] = {
        { id = "necrom_delve", questIds = { 7035, 7037, 7036, 7034 } },
        { id = "enchanter_writ", questIds = { 5400, 5406, 5407 } },
    },
    ["sharp-as-night"] = {
        { id = "necrom_worldboss", questIds = { 7042, 7041, 7043, 7039, 7040 } },
        { id = "ashlander_hunt_sorim_nakar", questIds = { 5907, 5908, 5909, 5910, 5911, 5912, 5913 } },
        { id = "ashlander_relic_numani_rasi", questIds = { 5924, 5925, 5926, 5927, 5928, 5929, 5930 } },
    },
    ["tanlorin"] = {
        { id = "fighters_daily", questIds = { 5786, 5793, 5787, 5789, 5791, 5833, 5794, 5796, 5795, 5797, 5785, 5790, 5788, 5784, 5792 } },
        { id = "alchemy_writ", questIds = { 5415, 5416, 5417, 5418, 6098, 6099, 6100, 6101, 6102, 6103, 6104, 6105 } },
    },
    ["zerith-var"] = {
        { id = "northern_grahtwood_defence_force", questIds = { 6318, 6341, 6342, 6345, 6347 } },
        { id = "tales_of_tribute_daily", questIds = { 6831, 6832 } },
    },
}

local function SafeGetSkillLineName(skillType, skillLineIndex)
    local id = GetSkillLineId and GetSkillLineId(skillType, skillLineIndex)
    return id and GetSkillLineNameById and GetSkillLineNameById(id)
end

local function GetLocalizedActivityLabel(activityId)
    if activityId == "fighters_daily" then
        return GetString(SI_GPH_OVERVIEW_COMPANION_ACTIVITY_FIGHTERS_DAILY)
    elseif activityId == "mages_daily" then
        return GetString(SI_GPH_OVERVIEW_COMPANION_ACTIVITY_MAGES_DAILY)
    elseif activityId == "undaunted_daily" then
        local undaunted = GetString(SI_QUESTTYPE15)
        if undaunted and undaunted ~= "" then
            return zo_strformat("<<C:1>>", undaunted)
        end
    elseif activityId == "heist_daily" then
        return GetString(SI_GPH_OVERVIEW_COMPANION_ACTIVITY_HEIST_DAILY)
    elseif activityId == "highisle_worldboss" then
        return GetString(SI_GPH_OVERVIEW_COMPANION_ACTIVITY_HIGHISLE_WB)
    elseif activityId == "highisle_delve" then
        return GetString(SI_GPH_OVERVIEW_COMPANION_ACTIVITY_HIGHISLE_DELVE)
    elseif activityId == "necrom_worldboss" then
        return GetString(SI_GPH_OVERVIEW_COMPANION_ACTIVITY_NECROM_WB)
    elseif activityId == "necrom_delve" then
        return GetString(SI_GPH_OVERVIEW_COMPANION_ACTIVITY_NECROM_DELVE)
    elseif activityId == "ashlander_hunt_sorim_nakar" then
        return GetString(SI_GPH_OVERVIEW_COMPANION_ACTIVITY_ASHLANDER_HUNT)
    elseif activityId == "ashlander_relic_numani_rasi" then
        return GetString(SI_GPH_OVERVIEW_COMPANION_ACTIVITY_ASHLANDER_RELIC)
    elseif activityId == "alchemy_writ" then
        return GetString(SI_GPH_OVERVIEW_COMPANION_ACTIVITY_ALCHEMY_WRIT)
    elseif activityId == "enchanter_writ" then
        return GetString(SI_GPH_OVERVIEW_COMPANION_ACTIVITY_ENCHANTER_WRIT)
    elseif activityId == "northern_grahtwood_defence_force" then
        return GetString(SI_GPH_OVERVIEW_COMPANION_ACTIVITY_NORTHERN_GRAHTWOOD_DEFENCE)
    elseif activityId == "tales_of_tribute_daily" then
        return GetString(SI_GPH_OVERVIEW_COMPANION_ACTIVITY_TALES_TRIBUTE)
    end
    return GetString(SI_GPH_OVERVIEW_TASKS)
end

local function GetCompanionProfileKey(companionId, companionName)
    local defId = tonumber(companionId)
    if defId then
        local byDefId = {}
        local function AddDef(defConstant, key)
            if type(defConstant) == "number" then
                byDefId[defConstant] = key
            end
        end
        AddDef(_G["COMPANION_DEF_ID_BASTIAN"], "bastian")
        AddDef(_G["COMPANION_DEF_ID_MIRRI"], "mirri")
        AddDef(_G["COMPANION_DEF_ID_EMBER"], "ember")
        AddDef(_G["COMPANION_DEF_ID_ISOBEL"], "isobel")
        AddDef(_G["COMPANION_DEF_ID_AZANDAR"], "azandar")
        AddDef(_G["COMPANION_DEF_ID_SHARP_AS_NIGHT"], "sharp-as-night")
        AddDef(_G["COMPANION_DEF_ID_TANLORIN"], "tanlorin")
        AddDef(_G["COMPANION_DEF_ID_ZERITH_VAR"], "zerith-var")
        if byDefId[defId] then
            return byDefId[defId]
        end
    end

    local name = GPH_NormalizeLowerText(companionName)
    if name == "" then return nil end
    if name:find("bastian", 1, true) then return "bastian" end
    if name:find("mirri", 1, true) then return "mirri" end
    if name:find("ember", 1, true) then return "ember" end
    if name:find("isobel", 1, true) then return "isobel" end
    if name:find("azandar", 1, true) then return "azandar" end
    if name:find("sharp", 1, true) then return "sharp-as-night" end
    if name:find("tanlorin", 1, true) then return "tanlorin" end
    if name:find("zerith", 1, true) then return "zerith-var" end
    return nil
end

function EnsureCompanionTrackerState()
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv then return nil end

    sv[GPH_COMPANION_TRACKER_KEY] = sv[GPH_COMPANION_TRACKER_KEY] or {}
    local tracker = sv[GPH_COMPANION_TRACKER_KEY]

    local currentDay = GetServerDayNumber()
    if tracker.lastKnownDay ~= currentDay then
        tracker.doneByActivity = {}
        tracker.lastKnownDay = currentDay
    end

    tracker.doneByActivity = tracker.doneByActivity or {}
    return tracker
end

function EnsureDailyWritTrackerState()
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv then return nil end

    sv[GPH_DAILY_WRIT_TRACKER_KEY] = sv[GPH_DAILY_WRIT_TRACKER_KEY] or {}
    local tracker = sv[GPH_DAILY_WRIT_TRACKER_KEY]

    local currentDay = GetServerDayNumber()
    if tracker.lastKnownDay ~= currentDay then
        tracker.doneByQuestId = {}
        tracker.doneByWritKey = {}
        tracker.activeByQuestId = {}
        tracker.activeByWritKey = {}
        tracker.lastKnownDay = currentDay
    end

    tracker.doneByQuestId = tracker.doneByQuestId or {}
    tracker.doneByWritKey = tracker.doneByWritKey or {}
    tracker.activeByQuestId = tracker.activeByQuestId or {}
    tracker.activeByWritKey = tracker.activeByWritKey or {}
    return tracker
end

function EnsureDailyQuestTrackerState()
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv then return nil end

    sv[GPH_DAILY_QUEST_TRACKER_KEY] = sv[GPH_DAILY_QUEST_TRACKER_KEY] or {}
    local tracker = sv[GPH_DAILY_QUEST_TRACKER_KEY]

    local currentDay = GetServerDayNumber()
    if tracker.lastKnownDay ~= currentDay then
        tracker.doneByQuestId = {}
        tracker.activeByQuestId = {}
        tracker.lastKnownDay = currentDay
    end

    tracker.doneByQuestId = tracker.doneByQuestId or {}
    tracker.activeByQuestId = tracker.activeByQuestId or {}
    return tracker
end

function Tasks.RefreshDailyQuestTrackerState(tracker)
    tracker = tracker or EnsureDailyQuestTrackerState()
    if not tracker then return end

    local activeByQuestId = {}
    for questIndex = 1, MAX_JOURNAL_QUESTS do
        if IsValidQuestIndex(questIndex) and GetJournalQuestRepeatType(questIndex) == QUEST_REPEAT_DAILY then
            local questId = GetJournalQuestId and GetJournalQuestId(questIndex) or nil
            if questId and questId ~= 0 then
                local questName = GetJournalQuestName and GetJournalQuestName(questIndex) or GetJournalQuestInfo(questIndex)
                activeByQuestId[questId] = zo_strformat("<<C:1>>", questName or "")
            end
        end
    end
    tracker.activeByQuestId = activeByQuestId
end

local function OnQuestRemovedForDailyQuestTracker(_, completed, questIndex, questName, zoneIndex, poiIndex, questId)
    if not completed then return end
    if not questId or questId == 0 then return end

    local tracker = EnsureDailyQuestTrackerState()
    if not tracker then return end

    if tracker.activeByQuestId[questId] then
        local name = zo_strformat("<<C:1>>", questName or "")
        tracker.doneByQuestId[questId] = name ~= "" and name or tracker.activeByQuestId[questId]
        tracker.activeByQuestId[questId] = nil
    end
end

local function IsQuestIdInActivity(questId, activity)
    if not questId or not activity or not activity.questIds then
        return false
    end
    for _, id in ipairs(activity.questIds) do
        if id == questId then
            return true
        end
    end
    return false
end

local function GetActiveCompanionOverviewData()
    if not HasActiveCompanion or not HasActiveCompanion() then return nil end
    local companionId = GetActiveCompanionDefId and GetActiveCompanionDefId() or nil
    if not companionId then return nil end

    local companionName = GetCompanionName and GetCompanionName(companionId) or ""
    local profileKey = GetCompanionProfileKey(companionId, companionName)
    local activities = profileKey and COMPANION_RAPPORT_RECOMMENDATIONS[profileKey] or nil
    local lines = {}
    local data = {
        name = zo_strformat("<<C:1>>", companionName ~= "" and companionName or GetString(SI_GENERIC_ACTIVE_COMPANION_NAME)),
        lines = lines,
    }

    if ZO_COMPANION_MANAGER and ZO_COMPANION_MANAGER.GetLevelInfo then
        data.level, data.currentXpInLevel, data.totalXpInLevel, data.isMaxLevel = ZO_COMPANION_MANAGER:GetLevelInfo()
    end

    local rapportValue = GetActiveCompanionRapport and GetActiveCompanionRapport() or nil
    local rapportLevel = GetActiveCompanionRapportLevel and GetActiveCompanionRapportLevel() or nil
    data.rapportValue = rapportValue
    data.rapportLevel = rapportLevel
    if rapportLevel then
        data.rapportLevelText = zo_strformat("<<C:1>>", GetString("SI_COMPANIONRAPPORTLEVEL", rapportLevel))
        data.rapportDescription = GetActiveCompanionRapportLevelDescription and GetActiveCompanionRapportLevelDescription(rapportLevel) or nil
    end

    if not activities or #activities == 0 then
        table.insert(lines, "|cAAAAAA" .. GetString(SI_GPH_OVERVIEW_COMPANION_NO_CONFIG) .. "|r")
        return data
    end

    table.insert(lines, "|cDAA520" .. GetString(SI_GPH_OVERVIEW_COMPANION_BEST_DAILIES) .. "|r")

    local tracker = EnsureCompanionTrackerState()
    local doneByActivity = (tracker and tracker.doneByActivity) or {}
    for _, activity in ipairs(activities) do
        local isDoneToday = doneByActivity[activity.id] == true
        local isInProgress = false
        local activeQuestName = nil
        for i = 1, MAX_JOURNAL_QUESTS do
            if IsValidQuestIndex(i) then
                local journalQuestId = GetJournalQuestId and GetJournalQuestId(i) or nil
                if IsQuestIdInActivity(journalQuestId, activity) then
                    isInProgress = true
                    activeQuestName = GetJournalQuestName and GetJournalQuestName(i) or GetJournalQuestInfo(i)
                    break
                end
            end
        end

        local status = isDoneToday and ("|c66FF66" .. GetString(SI_GPH_OVERVIEW_COMPANION_STATUS_DONE) .. "|r") or (isInProgress and ("|cFFFF66" .. GetString(SI_GPH_OVERVIEW_COMPANION_STATUS_IN_PROGRESS) .. "|r") or ("|cAAAAAA" .. GetString(SI_GPH_OVERVIEW_COMPANION_STATUS_NOT_DONE) .. "|r"))
        local activityLabel = activeQuestName and activeQuestName ~= "" and zo_strformat("<<C:1>>", activeQuestName) or GetLocalizedActivityLabel(activity.id)
        table.insert(lines, string.format("  %s - %s", activityLabel, status))
    end

    return data
end

function Tasks.OnQuestRemovedForCompanionTracker(_, completed, questIndex, questName, zoneIndex, poiIndex, questId)
    if not completed then return end
    if not questId or questId == 0 then return end
    if not HasActiveCompanion or not HasActiveCompanion() then return end

    local companionId = GetActiveCompanionDefId and GetActiveCompanionDefId() or nil
    if not companionId then return end
    local companionName = GetCompanionName and GetCompanionName(companionId) or ""
    local profileKey = GetCompanionProfileKey(companionId, companionName)
    local activities = profileKey and COMPANION_RAPPORT_RECOMMENDATIONS[profileKey] or nil
    if not activities then return end

    local tracker = EnsureCompanionTrackerState()
    if not tracker then return end

    for _, activity in ipairs(activities) do
        if IsQuestIdInActivity(questId, activity) then
            tracker.doneByActivity[activity.id] = true
        end
    end
end

local function IsDailyCraftingWritQuest(questIndex)
    if not IsValidQuestIndex(questIndex) then return false end
    if GetJournalQuestType(questIndex) ~= QUEST_TYPE_CRAFTING then return false end
    return GetJournalQuestRepeatType(questIndex) == QUEST_REPEAT_DAILY
end

local function GetDailyWritKeyForQuestId(questId)
    if not questId or questId == 0 then return nil end
    for _, group in ipairs(DAILY_WRIT_GROUPS) do
        for _, id in ipairs(group.questIds) do
            if id == questId then
                return group.id
            end
        end
    end
    return nil
end

local function GetDailyWritStatusByKey()
    local tracker = EnsureDailyWritTrackerState()
    if not tracker then return nil end

    Tasks.RefreshDailyWritTrackerState(tracker)

    local dailyWritLabel = GetString(SI_GPH_OVERVIEW_DAILY_WRIT)
    local statusByKey = {}
    for _, group in ipairs(DAILY_WRIT_GROUPS) do
        local status
        local isDone = false
        if tracker.activeByWritKey[group.id] then
            status = "|cFFFF66" .. GetString(SI_GPH_OVERVIEW_COMPANION_STATUS_IN_PROGRESS) .. "|r"
        elseif tracker.doneByWritKey[group.id] then
            status = "|c66FF66" .. GetString(SI_GPH_OVERVIEW_COMPANION_STATUS_DONE) .. "|r"
            isDone = true
        else
            status = "|cAAAAAA" .. GetString(SI_GPH_OVERVIEW_COMPANION_STATUS_NOT_DONE) .. "|r"
        end
        statusByKey[group.id] = { label = dailyWritLabel, status = status, isDone = isDone }
    end

    return statusByKey
end

function Tasks.RefreshDailyWritTrackerState(tracker)
    tracker = tracker or EnsureDailyWritTrackerState()
    if not tracker then return end

    local activeByQuestId = {}
    local activeByWritKey = {}

    for questIndex = 1, MAX_JOURNAL_QUESTS do
        if IsDailyCraftingWritQuest(questIndex) then
            local questId = GetJournalQuestId and GetJournalQuestId(questIndex) or nil
            local questName = GetJournalQuestName and GetJournalQuestName(questIndex) or GetJournalQuestInfo(questIndex)
            questName = zo_strformat("<<C:1>>", questName or "")
            local writKey = GetDailyWritKeyForQuestId(questId)

            if questId and questId ~= 0 then
                activeByQuestId[questId] = { name = questName, writKey = writKey }
            end
            if writKey then
                activeByWritKey[writKey] = questName
            end
        end
    end

    tracker.activeByQuestId = activeByQuestId
    tracker.activeByWritKey = activeByWritKey
end

local function OnQuestRemovedForDailyWritTracker(_, completed, questIndex, questName, zoneIndex, poiIndex, questId)
    if not completed then return end
    if not questId or questId == 0 then return end

    local tracker = EnsureDailyWritTrackerState()
    if not tracker then return end

    local writKey = GetDailyWritKeyForQuestId(questId)
    local activeQuest = tracker.activeByQuestId and tracker.activeByQuestId[questId]
    if activeQuest then
        tracker.doneByQuestId[questId] = activeQuest.name
        tracker.activeByQuestId[questId] = nil
    end
    writKey = writKey or (activeQuest and activeQuest.writKey)
    if writKey then
        tracker.doneByWritKey[writKey] = true
        if tracker.activeByWritKey then
            tracker.activeByWritKey[writKey] = nil
        end
    end
end

function Tasks.OnQuestStateChanged()
    Tasks.RefreshDailyWritTrackerState()
    Tasks.RefreshDailyQuestTrackerState()
    Tasks.InvalidateCache()
end

function Tasks.OnQuestRemoved(...)
    Tasks.OnQuestRemovedForCompanionTracker(...)
    OnQuestRemovedForDailyWritTracker(...)
    OnQuestRemovedForDailyQuestTracker(...)
    Tasks.OnQuestStateChanged()
end

local function FormatTimeRemaining(seconds)
    if not seconds or seconds <= 0 then return "" end
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local timeString = ""

    if days > 0 then
        timeString = timeString .. zo_strformat(GetString(SI_GPH_TIME_DAY_SHORT), days) .. " "
        if hours > 0 then timeString = timeString .. zo_strformat(GetString(SI_GPH_TIME_HOUR_SHORT), hours) .. " " end
    else
        if hours > 0 then timeString = timeString .. zo_strformat(GetString(SI_GPH_TIME_HOUR_SHORT), hours) .. " " end
        if minutes > 0 then timeString = timeString .. zo_strformat(GetString(SI_GPH_TIME_MINUTE_SHORT), minutes) end
    end

    timeString = timeString:gsub("%s+$", "")

    local totalDays = seconds / 86400
    if totalDays <= 3 then
        return "|cCC4C4C" .. timeString .. "|r"
    elseif totalDays <= 7 then
        return "|cFFFF00" .. timeString .. "|r"
    else
        return "|cFFFFFF" .. timeString .. "|r"
    end
end

local function FormatExactCountdown(seconds)
    if not seconds or seconds < 0 then return nil end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return string.format("%02d:%02d", hours, minutes)
end


local function GetResearchLineInfo(craftingType, researchLineIndex, numTraits)
    local areAllTraitsKnown = true
    for traitIndex = 1, numTraits do
        local _, _, known = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)

        if not known then
            areAllTraitsKnown = false

            local durationSecs = GetSmithingResearchLineTraitTimes(craftingType, researchLineIndex, traitIndex)
            if durationSecs and durationSecs > 0 then
                return traitIndex, areAllTraitsKnown
            end
        end
    end
    return nil, areAllTraitsKnown
end

local function GetResearchInfo(craftingType)
    local maximum = GetMaxSimultaneousSmithingResearch(craftingType)
    local current = 0
    local researchableTraits = 0
    local researchableItems = 0

    local researchableTraitList = {}
    for researchLineIndex = 1, GetNumSmithingResearchLines(craftingType) do
        local _, _, numTraits = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
        if numTraits > 0 then
            local researchingTraitIndex, areAllTraitsKnown = GetResearchLineInfo(craftingType, researchLineIndex, numTraits)
            if researchingTraitIndex then
                current = current + 1
            end
            if not areAllTraitsKnown then
                for traitIndex = 1, numTraits do
                    local _, _, known = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)
                    if not known then
                        local durationSecs = GetSmithingResearchLineTraitTimes(craftingType, researchLineIndex, traitIndex)
                        if not durationSecs or durationSecs == 0 then
                            researchableTraits = researchableTraits + 1
                            table.insert(researchableTraitList, { researchLineIndex = researchLineIndex, traitIndex = traitIndex })
                        end
                    end
                end
            end
        end
    end

    local function IsUsableForResearch(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
        return CanItemBeSmithingTraitResearched(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
            and not IsItemPlayerLocked(bagId, slotIndex)
            and GetItemTraitInformation(bagId, slotIndex) ~= ITEM_TRAIT_INFORMATION_RETRAITED
            and GetItemTraitInformation(bagId, slotIndex) ~= ITEM_TRAIT_INFORMATION_RECONSTRUCTED
    end

    if #researchableTraitList > 0 then
        for _, traitInfo in ipairs(researchableTraitList) do
            local hasItem = false

            for slotIndex = 0, GetBagSize(BAG_BACKPACK) - 1 do
                if GetItemId(BAG_BACKPACK, slotIndex) > 0 then
                    if IsUsableForResearch(BAG_BACKPACK, slotIndex, craftingType, traitInfo.researchLineIndex, traitInfo.traitIndex) then
                        hasItem = true
                        break
                    end
                end
            end

            if not hasItem then
                for slotIndex = 0, GetBagSize(BAG_BANK) - 1 do
                    if GetItemId(BAG_BANK, slotIndex) > 0 then
                        if IsUsableForResearch(BAG_BANK, slotIndex, craftingType, traitInfo.researchLineIndex, traitInfo.traitIndex) then
                            hasItem = true
                            break
                        end
                    end
                end
            end

            if not hasItem then
                for slotIndex = 0, GetBagSize(BAG_SUBSCRIBER_BANK) - 1 do
                    if GetItemId(BAG_SUBSCRIBER_BANK, slotIndex) > 0 then
                        if IsUsableForResearch(BAG_SUBSCRIBER_BANK, slotIndex, craftingType, traitInfo.researchLineIndex, traitInfo.traitIndex) then
                            hasItem = true
                            break
                        end
                    end
                end
            end

            if hasItem then
                researchableItems = researchableItems + 1
            end
        end
    end

    local availableSlots = maximum - current
    return researchableTraits, researchableItems, current, availableSlots
end

local function CountAllInventoryItems()
    local treasureCount = 0
    local totalSurveyCount = 0
    local totalWritCount = 0

    for _, bagId in ipairs({ BAG_BACKPACK, BAG_BANK, BAG_SUBSCRIBER_BANK }) do
        for slotIndex = 0, GetBagSize(bagId) - 1 do
            if GetItemId(bagId, slotIndex) > 0 then
                local itemType, specializedItemType = GetItemType(bagId, slotIndex)
                if specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP and not IsItemLinkUnique(GetItemLink(bagId, slotIndex)) then
                    treasureCount = treasureCount + GetSlotStackSize(bagId, slotIndex)
                elseif specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT then
                    totalSurveyCount = totalSurveyCount + GetSlotStackSize(bagId, slotIndex)
                elseif itemType == ITEMTYPE_MASTER_WRIT or specializedItemType == SPECIALIZED_ITEMTYPE_MASTER_WRIT then
                    totalWritCount = totalWritCount + GetSlotStackSize(bagId, slotIndex)
                end
            end
        end
    end

    return treasureCount, totalSurveyCount, totalWritCount
end

local function GetScryableAntiquitiesInfo()
    local totalLeads = 0
    local totalMinTimeRemaining = nil
    local urgentZoneName = nil

    local antiquityId = GetNextAntiquityId()
    while antiquityId do
        local antiquityData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)

        if antiquityData:HasLead() and antiquityData:MeetsScryingSkillRequirements() and not antiquityData:HasAchievedAllGoals() then
            totalLeads = totalLeads + 1
        end

        local timeRemaining = antiquityData:GetLeadTimeRemainingS()
        if timeRemaining and timeRemaining > 0 then
            if totalMinTimeRemaining == nil or timeRemaining < totalMinTimeRemaining then
                totalMinTimeRemaining = timeRemaining
                urgentZoneName = zo_strformat("<<C:1>>", GetZoneNameById(antiquityData:GetZoneId()))
            end
        end

        antiquityId = GetNextAntiquityId(antiquityId)
    end
    return totalLeads, totalMinTimeRemaining, urgentZoneName
end

local function GetLocalClockText()
    if not os or not os.date then return nil end
    local ok, result = pcall(os.date, "%H:%M")
    if ok and result and result ~= "" then return result end
    return nil
end

local function GetMissingRidingTrainingLines()
    if not STABLE_MANAGER or not STABLE_MANAGER.GetStats then
        return nil
    end

    local ridingTypes = {
        { trainingType = RIDING_TRAIN_SPEED, icon = "EsoUI/Art/Mounts/Gamepad/gp_ridingskill_speed.dds" },
        { trainingType = RIDING_TRAIN_CARRYING_CAPACITY, icon = "EsoUI/Art/Mounts/Gamepad/gp_ridingskill_capacity.dds" },
        { trainingType = RIDING_TRAIN_STAMINA, icon = "EsoUI/Art/Mounts/Gamepad/gp_ridingskill_stamina.dds" },
    }

    local lines = {}

    for _, ridingTypeData in ipairs(ridingTypes) do
        local bonus, maxBonus = STABLE_MANAGER:GetStats(ridingTypeData.trainingType)
        if bonus and maxBonus and bonus < maxBonus then
            local title = GetString("SI_RIDINGTRAINTYPE", ridingTypeData.trainingType)
            local icon = "|t32:32:" .. ridingTypeData.icon .. "|t"
            local valueText = string.format("|cFFFFFF%d|r/|cFFFFFF%d|r", bonus, maxBonus)
            table.insert(lines, "  " .. icon .. " " .. title .. " " .. valueText)
        end
    end

    return lines
end

local function GetDisplayTitle(text)
    text = zo_strformat("<<C:1>>", text or "")
    return text:gsub("[%s:：]+$", "")
end

local function GetCraftingOverviewTitle()
    local title = GetString and GetString("SI_QUESTTYPE", QUEST_TYPE_CRAFTING)
    if title and title ~= "" then
        return zo_strformat("<<C:1>>", title)
    end
    return "Crafting"
end

local function GetTimeOverviewTitle()
    return GetString(SI_GPH_OVERVIEW_TIME)
end

local function GetHorseOverviewTitle()
    return GetDisplayTitle(GetString(SI_GPH_OVERVIEW_HORSE_TRAINING))
end

local function GetMapsOverviewTitle()
    return zo_strformat(GetString(SI_GPH_OVERVIEW_MAPS), 2)
end

local function GetCompanionOverviewTitle()
    return GetDisplayTitle(GetString(SI_GPH_OVERVIEW_COMPANION_LABEL))
end

local SECTION_TITLE_ICONS = {
    time = "|t48:48:/esoui/art/tutorial/timer_icon.dds|t",
    horse = "|t64:64:/esoui/art/icons/servicetooltipicons/gamepad/gp_servicetooltipicon_stablemaster.dds|t",
    maps = "|t48:48:EsoUI/Art/TradingHouse/Gamepad/gp_tradinghouse_trophy_treasure_map.dds|t",
    companion = "|t48:48:EsoUI/Art/Journal/Gamepad/gp_questtypeicon_companion.dds|t",
    crafting = "|t64:64:/esoui/art/icons/servicetooltipicons/gamepad/gp_servicetooltipicon_buildstation.dds|t",
}

local function AddIconLines(section, lines, style)
    for _, displayLine in ipairs(lines) do
        section:AddLine(displayLine, style)
    end
end

local function TrimTrailingEmptyLines(lines)
    while #lines > 0 and lines[#lines] == "" do
        table.remove(lines)
    end
end

local function AddTitledDividerSection(tooltip, title, iconMarkup)
    local dividerSection = tooltip:AcquireSection(tooltip:GetStyle("bodyHeader"))
    local titleText = "|cDAA520" .. title .. "|r"
    if iconMarkup and iconMarkup ~= "" then
        titleText = iconMarkup .. " " .. titleText
    end
    dividerSection:AddLine(titleText, tooltip:GetStyle("title"))
    dividerSection:AddTexture(ZO_GAMEPAD_HEADER_DIVIDER_TEXTURE, tooltip:GetStyle("dividerLine"))
    tooltip:AddSection(dividerSection)
end

local function AddBlockSpacingSection(tooltip)
    local spacingSection = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
    spacingSection:AddLine("", tooltip:GetStyle("bodyDescription"))
    tooltip:AddSection(spacingSection)
end

local function AddCompanionOverviewSection(tooltip, companionData)
    if not companionData then
        return
    end

    local nameSection = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
    nameSection:AddLine("|cDAA520" .. companionData.name .. "|r", tooltip:GetStyle("title"))
    tooltip:AddSection(nameSection)

    if companionData.level then
        local xpProgressSection = tooltip:AcquireSection(tooltip:GetStyle("companionXpProgressSection"))
        local xpPair = xpProgressSection:AcquireStatValuePair(tooltip:GetStyle("statValuePair"))
        xpPair:SetStat(GetString(SI_STAT_GAMEPAD_EXPERIENCE_LABEL), tooltip:GetStyle("statValuePairStat"))

        local xpBar = tooltip:AcquireStatusBar(tooltip:GetStyle("companionXpBar"))
        local enlightenedBar = xpBar.GetNamedChild and xpBar:GetNamedChild("EnlightenedBar")
        if enlightenedBar then
            enlightenedBar:SetHidden(true)
        end

        if companionData.isMaxLevel then
            xpPair:SetValue(GetString(SI_EXPERIENCE_LIMIT_REACHED), tooltip:GetStyle("statValuePairValueSmall"))
            xpBar:SetMinMax(0, 1)
            xpBar:SetValue(1)
        elseif companionData.totalXpInLevel and companionData.totalXpInLevel > 0 then
            local percentageXp = zo_floor((companionData.currentXpInLevel or 0) / companionData.totalXpInLevel * 100)
            xpPair:SetValue(zo_strformat(SI_EXPERIENCE_CURRENT_MAX_PERCENT, ZO_CommaDelimitNumber(companionData.currentXpInLevel or 0), ZO_CommaDelimitNumber(companionData.totalXpInLevel), percentageXp), tooltip:GetStyle("statValuePairValueSmall"))
            xpBar:SetMinMax(0, companionData.totalXpInLevel)
            xpBar:SetValue(companionData.currentXpInLevel or 0)
        end

        xpProgressSection:AddStatValuePair(xpPair)
        tooltip:AddSection(xpProgressSection)
        tooltip:AddStatusBar(xpBar)
    end

    if companionData.rapportLevelText then
        local rapportStatusSection = tooltip:AcquireSection(tooltip:GetStyle("companionOverviewStatValueSection"))
        local rapportPair = rapportStatusSection:AcquireStatValuePair(tooltip:GetStyle("statValuePair"))
        rapportPair:SetStat(GetString(SI_COMPANION_RAPPORT_STATUS), tooltip:GetStyle("statValuePairStat"))
        rapportPair:SetValue(companionData.rapportLevelText, tooltip:GetStyle("statValuePairValueSmall"))
        rapportStatusSection:AddStatValuePair(rapportPair)
        tooltip:AddSection(rapportStatusSection)
    end

    if companionData.rapportValue then
        local rapportBarSection = tooltip:AcquireSection(tooltip:GetStyle("companionRapportBarSection"))
        local rapportBarControl = tooltip:AcquireCustomControl(tooltip:GetStyle("companionRapportBar"))
        local rapportBar = ZO_SlidingStatusBar:New(rapportBarControl)
        rapportBar:SetGradientColors(RAPPORT_GRADIENT_START, RAPPORT_GRADIENT_END, RAPPORT_GRADIENT_MIDDLE)
        rapportBar:SetMinMax(GetMinimumRapport(), GetMaximumRapport())
        rapportBar.indicatorOffsetY = -8

        -- The stock companion rapport bar style is tuned for ESO's wider overview tooltip.
        -- Fit it to this narrower custom panel while keeping the pointer visible.
        local tooltipWidth = tooltip:GetWidth() or 420
        rapportBarControl:SetWidth(math.max(335, tooltipWidth + 5))
        local valuePointer = rapportBarControl:GetNamedChild("ValuePointer")
        if valuePointer then
            valuePointer:SetHidden(false)
            valuePointer:SetDimensions(24, 24)
        end
        rapportBar:SetValue(companionData.rapportValue, true)

        rapportBarSection:AddCustomControl(rapportBarControl)
        tooltip:AddSection(rapportBarSection)
    end

    if companionData.rapportDescription and companionData.rapportDescription ~= "" then
        local rapportBodySection = tooltip:AcquireSection(tooltip:GetStyle("companionOverviewBodySection"))
        rapportBodySection:AddLine(companionData.rapportDescription, tooltip:GetStyle("companionOverviewDescription"))
        tooltip:AddSection(rapportBodySection)
    end

    if companionData.lines and #companionData.lines > 0 then
        AddBlockSpacingSection(tooltip)
        local dailiesSection = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
        AddIconLines(dailiesSection, companionData.lines, tooltip:GetStyle("bodyDescription"))
        tooltip:AddSection(dailiesSection)
    end
end

function ZO_Tooltip:LayoutTasksTooltip(title, timeText, horseLines, mapLines, companionData, craftingLines)
    local style = self:GetStyle("bodyDescription")

    if timeText and timeText ~= "" then
        AddTitledDividerSection(self, GetTimeOverviewTitle(), SECTION_TITLE_ICONS.time)
        local s = self:AcquireSection(self:GetStyle("bodySection"))
        s:AddLine(timeText, style)
        self:AddSection(s)
        if (horseLines and #horseLines > 0) or (mapLines and #mapLines > 0) or companionData or (craftingLines and #craftingLines > 0) then
            AddBlockSpacingSection(self)
        end
    end

    if horseLines and #horseLines > 0 then
        AddTitledDividerSection(self, GetHorseOverviewTitle(), SECTION_TITLE_ICONS.horse)
        local s = self:AcquireSection(self:GetStyle("bodySection"))
        AddIconLines(s, horseLines, style)
        self:AddSection(s)
        if (mapLines and #mapLines > 0) or companionData or (craftingLines and #craftingLines > 0) then
            AddBlockSpacingSection(self)
        end
    end

    if mapLines and #mapLines > 0 then
        AddTitledDividerSection(self, GetMapsOverviewTitle(), SECTION_TITLE_ICONS.maps)
        local s = self:AcquireSection(self:GetStyle("bodySection"))
        AddIconLines(s, mapLines, style)
        self:AddSection(s)
        if companionData or (craftingLines and #craftingLines > 0) then
            AddBlockSpacingSection(self)
        end
    end

    if companionData then
        AddTitledDividerSection(self, GetCompanionOverviewTitle(), SECTION_TITLE_ICONS.companion)
        AddCompanionOverviewSection(self, companionData)
        if craftingLines and #craftingLines > 0 then
            AddBlockSpacingSection(self)
        end
    end

    if craftingLines and #craftingLines > 0 then
        AddTitledDividerSection(self, GetCraftingOverviewTitle(), SECTION_TITLE_ICONS.crafting)
        local s = self:AcquireSection(self:GetStyle("bodySection"))
        AddIconLines(s, craftingLines, style)
        self:AddSection(s)
    end
end

local function BuildRightTooltipDescription()
    local timeText = ""
    local horseLines = {}
    local mapLines = {}

    local localTime = GetBoolSetting("overviewLocalTimeEnabled", true) and GetLocalClockText() or nil
    local resetCountdown = GetBoolSetting("overviewResetTimerEnabled", true) and FormatExactCountdown(GetSecondsUntilReset()) or nil
    if localTime or resetCountdown then
        local timeLine = ""
        if localTime then
            timeLine = "|cDAA520" .. GetString(SI_GPH_OVERVIEW_LOCAL_TIME) .. "|r |cFFFFFF" .. localTime .. "|r"
        end
        if resetCountdown then
            if timeLine ~= "" then timeLine = timeLine .. "\n" end
            timeLine = timeLine .. "|cDAA520" .. GetString(SI_GPH_OVERVIEW_RESET_IN) .. "|r |cFFFFFF" .. resetCountdown .. "|r"
        end
        timeText = timeLine
    end

    local totalCount, totalMinTime, urgentZoneName = GetScryableAntiquitiesInfo()
    local isUrgent = totalMinTime and (totalMinTime / 86400) <= 3
    if isUrgent then
        local zoneText = urgentZoneName and zo_strformat(GetString(SI_GPH_OVERVIEW_IN_ZONE), "|cFFFF00" .. urgentZoneName .. "|r") or ""
        if timeText ~= "" then
            timeText = timeText .. "\n\n"
        end
        timeText = timeText .. "|cCC4C4C" .. GetString(SI_GPH_OVERVIEW_URGENT) .. "|r\n   " .. zo_strformat(GetString(SI_GPH_OVERVIEW_LEAD_EXPIRES), zoneText, FormatTimeRemaining(totalMinTime))
    end

    local horseTrainingTimeRemaining = GetTimeUntilCanBeTrained()
    local speedBonus, maxSpeedBonus, staminaBonus, maxStaminaBonus, inventoryBonus, maxInventoryBonus = STABLE_MANAGER:GetStats()
    if GetBoolSetting("overviewHorseEnabled", true) and horseTrainingTimeRemaining == 0 and ((speedBonus < maxSpeedBonus) or (staminaBonus < maxStaminaBonus) or (inventoryBonus < maxInventoryBonus)) then
        table.insert(horseLines, "|c66FF66" .. GetString(SI_GPH_OVERVIEW_AVAILABLE) .. "|r")
        local ridingLines = GetMissingRidingTrainingLines()
        if ridingLines and #ridingLines > 0 then
            for _, line in ipairs(ridingLines) do
                table.insert(horseLines, line)
            end
        end
    end

    local treasureCount, totalSurveyCount, totalWritCount = CountAllInventoryItems()

    local hasCrafting = false

    local writStatusByKey = GetBoolSetting("overviewDailyWritEnabled", true) and GetDailyWritStatusByKey() or nil
    local hideCompletedDailyWrits = GetBoolSetting("overviewHideCompletedDailyWritEnabled", true)
    local showResearch = GetBoolSetting("overviewResearchEnabled", true)

    local allCraftingLines = {}

    local ICON_LEADS    = "|t32:32:EsoUI/Art/TreeIcons/gamepad/GP_antiquities_indexIcon_scryable.dds|t"
    local ICON_TREASURE = "|t32:32:EsoUI/Art/TradingHouse/Gamepad/gp_tradinghouse_trophy_treasure_map.dds|t"
    local ICON_SURVEY   = "|t32:32:EsoUI/Art/TradingHouse/Gamepad/gp_tradinghouse_trophy_scroll.dds|t"
    local ICON_CRAFTING = "|t32:32:EsoUI/Art/TradingHouse/Gamepad/gp_tradinghouse_master_writ.dds|t"

    if totalCount > 0 then
        local totalTimeString = ""
        if totalMinTime and not isUrgent and totalMinTime < (30 * 86400) then
            totalTimeString = " (" .. FormatTimeRemaining(totalMinTime) .. ")"
        end
        local label = zo_strformat(GetString(SI_GPH_OVERVIEW_SCRYABLE), totalCount)
        table.insert(mapLines, ICON_LEADS .. " |cFFFFFF" .. totalCount .. "|r " .. label .. totalTimeString)
    end

    if treasureCount > 0 then
        local mapLabel = GetString(SI_GPH_OVERVIEW_TREASURE) .. " " .. zo_strformat(GetString(SI_GPH_OVERVIEW_MAPS), treasureCount)
        table.insert(mapLines, ICON_TREASURE .. " |cFFFFFF" .. treasureCount .. "|r " .. mapLabel)
    end

    if totalSurveyCount > 0 then
        local mapLabel = GetString(SI_GPH_OVERVIEW_SURVEY) .. " " .. zo_strformat(GetString(SI_GPH_OVERVIEW_MAPS), totalSurveyCount)
        table.insert(mapLines, ICON_SURVEY .. " |cFFFFFF" .. totalSurveyCount .. "|r " .. mapLabel)
    end

    if totalWritCount > 0 then
        local label = zo_strformat(GetString(SI_GPH_OVERVIEW_WRIT), totalWritCount)
        table.insert(allCraftingLines, ICON_CRAFTING .. " |cFFFFFF" .. totalWritCount .. "|r " .. label)
        table.insert(allCraftingLines, "")
        hasCrafting = true
    end

    for _, craftingType in ipairs(CRAFTING) do
        local craftName = zo_strformat("<<C:1>>", GetCraftingSkillName(craftingType))
        local writKey = CRAFTING_TYPE_TO_WRIT_KEY[craftingType]
        local writEntry = writStatusByKey and writKey and writStatusByKey[writKey]
        local entryLines = {}

        if writEntry and (not writEntry.isDone or not hideCompletedDailyWrits) then
            table.insert(entryLines, "  " .. writEntry.label .. " - " .. writEntry.status)
        end

        if showResearch then
            local researchableTraits, researchableItems, _, availableSlots = GetResearchInfo(craftingType)
            if GetNumSmithingResearchLines(craftingType) == 0 then
                local hasSkill = false
                if craftingType == CRAFTING_TYPE_PROVISIONING or craftingType == CRAFTING_TYPE_ENCHANTING or craftingType == CRAFTING_TYPE_ALCHEMY then
                    local targetSkillName = zo_strlower(zo_strformat("<<1>>", GetCraftingSkillName(craftingType) or ""))
                    for skillCategory = 1, GetNumSkillTypes() do
                        for skillLine = 1, GetNumSkillLines(skillCategory) do
                            local skillLineName = SafeGetSkillLineName(skillCategory, skillLine)
                            if skillLineName then
                                if targetSkillName ~= "" and zo_strlower(zo_strformat("<<1>>", skillLineName)):find(targetSkillName, 1, true) then
                                    hasSkill = true
                                    break
                                end
                            end
                        end
                        if hasSkill then break end
                    end
                end
                if not hasSkill then
                    table.insert(entryLines, "  " .. GetString(SI_GPH_OVERVIEW_VISIT_STATION))
                end
            elseif researchableTraits > 0 and availableSlots > 0 then
                local slotText = string.format(" |c00FF00%d|r %s", availableSlots, zo_strformat(GetString(SI_GPH_OVERVIEW_AVAILABLE_SLOTS), zo_strformat("<<1[slot/slots/slots]>>", availableSlots), ""))
                table.insert(entryLines, "  " .. string.format("|cFFFFFF%d|r/|cFFFFFF%d|r %s%s", researchableTraits, researchableItems, GetString(SI_GPH_OVERVIEW_RESEARCHABLE), slotText))
            end
        end

        if #entryLines > 0 then
            hasCrafting = true
            table.insert(allCraftingLines, "|cDAA520" .. craftName .. "|r")
            for _, line in ipairs(entryLines) do
                table.insert(allCraftingLines, line)
            end
            table.insert(allCraftingLines, "")
        end
    end

    local companionData = GetBoolSetting("overviewCompanionEnabled", true) and GetActiveCompanionOverviewData() or nil

    TrimTrailingEmptyLines(horseLines)
    TrimTrailingEmptyLines(mapLines)
    TrimTrailingEmptyLines(allCraftingLines)

    if timeText == "" and not companionData and #horseLines == 0 and #mapLines == 0 and #allCraftingLines == 0 then
        timeText = GetString(SI_GPH_OVERVIEW_TASKS_AVAILABLE)
    end

    return timeText, horseLines, mapLines, companionData, allCraftingLines
end

function Tasks.ShowRightTooltip(rightTooltip)
    local nowMs = GetNowMs()
    local timeText, horseLines, mapLines, companionData, craftingLines =
        tasksCacheTimeText, tasksCacheHorseLines, tasksCacheMapLines, tasksCacheCompanionData, tasksCacheCraftingLines

    if tasksCacheDirty or tasksCacheTimeText == nil or (nowMs - tasksCacheTimeMs) >= TASKS_CACHE_TTL_MS then
        timeText, horseLines, mapLines, companionData, craftingLines = BuildRightTooltipDescription()
        tasksCacheTimeText = timeText
        tasksCacheHorseLines = horseLines
        tasksCacheMapLines = mapLines
        tasksCacheCompanionData = companionData
        tasksCacheCraftingLines = craftingLines
        tasksCacheTimeMs = nowMs
        tasksCacheDirty = false
    end

    GAMEPAD_TOOLTIPS:LayoutTasksTooltip(rightTooltip, nil, timeText, horseLines, mapLines, companionData, craftingLines)
end

local function RegisterCacheInvalidationEvent(namespace, eventCode)
    if eventCode then
        EVENT_MANAGER:RegisterForEvent(namespace, eventCode, Tasks.InvalidateCache)
    end
end

EVENT_MANAGER:RegisterForEvent("GPH_OverviewTasks_Cache", EVENT_ADD_ON_LOADED, function(_, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("GPH_OverviewTasks_Cache", EVENT_ADD_ON_LOADED)

    EVENT_MANAGER:RegisterForEvent("GPH_OverviewTasks_PlayerActivated", EVENT_PLAYER_ACTIVATED, function()
        EVENT_MANAGER:UnregisterForEvent("GPH_OverviewTasks_PlayerActivated", EVENT_PLAYER_ACTIVATED)
        EnsureCompanionTrackerState()
        EnsureDailyWritTrackerState()
        EnsureDailyQuestTrackerState()
        Tasks.RefreshDailyQuestTrackerState()
        Tasks.InvalidateCache()
        ScheduleDailyResetRefresh()
    end)

    RegisterCacheInvalidationEvent("GPH_OverviewTasks_InventoryCache", EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
    RegisterCacheInvalidationEvent("GPH_OverviewTasks_ResearchCompletedCache", EVENT_SMITHING_TRAIT_RESEARCH_COMPLETED)
    RegisterCacheInvalidationEvent("GPH_OverviewTasks_ResearchStartedCache", EVENT_SMITHING_TRAIT_RESEARCH_STARTED)
    RegisterCacheInvalidationEvent("GPH_OverviewTasks_StableCache", EVENT_MOUNT_INFO_UPDATED)
    RegisterCacheInvalidationEvent("GPH_OverviewTasks_QuestAddedCache", EVENT_QUEST_ADDED)
    RegisterCacheInvalidationEvent("GPH_OverviewTasks_QuestAdvancedCache", EVENT_QUEST_ADVANCED)

    if EVENT_QUEST_ADDED then
        EVENT_MANAGER:RegisterForEvent("GPH_OverviewTasks_DailyWritQuestAdded", EVENT_QUEST_ADDED, Tasks.OnQuestStateChanged)
    end
    if EVENT_QUEST_ADVANCED then
        EVENT_MANAGER:RegisterForEvent("GPH_OverviewTasks_DailyWritQuestAdvanced", EVENT_QUEST_ADVANCED, Tasks.OnQuestStateChanged)
    end
    if EVENT_QUEST_REMOVED then
        EVENT_MANAGER:RegisterForEvent("GPH_OverviewTasks_QuestRemoved", EVENT_QUEST_REMOVED, Tasks.OnQuestRemoved)
    end
end)
