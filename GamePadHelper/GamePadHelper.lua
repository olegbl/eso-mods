local ADDON_NAME = "GamePadHelper"
local ANNOUNCE_VERSION = 10617
local ANNOUNCE_VERSION_STRING = "1.06.17"
local GPH_NOTIFICATION_TYPE_WHATS_NEW = "GPH_WHATS_NEW"

-- Make ADDON_NAME globally accessible for submodules
_G["ADDON_NAME"] = ADDON_NAME

-- Ensure ESO API compatibility
if GetAPIVersion() < 101049 then
    d(zo_strformat(GetString(SI_GPH_API_TOO_OLD), ADDON_NAME, "101049"))
    return
end

local function IsConsole()
    return IsConsoleUI and IsConsoleUI() or false
end
_G["GamePadHelper_IsConsole"] = IsConsole

-- Account-wide saved variables (shared bookmark pool + what's new state)
local defaults = {
    mapSearchBookmarksAll = {},
    lastAnnouncedVersion = 0,
}
_G["GamePadHelper_Defaults"] = defaults

-- Per-character saved variables (all settings)
local charDefaults = {
    fishingEnabled = true,
    fishingAlternativeBaits = true,
    autoRepairEnabled = true,
    autoChargeEnabled = true,
    autoChargeThreshold = 25,
    antiquariansEyeEnabled = true,
    dungeonFinderEnabled = true,
    teleporterEnabled = true,
    mapSearchEnabled = true,
    mapSearchMapPin = true,
    mapSearchGroupByLocation = false,
    mapSearchSetDestination = true,
    mapSearchNarratePostTeleport = true,
    mapSearchBookmarksAccountWide = false,
    mapSearchAutoFocusSearch = false,
    mapSearchOpenOnSearch = false,
    lootOffsetEnabled = true,
    lootOffset = 350,
    showLowLevelRecipes = false,
    tooltipTraitEnabled = true,
    tooltipCovetousCountessEnabled = true,
    tooltipCrowEnabled = true,
    tooltipPriceEnabled = true,
    gearComparisonEnabled = true,
    inventoryTraitEnabled = true,
    inventoryTraitDeconstructionLegendEnabled = true,
    inventoryTraitDeconstructionLegendVisible = true,
    inventoryCovetousCountessEnabled = true,
    inventoryCrowEnabled = true,
    overviewEnabled = true,
    overviewQuestEnabled = true,
    overviewHorseEnabled = true,
    overviewDailyWritEnabled = true,
    overviewHideCompletedDailyWritEnabled = true,
    overviewResearchEnabled = true,
    overviewCompanionEnabled = true,
    overviewLocalTimeEnabled = true,
    overviewServerTimeEnabled = true,
    tooltipPoisonEnabled = true,
    tooltipFontEnabled = true,
    tooltipEnchantmentEnabled = true,
    cyrodiilKeepSearchEnabled = true,
}
_G["GamePadHelper_CharDefaults"] = charDefaults

local savedVars
local charVars

local function ShouldShowWhatsNew()
    return savedVars ~= nil and (savedVars.lastAnnouncedVersion or 0) < ANNOUNCE_VERSION
end

local function DismissWhatsNew()
    if savedVars then
        savedVars.lastAnnouncedVersion = ANNOUNCE_VERSION
    end
end

local function InstallWhatsNewNotificationProvider()
    if not GAMEPAD_NOTIFICATIONS or not GAMEPAD_NOTIFICATIONS.providers then
        return false
    end

    if not GAMEPAD_NOTIFICATIONS.gphWhatsNewHeaderWrapped then
        GAMEPAD_NOTIFICATIONS.gphWhatsNewHeaderWrapped = true
        local originalAddDataEntry = GAMEPAD_NOTIFICATIONS.AddDataEntry
        GAMEPAD_NOTIFICATIONS.AddDataEntry = function(self, dataType, data, isHeader)
            if data and data.customHeaderText then
                local icon = data.customIcon or ZO_GAMEPAD_NOTIFICATION_ICONS[data.notificationType]
                if type(icon) == "function" then
                    icon = icon(data)
                end

                local entryData = ZO_GamepadEntryData:New(data.shortDisplayText, icon)
                entryData.data = data
                entryData:SetIconTintOnSelection(true)
                entryData:SetIconDisabledTintOnSelection(true)

                if isHeader then
                    entryData:SetHeader(data.customHeaderText)
                    self.list:AddEntryWithHeader(ZO_NOTIFICATION_TYPE_TO_GAMEPAD_TEMPLATE[dataType], entryData)
                else
                    self.list:AddEntry(ZO_NOTIFICATION_TYPE_TO_GAMEPAD_TEMPLATE[dataType], entryData)
                end
                return
            end

            return originalAddDataEntry(self, dataType, data, isHeader)
        end
    end

    for _, provider in ipairs(GAMEPAD_NOTIFICATIONS.providers) do
        if provider.isGamePadHelperWhatsNewProvider then
            return true
        end
    end

    local WhatsNewProvider = ZO_NotificationProvider:Subclass()

    function WhatsNewProvider:BuildNotificationList()
        ZO_ClearNumericallyIndexedTable(self.list)

        if not ShouldShowWhatsNew() then
            return
        end

        table.insert(self.list, {
            dataType = NOTIFICATIONS_ALERT_DATA,
            notificationType = GPH_NOTIFICATION_TYPE_WHATS_NEW,
            shortDisplayText = ANNOUNCE_VERSION_STRING,
            customHeaderText = ADDON_NAME,
            customIcon = "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_new_64.dds",
            message = GetString(SI_GPH_WHATS_NEW_BODY),
            declineText = GetString(SI_NOTIFICATIONS_DELETE),
            secsSinceRequest = ZO_NormalizeSecondsSince(0),
        })
    end

    function WhatsNewProvider:Decline(data)
        DismissWhatsNew()
        self.notificationManager:RefreshNotificationList()
    end

    local provider = WhatsNewProvider:New(GAMEPAD_NOTIFICATIONS)
    provider.isGamePadHelperWhatsNewProvider = true
    table.insert(GAMEPAD_NOTIFICATIONS.providers, provider)
    GAMEPAD_NOTIFICATIONS:RefreshNotificationList()
    return true
end

_G["GamePadHelper_AnnounceVersion"] = ANNOUNCE_VERSION
_G["GamePadHelper_ShouldShowWhatsNew"] = ShouldShowWhatsNew
_G["GamePadHelper_DismissWhatsNew"] = DismissWhatsNew

local function OnAddonLoaded(event, addonName)
    if addonName ~= ADDON_NAME then return end
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    savedVars = ZO_SavedVars:NewAccountWide("GamePadHelperSavedVars", 1, nil, defaults)
    _G["GamePadHelper_SavedVars"] = savedVars
    charVars = ZO_SavedVars:New("GamePadHelperSavedVars", 1, nil, charDefaults)
    _G["GamePadHelper_CharSavedVars"] = charVars
    -- GamePadHelperMapData is accessed as a raw table in MapSearch.lua; never overwrite
    -- the global with a ZO_SavedVars proxy or ESO will serialize the proxy at logout.

    local function TryInstallProvider()
        if InstallWhatsNewNotificationProvider() then
            EVENT_MANAGER:UnregisterForEvent(ADDON_NAME .. "_PlayerActivated", EVENT_PLAYER_ACTIVATED)
        end
    end

    zo_callLater(TryInstallProvider, 0)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_PlayerActivated", EVENT_PLAYER_ACTIVATED, TryInstallProvider)
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
