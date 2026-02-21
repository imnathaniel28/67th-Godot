extends Node
## GameState — replaces obj_game_controller (Create_0 + Step_0)
## Runs time system server-side, broadcasts to clients.
## All other autoloads read from this for time/scene info.

# ─── Time System ───────────────────────────────────────────────────────────────
const DAY_LENGTH_SECONDS := 300.0  # 5 real minutes = 1 in-game day (matches GML)
const NIGHT_START_HOUR   := 22
const NIGHT_END_HOUR     := 10

var time_elapsed:   float = 0.0   # seconds into current in-game day
var day_current:    int   = 1
var week_current:   int   = 1
var time_hours:     int   = 0
var time_minutes:   int   = 0
var is_night:       bool  = false
var night_alpha:    float = 0.0   # 0.0 = full day, 0.4 = full night overlay
var night_price_multiplier: float = 1.5

var _time_broadcast_timer: float = 0.0
const TIME_BROADCAST_INTERVAL := 1.0  # sync clients every real second

# ─── Game State Enum ────────────────────────────────────────────────────────────
enum GameStateEnum { MENU, PLAYING, PVP_CHOICE, DUEL, JAIL, CUTSCENE }
var game_state: GameStateEnum = GameStateEnum.MENU

# ─── Scene Registry ─────────────────────────────────────────────────────────────
## Maps scene name strings → .tscn paths (replaces scr_room_to_string)
const SCENE_MAP: Dictionary = {
	"Seattle":                "res://scenes/world/Seattle.tscn",
	"LA":                     "res://scenes/world/LA.tscn",
	"i5":                     "res://scenes/world/Highway_i5.tscn",
	"i5_2":                   "res://scenes/world/Highway_i5_2.tscn",
	"i5_3":                   "res://scenes/world/Highway_i5_3.tscn",
	"i5_4":                   "res://scenes/world/Highway_i5_4.tscn",
	"rm_jail_lobby":          "res://scenes/world/JailLobby.tscn",
	"rm_trap_house_interior": "res://scenes/world/TrapHouseInterior.tscn",
	"rm_generic_house":       "res://scenes/world/GenericHouseInterior.tscn",
	"rm_duel":                "res://scenes/world/DuelArena.tscn",
	"rm_customize":           "res://scenes/world/CustomizationRoom.tscn",
	"rm_menu":                "res://scenes/ui/MainMenu.tscn",
}

## Highway rooms where players cannot exit cars (mirrors GML list)
const HIGHWAY_SCENES: Array[String] = ["i5", "i5_2", "i5_3", "i5_4"]

# ─── Crosswalk Zones ────────────────────────────────────────────────────────────
## Mirrors GML crosswalk_zones array. NPCs use these to cross safely.
const CROSSWALK_ZONES: Array[Dictionary] = [
	{"x_min": 140, "x_max": 165},
	{"x_min": 655, "x_max": 690},
	{"x_min": 703, "x_max": 768},
	{"x_min": 1170, "x_max": 1215},
]
const STREET_Y_TOP:    float = 320.0
const STREET_Y_BOTTOM: float = 400.0

# ─── Debug ──────────────────────────────────────────────────────────────────────
var debug_mode: bool = false

# ─── Signals ────────────────────────────────────────────────────────────────────
signal day_changed(new_day: int, new_week: int)
signal time_updated(hours: int, minutes: int, is_night: bool)
signal game_state_changed(new_state: GameStateEnum)


func _process(delta: float) -> void:
	# Time only ticks on the server
	if not multiplayer.is_server():
		return

	_tick_time(delta)

	# Broadcast time to clients periodically
	_time_broadcast_timer += delta
	if _time_broadcast_timer >= TIME_BROADCAST_INTERVAL:
		_time_broadcast_timer = 0.0
		_rpc_sync_time.rpc(time_hours, time_minutes, is_night, night_alpha)

	# Debug hotkeys (server only)
	if OS.is_debug_build():
		if Input.is_action_just_pressed("debug_toggle"):
			debug_mode = !debug_mode
			print("Debug mode: ", debug_mode)


func _tick_time(delta: float) -> void:
	time_elapsed += delta

	# Day rollover
	if time_elapsed >= DAY_LENGTH_SECONDS:
		time_elapsed -= DAY_LENGTH_SECONDS
		day_current += 1
		if day_current > 7:
			day_current = 1
			week_current += 1
		emit_signal("day_changed", day_current, week_current)
		_rpc_day_changed.rpc(day_current, week_current)

	# Calculate hours and minutes (24-hour clock)
	var progress      := time_elapsed / DAY_LENGTH_SECONDS
	var total_minutes := int(progress * 1440.0)
	time_hours   = (total_minutes / 60) % 24
	time_minutes = total_minutes % 60

	# Day/night detection
	is_night = (time_hours >= NIGHT_START_HOUR or time_hours < NIGHT_END_HOUR)

	# Smooth night overlay alpha (mirrors GML lerp approach)
	var frac_hour := time_hours + (time_minutes / 60.0)
	var target_alpha: float

	if frac_hour >= 6.0 and frac_hour < 10.5:
		target_alpha = lerpf(0.4, 0.0, (frac_hour - 6.0) / 4.5)   # sunrise
	elif frac_hour >= 10.5 and frac_hour < 20.0:
		target_alpha = 0.0                                          # daytime
	elif frac_hour >= 20.0 and frac_hour < 23.0:
		target_alpha = lerpf(0.0, 0.4, (frac_hour - 20.0) / 3.0)  # sunset
	else:
		target_alpha = 0.4                                          # night

	night_alpha = lerpf(night_alpha, target_alpha, 0.05)
	emit_signal("time_updated", time_hours, time_minutes, is_night)


func get_time_string() -> String:
	## Returns formatted time like "10:30 PM" for HUD display
	var display_hour := time_hours % 12
	if display_hour == 0:
		display_hour = 12
	var am_pm := "PM" if time_hours >= 12 else "AM"
	var min_str := ("0" + str(time_minutes)) if time_minutes < 10 else str(time_minutes)
	return "%d:%s %s" % [display_hour, min_str, am_pm]


func set_game_state(new_state: GameStateEnum) -> void:
	game_state = new_state
	emit_signal("game_state_changed", new_state)


func scene_name_to_path(scene_name: String) -> String:
	return SCENE_MAP.get(scene_name, SCENE_MAP["Seattle"])


func path_to_scene_name(path: String) -> String:
	for name in SCENE_MAP:
		if SCENE_MAP[name] == path:
			return name
	return "Seattle"


func is_highway_scene(scene_name: String) -> bool:
	return HIGHWAY_SCENES.has(scene_name)


# ─── RPCs (server → clients) ────────────────────────────────────────────────────

@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_sync_time(hours: int, minutes: int, night: bool, alpha: float) -> void:
	time_hours  = hours
	time_minutes = minutes
	is_night    = night
	night_alpha = alpha
	emit_signal("time_updated", hours, minutes, night)


@rpc("authority", "call_remote", "reliable")
func _rpc_day_changed(day: int, week: int) -> void:
	day_current  = day
	week_current = week
	emit_signal("day_changed", day, week)
