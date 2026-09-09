extends SceneTree
## Standalone disk-save regression checks; never opens the player's save.

const SaveStoreScript := preload("res://scripts/save_store.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")

var _checks := 0
var _failures: Array[String] = []
var _test_directory: String
var _path: String

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_directory = "user://deadwax-save-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_path = _test_directory + "/checkpoint.json"
	_check(DirAccess.make_dir_absolute(_test_directory) == OK, "create isolated test directory")
	_check_roundtrip()
	_check_invalid_data()
	_check_recovery()
	_check_failed_writes()
	var store := SaveStoreScript.new(_path)
	_check(store.delete_save(), "remove all isolated save files")
	_check(not store.has_save(), "deleting also removes Continue recovery")
	_check(DirAccess.remove_absolute(_test_directory) == OK, "remove isolated test directory")
	if _failures.is_empty():
		print("DEAD WAX SAVE PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _sample() -> Dictionary:
	var progression := ProgressionScript.new()
	progression.unlock_refrain(ProgressionScript.Refrain.GATHER)
	progression.discover_technique(ProgressionScript.Technique.COUNT_IN)
	return {
		"version": 1,
		"room_id": "verse",
		"entry_id": "from_practice",
		"progression": progression.snapshot(),
		"shine": 27,
		"purchases": [],
		"completed": true,
		"encounters": {"practice/dummy": "won", "verse/auditioner-1": "freed"},
		"settings": {"volume": 0.35, "reduced_motion": true, "fullscreen": true},
	}

func _check_roundtrip() -> void:
	var store := SaveStoreScript.new(_path)
	_check(store.load_game().is_empty() and store.last_error.is_empty(), "missing save is an ordinary empty state")
	_check(not store.has_save(), "Continue absent before first save")
	var original := _sample()
	_check(store.save_game(original), "write a full checkpoint")
	var restored := SaveStoreScript.new(_path).load_game()
	_check(restored == original, "new store restores location, Shine, completion, encounters and settings")
	_check(restored.get("shine") is int and restored.get("version") is int, "JSON whole numbers normalize to integers")
	var progression := ProgressionScript.new()
	_check(progression.restore_snapshot(restored.progression), "loaded progression restores through its native API")
	_check(progression.has_refrain(ProgressionScript.Refrain.GATHER), "earned Refrain survives disk save")
	_check(progression.knows_technique(ProgressionScript.Technique.COUNT_IN), "discovered technique survives disk save")
	_check(store.has_save() and store.last_error.is_empty(), "Continue validates a good checkpoint")
	var minimal := original.duplicate(true)
	for key in ["purchases", "completed", "encounters", "settings"]:
		minimal.erase(key)
	_check(store.save_game(minimal), "optional fields may be absent")
	var defaults := store.load_game()
	_check(defaults.completed == false and defaults.encounters == {} and defaults.purchases == [], "optional campaign state defaults")
	_check(defaults.settings == SaveStoreScript.DEFAULT_SETTINGS, "optional settings default")

func _check_invalid_data() -> void:
	var store := SaveStoreScript.new(_path)
	_check(store.save_game(_sample()), "establish known checkpoint before malformed requests")
	var variants: Array[Dictionary] = []
	for key in ["version", "room_id", "entry_id", "progression", "shine"]:
		var missing := _sample()
		missing.erase(key)
		variants.append(missing)
	for pair in [["version", 2], ["version", "1"], ["version", 1.5], ["room_id", "../label"], ["entry_id", ""], ["shine", -1], ["shine", 0.5], ["shine", true], ["shine", 2147483648], ["shine", INF], ["completed", 1], ["encounters", []], ["encounters", {"verse/a": true}], ["encounters", {"verse/a": "invented"}], ["settings", {"volume": 1.1}], ["settings", {"volume": "0.5"}], ["settings", {"volume": NAN}], ["settings", {"fullscreen": 1}], ["settings", {"unknown": false}], ["extra", true]]:
		var bad := _sample()
		bad[pair[0]] = pair[1]
		variants.append(bad)
	for progression in [{"version": 9, "refrains": [], "techniques": []}, {"version": 1, "refrains": ["unknown"], "techniques": []}, {"version": 1, "refrains": ["gather", "gather"], "techniques": []}, {"version": 1, "refrains": [], "techniques": [1]}, {"version": 1, "refrains": "gather", "techniques": []}]:
		var bad := _sample()
		bad.progression = progression
		variants.append(bad)
	for index in variants.size():
		_check(not store.save_game(variants[index]) and not store.last_error.is_empty(), "reject malformed incoming checkpoint %d" % index)
		_check(store.load_game() == _sample(), "malformed request %d preserves previous checkpoint" % index)
	store.delete_save()
	for content in ["{broken", "[]", "null", JSON.stringify(variants[5]), " ".repeat(SaveStoreScript.MAX_FILE_BYTES + 1)]:
		_write_raw(_path, content)
		_check(not store.has_save() and not store.last_error.is_empty(), "invalid disk data cannot enable Continue")

func _check_recovery() -> void:
	var store := SaveStoreScript.new(_path)
	store.delete_save()
	var first := _sample()
	var second := _sample()
	second.shine = 80
	_check(store.save_game(first) and store.save_game(second), "atomically replace existing checkpoint")
	_check(store.load_game().shine == 80, "newest valid checkpoint takes priority")
	_write_raw(_path, "{truncated")
	_check(store.load_game() == first, "corrupt primary recovers last valid checkpoint")
	_check(store.has_save() and store.last_error.is_empty(), "recovered checkpoint enables Continue without error")
	_check(store.save_game(second), "replace corrupt primary using a new valid checkpoint")
	_write_raw(_path, "{truncated again")
	_check(store.load_game() == first, "corrupt primary never overwrites a valid backup")
	DirAccess.remove_absolute(_path)
	_check(store.load_game() == first, "missing primary can recover backup after an interrupted operation")
	_write_raw(_path + ".bak", "{bad backup")
	_check(not store.has_save(), "invalid recovery data also fails closed")

func _check_failed_writes() -> void:
	var store := SaveStoreScript.new(_path)
	store.delete_save()
	_check(store.save_game(_sample()), "establish checkpoint before filesystem failures")
	var modified := _sample()
	modified.shine = 100
	_check(DirAccess.make_dir_absolute(_path + ".tmp") == OK, "block staged write using a directory")
	_check(not store.save_game(modified) and not store.last_error.is_empty(), "failed staged write reports error")
	_check(store.load_game() == _sample(), "failed staged write preserves old save")
	DirAccess.remove_absolute(_path + ".tmp")
	_check(DirAccess.make_dir_absolute(_path + ".bak") == OK, "block backup replacement using a directory")
	_check(not store.save_game(modified) and not store.last_error.is_empty(), "failed backup installation reports error")
	_check(store.load_game() == _sample(), "failed backup installation preserves old save")
	DirAccess.remove_absolute(_path + ".bak")
	var missing_parent := SaveStoreScript.new(_test_directory + "/missing/checkpoint.json")
	_check(not missing_parent.save_game(_sample()), "missing destination directory fails gracefully")
	var blocked_target := _test_directory + "/blocked-target"
	DirAccess.make_dir_absolute(blocked_target)
	var blocked := SaveStoreScript.new(blocked_target)
	_check(not blocked.save_game(_sample()) and not blocked.last_error.is_empty(), "failed final rename reports error")
	_check(DirAccess.dir_exists_absolute(blocked_target), "failed replacement leaves existing directory intact")
	DirAccess.remove_absolute(blocked_target)

func _write_raw(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "open isolated fixture")
		return
	file.store_string(content)
	file.close()

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
