extends RefCounted
## The first call, and the rubbing it leaves on the stone. Functional note
## marks follow the supplied stage even when decorative motion is disabled.

const AuditionerPrint := preload("res://scripts/press_auditioner.gd")
const PINK := Color("d7a66b")

static func draw_voice(c: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var stage := String(pose.get("stage", "waiting"))
	var reduced := bool(pose.get("reduced_motion", false))
	var clock := 0.0 if reduced else float(pose.get("clock", 0.0))
	var base := pose.duplicate(true)
	base.clock = clock
	if reduced:
		base.stride = 0.0
		base.jitter = Vector2.ZERO
	var warm := _warm(stock)
	AuditionerPrint.draw_auditioner(c, base, ink, ink.lerp(stock, 0.18), stock, PINK,
		ink.lerp(stock, 0.53), warm)
	if stage == "down" or String(base.phase) == "down":
		c.draw_set_transform(Vector2.ZERO)
		return
	var alpha := 1.0
	if String(base.phase) == "freed" and not bool(base.get("held", false)):
		alpha = pow(1.0 - clampf(float(base.get("leave", 0.0)), 0.0, 1.0), 1.1)
	var center := _body_center(base)
	var face := float(base.get("face", -1.0))
	var answered := stage == "freed"
	var note := clampi(int(pose.get("note", -1)), -1, 1)
	var calling := stage == "calling" or (stage == "waiting" and note >= 0)
	# One surviving sleeve hangs across the lower disc. Its folded end lifts
	# hesitantly with each call, distinct from the Auditioner's reaching arm.
	var flutter := sin(clock * 2.6) * 1.0
	var lift := (5.0 + maxf(note, 0) * 5.0) if calling else (3.0 if answered else 0.0)
	var tail := center + Vector2(-face * 27, 17 - lift + flutter)
	var cloth := PackedVector2Array([
		center + Vector2(-19, 7), center + Vector2(18, 10),
		center + Vector2(16, 16), center + Vector2(-16, 12),
	])
	c.draw_colored_polygon(cloth, Color(warm.lerp(stock, 0.25), alpha * 0.92))
	c.draw_polyline(PackedVector2Array([center + Vector2(-face * 15, 9), tail,
		tail + Vector2(face * 9, 4)]), Color(warm, alpha), 4.0, true)
	c.draw_line(center + Vector2(-16, 8), center + Vector2(15, 11), Color(ink, alpha * 0.54), 1.0, true)
	for index in range(3):
		var stitch := center + Vector2(-7 + index * 7, 11 + index * 0.5)
		c.draw_line(stitch, stitch + Vector2(1.5, -2), Color(ink, alpha * 0.70), 1.0, true)
	# Two small nicks in the rim make this old voice recognizable before it
	# asks anything. They are an engraving, never additional hit feedback.
	for offset in [-8.0, 5.0]:
		c.draw_line(center + Vector2(offset, -20), center + Vector2(offset + 2, -16), Color(warm, alpha * 0.9), 1.7, true)
	if bool(pose.get("near", false)) and stage not in ["freed", "down"]:
		_call_marks(c, stage, note, clampf(float(pose.get("answer", 0.0)), 0.0, 1.0), ink, stock, warm)
	c.draw_set_transform(Vector2.ZERO)

static func draw_memory(c: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var outcome := String(pose.get("outcome", ""))
	var reduced := bool(pose.get("reduced_motion", false))
	var clock := 0.0 if reduced else float(pose.get("clock", 0.0))
	var reveal := 1.0 if reduced else clampf(float(pose.get("reveal", 1.0)), 0.0, 1.0)
	var heard := outcome == "freed"
	var broken := outcome == "shattered"
	var faded := ink.lerp(stock, 0.79)
	var cut := ink.lerp(stock, 0.62)
	var warm := _warm(stock)
	# A broad rubbed headstone, deliberately faint and open at its bottom.
	# Every cut remains above local y10, clear of the real walkable edge.
	var edge := PackedVector2Array([Vector2(-116, 5), Vector2(-119, -120), Vector2(-108, -144),
		Vector2(-71, -160), Vector2(52, -158), Vector2(105, -142), Vector2(119, -112), Vector2(117, 4)])
	c.draw_colored_polygon(edge, Color(stock.lerp(Color("365559"), 0.35), 0.22))
	for vein in range(11):
		var y := -143.0 + vein * 13.0
		c.draw_line(Vector2(-95, y), Vector2(91, y + sin(vein * 2.1) * 9), Color(warm, 0.035), 2.5, true)
	c.draw_polyline(edge, faded, 2.2, true)
	c.draw_polyline(PackedVector2Array([Vector2(-108, -116), Vector2(-98, -137), Vector2(-69, -150), Vector2(48, -149)]),
		Color(ink, 0.10), 1.0, true)
	for index in range(5):
		var start := Vector2(-84 + index * 29, -141 + index % 2 * 3)
		c.draw_line(start, start + Vector2(14 + index % 3 * 4, -1), Color(ink, 0.20), 1.7, true)
	var first := Vector2(-72, -91)
	var second := Vector2(-12, -112)
	var reply := Vector2(66, -88)
	var path := PackedVector2Array([Vector2(-100, -78), first, Vector2(-47, -103), second, Vector2(24, -103), reply, Vector2(103, -67)])
	for offset in [-5.0, 5.0]:
		var echo := PackedVector2Array()
		for point in path: echo.append(point + Vector2(0, offset))
		c.draw_polyline(echo, Color(ink, 0.11), 1, true)
	if heard:
		c.draw_polyline(path, cut, 1.4, true)
		_reveal_line(c, path, reveal, Color(warm, 0.84), 2.4)
		for index in range(3):
			var point: Vector2 = [first, second, reply][index]
			var presence := clampf(reveal * 3.0 - index, 0.0, 1.0)
			_rosette(c, point, warm.lerp(stock, 0.10), stock, 0.43 + presence * 0.52, true)
		# The response completes the old ornamental curl instead of producing
		# a loot marker. Its warmth belongs permanently to this particular stone.
		c.draw_arc(reply + Vector2(19, 0), 21, -PI * 0.72, PI * 0.59, 38, Color(warm, reveal * 0.42), 1.4, true)
		for index in range(5):
			var point := Vector2(30 + index * 15, -43 + sin(index * 1.6) * 7)
			var alpha := (0.23 + sin(clock * 0.6 + index) * 0.025) * reveal
			c.draw_line(point, point + Vector2(4, -3), Color(warm, alpha), 1.1, true)
	elif broken:
		c.draw_polyline(PackedVector2Array([path[0], path[1], Vector2(-37, -105)]), cut, 1.8, true)
		c.draw_polyline(PackedVector2Array([Vector2(23, -103), reply, path[6]]), faded, 1.5, true)
		c.draw_arc(first, 10, 0.0, 2.4, 19, cut, 1.4, true)
		c.draw_arc(second + Vector2(4, 5), 12, 2.2, 5.2, 23, cut, 1.7, true)
		c.draw_arc(reply, 10, 1.0, 3.4, 19, faded, 1.4, true)
		var split := PackedVector2Array([Vector2(-24, -151), Vector2(-17, -124), Vector2(-26, -103),
			Vector2(-8, -84), Vector2(-18, -64), Vector2(-2, -38)])
		c.draw_polyline(split, cut, 1.6, true)
		for index in range(5):
			var point := Vector2(-49 + index * 23, -34 + index % 2 * 8)
			c.draw_line(point, point + Vector2(5, -3), Color(ink, 0.25), 1.5, true)
	else:
		c.draw_polyline(PackedVector2Array([path[0], path[1], path[2], path[3], Vector2(22, -103)]), faded, 1.4, true)
		_rosette(c, first, cut, stock, 0.56, false)
		_rosette(c, second, cut, stock, 0.56, false)
		c.draw_arc(reply, 11, 0.3, PI * 1.3, 24, faded, 1.4, true)
		c.draw_line(Vector2(91, -77), Vector2(102, -67), faded, 1.4, true)
	for index in range(10):
		var x := -102.0 + index * 20.0
		c.draw_line(Vector2(x, -10 - index % 3 * 4), Vector2(x + 9, -14 - index % 3 * 4), Color(ink, 0.12), 1.0, true)
	c.draw_set_transform(Vector2.ZERO)

static func _call_marks(c: CanvasItem, stage: String, note: int, answer: float, ink: Color, stock: Color, warm: Color) -> void:
	var answering := stage == "answering"
	var completed_call := answering
	# A sliver of stock separates semantic marks from the engraved memory.
	c.draw_rect(Rect2(-46, -91, 98, 26), Color(stock, 0.93))
	for index in range(2):
		var point := Vector2(-27 + index * 23, -78)
		var active := completed_call or (stage in ["calling", "waiting"] and index <= note)
		c.draw_circle(point, 5.6, warm if active else stock, true, -1, true)
		c.draw_arc(point, 5.6, 0, TAU, 26, ink, 1.5, true)
		if active: c.draw_circle(point, 1.7, ink, true, -1, true)
	c.draw_line(Vector2(7, -78), Vector2(16, -78), Color(ink, 0.43), 1.1, true)
	var reply := Vector2(33, -78)
	var diamond := PackedVector2Array([reply + Vector2(0, -8), reply + Vector2(8, 0), reply + Vector2(0, 8), reply + Vector2(-8, 0), reply + Vector2(0, -8)])
	c.draw_polyline(diamond, warm if answering else ink.lerp(stock, 0.60), 2.2 if answering else 1.1, true)
	if answering:
		c.draw_line(reply + Vector2(-13, -4), reply + Vector2(-13, 4), ink, 1.4, true)
		c.draw_line(reply + Vector2(13, -4), reply + Vector2(13, 4), ink, 1.4, true)
		if answer > 0.0:
			c.draw_arc(reply, 4.0, -PI / 2, -PI / 2 + TAU * answer, 30, warm, 3.0, true)

static func _body_center(pose: Dictionary) -> Vector2:
	var clock := float(pose.get("clock", 0.0))
	var phase := String(pose.get("phase", "calm"))
	var face := float(pose.get("face", -1.0))
	var breath := sin(clock * 2.8)
	var walking := phase == "pursue" or phase == "reach"
	var lift := absf(cos(float(pose.get("stride", 0.0)))) * 1.8 if walking else breath * 1.4
	var reach := float(pose.get("reach", 0.0)) if phase == "reach" else 0.0
	var center := Vector2(face * (reach * reach * 8 - sin(reach * PI) * 3 - float(pose.get("recoil", 0.0)) * 8), -26 - lift)
	center += Vector2(pose.get("jitter", Vector2.ZERO))
	if phase == "recover": center.x += face * 7 * (1.0 - float(pose.get("recover", 0.0)))
	if phase == "freed":
		center = Vector2(sin(clock * 1.9) * 1.1, -28 - breath * 1.8 - (0.0 if bool(pose.get("held", false)) else float(pose.get("leave", 0.0)) * 18))
	return center

static func _rosette(c: CanvasItem, point: Vector2, color: Color, stock: Color, alpha: float, complete: bool) -> void:
	c.draw_circle(point, 4.0, Color(color, alpha), true, -1, true)
	c.draw_circle(point, 1.3, Color(stock, alpha), true, -1, true)
	for radius in [8.0, 12.0]:
		c.draw_arc(point, radius, -1.3, -1.3 + (TAU if complete else 4.6), 34, Color(color, alpha * 0.70), 1.2, true)

static func _reveal_line(c: CanvasItem, points: PackedVector2Array, progress: float, color: Color, width: float) -> void:
	if progress <= 0.0: return
	var exact := progress * (points.size() - 1)
	var count := mini(int(exact), points.size() - 1)
	var visible := PackedVector2Array()
	for index in range(count + 1): visible.append(points[index])
	if count < points.size() - 1: visible.append(points[count].lerp(points[count + 1], exact - count))
	if visible.size() >= 2: c.draw_polyline(visible, color, width, true)

static func _warm(stock: Color) -> Color:
	return Color("bd8c43") if stock.get_luminance() > 0.45 else Color("e8c078")
