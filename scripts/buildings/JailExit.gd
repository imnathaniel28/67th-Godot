extends Area2D
## JailExit — placed in JailLobby.tscn near the cell door.
## When the player overlaps and presses [E], transitions back to Seattle.
## Mirrors GML obj_jail_exit/Step_0.gml behavior.

# The scene to return to when leaving jail
const SEATTLE_SCENE := "res://seattle.tscn"
const PROMPT_TEXT   := "[E] Exit Jail"

var _prompt: Label
var _player_inside: bool = false


func _ready() -> void:
	# Self-contained prompt label — no manual child node needed in the editor
	_prompt = Label.new()
	_prompt.text = PROMPT_TEXT
	_prompt.position = Vector2(-40, -36)
	_prompt.modulate = Color.CYAN
	_prompt.visible = false
	add_child(_prompt)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _player_inside and Input.is_action_just_pressed("interact"):
		get_tree().change_scene_to_file(SEATTLE_SCENE)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_inside = true
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_inside = false
		_prompt.visible = false
