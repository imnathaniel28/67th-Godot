# Territory Control System

## Overview
The Territory Control System allows players to claim and manage blocks of space in the low-income neighborhood. Players can customize their territory with colors and names, and relocate as needed.

## How to Use

### Claiming Territory (Free!)
1. Press **T** key to open the territory menu
2. If you don't have a territory yet, the claiming UI will appear
3. Select your territory color by pressing number keys **1-9**
4. Click on any **unclaimed block** (faint gray outline) in the low-income neighborhood
5. Enter a name for your territory when prompted
6. Your territory is now claimed!

### Relocating Territory (10% Tax)
1. Press **T** key to open the territory menu
2. If you already have a territory, the relocation UI will appear
3. Click on any **unclaimed block** to move your territory
4. You'll pay a **10% cash tax** based on your current money
5. Your territory keeps its name and color at the new location

### Visual Indicators
- **Claimed territories**: Shown as colored semi-transparent blocks
- **Your territory**: Displays in top-right corner with name and color
- **Unclaimed blocks**: Faint gray outlines
- **Selected block**: Highlighted in yellow when hovering

### Controls
- **T** - Toggle territory menu
- **1-9** - Select color when claiming (first time only)
- **Left Click** - Claim or relocate to selected block
- **Mouse** - Hover over blocks to select them

## Technical Details

### Territory Grid
- Grid size: 20 blocks wide × 12 blocks tall
- Block size: 64×64 pixels
- Location: Low-income neighborhood (bottom half of map)
- Starting position: (64, 448) in world coordinates

### Scripts
- `scr_claim_territory(player, block_x, block_y, color)` - Claim a territory
- `scr_relocate_territory(player, new_block_x, new_block_y)` - Move territory (10% tax)
- `scr_update_territory_name(player, new_name)` - Rename territory
- `scr_get_territory_owner(block_x, block_y)` - Check who owns a block

### Player Variables
- `territory_x` - Grid X position of owned territory (-1 if none)
- `territory_y` - Grid Y position of owned territory (-1 if none)
- `territory_color` - Color of territory
- `territory_name` - Name of territory
- `has_territory` - Boolean indicating ownership

### Objects
- `obj_territory_controller` - Main controller managing the territory grid and UI

## Features
✅ Free territory claiming in low-income neighborhood
✅ 12 color options for customization
✅ Custom naming for territories
✅ Territory relocation with 10% cash tax
✅ Visual overlay showing all territories
✅ Real-time UI updates
✅ Integration with existing player systems

## Future Enhancements (Not Implemented)
- Territory benefits (e.g., income generation, safe zones)
- Multi-block territories
- Territory trading between players
- Territory upgrades
- Income from territory control
