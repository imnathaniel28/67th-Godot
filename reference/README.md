# 67th Street - GameMaker Reference Files

Source of truth for porting features from the GameMaker master project to Godot.
These files are READ-ONLY reference — do not edit them.

---

## docs/

| File | Contents |
|------|----------|
| `CLAUDE.md` | Full feature overview, all systems, room structure, technical notes |
| `IMPLEMENTATION_PLAN.md` | 15-phase porting roadmap with dependencies |
| `CREW_SYSTEM.md` | Crew/gang AI, recruitment, wages, leveling |
| `TERRITORY_SYSTEM.md` | Territory control mechanics |
| `CRIME_AND_COP_SYSTEM.md` | Cop AI, heat system, arrest mechanics |
| `CRIME_SYSTEM_QUICK_REFERENCE.md` | Quick lookup: heat values, outcomes |

---

## gml/scripts/

Core game logic scripts — port these to Godot autoloads or systems:

| GML Script | Godot Target |
|------------|-------------|
| `scr_arrest_player.gml` | `scripts/systems/ArrestSystem.gd` |
| `scr_make_sale.gml` | `autoloads/EconomyManager.gd` |
| `scr_save_load.gml` | `autoloads/SaveSystem.gd` |
| `scr_random_events.gml` | new: `scripts/systems/RandomEvents.gd` |
| `scr_territory_system.gml` | new: `scripts/systems/TerritorySystem.gd` |
| `scr_start_duel.gml` | new: `scripts/systems/DuelSystem.gd` |
| `scr_end_duel.gml` | new: `scripts/systems/DuelSystem.gd` |
| `scr_start_pvp_encounter.gml` | new: `scripts/systems/DuelSystem.gd` |
| `scr_resolve_pvp.gml` | new: `scripts/systems/DuelSystem.gd` |
| `scr_drug_prices.gml` | `autoloads/EconomyManager.gd` |
| `scr_notify.gml` | `autoloads/NotificationBus.gd` |
| `scr_seamless_travel.gml` | new: room transition system |
| `scr_traffic_spawner.gml` | new: NPC spawner system |

---

## gml/objects/

Object event scripts — port these to Godot scene scripts:

| GML Object | Godot Target |
|------------|-------------|
| `player1/` | `scripts/player/Player.gd` |
| `obj_cop/` | `scripts/npcs/NPC_Cop.gd` |
| `obj_npc_customer/` | `scripts/npcs/NPC_Customer.gd` |
| `obj_undercover_agent/` | new NPC script |
| `obj_game_controller/` | `autoloads/GameState.gd` + `EconomyManager.gd` |
| `obj_territory_controller/` | new: TerritorySystem |
| `obj_crew_member/` | new: crew NPC script |
| `obj_crew_recruiter/` | new: crew NPC script |
| `obj_shipment_walker/` | new: shipment NPC script |
| `obj_dice_game/` | new: dice game scene |
| `obj_loan_shark/` | new: loan shark NPC |
| `obj_rival_dealer/` | new: rival NPC |
| `obj_jail_exit/` | part of JailSystem |
