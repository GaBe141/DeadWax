extends RefCounted
## A versioned campaign checkpoint. Main owns gameplay and supplies snapshots.
## JSON numbers are checked before conversion, and every read is validated.
## The last valid checkpoint remains in .bak when a new checkpoint is installed.
## Required v1 fields: version, room_id, entry_id, progression.snapshot(), shine.
## Optional fields: purchases, map, completed, encounters ("room/encounter": outcome), settings.
## Main must also check that saved location IDs belong to the active campaign.

const SAVE_VERSION := 1
const MAX_FILE_BYTES := 65536
const MAX_SHINE := 2147483647
const MAX_ENCOUNTERS := 256
const ProgressionScript := preload("res://scripts/progression_state.gd")
const EconomyScript := preload("res://scripts/economy_state.gd")
const MapStateScript := preload("res://scripts/map_state.gd")
const ENCOUNTER_STATES := ["opened", "freed", "shattered", "polished", "won"]
const DEFAULT_SETTINGS := {"volume": 1.0, "reduced_motion": false, "fullscreen": false}
const ROOT_KEYS := ["version", "room_id", "entry_id", "progression", "shine", "purchases", "map", "completed", "encounters", "settings"]

var last_error := ""
var _path: String

func _init(path: String = "user://deadwax-save.json") -> void:
	_path = path

func has_save() -> bool:
	return not load_game().is_empty()

func load_game() -> Dictionary:
	last_error = ""
	var current := _read_file(_path)
	if not current.is_empty():
		return current
	var primary_error := last_error
	var backup := _read_file(_path + ".bak")
	if not backup.is_empty():
		last_error = ""
		return backup
	if not primary_error.is_empty():
		last_error = primary_error
	return {}

func save_game(data: Dictionary) -> bool:
	last_error = ""
	var clean := _normalise(data)
	if clean.is_empty():
		return false
	var encoded := JSON.stringify(clean, "\t")
	if encoded.to_utf8_buffer().size() > MAX_FILE_BYTES:
		last_error = "The checkpoint is too large."
		return false
	var temporary := _path + ".tmp"
	if not _write_file(temporary, encoded):
		return false
	# Reading the staged bytes also catches incomplete writes before replacement.
	if _read_file(temporary).is_empty():
		_remove_temporary(temporary)
		return false
	var previous := _read_file(_path)
	last_error = ""
	if not previous.is_empty():
		var backup_temporary := _path + ".bak.tmp"
		if not _write_file(backup_temporary, JSON.stringify(previous, "\t")):
			_remove_temporary(temporary)
			return false
		if not _replace_file(backup_temporary, _path + ".bak"):
			_remove_temporary(temporary)
			_remove_temporary(backup_temporary)
			return false
	# Same-directory rename installs the completed file without exposing a partial
	# JSON document. A failed rename leaves the old main file and backup intact.
	if not _replace_file(temporary, _path):
		_remove_temporary(temporary)
		return false
	last_error = ""
	return true

func delete_save() -> bool:
	last_error = ""
	# Remove recovery copies before the main file: Continue cannot resurrect a
	# deliberately deleted campaign from its previous checkpoint.
	for suffix in [".tmp", ".bak.tmp", ".bak", ""]:
		var target := _path + String(suffix)
		if FileAccess.file_exists(target):
			var error := DirAccess.remove_absolute(target)
			if error != OK:
				last_error = "Could not delete the checkpoint (%s)." % error_string(error)
				return false
	return true

func _read_file(path: String) -> Dictionary:
	last_error = ""
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _invalid("Could not open the checkpoint (%s)." % error_string(FileAccess.get_open_error()))
	if file.get_length() > MAX_FILE_BYTES:
		file.close()
		return _invalid("The checkpoint is too large.")
	var source := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		return _invalid("Could not read the checkpoint (%s)." % error_string(read_error))
	var parser := JSON.new()
	if parser.parse(source) != OK or not (parser.data is Dictionary):
		return _invalid("The checkpoint is not valid JSON save data.")
	return _normalise(parser.data)

func _normalise(data: Dictionary) -> Dictionary:
	if not _known_keys(data, ROOT_KEYS):
		return _invalid("The checkpoint contains an unknown field.")
	if not _whole_number(data.get("version"), SAVE_VERSION, SAVE_VERSION):
		return _invalid("This checkpoint version is not supported.")
	if not _identifier(data.get("room_id")) or not _identifier(data.get("entry_id")):
		return _invalid("The checkpoint location is invalid.")
	if not _whole_number(data.get("shine"), 0, MAX_SHINE):
		return _invalid("The checkpoint Shine amount is invalid.")
	var purchases: Variant = data.get("purchases", [])
	if not EconomyScript.valid_purchases(purchases):
		return _invalid("The checkpoint purchases are invalid.")
	var map: Variant = data.get("map", {"owned": false, "visited": []})
	if not MapStateScript.valid_snapshot(map):
		return _invalid("The checkpoint map is invalid.")
	var progression: Variant = data.get("progression")
	if not (progression is Dictionary) or not _known_keys(progression, ["version", "refrains", "techniques"]):
		return _invalid("The checkpoint progression is invalid.")
	if not _whole_number(progression.get("version"), ProgressionScript.SAVE_VERSION, ProgressionScript.SAVE_VERSION):
		return _invalid("This progression version is not supported.")
	if not _progression_keys(progression.get("refrains"), ProgressionScript.REFRAIN_KEYS.values()):
		return _invalid("The checkpoint Refrains are invalid.")
	if not _progression_keys(progression.get("techniques"), ProgressionScript.TECHNIQUE_KEYS.values()):
		return _invalid("The checkpoint techniques are invalid.")
	var completed: Variant = data.get("completed", false)
	if not (completed is bool):
		return _invalid("The checkpoint completion state is invalid.")
	var encounters: Variant = data.get("encounters", {})
	if not (encounters is Dictionary) or encounters.size() > MAX_ENCOUNTERS:
		return _invalid("The checkpoint encounters are invalid.")
	for key in encounters:
		if not _encounter_key(key) or not (encounters[key] is String) or not ENCOUNTER_STATES.has(encounters[key]):
			return _invalid("The checkpoint encounter state is invalid.")
	var settings: Variant = data.get("settings", {})
	if not (settings is Dictionary) or not _known_keys(settings, DEFAULT_SETTINGS.keys()):
		return _invalid("The checkpoint settings are invalid.")
	var volume: Variant = settings.get("volume", DEFAULT_SETTINGS.volume)
	if not (volume is int or volume is float) or not is_finite(float(volume)) or float(volume) < 0.0 or float(volume) > 1.0:
		return _invalid("The checkpoint volume is invalid.")
	for key in ["reduced_motion", "fullscreen"]:
		if not (settings.get(key, DEFAULT_SETTINGS[key]) is bool):
			return _invalid("The checkpoint display settings are invalid.")
	return {
		"version": SAVE_VERSION,
		"room_id": data.room_id,
		"entry_id": data.entry_id,
		"progression": {
			"version": ProgressionScript.SAVE_VERSION,
			"refrains": progression.refrains.duplicate(),
			"techniques": progression.techniques.duplicate(),
		},
		"shine": int(data.shine),
		"purchases": purchases.duplicate(),
		"map": map.duplicate(true),
		"completed": completed,
		"encounters": encounters.duplicate(),
		"settings": {
			"volume": float(volume),
			"reduced_motion": settings.get("reduced_motion", false),
			"fullscreen": settings.get("fullscreen", false),
		},
	}

func _known_keys(data: Dictionary, allowed: Array) -> bool:
	for key in data:
		if not (key is String) or not allowed.has(key):
			return false
	return true

func _whole_number(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is int or value is float):
		return false
	var number := float(value)
	return is_finite(number) and number >= minimum and number <= maximum and number == floor(number)

func _identifier(value: Variant) -> bool:
	if not (value is String) or value.is_empty() or value.length() > 128:
		return false
	var allowed := "abcdefghijklmnopqrstuvwxyz0123456789_-"
	for character in value:
		if not allowed.contains(character):
			return false
	return true

func _encounter_key(value: Variant) -> bool:
	if not (value is String) or value.length() > 128:
		return false
	var parts: PackedStringArray = value.split("/")
	return parts.size() == 2 and _identifier(parts[0]) and _identifier(parts[1])

func _progression_keys(value: Variant, allowed: Array) -> bool:
	if not (value is Array) or value.size() > allowed.size():
		return false
	var seen: Array[String] = []
	for key in value:
		if not (key is String) or not allowed.has(key) or seen.has(key):
			return false
		seen.append(key)
	return true

func _write_file(path: String, contents: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		last_error = "Could not write the checkpoint (%s)." % error_string(FileAccess.get_open_error())
		return false
	file.store_string(contents)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		last_error = "Could not finish writing the checkpoint (%s)." % error_string(error)
		_remove_temporary(path)
		return false
	return true

func _replace_file(source: String, destination: String) -> bool:
	var error := DirAccess.rename_absolute(source, destination)
	if error != OK:
		last_error = "Could not install the checkpoint (%s)." % error_string(error)
		return false
	return true

func _remove_temporary(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func _invalid(message: String) -> Dictionary:
	last_error = message
	return {}
