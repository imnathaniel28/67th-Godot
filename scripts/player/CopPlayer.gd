extends CharacterBody2D
## CopPlayer — player-controlled cop character.
## Uses arrow keys / WASD for movement, switches between
## AnimatedSprite2D nodes for idle and run animations.

const WALK_SPEED := 90.0

# References to the 4 AnimatedSprite2D nodes in the scene
@onready var idle_l: AnimatedSprite2D = $idle_l
@onready var idle_r: AnimatedSprite2D = $idle_r
@onready var run_r:  AnimatedSprite2D = $Run_r
@onready var run_l:  AnimatedSprite2D = $Run_l

var facing: String = "left"


func _ready() -> void:
	# Add a camera so we can see the cop
	var cam := Camera2D.new()
	cam.make_current()
	add_child(cam)

	# Start with idle_l visible, everything else hidden
	_show_only(idle_l)
	idle_l.play()


func _physics_process(_delta: float) -> void:
	var input_dir := _get_input_direction()
	velocity = input_dir * WALK_SPEED
	move_and_slide()

	# Update facing based on horizontal input
	if input_dir.x > 0.1:
		facing = "right"
	elif input_dir.x < -0.1:
		facing = "left"

	# Pick the right animation node
	var moving := velocity.length() > 1.0
	if moving:
		if facing == "right":
			_show_only(run_r)
			run_r.play()
		else:
			_show_only(run_l)
			run_l.play()
	else:
		if facing == "right":
			_show_only(idle_r)
			idle_r.play()
		else:
			_show_only(idle_l)
			idle_l.play()


func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1.0
	if Input.is_action_pressed("ui_left"):  dir.x -= 1.0
	if Input.is_action_pressed("ui_down"):  dir.y += 1.0
	if Input.is_action_pressed("ui_up"):    dir.y -= 1.0
	return dir.normalized()


func _show_only(active: AnimatedSprite2D) -> void:
	idle_l.visible = (active == idle_l)
	idle_r.visible = (active == idle_r)
	run_r.visible  = (active == run_r)
	run_l.visible  = (active == run_l)
