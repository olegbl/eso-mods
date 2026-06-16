local ADDON_NAME = "LibCovetousCountess"
local ADDON_VERSION = 1.03

-- Ensure ESO API compatibility
if GetAPIVersion() < 101047 then return end

LibCovetousCountess = {}

local TREASURE_TYPE_CATEGORY = 1
local COUNTESS_QUEST_ID = 5584

local COUNTESS_TAGS = {
  en = {
    [1] = { ["Games"] = true, ["Dolls"] = true, ["Statues"] = true },
    [2] = { ["Ritual Objects"] = true, ["Oddities"] = true, ["Magic Curiosities"] = true },
    [3] = { ["Writings"] = true, ["Maps"] = true, ["Scrivener Supplies"] = true },
    [4] = { ["Cosmetics"] = true, ["Dry Goods"] = true, ["Wardrobe Accessories"] = true },
    [5] = { ["Drinkware"] = true, ["Utensils"] = true, ["Dishes and Cookware"] = true },
  },
  de = {
    [1] = { ["Spiele"] = true, ["Puppen"] = true, ["Statuen"] = true },
    [2] = { ["Ritualgegenstände"] = true, ["Kuriositäten"] = true, ["Magische Kuriositäten"] = true },
    [3] = { ["Schriften"] = true, ["Karten"] = true, ["Schreiberbedarf"] = true },
    [4] = { ["Kosmetika"] = true, ["Trockenwaren"] = true, ["Schmuckstücke"] = true },
    [5] = { ["Trinkgefäße"] = true, ["Utensilien"] = true, ["Teller und Kochgeschirr"] = true },
  },
  es = {
    [1] = { ["Juegos"] = true, ["Muñecos"] = true, ["Estatuas"] = true },
    [2] = { ["Objetos ceremoniales"] = true, ["Rarezas"] = true, ["Curiosidades mágicas"] = true },
    [3] = { ["Escritos"] = true, ["Mapas"] = true, ["Materiales de escribano"] = true },
    [4] = { ["Estéticos"] = true, ["Productos secos"] = true, ["Accesorios de armario"] = true },
    [5] = { ["Cristalería"] = true, ["Utensilios"] = true, ["Utensilios de cocina"] = true },
  },
  fr = {
    [1] = { ["Jeux"] = true, ["Poupées"] = true, ["Statues"] = true },
    [2] = { ["Objets rituels"] = true, ["Curiosités"] = true, ["Curiosités magiques"] = true },
    [3] = { ["Écrits"] = true, ["Cartes"] = true, ["Fournitures de scribe"] = true },
    [4] = { ["Produits cosmétiques"] = true, ["Denrées sèches"] = true, ["Accessoires vestimentaires"] = true },
    [5] = { ["Récipients à boire"] = true, ["Ustensiles"] = true, ["Plats et moules"] = true },
  },
  ru = {
    [1] = { ["игры"] = true, ["куклы"] = true, ["статуэтки"] = true },
    [2] = { ["ритуальные объекты"] = true, ["диковины"] = true, ["магические диковинки"] = true },
    [3] = { ["сочинения"] = true, ["карты"] = true, ["писчие принадлежности"] = true },
    [4] = { ["косметика"] = true, ["ткани"] = true, ["аксессуары"] = true },
    [5] = {
      ["посуда для напитков"] = true,
      ["утварь"] = true,
      ["приборы"] = true,
      ["посуда и кухонные принадлежности"] = true,
    },
  },
  jp = {
    [1] = { ["遊具"] = true, ["人形"] = true, ["像"] = true },
    [2] = { ["儀式用品"] = true, ["珍品"] = true, ["魔法の珍品"] = true },
    [3] = { ["書物"] = true, ["マップ"] = true, ["筆記用具"] = true },
    [4] = { ["化粧品"] = true, ["生地"] = true, ["ワードローブ用品"] = true },
    [5] = { ["飲み物用食器"] = true, ["調理器具"] = true, ["食器と調理用具"] = true },
  },
  zh = {
    [1] = { ["游戏"] = true, ["玩偶"] = true, ["雕像"] = true },
    [2] = { ["仪式物品"] = true, ["奇异物品"] = true, ["魔法新奇之物"] = true },
    [3] = { ["文字"] = true, ["地图"] = true, ["公证人补给"] = true },
    [4] = { ["装扮品"] = true, ["干制物品"] = true, ["衣橱配饰"] = true },
    [5] = { ["饮具"] = true, ["餐具"] = true, ["餐盘和厨具"] = true },
  },
}

local CROW_TAGS = {
  en = {
    leisure = { ["Games"] = true, ["Children's Toys"] = true, ["Toys"] = true },
    tributes = { ["Cosmetics"] = true, ["Grooming Items"] = true },
    respect = { ["Drinkware"] = true, ["Utensils"] = true, ["Dishes and Cookware"] = true },
  },
  de = {
    leisure = { ["Spiele"] = true, ["Kinderspielzeug"] = true },
    tributes = { ["Kosmetika"] = true, ["Körperpflegegegenstände"] = true },
    respect = { ["Trinkgefäße"] = true, ["Utensilien"] = true, ["Teller und Kochgeschirr"] = true },
  },
  es = {
    leisure = { ["Juegos"] = true, ["Juegos infantiles"] = true },
    tributes = { ["Estéticos"] = true, ["Objetos de aseo"] = true },
    respect = { ["Cristalería"] = true, ["Utensilios"] = true, ["Utensilios de cocina"] = true },
  },
  fr = {
    leisure = { ["Jeux"] = true, ["Jouets d'enfants"] = true },
    tributes = { ["Produits cosmétiques"] = true, ["Ustensiles de toilette"] = true },
    respect = { ["Récipients à boire"] = true, ["Ustensiles"] = true, ["Plats et moules"] = true },
  },
  ru = {
    leisure = { ["игры"] = true, ["детские игрушки"] = true },
    tributes = { ["косметика"] = true, ["предметы для ухода"] = true },
    respect = {
      ["посуда для напитков"] = true,
      ["утварь"] = true,
      ["приборы"] = true,
      ["посуда и кухонные принадлежности"] = true,
    },
  },
  jp = {
    leisure = { ["遊具"] = true, ["子供のおもちゃ"] = true },
    tributes = { ["化粧品"] = true, ["身だしなみ用品"] = true },
    respect = { ["飲み物用食器"] = true, ["調理器具"] = true, ["食器と調理用具"] = true },
  },
  zh = {
    leisure = { ["游戏"] = true, ["儿童玩具"] = true },
    tributes = { ["装扮品"] = true, ["刷洗物品"] = true },
    respect = { ["饮具"] = true, ["餐具"] = true, ["餐盘和厨具"] = true },
  },
}

local QUEST_FRAGMENTS = {
  en = {
    [1] = { "games" },
    [2] = { "ritual" },
    [3] = { "writings", "maps" },
    [4] = { "cosmetics" },
    [5] = { "drinkware", "utensils", "dishes" },
  },
  de = {
    [1] = { "spiel" },
    [2] = { "ritual" },
    [3] = { "schrift", "karte" },
    [4] = { "kosmet" },
    [5] = { "trink", "utens", "geschirr" },
  },
  es = {
    [1] = { "jueg" },
    [2] = { "ritual" },
    [3] = { "escrit", "mapa" },
    [4] = { "estét", "cosm" },
    [5] = { "cristaler", "utens", "cocina" },
  },
  fr = {
    [1] = { "jeu" },
    [2] = { "rituel" },
    [3] = { "écrit", "carte" },
    [4] = { "cosm" },
    [5] = { "boire", "ustens", "plat" },
  },
  ru = {
    [1] = { "игр" },
    [2] = { "ритуал" },
    [3] = { "сочинен", "карт" },
    [4] = { "космет" },
    [5] = { "напит", "утвар", "посуд", "прибор" },
  },
  jp = {
    [1] = { "遊" },
    [2] = { "儀式" },
    [3] = { "書物", "マップ" },
    [4] = { "化粧" },
    [5] = { "飲み物", "調理", "食器" },
  },
  zh = {
    [1] = { "游戏" },
    [2] = { "仪式" },
    [3] = { "文字", "地图" },
    [4] = { "装扮" },
    [5] = { "饮具", "餐具", "厨具" },
  },
}

local CROW_QUEST_FRAGMENTS = {
  en = {
    leisure = { "games", "toys" },
    tributes = { "cosmetics", "grooming" },
    respect = { "cookware", "dishes", "utensils", "drinkware" },
  },
  de = {
    leisure = { "spiel", "spielzeug" },
    tributes = { "kosmet", "pflege" },
    respect = { "koch", "geschirr", "utens", "trink" },
  },
  es = {
    leisure = { "jueg", "infantil" },
    tributes = { "estét", "aseo" },
    respect = { "cocina", "utens", "cristaler" },
  },
  fr = {
    leisure = { "jeu", "jouet" },
    tributes = { "cosm", "toilette" },
    respect = { "plat", "ustens", "boire" },
  },
  ru = {
    leisure = { "игр", "игруш" },
    tributes = { "космет", "уход" },
    respect = { "кухон", "посуд", "утвар", "прибор", "напит" },
  },
  jp = {
    leisure = { "遊", "おもちゃ" },
    tributes = { "化粧", "身だしなみ" },
    respect = { "調理", "食器", "飲み物" },
  },
  zh = {
    leisure = { "游戏", "玩具" },
    tributes = { "装扮", "刷洗" },
    respect = { "厨具", "餐具", "饮具" },
  },
}

local CROW_QUEST_IDS = {
  [6107] = "leisure",  -- A Matter of Leisure
  [6106] = "tributes", -- A Matter of Tributes
  [6072] = "respect",  -- A Matter of Respect
}

local function GetClientLanguage()
  local language = string.lower(GetCVar("language.2") or "en")
  local shortLanguage = string.sub(language, 1, 2)
  if COUNTESS_TAGS[language] then
    return language
  elseif COUNTESS_TAGS[shortLanguage] then
    return shortLanguage
  end

  return "en"
end

local function GetLanguageData(localizedTable)
  return localizedTable[GetClientLanguage()] or localizedTable.en
end

local function NormalizeTagText(text)
  if text == nil or text == "" then
    return ""
  end

  return zo_strformat(SI_TOOLTIP_ITEM_TAG_FORMATER, text)
end

local function ContainsAnyFragment(text, fragments)
  if text == nil or text == "" or fragments == nil then
    return false
  end

  for _, fragment in ipairs(fragments) do
    if string.find(text, fragment, 1, true) then
      return true
    end
  end

  return false
end

local function GetQuestTypeFromText(text)
  local lowerText = string.lower(text or "")
  local localization = GetLanguageData(QUEST_FRAGMENTS)
  for questType = 1, 5 do
    if ContainsAnyFragment(lowerText, localization[questType])
      or ContainsAnyFragment(lowerText, QUEST_FRAGMENTS.en[questType]) then
      return questType
    end
  end

  return 0
end

local function GetTagQuestTypes(tagText)
  local localization = GetLanguageData(COUNTESS_TAGS)
  local normalizedTagText = NormalizeTagText(tagText)
  local questTypes = {}

  for questType = 1, 5 do
    if (localization[questType] and localization[questType][normalizedTagText] == true)
      or (COUNTESS_TAGS.en[questType] and COUNTESS_TAGS.en[questType][normalizedTagText] == true) then
      questTypes[#questTypes + 1] = questType
    end
  end

  return questTypes
end

local function GetCrowTagGroups(tagText)
  local localization = GetLanguageData(CROW_TAGS)
  local normalizedTagText = NormalizeTagText(tagText)
  local groups = {}

  for groupName, groupTags in pairs(localization) do
    if (groupTags and groupTags[normalizedTagText] == true)
      or (CROW_TAGS.en[groupName] and CROW_TAGS.en[groupName][normalizedTagText] == true) then
      groups[#groups + 1] = groupName
    end
  end

  table.sort(groups)
  return groups
end

local function GetCrowGroupFromText(text)
  local lowerText = string.lower(text or "")
  local localization = GetLanguageData(CROW_QUEST_FRAGMENTS)
  for groupName, fragments in pairs(localization) do
    if ContainsAnyFragment(lowerText, fragments)
      or ContainsAnyFragment(lowerText, CROW_QUEST_FRAGMENTS.en[groupName]) then
      return groupName
    end
  end

  return nil
end

local function GetCrowGroupFromQuestId(questId)
  return CROW_QUEST_IDS[questId]
end

local currentQuestType = 0
local currentCrowGroup = nil

local function UpdateQuestInfo()
  currentQuestType = 0
  currentCrowGroup = nil
  local numQuests = GetNumJournalQuests()
  for journalIndex = 1, numQuests do
      local _, _, activeStepText = GetJournalQuestInfo(journalIndex)
      local questId = GetJournalQuestId(journalIndex)
      if questId == COUNTESS_QUEST_ID then
        currentQuestType = GetQuestTypeFromText(activeStepText)
      elseif currentCrowGroup == nil then
        currentCrowGroup = GetCrowGroupFromQuestId(questId)
        if currentCrowGroup == nil then
          currentCrowGroup = GetCrowGroupFromText(activeStepText)
        end
      end
  end
end

local function GetCountessState(itemLink)
  if itemLink == nil then
    return false, false
  end

  local numItemTags = GetItemLinkNumItemTags(itemLink)
  local isUsefulForAnyQuest = false
  if numItemTags > 0 then
    for itemTagIndex = 1, numItemTags do
      local itemTagDescription, itemTagCategory = GetItemLinkItemTagInfo(itemLink, itemTagIndex)
      if itemTagCategory == TREASURE_TYPE_CATEGORY and itemTagDescription ~= "" then
        local itemTagString = NormalizeTagText(itemTagDescription)
        local questTypes = GetTagQuestTypes(itemTagString)
        for _, questType in ipairs(questTypes) do
          if questType == currentQuestType then
            return true, true
          end
          isUsefulForAnyQuest = true
        end
      end
    end
  end

  return false, isUsefulForAnyQuest
end

function LibCovetousCountess:IsItemUsefulForCountess(itemLink)
  return GetCountessState(itemLink)
end

function LibCovetousCountess:IsItemUsefulForCrow(itemLink)
  if itemLink == nil then
    return false, false
  end

  local groups = {}
  local seenGroups = {}
  local numItemTags = GetItemLinkNumItemTags(itemLink)
  for itemTagIndex = 1, numItemTags do
    local itemTagDescription, itemTagCategory = GetItemLinkItemTagInfo(itemLink, itemTagIndex)
    if itemTagCategory == TREASURE_TYPE_CATEGORY and itemTagDescription ~= "" then
      local tagGroups = GetCrowTagGroups(itemTagDescription)
      for _, groupName in ipairs(tagGroups) do
        if not seenGroups[groupName] then
          seenGroups[groupName] = true
          groups[#groups + 1] = groupName
        end
      end
    end
  end

  table.sort(groups)
  if #groups == 0 then
    return false, false
  end

  if currentCrowGroup then
    for _, groupName in ipairs(groups) do
      if groupName == currentCrowGroup then
        return true, true
      end
    end
  end

  return false, true
end

function LibCovetousCountess:IsItemUseful(itemLink)
  local isUsefulForActiveCountess, isUsefulForCountess = GetCountessState(itemLink)
  local isUsefulForActiveCrow, isUsefulForCrow = self:IsItemUsefulForCrow(itemLink)

  local source
  if isUsefulForCountess and isUsefulForCrow then
    source = "both"
  elseif isUsefulForCountess then
    source = "countess"
  elseif isUsefulForCrow then
    source = "crow"
  end

  return isUsefulForActiveCountess or isUsefulForActiveCrow, isUsefulForCountess or isUsefulForCrow, source
end

local function OnQuestAdded(eventCode, journalIndex, questName, objectiveName)
  UpdateQuestInfo()
end

local function OnQuestComplete(eventCode, questName, level, previousExperience, currentExperience, rank, previousPoints, currentPoints)
  UpdateQuestInfo()
end

local function OnQuestRemoved(eventCode, isQuestCompleted, journalIndex, questName, zoneIndex, poiIndex)
  UpdateQuestInfo()
end

local function OnPlayerActivated(eventCode)
  EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED)
  UpdateQuestInfo()
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_QUEST_ADDED, OnQuestAdded)
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_QUEST_COMPLETE, OnQuestComplete)
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_QUEST_REMOVED, OnQuestRemoved)
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
