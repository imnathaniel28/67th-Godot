extends "res://scripts/npcs/NPC_Base.gd"
## NPC_Cop — server-side police AI.
## Replaces obj_cop/Create_0.gml + Step_0.gml.
## Roams scene, detects players with heat > 0, chases, arrests.

# ─── State machine ────────────────────────────────────────────────────────────────
enum State { ROAMING, CHASING, STUNNED, RETURNING }

var state: State = State.ROAMING

# ─── Config ───────────────────────────────────────────────────────────────────────
const CHASE_SPEED_MULT      := 1.5
const BASE_DETECTION_RANGE  := 100.0
const ARREST_RANGE          := 20.0
const CHASE_FORGET_TIME     := 5.0   # seconds before cop gives up chase

# ─── State vars ──────────────────────────────────────────────────────────────────
var target_peer_id:    int   = -1
var detection_range:   float = BASE_DETECTION_RANGE
var lost_sight_timer:  float = 0.0
var stunned_timer:     float = 0.0
var lifetime:          float = 0.0     # Cops despawn after their lifetime expires

# Roam vars
var _roam_direction:   float = 0.0
var _roam_timer:       float = 0.0
const ROAM_SPEED_MULT := 0.6


func _ready() -> void:
	super._ready()
	npc_type = "cop"

	# Random lifetime: 10-30 seconds
	lifetime         = randf_range(10.0, 30.0)
	_roam_direction  = randf() * TAU
	_roam_timer      = randf_range(1.0, 3.0)
	move_speed       = 100.0   # Slightly faster than player walk


func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return

	# ── Lifetime countdown ──
	if state != State.RETURNING:
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()
			return

	# ── Stun ──
	if stunned_timer > 0.0:
		stunned_timer -= delta
		return

	if state == State.STUNNED:
		state = State.ROAMING

	# ── Dynamic detection range (scales with player heat) ──
	_update_detection_range()

	match state:
		State.ROAMING:
			_handle_roam(delta)
			_scan_for_players()
		State.CHASING:
			_handle_chase(delta)


# ─── State handlers ────────────────────────────────────────────────────────────────

func _handle_roam(delta: float) -> void:
	_roam_timer -= delta
	if _roam_timer <= 0.0:
		_roam_direction = randf() * TAU
		_roam_timer     = randf_range(1.5, 4.0)

	var new_pos := pos + Vector2(cos(_roam_direction), sin(_roam_direction)) * move_speed * ROAM_SPEED_MULT * delta
	pos = apply_sidewalk_constraint(new_pos)


func _scan_for_players() -> void:
	for data in PlayerRegistry.all_players():
		if data.is_jailed or data.current_scene != home_scene:
			continue
		if data.heat_level <= 0:
			continue

		var dist := pos.distance_to(data.position)
		if dist <= detection_range:
			target_peer_id = data.peer_id
			state          = State.CHASING
			lost_sight_timer = CHASE_FORGET_TIME
			NotificationBus.notify_player(data.peer_id, "Five-O! Run!", Color.RED)
			return


func _handle_chase(delta: float) -> void:
	if target_peer_id < 0:
		state = State.ROAMING
		return

	var target_data := PlayerRegistry.get_player(target_peer_id)
	if target_data == null or target_data.is_jailed or target_data.current_scene != home_scene:
		state          = State.ROAMING
		target_peer_id = -1
		return

	var dist := pos.distance_to(target_data.position)

	if dist > detection_range * 2.0:
		# Out of extended range — countdown to giving up
		lost_sight_timer -= delta
		if lost_sight_timer <= 0.0:
			state          = State.ROAMING
			target_peer_id = -1
			return
	else:
		lost_sight_timer = CHASE_FORGET_TIME

	if dist <= ARREST_RANGE:
		# Arrest the player
		ArrestSystem.arrest_player(target_peer_id)
		state          = State.ROAMING
		target_peer_id = -1
		return

	# Move toward player
	pos += pos.direction_to(target_data.position) * move_speed * CHASE_SPEED_MULT * delta


# ─── Helpers ───────────────────────────────────────────────────────────────────────

func _update_detection_range() -> void:
	var max_heat := 0.0
	for data in PlayerRegistry.all_players():
		if data.current_scene == home_scene:
			max_heat = maxf(max_heat, data.heat_level)
	detection_range = BASE_DETECTION_RANGE + max_heat * 0.5


func stun(duration: float) -> void:
	## Called when player fights back (escape mechanic)
	state         = State.STUNNED
	stunned_timer = duration
