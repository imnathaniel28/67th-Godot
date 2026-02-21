extends Node
## EconomyManager — server-authoritative drug economy.
## Clients NEVER write money/inventory directly. They send requests; server validates and syncs back.
## Replaces scr_drug_prices.gml, scr_make_sale.gml.

# ─── Drug Types ─────────────────────────────────────────────────────────────────
enum DrugType { WEED = 0, PILLS = 1, COCAINE = 2, HEROIN = 3, METH = 4 }

const DRUG_NAMES: Dictionary = {
	DrugType.WEED:    "Weed",
	DrugType.PILLS:   "Pills",
	DrugType.COCAINE: "Coke",
	DrugType.HEROIN:  "H",
	DrugType.METH:    "Meth",
}

## Base price ranges per drug (matches GML scr_drug_prices.gml)
const PRICE_RANGES: Dictionary = {
	DrugType.WEED:    {"low": 15,  "high": 25},
	DrugType.PILLS:   {"low": 20,  "high": 35},
	DrugType.COCAINE: {"low": 40,  "high": 60},
	DrugType.HEROIN:  {"low": 50,  "high": 75},
	DrugType.METH:    {"low": 60,  "high": 90},
}

## NPC customer demand ranges (what they expect to pay — mirrors GML npc_customer Create_0)
const CUSTOMER_PRICE_RANGES: Dictionary = {
	DrugType.WEED:    {"low": 150, "high": 250},
	DrugType.PILLS:   {"low": 50,  "high": 150},
	DrugType.COCAINE: {"low": 400, "high": 600},
	DrugType.HEROIN:  {"low": 500, "high": 700},
	DrugType.METH:    {"low": 300, "high": 500},
}

## Location multipliers
const LA_PRICE_MULTIPLIER: float = 2.0

# ─── Signals (for UI and HUD updates) ───────────────────────────────────────────
signal sale_completed(peer_id: int, drug_name: String, amount: int)


# ─── Server-Side Sale Processing ─────────────────────────────────────────────────

func process_sale(seller_peer_id: int, drug_type: int) -> Dictionary:
	## Called ONLY by server systems (NPC AI, ShipmentSpawner, etc.)
	## Returns {success, amount, reason}
	if not multiplayer.is_server():
		push_error("EconomyManager.process_sale called on client!")
		return {"success": false, "amount": 0, "reason": "not_server"}

	var seller := PlayerRegistry.get_player(seller_peer_id)
	if seller == null:
		return {"success": false, "amount": 0, "reason": "no_player"}
	if seller.is_jailed:
		return {"success": false, "amount": 0, "reason": "jailed"}
	if not _has_drug(seller, drug_type):
		return {"success": false, "amount": 0, "reason": "no_stock"}

	var amount := calculate_sale_price(drug_type, seller.current_scene)
	_deduct_drug(seller, drug_type)
	PlayerRegistry.add_money(seller_peer_id, amount)
	seller.heat_level = minf(100.0, seller.heat_level + 2.0)
	seller.last_crime_time = GameState.time_elapsed

	# Sync economy state back to the client
	sync_economy_to_client(seller_peer_id)

	var drug_name := DRUG_NAMES.get(drug_type, "drugs")
	emit_signal("sale_completed", seller_peer_id, drug_name, amount)
	return {"success": true, "amount": amount, "reason": "ok"}


func calculate_sale_price(drug_type: int, scene_name: String) -> int:
	var range_data: Dictionary = PRICE_RANGES.get(drug_type, {"low": 10, "high": 30})
	var price := randi_range(range_data["low"], range_data["high"])

	if GameState.is_night:
		price = int(float(price) * GameState.night_price_multiplier)

	if scene_name == "LA":
		price = int(float(price) * LA_PRICE_MULTIPLIER)

	return price


func get_customer_payment(drug_type: int) -> int:
	## Returns what an NPC customer offers to pay (mirrors GML payment_amount)
	var range_data: Dictionary = CUSTOMER_PRICE_RANGES.get(drug_type, {"low": 50, "high": 150})
	return randi_range(range_data["low"], range_data["high"])


func get_drug_name(drug_type: int) -> String:
	return DRUG_NAMES.get(drug_type, "unknown")


# ─── Inventory helpers ────────────────────────────────────────────────────────────

func _has_drug(data: PlayerRegistry.PlayerData, drug_type: int) -> bool:
	match drug_type:
		DrugType.WEED:    return data.inv_weed    > 0
		DrugType.PILLS:   return data.inv_pills   > 0
		DrugType.COCAINE: return data.inv_cocaine > 0
		DrugType.HEROIN:  return data.inv_heroin  > 0
		DrugType.METH:    return data.inv_meth    > 0
	return false


func _deduct_drug(data: PlayerRegistry.PlayerData, drug_type: int) -> void:
	match drug_type:
		DrugType.WEED:    data.inv_weed    = maxi(0, data.inv_weed    - 1)
		DrugType.PILLS:   data.inv_pills   = maxi(0, data.inv_pills   - 1)
		DrugType.COCAINE: data.inv_cocaine = maxi(0, data.inv_cocaine - 1)
		DrugType.HEROIN:  data.inv_heroin  = maxi(0, data.inv_heroin  - 1)
		DrugType.METH:    data.inv_meth    = maxi(0, data.inv_meth    - 1)


# ─── Client Economy Sync (server → client) ────────────────────────────────────────

func sync_economy_to_client(peer_id: int) -> void:
	## Sends authoritative money + inventory to the specific client
	if not multiplayer.is_server():
		return
	var data := PlayerRegistry.get_player(peer_id)
	if data == null:
		return
	_rpc_receive_economy.rpc_id(peer_id,
		data.money,
		data.get_inventory_array(),
		data.heat_level)


func sync_economy_to_all() -> void:
	for pid in PlayerRegistry.all_player_ids():
		sync_economy_to_client(pid)


@rpc("authority", "call_local", "reliable")
func _rpc_receive_economy(money: int, inventory: Array, heat: float) -> void:
	## Runs on the client — update local PlayerData (HUD reads from here)
	var local := PlayerRegistry.get_local_player()
	if local == null:
		return
	local.money     = money
	local.heat_level = heat
	local.apply_inventory_array(inventory)


# ─── Client requests ──────────────────────────────────────────────────────────────

func client_request_sale(drug_type: int) -> void:
	## Client-side call — sends sale request to server
	_rpc_request_sale.rpc_id(1, drug_type)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_sale(drug_type: int) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	var result := process_sale(sender, drug_type)
	if result["success"]:
		NotificationBus.notify_player(sender,
			"+$%d (%s)" % [result["amount"], get_drug_name(drug_type)],
			Color.LIME_GREEN)
	else:
		NotificationBus.notify_player(sender,
			"No stock!", Color.YELLOW)
