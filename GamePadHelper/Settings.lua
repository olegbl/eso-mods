local GPH_PANEL_ID = 9106
local GPH_SYSTEM_ID = 9106
local GPH_CATEGORY_NAME = "|c3399FFGPH|r Settings"
local GPH_RELOAD_DIALOG = "GPH_RELOADUI_CONFIRM"
local gphLootReloadPending = false
local gphExitHookRegistered = false
local gphBackOverrideActive = false
local TRAIT_COLOR_LEGEND = "\n\nTrait color meaning:\n|c2DC50EGreen|r: Only copy with this trait you have access\n|cFFFF00Yellow|r: Another copy with the same trait exists in your inventory\n|cFF4444Red|r: Another copy with the same trait exists in your bank\n|cFFFFFFWhite|r: Equipped item uses ESO's default magnifying glass icon; details are shown in the tooltip"

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
        system = GPH_SYSTEM_ID,
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
    return {
        panel = GPH_PANEL_ID,
        system = GPH_SYSTEM_ID,
        controlType = OPTIONS_CHECKBOX,
        text = text,
        gamepadTextOverride = text,
        header = header,
        disabled = disabledFunc,
        tooltipText = tooltip,
        gamepadCustomTooltipFunction = function(tooltipControl)
            GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(tooltipControl, tooltip)
        end,
        GetSettingOverride = function()
            return getFunc()
        end,
        SetSettingOverride = function(_, value)
            setFunc(value)
        end,
    }
end

local function BuildSlider(text, tooltip, minValue, maxValue, stepValue, getFunc, setFunc, header, disabledFunc)
    return {
        panel = GPH_PANEL_ID,
        system = GPH_SYSTEM_ID,
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
        default = 350,
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
        system = GPH_SYSTEM_ID,
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
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, "Reload UI required.")
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
        title = { text = "Reload UI Required" },
        mainText = { text = "Changes require a UI reload. Reload now?" },
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

    add(BuildInvoke("Reload UI", "Reloads the interface to apply all changes.", function()
        ShowReloadPrompt()
    end))

    add(BuildCheckboxCustom("Fishing Module", "Enable controller vibration feedback, 'Reel in!' alerts, and automatic bait selection by water type.", function()
        return GetBoolSetting("fishingEnabled", false)
    end, function(v)
        SetSetting("fishingEnabled", v)
    end, function()
        return "Fishing"
    end))

    add(BuildCheckbox("Alternative Baits", "Fall back to alternative baits.", "fishingAlternativeBaits"))

    add(BuildCheckboxCustom("Auto Repair", "Automatically repair all equipped items when you open a merchant store.", function()
        return GetBoolSetting("autoRepairEnabled", false)
    end, function(v)
        SetSetting("autoRepairEnabled", v)
    end, function()
        return "Automation"
    end))

    add(BuildCheckbox("Auto Weapon Charge", "Automatically recharge weapons.", "autoChargeEnabled"))
    add(BuildCheckbox("Antiquarian's Eye", "Automatically activate the Eye.", "antiquariansEyeEnabled"))
    add(BuildCheckbox("Teleporter", "Enable teleport functionality.", "teleporterEnabled"))

    add(BuildCheckboxCustom("Dungeon Finder Enhancement", "Show pledge quest names inside the dungeon finder.", function()
        return GetBoolSetting("dungeonFinderEnabled", false)
    end, function(v)
        SetSetting("dungeonFinderEnabled", v)
    end, function()
        return "UI Enhancements"
    end))

    add(BuildCheckbox("Hide Low Level Recipes", "Hide recipes under CP160 in the provisioning panel.", "showLowLevelRecipes"))

    add(BuildCheckboxCustom("Tooltip Traits", "Show enhanced trait information with research icons in item tooltips." .. TRAIT_COLOR_LEGEND, function()
        return GetBoolSetting("tooltipTraitEnabled", false)
    end, function(v)
        SetSetting("tooltipTraitEnabled", v)
    end, function()
        return "Tooltips & UI"
    end))

    add(BuildCheckbox("Tooltip Price", "Show item price information (including market addon data when available) in item tooltips.", "tooltipPriceEnabled"))
    add(BuildCheckbox("Gear Comparison", "Show gear stat comparisons.", "gearComparisonEnabled"))
    add(BuildCheckbox("Inventory Traits", "Show item traits in inventory." .. TRAIT_COLOR_LEGEND, "inventoryTraitEnabled"))
    add(BuildCheckbox("Inventory Covetous Countess", "Highlight Covetous Countess items in inventory.", "inventoryCovetousCountessEnabled"))
    add(BuildCheckbox("Overview Panel", "Enable character overview enhancements.", "overviewEnabled"))
    add(BuildCheckbox("Tooltip Poison Info", "Show poison information in tooltips.", "tooltipPoisonEnabled"))
    add(BuildCheckboxCustom("Tooltip Font Changes", "Apply font size changes to tooltips.", function()
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
    add(BuildCheckbox("Tooltip Enchantments", "Show enchantment information in tooltips.", "tooltipEnchantmentEnabled"))

    add(BuildCheckboxCustom("Enable Loot Offset", "Shift the loot history panel upward so it does not overlap the chat box.\n\n|cFFAA00Reload UI required after changing this setting.|r", function()
        return GetBoolSetting("lootOffsetEnabled", false)
    end, function(v)
        SetSetting("lootOffsetEnabled", v)
        MarkLootReloadPending()
    end, function()
        return "Loot"
    end, function()
        return IsConsoleUI and IsConsoleUI()
    end))

    -- UI shows -350..350, but saved value stays compatible with loot module (0..700 where 350 is midpoint).
    add(BuildSlider("Loot Offset Amount", "Adjust loot panel offset from -350 to +350.\n\nInternal midpoint is 350 (shown here as 0).\n|cFFAA00Reload UI required after changing this setting.|r", -350, 350, 10, function()
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
        [GPH_SYSTEM_ID] = {},
    }

    for _, optionData in ipairs(settingsData) do
        local copy = ZO_ShallowTableCopy(optionData)
        shared[GPH_SYSTEM_ID][optionData.settingId] = copy
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
        if data and data.system == GPH_SYSTEM_ID and data.panel == GPH_PANEL_ID and data.callback then
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

    local function TryRegister()
        if RegisterCategory() then
            return
        end
        zo_callLater(TryRegister, 1000)
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

    SLASH_COMMANDS["/gph"] = function()
        OpenSettings()
    end
end

EVENT_MANAGER:RegisterForEvent("Settings_Init", EVENT_PLAYER_ACTIVATED, function()
    EVENT_MANAGER:UnregisterForEvent("Settings_Init", EVENT_PLAYER_ACTIVATED)
    InitializeGamepadSettings()
end)
