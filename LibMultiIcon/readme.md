# LibMultiIcon

[https://github.com/olegbl/eso-mods/tree/main/LibMultiIcon](https://github.com/olegbl/eso-mods/tree/main/LibMultiIcon)

> ⚠ **This library is no longer actively developed. It will not be updated beyond API 101049.**

## Description

Adds additional methods to instances of ZO_MultiIcon to allow different icons to have different colors instead of sharing a single color.

## Changes in 1.03

- Updated icon removal to work with current ESO `ZO_MultiIcon` internals (`iconData`).
- Removing the currently displayed icon now immediately switches to the next remaining icon.
- Clearing icons now also resets the active texture so reused controls do not keep stale icons.

## API

```
-- multiIcon is instance of ZO_MultiIcon
multiIcon:SetTexture(texture) -- sets the current texture on the multiIcon
multiIcon:SetIconColor(texture, r, g, b, a) -- sets a custom color for the given texture
multiIcon:RemoveIconColor(texture) -- removes custom color from the given texture
multiIcon:RemoveIcon(texture) -- removes the given icon from list of icons
multiIcon:SetTextureWithoutColor(texture) -- the same as vanilla multiIcon:SetTexture(texture)

-- example
local multiIcon = control:GetNamedChild("TestMultiIcon")
if not multiIcon:HasIcon(subIcon) then
  -- animation will not kick in if MultiIcon is already shown when second icon is added
  multiIcon:Hide()
  multiIcon:AddIcon(subIcon)
  multiIcon:Show()
end
multiIcon:SetIconColor(subIcon, COLOR_OF_SUB_ICON:UnpackRGBA())
```

## Support

This addon is provided as is, without warranty or support of any kind, express or implied.
