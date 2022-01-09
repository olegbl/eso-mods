local ADDON_NAME = "LibPOI"
local ADDON_VERSION = 1.02

LibPOI = {}

-- TODO: parse Mundus Stone names from known zoneId, poiIndex to detect Mundus Stones
--       via their name on all localizations instead of hardcoding all zoneId, poiIndex combinations

-- TODO: localization boilerplate to allow potentially adding other translations for Mundus Stone descriptions

-- name, description
local MUNDUS_STONE_DESCRIPTIONS = {
  ["The Apprentice"] = "Increases Spell Power",
  ["The Atronach"] = "Increases Magicka Recovery",
  ["The Lady"] = "Increases Physical and Spell Resistance",
  ["The Lord"] = "Increases Maximum Health",
  ["The Lover"] = "Increases Physical and Spell Penetration",
  ["The Mage"] = "Increases Maximum Magicka",
  ["The Ritual"] = "Increases Healing Effectiveness",
  ["The Serpent"] = "Increases Stamina Recovery",
  ["The Shadow"] = "Increases Critical Damage and Healing",
  ["The Steed"] = "Increases Run Speed & Increases Health Recovery",
  ["The Thief"] = "Increases Critical Strike Rating",
  ["The Tower"] = "Increases Maximum Stamina",
  ["The Warrior"] = "Increases Weapon Damage",
}

-- zoneId, poiIndex, name
local MUNDUS_STONE_POI = {
  [3] = {[37] = "The Lover", [38] = "The Lady"},
  [19] = {[36] = "The Tower", [37] = "The Mage", [38] = "The Lord"},
  [20] = {[28] = "The Atronach", [29] = "The Shadow", [30] = "The Serpent"},
  [41] = {[32] = "The Lady", [33] = "The Lover"},
  [57] = {[14] = "The Tower", [15] = "The Mage", [16] = "The Lord"},
  [58] = {[11] = "The Thief", [12] = "The Ritual", [13] = "The Warrior"},
  [92] = {[17] = "The Steed", [18] = "The Apprentice"},
  [101] = {[2] = "The Thief", [3] = "The Warrior", [4] = "The Ritual"},
  [103] = {[20] = "The Steed", [43] = "The Apprentice"},
  [104] = {[39] = "The Warrior", [40] = "The Ritual", [41] = "The Thief"},
  [108] = {[26] = "The Atronach", [27] = "The Serpent", [28] = "The Shadow"},
  [117] = {[17] = "The Atronach", [18] = "The Shadow", [19] = "The Serpent"},
  [181] = {[67] = "The Apprentice", [68] = "The Atronach", [69] = "The Lady", [70] = "The Warrior", [71] = "The Mage", [72] = "The Thief", [73] = "The Lover", [74] = "The Serpent", [75] = "The Ritual", [76] = "The Tower", [77] = "The Steed", [78] = "The Shadow"},
  [381] = {[12] = "The Lady", [22] = "The Lover"},
  [382] = {[27] = "The Steed", [28] = "The Apprentice"},
  [383] = {[12] = "The Tower", [13] = "The Mage", [14] = "The Lord"},
}

-- zoneId, poiIndex
local HARBORAGE_POI = {
  [3] = {[46] = true}, -- Stonefalls
  [41] = {[46] = true}, -- Glenumbra
  [381] = {[42] = true}, -- Auridon
}

-- zoneId, poiIndex, itemId, traitsNeeded
local CRAFTING_STATION_POI = {
  [3] = {[56] = {43815, 2}, [60] = {43803, 2}, [61] = {43871, 2}},
  [19] = {[56] = {43977, 3}, [57] = {43827, 3}, [59] = {43807, 3}},
  [20] = {[52] = {43847, 4}, [53] = {43819, 4}, [57] = {43995, 4}},
  [41] = {[54] = {43803, 2}, [56] = {43815, 2}, [59] = {43871, 2}},
  [57] = {[51] = {43807, 3}, [52] = {43977, 3}, [53] = {43827, 3}},
  [58] = {[53] = {44013, 5}, [56] = {44019, 5}, [58] = {43831, 5}},
  [92] = {[49] = {43859, 6}, [55] = {44001, 6}, [57] = {44007, 6}},
  [101] = {[52] = {44019, 5}, [54] = {44013, 5}, [55] = {43831, 5}},
  [103] = {[53] = {44001, 6}, [57] = {43859, 6}, [59] = {44007, 6}},
  [104] = {[54] = {44013, 5}, [55] = {44019, 5}, [59] = {43831, 5}},
  [108] = {[50] = {43819, 4}, [52] = {43847, 4}, [55] = {43995, 4}},
  [117] = {[50] = {43847, 4}, [57] = {43995, 4}, [59] = {43819, 4}},
  [347] = {[47] = {43971, 8}, [56] = {43965, 8}},
  [381] = {[50] = {43815, 2}, [55] = {43871, 2}, [56] = {43803, 2}},
  [382] = {[48] = {43859, 6}, [51] = {44007, 6}, [52] = {44001, 6}},
  [383] = {[49] = {43807, 3}, [52] = {43827, 3}, [55] = {43977, 3}},
  [584] = {[22] = {60618, 7}, [23] = {60280, 5}, [24] = {60973, 9}},
  [684] = {[51] = {69949, 3}, [52] = {69606, 6}, [53] = {70642, 9}},
  [726] = {[17] = {143544, 4}, [18] = {143174, 2}, [19] = {142804, 7}},
  [816] = {[19] = {72502, 9}, [21] = {71795, 5}, [24] = {72145, 7}},
  [823] = {[18] = {75397, 5}, [19] = {75747, 7}, [20] = {76120, 9}},
  [849] = {[44] = {121551, 3}, [45] = {121921, 8}, [46] = {122251, 6}},
  [888] = {[12] = {58153, 9}, [43] = {54787, 8}},
  [980] = {[19] = {130460, 2}, [20] = {131168, 6}},
  [981] = {[3] = {130803, 4}},
  [1011] = {[33] = {135730, 3}, [34] = {136430, 9}},
  [1027] = {[1] = {136080, 6}},
  [1086] = {[26] = {148331, 5}, [27] = {147961, 8}, [28] = {148701, 3}},
  [1133] = {[11] = {156165, 9}, [12] = {155417, 3}},
  [1160] = {[48] = {161234, 5}, [49] = {161608, 7}},
  [1161] = {[22] = {163070, 3}},
  [1207] = {[4] = {168386, 6}, [17] = {168012, 3}},
  [1208] = {[11] = {168760, 9}},
  [1261] = {[50] = {173216, 5}, [51] = {172842, 7}, [52] = {172468, 3}},
  [1283] = {[1] = {179567, 5}},
  [1286] = {[19] = {179193, 7}, [20] = {178819, 3}},
}

local POI_CATEGORIES = {
  areaofinterest = {
    id = "areaofinterest",
    categoryName = "Areas of Interest",
    completeIcons = {
      "/esoui/art/icons/poi/poi_areaofinterest_complete.dds",
      "/esoui/art/icons/poi/poi_group_areaofinterest_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_areaofinterest_incomplete.dds",
      "/esoui/art/icons/poi/poi_group_areaofinterest_incomplete.dds",
    }
  },
  ayleidruin = {
    id = "ayleidruin",
    categoryName = "Ayleid Ruins",
    completeIcons = {
      "/esoui/art/icons/poi/poi_ayleidruin_complete.dds",
      "/esoui/art/icons/poi/poi_ayliedruin_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_ayleidruin_incomplete.dds",
      "/esoui/art/icons/poi/poi_ayliedruin_incomplete.dds",
    }
  },
  battlefield = {
    id = "battlefield",
    categoryName = "Battlefields",
    completeIcons = {
      "/esoui/art/icons/poi/poi_battlefield_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_battlefield_incomplete.dds",
    }
  },
  boss = {
    id = "boss",
    categoryName = "Bosses",
    completeIcons = {
      "/esoui/art/icons/poi/poi_groupboss_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_groupboss_incomplete.dds",
    }
  },
  camp = {
    id = "camp",
    categoryName = "Camps",
    completeIcons = {
      "/esoui/art/icons/poi/poi_camp_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_camp_incomplete.dds",
    }
  },
  cave = {
    id = "cave",
    categoryName = "Caves",
    completeIcons = {
      "/esoui/art/icons/poi/poi_cave_complete.dds",
      "/esoui/art/icons/poi/poi_group_cave_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_cave_incomplete.dds",
      "/esoui/art/icons/poi/poi_group_cave_incomplete.dds",
    }
  },
  cemetery = {
    id = "cemetery",
    categoryName = "Cemeteries",
    completeIcons = {
      "/esoui/art/icons/poi/poi_cemetery_complete.dds",
      "/esoui/art/icons/poi/poi_group_cemetery_complete.dds",
      "/esoui/art/icons/poi/poi_cemetary_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_cemetery_incomplete.dds",
      "/esoui/art/icons/poi/poi_group_cemetery_incomplete.dds",
      "/esoui/art/icons/poi/poi_cemetary_incomplete.dds",
    }
  },
  city = {
    id = "city",
    categoryName = "Cities",
    completeIcons = {
      "/esoui/art/icons/poi/poi_city_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_city_incomplete.dds",
    }
  },
  crafting = {
    id = "crafting",
    categoryName = "Crafting Stations",
    completeIcons = {
      "/esoui/art/icons/poi/poi_crafting_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_crafting_incomplete.dds",
    }
  },
  crypt = {
    id = "crypt",
    categoryName = "Crypts",
    completeIcons = {
      "/esoui/art/icons/poi/poi_crypt_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_crypt_incomplete.dds",
    }
  },
  daedricruin = {
    id = "daedricruin",
    categoryName = "Daedric Ruins",
    completeIcons = {
      "/esoui/art/icons/poi/poi_daedricruin_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_daedricruin_incomplete.dds",
    }
  },
  darkbrotherhood = {
    id = "darkbrotherhood",
    categoryName = "Dark Brotherhood",
    completeIcons = {
      "/esoui/art/icons/poi/poi_darkbrotherhood_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_darkbrotherhood_incomplete.dds",
    }
  },
  delve = {
    id = "delve",
    categoryName = "Delves",
    completeIcons = {
      "/esoui/art/icons/poi/poi_delve_complete.dds",
      "/esoui/art/icons/poi/poi_groupdelve_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_delve_incomplete.dds",
      "/esoui/art/icons/poi/poi_groupdelve_incomplete.dds",
    }
  },
  dock = {
    id = "dock",
    categoryName = "Docks",
    completeIcons = {
      "/esoui/art/icons/poi/poi_dock_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_dock_incomplete.dds",
    }
  },
  dungeon = {
    id = "dungeon",
    categoryName = "Dungeons",
    completeIcons = {
      "/esoui/art/icons/poi/poi_dungeon_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_dungeon_incomplete.dds",
    }
  },
  dwemerruin = {
    id = "dwemerruin",
    categoryName = "Dwemer Ruins",
    completeIcons = {
      "/esoui/art/icons/poi/poi_dwemerruin_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_dwemerruin_incomplete.dds",
    }
  },
  estate = {
    id = "estate",
    categoryName = "Estates",
    completeIcons = {
      "/esoui/art/icons/poi/poi_estate_complete.dds",
      "/esoui/art/icons/poi/poi_group_estate_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_estate_incomplete.dds",
      "/esoui/art/icons/poi/poi_group_estate_incomplete.dds",
    }
  },
  explorable = {
    id = "explorable",
    categoryName = "Explorable",
    completeIcons = {
      "/esoui/art/icons/poi/poi_explorable_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_explorable_incomplete.dds",
    }
  },
  farm = {
    id = "farm",
    categoryName = "Farms",
    completeIcons = {
      "/esoui/art/icons/poi/poi_farm_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_farm_incomplete.dds",
    }
  },
  gate = {
    id = "gate",
    categoryName = "Gates",
    completeIcons = {
      "/esoui/art/icons/poi/poi_gate_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_gate_incomplete.dds",
    }
  },
  grove = {
    id = "grove",
    categoryName = "Groves",
    completeIcons = {
      "/esoui/art/icons/poi/poi_grove_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_grove_incomplete.dds",
    }
  },
  harborage = {
    id = "harborage",
    categoryName = "Harborage",
    completeIcons = {
      "/esoui/art/icons/poi/poi_cave_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_cave_incomplete.dds",
    }
  },
  house = {
    id = "house",
    categoryName = "Houses",
    completeIcons = {
      "/esoui/art/icons/poi/poi_group_house_owned.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_group_house_unowned.dds",
    }
  },
  instance = {
    id = "instance",
    categoryName = "Group Dungeons",
    completeIcons = {
      "/esoui/art/icons/poi/poi_groupinstance_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_groupinstance_incomplete.dds",
    }
  },
  keep = {
    id = "keep",
    categoryName = "Keeps",
    completeIcons = {
      "/esoui/art/icons/poi/poi_keep_complete.dds",
      "/esoui/art/icons/poi/poi_group_keep_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_keep_incomplete.dds",
      "/esoui/art/icons/poi/poi_group_keep_incomplete.dds",
    }
  },
  lighthouse = {
    id = "lighthouse",
    categoryName = "Lighthouses",
    completeIcons = {
      "/esoui/art/icons/poi/poi_lighthouse_complete.dds",
      "/esoui/art/icons/poi/poi_group_lighthouse_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_lighthouse_incomplete.dds",
      "/esoui/art/icons/poi/poi_group_lighthouse_incomplete.dds",
    }
  },
  mine = {
    id = "mine",
    categoryName = "Mines",
    completeIcons = {
      "/esoui/art/icons/poi/poi_mine_complete.dds",
      "/esoui/art/icons/poi/poi_mine_compete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_mine_incomplete.dds",
      "/esoui/art/icons/poi/poi_mine_incompete.dds",
    }
  },
  mundus = {
    id = "mundus",
    categoryName = "Mundus Stones",
    completeIcons = {
      "/esoui/art/icons/poi/poi_mundus_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_mundus_incomplete.dds",
    }
  },
  portal = {
    id = "portal",
    categoryName = "Dolmens",
    completeIcons = {
      "/esoui/art/icons/poi/poi_portal_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_portal_incomplete.dds",
    }
  },
  raiddungeon = {
    id = "raiddungeon",
    categoryName = "Group Trials",
    completeIcons = {
      "/esoui/art/icons/poi/poi_raiddungeon_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_raiddungeon_incomplete.dds",
    }
  },
  ruin = {
    id = "ruin",
    categoryName = "Ruins",
    completeIcons = {
      "/esoui/art/icons/poi/poi_ruin_complete.dds",
      "/esoui/art/icons/poi/poi_group_ruin_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_ruin_incomplete.dds",
      "/esoui/art/icons/poi/poi_group_ruin_incomplete.dds",
    }
  },
  sewer = {
    id = "sewer",
    categoryName = "Sewers",
    completeIcons = {
      "/esoui/art/icons/poi/poi_sewer_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_sewer_incomplete.dds",
    }
  },
  solotrial = {
    id = "solotrial",
    categoryName = "Solo Trials",
    completeIcons = {
      "/esoui/art/icons/poi/poi_solotrial_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_solotrial_incomplete.dds",
    }
  },
  tower = {
    id = "tower",
    categoryName = "Towers",
    completeIcons = {
      "/esoui/art/icons/poi/poi_tower_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_tower_incomplete.dds",
    }
  },
  town = {
    id = "town",
    categoryName = "Towns",
    completeIcons = {
      "/esoui/art/icons/poi/poi_town_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_town_incomplete.dds",
    }
  },
  u26_dwemergear = {
    id = "u26_dwemergear",
    categoryName = "Dwemer Gears",
    completeIcons = {
      "/esoui/art/icons/poi/poi_u26_dwemergear_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_u26_dwemergear_incomplete.dds",
    }
  },
  u26_nord_boat = {
    id = "u26_nord_boat",
    categoryName = "Nord Boats",
    completeIcons = {
      "/esoui/art/icons/poi/poi_u26_nord_boat_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_u26_nord_boat_incomplete.dds",
    }
  },
  unknown = {
    id = "unknown",
    categoryName = "Unknown",
    completeIcons = {
      "/esoui/art/antiquities/digsite_unknown.dds",
    },
    incompleteIcons = {
      "/esoui/art/antiquities/digsite_unknown.dds",
      "/esoui/art/icons/icon_missing.dds",
    }
  },
  wayshrine = {
    id = "wayshrine",
    categoryName = "Wayshrines",
    completeIcons = {
      "/esoui/art/icons/poi/poi_wayshrine_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_wayshrine_incomplete.dds",
    }
  },
}

local ICON_TO_POI = {}
local COMPLETE_ICON_TO_POI = {}
local INCOMPLETE_ICON_TO_POI = {}
for _, poi in pairs(POI_CATEGORIES) do
  -- for the harborage, it uses the same icon as caves,
  -- so we'll map it using ids instead of icons
  if poi.id ~= "harborage" then
    for _, icon in ipairs(poi.completeIcons) do
      ICON_TO_POI[icon] = poi
      COMPLETE_ICON_TO_POI[icon] = poi
    end
    for _, icon in ipairs(poi.incompleteIcons) do
      ICON_TO_POI[icon] = poi
      INCOMPLETE_ICON_TO_POI[icon] = poi
    end
  end
end

local function GetSanitizedIcon(icon)
  -- some POIs have an icon set but are missing the ".dds" extension, we fix it here
  if string.sub(icon, -4) ~= ".dds" then
    icon = icon .. ".dds"
  end
  return icon
end

local function GetCraftingStationDescription(itemId, traitsNeeded)
  local itemLink = ("|H1:item:%d:370:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"):format(itemId)
  local hasSet, setName, numBonuses, numEquipped, maxEquipped = GetItemLinkSetInfo(itemLink)

  local description = {}
  local maxNumRequired = 0

  for bonusIndex = 1, numBonuses do
    local numRequired, bonusDescription = GetItemLinkSetBonusInfo(itemLink, false, bonusIndex)
    maxNumRequired = math.max(maxNumRequired, numRequired)
    bonusDescription = string.gsub(bonusDescription, " %d+ ", ZO_SELECTED_TEXT:Colorize("%1"))
    table.insert(description, bonusDescription)
  end

  table.insert(description, 1, maxNumRequired .. " Total Items, " .. traitsNeeded .. " Traits Needed")
  table.insert(description, 1, ZO_SELECTED_TEXT:Colorize(setName .. " Set"))

  return table.concat(description, "\n")
end

function LibPOI:GetPOICategories()
  return POI_CATEGORIES
end

function LibPOI:GetPOICategory(zoneIndex, poiIndex)
  local zoneId = GetZoneId(zoneIndex)

  if HARBORAGE_POI[zoneId] ~= nil and HARBORAGE_POI[zoneId][poiIndex] ~= nil then
    return POI_CATEGORIES.harborage
  end

  local normalizedX, normalizedY, poiType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = GetPOIMapInfo(zoneIndex, poiIndex)
  local poi = ICON_TO_POI[GetSanitizedIcon(icon)]

  -- if we don't have a record of this kind of icon, treat it as the "unknown" category
  if poi == nil then
    d("[|c3399FFLibPOI|r] |cFF9933Warning|r: unknown POI type \"" .. icon .. "\"")
    return POI_CATEGORIES.unknown
  end
  
  return poi
end

function LibPOI:IsComplete(zoneIndex, poiIndex)
  local normalizedX, normalizedY, poiType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = GetPOIMapInfo(zoneIndex, poiIndex)
  return COMPLETE_ICON_TO_POI[GetSanitizedIcon(icon)] ~= nil
end

function LibPOI:GetDescription(zoneIndex, poiIndex)
  local objectiveName, objectiveLevel, startDescription, finishedDescription = GetPOIInfo(zoneIndex, poiIndex)
  local isComplete = LibPOI:IsComplete(zoneIndex, poiIndex)

  local zoneId = GetZoneId(zoneIndex)

  local mundusStonePoi =
    MUNDUS_STONE_POI[zoneId] ~= nil and
    MUNDUS_STONE_POI[zoneId][poiIndex] ~= nil and
    MUNDUS_STONE_POI[zoneId][poiIndex] or
    nil

  local mundusStoneDescription =
    MUNDUS_STONE_DESCRIPTIONS[mundusStonePoi] or
    MUNDUS_STONE_DESCRIPTIONS[objectiveName] or
    nil

  local craftingStationPoi =
    CRAFTING_STATION_POI[zoneId] ~= nil and
    CRAFTING_STATION_POI[zoneId][poiIndex] ~= nil and
    CRAFTING_STATION_POI[zoneId][poiIndex] or
    nil

  local craftingStationDescription =
    craftingStationPoi ~= nil and
    GetCraftingStationDescription(craftingStationPoi[1], craftingStationPoi[2]) or
    nil

  return (
    mundusStoneDescription or
    craftingStationDescription or
    (isComplete and finishedDescription or startDescription)
  )
end
