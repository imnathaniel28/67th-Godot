# 67th Street - Implementation Plan

> Master plan for completing all incomplete features.
> Ordered by dependency chain: foundational fixes first, then systems that other systems rely on, then standalone features, then polish.

---

## Phase 1: Critical Bug Fixes (Foundation)

*These are crashes, wrong variable names, and rendering bugs that must be fixed before building anything on top of them. Most are one-line fixes.*

### 1.1 Fix Loan Shark Variable Name
- **File**: `objects/obj_loan_shark/Step_0.gml` (line 34)
- **Problem**: References `game_ctrl.current_day` but the actual variable is `day_current`
- **Fix**: Change to `game_ctrl.day_current`
- **Why first**: Crashes the game if a player takes a loan

### 1.2 Fix Tank Bully Ally Label Position
- **File**: `objects/obj_tank_bully/Draw_64.gml` (line 95)
- **Problem**: `draw_text(_ally_y, _ally_y, "ALLY")` — uses Y for both coordinates
- **Fix**: Change to `draw_text(_screen_x, _ally_y, "ALLY")`
- **Why first**: Visual bug visible to players in jail

### 1.3 Fix Malformed Code in Game Controller Draw
- **File**: `objects/obj_game_controller/Draw_64.gml` (line 19)
- **Problem**: Entire debt display block compressed to one line (merge artifact)
- **Fix**: Reformat to proper multi-line GML
- **Why first**: Maintainability — impossible to debug or extend this code

### 1.4 Remove Hospital Debug Text
- **File**: `objects/obj_hospital/Draw_0.gml` (lines 21-30)
- **Problem**: Debug distance/NEARBY text renders on screen during gameplay
- **Fix**: Wrap in `if (global.debug_mode)` or remove entirely
- **Why first**: Visible to players, breaks immersion

### 1.5 Create `scr_spawn_cop_from_car()` Function
- **File**: NEW — `scripts/scr_spawn_cop_from_car/scr_spawn_cop_from_car.gml`
- **Problem**: Called by random events (police raid, snitch spotted), obj_pedestrian, and obj_car but never defined — crashes if triggered
- **Fix**: Implement function that spawns a cop instance at a given position (similar to how scr_traffic_spawner creates cops)
- **Why first**: Multiple systems depend on this function existing. Without it, police raids, snitch events, and pedestrian witness mechanics all crash

---

## Phase 2: Jail Timer System (Core Punishment Loop)

*The arrest/jail system is the primary consequence for heat and criminal activity. Without a working timer, getting arrested is meaningless. This must work before random events (which spawn cops) or the duel system matter.*

### 2.1 Re-implement Jail Timer
- **Files**:
  - `objects/obj_game_controller/Step_0.gml` (lines 359-361, currently disabled)
  - `objects/obj_game_controller/Create_0.gml` (add timer variables if missing)
- **Task**: Create a real-time countdown system that:
  - Starts when `is_jailed` is set to true
  - Counts down based on `delta_time` or frame count
  - Automatically releases player when timer expires
  - Supports different durations (short for minor offenses, longer for drug charges)
- **Depends on**: Phase 1 fixes (game controller Draw_64 formatting)

### 2.2 Re-enable Jail Timer Display
- **Files**:
  - `objects/obj_game_controller/Draw_64.gml` (lines 49, 61-62, currently disabled)
  - `objects/player1/Draw_64.gml` (lines 197, 330, removed displays)
- **Task**: Show remaining jail time in HUD — format as days/hours/minutes
- **Depends on**: 2.1 (timer must exist before displaying it)

### 2.3 Wire Jail Exit to Timer
- **File**: `objects/obj_jail_exit/Step_0.gml`
- **Task**: Only allow exit when jail timer has expired (currently exits immediately on [E])
- **Depends on**: 2.1

### 2.4 Wire Arrest Script to Timer
- **File**: `scripts/scr_arrest_player/scr_arrest_player.gml`
- **Task**: Ensure each arrest scenario sets appropriate jail duration:
  - Scenario 1 (no drugs): Fine only, no jail
  - Scenario 2 (drugs, < $1000): 1 in-game week
  - Scenario 3 (drugs + $1000+): Longer sentence
- **Depends on**: 2.1

---

## Phase 3: Random Events Integration (World Feels Alive)

*The entire random events system is coded but never called. Activating it makes the game world dynamic. Must come after jail timer (events can lead to arrests) and after scr_spawn_cop_from_car exists (events use it).*

### 3.1 Add Random Event Trigger to Game Loop
- **File**: `objects/obj_game_controller/Step_0.gml`
- **Task**: Add periodic call to `scr_trigger_random_event()`:
  - Check every few in-game minutes (use `time_current` or frame counter)
  - Scale frequency with heat level (higher heat = more events)
  - Only trigger when `game_state == GAME_STATE.PLAYING` and player is not jailed
  - Add cooldown between events (prevent spam)
- **Depends on**: Phase 1.5 (scr_spawn_cop_from_car must exist), Phase 2 (jail timer for arrest outcomes)

### 3.2 Review and Polish Each Event Function
- **File**: `scripts/scr_random_events/scr_random_events.gml`
- **Tasks per event**:
  - **DRIVE_BY** (lines 90-125): Verify obj_driveby_car Step/Draw events work. Test spawning and AI behavior
  - **POLICE_RAID** (lines 128-136): Currently just spawns 2-3 cops. Add raid ending conditions (cops leave after X time if player escapes)
  - **SNITCH_SPOTTED** (lines 139-145): Currently just spawns undercover agent. Consider adding bribe/escape options
  - **BIG_BUYER** (lines 148-160): Verify `payment_multiplier` is respected by scr_make_sale. Add visual indicator so player knows this is a special customer
  - **TURF_WAR** (lines 163-173): Verify obj_rival_dealer works when spawned. Test combat
  - **SUPPLY_DROP** (lines 252-266): Fix reference to `drug_get_name(DRUG_TYPE.COCAINE)` — verify enum/function exists in scr_drug_prices, fix if not
- **Depends on**: 3.1 (triggering system must work first)

---

## Phase 4: Crew System Visibility (Make Workers Playable)

*The crew AI logic is mostly complete but players can't see or interact with it. Drawing and UI must come before any Phase 2 crew features.*

### 4.1 Create Crew Member Draw Event
- **File**: NEW — `objects/obj_crew_member/Draw_0.gml`
- **Task**: Render the worker sprite, name tag, and status indicator:
  - Draw sprite based on facing direction (use existing spr_player_walk_* sprites)
  - Draw name tag above head
  - Draw color-coded status: green (working), yellow (selling), purple (break), red (trouble)
- **Depends on**: Nothing — standalone visual fix

### 4.2 Create Crew Recruiter Draw Event
- **File**: NEW — `objects/obj_crew_recruiter/Draw_64.gml`
- **Task**: Render the recruitment dialog when recruiter is in "waiting" state:
  - Draw dialog box with worker stats (Sales Skill, Heat Mgmt, Loyalty, Stamina)
  - Show 3 options: [1] Hire Now ($500), [2] Test Run (FREE), [3] Reject
  - Show worker name and daily wage estimate
- **Depends on**: Nothing — standalone UI

### 4.3 Create Crew Recruiter Input Handling
- **File**: `objects/obj_crew_recruiter/Step_0.gml` (extend existing)
- **Task**: Add key press handling in "waiting" state:
  - [1] Hire: Deduct $500 from player, create obj_crew_member, add to player.crew_members[]
  - [2] Test Run: Create obj_crew_member with `is_test_run = true`, set expiration timer
  - [3] Reject: Set recruiter state to "rejected", walk away
- **Depends on**: 4.2 (dialog must be visible for input to make sense)

### 4.4 Create Crew Recruiter Sprite/Visual
- **File**: NEW — `objects/obj_crew_recruiter/Draw_0.gml`
- **Task**: Draw the recruiter NPC sprite so they're visible when approaching player
- **Depends on**: Nothing — standalone

### 4.5 Fix Crew HUD Display
- **File**: `objects/player1/Draw_64.gml`
- **Task**: Verify crew HUD (active workers count, daily earnings) displays correctly. Add earnings collection prompt when near worker: "[C] Collect $X"
- **Depends on**: 4.1 (workers must be visible)

### 4.6 Test Run Expiration Notification
- **File**: `objects/obj_crew_member/Step_0.gml` (lines 88-94)
- **Task**: Replace `show_debug_message()` with `scr_notify()` when test run expires. Show hire/fire prompt
- **Depends on**: 4.3 (hiring system must work)

---

## Phase 5: Duel & PVP System (Combat Loop)

*These are completely stubbed out. Implementing them unlocks the entire PVP side of gameplay. Must come after jail timer (duels can lead to death/arrest) and after random events (turf wars can trigger PVP).*

### 5.1 Implement scr_start_duel
- **File**: `scripts/scr_start_duel/scr_start_duel.gml`
- **Task**: Full duel initialization:
  - Save player's current room and position for return
  - Set `game_state = GAME_STATE.DUEL`
  - Set `player.in_duel = true`
  - Transition to `rm_duel`
  - Position both combatants
  - Reset duel_health for both fighters
  - Initialize duel UI (health bars, timer)
- **Depends on**: Phase 2 (jail timer, since losing a duel may lead to consequences)

### 5.2 Implement scr_end_duel
- **File**: `scripts/scr_end_duel/scr_end_duel.gml`
- **Task**: Duel resolution:
  - Determine winner (based on duel_health reaching 0)
  - Apply rewards/penalties (money, reputation)
  - Set `player.in_duel = false`
  - Restore `game_state = GAME_STATE.PLAYING`
  - Return player to previous room and position
  - Handle death if health reaches 0 (respawn system)
- **Depends on**: 5.1

### 5.3 Implement scr_start_pvp_encounter
- **File**: `scripts/scr_start_pvp_encounter/scr_start_pvp_encounter.gml`
- **Task**: PVP encounter initiation:
  - Triggered by territory disputes or rival dealer confrontation
  - Show encounter dialog (Fight / Talk / Run)
  - If fight chosen, call scr_start_duel
  - If talk, attempt negotiation (based on reputation)
  - If run, attempt escape (based on speed/stats)
- **Depends on**: 5.1, 5.2

### 5.4 Implement scr_resolve_pvp
- **File**: `scripts/scr_resolve_pvp/scr_resolve_pvp.gml`
- **Task**: PVP aftermath:
  - Territory changes based on outcome
  - Money/drug transfer from loser to winner
  - Heat level adjustments
  - Collaboration bonus activation (wire up the existing collab_bonus variables)
- **Depends on**: 5.3

### 5.5 Implement Rival Dealer [F] Fight Handler
- **File**: `objects/obj_rival_dealer/Step_0.gml`
- **Task**: Add `keyboard_check_pressed(ord("F"))` handler that calls scr_start_pvp_encounter
- **Depends on**: 5.3

---

## Phase 6: Phone System Activation (Information Hub)

*The phone is 85% built but unreachable. It serves as the player's information hub — messages from events, crew updates, contacts. Should activate after random events (which send phone messages) and crew system (which should also send messages).*

### 6.1 Initialize Phone System
- **File**: `objects/player1/Create_0.gml`
- **Task**: Ensure `phone_active = false` is properly initialized (verify it is). Add `phone_exists = false` if missing
- **Depends on**: Nothing

### 6.2 Wire Phone Hotkey
- **File**: `objects/player1/Step_0.gml`
- **Task**: Add working [P] key handler:
  - Create obj_phone_controller instance if not exists
  - Toggle phone_active
  - Freeze player movement while phone is open
  - Only allow when not jailed, not in duel, not in dialog
- **Depends on**: 6.1

### 6.3 Connect Systems to Phone Messages
- **Files**: Various
- **Task**: Add `phone_add_message()` calls to key events:
  - Crew member hired: "New worker joined your crew"
  - Crew member test run expired: "Trial period over for [name]"
  - Territory captured/lost: "You gained/lost territory at [location]"
  - Loan shark deadline approaching: "Payment due soon"
  - Heat level warnings: "Cops are onto you"
- **Depends on**: 6.2, Phase 4 (crew), Phase 3 (random events)

---

## Phase 7: Save/Load System (Persistence)

*Must come after most gameplay systems are functional — no point saving broken state. This is what makes the game replayable across sessions.*

### 7.1 Design Save Data Structure
- **File**: `scripts/scr_save_load/scr_save_load.gml`
- **Task**: Define what gets saved:
  - **Player**: money, health, inventory (all drug types), weapons_owned, weapon_type, heat_level, reputation
  - **Crew**: crew_unlocked, crew_members array (stats, names, levels, earnings)
  - **Progress**: current room, position, day_current, time_current, territories owned
  - **State flags**: is_snitch, snitch_timer, crew_unlocked
  - **Phone**: message inbox
- **Format**: Use `json_stringify()` / `json_parse()` for structured data, save to file
- **Depends on**: All gameplay systems being stable

### 7.2 Implement Save Function
- **File**: `scripts/scr_save_load/scr_save_load.gml`
- **Task**: `function scr_save_game()` — serialize all state to JSON, write to file
- **Depends on**: 7.1

### 7.3 Implement Load Function
- **File**: `scripts/scr_save_load/scr_save_load.gml`
- **Task**: `function scr_load_game()` — read file, parse JSON, restore all state
- **Depends on**: 7.1

### 7.4 Add Auto-Save
- **File**: `objects/obj_game_controller/Step_0.gml`
- **Task**: Auto-save at key moments:
  - End of each in-game day
  - Room transitions
  - After major events (arrest, crew hire, large sale)
- **Depends on**: 7.2

### 7.5 Add Save/Load to Menu
- **File**: `objects/obj_menu_controller/Step_0.gml`
- **Task**: Add Continue/New Game options that use save/load
- **Depends on**: 7.2, 7.3

---

## Phase 8: Dice Game Completion (Gambling Polish)

*The dice game is mostly functional but has 3 stubbed mechanics. Should come after the jail timer works (police bust sends player to jail).*

### 8.1 Implement Police Bust Mechanic
- **File**: `objects/obj_dice_game/Step_0.gml` (line 339)
- **Task**: Uncomment/implement inline police bust:
  - Scatter NPCs from dice game
  - Trigger arrest on player (call scr_arrest_player)
  - Confiscate gambling money
- **Depends on**: Phase 2 (jail timer)

### 8.2 Implement Shooter Advancement
- **File**: `objects/obj_dice_game/Step_0.gml` (line 420)
- **Task**: Implement inline next shooter logic:
  - Move shooter pointer to next player in circle
  - Handle case when shooter busts out (removed from game)
  - Reset dice for new shooter
- **Depends on**: Nothing (standalone dice mechanic)

### 8.3 Implement Dice Game Robbery
- **File**: `objects/obj_dice_game/Step_0.gml` (line 427)
- **Task**: Implement inline robbery mechanic:
  - Player grabs pot money and runs
  - NPCs react (flee or fight)
  - Increase heat level
  - Trigger gunshot panic if NPCs fight back
- **Depends on**: Phase 1.5 (scr_spawn_cop_from_car for witness response)

---

## Phase 9: Dealer Economy (Depth & Balance)

*Makes the economic game more interesting. Can be worked on independently but should come after core systems are stable.*

### 9.1 Activate Dealer Supply Network
- **Files**:
  - `objects/obj_dealer_stashHouse_low/Step_0.gml`
  - `objects/obj_dealer_stashHouse_mid/Step_0.gml`
  - `objects/obj_dealer_stashHouse_high/Step_0.gml`
- **Task**: Wire up `stash_amount`, `stash_max`, and `supply_network`:
  - Dealers check stash before selling (can run out)
  - High-tier restocks mid-tier, mid-tier restocks low-tier
  - Restocking happens on a timer (shipment system)
  - Prices adjust based on supply (low stock = higher prices)
- **Depends on**: Nothing (standalone economy improvement)

### 9.2 Chess Pawn Promotion
- **File**: `scripts/scr_chess_move/scr_chess_move.gml` (line 44)
- **Task**: Show promotion UI when pawn reaches end:
  - Display piece selection (Queen, Rook, Bishop, Knight)
  - Replace pawn with selected piece on board
  - Update AI to consider promotion
- **Depends on**: Nothing (standalone chess fix)

### 9.3 NPC Gambling Integration
- **Files**:
  - `objects/obj_npc_customer/Step_0.gml` (lines 235-262)
  - `objects/obj_npc_customer/Create_0.gml`
- **Task**: Wire the "gambling" state so NPCs actually join dice games:
  - Add transition from "wander" to "gambling" when near obj_dice_game
  - NPCs place bets using their `money` variable
  - NPCs leave when they run out of money or randomly
- **Depends on**: Phase 8 (dice game must be complete)

---

## Phase 10: Loan Shark System (Risk/Reward Mechanic)

*Adds financial pressure and decision-making. Requires jail timer (debt can lead to jail) and save/load (loans persist across sessions).*

### 10.1 Implement Loan Dialog UI
- **File**: `objects/obj_loan_shark/Draw_64.gml` (create or extend)
- **Task**: Render loan offer dialog:
  - Show available loan amounts ($500, $1000, $2500, $5000)
  - Show interest rate and repayment deadline
  - Show current debt if any
  - Input handling for accept/decline
- **Depends on**: Phase 1.1 (variable name fix)

### 10.2 Implement Debt Tracking
- **File**: `objects/player1/Create_0.gml` + `objects/obj_loan_shark/Step_0.gml`
- **Task**: Track active loans:
  - `player.debt` amount
  - `player.loan_due_day` deadline
  - Daily interest accumulation
  - Auto-send debt collector when overdue (obj_debt_collector)
- **Depends on**: 10.1, Phase 2 (day system for due dates)

### 10.3 Wire Debt Consequences
- **File**: `objects/obj_game_controller/Step_0.gml`
- **Task**: Check debt status each day:
  - Warning at 75% of deadline
  - Debt collector spawns when overdue
  - Auto-jail if debt exceeds $500 (already referenced in Draw_64 warning)
- **Depends on**: 10.2, Phase 2 (jail timer)

---

## Phase 11: City Travel & Casino (World Expansion)

*These systems work partially but have bugs and hardcoded values.*

### 11.1 Fix Casino Exit Globals
- **Files**:
  - `objects/obj_game_controller/Create_0.gml` — initialize `global.casino_return_x/y`
  - `objects/obj_casino_exit/Step_0.gml` — verify `game_ctrl.last_visited_room` exists
- **Task**: Initialize all required globals so casino transitions don't crash
- **Depends on**: Nothing

### 11.2 Improve City Travel Scalability
- **File**: `objects/obj_city_exit/Create_0.gml`
- **Task**: Replace hardcoded Seattle/LA room checks with a data-driven approach:
  - Use a lookup table or switch statement that's easy to extend
  - Support adding new cities without code changes to the exit object
- **Depends on**: Nothing (standalone improvement)

---

## Phase 12: Crew System Phase 2 (Advanced Workers)

*Builds on the functional crew from Phase 4. Requires crew visibility and hiring to work first.*

### 12.1 Territory Assignment System
- **File**: `objects/obj_crew_member/Step_0.gml`
- **Task**: Workers stay within assigned territory:
  - Player assigns territory via management UI
  - Worker roaming bounded to territory area
  - Workers return to territory if they drift
- **Depends on**: Phase 4 (crew must be visible/hireable)

### 12.2 Wage Deduction System
- **File**: `objects/obj_game_controller/Step_0.gml`
- **Task**: At end of each in-game day:
  - Deduct each worker's daily_wage from player money
  - If player can't afford wages, workers become disloyal
  - Notification via scr_notify
- **Depends on**: Phase 4

### 12.3 Drug Re-supply Mechanic
- **File**: `objects/obj_crew_member/Step_0.gml`
- **Task**: Workers consume drugs from player inventory when selling:
  - Track worker drug inventory
  - Workers request re-supply when empty
  - Player must manually re-supply or set auto-supply
- **Depends on**: Phase 4

### 12.4 Crew Management Menu
- **File**: NEW — extend player1/Step_0.gml or create obj_crew_menu
- **Task**: Menu accessed via key press showing:
  - All workers with stats, earnings, loyalty
  - Assign/reassign territory
  - Fire worker
  - View daily profit/loss breakdown
- **Depends on**: 12.1, 12.2

### 12.5 NPC Follow Worker State
- **File**: `objects/obj_npc_customer/Step_0.gml`
- **Task**: Implement the `"follow_worker"` state that scr_make_sale sets:
  - NPC walks toward `target_worker`
  - When in range, worker handles the sale
  - If worker is unavailable, NPC returns to wander
- **Depends on**: Phase 4 (workers must be functional)

---

## Phase 13: Casino Games (Content Expansion)

*4 gambling tables are placeholder-only. Lower priority since chess, craps, and spades already work.*

### 13.1 Blackjack Table
- **Files**: `objects/obj_blackjack_table/`
- **Task**: Full blackjack implementation:
  - Card deck, deal, hit/stand/double/split
  - Dealer AI (hit on 16, stand on 17)
  - Betting system with player money
  - Visual card display

### 13.2 Texas Hold'em Table
- **Files**: `objects/obj_holdem_table/`
- **Task**: Simplified poker:
  - 2-4 NPC opponents
  - Betting rounds (pre-flop, flop, turn, river)
  - Hand evaluation
  - AI bluffing/folding logic

### 13.3 Baccarat Table
- **Files**: `objects/obj_baccarat_table/`
- **Task**: Standard baccarat rules:
  - Player/Banker/Tie betting
  - Card dealing and natural win detection
  - Third card rules

### 13.4 Slot Machine
- **Files**: `objects/obj_slot_machine/`
- **Task**: Slot machine:
  - Spinning reel animation
  - Symbol matching and payout table
  - Bet amount selection
  - Jackpot mechanic

---

## Phase 14: Pedestrian & Witness Polish

### 14.1 Pedestrian Draw Event
- **File**: NEW — `objects/obj_pedestrian/Draw_0.gml`
- **Task**: Render pedestrian sprites so witnesses are visible
- **Depends on**: Phase 1.5 (scr_spawn_cop_from_car for witness cop-calling)

### 14.2 Civilian Car Sprites
- **File**: `objects/obj_car/Draw_0.gml`
- **Task**: Replace colored rectangle placeholders with proper car sprites
- **Depends on**: Art assets being available

### 14.3 Snitch Reputation Progression
- **File**: `objects/player1/Step_0.gml` or `objects/obj_game_controller/Step_0.gml`
- **Task**: Wire up `snitch_level` progression:
  - Timer counts up while player is snitch
  - Level increases every `snitch_level_duration` frames
  - `snitch_flee_chances` array reduces customer flee rate as level increases
  - Verify NPC customer code checks `snitch_flee_chances[snitch_level]`
- **Depends on**: Nothing (standalone system)

---

## Phase 15: Crew System Phase 3 (Risk & Consequences)

*Final crew features adding danger and unpredictability. Requires all previous crew phases.*

### 15.1 Worker Arrest System
- **Task**: Cops can arrest crew members:
  - Workers near cops with high heat get arrested
  - Arrested workers go to "jail" state (unavailable)
  - Player can pay bail to release
- **Depends on**: Phase 4, Phase 12

### 15.2 Loyalty & Betrayal
- **Task**: Low loyalty workers can:
  - Steal earnings before player collects
  - Snitch to police (increase player heat)
  - Desert (leave crew permanently)
  - Loyalty affected by: wages paid, time employed, player reputation
- **Depends on**: Phase 12.2 (wage system)

### 15.3 Worker Flee State
- **File**: `objects/obj_crew_member/Step_0.gml` (lines 270-272)
- **Task**: Implement fleeing from cops:
  - Detect nearby cop instances
  - Run in opposite direction
  - Return to roaming when safe
- **Depends on**: Phase 4

### 15.4 Worker Return State
- **File**: `objects/obj_crew_member/Step_0.gml` (lines 274-276)
- **Task**: Workers return to trap house to drop off money:
  - Navigate to assigned trap house
  - Deposit earnings
  - Return to roaming
- **Depends on**: Phase 12.1 (territory assignment)

---

## Quick Reference: Dependency Graph

```
Phase 1 (Bug Fixes)
  |
  +---> Phase 2 (Jail Timer)
  |       |
  |       +---> Phase 3 (Random Events)
  |       |       |
  |       |       +---> Phase 6 (Phone System)
  |       |
  |       +---> Phase 5 (Duel/PVP)
  |       |
  |       +---> Phase 8 (Dice Game)
  |       |
  |       +---> Phase 10 (Loan Shark)
  |
  +---> Phase 4 (Crew Visibility) ----+
          |                            |
          +---> Phase 12 (Crew Ph.2)   |
          |       |                    |
          |       +---> Phase 15       |
          |             (Crew Ph.3)    |
          |                            |
          +---> Phase 9.3 (NPC        |
                  Gambling)            |

  Phase 7 (Save/Load) --- depends on most systems being stable
  Phase 9 (Economy) ----- standalone, work anytime
  Phase 11 (Travel) ----- standalone, work anytime
  Phase 13 (Casino) ----- standalone, lowest priority
  Phase 14 (Polish) ----- standalone, work anytime
```

---

## Estimated Scope per Phase

| Phase | Description | Scope | Priority |
|-------|-------------|-------|----------|
| 1 | Critical Bug Fixes | ~1 hour | Immediate |
| 2 | Jail Timer | ~2 hours | Immediate |
| 3 | Random Events | ~2-3 hours | High |
| 4 | Crew Visibility | ~3-4 hours | High |
| 5 | Duel/PVP System | ~4-6 hours | High |
| 6 | Phone System | ~1-2 hours | Medium |
| 7 | Save/Load | ~3-4 hours | Medium |
| 8 | Dice Game | ~2 hours | Medium |
| 9 | Dealer Economy | ~3-4 hours | Medium |
| 10 | Loan Shark | ~2-3 hours | Medium |
| 11 | Travel & Casino Fix | ~1 hour | Low |
| 12 | Crew Phase 2 | ~4-6 hours | Low |
| 13 | Casino Games | ~8-12 hours | Low |
| 14 | Visual Polish | ~2-3 hours | Low |
| 15 | Crew Phase 3 | ~4-6 hours | Low |
