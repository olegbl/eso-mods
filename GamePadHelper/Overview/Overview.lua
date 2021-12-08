local ADDON_NAME = "GamePadHelper_Overview"
local ADDON_VERSION = 1.01

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
            if durationSecs then
                return traitIndex, areAllTraitsKnown
            end
        end
    end
    return nil, areAllTraitsKnown
end

local function GetResearchInfo(craftingType)
  local maximum = GetMaxSimultaneousSmithingResearch(craftingType)
  local current = 0
  local available = false
  for researchLineIndex = 1, GetNumSmithingResearchLines(craftingType) do
    local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
    if numTraits > 0 then
        local researchingTraitIndex, areAllTraitsKnown = GetResearhLineInfo(craftingType, researchLineIndex, numTraits)
        if researchingTraitIndex then
            current = current + 1
        end
        if not areAllTraitsKnown then
          available = true
        end
    end
  end
  return current, available and maximum or 0
end

local function LayoutTooltip(self)
  -- https://github.com/esoui/esoui/blob/master/esoui/common/tooltip/tooltipstyles.lua

  -- title
  --local topSection = self:AcquireSection(self:GetStyle("topSection"))
  --topSection:AddLine("Overview", self:GetStyle("title"))
  --self:AddSectionEvenIfEmpty(topSection)

  -- daily / recurring tasks
  local tasksSection = self:AcquireSection(self:GetStyle("bodySection"))
  local isTasksLabelAdded = false
  local function AddTask(text, style)
    if not isTasksLabelAdded then
      tasksSection:AddLine("Tasks", self:GetStyle("title"))
      isTasksLabelAdded = true
    end
    tasksSection:AddLine(text, style)
  end

  -- horse training reminder
  local horseTrainingTimeRemaining = GetTimeUntilCanBeTrained()
  if horseTrainingTimeRemaining == 0 then
    local text = string.format("Horse Training Available")
    AddTask(text, self:GetStyle("bodyDescription"))
  end

  -- crafting research reminder
  for craftingType, craft in ipairs(CRAFTING) do
    local current, max = GetResearchInfo(craftingType)
    local count = max - current
    if count > 0 then
      local craftText = GetCraftingSkillName(craftingType)
      local researchText = zo_strformat("<<1[Research/Research/Researches]>>", count)
      local text = string.format("|cFFFFFF%s|r %s %s Available", count, craftText, researchText)
      AddTask(text, self:GetStyle("bodyDescription"))
    end
  end

  -- crafting writ reminder
  -- TODO: doesn't seem to be possible to distinguish unaccepted vs completed?

  self:AddSection(tasksSection)

  -- quest
  local questSection = self:AcquireSection(self:GetStyle("bodySection"))
  questSection:AddLine("Quest", self:GetStyle("title"))
  local questIndex = QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex()
  local questName, backgroundText, activeStepText, activeStepType, activeStepOverrideText = GetJournalQuestInfo(questIndex)
  questSection:AddLine(questName, self:GetStyle("bodyHeader"))
  questSection:AddLine(backgroundText, self:GetStyle("bodyDescription"))
  questSection:AddLine(activeStepText, self:GetStyle("bodyDescription"))

  local questStrings = {}
  local fakeQuestJournal = {questStrings = questStrings}
  
  questSection:AddLine("Tasks", self:GetStyle("bodyHeader"))
  ZO_ClearNumericallyIndexedTable(questStrings)
  QUEST_JOURNAL_MANAGER:BuildTextForTasks(activeStepOverrideText, questIndex, questStrings)
  for key, value in ipairs(questStrings) do
    if not value.isComplete then
      questSection:AddLine(value.name, self:GetStyle("bodyDescription"))
    end
  end


  ZO_ClearNumericallyIndexedTable(questStrings)
  ZO_QuestJournal_Shared.BuildTextForStepVisibility(fakeQuestJournal, questIndex, QUEST_STEP_VISIBILITY_OPTIONAL)
  if #questStrings > 0 then
    questSection:AddLine("Optional", self:GetStyle("bodyHeader"))
  end
  for index = 1, #questStrings do
    questSection:AddLine(questStrings[index], self:GetStyle("bodyDescription"))
  end

  ZO_ClearNumericallyIndexedTable(questStrings)
  ZO_QuestJournal_Shared.BuildTextForStepVisibility(fakeQuestJournal, questIndex, QUEST_STEP_VISIBILITY_HINT)
  if #questStrings > 0 then
    questSection:AddLine("Hints", self:GetStyle("bodyHeader"))
  end
  for index = 1, #questStrings do
    questSection:AddLine(questStrings[index], self:GetStyle("bodyDescription"))
  end

  self:AddSection(questSection)
end

local function MainMenuManager_Gamepad_OnSelectionChanged_After(self, list, selectedData, oldSelectedData)
  if not self:IsShowing() then return end
  if list ~= self.mainList then return end

  -- TODO: use zo_tooltip_gamepad.lua's LayoutFunction instead
  --       of manually messing with SCENE_MANAGER
  
  local fragmentGroup = {
    GAMEPAD_TOOLTIPS:GetTooltipFragment(GAMEPAD_LEFT_TOOLTIP),
    GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT 
  }

  local showFragmentGroupNew = selectedData and not selectedData.data.fragmentGroupCallback
  local showFragmentGroupOld = oldSelectedData and not oldSelectedData.data.fragmentGroupCallback

  if showFragmentGroupNew and not showFragmentGroupOld then
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
    LayoutTooltip(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP))
    SCENE_MANAGER:AddFragmentGroup(fragmentGroup)
  elseif not showFragmentGroupNew and showFragmentGroupOld then
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
    SCENE_MANAGER:RemoveFragmentGroup(fragmentGroup)
  end
end

ZO_PostHook(SYSTEMS:GetGamepadObject("mainMenu"), "OnSelectionChanged", MainMenuManager_Gamepad_OnSelectionChanged_After)
