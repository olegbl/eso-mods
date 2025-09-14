local ADDON_NAME = "GamePadHelper"
local ADDON_VERSION = 1.03

-- Ensure ESO API compatibility
if GetAPIVersion() < 101047 then
    d("[" .. ADDON_NAME .. "] ESO API version too old. Requires API 101047 or higher.")
    return
end