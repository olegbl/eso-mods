local STYLE_NAMES = {"bodyDescription", "flavorText", "poisonCount", "prioritySellText"}
local NEW_FONT_SIZE = "$(GP_34)"

local tooltips = {
  GAMEPAD_LEFT_DIALOG_TOOLTIP,
  GAMEPAD_LEFT_TOOLTIP,
  GAMEPAD_MOVABLE_TOOLTIP,
  GAMEPAD_QUAD1_TOOLTIP,
  GAMEPAD_QUAD3_TOOLTIP,
  GAMEPAD_RIGHT_TOOLTIP
}

local originalFontSizes = {}

local function CaptureOriginals()
    for _, tooltipID in ipairs(tooltips) do
        local tooltip = GAMEPAD_TOOLTIPS:GetTooltip(tooltipID)
        originalFontSizes[tooltipID] = {}
        for _, styleName in ipairs(STYLE_NAMES) do
            originalFontSizes[tooltipID][styleName] = tooltip:GetStyle(styleName).fontSize
        end
    end
end

local function ApplyFontChanges()
    for _, tooltipID in ipairs(tooltips) do
        local tooltip = GAMEPAD_TOOLTIPS:GetTooltip(tooltipID)
        for _, styleName in ipairs(STYLE_NAMES) do
            tooltip:GetStyle(styleName).fontSize = NEW_FONT_SIZE
        end
    end
end

local function RevertFontChanges()
    for _, tooltipID in ipairs(tooltips) do
        local tooltip = GAMEPAD_TOOLTIPS:GetTooltip(tooltipID)
        for _, styleName in ipairs(STYLE_NAMES) do
            local orig = originalFontSizes[tooltipID] and originalFontSizes[tooltipID][styleName]
            if orig then
                tooltip:GetStyle(styleName).fontSize = orig
            end
        end
    end
end

_G["TooltipFont_Apply"] = ApplyFontChanges
_G["TooltipFont_Revert"] = RevertFontChanges

CaptureOriginals()

EVENT_MANAGER:RegisterForEvent("TooltipFont", EVENT_ADD_ON_LOADED, function(event, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("TooltipFont", EVENT_ADD_ON_LOADED)
    local sv = _G["GamePadHelper_SavedVars"]
    if sv and sv.tooltipFontEnabled then
        ApplyFontChanges()
    end
end)
