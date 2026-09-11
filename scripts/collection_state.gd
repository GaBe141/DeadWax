extends RefCounted
## Main owns this carried collection. Rolls, salvage and pity form one snapshot
## so a failed checkpoint can restore the entire transaction, including chance.

const Catalog := preload("res://scripts/collection_catalog.gd")
const CRAFT_COST := Catalog.CRAFT_COST
const PITY_WINS := Catalog.PITY_WINS
const MAX_COUNT := 1000000
const MAX_OFFCUTS := 1000000000
const RNG_MODULUS := 2147483647
const DEFAULT_SEED := 104729
const ROOT_KEYS := ["version", "owned", "equipped", "offcuts", "rng_state", "hunts", "bestiary"]
const MULTIPLIERS := ["speed", "accel", "friction", "air_control", "hood_speed", "noise_decay"]

var _data: Dictionary = default_snapshot()

static func default_snapshot() -> Dictionary:
	var result := {"version": 1, "owned": [], "equipped": {"needle": "", "lining": "", "charm": ""},
		"offcuts": 0, "rng_state": DEFAULT_SEED, "hunts": {}, "bestiary": {}}
	for hunt in Catalog.HUNTS:
		result.hunts[hunt.id] = {"discovered": false, "wins": 0, "dry": 0}
	for species in Catalog.SPECIES:
		result.bestiary[species.id] = {"seen": false, "freed": 0, "shattered": 0}
	return result

func snapshot() -> Dictionary:
	return _data.duplicate(true)

func reset() -> void:
	_data = default_snapshot()
	# One campaign seed, persisted before its first trial. No per-drop global RNG.
	_data.rng_state = randi_range(1, RNG_MODULUS - 1)

static func valid_snapshot(value: Variant) -> bool:
	if not _exact_keys(value, ROOT_KEYS) or not _integer(value.version, 1, 1):
		return false
	if not _integer(value.offcuts, 0, MAX_OFFCUTS) or not _integer(value.rng_state, 1, RNG_MODULUS - 1):
		return false
	if not value.owned is Array or value.owned.size() > Catalog.ITEMS.size():
		return false
	var unique: Array[String] = []
	for id in value.owned:
		if not id is String or Catalog.item(id).is_empty() or id in unique:
			return false
		unique.append(id)
	if not _exact_keys(value.equipped, Catalog.SLOTS):
		return false
	for slot in Catalog.SLOTS:
		var id: Variant = value.equipped[slot]
		if not id is String:
			return false
		if not id.is_empty() and (id not in unique or Catalog.item(id).get("slot", "") != slot):
			return false
	var hunt_ids: Array[String] = []
	for hunt in Catalog.HUNTS:
		hunt_ids.append(hunt.id)
	if not _known_keys(value.hunts, hunt_ids):
		return false
	for id in value.hunts:
		var record: Variant = value.hunts[id]
		if not _exact_keys(record, ["discovered", "wins", "dry"]) or not record.discovered is bool:
			return false
		if not _integer(record.wins, 0, MAX_COUNT) or not _integer(record.dry, 0, PITY_WINS - 1):
			return false
		if record.dry > record.wins or (not record.discovered and record.wins != 0):
			return false
	var species_ids: Array[String] = []
	for species in Catalog.SPECIES:
		species_ids.append(species.id)
	if not _known_keys(value.bestiary, species_ids):
		return false
	for id in value.bestiary:
		var record: Variant = value.bestiary[id]
		if not _exact_keys(record, ["seen", "freed", "shattered"]) or not record.seen is bool:
			return false
		if not _integer(record.freed, 0, MAX_COUNT) or not _integer(record.shattered, 0, MAX_COUNT):
			return false
		if not record.seen and (record.freed != 0 or record.shattered != 0):
			return false
	return true

func restore_snapshot(value: Variant) -> bool:
	if not valid_snapshot(value):
		return false
	_data = value.duplicate(true)
	# Adding a known species or trial later leaves old books valid and unseen.
	# Supplied records remain strict; unknown IDs never enter the model.
	var defaults := default_snapshot()
	for field in ["hunts", "bestiary"]:
		for id in defaults[field]:
			if not _data[field].has(id):
				_data[field][id] = defaults[field][id].duplicate(true)
	for key in ["version", "offcuts", "rng_state"]:
		_data[key] = int(_data[key])
	for record in _data.hunts.values():
		record.wins = int(record.wins)
		record.dry = int(record.dry)
	for record in _data.bestiary.values():
		record.freed = int(record.freed)
		record.shattered = int(record.shattered)
	return true

func has_item(id: String) -> bool:
	return id in _data.owned

func equip(id: String) -> bool:
	if not has_item(id):
		return false
	var item := Catalog.item(id)
	if _data.equipped[item.slot] == id:
		return false
	_data.equipped[item.slot] = id
	return true

func unequip(slot: String) -> bool:
	if slot not in Catalog.SLOTS or _data.equipped[slot].is_empty():
		return false
	_data.equipped[slot] = ""
	return true

func modifiers() -> Dictionary:
	var result := {"speed": 1.0, "accel": 1.0, "friction": 1.0, "air_control": 1.0,
		"hood_speed": 1.0, "noise_decay": 1.0, "health": 0}
	for id in _data.equipped.values():
		var item := Catalog.item(id)
		for key in item.get("modifiers", {}):
			if key == "health":
				result.health += int(item.modifiers[key])
			else:
				result[key] *= float(item.modifiers[key])
	for key in MULTIPLIERS:
		result[key] = clampf(result[key], 0.65, 1.4)
	result.health = clampi(result.health, -1, 1)
	return result

func discover_hunt(id: String) -> bool:
	if not _data.hunts.has(id) or _data.hunts[id].discovered:
		return false
	_data.hunts[id].discovered = true
	return true

func finish_hunt(id: String) -> Dictionary:
	if not _data.hunts.has(id) or not _data.hunts[id].discovered or _data.hunts[id].wins >= MAX_COUNT:
		return {}
	var record: Dictionary = _data.hunts[id]
	var pool: Array[Dictionary] = []
	var missing: Array[Dictionary] = []
	for item in Catalog.ITEMS:
		if item.source == id:
			pool.append(item)
			if not has_item(item.id):
				missing.append(item)
	record.wins += 1
	record.dry += 1
	var roll := _next_random() % 100
	var item_id := ""
	var pity: bool = record.dry >= PITY_WINS
	if pity:
		var candidates: Array[Dictionary] = missing if not missing.is_empty() else pool
		item_id = candidates[_next_random() % candidates.size()].id
	else:
		var threshold := 0
		for item in pool:
			threshold += int(item.drop_chance)
			if roll < threshold:
				item_id = item.id
				break
	var duplicate := not item_id.is_empty() and has_item(item_id)
	if not item_id.is_empty():
		record.dry = 0
		if not duplicate:
			_data.owned.append(item_id)
	var before: int = _data.offcuts
	_data.offcuts = mini(MAX_OFFCUTS, before + (6 if duplicate else 1))
	return {"hunt_id": id, "item_id": item_id, "duplicate": duplicate, "pity": pity,
		"offcuts": int(_data.offcuts) - before, "total_offcuts": _data.offcuts,
		"wins": record.wins, "dry": record.dry}

func can_craft(id: String) -> bool:
	var item := Catalog.item(id)
	return not item.is_empty() and not has_item(id) and _data.offcuts >= CRAFT_COST and _data.hunts[item.source].wins > 0

func craft(id: String) -> bool:
	if not can_craft(id):
		return false
	_data.offcuts -= CRAFT_COST
	_data.owned.append(id)
	return true

func record_species(id: String, outcome := "seen") -> bool:
	if not _data.bestiary.has(id) or outcome not in ["seen", "freed", "shattered"]:
		return false
	var record: Dictionary = _data.bestiary[id]
	var changed: bool = not record.seen
	record.seen = true
	if outcome != "seen" and record[outcome] < MAX_COUNT:
		record[outcome] += 1
		changed = true
	return changed

func backfill(encounters: Dictionary) -> bool:
	# The immutable campaign ledger supplies historical minima. Re-reading it
	# never increments counters already recorded by live resolution events.
	var minima: Dictionary = {}
	for key in encounters:
		if not key is String:
			continue
		var species := Catalog.species_for_encounter(key)
		var outcome: Variant = encounters[key]
		if species.is_empty() or not outcome is String or outcome not in ["freed", "shattered", "won"]:
			continue
		if not minima.has(species):
			minima[species] = {"freed": 0, "shattered": 0}
		if outcome != "won":
			minima[species][outcome] += 1
	var changed := false
	for id in minima:
		var record: Dictionary = _data.bestiary[id]
		if not record.seen:
			record.seen = true
			changed = true
		for outcome in ["freed", "shattered"]:
			if record[outcome] < minima[id][outcome]:
				record[outcome] = minima[id][outcome]
				changed = true
	return changed

func completion_snapshot() -> Dictionary:
	var result := {"gear_found": _data.owned.size(), "gear_total": Catalog.ITEMS.size(),
		"mastery_wins": 0, "mastery_total": Catalog.MASTERY_WINS * Catalog.HUNTS.size(),
		"hunts_mastered": 0, "hunts_total": Catalog.HUNTS.size(), "species_seen": 0, "species_total": Catalog.SPECIES.size()}
	for record in _data.hunts.values():
		result.mastery_wins += mini(record.wins, Catalog.MASTERY_WINS)
		if record.wins >= Catalog.MASTERY_WINS:
			result.hunts_mastered += 1
	for record in _data.bestiary.values():
		if record.seen:
			result.species_seen += 1
	return result

func _next_random() -> int:
	_data.rng_state = (int(_data.rng_state) * 48271) % RNG_MODULUS
	return int(_data.rng_state)

static func _exact_keys(value: Variant, keys: Array) -> bool:
	if not value is Dictionary or value.size() != keys.size():
		return false
	for key in keys:
		if not value.has(key):
			return false
	return true

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is int or value is float):
		return false
	if value is float and (not is_finite(value) or value != floor(value)):
		return false
	return value >= minimum and value <= maximum

static func _known_keys(value: Variant, keys: Array) -> bool:
	if not value is Dictionary or value.size() > keys.size():
		return false
	for key in value:
		if not key is String or key not in keys:
			return false
	return true
