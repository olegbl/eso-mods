local ADDON_NAME = "GamePadHelper_TooltipPrice"
local ADDON_VERSION = 1.01

-- Ensure ESO API compatibility
if GetAPIVersion() < 101047 then
    d("[" .. ADDON_NAME .. "] ESO API version too old. Requires API 101047 or higher.")
    return
end

-- TODO: use LibPrice

local COLOR_GAME = ZO_ColorDef:New("FFFFFF")
local COLOR_TTC = ZO_ColorDef:New("EECA2A")

local COLOR_TITLE = ZO_ColorDef:New("FFFFFF")
local COLOR_DETAILS = ZO_ColorDef:New("B2B2B2")

local PRICE_ICON = ZO_Currency_GetGamepadFormattedCurrencyIcon(CURT_MONEY, 24, true)
local AMOUNT_ICON = zo_iconFormatInheritColor("/esoui/art/inventory/gamepad/gp_inventory_icon_all.dds", 24, 24)

-- Safe wrapper functions for TamrielTradeCentre
local function SafeFormatNumber(number, decimal)
    if TamrielTradeCentre and TamrielTradeCentre.FormatNumber then
        local success, result = pcall(TamrielTradeCentre.FormatNumber, TamrielTradeCentre, number or 0, decimal or 0)
        if success then
            return result
        end
    end
    return tostring(number or 0)
end

local function SafeGetPriceInfo(itemLink)
    if TamrielTradeCentrePrice and TamrielTradeCentrePrice.GetPriceInfo then
        local success, result = pcall(TamrielTradeCentrePrice.GetPriceInfo, TamrielTradeCentrePrice, itemLink)
        if success then
            return result or {}
        end
    end
    return {}
end

local function getStackPrice(price, count)
  if price == nil then return nil end
  return price * count
end

local function getPriceSummary(gameValue, gameMaxValue, ttcValue, suffix)
   local gameValueText = gameValue == gameMaxValue
     and SafeFormatNumber(gameValue or 0, 0)
     or zo_strformat(SI_ITEM_FORMAT_STR_EFFECTIVE_VALUE_OF_MAX, gameValue, gameMaxValue)

   -- Check if TTC is available
   local isTtcAvailable = TamrielTradeCentre and TamrielTradeCentrePrice and ttcValue and ttcValue > 0

   if isTtcAvailable then
     local ttcValueText = SafeFormatNumber(ttcValue, 0)
     return COLOR_TITLE:Colorize(string.format(
       "%s %s %s %s",
       PRICE_ICON,
       COLOR_GAME:Colorize(gameValueText),
       COLOR_TTC:Colorize(ttcValueText),
       suffix or ""
     ))
   else
     -- Only show in-game price when TTC is not available
     return COLOR_TITLE:Colorize(string.format(
       "%s %s %s",
       PRICE_ICON,
       COLOR_GAME:Colorize(gameValueText),
       suffix or ""
     ))
   end
end

local function getPriceBreakdown(priceInfo, suffix)
   local amount = SafeFormatNumber(priceInfo.AmountCount or 0, 0)
   local entries = SafeFormatNumber(priceInfo.EntryCount or 0, 0)
   return COLOR_DETAILS:Colorize(string.format(
     "%s %s - %s %s %s %s%s",
     PRICE_ICON,
     SafeFormatNumber(priceInfo.Min or 0, 0),
     SafeFormatNumber(priceInfo.Max or 0, 0),
     suffix or "",
     AMOUNT_ICON,
     amount,
     priceInfo.EntryCount ~= priceInfo.AmountCount
       and string.format(" (%s stacks)", entries)
       or ""
   ))
end

local lastItemLink = nil
local lastStackSize = nil
local function Tooltip_LayoutBagItem_Before(self, bagId, slotIndex, showCombinedCount, extraData)
  lastItemLink = GetItemLink(bagId, slotIndex)
  lastStackSize = GetSlotStackSize(bagId, slotIndex)
end

local function Tooltip_AddItemTitle_After(self, itemLink, name)
  local stackSize = itemLink == lastItemLink and lastStackSize or 1
  local ttcColor = "FFCC00"

  local gamePrice = GetItemLinkValue(itemLink, false)
  local gameMaxPrice = GetItemLinkValue(itemLink, true)
  local ttcPriceInfo = SafeGetPriceInfo(itemLink)
  local ttcPrice = (ttcPriceInfo.SuggestedPrice or 0) > 0
    and ttcPriceInfo.SuggestedPrice
    or (ttcPriceInfo.Avg or 0)

  local gameProductPrice = 0
  local ttcProductPriceInfo = {}
  local ttcProductPrice = (ttcProductPriceInfo.SuggestedPrice or 0) > 0
    and ttcProductPriceInfo.SuggestedPrice
    or (ttcProductPriceInfo.Avg or 0)

  -- show product pricing for recipes
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)
  if itemType == ITEMTYPE_RECIPE then
    local productItemLink = GetItemLinkRecipeResultItemLink(itemLink)
    if productItemLink then
      gameProductPrice = GetItemLinkValue(productItemLink, false)
      ttcProductPriceInfo = SafeGetPriceInfo(productItemLink)
    end
  end

  local section = self:AcquireSection({
    paddingTop = 3,
    paddingBottom = 3,
    customSpacing = 5, 
    childSpacing = 5, 
    widthPercent = 100, 
    width = 650 - 2 * 40,
    fontSize = 30, 
    fontFace = "$(GAMEPAD_LIGHT_FONT)", 
    fontColorType = INTERFACE_COLOR_TYPE_TEXT_COLORS, 
    fontColorField = INTERFACE_TEXT_COLOR_NORMAL, 
    fontStyle = "soft-shadow-thick",
    uppercase = false, 
  })

  -- Check if TTC is available
  local isTtcAvailable = TamrielTradeCentre and TamrielTradeCentrePrice

  local hasValue = gamePrice > 0 or (isTtcAvailable and ttcPrice > 0)
  local hasAmount = isTtcAvailable and (ttcPriceInfo.AmountCount or 0) > 0
  local productHasValue = gameProductPrice > 0 or (isTtcAvailable and ttcProductPrice > 0)
  local productHasAmount = isTtcAvailable and (ttcProductPriceInfo.AmountCount or 0) > 0

  if hasValue then
    section:AddLine(getPriceSummary(gamePrice, gameMaxPrice, ttcPrice))
  end
  if hasValue and stackSize > 1 then
    section:AddLine(getPriceSummary(getStackPrice(gamePrice, stackSize), getStackPrice(gameMaxPrice, stackSize), getStackPrice(ttcPrice, stackSize), string.format("(stack of %s)", stackSize)))
  end
  if hasAmount then
    section:AddLine(getPriceBreakdown(ttcPriceInfo))
  end
  if productHasValue then
    section:AddLine(getPriceSummary(gameProductPrice, gameProductPrice, ttcProductPrice, "(product)"))
  end
  if productHasAmount then
    section:AddLine(getPriceBreakdown(ttcProductPriceInfo))
  end

  self:AddSection(section)
end

local function Tooltip_AddItemValue_Before(self, itemLink)
  -- just don't run the original code
  return true
end

local tooltips = {
  GAMEPAD_LEFT_DIALOG_TOOLTIP,
  GAMEPAD_LEFT_TOOLTIP,
  GAMEPAD_MOVABLE_TOOLTIP,
  GAMEPAD_QUAD1_TOOLTIP,
  GAMEPAD_QUAD3_TOOLTIP,
  GAMEPAD_RIGHT_TOOLTIP
}

for index, tooltip in ipairs(tooltips) do
  ZO_PreHook(GAMEPAD_TOOLTIPS:GetTooltip(tooltip), "LayoutBagItem", Tooltip_LayoutBagItem_Before)
  ZO_PostHook(GAMEPAD_TOOLTIPS:GetTooltip(tooltip), "AddItemTitle", Tooltip_AddItemTitle_After)
  ZO_PreHook(GAMEPAD_TOOLTIPS:GetTooltip(tooltip), "AddItemValue", Tooltip_AddItemValue_Before)
end
