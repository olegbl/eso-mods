local ADDON_NAME = "LibMultiIcon"
local ADDON_VERSION = 1.01

LibMultiIcon = {}

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

local function RemoveIcon(self, iconTexture)
  if self.iconTextures then
    local previousIconTextures = self.iconTextures
    self.iconTextures = {}
    for _, texture in ipairs(previousIconTextures) do
      if texture ~= iconTexture then
        table.insert(self.iconTextures, texture)
      end
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
  self.RemoveIcon = RemoveIcon
  self.SetIconColor = SetIconColor
  self.RemoveIconColor = RemoveIconColor
end

ZO_PostHook("ZO_MultiIcon_Initialize", MultiIcon_Initialize_After)
