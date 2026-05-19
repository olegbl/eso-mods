local ADDON_NAME = "LibPOI"
local ADDON_VERSION = 1.02

LibPOI = {}

-- name → description (English). Add more locale tables and merge them here for localization support.
local MUNDUS_STONE_DESCRIPTIONS = {
  ["The Apprentice"] = "Increases Spell Power",
  ["The Atronach"]   = "Increases Magicka Recovery",
  ["The Lady"]       = "Increases Physical and Spell Resistance",
  ["The Lord"]       = "Increases Maximum Health",
  ["The Lover"]      = "Increases Physical and Spell Penetration",
  ["The Mage"]       = "Increases Maximum Magicka",
  ["The Ritual"]     = "Increases Healing Effectiveness",
  ["The Serpent"]    = "Increases Stamina Recovery",
  ["The Shadow"]     = "Increases Critical Damage and Healing",
  ["The Steed"]      = "Increases Run Speed & Increases Health Recovery",
  ["The Thief"]      = "Increases Critical Strike Rating",
  ["The Tower"]      = "Increases Maximum Stamina",
  ["The Warrior"]    = "Increases Weapon Damage",
}

-- zoneId, poiIndex
local HARBORAGE_POI = {
  [3]   = {[46] = true}, -- Stonefalls
  [41]  = {[46] = true}, -- Glenumbra
  [381] = {[42] = true}, -- Auridon
}

-- zoneId, poiIndex, itemId, traitsNeeded
local CRAFTING_STATION_POI = {
  [3]    = {[56] = {43815, 2}, [60] = {43803, 2}, [61] = {43871, 2}},
  [19]   = {[56] = {43977, 3}, [57] = {43827, 3}, [59] = {43807, 3}},
  [20]   = {[52] = {43847, 4}, [53] = {43819, 4}, [57] = {43995, 4}},
  [41]   = {[54] = {43803, 2}, [56] = {43815, 2}, [59] = {43871, 2}},
  [57]   = {[51] = {43807, 3}, [52] = {43977, 3}, [53] = {43827, 3}},
  [58]   = {[53] = {44013, 5}, [56] = {44019, 5}, [58] = {43831, 5}},
  [92]   = {[49] = {43859, 6}, [55] = {44001, 6}, [57] = {44007, 6}},
  [101]  = {[52] = {44019, 5}, [54] = {44013, 5}, [55] = {43831, 5}},
  [103]  = {[53] = {44001, 6}, [57] = {43859, 6}, [59] = {44007, 6}},
  [104]  = {[54] = {44013, 5}, [55] = {44019, 5}, [59] = {43831, 5}},
  [108]  = {[50] = {43819, 4}, [52] = {43847, 4}, [55] = {43995, 4}},
  [117]  = {[50] = {43847, 4}, [57] = {43995, 4}, [59] = {43819, 4}},
  [347]  = {[47] = {43971, 8}, [56] = {43965, 8}},
  [381]  = {[50] = {43815, 2}, [55] = {43871, 2}, [56] = {43803, 2}},
  [382]  = {[48] = {43859, 6}, [51] = {44007, 6}, [52] = {44001, 6}},
  [383]  = {[49] = {43807, 3}, [52] = {43827, 3}, [55] = {43977, 3}},
  [584]  = {[22] = {60618, 7}, [23] = {60280, 5}, [24] = {60973, 9}},
  [684]  = {[51] = {69949, 3}, [52] = {69606, 6}, [53] = {70642, 9}},
  [726]  = {[17] = {143544, 4}, [18] = {143174, 2}, [19] = {142804, 7}},
  [816]  = {[19] = {72502, 9}, [21] = {71795, 5}, [24] = {72145, 7}},
  [823]  = {[18] = {75397, 5}, [19] = {75747, 7}, [20] = {76120, 9}},
  [849]  = {[44] = {121551, 3}, [45] = {121921, 8}, [46] = {122251, 6}},
  [888]  = {[12] = {58153, 9}, [43] = {54787, 8}},
  [980]  = {[19] = {130460, 2}, [20] = {131168, 6}},
  [981]  = {[3]  = {130803, 4}},
  [1011] = {[33] = {135730, 3}, [34] = {136430, 9}},
  [1027] = {[1]  = {136080, 6}},
  [1086] = {[26] = {148331, 5}, [27] = {147961, 8}, [28] = {148701, 3}},
  [1133] = {[11] = {156165, 9}, [12] = {155417, 3}},
  [1160] = {[48] = {161234, 5}, [49] = {161608, 7}},
  [1161] = {[22] = {163070, 3}},
  [1207] = {[4]  = {168386, 6}, [17] = {168012, 3}},
  [1208] = {[11] = {168760, 9}},
  [1261] = {[50] = {173216, 5}, [51] = {172842, 7}, [52] = {172468, 3}},
  [1283] = {[1]  = {179567, 5}},
  [1286] = {[19] = {179193, 7}, [20] = {178819, 3}},
}

-- Category metadata. Icons are derived dynamically from GetPOIMapInfo icon filenames via ParseIcon.
local POI_CATEGORIES = {
  areaofinterest  = { id = "areaofinterest",  categoryName = "Areas of Interest" },
  adventurezone   = { id = "adventurezone",   categoryName = "Adventure Zones"   },
  ayleidruin      = { id = "ayleidruin",       categoryName = "Ayleid Ruins"      },
  battlefield     = { id = "battlefield",      categoryName = "Battlefields"      },
  boss            = { id = "boss",             categoryName = "Bosses"            },
  camp            = { id = "camp",             categoryName = "Camps"             },
  cave            = { id = "cave",             categoryName = "Caves"             },
  cemetery        = { id = "cemetery",         categoryName = "Cemeteries"        },
  city            = { id = "city",             categoryName = "Cities"            },
  crafting        = { id = "crafting",         categoryName = "Crafting Stations" },
  crypt           = { id = "crypt",            categoryName = "Crypts"            },
  daedricruin     = { id = "daedricruin",      categoryName = "Daedric Ruins"     },
  darkbrotherhood = { id = "darkbrotherhood",  categoryName = "Dark Brotherhood"  },
  delve           = { id = "delve",            categoryName = "Delves"            },
  dock            = { id = "dock",             categoryName = "Docks"             },
  dungeon         = { id = "dungeon",          categoryName = "Dungeons"          },
  dwemerruin      = { id = "dwemerruin",       categoryName = "Dwemer Ruins"      },
  endlessdungeon  = { id = "endlessdungeon",   categoryName = "Endless Dungeons"  },
  estate          = { id = "estate",           categoryName = "Estates"           },
  explorable      = { id = "explorable",       categoryName = "Explorable"        },
  farm            = { id = "farm",             categoryName = "Farms"             },
  gate            = { id = "gate",             categoryName = "Gates"             },
  grove           = { id = "grove",            categoryName = "Groves"            },
  harborage       = { id = "harborage",        categoryName = "Harborage"         },
  house           = { id = "house",            categoryName = "Houses"            },
  imperial_city   = { id = "imperial_city",    categoryName = "Imperial City"     },
  instance        = { id = "instance",         categoryName = "Group Dungeons"    },
  keep            = { id = "keep",             categoryName = "Keeps"             },
  lighthouse      = { id = "lighthouse",       categoryName = "Lighthouses"       },
  mine            = { id = "mine",             categoryName = "Mines"             },
  mundus          = { id = "mundus",           categoryName = "Mundus Stones"     },
  mushromtower    = { id = "mushromtower",     categoryName = "Mushroom Towers"   },
  portal          = { id = "portal",           categoryName = "Dolmens"           },
  raiddungeon     = { id = "raiddungeon",      categoryName = "Group Trials"      },
  ruin            = { id = "ruin",             categoryName = "Ruins"             },
  sewer           = { id = "sewer",            categoryName = "Sewers"            },
  shrine          = { id = "shrine",           categoryName = "Shrines"           },
  solotrial       = { id = "solotrial",        categoryName = "Solo Trials"       },
  tower           = { id = "tower",            categoryName = "Towers"            },
  town            = { id = "town",             categoryName = "Towns"             },
  u26_dwemergear  = { id = "u26_dwemergear",   categoryName = "Dwemer Gears"      },
  u26_nord_boat   = { id = "u26_nord_boat",    categoryName = "Nord Boats"        },
  unknown         = { id = "unknown",          categoryName = "Unknown"           },
  wayshrine       = { id = "wayshrine",        categoryName = "Wayshrines"        },
}

-- Representative icon prefix for categories whose id doesn't match the standard poi_<id> pattern.
local CATEGORY_ICON_PREFIX = {
  boss          = "poi_groupboss",
  instance      = "poi_groupinstance",
  imperial_city = "poi_ic_boneshard",
  adventurezone = "poi_adventurezone_jumppad",
}

-- Overrides for icon names that don't map cleanly to a category after prefix/suffix stripping.
local ICON_CATEGORY_OVERRIDES = {
  -- Imperial City: multiple distinct item icons, all the same category
  ic_boneshard         = "imperial_city",
  ic_darkether         = "imperial_city",
  ic_tinyclaw          = "imperial_city",
  ic_marklegion        = "imperial_city",
  ic_monstrousteeth    = "imperial_city",
  ic_planararmorscraps = "imperial_city",
  ic_daedricshackles   = "imperial_city",
  ic_daedricembers     = "imperial_city",
  -- Adventure zones: various u49/jumppad naming patterns
  adventurezone_entrance             = "adventurezone",
  adventurezone_jumppad              = "adventurezone",
  adventurezone_faction_ruckus       = "adventurezone",
  adventurezone_faction_thousandeyes = "adventurezone",
  adventurezone_faction_glittering   = "adventurezone",
  adventurezone_skirmish             = "adventurezone",
  adventurezone_contentgrouptimed    = "adventurezone",
  -- Group POIs without underscore between "group" and the type name
  groupboss     = "boss",
  groupdelve    = "delve",
  groupinstance = "instance",
  -- Battleground is the group variant of battlefield
  battleground  = "battlefield",
  -- Shrine sub-types
  shrine_werewolf = "shrine",
  shrine_vampire  = "shrine",
  -- In-game icon filename typos
  ayliedruin     = "ayleidruin",
  cemetary       = "cemetery",
  mine_compete   = "mine",
  mine_incompete = "mine",
  -- Missing icon sentinel
  icon_missing   = "unknown",
}

-- Derives category id and completion state from a raw GetPOIMapInfo icon path.
-- Returns: categoryId (string), isComplete (true/false/nil — nil means state is not encoded in the name).
local function ParseIcon(rawIcon)
  if not rawIcon or rawIcon == "" then return nil, nil end

  local filename = rawIcon:match("([^/]+)%.dds$") or rawIcon

  local isComplete   = filename:find("_complete$")   ~= nil
  local isIncomplete = filename:find("_incomplete$")  ~= nil

  -- Houses use owned/unowned instead of complete/incomplete
  if not isComplete and not isIncomplete then
    if     filename:find("_owned$")   then isComplete   = true
    elseif filename:find("_unowned$") then isIncomplete = true
    end
  end

  -- Strip state suffixes then common POI icon prefixes (most-specific first)
  local name = filename
    :gsub("_complete$",   "")
    :gsub("_incomplete$", "")
    :gsub("_owned$",      "")
    :gsub("_unowned$",    "")
    :gsub("^poi_group_",  "")
    :gsub("^poi_",        "")
    :gsub("^u%d+_poi_",   "")
    :gsub("^u%d+_",       "")

  local categoryId = ICON_CATEGORY_OVERRIDES[name] or name
  return categoryId, isComplete or (not isIncomplete and nil)
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

-- Returns a representative display icon path for a category.
-- Houses use owned/unowned; all others use complete/incomplete.
function LibPOI:GetCategoryIcon(categoryId, isComplete)
  if categoryId == "house" then
    local state = isComplete and "_owned" or "_unowned"
    return "/esoui/art/icons/poi/poi_group_house" .. state .. ".dds"
  end
  local prefix = CATEGORY_ICON_PREFIX[categoryId] or ("poi_" .. (categoryId or "unknown"))
  local state = isComplete and "_complete" or "_incomplete"
  return "/esoui/art/icons/poi/" .. prefix .. state .. ".dds"
end

function LibPOI:GetPOICategory(zoneIndex, poiIndex)
  local zoneId = GetZoneId(zoneIndex)

  if HARBORAGE_POI[zoneId] and HARBORAGE_POI[zoneId][poiIndex] then
    return POI_CATEGORIES.harborage
  end

  local _, _, _, icon = GetPOIMapInfo(zoneIndex, poiIndex)
  local categoryId = ParseIcon(icon)

  return POI_CATEGORIES[categoryId] or POI_CATEGORIES.unknown
end

function LibPOI:IsComplete(zoneIndex, poiIndex)
  local _, _, _, icon = GetPOIMapInfo(zoneIndex, poiIndex)
  local _, isComplete = ParseIcon(icon)
  return isComplete == true
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, function(_, name)
  if name ~= ADDON_NAME then return end
  EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
end)

-- -----------------------------------------------------------------------------
-- Icon Exporter Utility
-- Run /poiexport in-game, then /reloadui to write LibPOIDumpVars to disk.
-- Inspect the SavedVariables file to find icons not yet covered by ParseIcon.
-- -----------------------------------------------------------------------------
SLASH_COMMANDS["/poiexport"] = function()
    LibPOIDumpVars = LibPOIDumpVars or {}
    local dump = LibPOIDumpVars
    local added = 0

    for zoneIndex = 1, GetNumZones() do
        for poiIndex = 1, GetNumPOIs(zoneIndex) do
            local _, _, _, icon = GetPOIMapInfo(zoneIndex, poiIndex)
            if icon and icon ~= "" then
                if not dump[icon] then
                    dump[icon] = true
                    added = added + 1
                end
            end
        end
    end

    local total = 0
    for _ in pairs(dump) do total = total + 1 end

    d("[LibPOI] Exported " .. added .. " new icons. Total: " .. total)
    d("Type /reloadui to save to SavedVariables.")
end

function LibPOI:GetDescription(zoneIndex, poiIndex)
  local objectiveName, objectiveLevel, startDescription, finishedDescription = GetPOIInfo(zoneIndex, poiIndex)
  local isComplete = LibPOI:IsComplete(zoneIndex, poiIndex)
  local category = LibPOI:GetPOICategory(zoneIndex, poiIndex)

  local zoneId = GetZoneId(zoneIndex)

  -- Dynamic mundus detection: match POI name against known stone names (works across locales
  -- as long as the stone name appears somewhere in the POI's objectiveName).
  local mundusStoneDescription = nil
  if category and category.id == "mundus" then
    for name, desc in pairs(MUNDUS_STONE_DESCRIPTIONS) do
      if objectiveName and objectiveName:find(name, 1, true) then
        mundusStoneDescription = desc
        break
      end
    end
  end

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
