-- Provisioning
-- Adds a filter option to hide low-level recipes (under CP160) in the provisioning interface

local showLowLevelFilter = {
    filterName = GetString(SI_GPH_PROVISIONING_HIDE_LOW_LEVEL),
    filterTooltip = GetString(SI_GPH_PROVISIONING_HIDE_LOW_LEVEL_TOOLTIP),
}

local function IsHideLowLevelEnabled()
    local sv = _G["GamePadHelper_CharSavedVars"]
    return sv and sv.showLowLevelRecipes == true
end

local function HideRecipes(recipeList)
    if not IsHideLowLevelEnabled() then
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

    -- Pass 2: preserve category headings. If a group's first entry (which carries
    -- data.header) is being removed, migrate the header to the next surviving entry
    -- in the same group so the category label isn't lost. A forward pass with a
    -- "pending" header handles back-to-back fully-removed groups correctly.
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

local function ToggleHideLowLevelRecipes()
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv then
        return
    end

    sv.showLowLevelRecipes = not sv.showLowLevelRecipes

    if GAMEPAD_PROVISIONER then
        GAMEPAD_PROVISIONER:DirtyRecipeList()
        if GAMEPAD_PROVISIONER.mainKeybindStripDescriptor then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(GAMEPAD_PROVISIONER.mainKeybindStripDescriptor)
        end
    end
end

local function HookProvisioningKeybind()
    if not GAMEPAD_PROVISIONER or not GAMEPAD_PROVISIONER.mainKeybindStripDescriptor or GAMEPAD_PROVISIONER.gphLowLevelKeybindAdded then
        return
    end

    table.insert(GAMEPAD_PROVISIONER.mainKeybindStripDescriptor,
    {
        name = function()
            if IsHideLowLevelEnabled() then
                return GetString(SI_GPH_PROVISIONING_SHOW_LOW_LEVEL)
            end
            return GetString(SI_GPH_PROVISIONING_HIDE_LOW_LEVEL)
        end,
        keybind = "UI_SHORTCUT_QUINARY",
        gamepadOrder = 1015,
        visible = function()
            return GAMEPAD_PROVISIONER_CREATION_SCENE and GAMEPAD_PROVISIONER_CREATION_SCENE:IsShowing()
                and not ZO_CraftingUtils_IsPerformingCraftProcess()
        end,
        callback = function()
            ToggleHideLowLevelRecipes()
        end,
    })

    GAMEPAD_PROVISIONER.gphLowLevelKeybindAdded = true
end

local function OnAddonLoaded(event, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("Provisioning", EVENT_ADD_ON_LOADED)

    if GAMEPAD_PROVISIONER then
        HookProvisioningKeybind()
        if GAMEPAD_PROVISIONER.recipeList then
            ZO_PreHook(GAMEPAD_PROVISIONER.recipeList, "Commit", HideRecipes)
        end
    end
end

EVENT_MANAGER:RegisterForEvent("Provisioning", EVENT_ADD_ON_LOADED, OnAddonLoaded)
