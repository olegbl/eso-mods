local _GetTraitIcon = ZO_GetPlatformTraitInformationIcon or GetPlatformTraitInformationIcon
local RESEARCH_ICON = _GetTraitIcon and zo_iconFormatInheritColor(_GetTraitIcon(ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED), 32, 32)
local BAG_ICON = zo_iconFormatInheritColor("esoui/art/tooltips/icon_bag.dds", 20, 20)
local BANK_ICON = zo_iconFormatInheritColor("esoui/art/tooltips/icon_bank.dds", 20, 20)
local COLOR_WORN = ZO_ColorDef:New("FFFFFF")

local function OnAddonLoaded(event, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("TooltipTrait", EVENT_ADD_ON_LOADED)

    local function Tooltip_AddTrait_Before(self, itemLink, extraData)
        local sv = _G["GamePadHelper_SavedVars"]
        if not sv or not sv.tooltipTraitEnabled then return end
        local traitType, traitDescription = GetItemLinkTraitInfo(itemLink)
        if traitType ~= ITEM_TRAIT_TYPE_NONE and traitDescription ~= "" then
            local traitName = GetString("SI_ITEMTRAITTYPE", traitType)
            if traitName ~= "" then
                local traitSection = self:AcquireSection(self:GetStyle("bodySection"))
                local traitInformation = GetItemTraitInformationFromItemLink(itemLink)
                local traitInformationIcon = _GetTraitIcon and _GetTraitIcon(traitInformation)

                local canBeResearched, colorOverall, duplicateRemoteItems, colorRemote, duplicateLocalItems, colorLocal
                if LibTraitResearch then
                    if LibTraitResearch.GetItemLinkTraitResearchStateForSlot and extraData and extraData.bagId ~= nil and extraData.slotIndex ~= nil then
                        canBeResearched, colorOverall, duplicateRemoteItems, colorRemote, duplicateLocalItems, colorLocal = LibTraitResearch:GetItemLinkTraitResearchStateForSlot(itemLink, extraData.bagId, extraData.slotIndex)
                    else
                        canBeResearched, colorOverall, duplicateRemoteItems, colorRemote, duplicateLocalItems, colorLocal = LibTraitResearch:GetItemLinkTraitResearchState(itemLink)
                    end
                end

                local additionalTooltipStyle
                if extraData and extraData.showTraitAsNew then
                    additionalTooltipStyle = self:GetStyle("succeeded")
                end

                local title = zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_HEADER, traitName)

                if traitInformationIcon and traitInformation ~= ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED then
                    traitInformationIcon = zo_iconFormat(traitInformationIcon, 32, 32)
                    title = string.format("%s %s", title, traitInformationIcon)
                end

                if canBeResearched then
                    local researchIcon = colorOverall:Colorize(RESEARCH_ICON)
                    local duplicateRemoteText = colorRemote:Colorize(duplicateRemoteItems)
                    local duplicateLocalText = colorLocal:Colorize(duplicateLocalItems)

                    if duplicateRemoteItems > 0 and duplicateLocalItems > 0 then
                        title = string.format("%s (%s%s%s%s%s)", title, researchIcon, BANK_ICON, duplicateRemoteText, BAG_ICON, duplicateLocalText)
                    elseif duplicateRemoteItems > 0 then
                        title = string.format("%s (%s%s%s)", title, researchIcon, BANK_ICON, duplicateRemoteText)
                    elseif duplicateLocalItems > 0 then
                        title = string.format("%s (%s%s%s)", title, researchIcon, BAG_ICON, duplicateLocalText)
                    else
                        title = string.format("%s (%s)", title, researchIcon)
                    end
                end
                
                if extraData and extraData.bagId == BAG_WORN then
                    title = string.format("%s %s", title, COLOR_WORN:Colorize("(Equipped)"))
                end

                traitSection:AddLine(title, self:GetStyle("bodyHeader"), additionalTooltipStyle)
                traitSection:AddLine(traitDescription, self:GetStyle("bodyDescription"), additionalTooltipStyle)
                self:AddSection(traitSection)
            end
        end

        return true
    end

    local tooltips = {
        GAMEPAD_LEFT_DIALOG_TOOLTIP,
        GAMEPAD_LEFT_TOOLTIP,
        GAMEPAD_MOVABLE_TOOLTIP,
        GAMEPAD_QUAD1_TOOLTIP,
        GAMEPAD_QUAD3_TOOLTIP,
        GAMEPAD_RIGHT_TOOLTIP,
    }

    for index, tooltip in ipairs(tooltips) do
        ZO_PreHook(GAMEPAD_TOOLTIPS:GetTooltip(tooltip), "AddTrait", Tooltip_AddTrait_Before)
    end
end

EVENT_MANAGER:RegisterForEvent("TooltipTrait", EVENT_ADD_ON_LOADED, OnAddonLoaded)
