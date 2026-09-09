extends SceneTree
## Extension regressions: old checkpoints keep their meaning, a new ending
## needs its encounter, and the authored route stays traversable in reverse.
## Every disk write uses a unique isolated user-data directory.

const MainScene := preload("res://scenes/main.tscn")
const CampaignScript := preload("res://scripts/campaign.gd")
const ChapterOne := preload("res://scripts/chapter_one.gd")
const ChapterTwo := preload("res://scripts/chapter_two.gd")
const SaveScript := preload("res://scripts/save_store.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
const SkipScript := preload("res://scripts/skip.gd")
const COMPLETE_OUTCOMES := {
	"smoothed_floor/hush": "won",
	"the_arm/gallery_shortcut": "opened",
	"the_arm/tonearm": "freed",
}
const OLD_CHOICES := {
	"practice_room/practice_count_in": "opened",
	"groove_yard/yard_first_voice": "freed",
	"groove_yard/yard_last_voice": "shattered",
	"horn_plaza/horn_wax": "polished",
}

var _checks := 0
var _failures: Array[String] = []
var _directory: String
var _save_path: String
var _settings_path: String
var _main: Node2D

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-overture-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_save_path = _directory + "/checkpoint.json"
	_settings_path = _directory + "/settings.cfg"
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated Overture test directory")
	_check_completion_rules()
	_check_full_registry()
	await _check_legacy_checkpoint()
	await _check_hush_close_parry()
	await _check_conditional_routes()
	await _check_resolution_and_ending()
	await _check_finished_checkpoints()
	await _close_main()
	_check(SaveScript.new(_save_path).delete_save(), "remove isolated Overture checkpoint and backups")
	if FileAccess.file_exists(_settings_path):
		_check(DirAccess.remove_absolute(_settings_path) == OK, "remove isolated Overture settings")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated Overture directory")
	if _failures.is_empty():
		print("DEAD WAX OVERTURE PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("OVERTURE FAIL: " + failure)
	quit(1)

func _check_completion_rules() -> void:
	for complete in [false, true]:
		for outcome in ["", "opened", "polished", "won", "freed", "shattered"]:
			var data := _fixture(&"the_arm", &"from_smoothed_floor", complete)
			if not outcome.is_empty():
				data.encounters["the_arm/tonearm"] = outcome
			var expected: bool = complete and outcome in ["freed", "shattered"]
			_check(CampaignScript.saved_completion(data) == expected,
				"completion requires both ending flag and Tonearm resolution (%s/%s)" % [complete, outcome])
	_check(not CampaignScript.saved_completion(_fixture(&"overture_stair", &"from_label_descent", true)),
		"the old stair ending alone is not the extended campaign ending")

func _check_full_registry() -> void:
	var ids: Array[StringName] = CampaignScript.room_ids()
	_check(ids.size() == 15 and ChapterOne.room_ids().size() == 8 and ChapterTwo.room_ids().size() == 7,
		"campaign combines the eight opening rooms and seven Overture rooms")
	_check(CampaignScript.START_ROOM == &"headshell" and CampaignScript.END_ROOM == &"the_arm",
		"campaign begins at home and ends at the Tonearm")
	_check(not CampaignScript.has_room(&"undersong_sump") and CampaignScript.create_room(&"undersong_sump") == null,
		"the campaign never falls back to an unauthored graybox")
	var entries := {}
	var edges: Array[Dictionary] = []
	var unique := {}
	for id in ids:
		_check(not unique.has(id), "authored room identity is unique: %s" % id)
		unique[id] = true
		var room: Node2D = CampaignScript.create_room(id)
		if room == null:
			_check(false, "%s creates a room" % id)
			continue
		room.process_mode = Node.PROCESS_MODE_DISABLED
		room.progression = ProgressionScript.new()
		if "session_outcomes" in room:
			room.session_outcomes = {}
		root.add_child(room)
		_check(room.room_id == id and not String(room.objective_label).is_empty(), "%s boots with an authored objective" % id)
		entries[id] = room.entry_points.keys()
		var supports := _platforms(room)
		_check(_supported(supports, room.spawn_pos), "%s default spawn has a full player-width floor" % id)
		for entry_id in room.entry_points:
			_check(_supported(supports, room.entry_points[entry_id]), "%s/%s arrival has a full player-width floor" % [id, entry_id])
		var entity_ids := {}
		for child in room.get_children():
			if child.has_meta("chapter_state_id"):
				var entity_id := String(child.get_meta("chapter_state_id"))
				_check(not entity_ids.has(entity_id), "%s stable encounter ID is unique: %s" % [id, entity_id])
				entity_ids[entity_id] = true
			if not child.is_in_group("room_exit"):
				continue
			_check(CampaignScript.has_room(child.target_room), "%s passage targets an authored room: %s" % [id, child.target_room])
			_check(_supported(supports, child.position), "%s passage to %s is reachable from a standing position" % [id, child.target_room])
			edges.append({"source": id, "target": child.target_room, "entry": child.target_entry, "locked": child.is_locked()})
			if id == &"smoothed_floor" and child.target_room == &"the_arm":
				for wrong_outcome in ["opened", "freed", "shattered"]:
					room.session_outcomes["smoothed_floor/hush"] = wrong_outcome
					_check(child.is_locked(), "HUSH gate accepts a won bout, not %s" % wrong_outcome)
				room.session_outcomes.clear()
			if id == &"worn_gallery" and child.target_room == &"the_arm":
				room.session_outcomes["the_arm/gallery_shortcut"] = "won"
				_check(child.is_locked(), "Gallery latch requires its opened state")
				room.session_outcomes.clear()
		if id == &"overture_stair":
			_check(_room_marker(room) == null and _room_exit(room, &"bootlegger") != null,
				"the former stair endpoint is now a passage to the Bootlegger")
		if id == &"overture_well":
			_check_well_return(room, supports)
		if id == &"whistlers":
			_check_recovery_headroom(supports)
		if id == &"the_arm":
			_check(_room_marker(room) == null or not _room_marker(room).is_processing(),
				"unresolved Tonearm room cannot offer an active ending marker")
		room.free()
	for edge in edges:
		_check(edge.entry in entries.get(edge.target, []), "%s > %s resolves a real named arrival" % [edge.source, edge.target])
	_check(_reachable_rooms(edges, false).size() == ids.size(), "all fifteen authored rooms belong to one connected route")
	var before_hush := _reachable_rooms(edges, true)
	_check(before_hush.has(&"smoothed_floor") and not before_hush.has(&"the_arm"),
		"a fresh route reaches HUSH but cannot bypass it through the Gallery shortcut")

func _check_recovery_headroom(solids: Array[Rect2]) -> void:
	var steps := 0
	for ledge in solids:
		if ledge.position.y <= 600 or ledge.position.y >= 880:
			continue
		steps += 1
		var can_stand := false
		# A tread needs space for the whole 34x52 body above it. Foot support
		# alone misses a step tucked immediately under a bank's underside.
		for x in range(int(ceil(ledge.position.x + 17)), int(floor(ledge.end.x - 17)) + 1):
			var standing_body := Rect2(Vector2(x - 17, ledge.position.y - 52), Vector2(34, 52))
			var blocked := false
			for obstacle in solids:
				if standing_body.intersects(obstacle):
					blocked = true
					break
			if not blocked:
				can_stand = true
				break
		_check(can_stand, "Whistlers recovery tread at %s has a full standing body of clear headroom" % ledge.position)
	_check(steps >= 4, "Whistlers provides a pair of catch-lane recovery steps at each bank")

func _check_well_return(room: Node2D, solids: Array[Rect2]) -> void:
	var lower: Vector2 = room.entry_position(&"from_worn_gallery")
	var upper := _room_exit(room, &"addie")
	_check(upper != null, "Well has a reverse passage back to Addie")
	if upper == null:
		return
	_check(lower.y - upper.position.y > 180.0, "Well return actually climbs more than one plain jump")
	var jump_rise := pow(SkipScript.JUMP_VELOCITY, 2.0) / (2.0 * SkipScript.GRAVITY)
	var reached := {}
	var frontier: Array[int] = []
	for index in solids.size():
		if _supports(solids[index], lower):
			frontier.append(index)
	while not frontier.is_empty():
		var current: int = frontier.pop_front()
		if reached.has(current):
			continue
		reached[current] = true
		for index in solids.size():
			var rise := solids[current].position.y - solids[index].position.y
			if reached.has(index) or rise > jump_rise or rise < -jump_rise:
				continue
			# Flight time to this height, with a margin for starting/stopping on
			# the ledge. Unlike a room-wide overlap check this starts at the
			# lower arrival and constrains every upward hop by the player's rise.
			var flight := (absf(SkipScript.JUMP_VELOCITY) + sqrt(maxf(0, pow(SkipScript.JUMP_VELOCITY, 2) - 2 * SkipScript.GRAVITY * rise))) / SkipScript.GRAVITY
			var gap := maxf(0.0, maxf(solids[index].position.x - solids[current].end.x, solids[current].position.x - solids[index].end.x))
			if gap + 34.0 <= SkipScript.RUN_SPEED * flight * 0.75:
				frontier.append(index)
	var reaches_top := false
	for index in reached:
		reaches_top = reaches_top or _supports(solids[index], upper.position)
	_check(reaches_top, "Well reverse route reaches Addie using jump-sized steps without a Refrain")

func _check_legacy_checkpoint() -> void:
	var data := _fixture(&"overture_stair", &"from_label_descent", true)
	_check(SaveScript.new(_save_path).save_game(data), "write isolated v1 completed-demo fixture")
	await _boot()
	_check(_main.game_menu._can_continue, "old completed demo still offers Continue")
	_main.game_menu.continue_requested.emit()
	await _frames(5)
	_check(_main.world_room_id == &"overture_stair" and _main.room_entry_id == &"from_label_descent",
		"demo migration keeps the exact stair and entry")
	_check(not _main.chapter_complete and not paused and not _main.game_menu.is_open,
		"demo Continue resumes the unfinished extended campaign")
	_check(_main.player.shine == 17 and _main.progression.knows_technique(ProgressionScript.Technique.COUNT_IN),
		"demo migration preserves Shine and Count-In")
	_check(_main.encounters == OLD_CHOICES, "demo migration preserves opened doors, polish, mercy and force choices")
	var saved: Dictionary = _main.save_store.load_game()
	_check(saved.version == 1 and not saved.completed and saved.entry_id == "from_label_descent" and saved.encounters == OLD_CHOICES,
		"Continue writes a normalized unfinished checkpoint without a schema bump or lost choices")
	var passage := _room_exit(_main.room, &"bootlegger")
	_check(passage != null, "continued demo exposes the new physical passage")
	if passage != null:
		await _enter(passage)
		_check(_main.world_room_id == &"bootlegger" and _main.room_entry_id == &"from_overture_stair",
			"physical E at the old endpoint enters the Bootlegger instead of replaying the ending")
	_check(not _main.chapter_complete, "crossing the old ending platform never completes the extension")

func _check_hush_close_parry() -> void:
	_main._load_world_room(&"smoothed_floor", &"from_worn_gallery")
	await _frames(4)
	var hush := _persistent(&"hush")
	_check(hush != null, "close HUSH parry has its authored opponent")
	if hush == null:
		return
	# Start at the visible wind-up rather than waiting through three ticks.
	# Everything after that uses actual J input, Skip's strike/pogo, Main's
	# listener wiring, and normal process/physics time. Never mint a parry by
	# writing last_strike_ms or invoking the swing resolver directly.
	hush.set_process(false)
	_main.player.position = hush.position + Vector2(-60, 17)
	_main.player.velocity = Vector2.ZERO
	await _physics_frames(4)
	_check(_main.player.is_on_floor(), "close HUSH parry begins with grounded feet")
	var previous_strike: int = _main.player.last_strike_ms
	var previous_health: int = _main._health
	hush.state = hush.S.SWING
	hush._t = 0.06
	hush.set_process(true)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_J
	event.keycode = KEY_J
	event.pressed = true
	Input.parse_input_event(event)
	await _physics_frames(2)
	event = InputEventKey.new()
	event.physical_keycode = KEY_J
	event.keycode = KEY_J
	event.pressed = false
	Input.parse_input_event(event)
	_check(_main.player.last_strike_ms > previous_strike, "physical J produces Skip's real close-range strike")
	var deadline := Time.get_ticks_msec() + 700
	while hush.state == hush.S.SWING and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(hush.state == hush.S.STAGGER and hush.parry_count == 1,
		"a close, correctly timed real strike catches HUSH without postponing his swing")
	_check(_main._health == previous_health, "the correctly timed close HUSH parry costs no needle health")
	_check(is_zero_approx(float(hush.resonance)), "a real HUSH parry keeps the burnished floor free of resonance")
	_main._respawn()
	await _physics_frames(3)

func _check_conditional_routes() -> void:
	_main._load_world_room(&"worn_gallery", &"from_overture_well")
	await _frames(4)
	var shortcut := _room_exit(_main.room, &"the_arm")
	_check(shortcut != null and shortcut.is_locked(), "Gallery shortcut begins sealed")
	if shortcut != null:
		await _enter(shortcut)
		_check(_main.world_room_id == &"worn_gallery", "physical E cannot bypass HUSH through the unopened Gallery shortcut")
	_main._load_world_room(&"smoothed_floor", &"from_worn_gallery")
	await _frames(4)
	var onward := _room_exit(_main.room, &"the_arm")
	var back := _room_exit(_main.room, &"worn_gallery")
	_check(onward != null and onward.is_locked(), "HUSH forward passage requires a won bout")
	_check(back != null and not back.is_locked(), "HUSH always leaves the return passage open")
	if onward != null:
		await _enter(onward)
		_check(_main.world_room_id == &"smoothed_floor", "physical E cannot skip the unfinished HUSH bout")
	var hush := _persistent(&"hush")
	_check(hush != null and hush.has_signal("bout_won"), "HUSH exposes a stable bout outcome")
	if hush == null:
		return
	# The boss suite exercises the duel. Here the real outcome signal must
	# travel through Main's save wiring and unlock this room's existing exit.
	hush.emit_signal("bout_won")
	await _frames(4)
	_check(_main.encounters.get("smoothed_floor/hush") == "won", "HUSH victory signal records its campaign outcome")
	_check(onward != null and not onward.is_locked(), "HUSH victory opens the current forward passage without recreating the room")
	if onward == null:
		return
	await _enter(onward)
	_check(_main.world_room_id == &"the_arm" and _main.room_entry_id == &"from_smoothed_floor", "won HUSH passage enters the Tonearm's named arrival")
	_check(_main.encounters.get("the_arm/gallery_shortcut") == "opened", "first legitimate Arm arrival unbars the Gallery return shortcut")
	_main._on_chapter_completed()
	await _frames(3)
	_check(not _main.chapter_complete and not paused, "an unresolved Tonearm cannot complete the campaign even through a premature signal")
	var before: Dictionary = _main.encounters.duplicate(true)
	_main._load_world_room(&"worn_gallery", &"from_the_arm")
	await _frames(3)
	shortcut = _room_exit(_main.room, &"the_arm")
	_check(shortcut != null and not shortcut.is_locked(), "unbarred Gallery shortcut stays open on room recreation")
	if shortcut != null:
		await _enter(shortcut)
		_check(_main.world_room_id == &"the_arm" and _main.room_entry_id == &"from_worn_gallery", "opened shortcut returns to the Arm's Gallery arrival")
	_check(_main.encounters == before, "reusing the shortcut does not change prior encounter outcomes")

func _check_resolution_and_ending() -> void:
	# Tonearm mechanics are covered by tonearm_test. This checks Main's actual
	# R recovery wiring and the live resolution signal crossing into saves.
	if _main.world_room_id != &"the_arm":
		_main._load_world_room(&"the_arm", &"from_smoothed_floor")
		await _frames(3)
	var boss := _persistent(&"tonearm")
	_check(boss != null and boss.is_in_group("chapter_boss") and boss.has_method("reset_attempt"),
		"Tonearm participates in Main's attempt-reset contract")
	_check(_room_marker(_main.room) == null or not _room_marker(_main.room).is_processing(),
		"unresolved live boss has no active completion marker")
	if boss == null:
		return
	var full_hp: float = boss.hp
	boss.call("on_player_strike", boss.position, false)
	boss.hp = 2.0
	await _key(KEY_R)
	_check(is_equal_approx(float(boss.hp), full_hp) and not boss._engaged and String(boss.outcome).is_empty(),
		"physical R resets the unresolved boss attempt as well as the player")
	_check(_main.world_room_id == &"the_arm" and _main._health == 3,
		"boss attempt recovery keeps the room and restores needle health")
	boss.call("_resolve_outcome", "freed")
	await _frames(4)
	_check(_main.encounters.get("the_arm/tonearm") == "freed", "Tonearm resolution signal records mercy through Main")
	var marker := _room_marker(_main.room)
	_check(marker != null, "live Tonearm mercy exposes the completion point without recreating the room")
	_main._respawn()
	await _frames(3)
	_check(_main.encounters.get("the_arm/tonearm") == "freed" and boss.outcome == "freed",
		"recovery preserves a resolved Tonearm and cannot restart its battle")
	if marker == null:
		return
	_main.player.position = marker.position + Vector2(0, -160)
	_main.player.velocity = Vector2.ZERO
	marker.call("_process", 0.0)
	_check(not marker.try_activate(), "completion cannot be triggered while airborne above the endpoint")
	await _enter(marker)
	_check(_main.chapter_complete and paused and _main.game_menu.screen == "ending", "physical E at the resolved grounded endpoint shows the extended ending")
	_check(_main.save_store.load_game().completed, "extended completion reaches the checkpoint")
	_check(not marker.try_activate(), "resolved ending only activates once")
	await _close_main()
	await _boot()
	_main._continue_game()
	await _frames(4)
	marker = _room_marker(_main.room)
	_check(_main.chapter_complete and _main.encounters.get("the_arm/tonearm") == "freed",
		"fresh Continue preserves Tonearm mercy and extended completion")
	_check(marker != null and marker.used, "completed Continue restores the endpoint as used")
	if marker != null:
		await _enter(marker)
		_check(not paused and not _main.game_menu.is_open, "restored completed endpoint cannot replay the ending")

func _check_finished_checkpoints() -> void:
	for outcome in ["freed", "shattered"]:
		for complete in [false, true]:
			await _close_main()
			var data := _fixture(&"the_arm", &"from_smoothed_floor", complete)
			data.encounters.merge(COMPLETE_OUTCOMES)
			data.encounters["the_arm/tonearm"] = outcome
			data.encounters["addie/addie"] = outcome
			_check(SaveScript.new(_save_path).save_game(data), "write resolved %s/%s checkpoint" % [outcome, complete])
			await _boot()
			_main._continue_game()
			await _frames(4)
			_check(_main.chapter_complete == complete and _main.encounters.get("the_arm/tonearm") == outcome,
				"Continue preserves resolved %s with ending flag %s" % [outcome, complete])
			var marker := _room_marker(_main.room)
			_check(marker != null and marker.used == complete, "resolved %s checkpoint restores the endpoint's exact used state" % outcome)
			_check(_main.player.shine == 17 and _main.room_entry_id == &"from_smoothed_floor", "resolved Continue keeps its entry and Shine")
			_main._respawn()
			_check(_main.encounters.get("the_arm/tonearm") == outcome, "recovery cannot erase a %s resolution" % outcome)
			_main._load_world_room(&"addie", &"from_whistlers")
			await _frames(3)
			var addie := _persistent(&"addie")
			_check(addie != null and addie._resolved == outcome and not addie.is_in_group("strikable")
				and _main.encounters.get("addie/addie") == outcome,
				"Continue restores Addie's %s choice without restarting the encounter" % outcome)
			_check(addie != null and addie.visible == (outcome == "freed"),
				"Addie's doorway preserves the distinct %s presentation" % outcome)

func _fixture(id: StringName, entry: StringName, complete: bool) -> Dictionary:
	return {
		"version": 1, "room_id": String(id), "entry_id": String(entry),
		"progression": {"version": 1, "refrains": [], "techniques": ["count-in"]},
		"shine": 17, "completed": complete, "encounters": OLD_CHOICES.duplicate(true),
	}

func _platforms(room: Node2D) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for child in room.get_children():
		if not child is StaticBody2D or child.has_meta("chapter_state_id"):
			continue
		for shape_node in child.get_children():
			if shape_node is CollisionShape2D and shape_node.shape is RectangleShape2D:
				var size: Vector2 = shape_node.shape.size
				if size.x >= 70 and size.x >= size.y:
					result.append(Rect2(child.position + shape_node.position - size / 2.0, size))
	return result

func _supports(solid: Rect2, center: Vector2) -> bool:
	return absf(solid.position.y - center.y - 26.0) < 1.0 and center.x >= solid.position.x + 17 and center.x <= solid.end.x - 17

func _supported(solids: Array[Rect2], point: Vector2) -> bool:
	for solid in solids:
		if _supports(solid, point):
			return true
	return false

func _reachable_rooms(edges: Array[Dictionary], honor_locks: bool) -> Dictionary:
	var reached := {}
	var frontier: Array[StringName] = [CampaignScript.START_ROOM]
	while not frontier.is_empty():
		var id: StringName = frontier.pop_front()
		if reached.has(id):
			continue
		reached[id] = true
		for edge in edges:
			if edge.source == id and (not honor_locks or not edge.locked):
				frontier.append(edge.target)
	return reached

func _room_exit(room: Node2D, target: StringName) -> Node2D:
	for child in room.get_children():
		if child.is_in_group("room_exit") and child.target_room == target:
			return child
	return null

func _room_marker(room: Node2D) -> Node2D:
	for child in room.get_children():
		if child.is_in_group("chapter_endpoint"):
			return child
	return null

func _persistent(id: StringName) -> Node:
	for child in _main.room.get_children():
		if child.get_meta("chapter_state_id", &"") == id:
			return child
	return null

func _enter(node: Node2D) -> void:
	_main.player.position = node.position
	_main.player.velocity = Vector2.ZERO
	await _physics_frames(4)
	await _key(KEY_E)

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(3)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(2)

func _boot() -> void:
	_main = MainScene.instantiate()
	_main.save_path = _save_path
	_main.settings_path = _settings_path
	root.add_child(_main)
	await _frames(3)

func _close_main() -> void:
	if is_instance_valid(_main):
		_main.queue_free()
		await _frames(3)
	paused = false

func _frames(count: int) -> void:
	for frame in range(count):
		await process_frame

func _physics_frames(count: int) -> void:
	for frame in range(count):
		await physics_frame
	await process_frame

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
