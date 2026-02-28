extends Node2D
class_name DrivebyChar
## DrivebyChar — drive-by shooting car that attacks a player.
## Ports obj_driveby_car (Create_0, Step_0, Draw_0) from GameMaker.
##
## Spawner sets target/direction/texture via setup(), then adds to scene.
## Bullets are a TODO — wire in a bullet scene when ready.

enum State { APPROACHING, STOPPING, SHOOTING, FLEEING }

# ─── Config ───────────────────────────────────────────────────────────────────
const DRIVE_SPEED:         float = 3.5
const FLEE_SPEED:          float = 4.0
const FRICTION:            float = 0.85
const ESCAPE_DIST:         float = 300.0
const MAX_LIFETIME:        float = 30.0

const SHOOT_COOLDOWN:      float = 18.0 / 60.0   # ~3.3 shots/sec
const BULLET_DAMAGE:       float = 12.0
const SHOOT_SPREAD_DEG:    float = 15.0
const INITIAL_BURST_DELAY: float = 30.0 / 60.0   # 0.5 sec car-settling pause

const SPEECH_DURATION:     float = 2.5
const TAUNTS: Array        = ["Yea, Gotchu now!", "Stay off this block!", "Wassup now?!"]

# ─── State ────────────────────────────────────────────────────────────────────
var state:     State   = State.APPROACHING
var target:    Node2D  = null
var direction: int     = 0        # 0 = right (+x), 1 = left (-x)

# ─── Movement ─────────────────────────────────────────────────────────────────
var x_vel:    float = 0.0
var stop_x:   float = 0.0

# ─── Shooting ─────────────────────────────────────────────────────────────────
var shoot_timer:        float = 0.0
var burst_timer:        float = 0.0
var muzzle_flash_timer: float = 0.0

# ─── Speech ───────────────────────────────────────────────────────────────────
var speech_text:  String = ""
var speech_timer: float  = 0.0
var speech_shown: bool   = false

# ─── Lifetime ─────────────────────────────────────────────────────────────────
var lifetime: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("cars")


func _process(delta: float) -> void:
	lifetime += delta

	if target == null or not is_instance_valid(target):
		state = State.FLEEING

	if state == State.SHOOTING and is_instance_valid(target):
		if global_position.distance_to(target.global_position) >= ESCAPE_DIST:
			state = State.FLEEING

	if lifetime >= MAX_LIFETIME and state != State.FLEEING:
		state = State.FLEEING

	match state:
		State.APPROACHING: _process_approaching()
		State.STOPPING:    _process_stopping()
		State.SHOOTING:    _process_shooting(delta)
		State.FLEEING:     _process_fleeing()

	if speech_timer > 0.0:
		speech_timer -= delta
	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta

	global_position.x += x_vel
	z_index = int(-global_position.y)

	# Despawn off-screen
	if global_position.x < -200.0 or global_position.x > 2000.0:
		queue_free()


# ─── State handlers ───────────────────────────────────────────────────────────

func _process_approaching() -> void:
	x_vel = DRIVE_SPEED if direction == 0 else -DRIVE_SPEED
	if absf(global_position.x - stop_x) < 60.0:
		state = State.STOPPING


func _process_stopping() -> void:
	x_vel *= FRICTION
	if absf(x_vel) < 0.2:
		x_vel = 0.0
		state = State.SHOOTING
		burst_timer = INITIAL_BURST_DELAY


func _process_shooting(delta: float) -> void:
	if not speech_shown:
		speech_shown = true
		speech_text  = TAUNTS[randi() % TAUNTS.size()]
		speech_timer = SPEECH_DURATION

	# Slowly track player X along the street
	if is_instance_valid(target):
		var dx := target.global_position.x - global_position.x
		x_vel = clampf(dx * 0.02, -1.5, 1.5) if absf(dx) > 30.0 else 0.0

	if burst_timer > 0.0:
		burst_timer -= delta
		return

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = SHOOT_COOLDOWN
		_fire_bullet()
		muzzle_flash_timer = 4.0 / 60.0


func _process_fleeing() -> void:
	x_vel = FLEE_SPEED if direction == 0 else -FLEE_SPEED


# ─── Bullet ───────────────────────────────────────────────────────────────────

func _fire_bullet() -> void:
	if not is_instance_valid(target):
		return

	var angle_deg := rad_to_deg(global_position.direction_to(target.global_position).angle())
	angle_deg += randf_range(-SHOOT_SPREAD_DEG, SHOOT_SPREAD_DEG)

	# TODO: instantiate a bullet scene here when it exists.
	# var bullet := BULLET_SCENE.instantiate()
	# bullet.global_position = global_position + Vector2(0.0, -5.0)
	# bullet.direction_deg   = angle_deg
	# bullet.damage          = BULLET_DAMAGE
	# bullet.owner_node      = self
	# get_parent().add_child(bullet)
	pass


# ─── Public API (called by spawner / random event system) ────────────────────

func setup(p_target: Node2D, p_dir: int, p_texture: Texture2D) -> void:
	target    = p_target
	direction = p_dir
	if is_instance_valid(p_target):
		stop_x = p_target.global_position.x
	if sprite:
		sprite.texture = p_texture
		sprite.flip_h  = (p_dir == 1)
