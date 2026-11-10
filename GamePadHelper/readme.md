# GamePadHelper

**Version:** 1.06.19
**Authors:** olegbl, quelron  
**API:** 101051 (live)

A modular collection of quality-of-life improvements for Elder Scrolls Online, built for gamepad and console UI. Every feature can be toggled individually from `Options > GPH Settings`.

## What's New in 1.06.19

- Full native gamepad color pickers for five research states, active Countess treasures, active Bursar treasures, and useful inactive treasures. Saved per character and shared by inventory and tooltips, with separate trait/treasure reset buttons.
- Research magnifiers remain without extra bank/bag icon cycling. Duplicate counts show bank/storage first, then inventory.
- Larger trait legend icons and text, native equipped/lock markers, and fixes for duplicate-control errors when reopening the legend.
- Updated for live API 101051, confirmed from current SavedVariables. PTS API 101052 support is not declared.

## Installation

1. Extract into `Documents\Elder Scrolls Online\live\AddOns\GamePadHelper\`
2. Install the required libraries listed below.
3. If you previously installed **LibMultiIcon** for older builds, remove or disable it — GamePadHelper now includes its own private multi-icon helper.
4. Enable **GamePadHelper** in the AddOn Manager.

## Features

**Overview Panel** — adds a two-column root menu with quest details on the left and daily reminders (time, horse training, maps, crafting, companion) on the right.

**Map Search** — gamepad search tab on the world map. Search wayshrines, zones, houses, city services, daily quest givers, travel NPCs, and crafting set stations. The three Freerunner’s Post Favor boards in Skywatch, Ebonheart, and Aldcroft are included as daily quest givers. Includes fuzzy ranking, bookmarks, recent destinations, map panning, and ping markers. In Cyrodiil, shows accessible keeps with live group-member positions and the group leader highlighted. While dead, switches to revive mode and revalidates keeps, towns, outposts, and forward camps before respawning. Retreat items and abilities can also select an available destination directly from the gamepad list.

**Teleporter** — world map hotkey to teleport to a hovered zone, prioritising free travel via group, friend, or guild members. It waits for ESO's teleport response and tries the next player only after a confirmed unavailable-player error. A started teleport is monitored, while movement, cancellation, silence, and unrelated errors stop the retry chain. The wayshrine fallback appears only after all eligible players are confirmed unavailable and shows the current recall fee before confirmation. Unavailable houses and chat teleports use the same safe fallback handling.

**Tooltip Set Collection** — single-set reward containers, such as Imperial City coffers, show account collection progress and the equipment slots still missing. Multi-set containers are ignored. Toggleable under `Tooltips and UI`.

**Dungeon Finder** — replaces dungeon names in the finder list with their matching pledge quest names.

**Fishing** — controller vibration on bite, on-screen reel alert, automatic bait selection for all hole types, and fallback bait support.

**Auto Repair** — automatically repairs equipped items when opening a merchant that offers repair for gold.

**Auto Charge** — recharges equipped weapons in and out of combat using regular soul gems. Configurable charge threshold (default 25%).

**Antiquarian's Eye** — auto-slots and activates the collectible when stationary and out of combat; unslots it when activation would be blocked.

**Provisioning Filter** — adds a filter to hide recipes below CP160.

**Gear Comparison** — shows currently equipped and new item stat panels side by side.

**Loot Offset** — moves the loot history panel upward to avoid chat overlap.

## Tooltip Improvements

- **Tooltip Set Collection** — single-set reward containers show account collection progress and missing equipment slots; multi-set containers are excluded.
- **Tooltip Price** — cleaner price display with market data when a supported source is installed.
- **Tooltip Enchantment** — reformatted enchantment lines.
- **Tooltip Poison** — reformatted applied poison lines.
- **Tooltip Trait** — improved trait visibility using the same color coding as Inventory Trait.
- **Tooltip Font** — cleaner font for gamepad item tooltips.

## Inventory Features

**Inventory Countess and Bursar** — adds a quest icon to relevant treasures. Under **Treasure Colors**, freely choose separate colors for active Countess quests, active Bursar groups, and useful inactive treasures. Defaults remain green for active and white for inactive. Colors are saved per character and shared with tooltips and settings legends; **Reset Treasure Colors** resets only these colors. If both quests are active for one item and their chosen colors differ, the quest icon alternates between those colors. Stolen items retain the native stolen icon in the cycle.

**Inventory Trait** — shows trait research indicators in inventory, bank, and deconstruction.
- Equipped, only-copy, inventory-duplicate, bank/storage-duplicate, and locked states each have their own color.
- Choose any color for each state with ESO's full color picker under **Trait Colors**. Colors are saved per character and shared by inventory, bank, deconstruction, tooltips, and the legend.
- The research magnifier is retained; no extra bank/bag icons are added to its cycle. When both locations contain copies, it alternates between their colors.
- **Reset Trait Colors** restores the original colors without changing other settings.

Duplicate counts appear below the research icon: bank/storage first, inventory second. Equipped and locked items do not show duplicate counts. Deconstruction screens include a right-side legend with the selected colors, sample counts, native equipped/lock markers, and ornate/intricate icons.

## Required Libraries

- **LibCovetousCountess** — Countess and Bursar treasure-quest data.
- **LibItemLinkDecoder** — item link decoding for Tooltip Enchantment.
- **LibTraitResearch** — trait research data for Inventory Trait and Tooltip Trait.

## Optional Integrations

- **TamrielTradeCentre** — PC market price source for Tooltip Price.
- **TSCPriceDataAPIXBNA / PSNA / XBEU / PSEU** — console market price data via Tamriel Savings Co Price Fetcher (https://tamrielsavings.com/price-fetcher).
