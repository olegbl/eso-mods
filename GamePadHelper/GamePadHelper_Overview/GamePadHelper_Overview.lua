-- =============================================================================
-- ADDON HEADER
-- =============================================================================

local ADDON_NAME = "GamePadHelper_Overview"
local ADDON_VERSION = 1.03

-- GamePadHelper_Overview Addon
-- Enhanced tooltips in the main menu showing crafting research, surveys, antiquities, and treasure maps
-- Manages tooltip positioning when chat slider is active

local GamePadHelper_Overview = {}

-- Global flag for chat faded state
local isChatFaded = false


-- =============================================================================
-- CONFIGURATION
-- =============================================================================

-- Crafting profession types
local CRAFTING = {
  CRAFTING_TYPE_BLACKSMITHING,
  CRAFTING_TYPE_CLOTHIER,
  CRAFTING_TYPE_ENCHANTING,
  CRAFTING_TYPE_ALCHEMY,
  CRAFTING_TYPE_JEWELRYCRAFTING,
  CRAFTING_TYPE_PROVISIONING,
  CRAFTING_TYPE_WOODWORKING
}


-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

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
-- DATA COLLECTION FUNCTIONS
-- =============================================================================

-- Get information about a research line (finds currently researching trait)
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

-- Get research information for a crafting type
-- Returns: researchableTraits, researchableItems, currentResearching, availableSlots
local function GetResearchInfo(craftingType)
  local maximum = GetMaxSimultaneousSmithingResearch(craftingType)
  local current = 0
  local researchableTraits = 0
  local researchableItems = 0

  -- Collect researchable traits (unknown and not researching)
  local researchableTraitList = {}
  for researchLineIndex = 1, GetNumSmithingResearchLines(craftingType) do
    local _, _, numTraits = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
    if numTraits > 0 then
        local researchingTraitIndex, areAllTraitsKnown = GetResearhLineInfo(craftingType, researchLineIndex, numTraits)
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
                table.insert(researchableTraitList, {researchLineIndex = researchLineIndex, traitIndex = traitIndex})
              end
            end
          end
        end
    end
  end

  -- Count researchable traits that have items available
  if #researchableTraitList > 0 then
    for _, traitInfo in ipairs(researchableTraitList) do
      local hasItem = false

      -- Check backpack
      for slotIndex = 0, GetBagSize(BAG_BACKPACK) - 1 do
        if GetItemId(BAG_BACKPACK, slotIndex) > 0 then
          if CanItemBeSmithingTraitResearched(BAG_BACKPACK, slotIndex, craftingType, traitInfo.researchLineIndex, traitInfo.traitIndex) then
            hasItem = true
            break
          end
        end
      end

      -- Check bank if not found in backpack
      if not hasItem then
        for slotIndex = 0, GetBagSize(BAG_BANK) - 1 do
          if GetItemId(BAG_BANK, slotIndex) > 0 then
            if CanItemBeSmithingTraitResearched(BAG_BANK, slotIndex, craftingType, traitInfo.researchLineIndex, traitInfo.traitIndex) then
              hasItem = true
              break
            end
          end
        end
      end

      -- Check subscriber bank if not found
      if not hasItem then
        for slotIndex = 0, GetBagSize(BAG_SUBSCRIBER_BANK) - 1 do
          if GetItemId(BAG_SUBSCRIBER_BANK, slotIndex) > 0 then
            if CanItemBeSmithingTraitResearched(BAG_SUBSCRIBER_BANK, slotIndex, craftingType, traitInfo.researchLineIndex, traitInfo.traitIndex) then
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

-- Consolidated function to count all inventory items in one pass
-- Returns: treasureCount, totalSurveyCount, totalWritCount
local function CountAllInventoryItems()
  local treasureCount = 0
  local totalSurveyCount = 0
  local totalWritCount = 0

  -- Single pass through all bags
  for bagId = BAG_BACKPACK, BAG_SUBSCRIBER_BANK do
    for slotIndex = 0, GetBagSize(bagId) - 1 do
      if GetItemId(bagId, slotIndex) > 0 then
        local itemName = GetItemName(bagId, slotIndex)
        if itemName then
          local itemNameLower = itemName:lower()

          -- Count treasure maps
          if itemNameLower:find("treasure") and itemNameLower:find("map") then
            treasureCount = treasureCount + GetSlotStackSize(bagId, slotIndex)
          -- Count all surveys and writs (simplified - no profession matching needed)
          elseif itemNameLower:find("survey") then
            totalSurveyCount = totalSurveyCount + GetSlotStackSize(bagId, slotIndex)
          elseif itemNameLower:find("writ") then
            totalWritCount = totalWritCount + GetSlotStackSize(bagId, slotIndex)
          end
        end
      end
    end
  end

  return treasureCount, totalSurveyCount, totalWritCount
end

-- Count scryable antiquities and find minimum lead expiration time
local function GetScryableAntiquitiesInfo()
  local totalLeads = 0
  local totalMinTimeRemaining = nil
  local urgentZoneName = nil

  local antiquityId = GetNextAntiquityId()
  while antiquityId do
    local antiquityData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)

    -- Check if this antiquity has a lead and meets skill requirements (global count)
    if antiquityData:HasLead() and antiquityData:MeetsScryingSkillRequirements() and not antiquityData:HasAchievedAllGoals() then
      totalLeads = totalLeads + 1
    end

    -- Check lead expiration time for all antiquities with expiring leads
    local timeRemaining = antiquityData:GetLeadTimeRemainingS()
    if timeRemaining and timeRemaining > 0 then
      -- Track global minimum time and zone
      if totalMinTimeRemaining == nil or timeRemaining < totalMinTimeRemaining then
        totalMinTimeRemaining = timeRemaining
        urgentZoneName = GetZoneNameById(antiquityData:GetZoneId())
      end
    end

    antiquityId = GetNextAntiquityId(antiquityId)
  end
  return totalLeads, totalMinTimeRemaining, urgentZoneName
end

-- =============================================================================
-- TOOLTIP MANAGEMENT FUNCTIONS
-- =============================================================================

-- Main function to display tooltips with all game information
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
    local completedTasks = ""
    for key, value in ipairs(questStrings) do
        if not value.isComplete then
            taskText = taskText .. "\n• " .. value.name
        else
            completedTasks = completedTasks .. "\n|c9D9D9D~~" .. value.name .. "~~|r"
        end
    end
    if taskText ~= "" then
        questDescription = questDescription .. "\n\n|cDAA520Tasks:|r" .. taskText
    end
    if completedTasks ~= "" then
        questDescription = questDescription .. "\n\n|cDAA520Completed:|r" .. completedTasks
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
    local totalCount, totalMinTime, urgentZoneName = GetScryableAntiquitiesInfo()
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
    local treasureCount, totalSurveyCount, totalWritCount = CountAllInventoryItems()

    -- Add main crafting header with total counts
    if totalSurveyCount > 0 or totalWritCount > 0 then
        local craftingCountersText = ""
        if totalSurveyCount > 0 then
            craftingCountersText = craftingCountersText .. " |cFFFFFF" .. totalSurveyCount .. "|r Survey"
        end
        if totalSurveyCount > 0 and totalWritCount > 0 then
            craftingCountersText = craftingCountersText .. " -"
        end
        if totalWritCount > 0 then
            craftingCountersText = craftingCountersText .. " |cFFFFFF" .. totalWritCount .. "|r Writ"
        end
        tasksDescription = tasksDescription .. "|cDAA520Crafting:|r" .. craftingCountersText .. "\n"
        hasCrafting = true
    end

    -- Second pass: show individual profession research info
    for _, craftingType in ipairs(CRAFTING) do
        local researchableTraits, researchableItems, current, availableSlots = GetResearchInfo(craftingType)
        local craftText = GetCraftingSkillName(craftingType)

        if GetNumSmithingResearchLines(craftingType) == 0 then
            -- For non-smithing skills, check if player has the skill
            local hasSkill = false
            if craftingType == CRAFTING_TYPE_PROVISIONING or craftingType == CRAFTING_TYPE_ENCHANTING or craftingType == CRAFTING_TYPE_ALCHEMY then
                -- Check if player has these crafting skills
                for skillCategory = 1, GetNumSkillTypes() do
                    for skillLine = 1, GetNumSkillLines(skillCategory) do
                        local skillLineName = GetSkillLineName(skillCategory, skillLine)
                        if skillLineName then
                            if (craftingType == CRAFTING_TYPE_PROVISIONING and skillLineName:lower():find("provisioning")) or
                                (craftingType == CRAFTING_TYPE_ENCHANTING and skillLineName:lower():find("enchanting")) or
                                (craftingType == CRAFTING_TYPE_ALCHEMY and skillLineName:lower():find("alchemy")) then
                                 hasSkill = true
                                 break
                             end
                         end
                     end
                     if hasSkill then break end
                 end
             end

             if not hasSkill then
                 -- Player doesn't have this crafting skill
                 if not hasCrafting then
                     hasCrafting = true
                 end
                 tasksDescription = tasksDescription .. "|cDAA520" .. craftText .. ":|r\n  Visit crafting station\n"
             end
             -- Don't show empty entries for non-smithing professions that player has
         elseif researchableTraits > 0 and availableSlots > 0 then
             if not hasCrafting then
                 hasCrafting = true
             end
             local slotText = availableSlots > 0 and string.format(" |c00FF00%d|r %s avaliable", availableSlots, zo_strformat("<<1[slot/slots/slots]>>", availableSlots)) or ""
             local text = string.format("  |cFFFFFF%d|r/|cFFFFFF%d|r Reseachable%s", researchableTraits, researchableItems, slotText)
             tasksDescription = tasksDescription .. "|cDAA520" .. craftText .. ":|r\n" .. text .. "\n"
         end
     end
    if hasCrafting then
        tasksDescription = tasksDescription .. "\n"
    end

    -- antiquities scryable count and lead expiration timer
    if totalCount > 0 then
        -- Main leads line with total count and timer
        local totalTimeString = ""
        if totalMinTime and not isUrgent then
            totalTimeString = " (" .. FormatTimeRemaining(totalMinTime) .. ")"
        end
        tasksDescription = tasksDescription .. "|cDAA520Leads:|r |cFFFFFF" .. totalCount .. "|r scryable" .. totalTimeString .. "\n"
    end

    -- treasure maps count
    if treasureCount > 0 then
        tasksDescription = tasksDescription .. "|cDAA520Treasure:|r |cFFFFFF" .. treasureCount .. "|r maps\n"
    end

    if totalCount > 0 or treasureCount > 0 then
        tasksDescription = tasksDescription .. "\n\n"
    end

    if tasksDescription == "" then
        tasksDescription = "Access daily tasks, achievements, and other activities."
    end

    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(rightTooltip, "|cDAA520Tasks|r", tasksDescription)
end

-- Hide all tooltips when menu is closed
local function HideTooltips()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end


-- =============================================================================
-- ADDON INITIALIZATION
-- =============================================================================

-- Initialize the addon by registering scene callbacks and chat system hooks
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
