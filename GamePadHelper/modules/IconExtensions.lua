local MultiIcon = {}

local function NormalizeTexture(texture)
    if type(texture) == "string" then
        return texture
    end
    return ""
end

local function SetTexture(self, texture, tint)
    texture = NormalizeTexture(texture)
    self.activeTexture = texture ~= "" and texture or nil
    self.SetTextureWithoutColor(self, texture)
    if tint then
        self:SetColor(tint:UnpackRGBA())
    end
end

local function ClearIcons(self)
    -- Explicitly unregister from MULTI_ICON_TIMER before clearing iconData.
    -- self:Hide() only fires OnHide when transitioning visible→hidden; if the control
    -- is already hidden (e.g. parent was hidden), OnHide won't fire and the stale
    -- timer entry would later crash on empty iconData (cycle % 0 = NaN).
    if self.iconData and #self.iconData > 1 then
        ZO_MultiIcon_OnHide(self)
    end
    self:Hide()
    self.activeTexture = nil

    if self.iconData ~= nil then
        ZO_ClearNumericallyIndexedTable(self.iconData)
    end

    self.SetTextureWithoutColor(self, "")
end

local function RemoveIcon(self, iconTexture)
    -- Unregister from MULTI_ICON_TIMER BEFORE modifying iconData.
    -- ZO_MultiIcon_OnHide's eligibility check reads #iconData, so it must be called
    -- while the old count is still intact. Without this, removing all icons that share
    -- the same texture (e.g. two duplicate-research icons) drops count to 0 while the
    -- control is still in the timer, causing cycle % 0 = NaN in SetupMultiIconTexture.
    if self.iconData and #self.iconData > 1 then
        ZO_MultiIcon_OnHide(self)
    end

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

    local newCount = self.iconData and #self.iconData or 0

    if newCount > 1 and not self:IsHidden() then
        ZO_MultiIcon_OnShow(self)  -- re-register with timer for the updated icon set
    elseif removedActiveTexture or newCount == 0 then
        local nextIconData = self.iconData and self.iconData[1]
        local nextTexture = NormalizeTexture(nextIconData and nextIconData.iconTexture)
        if nextTexture ~= "" then
            self:SetTexture(nextTexture, nextIconData.iconTint)
        else
            self.activeTexture = nil
            self.SetTextureWithoutColor(self, "")
            self:Hide()
        end
    end
end

function MultiIcon.Initialize(self)
    if not self then return nil end
    if self.gphMultiIconInitialized then return self end

    if not self.HasIcon or not self.AddIcon then
        ZO_MultiIcon_Initialize(self)
    end

    if self.SetTexture ~= SetTexture then
        self.SetTextureWithoutColor = self.SetTexture
        self.SetTexture = SetTexture
    end

    self.ClearIcons = ClearIcons
    self.RemoveIcon = RemoveIcon
    self.gphMultiIconInitialized = true
    return self
end

_G["GamePadHelper_IconExtensions"] = MultiIcon
