

-- GetPlatformTraitInformationIcon is a PC-only alias; ZO_GetPlatformTraitInformationIcon is the base function
local _GetTraitIcon = ZO_GetPlatformTraitInformationIcon or GetPlatformTraitInformationIcon

local REFRESH_NAMESPACE = "GPH_InventoryTrait_Refresh"
local refreshPending = false
local REFRESH_DELAYS_MS = { 50, 200, 500 }

local function IsInCraftBagTab()
    if GAMEPAD_INVENTORY and GAMEPAD_INVENTORY.header then
        local tabBar = GAMEPAD_INVENTORY.header.tabBar
        if tabBar then
            local selectedData = tabBar:GetSelectedData()
            if selectedData and selectedData.text == GetString(SI_GAMEPAD_INVENTORY_CRAFT_BAG_HEADER) then
                return true
            end
        end
    end
    return false
end

local function GetItemLinkFromData(data)
    if type(data) ~= "table" then
        return nil
    end

    local itemLink
    local bagId = data.bagId
    local slotIndex = data.slotIndex
    if (bagId == nil or slotIndex == nil) and type(data.dataSource) == "table" then
        bagId = data.dataSource.bagId
        slotIndex = data.dataSource.slotIndex
    end

    if bagId ~= nil and slotIndex ~= nil then
        itemLink = GetItemLink(bagId, slotIndex)
    elseif data.lootId ~= nil then
        itemLink = GetLootItemLink(data.lootId)
    end
    return itemLink, bagId, slotIndex
end

local function RefreshList(list)
    if not list or not list.RefreshVisible then return false end

    local selectedIndex = list.GetSelectedIndex and list:GetSelectedIndex() or nil
    if selectedIndex and selectedIndex > 0 and list.SetSelectedIndex then
        list:SetSelectedIndex(selectedIndex, true)
    end
    list:RefreshVisible()
    return true
end

local function RefreshVisibleInventoryRows()
    local sv = _G["GamePadHelper_SavedVars"]
    if not sv or not sv.inventoryTraitEnabled then return end
    if IsInCraftBagTab() then return end
    if not GAMEPAD_INVENTORY then return end

    local refreshed = false
    refreshed = RefreshList(GAMEPAD_INVENTORY.activeList) or refreshed
    refreshed = RefreshList(GAMEPAD_INVENTORY.itemList) or refreshed
    refreshed = RefreshList(GAMEPAD_INVENTORY.list) or refreshed
    refreshed = RefreshList(GAMEPAD_INVENTORY.currentList) or refreshed

    if not refreshed and GAMEPAD_INVENTORY.RefreshList then
        GAMEPAD_INVENTORY:RefreshList()
    end
end

local function QueueInventoryRowsRefresh()
    local sv = _G["GamePadHelper_SavedVars"]
    if not sv or not sv.inventoryTraitEnabled or refreshPending then return end

    refreshPending = true
    for index, delayMs in ipairs(REFRESH_DELAYS_MS) do
        zo_callLater(function()
            RefreshVisibleInventoryRows()
            if index == #REFRESH_DELAYS_MS then
                refreshPending = false
            end
        end, delayMs)
    end
end

local function ZO_SharedGamepadEntry_OnSetup_After(self, data, ...)
    local sv = _G["GamePadHelper_SavedVars"]
    if not sv or not sv.inventoryTraitEnabled then return end
    if IsInCraftBagTab() then return end

    if type(data) ~= "table" then return end

    local itemLink, bagId, slotIndex = GetItemLinkFromData(data)
    if not itemLink then return end

    local researchIcon = _GetTraitIcon and _GetTraitIcon(ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED)
    local icon = self:GetNamedChild("StatusIndicator")
    if not icon then return end

    local researchLabel = self:GetNamedChild("StatusIndicatorLabel")
    if researchLabel == nil then
        researchLabel = CreateControl("$(parent)StatusIndicatorLabel", self, CT_LABEL)
        researchLabel:SetFont("ZoFontGamepad18")
        researchLabel:SetInheritScale(false)
        researchLabel:SetMaxLineCount(1)
        researchLabel:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        researchLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
        researchLabel:SetVerticalAlignment(TEXT_ALIGN_TOP)
        researchLabel:SetDrawLayer(DL_OVERLAY)
        researchLabel:SetDrawTier(DT_HIGH)
        researchLabel:ClearAnchors()
        researchLabel:SetAnchor(TOPLEFT, icon, BOTTOMLEFT, 0, 2)
        researchLabel:SetAnchor(TOPRIGHT, icon, BOTTOMRIGHT, 0, 2)
    end

    researchLabel:SetHidden(true)

    if bagId == BAG_WORN then
        if not icon.HasIcon or not icon.AddIcon or not icon.SetIconColor then
            ZO_MultiIcon_Initialize(icon)
        end
        if researchIcon and icon.HasIcon and icon:HasIcon(researchIcon) and icon.SetIconColor then
            icon:SetIconColor(researchIcon, 1, 1, 1, 1)
        end
        return
    end

    if not icon.HasIcon or not icon.AddIcon or not icon.SetIconColor then
        ZO_MultiIcon_Initialize(icon)
    end

    if not LibTraitResearch then return end
    local canBeResearched, colorOverall, duplicateRemoteItems, colorRemote, duplicateLocalItems, colorLocal
    if LibTraitResearch.GetItemLinkTraitResearchStateForSlot and bagId ~= nil and slotIndex ~= nil then
        canBeResearched, colorOverall, duplicateRemoteItems, colorRemote, duplicateLocalItems, colorLocal = LibTraitResearch:GetItemLinkTraitResearchStateForSlot(itemLink, bagId, slotIndex)
    else
        canBeResearched, colorOverall, duplicateRemoteItems, colorRemote, duplicateLocalItems, colorLocal = LibTraitResearch:GetItemLinkTraitResearchState(itemLink)
    end

    if canBeResearched then
        if researchIcon and not icon:HasIcon(researchIcon) then
            icon:AddIcon(researchIcon)
        end
        local duplicateRemoteText = colorRemote:Colorize(duplicateRemoteItems)
        local duplicateLocalText = colorLocal:Colorize(duplicateLocalItems)

        if icon.SetIconColor then
            icon:SetIconColor(researchIcon, colorOverall:UnpackRGBA())
        end

        researchLabel:SetHidden(duplicateRemoteItems == 0 and duplicateLocalItems == 0)

        if duplicateRemoteItems > 0 and duplicateLocalItems > 0 then
            researchLabel:SetText(duplicateRemoteText.." "..duplicateLocalText)
        elseif duplicateRemoteItems > 0 then
            researchLabel:SetText(duplicateRemoteText)
        elseif duplicateLocalItems > 0 then
            researchLabel:SetText(duplicateLocalText)
        end
    else
        researchLabel:SetHidden(true)
    end
end

ZO_PostHook("ZO_SharedGamepadEntry_OnSetup", ZO_SharedGamepadEntry_OnSetup_After)

EVENT_MANAGER:RegisterForEvent(REFRESH_NAMESPACE, EVENT_PLAYER_ACTIVATED, function()
    EVENT_MANAGER:UnregisterForEvent(REFRESH_NAMESPACE, EVENT_PLAYER_ACTIVATED)
    local function RegisterRefreshEvent(suffix, eventCode)
        if eventCode then
            EVENT_MANAGER:RegisterForEvent(REFRESH_NAMESPACE .. suffix, eventCode, QueueInventoryRowsRefresh)
        end
    end

    RegisterRefreshEvent("_SlotUpdate", EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
    RegisterRefreshEvent("_FullUpdate", EVENT_INVENTORY_FULL_UPDATE)
    RegisterRefreshEvent("_ResearchStarted", EVENT_SMITHING_TRAIT_RESEARCH_STARTED)
    RegisterRefreshEvent("_ResearchCompleted", EVENT_SMITHING_TRAIT_RESEARCH_COMPLETED)
end)

