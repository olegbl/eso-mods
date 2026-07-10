GPH_Overview = GPH_Overview or {}
GPH_Overview.Quest = GPH_Overview.Quest or {}

local Quest = GPH_Overview.Quest
local activeBulletControls = {}
local QUEST_HEADER_ICON = "|t48:48:EsoUI/Art/Journal/Gamepad/gp_trackedquesticon.dds|t"

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
  local spacerSection = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
  spacerSection:AddLine(" ", tooltip:GetStyle("bodyDescription"))
  tooltip:AddSection(spacerSection)
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
  table.insert(activeBulletControls, control)

  local section = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
  section:AddControl(control, control:GetHeight() + 12, control:GetWidth())
  tooltip:AddSection(section)
end

local function AddQuestStringLine(lines, value)
  local text = type(value) == "table" and value.name or value
  if text and text ~= "" then
    table.insert(lines, text)
  end
end

function ZO_Tooltip:LayoutGPHQuestOverviewTooltip(title, questName, backgroundText, activeStepText, taskLines, completedLines, optionalLines, hintLines)
  AddTitledDividerSection(self, title, QUEST_HEADER_ICON)

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

  AddBlockSpacingSection(self)
  AddBulletListSection(self, hintLines,      "|cDAA520" .. GetString(SI_GPH_OVERVIEW_HINTS_LABEL)     .. "|r", "|cAAAAAA", "gphHints")
  AddBulletListSection(self, taskLines,      "|cDAA520" .. GetString(SI_GPH_OVERVIEW_TASKS_LABEL)     .. "|r", nil,       "gphTasks")
  AddBulletListSection(self, optionalLines,  "|cDAA520" .. GetString(SI_GPH_OVERVIEW_OPTIONAL_LABEL)  .. "|r", "|cAAAAAA", "gphOptional")
  AddBulletListSection(self, completedLines, "|cDAA520" .. GetString(SI_GPH_OVERVIEW_COMPLETED_LABEL) .. "|r", "|c9D9D9D", "gphCompleted", "ZO_QuestJournal_CompletedTaskIcon_Gamepad")
end

function Quest.HideControls()
  for _, control in ipairs(activeBulletControls) do
    control:SetHidden(true)
  end
  ZO_ClearNumericallyIndexedTable(activeBulletControls)
end

function Quest.GetValidQuestIndices()
  local indices = {}
  for i = 1, MAX_JOURNAL_QUESTS do
    if IsValidQuestIndex(i) then
      table.insert(indices, i)
    end
  end
  return indices
end

local function GetValidQuestCount()
  local count = 0
  for i = 1, MAX_JOURNAL_QUESTS do
    if IsValidQuestIndex(i) then
      count = count + 1
      if count > 1 then return count end
    end
  end
  return count
end

local function GetOverviewQuestIndex(state)
  if state.questIndexOverride and IsValidQuestIndex and IsValidQuestIndex(state.questIndexOverride) then
    return state.questIndexOverride
  end
  state.questIndexOverride = nil
  return nil
end

function Quest.GetBestQuestIndex(state)
  local questIndex = QUEST_JOURNAL_MANAGER and QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex() or nil
  if questIndex and IsValidQuestIndex and IsValidQuestIndex(questIndex) then
    state.questIndexOverride = nil
    return questIndex
  end

  for i = 1, MAX_JOURNAL_QUESTS do
    if IsValidQuestIndex(i) then
      local _, _, _, _, _, _, tracked = GetJournalQuestInfo(i)
      if tracked then
        state.questIndexOverride = nil
        return i
      end
    end
  end

  local overridden = GetOverviewQuestIndex(state)
  if overridden then
    return overridden
  end

  for i = 1, MAX_JOURNAL_QUESTS do
    if IsValidQuestIndex(i) then
      return i
    end
  end

  return nil
end

function Quest.ShowLeftTooltip(state)
  local questIndex = Quest.GetBestQuestIndex(state)
  if not questIndex then
    return false
  end

  local questName, backgroundText, activeStepText, _, activeStepOverrideText = GetJournalQuestInfo(questIndex)

  local taskLines = {}
  local completedLines = {}
  local questStrings = {}
  local fakeQuestJournal = { questStrings = questStrings }

  QUEST_JOURNAL_MANAGER:BuildTextForTasks(activeStepOverrideText, questIndex, questStrings)
  for _, v in ipairs(questStrings) do
    local text = v and v.name
    if text and text ~= "" then
      if v.isComplete then
        table.insert(completedLines, text)
      else
        table.insert(taskLines, text)
      end
    end
  end
  ZO_ClearNumericallyIndexedTable(questStrings)

  ZO_QuestJournal_Shared.BuildTextForStepVisibility(fakeQuestJournal, questIndex, QUEST_STEP_VISIBILITY_OPTIONAL)
  local optionalLines = {}
  for _, v in ipairs(questStrings) do
    AddQuestStringLine(optionalLines, v)
  end

  ZO_ClearNumericallyIndexedTable(questStrings)
  ZO_QuestJournal_Shared.BuildTextForStepVisibility(fakeQuestJournal, questIndex, QUEST_STEP_VISIBILITY_HINT)
  local hintLines = {}
  for _, v in ipairs(questStrings) do
    AddQuestStringLine(hintLines, v)
  end

  GAMEPAD_TOOLTIPS:LayoutGPHQuestOverviewTooltip(
    GAMEPAD_LEFT_TOOLTIP,
    GetString(SI_GPH_OVERVIEW_QUEST),
    zo_strformat("<<C:1>>", questName or ""),
    backgroundText or "",
    activeStepText or "",
    taskLines,
    completedLines,
    optionalLines,
    hintLines
  )

  return true
end

function Quest.ShouldShowKeybinds(state)
  local sv = _G["GamePadHelper_CharSavedVars"]
  if not (sv and sv.overviewEnabled and SCENE_MANAGER:IsShowing("mainMenuGamepad")) then
    return false
  end

  if GetValidQuestCount() <= 1 then
    return false
  end

  if MAIN_MENU_GAMEPAD then
    if MAIN_MENU_GAMEPAD.activeHelperPanel then
      return false
    end

    local list = MAIN_MENU_GAMEPAD.GetCurrentList and MAIN_MENU_GAMEPAD:GetCurrentList()
    local targetData = list and list.GetTargetData and list:GetTargetData()
    local entryData = targetData and targetData.data
    if entryData and (entryData.keybindStripDescriptor or entryData.customKeybindStripDescriptor) then
      return false
    end
  end

  return state.ownsLeftPanel == true
end

function Quest.SelectedEntryOwnsLeftPanel()
  if not MAIN_MENU_GAMEPAD then
    return false
  end

  local list = MAIN_MENU_GAMEPAD.GetCurrentList and MAIN_MENU_GAMEPAD:GetCurrentList()
  local targetData = list and list.GetTargetData and list:GetTargetData()
  local entryData = targetData and targetData.data
  if not entryData then
    return false
  end

  return entryData.onSelectedCallback ~= nil
end

function Quest.OnNativeQuestSelectionChanged(state, refreshCallback)
  state.questIndexOverride = nil
  refreshCallback()
end

function Quest.OnNativeQuestAssistChanged(state, questIndex, refreshCallback)
  state.questIndexOverride = nil
  if questIndex and IsValidQuestIndex and IsValidQuestIndex(questIndex) then
    state.questIndexOverride = questIndex
  end
  refreshCallback()
end

function Quest.CycleQuest(state, step, refreshCallback)
  local validIndices = Quest.GetValidQuestIndices()
  if #validIndices <= 1 then return end

  step = step or 1
  local current = Quest.GetBestQuestIndex(state)
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

  state.questIndexOverride = validIndices[nextPos]

  if ZO_ZoneStories_Manager and ZO_ZoneStories_Manager.SetTrackedZoneStoryAssisted then
    ZO_ZoneStories_Manager.SetTrackedZoneStoryAssisted(false)
  end
  if FOCUSED_QUEST_TRACKER and FOCUSED_QUEST_TRACKER.ForceAssist then
    FOCUSED_QUEST_TRACKER:ForceAssist(state.questIndexOverride)
  end

  refreshCallback()
end
