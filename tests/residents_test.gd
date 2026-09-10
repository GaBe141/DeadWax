extends SceneTree
## Residents share the live campaign, input map and pause state. Every save in
## this suite lives in a unique directory, never in the player's checkpoint.

const MainScene := preload("res://scenes/main.tscn")
const SaveScript := preload("res://scripts/save_store.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-residents-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated resident directory")
	await _boot()
	_main._new_game(false)
	await _physics(5)
	await _check_dialogue(&"bootlegger", &"from_overture_stair", &"bootlegger")
	await _check_dialogue(&"practice_room", &"from_high_street", &"tick")
	await _check_count_in()
	await _check_hound()
	await _check_addie()
	await _check_old_continue()
	await _close()
	_check(SaveScript.new(_directory + "/checkpoint.json").delete_save(), "remove isolated resident checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated resident directory")
	if _failures.is_empty():
		print("DEAD WAX RESIDENTS PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("RESIDENTS FAIL: " + failure)
	quit(1)

func _check_dialogue(room_id: StringName, entry: StringName, kind: StringName) -> void:
	_main._load_world_room(room_id, entry)
	await _physics(5)
	var resident := _resident(kind)
	_check(resident != null, "%s has its authored resident" % room_id)
	if resident == null:
		return
	_check_harmless(resident, String(kind))
	_check(resident.lines.size() >= 2, "%s has a conversation to advance" % kind)
	var baseline := _gameplay_snapshot()
	var line_before: int = resident._line
	await _tap(KEY_E)
	_check(resident._line == line_before, "%s ignores a remote E press" % kind)
	await _stand(resident.position + Vector2(-42, 0))
	_check(_main.player.is_on_floor() and resident._near, "%s recognizes a grounded listener" % kind)
	_key(KEY_E, true)
	await _physics(8)
	_check(resident._line == (line_before + 1) % resident.lines.size(), "%s advances exactly once while E is held" % kind)
	_key(KEY_E, false)
	await _physics(2)
	line_before = resident._line
	await _tap(KEY_E)
	_check(resident._line == (line_before + 1) % resident.lines.size(), "%s advances once on a fresh E press" % kind)
	_check(_main.world_room_id == room_id and not _main._transition_pending, "%s conversation never takes a passage" % kind)
	line_before = resident._line
	_key(KEY_SPACE, true)
	await _physics(4)
	_key(KEY_SPACE, false)
	_check(not _main.player.is_on_floor(), "%s airborne interaction uses an actual jump" % kind)
	await _tap(KEY_E)
	_check(resident._line == line_before, "%s does not advance dialogue in the air" % kind)
	await _land()
	_check(_gameplay_snapshot() == baseline, "%s dialogue changes no health, reward, progression or encounter" % kind)
	await _check_pause(resident, String(kind))

func _check_count_in() -> void:
	var tick := _resident(&"tick")
	var door := _persistent(&"practice_count_in")
	_check(tick != null and door != null and not door.is_open, "Tick shares Practice with the unopened Count-In lock")
	if tick == null or door == null:
		return
	await _stand(tick.position + Vector2(-42, 0))
	# The lock measures wall time. Real J presses at even 350 ms intervals
	# exercise Main's unchanged strike dispatch and its knowledge discovery.
	for beat in range(4):
		await _tap(KEY_J)
		if beat < 3:
			await create_timer(0.35).timeout
	await _physics(3)
	_check(door.is_open, "four physical strikes still open the Count-In beside Tick")
	_check(_main.encounters.get("practice_room/practice_count_in") == "opened", "Count-In still records its existing lock outcome")
	_check(_main.progression.knows_technique(ProgressionScript.Technique.COUNT_IN), "Count-In still discovers its existing technique")
	_check(tick._line == -1 and tick.resident_pose().opened and not tick.is_in_group("strikable"), "Tick acknowledges the opened lock without becoming a combat target")
	_check(_main.player.shine == 0 and _main.progression.unlocked_refrains().is_empty(), "the rhythm lesson gives no new resident reward")

func _check_hound() -> void:
	_main._load_world_room(&"horn_plaza", &"from_headshell")
	await _physics(5)
	var hound := _resident(&"hound")
	_check(hound != null, "Horn Plaza has the roaming Hound")
	if hound == null:
		return
	_check_harmless(hound, "Hound")
	var baseline := _gameplay_snapshot()
	await _stand(hound.position + Vector2(40, 0))
	_key(KEY_K, true)
	await _physics(5)
	# Allow its short step back to the sitting distance before the 1.1 s pet.
	await create_timer(1.85).timeout
	_check(float(hound.pet_progress) > 0.95, "grounded, still Hood holding lets the Hound be petted")
	_check(String(hound.animation_pose().phase) == "pet", "completed quiet contact shows the pet pose")
	_check(_gameplay_snapshot() == baseline, "petting never grants rewards or changes encounter choices")
	await _check_pause(hound, "Hound")
	_key(KEY_K, false)
	await _physics(2)
	await _tap(KEY_J)
	_check(String(hound.animation_pose().phase) == "startled", "a real nearby strike startles the Hound")
	_check(_gameplay_snapshot() == baseline, "the startled Hound never damages or rewards the player")
	await create_timer(1.0).timeout
	_check(String(hound.animation_pose().phase) != "startled", "the Hound recovers from a harmless startle")
	await _stand(hound.position + Vector2(40, 0))
	_key(KEY_K, true)
	await _physics(2)
	_main.player.set_physics_process(false)
	_main.player.noise = 0.6
	for step in range(30):
		hound._process(0.05)
	_check(float(hound.pet_progress) < 0.1, "Hood alone does not pet the Hound while the player is noisy")
	_main.player.noise = 0.0
	_main.player.velocity = Vector2(80, 0)
	for step in range(30):
		hound._process(0.05)
	_check(float(hound.pet_progress) < 0.1, "moving past in a Hood does not count as still petting")
	_main.player.velocity = Vector2.ZERO
	_main.player.set_physics_process(true)
	_key(KEY_K, false)
	var narrow: float = hound.patrol_radius
	_main.encounters["the_arm/tonearm"] = "freed"
	_main._load_world_room(&"horn_plaza", &"from_headshell")
	await _physics(4)
	hound = _resident(&"hound")
	_check(hound != null and float(hound.patrol_radius) > narrow, "the saved mercy ending widens the Hound's home patrol")
	if hound != null:
		_main.player.position = Vector2(1700, 574)
		for step in range(400):
			hound._process(0.05)
			if hound.position.x < 620 or hound.position.x > 1080:
				_check(false, "Hound movement remains in the authored safe patrol bounds")
				return
		_check(true, "Hound movement remains in the authored safe patrol bounds")

func _check_addie() -> void:
	_main.encounters["addie/addie"] = "freed"
	_main._load_world_room(&"addie", &"from_whistlers")
	await _physics(5)
	var addie := _persistent(&"addie")
	_check(addie != null and addie.visible and addie._resolved == "freed", "freed Addie returns as a visible resident")
	if addie == null:
		return
	_check_harmless(addie, "freed Addie")
	_check(not addie.is_pogoable(), "freed Addie is never a pogo target")
	var baseline := _gameplay_snapshot()
	var home: Vector2 = addie.resident_pose().home
	_main.player.position = Vector2(1650, 574)
	var start: Vector2 = addie.position
	for step in range(100):
		addie._process(0.05)
	_check(not is_equal_approx(addie.position.x, start.x), "freed Addie putters beside her own doorway")
	_check(absf(addie.position.x - home.x) <= 55.1 and is_equal_approx(addie.position.y, home.y), "Addie stays on her authored floor near home")
	await _stand(addie.position + Vector2(44, -13))
	_key(KEY_K, true)
	await _physics(4)
	await create_timer(1.4).timeout
	_check(float(addie.resident_pose().pat) > 0, "freed Addie gently pats a quiet Hood visitor")
	await _check_pause(addie, "freed Addie")
	_key(KEY_K, false)
	await _physics(2)
	await _tap(KEY_J)
	_key(KEY_L, true)
	await create_timer(1.4).timeout
	_key(KEY_L, false)
	await _physics(2)
	_check(addie._resolved == "freed" and not addie.is_in_group("strikable"), "a revisit cannot return freed Addie to combat")
	_check(_gameplay_snapshot() == baseline, "Addie's kindness cannot replay Shine, discovery or outcome rewards")
	_main.encounters["addie/addie"] = "shattered"
	_main._load_world_room(&"addie", &"from_whistlers")
	await _physics(4)
	addie = _persistent(&"addie")
	_check(addie != null and not addie.visible and addie._resolved == "shattered", "a shattered Addie stays gone on revisit")
	if addie != null:
		start = addie.position
		for step in range(30):
			addie._process(0.05)
		_check(addie.position == start and not addie.visible and not addie.is_pogoable(), "a shattered Addie never putters, returns or becomes a target")

func _check_old_continue() -> void:
	await _close()
	var fixture := {"version": 1, "room_id": "bootlegger", "entry_id": "from_overture_stair", "shine": 23,
		"progression": {"version": 1, "refrains": [], "techniques": ["count-in"]},
		"encounters": {"addie/addie": "freed", "practice_room/practice_count_in": "opened"}, "completed": false}
	_check(SaveScript.new(_directory + "/checkpoint.json").save_game(fixture), "write a pre-resident version-one checkpoint")
	await _boot()
	_main._continue_game()
	await _physics(5)
	_check(_main.world_room_id == &"bootlegger" and _main.room_entry_id == &"from_overture_stair", "old Continue preserves the saved room and arrival")
	_check(_resident(&"bootlegger") != null and _main.player.shine == 23, "old Continue creates the new resident without altering Shine")
	_check(_main.progression.snapshot() == fixture.progression and _main.encounters == fixture.encounters, "old Continue preserves knowledge and resident outcomes")
	_main._load_world_room(&"addie", &"from_whistlers")
	await _physics(4)
	var addie := _persistent(&"addie")
	_check(addie != null and addie._resolved == "freed" and addie.visible, "the old mercy outcome restores Addie's living revisit")
	_check(_main.player.shine == 23, "old mercy restoration never replays its reward")

func _check_pause(resident: Node2D, label: String) -> void:
	var before := _pose(resident)
	await _physics(6)
	_check(_pose(resident) != before, label + " has an advancing life animation")
	_main._pause_game()
	var frozen := _pose(resident)
	var transform_before := resident.transform
	var line_before: int = resident.get("_line") if "_line" in resident else -1
	_key(KEY_E, true)
	await _frames(12)
	_key(KEY_E, false)
	_check(_pose(resident) == frozen and resident.transform == transform_before, label + " freezes its animation and movement while paused")
	if "_line" in resident:
		_check(resident._line == line_before, label + " cannot advance dialogue while paused")
	_main._resume_game()
	await _physics(3)

func _check_harmless(resident: Node2D, label: String) -> void:
	_check(not resident.is_in_group("strikable") and not resident.is_in_group("chapter_boss"), label + " is outside combat target groups")
	_check(not _has_collision(resident), label + " adds no collision body or shape")
	_check(not resident.has_meta("chapter_state_id") or label == "freed Addie", label + " adds no persistent encounter outcome")

func _has_collision(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D:
		return true
	for child in node.get_children():
		if _has_collision(child):
			return true
	return false

func _pose(node: Node2D) -> Dictionary:
	if node.has_method("resident_pose"):
		return node.resident_pose().duplicate(true)
	return node.animation_pose().duplicate(true)

func _resident(kind: StringName) -> Node2D:
	for child in _main.room.get_children():
		if "kind" in child and StringName(child.kind) == kind:
			return child
		if kind == &"hound" and child.has_method("animation_pose") and "pet_progress" in child:
			return child
	return null

func _persistent(id: StringName) -> Node2D:
	for child in _main.room.get_children():
		if child.get_meta("chapter_state_id", &"") == id:
			return child
	return null

func _gameplay_snapshot() -> Dictionary:
	return {"shine": _main.player.shine, "hits": _main._hits_taken,
		"progression": _main.progression.snapshot(), "encounters": _main.encounters.duplicate(true)}

func _stand(position: Vector2) -> void:
	_main.player.position = position
	_main.player.velocity = Vector2.ZERO
	await _physics(5)

func _land() -> void:
	for frame in range(70):
		await _physics(1)
		if _main.player.is_on_floor():
			return
	_check(false, "player lands after the dialogue jump")

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

func _boot() -> void:
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)

func _close() -> void:
	for key in [KEY_E, KEY_J, KEY_K, KEY_L, KEY_SPACE]:
		_key(key, false)
	if is_instance_valid(_main):
		_main.queue_free()
		await _frames(3)
	paused = false

func _physics(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in range(count):
		await process_frame

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
