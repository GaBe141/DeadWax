extends SceneTree
## Batched scenery marks: press_geometry.gd builds the same triangles the
## engine builds for polylines, ellipses and polygons, and the world brush
## gathers still scenery into few draw calls while keeping recurring marks.
## Headless runs check the geometry and the brush's bookkeeping; with a
## display, the batched and native drawings are also rendered and compared
## pixel for pixel (run it windowed after a Godot upgrade).

const Geometry := preload("res://scripts/press_geometry.gd")
const Brush := preload("res://scripts/press_world_brush.gd")
const MainScene := preload("res://scenes/main.tscn")
const SaveScript := preload("res://scripts/save_store.gd")
const Campaign := preload("res://scripts/campaign.gd")
const RENDER_SIZE := Vector2i(640, 480)

class DrawProbe extends Node2D:
	var paint: Callable
	func _draw() -> void:
		if paint.is_valid():
			paint.call(self)

class MarkPainter extends Node2D:
	var marks: Array = []
	var batched := false
	func _draw() -> void:
		var batch := Geometry.new()
		for mark in marks:
			match String(mark[0]):
				"polyline":
					if batched: batch.add_polyline(mark[1], mark[2], mark[3], mark[4])
					else: draw_polyline(mark[1], mark[2], mark[3], mark[4])
				"circle":
					if batched: batch.add_circle(mark[1], mark[2], mark[3], mark[4])
					else: draw_circle(mark[1], mark[2], mark[3], true, -1, mark[4])
				"polygon":
					if batched: batch.add_polygon(mark[1], mark[2])
					else: draw_colored_polygon(mark[1], mark[2])
				"arc":
					if batched: batch.add_arc(mark[1], mark[2], mark[3], mark[4], mark[5], mark[6], mark[7], mark[8])
					else: draw_arc(mark[1], mark[2], mark[3], mark[4], mark[5], mark[6], mark[7], mark[8])
		if batched:
			batch.flush(self)

var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_polyline_layout()
	_check_polyline_values()
	_check_ellipse_and_polygon()
	_check_compensation()
	await _check_brush_bookkeeping()
	await _check_rooms()
	await _check_render()
	if _failures.is_empty():
		print("DEAD WAX RENDER BATCH PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("RENDER BATCH FAIL: " + failure)
	quit(1)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)

# -- geometry -------------------------------------------------------------------

func _check_polyline_layout() -> void:
	var color := Color(0.8, 0.6, 0.4, 0.9)
	for count: int in [2, 3, 7]:
		var line := PackedVector2Array()
		for i in count:
			line.append(Vector2(i * 20.0, sin(i) * 9.0))
		var batch := Geometry.new()
		batch.add_polyline(line, color, 4.0, true)
		var main := 2 * count + 4
		var side := 2 * count + 5
		_check(batch.points.size() == main + 2 * side, "an open antialiased polyline is the engine's strip and two feathers (%d points)" % count)
		_check(batch.indices.size() == 3 * ((main - 2) + 2 * (side - 2)), "each strip becomes a triangle list (%d points)" % count)
		_check(batch.colors.size() == batch.points.size(), "every vertex carries its colour")
		var plain := Geometry.new()
		plain.add_polyline(line, color, 4.0, false)
		_check(plain.points.size() == 2 * count and plain.indices.size() == 3 * (2 * count - 2), "a plain polyline is one strip (%d points)" % count)
	var loop := PackedVector2Array([Vector2(0, 0), Vector2(30, 0), Vector2(30, 30), Vector2(0, 0)])
	var closed := Geometry.new()
	closed.add_polyline(loop, color, 3.0, true)
	_check(closed.points.size() == 3 * 2 * loop.size(), "a closed antialiased polyline has no end caps")
	var thin := Geometry.new()
	thin.add_polyline(loop, color, -1.0, false)
	_check(thin.is_empty(), "line strips (negative width) stay ordinary draw calls")
	var strip := Geometry.new()
	strip.add_polyline(PackedVector2Array([Vector2.ZERO, Vector2(10, 0), Vector2(20, 0)]), color, 2.0, false)
	_check(Array(strip.indices.slice(0, 6)) == [0, 1, 2, 2, 1, 3], "strip triangles keep OpenGL's vertex order")

func _check_polyline_values() -> void:
	# A level stroke 4 px wide: the engine narrows it to 2.825 px and feathers
	# each edge by 1.25 px, including its caps.
	var color := Color(0.2, 0.4, 0.6, 0.8)
	var batch := Geometry.new()
	batch.add_polyline(PackedVector2Array([Vector2(10, 50), Vector2(110, 50)]), color, 4.0, true)
	var half := Geometry.compensated_width(4.0) * 0.5
	_check(is_equal_approx(half, 1.4125), "a 4 px antialiased stroke is narrowed for its feather")
	# Vector2.orthogonal() of a rightward stroke points up the screen.
	var main := batch.points.slice(0, 8)
	_check(main[2].is_equal_approx(Vector2(10, 50 - half)) and main[3].is_equal_approx(Vector2(10, 50 + half)), "the strip starts on the stroke's edges")
	_check(main[0].is_equal_approx(Vector2(10 - 1.25, 50 - half)), "the begin cap reaches back by the feather")
	_check(main[6].is_equal_approx(Vector2(110 + 1.25, 50 - half)), "the end cap reaches forward by the feather")
	_check(batch.colors[0].a == 0.0 and batch.colors[2] == color, "caps fade out and the body is solid")
	var left := batch.points.slice(8, 15)
	_check(left[3].is_equal_approx(Vector2(10, 50 - half - 1.25)), "the left feather sits outside the edge")
	_check(batch.colors[11].a == 0.0 and batch.colors[11].r == color.r, "the feather fades to the same colour")
	# A sharp turn uses the clamped miter, at most three times the half width.
	var corner := Geometry.new()
	corner.add_polyline(PackedVector2Array([Vector2(0, 0), Vector2(40, 0), Vector2(0, 2)]), color, 6.0, false)
	var miter := (corner.points[2] - Vector2(40, 0)).length()
	_check(miter <= 3.0 * 3.0 + 0.001, "a sharp corner's miter is clamped like the engine's")

func _check_ellipse_and_polygon() -> void:
	var color := Color(0.9, 0.7, 0.3, 1.0)
	var circle := Geometry.new()
	circle.add_circle(Vector2(40, 40), 10.0, color, true)
	_check(circle.points.size() == 66 + 130, "an antialiased circle is a 64-segment fan and its feather")
	_check(circle.indices.size() == 64 * 3 + 128 * 3, "the fan and feather are triangle lists")
	_check(is_equal_approx(circle.points[0].x, 40.0 + 10.0 - 0.3125), "the antialiased radius shrinks by a quarter feather")
	_check(circle.points[65] == Vector2(40, 40), "the fan's centre is its last vertex")
	_check(is_equal_approx(circle.points[67].x, 40.0 + 10.0 - 0.3125 + 1.25), "the feather ring sits 1.25 px outside")
	var plain := Geometry.new()
	plain.add_circle(Vector2.ZERO, 5.0, color, false)
	_check(plain.points.size() == 66 and is_equal_approx(plain.points[0].x, 5.0), "a plain circle keeps its radius")
	var polygon := PackedVector2Array([Vector2(0, 0), Vector2(30, 2), Vector2(26, 25), Vector2(3, 20)])
	var shape := Geometry.new()
	shape.add_polygon(polygon, color)
	_check(Array(shape.indices) == Array(Geometry2D.triangulate_polygon(polygon)), "polygons use the engine's own triangulation")
	var arc := Geometry.new()
	arc.add_arc(Vector2.ZERO, 12.0, 0.0, PI, 10, color, 2.0, true)
	_check(arc.points.size() == (2 * 10 + 4) + 2 * (2 * 10 + 5), "an arc is a polyline of its points")
	var merged := Geometry.new()
	merged.add_polygon(polygon, color)
	merged.add_circle(Vector2.ZERO, 3.0, color, false)
	_check(merged.indices[merged.indices.size() - 1] >= polygon.size(), "later marks index their own vertices")

func _check_compensation() -> void:
	_check(is_equal_approx(Geometry.compensated_width(2.0), 1.0), "thin strokes are halved")
	_check(is_equal_approx(Geometry.compensated_width(5.0), 4.375), "mid strokes blend toward the offset")
	_check(is_equal_approx(Geometry.compensated_width(9.0), 8.375), "wide strokes lose a constant offset")
	_check(is_equal_approx(Geometry.compensated_width(-1.0), -1.0), "line strips are untouched")

# -- the brush ------------------------------------------------------------------

func _draw_with(paint: Callable) -> DrawProbe:
	var probe := DrawProbe.new()
	probe.paint = paint
	root.add_child(probe)
	await process_frame
	await process_frame
	return probe

func _check_brush_bookkeeping() -> void:
	var p := Brush.palette(Color("dbc697"), Color("152e37"))
	var cache_before: int = Brush._cache.size() + Brush._old_cache.size()
	var still := await _draw_with(func(c: CanvasItem) -> void:
		Brush.begin(c)
		Brush.line(c, Vector2(0, 0), Vector2(80, 10), p.edge, 4)
		Brush.wash(c, PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(10, 20)]), p.body)
		Brush.dot(c, Vector2(30, 30), 6, p.gold)
		Brush.flush(c)
		c.draw_rect(Rect2(0, 0, 4, 4), p.copper)
		Brush.curve(c, Vector2(0, 40), Vector2(40, 80), Vector2(80, 40), p.gold, 2)
		Brush.end(c))
	_check(Brush._gathering == 0 and Brush._run.is_empty(), "gathering ends with the drawing")
	var cache_after: int = Brush._cache.size() + Brush._old_cache.size()
	_check(cache_after == cache_before + 2, "each gathered run keeps its triangles (two runs around the rect)")
	still.queue_redraw()
	await process_frame
	await process_frame
	_check(Brush._cache.size() + Brush._old_cache.size() == cache_after, "drawing the same scenery again reuses its runs")
	still.queue_free()
	# Outside a run, a mark is ordinary draw calls once, then kept.
	var moving := DrawProbe.new()
	var unit_key := [[&"polygon", PackedVector2Array([Vector2(1, 1), Vector2(9, 1), Vector2(5, 7)]), p.light]]
	moving.paint = func(c: CanvasItem) -> void:
		Brush.wash(c, PackedVector2Array([Vector2(1, 1), Vector2(9, 1), Vector2(5, 7)]), p.light)
	root.add_child(moving)
	await process_frame
	await process_frame
	_check(Brush._lookup(unit_key).is_empty() and Brush._seen.has(hash(unit_key)), "a mark seen once is drawn as before and remembered")
	moving.queue_redraw()
	await process_frame
	await process_frame
	_check(not Brush._lookup(unit_key).is_empty(), "a mark that comes back keeps its triangles")
	moving.queue_free()
	# Another canvas's flush never sends this canvas's marks.
	var other := DrawProbe.new()
	root.add_child(other)
	var crossed := await _draw_with(func(c: CanvasItem) -> void:
		Brush.begin(c)
		Brush.line(c, Vector2.ZERO, Vector2(10, 0), p.edge, 2)
		Brush.flush(other)
		_check(Brush._run.size() == 2, "a flush for another canvas leaves the run alone")
		Brush.end(c))
	crossed.queue_free()
	other.queue_free()
	# The cache keeps to its budget by retiring a generation.
	var saved_cache := Brush._cache
	var saved_old := Brush._old_cache
	var saved_bytes := Brush._cache_bytes
	Brush._cache = {}
	Brush._old_cache = {}
	Brush._cache_bytes = Brush.CACHE_BUDGET - 10
	var big := [PackedVector2Array([Vector2.ONE]), PackedColorArray([Color.WHITE]), PackedInt32Array([0, 0, 0])]
	Brush._store([&"budget"], big)
	_check(Brush._old_cache.size() == 0 and Brush._cache.has([&"budget"]) and Brush._cache_bytes < 100, "a full generation is retired before storing more")
	Brush._old_cache = {[&"kept"]: big}
	_check(not Brush._lookup([&"kept"]).is_empty() and Brush._cache.has([&"kept"]), "a mark found in the retired generation moves back")
	Brush._cache = saved_cache
	Brush._old_cache = saved_old
	Brush._cache_bytes = saved_bytes
	await process_frame

# -- rooms ----------------------------------------------------------------------

func _check_rooms() -> void:
	var directory := "user://deadwax-render-batch-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(directory) == OK, "create a private render-batch directory")
	var main := MainScene.instantiate()
	main.save_path = directory + "/checkpoint.json"
	main.settings_path = directory + "/settings.cfg"
	root.add_child(main)
	for frame in 3:
		await process_frame
	main._new_game(false)
	for id in Campaign.room_ids():
		main._load_world_room(id)
		for frame in 4:
			await process_frame
		_check(Brush._gathering == 0, "%s leaves no run open after drawing" % id)
		var atmosphere: Node = main.room.get_node_or_null("Atmosphere")
		_check(atmosphere != null, "%s has its scenery" % id)
		if atmosphere != null:
			var moves := bool(atmosphere._pose.get("middle_moves", false))
			_check(moves == (id in atmosphere.AMBIENT_IDS), "%s's middle plane gathers only while still" % id)
	main._load_world_room(&"headshell")
	var atmosphere: Node = main.room.get_node("Atmosphere")
	atmosphere.set_reduced_motion(true)
	_check(not bool(atmosphere._pose.get("middle_moves", true)), "Reduced motion stills the middle plane, so it gathers")
	main.queue_free()
	for frame in 3:
		await process_frame
	_check(SaveScript.new(directory + "/checkpoint.json").delete_save(), "remove the private render-batch checkpoint")
	if FileAccess.file_exists(directory + "/settings.cfg"):
		DirAccess.remove_absolute(directory + "/settings.cfg")
	DirAccess.remove_absolute(directory)

# -- pixels (only with a display) -----------------------------------------------

func _check_render() -> void:
	if DisplayServer.get_name() == "headless":
		print("render batch: headless, so the pixel comparison is skipped (run windowed to compare)")
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	var marks: Array = []
	for i in 180:
		var roll := rng.randf()
		var color := Color(rng.randf(), rng.randf(), rng.randf(), rng.randf_range(0.2, 1.0))
		var at := Vector2(rng.randf_range(30, RENDER_SIZE.x - 30), rng.randf_range(30, RENDER_SIZE.y - 30))
		if roll < 0.5:
			var line := PackedVector2Array([at])
			for p in rng.randi_range(1, 10):
				line.append(line[-1] + Vector2.from_angle(rng.randf_range(-PI, PI)) * rng.randf_range(0.0, 50.0))
			if rng.randf() < 0.15:
				line.append(line[0])
			marks.append(["polyline", line, color, rng.randf_range(0.4, 12.0), rng.randf() < 0.85])
		elif roll < 0.75:
			marks.append(["circle", at, rng.randf_range(0.3, 30.0), color, rng.randf() < 0.85])
		elif roll < 0.9:
			var polygon := PackedVector2Array()
			var sides := rng.randi_range(3, 8)
			for s in sides:
				polygon.append(at + Vector2.from_angle(TAU * s / sides + rng.randf_range(-0.2, 0.2)) * rng.randf_range(8, 40))
			marks.append(["polygon", polygon, color])
		else:
			var start := rng.randf_range(-PI, PI)
			marks.append(["arc", at, rng.randf_range(2, 30), start, start + rng.randf_range(-6.0, 6.0), rng.randi_range(2, 30), color, rng.randf_range(0.5, 5.0), rng.randf() < 0.85])
	var native := _render_viewport(marks, false)
	var batched := _render_viewport(marks, true)
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var a := native.get_texture().get_image()
	var b := batched.get_texture().get_image()
	var differing := 0
	var worst := 0.0
	for y in RENDER_SIZE.y:
		for x in RENDER_SIZE.x:
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			var d := maxf(maxf(absf(ca.r - cb.r), absf(ca.g - cb.g)), absf(ca.b - cb.b))
			if d > 0.0:
				differing += 1
				worst = maxf(worst, d)
	print("render batch: %d of %d pixels differ from the engine's own drawing (worst %.1f/255)" % [differing, RENDER_SIZE.x * RENDER_SIZE.y, worst * 255.0])
	# Trigonometry in single precision can move a vertex by a rounding step.
	_check(differing <= 4 and worst <= 3.0 / 255.0, "batched marks render as the engine's own (%d pixels differ, worst %.1f/255)" % [differing, worst * 255.0])
	native.queue_free()
	batched.queue_free()

func _render_viewport(marks: Array, batched: bool) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = RENDER_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var background := ColorRect.new()
	background.color = Color(0.1, 0.18, 0.2)
	background.size = Vector2(RENDER_SIZE)
	viewport.add_child(background)
	var painter := MarkPainter.new()
	painter.marks = marks
	painter.batched = batched
	viewport.add_child(painter)
	root.add_child(viewport)
	return viewport
