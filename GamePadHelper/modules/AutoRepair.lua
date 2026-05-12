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

local function OnAddonLoaded(event, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("AutoRepair", EVENT_ADD_ON_LOADED)
    EVENT_MANAGER:RegisterForEvent("AutoRepair", EVENT_OPEN_STORE, AutoRepairStore)
end

EVENT_MANAGER:RegisterForEvent("AutoRepair", EVENT_ADD_ON_LOADED, OnAddonLoaded)
