local GPH_PANEL_ID = 9106
local GPH_CATEGORY_NAME = GetString(SI_GPH_SETTINGS_CATEGORY)
local GPH_RELOAD_DIALOG = "GPH_RELOADUI_CONFIRM"
local gphLootReloadPending = false
local gphExitHookRegistered = false
local gphBackOverrideActive = false
local TRAIT_COLOR_LEGEND = GetString(SI_GPH_TRAIT_COLOR_LEGEND)

local function GetSavedVars()
    return _G["GamePadHelper_SavedVars"]
end

local function GetBoolSetting(key, defaultValue)
    local sv = GetSavedVars()
    if not sv then
        return defaultValue or false
    end
    local value = sv[key]
    if value == nil then
        return defaultValue or false
    end
    return value
end

local function SetSetting(key, value)
    local sv = GetSavedVars()
    if sv then
        sv[key] = value
    end
end

local function BuildCheckbox(text, tooltip, key)
    return {
        panel = GPH_PANEL_ID,
        system = GPH_PANEL_ID,
        controlType = OPTIONS_CHECKBOX,
        text = text,
        gamepadTextOverride = text,
        tooltipText = tooltip,
        gamepadCustomTooltipFunction = function(tooltipControl)
            GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(tooltipControl, tooltip)
        end,
        GetSettingOverride = function()
            return GetBoolSetting(key, false)
        end,
        SetSettingOverride = function(_, value)
            SetSetting(key, value)
        end,
    }
end

local function BuildCheckboxCustom(text, tooltip, getFunc, setFunc, header, disabledFunc)
    local function getTooltip()
        if disabledFunc and disabledFunc() then
            return tooltip .. "\n\n" .. GetString(SI_GPH_SETTING_DISABLED_NOTICE)
        end
        return tooltip
    end
    return {
        panel = GPH_PANEL_ID,
        system = GPH_PANEL_ID,
        controlType = OPTIONS_CHECKBOX,
        text = text,
        gamepadTextOverride = text,
        header = header,
        disabled = disabledFunc,
        gamepadIsEnabledCallback = disabledFunc and function() return not disabledFunc() end or nil,
        tooltipText = getTooltip,
        gamepadCustomTooltipFunction = function(tooltipControl)
            GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(tooltipControl, getTooltip())
        end,
        GetSettingOverride = function()
            return getFunc()
        end,
        SetSettingOverride = function(_, value)
            setFunc(value)
        end,
    }
end

local function BuildSlider(text, tooltip, minValue, maxValue, stepValue, defaultValue, getFunc, setFunc, header, disabledFunc)
    return {
        panel = GPH_PANEL_ID,
        system = GPH_PANEL_ID,
        controlType = OPTIONS_SLIDER,
        text = text,
        gamepadTextOverride = text,
        header = header,
        disabled = disabledFunc,
        tooltipText = tooltip,
        minValue = minValue,
        maxValue = maxValue,
        showValue = true,
        showValueMin = minValue,
        showValueMax = maxValue,
        default = defaultValue,
        valueFormat = "%d",
        gamepadValueStepPercent = ((stepValue and stepValue > 0) and ((stepValue / (maxValue - minValue)) * 100)) or nil,
        gamepadCustomTooltipFunction = function(tooltipControl)
            GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(tooltipControl, tooltip)
        end,
        GetSettingOverride = function()
            return getFunc()
        end,
        SetSettingOverride = function(_, value)
            setFunc(tonumber(value) or minValue)
        end,
    }
end

local function BuildInvoke(text, tooltip, callback)
    return {
        panel = GPH_PANEL_ID,
        system = GPH_PANEL_ID,
        controlType = OPTIONS_INVOKE_CALLBACK,
        text = text,
        gamepadTextOverride = text,
        tooltipText = tooltip,
        gamepadCustomTooltipFunction = function(tooltipControl)
            GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(tooltipControl, tooltip)
        end,
        callback = callback,
    }
end

local function ShowReloadPrompt(onConfirm, onCancel)
    if ESO_Dialogs[GPH_RELOAD_DIALOG] then
        ZO_Dialogs_ShowGamepadDialog(GPH_RELOAD_DIALOG, {
            onConfirm = onConfirm,
            onCancel = onCancel,
        })
    elseif ESO_Dialogs["LIBGAMEPAD_RELOADUI_CONFIRM"] then
        ZO_Dialogs_ShowGamepadDialog("LIBGAMEPAD_RELOADUI_CONFIRM")
    else
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_GPH_RELOAD_REQUIRED_SHORT))
        if onCancel then
            onCancel()
        end
    end
end

local function MarkLootReloadPending()
    gphLootReloadPending = true
end

local function EnsureReloadDialog()
    if ESO_Dialogs[GPH_RELOAD_DIALOG] then
        return
    end

    -- Dedicated confirmation used by both "Reload UI" button and deferred loot changes.
    ESO_Dialogs[GPH_RELOAD_DIALOG] = {
        gamepadInfo = { dialogType = GAMEPAD_DIALOGS.BASIC },
        title = { text = SI_GPH_RELOAD_TITLE },
        mainText = { text = SI_GPH_RELOAD_BODY },
        buttons = {
            {
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    local onConfirm = dialog.data and dialog.data.onConfirm
                    if onConfirm then
                        onConfirm()
                    else
                        ReloadUI()
                    end
                end,
            },
            {
                text = SI_DIALOG_CANCEL,
                callback = function(dialog)
                    local onCancel = dialog.data and dialog.data.onCancel
                    if onCancel then
                        onCancel()
                    end
                end,
            },
        },
    }
end

local function BuildSettingsData()
    local data = {}
    local nextSettingId = 1

    -- Each row must have a stable settingId for ZO_SharedOptions lookups.
    local function add(row)
        row.settingId = nextSettingId
        nextSettingId = nextSettingId + 1
        data[#data + 1] = row
    end

    add(BuildInvoke(GetString(SI_GPH_SETTING_RELOAD_UI_NAME), GetString(SI_GPH_SETTING_RELOAD_UI_TOOLTIP), function()
        ShowReloadPrompt()
    end))

    add(BuildCheckboxCustom(GetString(SI_GPH_SETTING_FISHING_MODULE_NAME), GetString(SI_GPH_SETTING_FISHING_MODULE_TOOLTIP), function()
        return GetBoolSetting("fishingEnabled", false)
    end, function(v)
        SetSetting("fishingEnabled", v)
    end, GetString(SI_GPH_SETTINGS_HEADER_FISHING)))

    add(BuildCheckbox(GetString(SI_GPH_SETTING_ALTERNATIVE_BAITS_NAME), GetString(SI_GPH_SETTING_ALTERNATIVE_BAITS_TOOLTIP), "fishingAlternativeBaits"))

    add(BuildCheckboxCustom(GetString(SI_GPH_SETTING_AUTO_REPAIR_NAME), GetString(SI_GPH_SETTING_AUTO_REPAIR_TOOLTIP), function()
        return GetBoolSetting("autoRepairEnabled", false)
    end, function(v)
        SetSetting("autoRepairEnabled", v)
    end, GetString(SI_GPH_SETTINGS_HEADER_AUTOMATION)))

    add(BuildCheckbox(GetString(SI_GPH_SETTING_AUTO_CHARGE_NAME), GetString(SI_GPH_SETTING_AUTO_CHARGE_TOOLTIP), "autoChargeEnabled"))
    add(BuildSlider(GetString(SI_GPH_SETTING_AUTO_CHARGE_THRESHOLD_NAME), GetString(SI_GPH_SETTING_AUTO_CHARGE_THRESHOLD_TOOLTIP), 5, 95, 5, 25, function()
        local sv = GetSavedVars()
        return (sv and sv.autoChargeThreshold) or 25
    end, function(v)
        SetSetting("autoChargeThreshold", tonumber(v) or 25)
    end, nil, function()
        return not GetBoolSetting("autoChargeEnabled", false)
    end))
    add(BuildCheckbox(GetString(SI_GPH_SETTING_ANTIQUARIAN_EYE_NAME), GetString(SI_GPH_SETTING_ANTIQUARIAN_EYE_TOOLTIP), "antiquariansEyeEnabled"))
    add(BuildCheckbox(GetString(SI_GPH_SETTING_TELEPORTER_NAME), GetString(SI_GPH_SETTING_TELEPORTER_TOOLTIP), "teleporterEnabled"))

    local function mapSearchDisabled() return not GetBoolSetting("mapSearchEnabled", true) end

    add(BuildCheckboxCustom(GetString(SI_GPH_SETTING_MAP_SEARCH_ENABLED_NAME), GetString(SI_GPH_SETTING_MAP_SEARCH_ENABLED_TOOLTIP), function()
        return GetBoolSetting("mapSearchEnabled", true)
    end, function(v)
        SetSetting("mapSearchEnabled", v)
        if GAMEPAD_OPTIONS then GAMEPAD_OPTIONS:RefreshOptionsList() end
    end, GetString(SI_GPH_SETTINGS_HEADER_MAP_SEARCH)))

    add(BuildCheckboxCustom(GetString(SI_GPH_SETTING_MAP_SEARCH_MAP_PIN_NAME), GetString(SI_GPH_SETTING_MAP_SEARCH_MAP_PIN_TOOLTIP), function()
        return GetBoolSetting("mapSearchMapPin", true)
    end, function(v)
        SetSetting("mapSearchMapPin", v)
    end, nil, mapSearchDisabled))

    add(BuildCheckboxCustom(GetString(SI_GPH_SETTING_MAP_SEARCH_GROUP_BY_LOCATION_NAME), GetString(SI_GPH_SETTING_MAP_SEARCH_GROUP_BY_LOCATION_TOOLTIP), function()
        return GetBoolSetting("mapSearchGroupByLocation", false)
    end, function(v)
        SetSetting("mapSearchGroupByLocation", v)
    end, nil, mapSearchDisabled))

    add(BuildCheckboxCustom(GetString(SI_GPH_SETTING_MAP_SEARCH_ACCOUNT_BOOKMARKS_NAME), GetString(SI_GPH_SETTING_MAP_SEARCH_ACCOUNT_BOOKMARKS_TOOLTIP), function()
        return GetBoolSetting("mapSearchBookmarksAccountWide", false)
    end, function(v)
        SetSetting("mapSearchBookmarksAccountWide", v)
    end, nil, mapSearchDisabled))

    add(BuildCheckboxCustom(GetString(SI_GPH_SETTING_MAP_SEARCH_SET_DESTINATION_NAME), GetString(SI_GPH_SETTING_MAP_SEARCH_SET_DESTINATION_TOOLTIP), function()
        return GetBoolSetting("mapSearchSetDestination", true)
    end, function(v)
        SetSetting("mapSearchSetDestination", v)
    end, nil, mapSearchDisabled))

    add(BuildCheckboxCustom(GetString(SI_GPH_SETTING_MAP_SEARCH_ANNOUNCE_NAME), GetString(SI_GPH_SETTING_MAP_SEARCH_ANNOUNCE_TOOLTIP), function()
        return GetBoolSetting("mapSearchNarratePostTeleport", true)
    end, function(v)
        SetSetting("mapSearchNarratePostTeleport", v)
    end, nil, mapSearchDisabled))

    add(BuildCheckboxCustom(GetString(SI_GPH_SETTING_DUNGEON_FINDER_NAME), GetString(SI_GPH_SETTING_DUNGEON_FINDER_TOOLTIP), function()
        return GetBoolSetting("dungeonFinderEnabled", false)
    end, function(v)
        SetSetting("dungeonFinderEnabled", v)
    end, GetString(SI_GPH_SETTINGS_HEADER_UI_ENHANCEMENTS)))

    add(BuildCheckbox(GetString(SI_GPH_PROVISIONING_HIDE_LOW_LEVEL), GetString(SI_GPH_PROVISIONING_HIDE_LOW_LEVEL_TOOLTIP), "showLowLevelRecipes"))

    add(BuildCheckboxCustom(GetString(SI_GPH_SETTING_TOOLTIP_TRAITS_NAME), GetString(SI_GPH_SETTING_TOOLTIP_TRAITS_TOOLTIP) .. TRAIT_COLOR_LEGEND, function()
        return GetBoolSetting("tooltipTraitEnabled", false)
    end, function(v)
        SetSetting("tooltipTraitEnabled", v)
    end, GetString(SI_GPH_SETTINGS_HEADER_TOOLTIPS_UI)))

    add(BuildCheckbox(GetString(SI_GPH_SETTING_TOOLTIP_PRICE_NAME), GetString(SI_GPH_SETTING_TOOLTIP_PRICE_TOOLTIP), "tooltipPriceEnabled"))
    add(BuildCheckbox(GetString(SI_GPH_SETTING_GEAR_COMPARISON_NAME), GetString(SI_GPH_SETTING_GEAR_COMPARISON_TOOLTIP), "gearComparisonEnabled"))
    add(BuildCheckbox(GetString(SI_GPH_SETTING_INVENTORY_TRAITS_NAME), GetString(SI_GPH_SETTING_INVENTORY_TRAITS_TOOLTIP) .. TRAIT_COLOR_LEGEND, "inventoryTraitEnabled"))
    add(BuildCheckbox(GetString(SI_GPH_SETTING_INVENTORY_COVETOUS_COUNTESS_NAME), GetString(SI_GPH_SETTING_INVENTORY_COVETOUS_COUNTESS_TOOLTIP), "inventoryCovetousCountessEnabled"))
    add(BuildCheckbox(GetString(SI_GPH_SETTING_OVERVIEW_NAME), GetString(SI_GPH_SETTING_OVERVIEW_TOOLTIP), "overviewEnabled"))
    add(BuildCheckboxCustom(GetString(SI_GPH_SETTING_OVERVIEW_DAILY_WRIT_NAME), GetString(SI_GPH_SETTING_OVERVIEW_DAILY_WRIT_TOOLTIP), function()
        return GetBoolSetting("overviewDailyWritEnabled", true)
    end, function(v)
        SetSetting("overviewDailyWritEnabled", v)
    end, nil, function()
        return not GetBoolSetting("overviewEnabled", false)
    end))
    add(BuildCheckboxCustom(GetString(SI_GPH_SETTING_OVERVIEW_COMPANION_NAME), GetString(SI_GPH_SETTING_OVERVIEW_COMPANION_TOOLTIP), function()
        return GetBoolSetting("overviewCompanionEnabled", true)
    end, function(v)
        SetSetting("overviewCompanionEnabled", v)
    end, nil, function()
        return not GetBoolSetting("overviewEnabled", false)
    end))
    add(BuildCheckbox(GetString(SI_GPH_SETTING_TOOLTIP_POISON_NAME), GetString(SI_GPH_SETTING_TOOLTIP_POISON_TOOLTIP), "tooltipPoisonEnabled"))
    add(BuildCheckboxCustom(GetString(SI_GPH_SETTING_TOOLTIP_FONT_NAME), GetString(SI_GPH_SETTING_TOOLTIP_FONT_TOOLTIP), function()
        return GetBoolSetting("tooltipFontEnabled", false)
    end, function(v)
        SetSetting("tooltipFontEnabled", v)
        if v then
            if _G["TooltipFont_Apply"] then
                _G["TooltipFont_Apply"]()
            end
        else
            if _G["TooltipFont_Revert"] then
                _G["TooltipFont_Revert"]()
            end
        end
    end))
    add(BuildCheckbox(GetString(SI_GPH_SETTING_TOOLTIP_ENCHANTMENTS_NAME), GetString(SI_GPH_SETTING_TOOLTIP_ENCHANTMENTS_TOOLTIP), "tooltipEnchantmentEnabled"))

    add(BuildCheckboxCustom(GetString(SI_GPH_SETTING_LOOT_OFFSET_NAME), GetString(SI_GPH_SETTING_LOOT_OFFSET_TOOLTIP), function()
        return GetBoolSetting("lootOffsetEnabled", false)
    end, function(v)
        SetSetting("lootOffsetEnabled", v)
        MarkLootReloadPending()
    end, GetString(SI_GPH_SETTINGS_HEADER_LOOT), function()
        return IsConsoleUI and IsConsoleUI()
    end))

    -- UI shows -350..350, but saved value stays compatible with loot module (0..700 where 350 is midpoint).
    add(BuildSlider(GetString(SI_GPH_SETTING_LOOT_OFFSET_AMOUNT_NAME), GetString(SI_GPH_SETTING_LOOT_OFFSET_AMOUNT_TOOLTIP), -350, 350, 10, 0, function()
        local sv = GetSavedVars()
        local internalValue = (sv and sv.lootOffset) or 350
        return internalValue - 350
    end, function(v)
        local sv = GetSavedVars()
        if not sv then return end
        sv.lootOffset = zo_clamp((tonumber(v) or 0) + 350, 0, 700)
        MarkLootReloadPending()
    end, nil, function()
        local sv = GetSavedVars()
        local isConsole = IsConsoleUI and IsConsoleUI()
        return isConsole or not (sv and sv.lootOffsetEnabled)
    end))

    return data
end

local function RegisterSharedOptions(settingsData)
    if not ZO_SharedOptions or not ZO_SharedOptions.AddTableToPanel then
        return
    end

    local shared = {
        [GPH_PANEL_ID] = {},
    }

    for _, optionData in ipairs(settingsData) do
        local copy = ZO_ShallowTableCopy(optionData)
        shared[GPH_PANEL_ID][optionData.settingId] = copy
    end

    ZO_SharedOptions.AddTableToPanel(GPH_PANEL_ID, shared)
end

local function RegisterCategory()
    if not GAMEPAD_OPTIONS then
        return false
    end

    if not GAMEPAD_SETTINGS_DATA then
        return false
    end

    if GAMEPAD_SETTINGS_DATA[GPH_PANEL_ID] == nil then
        GAMEPAD_SETTINGS_DATA[GPH_PANEL_ID] = BuildSettingsData()
    end

    RegisterSharedOptions(GAMEPAD_SETTINGS_DATA[GPH_PANEL_ID])

    local categoryData = ZO_GamepadEntryData:New(GPH_CATEGORY_NAME, "/esoui/art/options/gamepad/gp_options_addons.dds")
    categoryData.sortOrder = 106
    categoryData.panelId = GPH_PANEL_ID
    categoryData:SetIconTintOnSelection(true)
    categoryData.callback = function()
        GAMEPAD_OPTIONS.currentCategory = GPH_PANEL_ID
        SCENE_MANAGER:Push("gamepad_options_panel")
    end

    GAMEPAD_OPTIONS:RegisterCustomCategory(categoryData)

    return true
end

local function OpenSettings()
    if not GAMEPAD_OPTIONS then
        return
    end

    GAMEPAD_OPTIONS.currentCategory = GPH_PANEL_ID
    SCENE_MANAGER:Push("gamepad_options_panel")
end

local function HookInvokeCallback()
    -- OPTIONS_INVOKE_CALLBACK rows in custom systems need explicit routing in gamepad options.
    ZO_PreHook("ZO_Options_InvokeCallback", function(control)
        local data = control and control.data
        if data and data.system == GPH_PANEL_ID and data.panel == GPH_PANEL_ID and data.callback then
            data.callback(control)
            return true
        end
        return false
    end)
end

local function InstallBackOverride()
    if gphBackOverrideActive or not GAMEPAD_OPTIONS then
        return
    end

    gphBackOverrideActive = true
    GAMEPAD_OPTIONS.overrideBackName = GetString(SI_GAMEPAD_BACK_OPTION)
    GAMEPAD_OPTIONS.overrideBackCallback = function()
        if GAMEPAD_OPTIONS.currentCategory == GPH_PANEL_ID and gphLootReloadPending then
            ShowReloadPrompt(function()
                ReloadUI()
            end, function()
                gphLootReloadPending = false
                SCENE_MANAGER:HideCurrentScene()
            end)
            return
        end

        gphLootReloadPending = false
        SCENE_MANAGER:HideCurrentScene()
    end
end

local function ClearBackOverride()
    if not gphBackOverrideActive or not GAMEPAD_OPTIONS then
        return
    end

    GAMEPAD_OPTIONS.overrideBackCallback = nil
    GAMEPAD_OPTIONS.overrideBackName = nil
    gphBackOverrideActive = false
end

local function InitializeGamepadSettings()
    EnsureReloadDialog()
    HookInvokeCallback()

    local tryRegisterAttempts = 0
    local function TryRegister()
        if RegisterCategory() then
            return
        end
        tryRegisterAttempts = tryRegisterAttempts + 1
        if tryRegisterAttempts < 10 then
            zo_callLater(TryRegister, 1000)
        end
    end

    TryRegister()

    if not gphExitHookRegistered then
        local panelScene = SCENE_MANAGER and SCENE_MANAGER:GetScene("gamepad_options_panel")
        if panelScene then
            panelScene:RegisterCallback("StateChange", function(...)
                local newState = select(2, ...) or select(1, ...)
                if newState == SCENE_SHOWING or newState == "showing" then
                    if GAMEPAD_OPTIONS and GAMEPAD_OPTIONS.currentCategory == GPH_PANEL_ID then
                        InstallBackOverride()
                    end
                elseif newState == SCENE_HIDING or newState == SCENE_HIDDEN or newState == "hiding" or newState == "hidden" then
                    ClearBackOverride()
                end
            end)
            gphExitHookRegistered = true
        end
    end

end

EVENT_MANAGER:RegisterForEvent("Settings_Init", EVENT_PLAYER_ACTIVATED, function()
    EVENT_MANAGER:UnregisterForEvent("Settings_Init", EVENT_PLAYER_ACTIVATED)
    InitializeGamepadSettings()
end)
