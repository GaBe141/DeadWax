extends SceneTree
## Move permissions are explicit campaign state, with a deliberate legacy
## migration. Validation cannot partly replace an already earned moveset.

const Abilities := preload("res://scripts/abilities_state.gd")
const EXPECTED_IDS: Array[StringName] = [&"strike", &"set", &"hood", &"combo", &"groove", &"pogo"]
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_permissions()
	_check_validation()
	_check_catalog()
	if _failures.is_empty():
		print("DEAD WAX ABILITIES STATE PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("ABILITIES STATE FAIL: " + failure)
	quit(1)

func _check_permissions() -> void:
	var state := Abilities.new()
	_check(state.snapshot() == Abilities.default_snapshot(), "new model starts with no earned moves")
	for id in EXPECTED_IDS:
		_check(not state.has_ability(id), "fresh journey has no " + String(id))
		_check(state.unlock_ability(id) and state.has_ability(id), "each real move can be earned: " + String(id))
		_check(not state.unlock_ability(id), "earning a move twice is inert: " + String(id))
	_check(not state.unlock_ability(&"invented") and not state.has_ability(&"invented"), "unknown permissions never enter the model")
	_check(state.snapshot() == Abilities.legacy_snapshot(), "legacy compatibility grants exactly the old six permissions")
	var copy := state.snapshot()
	copy.unlocked.clear()
	copy.version = 99
	_check(state.snapshot() == Abilities.legacy_snapshot(), "snapshot callers cannot mutate earned permissions")
	state.reset()
	_check(state.snapshot() == Abilities.default_snapshot(), "New Game reset removes every ability")
	_check(state.restore_snapshot(Abilities.legacy_snapshot()), "explicit legacy restoration succeeds")
	state.reset()
	_check(state.restore_snapshot({"version": 1, "unlocked": ["pogo", "strike"]}), "partial snapshots restore without demanding unrelated abilities")
	_check(state.snapshot().unlocked == ["strike", "pogo"], "snapshots normalize earned IDs to stable catalog-independent order")
	var input := {"version": 1, "unlocked": ["hood"]}
	_check(state.restore_snapshot(input), "valid replacement restores the supplied permission")
	input.unlocked.append("set")
	_check(state.has_ability(&"hood") and not state.has_ability(&"set") and not state.has_ability(&"strike"), "restoration owns its state and replaces stale permissions")
	var empty := Abilities.default_snapshot()
	empty.unlocked.append("strike")
	_check(Abilities.default_snapshot().unlocked.is_empty(), "default snapshots never share their array")
	var legacy := Abilities.legacy_snapshot()
	legacy.unlocked.clear()
	_check(Abilities.legacy_snapshot().unlocked.size() == EXPECTED_IDS.size(), "legacy snapshots never share their array")

func _check_validation() -> void:
	var state := Abilities.new()
	state.unlock_ability(&"hood")
	var before := state.snapshot()
	var invalid: Array = [null, false, true, 0, [], {}, "abilities", {"version": 1}, {"unlocked": []},
		{"version": 1, "unlocked": [], "extra": true}]
	for bad in [null, true, false, "1", -1, 0, 2, 0.5, 1.5, INF, -INF, NAN, 1e30, [], {}]:
		invalid.append({"version": bad, "unlocked": []})
	for bad in [null, false, true, 1, "strike", {}, ["invented"], ["strike", "strike"], [true], [0], [null], [&"strike"],
		["strike", "set", "hood", "combo", "groove", "pogo", "strike"]]:
		invalid.append({"version": 1, "unlocked": bad})
	for value in invalid:
		_check(not Abilities.valid_snapshot(value), "malformed state is rejected: " + str(value))
		_check(not state.restore_snapshot(value) and state.snapshot() == before, "failed restoration preserves the complete previous moveset")
	for value in [Abilities.default_snapshot(), Abilities.legacy_snapshot(), {"version": 1.0, "unlocked": ["set"]}]:
		_check(Abilities.valid_snapshot(value), "valid in-memory and JSON whole versions are accepted")
		var parsed: Variant = JSON.parse_string(JSON.stringify(value))
		_check(state.restore_snapshot(parsed) and Abilities.valid_snapshot(state.snapshot()), "JSON round trip retains a validated permission state")

func _check_catalog() -> void:
	var entries := Abilities.catalog()
	_check(entries.size() == EXPECTED_IDS.size(), "six authored move discoveries")
	var seen: Array[StringName] = []
	for entry in entries:
		_check(entry.id in EXPECTED_IDS and entry.id not in seen, "unique recognized discovery ID: " + String(entry.id))
		seen.append(entry.id)
		_check(entry.name is String and not entry.name.is_empty() and entry.description is String and not entry.description.is_empty(), "each discovery has a readable name and use")
		_check(entry.lead is String and not entry.lead.is_empty() and entry.room_id is StringName and entry.position is Vector2 and entry.position.is_finite(), "each discovery carries an authored room, fixed origin and lead")
		_check(entry.outcome_key is String, "outcome requirements have one explicit key")
		var lookup := Abilities.ability(entry.id)
		_check(lookup == entry, "single discovery lookup matches the catalog")
		lookup.name = "CHANGED"
		_check(Abilities.ability(entry.id).name != "CHANGED", "single discovery lookup is an independent copy")
	entries[0].description = "CHANGED"
	entries.clear()
	_check(Abilities.catalog().size() == 6 and Abilities.ability(&"strike").description != "CHANGED", "catalog arrays and their entries cannot rewrite authored content")
	_check(Abilities.ability(&"invented").is_empty(), "unknown discoveries have no fabricated location")
	_check(Abilities.ability(&"groove").outcome_key == "practice_room/practice_count_in", "Groove Riding waits behind the existing Count-In result")
	_check(Abilities.ability(&"pogo").room_id == &"overture_well", "Pogo names the real authored Well")
	for id in EXPECTED_IDS:
		if id != &"groove":
			_check(Abilities.ability(id).outcome_key.is_empty(), "ordinary pickups do not require a story outcome: " + String(id))

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
