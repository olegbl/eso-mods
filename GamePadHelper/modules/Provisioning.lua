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

    local n = recipeList:GetNumEntries()

    -- Pass 2: preserve category headings. The game attaches each group's header to
    -- that group's first entry (data.header set, *WithHeader template). If that entry
    -- is being removed, hand its header to the first surviving member of the SAME group
    -- so the heading isn't lost. A forward pass with a "pending" header keeps the right
    -- heading even when several whole groups are removed back-to-back.
    -- (Identifying headers by data.header rather than a template-name literal is what
    -- makes this work — the real template is "ZO_Provisioner_..." not the generic name.)
    local pendingHeader, pendingTemplate = nil, nil
    for i = 1, n do
        local data = recipeList.dataList[i]
        if data and data.header then
            if toRemove[i] then
                pendingHeader = data.header
                pendingTemplate = recipeList.templateList[i]
            else
                pendingHeader, pendingTemplate = nil, nil
            end
        elseif data and not toRemove[i] and pendingHeader then
            data.header = pendingHeader
            recipeList.templateList[i] = pendingTemplate
            pendingHeader, pendingTemplate = nil, nil
        end
    end

    -- Pass 3: remove marked entries in reverse so earlier indices stay valid
    for i = n, 1, -1 do
        if toRemove[i] then
            recipeList:RemoveEntry(recipeList.templateList[i], recipeList.dataList[i])
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
