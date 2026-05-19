local Overview = {}

-- On console GAMEPAD_CHAT_SYSTEM is absent; treat as faded so the full
-- GAMEPAD_RIGHT_TOOLTIP slot is used for the tasks panel.
local isChatFaded = (GAMEPAD_CHAT_SYSTEM == nil)

local CRAFTING = {
  CRAFTING_TYPE_BLACKSMITHING,
  CRAFTING_TYPE_CLOTHIER,
  CRAFTING_TYPE_ENCHANTING,
  CRAFTING_TYPE_ALCHEMY,
  CRAFTING_TYPE_JEWELRYCRAFTING,
  CRAFTING_TYPE_PROVISIONING,
  CRAFTING_TYPE_WOODWORKING
}


local gphActiveBulletControls = {}
local gphOverviewDeferredRefreshQueued = false
local gphOverviewQuestIndexOverride = nil
local gphOverviewKeybindDescriptor = nil
local gphOverviewOwnsLeftPanel = false

local function GetValidQuestIndices()
  local indices = {}
  for i = 1, MAX_JOURNAL_QUESTS do
    if IsValidQuestIndex(i) then
      table.insert(indices, i)
    end
  end
  return indices
end

local function GetOverviewQuestIndex()
  if gphOverviewQuestIndexOverride and IsValidQuestIndex and IsValidQuestIndex(gphOverviewQuestIndexOverride) then
    return gphOverviewQuestIndexOverride
  end
  gphOverviewQuestIndexOverride = nil
  return nil
end

local function EnsureTooltipBulletList(tooltip, key, labelTemplate, secondaryBulletTemplate)
  tooltip.gphBulletLists = tooltip.gphBulletLists or {}
  local entry = tooltip.gphBulletLists[key]
  if not entry then
    local controlName = "GPHOverviewBulletList_" .. tostring(key or "default")
    local control = _G[controlName]
    if not control then
      control = WINDOW_MANAGER:CreateControl(controlName, tooltip, CT_CONTROL)
    else
      control:SetParent(tooltip)
    end
    control:SetHidden(true)
    local list = ZO_BulletList:New(control, labelTemplate or "GPH_OverviewBulletLabel", nil, secondaryBulletTemplate)
    list:SetLinePaddingY(8)
    list:SetBulletPaddingX(16)
    entry = { control = control, list = list }
    tooltip.gphBulletLists[key] = entry
  end
  return entry.control, entry.list
end

local function AddBulletListSection(tooltip, lines, headerText, lineColor, listKey, secondaryBulletTemplate)
  if not lines or #lines == 0 then return end

  local headerSection = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
  headerSection:AddLine(headerText, tooltip:GetStyle("bodyDescription"))
  tooltip:AddSection(headerSection)

  local control, bulletList = EnsureTooltipBulletList(tooltip, listKey or "gphTasks", "GPH_OverviewBulletLabel", secondaryBulletTemplate)
  bulletList:Clear()

  local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_3)
  for _, line in ipairs(lines) do
    local text = lineColor and lineColor ~= "" and (lineColor .. line .. "|r") or line
    bulletList:AddLine(text)
    if (not lineColor or lineColor == "") and bulletList.lastLabel then
      bulletList.lastLabel:SetColor(r, g, b, 1)
    end
  end

  local width = tooltip:GetWidth()
  if not width or width <= 0 then width = 420 end
  control:SetWidth(width - 40)
  control:SetHidden(false)

  -- Wrapped bullet lines can exceed control:GetHeight(); measure actual used height.
  local usedHeight = 0
  local controlTop = control:GetTop()
  for i = 1, control:GetNumChildren() do
    local child = control:GetChild(i)
    if child and not child:IsHidden() then
      local childBottom = child:GetBottom()
      if controlTop and childBottom then
        usedHeight = math.max(usedHeight, childBottom - controlTop)
      end
    end
  end
  if usedHeight <= 0 then
    usedHeight = control:GetHeight()
  end
  control:SetHeight(math.max(1, zo_ceil(usedHeight) + 8))
  table.insert(gphActiveBulletControls, control)

  local section = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
  section:AddControl(control, control:GetHeight() + 12, control:GetWidth())
  tooltip:AddSection(section)
end

function ZO_Tooltip:LayoutGPHQuestOverviewTooltip(title, questName, backgroundText, activeStepText, taskLines, completedLines, optionalLines, hintLines)
  local titleSection = self:AcquireSection(self:GetStyle("bodyHeader"))
  titleSection:AddLine(title, self:GetStyle("title"))
  self:AddSection(titleSection)

  local nameSection = self:AcquireSection(self:GetStyle("bodySection"))
  nameSection:AddLine("|cDAA520" .. questName .. "|r", self:GetStyle("bodyDescription"))
  self:AddSection(nameSection)

  if backgroundText and backgroundText ~= "" then
    local bgSection = self:AcquireSection(self:GetStyle("bodySection"))
    bgSection:AddLine(backgroundText, self:GetStyle("bodyDescription"))
    self:AddSection(bgSection)
  end

  if activeStepText and activeStepText ~= "" then
    local stepSection = self:AcquireSection(self:GetStyle("bodySection"))
    stepSection:AddLine(activeStepText, self:GetStyle("bodyDescription"))
    self:AddSection(stepSection)
  end

  AddBulletListSection(self, taskLines,      "|cDAA520" .. GetString(SI_GPH_OVERVIEW_TASKS_LABEL)     .. "|r", nil,       "gphTasks")
  AddBulletListSection(self, completedLines, "|cDAA520" .. GetString(SI_GPH_OVERVIEW_COMPLETED_LABEL) .. "|r", "|c9D9D9D", "gphCompleted", "ZO_QuestJournal_CompletedTaskIcon_Gamepad")
  AddBulletListSection(self, optionalLines,  "|cDAA520" .. GetString(SI_GPH_OVERVIEW_OPTIONAL_LABEL)  .. "|r", "|cAAAAAA", "gphOptional")
  AddBulletListSection(self, hintLines,      "|cDAA520" .. GetString(SI_GPH_OVERVIEW_HINTS_LABEL)     .. "|r", "|cAAAAAA", "gphHints")
end

local function GetBestQuestIndex()
  local overridden = GetOverviewQuestIndex()
  if overridden then
    return overridden
  end

  local questIndex = QUEST_JOURNAL_MANAGER and QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex() or nil
  if questIndex and IsValidQuestIndex and IsValidQuestIndex(questIndex) then
    return questIndex
  end

  for i = 1, MAX_JOURNAL_QUESTS do
    if IsValidQuestIndex(i) then
      local _, _, _, _, _, _, tracked = GetJournalQuestInfo(i)
      if tracked then
        return i
      end
    end
  end

  for i = 1, MAX_JOURNAL_QUESTS do
    if IsValidQuestIndex(i) then
      return i
    end
  end

  return nil
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

-- Returns: researchableTraits, researchableItems, currentResearching, availableSlots
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
                table.insert(researchableTraitList, {researchLineIndex = researchLineIndex, traitIndex = traitIndex})
              end
            end
          end
        end
    end
  end

  if #researchableTraitList > 0 then
    for _, traitInfo in ipairs(researchableTraitList) do
      local hasItem = false

      for slotIndex = 0, GetBagSize(BAG_BACKPACK) - 1 do
        if GetItemId(BAG_BACKPACK, slotIndex) > 0 then
          if CanItemBeSmithingTraitResearched(BAG_BACKPACK, slotIndex, craftingType, traitInfo.researchLineIndex, traitInfo.traitIndex) then
            hasItem = true
            break
          end
        end
      end

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

-- Returns: treasureCount, totalSurveyCount, totalWritCount
local function CountAllInventoryItems()
  local treasureCount = 0
  local totalSurveyCount = 0
  local totalWritCount = 0
  local treasureKeyword = zo_strlower(GetString(SI_GPH_OVERVIEW_KEYWORD_TREASURE) or "")
  local mapKeyword = zo_strlower(GetString(SI_GPH_OVERVIEW_KEYWORD_MAP) or "")
  local surveyKeyword = zo_strlower(GetString(SI_GPH_OVERVIEW_KEYWORD_SURVEY) or "")
  local writKeyword = zo_strlower(GetString(SI_GPH_OVERVIEW_KEYWORD_WRIT) or "")

  local function NameContains(name, keyword)
    return keyword ~= "" and name:find(keyword, 1, true) ~= nil
  end

  for bagId = BAG_BACKPACK, BAG_SUBSCRIBER_BANK do
    for slotIndex = 0, GetBagSize(bagId) - 1 do
      if GetItemId(bagId, slotIndex) > 0 then
        local itemName = GetItemName(bagId, slotIndex)
        if itemName then
          local itemNameLower = zo_strlower(itemName)

          if NameContains(itemNameLower, treasureKeyword) and NameContains(itemNameLower, mapKeyword) then
            treasureCount = treasureCount + GetSlotStackSize(bagId, slotIndex)
          elseif NameContains(itemNameLower, surveyKeyword) then
            totalSurveyCount = totalSurveyCount + GetSlotStackSize(bagId, slotIndex)
          elseif NameContains(itemNameLower, writKeyword) then
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

local function ShowTooltips()
    local sv = _G["GamePadHelper_SavedVars"]
    if not sv or not sv.overviewEnabled then return end

    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD3_TOOLTIP)
    gphOverviewOwnsLeftPanel = true

    local questIndex = GetBestQuestIndex()
    if not questIndex then
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(
            GAMEPAD_LEFT_TOOLTIP,
            "|c57A64E" .. GetString(SI_GPH_OVERVIEW_QUEST) .. "|r",
            GetString(SI_GPH_OVERVIEW_TASKS_AVAILABLE)
        )
        return
    end

    local questName, backgroundText, activeStepText, _, activeStepOverrideText = GetJournalQuestInfo(questIndex)

    local taskLines = {}
    local completedLines = {}

    if activeStepOverrideText and activeStepOverrideText ~= "" then
        table.insert(taskLines, activeStepOverrideText)
    else
        local conditionCount = GetJournalQuestNumConditions(questIndex, QUEST_MAIN_STEP_INDEX)
        for i = 1, conditionCount do
            local conditionText, currentCount, maxCount, isFailCondition, isComplete, _, isVisible =
                GetJournalQuestConditionInfo(questIndex, QUEST_MAIN_STEP_INDEX, i)
            if isVisible and not isFailCondition and conditionText ~= "" then
                if isComplete then
                    table.insert(completedLines, conditionText)
                elseif maxCount > 0 and currentCount >= maxCount then
                    table.insert(taskLines, "|c9D9D9D" .. conditionText .. "|r")
                else
                    table.insert(taskLines, conditionText)
                end
            end
        end
    end

    local questStrings = {}
    local fakeQuestJournal = {questStrings = questStrings}

    ZO_QuestJournal_Shared.BuildTextForStepVisibility(fakeQuestJournal, questIndex, QUEST_STEP_VISIBILITY_OPTIONAL)
    local optionalLines = {}
    for _, v in ipairs(questStrings) do table.insert(optionalLines, v.name) end

    ZO_ClearNumericallyIndexedTable(questStrings)
    ZO_QuestJournal_Shared.BuildTextForStepVisibility(fakeQuestJournal, questIndex, QUEST_STEP_VISIBILITY_HINT)
    local hintLines = {}
    for _, v in ipairs(questStrings) do table.insert(hintLines, v.name) end

    GAMEPAD_TOOLTIPS:LayoutGPHQuestOverviewTooltip(
        GAMEPAD_LEFT_TOOLTIP,
        "|c57A64E" .. GetString(SI_GPH_OVERVIEW_QUEST) .. "|r",
        zo_strformat("<<C:1>>", questName or ""),
        backgroundText or "",
        activeStepText or "",
        taskLines,
        completedLines,
        optionalLines,
        hintLines
    )

    local rightTooltip = isChatFaded and GAMEPAD_RIGHT_TOOLTIP or GAMEPAD_QUAD3_TOOLTIP

    local tasksDescription = ""

    local totalCount, totalMinTime, urgentZoneName = GetScryableAntiquitiesInfo()
    local isUrgent = totalMinTime and (totalMinTime / 86400) <= 3
    if isUrgent then
        local zoneText = urgentZoneName and zo_strformat(GetString(SI_GPH_OVERVIEW_IN_ZONE), "|cFFFF00" .. urgentZoneName .. "|r") or ""
        tasksDescription = tasksDescription .. "|cCC4C4C" .. GetString(SI_GPH_OVERVIEW_URGENT) .. "|r\n   " .. zo_strformat(GetString(SI_GPH_OVERVIEW_LEAD_EXPIRES), zoneText, FormatTimeRemaining(totalMinTime)) .. "\n\n"
    end

    local horseTrainingTimeRemaining = GetTimeUntilCanBeTrained()
    local speedBonus, maxSpeedBonus, staminaBonus, maxStaminaBonus, inventoryBonus, maxInventoryBonus = STABLE_MANAGER:GetStats()
    if horseTrainingTimeRemaining == 0 and ((speedBonus < maxSpeedBonus) or (staminaBonus < maxStaminaBonus) or (inventoryBonus < maxInventoryBonus)) then
        tasksDescription = tasksDescription .. "|cDAA520" .. GetString(SI_GPH_OVERVIEW_HORSE_TRAINING) .. "|r " .. GetString(SI_GPH_OVERVIEW_AVAILABLE) .. "\n\n"
    end

    local hasCrafting = false
    local treasureCount, totalSurveyCount, totalWritCount = CountAllInventoryItems()

    if totalSurveyCount > 0 or totalWritCount > 0 then
        local craftingCountersText = ""
        if totalSurveyCount > 0 then
            craftingCountersText = craftingCountersText .. " |cFFFFFF" .. totalSurveyCount .. "|r " .. GetString(SI_GPH_OVERVIEW_SURVEY)
        end
        if totalSurveyCount > 0 and totalWritCount > 0 then
            craftingCountersText = craftingCountersText .. " -"
        end
        if totalWritCount > 0 then
            craftingCountersText = craftingCountersText .. " |cFFFFFF" .. totalWritCount .. "|r " .. GetString(SI_GPH_OVERVIEW_WRIT)
        end
        tasksDescription = tasksDescription .. "|cDAA520" .. GetString(SI_GPH_OVERVIEW_CRAFTING) .. "|r" .. craftingCountersText .. "\n\n"
        hasCrafting = true
    end

    for _, craftingType in ipairs(CRAFTING) do
        local researchableTraits, researchableItems, _, availableSlots = GetResearchInfo(craftingType)
        local craftText = zo_strformat("<<C:1>>", GetCraftingSkillName(craftingType))

        if GetNumSmithingResearchLines(craftingType) == 0 then
            local hasSkill = false
            if craftingType == CRAFTING_TYPE_PROVISIONING or craftingType == CRAFTING_TYPE_ENCHANTING or craftingType == CRAFTING_TYPE_ALCHEMY then
                local targetSkillName = zo_strlower(zo_strformat("<<1>>", GetCraftingSkillName(craftingType) or ""))
                -- GetSkillLineName is a PC-only alias; use GetSkillLineNameById on console
                local function SafeGetSkillLineName(skillType, skillLineIndex)
                    if GetSkillLineName then return GetSkillLineName(skillType, skillLineIndex) end
                    local id = GetSkillLineId and GetSkillLineId(skillType, skillLineIndex)
                    return id and GetSkillLineNameById and GetSkillLineNameById(id)
                end
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
                 if not hasCrafting then
                     hasCrafting = true
                 end
                 tasksDescription = tasksDescription .. "|cDAA520" .. craftText .. ":|r\n  " .. GetString(SI_GPH_OVERVIEW_VISIT_STATION) .. "\n\n"
             end
         elseif researchableTraits > 0 and availableSlots > 0 then
             if not hasCrafting then
                 hasCrafting = true
             end
             local slotText = availableSlots > 0 and string.format(" |c00FF00%d|r %s", availableSlots, zo_strformat(GetString(SI_GPH_OVERVIEW_AVAILABLE_SLOTS), zo_strformat("<<1[slot/slots/slots]>>", availableSlots), "")) or ""
             local text = string.format("  |cFFFFFF%d|r/|cFFFFFF%d|r %s%s", researchableTraits, researchableItems, GetString(SI_GPH_OVERVIEW_RESEARCHABLE), slotText)
             tasksDescription = tasksDescription .. "|cDAA520" .. craftText .. ":|r\n" .. text .. "\n"
         end
     end
    if hasCrafting then
        tasksDescription = tasksDescription .. "\n"
    end

    if totalCount > 0 then
        local totalTimeString = ""
        if totalMinTime and not isUrgent then
            totalTimeString = " (" .. FormatTimeRemaining(totalMinTime) .. ")"
        end
        tasksDescription = tasksDescription .. "|cDAA520" .. GetString(SI_GPH_OVERVIEW_LEADS) .. "|r |cFFFFFF" .. totalCount .. "|r " .. GetString(SI_GPH_OVERVIEW_SCRYABLE) .. totalTimeString .. "\n"
    end

    if treasureCount > 0 then
        tasksDescription = tasksDescription .. "|cDAA520" .. GetString(SI_GPH_OVERVIEW_TREASURE) .. "|r |cFFFFFF" .. treasureCount .. "|r " .. GetString(SI_GPH_OVERVIEW_MAPS) .. "\n"
    end

    if totalCount > 0 or treasureCount > 0 then
        tasksDescription = tasksDescription .. "\n\n"
    end

    if tasksDescription == "" then
        tasksDescription = GetString(SI_GPH_OVERVIEW_TASKS_AVAILABLE)
    end

    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(rightTooltip, "|cDAA520" .. GetString(SI_GPH_OVERVIEW_TASKS) .. "|r", tasksDescription)
end

local function HideTooltips()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    gphOverviewOwnsLeftPanel = false
    for _, control in ipairs(gphActiveBulletControls) do
        control:SetHidden(true)
    end
    ZO_ClearNumericallyIndexedTable(gphActiveBulletControls)
end

local function QueueOverviewRefresh()
    if gphOverviewDeferredRefreshQueued then return end
    gphOverviewDeferredRefreshQueued = true
    zo_callLater(function()
        gphOverviewDeferredRefreshQueued = false
        local sv = _G["GamePadHelper_SavedVars"]
        if sv and sv.overviewEnabled and SCENE_MANAGER:IsShowing("mainMenuGamepad") then
            ShowTooltips()
        end
    end, 1)
end

local function RefreshOverviewIfVisible()
    local sv = _G["GamePadHelper_SavedVars"]
    if sv and sv.overviewEnabled and SCENE_MANAGER:IsShowing("mainMenuGamepad") then
        ShowTooltips()
        QueueOverviewRefresh()
    end
end

local function ShouldShowOverviewQuestKeybinds()
    local sv = _G["GamePadHelper_SavedVars"]
    if not (sv and sv.overviewEnabled and SCENE_MANAGER:IsShowing("mainMenuGamepad")) then
        return false
    end

    if #GetValidQuestIndices() <= 1 then
        return false
    end

    if MAIN_MENU_GAMEPAD then
        if MAIN_MENU_GAMEPAD.activeHelperPanel then
            return false
        end

        local list = MAIN_MENU_GAMEPAD.GetCurrentList and MAIN_MENU_GAMEPAD:GetCurrentList()
        local targetData = list and list.GetTargetData and list:GetTargetData()
        local entryData = targetData and targetData.data

        -- If selected entry provides custom selection behavior, avoid interfering with its keybind UX.
        if entryData and (entryData.keybindStripDescriptor or entryData.customKeybindStripDescriptor) then
            return false
        end
    end

    if not gphOverviewOwnsLeftPanel then
        return false
    end

    return true
end

local function SelectedEntryOwnsLeftPanel()
    if not MAIN_MENU_GAMEPAD then
        return false
    end

    local list = MAIN_MENU_GAMEPAD.GetCurrentList and MAIN_MENU_GAMEPAD:GetCurrentList()
    local targetData = list and list.GetTargetData and list:GetTargetData()
    local entryData = targetData and targetData.data
    if not entryData then
        return false
    end

    -- In the gamepad main menu, entries that implement onSelectedCallback commonly manage
    -- helper/tooltip content. If present, prefer native left-panel behavior.
    return entryData.onSelectedCallback ~= nil
end

local function ReapplyOverviewTooltipSoon()
    zo_callLater(function()
        if not SelectedEntryOwnsLeftPanel() then
            RefreshOverviewIfVisible()
        else
            gphOverviewOwnsLeftPanel = false
        end
        if gphOverviewKeybindDescriptor then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(gphOverviewKeybindDescriptor)
        end
    end, 1)
end

local function CycleOverviewQuest(step)
  local validIndices = GetValidQuestIndices()
  if #validIndices <= 1 then return end

  step = step or 1
  local current = GetBestQuestIndex()
  local pos = 1
  for i, idx in ipairs(validIndices) do
    if idx == current then
      pos = i
      break
    end
  end

  local nextPos = pos + step
  while nextPos > #validIndices do nextPos = nextPos - #validIndices end
  while nextPos < 1 do nextPos = nextPos + #validIndices end

  gphOverviewQuestIndexOverride = validIndices[nextPos]

  -- Keep native quest state in sync with overview cycling.
  local questIndex = gphOverviewQuestIndexOverride
  if ZO_ZoneStories_Manager and ZO_ZoneStories_Manager.SetTrackedZoneStoryAssisted then
    ZO_ZoneStories_Manager.SetTrackedZoneStoryAssisted(false)
  end
  if FOCUSED_QUEST_TRACKER and FOCUSED_QUEST_TRACKER.ForceAssist then
    FOCUSED_QUEST_TRACKER:ForceAssist(questIndex)
  end

  RefreshOverviewIfVisible()
end


function Overview:Initialize()
    -- re-evaluate: on PC check actual minimized state; on console always faded (no GAMEPAD_CHAT_SYSTEM)
    isChatFaded = not GAMEPAD_CHAT_SYSTEM or GAMEPAD_CHAT_SYSTEM:IsMinimized()

    gphOverviewKeybindDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_QUATERNARY",
            name = function()
                return GetString(SI_GPH_OVERVIEW_KEYBIND_PREV_QUEST)
            end,
            visible = function()
                return ShouldShowOverviewQuestKeybinds()
            end,
            callback = function()
                CycleOverviewQuest(-1)
            end,
        },
        {
            keybind = "UI_SHORTCUT_QUINARY",
            name = function()
                return GetString(SI_GPH_OVERVIEW_KEYBIND_NEXT_QUEST)
            end,
            visible = function()
                return ShouldShowOverviewQuestKeybinds()
            end,
            callback = function()
                CycleOverviewQuest(1)
            end,
        },
    }

    SCENE_MANAGER:RegisterCallback("SceneStateChanged", function(scene, oldState, newState)
        if scene:GetName() == "mainMenuGamepad" then
            if newState == SCENE_SHOWING then
                ShowTooltips()
                QueueOverviewRefresh()
                if gphOverviewKeybindDescriptor then
                    KEYBIND_STRIP:AddKeybindButtonGroup(gphOverviewKeybindDescriptor)
                    KEYBIND_STRIP:UpdateKeybindButtonGroup(gphOverviewKeybindDescriptor)
                end
            elseif newState == SCENE_HIDING then
                HideTooltips()
                if gphOverviewKeybindDescriptor then
                    KEYBIND_STRIP:RemoveKeybindButtonGroup(gphOverviewKeybindDescriptor)
                end
            end
        end
    end)

    if GAMEPAD_CHAT_SYSTEM then
        ZO_PostHook(GAMEPAD_CHAT_SYSTEM, "Minimize", function()
            isChatFaded = true
            RefreshOverviewIfVisible()
        end)

        ZO_PostHook(GAMEPAD_CHAT_SYSTEM, "Maximize", function()
            isChatFaded = false
            RefreshOverviewIfVisible()
        end)
    end

    -- React to native quest cycling/focus changes (including d-pad cycle quest behavior).
    if QUEST_JOURNAL_MANAGER then
        if QUEST_JOURNAL_MANAGER.SetFocusedQuestIndex then
            ZO_PostHook(QUEST_JOURNAL_MANAGER, "SetFocusedQuestIndex", function()
                RefreshOverviewIfVisible()
            end)
        end
        if QUEST_JOURNAL_MANAGER.SetTrackedQuestIndex then
            ZO_PostHook(QUEST_JOURNAL_MANAGER, "SetTrackedQuestIndex", function()
                RefreshOverviewIfVisible()
            end)
    end

    -- Main menu entries can clear/replace GAMEPAD_LEFT_TOOLTIP in their OnSelectionChanged callbacks.
    -- Reapply our overview tooltip right after selection changes.
    if MAIN_MENU_GAMEPAD and MAIN_MENU_GAMEPAD.OnSelectionChanged then
        ZO_PostHook(MAIN_MENU_GAMEPAD, "OnSelectionChanged", function()
            ReapplyOverviewTooltipSoon()
            if gphOverviewKeybindDescriptor then
                KEYBIND_STRIP:UpdateKeybindButtonGroup(gphOverviewKeybindDescriptor)
            end
        end)
    end
end

end

EVENT_MANAGER:RegisterForEvent("Overview", EVENT_ADD_ON_LOADED, function(_, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("Overview", EVENT_ADD_ON_LOADED)
    Overview:Initialize()
end)
