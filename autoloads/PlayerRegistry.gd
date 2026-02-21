extends Node
## PlayerRegistry — single source of truth for ALL player state.
## Replaces every global.travel_* variable and all player1 instance variables from GML.
## On server: one PlayerData per connected peer (full state).
## On client: only local player's PlayerData is fully populated.


# ═══════════════════════════════════════════════════════════════════════════════
# PlayerData — mirrors player1/Create_0.gml variable list
# ═══════════════════════════════════════════════════════════════════════════════
class PlayerData:
	# ── Identity ──────────────────────────────────────────────────────────────
	var peer_id:       int    = 0
	var display_name:  String = "Player"
	var current_scene: String = "Seattle"
	var position:      Vector2 = Vector2(600, 500)
	var facing:        String = "down"

	# ── Core Stats (server-authoritative — clients never write these directly) ─
	var money:           int   = 99999
	var health:          float = 100.0
	var max_health:      float = 100.0
	var heat_level:      float = 0.0
	var last_crime_time: float = 0.0

	# ── Inventory ─────────────────────────────────────────────────────────────
	var inv_weed:      int = 0
	var inv_cocaine:   int = 0
	var inv_heroin:    int = 0
	var inv_meth:      int = 0
	var inv_pills:     int = 0
	var commissary_food: int = 0

	# ── Weapons ───────────────────────────────────────────────────────────────
	var weapon_type:   int  = 0        # 0=fists 1=pistol 2=smg 3=shotgun
	var has_gun:       bool = false
	var weapon_drawn:  bool = false
	var weapons_owned: Array = [true, false, false, false]

	# ── Car ───────────────────────────────────────────────────────────────────
	var owned_car:   int   = -1        # -1=none 0=Beater 1=Sedan 2=Sports 3=Jeep
	var in_car:      bool  = false
	var car_heading: float = 0.0
	var car_speed:   float = 0.0

	# ── Loan System (mirrors GML loan variables) ───────────────────────────────
	var has_active_loan:       bool = false
	var loan_amount:           int  = 0
	var loan_original_amount:  int  = 0
	var loan_due_day:          int  = 0
	var loan_days_overdue:     int  = 0
	var loan_threat_level:     int  = 0
	var loan_total_paid:       int  = 0
	var loan_collectors_sent:  int  = 0
	var loan_last_interest_day: int = 0
	var loan_rep_with_shark:   int  = 0
	var debt:                  int  = 0

	# ── Territory ─────────────────────────────────────────────────────────────
	var has_territory:   bool   = false
	var territory_x:     int    = -1
	var territory_y:     int    = -1
	var territory_color: Color  = Color.WHITE
	var territory_name:  String = ""

	# ── Crew/Gang ─────────────────────────────────────────────────────────────
	var crew_unlocked:       bool  = false
	var total_crew_earnings: int   = 0
	var crew_member_ids:     Array = []  # NPC node IDs managed by server

	# ── Status Flags ──────────────────────────────────────────────────────────
	var is_jailed:    bool   = false
	var jail_timer:   float  = 0.0
	var jail_sentence: float = 0.0
	var is_bleeding:  bool   = false
	var bleed_source: String = ""
	var is_snitch:    bool   = false
	var snitch_timer: float  = 0.0
	var snitch_level: int    = 0

	# ── Customization ─────────────────────────────────────────────────────────
	var skin_tone:     int = 0
	var bandana_color: int = 0

	# ── Earned totals (for crew unlock threshold) ──────────────────────────────
	var total_money_earned: int = 0


	func get_total_drugs() -> int:
		return inv_weed + inv_cocaine + inv_heroin + inv_meth + inv_pills


	func get_inventory_array() -> Array:
		return [inv_weed, inv_pills, inv_cocaine, inv_heroin, inv_meth]


	func apply_inventory_array(arr: Array) -> void:
		if arr.size() >= 5:
			inv_weed    = arr[0]
			inv_pills   = arr[1]
			inv_cocaine = arr[2]
			inv_heroin  = arr[3]
			inv_meth    = arr[4]


# ═══════════════════════════════════════════════════════════════════════════════
# Registry
# ═══════════════════════════════════════════════════════════════════════════════
var _players: Dictionary = {}   # peer_id → PlayerData


func register_player(peer_id: int) -> void:
	if _players.has(peer_id):
		return
	var data        := PlayerData.new()
	data.peer_id    = peer_id
	_players[peer_id] = data
	print("PlayerRegistry: registered peer ", peer_id)


func unregister_player(peer_id: int) -> void:
	_players.erase(peer_id)
	print("PlayerRegistry: unregistered peer ", peer_id)


func get_player(peer_id: int) -> PlayerData:
	return _players.get(peer_id, null)


func get_local_player() -> PlayerData:
	return get_player(multiplayer.get_unique_id())


func all_player_ids() -> Array:
	return _players.keys()


func all_players() -> Array:
	return _players.values()


# ─── Server-side stat mutation ───────────────────────────────────────────────────

func add_money(peer_id: int, amount: int) -> void:
	var data := get_player(peer_id)
	if data:
		data.money += amount
		if amount > 0:
			data.total_money_earned += amount
		# Check crew unlock threshold
		if data.total_money_earned >= 100_000 and not data.crew_unlocked:
			data.crew_unlocked = true
			NotificationBus.notify_player(peer_id,
				"Crew system unlocked! Press [C] to manage.", Color.GOLD)


func take_damage(peer_id: int, amount: float) -> void:
	var data := get_player(peer_id)
	if not data or data.is_jailed:
		return
	data.health = maxf(0.0, data.health - amount)
	if data.health <= 0.0:
		_handle_player_death(peer_id, data)


func _handle_player_death(peer_id: int, data: PlayerData) -> void:
	## Mirrors GML player1/Step_0.gml death block
	data.health = data.max_health
	data.position = Vector2(600, 500)
	data.money = maxi(0, data.money - 50)
	# Lose 50% of all drugs
	data.inv_weed    = data.inv_weed    / 2
	data.inv_cocaine = data.inv_cocaine / 2
	data.inv_heroin  = data.inv_heroin  / 2
	data.inv_meth    = data.inv_meth    / 2
	data.inv_pills   = data.inv_pills   / 2

	NotificationBus.notify_player(peer_id, "You died! Lost $50 and half your stash.", Color.RED)
	_rpc_force_respawn.rpc_id(peer_id, data.position.x, data.position.y, data.health)


@rpc("authority", "call_remote", "reliable")
func _rpc_force_respawn(x: float, y: float, hp: float) -> void:
	var local := get_local_player()
	if local:
		local.position = Vector2(x, y)
		local.health   = hp


# ─── Save/Load integration ───────────────────────────────────────────────────────

func apply_save_data(peer_id: int, save_dict: Dictionary) -> void:
	var data := get_player(peer_id)
	if data == null or not save_dict.has("player"):
		return

	var p: Dictionary = save_dict["player"]

	data.money           = p.get("money",           data.money)
	data.health          = p.get("health",           data.health)
	data.heat_level      = p.get("heat_level",       data.heat_level)
	data.inv_weed        = p.get("inv_weed",         0)
	data.inv_cocaine     = p.get("inv_cocaine",      0)
	data.inv_heroin      = p.get("inv_heroin",       0)
	data.inv_meth        = p.get("inv_meth",         0)
	data.inv_pills       = p.get("inv_pills",        0)
	data.commissary_food = p.get("commissary_food",  0)
	data.weapon_type     = p.get("weapon_type",      0)
	data.has_gun         = p.get("has_gun",          false)
	data.weapons_owned   = p.get("weapons_owned",    [true, false, false, false])
	data.owned_car       = p.get("owned_car",        -1)

	# Loan system
	data.has_active_loan       = p.get("has_active_loan",       false)
	data.loan_amount           = p.get("loan_amount",           0)
	data.loan_original_amount  = p.get("loan_original_amount",  0)
	data.loan_due_day          = p.get("loan_due_day",          0)
	data.loan_days_overdue     = p.get("loan_days_overdue",     0)
	data.loan_threat_level     = p.get("loan_threat_level",     0)
	data.loan_total_paid       = p.get("loan_total_paid",       0)
	data.loan_collectors_sent  = p.get("loan_collectors_sent",  0)
	data.loan_last_interest_day = p.get("loan_last_interest_day", 0)
	data.loan_rep_with_shark   = p.get("loan_rep_with_shark",   0)
	data.debt                  = p.get("debt",                  0)

	# Territory
	data.has_territory  = p.get("has_territory",  false)
	data.territory_x    = p.get("territory_x",    -1)
	data.territory_y    = p.get("territory_y",    -1)
	data.territory_name = p.get("territory_name", "")
	var tc_str: String  = p.get("territory_color", "#ffffff")
	data.territory_color = Color(tc_str)

	# Crew
	data.crew_unlocked       = p.get("crew_unlocked",       false)
	data.total_crew_earnings = p.get("total_crew_earnings", 0)
	data.total_money_earned  = p.get("total_money_earned",  0)

	# Status
	data.is_snitch    = p.get("is_snitch",    false)
	data.is_bleeding  = p.get("is_bleeding",  false)
	data.bleed_source = p.get("bleed_source", "")

	# Customization
	data.skin_tone     = p.get("skin_tone",     0)
	data.bandana_color = p.get("bandana_color", 0)

	# Position / scene
	data.current_scene = p.get("current_scene", "Seattle")
	data.position      = Vector2(p.get("position_x", 600.0), p.get("position_y", 500.0))

	# World time (only applied once, from the first player's save)
	if save_dict.has("world"):
		var w: Dictionary = save_dict["world"]
		if multiplayer.is_server():
			GameState.time_elapsed  = float(w.get("time_elapsed",  0.0))
			GameState.day_current   = int(w.get("day_current",   1))
			GameState.week_current  = int(w.get("week_current",  1))
