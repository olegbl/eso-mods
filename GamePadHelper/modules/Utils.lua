local GPH_Utils = {}
_G["GamePadHelper_Utils"] = GPH_Utils

GPH_Utils.GetTraitIcon = ZO_GetPlatformTraitInformationIcon or GetPlatformTraitInformationIcon

function GPH_Utils.GetCountessState(itemLink)
    if not itemLink or itemLink == "" then return false, false end
    if not LibCovetousCountess or not LibCovetousCountess.IsItemUsefulForCountess then return false, false end
    local success, isUsefulForActiveQuest, isUsefulForQuest = pcall(LibCovetousCountess.IsItemUsefulForCountess, LibCovetousCountess, itemLink)
    if not success then return false, false end
    return isUsefulForActiveQuest, isUsefulForQuest
end

function GPH_Utils.GetCrowState(itemLink)
    if not itemLink or itemLink == "" then return false, false end
    if not LibCovetousCountess or not LibCovetousCountess.IsItemUsefulForCrow then return false, false end
    local success, isUsefulForActiveGroup, isUsefulForCrow = pcall(LibCovetousCountess.IsItemUsefulForCrow, LibCovetousCountess, itemLink)
    if not success then return false, false end
    return isUsefulForActiveGroup, isUsefulForCrow
end

local GAMEPAD_TOOLTIP_IDS = {
    GAMEPAD_LEFT_DIALOG_TOOLTIP,
    GAMEPAD_LEFT_TOOLTIP,
    GAMEPAD_MOVABLE_TOOLTIP,
    GAMEPAD_QUAD1_TOOLTIP,
    GAMEPAD_QUAD3_TOOLTIP,
    GAMEPAD_RIGHT_TOOLTIP,
}

function GPH_Utils.HookAllGamepadTooltips(hookType, methodName, callback)
    local hookFn = hookType == "post" and ZO_PostHook or ZO_PreHook
    for _, tooltipId in ipairs(GAMEPAD_TOOLTIP_IDS) do
        hookFn(GAMEPAD_TOOLTIPS:GetTooltip(tooltipId), methodName, callback)
    end
end
