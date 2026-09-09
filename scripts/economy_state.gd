extends RefCounted
## Main owns this purse. The model changes balance and ownership atomically;
## saving, rollback, rewards and applying the effects belong to its caller.

const MAX_BALANCE := 2147483647
const BASE_HEALTH := 3
const BASE_HOOD_SPEED := 0.62
const LINED_HOOD_SPEED := 0.75
const CATALOG: Array[Dictionary] = [
	{
		"id": &"spare_groove", "name": "Spare Groove", "price": 4,
		"description": "One more notch for your needle.\nMaximum needle health: 3 → 4.",
	},
	{
		"id": &"soft_lining", "name": "Soft Lining", "price": 3,
		"description": "A softer sleeve, a quicker quiet step.\nMove faster with your Hood raised.",
	},
	{
		"id": &"warm_thread", "name": "Warm Thread", "price": 2,
		"description": "A little amber stitching for your Hood.\nJust something warm to wear.",
	},
]

var _balance := 0
var _owned: Array[String] = []
var balance: int:
	get:
		return _balance

static func catalog() -> Array[Dictionary]:
	return CATALOG.duplicate(true)

static func item(id: StringName) -> Dictionary:
	for entry in CATALOG:
		if entry.id == id:
			return entry.duplicate(true)
	return {}

static func valid_shine(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number := float(value)
	return is_finite(number) and number >= 0 and number <= MAX_BALANCE and number == floor(number)

static func valid_purchases(value: Variant) -> bool:
	if not (value is Array) or value.size() > CATALOG.size():
		return false
	var seen: Array[String] = []
	for id in value:
		if not (id is String) or seen.has(id) or item(StringName(id)).is_empty():
			return false
		seen.append(id)
	return true

func credit(amount: int) -> bool:
	if amount <= 0 or amount > MAX_BALANCE or _balance > MAX_BALANCE - amount:
		return false
	_balance += amount
	return true

func has_item(id: StringName) -> bool:
	return _owned.has(String(id))

func can_purchase(id: StringName) -> bool:
	var entry := item(id)
	return not entry.is_empty() and not has_item(id) and _balance >= int(entry.price)

func purchase(id: StringName) -> bool:
	if not can_purchase(id):
		return false
	_balance -= int(item(id).price)
	_owned.append(String(id))
	return true

func reset() -> void:
	_balance = 0
	_owned.clear()

func restore(shine: Variant, purchases: Variant = []) -> bool:
	if not valid_shine(shine) or not valid_purchases(purchases):
		return false
	var restored: Array[String] = []
	for id in purchases:
		restored.append(id)
	_balance = int(shine)
	_owned = restored
	return true

func snapshot() -> Dictionary:
	return {"shine": _balance, "purchases": _owned.duplicate()}

func max_health() -> int:
	return BASE_HEALTH + (1 if has_item(&"spare_groove") else 0)

func hood_speed_multiplier() -> float:
	return LINED_HOOD_SPEED if has_item(&"soft_lining") else BASE_HOOD_SPEED
