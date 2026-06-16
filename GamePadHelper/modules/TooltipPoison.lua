local Utils = _G["GamePadHelper_Utils"]

local function Tooltip_AddPoisonInfo_Before(self, itemLink, equipSlot)
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv or not sv.tooltipPoisonEnabled then return end
    local hasPoison, poisonCount, poisonHeader, poisonItemLink = GetItemPairedPoisonInfo(equipSlot)
    if hasPoison then
        local poisonQuality = GetItemLinkDisplayQuality(poisonItemLink)
        local poisonQualityColor = GetItemQualityColor(poisonQuality)

        local poisonNameString = poisonQualityColor:Colorize(poisonHeader)
        local poisonCountString = tostring(poisonCount)

        local equippedPoisonSection = self:AcquireSection(self:GetStyle("equippedPoisonSection"))

        equippedPoisonSection:AddLine(
            string.format(
                "%s (%s)",
                poisonNameString,
                poisonCountString
            ),
            self:GetStyle("bodyHeader")
        )

        self:AddSection(equippedPoisonSection)

        self:AddOnUseAbility(poisonItemLink)
    end

    return true
end

EVENT_MANAGER:RegisterForEvent("TooltipPoison", EVENT_ADD_ON_LOADED, function(_, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("TooltipPoison", EVENT_ADD_ON_LOADED)
    Utils.HookAllGamepadTooltips("pre", "AddPoisonInfo", Tooltip_AddPoisonInfo_Before)
end)
