extends RefCounted
## Skip's hood in the ink look (ink_look.gd): "a worn 45
## sleeve for a hood" (docs/CAST.md), drawn after the canon's LIFT pose
## (docs/art/direction.html, 02): a tall sleeve pulled up over him, its centre
## hole his face, its hem corners flicked out.
##
## Laws it keeps:
## - Hood up is silence: the sleeve takes the tone of the page it stands on,
##   its ink goes grey, and nothing on it is pink or gold.
## - Readable first: under it he is still found by its grey edge, the dark
##   face hole and the point stood beside it.
## - Presentation only: the pose decides, the sleeve never moves him.
##
## It goes up from behind. The folded sleeve rises off his back to over his
## head, then its front comes down across his face to the street; taking it
## off runs the same way back. Under it his boots show at the hem and shuffle
## when he walks, the hem flares when he jumps and falls, and one hand comes
## out of the sleeve's open side to hold the point. What is fitted shows on it:
## the Warm Thread's stitching and the Book's Sleeve slot.
##
## `shape` is pure: a pose and the body in, the sleeve's outline and face hole
## out, in Skip's space (feet on y = 26). `draw` inks it.

const Ink := preload("res://scripts/press_ink.gd")

## Where the sleeve sits when it is up, drawn facing right: its crown over his
## head, its hem just clear of the street so his boots show, and the hole
## where his face is.
const CROWN := Vector2(1, -54)
const HEM := 22.5
const HEM_WIDTH := 25.0
const FACE := Vector2(0.5, -20)
const FACE_RADIUS := 8.0
## Before it goes up it lies folded on his back.
const FOLDED := Vector2(-13, -4)
const FOLDED_FRONT := Vector2(-6, 6)
## The record's ring, worn into the paper round the hole.
const RING_WEAR := 17.5
## Every fitted Sleeve by item id (collection_catalog.gd, the Sleeve slot).
const LININGS := [&"", &"felt_cuff", &"silk_hood", &"padded_sleeve", &"stillwater_wrap", &"seam_lining"]

## The sleeve for this pose. `cover` is how far its front has come down over
## his face (the head draws narrower and the eyes go as it does); `open` is how
## much of the face hole shows.
static func shape(pose: Dictionary, body: Transform2D, side: float, turn := 1.0) -> Dictionary:
	var hood := clampf(float(pose.get("hood", 0.0)), 0.0, 1.0)
	var rise := smoothstep(0.0, 0.55, hood)
	var cover := smoothstep(0.35, 1.0, hood)
	var run := clampf(float(pose.get("run", 0.0)), 0.0, 1.0)
	var stride := float(pose.get("stride", 0.0))
	var air := clampf(float(pose.get("air", 0.0)), 0.0, 1.0)
	var vertical := clampf(float(pose.get("vertical", 0.0)), -1.0, 1.0)
	var flip := Vector2(side * turn, 1.0)
	# Falling, the hem billows up and out; rising, it trails in and down; a
	# landing spreads it.
	var falling := air * maxf(vertical, 0.0)
	var rising := air * maxf(-vertical, 0.0)
	var squash := sin(float(pose.get("land", 0.0)) * PI) * float(pose.get("impact", 0.0))
	var flare := 8.0 * falling - 4.0 * rising + 5.0 * squash
	var lift := 9.0 * falling - 3.0 * rising
	# Walking, each step pushes the hem from inside.
	var step := sin(stride) * run
	var back_hem := _hem(body, -(HEM_WIDTH + flare) * flip.x, lift + maxf(-step, 0.0) * 2.5)
	var front_hem := _hem(body, (HEM_WIDTH + flare) * flip.x, lift + maxf(step, 0.0) * 2.5)
	var crown := (body * (FOLDED * flip)).lerp(body * (CROWN * flip), rise)
	front_hem = (body * (FOLDED_FRONT * flip)).lerp(front_hem, cover)
	var up := (crown - (back_hem + front_hem) * 0.5).normalized()
	var across := Vector2(side, 0.0)
	if not up.is_zero_approx():
		across = up.orthogonal()
		if across.x * side < 0.0:
			across = -across
	# The outline, back hem first: a bowed back over his head, a rounded crown,
	# the front edge, the hem with a small tear near the back corner.
	var outline := PackedVector2Array()
	outline.append(back_hem)
	outline.append(back_hem.lerp(crown, 0.4) - across * 2.0)
	outline.append(back_hem.lerp(crown, 0.78) - across * 2.6)
	outline.append(crown - across * 2.6 - up * 0.4)
	outline.append(crown + up * 0.6)
	outline.append(crown + across * 2.4 - up * 0.6)
	outline.append(crown.lerp(front_hem, 0.32) + across * 1.4)
	outline.append(crown.lerp(front_hem, 0.66) + across * 0.8)
	outline.append(front_hem)
	var sag := Vector2(0.0, 0.8)
	outline.append(front_hem.lerp(back_hem, 0.34) + sag + Vector2(0.0, step * 1.2))
	outline.append(front_hem.lerp(back_hem, 0.68) + sag - Vector2(0.0, step * 1.2))
	var tear := front_hem.lerp(back_hem, 0.8)
	outline.append(tear)
	outline.append(tear + tear.direction_to(crown) * 3.2 - across * 0.6)
	outline.append(front_hem.lerp(back_hem, 0.88))
	# Where his arm comes out of the sleeve's open side, at the grip's height.
	var reach := clampf((FACE.y + 1.0 - CROWN.y) / (HEM - CROWN.y), 0.0, 1.0)
	return {
		"outline": outline, "crown": crown, "back_hem": back_hem, "front_hem": front_hem,
		"face": body * (FACE * flip), "radius": FACE_RADIUS, "cover": cover,
		"open": smoothstep(0.78, 1.0, cover), "opening": crown.lerp(front_hem, reach) + across * 1.0,
		"squeeze": lerpf(1.0, 0.4, smoothstep(0.45, 1.0, cover)), "hood": hood,
		"up": up, "across": across, "side": side, "step": step, "flare": maxf(flare, 0.0),
	}

## A hem corner: as far out as `x` from his feet, on the street line however
## he leans, lifted by `lift`.
static func _hem(body: Transform2D, x: float, lift: float) -> Vector2:
	return Vector2((body * Vector2(x, 26.0)).x, HEM - lift)

## A point on the sleeve: `u` from the crown (0) to the hem (1), `v` from the
## back edge (-1) to the front edge (1).
static func at(s: Dictionary, u: float, v: float) -> Vector2:
	var crown: Vector2 = s.crown
	var back := crown.lerp(s.back_hem, u)
	var front := crown.lerp(s.front_hem, u)
	return back.lerp(front, (v + 1.0) * 0.5)

# == drawing ===========================================================================

## The sleeve, over Skip. `c` is the figure palette (press_ink_figures.colours());
## `dress` may hold "warm_thread" and the fitted Sleeve as "lining".
static func draw(k: Ink, s: Dictionary, pose: Dictionary, c: Dictionary, frame: int, dress: Dictionary) -> void:
	var outline: PackedVector2Array = _boil(s.outline, frame, 120, 0.45)
	if Geometry2D.triangulate_polygon(outline).is_empty():
		outline = s.outline
		if Geometry2D.triangulate_polygon(outline).is_empty():
			return
	var line: Color = c.hood_line
	var side := float(s.side)
	k.fill(outline, c.hood)
	# The shadowed third, hatched, and the fold down his middle.
	for piece in k.shadow_side(outline, Vector2(-side, -1.0), 0.38):
		k.hatch(piece, -PI * 0.25 if side > 0.0 else -PI * 0.75, 3.0, 0.8, Color(line, 0.55))
	var fold := PackedVector2Array([at(s, 0.08, -0.05), at(s, 0.5, -0.2), at(s, 1.0, -0.12)])
	k.stroke(fold, 1.0, Color(line, 0.6), 0.3, 0.2, 0.2, 100.0)
	k.stroke(_shifted(fold, Vector2(side * 1.3, 0.0)), 0.8, Color(c.paper, 0.55), 0.3, 0.3, 0.2, 100.0)
	# Creases from being folded on his back (the canon's three).
	for crease: Array in [[0.74, -0.55, 0.62, -0.18], [0.44, -0.62, 0.36, -0.36], [0.6, 0.38, 0.68, 0.72]]:
		var a := at(s, float(crease[0]), float(crease[1]))
		var b := at(s, float(crease[2]), float(crease[3]))
		k.hair(a, b, 1.1, Color(line, 0.7))
		k.hair(a + Vector2(0.0, 1.1), b + Vector2(0.0, 1.1), 0.7, Color(c.paper, 0.6))
	var open := float(s.open)
	var face: Vector2 = s.face
	if open > 0.0:
		_ring_wear(k, s, outline, c, open)
		_print(k, s, c, open)
	_lining(k, s, outline, c, StringName(dress.get("lining", &"")), frame)
	if bool(dress.get("warm_thread", false)):
		_warm_thread(k, s, c)
	# A strip of cassette tape holding a split in the back edge together.
	var mend := at(s, 0.46, -0.93)
	var along: Vector2 = Vector2(s.crown).direction_to(s.back_hem)
	var tape := PackedVector2Array([mend - along * 1.3 - Vector2(s.across) * 2.4, mend + along * 1.3 - Vector2(s.across) * 2.4,
		mend + along * 1.3 + Vector2(s.across) * 3.4, mend - along * 1.3 + Vector2(s.across) * 3.4])
	k.fill(tape, c.tape)
	k.hair(tape[0].lerp(tape[3], 0.2), tape[1].lerp(tape[2], 0.2), 0.5, Color(c.tape_shine, 0.8))
	# The edge: grey ink, heavy, hem corners flicked out like the canon's.
	k.outline(outline, 2.2, line, 0.25, 0.5, false)
	var back_hem: Vector2 = s.back_hem
	var front_hem: Vector2 = s.front_hem
	for corner: Array in [[back_hem, -1.0], [front_hem, 1.0]]:
		var at_corner: Vector2 = corner[0]
		var out := float(corner[1]) * side
		var flick := PackedVector2Array([at_corner, at_corner + Vector2(out * 3.4, -2.0), at_corner + Vector2(out * 5.0, -5.6 - float(s.flare) * 0.3)])
		k.stroke(flick, 1.5, line, 0.0, 0.0, 0.4, 100.0)
	for i in 4:
		# Frayed paper at the hem.
		var fibre := front_hem.lerp(back_hem, 0.18 + i * 0.19) + Vector2(0.0, 0.8)
		k.hair(fibre, fibre + Vector2(sin(i * 2.3) * 1.2, 1.6), 0.6, Color(line, 0.6))
	# The hole: his face, two pinpricks for eyes. They blink and look, quietly.
	if open > 0.0:
		var hole := k.ellipse_points(face, Vector2.ONE * float(s.radius), 0.0, 16)
		hole = _boil(hole, frame, 130, 0.3)
		k.fill(hole, Color(c.body, open))
		k.outline(hole, 1.6, Color(line, open), 0.15, 0.0, false)
		var time := float(pose.get("time", 0.0))
		var blink := clampf(1.0 - absf(fmod(time, 4.7) - 4.43) / 0.085, 0.0, 1.0)
		var look := Vector2(side * 0.9, 0.3) + Vector2(sin(time * 0.7) * 0.6, 0.0)
		for eye_side: float in [-1.0, 1.0]:
			var eye := face + look + Vector2(eye_side * 2.7, -0.6)
			if blink > 0.5:
				k.hair(eye - Vector2(1.3, 0.0), eye + Vector2(1.3, 0.0), 0.9, Color(c.eye, open))
			else:
				k.blob(eye, 1.15, Color(c.eye, open), 5)

## Ring wear: the record's outline rubbed into the paper round the hole, in
## pieces where the wear is uneven.
static func _ring_wear(k: Ink, s: Dictionary, outline: PackedVector2Array, c: Dictionary, open: float) -> void:
	var face: Vector2 = s.face
	for arc: Array in [[-2.5, -0.9, RING_WEAR], [-0.55, 1.2, RING_WEAR], [1.65, 2.75, RING_WEAR], [-2.2, -1.2, 11.5], [0.2, 1.4, 11.5]]:
		var points := PackedVector2Array()
		for i in 10:
			var a := lerpf(float(arc[0]), float(arc[1]), i / 9.0)
			points.append(face + Vector2(cos(a), sin(a) * 0.96) * float(arc[2]))
		for piece in Geometry2D.intersect_polyline_with_polygon(points, outline):
			var widths := PackedFloat32Array()
			for i in piece.size():
				widths.append(1.9 if float(arc[2]) > 12.0 else 1.1)
			k.ribbon(piece, widths, Color(c.paper, 0.55 * open))

## The sleeve's print, rubbed half away: a big 45 under the hole.
static func _print(k: Ink, s: Dictionary, c: Dictionary, open: float) -> void:
	var ink := Color(c.hood_line, 0.32 * open)
	var origin := at(s, 0.74, 0.0)
	var size := 1.25
	var four := [[Vector2(-1.2, -4.5), Vector2(-4.4, 1.0), Vector2(0.6, 1.0)], [Vector2(-0.5, -4.5), Vector2(-0.5, 4.5)]]
	var five := [[Vector2(5.0, -4.5), Vector2(2.0, -4.5), Vector2(1.6, -0.6)], [Vector2(1.6, -0.6), Vector2(4.6, -0.4), Vector2(5.2, 2.6), Vector2(3.4, 4.6), Vector2(1.2, 4.0)]]
	var strokes: Array = four + five
	for i in strokes.size():
		var stroke := PackedVector2Array()
		for v: Vector2 in strokes[i]:
			stroke.append(origin + v * size)
		if i == strokes.size() - 1:
			# The 5's belly, rubbed off where his hip wears it.
			stroke = stroke.slice(0, 3)
		k.stroke(stroke, 1.7, ink, 0.2, 0.15, 0.4, 100.0)

## The Warm Thread (economy_state.gd): a little amber running stitch up the
## back edge and along the hem.
static func _warm_thread(k: Ink, s: Dictionary, c: Dictionary) -> void:
	for i in 22:
		var u := 0.12 + i * 0.037
		k.hair(at(s, u, -0.84), at(s, u + 0.022, -0.84), 1.2, c.thread)
	for i in 20:
		var v := -0.84 + i * 0.086
		k.hair(at(s, 0.93, v), at(s, 0.93, v + 0.05), 1.2, c.thread)

## The fitted Sleeve, from the Book's Sleeve slot: each lining shows a little.
static func _lining(k: Ink, s: Dictionary, outline: PackedVector2Array, c: Dictionary, lining: StringName, frame: int) -> void:
	var line: Color = c.hood_line
	match lining:
		&"felt_cuff":
			# A felt band round the hem, its top edge fuzzy.
			var band := PackedVector2Array([at(s, 0.88, -1.0), at(s, 0.88, 1.0), s.front_hem, s.back_hem])
			k.fill(band, Color(c.felt, 0.95))
			for i in 16:
				var fuzz := at(s, 0.88, -0.95 + i * 0.125)
				k.hair(fuzz, fuzz + Vector2(sin(i * 1.7) * 0.8, -1.6), 0.7, Color(c.felt, 0.9))
		&"silk_hood":
			# A silk lining: it shows round the hole and runs light down the front.
			if float(s.open) > 0.0:
				var ring := k.ellipse_points(s.face, Vector2.ONE * (float(s.radius) + 2.2), 0.0, 18)
				ring.append(ring[0])
				k.stroke(ring, 1.6, Color(c.silk, float(s.open)), 0.0, 0.0, 1.0, 100.0)
			for lane: float in [0.35, 0.62]:
				var sheen := PackedVector2Array([at(s, 0.2, lane), at(s, 0.55, lane - 0.05), at(s, 0.9, lane - 0.1)])
				k.stroke(sheen, 1.5, Color(c.silk, 0.55), 0.2, 0.4, 0.2, 100.0)
		&"padded_sleeve":
			# Quilted packing, stitched in diamonds.
			for direction: float in [PI * 0.25, -PI * 0.25]:
				k.hatch(outline, direction, 7.0, 0.7, Color(line, 0.45))
		&"stillwater_wrap":
			# Heavy quiet cloth wound round his middle, its end hanging.
			var wrap := PackedVector2Array([at(s, 0.58, -1.0), at(s, 0.5, 1.0), at(s, 0.64, 1.0), at(s, 0.72, -1.0)])
			k.fill(wrap, Color(c.wrap, 0.88))
			k.outline(wrap, 1.2, line, 0.1, 0.3, false)
			var end := at(s, 0.57, 1.0)
			var tail := PackedVector2Array([end, end + Vector2(float(s.side) * 3.0, 6.0), end + Vector2(float(s.side) * 2.0, 12.0)])
			k.stroke(_boil(tail, frame, 140, 0.4), 2.4, Color(c.wrap, 0.9), 0.0, 0.0, 0.5, 100.0)
		&"seam_lining":
			# The sleeve's folded seam turned out down the back, cross-stitched.
			var seam := PackedVector2Array()
			for i in 9:
				seam.append(at(s, 0.1 + i * 0.1, -0.72))
			k.stroke(seam, 1.1, Color(line, 0.8), 0.1, 0.1, 0.4, 100.0)
			for i in seam.size():
				var tick: Vector2 = Vector2(s.across) * 1.6
				k.hair(seam[i] - tick, seam[i] + tick, 0.8, Color(line, 0.75))

static func _boil(points: PackedVector2Array, frame: int, salt: int, amount: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in points.size():
		var seed_value := float(i * 7 + salt * 131 + frame * 977)
		result.append(points[i] + Vector2(sin(seed_value * 12.9898), cos(seed_value * 78.233)) * amount)
	return result

static func _shifted(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point + by)
	return result
