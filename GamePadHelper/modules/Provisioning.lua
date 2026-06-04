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

    -- Pass 1: mark low-level recipes for removal
    local toRemove = {}
    for i = 1, recipeList:GetNumEntries() do
        local recipe = recipeList:GetEntryData(i):GetDataSource()
        if recipe then
            local itemLink = GetRecipeResultItemLink(recipe.recipeListIndex, recipe.recipeIndex)
            local hasAbility, abilityHeader, abilityDescription, cooldown, hasScaling, minLevel, maxLevel, isChampionPoints, remainingCooldown = GetItemLinkOnUseAbilityInfo(itemLink)
            if hasScaling and maxLevel < 160 then
                toRemove[i] = true
            end
        end
    end

    -- Pass 2: remove entries in reverse to preserve indices
    for i = recipeList:GetNumEntries(), 1, -1 do
        if toRemove[i] then
            local template = recipeList.templateList[i]
            local recipeData = recipeList.dataList[i]
            recipeList:RemoveEntry(template, recipeData)
        end
    end

    -- Pass 3: remove orphaned headers (header with no visible entries before next header or end of list)
    local i = 1
    while i <= recipeList:GetNumEntries() do
        local template = recipeList.templateList[i]
        if template == "ZO_GamepadItemSubEntryTemplateWithHeader" then
            if i == recipeList:GetNumEntries() then
                -- Last entry is a header with no following content
                local recipeData = recipeList.dataList[i]
                recipeList:RemoveEntry(template, recipeData)
            else
                local nextData = recipeList.dataList[i + 1]
                local nextTemplate = recipeList.templateList[i + 1]
                -- Check if next entry is also a header → this one has no visible content
                if nextData and nextData.header and nextTemplate == "ZO_GamepadItemSubEntryTemplateWithHeader" then
                    local recipeData = recipeList.dataList[i]
                    recipeList:RemoveEntry(template, recipeData)
                else
                    i = i + 1
                end
            end
        else
            i = i + 1
        end
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

    if GAMEPAD_PROVISIONER then
        if GAMEPAD_PROVISIONER.recipeList then
            ZO_PreHook(GAMEPAD_PROVISIONER.recipeList, "Commit", HideRecipes)
        end
        ZO_PostHook(GAMEPAD_PROVISIONER, "SaveFilters", SaveOptions)
        ZO_PreHook(GAMEPAD_PROVISIONER, "ShowOptionsMenu", HookOptions)
    end
end

EVENT_MANAGER:RegisterForEvent("Provisioning", EVENT_ADD_ON_LOADED, OnAddonLoaded)
