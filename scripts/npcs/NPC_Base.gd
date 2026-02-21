extends Node2D
## NPC_Base — shared base for all server-side NPC types.
## Subclass this for Customer, Cop, DebtCollector, CrewMember.
## All NPC AI runs ONLY on the server. Clients receive position broadcasts.

## Unique ID assigned by the NPCSpawner — used to match server NPCs to client ghosts
var npc_id:    int    = 0
var npc_type:  String = "base"

## Position tracked here (not in Node2D.position — NPCs aren't CharacterBody2D on server)
var pos: Vector2 = Vector2.ZERO

## Which scene this NPC belongs to (for multi-scene routing)
var home_scene: String = "Seattle"

## Base move speed in pixels/sec
var move_speed: float = 72.0   # GML 1.2 units/frame × 60fps

## Broadcast interval tracker (set by NPCSpawner)
var _broadcast_timer: float = 0.0
const BROADCAST_INTERVAL := 0.1  # 10Hz position updates to clients


func _ready() -> void:
	if not multiplayer.is_server():
		queue_free()  # Safety: NPC nodes must only exist on server


func get_nearest_player_in_scene(detection_radius: float) -> PlayerRegistry.PlayerData:
	var closest: PlayerRegistry.PlayerData = null
	var closest_dist := detection_radius

	for data in PlayerRegistry.all_players():
		if data.is_jailed or data.current_scene != home_scene:
			continue
		var dist := pos.distance_to(data.position)
		if dist < closest_dist:
			closest_dist = dist
			closest = data

	return closest


func is_in_crosswalk(check_pos: Vector2) -> bool:
	for cw in GameState.CROSSWALK_ZONES:
		if check_pos.x >= cw["x_min"] and check_pos.x <= cw["x_max"]:
			return true
	return false


func find_nearest_crosswalk(from_pos: Vector2) -> Dictionary:
	var nearest := {}
	var min_dist := 999999.0
	for cw in GameState.CROSSWALK_ZONES:
		var cx := (cw["x_min"] + cw["x_max"]) / 2.0
		var d  := abs(from_pos.x - cx)
		if d < min_dist:
			min_dist = d
			nearest  = {"x_min": cw["x_min"], "x_max": cw["x_max"], "center_x": cx}
	return nearest


func apply_sidewalk_constraint(new_pos: Vector2) -> Vector2:
	## Prevents crossing street except at crosswalks (mirrors GML crosswalk logic)
	if is_in_crosswalk(pos):
		return new_pos  # Currently in crosswalk — allow any Y movement

	var going_into_street := (
		(pos.y < GameState.STREET_Y_TOP    and new_pos.y >= GameState.STREET_Y_TOP) or
		(pos.y > GameState.STREET_Y_BOTTOM and new_pos.y <= GameState.STREET_Y_BOTTOM)
	)

	if going_into_street:
		new_pos.y = pos.y  # Block the Y movement
	return new_pos


func move_toward_target(target_pos: Vector2, speed: float, delta: float) -> void:
	var dir := pos.direction_to(target_pos)
	var new_pos := pos + dir * speed * delta
	pos = apply_sidewalk_constraint(new_pos)


func broadcast_position() -> void:
	## Called by NPCSpawner at 10Hz to update clients
	## Subclasses can override to add extra data
	_rpc_update_npc_position.rpc(npc_id, pos.x, pos.y)


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_update_npc_position(id: int, x: float, y: float) -> void:
	## Runs on clients — find the ghost node for this NPC and update its position
	var ghost := _find_ghost(id)
	if ghost:
		ghost.target_position = Vector2(x, y)


func _find_ghost(id: int) -> Node:
	## Clients look up their local NPC ghost node by npc_id
	var ghosts := get_tree().get_nodes_in_group("npc_ghost")
	for g in ghosts:
		if g.get("npc_id") == id:
			return g
	return null
