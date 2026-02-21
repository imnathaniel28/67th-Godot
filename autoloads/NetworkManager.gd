extends Node
## NetworkManager — owns the ENet peer, manages connections and scene populations.
## All multiplayer setup goes through here. Game logic never touches the peer directly.

const DEFAULT_PORT := 7777
const MAX_PLAYERS  := 4

var peer: ENetMultiplayerPeer = null

## scene_populations[scene_name] = [peer_id, peer_id, ...]
var scene_populations: Dictionary = {}

# ─── Signals ────────────────────────────────────────────────────────────────────
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_succeeded()
signal connection_failed()
signal server_disconnected()
signal scene_transition_requested(peer_id: int, scene_name: String, dest: Vector2)


# ─── Server ─────────────────────────────────────────────────────────────────────

func create_server(port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("NetworkManager: failed to create server on port %d — %s" % [port, error_string(err)])
		peer = null
		return err

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	print("NetworkManager: server started on port %d (max %d players)" % [port, MAX_PLAYERS])
	return OK


# ─── Client ─────────────────────────────────────────────────────────────────────

func join_server(address: String, port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_error("NetworkManager: failed to connect to %s:%d — %s" % [address, port, error_string(err)])
		peer = null
		emit_signal("connection_failed")
		return err

	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	print("NetworkManager: connecting to %s:%d …" % [address, port])
	return OK


func disconnect_all() -> void:
	if peer:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = null
	scene_populations.clear()
	print("NetworkManager: disconnected")


# ─── Helpers ────────────────────────────────────────────────────────────────────

func is_server() -> bool:
	return multiplayer.is_server()


func my_id() -> int:
	return multiplayer.get_unique_id()


func is_connected_to_server() -> bool:
	return peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func get_peers_in_scene(scene_name: String) -> Array:
	return scene_populations.get(scene_name, []).duplicate()


func move_peer_to_scene(peer_id: int, from_scene: String, to_scene: String) -> void:
	## Server-side: update population tracking when a player changes scenes
	if scene_populations.has(from_scene):
		scene_populations[from_scene].erase(peer_id)

	if not scene_populations.has(to_scene):
		scene_populations[to_scene] = []
	if not scene_populations[to_scene].has(peer_id):
		scene_populations[to_scene].append(peer_id)


# ─── Scene Transition RPC ────────────────────────────────────────────────────────

func request_scene_transition(scene_name: String, dest_x: float, dest_y: float) -> void:
	## Called by client when hitting an exit trigger. Server validates and approves.
	_server_handle_transition_request.rpc_id(1, scene_name, dest_x, dest_y)


@rpc("any_peer", "call_remote", "reliable")
func _server_handle_transition_request(scene_name: String, dest_x: float, dest_y: float) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	var data   := PlayerRegistry.get_player(sender)
	if data == null:
		return

	# Validate scene exists
	if not GameState.SCENE_MAP.has(scene_name):
		push_warning("NetworkManager: unknown scene requested: " + scene_name)
		return

	# Save before transition
	SaveSystem.save_player(sender, data)

	# Update population
	move_peer_to_scene(sender, data.current_scene, scene_name)

	# Update player data
	data.current_scene = scene_name
	data.position      = Vector2(dest_x, dest_y)

	# Tell the client to load the new scene
	_rpc_execute_transition.rpc_id(sender,
		GameState.SCENE_MAP[scene_name], dest_x, dest_y)

	emit_signal("scene_transition_requested", sender, scene_name, Vector2(dest_x, dest_y))


@rpc("authority", "call_remote", "reliable")
func _rpc_execute_transition(scene_path: String, dest_x: float, dest_y: float) -> void:
	## Runs on the client — load the new scene, then restore position in _ready
	var local := PlayerRegistry.get_local_player()
	if local:
		local.position = Vector2(dest_x, dest_y)
	get_tree().change_scene_to_file(scene_path)


# ─── Peer Events ─────────────────────────────────────────────────────────────────

func _on_peer_connected(id: int) -> void:
	print("NetworkManager: peer connected — ", id)
	PlayerRegistry.register_player(id)

	# Load existing save if one exists
	if SaveSystem.save_exists(id):
		var save_data := SaveSystem.load_player(id)
		PlayerRegistry.apply_save_data(id, save_data)

	emit_signal("player_connected", id)

	# Add to Seattle population by default
	move_peer_to_scene(id, "", PlayerRegistry.get_player(id).current_scene)

	# Tell the new client to spawn their player
	var data := PlayerRegistry.get_player(id)
	_rpc_on_join.rpc_id(id, data.current_scene, data.position.x, data.position.y)


func _on_peer_disconnected(id: int) -> void:
	print("NetworkManager: peer disconnected — ", id)
	SaveSystem.save_player(id, PlayerRegistry.get_player(id))
	var data := PlayerRegistry.get_player(id)
	if data:
		scene_populations.get(data.current_scene, []).erase(id)
	PlayerRegistry.unregister_player(id)
	emit_signal("player_disconnected", id)


func _on_connected_to_server() -> void:
	print("NetworkManager: connected as peer ", my_id())
	emit_signal("connection_succeeded")


func _on_connection_failed() -> void:
	print("NetworkManager: connection failed")
	peer = null
	emit_signal("connection_failed")


func _on_server_disconnected() -> void:
	print("NetworkManager: server disconnected")
	peer = null
	emit_signal("server_disconnected")


@rpc("authority", "call_local", "reliable")
func _rpc_on_join(scene_name: String, spawn_x: float, spawn_y: float) -> void:
	## Client receives this after connecting — loads starting scene
	var local := PlayerRegistry.get_local_player()
	if local:
		local.current_scene = scene_name
		local.position      = Vector2(spawn_x, spawn_y)
	get_tree().change_scene_to_file(GameState.SCENE_MAP.get(scene_name, GameState.SCENE_MAP["Seattle"]))
