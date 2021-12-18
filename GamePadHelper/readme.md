# GamePadHelper

[https://github.com/olegbl/eso-mods/tree/main/GamePadHelper](https://github.com/olegbl/eso-mods/tree/main/GamePadHelper)

## Description

Adds various UI improvements for GamePad. Each addition is split into a separate sub-addon and can be enabled or disabled individually from the addon list.

## Gear Comparison

When toggling between preview of currently equipped item and preview of stats changes, allows both panels to be shown side-by-side.

## Inventory Covetous Countess

Shows a magnifying glass icons next to treasures that are useful for the Covetous Countess quest. The icon is green if the item is useful for the currently active quest (if any) and white otherwise.

### Dependencies

* [LibCovetousCountess](https://www.esoui.com/downloads/info3266-LibCovetousCountess.html)
* [LibMultiIcon](https://www.esoui.com/downloads/info3267-LibMultiIcon.html)

## Inventory Trait

Shows a magnifying glass icon next to items that have a trait that can be researched by the current character.  
The icon is red if there is another item with the same trait in the bank. The icon is yellow if there is another item with the same trait in the inventory. The icon is green if it is the only one with that trait that the character has access to.  
If there is another item with the same trait in the bank, there is a red number below the icon indicating how many duplicate copies there are.  
If there is another item with the same trait in the inventory, there is a yellow number below the icon indicating how many duplicate copies there are.  
Locked items still show an icon but are ignored by all other items.  
Other characters in the account are ignored.

### Dependencies

* [LibMultiIcon](https://www.esoui.com/downloads/info3267-LibMultiIcon.html)
* [LibTraitResearch](https://www.esoui.com/downloads/info3264-LibTraitResearch.html)

## Overview

Shows an overview panel at the root menu that shows information about the currently selected quest as well as reminders for common tasks (horse training, crafting research).

## Teleporter

When hovering a zone on the world map, adds a new hotkey that can be pressed in order to ask BeamMeUp to teleport the player to the target zone using the best available method.  
This also works with Keyboard + Mouse but is mostly useful for GamePad which does not have a convenient way to utilize BeamMeUp's normal interface.

### Dependencies

* [BeamMeUp](https://www.esoui.com/downloads/info2143-BeamMeUp-TeleporterFastTravel.html)

## Tooltip Enchantment

Reformats the enchantment information in item tooltips.

### Dependencies

* [LibItemLinkDecoder](https://www.esoui.com/downloads/info3265-LibItemLinkDecoder.html)

## Tooltip Font

Changes the font used in item tooltips.

## Tooltip Poison

Reformats the applied poison information in item tooltips.

## Tooltip Price

Reformats the price information in item tooltips. Optionally, adds pricing based on Tamriel Trade Centre if that addon is available.

### Dependencies

* [TamrielTradeCentre](https://www.esoui.com/downloads/info1245-TamrielTradeCentre.html) (Optional)

## Tooltip Trait

Reformats the trait information in item tooltips. See Inventory Trait sub-addon's description for a brief description of what the colors mean.

### Dependencies

* [LibTraitResearch](https://www.esoui.com/downloads/info3264-LibTraitResearch.html)

## Support

This addon is provided as is, without warranty or support of any kind, express or implied.