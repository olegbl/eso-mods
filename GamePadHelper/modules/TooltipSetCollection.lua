-- Appends an account set-collection progress line to gamepad tooltips for
-- single-set containers (e.g. Imperial City Tel Var coffers). The container's
-- set id is read directly from the item link; pure logic lives in
-- modules/SetCollectionData.lua (_G["GPH_SetCollection"]).

local function OnAddonLoaded(event, name)
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("TooltipSetCollection", EVENT_ADD_ON_LOADED)

    local Utils = _G["GamePadHelper_Utils"]
    local Data = _G["GPH_SetCollection"]

    local function Tooltip_AddContainerSets_After(self, itemLink)
        local sv = _G["GamePadHelper_CharSavedVars"]
        if not sv or not sv.tooltipSetCollectionEnabled then return end
        if not Data or not itemLink or itemLink == "" then return end

        -- Single-set containers only (skip multi-set and no-set containers).
        if GetItemLinkNumContainerSetIds(itemLink) ~= 1 then return end

        local hasSet, setName, _, _, _, setId = GetItemLinkContainerSetInfo(itemLink, 1)
        if not hasSet or not setId or setId <= 0 then return end

        local collectionSetId = Data.ResolveCollectionSetId(setId)
        if not collectionSetId then return end

        local line = Data.BuildProgressLine(collectionSetId, setName)
        if not line then return end

        local section = self:AcquireSection(self:GetStyle("bodySection"))
        section:AddLine(line, self:GetStyle("bodyDescription"))
        self:AddSection(section)
    end

    Utils.HookAllGamepadTooltips("post", "AddContainerSets", Tooltip_AddContainerSets_After)
end

EVENT_MANAGER:RegisterForEvent("TooltipSetCollection", EVENT_ADD_ON_LOADED, OnAddonLoaded)
