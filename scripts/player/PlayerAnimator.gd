extends Node
## PlayerAnimator — handles sprite/animation state for the player.
## Attach as child of Player. Reads facing + velocity from parent Player node.
## Mirrors GML player1/Draw_0.gml sprite switching logic.
##
## Expected AnimationPlayer animations: idle_up, idle_down, idle_left, idle_right,
##   walk_up, walk_down, walk_left, walk_right

@onready var anim_player: AnimationPlayer = $"../AnimationPlayer"
@onready var sprite:      Sprite2D        = $"../Sprite2D"

## Skin tone color modulate (mirrors GML skin_tone_colors array)
const SKIN_TONE_COLORS: Array[Color] = [
	Color(1.0,  1.0,  1.0),         # 0 — default
	Color(0.871, 0.722, 0.529),      # 1 — light tan
	Color(0.722, 0.522, 0.337),      # 2 — medium tan
	Color(0.545, 0.353, 0.169),      # 3 — brown
	Color(0.302, 0.169, 0.051),      # 4 — dark brown
]

var _current_anim: String = ""


func _ready() -> void:
	var player := get_parent() as CharacterBody2D
	if player and player.has_signal("facing_changed"):
		pass  # Could connect if signal exists


func update(velocity: Vector2, facing: String, skin_tone: int) -> void:
	## Called every frame by Player._process()
	_update_animation(velocity, facing)
	_update_skin_tone(skin_tone)


func _update_animation(velocity: Vector2, facing: String) -> void:
	if not anim_player:
		return

	var moving    := velocity.length() > 1.0
	var anim_name := ("walk_" if moving else "idle_") + facing

	if anim_player.has_animation(anim_name) and _current_anim != anim_name:
		anim_player.play(anim_name)
		_current_anim = anim_name


func _update_skin_tone(skin_tone: int) -> void:
	if not sprite:
		return
	var idx   := clampi(skin_tone, 0, SKIN_TONE_COLORS.size() - 1)
	sprite.modulate = SKIN_TONE_COLORS[idx]
