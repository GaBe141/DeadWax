extends RefCounted
## Main owns earned move permissions separately from knowledge and Refrains.
## New journeys start with movement alone. Missing legacy save data explicitly
## restores the complete old moveset; the model never chooses that migration.

const SAVE_VERSION := 1
const IDS: Array[StringName] = [&"strike", &"set", &"hood", &"combo", &"groove", &"pogo"]
const CATALOG: Array[Dictionary] = [
	{"id": &"strike", "name": "STRIKE", "description": "Press J / X to strike or parry. Each strike recovers in 0.2 seconds; meet an incoming attack within the first 0.1 seconds to parry. Your first strike is a single Tap.",
		"lead": "A needle waits on the Headshell's lower floor.", "room_id": &"headshell", "position": Vector2(365, 554), "outcome_key": ""},
	{"id": &"set", "name": "SET", "description": "Hold L / LB to kneel and Set. Answer a listening voice in its silence and resolve encounters through patient responses.",
		"lead": "Follow the Headshell floor toward its eastern passage.", "room_id": &"headshell", "position": Vector2(890, 554), "outcome_key": ""},
	{"id": &"hood", "name": "HOOD", "description": "Hold K or C / B to raise the Hood. Move quietly, damp your noise, listen to voices before answering with Set, and polish marked wax for Shine.",
		"lead": "Climb the upper walk of High Street.", "room_id": &"high_street", "position": Vector2(1100, 359), "outcome_key": ""},
	{"id": &"combo", "name": "THREE-STRIKE CHAIN", "description": "Link fresh strikes within 0.65 seconds: Tap, Sweep, then Accent. The final Accent hits hard. Holding strike never repeats it; parry timing and reach stay the same.",
		"lead": "Look along the Groove Yard's western approach.", "room_id": &"groove_yard", "position": Vector2(610, 574), "outcome_key": ""},
	{"id": &"groove", "name": "GROOVE RIDING", "description": "Strike a live groove to launch along it. In thick air, strike while steering to spend a breath on a directional jet. The room restores your breaths when you land.",
		"lead": "Open the Count-In door in the Practice Room, then search beyond it.", "room_id": &"practice_room", "position": Vector2(1320, 574), "outcome_key": "practice_room/practice_count_in"},
	{"id": &"pogo", "name": "POGO", "description": "Strike a vulnerable foe while airborne to rebound. Jumping and striking together counts. Guarded and muted foes cannot launch you; grounded strikes keep your footing.",
		"lead": "Search the lower resting shelf of the Overture Well.", "room_id": &"overture_well", "position": Vector2(785, 794), "outcome_key": ""},
]

var _unlocked: Array[StringName] = []

static func default_snapshot() -> Dictionary:
	return {"version": SAVE_VERSION, "unlocked": []}

static func legacy_snapshot() -> Dictionary:
	var unlocked: Array[String] = []
	for id in IDS:
		unlocked.append(String(id))
	return {"version": SAVE_VERSION, "unlocked": unlocked}

static func catalog() -> Array[Dictionary]:
	return CATALOG.duplicate(true)

static func ability(id: StringName) -> Dictionary:
	for entry in CATALOG:
		if entry.id == id:
			return entry.duplicate(true)
	return {}

func reset() -> void:
	_unlocked.clear()

func has_ability(id: StringName) -> bool:
	return id in _unlocked

func unlock_ability(id: StringName) -> bool:
	if id not in IDS or has_ability(id):
		return false
	_unlocked.append(id)
	return true

func snapshot() -> Dictionary:
	var unlocked: Array[String] = []
	for id in IDS:
		if has_ability(id):
			unlocked.append(String(id))
	return {"version": SAVE_VERSION, "unlocked": unlocked}

static func valid_snapshot(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 2:
		return false
	for key in value:
		if not key is String or key not in ["version", "unlocked"]:
			return false
	var version: Variant = value.get("version")
	if not (version is int or version is float) or not is_finite(float(version)) or version != SAVE_VERSION:
		return false
	var unlocked: Variant = value.get("unlocked")
	if not unlocked is Array or unlocked.size() > IDS.size():
		return false
	var unique: Array[String] = []
	for id in unlocked:
		if not id is String or StringName(id) not in IDS or id in unique:
			return false
		unique.append(id)
	return true

func restore_snapshot(value: Variant) -> bool:
	if not valid_snapshot(value):
		return false
	var restored: Array[StringName] = []
	for id in IDS:
		if String(id) in value.unlocked:
			restored.append(id)
	_unlocked = restored
	return true
