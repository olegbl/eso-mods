local PRICE_ICON = ZO_Currency_GetGamepadFormattedCurrencyIcon(CURT_MONEY, 20, true)

local function AutoRepairStore()
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv or not sv.autoRepairEnabled then
        return
    end

    local cost = GetRepairAllCost()
    if cost > 0 and CanStoreRepair() then
        RepairAll()
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT)
        messageParams:SetText(zo_strformat(SI_GPH_AUTOREPAIR_DONE, ZO_CommaDelimitNumber(cost), PRICE_ICON))
        CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
    end
end

local function OnAddonLoaded(event, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("AutoRepair", EVENT_ADD_ON_LOADED)
    EVENT_MANAGER:RegisterForEvent("AutoRepair", EVENT_OPEN_STORE, AutoRepairStore)
end

EVENT_MANAGER:RegisterForEvent("AutoRepair", EVENT_ADD_ON_LOADED, OnAddonLoaded)
