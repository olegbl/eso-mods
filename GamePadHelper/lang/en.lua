-- en overrides for GamePadHelper strings.
-- All strings fall back to common.lua which is already in English.
local strings = {
}

for stringId, stringValue in pairs(strings) do
    SafeAddString(_G[stringId], stringValue, 1)
end
