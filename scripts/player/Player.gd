extends CharacterBody2D
## Player — client-side movement with server position validation.
## One instance per connected peer, spawned in each scene.
## Local player: processes input, moves optimistically, reports to server.
## Remote players: rendered from server-broadcast position (ghost).
##
## Replaces: player1/Create_0.gml, player1/Step_0.gml, player1/Draw_0.gml

# ─── Config ──────────────────────────────────────────────────────────────────────
const WALK_SPEED       := 90.0   # pixels/sec (GML move_speed=1.5 × 60fps)
const HEALTH_REGEN_DELAY := 3.0  # seconds between regen ticks (GML: 180 frames)
const HEALTH_REGEN_AMOUNT := 1.0
const HEAT_DECAY_INTERVAL := 120.0  # seconds (GML: 2 in-game hours)
const INTERACT_RANGE    := 48.0  # pixels (matches GML [E] interact range)

# ─── Export ───────────────────────────────────────────────────────────────────────
## Set by the scene spawner to identify which peer owns this body
@export var player_peer_id: int = 1

# ─── Node refs (set in _ready — must exist in Player.tscn) ────────────────────────
@onready var sprite:     Sprite2D              = $Sprite2D
@onready var anim:       AnimationPlayer       = $AnimationPlayer
@onready var sync:       MultiplayerSynchronizer = $MultiplayerSynchronizer

# ─── State (mirrors key player1 vars) ────────────────────────────────────────────
var facing:    String = "down"
var is_local:  bool   = false

# Client-side timers (not synced — run independently on each client)
var _health_regen_timer: float = 0.0
var _heat_decay_timer:   float = 0.0
var _last_interact_time: float = 0.0


func _ready() -> void:
	is_local = (player_peer_id == multiplayer.get_unique_id())

	if is_local:
		# Only local player gets a camera
		var cam := Camera2D.new()
		cam.enabled = true
		cam.make_current()
		add_child(cam)

		# Connect HUD signals
		NotificationBus.notification_received.connect(_on_notification)

	# Non-local players: disable physics, only render
	set_physics_process(is_local)
	set_process(is_local)

	# Y-sort depth (replaces GML depth = -y)
	# Handled by parent node having y_sort_enabled = true


func _physics_process(delta: float) -> void:
	var data := PlayerRegistry.get_local_player()
	if data == null:
		return

	# ── Jailed: no movement ──
	if data.is_jailed:
		return

	# ── In car: hide player, car node handles movement ──
	if data.in_car:
		visible = false
		return
	visible = true

	# ── Input ──
	var input_dir := _get_input_direction()
	velocity = input_dir * WALK_SPEED
	move_and_slide()

	# ── Update facing ──
	if input_dir.length() > 0.1:
		_update_facing(input_dir)

	# ── Send position to server (throttled — every frame is fine for ENet unreliable) ──
	_rpc_send_position.rpc_id(1, position, facing)

	# ── Interact key ──
	if Input.is_action_just_pressed("interact"):
		_try_interact()


func _process(delta: float) -> void:
	var data := PlayerRegistry.get_local_player()
	if data == null:
		return

	# ── Health regen (mirrors GML: 1 HP every 180 frames = 3s at 60fps) ──
	if data.health < data.max_health and not data.is_jailed and not data.is_bleeding:
		_health_regen_timer += delta
		if _health_regen_timer >= HEALTH_REGEN_DELAY:
			_health_regen_timer = 0.0
			# Request health regen from server
			_rpc_request_health_regen.rpc_id(1)

	# ── Heat decay ──
	if data.heat_level > 0 and not data.is_jailed:
		_heat_decay_timer += delta
		if _heat_decay_timer >= HEAT_DECAY_INTERVAL:
			_heat_decay_timer = 0.0
			_rpc_request_heat_decay.rpc_id(1)

	# ── Update animation ──
	_update_animation(data)


func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1.0
	if Input.is_action_pressed("ui_left"):  dir.x -= 1.0
	if Input.is_action_pressed("ui_down"):  dir.y += 1.0
	if Input.is_action_pressed("ui_up"):    dir.y -= 1.0
	return dir.normalized()


func _update_facing(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		facing = "right" if dir.x > 0 else "left"
	else:
		facing = "down" if dir.y > 0 else "up"


func _update_animation(data: PlayerRegistry.PlayerData) -> void:
	if not anim:
		return
	var moving := velocity.length() > 1.0
	var anim_name: String
	if moving:
		anim_name = "walk_" + facing
	else:
		anim_name = "idle_" + facing

	if anim.has_animation(anim_name) and anim.current_animation != anim_name:
		anim.play(anim_name)


func _try_interact() -> void:
	## Checks for interactable objects nearby — mirrors GML [E] key handling
	## Each interactable object in Godot should be in the "interactable" group
	var nearby := get_tree().get_nodes_in_group("interactable")
	for obj in nearby:
		if obj.has_method("interact") and global_position.distance_to(obj.global_position) <= INTERACT_RANGE:
			obj.interact(player_peer_id)
			break


func _on_notification(message: String, color: Color) -> void:
	## Forward to HUD — HUD node connects to NotificationBus directly too,
	## but this can be used for in-world popups above the player
	pass  # HUD handles toast display via its own signal connection


# ─── RPCs ────────────────────────────────────────────────────────────────────────

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_send_position(pos: Vector2, face: String) -> void:
	## Server receives client movement
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender != player_peer_id:
		return

	var data := PlayerRegistry.get_player(sender)
	if data == null or data.is_jailed or data.in_car:
		return

	# Sanity check: max movement per frame × small buffer
	var max_delta := (WALK_SPEED / 60.0) * 8.0
	if pos.distance_to(data.position) > max_delta:
		# Position looks suspicious — send correction
		_rpc_correct_position.rpc_id(sender, data.position)
		return

	data.position = pos
	data.facing   = face
	# Update this ghost body's position for other clients
	position = pos
	facing   = face


@rpc("authority", "call_remote", "reliable")
func _rpc_correct_position(correct_pos: Vector2) -> void:
	## Server corrects client position (anti-speedhack)
	position = correct_pos
	var local := PlayerRegistry.get_local_player()
	if local:
		local.position = correct_pos


@rpc("authority", "call_local", "reliable")
func force_position(target_pos: Vector2) -> void:
	## Server forces player to a position (arrest, respawn, jail release)
	position = target_pos
	var local := PlayerRegistry.get_local_player()
	if local:
		local.position = target_pos


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_health_regen() -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	var data   := PlayerRegistry.get_player(sender)
	if data and not data.is_jailed and not data.is_bleeding:
		data.health = minf(data.health + HEALTH_REGEN_AMOUNT, data.max_health)
		_rpc_sync_health.rpc_id(sender, data.health)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_heat_decay() -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	var data   := PlayerRegistry.get_player(sender)
	if data and data.heat_level > 0:
		data.heat_level = maxf(0.0, data.heat_level - 1.0)
		EconomyManager.sync_economy_to_client(sender)


@rpc("authority", "call_local", "reliable")
func _rpc_sync_health(hp: float) -> void:
	var local := PlayerRegistry.get_local_player()
	if local:
		local.health = hp
