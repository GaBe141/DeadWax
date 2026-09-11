extends SceneTree
## Shortcut snapshots grant no incidental rewards, accept genuine JSON whole
## versions, and never partly replace state when validation fails.

const Exploration := preload("res://scripts/exploration_state.gd")
const IDS: Array[StringName] = [&"warren_return", &"gallery_return"]
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_shortcuts()
	_check_snapshots()
	_check_invalid()
	if _failures.is_empty():
		print("DEAD WAX EXPLORATION STATE PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("EXPLORATION STATE FAIL: " + failure)
	quit(1)

func _check_shortcuts() -> void:
	var state := Exploration.new()
	_check(state.snapshot() == Exploration.default_snapshot(), "new and legacy-default exploration open no shortcut")
	for id in IDS:
		_check(not state.is_open(id), "shortcut starts closed: " + String(id))
		_check(state.open_shortcut(id) and state.is_open(id), "each known shortcut opens once: " + String(id))
		var before := state.snapshot()
		_check(not state.open_shortcut(id) and state.snapshot() == before, "opening again is inert: " + String(id))
	var before := state.snapshot()
	_check(not state.open_shortcut(&"invented") and not state.is_open(&"invented") and state.snapshot() == before, "unknown shortcut cannot enter exploration")
	state.reset()
	_check(state.snapshot() == Exploration.default_snapshot(), "New Game reset closes every shortcut")
	for id in IDS:
		_check(not state.is_open(id), "reset removes the remembered opening: " + String(id))

func _check_snapshots() -> void:
	var state := Exploration.new()
	var cases := [[], ["warren_return"], ["gallery_return"], ["warren_return", "gallery_return"], ["gallery_return", "warren_return"]]
	for opened in cases:
		var original := {"version": 1, "opened": opened}
		var parsed: Variant = JSON.parse_string(JSON.stringify(original))
		var source_copy: Dictionary = parsed.duplicate(true)
		_check(Exploration.valid_snapshot(parsed) and state.restore_snapshot(parsed), "JSON restores a valid subset of shortcuts: " + str(opened))
		var expected: Array[String] = []
		for id in IDS:
			if String(id) in opened:
				expected.append(String(id))
		_check(state.snapshot() == {"version": 1, "opened": expected}, "snapshot normalizes order and version: " + str(opened))
		_check(parsed == source_copy, "restore does not mutate source data")
		var saved := state.snapshot()
		_check(state.restore_snapshot(saved) and state.snapshot() == saved, "restoring the same state is stable")
		parsed.opened.clear()
		_check(state.snapshot() == saved, "restoration owns its array")
		var copy := state.snapshot()
		copy.opened.clear()
		copy.version = 99
		_check(state.snapshot() == saved, "snapshot callers cannot rewrite opened shortcuts")
	var default_copy := Exploration.default_snapshot()
	default_copy.opened.append("warren_return")
	_check(Exploration.default_snapshot().opened.is_empty(), "default snapshots never share an array")
	state.open_shortcut(&"warren_return")
	_check(state.restore_snapshot(Exploration.default_snapshot()) and not state.is_open(&"warren_return"), "empty restoration replaces stale openings without an additive merge")

func _check_invalid() -> void:
	var state := Exploration.new()
	state.open_shortcut(&"gallery_return")
	var before := state.snapshot()
	var invalid: Array = [null, true, false, 0, "exploration", [], {}, {"version": 1}, {"opened": []},
		{"version": 1, "opened": [], "extra": true}, {"version": 1, "unlocked": []}]
	for version in [null, true, false, "1", 0, -1, 2, 0.5, 1.5, INF, -INF, NAN, 1e30, [], {}]:
		invalid.append({"version": version, "opened": []})
	for opened in [null, true, false, 1, "warren_return", {}, ["invented"], [0], [null], [true], [&"warren_return"],
		["warren_return", "warren_return"], ["warren_return", "gallery_return", "warren_return"]]:
		invalid.append({"version": 1, "opened": opened})
	for value in invalid:
		_check(not Exploration.valid_snapshot(value), "malformed exploration is rejected: " + str(value))
		_check(not state.restore_snapshot(value) and state.snapshot() == before, "invalid restoration preserves the complete previous shortcut state")
	_check(Exploration.valid_snapshot({"version": 1.0, "opened": []}), "a finite whole JSON version is accepted")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
