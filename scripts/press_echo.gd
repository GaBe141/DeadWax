extends RefCounted
## A small reel, an old wire and the audience behind a shutter. All state and
## colours arrive from the caller; these drawings never inspect the world.

const COPPER := Color("e2a36b")

static func draw(c: CanvasItem, kind: StringName, state: Dictionary, time: float, reduced: bool, ink: Color, stock: Color) -> void:
	var clock := 0.0 if reduced else time
	var warm := COPPER.lerp(ink, 0.15)
	match kind:
		&"collect_spool": _spool(c, state, clock, ink, stock, warm)
		&"record_phrase": _wire(c, state, clock, ink, stock, warm)
		&"restore_warren": _alcove(c, state, clock, ink, stock, warm)
		&"collect_survey": _slip(c, state, clock, ink, stock, warm)
	c.draw_set_transform(Vector2.ZERO)
	if String(state.get("stage", "idle")) != "idle":
		_notes(c, state, ink, stock, warm)

static func _spool(c: CanvasItem, state: Dictionary, clock: float, ink: Color, stock: Color, warm: Color) -> void:
	var held := String(state.get("echo_spool", "missing")) != "missing"
	var rim := ink.lerp(stock, 0.34)
	# The cradle stays after collection. Its open lid points toward the Warren.
	c.draw_colored_polygon(PackedVector2Array([Vector2(-43, 23), Vector2(-38, 5), Vector2(36, 5), Vector2(44, 23)]), stock.lerp(ink, 0.18))
	c.draw_polyline(PackedVector2Array([Vector2(-42, 23), Vector2(-38, 5), Vector2(36, 5), Vector2(42, 23)]), rim, 2.0, true)
	c.draw_line(Vector2(-47, 25), Vector2(48, 25), rim, 2.0, true)
	c.draw_line(Vector2(27, 5), Vector2(52, -28), rim, 3.0, true)
	c.draw_line(Vector2(32, 9), Vector2(57, -23), Color(warm, 0.45), 1.0, true)
	if held:
		c.draw_arc(Vector2(0, 7), 18, 0.0, PI, 24, Color(ink, 0.25), 1.5, true)
		return
	var bob := sin(clock * 2.0) * 2.0
	c.draw_set_transform(Vector2(0, -15 + bob), -0.06)
	for radius in [35.0, 30.0, 26.0]:
		c.draw_circle(Vector2.ZERO, radius, Color(warm, 0.028), true, -1.0, true)
	_reel(c, Vector2(-11, 0), 20, ink, stock, warm, clock * 0.18)
	_reel(c, Vector2(14, 0), 20, ink, stock, warm, clock * 0.18)
	c.draw_rect(Rect2(-11, -6, 25, 12), stock.lerp(ink, 0.25))
	c.draw_line(Vector2(-11, -7), Vector2(14, -7), warm, 2.0, true)
	c.draw_line(Vector2(-11, 7), Vector2(14, 7), ink, 2.0, true)
	c.draw_polyline(PackedVector2Array([Vector2(20, 7), Vector2(28, 16), Vector2(34, 13), Vector2(42, 20)]), warm, 1.8, true)
	c.draw_set_transform(Vector2.ZERO)

static func _wire(c: CanvasItem, state: Dictionary, clock: float, ink: Color, stock: Color, warm: Color) -> void:
	var running := String(state.get("stage", "idle")) == "recording"
	var stored := String(state.get("echo_spool", "missing")) in ["recorded", "restored"]
	var frame := ink.lerp(stock, 0.24)
	c.draw_rect(Rect2(-33, -29, 67, 52), stock.lerp(ink, 0.10))
	c.draw_rect(Rect2(-33, -29, 67, 52), frame, false, 2.3)
	c.draw_line(Vector2(-40, 26), Vector2(42, 26), frame, 2.5, true)
	for x in [-22.0, 23.0]:
		c.draw_line(Vector2(x, 21), Vector2(x + signf(x) * 4, 26), frame, 3.0, true)
	c.draw_polyline(PackedVector2Array([Vector2(-16, -28), Vector2(-16, -50), Vector2(-35, -56), Vector2(-35, -77)]), frame, 3.5, true)
	# A broken telephone-like horn funnels the surviving phrase into the reel.
	c.draw_colored_polygon(PackedVector2Array([Vector2(-41, -80), Vector2(-28, -80), Vector2(-16, -59), Vector2(-52, -59)]), stock.lerp(warm, 0.20))
	c.draw_arc(Vector2(-34, -78), 14, PI, TAU, 22, warm.lerp(stock, 0.30), 3.0, true)
	c.draw_line(Vector2(-48, -78), Vector2(-21, -78), ink, 2.0, true)
	c.draw_line(Vector2(16, -29), Vector2(16, -65), frame, 2.0, true)
	c.draw_polyline(PackedVector2Array([Vector2(-33, -59), Vector2(-12, -68), Vector2(16, -65), Vector2(32, -75)]), Color(warm, 0.48), 1.3, true)
	for index in range(3):
		var pos := Vector2(-12 + index * 17, -63 - index % 2 * 7)
		var live := running and int(state.get("note", -1)) == index
		c.draw_circle(pos, 3.0 if live else 2.0, warm if live else ink.lerp(stock, 0.48), true, -1.0, true)
	_reel(c, Vector2(0, -2), 18, ink, stock, warm if running or stored else ink.lerp(stock, 0.52), clock * (1.7 if running else 0.04))
	for index in range(4):
		c.draw_line(Vector2(-27 + index * 5, 13), Vector2(-25 + index * 5, 13), Color(ink, 0.34), 1.0, true)
	c.draw_circle(Vector2(24, 13), 3, warm if stored else stock, true, -1.0, true)

static func _alcove(c: CanvasItem, state: Dictionary, clock: float, ink: Color, stock: Color, warm: Color) -> void:
	var restored := String(state.get("echo_spool", "missing")) == "restored"
	var playing := String(state.get("stage", "idle")) == "playing"
	var reveal := 1.0 if restored else (float(state.get("progress", 0.0)) if playing and not bool(state.get("reduced_motion", false)) else 0.0)
	var frame := ink.lerp(stock, 0.47)
	# The little room is engraved above its real terrace. No drawn sill extends
	# beyond that surface and the shutter adds no collider or passage.
	var arch := PackedVector2Array([Vector2(-151, 22), Vector2(-151, -71), Vector2(-133, -97), Vector2(-100, -112),
		Vector2(-34, -112), Vector2(-1, -97), Vector2(17, -71), Vector2(17, 22)])
	c.draw_colored_polygon(arch, stock.lerp(ink, 0.065))
	c.draw_polyline(arch, frame, 3.0, true)
	c.draw_line(Vector2(-153, 25), Vector2(20, 25), frame, 2.8, true)
	if reveal > 0.0:
		c.draw_colored_polygon(PackedVector2Array([Vector2(-138, 18), Vector2(-136, -68), Vector2(-110, -94),
			Vector2(-28, -94), Vector2(4, -65), Vector2(4, 18)]), Color(warm, 0.07 * reveal))
		for index in range(3):
			var pos := Vector2(-117 + index * 48, -38 - (12 if index == 1 else 0))
			var answering := playing and int(state.get("note", -1)) == index
			var breath := sin(clock * 1.5 + index) * (1.5 if restored else 0.0)
			pos.y += breath
			var tint := warm.lerp(ink, 0.20) if answering else warm.lerp(stock, 0.25)
			c.draw_line(pos + Vector2(-10, 21), Vector2(pos.x - 15, 21), Color(frame, reveal), 2.4, true)
			c.draw_line(pos + Vector2(10, 21), Vector2(pos.x + 15, 21), Color(frame, reveal), 2.4, true)
			c.draw_circle(pos, 19, Color(ink.lerp(stock, 0.78), reveal), true, -1.0, true)
			c.draw_arc(pos, 19, 0.0, TAU, 40, Color(tint, reveal * 0.84), 2.0, true)
			c.draw_arc(pos, 13, -1.3, 4.6, 28, Color(tint, reveal * 0.40), 1.0, true)
			c.draw_circle(pos + Vector2(-5, -2), 1.8, Color(tint, reveal), true, -1.0, true)
			c.draw_circle(pos + Vector2(5, -2), 1.8, Color(tint, reveal), true, -1.0, true)
			if answering:
				c.draw_circle(pos + Vector2(0, 7), 3.5, warm, false, 1.6, true)
			else:
				c.draw_arc(pos + Vector2(0, 4), 5, 0.2, PI - 0.2, 15, Color(tint, reveal), 1.2, true)
		# The formerly empty staff becomes a single complete copper inscription.
		c.draw_polyline(PackedVector2Array([Vector2(-135, -80), Vector2(-111, -85), Vector2(-72, -78), Vector2(-34, -86), Vector2(0, -78)]), Color(warm, reveal * 0.56), 1.4, true)
	# Two sliding wooden leaves expose the audience. Saved discoveries arrive
	# fully open, without replaying the first-opening sequence.
	if reveal < 1.0:
		var shutter_width := (1.0 - reveal) * 78.0
		for side in [-1.0, 1.0]:
			var x := -145.0 if side < 0.0 else 10.0 - shutter_width
			c.draw_rect(Rect2(x, -74, shutter_width, 96), stock.lerp(ink, 0.12))
			for index in range(5):
				c.draw_line(Vector2(x + 3, -65 + index * 18), Vector2(x + shutter_width - 3, -65 + index * 18), Color(frame, 0.60), 1.4, true)
			c.draw_line(Vector2(x, -74), Vector2(x, 22), frame, 2.0, true)
	# The receiver sits beside the engraving so its controls remain readable.
	c.draw_rect(Rect2(29, 3, 31, 20), stock.lerp(ink, 0.20))
	c.draw_line(Vector2(25, 25), Vector2(65, 25), ink.lerp(stock, 0.30), 2.4, true)
	c.draw_polyline(PackedVector2Array([Vector2(44, 3), Vector2(44, -29), Vector2(28, -46)]), ink.lerp(stock, 0.22), 5.0, true)
	c.draw_colored_polygon(PackedVector2Array([Vector2(23, -44), Vector2(34, -52), Vector2(18, -79), Vector2(-1, -58)]), stock.lerp(warm, 0.24 + reveal * 0.17))
	c.draw_line(Vector2(-1, -58), Vector2(18, -79), warm.lerp(stock, 0.30 - reveal * 0.20), 3.5, true)
	c.draw_circle(Vector2(46, 12), 4, warm if restored else stock, true, -1.0, true)
	if playing:
		c.draw_arc(Vector2(6, -68), 26, 3.5, 5.0, 23, Color(warm, 0.52), 1.5, true)

static func _slip(c: CanvasItem, state: Dictionary, clock: float, ink: Color, stock: Color, warm: Color) -> void:
	var held := bool(state.get("survey_slip", false))
	c.draw_line(Vector2(-30, 23), Vector2(30, 23), ink.lerp(stock, 0.42), 2.4, true)
	c.draw_circle(Vector2(-23, 19), 4, ink.lerp(stock, 0.55), true, -1.0, true)
	if held:
		c.draw_line(Vector2(-12, 16), Vector2(13, 12), Color(warm, 0.30), 1.4, true)
		return
	c.draw_set_transform(Vector2(0, sin(clock * 1.8) * 1.8), -0.08)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-22, -29), Vector2(19, -29), Vector2(27, -18), Vector2(23, 19), Vector2(-23, 17)]), ink.lerp(stock, 0.17))
	c.draw_polyline(PackedVector2Array([Vector2(-22, -29), Vector2(19, -29), Vector2(27, -18), Vector2(23, 19)]), warm, 1.8, true)
	c.draw_line(Vector2(18, -28), Vector2(17, -17), stock.lerp(ink, 0.42), 1.2, true)
	c.draw_line(Vector2(17, -17), Vector2(26, -18), stock.lerp(ink, 0.42), 1.2, true)
	var route := PackedVector2Array([Vector2(-13, 9), Vector2(-11, -1), Vector2(-2, -1), Vector2(-2, -11), Vector2(10, -11)])
	c.draw_polyline(route, stock.lerp(warm, 0.16), 1.6, true)
	c.draw_arc(Vector2(10, -11), 5, 0, TAU, 21, stock, 1.5, true)
	for index in range(3):
		c.draw_line(Vector2(-13, -22 + index * 4), Vector2(4 + index % 2 * 6, -22 + index * 4), Color(stock, 0.30), 1.0, true)
	c.draw_set_transform(Vector2.ZERO)

static func _reel(c: CanvasItem, pos: Vector2, radius: float, ink: Color, stock: Color, warm: Color, angle: float) -> void:
	c.draw_circle(pos, radius, stock.lerp(ink, 0.10), true, -1.0, true)
	c.draw_arc(pos, radius, 0, TAU, 44, warm, 2.0, true)
	c.draw_arc(pos, radius - 4, 0, TAU, 38, ink.lerp(stock, 0.45), 1.0, true)
	for spoke in range(3):
		var direction := Vector2.from_angle(angle + spoke * TAU / 3.0)
		c.draw_circle(pos + direction * radius * 0.46, radius * 0.18, ink.lerp(stock, 0.28), true, -1.0, true)
	c.draw_circle(pos, 3.5, warm, true, -1.0, true)
	c.draw_circle(pos, 1.3, stock, true, -1.0, true)

static func _notes(c: CanvasItem, state: Dictionary, ink: Color, stock: Color, warm: Color) -> void:
	# Semantic note marks continue under Reduced motion. They describe the
	# actual finite recording/playback timer, independent of the brush clock.
	c.draw_rect(Rect2(-39, -105, 78, 19), Color(stock, 0.96))
	for index in range(3):
		var pos := Vector2(-24 + index * 24, -96)
		var active := index <= int(state.get("note", -1))
		c.draw_circle(pos, 4.5, warm if active else stock, true, -1.0, true)
		c.draw_arc(pos, 4.5, 0, TAU, 24, ink, 1.2, true)
	c.draw_line(Vector2(-33, -82), Vector2(33, -82), ink.lerp(stock, 0.65), 2.0, true)
	c.draw_line(Vector2(-33, -82), Vector2(-33 + 66.0 * float(state.get("progress", 0.0)), -82), warm, 2.0, true)
