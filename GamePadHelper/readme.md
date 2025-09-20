# GamePadHelper

[https://github.com/olegbl/eso-mods/tree/main/GamePadHelper](https://github.com/olegbl/eso-mods/tree/main/GamePadHelper)

## Description

Adds various UI improvements for GamePad. Each addition is split into a separate sub-addon and can be enabled or disabled individually from the addon list.

## Auto Charge

automatically charges equipped weapons (main hand, off hand, backup main, backup off) with soul gems when their charge drops below 25%, using the highest level filled soul gem available. Configure with /gph charge.

## Auto Eye

automates Antiquarian's Eye usage by slotting and using the collectible automatically when not in combat or moving, and unslotting when blocked. Configure with /gph eye.

## Auto Repair

automatically repairs all equipped items when opening a merchant store, provided repair is available and costs gold. Configure with /gph repair.

## Dungeon Finder

enhances the dungeon finder by displaying pledge quests in the list, replacing dungeon names with their corresponding pledge quest names for easier identification. Configure with /gph dungeon.

## Fishing

enhances fishing with controller vibration feedback on fish bites, 'Reel in!' alerts, and automatic bait selection based on fishing hole type. Configure with /gph fish and /gph bait.

## Gear Comparison

when toggling between preview of currently equipped item and preview of stats changes, allows both panels to be shown side-by-side.

## Inventory Covetous Countess

shows a magnifying glass icons next to treasures that are useful for the Covetous Countess quest. The icon is green if the item is useful for the currently active quest (if any) and white otherwise.

### Dependencies

* [LibCovetousCountess](https://www.esoui.com/downloads/info3266-LibCovetousCountess.html)
* [LibMultiIcon](https://www.esoui.com/downloads/info3267-LibMultiIcon.html)

## Inventory Trait

shows a magnifying glass icon next to items that have a trait that can be researched by the current character. The icon is red if there is another item with the same trait in the bank. The icon is yellow if there is another item with the same trait in the inventory. The icon is green if it is the only one with that trait that the character has access to. If there is another item with the same trait in the bank, there is a red number below the icon indicating how many duplicate copies there are. If there is another item with the same trait in the inventory, there is a yellow number below the icon indicating how many duplicate copies there are. Locked items still show an icon but are ignored by all other items. Other characters in the account are ignored.

### Dependencies

* [LibMultiIcon](https://www.esoui.com/downloads/info3267-LibMultiIcon.html)
* [LibTraitResearch](https://www.esoui.com/downloads/info3264-LibTraitResearch.html)

## Loot Offset

adjusts the loot history offset for keyboard chat users. Configure with /gph loot.

## Overview

shows an overview panel at the root menu with detailed quest information (background, active step, tasks, completed tasks, optional steps, and hints) on the left, and reminders for common tasks on the right including horse training availability, crafting research status with available slots and researchable traits/items, surveys and writs counts, antiquities scryable leads with expiration timers, and treasure maps count.

## Provisioning

adds a filter option to hide low-level recipes (under CP160) in the provisioning interface, with a toggle in the options menu. Configure with /gph provisioning.

## Teleporter

when hovering a zone on the world map, adds a new hotkey that can be pressed in order to ask BeamMeUp to teleport the player to the target zone using the best available method. This also works with Keyboard + Mouse but is mostly useful for GamePad which does not have a convenient way to utilize BeamMeUp's normal interface. Additionally, adds "Jump to Player" options in the chat menu for friends, guild members, and group members.

### Dependencies

* [BeamMeUp](https://www.esoui.com/downloads/info2143-BeamMeUp-TeleporterFastTravel.html) (Optional)

## Tooltip Enchantment

reformats the enchantment information in item tooltips.

### Dependencies

* [LibItemLinkDecoder](https://www.esoui.com/downloads/info3265-LibItemLinkDecoder.html)

## Tooltip Font

changes the font used in item tooltips.

## Tooltip Poison

reformats the applied poison information in item tooltips.

## Tooltip Price

reformats the price information in item tooltips. Optionally, adds pricing based on Tamriel Trade Centre if that addon is available.

### Dependencies

* [TamrielTradeCentre](https://www.esoui.com/downloads/info1245-TamrielTradeCentre.html) (Optional)

## Tooltip Trait

reformats the trait information in item tooltips. See Inventory Trait sub-addon's description for a brief description of what the colors mean.

### Dependencies

* [LibTraitResearch](https://www.esoui.com/downloads/info3264-LibTraitResearch.html)

## Support

This addon is provided as is, without warranty or support of any kind, express or implied.