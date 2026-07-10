local _GetTraitIcon = _G["GamePadHelper_Utils"] and _G["GamePadHelper_Utils"].GetTraitIcon
local MultiIcon = _G["GamePadHelper_IconExtensions"]

local function GetItemLinkFromData(data)
    if type(data) ~= "table" then
        return nil
    end

    local bagId = data.bagId or data.bag
    local slotIndex = data.slotIndex or data.index

    if (bagId == nil or slotIndex == nil) and type(data.dataSource) == "table" then
        bagId = data.dataSource.bagId or data.dataSource.bag or bagId
        slotIndex = data.dataSource.slotIndex or data.dataSource.index or slotIndex
    end

    if (bagId == nil or slotIndex == nil) and type(data.itemData) == "table" then
        bagId = data.itemData.bagId or data.itemData.bag or bagId
        slotIndex = data.itemData.slotIndex or data.itemData.index or slotIndex
    end

    if bagId ~= nil and slotIndex ~= nil then
        return GetItemLink(bagId, slotIndex), bagId, slotIndex
    end

    if data.lootId ~= nil then
        return GetLootItemLink(data.lootId), nil, nil
    end

    return nil
end

local function EnsureResearchLabel(control, icon)
    local label = control:GetNamedChild("StatusIndicatorLabel")
    if label then return label end

    label = CreateControl("$(parent)StatusIndicatorLabel", control, CT_LABEL)
    label:SetFont("ZoFontGamepad18")
    label:SetInheritScale(false)
    label:SetMaxLineCount(1)
    label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    label:SetVerticalAlignment(TEXT_ALIGN_TOP)
    label:SetDrawLayer(DL_OVERLAY)
    label:SetDrawTier(DT_HIGH)
    label:ClearAnchors()
    label:SetAnchor(TOPLEFT, icon, BOTTOMLEFT, 0, 2)
    label:SetAnchor(TOPRIGHT, icon, BOTTOMRIGHT, 0, 2)
    return label
end

local function ClearTraitDecoration(icon, label, researchIcon)
    if researchIcon and icon.RemoveIcon then icon:RemoveIcon(researchIcon) end
    if label then
        label:SetText("")
        label:SetHidden(true)
    end
end

local function RefreshMultiIcon(icon)
    if not icon or not icon.iconData or not icon.Hide or not icon.Show then return end
    if not icon:IsHidden() then icon:Hide() end
    icon:Show()
end

local function ClearAndRefresh(icon, label, researchIcon)
    ClearTraitDecoration(icon, label, researchIcon)
    RefreshMultiIcon(icon)
end

local function ClearDeconstructionTraitLegend()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

local function IsDeconstructionTraitLegendEnabled()
    local sv = _G["GamePadHelper_CharSavedVars"]
    return sv and sv.inventoryTraitEnabled and sv.inventoryTraitDeconstructionLegendEnabled
end

local function IsDeconstructionTraitLegendVisible()
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv then return true end
    return sv.inventoryTraitDeconstructionLegendVisible ~= false
end

local function SetDeconstructionTraitLegendVisible(visible)
    local sv = _G["GamePadHelper_CharSavedVars"]
    if sv then sv.inventoryTraitDeconstructionLegendVisible = visible end
end

local function ShouldShowDeconstructionTraitLegend()
    return IsDeconstructionTraitLegendEnabled() and IsDeconstructionTraitLegendVisible()
end

local function RefreshDeconstructionTraitLegend()
    if not ShouldShowDeconstructionTraitLegend() then
        ClearDeconstructionTraitLegend()
        return
    end

    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(
        GAMEPAD_RIGHT_TOOLTIP,
        GetString(SI_GPH_SETTING_INVENTORY_TRAITS_NAME),
        GetString(SI_GPH_TRAIT_COLOR_LEGEND)
    )
end

local function AddDeconstructionTraitLegendKeybind(panel)
    if not panel or panel.gphTraitLegendKeybindAdded or not panel.keybindStripDescriptor then
        return
    end

    table.insert(panel.keybindStripDescriptor,
    {
        name = function()
            if not IsDeconstructionTraitLegendVisible() then
                return GetString(SI_GPH_DECONSTRUCTION_TRAIT_LEGEND_SHOW)
            end
            return GetString(SI_GPH_DECONSTRUCTION_TRAIT_LEGEND_HIDE)
        end,
        keybind = "UI_SHORTCUT_QUINARY",
        gamepadOrder = 1015,
        visible = function()
            return IsDeconstructionTraitLegendEnabled()
        end,
        callback = function()
            SetDeconstructionTraitLegendVisible(not IsDeconstructionTraitLegendVisible())
            RefreshDeconstructionTraitLegend()
            if KEYBIND_STRIP and panel.keybindStripDescriptor then
                KEYBIND_STRIP:UpdateKeybindButtonGroup(panel.keybindStripDescriptor)
            end
        end,
    })

    panel.gphTraitLegendKeybindAdded = true
end

local function GetTraitResearchState(itemLink, bagId, slotIndex)
    if not itemLink or not LibTraitResearch then return nil end
    return LibTraitResearch:GetItemLinkTraitResearchStateForSlot(itemLink, bagId, slotIndex)
end

local function BuildDuplicateLabelText(duplicateRemoteItems, colorRemote, duplicateLocalItems, colorLocal)
    if duplicateRemoteItems > 0 and duplicateLocalItems > 0 then
        return colorRemote:Colorize(duplicateRemoteItems) .. " " .. colorLocal:Colorize(duplicateLocalItems)
    elseif duplicateRemoteItems > 0 then
        return colorRemote:Colorize(duplicateRemoteItems)
    elseif duplicateLocalItems > 0 then
        return colorLocal:Colorize(duplicateLocalItems)
    end
    return nil
end

local function ApplyTraitOverrideData(data)
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv or not sv.inventoryTraitEnabled or type(data) ~= "table" then return end

    local itemLink, bagId, slotIndex = GetItemLinkFromData(data)
    if not itemLink then return end

    local canBeResearched, colorOverall, duplicateRemoteItems, colorRemote, duplicateLocalItems, colorLocal =
        GetTraitResearchState(itemLink, bagId, slotIndex)

    if not canBeResearched or not data.overrideStatusIndicatorIcons then return end

    local researchIcon = _GetTraitIcon and _GetTraitIcon(ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED)
    if not researchIcon then return end

    local traitNarration = GetString("SI_ITEMTRAITINFORMATION", ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED)
    local bothDuplicates = duplicateRemoteItems > 0 and duplicateLocalItems > 0

    local filtered = {}
    for _, iconData in ipairs(data.overrideStatusIndicatorIcons) do
        if iconData.iconTexture ~= researchIcon then
            table.insert(filtered, iconData)
        end
    end
    data.overrideStatusIndicatorIcons = filtered

    if bothDuplicates then
        table.insert(data.overrideStatusIndicatorIcons, { iconTexture = researchIcon, iconTint = colorRemote, iconNarration = traitNarration })
        table.insert(data.overrideStatusIndicatorIcons, { iconTexture = researchIcon, iconTint = colorLocal,  iconNarration = traitNarration })
    else
        table.insert(data.overrideStatusIndicatorIcons, { iconTexture = researchIcon, iconTint = colorOverall, iconNarration = traitNarration })
    end
end

local function SharedGamepadEntry_OnSetup_After(control, data)
    local sv = _G["GamePadHelper_CharSavedVars"]
    if not sv or not sv.inventoryTraitEnabled then return end

    local icon = control:GetNamedChild("StatusIndicator")
    if not icon then return end

    if MultiIcon then
        MultiIcon.Initialize(icon)
    elseif not icon.HasIcon or not icon.AddIcon then
        ZO_MultiIcon_Initialize(icon)
    end

    local researchIcon = _GetTraitIcon and _GetTraitIcon(ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED)

    local itemLink, bagId, slotIndex = GetItemLinkFromData(data)
    if not itemLink then
        ClearAndRefresh(icon, nil, researchIcon)
        return
    end

    local label = EnsureResearchLabel(control, icon)
    label:SetHidden(true)

    local canBeResearched, colorOverall, duplicateRemoteItems, colorRemote, duplicateLocalItems, colorLocal =
        GetTraitResearchState(itemLink, bagId, slotIndex)

    if not canBeResearched then
        ClearAndRefresh(icon, label, researchIcon)
        return
    end

    local bothDuplicates = duplicateRemoteItems > 0 and duplicateLocalItems > 0

    if researchIcon then
        if icon.RemoveIcon then icon:RemoveIcon(researchIcon) end
        if bothDuplicates then
            icon:AddIcon(researchIcon, colorRemote)
            icon:AddIcon(researchIcon, colorLocal)
        else
            icon:AddIcon(researchIcon, colorOverall)
        end
    end
    icon:Show()

    local duplicateLabelText = BuildDuplicateLabelText(duplicateRemoteItems, colorRemote, duplicateLocalItems, colorLocal)
    if duplicateLabelText then
        label:SetText(duplicateLabelText)
        label:SetHidden(false)
    else
        label:SetText("")
        label:SetHidden(true)
    end

    RefreshMultiIcon(icon)
end

ZO_PostHook("ZO_SharedGamepadEntry_OnSetup", SharedGamepadEntry_OnSetup_After)

local function WrapCustomExtraDataFunction(inventory)
    if not inventory or inventory.gphTraitExtraDataWrapped or type(inventory.customExtraDataFunction) ~= "function" then
        return
    end

    local originalCustomExtraDataFunction = inventory.customExtraDataFunction
    inventory.customExtraDataFunction = function(bagId, slotIndex, data)
        originalCustomExtraDataFunction(bagId, slotIndex, data)
        ApplyTraitOverrideData(data)
    end
    inventory.gphTraitExtraDataWrapped = true
end

local function PatchDeconstructionSetupFunctionForInventory(inventory)
    if not inventory or not inventory.list then return false end

    local list = inventory.list
    if not list.SetDataTemplateSetupFunction or not list.dataTypes then return false end

    local function WrapTemplate(templateName)
        local dataType = list.dataTypes[templateName]
        if not dataType or type(dataType.setupFunction) ~= "function" or dataType.gphTraitWrapped then
            return false
        end

        local originalSetup = dataType.setupFunction
        list:SetDataTemplateSetupFunction(templateName, function(control, data, selected, ...)
            originalSetup(control, data, selected, ...)
            SharedGamepadEntry_OnSetup_After(control, data)
        end)
        dataType.gphTraitWrapped = true
        return true
    end

    local patched = false
    patched = WrapTemplate("ZO_GamepadItemSubEntryTemplate") or patched
    patched = WrapTemplate("ZO_GamepadItemSubEntryTemplateWithHeader") or patched
    patched = WrapTemplate("ZO_GamepadItemSubEntry") or patched
    return patched
end

local function DecorateDeconstructionVisibleControls(inventory)
    if not inventory or not inventory.list or not inventory.list.GetAllVisibleControls then return end

    local visibleControls = inventory.list:GetAllVisibleControls()
    if not visibleControls then return end

    for control in pairs(visibleControls) do
        local data = control.dataEntry and control.dataEntry.data
        if not data then
            local dataIndex = control.dataIndex
            if dataIndex and inventory.list.dataList then
                data = inventory.list.dataList[dataIndex]
            end
        end

        if data then
            ApplyTraitOverrideData(data)
            SharedGamepadEntry_OnSetup_After(control, data)
        end
    end
end

local function QueueDeconstructionVisibleRefresh(inventory)
    if not inventory or inventory.gphTraitRefreshQueued then return end
    inventory.gphTraitRefreshQueued = true
    local function Refresh()
        if inventory.list then DecorateDeconstructionVisibleControls(inventory) end
    end
    zo_callLater(Refresh, 50)
    zo_callLater(function() Refresh() inventory.gphTraitRefreshQueued = false end, 200)
end

local function RefreshDeconstructionInventory(inventory)
    DecorateDeconstructionVisibleControls(inventory)
    QueueDeconstructionVisibleRefresh(inventory)
end

local function HookDeconstructionInventory(inventory)
    if not inventory then return end

    WrapCustomExtraDataFunction(inventory)

    if not inventory.gphTraitRefreshWrapped then
        local originalPerformFullRefresh = inventory.PerformFullRefresh
        inventory.PerformFullRefresh = function(self, ...)
            WrapCustomExtraDataFunction(self)
            PatchDeconstructionSetupFunctionForInventory(self)
            local result = originalPerformFullRefresh(self, ...)
            RefreshDeconstructionInventory(self)
            return result
        end
        inventory.gphTraitRefreshWrapped = true
    end

    if inventory.list and not inventory.list.gphTraitRefreshWrapped then
        local originalRefreshVisible = inventory.list.RefreshVisible
        inventory.list.RefreshVisible = function(listSelf, ...)
            local result = originalRefreshVisible(listSelf, ...)
            RefreshDeconstructionInventory(inventory)
            return result
        end
        inventory.list.gphTraitRefreshWrapped = true
    end

    PatchDeconstructionSetupFunctionForInventory(inventory)
    RefreshDeconstructionInventory(inventory)
end

local function HookDeconstructionTraitLegend(panel, scene)
    if not panel or panel.gphTraitLegendWrapped then return end

    AddDeconstructionTraitLegendKeybind(panel)

    local originalRefreshTooltip = panel.RefreshTooltip
    panel.RefreshTooltip = function(self, ...)
        local result = originalRefreshTooltip(self, ...)
        RefreshDeconstructionTraitLegend()
        return result
    end

    if scene and not panel.gphTraitLegendSceneHooked then
        scene:RegisterCallback("StateChange", function(oldState, newState)
            if newState == SCENE_SHOWING or newState == SCENE_SHOWN then
                zo_callLater(function()
                    RefreshDeconstructionTraitLegend()
                    if KEYBIND_STRIP and panel.keybindStripDescriptor then
                        KEYBIND_STRIP:UpdateKeybindButtonGroup(panel.keybindStripDescriptor)
                    end
                end, 0)
            elseif newState == SCENE_HIDING or newState == SCENE_HIDDEN then
                ClearDeconstructionTraitLegend()
            end
        end)
        panel.gphTraitLegendSceneHooked = true
    end

    panel.gphTraitLegendWrapped = true
end

local deconstructionHooksInstalled = false

local function TryInstallDeconstructionHooks()
    if deconstructionHooksInstalled then return true end

    if not ZO_UniversalDeconstructionPanel_Gamepad or not ZO_GamepadSmithingExtraction then
        return false
    end

    local function HookClass(class)
        ZO_PostHook(class, "InitializeInventory", function(self)
            HookDeconstructionInventory(self.inventory)
        end)
        ZO_PostHook(class, "Initialize", function(self, _, _, _, _, scene)
            HookDeconstructionTraitLegend(self, scene)
        end)
    end

    HookClass(ZO_UniversalDeconstructionPanel_Gamepad)
    HookClass(ZO_GamepadSmithingExtraction)

    if UNIVERSAL_DECONSTRUCTION_GAMEPAD
        and UNIVERSAL_DECONSTRUCTION_GAMEPAD.deconstructionPanel
        and UNIVERSAL_DECONSTRUCTION_GAMEPAD.deconstructionPanel.inventory
    then
        HookDeconstructionInventory(UNIVERSAL_DECONSTRUCTION_GAMEPAD.deconstructionPanel.inventory)
        HookDeconstructionTraitLegend(UNIVERSAL_DECONSTRUCTION_GAMEPAD.deconstructionPanel, UNIVERSAL_DECONSTRUCTION_GAMEPAD.scene)
    end

    if SMITHING_GAMEPAD and SMITHING_GAMEPAD.deconstructionPanel and SMITHING_GAMEPAD.deconstructionPanel.inventory then
        HookDeconstructionInventory(SMITHING_GAMEPAD.deconstructionPanel.inventory)
        HookDeconstructionTraitLegend(SMITHING_GAMEPAD.deconstructionPanel, GAMEPAD_SMITHING_DECONSTRUCT_SCENE)
    end

    deconstructionHooksInstalled = true
    return true
end

local function RedecorateInventoryList(inventoryList)
    if not inventoryList then return end
    local list = (inventoryList.list and inventoryList.list.GetAllVisibleControls) and inventoryList.list or inventoryList
    local visibleControls = list.GetAllVisibleControls and list:GetAllVisibleControls()
    if not visibleControls then return end
    for control in pairs(visibleControls) do
        local dataIndex = control.dataIndex
        local data = dataIndex and list.dataList and list.dataList[dataIndex]
        if data then SharedGamepadEntry_OnSetup_After(control, data) end
    end
end

local function RefreshBagVisibleItems()
    zo_callLater(function()
        if GAMEPAD_INVENTORY then
            RedecorateInventoryList(GAMEPAD_INVENTORY.itemList)
            RedecorateInventoryList(GAMEPAD_INVENTORY.vengeanceItemList)
        end
        if GAMEPAD_BANKING then
            RedecorateInventoryList(GAMEPAD_BANKING.withdrawList)
            RedecorateInventoryList(GAMEPAD_BANKING.depositList)
        end
    end, 0)
end

EVENT_MANAGER:RegisterForEvent("GPH_InventoryTrait_SlotLocked",   EVENT_INVENTORY_SLOT_LOCKED,   RefreshBagVisibleItems)
EVENT_MANAGER:RegisterForEvent("GPH_InventoryTrait_SlotUnlocked", EVENT_INVENTORY_SLOT_UNLOCKED, RefreshBagVisibleItems)

EVENT_MANAGER:RegisterForEvent("GPH_InventoryTrait_Initialize", EVENT_PLAYER_ACTIVATED, function()
    EVENT_MANAGER:UnregisterForEvent("GPH_InventoryTrait_Initialize", EVENT_PLAYER_ACTIVATED)

    local function TryLater()
        if not TryInstallDeconstructionHooks() then
            zo_callLater(TryLater, 1000)
        end
    end

    TryLater()
end)
