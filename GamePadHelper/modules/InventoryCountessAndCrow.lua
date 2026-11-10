local Utils = _G["GamePadHelper_Utils"]
local MultiIcon = _G["GamePadHelper_IconExtensions"]
local QUEST_ICON = "/esoui/art/inventory/gamepad/gp_inventory_icon_quest.dds"

local function ClearCovetousDecoration(statusIndicator)
    if not statusIndicator then return end
    MultiIcon.Initialize(statusIndicator)
    if statusIndicator.RemoveIcon then
        statusIndicator:RemoveIcon(QUEST_ICON)
    end
end

local function GetItemLinkFromData(data)
    if type(data) ~= "table" then
        return nil
    end

    if type(data.itemLink) == "string" and data.itemLink ~= "" then
        return data.itemLink
    elseif type(data.link) == "string" and data.link ~= "" then
        return data.link
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
        return GetItemLink(bagId, slotIndex)
    elseif data.lootId ~= nil then
        return GetLootItemLink(data.lootId)
    end

    return nil
end

local function RefreshMultiIcon(icon)
    if not icon or not icon.iconData or not icon.Hide or not icon.Show then return end
    if not icon:IsHidden() then icon:Hide() end
    icon:Show()
end

local function SharedGamepadEntry_OnSetup_After(control, data)
    local sv = _G["GamePadHelper_CharSavedVars"]
    local statusIndicator = control:GetNamedChild("StatusIndicator")
    if not statusIndicator then return end

    ClearCovetousDecoration(statusIndicator)

    if not sv or (not sv.inventoryCovetousCountessEnabled and not sv.inventoryCrowEnabled) then return end

    local itemLink = GetItemLinkFromData(data)
    if not itemLink then return end

    local itemType = GetItemLinkItemType(itemLink)
    if itemType ~= ITEMTYPE_TREASURE then return end

    local isUsefulForActiveQuest, isUsefulForQuest = Utils.GetCountessState(itemLink)
    local isUsefulForActiveCrowGroup, isUsefulForCrow = Utils.GetCrowState(itemLink)

    MultiIcon.Initialize(statusIndicator)

    local countessActive = sv.inventoryCovetousCountessEnabled and isUsefulForActiveQuest
    local crowActive     = sv.inventoryCrowEnabled and isUsefulForActiveCrowGroup
    local countessUseful = sv.inventoryCovetousCountessEnabled and isUsefulForQuest
    local crowUseful     = sv.inventoryCrowEnabled and isUsefulForCrow

    local anyActive  = countessActive or crowActive
    local anyUseful  = countessUseful or crowUseful

    if anyActive or anyUseful then
        if countessActive then statusIndicator:AddIcon(QUEST_ICON, Utils.GetTreasureColor("countess")) end
        if crowActive and (not countessActive or Utils.GetTreasureColor("countess"):ToHex() ~= Utils.GetTreasureColor("crow"):ToHex()) then
            statusIndicator:AddIcon(QUEST_ICON, Utils.GetTreasureColor("crow"))
        end
        if not anyActive then statusIndicator:AddIcon(QUEST_ICON, Utils.GetTreasureColor("inactive")) end
        statusIndicator:Show()
    end

    RefreshMultiIcon(statusIndicator)
end

ZO_PostHook("ZO_SharedGamepadEntry_OnSetup", SharedGamepadEntry_OnSetup_After)

local function RedecorateInventoryList(inventoryList)
    if not inventoryList then return end
    local list = (inventoryList.list and inventoryList.list.GetAllVisibleControls) and inventoryList.list or inventoryList
    local visibleControls = list.GetAllVisibleControls and list:GetAllVisibleControls()
    if not visibleControls then return end
    for control in pairs(visibleControls) do
        local dataIndex = control.dataIndex
        local data = (control.dataEntry and control.dataEntry.data) or (dataIndex and list.dataList and list.dataList[dataIndex])
        if data then SharedGamepadEntry_OnSetup_After(control, data) end
    end
end

local function RefreshVisibleInventoryControls()
    zo_callLater(function()
        if GAMEPAD_INVENTORY then
            RedecorateInventoryList(GAMEPAD_INVENTORY.itemList)
        end
        if GAMEPAD_BANKING then
            RedecorateInventoryList(GAMEPAD_BANKING.withdrawList)
            RedecorateInventoryList(GAMEPAD_BANKING.depositList)
        end
    end, 0)
end

_G.GamePadHelper_RefreshTreasureColors = RefreshVisibleInventoryControls

EVENT_MANAGER:RegisterForEvent("GPH_CC_QuestAdded",    EVENT_QUEST_ADDED,    RefreshVisibleInventoryControls)
EVENT_MANAGER:RegisterForEvent("GPH_CC_QuestRemoved",  EVENT_QUEST_REMOVED,  RefreshVisibleInventoryControls)
EVENT_MANAGER:RegisterForEvent("GPH_CC_QuestAdvanced", EVENT_QUEST_ADVANCED, RefreshVisibleInventoryControls)
