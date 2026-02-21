extends CanvasLayer
## PlayerHUD — draws health bar, money, heat level, clock, and notifications.
## Attach to player scene or as a persistent UI layer.
## Replaces GML player1/Draw_64.gml + obj_game_controller/Draw_64.gml.
##
## Expects child nodes: HealthBar, MoneyLabel, HeatBar, ClockLabel, NotifLabel

@onready var health_bar:   ProgressBar = $HealthBar
@onready var money_label:  Label       = $MoneyLabel
@onready var heat_bar:     ProgressBar = $HeatBar
@onready var clock_label:  Label       = $ClockLabel
@onready var notif_label:  Label       = $NotifLabel
@onready var notif_timer:  Timer       = $NotifTimer

## Night overlay (full-screen dark blue tint, mirrors GML night overlay)
@onready var night_overlay: ColorRect  = $NightOverlay

var _notif_queue: Array[Dictionary] = []


func _ready() -> void:
	# Connect to game events
	GameState.time_updated.connect(_on_time_updated)
	NotificationBus.notification_received.connect(_on_notification)
	NotificationBus.phone_message_received.connect(_on_phone_message)

	# Night overlay setup
	if night_overlay:
		night_overlay.color = Color(0.039, 0.039, 0.157, 0.0)  # dark blue, initially transparent
		night_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		night_overlay.anchors_preset = Control.PRESET_FULL_RECT

	if notif_timer:
		notif_timer.timeout.connect(_show_next_notification)


func _process(_delta: float) -> void:
	var data := PlayerRegistry.get_local_player()
	if data == null:
		return

	# ── Health bar ──
	if health_bar:
		health_bar.max_value = data.max_health
		health_bar.value     = data.health
		# Color: green > 60%, yellow > 30%, red otherwise (mirrors GML draw_healthbar)
		var pct := data.health / data.max_health
		if pct > 0.6:
			health_bar.modulate = Color.GREEN
		elif pct > 0.3:
			health_bar.modulate = Color.YELLOW
		else:
			health_bar.modulate = Color.RED

	# ── Money label ──
	if money_label:
		money_label.text = "$" + _format_money(data.money)

	# ── Heat bar ──
	if heat_bar:
		heat_bar.max_value = 100
		heat_bar.value     = data.heat_level

	# ── Night overlay ──
	if night_overlay:
		night_overlay.color = Color(0.039, 0.039, 0.157, GameState.night_alpha)


func _on_time_updated(hours: int, minutes: int, is_night: bool) -> void:
	if clock_label:
		clock_label.text = GameState.get_time_string()
		clock_label.modulate = Color.CYAN if is_night else Color.YELLOW


func _on_notification(message: String, color: Color) -> void:
	_notif_queue.append({"text": message, "color": color})
	if notif_timer and notif_timer.is_stopped():
		_show_next_notification()


func _show_next_notification() -> void:
	if _notif_queue.is_empty():
		if notif_label:
			notif_label.visible = false
		return

	var notif: Dictionary = _notif_queue.pop_front()
	if notif_label:
		notif_label.text     = notif["text"]
		notif_label.modulate = notif["color"]
		notif_label.visible  = true

	if notif_timer:
		notif_timer.start(2.5)


func _on_phone_message(sender: String, message: String) -> void:
	## Phone messages get shown as persistent notifications in a phone UI
	## For now, show as a notification toast
	_on_notification("[%s]: %s" % [sender, message], Color.ORANGE)


func _format_money(amount: int) -> String:
	## Formats large numbers with commas: 1234567 → "1,234,567"
	var s    := str(amount)
	var result := ""
	var count  := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count  += 1
	return result
