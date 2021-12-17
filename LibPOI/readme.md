# LibPOI

[https://github.com/olegbl/eso-mods/tree/main/LibPOI](https://github.com/olegbl/eso-mods/tree/main/LibPOI)

## Description

Given a zoneIndex and a poiIndex, can convert a POI map pin into a category name, a description and a completion status. The description additionally provides information about Mundus Stone and Crafting Station POIs.

## API

```
local poiCategories = LibPOI:GetPOICategories()
local poiCategory = LibPOI:GetPOICategory(zoneIndex, poiIndex)
local isComplete = LibPOI:IsComplete(zoneIndex, poiIndex)
local description = LibPOI:GetDescription(zoneIndex, poiIndex)

poiCategory.id
poiCategory.categoryName
poiCategory.completeIcons[1]
poiCategory.incompleteIcons[1]
```

## Support

This addon is provided as is, without warranty or support of any kind, express or implied.