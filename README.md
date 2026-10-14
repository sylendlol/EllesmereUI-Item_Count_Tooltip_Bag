# EllesmereUI-Item_Count_Tooltip_Bag
<img width="1306" height="950" alt="{B2465350-D257-4979-893B-2D5B976CC452}" src="https://github.com/user-attachments/assets/8b5939be-7b65-4597-b04d-7260d12a9aac" />
<img width="750" height="556" alt="{23B0F3E5-013D-43DA-B2F9-B9D4E99B5A1E}" src="https://github.com/user-attachments/assets/44d08f62-22ee-4fc3-bab4-77698ee72c46" />

A small add-on for **EllesmereUI** on **WoW Forever** (Interface 16001). It adds item counts to item tooltips: how many of the item you have in total, in your bags and in your bank.

```
Item Count        12
  Bags             7
  Bank             5
```

It is a standalone add-on and does not modify any EllesmereUI file, so EllesmereUI updates cannot overwrite or break it.

## Features

- Adds the counts to every item tooltip: your bags, links in chat, the auction house, vendors and loot.
- **Show Count For** controls which lines appear:
  - **Bags + Bank** (default): the total, then the bags and bank lines
  - **Bags**: only the bags line
  - **Bank**: only the bank line
- The lines always appear, even when the count is zero (for example, `Bank 0`), so you can see right away that you have none.
- Each line has its own colour: **Item Count** (gold by default), **Bags** and **Bank** (light grey by default). The label and the number use the same colour.
- The settings are stored in the add-on's own saved variables (`EllesmereUIItemCountDB`), not in the EllesmereUI profile.

> **Bank counts** use the game's own bank cache. They become complete once you have opened your bank on that character.

## Requirements

| Add-on | Required? | Why |
|---|---|---|
| **EllesmereUI** | Required | Base add-on, widgets and localisation |
| **EllesmereUIDworak** | Optional | Adds the **Dworak > Item Count** settings page. Without it, the tooltip lines still work and you change the settings with `/itemcount`. |

## Installation

1. Download this repository, or the latest release.
2. Copy the `EllesmereUIItemCount` folder into
   `World of Warcraft\_classic_beta_\Interface\AddOns\`
   The path should look like this: `AddOns\EllesmereUIItemCount\EllesmereUIItemCount.toc`.
3. Restart the game client completely. A `/reload` does not pick up a new add-on folder.
4. Make sure **EllesmereUI Item Count** is enabled in the AddOns list on the character select screen.

The feature is **on by default**.

## Settings

Open the EllesmereUI panel and go to **Dworak → Item Count**, or type `/itemcount`.

- **Item Count on Tooltip**: turns the tooltip lines on or off.
- **⚙ cog** next to it:
  - **Show Count For**: Bags + Bank / Bags / Bank
  - **Item Count Color**, **Bags Color**, **Bank Color**

### Slash commands

| Command | What it does |
|---|---|
| `/itemcount` | Opens the settings page. Without EllesmereUIDworak, it prints the current settings. |
| `/itemcount on` / `off` | Turns the tooltip lines on or off |
| `/itemcount both` / `bags` / `bank` | Sets **Show Count For** |

## Upgrading from the old built-in version

This feature used to be an edit inside EllesmereUI's own Bags files (**Bags → Extras → Item Count on Tooltip**, EllesmereUI 9.4). An EllesmereUI update removed that edit. On the first login, the add-on copies the old **Show Count For** setting and the three colours over once, if they are still in your EllesmereUI Bags profile.

## How it works

- It registers a `TooltipDataProcessor` post-call for item tooltips (`GameTooltip` and `ItemRefTooltip`).
- Counts:
  - bags = `C_Item.GetItemCount(id, false)`
  - total = `C_Item.GetItemCount(id, true, false, true)`
  - bank = total − bags
- Each tooltip is checked so the lines are added only once, even when the game fires the post-call more than once.

## Files

```
EllesmereUIItemCount/
  EllesmereUIItemCount.toc            add-on metadata and load order
  EllesmereUIItemCount.lua            settings, tooltip lines, one-time import, /itemcount
  EllesmereUIItemCount_Options.lua    the Dworak > Item Count settings page
```

## Compatibility

- Made for: WoW Forever beta (Interface 16001), EllesmereUI 9.5.4.
- The `.toc` also lists the retail interface versions that EllesmereUI supports, but the add-on was made for WoW Forever.
