local ADDON_NAME = "GamePadHelper_Overview"
local ADDON_VERSION = 1.03

-- GamePadHelper_Overview Addon
-- Manages tooltips in the main menu, switching positions when chat slider is active.

local GamePadHelper_Overview = {}

-- Global flag for chat faded state
local isChatFaded = false


-- =============================================================================
-- CONFIGURATION
-- =============================================================================

-- Constants for tooltip text content
local LEFT_TOOLTIP_TEXT = "Left Tooltip: Welcome to the Main Menu!"
local RIGHT_TOOLTIP_TEXT = "Right Tooltip: Use this menu to navigate."

-- Data from GamePadHelper_Overview
local CRAFTING = {
  [CRAFTING_TYPE_BLACKSMITHING] = {questId = 5377},
  [CRAFTING_TYPE_CLOTHIER] = {questId = 5374},
  [CRAFTING_TYPE_ENCHANTING] = {questId = 5407},
  [CRAFTING_TYPE_ALCHEMY] = {questId = 6105},
  [CRAFTING_TYPE_JEWELRYCRAFTING] = {questId = 6228},
  [CRAFTING_TYPE_PROVISIONING] = {questId = 5414},
  [CRAFTING_TYPE_WOODWORKING] = {questId = 5395}
}

local function GetResearhLineInfo(craftingType, researchLineIndex, numTraits)
    local areAllTraitsKnown = true
    for traitIndex = 1, numTraits do
        local traitType, _, known = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)

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
  local hasUnknownTraits = false
  for researchLineIndex = 1, GetNumSmithingResearchLines(craftingType) do
    local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
    if numTraits > 0 then
        local researchingTraitIndex, areAllTraitsKnown = GetResearhLineInfo(craftingType, researchLineIndex, numTraits)
        if researchingTraitIndex then
            current = current + 1
        end
        if not areAllTraitsKnown then
          hasUnknownTraits = true
        end
    end
  end

  -- Only return available slots if player has both available slots AND unknown traits
  local availableSlots = maximum - current
  if availableSlots > 0 and hasUnknownTraits then
    return current, availableSlots
  else
    return current, 0
  end
end

-- Function to count scryable antiquities and find minimum lead expiration time
local function GetScryableAntiquitiesInfo()
  local totalLeads = 0
  local currentZoneLeads = 0
  local totalMinTimeRemaining = nil
  local currentZoneMinTimeRemaining = nil
  local urgentZoneName = nil
  local currentZoneId = ZO_ExplorationUtils_GetPlayerCurrentZoneId()

  local antiquityId = GetNextAntiquityId()
  while antiquityId do
    local antiquityData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)

    -- Check if this antiquity has a lead and meets skill requirements (global count)
    if antiquityData:HasLead() and antiquityData:MeetsScryingSkillRequirements() and not antiquityData:HasAchievedAllGoals() then
      totalLeads = totalLeads + 1

      -- Check if it's in current zone for zone-specific count
      if antiquityData:IsInZone(currentZoneId) then
        currentZoneLeads = currentZoneLeads + 1
      end
    end

    -- Check lead expiration time for all antiquities with expiring leads
    local timeRemaining = antiquityData:GetLeadTimeRemainingS()
    if timeRemaining and timeRemaining > 0 then
      -- Track global minimum time and zone
      if totalMinTimeRemaining == nil or timeRemaining < totalMinTimeRemaining then
        totalMinTimeRemaining = timeRemaining
        urgentZoneName = GetZoneNameById(antiquityData:GetZoneId())
      end

      -- Track current zone minimum time
      if antiquityData:IsInZone(currentZoneId) then
        if currentZoneMinTimeRemaining == nil or timeRemaining < currentZoneMinTimeRemaining then
          currentZoneMinTimeRemaining = timeRemaining
        end
      end
    end

    antiquityId = GetNextAntiquityId(antiquityId)
  end
  return totalLeads, currentZoneLeads, totalMinTimeRemaining, currentZoneMinTimeRemaining, urgentZoneName
end

-- Helper function to format time in days, hours, minutes with color coding
local function FormatTimeRemaining(seconds)
  if not seconds or seconds <= 0 then return "" end
  local days = math.floor(seconds / 86400)
  local hours = math.floor((seconds % 86400) / 3600)
  local minutes = math.floor((seconds % 3600) / 60)
  local timeString = ""

  if days > 0 then
    -- If days are present, show days and hours only (no minutes)
    timeString = timeString .. days .. "d "
    if hours > 0 then timeString = timeString .. hours .. "h " end
  else
    -- If no days, show hours and minutes
    if hours > 0 then timeString = timeString .. hours .. "h " end
    if minutes > 0 then timeString = timeString .. minutes .. "m" end
  end

  -- Remove trailing space
  timeString = timeString:gsub("%s+$", "")

  -- Color coding based on time remaining
  local totalDays = seconds / 86400
  if totalDays <= 3 then
    -- Red for less than 3 days - matches urgent color
    return "|cCC4C4C" .. timeString .. "|r"
  elseif totalDays <= 7 then
    -- Yellow for less than 7 days
    return "|cFFFF00" .. timeString .. "|r"
  else
    -- Default color for more than 7 days
    return "|cFFFFFF" .. timeString .. "|r"
  end
end


-- =============================================================================
-- TOOLTIP MANAGEMENT FUNCTIONS
-- =============================================================================

-- Core tooltip functions for showing and hiding tooltips
local function ShowTooltips()
    -- Clear both possible right tooltip positions
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD3_TOOLTIP)

    local questIndex = QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex()
    local questName, backgroundText, activeStepText, activeStepType, activeStepOverrideText = GetJournalQuestInfo(questIndex)
    local questDescription = string.format("|cDAA520%s|r\n\n%s\n\n%s", questName, backgroundText, activeStepText)

    -- Add quest tasks
    local questStrings = {}
    local fakeQuestJournal = {questStrings = questStrings}
    ZO_ClearNumericallyIndexedTable(questStrings)
    QUEST_JOURNAL_MANAGER:BuildTextForTasks(activeStepOverrideText, questIndex, questStrings)
    local taskText = ""
    for key, value in ipairs(questStrings) do
        if not value.isComplete then
            taskText = taskText .. "\n• " .. value.name
        end
    end
    if taskText ~= "" then
        questDescription = questDescription .. "\n\n|cDAA520Tasks:|r" .. taskText
    end

    -- Add optional steps
    ZO_ClearNumericallyIndexedTable(questStrings)
    ZO_QuestJournal_Shared.BuildTextForStepVisibility(fakeQuestJournal, questIndex, QUEST_STEP_VISIBILITY_OPTIONAL)
    if #questStrings > 0 then
        questDescription = questDescription .. "\n\n|cDAA520Optional:|r"
        for index = 1, #questStrings do
            questDescription = questDescription .. "\n|cAAAAAA• " .. questStrings[index] .. "|r"
        end
    end

    -- Add hints
    ZO_ClearNumericallyIndexedTable(questStrings)
    ZO_QuestJournal_Shared.BuildTextForStepVisibility(fakeQuestJournal, questIndex, QUEST_STEP_VISIBILITY_HINT)
    if #questStrings > 0 then
        questDescription = questDescription .. "\n\n|cDAA520Hints:|r"
        for index = 1, #questStrings do
            questDescription = questDescription .. "\n|cAAAAAA• " .. questStrings[index] .. "|r"
        end
    end

    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, "|c57A64EQuest|r", questDescription)

    -- Determine tooltip position based on chat faded state
    local rightTooltip = isChatFaded and GAMEPAD_RIGHT_TOOLTIP or GAMEPAD_QUAD3_TOOLTIP

    local tasksDescription = ""

    -- Check for urgent antiquity timers first (show at very top)
    local totalCount, currentZoneCount, totalMinTime, currentZoneMinTime, urgentZoneName = GetScryableAntiquitiesInfo()
    local isUrgent = totalMinTime and (totalMinTime / 86400) <= 3
    if isUrgent then
        local zoneText = urgentZoneName and (" in |cFFFF00" .. urgentZoneName .. "|r") or ""
        tasksDescription = tasksDescription .. "|cCC4C4CURGENT:|r\n   Lead" .. zoneText .. " expires in " .. FormatTimeRemaining(totalMinTime) .. "\n\n"
    end

    -- horse training reminder
    local horseTrainingTimeRemaining = GetTimeUntilCanBeTrained()
    local speedBonus, maxSpeedBonus, staminaBonus, maxStaminaBonus, inventoryBonus, maxInventoryBonus = STABLE_MANAGER:GetStats()
    if horseTrainingTimeRemaining == 0 and ((speedBonus < maxSpeedBonus) or (staminaBonus < maxStaminaBonus) or (inventoryBonus < maxInventoryBonus)) then
        tasksDescription = tasksDescription .. "|cDAA520Horse Training:|r Available\n\n"
    end

    -- crafting research reminder
    local hasCrafting = false
    for craftingType, craft in ipairs(CRAFTING) do
        local current, max = GetResearchInfo(craftingType)
        local count = max
        if count > 0 then
            if not hasCrafting then
                tasksDescription = tasksDescription .. "|cDAA520Crafting Research:|r\n"
                hasCrafting = true
            end
            local craftText = GetCraftingSkillName(craftingType)
            local researchText = zo_strformat("<<1[Research/Research/Researches]>>", count)
            local text = string.format("|cFFFFFF%s|r %s %s Available", count, craftText, researchText)
            tasksDescription = tasksDescription .. text .. "\n"
        end
    end
    if hasCrafting then
        tasksDescription = tasksDescription .. "\n"
    end

    -- antiquities scryable count and lead expiration timer
    if totalCount > 0 or currentZoneCount > 0 then
        -- Main leads line with total count and timer
        local totalTimeString = ""
        if totalMinTime and not isUrgent then
            totalTimeString = " (" .. FormatTimeRemaining(totalMinTime) .. ")"
        end
        tasksDescription = tasksDescription .. "|cDAA520Leads:|r\n|cFFFFFF" .. totalCount .. "|r Scryable" .. totalTimeString .. "\n"

        if currentZoneCount > 0 then
            -- Current zone always shows timer with colors
            local currentTimeString = ""
            if currentZoneMinTime then
                currentTimeString = " (" .. FormatTimeRemaining(currentZoneMinTime) .. ")"
            end
            tasksDescription = tasksDescription .. "   |cFFFFFF" .. currentZoneCount .. "|r in This Zone" .. currentTimeString .. "\n"
        end
        tasksDescription = tasksDescription .. "\n"
    end

    if tasksDescription == "" then
        tasksDescription = "Access daily tasks, achievements, and other activities."
    end

    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(rightTooltip, "|cDAA520Tasks|r", tasksDescription)
end

local function HideTooltips()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end



-- =============================================================================
-- ADDON INITIALIZATION
-- =============================================================================

-- Initialize the addon by registering callbacks
function GamePadHelper_Overview:Initialize()
    -- Set initial chat faded state
    if GAMEPAD_CHAT_SYSTEM and GAMEPAD_CHAT_SYSTEM:IsMinimized() then
        isChatFaded = true
    else
        isChatFaded = false
    end

    SCENE_MANAGER:RegisterCallback("SceneStateChanged", function(scene, oldState, newState)
        if scene:GetName() == "mainMenuGamepad" then
            if newState == SCENE_SHOWING then
                ShowTooltips()
            elseif newState == SCENE_HIDING then
                HideTooltips()
            end
        end
    end)

    if GAMEPAD_CHAT_SYSTEM then
        local originalMinimize = GAMEPAD_CHAT_SYSTEM.Minimize
        GAMEPAD_CHAT_SYSTEM.Minimize = function(self, ...)
            isChatFaded = true
            local result = originalMinimize(self, ...)
            if SCENE_MANAGER:IsShowing("mainMenuGamepad") then
                ShowTooltips()
            end
            return result
        end

        local originalMaximize = GAMEPAD_CHAT_SYSTEM.Maximize
        GAMEPAD_CHAT_SYSTEM.Maximize = function(self, ...)
            isChatFaded = false
            local result = originalMaximize(self, ...)
            if SCENE_MANAGER:IsShowing("mainMenuGamepad") then
                ShowTooltips()
            end
            return result
        end
    end
end

-- Start the addon
GamePadHelper_Overview:Initialize()
