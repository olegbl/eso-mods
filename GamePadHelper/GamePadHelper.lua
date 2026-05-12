local ADDON_NAME = "GamePadHelper"
local ADDON_VERSION = 1.06

-- Make ADDON_NAME globally accessible for submodules
_G["ADDON_NAME"] = ADDON_NAME

-- Ensure ESO API compatibility
if GetAPIVersion() < 101047 then
    d("[" .. ADDON_NAME .. "] ESO API version too old. Requires API 101047 or higher.")
    return
end

local function IsConsole()
    return IsConsoleUI and IsConsoleUI() or false
end
_G["GamePadHelper_IsConsole"] = IsConsole

-- Default saved variables
local defaults = {
    fishingEnabled = true,
    fishingAlternativeBaits = true,
    autoRepairEnabled = true,
    autoChargeEnabled = true,
    antiquariansEyeEnabled = true,
    dungeonFinderEnabled = true,
    teleporterEnabled = true,
    lootOffsetEnabled = true,
    lootOffset = 350,
    showLowLevelRecipes = true,
    tooltipTraitEnabled = true,
    tooltipPriceEnabled = true,
    gearComparisonEnabled = true,
    inventoryTraitEnabled = true,
    inventoryCovetousCountessEnabled = true,
    overviewEnabled = true,
    tooltipPoisonEnabled = true,
    tooltipFontEnabled = true,
    tooltipEnchantmentEnabled = true,
}

local savedVars

local function OnAddonLoaded(event, addonName)
    if addonName ~= ADDON_NAME then return end
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    savedVars = ZO_SavedVars:NewAccountWide("GamePadHelperSavedVars", 1, nil, defaults)

    -- Make saved variables globally accessible for submodules
    _G["GamePadHelper_SavedVars"] = savedVars
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
