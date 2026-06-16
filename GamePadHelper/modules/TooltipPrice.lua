
local COLOR_GAME = ZO_ColorDef:New("FFFFFF")
local COLOR_TTC = ZO_ColorDef:New("EECA2A")

local COLOR_TITLE = ZO_ColorDef:New("FFFFFF")
local COLOR_DETAILS = ZO_ColorDef:New("B2B2B2")

local PRICE_ICON = ZO_Currency_GetGamepadFormattedCurrencyIcon(CURT_MONEY, 24, true)
local AMOUNT_ICON = zo_iconFormatInheritColor("/esoui/art/inventory/gamepad/gp_inventory_icon_all.dds", 24, 24)

local cachedTscApi = nil
local PRICE_CACHE_TTL_MS = 60000
local PRICE_CACHE_MAX_ENTRIES = 500
local priceInfoCache = {}
local priceCacheCount = 0

local SUPPRESS_EXTERNAL_PRICE_PATTERNS = {
    "tsc",
    "tamriel savings",
    "price fetcher",
    "no price data",
    "bound item",
    "exact avg:",
    "exact range:",
    "item avg:",
    "item range:",
    "item avg",
    "item range",
    "common price range",
    "legacy avg",
    "average price",
    "avg price",
    "price range",
}

local function GetNowMs()
    if GetGameTimeMilliseconds then
        return GetGameTimeMilliseconds()
    end
    if GetFrameTimeMilliseconds then
        return GetFrameTimeMilliseconds()
    end
    if GetTimeStamp then
        return GetTimeStamp() * 1000
    end
    return 0
end

local function GetTSCApi()
    if cachedTscApi ~= nil then
        return cachedTscApi
    end

    local function SafeGetGlobal(name)
        return rawget(_G, name)
    end

    local worldName = GetWorldName and GetWorldName() or nil
    local apiByWorld = ({
        ["NA Megaserver"] = SafeGetGlobal("TSCPriceDataAPIXBNA") or SafeGetGlobal("TSCPriceDataAPI"),
        ["EU Megaserver"] = SafeGetGlobal("TSCPriceDataAPIXBEU") or SafeGetGlobal("TSCPriceDataAPI"),
        ["XB1live"] = SafeGetGlobal("TSCPriceDataAPIXBNA"),
        ["PS4live"] = SafeGetGlobal("TSCPriceDataAPIPSNA"),
        ["XB1live-eu"] = SafeGetGlobal("TSCPriceDataAPIXBEU"),
        ["PS4live-eu"] = SafeGetGlobal("TSCPriceDataAPIPSEU"),
    })[worldName]

    if type(apiByWorld) == "table" and type(apiByWorld.GetItemData) == "function" then
        cachedTscApi = apiByWorld
        return cachedTscApi
    end

    local direct = SafeGetGlobal("TSCPriceDataAPI")
    if type(direct) == "table" and type(direct.GetItemData) == "function" then
        cachedTscApi = direct
        return cachedTscApi
    end

    cachedTscApi = false
    return nil
end

-- Safe wrapper functions for market price providers (TTC, TSC, etc.)
local function SafeFormatNumber(number, decimal)
    local ttc = rawget(_G, "TamrielTradeCentre")
    if type(ttc) == "table" and type(ttc.FormatNumber) == "function" then
        local success, result = pcall(ttc.FormatNumber, ttc, number or 0, decimal or 0)
        if success and type(result) == "string" and result ~= "" then
            return result
        end
    end

    local n = zo_floor((tonumber(number) or 0) + 0.5)

    if type(ZO_LocalizeDecimalNumber) == "function" then
        return zo_strformat("<<1>>", ZO_LocalizeDecimalNumber(n))
    end
    if type(ZO_CommaDelimitNumber) == "function" then
        return zo_strformat("<<1>>", ZO_CommaDelimitNumber(n))
    end
    if type(FormatIntegerWithDigitGrouping) == "function" then
        return zo_strformat("<<1>>", FormatIntegerWithDigitGrouping(n))
    end

    return tostring(n)
end

local function NormalizePriceInfo(result)
    if type(result) ~= "table" then return {} end
    return {
        Avg = result.Avg or result.avg or result.average or result.price or result.Price or result.P,
        Max = result.Max or result.max or result.high or result.H,
        Min = result.Min or result.min or result.low or result.L,
        EntryCount = result.EntryCount or result.entryCount or result.entries or result.EC,
        AmountCount = result.AmountCount or result.amountCount or result.amount or result.AC,
        SuggestedPrice = result.SuggestedPrice or result.suggestedPrice or result.suggested or result.S,
    }
end

local function ToNumber(value)
    if type(value) == "number" then
        return value
    end
    if type(value) == "string" then
        return tonumber(value)
    end
    return nil
end

local function SafeGetPriceInfo(itemLink)
        if type(itemLink) ~= "string" or itemLink == "" then
        return {}
        end

        local nowMs = GetNowMs()
        local cached = priceInfoCache[itemLink]
        if cached and (nowMs - cached.timeMs) < PRICE_CACHE_TTL_MS then
        return cached.value
        end

        local value = nil
        if TamrielTradeCentrePrice and TamrielTradeCentrePrice.GetPriceInfo then
                local success, result = pcall(TamrielTradeCentrePrice.GetPriceInfo, TamrielTradeCentrePrice, itemLink)
                if success then
                        value = NormalizePriceInfo(result)
                end
        end
        if not value and LibPriceCache and LibPriceCache.GetPrice then
        local success, result = pcall(LibPriceCache.GetPrice, itemLink)
        if success and result and result > 0 then
                value = NormalizePriceInfo({ Avg = result, SuggestedPrice = result })
        end
        end
        local tscApi = GetTSCApi()
        if not value and tscApi and type(tscApi.GetItemData) == "function" then
        local success, itemData = pcall(function()
                return tscApi:GetItemData(itemLink)
        end)
        if success and itemData then
                local avgPrice = nil
                if type(itemData) == "number" then
                    avgPrice = itemData
                elseif type(itemData) == "table" then
                    avgPrice = ToNumber(itemData.avgPrice)
                        or ToNumber(itemData.avg)
                        or ToNumber(itemData.Avg)
                        or ToNumber(itemData.average)
                        or ToNumber(itemData.averagePrice)
                        or ToNumber(itemData.SuggestedPrice)
                        or ToNumber(itemData.suggestedPrice)
                        or ToNumber(itemData.suggested)
                        or ToNumber(itemData.legacyAvg)
                        or ToNumber(itemData.price)
                        or ToNumber(itemData.Price)
                end

                if avgPrice and avgPrice > 0 then
                    local minPrice = type(itemData) == "table" and (ToNumber(itemData.commonMin) or ToNumber(itemData.minPrice) or ToNumber(itemData.Min) or ToNumber(itemData.min) or ToNumber(itemData.legacyMin)) or nil
                    local maxPrice = type(itemData) == "table" and (ToNumber(itemData.commonMax) or ToNumber(itemData.maxPrice) or ToNumber(itemData.Max) or ToNumber(itemData.max) or ToNumber(itemData.legacyMax)) or nil
                    value = NormalizePriceInfo({
                        Avg = avgPrice,
                        SuggestedPrice = avgPrice,
                        Min = minPrice,
                        Max = maxPrice,
                    })
                end
        end
        end

        value = value or {}
        if not priceInfoCache[itemLink] then
            priceCacheCount = priceCacheCount + 1
            if priceCacheCount > PRICE_CACHE_MAX_ENTRIES then
                priceInfoCache = {}
                priceCacheCount = 1
            end
        end
        priceInfoCache[itemLink] = { value = value, timeMs = nowMs }
        return value
end

local function HasMarketProvider()
    local tscApi = GetTSCApi()
    return (TamrielTradeCentrePrice and TamrielTradeCentrePrice.GetPriceInfo)
        or (LibPriceCache and LibPriceCache.GetPrice)
        or (tscApi and type(tscApi.GetItemData) == "function")
end

local function IsBoundItemLink(itemLink)
    if type(itemLink) ~= "string" or itemLink == "" then return false end
    if type(GetItemLinkBindType) ~= "function" then return false end
    local bindType = GetItemLinkBindType(itemLink)
    return bindType ~= nil and bindType ~= BIND_TYPE_NONE
end

local function getStackPrice(price, count)
    if price == nil then return nil end
    return price * count
end

local function getPriceSummary(gameValue, gameMaxValue, ttcValue, suffix, suppressNoDataLabel)
    local gameValueText = gameValue == gameMaxValue
        and SafeFormatNumber(gameValue or 0, 0)
        or zo_strformat(SI_ITEM_FORMAT_STR_EFFECTIVE_VALUE_OF_MAX, gameValue, gameMaxValue)

    local isMarketLoaded = HasMarketProvider()
    local isMarketAvailable = isMarketLoaded and ttcValue and ttcValue > 0

    if isMarketAvailable then
        local ttcValueText = SafeFormatNumber(ttcValue, 0)
        return COLOR_TITLE:Colorize(string.format(
            "%s %s %s %s",
            PRICE_ICON,
            COLOR_GAME:Colorize(gameValueText),
            COLOR_TTC:Colorize(ttcValueText),
            suffix or ""
        ))
    elseif isMarketLoaded and not suppressNoDataLabel then
        return COLOR_TITLE:Colorize(string.format(
            "%s %s %s %s",
            PRICE_ICON,
            COLOR_GAME:Colorize(gameValueText),
            COLOR_DETAILS:Colorize(GetString(SI_GPH_TOOLTIPPRICE_NO_MARKET)),
            suffix or ""
        ))
    else
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
    local hasCounts = (priceInfo.AmountCount or 0) > 0
    local countText = hasCounts and amount or "-"
    local stackText = hasCounts and priceInfo.EntryCount ~= priceInfo.AmountCount
        and zo_strformat(SI_GPH_TOOLTIPPRICE_STACKS, entries)
        or ""
    return COLOR_DETAILS:Colorize(string.format(
        "%s %s - %s %s %s %s%s",
        PRICE_ICON,
        SafeFormatNumber(priceInfo.Min or 0, 0),
        SafeFormatNumber(priceInfo.Max or 0, 0),
        suffix or "",
        AMOUNT_ICON,
        countText,
        stackText
    ))
end

local lastItemLink = nil
local lastStackSize = nil
local lastBagId = nil
local lastSlotIndex = nil
local lastLootValue = nil

local function FindLootValueByItemLink(itemLink)
    if type(itemLink) ~= "string" or itemLink == "" then return nil end
    if type(GetNumLootItems) ~= "function" or type(GetLootItemInfo) ~= "function" or type(GetLootItemLink) ~= "function" then
        return nil
    end

    local numLootItems = GetNumLootItems()
    if type(numLootItems) ~= "number" or numLootItems <= 0 then
        return nil
    end

    for i = 1, numLootItems do
        local lootId = GetLootItemInfo(i)
        if lootId ~= nil then
        local link = GetLootItemLink(lootId)
        if link == itemLink then
                local _, _, _, _, _, value = GetLootItemInfo(i)
                if type(value) == "number" and value > 0 then
                    return value
                end
                return 0
        end
        end
    end

    return nil
end

local function Tooltip_LayoutItemWithStackCount_Before(self, itemLink, equipped, creatorName, forceFullDurability, previewValueToAdd, stackCount)
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv or not sv.tooltipPriceEnabled then return end

    self.__gph_priceAdded = nil
    lastItemLink = itemLink
    lastStackSize = type(stackCount) == "number" and stackCount or 1
    lastBagId = nil
    lastSlotIndex = nil
    lastLootValue = FindLootValueByItemLink(itemLink)
end

local function Tooltip_LayoutBagItem_Before(self, bagId, slotIndex, showCombinedCount, extraData)
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv or not sv.tooltipPriceEnabled then return end
    self.__gph_priceAdded = nil
    lastItemLink = GetItemLink(bagId, slotIndex)
    lastStackSize = GetSlotStackSize(bagId, slotIndex)
    lastBagId = bagId
    lastSlotIndex = slotIndex
    lastLootValue = nil
end

local function Tooltip_AddItemTitle_After(self, itemLink, name)
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv or not sv.tooltipPriceEnabled then return end
    self.__gph_priceAdded = nil
    local stackSize = itemLink == lastItemLink and lastStackSize or 1
    local isBound = IsBoundItemLink(itemLink)

    local gamePrice = 0
    local gameMaxPrice = 0
    local isFromBag = itemLink == lastItemLink and lastBagId ~= nil and lastSlotIndex ~= nil
    if isFromBag and type(GetItemSellValueWithBonuses) == "function" then
        local success, value = pcall(GetItemSellValueWithBonuses, lastBagId, lastSlotIndex)
        if success and type(value) == "number" and value > 0 then
        gamePrice = value
        gameMaxPrice = value
        end
    end
    if gamePrice == 0 and itemLink == lastItemLink and type(lastLootValue) == "number" and lastLootValue > 0 then
        gamePrice = lastLootValue
        gameMaxPrice = lastLootValue
    end
    if gamePrice == 0 then
        gamePrice = GetItemLinkValue(itemLink, false)
        gameMaxPrice = GetItemLinkValue(itemLink, true)
    end
    local ttcPriceInfo = SafeGetPriceInfo(itemLink)
    local ttcPrice = (ttcPriceInfo.SuggestedPrice or 0) > 0
        and ttcPriceInfo.SuggestedPrice
        or (ttcPriceInfo.Avg or 0)

    local gameProductPrice = 0
    local ttcProductPriceInfo = {}
    local ttcProductPrice = 0
    local productIsBound = false

    local itemType = GetItemLinkItemType(itemLink)

    -- show product pricing for recipes
    if itemType == ITEMTYPE_RECIPE then
        local productItemLink = GetItemLinkRecipeResultItemLink(itemLink)
        if productItemLink then
        gameProductPrice = GetItemLinkValue(productItemLink, false)
        ttcProductPriceInfo = SafeGetPriceInfo(productItemLink)
        ttcProductPrice = (ttcProductPriceInfo.SuggestedPrice or 0) > 0
                and ttcProductPriceInfo.SuggestedPrice
                or (ttcProductPriceInfo.Avg or 0)
        productIsBound = IsBoundItemLink(productItemLink)
        end
    end

    local section = self:AcquireSection({
        paddingTop = 3,
        paddingBottom = 3,
        customSpacing = 5,
        childSpacing = 5,
        widthPercent = 100,
        fontSize = 30,
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
        fontColorType = INTERFACE_COLOR_TYPE_TEXT_COLORS,
        fontColorField = INTERFACE_TEXT_COLOR_NORMAL,
        fontStyle = "soft-shadow-thick",
        uppercase = false,
    })

    -- Check if any market provider is available
    local isTtcAvailable = HasMarketProvider()

    local hasValue = gamePrice > 0 or (isTtcAvailable and ttcPrice > 0)
    local hasAmount = not isBound and isTtcAvailable and ((ttcPriceInfo.AmountCount or 0) > 0 or ((ttcPriceInfo.Min or 0) > 0 and (ttcPriceInfo.Max or 0) > 0))
    local productHasValue = gameProductPrice > 0 or (isTtcAvailable and ttcProductPrice > 0)
    local productHasAmount = not productIsBound and isTtcAvailable and ((ttcProductPriceInfo.AmountCount or 0) > 0 or ((ttcProductPriceInfo.Min or 0) > 0 and (ttcProductPriceInfo.Max or 0) > 0))

    local addedAny = false
    -- Bound items (including treasure) can't be sold on the guild store, so market price is irrelevant.
    -- Show only the vendor/game price with no TTC price and no market labels.
    local displayTtcPrice = isBound and 0 or ttcPrice
    local suppressNoDataLabel = isBound
    if hasValue then
        section:AddLine(getPriceSummary(gamePrice, gameMaxPrice, displayTtcPrice, nil, suppressNoDataLabel))
        addedAny = true
    end
    if hasValue and stackSize > 1 then
        section:AddLine(getPriceSummary(getStackPrice(gamePrice, stackSize), getStackPrice(gameMaxPrice, stackSize), getStackPrice(displayTtcPrice, stackSize), zo_strformat(SI_GPH_TOOLTIPPRICE_STACK_OF, stackSize), suppressNoDataLabel))
        addedAny = true
    end
    if hasAmount then
        section:AddLine(getPriceBreakdown(ttcPriceInfo))
        addedAny = true
    end
    if productHasValue then
        section:AddLine(getPriceSummary(gameProductPrice, gameProductPrice, productIsBound and 0 or ttcProductPrice, GetString(SI_GPH_TOOLTIPPRICE_PRODUCT), productIsBound))
        addedAny = true
    end
    if productHasAmount then
        section:AddLine(getPriceBreakdown(ttcProductPriceInfo))
        addedAny = true
    end
    if addedAny then
        section:AddLine(" ")
    end

    self.__gph_priceAdded = addedAny
    self:AddSection(section)
end

local function Tooltip_AddItemValue_Before(self, itemLink)
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv or not sv.tooltipPriceEnabled then return end
    -- Only suppress ESO's default value line when we've already added our own.
    -- If we couldn't determine a price (e.g. stolen items with 0 merchant value),
    -- fall through so ESO's built-in value is still visible.
    if self.__gph_priceAdded then
        return true
    end
end

local function ShouldSuppressExternalPriceLine(lineText)
    if type(lineText) ~= "string" then return false end
    local lower = string.lower(lineText)
    for _, pattern in ipairs(SUPPRESS_EXTERNAL_PRICE_PATTERNS) do
        if string.find(lower, pattern, 1, true) then
        return true
        end
    end
    return false
end

local function Tooltip_AddLine_Before(self, lineText)
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv or not sv.tooltipPriceEnabled then return end
    if ShouldSuppressExternalPriceLine(lineText) then
        return true
    end
end

local function TooltipSection_AddLine_Before(self, lineText)
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv or not sv.tooltipPriceEnabled then return end
    if ShouldSuppressExternalPriceLine(lineText) then
        return true
    end
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
    local gamepadTooltip = GAMEPAD_TOOLTIPS:GetTooltip(tooltip)
    ZO_PreHook(gamepadTooltip, "LayoutBagItem", Tooltip_LayoutBagItem_Before)
    if type(gamepadTooltip.LayoutItemWithStackCount) == "function" then
        ZO_PreHook(gamepadTooltip, "LayoutItemWithStackCount", Tooltip_LayoutItemWithStackCount_Before)
    end
    ZO_PostHook(gamepadTooltip, "AddItemTitle", Tooltip_AddItemTitle_After)
    ZO_PreHook(gamepadTooltip, "AddItemValue", Tooltip_AddItemValue_Before)
    ZO_PreHook(gamepadTooltip, "AddLine", Tooltip_AddLine_Before)
end

-- Some addons inject lines at the tooltip section level instead of tooltip:AddLine.
if ZO_TooltipSection and ZO_TooltipSection.AddLine then
    ZO_PreHook(ZO_TooltipSection, "AddLine", TooltipSection_AddLine_Before)
end

-- TTC Price Support for Crafting Panels (Gamepad UI)
-- Adapted from TamrielTradeCentre's keyboard implementation

local MATERIAL_ICON = zo_iconFormatInheritColor("EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_materials.dds", 24, 24)

local function GetMaterialCostTotal(craftType, patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)
    local totalTtcCost = 0
    local totalGameCost = 0
    local materialLinks = {}

    -- Get material item link based on crafting type
    local materialLink = GetSmithingPatternMaterialItemLink(patternIndex, materialIndex)
    if materialLink then
        local matPriceInfo = SafeGetPriceInfo(materialLink)
        if matPriceInfo then
            local matTtcPrice = (matPriceInfo.SuggestedPrice or 0) > 0 and matPriceInfo.SuggestedPrice or (matPriceInfo.Avg or 0)
            local matGamePrice = GetItemLinkValue(materialLink, false)
            totalTtcCost = totalTtcCost + (matTtcPrice * materialQuantity)
            totalGameCost = totalGameCost + (matGamePrice * materialQuantity)
            table.insert(materialLinks, {link = materialLink, qty = materialQuantity, ttcPrice = matTtcPrice, gamePrice = matGamePrice})
        end
    end

    -- Get style material
    local styleLink = GetItemStyleMaterialLink(styleIndex)
    if styleLink then
        local stylePriceInfo = SafeGetPriceInfo(styleLink)
        if stylePriceInfo then
            local styleTtcPrice = (stylePriceInfo.SuggestedPrice or 0) > 0 and stylePriceInfo.SuggestedPrice or (stylePriceInfo.Avg or 0)
            local styleGamePrice = GetItemLinkValue(styleLink, false)
            totalTtcCost = totalTtcCost + styleTtcPrice
            totalGameCost = totalGameCost + styleGamePrice
            table.insert(materialLinks, {link = styleLink, qty = 1, ttcPrice = styleTtcPrice, gamePrice = styleGamePrice})
        end
    end

    -- Get trait material (if applicable)
    if traitIndex and traitIndex > 0 then
        local traitLink = GetSmithingTraitItemLink(traitIndex)
        if traitLink then
            local traitPriceInfo = SafeGetPriceInfo(traitLink)
            if traitPriceInfo then
                local traitTtcPrice = (traitPriceInfo.SuggestedPrice or 0) > 0 and traitPriceInfo.SuggestedPrice or (traitPriceInfo.Avg or 0)
                local traitGamePrice = GetItemLinkValue(traitLink, false)
                totalTtcCost = totalTtcCost + traitTtcPrice
                totalGameCost = totalGameCost + traitGamePrice
                table.insert(materialLinks, {link = traitLink, qty = 1, ttcPrice = traitTtcPrice, gamePrice = traitGamePrice})
            end
        end
    end

    return totalTtcCost, totalGameCost, materialLinks
end

local function GetProvisioningMaterialCost(recipeListIndex, recipeIndex)
    local totalTtcCost = 0
    local totalGameCost = 0
    local materialLinks = {}

    local numIngredients = select(3, GetRecipeInfo(recipeListIndex, recipeIndex))
    for i = 1, numIngredients do
        local itemLink = GetRecipeIngredientItemLink(recipeListIndex, recipeIndex, i)
        if itemLink then
            local reqQty = GetRecipeIngredientRequiredQuantity(recipeListIndex, recipeIndex, i)
            local priceInfo = SafeGetPriceInfo(itemLink)
            if priceInfo then
                local ttcPrice = (priceInfo.SuggestedPrice or 0) > 0 and priceInfo.SuggestedPrice or (priceInfo.Avg or 0)
                local gamePrice = GetItemLinkValue(itemLink, false)
                totalTtcCost = totalTtcCost + (ttcPrice * reqQty)
                totalGameCost = totalGameCost + (gamePrice * reqQty)
                table.insert(materialLinks, {link = itemLink, qty = reqQty, ttcPrice = ttcPrice, gamePrice = gamePrice})
            end
        end
    end

    return totalTtcCost, totalGameCost, materialLinks
end

-- enchantingInstance is ENCHANTING (keyboard) or GAMEPAD_ENCHANTING (gamepad)
-- GetAllCraftingBagAndSlots() returns potencyBag, potencySlot, essenceBag, essenceSlot, aspectBag, aspectSlot
local function GetEnchantingMaterialCost(enchantingInstance)
    if not enchantingInstance or type(enchantingInstance.GetAllCraftingBagAndSlots) ~= "function" then
        return 0, 0, {}
    end
    local totalTtcCost = 0
    local totalGameCost = 0
    local materialLinks = {}

    local b1, s1, b2, s2, b3, s3 = enchantingInstance:GetAllCraftingBagAndSlots()
    for _, pair in ipairs({{b1, s1}, {b2, s2}, {b3, s3}}) do
        local bag, slot = pair[1], pair[2]
        if bag and slot then
            local link = GetItemLink(bag, slot)
            if link and link ~= "" then
                local priceInfo = SafeGetPriceInfo(link)
                if priceInfo then
                    local ttcPrice = (priceInfo.SuggestedPrice or 0) > 0 and priceInfo.SuggestedPrice or (priceInfo.Avg or 0)
                    local gamePrice = GetItemLinkValue(link, false)
                    totalTtcCost = totalTtcCost + ttcPrice
                    totalGameCost = totalGameCost + gamePrice
                    table.insert(materialLinks, {link = link, qty = 1, ttcPrice = ttcPrice, gamePrice = gamePrice})
                end
            end
        end
    end

    return totalTtcCost, totalGameCost, materialLinks
end

local function GetAlchemyMaterialCostFromInstance(instance)
    local totalTtcCost = 0
    local totalGameCost = 0
    local materialLinks = {}

    if not instance or type(instance.GetAllCraftingBagAndSlots) ~= "function" then
        return totalTtcCost, totalGameCost, materialLinks
    end

    -- Returns: solventBag, solventSlot, bag1, slot1, bag2, slot2, bag3, slot3
    local sb, ss, b1, s1, b2, s2, b3, s3 = instance:GetAllCraftingBagAndSlots()
    local pairs = {{sb, ss}, {b1, s1}, {b2, s2}, {b3, s3}}
    for _, pair in ipairs(pairs) do
        local bag, slot = pair[1], pair[2]
        if bag and slot then
            local link = GetItemLink(bag, slot)
            if link and link ~= "" then
                local priceInfo = SafeGetPriceInfo(link)
                if priceInfo then
                    local ttcPrice = (priceInfo.SuggestedPrice or 0) > 0 and priceInfo.SuggestedPrice or (priceInfo.Avg or 0)
                    local gamePrice = GetItemLinkValue(link, false)
                    totalTtcCost = totalTtcCost + ttcPrice
                    totalGameCost = totalGameCost + gamePrice
                    table.insert(materialLinks, {link = link, qty = 1, ttcPrice = ttcPrice, gamePrice = gamePrice})
                end
            end
        end
    end

    return totalTtcCost, totalGameCost, materialLinks
end

local function GetAlchemyMaterialCost()
    return GetAlchemyMaterialCostFromInstance(ALCHEMY)
end

local function GetImprovementMaterialCost(improvementInstance, craftingType)
    local boosterIndex = improvementInstance and improvementInstance.boosterSlot and improvementInstance.boosterSlot.index
    if not boosterIndex then return 0, 0, {} end

    local boosterLink = GetSmithingImprovementItemLink(craftingType, boosterIndex, LINK_STYLE_DEFAULT)
    if not boosterLink or boosterLink == "" then return 0, 0, {} end

    local qty = 1
    if type(improvementInstance.GetNumBoostersToApply) == "function" then
        qty = improvementInstance:GetNumBoostersToApply()
    end

    local priceInfo = SafeGetPriceInfo(boosterLink)
    if not priceInfo then return 0, 0, {} end

    local ttcPrice = (priceInfo.SuggestedPrice or 0) > 0 and priceInfo.SuggestedPrice or (priceInfo.Avg or 0)
    local gamePrice = GetItemLinkValue(boosterLink, false)
    return ttcPrice * qty, gamePrice * qty, {{link = boosterLink, qty = qty, ttcPrice = ttcPrice * qty, gamePrice = gamePrice * qty}}
end

-- toolTipControl can be a control directly, or a function(self) that returns one
-- (needed for gamepad panels where the tooltip is self.resultTooltip.tip)
local valueSuppressedTooltips = setmetatable({}, { __mode = "k" })

local function ResolveTooltipControl(control)
    if not control then return nil end
    if control.AcquireSection and control.AddSection then
        return control
    end
    local tip = nil
    if type(control) == "table" then
        tip = rawget(control, "tip")
    end
    if tip == nil then
        local ok, result = pcall(function() return control.tip end)
        if ok then tip = result end
    end
    if tip and tip.AcquireSection and tip.AddSection then
        return tip
    end
    local tooltip = nil
    if type(control) == "table" then
        tooltip = rawget(control, "tooltip")
    end
    if tooltip == nil then
        local ok, result = pcall(function() return control.tooltip end)
        if ok then tooltip = result end
    end
    if tooltip and tooltip.AcquireSection and tooltip.AddSection then
        return tooltip
    end
    return nil
end

local function EnsureValueSuppressedForTooltip(tooltipControl)
    if not tooltipControl or valueSuppressedTooltips[tooltipControl] then return end
    valueSuppressedTooltips[tooltipControl] = true
    if tooltipControl.AddItemValue then
        ZO_PreHook(tooltipControl, "AddItemValue", Tooltip_AddItemValue_Before)
    end
end

local function AddCraftingPriceTooltip(hookObject, toolTipControl, functionName, getItemLinkFunction, getMaterialCostFunction)
    ZO_PreHook(hookObject, functionName, function(...)
        local sv = _G["GamePadHelper_CharSavedVars"]
        if not sv or not sv.tooltipPriceEnabled then return end
        if not IsInGamepadPreferredMode() then return end
        local actualTooltipControl = toolTipControl
        if type(toolTipControl) == "function" then
            actualTooltipControl = toolTipControl(select(1, ...))
        end
        local tooltip = ResolveTooltipControl(actualTooltipControl)
        if tooltip then
            tooltip.__gph_priceAdded = true
        end
        EnsureValueSuppressedForTooltip(tooltip)
    end)

    SecurePostHook(hookObject, functionName, function(...)
        local sv = _G["GamePadHelper_CharSavedVars"]
        if not sv or not sv.tooltipPriceEnabled then return end
        if not IsInGamepadPreferredMode() then return end
        local actualTooltipControl = toolTipControl
        if type(toolTipControl) == "function" then
            actualTooltipControl = toolTipControl(select(1, ...))
        end
        local tooltip = ResolveTooltipControl(actualTooltipControl)
        if not tooltip then return end
        EnsureValueSuppressedForTooltip(tooltip)

        local itemLink = getItemLinkFunction(...)
        if itemLink == nil then
            return
        end
        local isBound = IsBoundItemLink(itemLink)

        local ttcPriceInfo = SafeGetPriceInfo(itemLink)
        local ttcPrice = 0
        if ttcPriceInfo then
            ttcPrice = (ttcPriceInfo.SuggestedPrice or 0) > 0
                and ttcPriceInfo.SuggestedPrice
                or (ttcPriceInfo.Avg or 0)
        end

        local gamePrice = GetItemLinkValue(itemLink, false)
        local hasValue = gamePrice > 0 or ttcPrice > 0

        local hasMaterialCost = false
        local totalMaterialTtcCost = 0
        local totalMaterialGameCost = 0

        -- Get material costs if function provided
        if getMaterialCostFunction then
            local matTtcCost, matGameCost, _ = getMaterialCostFunction(...)
            matTtcCost = matTtcCost or 0
            matGameCost = matGameCost or 0
            if matTtcCost > 0 or matGameCost > 0 then
                totalMaterialTtcCost = matTtcCost
                totalMaterialGameCost = matGameCost
                hasMaterialCost = true
            end
        end

        if hasValue or hasMaterialCost then
            local outerSection = tooltip:AcquireSection({
                paddingTop = 3,
                paddingBottom = 3,
                customSpacing = 5,
                childSpacing = 5,
                widthPercent = 100,
                layoutPrimaryDirection = "right",
                layoutSecondaryDirection = "down",
                layoutPrimaryDirectionCentered = true,
            })

            local section = outerSection:AcquireSection({
                paddingTop = 0,
                paddingBottom = 0,
                customSpacing = 5,
                childSpacing = 5,
                widthPercent = 80,
                horizontalAlignment = TEXT_ALIGN_LEFT,
                fontSize = 38,
                fontFace = "$(GAMEPAD_LIGHT_FONT)",
                fontColorType = INTERFACE_COLOR_TYPE_TEXT_COLORS,
                fontColorField = INTERFACE_TEXT_COLOR_NORMAL,
                fontStyle = "soft-shadow-thick",
                uppercase = false,
            })
            section:AddLine(" ")

            -- Show material costs
            if hasMaterialCost then
                local matGameText = SafeFormatNumber(totalMaterialGameCost, 0)
                if totalMaterialTtcCost > 0 then
                    local matCostText = SafeFormatNumber(totalMaterialTtcCost, 0)
                    section:AddLine(COLOR_TITLE:Colorize(string.format(
                        "%s %s %s %s",
                        PRICE_ICON,
                        COLOR_GAME:Colorize(matGameText),
                        COLOR_TTC:Colorize(matCostText),
                        GetString(SI_GPH_TOOLTIPPRICE_MATERIALS)
                    )))
                else
                    section:AddLine(COLOR_TITLE:Colorize(string.format(
                        "%s %s %s",
                        PRICE_ICON,
                        COLOR_GAME:Colorize(matGameText),
                        COLOR_DETAILS:Colorize(GetString(SI_GPH_TOOLTIPPRICE_GAME_MATERIALS))
                    )))
                end
            end

            -- Show result item price
            if hasValue then
                section:AddLine(getPriceSummary(gamePrice, gamePrice, isBound and 0 or ttcPrice, nil, isBound))
            end

            if not isBound and ((ttcPriceInfo.AmountCount and ttcPriceInfo.AmountCount > 0)
                or ((ttcPriceInfo.Min or 0) > 0 and (ttcPriceInfo.Max or 0) > 0)) then
                section:AddLine(getPriceBreakdown(ttcPriceInfo))
            end
            section:AddLine(" ")

            outerSection:AddSection(section)
            tooltip:AddSection(outerSection)
            tooltip.__gph_priceAdded = true
        end
    end)
end

local craftingHooksDone = {}

-- Initialize crafting panel hooks
local function InitializeCraftingHooks()
    if not craftingHooksDone.keyboard then
        craftingHooksDone.keyboard = true

    -- Hook into Smithing Improvement Panel
    if ZO_SmithingTopLevelImprovementPanelResultTooltip then
        AddCraftingPriceTooltip(
        ZO_SmithingImprovement,
        ZO_SmithingTopLevelImprovementPanelResultTooltip,
        "SetupResultTooltip",
        function(self, bagId, slotIndex, craftingType)
                if bagId == nil or slotIndex == nil then return nil end
                return GetSmithingImprovedItemLink(bagId, slotIndex, craftingType, LINK_STYLE_DEFAULT)
        end,
        function(self, bagId, slotIndex, craftingType)
                return GetImprovementMaterialCost(self, craftingType)
        end
        )
    end

    -- Hook into Smithing Creation/Crafting Panel
    if ZO_SmithingTopLevelCreationPanelResultTooltip then
        AddCraftingPriceTooltip(ZO_SmithingCreation, ZO_SmithingTopLevelCreationPanelResultTooltip, "SetupResultTooltip", function(_, patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)
        return GetSmithingPatternResultLink(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)
        end, function(_, patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)
        if patternIndex == nil or materialIndex == nil then
                return 0, 0
        end
        return GetMaterialCostTotal(nil, patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)
        end)
    end

    -- Hook into Provisioning (Cooking) Panel
    if ZO_ProvisionerTopLevelTooltip then
        AddCraftingPriceTooltip(ZO_Provisioner, ZO_ProvisionerTopLevelTooltip, "RefreshRecipeDetails", function(control)
        local recipeData = control:GetRecipeData()
        if recipeData == nil then
                return nil
        end
        return GetRecipeResultItemLink(control:GetSelectedRecipeListIndex(), control:GetSelectedRecipeIndex())
        end, function(control)
        local recipeListIndex = control:GetSelectedRecipeListIndex()
        local recipeIndex = control:GetSelectedRecipeIndex()
        if recipeListIndex == nil or recipeIndex == nil then
                return 0, 0
        end
        return GetProvisioningMaterialCost(recipeListIndex, recipeIndex)
        end)
    end

    -- Hook into Enchanting Panel
    if ZO_EnchantingTopLevelTooltip then
        AddCraftingPriceTooltip(ZO_Enchanting, ZO_EnchantingTopLevelTooltip, "UpdateTooltip", function()
        return ENCHANTING:GetResultItemLink()
        end, function()
        return GetEnchantingMaterialCost(ENCHANTING)
        end)
    end

    -- Hook into Alchemy Panel
    if ZO_AlchemyTopLevelTooltip then
        AddCraftingPriceTooltip(ZO_Alchemy, ZO_AlchemyTopLevelTooltip, "UpdateTooltip", function()
        return ALCHEMY:GetResultItemLink()
        end, function()
        return GetAlchemyMaterialCost()
        end)
    end

    end -- craftingHooksDone.keyboard

    -- Gamepad hooks (run once only since class tables are always present)
    if not craftingHooksDone.gamepad then
        craftingHooksDone.gamepad = true

        -- Gamepad: Smithing Creation Panel
        if ZO_GamepadSmithingCreation then
        AddCraftingPriceTooltip(
                ZO_GamepadSmithingCreation,
                function(self) return self and self.resultTooltip and self.resultTooltip.tip end,
                "SetupResultTooltip",
                function(_, patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)
                    return GetSmithingPatternResultLink(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)
                end,
                function(_, patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)
                    if patternIndex == nil or materialIndex == nil then return 0, 0 end
                    return GetMaterialCostTotal(nil, patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)
                end
        )
        end

        -- Gamepad: Provisioning Panel
        if ZO_GamepadProvisioner then
        AddCraftingPriceTooltip(
                ZO_GamepadProvisioner,
                function(self) return self and self.resultTooltip and self.resultTooltip.tip end,
                "RefreshRecipeDetails",
                function(_, selectedData)
                    if selectedData == nil then return nil end
                    local recipeListIndex = selectedData.recipeListIndex
                    local recipeIndex = selectedData.recipeIndex
                    if recipeListIndex == nil or recipeIndex == nil then return nil end
                    return GetRecipeResultItemLink(recipeListIndex, recipeIndex)
                end,
                function(_, selectedData)
                    if selectedData == nil then return 0, 0 end
                    local recipeListIndex = selectedData.recipeListIndex
                    local recipeIndex = selectedData.recipeIndex
                    if recipeListIndex == nil or recipeIndex == nil then return 0, 0 end
                    return GetProvisioningMaterialCost(recipeListIndex, recipeIndex)
                end
        )
        end

        -- Gamepad: Enchanting Panel
        -- self.resultTooltip.tip is the tooltip; GetResultItemLink is inherited from ZO_SharedEnchanting
        if ZO_GamepadEnchanting then
        AddCraftingPriceTooltip(
                ZO_GamepadEnchanting,
                function(self) return self and self.resultTooltip and self.resultTooltip.tip end,
                "UpdateTooltip",
                function(self) return self:GetResultItemLink() end,
                function(self) return GetEnchantingMaterialCost(GAMEPAD_ENCHANTING or self) end
        )
        end

        -- Gamepad: Alchemy Panel
        -- uses self.tooltip (not self.resultTooltip); GetResultItemLink and GetSlotItemLink inherited from ZO_SharedAlchemy
        if ZO_GamepadAlchemy then
        AddCraftingPriceTooltip(
                ZO_GamepadAlchemy,
                function(self) return self and self.tooltip and self.tooltip.tip end,
                "UpdateTooltip",
                function(self)
                    local instance = GAMEPAD_ALCHEMY or self
                    if type(instance.GetResultItemLink) ~= "function" then return nil end
                    return instance:GetResultItemLink()
                end,
                function(self) return GetAlchemyMaterialCostFromInstance(GAMEPAD_ALCHEMY or self) end
        )
        end

        -- Gamepad: Smithing Improvement Panel
        if ZO_GamepadSmithingImprovement then
        AddCraftingPriceTooltip(
                ZO_GamepadSmithingImprovement,
                function(self) return self and self.resultTooltip and self.resultTooltip.tip end,
                "SetupResultTooltip",
                function(self, bagId, slotIndex, craftingType)
                    if bagId == nil or slotIndex == nil then return nil end
                    return GetSmithingImprovedItemLink(bagId, slotIndex, craftingType, LINK_STYLE_DEFAULT)
                end,
                function(self, bagId, slotIndex, craftingType)
                    return GetImprovementMaterialCost(self, craftingType)
                end
        )
        end
    end
end

-- Try to initialize immediately, and also register for scene callbacks
InitializeCraftingHooks()

-- Also try to register callback for when gamepad crafting station is shown
local function OnCraftingSceneStateChanged(scene, oldState, newState)
    if newState == SCENE_SHOWING then
        -- Re-initialize hooks when craft scene shows
        InitializeCraftingHooks()
    end
end

-- Try to register for various crafting scenes
local craftingScenes = {"smithing", "provisioner", "enchanting", "alchemy"}
for _, sceneName in ipairs(craftingScenes) do
    local scene = SCENE_MANAGER:GetScene(sceneName .. "Gamepad")
    if scene then
        scene:RegisterCallback("StateChange", OnCraftingSceneStateChanged)
    end
    -- Also try keyboard scenes
    local kbScene = SCENE_MANAGER:GetScene(sceneName)
    if kbScene then
        kbScene:RegisterCallback("StateChange", OnCraftingSceneStateChanged)
    end
end

