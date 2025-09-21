local ADDON_NAME = "GamePadHelper_AutoRepair"
local ADDON_VERSION = 1.00

local PRICE_ICON = ZO_Currency_GetGamepadFormattedCurrencyIcon(CURT_MONEY, 20, true)

local function AutoRepairStore()
    local savedVars = _G["GamePadHelper_SavedVars"]
    if not savedVars or not savedVars.autoRepairEnabled then
        return
    end

    local cost = GetRepairAllCost()
    if cost > 0 and CanStoreRepair() then
        RepairAll()
        d("|c3399FFGamePadHelper|r: Equipment repaired for |cFFFF00" .. cost .. "|r " .. PRICE_ICON)
    end
end

local function OnAddonLoaded(event, addonName)
    if addonName ~= ADDON_NAME then return end
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_OPEN_STORE, AutoRepairStore)

    -- Set global flag to indicate module is loaded
    _G["GamePadHelper_AutoRepair_Loaded"] = true
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)