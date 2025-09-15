local ADDON_NAME = "LibCovetousCountess"
local ADDON_VERSION = 1.00

-- Ensure ESO API compatibility
if GetAPIVersion() < 101047 then return end

LibCovetousCountess = {}

-- TODO: figure out a way to solve potential localization issues
local TAGS = {
  -- levels 1-15, 50
  ["Games"] = 1,
  ["Dolls"] = 1,
  ["Statues"] = 1,
  -- levels 16-24, 50
  ["Ritual Objects"] = 2,
  ["Oddities"] = 2,
  -- levels 25-30, 50
  ["Writings"] = 3,
  ["Maps"] = 3,
  ["Scrivener Supplies"] = 3,
  -- levels 31-37, 50
  ["Cosmetics"] = 4,
  ["Linens"] = 4,
  ["Wardrobe Accessories"] = 4,
  -- levels 38-50
  ["Drinkware"] = 5,
  ["Utensils"] = 5,
  ["Dishes and Cookware"] = 5
}

local currentQuestType = 0

function LibCovetousCountess:UpdateQuestInfo()
  currentQuestType = 0
  local questNameTCC = GetCompletedQuestInfo(5584)
  if questNameTCC ~= nil then
    local numQuests = GetNumJournalQuests()
    for journalIndex = 1, numQuests do
      local questName, backgroundText, activeStepText = GetJournalQuestInfo(journalIndex)
      if questName == questNameTCC then
        -- TODO: figure out a way to solve potential localization issues
        if string.find(activeStepText, "games") then
          currentQuestType = 1
        elseif string.find(activeStepText, "ritual") then
          currentQuestType = 2
        elseif string.find(activeStepText, "writings and maps") then
          currentQuestType = 3
        elseif string.find(activeStepText, "cosmetics") then
          currentQuestType = 4
        elseif string.find(activeStepText, "drinkware, utensils, and dishes") then
          currentQuestType = 5
        end
      end
    end
  end
end

function LibCovetousCountess:IsItemUseful(itemLink)
  if itemLink == nil then
    return false, false
  end
  
  local numItemTags = GetItemLinkNumItemTags(itemLink)
  local isUsefulForAnyQuest = false
  if numItemTags > 0 then 
    for itemTagIndex = 1, numItemTags do
      local itemTagDescription = GetItemLinkItemTagInfo(itemLink, itemTagIndex)
      local itemTagString = zo_strformat(SI_TOOLTIP_ITEM_TAG_FORMATER, itemTagDescription)  
      if TAGS[itemTagString] == currentQuestType then
        return true, true -- used in active quest
      elseif TAGS[itemTagString] ~= nil then
        isUsefulForAnyQuest = true -- used in other quest
      end
    end
  end

  return false, isUsefulForAnyQuest  -- not used in any quest
end

local function OnQuestAdded(eventCode, journalIndex, questName, objectiveName)
  LibCovetousCountess:UpdateQuestInfo()
end

local function OnQuestComplete(eventCode, questName, level, previousExperience, currentExperience, rank, previousPoints, currentPoints)
  LibCovetousCountess:UpdateQuestInfo()
end

local function OnQuestRemoved(eventCode, isQuestCompleted, journalIndex, questName, zoneIndex, poiIndex)
  LibCovetousCountess:UpdateQuestInfo()
end

local function OnPlayerActivated(eventCode)
  EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED)
  LibCovetousCountess:UpdateQuestInfo()
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_QUEST_ADDED, OnQuestAdded)
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_QUEST_COMPLETE, OnQuestComplete)
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_QUEST_REMOVED, OnQuestRemoved)
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

