-- GamePadHelper_Provisioning
-- Adds a filter option to hide low-level recipes (under CP160) in the provisioning interface

local addonName = "GamePadHelper_Provisioning"

local SHOW_LOW_LEVEL_SETTING_KEY = "SHOW_LOW_LEVEL_RECIPES"
local showLowLevelFilter = {
    filterName = "Show Low Level Recipes",
    filterTooltip = "Shows Recipes under CP160",
    checked = false,
}

local function HideRecipies(recipeList)
    if GamePadHelper_SavedVars[SHOW_LOW_LEVEL_SETTING_KEY] then
        return false
    end

    local i = 1
    while i < recipeList:GetNumEntries() do
        local recipe = recipeList:GetEntryData(i):GetDataSource()
        if recipe then
            local itemLink = GetRecipeResultItemLink(recipe.recipeListIndex, recipe.recipeIndex)
            local hasAbility, abilityHeader, abilityDescription, cooldown, hasScaling, minLevel, maxLevel, isChampionPoints, remainingCooldown = GetItemLinkOnUseAbilityInfo(itemLink)
            if hasScaling and maxLevel < 160 then
                local template = recipeList.templateList[i]
                local recipeData = recipeList.dataList[i]
                if template == "ZO_GamepadItemSubEntryTemplateWithHeader" and
                        i + 1 <= recipeList:GetNumEntries() and
                        not recipeList.dataList[i + 1].header then
                    recipeList.dataList[i + 1].header = recipeData.header
                    recipeList.templateList[i + 1] = template
                end
                recipeList:RemoveEntry(template, recipeData)
                i = i - 1
            end
        end
        i = i + 1
    end

    return false
end

local function AddCustomOptions(dialog, dialogData)
    showLowLevelFilter.checked = GamePadHelper_SavedVars[SHOW_LOW_LEVEL_SETTING_KEY]
    table.insert(dialogData.filters, showLowLevelFilter)
end

local function SaveOptions()
    if GamePadHelper_SavedVars[SHOW_LOW_LEVEL_SETTING_KEY] ~= showLowLevelFilter.checked then
        GamePadHelper_SavedVars[SHOW_LOW_LEVEL_SETTING_KEY] = showLowLevelFilter.checked
        GAMEPAD_PROVISIONER:DirtyRecipeList()
    end
end

local function HookOptions()
    if not GAMEPAD_PROVISIONER.craftingOptionsDialogGamepad then
        GAMEPAD_PROVISIONER.craftingOptionsDialogGamepad = ZO_CraftingOptionsDialogGamepad:New()
        ZO_PreHook(GAMEPAD_PROVISIONER.craftingOptionsDialogGamepad, "ShowOptionsDialog", AddCustomOptions)
    end
end

local function OnAddonLoaded(event, name)
    if name ~= addonName then return end
    EVENT_MANAGER:UnregisterForEvent(addonName, EVENT_ADD_ON_LOADED)

    -- Check if provisioning is enabled in GamePadHelper
    if not GamePadHelper_SavedVars or not GamePadHelper_SavedVars.provisioningEnabled then return end

    -- Initialize settings
    GamePadHelper_SavedVars[SHOW_LOW_LEVEL_SETTING_KEY] = GamePadHelper_SavedVars[SHOW_LOW_LEVEL_SETTING_KEY] or false
    showLowLevelFilter.checked = GamePadHelper_SavedVars[SHOW_LOW_LEVEL_SETTING_KEY]

    -- Apply hooks
    ZO_PreHook(GAMEPAD_PROVISIONER.recipeList, "Commit", HideRecipies)
    ZO_PostHook(GAMEPAD_PROVISIONER, "SaveFilters", SaveOptions)
    ZO_PreHook(GAMEPAD_PROVISIONER, "ShowOptionsMenu", HookOptions)
end

EVENT_MANAGER:RegisterForEvent(addonName, EVENT_ADD_ON_LOADED, OnAddonLoaded)