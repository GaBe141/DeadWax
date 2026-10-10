extends SceneTree
## The animation moments are presentation. Skip's gestures, dust and listening
## turn change no body, facing, clock, input or model; the Book's board, page
## turns and closing fold, the map unfolding and the room wipe never delay
## focus, input, a room load or a close; the HUD reacts only to what Main
## reports. Pause freezes the world's motion and Reduced motion settles the
## screen-sized ones. A logger fails the run on any script error.

const MainScene := preload("res://scenes/main.tscn")
const SaveScript := preload("res://scripts/save_store.gd")
const SkipScript := preload("res://scripts/skip.gd")
const AbilitiesScript := preload("res://scripts/abilities_state.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
const PostScript := preload("res://scripts/listening_post.gd")
const ResidentScript := preload("res://scripts/resident.gd")
const Gesture := preload("res://scripts/press_skip_gesture.gd")
const PressMap := preload("res://scripts/press_map.gd")
const Capture := preload("res://scripts/screen_capture.gd")
const Press := preload("res://scripts/press.gd")
const BookMotion := preload("res://scripts/book_motion.gd")
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "jump", "strike", "lift", "set", "enter_passage"]

class ErrorLog extends Logger:
	var script_errors: Array[String] = []
	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_SCRIPT:
			script_errors.append("%s:%d %s" % [file, line, rationale if not rationale.is_empty() else code])
	func _log_message(_message: String, _error: bool) -> void:
		pass

class Canvas extends Control:
	var paint: Callable
	var calls := 0
	func _draw() -> void:
		if paint.is_valid():
			paint.call(self)
			calls += 1

var _checks := 0
var _failures: Array[String] = []
var _directory := ""
var _main: Node2D
var _log := ErrorLog.new()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.add_logger(_log)
	_directory = "user://deadwax-moments-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create private animation fixture")
	_check_helpers()
	await _check_drawing()
	await _check_skip()
	await _check_main()
	if is_instance_valid(_main):
		_main.queue_free()
		await _frames(3)
	paused = false
	_check(SaveScript.new(_directory + "/checkpoint.json").delete_save(), "remove private checkpoint")
	for name in ["settings.cfg", "settings.cfg.tmp"]:
		if FileAccess.file_exists(_directory + "/" + name):
			DirAccess.remove_absolute(_directory + "/" + name)
	_check(DirAccess.remove_absolute(_directory) == OK, "remove private animation fixture")
	await create_timer(0.2).timeout
	OS.remove_logger(_log)
	for error in _log.script_errors:
		_failures.append("script error: " + error)
	if _failures.is_empty():
		print("DEAD WAX ANIMATION MOMENTS PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("ANIMATION MOMENTS FAIL: " + failure)
	quit(1)

# -- pure helpers -----------------------------------------------------------------

func _check_helpers() -> void:
	var settled := Gesture.fidget(Gesture.IDLE_DELAY - 0.1)
	_check(settled.kind == &"" and float(settled.weight) == 0.0, "no fidget before Skip has stood still long enough")
	var tap := Gesture.fidget(Gesture.IDLE_DELAY + 1.0)
	_check(tap.kind == &"tap" and is_equal_approx(float(tap.weight), 1.0), "standing still first taps along")
	var cycle := 0.0
	for entry in Gesture.FIDGETS:
		cycle += float(entry[1])
	_check(Gesture.fidget(Gesture.IDLE_DELAY + 3.2 + 0.5).kind == &"", "fidgets rest between turns")
	_check(Gesture.fidget(Gesture.IDLE_DELAY + 3.2 + 1.4 + 1.0).kind == &"look", "then Skip looks around")
	_check(Gesture.fidget(Gesture.IDLE_DELAY + 3.2 + 1.4 + 2.6 + 1.2 + 1.0).kind == &"polish", "then polishes the stylus")
	_check(Gesture.fidget(Gesture.IDLE_DELAY + cycle + 1.0).kind == &"tap", "and the cycle repeats")
	var raised := Gesture.sample({"face": 1.0, "item": 0.5})
	_check(float(raised.stylus) > 0.99 and Vector2(raised.tip).y < -45.0, "a held find lifts the stylus overhead")
	var hooded := Gesture.sample({"face": 1.0, "item": 0.5, "hood": 1.0})
	_check(is_zero_approx(float(hooded.stylus)), "Hood folds a gesture away")
	var mirrored := Gesture.sample({"face": -1.0, "idle": Gesture.IDLE_DELAY + 3.2 + 1.4 + 2.6 + 1.2 + 1.0})
	_check(Vector2(mirrored.tip).x < 0.0 and float(mirrored.stylus) > 0.9, "polishing follows the drawn facing")
	# The folded guide: a letter fold that ends as the open sheet.
	var size := Vector2(900, 360)
	var third := size.x / 3.0
	var closed := PressMap.fold_layout(size, 0.0)
	_check(closed.size() == 3 and int(closed[0].index) == 1 and int(closed[2].index) == 2, "the middle third lies under both flaps, the right on top")
	_check(not bool(closed[1].front) and not bool(closed[2].front), "the closed guide shows only the flaps' outsides")
	for entry in closed:
		var rect: Rect2 = entry.rect
		_check(rect.position.x >= third - 0.5 and rect.end.x <= third * 2.0 + 0.5, "the closed guide is one third wide")
	var opened := PressMap.fold_layout(size, 1.0)
	for entry in opened:
		var rect: Rect2 = entry.rect
		var index := int(entry.index)
		_check(bool(entry.front) and is_equal_approx(rect.position.x, third * index) and is_equal_approx(rect.size.x, third),
			"the open guide lays panel %d flat in its own third" % index)
		var base: Transform2D = entry.base
		_check((base * Vector2(third * index, 7.0)).is_equal_approx(Vector2(0, 7)) and (base * Vector2(third * (index + 1), 7.0)).is_equal_approx(Vector2(third, 7)),
			"panel %d prints its own third of the chart" % index)
	var middle := PressMap.fold_layout(size, 0.5)
	_check(bool(middle[2].front) and not bool(middle[1].front), "the right flap opens before the left")
	_check(Capture.grab(root) == {} if DisplayServer.get_name() == "headless" else Capture.grab(root).has("texture"),
		"a still is taken only where frames are drawn")
	var uvs := Capture.uvs({"visible": Rect2(0, 0, 200, 100)}, PackedVector2Array([Vector2(100, 50), Vector2(200, 0)]))
	_check(uvs[0].is_equal_approx(Vector2(0.5, 0.5)) and uvs[1].is_equal_approx(Vector2(1, 0)), "still UVs follow the visible canvas")

# -- every drawing path runs ---------------------------------------------------------

func _check_drawing() -> void:
	var canvas := Canvas.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)
	var plans: Array[Callable] = []
	for progress in [0.0, 0.2, 0.5, 0.8, 0.99]:
		for forward in [1.0, -1.0]:
			plans.append(func(c: Control) -> void: Press.draw_room_wipe(c, c.size, {"progress": progress, "direction": forward}, {}))
			plans.append(func(c: Control) -> void: Press.draw_page_turn(c, {"rect": Rect2(40, 120, 1200, 520), "progress": progress, "direction": forward}, {}))
		plans.append(func(c: Control) -> void: Press.draw_room_wipe(c, c.size, {"progress": progress, "reduced": true}, {}))
		plans.append(func(c: Control) -> void: Press.draw_book_cover(c, Rect2(Vector2.ZERO, c.size), progress))
		plans.append(func(c: Control) -> void: Press.draw_book_fold(c, {"rect": Rect2(Vector2.ZERO, c.size), "progress": progress, "target": Vector2(600, 500)}, {}))
		plans.append(func(c: Control) -> void: Press.draw_chart_fold(c, Vector2(300, 400), {"turned": 1.0 - progress, "shade": progress * 0.4, "cover": true}, Color.WHITE, Color.BLACK))
		plans.append(func(c: Control) -> void: Press.draw_cinematic(c, c.size, {"health": 2, "max_health": 4,
			"cracks": [-1.0, -1.0, progress, -1.0], "inks": [progress, -1.0, -1.0, -1.0], "burst": progress, "burst_still": progress > 0.5,
			"xp": {"level": 2, "ratio": progress, "picks": 1, "flash": progress}}, Color.WHITE, Color.ORANGE))
		for kind in [&"move", &"pressing", &"map", &"refrain", &"spool", &"slip", &"gear"]:
			plans.append(func(c: Control) -> void: Press.draw_skip(c, _gesture_pose({"item": 1.0 - progress, "item_kind": kind, "item_detail": &"pogo"}), _palette()))
		plans.append(func(c: Control) -> void: Press.draw_skip(c, _gesture_pose({"book": 1.0 - progress, "nod": progress, "listen": progress, "glow": progress}), _palette()))
		plans.append(func(c: Control) -> void: Press.draw_skip(c, _gesture_pose({"idle": Gesture.IDLE_DELAY + progress * 18.0, "beat": progress, "face": -1.0}), _palette()))
		plans.append(func(c: Control) -> void: Press.draw_skip_dust(c, [{"at": Vector2(10, 25), "age": progress, "size": 1.0}], Color.WHEAT))
	for plan in plans:
		canvas.paint = plan
		canvas.queue_redraw()
		await process_frame
	_check(canvas.calls >= plans.size(), "every new drawing path renders (%d plans)" % plans.size())
	canvas.queue_free()
	await process_frame

func _gesture_pose(extra: Dictionary) -> Dictionary:
	var pose := {"time": 1.0, "stride": 0.0, "run": 0.0, "air": 0.0, "vertical": 0.0, "hood": 0.0, "set": 0.0,
		"face": 1.0, "land": 0.0, "impact": 0.0, "launch": 0.0, "strike": 0.0, "big": false, "combo_step": 1,
		"strike_face": 1.0, "strike_contact": &"miss", "strike_hold": 0.0, "contact_pulse": 0.0, "parry": 0.0,
		"parry_face": 1.0, "queued": 0.0, "strike_launched": false, "strike_pogo": false, "hurt": 0.0,
		"hit_direction": -1.0, "noise": 0.0, "flat": 0.0}
	pose.merge(extra, true)
	return pose

func _palette() -> Dictionary:
	return {"ink": SkipScript.INK, "body": SkipScript.IRON, "pale": SkipScript.PALE, "pink": Press.PINK, "hood": SkipScript.HOODGREY, "warm_thread": false}

# -- Skip alone ---------------------------------------------------------------------

func _check_skip() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var floor := StaticBody2D.new()
	floor.position = Vector2(0, 500)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(20000, 40)
	shape.shape = rectangle
	floor.add_child(shape)
	root.add_child(floor)
	var skip: CharacterBody2D = SkipScript.new()
	skip.position = Vector2(0, 440)
	root.add_child(skip)
	for frame in 40:
		await physics_frame
		if skip.is_on_floor() and absf(skip.velocity.y) < 1.0: break
	await _physics(4)
	_check(skip.is_on_floor(), "a standalone Skip stands on the fixture floor")
	var collider := skip.get_child(0) as CollisionShape2D
	var body := _body(skip)
	# The Book snapped shut and tucked away.
	skip.present_book_close()
	_check(is_equal_approx(float(skip._animation_pose().book), 1.0), "closing the Book starts the tuck from the top")
	await create_timer(0.45).timeout
	var tucking := float(skip._animation_pose().book)
	_check(tucking > 0.0 and tucking < 1.0, "the tuck plays out over time")
	_check(_body(skip) == body, "the tuck never moves Skip, turns him, or touches a clock")
	await create_timer(0.7).timeout
	_check(is_zero_approx(float(skip._animation_pose().book)), "the tuck finishes on its own")
	# A find raised overhead; running lowers it sooner.
	skip.present_item(&"map")
	var pose: Dictionary = skip._animation_pose()
	_check(pose.item_kind == &"map" and is_equal_approx(float(pose.item), 1.0), "a find is raised with its kind")
	await create_timer(0.5).timeout
	_check(float(skip._animation_pose().item) > 0.3 and _body(skip) == body, "standing, the find stays aloft without moving the body")
	skip.present_item(&"refrain")
	Input.action_press("move_right")
	await create_timer(0.65).timeout
	Input.action_release("move_right")
	_check(is_zero_approx(float(skip._animation_pose().item)), "running lowers a raised find early")
	await _stop(skip)
	body = _body(skip)
	# Combat takes over at once.
	skip.present_book_close()
	skip.present_level_up()
	skip.set_physics_process(false)
	skip._strike_cd = 0.0
	skip._strike()
	_check(is_zero_approx(float(skip._animation_pose().book)) and float(skip._animation_pose().glow) > 0.0,
		"a strike cancels a gesture but not a level's ring")
	skip.present_item(&"spool")
	skip.take_hit(skip.global_position + Vector2(50, 0))
	_check(is_zero_approx(float(skip._animation_pose().item)), "a hit drops a raised find")
	skip.velocity = Vector2.ZERO
	skip._stagger = 0.0
	skip.reset_animation()
	skip.set_physics_process(true)
	await _stop(skip)
	# Idle fidgets begin only after Skip has been left alone.
	skip.reset_animation()
	body = _body(skip)
	skip._idle_time = Gesture.IDLE_DELAY - 0.2
	await create_timer(0.5).timeout
	pose = skip._animation_pose()
	_check(float(pose.idle) > Gesture.IDLE_DELAY and Gesture.fidget(float(pose.idle)).kind == &"tap", "left alone, Skip starts tapping along")
	_check(_body(skip) == body, "fidgets never move Skip or change his facing")
	Input.action_press("move_left")
	await _physics(3)
	Input.action_release("move_left")
	_check(is_zero_approx(float(skip._animation_pose().idle)), "any movement ends the fidget")
	await _stop(skip)
	# A speaker turns the drawn figure; the strike direction stays the player's.
	skip.facing = 1.0
	skip.reset_animation()
	skip.present_attention(skip.global_position + Vector2(-120, 0))
	_check(float(skip._animation_pose().nod) > 0.9, "a spoken line starts a nod")
	await create_timer(0.3).timeout
	pose = skip._animation_pose()
	_check(float(pose.face) < -0.5 and skip.facing == 1.0 and float(pose.listen) > 0.5, "Skip turns to listen without changing his facing")
	Input.action_press("move_right")
	await _physics(4)
	Input.action_release("move_right")
	await create_timer(0.3).timeout
	pose = skip._animation_pose()
	_check(float(pose.face) > 0.5 and float(pose.listen) < 0.5, "walking away ends the listening turn")
	await _stop(skip)
	# Footwork dust stays where it was kicked up.
	skip.reset_animation()
	Input.action_press("jump")
	await _physics(2)
	Input.action_release("jump")
	await process_frame
	var dust: Array[Dictionary] = skip.dust_snapshot()
	_check(dust.size() >= 2 and not skip.is_on_floor(), "taking off kicks up dust")
	var origins: Array[float] = []
	for puff in dust:
		origins.append(Vector2(puff.at).y)
	_check(origins.max() > skip.global_position.y + 10.0, "take-off dust starts at the feet, not the rising body")
	for frame in 90:
		await physics_frame
		if skip.is_on_floor(): break
	await create_timer(0.6).timeout
	_check(skip.dust_snapshot().is_empty(), "dust thins away on its own")
	Input.action_press("move_right")
	await create_timer(0.45).timeout
	Input.action_release("move_right")
	Input.action_press("move_left")
	var skidded := false
	for frame in 20:
		await physics_frame
		await process_frame
		if skip.velocity.x > 0.0 and not skip.dust_snapshot().is_empty():
			skidded = true
	Input.action_release("move_left")
	_check(skidded, "turning at a run skids up dust")
	await _stop(skip)
	skip.present_item(&"gear")
	skip.present_attention(skip.global_position + Vector2(80, 0))
	skip._kick_dust(skip.global_position, Vector2.ZERO, 1.0)
	skip.reset_animation()
	pose = skip._animation_pose()
	for key in ["book", "item", "nod", "listen", "glow", "idle"]:
		_check(is_zero_approx(float(pose[key])), "reset clears the %s moment" % key)
	_check(pose.item_kind == &"" and skip.dust_snapshot().is_empty(), "reset clears the held find and dust")
	# Pause freezes the moments with the body.
	skip.present_item(&"slip")
	await create_timer(0.1).timeout
	paused = true
	var frozen: Dictionary = skip._animation_pose().duplicate(true)
	var frozen_body := _body(skip)
	await create_timer(0.3, true).timeout
	_check(skip._animation_pose() == frozen and _body(skip) == frozen_body, "pause freezes Skip's moments")
	paused = false
	skip.set_physics_process(false)
	skip.set_process(false)
	var clocks := _clocks(skip)
	var shape_size: Vector2 = (collider.shape as RectangleShape2D).size
	for gesture in ["book", "item", "attention", "idle", "level", "dust"]:
		match gesture:
			"book": skip.present_book_close()
			"item": skip.present_item(&"move", &"pogo")
			"attention": skip.present_attention(skip.global_position + Vector2(-50, 0))
			"idle": skip._idle_time = Gesture.IDLE_DELAY + 7.0
			"level": skip.present_level_up()
			"dust": skip._kick_dust(skip.global_position + Vector2(0, 25), Vector2(40, -10), 1.0)
		for step in 40:
			skip._process(0.035)
		_check(_clocks(skip) == clocks and collider.transform == Transform2D.IDENTITY and (collider.shape as RectangleShape2D).size == shape_size,
			"playing the %s moment leaves body, collider, input and combat clocks untouched" % gesture)
	skip.set_process(true)
	skip.set_physics_process(true)
	# A listening post and a resident speak to Skip.
	await _stop(skip)
	skip.reset_animation()
	skip.facing = 1.0
	var post: Node2D = PostScript.new()
	var lines: Array[String] = ["One.", "Two."]
	post.lines = lines
	post.position = skip.position + Vector2(-90, 0)
	root.add_child(post)
	await _physics(2)
	_check(post.try_listen() and skip._attention_face == -1.0 and float(skip._animation_pose().nod) > 0.9,
		"a listening post's line turns Skip toward it with a nod")
	await create_timer(0.2).timeout
	_check(post.try_listen() and float(skip._animation_pose().nod) > 0.9 and skip.facing == 1.0, "each further line nods again")
	post.queue_free()
	skip.reset_animation()
	var resident: Node2D = ResidentScript.new()
	resident.kind = &"tick"
	resident.position = skip.position + Vector2(100, 0)
	root.add_child(resident)
	await _physics(2)
	_check(resident.try_listen() and skip._attention_face == 1.0, "Tick's words turn Skip toward him")
	resident.queue_free()
	skip.queue_free()
	floor.queue_free()
	for action in ACTIONS:
		Input.action_release(action)
	await _frames(3)

## What a standing Skip keeps while his moments play. Combat clocks that run
## down on their own are compared separately, with physics held still.
func _body(skip: CharacterBody2D) -> Dictionary:
	return {"transform": skip.transform, "velocity": skip.velocity, "facing": skip.facing,
		"buffer": skip._strike_buffer, "stagger": skip._stagger, "combo": skip.combo_step, "scale": skip.scale}

func _clocks(skip: CharacterBody2D) -> Dictionary:
	return {"transform": skip.transform, "velocity": skip.velocity, "facing": skip.facing,
		"strike": skip._strike_cd, "buffer": skip._strike_buffer, "recover": skip._recover,
		"stagger": skip._stagger, "combo": skip.combo_step, "window": skip.combo_remaining,
		"noise": skip.noise, "stamp": skip.last_strike_ms, "air": skip.air_strikes_left,
		"hooded": skip.hooded, "setting": skip.setting, "coyote": skip._coyote, "jump": skip._buffer}

func _stop(skip: CharacterBody2D) -> void:
	for action in ACTIONS:
		Input.action_release(action)
	for frame in 90:
		await physics_frame
		if skip.is_on_floor() and skip.velocity.length() < 0.5: break
	await _physics(2)

# -- in the game ------------------------------------------------------------------------

func _check_main() -> void:
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._new_game(false)
	await _physics(4)
	await _check_pickups()
	_main.abilities.restore_snapshot(AbilitiesScript.legacy_snapshot())
	_main._apply_purchases()
	_main._load_world_room(&"horn_plaza")
	await _physics(6)
	await _check_hud()
	await _check_book()
	await _check_map()
	await _check_wipe()

func _check_pickups() -> void:
	var player: CharacterBody2D = _main.player
	_main._load_world_room(&"horn_plaza", &"from_headshell")
	await _physics(4)
	var source: Node2D = null
	for child in _main.room.get_children():
		if child.is_in_group("ability_pickup") and child.ability == &"strike": source = child
	_check(source != null, "Horn Plaza keeps the missing needle")
	if source == null: return
	player.position = source.position
	player.velocity = Vector2.ZERO
	await _physics(4)
	player.reset_animation()
	_check(DirAccess.make_dir_absolute(_main.save_path + ".tmp") == OK, "block the private checkpoint")
	_main._on_ability_requested(&"strike", source)
	_check(not _main.abilities.has_ability(&"strike") and is_zero_approx(float(player._animation_pose().item)),
		"an unsaved find is never raised")
	_check(DirAccess.remove_absolute(_main.save_path + ".tmp") == OK, "unblock the private checkpoint")
	_main._on_ability_requested(&"strike", source)
	var pose: Dictionary = player._animation_pose()
	_check(_main.abilities.has_ability(&"strike") and pose.item_kind == &"move" and pose.item_detail == &"strike" and float(pose.item) > 0.9,
		"a saved move is raised overhead")
	player.reset_animation()
	_main._load_world_room(&"headshell")
	await _physics(3)
	_main._on_map_collected()
	_check(_main.map_state.owned and player._animation_pose().item_kind == &"map", "the folded map is raised when found")
	player.reset_animation()
	_main._on_map_collected()
	_check(is_zero_approx(float(player._animation_pose().item)), "an owned map raises nothing again")
	_main.progression.unlock_refrain(ProgressionScript.Refrain.GATHER)
	_check(player._animation_pose().item_kind == &"refrain", "a remembered Refrain is raised")
	player.reset_animation()
	_main._present_level_up(2)
	_check(float(player._animation_pose().glow) > 0.9, "a new level rings out around Skip")
	player.reset_animation()

func _check_hud() -> void:
	var hud: Control = _main.cinematic_hud
	var marks: Dictionary = hud.marks_snapshot()
	_check(_all_settled(marks.cracks) and _all_settled(marks.inks), "a fresh session shows its diamonds as they are")
	var model := _models()
	_main._on_player_hit()
	await process_frame
	marks = hud.marks_snapshot()
	_check(float(marks.cracks[2]) >= 0.0 and float(marks.cracks[2]) < 1.0, "a lost diamond cracks")
	_main._pause_game()
	await _frames(2)
	var frozen: Dictionary = hud.marks_snapshot()
	await create_timer(0.3, true).timeout
	_check(hud.marks_snapshot() == frozen, "pause freezes the HUD's reactions")
	_main._resume_game()
	await create_timer(0.7).timeout
	_check(_all_settled(hud.marks_snapshot().cracks), "the crack falls away on its own")
	_main._respawn()
	await _frames(2)
	marks = hud.marks_snapshot()
	_check(float(marks.inks[2]) >= 0.0 and float(marks.inks[2]) < 1.0 and _all_settled([marks.inks[0], marks.inks[1]]),
		"restored health re-inks only the diamond that was lost")
	await create_timer(0.6).timeout
	_check(_all_settled(hud.marks_snapshot().inks), "re-inking settles")
	_check(_models() == model, "HUD reactions change no wallet, progress or outcome")
	# The XP hairline eases; a level runs it to the end first.
	var experience: RefCounted = _main.experience
	experience.reset()
	_main._update_cinematic_presentation()
	hud.settle_marks()
	await _frames(3)
	_main._award_xp(20, null)
	_main._update_cinematic_presentation()
	await process_frame
	var target := float(hud._state.xp.ratio)
	_check(float(hud.marks_snapshot().xp) < target, "the hairline eases toward a gain instead of jumping")
	await create_timer(0.8).timeout
	_check(is_equal_approx(float(hud.marks_snapshot().xp), float(hud._state.xp.ratio)), "and arrives")
	_main._award_xp(30, null)
	await process_frame
	marks = hud.marks_snapshot()
	_check(int(marks.xp_level) == 1 and experience.level() == 2, "a new level first finishes the old line")
	_check(float(marks.burst) >= 0.0, "a new level rings out on the HUD")
	await create_timer(0.8).timeout
	marks = hud.marks_snapshot()
	_check(int(marks.xp_level) == 2 and float(marks.flash) < 1.0, "then starts the next line")
	_main._settings.reduced_motion = true
	_main._apply_settings()
	_main._on_player_hit()
	await process_frame
	_check(_all_settled(hud.marks_snapshot().cracks) and is_equal_approx(float(hud.marks_snapshot().xp), float(hud._state.xp.ratio)),
		"Reduced motion settles diamonds and the hairline")
	_main._settings.reduced_motion = false
	_main._apply_settings()
	_main._respawn()
	await _physics(2)

func _check_book() -> void:
	var book: CanvasLayer = _main.inventory
	var paper: Node = book.paper()
	var player: CharacterBody2D = _main.player
	var model := _models()
	book.open_inventory()
	_check(book.is_open() and paused and book.overlay.visible and _focus_inside(book.overlay), "the Book opens, pauses and focuses at once")
	_check(paper.is_covering() and paper.cover.visible and paper.cover.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"its board swings off a live page and takes no input")
	_check(book.overlay.get_child(book.overlay.get_child_count() - 1) == paper.cover, "the board draws above the page")
	await create_timer(BookMotion.COVER_TIME + 0.1, true).timeout
	_check(not paper.is_covering() and not paper.cover.visible, "the board finishes on its own")
	book.select_page("equipment", true, 1)
	_check(book.current_page() == "equipment" and paper.is_turning() and _focus_inside(book.overlay), "a tab turns the page while the new one is already live")
	await _tap(KEY_TAB)
	_check(book.current_page() == "bestiary" and paper.is_turning(), "Tab turns the next page")
	await create_timer(BookMotion.TURN_TIME + 0.1, true).timeout
	_check(not paper.is_turning() and not paper.turn.visible, "a turn finishes on its own")
	book.select_page("bestiary")
	_check(not paper.is_turning(), "staying on a page turns nothing")
	book.select_page("journey")
	player.reset_animation()
	await _tap(KEY_ESCAPE)
	await process_frame
	_check(not book.is_open() and not paused and not book.overlay.visible, "Escape still closes the Book at once")
	_check(paper.is_folding() and paper.fold.visible and paper.fold.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"the closed Book folds shut into Skip's hands over live play")
	_check(float(player._animation_pose().book) > 0.0, "and Skip tucks it into his coat")
	await create_timer(BookMotion.FOLD_TIME + 0.1, true).timeout
	_check(not paper.is_folding() and not paper.fold.visible, "the fold finishes on its own")
	# Reopening ends a fold; handing over to the map tucks nothing away.
	book.open_inventory()
	book.close_inventory()
	await process_frame
	book.open_inventory()
	_check(not paper.is_folding(), "reopening the Book ends an unfinished fold")
	player.reset_animation()
	_main.map_state.collect()
	_main._open_map_from_book()
	await process_frame
	_check(_main.map_menu.is_open and not paper.is_folding() and is_zero_approx(float(player._animation_pose().book)),
		"handing over to the map keeps the Book out of Skip's hands")
	_main._close_map()
	await _physics(3)
	# Reduced motion keeps the Book still.
	_main._settings.reduced_motion = true
	_main._apply_settings()
	book.open_inventory()
	_check(not paper.is_covering(), "Reduced motion opens the Book without its board")
	book.select_page("level")
	_check(not paper.is_turning() and book.current_page() == "level", "and changes pages without a turn")
	book.close_inventory()
	await process_frame
	_check(not paper.is_folding(), "and closes it without a fold")
	_main._settings.reduced_motion = false
	_main._apply_settings()
	book.open_inventory()
	_main._settings.reduced_motion = true
	_main._apply_settings()
	_check(paper.active_count() == 0 and not paper.cover.visible, "turning Reduced motion on settles an open board at once")
	book.close_inventory()
	_main._settings.reduced_motion = false
	_main._apply_settings()
	await _physics(3)
	_check(_models() == model, "the Book's paper changes no wallet, progress or outcome")
	player.reset_animation()

func _check_map() -> void:
	var menu: CanvasLayer = _main.map_menu
	var chart: Control = menu._chart
	_main._show_map()
	await process_frame
	_check(menu.is_open and paused and menu.close_button().has_focus(), "the map opens, pauses and focuses at once")
	_check(chart.is_unfolding() and chart.unfold < 1.0, "the guide begins folded")
	var panels := 0
	for child in chart.get_children():
		if child is Control and child.visible:
			panels += 1
			_check(child.mouse_filter == Control.MOUSE_FILTER_IGNORE and child.clip_contents, "a folding panel takes no input and keeps to its third")
	_check(panels >= 1, "folded panels draw while it opens")
	await create_timer(chart.UNFOLD_TIME + 0.15, true).timeout
	_check(not chart.is_unfolding(), "the guide opens flat on its own")
	for child in chart.get_children():
		_check(not (child as Control).visible, "an open guide draws as one sheet")
	_main._close_map()
	await _physics(3)
	_main._show_map()
	await process_frame
	_main._close_map()
	_check(not chart.is_unfolding(), "closing mid-unfold settles the guide")
	await _physics(3)
	_main._settings.reduced_motion = true
	_main._apply_settings()
	_main._show_map()
	_check(not chart.is_unfolding(), "Reduced motion opens the guide flat")
	_main._close_map()
	_main._settings.reduced_motion = false
	_main._apply_settings()
	await _physics(3)

func _check_wipe() -> void:
	var wipe: CanvasLayer = _main.screen_wipe
	_check(wipe.layer < _main.inventory.layer and wipe.layer < _main.game_menu.layer, "the wipe sits beneath every menu")
	_check(wipe._art.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the wipe takes no input")
	_main._load_world_room(&"horn_plaza", &"from_headshell")
	await _physics(4)
	var model := _models()
	_main._on_route_requested(&"headshell", &"from_horn_plaza")
	_check(wipe.is_active() and _main._transition_pending, "a passage starts the wipe")
	await process_frame
	_check(_main.world_room_id == &"headshell" and not _main._transition_pending, "the next room loads as soon as before")
	_check(wipe.is_active() and wipe.progress() < 1.0, "the old room is still being brushed away over the live one")
	var arrival: float = _main.player.get_global_transform_with_canvas().origin.x
	_check(wipe.direction() == (1.0 if arrival <= wipe._art.size.x * 0.5 else -1.0), "the stroke uncovers Skip's side first")
	await create_timer(wipe.WIPE_TIME + 0.15).timeout
	_check(not wipe.is_active() and not wipe._art.visible, "the wipe finishes on its own")
	_main._on_route_requested(&"horn_plaza", &"from_headshell")
	await process_frame
	_main._pause_game()
	_check(paused and not wipe.is_active(), "pausing ends the wipe rather than freezing an old room")
	_main._resume_game()
	await _physics(3)
	_main._settings.reduced_motion = true
	_main._apply_settings()
	_main._on_route_requested(&"headshell", &"from_horn_plaza")
	await process_frame
	_check(wipe.is_active() and bool(wipe.pose().reduced), "Reduced motion dissolves instead of sweeping")
	await create_timer(wipe.DISSOLVE_TIME + 0.15).timeout
	_check(not wipe.is_active(), "and the dissolve is brief")
	_main._settings.reduced_motion = false
	_main._apply_settings()
	_check(_models() == model, "passages keep their outcomes")

# -- helpers --------------------------------------------------------------------------

func _models() -> Dictionary:
	return {"wallet": _main.economy.snapshot(), "progression": _main.progression.snapshot(),
		"encounters": _main.encounters.duplicate(true), "xp": _main.experience.snapshot()}

func _all_settled(values: Array) -> bool:
	for value in values:
		if float(value) >= 0.0: return false
	return true

func _focus_inside(control: Control) -> bool:
	var focused := root.gui_get_focus_owner()
	return focused != null and control.is_ancestor_of(focused) and focused.is_visible_in_tree()

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _tap(code: Key) -> void:
	_key(code, true)
	await _frames(1)
	_key(code, false)
	await _frames(1)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
