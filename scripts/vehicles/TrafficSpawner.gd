extends Node
## TrafficSpawner — spawns civilian and cop cars along the street lane.
## Ports scr_traffic_spawner + scr_spawn_cop_from_car from GameMaker.
##
## Add one of these nodes to any scene that has street traffic (Seattle, LA, etc.).
## Connect Car.spawn_cops_requested to _on_car_spawn_cops_requested in the same scene
## (or handle it however your arrest system is wired up).

# ─── Scene references ─────────────────────────────────────────────────────────
const CAR_SCENE       := preload("res://scenes/vehicles/Car.tscn")

# Sprites — add more textures to CIVILIAN_TEXTURES as assets are imported
const CIV_TEXTURE     := preload("res://assets/sprites/GreenCar_side/GreenCar_side_0.png")
const COP_CAR_TEXTURE := preload("res://assets/sprites/spr_cop_car/spr_cop_car_0.png")

# TODO: expand when more civilian car sprites are imported:
# const CAR_BUG       := preload("res://assets/sprites/Car_Bug/Car_Bug_0.png")
# const CAR_GRAY_TRUCK := preload("res://assets/sprites/Car_grayTruck/Car_grayTruck_0.png")
# const CAR_SPORT     := preload("res://assets/sprites/Car_sport/Car_sport_0.png")
# const CAR_SPORT2    := preload("res://assets/sprites/Car_sport2/Car_sport2_0.png")
# const CAR_SPORT_RED := preload("res://assets/sprites/Car_sportRed/Car_sportRed_0.png")
# const CAR_YELLOW_JEEP := preload("res://assets/sprites/Car_yellowJeep/Car_yellowJeep_0.png")
# var CIVILIAN_TEXTURES := [CIV_TEXTURE, CAR_BUG, CAR_GRAY_TRUCK, CAR_SPORT, CAR_SPORT2, CAR_SPORT_RED, CAR_YELLOW_JEEP]

# ─── Lane positions (mirrors GML spawn coordinates) ──────────────────────────
@export var room_width:  float = 1280.0
@export var civilian_y:  float = 370.0   # eastbound lane centre
@export var cop_car_y:   float = 358.0   # westbound cop lane centre

# ─── Cop spawn timer (120–180 in-game minutes = ~25–37 real seconds) ─────────
# Conversion: DAY_LENGTH_SECONDS (300) / 1440 minutes = 0.208 sec/game-minute
const COP_SPAWN_MIN_SEC: float = 120.0 * (300.0 / 1440.0)   # ≈ 25 s
const COP_SPAWN_MAX_SEC: float = 180.0 * (300.0 / 1440.0)   # ≈ 37.5 s

var _cop_timer: float = 0.0
var _cop_next:  float = 0.0

# ─── Per-frame traffic chances (GML per-frame values × 60 → per-second) ──────
# Multiplied by delta each frame to get the correct probability.
const CHANCE_BASE:      float = 0.005 * 60.0
const CHANCE_RUSH:      float = 0.010 * 60.0
const CHANCE_PRE_RUSH:  float = 0.0075 * 60.0
const CHANCE_NIGHT:     float = 0.0025 * 60.0


func _ready() -> void:
	_cop_next = randf_range(COP_SPAWN_MIN_SEC, COP_SPAWN_MAX_SEC)


func _process(delta: float) -> void:
	# Traffic only ticks on the server (mirrors GML obj_game_controller authority)
	if not multiplayer.is_server():
		return
	_tick_civilian(delta)
	_tick_cop(delta)


# ─── Civilian cars ────────────────────────────────────────────────────────────

func _tick_civilian(delta: float) -> void:
	var chance := _traffic_chance_per_sec()
	if randf() < chance * delta:
		var car := _make_car()
		car.global_position = Vector2(-50.0, civilian_y)
		var spd := randf_range(2.5, 5.0)
		if randi() % 8 == 0:   # 1-in-8 speeder (~80–90 MPH feel)
			spd = randf_range(6.5, 7.5)
		car.setup(Car.CarType.CIVILIAN, 0, spd, CIV_TEXTURE)


## Returns the per-second civilian spawn probability for the current in-game hour.
func _traffic_chance_per_sec() -> float:
	var h := GameState.time_hours
	if (h >= 9 and h < 10) or (h >= 18 and h < 19):
		return CHANCE_RUSH
	if (h >= 7 and h < 9) or (h >= 17 and h < 18) or (h >= 19 and h < 20):
		return CHANCE_PRE_RUSH
	if h >= 0 and h < 6:
		return CHANCE_NIGHT
	return CHANCE_BASE


# ─── Cop cars ─────────────────────────────────────────────────────────────────

func _tick_cop(delta: float) -> void:
	_cop_timer += delta
	if _cop_timer < _cop_next:
		return
	_spawn_cop_car(Vector2(room_width + 50.0, cop_car_y), 1)
	_cop_timer = 0.0
	_cop_next  = randf_range(COP_SPAWN_MIN_SEC, COP_SPAWN_MAX_SEC)


## Spawns a cop car at the given position. direction 0 = right, 1 = left.
func _spawn_cop_car(spawn_pos: Vector2, dir: int) -> Car:
	var car := _make_car()
	car.global_position = spawn_pos
	car.setup(Car.CarType.COP, dir, 2.5, COP_CAR_TEXTURE)
	return car


func _make_car() -> Car:
	var car: Car = CAR_SCENE.instantiate()
	get_parent().add_child(car)
	car.room_width = room_width
	car.spawn_cops_requested.connect(_on_car_spawn_cops_requested)
	return car


# ─── scr_spawn_cop_from_car equivalent ───────────────────────────────────────
## Called when a cop car gets blocked by the player long enough.
## Emits a signal your arrest/cop system should handle to spawn foot cops.
## Connect ArrestSystem (or game controller) to this signal.
signal foot_cops_requested(world_pos: Vector2, count: int, from_car: Car)

func _on_car_spawn_cops_requested(world_pos: Vector2, count: int, from_car: Car) -> void:
	emit_signal("foot_cops_requested", world_pos, count, from_car)


## Finds or creates a cop car near a world position, used by ArrestSystem
## to spawn a cop "stepping out" of a vehicle.  Returns the car node.
func get_or_spawn_cop_car_near(near_pos: Vector2) -> Car:
	# Prefer an existing cop car
	var best: Car = null
	var best_dist := INF
	for node: Node in get_tree().get_nodes_in_group("cars"):
		var car := node as Car
		if car == null or car.car_type != Car.CarType.COP:
			continue
		var d := near_pos.distance_to(car.global_position)
		if d < best_dist:
			best_dist = d
			best = car
	if best != null:
		return best

	# None found — spawn one stopped beside the action
	var offset := -120.0 if near_pos.x > room_width / 2.0 else 120.0
	var spawn_x := clampf(near_pos.x + offset, 50.0, room_width - 50.0)
	var dir    := 1 if near_pos.x < room_width / 2.0 else 0
	var car    := _spawn_cop_car(Vector2(spawn_x, cop_car_y), dir)
	car.has_target = true   # stopped — officers are exiting
	return car
