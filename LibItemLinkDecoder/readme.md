# LibItemLinkDecoder

[https://github.com/olegbl/eso-mods/tree/main/LibItemLinkDecoder](https://github.com/olegbl/eso-mods/tree/main/LibItemLinkDecoder)

## Description

Given an item link, decodes it and converts it into an object that allows easy manipulation of various item link properties.

## API

```
local decodedItemLink = LibItemLinkDecoder:Decode(itemLink)

decodedItemLink[1]
decodedItemLink[2]
...

decodedItemLink.linkType
decodedItemLink.linkStyle
decodedItemLink.quality
decodedItemLink.level
decodedItemLink.championLevel
decodedItemLink.enchantSubType
decodedItemLink.enchantQuality
decodedItemLink.enchantLevel
decodedItemLink.enchantChampionLevel

decodedItemLink:SetIndex(1, "value")
decodedItemLink:SetValue("level", 50)
local copiedDecodedItemLink = decodedItemLink:Clone()
local itemLink = decodedItemLink:Encode()
```

## Support

This addon is provided as is, without warranty or support of any kind, express or implied.