local ADDON_NAME = "AzurahFormatter"
local ADDON_VERSION = 1.00

local IsAzurahLoaded = false

local function GetFormattedValue(value, truncate)
  if truncate and value >= 1000 then
    return math.ceil(value / 1000) .. "k"
  end
  return math.ceil(value)
end

local function GetReplacement(str, key, value)
  str = string.gsub(str, "$$" .. key, GetFormattedValue(value, true))
  str = string.gsub(str, "$" .. key, GetFormattedValue(value, false))
  return str
end

local function GetOverlayFormat(current, max, effMax, shield)
  max = max or 1
  effMax = effMax or 1
  shield = shield or 0

  local total = current + shield
  local percent = (current / effMax) * 100

  if (current or 0) == 0 then
    return "0"
  end

  -- TODO: allow customizing via LibAddOnMenu
  local str = "$$current    $percent"

  str = GetReplacement(str, "current", current)
  str = GetReplacement(str, "max", max)
  str = GetReplacement(str, "shield", shield)
  str = GetReplacement(str, "effMax", effMax)
  str = GetReplacement(str, "total", total)
  str = GetReplacement(str, "percent", percent)

  return str
end

for i, _ in pairs(Azurah.overlayFuncs) do
  Azurah.overlayFuncs[i] = GetOverlayFormat
end
