# GamePadHelper

**Version:** 1.06.12 · **Authors:** olegbl, quelron · **API:** 101049

A collection of UI improvements and quality-of-life enhancements for Elder Scrolls Online, designed only for gamepad and console UI. Every feature can be toggled individually from the in-game settings panel.

Price data provided by [**Tamriel Savings Co Price Fetcher**](https://tamrielsavings.com/price-fetcher) when TSC sources are available.

---

## What's New in 1.06.12

- **Overview tasks redesign** — the daily reminders panel is completely rebuilt. Each category (Time, Horse Training, Maps, Crafting, Companion) now renders as a titled section with a divider header and matching icon instead of a plain text block.
- **Horse training detail** — when training is available, the panel now shows individual riding skill progress (Speed, Carrying Capacity, Stamina) with icons and current/max values.
- **Maps section** — antiquity leads, treasure maps, and surveys each have inline item icons. Survey maps moved here from the old crafting counter.
- **Companion panel redesign** — now displays the companion's XP progress bar, rapport gradient bar, rapport level, and rapport description, in addition to the best daily activities list.
- **Quest panel toggle** — the quest left panel now has its own toggle, independent of the tasks panel. Show either, both, or neither.
- **Local time toggle** — the local clock can now be toggled on or off independently from server time.
- **Hide completed daily writs** — completed daily writ entries can now be hidden from the crafting section.
- **Quest panel visual update** — the quest title now uses a divider header with the tracked-quest icon. Section order updated: Hints first, then active tasks, optional steps, completed tasks.
- **Inventory Trait fix** — trait icons now appear more reliably during inventory navigation using a multi-pass refresh (50 / 200 / 500 ms).
- **Settings reorganized** — grouped into labeled sections: Automation, Fishing, Map Search, Overview, Tooltips and UI, Loot. Utility actions moved to the bottom.

---

## Table of Contents

- [Installation](#installation)
- [What's New in 1.06.12](#whats-new-in-10612)
- [Settings](#settings)
- [Features](#features)
  - [Fishing](#fishing)
  - [Auto Repair](#auto-repair)
  - [Auto Weapon Charge](#auto-weapon-charge)
  - [Antiquarian's Eye](#antiquarians-eye)
  - [Teleporter](#teleporter)
  - [Dungeon Finder](#dungeon-finder)
  - [Map Search](#map-search)
  - [Provisioning](#provisioning)
  - [Gear Comparison](#gear-comparison)
  - [Inventory Covetous Countess](#inventory-covetous-countess)
  - [Inventory Trait](#inventory-trait)
  - [Loot Offset](#loot-offset)
  - [Overview Panel](#overview-panel)
    - [Daily Crafting Writ Tracker](#daily-crafting-writ-tracker)
    - [Companion Rapport Dailies](#companion-rapport-dailies)
  - [Tooltip Enchantment](#tooltip-enchantment)
  - [Tooltip Font](#tooltip-font)
  - [Tooltip Poison](#tooltip-poison)
  - [Tooltip Price](#tooltip-price)
  - [Tooltip Trait](#tooltip-trait)
- [Dependencies](#dependencies)
- [Support](#support)

---

## Installation

1. Download and extract the archive into your AddOns folder:
   ```
   Documents\Elder Scrolls Online\live\AddOns\GamePadHelper\
   ```
2. Install all required dependencies listed in [Dependencies](#dependencies).
3. Launch ESO and enable **GamePadHelper** in the AddOn Manager.

---

## Settings

All features can be toggled without reloading the UI. Open the settings panel via:

- **Gamepad** — `Options → GPH Settings`

---

## Features

### Fishing

Enhances the fishing experience for gamepad users with three improvements:

- **Controller vibration** pulses when a fish bites.
- **"Reel in!" alert** appears on screen so you don't miss a catch.
- **Automatic bait selection** picks the correct bait for the current fishing hole type (foul, saltwater, lake, river). Falls back to alternative baits (Minnow/Guts, Chub/Worms) when the primary bait is unavailable.

---

### Auto Repair

Automatically repairs all equipped items when you open any merchant store, as long as repair is available and costs gold. No more forgetting to repair between combat sessions.

---

### Auto Weapon Charge

Automatically recharges equipped weapons (main hand, off hand, backup main, backup off) using the highest-level filled soul gem available when charge drops below a configurable threshold (default **25%**) after leaving combat. The threshold is adjustable from the settings panel in 5% increments.

---

### Antiquarian's Eye

Automatically slots and activates the **Antiquarian's Eye** collectible when you are not in combat and not moving, then unslots it when it would be blocked. Removes the need to manually manage the collectible slot while scrying.

---

### Teleporter

| Screenshot | Screenshot |
|---|---|
| ![Teleporter map hotkey](screenshots/Teleporter_1.png) | ![Teleporter chat menu](screenshots/Teleporter_2.png) |
| ![Teleporter in action](screenshots/Teleporter_3.png) | |

Two teleport improvements:

- **World Map hotkey** — while hovering a zone on the world map, a new hotkey lets you instantly teleport to that zone. Prioritizes free travel: jumps to a group member, friend, or guild member in the zone if one is available, otherwise falls back to the nearest discovered wayshrine.
- **Chat "Jump to Player"** — adds jump options to the chat context menu for friends, guild members, and group members.

---

### Dungeon Finder

![Dungeon Finder](screenshots/DungeonFinder.png)

Replaces dungeon names in the Dungeon Finder list with their corresponding **pledge quest names**, making it much easier to identify which dungeon completes your daily pledge without cross-referencing.

---

### Map Search

Adds a **GPH Search** tab to the Gamepad World Map info panel. Lets you search across wayshrines, zones, houses, and points of interest by name and instantly pan the map to the result.

**Features:**

- Controller-friendly tabs for **Search**, **Bookmarks**, **Recent**, **Houses**, and **Zones**.
- The Search tab starts empty until you type; saved and recent destinations live in their own tabs.
- **Recent destinations** keeps the latest map targets available from its own tab.
- **Zone details** can show quest, survey report, treasure map, and antiquity lead counts.
- **Wayshrine and trader POI details** show nearby trader counts and your guild names occupying those kiosks.
- **Crafting station details** show crafted set names, required trait counts, and full set bonuses in the right-side tooltip panel.
- **Special crafting locations** exposed as map-location service pins, such as Eyevea and The Earth Forge, are included when available.
- **City service pins** — searchable city-level services: guild traders, Mages/Fighters/Undaunted/Thieves Guild halls, banks, and other services. Teleports to the correct city wayshrine.
- **Daily quest givers** — key daily quest NPCs across all zones are searchable by name or quest category (Mages Guild daily, Fighters Guild daily, Undaunted, Thieves Guild, zone boss/delve dailies, and more).
- **Travel service NPCs** — ferry captains, caravan drivers, and silt strider operators are individual searchable entries showing their destination routes.

- Fuzzy search with ranked results — exact prefix matches score highest.
- Results grouped by category: **Wayshrines**, **Zones**, **Owned Houses**, **Unowned Houses**, and named POI types (Delve, Dungeon, World Boss, Crafting Station, Mundus Stone, etc.).
- **Bookmark** any location (per character) for quick access — bookmarks appear when the search bar is empty.
- **Bookmarks tab** keeps saved destinations separate from the Search tab.
- **Show on Map** pans the world map to the selected result and places a ping marker.
- **Teleport to Nearest Wayshrine** fast-travels to the closest discovered wayshrine in the same zone as the selected result (or directly to the wayshrine/house if it is one).
- **Tab memory** — reopening the map returns you to the GPH Search tab if that was the last tab you had open.
- **Teleport announcement** — after arriving at the destination, a small on-screen message confirms the location name and reminds you to check the map for the destination pin.
- Full **screen narration** support for gamepad accessibility — reads the name, category, ownership (houses), discovery/lock status, and crafted set details when available.

---

### Provisioning

Adds a filter to hide **low-level recipes (below CP160)** in the provisioning interface. Keeps the recipe list clean and focused on relevant recipes for end-game characters.

---

### Gear Comparison

![Gear Comparison](screenshots/GearComparison.png)

When toggling between a preview of your currently equipped item and a new item's stat changes, both panels are shown **side-by-side** simultaneously, making it easy to compare at a glance without toggling back and forth.

---

### Inventory Covetous Countess

![Inventory Covetous Countess](screenshots/InventoryCovetousCountess.png)

Adds a magnifying glass icon next to treasures in your inventory that are relevant to the **Covetous Countess** quest:

- **Green icon** — item is useful for your currently active Covetous Countess quest step.
- **White icon** — item is useful for the quest but not the current active step.

---

### Inventory Trait

| Screenshot | Screenshot | Screenshot |
|---|---|---|
| ![Inventory Trait 1](screenshots/InventoryTrait_1.png) | ![Inventory Trait 2](screenshots/InventoryTrait_2.png) | ![Inventory Trait 3](screenshots/InventoryTrait_3.png) |

Shows a magnifying glass icon next to items whose trait can be **researched by the current character**, with color coding to indicate duplicates:

| Icon | Meaning |
|---|---|
| 🟢 Green | Only copy with this trait you have access to — safe to research |
| 🟡 Yellow | Another copy with the same trait exists in your **inventory** |
| 🔴 Red | Another copy with the same trait exists in your **bank** |
| White | Equipped item uses ESO's default magnifying glass icon; details are shown in the tooltip |

Numbers below the icon show exactly how many duplicate copies exist (yellow = inventory, red = bank). Locked items show an icon but are excluded from duplicate counting. Other account characters are not considered.

---

### Loot Offset

![Loot Offset](screenshots/LootOffset.png)

Shifts the **loot history panel** upward so it does not overlap the chat box. The offset amount is configurable (default: 350 px).

> Requires a UI reload after toggling.

---

### Overview Panel

![Overview](screenshots/Overview.png)

Adds a rich overview panel at the root menu with two columns:

**Left — Quest Details** *(toggle: Quest Panel, default ON — independent of the right panel)*
- Quest background, active step, tasks, completed tasks, optional steps, and hints.
- Section order: Hints → Tasks → Optional → Completed.
- Full **screen narration** support — all sections are read aloud on gamepad.

**Right — Daily Reminders** *(toggle: Overview, default ON)*
- Each category renders as a titled section with a divider header and icon.
- **Time** — local and server time (each individually toggleable).
- **Horse Training** — available notification with individual Speed, Carrying Capacity, and Stamina skill progress.
- **Maps** — antiquity scryable leads (with expiration timer), treasure maps, and survey maps, each with inline icons.
- **Crafting** — master writ count, daily writ status per profession (Done / In Progress / Not Done), trait research slots and researchable trait/item counts. Completed writs can be hidden.
- **Companion** — companion name, XP bar, rapport gradient bar, rapport level and description, and best rapport-gaining daily activities with completion status.

**Daily Crafting Writ Tracker**

Shows the completion status of each daily crafting writ (Done / In Progress / Not Done) directly in the overview. Covers all seven professions: Blacksmithing, Clothier, Woodworking, Enchanting, Provisioning, Alchemy, and Jewelry. Completed writs are hidden from the list to keep it clean. Status persists across sessions and resets automatically at the daily reset. Tracking works by listening for quest completion events and covers all quest ID variants for each profession, so the status updates correctly regardless of which writ variant the game assigned.

**Companion Rapport Dailies**

When a companion is active, the right panel shows the companion's name, current rapport value and rank, and the best rapport-gaining daily activities with their completion status (Done / In Progress / Not Done). Status resets at the daily reset. Supported companions and their tracked activities:

| Companion | Tracked Activities |
|---|---|
| Bastian | Mages Guild Daily |
| Mirri | Fighters Guild Daily, Ashlander Hunt Daily, Ashlander Relic Daily |
| Ember | Mages Guild Daily, Thieves Guild Heist, High Isle Delve Daily |
| Isobel | Undaunted Daily, High Isle World Boss Daily |
| Azandar | Necrom Delve Daily, Enchanter Writ |
| Sharp-as-Night | Necrom World Boss Daily, Ashlander Hunt Daily, Ashlander Relic Daily |
| Tanlorin | Fighters Guild Daily, Alchemy Writ |
| Zerith-var | Northern Grahtwood Defence Force Daily, Tales of Tribute Daily |

Activity labels are hardcoded localized strings (available in EN, FR, DE, ES, RU, JP, ZH) so they display correctly on console where skill-line name APIs may be unavailable. Writ tracking (Alchemy Writ, Enchanter Writ) covers all quest ID variants so the status updates correctly regardless of which writ variant the player received.

---

### Tooltip Enchantment

![Tooltip Enchantment](screenshots/TooltipEnchantment.png)

Reformats the **enchantment information** in item tooltips for improved readability.

---

### Tooltip Font

![Tooltip Font](screenshots/TooltipFont.png)

Applies a cleaner font to **item tooltips**, optimized for readability on gamepad.

---

### Tooltip Poison

![Tooltip Poison](screenshots/TooltipPoison.png)

Reformats **applied poison information** in item tooltips for improved readability.

---

### Tooltip Price

![Tooltip Price](screenshots/TooltipPrice.png)

Reformats the **price information** in item tooltips. When a supported market addon is installed (for example **TamrielTradeCentre** or console price providers), also shows market pricing data inline.

Price data provided by [**Tamriel Savings Co Price Fetcher**](https://tamrielsavings.com/price-fetcher) when TSC sources are available.

---

### Tooltip Trait

![Tooltip Trait](screenshots/TooltipTrait.png)

Reformats **trait information** in item tooltips. Uses the same color coding as [Inventory Trait](#inventory-trait) to indicate research status at a glance.

---

## Dependencies

### Required

These must be installed for GamePadHelper to load. All are available on both PC and console.

| Library | What it does |
|---|---|
| [LibCovetousCountess](https://www.esoui.com/downloads/info3266-LibCovetousCountess.html) | Supplies quest-step data used by the **Inventory Covetous Countess** feature to identify which treasures are relevant to your active quest step. |
| [LibItemLinkDecoder](https://www.esoui.com/downloads/info3265-LibItemLinkDecoder.html) | Decodes raw item link data used by **Tooltip Enchantment** to reformat enchantment information in item tooltips. |
| [LibTraitResearch](https://www.esoui.com/downloads/info3264-LibTraitResearch.html) | Tracks per-character trait research progress, powering both the **Inventory Trait** icons and the **Tooltip Trait** color coding. |
| [LibMultiIcon](https://www.esoui.com/downloads/info3267-LibMultiIcon.html) | Renders stacked icon overlays on inventory slots, used by **Inventory Trait** and **Inventory Covetous Countess** to display their indicator icons without conflicting with each other. |

### Optional

These are not required to load the addon. Each one unlocks or enhances a specific feature.

| Library / Addon | What it unlocks |
|---|---|
| [TamrielTradeCentre](https://www.esoui.com/downloads/info1245-TamrielTradeCentre.html) | Optional market source for **Tooltip Price**. |
| [Tamriel Savings Co Price Fetcher / TSC Price Data API](https://tamrielsavings.com/price-fetcher) (`TSCPriceDataAPIXBNA`, `TSCPriceDataAPIPSNA`, `TSCPriceDataAPIXBEU`, `TSCPriceDataAPIPSEU`) | Optional console market data source for **Tooltip Price**. |

Attribution: Price data provided by [**Tamriel Savings Co Price Fetcher**](https://tamrielsavings.com/price-fetcher) when available.

---

## Support

This addon is provided as-is, without warranty or support of any kind. Bug reports and contributions are welcome via the [GitHub repository](https://github.com/olegbl/eso-mods/tree/main/GamePadHelper).
