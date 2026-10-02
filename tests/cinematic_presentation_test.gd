extends SceneTree
## Exercise the actual campaign's quieter presentation with private saves,
## deliberate write failures, live room changes and physical input.

const MainScene := preload("res://scenes/main.tscn")
const Save := preload("res://scripts/save_store.gd")
var _main: Node2D
var _directory := ""
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-cinematic-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "private checkpoint directory")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(4)
	_main._new_game(false)
	await _frames(4)
	var hud: Control = _main.cinematic_hud
	_check(hud.visible and not _main.masthead.visible and not _main.footer_stock.visible and not _main.controls_note.visible and not _main.combo_readout.visible, "campaign uses the quiet HUD without permanent plates or control lists")
	_check(_main.room.cinematic_mode and _main.room._notes.size() > 0, "authored room explicitly opts into cinematic mode")
	for note in _main.room._notes: _check(not note.visible, "authored tutorial card is carried into the Book instead")
	_check(hud.action_prompt.text.contains("Tap left") and _main.abilities.snapshot().unlocked.is_empty(), "movement-only opening retains a small truthful first lead")
	_check(hud.area_title.visible, "new room briefly announces its name")
	hud._process(4.0)
	_check(not hud.area_title.visible, "area title expires instead of becoming a permanent heading")
	var walk: Node2D = _main.room.get_node("AbilityWalk")
	await _stand(walk.position)
	_check(hud.action_prompt.text == "E / Y · Recover WALK" and not walk._card.visible, "nearest reachable sleeve has one short action cue")
	await _tap(KEY_E)
	_check(_main.abilities.has_ability(&"walk"), "real E still collects the saved ability in cinematic mode")
	_main.abilities.restore_snapshot(_main.AbilitiesScript.legacy_snapshot())
	_main.room.sign_label(Vector2(520, 250), "A QUIET NOTE\nA clue carried inside the Book.")
	await _frames(3)
	var note: Control = _main.room._notes.back()
	_check(not note.visible, "a live new sign also follows quiet presentation")
	_main.inventory.open_inventory()
	_main.inventory._select_slot(&"this_place")
	await _frames(3)
	_check(_main.inventory.detail_title().contains("HEADSHELL") and _main.inventory._detail_description.text.contains("A clue carried inside the Book"), "Book This Place retains live room guidance")
	_main.inventory.close_inventory()
	await _frames(3)
	_main._load_world_room(&"practice_room")
	await _stand(Vector2(465, 574))
	var tick: Node2D = _main.room.get_node("Tick")
	_check(tick.cinematic_mode and not tick._card.visible and hud.dialogue.text.is_empty(), "nearby resident does not speak or show an ambient paragraph automatically")
	_check(hud.action_prompt.text.contains("Talk"), "resident offers a single nearby action")
	await _tap(KEY_E)
	await _frames(3)
	_check(hud.dialogue.visible and hud.dialogue.text.contains("One.") and hud.speaker.text == "TICK", "actual interaction presents only the chosen spoken line")
	_check(not hud.dialogue.text.contains("Listen on") and not tick._card.visible, "subtitles contain no appended tutorial plate")
	var remaining: float = tick._dialogue_remaining
	_main._pause_game()
	await _frames(8)
	_check(is_equal_approx(tick._dialogue_remaining, remaining), "pause freezes dialogue lifetime")
	_main._resume_game()
	await _frames(3)
	# A disk failure must not be concealed by a speaking character.
	_check(DirAccess.make_dir_absolute(_main.save_path + ".tmp") == OK, "block checkpoint staging")
	_check(not _main._persist_session(), "deliberate checkpoint failure reports false")
	_check(hud.notice.visible and hud.notice.text.contains("Could not save") and not hud.dialogue.visible, "save failure takes priority over dialogue and stays readable")
	_check(not _main.controls_note.visible, "failure does not resurrect the old footer")
	_check(DirAccess.remove_absolute(_main.save_path + ".tmp") == OK, "unblock staging")
	_check(_main._persist_session(), "retry commits the campaign")
	_check(not hud.notice.visible and hud.dialogue.visible, "successful retry clears stale error and restores current speech")
	await _stand(Vector2(800, 574))
	_check(hud.dialogue.text.is_empty() and tick._line == -1, "walking away closes dialogue without carrying the paragraph")
	_main._respawn()
	await _frames(3)
	_check(not hud.notice.visible and not hud.area_title.visible, "recovery clears transient notices without repeating the room title")
	for dimensions in [Vector2i(960,540), Vector2i(1280,720)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await _stand(Vector2(465,574))
		await _tap(KEY_E)
		await _frames(3)
		for caption in [hud.dialogue, hud.speaker, hud.action_prompt]:
			var rect: Rect2 = caption.get_global_rect()
			_check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= dimensions.x and rect.end.y <= dimensions.y, "caption fits " + str(dimensions))
		_main._settings.reduced_motion = true
		_main._apply_settings()
		_check(hud.dialogue.visible and hud.action_prompt.visible, "reduced motion retains usable text cues")
	_main._load_world_room(&"verse_hall", &"from_verse_warren_n")
	await _frames(8)
	var nearby_post: Node2D
	for source in _main.room.get_children():
		if source.has_method("cancel_dialogue"):
			nearby_post = source
			break
	_check(nearby_post != null and _main.player.is_on_floor()
		and _main.player.global_position.distance_to(nearby_post.global_position) <= nearby_post.LISTEN_RADIUS,
		"Verse Hall recovery entry stays within its listening post's reach")
	await _tap(KEY_E)
	await _frames(3)
	_check(hud.dialogue.visible and not hud.dialogue.text.is_empty(), "real E starts a subtitle beside the Verse Hall entry")
	await _tap(KEY_R)
	await _frames(3)
	_check(_main.player.global_position.distance_to(nearby_post.global_position) <= nearby_post.LISTEN_RADIUS,
		"real R recovers inside the same dialogue radius")
	_check(not hud.dialogue.visible and hud.dialogue.text.is_empty()
		and nearby_post._line == -1 and nearby_post._dialogue_remaining == 0.0,
		"recovery closes the actor's subtitle so the next focus refresh cannot restore it")
	_check(hud.action_prompt.text.contains("Listen"), "recovery leaves the nearby listening interaction usable")
	_main._load_world_room(&"the_arm")
	await _frames(4)
	_main.room.session_outcomes["the_arm/tonearm"] = "freed"
	_main.room.restore_encounters({"the_arm/tonearm":"freed"})
	await _frames(4)
	for source in _main.room.get_children():
		if source.has_method("set_cinematic_mode"):
			_check(source.cinematic_mode, "live earned node inherits cinematic mode: " + String(source.name))
	_main._return_to_title()
	await _frames(3)
	_main._start_practice()
	await _frames(5)
	_check(not _main.cinematic_hud.visible and _main.masthead.visible and not _main.room.cinematic_mode, "move practice retains its explicit training guidance")
	_main._return_to_title()
	await _frames(3)
	_main.queue_free()
	await _frames(3)
	paused = false
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove private checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"): DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove private directory")
	if _failures.is_empty():
		print("DEAD WAX CINEMATIC PRESENTATION PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("CINEMATIC PRESENTATION FAIL: " + failure)
	quit(1)

func _stand(pos: Vector2) -> void:
	_main.player.position = pos
	_main.player.velocity = Vector2.ZERO
	await _frames(5)

func _tap(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(2)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
