# LibCovetousCountess

[https://github.com/olegbl/eso-mods/tree/main/LibCovetousCountess](https://github.com/olegbl/eso-mods/tree/main/LibCovetousCountess)

## Description

Given an item link (of a treasure), determines if the item is useful for the covetous countess thieves guild quest.

## API

```
local isUsefulForActiveQuest, isUsefulForAnyQuest = LibCovetousCountess:IsItemUseful(itemLink)

LibCovetousCountess:UpdateQuestInfo() -- refreshes current data, does not generally need to be called manually
```

## Support

This addon is provided as is, without warranty or support of any kind, express or implied.