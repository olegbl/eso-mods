-- Provisioning
-- Adds a filter option to hide low-level recipes (under CP160) in the provisioning interface

local showLowLevelFilter = {
    filterName = GetString(SI_GPH_PROVISIONING_HIDE_LOW_LEVEL),
    filterTooltip = GetString(SI_GPH_PROVISIONING_HIDE_LOW_LEVEL_TOOLTIP),
}

local function HideRecipes(recipeList)
    local sv = _G["GamePadHelper_SavedVars"]
    if not sv or not sv.showLowLevelRecipes then
        return false
    end

    local hiddenCount = 0
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
                hiddenCount = hiddenCount + 1
                i = i - 1
            end
        end
        i = i + 1
    end

    return false
end

local function AddCustomOptions(dialog, dialogData)
    local sv = _G["GamePadHelper_SavedVars"]
    showLowLevelFilter.checked = sv and sv.showLowLevelRecipes
    table.insert(dialogData.filters, showLowLevelFilter)
end

local function SaveOptions()
    local sv = _G["GamePadHelper_SavedVars"]
    if not sv then return end
    if sv.showLowLevelRecipes ~= showLowLevelFilter.checked then
        sv.showLowLevelRecipes = showLowLevelFilter.checked
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
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("Provisioning", EVENT_ADD_ON_LOADED)

    local sv = _G["GamePadHelper_SavedVars"]
    if sv then
        showLowLevelFilter.checked = sv.showLowLevelRecipes
    end

    ZO_PreHook(GAMEPAD_PROVISIONER.recipeList, "Commit", HideRecipes)
    ZO_PostHook(GAMEPAD_PROVISIONER, "SaveFilters", SaveOptions)
    ZO_PreHook(GAMEPAD_PROVISIONER, "ShowOptionsMenu", HookOptions)
end

EVENT_MANAGER:RegisterForEvent("Provisioning", EVENT_ADD_ON_LOADED, OnAddonLoaded)
