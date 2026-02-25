extends Node
## SaveSystem — per-player JSON saves. Replaces scr_save_load.gml.
## In solo play (server=local), saves to user://saves/player_1.json.
## In hosted server, each client gets their own file keyed by peer_id.
## Save format mirrors the GML savegame.sav JSON structure for reference continuity.

const SAVE_DIR := "user://saves/"
const LEGACY_SAVE_PATH := "user://savegame.sav"  # GML compat path (unused but noted)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


# ─── Existence checks ────────────────────────────────────────────────────────────

func save_exists(peer_id: int) -> bool:
	return FileAccess.file_exists(_save_path(peer_id))


func any_save_exists() -> bool:
	## Convenience: check if the local player (peer 1 in solo) has a save
	return save_exists(1)


# ─── Save ────────────────────────────────────────────────────────────────────────

func save_player(peer_id: int, data: PlayerRegistry.PlayerData) -> void:
	if not multiplayer.is_server():
		return
	if data == null:
		return

	var save_dict := {
		"version": 1,
		"player": {
			# Core stats
			"money":       data.money,
			"health":      data.health,
			"max_health":  data.max_health,
			"heat_level":  data.heat_level,
			# Inventory
			"inv_weed":        data.inv_weed,
			"inv_cocaine":     data.inv_cocaine,
			"inv_heroin":      data.inv_heroin,
			"inv_meth":        data.inv_meth,
			"inv_pills":       data.inv_pills,
			"commissary_food": data.commissary_food,
			# Weapons
			"weapon_type":   data.weapon_type,
			"has_gun":       data.has_gun,
			"weapons_owned": data.weapons_owned,
			# Car
			"owned_car": data.owned_car,
			"in_car":    data.in_car,
			# Loan system (all 10 variables)
			"has_active_loan":       data.has_active_loan,
			"loan_amount":           data.loan_amount,
			"loan_original_amount":  data.loan_original_amount,
			"loan_due_day":          data.loan_due_day,
			"loan_days_overdue":     data.loan_days_overdue,
			"loan_threat_level":     data.loan_threat_level,
			"loan_total_paid":       data.loan_total_paid,
			"loan_collectors_sent":  data.loan_collectors_sent,
			"loan_last_interest_day": data.loan_last_interest_day,
			"loan_rep_with_shark":   data.loan_rep_with_shark,
			"debt":                  data.debt,
			# Territory
			"has_territory":   data.has_territory,
			"territory_x":     data.territory_x,
			"territory_y":     data.territory_y,
			"territory_color": data.territory_color.to_html(false),
			"territory_name":  data.territory_name,
			# Crew
			"crew_unlocked":       data.crew_unlocked,
			"total_crew_earnings": data.total_crew_earnings,
			"total_money_earned":  data.total_money_earned,
			# Status
			"is_jailed":    data.is_jailed,
			"jail_timer":   data.jail_timer,
			"jail_sentence": data.jail_sentence,
			"is_snitch":    data.is_snitch,
			"snitch_level": data.snitch_level,
			"is_bleeding":  data.is_bleeding,
			"bleed_source": data.bleed_source,
			# Customization
			"skin_tone":     data.skin_tone,
			"bandana_color": data.bandana_color,
			# Position
			"current_scene": data.current_scene,
			"position_x":    data.position.x,
			"position_y":    data.position.y,
		},
		"world": {
			"day_current":  GameState.day_current,
			"week_current": GameState.week_current,
			"time_elapsed": GameState.time_elapsed,
		}
	}

	var json_str := JSON.stringify(save_dict, "\t")
	var file := FileAccess.open(_save_path(peer_id), FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		if GameState.debug_mode:
			print("SaveSystem: saved peer %d → %s" % [peer_id, _save_path(peer_id)])
	else:
		push_error("SaveSystem: failed to open %s for writing" % _save_path(peer_id))


func save_all_players() -> void:
	for peer_id in PlayerRegistry.all_player_ids():
		save_player(peer_id, PlayerRegistry.get_player(peer_id))


# ─── Load ────────────────────────────────────────────────────────────────────────

func load_player(peer_id: int) -> Dictionary:
	var path := _save_path(peer_id)
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("SaveSystem: failed to open %s for reading" % path)
		return {}

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if parsed == null:
		push_error("SaveSystem: failed to parse JSON from %s" % path)
		return {}

	return parsed


func get_save_preview(peer_id: int) -> Dictionary:
	## Returns {day, money} for display on the Continue button (mirrors GML menu preview)
	var save_dict := load_player(peer_id)
	if save_dict.is_empty():
		return {}
	return {
		"day":   save_dict.get("world", {}).get("day_current", 1),
		"money": save_dict.get("player", {}).get("money", 0),
	}


# ─── Manual save hotkey (F5) ──────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		var local_id := multiplayer.get_unique_id()
		# Client requests a save from the server
		_rpc_request_save.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_save() -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	save_player(sender, PlayerRegistry.get_player(sender))
	NotificationBus.notify_player(sender, "Game saved.", Color.CYAN)


# ─── Internal ────────────────────────────────────────────────────────────────────

func _save_path(peer_id: int) -> String:
	return SAVE_DIR + "player_%d.json" % peer_id
