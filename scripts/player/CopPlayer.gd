extends CharacterBody2D
## CopPlayer — player-controlled cop character.
## Uses arrow keys / WASD for movement, switches between
## AnimatedSprite2D nodes for idle and run animations in all 4 directions.

const WALK_SPEED := 90.0

@onready var idle_l:    AnimatedSprite2D = $idle_l
@onready var idle_r:    AnimatedSprite2D = $idle_r
@onready var idle_down: AnimatedSprite2D = $idle_down
@onready var run_r:     AnimatedSprite2D = $Run_r
@onready var run_l:     AnimatedSprite2D = $Run_l
@onready var run_up:    AnimatedSprite2D = $Run_up
@onready var run_down:  AnimatedSprite2D = $Run_down

var facing: String = "down"


func _ready() -> void:
	var cam := Camera2D.new()
	cam.make_current()
	add_child(cam)

	_show_only(idle_down)
	idle_down.play()


func _physics_process(_delta: float) -> void:
	# DEBUG: J key → go to jail lobby for testing
	if Input.is_action_just_pressed("go_to_jail"):
		get_tree().change_scene_to_file("res://scenes/world/JailLobby.tscn")
		return

	var input_dir := _get_input_direction()
	velocity = input_dir * WALK_SPEED
	move_and_slide()

	# Update facing — horizontal takes priority over vertical
	if input_dir.x > 0.1:
		facing = "right"
	elif input_dir.x < -0.1:
		facing = "left"
	elif input_dir.y > 0.1:
		facing = "down"
	elif input_dir.y < -0.1:
		facing = "up"

	var moving := velocity.length() > 1.0
	if moving:
		match facing:
			"right": _show_only(run_r);    run_r.play()
			"left":  _show_only(run_l);    run_l.play()
			"up":    _show_only(run_up);   run_up.play()
			"down":  _show_only(run_down); run_down.play()
	else:
		match facing:
			"right": _show_only(idle_r);    idle_r.play()
			"left":  _show_only(idle_l);    idle_l.play()
			"down":  _show_only(idle_down); idle_down.play()
			"up":    _show_only(idle_l);    idle_l.play()  # no idle_up sprite yet


func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1.0
	if Input.is_action_pressed("ui_left"):  dir.x -= 1.0
	if Input.is_action_pressed("ui_down"):  dir.y += 1.0
	if Input.is_action_pressed("ui_up"):    dir.y -= 1.0
	return dir.normalized()


func _show_only(active: AnimatedSprite2D) -> void:
	idle_l.visible    = (active == idle_l)
	idle_r.visible    = (active == idle_r)
	idle_down.visible = (active == idle_down)
	run_r.visible     = (active == run_r)
	run_l.visible     = (active == run_l)
	run_up.visible    = (active == run_up)
	run_down.visible  = (active == run_down)
