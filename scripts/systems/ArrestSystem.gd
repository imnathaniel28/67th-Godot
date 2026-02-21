extends Node
## ArrestSystem — server-authoritative arrest logic.
## Replaces scr_arrest_player.gml with a server-side, RPC-driven version.
## Three scenarios exactly matching GML behavior:
##   1. No drugs  → $100 fine, stay in scene
##   2. Has drugs, < $1000 → confiscate + jail (1 week)
##   3. Has drugs + $1000+ → corrupt cops rob everything, beat up, stay in scene

signal player_arrested(peer_id: int, scenario: int)


func arrest_player(peer_id: int) -> void:
	## Called by NPC_Cop or any server system that triggers an arrest
	if not multiplayer.is_server():
		push_error("ArrestSystem.arrest_player must run on server")
		return

	var data := PlayerRegistry.get_player(peer_id)
	if data == null or data.is_jailed:
		return

	var total_drugs := data.get_total_drugs()

	# ── Scenario 1: Clean — small fine ──────────────────────────────────────────
	if total_drugs <= 0:
		var fine := 100
		data.money = maxi(0, data.money - fine)
		EconomyManager.sync_economy_to_client(peer_id)
		NotificationBus.notify_player(peer_id,
			"Police stop! $%d fine. Stay out of trouble." % fine,
			Color.YELLOW)
		emit_signal("player_arrested", peer_id, 1)
		return

	# ── Scenario 2: Drugs found, broke — jail time ───────────────────────────────
	if data.money < 1000:
		_confiscate_drugs(data)

		# Set jail timer: 7 in-game days
		var sentence := GameState.DAY_LENGTH_SECONDS * 7.0
		data.jail_timer   = sentence
		data.jail_sentence = sentence
		data.is_jailed     = true

		# Give a little commissary for jail
		data.commissary_food = randi_range(1, 3)

		EconomyManager.sync_economy_to_client(peer_id)
		NotificationBus.notify_player(peer_id,
			"BUSTED! Drugs confiscated. You're doing 7 days.",
			Color.RED)

		# Transition client to jail scene
		_rpc_transition_to_jail.rpc_id(peer_id, 400.0, 500.0)
		var old_scene := data.current_scene
		data.current_scene = "rm_jail_lobby"
		data.position      = Vector2(400, 500)
		NetworkManager.move_peer_to_scene(peer_id, old_scene, "rm_jail_lobby")

		emit_signal("player_arrested", peer_id, 2)
		return

	# ── Scenario 3: Drugs found + cash — corrupt cops rob everything ─────────────
	var stolen_cash := data.money
	data.money = 0
	var stolen_drugs := _confiscate_drugs(data)

	# Beat up the player
	data.health = maxf(10.0, data.health - 50.0)

	EconomyManager.sync_economy_to_client(peer_id)
	NotificationBus.notify_player(peer_id,
		"Corrupt cops! Robbed $%d + all your pack. Took a beating." % stolen_cash,
		Color.RED)

	# Sync health to client
	_rpc_sync_health.rpc_id(peer_id, data.health)

	emit_signal("player_arrested", peer_id, 3)


func jail_player_manual(peer_id: int, sentence_days: float = 7.0) -> void:
	## Directly jail a player (used by duel loser, snitch mechanic, etc.)
	var data := PlayerRegistry.get_player(peer_id)
	if data == null:
		return

	var sentence := GameState.DAY_LENGTH_SECONDS * sentence_days
	data.jail_timer    = sentence
	data.jail_sentence = sentence
	data.is_jailed     = true

	_rpc_transition_to_jail.rpc_id(peer_id, 400.0, 500.0)
	var old_scene := data.current_scene
	data.current_scene = "rm_jail_lobby"
	data.position      = Vector2(400, 500)
	NetworkManager.move_peer_to_scene(peer_id, old_scene, "rm_jail_lobby")


# ─── Helpers ─────────────────────────────────────────────────────────────────────

func _confiscate_drugs(data: PlayerRegistry.PlayerData) -> Dictionary:
	var confiscated := {
		"weed":    data.inv_weed,
		"cocaine": data.inv_cocaine,
		"heroin":  data.inv_heroin,
		"meth":    data.inv_meth,
		"pills":   data.inv_pills,
	}
	data.inv_weed    = 0
	data.inv_cocaine = 0
	data.inv_heroin  = 0
	data.inv_meth    = 0
	data.inv_pills   = 0
	return confiscated


# ─── RPCs ────────────────────────────────────────────────────────────────────────

@rpc("authority", "call_remote", "reliable")
func _rpc_transition_to_jail(dest_x: float, dest_y: float) -> void:
	var local := PlayerRegistry.get_local_player()
	if local:
		local.position = Vector2(dest_x, dest_y)
	get_tree().change_scene_to_file(GameState.SCENE_MAP["rm_jail_lobby"])


@rpc("authority", "call_remote", "reliable")
func _rpc_sync_health(hp: float) -> void:
	var local := PlayerRegistry.get_local_player()
	if local:
		local.health = hp
