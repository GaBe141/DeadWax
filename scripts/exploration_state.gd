extends RefCounted
## Permanent return passages, owned and persisted by Main. This model records
## opened shortcuts only; it never grants a move, loads a room, or writes disk.

const SAVE_VERSION := 1
const IDS: Array[StringName] = [&"warren_return", &"gallery_return"]

var _opened: Array[StringName] = []

static func default_snapshot() -> Dictionary:
	return {"version": SAVE_VERSION, "opened": []}

func reset() -> void:
	_opened.clear()

func is_open(id: StringName) -> bool:
	return id in _opened

func open_shortcut(id: StringName) -> bool:
	if id not in IDS or is_open(id):
		return false
	_opened.append(id)
	return true

func snapshot() -> Dictionary:
	var opened: Array[String] = []
	for id in IDS:
		if is_open(id):
			opened.append(String(id))
	return {"version": SAVE_VERSION, "opened": opened}

static func valid_snapshot(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 2:
		return false
	for key in value:
		if not key is String or key not in ["version", "opened"]:
			return false
	var version: Variant = value.get("version")
	if not (version is int or version is float) or not is_finite(float(version)) or version != SAVE_VERSION:
		return false
	var opened: Variant = value.get("opened")
	if not opened is Array or opened.size() > IDS.size():
		return false
	var unique: Array[String] = []
	for id in opened:
		if not id is String or StringName(id) not in IDS or id in unique:
			return false
		unique.append(id)
	return true

func restore_snapshot(value: Variant) -> bool:
	if not valid_snapshot(value):
		return false
	var restored: Array[StringName] = []
	for id in IDS:
		if String(id) in value.opened:
			restored.append(id)
	_opened = restored
	return true
