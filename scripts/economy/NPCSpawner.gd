extends Node
## NPCSpawner — server-side NPC lifecycle manager per scene.
## Place one instance in each world scene. Handles:
##   - Spawning NPC_Customer at random sidewalk positions
##   - Spawning NPC_Cop in response to heat levels
##   - Broadcasting NPC positions to clients at 10Hz
##   - Despawning when scene is empty of players
##
## Replaces: obj_game_controller spawning logic for customers and cops.

# ─── Config ───────────────────────────────────────────────────────────────────────
@export var scene_name:      String = "Seattle"
@export var max_customers:   int    = 8
@export var max_cops:        int    = 3
@export var spawn_interval:  float  = 5.0     # seconds between customer spawn attempts
@export var sidewalk_positions: Array[Vector2] = []   # Set in editor or via code

# ─── State ────────────────────────────────────────────────────────────────────────
var _customers:    Array[Node] = []
var _cops:         Array[Node] = []
var _npc_id_counter: int       = 0

var _spawn_timer:      float = 0.0
var _broadcast_timer:  float = 0.0
const BROADCAST_INTERVAL := 0.1   # 10Hz


const CustomerScript := preload("res://scripts/npcs/NPC_Customer.gd")
const CopScript      := preload("res://scripts/npcs/NPC_Cop.gd")


func _ready() -> void:
	if not multiplayer.is_server():
		return

	# Generate default sidewalk positions if none set in editor
	if sidewalk_positions.is_empty():
		_generate_default_positions()


func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return

	# ── Spawn customers ──
	_spawn_timer += delta
	if _spawn_timer >= spawn_interval:
		_spawn_timer = 0.0
		_try_spawn_customer()

	# ── Spawn cops based on player heat ──
	_maybe_spawn_cop()

	# ── Broadcast all NPC positions to clients at 10Hz ──
	_broadcast_timer += delta
	if _broadcast_timer >= BROADCAST_INTERVAL:
		_broadcast_timer = 0.0
		_broadcast_all_npcs()

	# ── Clean up dead NPCs ──
	_customers = _customers.filter(func(n): return is_instance_valid(n))
	_cops      = _cops.filter(func(n):      return is_instance_valid(n))


# ─── Spawning ─────────────────────────────────────────────────────────────────────

func _try_spawn_customer() -> void:
	if _customers.size() >= max_customers:
		return
	if not _players_in_scene():
		return

	var npc         := Node.new()
	npc.set_script(CustomerScript)
	npc.npc_id      = _next_id()
	npc.home_scene  = scene_name
	npc.pos         = _random_spawn_pos()

	add_child(npc)
	_customers.append(npc)

	# Tell clients to create a ghost for this NPC
	_rpc_spawn_npc_ghost.rpc("customer", npc.npc_id, npc.pos.x, npc.pos.y)


func _maybe_spawn_cop() -> void:
	if _cops.size() >= max_cops:
		return
	if not _players_in_scene():
		return

	# Spawn cop if any player in this scene has heat > 30
	var should_spawn := false
	for data in PlayerRegistry.all_players():
		if data.current_scene == scene_name and data.heat_level > 30:
			should_spawn = true
			break

	if not should_spawn:
		return

	var npc        := Node.new()
	npc.set_script(CopScript)
	npc.npc_id     = _next_id()
	npc.home_scene = scene_name
	npc.pos        = _random_spawn_pos()

	add_child(npc)
	_cops.append(npc)

	_rpc_spawn_npc_ghost.rpc("cop", npc.npc_id, npc.pos.x, npc.pos.y)


# ─── Broadcasting ─────────────────────────────────────────────────────────────────

func _broadcast_all_npcs() -> void:
	var peer_ids := NetworkManager.get_peers_in_scene(scene_name)
	if peer_ids.is_empty():
		return

	for npc in _customers + _cops:
		if not is_instance_valid(npc):
			continue
		# Use NPC_Base's broadcast, which does .rpc() to all
		npc.broadcast_position()


# ─── RPCs ─────────────────────────────────────────────────────────────────────────

@rpc("authority", "call_remote", "reliable")
func _rpc_spawn_npc_ghost(npc_type: String, npc_id: int, x: float, y: float) -> void:
	## Runs on clients — instantiate a lightweight ghost node for visual display
	var ghost_scene_path := "res://scenes/npcs/NPC_Ghost_Customer.tscn" if npc_type == "customer" \
		else "res://scenes/npcs/NPC_Ghost_Cop.tscn"

	# Gracefully skip if ghost scenes don't exist yet
	if not ResourceLoader.exists(ghost_scene_path):
		return

	var ghost: Node = load(ghost_scene_path).instantiate()
	ghost.npc_id    = npc_id
	ghost.position  = Vector2(x, y)
	ghost.add_to_group("npc_ghost")

	# Add to current scene
	get_tree().current_scene.add_child(ghost)


@rpc("authority", "call_remote", "reliable")
func _rpc_despawn_npc_ghost(npc_id: int) -> void:
	for ghost in get_tree().get_nodes_in_group("npc_ghost"):
		if ghost.get("npc_id") == npc_id:
			ghost.queue_free()
			return


# ─── Helpers ──────────────────────────────────────────────────────────────────────

func _players_in_scene() -> bool:
	return not NetworkManager.get_peers_in_scene(scene_name).is_empty()


func _next_id() -> int:
	_npc_id_counter += 1
	return _npc_id_counter


func _random_spawn_pos() -> Vector2:
	if sidewalk_positions.is_empty():
		return Vector2(randf_range(100, 900), randf_range(200, 300))
	return sidewalk_positions[randi() % sidewalk_positions.size()] + Vector2(
		randf_range(-20, 20), randf_range(-10, 10))


func _generate_default_positions() -> void:
	## Default sidewalk spawn band for Seattle scene
	## Top sidewalk: Y ~250-310, bottom sidewalk: Y ~410-470
	for i in 12:
		sidewalk_positions.append(Vector2(randf_range(80, 1200), randf_range(250, 310)))
		sidewalk_positions.append(Vector2(randf_range(80, 1200), randf_range(410, 470)))
