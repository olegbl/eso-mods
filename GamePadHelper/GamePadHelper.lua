local ADDON_NAME = "GamePadHelper"
local ADDON_VERSION = 1.04

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
    antiquariansEyeEnabled = true,
    dungeonFinderEnabled = true,
    provisioningEnabled = true,
    lootOffsetEnabled = true,
    lootOffset = 350,
    showLowLevelRecipes = false,
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
            d("  /gph eye - Toggle auto Antiquarian's Eye (current: " .. (savedVars.antiquariansEyeEnabled and "|c00FF00ON|r" or "|cFF0000OFF|r") .. ")")
            d("  /gph dungeon - Toggle dungeon finder (current: " .. (savedVars.dungeonFinderEnabled and "|c00FF00ON|r" or "|cFF0000OFF|r") .. ")")
            d("  /gph provisioning - Toggle provisioning filter (current: " .. (savedVars.provisioningEnabled and "|c00FF00ON|r" or "|cFF0000OFF|r") .. ")")
            d("  /gph loot - Toggle loot offset (current: " .. (savedVars.lootOffsetEnabled and "|c00FF00ON|r" or "|cFF0000OFF|r") .. ")")
            d("  /gph loot <number> - Set loot offset value (current: " .. savedVars.lootOffset .. ")")
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
        elseif command == "eye" then
            savedVars.antiquariansEyeEnabled = not savedVars.antiquariansEyeEnabled
            d("|c3399FF[GamePadHelper]|r Auto Antiquarian's Eye " .. (savedVars.antiquariansEyeEnabled and "|c00FF00ENABLED|r" or "|cFF0000DISABLED|r"))
        elseif command == "dungeon" then
            savedVars.dungeonFinderEnabled = not savedVars.dungeonFinderEnabled
            d("|c3399FF[GamePadHelper]|r Dungeon finder " .. (savedVars.dungeonFinderEnabled and "|c00FF00ENABLED|r" or "|cFF0000DISABLED|r"))
        elseif command == "provisioning" then
            savedVars.provisioningEnabled = not savedVars.provisioningEnabled
            d("|c3399FF[GamePadHelper]|r Provisioning filter " .. (savedVars.provisioningEnabled and "|c00FF00ENABLED|r" or "|cFF0000DISABLED|r"))
        elseif command == "loot" then
            if #args == 1 then
                savedVars.lootOffsetEnabled = not savedVars.lootOffsetEnabled
                d("|c3399FF[GamePadHelper]|r Loot offset " .. (savedVars.lootOffsetEnabled and "|c00FF00ENABLED|r" or "|cFF0000DISABLED|r"))
            elseif #args == 2 then
                local offset = tonumber(args[2])
                if offset then
                    savedVars.lootOffset = offset
                    d("|c3399FF[GamePadHelper]|r Loot offset set to " .. offset)
                else
                    d("|c3399FF[GamePadHelper]|r Invalid offset value. Use a number.")
                end
            end
        else
            d("|c3399FF[GamePadHelper]|r Unknown command. Use /gph for help.")
        end
    end

    -- Make saved variables globally accessible for submodules
    _G["GamePadHelper_SavedVars"] = savedVars
end


EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
