extends SceneTree
## The art-direction test (scripts/ink_test.gd) is presentation only. Off by
## default, it draws Horn Plaza in the canon's ink and changes nothing else:
## the same collision, passages and fixtures, the same movement for the same
## input, every Quiet Wax layer restored when it is turned off, and no other
## room touched. Its scenery never uses crackle pink (heard sound) or etch
## gold (her); Skip's crack chips go pink only while he is loud. A logger
## fails the run on any script error.

const MainScene := preload("res://scenes/main.tscn")
const SaveScript := preload("res://scripts/save_store.gd")
const AbilitiesScript := preload("res://scripts/abilities_state.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
const InkTest := preload("res://scripts/ink_test.gd")
const Plaza := preload("res://scripts/press_ink_plaza.gd")
const Press := preload("res://scripts/press.gd")
const Point := preload("res://scripts/press_ink_point.gd")
const Combat := preload("res://scripts/press_skip_combat.gd")
const Figures := preload("res://scripts/press_ink_figures.gd")
const Hood := preload("res://scripts/press_ink_hood.gd")
const Ink := preload("res://scripts/press_ink.gd")
const Catalog := preload("res://scripts/collection_catalog.gd")
const Light := preload("res://scripts/press_ink_light.gd")

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
	_directory = "user://deadwax-ink-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create private ink fixture")
	_check(not InkTest.enabled and not InkTest.active, "the ink test is off by default")
	_check(InkTest.ROOMS == [&"horn_plaza"], "the ink test covers one room, Horn Plaza")
	await _check_scenery()
	_check_point()
	_check_hood()
	_check_light()
	await _check_figures()
	await _check_main()
	InkTest.enabled = false
	InkTest.active = false
	InkTest.far_face = false
	if is_instance_valid(_main):
		_main.queue_free()
		await _frames(3)
	paused = false
	_check(SaveScript.new(_directory + "/checkpoint.json").delete_save(), "remove private checkpoint")
	for name in ["settings.cfg", "settings.cfg.tmp"]:
		if FileAccess.file_exists(_directory + "/" + name):
			DirAccess.remove_absolute(_directory + "/" + name)
	_check(DirAccess.remove_absolute(_directory) == OK, "remove private ink fixture")
	await create_timer(0.2).timeout
	OS.remove_logger(_log)
	for error in _log.script_errors:
		_failures.append("script error: " + error)
	if _failures.is_empty():
		print("DEAD WAX INK TEST PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("INK TEST FAIL: " + failure)
	quit(1)

# -- scenery: every plane draws, and none of it is pink or gold --------------------

func _check_scenery() -> void:
	var canvas := Canvas.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)
	Plaza.clear_cache()
	for far_face in [false, true]:
		for plane in [&"paper", &"far", &"set", &"light"]:
			canvas.paint = func(c: Control) -> void: Press.draw_ink_room(c, plane, {"far_face": far_face, "exits": Plaza.EXITS})
			canvas.queue_redraw()
			await process_frame
	_check(canvas.calls >= 8, "both faces of every ink plane draw")
	var triangles := 0
	var lettering := 0
	var pink := 0
	var gold := 0
	for key in Plaza._tapes:
		for entry in Plaza._tapes[key]:
			if entry[0] == &"triangles":
				triangles += entry[3].size() / 3
				_check(entry[3].size() % 3 == 0 and entry[1].size() == entry[2].size(), "an ink run is whole triangles with a colour per point")
				for colour in entry[2]:
					if colour.a > 0.0 and _same_hue(colour, Press.PINK):
						pink += 1
					if colour.a > 0.0 and _same_hue(colour, Press.GOLD):
						gold += 1
			elif entry[0] == &"text":
				lettering += 1
				_check(not RegEx.create_from_string("(?i)\\b(needles?|stylus(es)?|styli)\\b").search(String(entry[5])), "street lettering never says needle or stylus: %s" % entry[5])
	_check(Plaza._tapes.size() == 8, "each plane and face is recorded once (%d)" % Plaza._tapes.size())
	_check(triangles > 50000, "the ink scenery is dense (%d triangles)" % triangles)
	_check(lettering > 20, "the street carries its lettering (%d runs)" % lettering)
	_check(pink == 0, "no scenery is crackle pink: pink means heard (%d points)" % pink)
	_check(gold == 0, "no scenery is etch gold: gold is her (%d points)" % gold)
	# A recorded plane replays without being built again.
	var before := Plaza._tapes.size()
	canvas.paint = func(c: Control) -> void: Press.draw_ink_room(c, &"set", {"far_face": false, "exits": Plaza.EXITS})
	canvas.queue_redraw()
	await process_frame
	_check(Plaza._tapes.size() == before, "a drawn plane is replayed from its tape")
	canvas.queue_free()
	await process_frame

func _same_hue(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.02 and absf(a.g - b.g) < 0.02 and absf(a.b - b.b) < 0.02

# -- figures and fixtures draw in every state ------------------------------------------

func _check_figures() -> void:
	var canvas := Canvas.new()
	canvas.size = Vector2(400, 300)
	root.add_child(canvas)
	InkTest.active = true
	var plans: Array[Callable] = []
	for far_face in [false, true]:
		for face in [1.0, -1.0, 0.2]:
			for extra in [{}, {"run": 1.0, "stride": 1.3}, {"air": 1.0, "vertical": -0.8}, {"hood": 1.0}, {"hood": 0.5},
					{"set": 1.0}, {"noise": 1.0}, {"strike": 0.8, "combo_step": 1}, {"strike": 0.6, "combo_step": 2, "big": true},
					{"strike": 0.9, "combo_step": 3, "strike_contact": &"hit", "contact_pulse": 0.8}, {"parry": 0.7},
					{"hurt": 0.9}, {"land": 0.5, "impact": 0.8}, {"item": 0.5, "item_kind": &"move"}, {"idle": 9.0}]:
				var pose := _skip_pose(extra)
				pose["face"] = face
				plans.append(func(c: Control) -> void:
					InkTest.far_face = far_face
					Press.draw_skip(c, pose, {}))
		for phase in ["patrol", "notice", "approach", "sit", "pet", "startled"]:
			for face in [1.0, -1.0]:
				plans.append(func(c: Control) -> void:
					InkTest.far_face = far_face
					Press.draw_hound(c, {"phase": phase, "time": 0.4, "clock": 3.0, "gait": 2.0, "face": face,
						"speed": 0.6, "sit": 1.0 if phase in ["sit", "pet"] else 0.0, "pet": 0.6, "wag": 0.8}, Color.BLACK, Color.WHITE))
		for state in [{"near": false, "locked": false, "target": &"headshell"}, {"near": true, "locked": false, "target": &"practice_room"},
				{"near": true, "locked": true, "target": &"headshell"}, {"near": true, "locked": false, "target": &"high_street"}]:
			plans.append(func(c: Control) -> void: Press.draw_passage(c, state, Color.BLACK, Color.WHITE))
		for state in [{"done": false, "progress": 0.0, "sparkle": 0.0}, {"done": false, "progress": 0.6, "sparkle": 0.0}, {"done": true, "progress": 1.0, "sparkle": 0.5}]:
			plans.append(func(c: Control) -> void: Press.draw_polish(c, state))
		for state in [{"collected": false, "available": false, "near": false}, {"collected": false, "available": true, "near": true, "clock": 1.0}, {"collected": true}]:
			plans.append(func(c: Control) -> void: Press.draw_lost_pressing(c, state, Color.BLACK, Color.WHITE))
		for state in [{"available": true, "near": true, "clock": 0.5}, {"available": false}, {"owned": true}]:
			plans.append(func(c: Control) -> void: Press.draw_ability_pickup(c, state, Color.BLACK, Color.WHITE))
		plans.append(func(c: Control) -> void: Press.draw_skip_dust(c, [{"at": Vector2(10, 25), "age": 0.4, "size": 1.0}], Color.WHEAT))
		for lamp_side in [1.0, -1.0]:
			var lit := _skip_pose({"hood": 0.0 if lamp_side > 0.0 else 1.0, "run": 0.4})
			plans.append(func(c: Control) -> void:
				InkTest.far_face = far_face
				InkTest.lamps = [{"at": c.get_global_transform() * Vector2(lamp_side * 40.0, -60.0), "reach": 200.0, "warmth": 0.9}]
				Press.draw_skip(c, lit, {})
				Press.draw_hound(c, {"phase": "patrol", "time": 0.4, "clock": 3.0, "face": lamp_side}, Color.BLACK, Color.WHITE)
				InkTest.lamps = [])
		for lining in Hood.LININGS:
			for thread in [false, true]:
				var dressed := _skip_pose({"hood": 1.0 if thread else 0.7, "run": 0.62 if thread else 0.0, "stride": 1.2})
				plans.append(func(c: Control) -> void:
					InkTest.far_face = far_face
					Press.draw_skip(c, dressed, {"lining": lining, "warm_thread": thread}))
		for tip in Point.TIPS:
			for noise in [0.0, 1.0]:
				var fitted := _skip_pose({"noise": noise, "strike": 0.6 if noise > 0.0 else 0.0, "combo_step": 2})
				plans.append(func(c: Control) -> void:
					InkTest.far_face = far_face
					Press.draw_skip(c, fitted, {"tip": tip}))
	for plan in plans:
		canvas.paint = plan
		canvas.queue_redraw()
		await process_frame
	_check(canvas.calls >= plans.size(), "every ink figure and fixture draws (%d plans)" % plans.size())
	InkTest.active = false
	InkTest.far_face = false
	canvas.queue_free()
	await process_frame

# -- the point: always touching something, the tip is the crackle meter ------------

func _check_point() -> void:
	var bodies: Array[Transform2D] = [Transform2D.IDENTITY, Transform2D(0.12, Vector2(1.08, 0.9), 0.0, Vector2(-2, 3)),
		Transform2D(-0.15, Vector2(0.94, 1.05), 0.0, Vector2(3, -2))]
	for body in bodies:
		for side in [1.0, -1.0]:
			for extra in [{}, {"run": 1.0, "stride": 0.7}, {"hood": 1.0}, {"set": 1.0}]:
				var pose := _skip_pose(extra)
				pose["face"] = side
				var point := Point.solve(pose, Combat.sample(pose), body, side)
				_check(absf(Vector2(point.tip).y - Point.GROUND) < 1.0,
					"at rest the point touches the street (%s, facing %d): tip at %s" % [extra, side, point.tip])
	var neutral := _skip_pose({})
	var resting := Point.solve(neutral, Combat.sample(neutral), Transform2D.IDENTITY, 1.0)
	_check(absf(Vector2(resting.tip).distance_to(resting.butt) - (Point.FRONT + Point.BACK)) < 0.5, "the point keeps its length")
	_check(Vector2(resting.tip).x > Vector2(resting.grip).x, "standing, the point is planted ahead")
	var running := _skip_pose({"run": 1.0})
	var dragged := Point.solve(running, Combat.sample(running), Transform2D.IDENTITY, 1.0)
	_check(Vector2(dragged.tip).x < Vector2(dragged.grip).x, "running, the point drags behind")
	# The sticking: a thrust, an up-stroke over his head, a slam into the street.
	var tap := _skip_pose({"strike": 1.0, "combo_step": 1})
	var thrust := Point.solve(tap, Combat.sample(tap), Transform2D.IDENTITY, 1.0)
	_check(Vector2(thrust.tip).x > Vector2(resting.tip).x and Vector2(thrust.tip).y < 0.0, "the Tap thrusts the point straight ahead")
	var held := _skip_pose({"strike": 1.0 - Point.HOLD + 0.05, "combo_step": 1})
	_check(is_equal_approx(float(Point.solve(held, Combat.sample(held), Transform2D.IDENTITY, 1.0).held), 1.0), "a stroke holds its pose before it settles")
	var lifted := _skip_pose({"strike": 1.0 - Point.TRAVEL, "combo_step": 2})
	var sweep := Point.solve(lifted, Combat.sample(lifted), Transform2D.IDENTITY, 1.0)
	_check(Vector2(sweep.tip).y < -41.0, "the Sweep lifts the point over his head (tip at %s)" % sweep.tip)
	_check(float(sweep.arc_from) > float(sweep.arc_to), "the Sweep's smear rises from the street")
	var slam := _skip_pose({"strike": 1.0, "combo_step": 3, "big": true})
	var accent := Point.solve(slam, Combat.sample(slam), Figures.skip_body(slam), 1.0)
	_check(Vector2(accent.tip).y > Point.GROUND and Vector2(accent.tip).y <= Point.GROUND + Point.BITE + 0.01 and float(accent.two_hands) > 0.9,
		"the Accent drives the point into the street with both hands (tip at %s)" % accent.tip)
	_check(float(accent.arc_from) < -90.0 and float(accent.arc_to) > 0.0, "the Accent's smear comes over the top")
	var left := tap.duplicate()
	left["strike_face"] = -1.0
	_check(Vector2(Point.solve(left, Combat.sample(left), Transform2D.IDENTITY, 1.0).tip).x < 0.0, "a stroke to the left points left")
	# Whatever the stroke, lean or moment, only the Accent's bite goes into the street.
	var sunk := 0
	var samples := 0
	for side in [1.0, -1.0]:
		for step in [1, 2, 3]:
			for contact in [&"miss", &"guard", &"hit"]:
				for i in 21:
					var moment := _skip_pose({"strike": i / 20.0, "combo_step": step, "strike_contact": contact,
						"contact_pulse": 0.6, "strike_face": side, "run": 1.0 if i % 4 == 0 else 0.0, "big": step == 3})
					moment["face"] = side
					for body in [Figures.skip_body(moment)] + bodies:
						var solved := Point.solve(moment, Combat.sample(moment), body, side)
						samples += 1
						if Vector2(solved.tip).y > Point.GROUND + Point.BITE + 0.01:
							sunk += 1
	_check(sunk == 0, "the point never goes through the street (%d of %d moments)" % [sunk, samples])
	var quiet := Color("8a8070")
	_check(Point.loudness({"noise": 0.0}) == 0.0 and Point.tip_paint(quiet, Press.PINK, 0.0) == quiet, "a quiet tip is grey")
	_check(Point.tip_paint(quiet, Press.PINK, Point.loudness({"noise": 1.0})).is_equal_approx(Press.PINK), "a loud tip is crackle pink")
	_check(Point.loudness({"noise": 1.0, "hood": 1.0}) == 0.0, "the hood drains the tip grey")
	_check(&"" in Point.TIPS and _slot_ids("needle") == _sorted_ids(Point.TIPS), "every fitted Tip has a drawing, and so does the bare point")

# -- the light: dawn-grey, the night's last lamps ---------------------------------------

func _check_light() -> void:
	var rig := Plaza.light_rig()
	var lamps: Array = rig.lamps
	var lanterns := 0
	for lamp: Dictionary in lamps:
		if lamp.kind == &"lantern" and Vector2(lamp.at).distance_to(Vector2(589, 494)) < 1.0:
			lanterns += 1
	_check(lanterns == 1, "the lantern's light hangs where the set draws its glass")
	# Every lit bulb is a drawn bulb, and the dead grey ones give no light.
	var drawn: Array = []
	for bulb in Plaza.bulbs():
		if int(bulb.turn) != Plaza.BULB_DEAD:
			drawn.append(Vector2(bulb.glass))
	var lit: Array = []
	for lamp: Dictionary in lamps:
		if lamp.kind == &"bulb":
			lit.append(Vector2(lamp.at))
	_check(not lit.is_empty() and lit == drawn, "every lit bulb is a drawn bulb, and the dead ones stay dark (%d lit)" % lit.size())
	_check(int(rig.failing) >= 0 and lamps[int(rig.failing)].kind == &"bulb", "one bulb on the long run is dying")
	# Lamps knock the dawn back; the street is lighter than under it; the open
	# sky over the square is paler than over the roofs.
	var dark_at_lantern := Light.darkness(rig, Vector2(589, 494))
	var dark_in_corner := Light.darkness(rig, Vector2(40, 494))
	_check(dark_at_lantern < dark_in_corner * 0.5, "the lantern knocks the dawn back (%.2f against %.2f)" % [dark_at_lantern, dark_in_corner])
	var unlit := rig.duplicate()
	unlit["lamps"] = []
	_check(Light.darkness(unlit, Vector2(1000, 760)) > Light.darkness(unlit, Vector2(1000, 560)), "under the street is darker than the street")
	_check(Light.darkness(unlit, Vector2(790, 400)) < Light.darkness(unlit, Vector2(40, 400)) * 0.7, "the open sky over the square is paler than over the roofs")
	# Hood up is silence, and so is the dawn: nothing in the light is pink or gold.
	var loud := 0
	for far_face in [false, true]:
		var k := Ink.new(null, 1, true)
		Light.draw_live(k, rig, far_face, 3.7)
		Light.figure_shadows(k, rig, Color.BLACK, Vector2(560, 600), 600.0, 17.0, 0.0)
		Light.rim(k, PackedVector2Array([Vector2(570, 540), Vector2(600, 540), Vector2(600, 590), Vector2(570, 590)]), lamps, Color("fff0c8"))
		k.flush()
		for entry in k.tape:
			if entry[0] == &"triangles":
				for colour in entry[2]:
					if colour.a > 0.0 and (_same_hue(colour, Press.PINK) or _same_hue(colour, Press.GOLD)):
						loud += 1
	_check(loud == 0, "the lamps, the dust and the shadows are never pink or gold (%d points)" % loud)

# -- the hood: a 45 sleeve over him, silent, his face its centre hole ---------------

func _check_hood() -> void:
	var moments := [{}, {"run": 0.62, "stride": 0.5}, {"run": 0.62, "stride": 2.1}, {"run": 0.62, "stride": 4.0},
		{"air": 1.0, "vertical": -0.8}, {"air": 1.0, "vertical": 0.8}, {"land": 0.5, "impact": 0.9}, {"noise": 1.0, "time": 2.6}]
	var uncovered := 0
	var faceless := 0
	var sunk := 0
	for side in [1.0, -1.0]:
		for extra in moments:
			var pose := _skip_pose(extra)
			pose["face"] = side
			pose["hood"] = 1.0
			var body := Figures.skip_body(pose)
			var sleeve := Hood.shape(pose, body, side)
			var outline: PackedVector2Array = sleeve.outline
			# The head, drawn as narrow as the sleeve folds it, stays inside.
			for vertex in Figures.HEAD:
				var at: Vector2 = body * (Vector2(vertex) * Vector2(side * float(sleeve.squeeze), 1.0))
				if not Geometry2D.is_point_in_polygon(at, outline) and _distance_to_outline(at, outline) > 1.5:
					uncovered += 1
			var face: Vector2 = sleeve.face
			if not Geometry2D.is_point_in_polygon(face, outline) or _distance_to_outline(face, outline) < float(sleeve.radius) - 1.0:
				faceless += 1
			for point in outline:
				if point.y > Point.GROUND + 0.01:
					sunk += 1
	_check(uncovered == 0, "hood up, his head is inside the sleeve (%d corners out)" % uncovered)
	_check(faceless == 0, "hood up, the face hole sits whole in the sleeve (%d moments not)" % faceless)
	_check(sunk == 0, "the sleeve's hem never goes through the street (%d points)" % sunk)
	# Going up and coming down, every moment of the sleeve is a whole shape.
	var broken := 0
	for side in [1.0, -1.0]:
		for extra in [{}, {"run": 0.62, "stride": 1.4}, {"air": 1.0, "vertical": 0.6}]:
			for i in range(1, 21):
				var pose := _skip_pose(extra)
				pose["face"] = side
				pose["hood"] = i / 20.0
				var sleeve := Hood.shape(pose, Figures.skip_body(pose), side)
				if Geometry2D.triangulate_polygon(sleeve.outline).is_empty():
					broken += 1
	_check(broken == 0, "the sleeve is a whole shape all the way up and down (%d moments not)" % broken)
	var halfway := _skip_pose({"hood": 0.4})
	var rising := Hood.shape(halfway, Figures.skip_body(halfway), 1.0)
	_check(float(rising.cover) < 0.1 and Vector2(rising.crown).y < -30.0 and float(rising.open) == 0.0,
		"it goes up from behind: over his head before it comes down his front")
	# Hood up is silence: nothing on the sleeve is pink or gold, whatever he wears.
	var loud := 0
	for far_face in [false, true]:
		InkTest.far_face = far_face
		for lining in Hood.LININGS:
			for thread in [false, true]:
				var pose := _skip_pose({"hood": 1.0, "noise": 1.0})
				var k := Ink.new(null, 1, true)
				Hood.draw(k, Hood.shape(pose, Figures.skip_body(pose), 1.0), pose, Figures.colours(), 0, {"lining": lining, "warm_thread": thread})
				k.flush()
				for entry in k.tape:
					if entry[0] == &"triangles":
						for colour in entry[2]:
							if colour.a > 0.0 and (_same_hue(colour, Press.PINK) or _same_hue(colour, Press.GOLD)):
								loud += 1
	InkTest.far_face = false
	_check(loud == 0, "hood up is silence: no pink or gold on the sleeve (%d points)" % loud)
	_check(&"" in Hood.LININGS and _slot_ids("lining") == _sorted_ids(Hood.LININGS), "every fitted Sleeve has a drawing, and so does the bare sleeve")

func _distance_to_outline(at: Vector2, outline: PackedVector2Array) -> float:
	var nearest := INF
	for i in outline.size():
		var closest := Geometry2D.get_closest_point_to_segment(at, outline[i], outline[(i + 1) % outline.size()])
		nearest = minf(nearest, at.distance_to(closest))
	return nearest

func _slot_ids(slot: String) -> Array:
	var ids: Array = []
	for item in Catalog.items():
		if String(item.get("slot", "")) == slot:
			ids.append(String(item.id))
	ids.sort()
	return ids

func _sorted_ids(names: Array) -> Array:
	var ids: Array = []
	for name in names:
		if not String(name).is_empty():
			ids.append(String(name))
	ids.sort()
	return ids

func _skip_pose(extra: Dictionary) -> Dictionary:
	var pose := {"time": 1.0, "stride": 0.0, "run": 0.0, "air": 0.0, "vertical": 0.0, "hood": 0.0, "set": 0.0,
		"face": 1.0, "land": 0.0, "impact": 0.0, "launch": 0.0, "strike": 0.0, "big": false, "combo_step": 1,
		"strike_face": 1.0, "strike_contact": &"miss", "strike_hold": 0.0, "contact_pulse": 0.0, "parry": 0.0,
		"parry_face": 1.0, "queued": 0.0, "strike_launched": false, "strike_pogo": false, "hurt": 0.0,
		"hit_direction": -1.0, "noise": 0.0, "flat": 0.0}
	pose.merge(extra, true)
	return pose

# -- the room: same world, either look ---------------------------------------------------

func _check_main() -> void:
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._new_game(false)
	await _physics(4)
	_main.abilities.restore_snapshot(AbilitiesScript.legacy_snapshot())
	_main._apply_purchases()
	_main._load_world_room(&"horn_plaza")
	await _physics(6)
	var room: Node2D = _main.room
	var wax_bodies := _bodies(room)
	var wax_nodes := _node_counts(room)
	var wax_clear := RenderingServer.get_default_clear_color()
	_check(room.get("ink_plate") == null and not InkTest.active, "Horn Plaza opens in Quiet Wax")
	var wax_walk := await _walk(room)
	_check(wax_walk[-1].x - 560.0 > 60.0, "the walk fixture really moves Skip (%s)" % wax_walk[-1])

	# On: the plate replaces the Quiet Wax layers, and nothing else changes.
	InkTest.enabled = true
	_main._apply_ink_test()
	await _physics(3)
	var plate: Node = room.get("ink_plate")
	_check(InkTest.active and is_instance_valid(plate), "F9's switch draws Horn Plaza in ink")
	_check(is_instance_valid(plate) and plate.get_parent() == room and plate.get_child_count() == 6, "the ink plate holds its paper, far, set, light, live light and contact planes")
	_check(InkTest.lamps.size() == Plaza.light_rig().lamps.size(), "the plaza's lamps are there for the figures walking past them")
	# The live light holds still under Reduced motion and moves without it.
	var live: Node = plate.get_node("Live")
	plate.call("set_reduced_motion", true)
	var held := float(live.get("time"))
	await _frames(4)
	_check(is_equal_approx(float(live.get("time")), held), "under Reduced motion the lamps and the dust hold still")
	plate.call("set_reduced_motion", false)
	await _frames(4)
	_check(float(live.get("time")) > held, "without it the lantern breathes")
	_check(not room.atmosphere.visible and not room.lighting.visible, "Quiet Wax air, depth and lamps step aside")
	var hidden_skins := true
	for skin in room._skins:
		hidden_skins = hidden_skins and not skin.visible
	_check(hidden_skins, "Quiet Wax plates step aside")
	var hidden_scenery := true
	for child in room.get_children():
		if child.has_meta("impression_kind"):
			hidden_scenery = hidden_scenery and not child.visible
	_check(hidden_scenery, "Quiet Wax impressions step aside")
	_check(_bodies(room) == wax_bodies, "collision is identical in ink")
	_check(_nodes_of(plate, "CollisionObject2D") == 0 and _nodes_of(plate, "CollisionShape2D") == 0, "the ink plate adds no collision")
	var ink_nodes := _node_counts(room)
	ink_nodes.erase("InkPlate")
	_check(ink_nodes == wax_nodes, "the room's own nodes are unchanged in ink")
	_check(RenderingServer.get_default_clear_color().is_equal_approx(InkTest.LABEL_PAPER), "the page is label paper in ink")
	var ink_walk := await _walk(room)
	_check(ink_walk == wax_walk, "the same input moves Skip the same way in either look")

	# The far face reprints the same drawing in scratchboard.
	_main.progression.unlock_refrain(ProgressionScript.Refrain.JUMP_CUT)
	_check(bool(_main.pressing.flip()), "the pressing turns over in the ink test")
	await _physics(2)
	_check(InkTest.far_face and bool(plate.get("far_face")), "the far face is drawn reversed out of wax")
	_check(RenderingServer.get_default_clear_color().is_equal_approx(InkTest.WAX), "the far face's page is wax")
	_main.pressing.call("flip")
	await _physics(2)
	_check(not InkTest.far_face and not bool(plate.get("far_face")), "the near face is paper again")

	# Off: every Quiet Wax layer comes back exactly as it was.
	InkTest.enabled = false
	_main._apply_ink_test()
	await _physics(3)
	_check(not InkTest.active and room.get("ink_plate") == null and not is_instance_valid(plate), "turning the test off removes the ink plate")
	_check(InkTest.lamps.is_empty(), "and takes its lamps away")
	_check(room.atmosphere.visible and room.lighting.visible, "Quiet Wax air, depth and lamps return")
	var shown := true
	for skin in room._skins:
		shown = shown and skin.visible
	for child in room.get_children():
		if child.has_meta("impression_kind"):
			shown = shown and child.visible
	_check(shown, "Quiet Wax plates and impressions return")
	_check(_node_counts(room) == wax_nodes and _bodies(room) == wax_bodies, "the room is as it was before the test")
	_check(RenderingServer.get_default_clear_color().is_equal_approx(wax_clear), "the room's own page colour returns")

	# Other rooms are never drawn in ink, and coming back draws the plaza again.
	InkTest.enabled = true
	_main._apply_ink_test()
	_main._load_world_room(&"headshell", &"from_horn_plaza")
	await _physics(4)
	_check(not InkTest.active and _main.room.get("ink_plate") == null and _main.room.atmosphere.visible, "the Headshell stays Quiet Wax with the test on")
	_main._load_world_room(&"horn_plaza", &"from_headshell")
	await _physics(4)
	_check(InkTest.active and is_instance_valid(_main.room.get("ink_plate")), "returning to Horn Plaza draws it in ink again")
	_main._load_world_room(&"high_street", &"from_horn_plaza")
	await _physics(4)
	_check(not InkTest.active and _main.room.get("ink_plate") == null, "the High Street stays Quiet Wax")
	InkTest.enabled = false
	_main._apply_ink_test()

## Holds right for a moment from a fixed start and returns Skip's path.
func _walk(room: Node2D) -> Array[Vector2]:
	var player: CharacterBody2D = _main.player
	player.global_position = Vector2(560, 574)
	player.velocity = Vector2.ZERO
	await _physics(4)
	var path: Array[Vector2] = []
	Input.action_press("move_right")
	for frame in 30:
		await physics_frame
		path.append(player.global_position.round())
	Input.action_release("move_right")
	for frame in 20:
		await physics_frame
		path.append(player.global_position.round())
	return path

func _bodies(room: Node) -> Array:
	var result: Array = []
	for node in _all(room):
		if node is CollisionShape2D and node.shape is RectangleShape2D:
			result.append([String(room.get_path_to(node)), (node as CollisionShape2D).global_position.round(), (node.shape as RectangleShape2D).size, node.disabled])
	return result

func _node_counts(room: Node) -> Dictionary:
	var counts := {}
	for child in room.get_children():
		var key := String(child.name) if child.name == &"InkPlate" else child.get_class()
		counts[key] = int(counts.get(key, 0)) + 1
	return counts

func _nodes_of(root_node: Node, type: String) -> int:
	if root_node == null:
		return 0
	var count := 0
	for node in _all(root_node):
		if node.is_class(type):
			count += 1
	return count

func _all(root_node: Node) -> Array[Node]:
	var result: Array[Node] = [root_node]
	for child in root_node.get_children():
		result.append_array(_all(child))
	return result

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
