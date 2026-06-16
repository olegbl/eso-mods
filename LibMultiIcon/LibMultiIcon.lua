local ADDON_NAME = "LibMultiIcon"
local ADDON_VERSION = 1.04

-- Ensure ESO API compatibility
if GetAPIVersion() >= 101049 then
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_Deprecated", EVENT_PLAYER_ACTIVATED, function()
        EVENT_MANAGER:UnregisterForEvent(ADDON_NAME .. "_Deprecated", EVENT_PLAYER_ACTIVATED)
        CHAT_SYSTEM:AddMessage("[LibMultiIcon] This library is deprecated and must not be enabled anymore! Please disable/delete it from your addons.")
    end)
    return
end

LibMultiIcon = {}

-- ZO_MultiIcon's animation timer calls SetTexture then SetColor(tint) each cycle.
-- We hook SetColor so the tint passed by ZO_MultiIcon cannot overwrite stored icon colors.
local function SetColor(self, r, g, b, a)
  if self.iconColors ~= nil and self.activeTexture ~= nil then
    local color = self.iconColors[self.activeTexture]
    if color ~= nil then
      self.SetColorWithoutIconColor(self, color.r, color.g, color.b, color.a)
      return
    end
  end
  self.SetColorWithoutIconColor(self, r, g, b, a)
end

local function SetTexture(self, texture)
  self.activeTexture = texture
  self.SetTextureWithoutColor(self, texture)
  if self.iconColors ~= nil then
    local color = self.iconColors[texture]
    if color ~= nil then
      self:SetColor(color.r, color.g, color.b, color.a)
    else
      -- TODO: how does this interact with stolen items?
      self:SetColor(255, 255, 255, 255)
    end
  end
end

local function ClearIcons(self)
  self:Hide()
  self.activeTexture = nil
  if self.iconData ~= nil then
    ZO_ClearNumericallyIndexedTable(self.iconData)
  end
  self.SetTextureWithoutColor(self, "")
end

local function RemoveIcon(self, iconTexture)
  local removedActiveTexture = self.activeTexture == iconTexture
  if self.iconData then
    local previousIconData = self.iconData
    self.iconData = {}
    for _, iconData in ipairs(previousIconData) do
      if iconData.iconTexture ~= iconTexture then
        table.insert(self.iconData, iconData)
      end
    end
  end

  if removedActiveTexture then
    local nextIconData = self.iconData and self.iconData[1] or nil
    local nextTexture = nextIconData and nextIconData.iconTexture or nil
    self.activeTexture = nextTexture
    if nextTexture ~= nil then
      self:SetTexture(nextTexture)
      if nextIconData.iconTint ~= nil then
        self:SetColor(nextIconData.iconTint:UnpackRGBA())
      else
        self:SetColor(1, 1, 1, 1)
      end
    else
      self:SetTextureWithoutColor(self, "")
    end
  end
end

local function SetIconColor(self, iconTexture, r, g, b, a)
  if not self.iconColors then self.iconColors = {} end
  self.iconColors[iconTexture] = {r = r, g = g, b = b, a = a}

  if iconTexture == self.activeTexture then
    self:SetColor(r, g, b, a)
  end
end

local function RemoveIconColor(self, iconTexture)
  if not self.iconColors then self.iconColors = {} end
  self.iconColors[iconTexture] = nil
end

local function MultiIcon_Initialize_After(self)
  -- if initialize is somehow called more than once,
  -- we do not want to put outselves into infinite recursion
  if self.SetTexture ~= SetTexture then
    self.SetTextureWithoutColor = self.SetTexture
    self.SetTexture = SetTexture
  end
  if self.SetColor ~= SetColor then
    self.SetColorWithoutIconColor = self.SetColor
    self.SetColor = SetColor
  end
  self.ClearIcons = ClearIcons
  self.RemoveIcon = RemoveIcon
  self.SetIconColor = SetIconColor
  self.RemoveIconColor = RemoveIconColor
end

ZO_PostHook("ZO_MultiIcon_Initialize", MultiIcon_Initialize_After)
