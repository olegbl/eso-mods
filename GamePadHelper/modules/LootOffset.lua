local function UpdateLootHistoryOffset()
    local savedVars = _G["GamePadHelper_SavedVars"]
    if not savedVars then return end

    local offset = savedVars.lootOffset or 0
    local mainControl = ZO_LootHistoryControl_Gamepad
    if mainControl then
        mainControl:ClearAnchors()
        local useKeyboardChat = GetSetting_Bool(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_USE_KEYBOARD_CHAT)
        if useKeyboardChat and savedVars.lootOffsetEnabled then
            local gamepadOffset = -120 - offset
            mainControl:SetAnchor(BOTTOMLEFT, GuiRoot, BOTTOMLEFT, 0, gamepadOffset)
        else
            mainControl:SetAnchor(BOTTOMLEFT, GuiRoot, BOTTOMLEFT, 0, -120)
        end
    end
end

local function OnAddonLoaded(event, addonName)
    if addonName ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("LootOffset", EVENT_ADD_ON_LOADED)

    -- Keyboard chat offset is a PC-only feature; skip entirely on console.
    if _G["GamePadHelper_IsConsole"] and _G["GamePadHelper_IsConsole"]() then return end

    -- Register for keyboard chat setting changes in gamepad mode
    EVENT_MANAGER:RegisterForEvent("LootOffset", EVENT_GAMEPAD_USE_KEYBOARD_CHAT_CHANGED, function()
        UpdateLootHistoryOffset()
    end)

    -- Apply offset at reload
    UpdateLootHistoryOffset()
end

EVENT_MANAGER:RegisterForEvent("LootOffset", EVENT_ADD_ON_LOADED, OnAddonLoaded)