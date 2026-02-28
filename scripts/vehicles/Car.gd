extends Node2D
class_name Car
## Car — traffic and cop car driving along the street lane.
## Ports obj_car (Create_0, Step_0, Draw_0) from GameMaker.
##
## The spawner calls setup() after add_child() to configure type/direction/speed/texture.
## Signal spawn_cops_requested is emitted when a cop car gets blocked — wire it up in the scene.

signal spawn_cops_requested(world_pos: Vector2, count: int, from_car: Car)

enum CarType { CIVILIAN, COP }

# ─── Identity ─────────────────────────────────────────────────────────────────
@export var car_type:   CarType = CarType.CIVILIAN
@export var direction:  int     = 0       # 0 = right (+x), 1 = left (-x)
@export var room_width: float   = 1280.0

# ─── Movement ─────────────────────────────────────────────────────────────────
var spd:      float = 2.5
var base_spd: float = 2.5
var x_vel:    float = 0.0

# ─── Cop car state ────────────────────────────────────────────────────────────
const SLOWDOWN_RANGE:      float = 200.0
const MIN_SPEED_MULT:      float = 0.01
const BLOCK_SPAWN_SECONDS: float = 3.0

var has_target:        bool  = false  # keep car stopped while cop pursues player
var block_timer:       float = 0.0
var block_cop_spawned: bool  = false

# ─── Car-ahead bumper detection ───────────────────────────────────────────────
const SAFE_DISTANCE: float = 140.0   # start slowing at this gap
const MIN_GAP:       float = 95.0    # stop at this gap
const LANE_HALF_H:   float = 30.0    # same-lane Y tolerance

# ─── Player braking ───────────────────────────────────────────────────────────
const BRAKE_RANGE: float = 180.0
const STOP_GAP:    float = 40.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("cars")
	x_vel = _dir_sign() * spd


func _process(delta: float) -> void:
	_update_cop_slowdown()
	var player_blocking := _update_player_braking()
	_update_car_ahead()
	_apply_movement()
	z_index = int(-position.y)

	if car_type == CarType.COP:
		_update_block_timer(delta, player_blocking)

	_check_despawn()


# ─── Cop proximity slowdown ───────────────────────────────────────────────────

func _update_cop_slowdown() -> void:
	if car_type != CarType.COP:
		return
	var player := _nearest_street_player()
	if player == null:
		spd = base_spd
		return
	var dist := position.distance_to(player.global_position)
	if dist < SLOWDOWN_RANGE:
		spd = base_spd * clampf(dist / SLOWDOWN_RANGE, MIN_SPEED_MULT, 1.0)
	else:
		spd = base_spd


# ─── Player braking ───────────────────────────────────────────────────────────

func _update_player_braking() -> bool:
	var blocking := false
	for player: Node in get_tree().get_nodes_in_group("players"):
		var py: float = (player as Node2D).global_position.y
		if py < GameState.STREET_Y_TOP or py > GameState.STREET_Y_BOTTOM:
			continue
		var dx: float = (player as Node2D).global_position.x - global_position.x
		var ahead := false
		if direction == 0 and dx > 0.0 and dx < BRAKE_RANGE:
			ahead = true
		if direction == 1 and dx < 0.0 and -dx < BRAKE_RANGE:
			ahead = true
		if ahead and absf((player as Node2D).global_position.y - global_position.y) < 32.0:
			var dist := absf(dx)
			if dist <= STOP_GAP:
				x_vel = 0.0
				blocking = true
			else:
				var brake := clampf((dist - STOP_GAP) / (BRAKE_RANGE - STOP_GAP), 0.0, 1.0)
				x_vel = _dir_sign() * spd * brake
	return blocking


# ─── Block timer (cop car) ────────────────────────────────────────────────────

func _update_block_timer(delta: float, player_blocking: bool) -> void:
	if player_blocking:
		block_timer += delta
		if not block_cop_spawned and block_timer >= BLOCK_SPAWN_SECONDS:
			var heat := _local_heat()
			var count := 2 if heat > 50.0 else 1
			emit_signal("spawn_cops_requested", global_position, count, self)
			has_target = true
			block_cop_spawned = true
	else:
		block_timer = 0.0


# ─── Car-ahead bumper detection ───────────────────────────────────────────────

func _update_car_ahead() -> void:
	if has_target:
		x_vel = 0.0
		return

	var best_car: Node2D = null
	var best_dist: float = 9999.0

	for car: Node in get_tree().get_nodes_in_group("cars"):
		if car == self:
			continue
		var other := car as Car
		if other.direction != direction:
			continue
		if absf(other.global_position.y - global_position.y) >= LANE_HALF_H:
			continue
		var dx: float
		if direction == 1:  # moving left — ahead = smaller x
			if other.global_position.x < global_position.x:
				dx = global_position.x - other.global_position.x
				if dx < SAFE_DISTANCE and dx < best_dist:
					best_car = other
					best_dist = dx
		else:               # moving right — ahead = larger x
			if other.global_position.x > global_position.x:
				dx = other.global_position.x - global_position.x
				if dx < SAFE_DISTANCE and dx < best_dist:
					best_car = other
					best_dist = dx

	if best_car != null:
		if best_dist <= MIN_GAP:
			x_vel = 0.0
			# Push-back correction so cars never overlap
			if direction == 1:
				global_position.x = best_car.global_position.x + MIN_GAP
			else:
				global_position.x = best_car.global_position.x - MIN_GAP
		else:
			var slow := clampf((best_dist - MIN_GAP) / (SAFE_DISTANCE - MIN_GAP), 0.1, 1.0)
			x_vel = _dir_sign() * spd * slow
	else:
		# Gradually accelerate back to normal speed (mirrors GML lerp 0.017)
		x_vel = lerpf(x_vel, _dir_sign() * spd, 0.017)


# ─── Movement & cleanup ───────────────────────────────────────────────────────

func _apply_movement() -> void:
	global_position.x += x_vel


func _check_despawn() -> void:
	if direction == 0 and global_position.x > room_width + 100.0:
		queue_free()
	elif direction == 1 and global_position.x < -100.0:
		queue_free()


# ─── Helpers ─────────────────────────────────────────────────────────────────

func _nearest_street_player() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for p: Node in get_tree().get_nodes_in_group("players"):
		var pn := p as Node2D
		if pn.global_position.y < GameState.STREET_Y_TOP or pn.global_position.y > GameState.STREET_Y_BOTTOM:
			continue
		var d := global_position.distance_to(pn.global_position)
		if d < best_dist:
			best_dist = d
			best = pn
	return best


func _dir_sign() -> float:
	return 1.0 if direction == 0 else -1.0


func _local_heat() -> float:
	var data := PlayerRegistry.get_local_player()
	return data.heat_level if data else 0.0


# ─── Public API (called by TrafficSpawner) ────────────────────────────────────

func setup(p_type: CarType, p_dir: int, p_spd: float, p_texture: Texture2D) -> void:
	car_type = p_type
	direction = p_dir
	spd      = p_spd
	base_spd = p_spd
	x_vel    = _dir_sign() * spd
	if sprite:
		sprite.texture = p_texture
		sprite.flip_h  = (p_dir == 1)
