# LibTraitResearch

[https://github.com/olegbl/eso-mods/tree/main/LibTraitResearch](https://github.com/olegbl/eso-mods/tree/main/LibTraitResearch)

## Description

Given an item link, exposes information about the researchability of a trait on that item, including information about other items with the same trait available in various bags that the character has access to. Does not consider other characters in account.

## API

```
local canBeResearched, colorOverall, duplicateRemoteItems, colorRemote, duplicateLocalItems, colorLocal = LibTraitResearch:GetItemLinkTraitResearchState(itemLink)

-- canBeResearched = if the item has a trait that can be researched
-- colorOverall = the color that should be used for the research icon
-- duplicateRemoteItems = how many other items with the same trait are available in a remote bag (e.g. the bank)
-- colorRemote = color that should be used for the remote count
-- duplicateLocalItems = how many other items with the same trait are available in a local bag (i.e. the inventory)
-- colorLocal = color that should be used for the local count

LibTraitResearch:Update() -- refreshes current data, does not generally need to be called manually
```

## Support

This addon is provided as is, without warranty or support of any kind, express or implied.