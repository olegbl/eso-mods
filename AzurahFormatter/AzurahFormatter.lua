local ADDON_NAME = "AzurahFormatter"
local ADDON_VERSION = 1.00

-- TODO: allow customizing via LibAddOnMenu
-- current
-- currentPlusShield
-- effCurrent
-- effMax
-- effPercent
-- max
-- percent
-- shield
local FORMATS = {
  -- placeholder
  [1] = "",
  
  -- base, shield, max, percentage
  [2] = "$$currentPlusShield / $$effMax ($percent%%)",
  
  -- base, shield, max
  [3] = "$$currentPlusShield / $$effMax",
  
  -- base, shield, percentage
  [4] = "$effPercent    $$effMax", -- "$$currentPlusShield ($percent%%)"
  
  -- base, shield
  [5] = "$$currentPlusShield",
  
  -- percentage
  [6] = "$effPercent", -- "$percent%%"
  
  -- base, shield, max, percentage (with commas)
  [12] = "$$currentPlusShield / $$effMax ($percent%%)",
  
  -- base, shield, max (with commas)
  [13] = "$$currentPlusShield / $$effMax",
  
  -- base, shield, percentage (with commas)
  [14] = "$effPercent    $$effMax", -- "$$currentPlusShield ($percent%%)"
  
  -- base, shield (with commas)
  [15] = "$$currentPlusShield",
  
  -- percentage (with commas)
  [16] = "$effPercent", -- "$percent%%"
}

-- comma_value from Azurah
local function GetValueWithCommaSeparators(value)
  local locale = Azurah:GetLocale()
  while (true) do
    value, k = string.gsub(value, "^(-?%d+)(%d%d%d)", "%1" .. locale.ThousandsSeparator .. "%2")
    if (k == 0) then
      break
    end
  end
  return value
end

local function GetFormattedValue(value, truncate, delimit)
  local GetFormattedValueInternal = function(value)
    if delimit then
      return GetValueWithCommaSeparators(math.ceil(value))
    else
      return math.ceil(value)
    end
  end

  if truncate and value >= 1000 then
    return GetFormattedValueInternal(value / 1000) .. "k"
  end
  return GetFormattedValueInternal(value)
end

local function GetReplacement(str, key, value, delimit)
  str = string.gsub(str, "$$" .. key, GetFormattedValue(value, true, delimit))
  str = string.gsub(str, "$" .. key, GetFormattedValue(value, false, delimit))
  return str
end

local function GetOverlayFormat(type, current, max, effMax, shield)
  max = max or 1
  effMax = effMax or 1
  shield = shield or 0

  local effCurrent = current + shield
  local percent = (current / effMax) * 100
  local effPercent = (effCurrent / effMax) * 100

  if (current or 0) == 0 then
    return "0"
  end

  local str = FORMATS[type] or FORMATS[2]
  local delimit = type > 10

  str = string.gsub(str, "$$currentPlusShield", shield > 0 and "$$current + $$shield" or "$$current")
  str = string.gsub(str, "$currentPlusShield", shield > 0 and "$current + $shield" or "$current")

  str = GetReplacement(str, "current", current, delimit)
  str = GetReplacement(str, "max", max, delimit)
  str = GetReplacement(str, "shield", shield, delimit)
  str = GetReplacement(str, "effMax", effMax, delimit)
  str = GetReplacement(str, "effCurrent", effCurrent, delimit)
  str = GetReplacement(str, "percent", percent, delimit)
  str = GetReplacement(str, "effPercent", effPercent, delimit)

  return str
end

for i, _ in pairs(Azurah.overlayFuncs) do
  Azurah.overlayFuncs[i] = function(current, max, effMax, shield)
    return GetOverlayFormat(i, current, max, effMax, shield)
  end
end
