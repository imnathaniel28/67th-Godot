extends "res://scripts/npcs/NPC_Base.gd"
## NPC_Customer — server-side wandering customer AI.
## Replaces obj_npc_customer/Create_0.gml + Step_0.gml.
## Wanders sidewalks, detects nearby players who have stock, approaches, buys.
## Obeys crosswalk rules: only crosses street at designated crosswalk zones.

# ─── State machine ───────────────────────────────────────────────────────────────
enum State { WANDER, FOLLOW, CROSSING, WAITING, LEAVING, FLEE }

var state:            State  = State.WANDER
var wanted_drug:      int    = 0   # EconomyManager.DrugType
var payment_amount:   int    = 0

var target_peer_id:   int    = -1
var wander_direction: float  = 0.0
var wander_timer:     float  = 0.0

# Crosswalk navigation (mirrors GML crossing variables)
var is_crossing:              bool   = false
var crossing_phase:           String = "none"   # "approach" | "crossing"
var crossing_destination_y:   float  = 0.0
var target_crosswalk_center_x: float = 0.0

# Flee / gunshot panic
var flee_direction:   float  = 0.0
var flee_until_time:  float  = 0.0

# Speech bubble (relayed to client for display)
var show_speech:      bool   = false
var speech_text:      String = ""
var speech_timer:     float  = 0.0
const SPEECH_DURATION := 2.0

const DETECTION_RADIUS  := 175.0
const FOLLOW_SPEED_MULT := 1.0
const CROSS_SPEED_MULT  := 1.5
const WANDER_SPEED_MULT := 0.7
const SALE_RANGE        := 24.0
const LEAVE_SPEED_MULT  := 2.0


func _ready() -> void:
	super._ready()
	npc_type = "customer"

	# Randomize wanted drug
	wanted_drug    = randi() % 5
	payment_amount = EconomyManager.get_customer_payment(wanted_drug)
	speech_text    = _make_speech_text()

	# Initial wander
	wander_direction = randf() * TAU
	wander_timer     = randf_range(1.0, 3.0)

	# Random spawn position on a sidewalk (server places this NPC)
	# pos is set by NPCSpawner before _ready


func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return

	_tick_speech(delta)

	# ── Crosswalk navigation overrides state machine ──
	if is_crossing:
		_handle_crossing(delta)
		return

	match state:
		State.WANDER:   _handle_wander(delta)
		State.FOLLOW:   _handle_follow(delta)
		State.LEAVING:  _handle_leaving(delta)
		State.FLEE:     _handle_flee(delta)
		State.WAITING:  pass   # Transaction in progress


# ─── State handlers ───────────────────────────────────────────────────────────────

func _handle_wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_direction = randf() * TAU
		wander_timer     = randf_range(1.5, 4.0)

	var new_pos := pos + Vector2(cos(wander_direction), sin(wander_direction)) * (move_speed * WANDER_SPEED_MULT) * delta
	pos = apply_sidewalk_constraint(new_pos)

	# Scan for nearby player with stock
	var target_data := get_nearest_player_in_scene(DETECTION_RADIUS)
	if target_data and _player_has_drug(target_data, wanted_drug):
		target_peer_id = target_data.peer_id
		state          = State.FOLLOW
		_show_speech_bubble()


func _handle_follow(delta: float) -> void:
	if target_peer_id < 0:
		state = State.WANDER
		return

	var target_data := PlayerRegistry.get_player(target_peer_id)
	if target_data == null or target_data.is_jailed or target_data.current_scene != home_scene:
		state          = State.WANDER
		target_peer_id = -1
		return

	# Check if we need to cross the street to reach the player
	if _needs_to_cross(target_data.position.y) and not is_crossing:
		_initiate_crossing(target_data.position.y)
		return

	var dist := pos.distance_to(target_data.position)

	if dist <= SALE_RANGE:
		# ── Execute sale ──
		state = State.WAITING
		var result := EconomyManager.process_sale(target_peer_id, wanted_drug)
		if result["success"]:
			NotificationBus.show_sale_popup(target_peer_id,
				result["amount"],
				EconomyManager.get_drug_name(wanted_drug),
				target_data.position.x, target_data.position.y - 32)
		# Leave regardless of sale success
		flee_direction = pos.angle_to_point(target_data.position) + PI
		state          = State.LEAVING
	else:
		# Move toward player
		var new_pos := pos + pos.direction_to(target_data.position) * move_speed * FOLLOW_SPEED_MULT * delta
		pos = apply_sidewalk_constraint(new_pos)


func _handle_leaving(delta: float) -> void:
	pos += Vector2(cos(flee_direction), sin(flee_direction)) * move_speed * LEAVE_SPEED_MULT * delta
	# Despawn when far off any player's screen (~200px boundary)
	if not _any_player_nearby(300.0):
		queue_free()


func _handle_flee(delta: float) -> void:
	## Gunshot panic — run away fast, then resume wandering
	if GameState.time_elapsed >= flee_until_time:
		state        = State.WANDER
		wander_timer = randf_range(1.0, 2.0)
		return

	pos += Vector2(cos(flee_direction), sin(flee_direction)) * move_speed * 2.5 * delta


# ─── Crosswalk navigation (mirrors GML crossing state machine) ────────────────────

func _needs_to_cross(target_y: float) -> bool:
	var on_top    := pos.y < GameState.STREET_Y_TOP
	var tgt_top   := target_y < GameState.STREET_Y_TOP
	return on_top != tgt_top


func _initiate_crossing(destination_y: float) -> void:
	var cw := find_nearest_crosswalk(pos)
	if cw.is_empty():
		return
	is_crossing              = true
	crossing_destination_y   = destination_y
	target_crosswalk_center_x = cw["center_x"]
	crossing_phase           = "approach" if not is_in_crosswalk(pos) else "crossing"


func _handle_crossing(delta: float) -> void:
	match crossing_phase:
		"approach":
			var dx := target_crosswalk_center_x - pos.x
			if abs(dx) <= 3.0:
				crossing_phase = "crossing"
			else:
				pos.x += sign(dx) * move_speed * delta

		"crossing":
			pos.x = target_crosswalk_center_x   # Stay in crosswalk column
			var dy := crossing_destination_y - pos.y
			var step := move_speed * CROSS_SPEED_MULT * delta
			if abs(dy) <= step:
				pos.y        = crossing_destination_y
				is_crossing  = false
				crossing_phase = "none"
			else:
				pos.y += sign(dy) * step


# ─── Helpers ─────────────────────────────────────────────────────────────────────

func _player_has_drug(data: PlayerRegistry.PlayerData, drug: int) -> bool:
	match drug:
		EconomyManager.DrugType.WEED:    return data.inv_weed    > 0
		EconomyManager.DrugType.PILLS:   return data.inv_pills   > 0
		EconomyManager.DrugType.COCAINE: return data.inv_cocaine > 0
		EconomyManager.DrugType.HEROIN:  return data.inv_heroin  > 0
		EconomyManager.DrugType.METH:    return data.inv_meth    > 0
	return false


func _any_player_nearby(radius: float) -> bool:
	for data in PlayerRegistry.all_players():
		if data.current_scene == home_scene and pos.distance_to(data.position) < radius:
			return true
	return false


func _make_speech_text() -> String:
	var texts := [
		"Psst, you holding?",
		"Need some %s",
		"Got %s?",
		"Hook me up",
		"You got work?"
	]
	var t := texts[randi() % texts.size()]
	return t % [EconomyManager.get_drug_name(wanted_drug)] if t.contains("%s") else t


func _show_speech_bubble() -> void:
	show_speech  = true
	speech_timer = SPEECH_DURATION
	# Tell clients to show speech bubble on this NPC's ghost
	_rpc_show_speech.rpc(npc_id, speech_text)


func _tick_speech(delta: float) -> void:
	if show_speech:
		speech_timer -= delta
		if speech_timer <= 0.0:
			show_speech = false
			_rpc_hide_speech.rpc(npc_id)


func trigger_gunshot_flee(origin: Vector2) -> void:
	## Called by ArrestSystem or combat when a shot is fired nearby
	state          = State.FLEE
	flee_direction = origin.angle_to_point(pos)  # Run away from shot
	flee_until_time = GameState.time_elapsed + randf_range(8.0, 15.0)


@rpc("authority", "call_remote", "reliable")
func _rpc_show_speech(id: int, text: String) -> void:
	var ghost := _find_ghost(id)
	if ghost and ghost.has_method("show_speech_bubble"):
		ghost.show_speech_bubble(text)


@rpc("authority", "call_remote", "reliable")
func _rpc_hide_speech(id: int) -> void:
	var ghost := _find_ghost(id)
	if ghost and ghost.has_method("hide_speech_bubble"):
		ghost.hide_speech_bubble()
