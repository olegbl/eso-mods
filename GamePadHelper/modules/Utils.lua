local GPH_Utils = {}
_G["GamePadHelper_Utils"] = GPH_Utils

GPH_Utils.GetTraitIcon = ZO_GetPlatformTraitInformationIcon or GetPlatformTraitInformationIcon

local traitColorCache = {}

function GPH_Utils.GetTraitColor(state, fallback)
    if not fallback then
        if state == "equipped" then fallback = ZO_ColorDef:New("3399FF")
        elseif state == "inventory" then fallback = ZO_CURRENCY_HIGHLIGHT_TEXT
        elseif state == "bank" then fallback = ZO_ERROR_COLOR
        elseif state == "locked" then fallback = LOCKED_COLOR or ZO_ColorDef:New(0.5, 0.5, 0.5, 1)
        else fallback = GetItemQualityColor(ITEM_DISPLAY_QUALITY_MAGIC or ITEM_QUALITY_MAGIC) end
    end
    local sv = _G["GamePadHelper_CharSavedVars"]
    local colors = sv and sv.traitColors
    local hex = type(colors) == "table" and colors[state] or nil
    if type(hex) ~= "string" or #hex ~= 6 or not hex:match("^%x+$") then return fallback end
    if not traitColorCache[hex] then traitColorCache[hex] = ZO_ColorDef:New(hex) end
    return traitColorCache[hex]
end

function GPH_Utils.GetTraitResearchState(itemLink, bagId, slotIndex)
    if not itemLink or not LibTraitResearch then return nil end
    local canResearch, overall, remote, remoteColor, localCount, localColor
    if LibTraitResearch.GetItemLinkTraitResearchStateForSlot then
        canResearch, overall, remote, remoteColor, localCount, localColor =
            LibTraitResearch:GetItemLinkTraitResearchStateForSlot(itemLink, bagId, slotIndex)
    else
        canResearch, overall, remote, remoteColor, localCount, localColor =
            LibTraitResearch:GetItemLinkTraitResearchState(itemLink)
    end
    if not canResearch then return canResearch, overall, remote, remoteColor, localCount, localColor end
    local state
    if bagId == BAG_WORN then state = "equipped"
    elseif bagId ~= nil and slotIndex ~= nil and IsItemPlayerLocked(bagId, slotIndex) then state = "locked"
    elseif remote > 0 then state = "bank"
    elseif localCount > 0 then state = "inventory"
    else state = "unique" end
    return canResearch, GPH_Utils.GetTraitColor(state, overall), remote, GPH_Utils.GetTraitColor("bank", remoteColor),
        localCount, GPH_Utils.GetTraitColor("inventory", localColor)
end

local treasureDefaults = {
    countess = ZO_ColorDef:New(0.18, 0.77, 0.05),
    crow = ZO_ColorDef:New(0.18, 0.77, 0.05),
    inactive = ZO_ColorDef:New(1, 1, 1),
}

function GPH_Utils.GetTreasureColor(state)
    local sv = _G.GamePadHelper_CharSavedVars
    local colors = sv and sv.treasureColors
    local hex = type(colors) == "table" and colors[state] or nil
    if type(hex) ~= "string" or #hex ~= 6 or not hex:match("^%x+$") then return treasureDefaults[state] end
    if not traitColorCache[hex] then traitColorCache[hex] = ZO_ColorDef:New(hex) end
    return traitColorCache[hex]
end

function GPH_Utils.GetTreasureLegend(state)
    local entry = GetString(state == "countess" and SI_GPH_TREASURE_LEGEND_COUNTESS or SI_GPH_TREASURE_LEGEND_CROW)
    entry = entry:gsub("|c%x%x%x%x%x%x", "|c" .. GPH_Utils.GetTreasureColor(state):ToHex())
    local legend = GetString(SI_GPH_TREASURE_COLOR_LEGEND):gsub("|c%x%x%x%x%x%x", "|c" .. GPH_Utils.GetTreasureColor("inactive"):ToHex())
    return zo_strformat(legend, entry)
end

local traitLegendRowPools = {}
local nextTraitLegendPoolId = 0

local function AcquireTraitLegendRow(section)
    local template = "GPH_TraitLegendRow"
    local pool = traitLegendRowPools[section]
    if pool and section.customControlPools[template] ~= pool then
        -- ZO_TooltipSection:Initialize replaces customControlPools when a pooled
        -- section is reused. Keep our pool (and its controls) across that reset.
        pool:ReleaseAllObjects()
        section.customControlPools[template] = pool
    end
    local overrideName
    if not pool then
        nextTraitLegendPoolId = nextTraitLegendPoolId + 1
        overrideName = "GPH_TraitLegendPool" .. nextTraitLegendPoolId .. "Row"
    end
    local row = section:AcquireCustomControl({
        controlTemplate = template,
        -- Different tooltip sections can have the same control name. Their
        -- independent pools must not generate the same global control names.
        controlTemplateOverrideName = overrideName,
    })
    traitLegendRowPools[section] = section.customControlPools[template]
    return row
end

function GPH_Utils.GetTraitLegend()
    local researchTexture = GPH_Utils.GetTraitIcon(ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED)
    local function ColoredIcon(texture, color)
        return color:Colorize(zo_iconFormatInheritColor(texture, 32, 32))
    end
    local equippedColor = GPH_Utils.GetTraitColor("equipped")
    local lockedColor = GPH_Utils.GetTraitColor("locked")
    return zo_strformat(SI_GPH_TRAIT_COLOR_LEGEND,
        ColoredIcon(researchTexture, equippedColor) .. " " .. zo_iconFormat(ZO_GAMEPAD_IS_EQUIPPED_ICON, 32, 32),
        ColoredIcon(researchTexture, GPH_Utils.GetTraitColor("unique")),
        ColoredIcon(researchTexture, GPH_Utils.GetTraitColor("inventory")),
        ColoredIcon(researchTexture, GPH_Utils.GetTraitColor("bank")),
        ColoredIcon(researchTexture, lockedColor) .. " " .. zo_iconFormat(ZO_GAMEPAD_LOCKED_ICON_32, 32, 32))
end

-- Reuse the legend controls and display the same configurable research colors
-- as inventory/tooltips, without adding location icons to the cycling sequence.
function ZO_Tooltip:LayoutGPHTraitLegendTooltip(title, description)
    if title then
        local heading = self:AcquireSection(self:GetStyle("bodySection"))
        heading:AddLine(title, self:GetStyle("title"))
        self:AddSection(heading)
    end
    if description then
        local intro = self:AcquireSection(self:GetStyle("bodySection"))
        intro:AddLine(description, self:GetStyle("bodyDescription"))
        self:AddSection(intro)
    end

    local lines = {}
    for line in GetString(SI_GPH_TRAIT_COLOR_LEGEND):gmatch("[^\n]+") do
        lines[#lines + 1] = line
    end
    local research = GPH_Utils.GetTraitIcon(ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED)
    local colors = {
        GPH_Utils.GetTraitColor("equipped"),
        GPH_Utils.GetTraitColor("unique"),
        GPH_Utils.GetTraitColor("inventory"),
        GPH_Utils.GetTraitColor("bank"),
        GPH_Utils.GetTraitColor("locked"),
    }
    for index = 1, 5 do
        local section = self:AcquireSection(self:GetStyle("bodySection"))
        local row = AcquireTraitLegendRow(section)
        row:SetWidth(math.max(240, self:GetWidth() - 40))
        local icon = row:GetNamedChild("Icon")
        local count = row:GetNamedChild("Count")
        local nativeState = row:GetNamedChild("NativeState")
        local caption = (lines[index] or ""):gsub("^<<%d+>>%s*", "")
        row:GetNamedChild("Caption"):SetText(caption)
        _G["GamePadHelper_IconExtensions"].Initialize(icon)
        icon:ClearIcons()
        icon:AddIcon(research, colors[index])
        count:SetText(index == 3 and colors[3]:Colorize("2") or index == 4 and colors[4]:Colorize("3") or "")
        count:SetHidden(index ~= 3 and index ~= 4)
        nativeState:SetHidden(true)
        if index == 1 then
            icon:AddIcon(ZO_GAMEPAD_IS_EQUIPPED_ICON)
        elseif index == 5 then
            nativeState:SetTexture(ZO_GAMEPAD_LOCKED_ICON_32)
            nativeState:SetHidden(false)
        end
        section:AddCustomControl(row, caption)
        self:AddSection(section)
        icon:Show()
    end
    local notes = self:AcquireSection(self:GetStyle("bodySection"))
    notes:AddLine(table.concat(lines, "\n", 6), self:GetStyle("bodyDescription"))
    self:AddSection(notes)
end

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
