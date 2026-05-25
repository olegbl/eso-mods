-- DungeonFinder
-- Enhanced dungeon finder with pledge quest highlighting

local NAVIGATION_MODE_ENTRY_LIST = 3
local pledgeQuestList = nil

local function NormalizeText(value)
    value = zo_strlower(value or "")
    value = value:gsub("[%p]", " ")
    value = value:gsub("%s+", " ")
    return zo_strtrim(value)
end

local function BuildPledgeQuestList()
    local list = {}
    for i = 1, MAX_JOURNAL_QUESTS do
        if IsValidQuestIndex(i) then
            local questName = zo_strformat("<<1>>", GetJournalQuestName(i) or "")
            local normalized = NormalizeText(questName)
            if normalized ~= "" then
                list[#list + 1] = { normalized = normalized, questName = questName }
            end
        end
    end
    return list
end

local function GetPledgeQuestList()
    if not pledgeQuestList then
        pledgeQuestList = BuildPledgeQuestList()
    end
    return pledgeQuestList
end

local function InvalidatePledgeQuestList()
    pledgeQuestList = nil
end

local function FindPledgeQuestForDungeon(pledgeQuests, dungeonName, rawName)
    for _, quest in ipairs(pledgeQuests) do
        if quest.normalized:find(dungeonName, 1, true) then
            if not string.match(rawName, " I$") or not string.match(quest.questName, "II") then
                return quest.questName
            end
        end
    end
    return nil
end

local function ShowPledgeDungeons()
    local savedVars = _G["GamePadHelper_SavedVars"]
    if not savedVars or not savedVars.dungeonFinderEnabled then return end

    if not DUNGEON_FINDER_GAMEPAD:IsShowing() or DUNGEON_FINDER_GAMEPAD.navigationMode ~= NAVIGATION_MODE_ENTRY_LIST then
        return false
    end

    local isSearching = IsCurrentlySearchingForGroup()
    local modes = DUNGEON_FINDER_GAMEPAD.dataManager:GetFilterModeData()
    local lockReasonTextOverride = DUNGEON_FINDER_GAMEPAD:GetGlobalLockText()

    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RebuildSelections( {DUNGEON_FINDER_GAMEPAD.currentSpecificActivityType } )
    local locationData = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(DUNGEON_FINDER_GAMEPAD.currentSpecificActivityType)

    local pledgeQuests = GetPledgeQuestList()

    local function AddLocationEntry(location, overrideName)
        local entryData = ZO_GamepadEntryData:New(location:GetNameGamepad(), DUNGEON_FINDER_GAMEPAD.categoryData.menuIcon)
        entryData.data = location
        entryData.data:SetLockReasonTextOverride(lockReasonTextOverride)
        entryData:SetEnabled(not location:IsLocked() and not isSearching)
        entryData:SetSelected(location:IsSelected())
        entryData:SetText(overrideName)
        DUNGEON_FINDER_GAMEPAD.entryList:AddEntryAtIndex(2, "ZO_GamepadItemSubEntryTemplate", entryData)
    end

    for _, location in ipairs(locationData) do
        if modes:IsEntryTypeVisible(location:GetEntryType()) and not location:HasRewardData() then
            local rawName     = zo_strformat("<<1>>", location.rawName or "")
            local dungeonName = NormalizeText(rawName)
            if dungeonName ~= "" then
                local questName = FindPledgeQuestForDungeon(pledgeQuests, dungeonName, rawName)
                if questName then
                    AddLocationEntry(location, questName)
                end
            end
        end
    end

    return false
end

local function OnAddonLoaded(event, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("DungeonFinder", EVENT_ADD_ON_LOADED)
    EVENT_MANAGER:RegisterForEvent("DungeonFinder_QuestAdded", EVENT_QUEST_ADDED, InvalidatePledgeQuestList)
    EVENT_MANAGER:RegisterForEvent("DungeonFinder_QuestRemoved", EVENT_QUEST_REMOVED, InvalidatePledgeQuestList)
    ZO_PreHook(DUNGEON_FINDER_GAMEPAD.entryList, "Commit", ShowPledgeDungeons)
end

EVENT_MANAGER:RegisterForEvent("DungeonFinder", EVENT_ADD_ON_LOADED, OnAddonLoaded)
