# LibCovetousCountess

[https://github.com/olegbl/eso-mods/tree/main/LibCovetousCountess](https://github.com/olegbl/eso-mods/tree/main/LibCovetousCountess)

Authors: olegbl, quelron

## Description

Given a treasure item link, determines whether the item is useful for The Covetous Countess quest and whether it belongs to the Bursar of Tributes / Crow tribute categories.

## API

```
local isUsefulForActiveQuest, isUsefulForAnyQuest, source = LibCovetousCountess:IsItemUseful(itemLink)
-- source = "countess", "crow", "both", or nil

-- Optional detailed calls if your addon wants separate handling:
local isUsefulForActiveCountess, isUsefulForAnyCountess = LibCovetousCountess:IsItemUsefulForCountess(itemLink)
local isUsefulForActiveCrowGroup, isUsefulForAnyCrowGroup = LibCovetousCountess:IsItemUsefulForCrow(itemLink)
```

## Notes

- Public API is intentionally small:
  - `IsItemUseful(itemLink)` is the main unified call.
  - `IsItemUsefulForCountess(itemLink)` and `IsItemUsefulForCrow(itemLink)` are available when an addon wants separate Countess/Crow presentation.
- Internal quest tracking updates automatically from quest events. Consumers do not need to refresh anything manually.
- Countess treasure matching is language-aware and based on exact localized treasure-type tables.
- Active Countess quest detection uses journal quest ID `5584`, then reads the active step text to determine which of the 5 Countess treasure groups is current.
- Bursar of Tributes / Crow treasure matching is kept separate so addons can use different icons or behaviors for those categories later.
- Active Bursar of Tributes / Crow quest detection prefers exact journal quest IDs:
  - `6107` = `leisure`
  - `6106` = `tributes`
  - `6072` = `respect`
- If a quest ID is unavailable for some reason, Bursar / Crow falls back to step-text matching as a safety net.

## Changes In 1.03

- Exact localized Countess tables
- Separate Bursar / Crow tables
- Bursar / Crow active-group detection by journal quest ID
- Unified `IsItemUseful(itemLink)` source return
- Optional detailed Countess and Bursar / Crow helper calls

## Support

This addon is provided as is, without warranty or support of any kind, express or implied.
