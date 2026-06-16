local Utils = _G["GamePadHelper_Utils"]
local QUEST_ICON = zo_iconFormatInheritColor("/esoui/art/inventory/gamepad/gp_inventory_icon_quest.dds", 32, 32)
local COLOR_ACTIVE          = ZO_ColorDef:New(0.18, 0.77, 0.05)
local COLOR_USEFUL_INACTIVE = ZO_ColorDef:New(1, 1, 1)
local COLOR_TITLE           = ZO_ColorDef:New(1.0, 0.82, 0.30)

local function OnAddonLoaded(event, name)
    if name ~= "GamePadHelper" then
        return
    end

    EVENT_MANAGER:UnregisterForEvent("TooltipCountessAndCrow", EVENT_ADD_ON_LOADED)

    local function Tooltip_AddCovetousCountess_After(self, itemLink)
        local sv = _G["GamePadHelper_CharSavedVars"]
        if not sv or (not sv.tooltipCovetousCountessEnabled and not sv.tooltipCrowEnabled) then
            return
        end

        if GetItemLinkItemType(itemLink) ~= ITEMTYPE_TREASURE then
            return
        end

        local isUsefulForActiveQuest, isUsefulForQuest = Utils.GetCountessState(itemLink)
        local isUsefulForActiveCrowGroup, isUsefulForCrow = Utils.GetCrowState(itemLink)

        if not isUsefulForQuest and not isUsefulForCrow then
            return
        end

        if sv.tooltipCovetousCountessEnabled and isUsefulForQuest then
            local iconColor = isUsefulForActiveQuest and COLOR_ACTIVE or COLOR_USEFUL_INACTIVE
            local status = GetString(isUsefulForActiveQuest and SI_GPH_TOOLTIP_TREASURE_ACTIVE_SHORT or SI_GPH_TOOLTIP_TREASURE_INACTIVE_SHORT)
            local line = iconColor:Colorize(QUEST_ICON) .. COLOR_TITLE:Colorize(" " .. GetString(SI_GPH_TOOLTIP_COVETOUS_TITLE) .. " ") .. COLOR_USEFUL_INACTIVE:Colorize("(") .. iconColor:Colorize(status) .. COLOR_USEFUL_INACTIVE:Colorize(")")
            local section = self:AcquireSection(self:GetStyle("bodySection"))
            section:AddLine(line, self:GetStyle("bodyDescription"))
            self:AddSection(section)
        end

        if sv.tooltipCrowEnabled and isUsefulForCrow then
            local iconColor = isUsefulForActiveCrowGroup and COLOR_ACTIVE or COLOR_USEFUL_INACTIVE
            local status = GetString(isUsefulForActiveCrowGroup and SI_GPH_TOOLTIP_TREASURE_ACTIVE_SHORT or SI_GPH_TOOLTIP_TREASURE_INACTIVE_SHORT)
            local line = iconColor:Colorize(QUEST_ICON) .. COLOR_TITLE:Colorize(" " .. GetString(SI_GPH_TOOLTIP_CROW_TITLE) .. " ") .. COLOR_USEFUL_INACTIVE:Colorize("(") .. iconColor:Colorize(status) .. COLOR_USEFUL_INACTIVE:Colorize(")")
            local section = self:AcquireSection(self:GetStyle("bodySection"))
            section:AddLine(line, self:GetStyle("bodyDescription"))
            self:AddSection(section)
        end
    end

    Utils.HookAllGamepadTooltips("post", "AddItemCombinationText", Tooltip_AddCovetousCountess_After)
end

EVENT_MANAGER:RegisterForEvent("TooltipCountessAndCrow", EVENT_ADD_ON_LOADED, OnAddonLoaded)
