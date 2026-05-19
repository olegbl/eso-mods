-- AutoEye
-- Antiquarian's Eye automation (auto-use and slot management)

local ANTIQUARIANS_EYE_ID   = 8006
local ANTIQUARIANS_EYE_LINK = "|H0:collectible:8006|h|h"

local autoUse = true
local previousSlot, eyeSlot, backupSlot
local isDigging = false
local eyeIsActive = false

local function FindEye()
    eyeSlot = 0
    for i = 1, 8 do
        if GetSlotItemLink(i, HOTBAR_CATEGORY_QUICKSLOT_WHEEL) == ANTIQUARIANS_EYE_LINK then
            eyeSlot = i
        end
    end
end

local function AnnounceCenter(text)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT)
    messageParams:SetText(text)
    CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
end

local function SlotEye()
    if eyeSlot ~= 0 and GetSlotItemLink(GetCurrentQuickslot(), HOTBAR_CATEGORY_QUICKSLOT_WHEEL) ~= ANTIQUARIANS_EYE_LINK then
        previousSlot = GetCurrentQuickslot()
        SetCurrentQuickslot(eyeSlot)
        if not eyeIsActive then
            eyeIsActive = true
            AnnounceCenter(GetString(SI_GPH_AUTOEYE_EQUIPPED))
        end
    end
end

local function UnslotEye()
    if GetSlotItemLink(GetCurrentQuickslot(), HOTBAR_CATEGORY_QUICKSLOT_WHEEL) == ANTIQUARIANS_EYE_LINK then
        SetCurrentQuickslot(previousSlot)
        if eyeIsActive then
            eyeIsActive = false
            AnnounceCenter(GetString(SI_GPH_AUTOEYE_UNEQUIPPED))
        end
    end
end

local function MainLoop()
    if not _G["GamePadHelper_SavedVars"] or not _G["GamePadHelper_SavedVars"].antiquariansEyeEnabled then
        return
    end
    if not IsCollectibleBlocked(ANTIQUARIANS_EYE_ID) then
        SlotEye()
        local cooldown, duration = GetCollectibleCooldownAndDuration(ANTIQUARIANS_EYE_ID)
        if not isDigging and autoUse and cooldown == 0 and duration == 0 and not IsPlayerMoving() and not IsUnitInCombat("player") then
            UseCollectible(ANTIQUARIANS_EYE_ID)
        end
    else
        UnslotEye()
    end
end

local function OnPlayerActivated()
    if GetMapContentType() ~= MAP_CONTENT_AVA and GetMapContentType() ~= MAP_CONTENT_BATTLEGROUND and GetMapContentType() ~= MAP_CONTENT_DUNGEON then
        EVENT_MANAGER:RegisterForUpdate("GamePadHelperTickUpdate", 1000, function(gameTimeMs) MainLoop() end)
    else
        EVENT_MANAGER:UnregisterForUpdate("GamePadHelperTickUpdate")
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
    if name ~= "GamePadHelper" then return end
    EVENT_MANAGER:UnregisterForEvent("AutoEye", EVENT_ADD_ON_LOADED)

    EVENT_MANAGER:RegisterForEvent("AutoEye", EVENT_ACTIVE_QUICKSLOT_CHANGED, UpdateSlots)
    EVENT_MANAGER:RegisterForEvent("AutoEye", EVENT_HOTBAR_SLOT_UPDATED, OnHotbarUpdate)
    EVENT_MANAGER:RegisterForEvent("AutoEye", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    EVENT_MANAGER:RegisterForEvent("AutoEye", EVENT_PLAYER_DEACTIVATED, function()
        EVENT_MANAGER:UnregisterForUpdate("GamePadHelperTickUpdate")
    end)
    EVENT_MANAGER:RegisterForEvent("AutoEye", EVENT_ANTIQUITY_DIGGING_READY_TO_PLAY, OnDiggingStart)
    EVENT_MANAGER:RegisterForEvent("AutoEye", EVENT_ANTIQUITY_DIGGING_EXIT_RESPONSE, OnDiggingEnd)
    UpdateSlots()
end

EVENT_MANAGER:RegisterForEvent("AutoEye", EVENT_ADD_ON_LOADED, OnAddonLoaded)
