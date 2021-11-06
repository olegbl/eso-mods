local ADDON_NAME = "LibPOI"
local ADDON_VERSION = 1.00

LibPOI = {}

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
    categoryName = "Instances",
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
    categoryName = "Dark Anchors",
    completeIcons = {
      "/esoui/art/icons/poi/poi_portal_complete.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/poi/poi_portal_incomplete.dds",
    }
  },
  raiddungeon = {
    id = "raiddungeon",
    categoryName = "Raid Dungeons",
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
      "/esoui/art/icons/u26_unknown_antiquity_questionmark.dds",
    },
    incompleteIcons = {
      "/esoui/art/icons/u26_unknown_antiquity_questionmark.dds",
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
  for _, icon in ipairs(poi.completeIcons) do
    ICON_TO_POI[icon] = poi
    COMPLETE_ICON_TO_POI[icon] = poi
  end
  for _, icon in ipairs(poi.incompleteIcons) do
    ICON_TO_POI[icon] = poi
    INCOMPLETE_ICON_TO_POI[icon] = poi
  end
end

local function sanitizeIcon(icon)
  -- some POIs have an icon set but are missing the ".dds" extension, we fix it here
  if string.sub(icon, -4) ~= ".dds" then
    icon = icon .. ".dds"
  end
  return icon
end

function LibPOI:GetPOICategories()
  return POI_CATEGORIES
end

function LibPOI:GetPOICategory(zoneIndex, poiIndex)
  local normalizedX, normalizedY, poiType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = GetPOIMapInfo(zoneIndex, poiIndex)
  local poi = ICON_TO_POI[sanitizeIcon(icon)]

  -- if we don't have a record of this kind of icon, treat it as the "unknown" category
  if poi == nil then
    d("[|c3399FFLibPOI|r] |cFF9933Warning|r: unknown POI type \"" .. icon .. "\"")
    return POI_CATEGORIES.unknown
  end
  
  return poi
end

function LibPOI:IsComplete(zoneIndex, poiIndex)
  local normalizedX, normalizedY, poiType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = GetPOIMapInfo(zoneIndex, poiIndex)
  return COMPLETE_ICON_TO_POI[sanitizeIcon(icon)] ~= nil
end

function LibPOI:GetDescription(zoneIndex, poiIndex)
  local objectiveName, objectiveLevel, startDescription, finishedDescription = GetPOIInfo(zoneIndex, poiIndex)
  local isComplete = LibPOI:IsComplete(zoneIndex, poiIndex)
  return isComplete and finishedDescription or startDescription
end
