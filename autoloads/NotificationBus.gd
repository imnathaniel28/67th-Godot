extends Node
## NotificationBus — server pushes toast notifications and phone messages to specific clients.
## Replaces scr_notify() and phone_add_message() from GML.
## UI components connect to the signals below to display messages.

# ─── Signals (clients connect to these) ─────────────────────────────────────────
signal notification_received(message: String, color: Color)
signal phone_message_received(sender: String, message: String)
signal sale_popup_received(amount: int, drug_name: String, position: Vector2)

# ─── Server → specific client ────────────────────────────────────────────────────

func notify_player(peer_id: int, message: String, color: Color = Color.WHITE) -> void:
	if not multiplayer.is_server():
		return
	_rpc_receive_notification.rpc_id(peer_id, message, color)


func notify_all(message: String, color: Color = Color.WHITE) -> void:
	if not multiplayer.is_server():
		return
	_rpc_receive_notification.rpc(message, color)


func send_phone_message(peer_id: int, sender: String, message: String) -> void:
	if not multiplayer.is_server():
		return
	_rpc_receive_phone_message.rpc_id(peer_id, sender, message)


func show_sale_popup(peer_id: int, amount: int, drug_name: String, px: float, py: float) -> void:
	## Shows floating "+$X" popup at world position (mirrors obj_sale_popup from GML)
	if not multiplayer.is_server():
		return
	_rpc_receive_sale_popup.rpc_id(peer_id, amount, drug_name, px, py)


# ─── Local helpers (for when server is also a client, i.e. solo play) ────────────

func notify_local(message: String, color: Color = Color.WHITE) -> void:
	emit_signal("notification_received", message, color)


# ─── RPCs ────────────────────────────────────────────────────────────────────────

@rpc("authority", "call_local", "reliable")
func _rpc_receive_notification(message: String, color: Color) -> void:
	emit_signal("notification_received", message, color)


@rpc("authority", "call_local", "reliable")
func _rpc_receive_phone_message(sender: String, message: String) -> void:
	emit_signal("phone_message_received", sender, message)


@rpc("authority", "call_local", "reliable")
func _rpc_receive_sale_popup(amount: int, drug_name: String, px: float, py: float) -> void:
	emit_signal("sale_popup_received", amount, drug_name, Vector2(px, py))
