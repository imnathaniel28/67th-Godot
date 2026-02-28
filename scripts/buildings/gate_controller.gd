extends AnimatedSprite2D

# How close the player needs to be to open the gate (in pixels)
@export var open_distance: float = 20.0

var player: Node2D
var gate_open := false
@onready var gate_marker = $GateMarker2D
@onready var gate_shape = $GateCollision/CollisionShape2D

func _ready():
	sprite_frames.set_animation_loop("default", false)
	frame = 0
	stop()
	animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	# Only unlock the gate after the open animation fully completes
	if gate_open:
		if gate_shape:
			gate_shape.disabled = true

func _process(_delta):
	if not player:
		player = get_node_or_null("../../CivilianArab")
		return

	var dist = gate_marker.global_position.distance_to(player.global_position)

	if dist < open_distance and not gate_open:
		gate_open = true
		play("default")           # collision stays blocking until animation_finished

	elif dist >= open_distance and gate_open:
		gate_open = false
		if gate_shape:
			gate_shape.disabled = false  # re-block immediately when player walks away
		play_backwards("default")
