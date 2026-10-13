extends SceneTree
## The Label's side rooms: the west loop (Rooms To Let, the Print Shop), the
## two secrets (the Stall Cache behind display glass, the Balcony above the
## loft) and the Unsigned Alcove's second way down to the Overture Stair.
## Real campaign input and private checkpoints; a logger fails the suite on
## any script error while the rooms, residents and fixtures draw.
const MainScene := preload("res://scenes/main.tscn")
const Campaign := preload("res://scripts/campaign.gd")
const ChapterOne := preload("res://scripts/chapter_one.gd")
const Chart := preload("res://scripts/campaign_chart.gd")
const Progression := preload("res://scripts/progression_state.gd")
const Abilities := preload("res://scripts/abilities_state.gd")
const Save := preload("res://scripts/save_store.gd")
const GlassPane := preload("res://scripts/glass_pane.gd")
const RefrainDoor := preload("res://scripts/refrain_door.gd")
const OutcomeExit := preload("res://scripts/outcome_exit.gd")
const RestPoint := preload("res://scripts/rest_point.gd")
const Resident := preload("res://scripts/resident.gd")
const Lighting := preload("res://scripts/lighting_profiles.gd")
const NEW_ROOMS: Array[StringName] = [&"rooms_to_let", &"print_shop", &"stall_cache", &"label_balcony", &"unsigned_alcove"]

class ErrorLog extends Logger:
	var script_errors: Array[String] = []
	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_SCRIPT:
			script_errors.append("%s:%d %s" % [file, line, rationale if not rationale.is_empty() else code])
	func _log_message(_message: String, _error: bool) -> void:
		pass

var _main: Node2D
var _directory := ""
var _checks := 0
var _failures: Array[String] = []
var _log := ErrorLog.new()
var _opened: Array[String] = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	OS.add_logger(_log)
	_directory = "user://deadwax-label-rooms-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create private checkpoint directory")
	_check_registry_and_chart()
	await _check_rooms_standalone()
	await _boot()
	_main._new_game(false)
	await _physics(4)
	await _check_glass()
	await _check_unsigned_lock()
	await _check_rest()
	await _check_residents_and_drawing()
	await _check_continue()
	await _close()
	_check(_log.script_errors.is_empty(), "no script errors while the side rooms run: " + "; ".join(_log.script_errors))
	OS.remove_logger(_log)
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove isolated checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated directory")
	if _failures.is_empty():
		print("DEAD WAX LABEL ROOMS PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("LABEL ROOMS FAIL: " + failure)
	quit(1)

# -- the registry and the folded guide ---------------------------------------

func _check_registry_and_chart() -> void:
	var ids := Campaign.room_ids()
	_check(ids.size() == 26 and ChapterOne.room_ids().size() == 13, "the Label grew from eight rooms to thirteen; the campaign has twenty-six")
	for id in NEW_ROOMS:
		_check(ChapterOne.has_room(id) and Chart.region_for_room(id) == &"label", "%s is an authored Label room on the Label's map page" % id)
		_check(Lighting.get_profile(id).lights.size() >= 2 and Lighting.get_profile(id).lights.size() <= 4, "%s has an authored light rig" % id)
	var pairs := {}
	for link in Chart.LINKS:
		pairs[_pair(link.a, link.b)] = bool(link.shortcut)
	_check(Chart.LINKS.size() == 33, "the chart carries thirty-three undirected pairs")
	for expected in [["high_street", "rooms_to_let"], ["high_street", "print_shop"], ["print_shop", "practice_room"],
			["the_stalls", "stall_cache"], ["the_stalls", "label_balcony"], ["groove_yard", "unsigned_alcove"], ["unsigned_alcove", "overture_stair"]]:
		var key := _pair(StringName(expected[0]), StringName(expected[1]))
		_check(pairs.has(key) and not pairs[key], "the chart draws %s as an ordinary walked passage" % key)
	# Loops: the west diamond and the yard's two ways down are both cycles.
	_check(_cycles(Chart.LINKS) >= 8, "the authored graph has at least eight independent loops (was six)")
	var page := Chart.page_snapshot(&"label", ["headshell", "horn_plaza"], &"horn_plaza")
	var seen := {}
	for room in page.rooms:
		seen[room.id] = room
		var box := Rect2(room.position - Chart.ROOM_SIZE * 0.5, Chart.ROOM_SIZE)
		_check(Rect2(Vector2.ZERO, Chart.EXTENT).encloses(box), "%s fits the Label page" % room.id)
	for id in NEW_ROOMS:
		_check(seen.has(id) and String(seen[id].title).is_empty(), "%s shows as an unnamed promise before it is visited" % id)
	_check(_no_box_crossings(page), "no Label passage line crosses an unrelated room card")
	var overture := Chart.page_snapshot(&"overture", ["overture_stair"], &"overture_stair")
	var alcove_stub := false
	for boundary in overture.boundaries:
		if boundary.id == &"unsigned_alcove":
			alcove_stub = String(boundary.title) == "TO THE LABEL"
	_check(alcove_stub, "the Overture page marks the alcove's way back to the Label without naming it")

func _cycles(links: Array) -> int:
	var nodes := {}
	for link in links:
		nodes[link.a] = true
		nodes[link.b] = true
	return links.size() - nodes.size() + 1

func _no_box_crossings(page: Dictionary) -> bool:
	for link in page.links:
		for room in page.rooms:
			if room.id == link.a or room.id == link.b: continue
			var box := Rect2(room.position - Chart.ROOM_SIZE * 0.5, Chart.ROOM_SIZE)
			if _segment_hits(link.from, link.to, box): return false
	return true

func _segment_hits(from: Vector2, to: Vector2, box: Rect2) -> bool:
	for step in range(0, 101):
		if box.has_point(from.lerp(to, step / 100.0)): return true
	return false

# -- the rooms as the factory builds them -------------------------------------

func _check_rooms_standalone() -> void:
	var exits := {}
	for id in [&"high_street", &"practice_room", &"the_stalls", &"groove_yard", &"overture_stair"] + NEW_ROOMS:
		var room: Node2D = Campaign.create_room(id)
		room.process_mode = Node.PROCESS_MODE_DISABLED
		room.progression = Progression.new()
		root.add_child(room)
		var targets: Array[String] = []
		for child in room.get_children():
			if child.is_in_group("room_exit"): targets.append(String(child.target_room))
		targets.sort()
		exits[id] = targets
		match id:
			&"the_stalls":
				var glass: Node = room.get_node_or_null("StallGlass")
				_check(glass is GlassPane and glass is StaticBody2D and glass.is_in_group("hears_strikes")
					and glass.get_meta("chapter_state_id") == &"stall_glass" and not glass.is_open,
					"the Stalls keeps display glass as a physical lock with a stable encounter id")
				_check(glass != null and glass.position == Vector2(1740, 695) and room.entry_points[&"from_stall_cache"].x > glass.position.x
					and room.entry_points[&"from_label_balcony"] == Vector2(2000, 144),
					"the cache arrival is behind the glass and the balcony arrival is on the shelf above the loft")
			&"groove_yard":
				var lock: Node = null
				for child in room.get_children():
					if child is RefrainDoor and child.get_meta("chapter_state_id") == &"unsigned_lock": lock = child
				_check(lock != null and lock.position == Vector2(2200, 525) and room.entry_points[&"from_unsigned_alcove"].x > lock.position.x,
					"the yard's unsigned lock is a listening door past the Descent, and the alcove arrives behind it")
				var signed := false
				for note in room._notes:
					if note.position.x > 1900: signed = true
				_check(not signed, "nothing is pasted up beside the unsigned lock")
			&"unsigned_alcove":
				var passage: Node = room.get_node_or_null("YardPassage")
				_check(passage is OutcomeExit and passage.required_outcome_key == "groove_yard/unsigned_lock" and passage.is_locked(),
					"from below, the way up into the yard is held closed until the lock has heard its count")
				room.session_outcomes = {"groove_yard/unsigned_lock": "opened"}
				passage.session_outcomes = room.session_outcomes
				_check(not passage.is_locked(), "the counted-in lock opens the alcove's way up")
			&"rooms_to_let":
				var bed: Node = room.get_node_or_null("MadeBed")
				_check(bed is RestPoint and bed.is_in_group("rest_point") and bed.entry_id == &"matron_bed"
					and room.entry_points[&"matron_bed"] == bed.position and not bed is CollisionObject2D,
					"Matron's bed is a cue point at its own arrival, with no collision")
				var matron: Node = room.get_node_or_null("Matron")
				_check(matron is Resident and matron.kind == &"matron" and matron.lines.size() == 6, "Matron keeps six worn-smooth pleasantries")
			&"print_shop":
				var typesetter: Node = room.get_node_or_null("Typesetter")
				_check(typesetter is Resident and typesetter.kind == &"typesetter" and typesetter.lines.size() == 5, "the Typesetter has his notices set")
		room.free()
		await _frames(1)
	_check(exits[&"high_street"] == ["horn_plaza", "practice_room", "print_shop", "rooms_to_let"], "High Street has four doors")
	_check(exits[&"practice_room"] == ["high_street", "horn_plaza", "print_shop"], "Practice has three doors")
	_check(exits[&"the_stalls"] == ["groove_yard", "horn_plaza", "label_balcony", "stall_cache", "worn_gallery"], "the Stalls is a five-way junction")
	_check(exits[&"groove_yard"] == ["label_descent", "the_stalls", "unsigned_alcove"], "the Yard has two ways down")
	_check(exits[&"overture_stair"] == ["bootlegger", "label_descent", "unsigned_alcove"], "the Stair has the alcove's way under it")
	_check(exits[&"unsigned_alcove"] == ["groove_yard", "overture_stair"] and exits[&"print_shop"] == ["high_street", "practice_room"],
		"the alcove and the print shop each join two rooms")
	_check(exits[&"rooms_to_let"] == ["high_street"] and exits[&"stall_cache"] == ["the_stalls"] and exits[&"label_balcony"] == ["the_stalls"],
		"the lodgings and both secrets are dead ends off the rooms that hold them")

# -- the display glass ---------------------------------------------------------

func _check_glass() -> void:
	_grant_everything()
	_main._load_world_room(&"the_stalls")
	await _physics(4)
	_quiet_actors()
	var glass: Node = _main.room.get_node("StallGlass")
	var xp_before: int = _main.experience.xp
	await _stand(Vector2(1650, 744))
	_face_right()
	await _tap(KEY_J)
	await _settle_strike()
	_check(not glass.is_open and glass._hits == 1 and _main.player.combo_step == 1,
		"a light stroke only rings the pane, and counts as contact so the chain goes on")
	await _tap(KEY_J)
	await _settle_strike()
	_check(not glass.is_open and glass._hits == 2 and _main.player.combo_step == 2, "the Sweep rings it too")
	await _tap(KEY_J)
	await _settle_strike()
	_check(glass.is_open and glass.get_node("block").disabled, "the Accent shatters the glass and the block goes with it")
	_check(String(_main.encounters.get("the_stalls/stall_glass", "")) == "opened", "Main remembers the broken pane as an opened lock")
	_check(_main.experience.xp == xp_before, "glass is nobody's sound: breaking it pays no XP")
	await _physics(3)
	var saved: Dictionary = _main.save_store.load_game()
	_check(String(saved.get("encounters", {}).get("the_stalls/stall_glass", "")) == "opened", "the broken pane is in the checkpoint")
	# Far away, a strike does not reach it: leave, forget the pane, and come
	# back to a whole one (Main captures the leaving room's locks on a swap).
	_main._load_world_room(&"horn_plaza")
	await _physics(2)
	_main.encounters.erase("the_stalls/stall_glass")
	_main._load_world_room(&"the_stalls")
	await _physics(4)
	_quiet_actors()
	glass = _main.room.get_node("StallGlass")
	await _stand(Vector2(1100, 744))
	_face_right()
	await _tap(KEY_J)
	await _settle_strike()
	_check(not glass.is_open and glass._hits == 0, "the pane only hears strokes within Skip's reach")
	# Restored outcome: the room rebuilds with the pane open and silent.
	_main.encounters["the_stalls/stall_glass"] = "opened"
	var reopened := 0
	_main._load_world_room(&"the_stalls")
	await _physics(4)
	glass = _main.room.get_node("StallGlass")
	glass.opened.connect(func() -> void: reopened += 1)
	_check(glass.is_open and glass.get_node("block").disabled and reopened == 0, "a remembered pane restores open without shattering again")
	await _stand(_main.room.entry_points[&"from_stall_cache"])
	_check(_main.player.is_on_floor(), "the cache arrival stands on the cellar shelf")

# -- the unsigned lock -----------------------------------------------------------

func _check_unsigned_lock() -> void:
	_main.encounters.erase("groove_yard/unsigned_lock")
	_main._load_world_room(&"unsigned_alcove")
	await _physics(4)
	var up: Node = _main.room.get_node("YardPassage")
	_check(up.is_locked(), "entered from the stair, the alcove's way up is held closed")
	var blocked: Array[String] = []
	_main.room.route_blocked.connect(func(message: String) -> void: blocked.append(message))
	await _stand(up.position)
	await _tap(KEY_E)
	_check(_main.world_room_id == &"unsigned_alcove" and blocked.size() == 1, "trying the held passage explains itself without moving Skip")
	_main._load_world_room(&"groove_yard")
	await _physics(4)
	_quiet_actors()
	var lock: Node = null
	for child in _main.room.get_children():
		if child is RefrainDoor and child.get_meta("chapter_state_id") == &"unsigned_lock": lock = child
	await _stand(Vector2(2080, 574))
	_face_right()
	for count in range(4):
		await _tap(KEY_J)
		await _physics(18)
	_check(lock.is_open and String(_main.encounters.get("groove_yard/unsigned_lock", "")) == "opened",
		"four even strikes open the unsigned lock, with no notice telling anyone to try")
	_main._load_world_room(&"unsigned_alcove", &"from_groove_yard")
	await _physics(4)
	up = _main.room.get_node("YardPassage")
	_check(not up.is_locked() and _main.player.position == _main.room.entry_points[&"from_groove_yard"], "the alcove's way up opens once the yard has heard the count")
	var stair_exit: Node = null
	for child in _main.room.get_children():
		if child.is_in_group("room_exit") and child.target_room == &"overture_stair": stair_exit = child
	await _stand(stair_exit.position)
	await _tap(KEY_E)
	await _physics(4)
	_check(_main.world_room_id == &"overture_stair" and _main.room_entry_id == &"from_unsigned_alcove"
		and _main.player.position == _main.room.entry_points[&"from_unsigned_alcove"], "the alcove comes out on the service ledge under the stair")
	var ledge_exit: Node = null
	for child in _main.room.get_children():
		if child.is_in_group("room_exit") and child.target_room == &"unsigned_alcove": ledge_exit = child
	_check(ledge_exit != null and ledge_exit.position.y > 900, "the stair's alcove passage sits under its lowest landing")

# -- Matron's bed -----------------------------------------------------------------

func _check_rest() -> void:
	_main._load_world_room(&"rooms_to_let", &"from_high_street")
	await _physics(4)
	var bed: Node = _main.room.get_node("MadeBed")
	_main._health = 1
	await _stand(Vector2(1300, 574))
	await _tap(KEY_E)
	_check(_main._health == 1 and _main.room_entry_id == &"from_high_street", "the bed only answers within reach")
	await _stand(bed.position)
	paused = true
	await _tap(KEY_E)
	paused = false
	_check(_main._health == 1, "a paused game cannot rest")
	await _physics(2)
	await _tap(KEY_E)
	await _physics(3)
	_check(_main._health == _main._max_health() and _main.room_entry_id == &"matron_bed", "resting refills the diamonds and makes the bed the cue point")
	var saved: Dictionary = _main.save_store.load_game()
	_check(String(saved.get("room_id", "")) == "rooms_to_let" and String(saved.get("entry_id", "")) == "matron_bed", "the checkpoint carries the bed as its entry")
	_main._health = 1
	_main._recover_needle()
	await _physics(2)
	_check(_main.player.position == bed.position and _main._health == _main._max_health(), "the Hound carries Skip back to the bed")

# -- residents, drawing and the Book ----------------------------------------------

func _check_residents_and_drawing() -> void:
	var matron: Node = _main.room.get_node("Matron")
	_check(matron.lines.size() == 6, "before Addie, Matron has six phrases")
	_main.encounters["addie/addie"] = "freed"
	await _physics(2)
	_check(matron.lines.size() == 7 and matron.lines[6].begins_with("addie heard"), "after Addie, a seventh phrase")
	await _stand(matron.position + Vector2(-90, 0))
	await _tap(KEY_E)
	_check(matron._line == 0 and matron._talk > 0.0, "grounded E talks to Matron")
	_main.encounters.erase("addie/addie")
	for id in [&"print_shop", &"stall_cache", &"label_balcony", &"unsigned_alcove", &"rooms_to_let"]:
		_main._load_world_room(id)
		await _physics(6)
		_check(_main.room.room_id == id and _main.room.atmosphere != null and _main.room.lighting != null,
			"%s builds with its atmosphere and lamps" % id)
		_main.room.apply_side(1)
		await _physics(2)
		_main.room.apply_side(0)
		await _physics(2)
	_main._load_world_room(&"print_shop")
	await _physics(4)
	var typesetter: Node = _main.room.get_node("Typesetter")
	_check(typesetter.lines.size() == 5 and typesetter.lines[4].begins_with("the gate below"), "before the gate, the Typesetter mentions the notice nobody read")
	_main.encounters["label_descent/descent_count_in"] = "opened"
	await _physics(2)
	_check(typesetter.lines.size() == 5 and typesetter.lines[4].begins_with("you counted"), "after the gate, he heard it from the shop")
	_main.encounters.erase("label_descent/descent_count_in")

# -- Continue --------------------------------------------------------------------

func _check_continue() -> void:
	_main._load_world_room(&"rooms_to_let", &"matron_bed")
	await _physics(3)
	_main._persist_session()
	await _physics(2)
	_main._return_to_title()
	await _physics(3)
	_main.game_menu.continue_requested.emit()
	await _physics(6)
	_check(_main.world_room_id == &"rooms_to_let" and _main.room_entry_id == &"matron_bed"
		and _main.player.position == _main.room.entry_points[&"matron_bed"], "Continue wakes Skip in Matron's bed")

# -- helpers ---------------------------------------------------------------------

func _grant_everything() -> void:
	for id in Abilities.IDS: _main.abilities.unlock_ability(id)
	_main.progression.unlock_refrain(Progression.Refrain.GATHER)
	_main.player.refresh_abilities() if _main.player.has_method("refresh_abilities") else null

func _quiet_actors() -> void:
	for actor in get_nodes_in_group("hears_strikes"):
		if actor is GlassPane or actor is RefrainDoor: continue
		actor.set_process(false)
		actor.set_physics_process(false)

func _face_right() -> void:
	_main.player.facing = 1.0

func _settle_strike() -> void:
	for frame in range(30):
		if _main.player._strike_cd <= 0: return
		await _physics(1)

func _stand(at: Vector2) -> void:
	_release()
	_main.player.position = at
	_main.player.velocity = Vector2.ZERO
	await _physics(4)

func _boot() -> void:
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)

func _close() -> void:
	_release()
	_main.queue_free()
	await _frames(3)
	paused = false

func _release() -> void:
	for code in [KEY_D, KEY_A, KEY_SPACE, KEY_J, KEY_X, KEY_K, KEY_C, KEY_L, KEY_E]: _key(code, false)

func _tap(code: Key) -> void:
	_key(code, true)
	await _physics(2)
	_key(code, false)
	await _physics(2)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _pair(a: StringName, b: StringName) -> String:
	var ids := [String(a), String(b)]
	ids.sort()
	return "%s<>%s" % ids

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in count: await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
