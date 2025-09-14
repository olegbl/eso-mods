local ADDON_NAME = "LibItemLinkDecoder"
local ADDON_VERSION = 1.00

-- Ensure ESO API compatibility
if GetAPIVersion() < 101047 then return end

LibItemLinkDecoder = {}

-- https://en.uesp.net/wiki/Online:Item_Link
local INDEX_TO_NAME = {
  [1] = {"linkType"},
  [2] = {"itemId"},
  [3] = {"subType"},
  [4] = {"level"},
  [5] = {"enchantId"},
  [6] = {"enchantSubType"},
  [7] = {"enchantLevel"},
  [8] = {"transmuteTrait"}
  -- TODO
}

local NAME_TO_INDEX = {}

for index, names in pairs(INDEX_TO_NAME) do
  for nameIndex, name in ipairs(names) do
    NAME_TO_INDEX[name] = index
  end
end

local function SetIndex(self, index, value)
  self[index] = value
  local fields = INDEX_TO_NAME[tonumber(index)]
  if fields then
    for fieldIndex, fieldName in ipairs(fields) do
      self[fieldName] = value
    end
  end
end

local function SetValue(self, field, value)
  if tonumber(field) then
    self:SetIndex(tonumber(field), value)
  elseif NAME_TO_INDEX[field] then
    self:SetIndex(NAME_TO_INDEX[field], value)
  else
    self[field] = value
  end
end

local function Clone(self)
  local clone = {}
  for field, value in pairs(self) do
    clone[field] = value
  end
  return clone
end

local function Encode(self)
  local values = {}
  for key, value in ipairs(self) do
    table.insert(values, value)
  end
  local createLink = self.linkStyle == LINK_STYLE_BRACKETS
    and ZO_LinkHandler_CreateLink
    or ZO_LinkHandler_CreateLinkWithoutBrackets
  return createLink(self.linkText, "", unpack(values))
end

function LibItemLinkDecoder:Decode(itemLink)
  local decodedItemLink = {
    SetIndex = SetIndex,
    SetValue = SetValue,
    Clone = Clone,
    Encode = Encode
  }

  decodedItemLink.linkType = GetLinkType(itemLink)

  local values = {ZO_LinkHandler_ParseLink(itemLink)}
  decodedItemLink.linkText = values[1]
  table.remove(values, 1)
  decodedItemLink.linkStyle = values[1]
  table.remove(values, 1)
  for index, value in ipairs(values) do
    decodedItemLink[index] = tonumber(value) or value
    local fields = INDEX_TO_NAME[index]
    if fields then
      for fieldIndex, fieldName in ipairs(fields) do
        decodedItemLink[fieldName] = tonumber(value) or value
      end
    end
  end

  decodedItemLink.quality = GetItemLinkQuality(itemLink)
  decodedItemLink.level = GetItemLinkRequiredLevel(itemLink)
  decodedItemLink.championLevel = GetItemLinkRequiredChampionPoints(itemLink)

  -- for non-crafted sets, enchant subtype matches the item
  -- TODO: same thing for glyphs
  if decodedItemLink.enchantSubType == 0
    and not IsItemLinkCrafted(itemLink)
    and GetItemLinkSetInfo(itemLink, false) then
    decodedItemLink.enchantSubType = decodedItemLink.subType
    decodedItemLink.enchantQuality = decodedItemLink.quality
    decodedItemLink.enchantLevel = decodedItemLink.level
    decodedItemLink.enchantChampionLevel = decodedItemLink.championLevel
  elseif decodedItemLink.enchantSubType ~= 0 or decodedItemLink.enchantLevel ~= 0 then
    local enchantDecodedItemLink = decodedItemLink:Clone()
    enchantDecodedItemLink:SetValue("itemId", decodedItemLink.enchantId)
    enchantDecodedItemLink:SetValue("subType", decodedItemLink.enchantSubType)
    enchantDecodedItemLink:SetValue("level", decodedItemLink.enchantLevel)
    enchantDecodedItemLink:SetValue("enchantId", 0)
    enchantDecodedItemLink:SetValue("enchantSubType", 0)
    enchantDecodedItemLink:SetValue("enchantLevel", 0)

    decodedItemLink.enchantItemLink = enchantDecodedItemLink:Encode()
    decodedItemLink.enchantQuality = GetItemLinkQuality(decodedItemLink.enchantItemLink)

    local enchantLevel, enchantChampionLevel = GetItemLinkGlyphMinLevels(decodedItemLink.enchantItemLink)
    if enchantLevel or enchantChampionLevel then
      decodedItemLink.enchantLevel = enchantLevel or 50
      decodedItemLink.enchantChampionLevel = enchantChampionLevel or 0
    else
      decodedItemLink.enchantLevel = decodedItemLink.level
      decodedItemLink.enchantChampionLevel = decodedItemLink.championLevel
    end
  else
    decodedItemLink.enchantQuality = decodedItemLink.quality
    decodedItemLink.enchantLevel = decodedItemLink.level
    decodedItemLink.enchantChampionLevel = decodedItemLink.championLevel
  end

  return decodedItemLink
end
