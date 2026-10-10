extends RefCounted
## Skip's small moments, drawn from explicit pose fields: the Book snapped
## shut and tucked into the coat, a find raised overhead, idle fidgets
## (tapping along, looking about, polishing the stylus), listening nods,
## footwork dust and a new level's ring. Like the combat sampler, these only
## deform drawn wax and brass; no clock, input, collision or gameplay state
## lives here. Positions are Skip-local with x toward his facing.

const Paint := preload("res://scripts/figure_paint.gd")
const PressAbility := preload("res://scripts/press_ability.gd")
const LEATHER := Color("0d232b")

## Standing still, Skip waits IDLE_DELAY seconds, then cycles these.
const IDLE_DELAY := 4.0
const FIDGETS := [[&"tap", 3.2], [&"", 1.4], [&"look", 2.6], [&"", 1.2], [&"polish", 2.4], [&"", 2.6]]
## Where the small Book sits in Skip's hand; Main lands the closing Book here.
const BOOK_HAND := Vector2(15, -3)
## Polishing brings the stylus down in front of the coat, clear of the face.
const POLISH_TIP := Vector2(24, -14)
const POLISH_ELBOW := Vector2(13, -38)

static func fidget(idle: float) -> Dictionary:
	var elapsed := idle - IDLE_DELAY
	if elapsed <= 0.0:
		return {"kind": &"", "phase": 0.0, "weight": 0.0}
	var cycle := 0.0
	for entry in FIDGETS:
		cycle += float(entry[1])
	elapsed = fmod(elapsed, cycle)
	for entry in FIDGETS:
		var length := float(entry[1])
		if elapsed < length:
			var phase := elapsed / length
			var weight := clampf(minf(elapsed, length - elapsed) / 0.3, 0.0, 1.0)
			return {"kind": entry[0], "phase": phase, "weight": weight if StringName(entry[0]) != &"" else 0.0}
		elapsed -= length
	return {"kind": &"", "phase": 0.0, "weight": 0.0}

## Offsets press_skip folds into its joints, already mirrored to the facing.
static func sample(pose: Dictionary) -> Dictionary:
	var face := -1.0 if float(pose.get("face", 1.0)) < 0.0 else 1.0
	var calm := (1.0 - clampf(float(pose.get("hood", 0.0)), 0.0, 1.0)) * (1.0 - clampf(float(pose.get("set", 0.0)), 0.0, 1.0))
	var result := {"stretch": Vector2.ZERO, "tilt": 0.0, "eye": Vector2.ZERO, "tap": 0.0,
		"stylus": 0.0, "tip": Vector2.ZERO, "elbow": Vector2.ZERO, "happy": 0.0}
	var book := _time_left(pose, "book")
	var item := _time_left(pose, "item")
	var nod := _time_left(pose, "nod")
	var listen := clampf(float(pose.get("listen", 0.0)), 0.0, 1.0)
	var quirk := fidget(float(pose.get("idle", 0.0)))
	var fidget_weight := float(quirk.weight) * calm
	if item >= 0.0:
		var raise := _raise(item) * calm
		result.stylus = raise
		result.tip = Vector2(face * 6.0, -51.0)
		result.elbow = Vector2(face * 11.0, -44.0)
		result.stretch = Vector2(-0.02, 0.05) * raise
		result.happy = calm if item > 0.18 and item < 0.8 else 0.0
		result.eye = Vector2(0, -1.5) * raise
	elif book >= 0.0:
		var pat := clampf((book - 0.72) / 0.1, 0.0, 1.0)
		var bob := sin(pat * TAU) * 0.02 if pat > 0.0 and pat < 1.0 else 0.0
		result.stretch = Vector2(0.0, -bob) * calm
		result.eye = Vector2(face * 1.2, 1.4) * _arm(book) * calm
	elif quirk.kind == &"polish":
		result.stylus = fidget_weight
		result.tip = POLISH_TIP * Vector2(face, 1.0)
		result.elbow = POLISH_ELBOW * Vector2(face, 1.0)
		result.eye = Vector2(face * 1.8, 0.4) * fidget_weight
	elif quirk.kind == &"look":
		var glance := _glance(float(quirk.phase))
		result.eye = Vector2(face * glance * 3.2, -0.8 * absf(glance)) * fidget_weight
		result.tilt = face * glance * 0.035 * fidget_weight
	elif quirk.kind == &"tap":
		var beat := clampf(float(pose.get("beat", 0.0)), 0.0, 1.0)
		result.tap = sin(beat * PI) * 3.0 * fidget_weight
		var accent := pow(1.0 - beat, 6.0) * fidget_weight
		result.eye = Vector2(0, accent * 0.9)
		result.stretch = Vector2(0.0, -0.012 * accent)
	if nod >= 0.0:
		var dip := sin(nod * PI) * calm
		result.eye += Vector2(0, dip * 2.2)
		result.tilt += face * dip * 0.06
		result.stretch += Vector2(0.0, -0.04 * dip)
	if listen > 0.0:
		result.eye += Vector2(face * 0.8, -0.6) * listen * calm
	return result

## Arms, the small Book and the raised find, inside the body's transform.
static func draw_held(canvas: CanvasItem, pose: Dictionary, body: Transform2D, paint: Dictionary, quiet: float) -> void:
	var face := -1.0 if float(pose.get("face", 1.0)) < 0.0 else 1.0
	var calm := (1.0 - clampf(float(pose.get("hood", 0.0)), 0.0, 1.0)) * (1.0 - clampf(float(pose.get("set", 0.0)), 0.0, 1.0)) * quiet
	if calm <= 0.01:
		return
	var item := _time_left(pose, "item")
	var book := _time_left(pose, "book")
	if item >= 0.0:
		var raise := _raise(item)
		var hand := Vector2(-14 * face, 14).lerp(Vector2(-6 * face, -50), raise)
		var elbow := Vector2(-18 * face, 4).lerp(Vector2(-15 * face, -21), raise)
		_arm_segments(canvas, Vector2(-9 * face, 1), elbow, hand, paint, calm * minf(raise * 3.0, 1.0))
		var rise := clampf(item / 0.16, 0.0, 1.0)
		var sink := clampf((item - 0.82) / 0.18, 0.0, 1.0)
		var center := Vector2(0, -10).lerp(Vector2(0, -63), 1.0 - pow(1.0 - rise, 3.0)).lerp(Vector2(0, -6), sink * sink)
		center.y += sin(item * 9.0) * 1.0 * (1.0 - sink) * rise
		var size := lerpf(0.45, 1.0, rise) * (1.0 - sink)
		if size > 0.02:
			if rise >= 1.0 and sink <= 0.0:
				canvas.draw_circle(center, 20.0, Color(paint.gold, 0.10 * calm), true, -1, true)
			var held := body * Transform2D(0.0, Vector2.ONE * size, 0.0, center)
			canvas.draw_set_transform_matrix(held)
			_find(canvas, StringName(pose.get("item_kind", &"")), StringName(pose.get("item_detail", &"")), paint, calm, held)
			canvas.draw_set_transform_matrix(body)
	elif book >= 0.0:
		var reach := _arm(book)
		if reach <= 0.0:
			return
		var hold := Vector2(BOOK_HAND.x * face, BOOK_HAND.y)
		var tucked := Vector2(3 * face, 9)
		var hand := hold
		if book >= 0.46:
			hand = hold.lerp(tucked, _smooth(clampf((book - 0.46) / 0.26, 0.0, 1.0)))
		if book >= 0.72:
			hand = tucked + Vector2(0, sin(clampf((book - 0.72) / 0.1, 0.0, 1.0) * TAU) * 1.2)
		if book >= 0.82:
			hand = tucked.lerp(Vector2(13 * face, 17), _smooth((book - 0.82) / 0.18))
		_arm_segments(canvas, Vector2(8 * face, 3), Vector2(16 * face, 11).lerp(Vector2(10 * face, 14), clampf((book - 0.46) / 0.3, 0.0, 1.0)), hand, paint, calm * reach)
		var shrink := 1.0 - clampf((book - 0.56) / 0.16, 0.0, 1.0)
		if shrink > 0.0:
			var squeeze := 0.0
			if book >= 0.36 and book < 0.46:
				squeeze = sin((book - 0.36) / 0.10 * PI)
			_small_book(canvas, hand + Vector2(face * 2.0, -3.0), face, squeeze, shrink, paint, calm * reach)
	else:
		var quirk := fidget(float(pose.get("idle", 0.0)))
		if quirk.kind == &"polish" and float(quirk.weight) > 0.0:
			var weight := float(quirk.weight) * calm
			var tip := POLISH_TIP * Vector2(face, 1.0)
			var elbow := POLISH_ELBOW * Vector2(face, 1.0)
			var rub := 0.5 + 0.5 * sin(float(quirk.phase) * 2.4 * 13.0)
			var hand := elbow.lerp(tip, 0.35 + 0.5 * rub)
			_arm_segments(canvas, Vector2(8 * face, 4), Vector2(18 * face, 2), hand, paint, weight)
			canvas.draw_line(hand + Vector2(-2.5, -1), hand + Vector2(2.5, 1), Color(paint.cream, 0.7 * weight), 1.4, true)

## Marks around the figure, after its transform: the snap, the glint on a
## polished stylus or a raised find, and a new level's ring.
static func draw_marks(canvas: CanvasItem, pose: Dictionary, body: Transform2D, paint: Dictionary, quiet: float) -> void:
	var face := -1.0 if float(pose.get("face", 1.0)) < 0.0 else 1.0
	var calm := (1.0 - clampf(float(pose.get("hood", 0.0)), 0.0, 1.0)) * quiet
	var book := _time_left(pose, "book")
	if book >= 0.40 and book < 0.56 and calm > 0.0:
		var snap := 1.0 - (book - 0.40) / 0.16
		var at := body * Vector2((BOOK_HAND.x + 11.0) * face, BOOK_HAND.y - 3.0)
		for side in [-1.0, 1.0]:
			var direction := Vector2(face * 0.8, side * 0.9).normalized()
			canvas.draw_line(at + direction * 3.0, at + direction * (5.0 + (1.0 - snap) * 4.0), Color(paint.cream, snap * 0.9 * calm), 1.4, true)
	var item := _time_left(pose, "item")
	if item >= 0.16 and item < 0.82 and calm > 0.0:
		var shine := sin((item - 0.16) / 0.66 * PI * 3.0)
		if shine > 0.0:
			_star(canvas, body * Vector2(11 * face, -74), 5.0 * shine, Color(paint.light, 0.9 * shine * calm))
	var quirk := fidget(float(pose.get("idle", 0.0)))
	if quirk.kind == &"polish" and float(quirk.phase) > 0.72:
		var glint := sin((float(quirk.phase) - 0.72) / 0.28 * PI) * calm
		if glint > 0.0:
			_star(canvas, body * (POLISH_TIP * Vector2(face, 1.0)), 5.0 * glint, Color(paint.light, glint))
	var glow := _time_left(pose, "glow")
	if glow >= 0.0:
		var center := body * Vector2(0, -6)
		for ring in 2:
			var local := clampf(glow * 1.3 - ring * 0.3, 0.0, 1.0)
			if local > 0.0 and local < 1.0:
				var eased := 1.0 - pow(1.0 - local, 3.0)
				canvas.draw_arc(center, 18.0 + eased * 44.0, 0.0, TAU, 48, Color(paint.gold if ring == 0 else paint.cream, (1.0 - local) * 0.75), 2.4 - ring, true)
		for ray in 6:
			var direction := Vector2.from_angle(ray * TAU / 6.0 - PI * 0.5)
			var reach := 1.0 - pow(1.0 - minf(glow * 1.8, 1.0), 2.0)
			canvas.draw_line(center + direction * (26.0 + reach * 14.0), center + direction * (31.0 + reach * 24.0), Color(paint.gold, (1.0 - glow) * 0.8), 1.6, true)

## Kicked-up dust in Skip-local coordinates: each puff swells, rises and thins.
static func draw_dust(canvas: CanvasItem, puffs: Array, color: Color) -> void:
	for puff in puffs:
		var age := clampf(float(puff.age), 0.0, 1.0)
		var at: Vector2 = puff.at
		var size := float(puff.size)
		var fade := (1.0 - age) * (1.0 - age)
		canvas.draw_circle(at, size * (3.2 + age * 4.4), Color(color, 0.40 * fade), true, -1, true)
		canvas.draw_circle(at + Vector2(size * 2.4, -size * 1.2), size * (2.0 + age * 2.8), Color(color, 0.30 * fade), true, -1, true)
		canvas.draw_circle(at + Vector2(-size * 2.6, size * 0.5) * (1.0 + age), size * 1.0, Color(color, 0.55 * fade), true, -1, true)

# -- pieces ---------------------------------------------------------------------

static func _arm_segments(canvas: CanvasItem, shoulder: Vector2, elbow: Vector2, hand: Vector2, paint: Dictionary, alpha: float) -> void:
	if alpha <= 0.01:
		return
	var coat: Color = paint.coat
	var brass: Color = paint.brass
	Paint.segment(canvas, shoulder, elbow, 5.0, Color(coat, alpha), Color(paint.edge, alpha), Color(paint.teal, alpha))
	Paint.segment(canvas, elbow, hand, 4.0, Color(brass, alpha), Color(paint.edge, alpha), Color(paint.gold, alpha))

## The Book in miniature: the same dark board and gold rule, its cream
## fore-edge away from the hand. `squeeze` presses it shut with a snap.
static func _small_book(canvas: CanvasItem, center: Vector2, face: float, squeeze: float, size: float, paint: Dictionary, alpha: float) -> void:
	var half := Vector2(8.0 * (1.0 + squeeze * 0.12), 6.0 * (1.0 - squeeze * 0.28)) * size
	var rect := Rect2(center - half, half * 2.0)
	canvas.draw_rect(rect.grow(1.0), Color(paint.edge, alpha))
	canvas.draw_rect(rect, Color(LEATHER, alpha))
	var fore := rect.end.x - 2.5 * size if face > 0.0 else rect.position.x
	canvas.draw_rect(Rect2(fore, rect.position.y + 1.0, 2.5 * size, rect.size.y - 2.0), Color(paint.cream, alpha))
	canvas.draw_rect(rect.grow(-1.6 * size), Color(paint.gold, 0.85 * alpha), false, 1.0)
	var spine := rect.position.x + 1.0 if face > 0.0 else rect.end.x - 1.0
	canvas.draw_line(Vector2(spine, rect.position.y), Vector2(spine, rect.end.y), Color(paint.gold, alpha), 1.6, true)
	canvas.draw_circle(rect.get_center() + Vector2(-face * 0.8, 0), 1.8 * size, Color(paint.gold, 0.9 * alpha), true, -1, true)

## The find in Skip's hands, centred on the origin, about 24 px across.
## `held` is the transform already applied, so a move's engraving can nest.
static func _find(canvas: CanvasItem, kind: StringName, detail: StringName, paint: Dictionary, alpha: float, held: Transform2D) -> void:
	var ink: Color = Color(paint.edge, alpha)
	var cream: Color = Color(paint.cream, alpha)
	var brass: Color = Color(paint.gold, alpha)
	match kind:
		&"move":
			canvas.draw_rect(Rect2(-12, -12, 24, 24), cream)
			canvas.draw_rect(Rect2(-12, -12, 24, 24), ink, false, 1.5)
			canvas.draw_line(Vector2(-9, -9), Vector2(9, -9), brass, 1.5, true)
			canvas.draw_set_transform_matrix(held * Transform2D(0.0, Vector2.ONE * 0.42, 0.0, Vector2(0, 1.5)))
			PressAbility.draw_glyph(canvas, detail, brass, ink, cream)
			canvas.draw_set_transform_matrix(held)
		&"map":
			var panels := [
				PackedVector2Array([Vector2(-12, -9), Vector2(-4, -11), Vector2(-4, 6), Vector2(-12, 8)]),
				PackedVector2Array([Vector2(-4, -11), Vector2(4, -8), Vector2(4, 9), Vector2(-4, 6)]),
				PackedVector2Array([Vector2(4, -8), Vector2(12, -10), Vector2(12, 7), Vector2(4, 9)]),
			]
			for index in panels.size():
				canvas.draw_colored_polygon(panels[index], cream.lerp(ink, 0.10 if index == 1 else 0.02))
				var line: PackedVector2Array = panels[index].duplicate()
				line.append(line[0])
				canvas.draw_polyline(line, ink, 1.2, true)
			canvas.draw_polyline(PackedVector2Array([Vector2(-9, -4), Vector2(-5, -5), Vector2(-1, -2), Vector2(3, -2), Vector2(7, 2), Vector2(10, 1)]), Color(paint.copper, alpha), 1.4, true)
		&"refrain":
			canvas.draw_circle(Vector2.ZERO, 12.0, cream, true, -1, true)
			canvas.draw_circle(Vector2.ZERO, 10.0, ink, true, -1, true)
			for radius in [8.0, 6.0]:
				canvas.draw_arc(Vector2.ZERO, radius, 0.3, TAU - 0.4, 24, Color(paint.cream, 0.45 * alpha), 0.8, true)
			canvas.draw_circle(Vector2.ZERO, 3.2, Color(paint.coral, alpha), true, -1, true)
			canvas.draw_circle(Vector2.ZERO, 1.0, cream, true, -1, true)
		&"spool":
			canvas.draw_circle(Vector2.ZERO, 11.0, ink, true, -1, true)
			canvas.draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 24, Color(paint.wax, alpha), 2.0, true)
			for spoke in 3:
				var direction := Vector2.from_angle(spoke * TAU / 3.0)
				canvas.draw_line(direction * 2.5, direction * 7.0, Color(paint.wax, alpha), 1.6, true)
			canvas.draw_circle(Vector2.ZERO, 2.5, brass, true, -1, true)
			canvas.draw_line(Vector2(9, 5), Vector2(14, 11), Color(paint.wax, alpha), 1.4, true)
		&"slip":
			canvas.draw_rect(Rect2(-12, -8, 24, 16), cream)
			canvas.draw_rect(Rect2(-12, -8, 24, 16), ink, false, 1.2)
			canvas.draw_polyline(PackedVector2Array([Vector2(-8, 3), Vector2(-3, -2), Vector2(2, 1), Vector2(8, -4)]), brass, 1.4, true)
			canvas.draw_circle(Vector2(-8, 3), 1.6, ink, true, -1, true)
			canvas.draw_circle(Vector2(8, -4), 1.6, ink, true, -1, true)
		_:
			# A fitting from a pressing or a trial: a folded sleeve with a brass seal.
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-11, -11), Vector2(8, -12), Vector2(12, -8), Vector2(11, 12), Vector2(-11, 11)]), cream.lerp(ink, 0.12))
			canvas.draw_polyline(PackedVector2Array([Vector2(-11, 11), Vector2(-11, -11), Vector2(8, -12), Vector2(12, -8), Vector2(11, 12), Vector2(-11, 11)]), ink, 1.2, true)
			canvas.draw_line(Vector2(8, -12), Vector2(7, -7), brass, 1.0, true)
			canvas.draw_line(Vector2(7, -7), Vector2(12, -8), brass, 1.0, true)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(6, 0), Vector2(0, 6), Vector2(-6, 0)]), brass)
			canvas.draw_circle(Vector2.ZERO, 1.6, ink, true, -1, true)

static func _star(canvas: CanvasItem, at: Vector2, size: float, color: Color) -> void:
	if size <= 0.2:
		return
	canvas.draw_line(at + Vector2(-size, 0), at + Vector2(size, 0), color, 1.3, true)
	canvas.draw_line(at + Vector2(0, -size), at + Vector2(0, size), color, 1.3, true)
	canvas.draw_line(at + Vector2(-size, -size) * 0.45, at + Vector2(size, size) * 0.45, color, 1.0, true)
	canvas.draw_line(at + Vector2(-size, size) * 0.45, at + Vector2(size, -size) * 0.45, color, 1.0, true)

## Elapsed share of a gesture whose remaining share the pose reports; -1 idle.
static func _time_left(pose: Dictionary, key: String) -> float:
	var remaining := clampf(float(pose.get(key, 0.0)), 0.0, 1.0)
	return 1.0 - remaining if remaining > 0.0 else -1.0

static func _raise(elapsed: float) -> float:
	if elapsed < 0.16:
		return 1.0 - pow(1.0 - elapsed / 0.16, 3.0)
	if elapsed > 0.82:
		return 1.0 - _smooth((elapsed - 0.82) / 0.18)
	return 1.0

static func _arm(elapsed: float) -> float:
	if elapsed < 0.08:
		return elapsed / 0.08
	if elapsed > 0.82:
		return 1.0 - _smooth((elapsed - 0.82) / 0.18)
	return 1.0

static func _glance(phase: float) -> float:
	if phase < 0.15: return -_smooth(phase / 0.15)
	if phase < 0.45: return -1.0
	if phase < 0.60: return lerpf(-1.0, 1.0, _smooth((phase - 0.45) / 0.15))
	if phase < 0.85: return 1.0
	return 1.0 - _smooth((phase - 0.85) / 0.15)

static func _smooth(amount: float) -> float:
	var clamped := clampf(amount, 0.0, 1.0)
	return clamped * clamped * (3.0 - 2.0 * clamped)
