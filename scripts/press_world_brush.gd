extends RefCounted
## A small shared brush kit. Every mark is deterministic and receives its paint;
## no world state, wall clock, collision or camera is read here.
##
## Marks cost fewer draw calls than they look. The engine gives every polygon
## command its own draw call, and an antialiased polyline is three of them, so
## a two-pass stroke costs six. The brush builds the engine's own triangles
## instead (press_geometry.gd) and sends them as triangle arrays; the picture
## is unchanged, triangle for triangle.
## - Still scenery calls begin(c) and end(c) around its drawing: consecutive
##   marks are sent as one draw call. Anything else drawn on that canvas in
##   between, including a draw_set_transform, must call flush(c) first so the
##   order of marks never changes. A run that recurs (a room drawn again on a
##   later visit) reuses its triangles.
## - Outside begin/end (scenery that redraws as it moves), a mark is drawn as
##   ordinary draw calls the first time; when the same mark comes back on a
##   later redraw its triangles are kept and it costs one draw call.

const Geometry := preload("res://scripts/press_geometry.gd")
## Rough bytes of kept triangles per cache generation; two are kept, which
## holds the scenery of the last several rooms visited.
const CACHE_BUDGET := 4 * 1024 * 1024
const SEEN_LIMIT := 4096

static var _gathering := 0
static var _run: Array = []
static var _cache: Dictionary = {}
static var _old_cache: Dictionary = {}
static var _cache_bytes := 0
static var _seen: Dictionary = {}
static var _old_seen: Dictionary = {}

## Starts gathering marks for `c`, which must be inside its _draw().
static func begin(c: CanvasItem) -> void:
	_run = []
	_gathering = c.get_instance_id()

## Sends the gathered marks and stops gathering.
static func end(c: CanvasItem) -> void:
	flush(c)
	_gathering = 0

## Sends what has been gathered so far, before any other draw call on `c`.
static func flush(c: CanvasItem) -> void:
	if not _gathers(c) or _run.is_empty():
		return
	var key := _run
	_run = []
	var geometry: Array = _lookup(key)
	if geometry.is_empty():
		geometry = _tessellate(key)
		_store(key, geometry)
	_emit(c, geometry)

static func _gathers(c: CanvasItem) -> bool:
	return _gathering != 0 and _gathering == c.get_instance_id()

## One mark: a list of [kind, ...] descriptions drawn in order.
static func _mark(c: CanvasItem, unit: Array) -> void:
	if _gathers(c):
		_run.append_array(unit)
		return
	var geometry: Array = _lookup(unit)
	if geometry.is_empty():
		var seen := hash(unit)
		if not _seen.has(seen) and not _old_seen.has(seen):
			if _seen.size() >= SEEN_LIMIT:
				_old_seen = _seen
				_seen = {}
			_seen[seen] = true
			for part in unit:
				match part[0]:
					&"polyline": c.draw_polyline(part[1], part[2], part[3], part[4])
					&"circle": c.draw_circle(part[1], part[2], part[3], true, -1, part[4])
					&"polygon": c.draw_colored_polygon(part[1], part[2])
			return
		geometry = _tessellate(unit)
		_store(unit, geometry)
	_emit(c, geometry)

static func _tessellate(parts: Array) -> Array:
	var batch := Geometry.new()
	for part in parts:
		match part[0]:
			&"polyline": batch.add_polyline(part[1], part[2], part[3], part[4])
			&"circle": batch.add_circle(part[1], part[2], part[3], part[4])
			&"polygon": batch.add_polygon(part[1], part[2])
	return [batch.points, batch.colors, batch.indices]

static func _emit(c: CanvasItem, geometry: Array) -> void:
	if not geometry[0].is_empty():
		RenderingServer.canvas_item_add_triangle_array(c.get_canvas_item(), geometry[2], geometry[0], geometry[1])

static func _lookup(key: Array) -> Array:
	var hit: Array = _cache.get(key, [])
	if hit.is_empty() and _old_cache.has(key):
		hit = _old_cache[key]
		_store(key, hit)
	return hit

## Keeps triangles; a full generation is retired before more are kept.
static func _store(key: Array, geometry: Array) -> void:
	var size: int = geometry[0].size() * 24 + geometry[2].size() * 4
	if _cache_bytes + size > CACHE_BUDGET:
		_old_cache = _cache
		_cache = {}
		_cache_bytes = 0
	_cache[key] = geometry
	_cache_bytes += size

static func palette(ink: Color, stock: Color) -> Dictionary:
	var reversed := ink.get_luminance() < stock.get_luminance()
	return {
		"shadow": stock.lerp(ink, 0.045), "body": stock.lerp(ink, 0.13),
		"edge": stock.lerp(ink, 0.32), "light": stock.lerp(ink, 0.68),
		"gold": ink.lerp(Color("9a6245") if reversed else Color("ffc77c"), 0.40),
		"copper": stock.lerp(Color("794d51") if reversed else Color("b78066"), 0.46),
		"sage": stock.lerp(Color("607b70"), 0.36),
	}

static func grain(seed: float) -> float:
	return fposmod(sin(seed * 127.1 + 31.7) * 43758.5453, 1.0)

static func fade(paint: Color, opacity: float) -> Color:
	return Color(paint, paint.a * opacity)

static func stroke(c: CanvasItem, points: PackedVector2Array, paint: Color, width: float, seed := 0.0) -> void:
	if points.size() < 2: return
	var rough := PackedVector2Array()
	for i in points.size():
		var offset := Vector2(grain(seed + i * 7) - 0.5, grain(seed + i * 11) - 0.5) * minf(width * 0.25, 1.1)
		rough.append(points[i] + offset)
	_mark(c, [[&"polyline", rough, Color(paint, paint.a * 0.23), width + 2.0, true],
		[&"polyline", points, paint, width, true]])

static func line(c: CanvasItem, a: Vector2, b: Vector2, paint: Color, width: float, seed := 0.0) -> void:
	stroke(c, PackedVector2Array([a, a.lerp(b, 0.32), a.lerp(b, 0.71), b]), paint, width, seed)

static func curve(c: CanvasItem, a: Vector2, bend: Vector2, b: Vector2, paint: Color, width: float) -> void:
	var points := PackedVector2Array()
	for i in range(25):
		var t := float(i) / 24.0
		points.append(a * (1.0 - t) * (1.0 - t) + bend * 2.0 * t * (1.0 - t) + b * t * t)
	stroke(c, points, paint, width, a.x + b.y)

static func ellipse(c: CanvasItem, center: Vector2, size: Vector2, paint: Color, width := 2.0, start := 0.0, end := TAU) -> void:
	var points := PackedVector2Array()
	for i in range(49):
		var angle := lerpf(start, end, float(i) / 48.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * size)
	stroke(c, points, paint, width, center.x)

static func wash(c: CanvasItem, polygon: PackedVector2Array, paint: Color) -> void:
	if polygon.size() < 3: return
	_mark(c, [[&"polygon", polygon, paint]])

## A filled antialiased circle: draw_circle(center, radius, paint, true, -1, true).
static func dot(c: CanvasItem, center: Vector2, radius: float, paint: Color) -> void:
	_mark(c, [[&"circle", center, radius, paint, true]])

static func window(c: CanvasItem, box: Rect2, p: Dictionary, lit := true, arch := true) -> void:
	var radius := box.size.x * 0.5
	var crown := Vector2(box.get_center().x, box.position.y + radius)
	var body := Rect2(box.position + Vector2(0, radius if arch else 0.0), box.size - Vector2(0, radius if arch else 0.0))
	var fill: Color = p.gold if lit else p.shadow
	if arch: dot(c, crown, radius, fade(fill, 0.26 if lit else 0.65))
	flush(c)
	c.draw_rect(body, fade(fill, 0.25 if lit else 0.65))
	if arch:
		ellipse(c, crown, Vector2.ONE * (radius + 3.0), fade(p.edge, 0.75), 4.0, PI, TAU)
	else:
		line(c, box.position, Vector2(box.end.x, box.position.y), p.edge, 4)
	for side in [-1.0, 1.0]:
		var x: float = crown.x + side * (radius + 2)
		line(c, Vector2(x, crown.y if arch else box.position.y), Vector2(x, box.end.y), p.edge, 5)
	line(c, Vector2(box.position.x - 7, box.end.y + 3), Vector2(box.end.x + 7, box.end.y + 3), p.copper, 5)
	line(c, Vector2(crown.x, box.position.y + 10), Vector2(crown.x, box.end.y - 2), fade(p.shadow, 0.75), 3)
	line(c, Vector2(box.position.x + 2, box.get_center().y + 10), Vector2(box.end.x - 2, box.get_center().y + 10), p.shadow, 3)
	if lit:
		line(c, Vector2(box.position.x + 5, crown.y + 4), Vector2(box.position.x + 5, box.end.y - 10), fade(p.gold, 0.48), 2)

static func column(c: CanvasItem, x: float, top: float, bottom: float, width: float, p: Dictionary) -> void:
	wash(c, PackedVector2Array([Vector2(x - width * 0.48, top), Vector2(x + width * 0.50, top + 4),
		Vector2(x + width * 0.42, bottom), Vector2(x - width * 0.52, bottom)]), fade(p.body, 0.82))
	line(c, Vector2(x - width * 0.33, top + 8), Vector2(x - width * 0.38, bottom - 9), fade(p.light, 0.23), 7)
	line(c, Vector2(x + width * 0.36, top), Vector2(x + width * 0.29, bottom), fade(p.shadow, 0.9), 9)
	for y in [top, bottom - 11]:
		line(c, Vector2(x - width * 0.64, y), Vector2(x + width * 0.63, y + 2), p.edge, 11)
		line(c, Vector2(x - width * 0.61, y - 5), Vector2(x + width * 0.60, y - 4), fade(p.gold, 0.27), 2)
	for i in range(5):
		var y := lerpf(top + 30, bottom - 30, float(i) / 4.0)
		line(c, Vector2(x - width * 0.35, y), Vector2(x + width * 0.30, y - 3), fade(p.edge, 0.30), 1)

static func archway(c: CanvasItem, center: Vector2, radius: Vector2, bottom: float, p: Dictionary, weight := 14.0) -> void:
	ellipse(c, center, radius, fade(p.shadow, 0.86), weight + 11, PI, TAU)
	ellipse(c, center, radius, fade(p.edge, 0.70), weight, PI, TAU)
	ellipse(c, center + Vector2(0, -3), radius + Vector2(3, 1), fade(p.gold, 0.21), 2.5, PI, TAU)
	for side in [-1.0, 1.0]:
		line(c, center + Vector2(side * radius.x, 0), Vector2(center.x + side * radius.x, bottom), p.body, weight + 7)
		line(c, center + Vector2(side * (radius.x - 4), 0), Vector2(center.x + side * (radius.x - 4), bottom), fade(p.edge, 0.60), 3)
	for i in range(11):
		var angle := PI + float(i) / 10.0 * PI
		var a := center + Vector2(cos(angle), sin(angle)) * (radius - Vector2.ONE * weight * 0.35)
		var b := center + Vector2(cos(angle), sin(angle)) * (radius + Vector2.ONE * weight * 0.35)
		line(c, a, b, fade(p.shadow, 0.65), 2)

static func cable(c: CanvasItem, a: Vector2, b: Vector2, sag: float, p: Dictionary) -> void:
	var bend := (a + b) * 0.5 + Vector2(0, sag)
	curve(c, a + Vector2(0, 2), bend + Vector2(0, 3), b + Vector2(0, 2), p.shadow, 4)
	curve(c, a, bend, b, fade(p.edge, 0.64), 1.4)

static func lamp(c: CanvasItem, point: Vector2, p: Dictionary, scale := 1.0) -> void:
	for i in range(5, 0, -1):
		dot(c, point, float(i) * 12 * scale, fade(p.gold, 0.006 * (6 - i)))
	wash(c, PackedVector2Array([point + Vector2(-16, -6) * scale, point + Vector2(-8, -18) * scale,
		point + Vector2(8, -18) * scale, point + Vector2(17, -5) * scale]), p.copper)
	line(c, point + Vector2(-17, -5) * scale, point + Vector2(17, -4) * scale, p.gold, 2 * scale)
	dot(c, point + Vector2(0, 3) * scale, 5 * scale, p.gold)

static func motes(c: CanvasItem, area: Rect2, clock: float, paint: Color, count := 12) -> void:
	for i in range(count):
		var x := area.position.x + grain(i * 13.0) * area.size.x + sin(clock * 0.23 + i) * 9
		var y := area.position.y + grain(i * 29.0) * area.size.y + sin(clock * 0.16 + i * 2.0) * 6
		dot(c, Vector2(x, y), 0.7 + grain(i) * 1.1, Color(paint, 0.08 + grain(i * 3.0) * 0.13))

static func face(c: CanvasItem, surfaces: Array, p: Dictionary, metal := false) -> void:
	for value in surfaces:
		if not value is Rect2: continue
		var raw: Rect2 = value
		var r := Rect2(raw.position + Vector2(5, 13), raw.size - Vector2(10, 18))
		if r.size.x < 16 or r.size.y < 5: continue
		# All detail remains inside the supplied collider face and its parent clip.
		for mark in range(mini(5, maxi(1, int(r.size.x / 220)))):
			var seed := raw.position.x * 0.17 + raw.position.y * 0.31 + mark * 13.0
			var span := minf(r.size.x * 0.36, 45.0 + grain(seed) * 95.0)
			var start := r.position.x + 2.0 + grain(seed + 7.0) * maxf(0.0, r.size.x - span - 4.0)
			var y := r.position.y + 2.0 + grain(seed + 11.0) * minf(21.0, r.size.y - 4.0)
			var points := PackedVector2Array()
			for i in range(7):
				var x := minf(r.end.x - 1.0, start + span * i / 6.0)
				points.append(Vector2(x, clampf(y + sin(i * 1.1 + seed) * 0.8, r.position.y + 1, r.end.y - 1)))
			_mark(c, [[&"polyline", points, fade(p.edge, 0.10 if metal else 0.07), 1.0, false]])
		if r.size.y > 18 and metal:
			for x in [r.position.x + 7, r.end.x - 7]:
				_mark(c, [[&"circle", Vector2(x, r.get_center().y), 2.1, fade(p.copper, 0.40), false],
					[&"circle", Vector2(x - 0.5, r.get_center().y - 0.5), 0.7, fade(p.gold, 0.42), false]])
