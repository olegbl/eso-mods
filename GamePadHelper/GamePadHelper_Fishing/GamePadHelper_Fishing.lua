local ADDON_NAME = "GamePadHelper_Fishing"
local ADDON_VERSION = 1.00

local cnt0 = 0

-- Bait constants from FishermansFriend
local BAIT_LAKE_GUTS = 2
local BAIT_LAKE_GUTS_ITEMID = 42870
local BAIT_LAKE_MINNOW = 8
local BAIT_LAKE_MINNOW_ITEMID = 42876

local BAIT_FOUL_CRAWLERS = 3
local BAIT_FOUL_CRAWLERS_ITEMID = 42871
local BAIT_FOUL_ROE = 9
local BAIT_FOUL_ROE_ITEMID = 42873

local BAIT_RIVER_INSECT = 4
local BAIT_RIVER_INSECT_ITEMID = 42872
local BAIT_RIVER_SHAD = 6
local BAIT_RIVER_SHAD_ITEMID = 42874

local BAIT_SALTWATER_WORMS = 5
local BAIT_SALTWATER_WORMS_ITEMID = 42869
local BAIT_SALTWATER_CHUB = 7
local BAIT_SALTWATER_CHUB_ITEMID = 42875

local setBait = true

-- Get item quantity function from FishermansFriend
local function GetItemQuantity(itemId)
    local icon, qnt = GetItemInfo(BAG_VIRTUAL, itemId)
    local icon, qnt2 = GetItemInfo(BAG_BACKPACK, itemId)
    if HasCraftBagAccess() then return (qnt + qnt2) else return qnt2 end
end
-- Bait selection logic from FishermansFriend
local function SelectFishingBait(interactableName)
    local savedVars = _G["GamePadHelper_SavedVars"]
    if not savedVars or not savedVars.fishingEnabled or not savedVars.fishingAlternativeBaits then
        return
    end
    if interactableName == "Lake Fishing Hole" then
        local regularBaitQuantity = GetItemQuantity(BAIT_LAKE_GUTS_ITEMID)
        local alternativeBaitQuantity = GetItemQuantity(BAIT_LAKE_MINNOW_ITEMID)

        if savedVars.fishingAlternativeBaits then
            if alternativeBaitQuantity > 0 then
                SetFishingLure(BAIT_LAKE_MINNOW)
            else
                SetFishingLure(BAIT_LAKE_GUTS)
            end
        else
            if regularBaitQuantity > 0 then
                SetFishingLure(BAIT_LAKE_GUTS)
            else
                SetFishingLure(BAIT_LAKE_MINNOW)
            end
        end

        setBait = false
    elseif interactableName == "Saltwater Fishing Hole" then
        local regularBaitQuantity = GetItemQuantity(BAIT_SALTWATER_WORMS_ITEMID)
        local alternativeBaitQuantity = GetItemQuantity(BAIT_SALTWATER_CHUB_ITEMID)

        if savedVars.fishingAlternativeBaits then
            if alternativeBaitQuantity > 0 then
                SetFishingLure(BAIT_SALTWATER_CHUB)
            else
                SetFishingLure(BAIT_SALTWATER_WORMS)
            end
        else
            if regularBaitQuantity > 0 then
                SetFishingLure(BAIT_SALTWATER_WORMS)
            else
                SetFishingLure(BAIT_SALTWATER_CHUB)
            end
        end

        setBait = false
    elseif interactableName == "Foul Fishing Hole" then
        local regularBaitQuantity = GetItemQuantity(BAIT_FOUL_CRAWLERS_ITEMID)
        local alternativeBaitQuantity = GetItemQuantity(BAIT_FOUL_ROE_ITEMID)

        if savedVars.fishingAlternativeBaits then
            if alternativeBaitQuantity > 0 then
                SetFishingLure(BAIT_FOUL_ROE)
            else
                SetFishingLure(BAIT_FOUL_CRAWLERS)
            end
        else
            if regularBaitQuantity > 0 then
                SetFishingLure(BAIT_FOUL_CRAWLERS)
            else
                SetFishingLure(BAIT_FOUL_ROE)
            end
        end

        setBait = false
    elseif interactableName == "River Fishing Hole" then
        local regularBaitQuantity = GetItemQuantity(BAIT_RIVER_INSECT_ITEMID)
        local alternativeBaitQuantity = GetItemQuantity(BAIT_RIVER_SHAD_ITEMID)

        if savedVars.fishingAlternativeBaits then
            if alternativeBaitQuantity > 0 then
                SetFishingLure(BAIT_RIVER_SHAD)
            else
                SetFishingLure(BAIT_RIVER_INSECT)
            end
        else
            if regularBaitQuantity > 0 then
                SetFishingLure(BAIT_RIVER_INSECT)
            else
                SetFishingLure(BAIT_RIVER_SHAD)
            end
        end

        setBait = false
    end
end

local function startVibration2()
    SetGamepadVibration(3000, 0.99, 0.50, 1.00, 1.00, ADDON_NAME)
    EVENT_MANAGER:UnregisterForUpdate("startVibration2")
end

local function startVibration()
    SetGamepadVibration(180, 0.50, 0.90, 1.00, 1.00, ADDON_NAME)
    EVENT_MANAGER:RegisterForUpdate("startVibration2", 250, startVibration2)
end

local function onSlotUpdate(event, bagId, slotIndex, isNew)
    -- Check if fishing module is enabled
    local savedVars = _G["GamePadHelper_SavedVars"]
    if not savedVars or not savedVars.fishingEnabled then
        return
    end

    local lure = GetFishingLure()
    local cnt = 0
    if lure then
        cnt = select(3, GetFishingLureInfo(lure))
    else
        cnt = 0
    end
    if (not isNew and (GetItemType(bagId, slotIndex) == ITEMTYPE_LURE) and (cnt0 - cnt == 1)) then
        startVibration()
        -- Show reel alert
        local action = GetGameCameraInteractableActionInfo()
        if action == GetString(SI_GAMECAMERAACTIONTYPE17) then
            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_MAJOR_TEXT, SOUNDS.BOOK_ACQUIRED)
            messageParams:SetText("|t32:32:/esoui/art/tutorial/gamepad/achievement_categoryicon_fishing.dds|t Reel in!")
            CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
        end
    else
        SetGamepadVibration(0, 0, 0, 0, 0, ADDON_NAME)
    end
    cnt0 = cnt
end

local function onLureCleared(event)
    local lure = GetFishingLure()
    if lure then
        cnt0 = select(3, GetFishingLureInfo(lure))
    end

    -- Set global flag to indicate module is loaded
    _G["gamepadhelper_Fishing_Loaded"] = true

end
local function onLureSet(event, lure)
    if lure then
        cnt0 = select(3, GetFishingLureInfo(lure))
    end
end

local function OnAddonLoaded(event, addonName)
    if addonName ~= ADDON_NAME then return end
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, onSlotUpdate)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_FISHING_LURE_CLEARED, onLureCleared)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_FISHING_LURE_SET, onLureSet)

    -- Hook into reticle interaction for automatic bait selection
    ZO_PreHook(ZO_Reticle, "TryHandlingInteraction", function(interactionPossible, currentFrameTimeSeconds)
        -- Check if fishing module is enabled
        local savedVars = _G["GamePadHelper_SavedVars"]
        if not savedVars or not savedVars.fishingEnabled then
            return
        end

        if interactionPossible then
            local action, interactableName, interactionBlocked, isOwned, additionalInteractInfo, context, contextLink, isCriminalInteract = GetGameCameraInteractableActionInfo()
            if additionalInteractInfo == ADDITIONAL_INTERACT_INFO_FISHING_NODE and setBait then
                SelectFishingBait(interactableName)
            end
        else
            setBait = true -- Reset setBait when not interacting
        end
    end)

    local lure = GetFishingLure()
    if lure then
        cnt0 = select(3, GetFishingLureInfo(lure))
    end

end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)