extends Node
## JailSystem — tracks jail timers for all jailed players, releases them when time is served.
## Replaces the jail timer logic in obj_game_controller/Step_0.gml.
## Jail minigame interactions (chess, spades, commissary, alliances) are in their own scripts.

signal player_released(peer_id: int)
signal jail_time_updated(peer_id: int, remaining: float, sentence: float)

## How often to broadcast jail timer to client (seconds)
const BROADCAST_INTERVAL := 5.0
var _broadcast_timers: Dictionary = {}   # peer_id → float


func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return

	for peer_id in PlayerRegistry.all_player_ids():
		var data := PlayerRegistry.get_player(peer_id)
		if data == null or not data.is_jailed:
			continue

		data.jail_timer -= delta

		# Periodic broadcast to client
		_broadcast_timers[peer_id] = _broadcast_timers.get(peer_id, 0.0) + delta
		if _broadcast_timers[peer_id] >= BROADCAST_INTERVAL:
			_broadcast_timers[peer_id] = 0.0
			_rpc_sync_jail_timer.rpc_id(peer_id, data.jail_timer, data.jail_sentence)

		emit_signal("jail_time_updated", peer_id, data.jail_timer, data.jail_sentence)

		# Release check
		if data.jail_timer <= 0.0:
			_release_player(peer_id, data)


func _release_player(peer_id: int, data: PlayerRegistry.PlayerData) -> void:
	data.is_jailed     = false
	data.jail_timer    = 0.0
	data.jail_sentence = 0.0

	# Restore some health
	data.health = data.max_health * 0.5

	# Move to Seattle by default (could be smarter about home scene)
	var release_scene := "Seattle"
	var release_pos   := Vector2(600, 300)
	data.current_scene = release_scene
	data.position      = release_pos
	NetworkManager.move_peer_to_scene(peer_id, "rm_jail_lobby", release_scene)

	# Sync client
	EconomyManager.sync_economy_to_client(peer_id)
	_rpc_release.rpc_id(peer_id,
		GameState.SCENE_MAP[release_scene],
		release_pos.x, release_pos.y,
		data.health)

	SaveSystem.save_player(peer_id, data)
	emit_signal("player_released", peer_id)
	NotificationBus.notify_player(peer_id, "Time served. You're out!", Color.CYAN)


# ─── Public API ──────────────────────────────────────────────────────────────────

func get_jail_time_string(peer_id: int) -> String:
	## Returns formatted remaining time for display: "6d 23h 12m"
	var data := PlayerRegistry.get_player(peer_id)
	if data == null or not data.is_jailed:
		return ""

	var total_secs := int(data.jail_timer)
	var in_game_mins := total_secs * 1440 / int(GameState.DAY_LENGTH_SECONDS)
	var days         := in_game_mins / 1440
	var hours        := (in_game_mins % 1440) / 60
	var mins         := in_game_mins % 60
	return "%dd %dh %dm" % [days, hours, mins]


# ─── RPCs ─────────────────────────────────────────────────────────────────────────

@rpc("authority", "call_remote", "reliable")
func _rpc_release(scene_path: String, dest_x: float, dest_y: float, hp: float) -> void:
	var local := PlayerRegistry.get_local_player()
	if local:
		local.is_jailed = false
		local.position  = Vector2(dest_x, dest_y)
		local.health    = hp
	get_tree().change_scene_to_file(scene_path)


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_sync_jail_timer(remaining: float, sentence: float) -> void:
	var local := PlayerRegistry.get_local_player()
	if local:
		local.jail_timer    = remaining
		local.jail_sentence = sentence
