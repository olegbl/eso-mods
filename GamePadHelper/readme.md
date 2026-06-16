# GamePadHelper

**Version:** 1.06.16  
**Authors:** olegbl, quelron  
**API:** 101050

GamePadHelper is a modular collection of quality-of-life improvements for Elder Scrolls Online, built specifically for gamepad and console UI.

Price data can use supported sources such as TamrielTradeCentre and Tamriel Savings Co Price Fetcher / TSC data packages when available.

## What's New in 1.06.16

- **Cyrodiil Map Search** - Map Search now shows accessible keeps, outposts, and border keeps when the Cyrodiil map is open. Group member counts appear on each keep entry and the keep nearest to your group leader is listed first with a green indicator. Open Map Search at a Transitus Shrine to select and travel to a keep directly. Toggle via Settings → GPH Settings → Map Search → Cyrodiil Keep Search.
- **Group leader pin** - the group leader pin on the Cyrodiil map is enlarged to 64×64 for better visibility. A navigation marker is automatically placed at the leader's last known position when Map Search opens.

## What's New in 1.06.15

- **Reset timer** - daily reset countdown now shows HH:MM instead of HH:MM:SS.
- **Auto Charge fix** - weapon charge threshold was referencing a stale variable; charging now triggers correctly at the configured threshold.
- **Countess and Bursar dual active** - when both quests are active for the same item, the inventory icon now flashes between green and blue.

## What's New in 1.06.14

- **API 101050 update** - updated for the latest ESO patch.
- **Per-character settings** - GamePadHelper settings and Map Search state now save per character, while the shared bookmark pool remains available when enabled.
- **Trait indicator refresh** - equipped researchable items now use a blue state, non-equipped items keep green/yellow/red duplicate logic, and tooltip trait explanations were refreshed to match.
- **Deconstruction trait legend** - deconstruction screens now show a right-side icon legend for research, duplicate counts, ornate, and intricate markers.
- **Countess and Bursar split** - The Covetous Countess and Bursar of Tributes now have separate inventory and tooltip toggles.
- **Shared quest icon styling** - Countess and Bursar now use the same quest icon with unified green for any active quest item and white for useful-but-inactive items. Stolen treasure items cycle between the stolen icon and the quest icon.
- **Quest-aware treasure checks** - Countess and Bursar treasure detection now follows the updated LibCovetousCountess logic and active quest detection.

## Installation

1. Extract the addon into:

   `Documents\Elder Scrolls Online\live\AddOns\GamePadHelper\`

2. Install the required libraries listed below.
3. IMPORTANT: If you previously installed **LibMultiIcon** for older GamePadHelper builds, remove or disable it. GamePadHelper now includes its own private multi-icon helper.
4. Enable **GamePadHelper** in the AddOn Manager.

## Main Features

- **Overview Panel** - adds a two-column root menu overview with quest details on the left and daily reminders on the right.
- **Map Search** - adds a gamepad search tab for wayshrines, zones, houses, city services, daily quest givers, travel NPCs, and Cyrodiil keeps (when in Cyrodiil).
- **Teleporter** - teleports to hovered zones from the world map and adds chat jump options.
- **Dungeon Finder** - shows pledge quest names in the finder list.
- **Fishing** - vibration, reel alert, automatic bait selection, and fallback bait support.
- **Auto Repair** - repairs equipped gear at merchants.
- **Auto Charge** - recharges weapons in and out of combat using regular soul gems.
- **Antiquarian's Eye** - auto-slots and uses the collectible when appropriate.
- **Provisioning Filter** - hides low-level recipes below CP160.
- **Gear Comparison** - shows side-by-side item comparison panels.
- **Loot Offset** - moves the loot history panel upward to avoid chat overlap.

## Tooltip Features

- **Tooltip Price** - cleaner price display with supported market data.
- **Tooltip Enchantment** - cleaner enchantment formatting.
- **Tooltip Poison** - cleaner poison formatting.
- **Tooltip Trait** - improved trait visibility in tooltips.
- **Tooltip Font** - cleaner tooltip font for gamepad.

## Inventory Features

### Inventory Countess and Bursar

Highlights treasures relevant to **The Covetous Countess** and **Bursar of Tributes** quests.

- **Green icon** - useful for the current active Countess or Bursar quest.
- **White icon** - useful for some quest, but neither is currently active.
- Stolen treasure items cycle between the stolen icon and the quest icon.

### Inventory Trait

Shows trait research indicators in inventory, bank, and deconstruction.

- **Blue** - equipped item with a researchable trait.
- **Green** - only accessible copy with this trait.
- **Yellow** - have duplicate in inventory.
- **Red** - have duplicate in bank.

Duplicate counts are shown under non-equipped items where applicable. Locked items are excluded from duplicate counting.
Deconstruction screens also show a right-side legend panel that explains research colors, sample duplicate counts, and ornate/intricate markers.

## Required Libraries

- **LibCovetousCountess** - Countess and Bursar treasure-quest data.
- **LibItemLinkDecoder** - raw item link decoding for Tooltip Enchantment.
- **LibTraitResearch** - trait research data for Inventory Trait and Tooltip Trait.

## Optional Integrations

- **TamrielTradeCentre** - optional PC market price source.
- **TSCPriceDataAPIXBNA**
- **TSCPriceDataAPIPSNA**
- **TSCPriceDataAPIXBEU**
- **TSCPriceDataAPIPSEU**

Console price data is provided by Tamriel Savings Co Price Fetcher / TSC packages when installed:

https://tamrielsavings.com/price-fetcher

## Notes

- Every feature can be enabled or disabled individually from `Options > GPH Settings`.
- Optional integrations improve specific features but are not required for GamePadHelper to load.
- This addon is provided as-is. Please report issues on the GamePadHelper project page.
