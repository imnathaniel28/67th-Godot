# GameMaker Project - 67th1.1_Master

<!--
⚠️ IMPORTANT FOR CLAUDE:
This file MUST be updated every time ANY changes are made to the project!
- After adding/modifying scripts, objects, rooms, or sprites
- After fixing bugs or implementing features
- After testing or discovering issues
- Update "Recent Changes" section with timestamp
- Update "What We're Working On" section
- Update "Next Steps" if priorities change
READ THIS FILE at the start of each session to understand project state!
-->

## Project Overview
67th Street is a street-level territory control and dealing game. Players navigate a top-down city environment, managing resources, engaging in PVP encounters, and building their empire through trap houses and strategic territory control.

## Project History
**2026-01-05**: Master project created by merging two development branches:
- Merged from `67th-Github_main` (primary base - more complete)
- Merged from `67th` (working customization scripts)
- Created unified master at `C:\Users\imn8\Documents\GitHub\67th-Master`

## Core Features

### Jail System
- **Jail Lobby** (`rm_jail_lobby`): Prison environment where arrested players spend time
  - Cell system with assigned bed for player
  - Multiple interactive gaming tables
  - NPC inmates with alliance system
  - Commissary booth for purchasing supplies
  - Exit door with timer (player leaves when time served)
- **Chess System** (`obj_chess_table`):
  - Full chess implementation with AI opponent
  - Easy and Medium difficulty levels
  - 12 chess piece sprites (6 white, 6 black)
  - Complete move validation and checkmate detection
  - Chess-specific scripts: `scr_chess_init`, `scr_chess_input`, `scr_chess_move`, `scr_chess_ai`, `scr_chess_draw`, `scr_chess_utils`
- **Spades Card Game** (`obj_chspades_table`):
  - Interactive spades/card game system
  - Multiplayer mechanics
  - Point-based gameplay
- **Chat Tables** (`obj_chat_table1`, `obj_chat_table2`):
  - Interactive NPC dialogue and storytelling
  - Relationship building mechanics
- **Commissary System** (`obj_commissary_booth`):
  - Purchase food and drinks: Ramen ($5), Chips ($3), Soda ($4), Coffee ($6), Candy ($2), Water ($2)
  - Interactive menu with [E] key interaction
  - Number key purchases (1-6)
  - Items added to player inventory for trading/gifting
- **Alliance System**:
  - Build relationships with 3 inmates in jail
  - 4 alliance levels: Stranger, Acquaintance, Friend, Ally
  - Gift items using [G] key
  - Point values based on item cost
  - Foundation for future perks (info, defense, escape)
- **Jail Mechanics**:
  - Random arrest by police during street encounters
  - Jail timer (countdown in days/hours/seconds)
  - Player leaves when timer expires
  - Inventory management while jailed
  - Integration with health and combat systems

### Territory System
- Territory control mechanics (see TERRITORY_SYSTEM.md for details)
- PVP encounters and duels
- Undercover agent system for realistic gameplay

### Trap House System
- **Interior System**: Full trap house interior with functional rooms
  - Objects: `house_trap`, `house_trapUpgrade`
  - Room: `rm_trap_house_interior`
  - Door/Exit mechanics: `obj_house_door`, `obj_house_exit`, `obj_house_wall`
- **Stash Houses**: Three tiers of dealer locations
  - `obj_dealer_stashHouse_low`
  - `obj_dealer_stashHouse_mid`
  - `obj_dealer_stashHouse_high`

### Economic System
- Customer NPC interactions (`obj_npc_customer`)
  - **Crosswalk Navigation**: NPCs only cross streets at designated crosswalks
  - Wander behavior: NPCs walk on sidewalks, occasionally cross at crosswalks
  - Follow behavior: NPCs navigate to nearest crosswalk when following player across street
  - Law-abiding pedestrian AI creates realistic street behavior
- Sale mechanics with popup notifications (`obj_sale_popup`, `scr_make_sale`)
- Transaction dialog system (`obj_transaction_dialog`)
- Gun store for weapon purchases (`obj_gun_store`)

### Crew/Gang System
- **Unlocks at $100,000**: Passive income through hired workers
- **Recruitment System** (`obj_crew_recruiter`):
  - Hustlers approach player periodically
  - View worker stats: Sales Skill, Heat Management, Loyalty, Stamina
  - Three hiring options:
    - **Hire Now**: $500 signing bonus, permanent hire
    - **Test Run**: FREE 1-day trial to evaluate performance
    - **Reject**: Turn down recruiter
- **Crew Members** (`obj_crew_member`):
  - Autonomous AI: Roam, detect customers, make sales automatically
  - Stats-based performance (sales skill affects earnings and success rate)
  - Leveling system: Workers gain XP from sales, improve stats over time
  - Visual name tags with status indicators (working, selling, break, trouble)
- **Economics**:
  - Workers earn $15-$45 per sale (modified by skill)
  - Daily wages: $200-$500 (based on sales skill)
  - Average profit: $300-$1500 per worker per day
  - Press [C] near worker to collect earnings
- **Crew Size**: Dynamic max based on progress
  - Base: 2 workers
  - +1 per $50,000 earned
  - +1 per trap house owned
  - Maximum: 8 workers
- **HUD Integration**: Shows active workers and daily earnings
- See CREW_SYSTEM.md for complete documentation

### Gambling System
- **Street Craps** (`obj_dice_game`):
  - Full dice game mechanics with craps rules
  - Players can gamble money on dice rolls
  - Probability-based outcomes with realistic odds
  - Win/loss scenarios with monetary rewards and penalties
  - Police interactions during active games
  - Robbery opportunities during gameplay
  - Integration with heat level and law enforcement
  - Complete game state management
  - Visual dice display and outcome tracking

### Shipment System
- Two delivery methods:
  - Car shipments (`obj_shipment_car`) - Fast delivery, higher risk
  - Walker shipments (`obj_shipment_walker`) - Foot courier, can be robbed
- **Robbery Mechanics**:
  - Players can intercept walker couriers with [R] key
  - Must be within 48 pixels of walker to see prompt
  - Stolen value: $50 per unit of drugs
  - Robbing increases heat level (+20)
  - Walker disappears after being robbed

### Combat & Law Enforcement
- Duel system with dedicated room (`rm_duel`)
  - Scripts: `scr_start_duel`, `scr_end_duel`
  - Bullet mechanics: `obj_duel_bullet`
- Police system
  - Cop AI and pursuit (`obj_cop`)
  - Cop bullets (`obj_cop_bullet`)
  - Arrest mechanics (`scr_arrest_player`)
- PVP encounters (`scr_start_pvp_encounter`, `scr_resolve_pvp`)

### Player Systems
- Player character (`player1`) with multiple animation states
- Customization system
  - Customization room (`rm_customize`)
  - Controller: `obj_customization_controller`
  - Variables: `player_skin_tone`, `player_bandana_color`
  - Save/Load: `scr_save_customization`, `scr_load_customization`

### Game Management
- Main controller (`obj_game_controller`) - Core game state and logic
- Territory controller (`obj_territory_controller`) - Territory mechanics
- Menu system (`obj_menu_controller`, `rm_menu`)
- Save/Load system (`scr_save_load`)

### Time & Day/Night System
- **24-Hour Clock**: Each in-game day lasts 5 real-time minutes (18000 frames at 60fps)
- **Digital Clock Display**: Shows current time in HH:MM format (top-right corner)
- **Day/Night Cycle**: Visual dimming during night hours (10pm-10am)
  - Night overlay: Dark blue tint with 0.4 alpha
  - Smooth transitions between day and night
  - Clock changes color during night (aqua) vs day (yellow/white)

### Art Assets & Sprite Packs
Project includes organized sprite asset packs in `sprites/Asset_Packs/`:

1. **Modern_Tiles** - Modern tileset collection
   - Characters (free version)
   - Interior tiles
   - Includes old versions for reference
   - License: See LICENSE.txt in pack folder

2. **Social_Media_Icons** - MV Icons Social Media pack
   - Individual social media icons
   - Combined spritesheet (ALL.png)
   - Useful for UI elements

3. **Serene_Village** - RPG Maker village tileset (revamped)
   - Multiple versions: 16x16, 32x32, 48x48
   - Animated elements
   - Support for multiple engines (Construct 3, RPG Maker variants)
   - Comprehensive village/town environment tiles

4. **Platformer_Metroidvania** - Complete platformer asset pack v1.01
   - Enemy sprites
   - Fauna/wildlife sprites
   - Hero character sprites (new)
   - HUD elements
   - Miscellaneous sprites
   - Tiles, backgrounds, and foregrounds (new)
   - README with usage instructions

## Room Structure
1. **rm_menu** - Main menu
2. **rm_customize** - Character customization
3. **Room1** - Main game world (streets, buildings, territories)
4. **rm_duel** - PVP duel arena
5. **rm_trap_house_interior** - Interior of trap houses (dealing operations)
6. **rm_generic_house_interior** - Generic interior for regular buildings (shared interior)
7. **rm_jail_lobby** - Jail prison environment with gaming and commissary

## Current Status
✅ **Master Project - Feature Rich** - All core systems implemented and verified
- **47 Game Objects** with complete event handlers (added crew system)
- **26 Scripts** for game logic and mechanics
- **7 Rooms** covering all game modes
- **Complete Jail System** with chess, spades, and commissary
- **Gambling System** with street craps minigame
- **Crew/Gang System** with autonomous workers and passive income (Phase 1)
- **Health & Respawn System** fully integrated
- **Police Enforcement** with arrest and search mechanics
- **Time System** with 24-hour cycle and day/night visuals
- Documentation fully up to date
- Git version control configured

## What We're Working On / Recently Completed
- ✅ Implemented Crew/Gang System Phase 1 - Autonomous workers and recruitment (2026-01-26)
- ✅ Implemented street craps (dice) gambling minigame (2026-01-11)
- ✅ Fixed dice game JSON syntax and physics field errors (2026-01-11)
- ✅ Implemented complete jail system with chess AI (2026-01-10)
- ✅ Implemented health system with respawn mechanics (2026-01-10)
- ✅ Implemented police stop & search system with 3 arrest outcomes (2026-01-10)
- ✅ Restored and updated documentation files (2026-01-11)
- 🔄 Next Up: Crew System Phase 2 (territory assignment, management UI, wage system)
- Ready for testing and gameplay balancing

## Important Technical Notes
- **GameMaker Version**: 2024.14.2.213
- **Save File Format**: Text-based .sav files for customization
- **Customization Variables**:
  - `global.player_skin_tone` (numeric)
  - `global.player_bandana_color` (numeric)
- **Territory System**: See TERRITORY_SYSTEM.md for complete documentation
- **Depth Sorting**: All moving objects use `depth = -y` for proper Y-based layering
  - Objects higher on screen (lower Y) appear behind objects lower on screen (higher Y)
- **Time System**:
  - Day length: 5 real minutes (300 seconds = 18000 frames at 60fps)
  - Time display: 24-hour format (00:00 to 23:59)
  - Night time: 22:00 (10pm) to 10:00 (10am)
  - Night dimming: 0.4 alpha dark blue overlay
- **Collision Prevention System**:
  - All moving objects prevent overlap with each other
  - Uses position rollback pattern: store old position → move → check collision → revert if needed
  - Checks against: `player1`, `FakePlayer1`, `obj_npc_customer`, `obj_cop`, `obj_undercover_agent`
  - Prevents walking through other characters while allowing intentional interactions (NPCs reaching players, cops arresting)
- **Crew System**: See CREW_SYSTEM.md for complete documentation
  - Unlocks at $100,000
  - Crew members array stores worker instances
  - Max crew size scales with progress (base 2, +1 per $50k, +1 per trap house, max 8)
  - Workers have autonomous AI: roam → detect customer → sell → earn money
  - Test Run option allows 1-day free trial before hiring
  - Press [C] near worker to collect earnings

## Recent Changes

### 2026-01-26 (Crew/Gang System - Phase 1)
- **Implemented complete Crew/Gang recruitment and management system**:
  - Created `obj_crew_member` - Autonomous worker AI with roaming and sales behavior
  - Created `obj_crew_recruiter` - Hustlers who approach player for recruitment
  - **Unlocks at $100,000 milestone**: System becomes available when player reaches threshold
  - **Recruitment Dialog System**:
    - Three hiring options: Hire Now ($500), Test Run (FREE 1-day trial), Reject
    - View worker stats: Sales Skill, Heat Management, Loyalty, Stamina
    - Randomized street names and appearances
  - **Worker AI States**:
    - Roaming: Wanders territory looking for customers
    - Selling: Autonomous sales with NPC customers (3-second transactions)
    - Break: 2-minute rest after 15 minutes of work
    - Stats-based success rates and earnings
  - **Economic System**:
    - Workers earn $15-$45 per sale (modified by sales skill)
    - Daily wages $200-$500 based on skill level
    - Press [C] near worker to collect earnings
  - **Leveling System**:
    - Workers gain XP from successful sales
    - 5 levels: Rookie → Corner Boy → Hustler → Dealer → Lieutenant
    - Stats improve on level up
  - **Dynamic Crew Size**: Base 2, +1 per $50k earned, +1 per trap house, max 8
  - **Visual System**:
    - Name tags above workers
    - Color-coded status indicators (green/yellow/purple/red)
    - HUD display shows active crew count and daily earnings
  - **Files Created**:
    - `objects/obj_crew_member/` - Complete worker implementation
    - `objects/obj_crew_recruiter/` - Recruitment system
    - `CREW_SYSTEM.md` - Complete documentation
  - **Files Modified**:
    - `player1/Create_0.gml` - Added crew variables
    - `player1/Step_0.gml` - Added recruitment spawning and earnings collection
    - `player1/Draw_64.gml` - Added crew HUD display
    - `67th1.1_Master.yyp` - Registered new objects
  - Phase 1 complete: Core recruitment and autonomous earning system functional
  - Future phases: Territory assignment UI, wage deduction, arrest/betrayal mechanics

### 2026-01-11 (Craps Mini-Game Implementation)
- **Implemented Street Craps (Dice) mini-game**:
  - Created `obj_dice_game` with full craps mechanics
  - Players can play craps in the streets/jail
  - Dice rolling mechanics with probability calculations
  - Win/loss scenarios with money rewards and losses
  - Visual dice display and game state management
  - Integration with game controller for game flow
  - Features police interactions during active games
  - Robbery mechanics during gameplay
  - Files modified:
    - `objects/obj_dice_game/` - Complete dice game implementation
    - `obj_game_controller` - Integration with main game
  - Creates strategic gambling opportunity in urban environment

### 2026-01-10 (Jail System Enhancement)
- **Comprehensive jail system implemented**:
  - Jail lobby room (`rm_jail_lobby`) with multiple interactive elements
  - Chess table (`obj_chess_table`) with AI opponent and difficulty selection
  - Spades table (`obj_chspades_table`) for card gaming
  - Chat tables (`obj_chat_table1`, `obj_chat_table2`) for NPC interactions
  - Commissary booth (`obj_commissary_booth`) for food/drink purchases
  - Alliance system for building relationships with inmates
  - Tank bully NPC (`obj_tank_bully`) for interaction and trades
  - Jail melee combat system
  - Jail cell bed assignment system
  - Jail exit mechanics with timer
  - Complete documentation of jail features in CLAUDE.md

### 2026-01-10 (Health System Implementation)
- **Complete health and respawn system**:
  - Health bar display in top-left corner
  - Death/respawn mechanics when health reaches 0
  - Death penalties: lose $50 and 50% of inventory
  - Health regeneration system (1 HP every 3 seconds when not in jail/duel)
  - Visual health bar with color coding (green/yellow/red)
  - Persistent health across game sessions

### 2026-01-10 (Police Stop & Search System)
- **Random police enforcement mechanics**:
  - Police stop players randomly for search (10-minute cooldown)
  - Three distinct outcomes based on player inventory:
    1. No drugs: $100 fine
    2. Has drugs but <$1000: Jail time (1 week) with drug confiscation
    3. Has drugs + $1000+: Corrupt cops rob all money, beat up player, confiscate drugs
  - Full arrest system integration
  - Robbery popup UI with visual feedback
  - Enhanced jail timer UI with countdown display

### 2026-01-06 (NPC Crosswalk Navigation)
- **Implemented law-abiding crosswalk navigation for NPCs**:
  - NPCs now only cross streets at designated crosswalks (X: 200-280, 600-680, 1000-1080)
  - Added crossing state machine with two phases: "approach" (walk to crosswalk) and "crossing" (cross street)
  - Wander state: 30% chance to cross street when changing direction
  - Follow state: NPCs detect when player is on opposite side and navigate to nearest crosswalk
  - Flee state: Unchanged - NPCs ignore traffic laws when fleeing snitches (panic behavior)
  - Added helper functions: `needs_to_cross()`, `is_in_crosswalk()`, `find_nearest_crosswalk()`, `initiate_crossing()`
  - Files modified:
    - `obj_npc_customer/Create_0.gml` - Added 6 crossing variables and 4 helper functions
    - `obj_npc_customer/Step_0.gml` - Added crossing behavior handler, modified wander and follow states
  - Creates realistic pedestrian behavior where NPCs obey traffic laws
  - NPCs walk horizontally to crosswalk, then cross vertically at 1.5x speed
  - Adjustable detection radius already set to 100 pixels for close-proximity following

### 2026-01-06 (Sprite Asset Organization)
- **Imported and organized 4 sprite asset packs**:
  - Created `sprites/Asset_Packs/` directory structure
  - **Modern_Tiles**: Modern tileset with characters and interiors
  - **Social_Media_Icons**: MV Icons pack for UI elements
  - **Serene_Village**: RPG village tileset (16x16, 32x32, 48x48 versions)
  - **Platformer_Metroidvania**: Complete platformer pack with enemies, characters, HUD, tiles
  - All packs organized in separate folders for easy access
  - License files and READMEs preserved with each pack
  - Ready to be imported into GameMaker as needed
  - Created `obj_npc_customer2` for future NPC variations
  - Location: `C:\Users\imn8\Documents\GitHub\67th-Master\sprites\Asset_Packs\`

### 2026-01-05 (Walker Robbery System)
- **Implemented courier robbery/intercept mechanics**:
  - Added interactive robbery system for `obj_shipment_walker`
  - Players can press [R] when within 48 pixels of walker courier
  - Shows prompt: "[R] Rob Courier" with potential value in yellow
  - Robbery rewards: $50 per unit of drugs being transported
  - Increases player heat level by +20 when robbing
  - Walker disappears after being robbed (runs away)
  - Added depth sorting (`depth = -y`) to walkers for proper layering
  - Files modified:
    - `obj_shipment_walker/Step_0.gml` - Added robbery detection and handling
    - `obj_shipment_walker/Draw_64.gml` - Added visual prompt system
    - `CLAUDE.md` - Updated documentation with robbery mechanics
  - Creates risk/reward dynamic for intercepting drug shipments
  - Foundation for future car shipment robberies

### 2026-01-05 (Building Collision System)
- **Implemented building collision detection**:
  - Created `obj_building_parent` as common parent for all buildings
  - Updated 6 building objects to inherit from parent:
    - `house1` (blue dome house)
    - `house_purp` (purple house)
    - `Object15` (modern house)
    - `Object16` (brown small house)
    - `Object17` (blue tall house)
    - `Object18` (curved house)
  - Modified `player1/Step_0.gml` to check building collisions
  - Players can no longer walk through or stand on buildings
  - Door entry system preserved (press E near doors still works)
  - Uses sprite-based collision masks for natural building shapes
  - Files modified:
    - Created: `objects/obj_building_parent/obj_building_parent.yy`
    - Updated: All 6 building object .yy files
    - Updated: `player1/Step_0.gml` (added building collision check)
    - Updated: `67th1.1_Master.yyp` (registered parent object)

## Recent Changes
### 2026-01-05 (Very Late Night - Collision Bug Fix #4 - FINAL)
- **Removed ALL collision detection from NPCs**:
  - Problem: NPCs were still colliding with each other, causing pileups and unnatural clustering
  - Solution: Removed ALL collision checks from NPCs - they now move completely freely
  - This creates organic, realistic crowd behavior where NPCs can naturally cluster
  - Updated `obj_npc_customer/Step_0.gml`:
    - Wander state: Removed all collision checks (previously checked cops/agents)
    - Follow state: Removed all collision checks (previously checked cops/agents)
    - Flee state: Removed all collision checks (previously checked cops/agents)
  - NPCs can now move through everything: players, other NPCs, cops, agents
  - Players still avoid NPCs (but not vice versa)
  - Creates natural street vendor feel with crowds

### 2026-01-05 (Very Late Night - Collision Bug Fix #3)
- **Fixed players also checking NPC collision**:
  - Problem: Both players AND NPCs were checking for collision with each other, causing bidirectional blocking
  - Solution: Removed NPC collision checks from both player1 and FakePlayer1
  - Updated files:
    - `player1/Step_0.gml` - Removed obj_npc_customer collision check
    - `FakePlayer1/Step_0.gml` - Removed obj_npc_customer collision check
  - Players can now move even when surrounded by NPCs
  - NPCs still couldn't move through each other (fixed in #4)

### 2026-01-05 (Very Late Night - Collision Bug Fix #2)
- **Fixed redundant collision check and pursuit collision**:
  - Problem: Collision checks had redundant `&& _collision != self` condition that was always true
  - Solution: Simplified to just `if (_collision)` since we already excluded self-type checks
  - Updated all 5 moving object types:
    - `player1/Step_0.gml` - Simplified collision check and re-added collision prevention
    - `FakePlayer1/Step_0.gml` - Removed redundant `!= self` check
    - `obj_npc_customer/Step_0.gml` - Fixed in all 3 states (wander, follow, flee)
    - `obj_cop/Step_0.gml` - Fixed in both patrol and chase states
    - `obj_undercover_agent/Step_0.gml` - Simplified collision check
  - Collision prevention now works correctly - objects avoid overlapping while maintaining smooth movement

### 2026-01-05 (Very Late Night - Collision Bug Fix #1)
- **Fixed collision prevention causing objects to freeze**:
  - Problem: Objects were checking for collision with their own object type, causing them to always detect collision with themselves
  - Solution: Removed self-type checks from all collision detection code
  - Fixed in all 5 moving object types:
    - `player1/Step_0.gml` - Removed `instance_place(x, y, player1)` check
    - `FakePlayer1/Step_0.gml` - Removed `instance_place(x, y, FakePlayer1)` check
    - `obj_npc_customer/Step_0.gml` - Removed `instance_place(x, y, obj_npc_customer)` checks in all 3 states
    - `obj_cop/Step_0.gml` - Removed `instance_place(x, y, obj_cop)` checks in both states
    - `obj_undercover_agent/Step_0.gml` - Removed `instance_place(x, y, obj_undercover_agent)` check

### 2026-01-05 (Very Late Night - Collision Prevention)
- **Implemented collision prevention between moving objects**:
  - Added collision checks to prevent objects from overlapping each other
  - Pattern: Store old position → attempt move → check collision → revert if colliding
  - Modified all moving objects to check for collisions with other moving object types
  - Files modified:
    - `player1/Step_0.gml` - Added collision prevention after movement (lines 83-94)
    - `FakePlayer1/Step_0.gml` - Added collision prevention in normal movement section (lines 49-60)
    - `obj_npc_customer/Step_0.gml` - Added collision checks in all three states: wander, follow, flee
    - `obj_cop/Step_0.gml` - Added collision prevention in both patrol and chase states
    - `obj_undercover_agent/Step_0.gml` - Added collision check when chasing target
  - Each object checks against all other moving types (except allows reaching intended targets)
  - NPCs in "follow" state can still reach players to trigger sales
  - Cops and agents can still reach players to trigger arrests
  - Prevents unrealistic overlapping while maintaining gameplay mechanics

### 2026-01-05 (Very Late Night - Bug Fix)
- **Fixed `global.debug_mode` error**:
  - Added `global.debug_mode = false` initialization in `obj_game_controller/Create_0.gml`
  - Fixes crash in `obj_shipment_walker` Draw event that referenced undefined variable
  - Error was: "global variable name 'debug_mode' index (112) not set before reading it"

### 2026-01-05 (Very Late Night)
- **Implemented Time System & Day/Night Cycle**:
  - Changed day length from 10 minutes to 5 minutes real-time
  - Added 24-hour clock system with hours (0-23) and minutes (0-59)
  - Created digital clock display in top-right corner with HH:MM format
  - Implemented AM/PM indicator that changes color (aqua at night, yellow/white during day)
  - Added night detection (10pm-10am)
  - Created smooth day/night transitions with `lerp` for gradual dimming
  - Night overlay: Dark blue tint (RGB: 10, 10, 40) with 0.4 alpha
  - Clock border changes color during night (aqua) vs day (yellow)
  - Files modified:
    - `obj_game_controller/Create_0.gml` - Added time display variables and night cycle vars
    - `obj_game_controller/Step_0.gml` - Calculate time and smooth night transitions
    - `obj_game_controller/Draw_64.gml` - Digital clock display and night overlay

### 2026-01-05 (Late Night)
- **Fixed depth sorting bug**: Objects now properly layer based on Y position
  - Added `depth = -y` to all moving objects:
    - `player1` (main player)
    - `FakePlayer1` (NPC player)
    - `obj_npc_customer` (wandering customers)
    - `obj_cop` (police officers)
    - `obj_undercover_agent` (undercover cops)
  - Now characters appear behind buildings when walking "up" and in front when walking "down"
  - Fixes overlap issues where player would incorrectly render on top of buildings

### 2026-01-05 (Earlier)
- Created master project by merging `67th-Github_main` and `67th`
- Verified all trap house features present
- Confirmed customization save/load system working
- All 5 rooms configured and functional
- Complete script library integrated
- Added documentation tracking system to CLAUDE.md

## Next Steps
- Test gameplay in all rooms
- Verify all NPC interactions
- Test save/load functionality
- Playtest territory control mechanics
