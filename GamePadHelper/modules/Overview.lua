local Overview = {}

GPH_Overview = GPH_Overview or {}

local State = GPH_Overview
local Quest = State.Quest
local Tasks = State.Tasks

local function IsGamepadOverviewAllowed()
    local isConsole = _G["GamePadHelper_IsConsole"] and _G["GamePadHelper_IsConsole"]() or false
    if isConsole then
        return true
    end

    return IsInGamepadPreferredMode == nil or IsInGamepadPreferredMode()
end

State.isChatFaded = false
State.deferredRefreshQueued = false
State.questIndexOverride = nil
State.keybindDescriptor = nil
State.ownsLeftPanel = false
State.whatsNewShownThisSession = false

local function GetRightTooltip()
    return State.isChatFaded and GAMEPAD_RIGHT_TOOLTIP or GAMEPAD_QUAD3_TOOLTIP
end

local function IsAnyOverviewActive(sv)
    return (sv.overviewQuestEnabled ~= false) or sv.overviewEnabled
end

local function ShowTooltips()
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv or not IsAnyOverviewActive(sv) or not IsGamepadOverviewAllowed() then
        HideTooltips()
        return
    end

    Quest.HideControls()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD3_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD_2_3_TOOLTIP)

    if sv.overviewQuestEnabled ~= false then
        State.ownsLeftPanel = Quest.ShowLeftTooltip(State)
    else
        State.ownsLeftPanel = false
    end

    if sv.overviewEnabled then
        Tasks.ShowRightTooltip(GetRightTooltip())
    end
end

local function HideTooltips()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD3_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD_2_3_TOOLTIP)
    Quest.HideControls()
    State.ownsLeftPanel = false
end

local function QueueOverviewRefresh()
    if State.deferredRefreshQueued then return end
    State.deferredRefreshQueued = true
    zo_callLater(function()
        State.deferredRefreshQueued = false
        local sv = _G["GamePadHelper_CharSavedVars"]
        if sv and IsAnyOverviewActive(sv) and IsGamepadOverviewAllowed() and SCENE_MANAGER:IsShowing("mainMenuGamepad") then
            ShowTooltips()
        end
    end, 1)
end

local function RefreshOverviewIfVisible()
    local sv = _G["GamePadHelper_CharSavedVars"]
    if sv and IsAnyOverviewActive(sv) and IsGamepadOverviewAllowed() and SCENE_MANAGER:IsShowing("mainMenuGamepad") then
        ShowTooltips()
        QueueOverviewRefresh()
    end
end

local function ReapplyOverviewTooltipSoon()
    zo_callLater(function()
        if not Quest.SelectedEntryOwnsLeftPanel() then
            RefreshOverviewIfVisible()
        else
            State.ownsLeftPanel = false
        end
        if State.keybindDescriptor and IsGamepadOverviewAllowed() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(State.keybindDescriptor)
        end
    end, 1)
end

function Overview:Initialize()
    State.isChatFaded = not GAMEPAD_CHAT_SYSTEM or GAMEPAD_CHAT_SYSTEM:IsMinimized()

    State.keybindDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_QUATERNARY",
            name = function()
                return GetString(SI_GPH_OVERVIEW_KEYBIND_PREV_QUEST)
            end,
            visible = function()
                return Quest.ShouldShowKeybinds(State)
            end,
            callback = function()
                Quest.CycleQuest(State, -1, RefreshOverviewIfVisible)
            end,
        },
        {
            keybind = "UI_SHORTCUT_QUINARY",
            name = function()
                return GetString(SI_GPH_OVERVIEW_KEYBIND_NEXT_QUEST)
            end,
            visible = function()
                return Quest.ShouldShowKeybinds(State)
            end,
            callback = function()
                Quest.CycleQuest(State, 1, RefreshOverviewIfVisible)
            end,
        },
    }

    SCENE_MANAGER:RegisterCallback("SceneStateChanged", function(scene, oldState, newState)
        if scene:GetName() == "mainMenuGamepad" then
            if newState == SCENE_SHOWING then
                if IsGamepadOverviewAllowed() then
                    ShowTooltips()
                    QueueOverviewRefresh()
                else
                    HideTooltips()
                end
                if State.keybindDescriptor and IsGamepadOverviewAllowed() then
                    KEYBIND_STRIP:AddKeybindButtonGroup(State.keybindDescriptor)
                    KEYBIND_STRIP:UpdateKeybindButtonGroup(State.keybindDescriptor)
                end
            elseif newState == SCENE_HIDING then
                HideTooltips()
                if State.keybindDescriptor then
                    KEYBIND_STRIP:RemoveKeybindButtonGroup(State.keybindDescriptor)
                end
            end
        end
    end)

    if GAMEPAD_CHAT_SYSTEM then
        ZO_PostHook(GAMEPAD_CHAT_SYSTEM, "Minimize", function()
            State.isChatFaded = true
            RefreshOverviewIfVisible()
        end)

        ZO_PostHook(GAMEPAD_CHAT_SYSTEM, "Maximize", function()
            State.isChatFaded = false
            RefreshOverviewIfVisible()
        end)
    end

    if QUEST_JOURNAL_MANAGER then
        if QUEST_JOURNAL_MANAGER.SetFocusedQuestIndex then
            ZO_PostHook(QUEST_JOURNAL_MANAGER, "SetFocusedQuestIndex", function()
                Quest.OnNativeQuestSelectionChanged(State, RefreshOverviewIfVisible)
            end)
        end
        if QUEST_JOURNAL_MANAGER.SetTrackedQuestIndex then
            ZO_PostHook(QUEST_JOURNAL_MANAGER, "SetTrackedQuestIndex", function()
                Quest.OnNativeQuestSelectionChanged(State, RefreshOverviewIfVisible)
            end)
        end
    end

    EVENT_MANAGER:RegisterForEvent("GPH_Overview_QuestAssistChanged", EVENT_QUEST_ASSIST_STATE_CHANGED, function(_, _, assisted)
        if assisted then
            Quest.OnNativeQuestSelectionChanged(State, RefreshOverviewIfVisible)
        end
    end)

    EVENT_MANAGER:RegisterForEvent("GPH_Overview_PreferredModeChanged", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function(_, isGamepadPreferred)
        local isConsole = _G["GamePadHelper_IsConsole"] and _G["GamePadHelper_IsConsole"]() or false
        if isConsole or isGamepadPreferred then
            RefreshOverviewIfVisible()
            if State.keybindDescriptor and SCENE_MANAGER:IsShowing("mainMenuGamepad") then
                KEYBIND_STRIP:UpdateKeybindButtonGroup(State.keybindDescriptor)
            end
        else
            HideTooltips()
            if State.keybindDescriptor then
                KEYBIND_STRIP:RemoveKeybindButtonGroup(State.keybindDescriptor)
            end
        end
    end)

    if FOCUSED_QUEST_TRACKER and FOCUSED_QUEST_TRACKER.ForceAssist then
        ZO_PostHook(FOCUSED_QUEST_TRACKER, "ForceAssist", function(_, questIndex)
            Quest.OnNativeQuestAssistChanged(State, questIndex, RefreshOverviewIfVisible)
        end)
    end

    if MAIN_MENU_GAMEPAD and MAIN_MENU_GAMEPAD.OnSelectionChanged then
        ZO_PostHook(MAIN_MENU_GAMEPAD, "OnSelectionChanged", function()
            ReapplyOverviewTooltipSoon()
            if State.keybindDescriptor and IsGamepadOverviewAllowed() then
                KEYBIND_STRIP:UpdateKeybindButtonGroup(State.keybindDescriptor)
            end
        end)
    end
end

EVENT_MANAGER:RegisterForEvent("Overview", EVENT_ADD_ON_LOADED, function(_, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("Overview", EVENT_ADD_ON_LOADED)
    Overview:Initialize()
end)
