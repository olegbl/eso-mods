local ADDON_NAME = "GamePadHelper"
local ADDON_VERSION = 1.03

-- Ensure ESO API compatibility
if GetAPIVersion() < 101047 then
    d("[" .. ADDON_NAME .. "] ESO API version too old. Requires API 101047 or higher.")
    return
end

-- Default saved variables
local defaults = {
    fishingEnabled = true,
    fishingAlternativeBaits = true,
    autoRepairEnabled = true,
    autoChargeEnabled = true,
}

-- Saved variables
local savedVars

-- Load saved variables
local function OnAddonLoaded(event, addonName)
    if addonName ~= ADDON_NAME then return end
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    savedVars = ZO_SavedVars:NewAccountWide("GamePadHelperSavedVars", 1, nil, defaults)

    -- Register slash commands
    SLASH_COMMANDS["/gph"] = function(cmd)
        local args = {}
        for arg in cmd:gmatch("%S+") do
            table.insert(args, arg:lower())
        end

        if #args == 0 then
            d("|c3399FF[GamePadHelper]|r Commands:")
            d("  /gph fish - Toggle fishing module (current: " .. (savedVars.fishingEnabled and "|c00FF00ON|r" or "|cFF0000OFF|r") .. ")")
            d("  /gph bait - Toggle alternative baits (current: " .. (savedVars.fishingAlternativeBaits and "|c00FF00ON|r" or "|cFF0000OFF|r") .. ")")
            d("  /gph repair - Toggle auto repair (current: " .. (savedVars.autoRepairEnabled and "|c00FF00ON|r" or "|cFF0000OFF|r") .. ")")
            d("  /gph charge - Toggle auto charge (current: " .. (savedVars.autoChargeEnabled and "|c00FF00ON|r" or "|cFF0000OFF|r") .. ")")
            return
        end

        local command = args[1]

        if command == "fish" then
            savedVars.fishingEnabled = not savedVars.fishingEnabled
            d("|c3399FF[GamePadHelper]|r Fishing module " .. (savedVars.fishingEnabled and "|c00FF00ENABLED|r" or "|cFF0000DISABLED|r"))
        elseif command == "bait" then
            savedVars.fishingAlternativeBaits = not savedVars.fishingAlternativeBaits
            d("|c3399FF[GamePadHelper]|r Alternative baits " .. (savedVars.fishingAlternativeBaits and "|c00FF00ENABLED|r" or "|cFF0000DISABLED|r"))
        elseif command == "repair" then
            savedVars.autoRepairEnabled = not savedVars.autoRepairEnabled
            d("|c3399FF[GamePadHelper]|r Auto repair " .. (savedVars.autoRepairEnabled and "|c00FF00ENABLED|r" or "|cFF0000DISABLED|r"))
        elseif command == "charge" then
            savedVars.autoChargeEnabled = not savedVars.autoChargeEnabled
            d("|c3399FF[GamePadHelper]|r Auto charge " .. (savedVars.autoChargeEnabled and "|c00FF00ENABLED|r" or "|cFF0000DISABLED|r"))
        else
            d("|c3399FF[GamePadHelper]|r Unknown command. Use /gph for help.")
        end
    end

    -- Make saved variables globally accessible for submodules
    _G["GamePadHelper_SavedVars"] = savedVars
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)