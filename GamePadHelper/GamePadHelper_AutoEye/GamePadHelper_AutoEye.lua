-- GamePadHelper_AutoEye
-- Antiquarian's Eye automation (auto-use and slot management)

local addonName = "GamePadHelper_AutoEye"
_G["GamePadHelper_AutoEye_Loaded"] = true

local autoUse = true
local previousSlot, eyeSlot, backupSlot
local isDigging = false

local function FindEye()
    eyeSlot = 0
    for i = 1, 8 do
        if GetSlotItemLink(i, HOTBAR_CATEGORY_QUICKSLOT_WHEEL) == "|H0:collectible:8006|h|h" then
            eyeSlot = i
        end
    end
end

local function SlotEye()
    if eyeSlot ~= 0 and GetSlotItemLink(GetCurrentQuickslot(), HOTBAR_CATEGORY_QUICKSLOT_WHEEL) ~= "|H0:collectible:8006|h|h" then
        previousSlot = GetCurrentQuickslot()
        SetCurrentQuickslot(eyeSlot)
    end
end

local function UnslotEye()
    if GetSlotItemLink(GetCurrentQuickslot(), HOTBAR_CATEGORY_QUICKSLOT_WHEEL) == "|H0:collectible:8006|h|h" then
        SetCurrentQuickslot(previousSlot)
    end
end

local function MainLoop()
    if not _G["GamePadHelper_SavedVars"] or not _G["GamePadHelper_SavedVars"].antiquariansEyeEnabled then
        return -- Standby: do not auto-check or use
    end
    if not IsCollectibleBlocked(8006) then
        SlotEye()
        if not isDigging and autoUse and GetCollectibleCooldownAndDuration(8006) == 0 and not IsPlayerMoving() and not IsUnitInCombat("player") then
            UseCollectible(8006)
        end
    else
        UnslotEye()
    end
end

local function OnPlayerActivated()
    if GetMapContentType() ~= MAP_CONTENT_AVA and GetMapContentType() ~= MAP_CONTENT_BATTLEGROUND and GetMapContentType() ~= MAP_CONTENT_DUNGEON then
        EVENT_MANAGER:RegisterForUpdate(addonName.."TickUpdate", 1000, function(gameTimeMs) MainLoop() end)
    else
        EVENT_MANAGER:UnregisterForUpdate(addonName.."TickUpdate")
    end
end

local function UpdateSlots()
    FindEye()
    if GetCurrentQuickslot() ~= eyeSlot then
        previousSlot = GetCurrentQuickslot()
    end
end

local function OnHotbarUpdate()
    if eyeSlot ~= 0 then
        backupSlot = eyeSlot
    end
    UpdateSlots()
    if eyeSlot == previousSlot then
        previousSlot = backupSlot
    end
end

local function OnDiggingStart()
    isDigging = true
end

local function OnDiggingEnd(event, accept)
    isDigging = false
end

local function OnAddonLoaded(event, name)
    if name ~= addonName then return end
    EVENT_MANAGER:UnregisterForEvent(addonName, EVENT_ADD_ON_LOADED)
    EVENT_MANAGER:RegisterForEvent(addonName, EVENT_ACTIVE_QUICKSLOT_CHANGED, UpdateSlots)
    EVENT_MANAGER:RegisterForEvent(addonName, EVENT_HOTBAR_SLOT_UPDATED, OnHotbarUpdate)
    EVENT_MANAGER:RegisterForEvent(addonName, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    EVENT_MANAGER:RegisterForEvent(addonName, EVENT_ANTIQUITY_DIGGING_READY_TO_PLAY, OnDiggingStart)
    EVENT_MANAGER:RegisterForEvent(addonName, EVENT_ANTIQUITY_DIGGING_EXIT_RESPONSE, OnDiggingEnd)
    UpdateSlots()
end

EVENT_MANAGER:RegisterForEvent(addonName, EVENT_ADD_ON_LOADED, OnAddonLoaded)