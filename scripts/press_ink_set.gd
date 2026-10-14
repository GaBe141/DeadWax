extends RefCounted
## The set kit for the ink look (ink_look.gd): the pieces every room is built
## from, in the canon's detail language (docs/art/direction.html, density
## target). Brick courses, weather and damp, windows, posters, crates,
## barrels, tapes, lanterns, benches, carts, a washing line; and the ground
## itself: street slabs on a walking edge, the earth cut away beneath it,
## archways and doorways for the passages. Horn Plaza (press_ink_plaza.gd)
## composes its square from these by hand; every other room
## (press_ink_room.gd) is composed from them by its own geometry.
##
## Pure drawing: every piece takes its ink kit, its palette and its place,
## and reads no clock, camera, collision or game state.

const Ink := preload("res://scripts/press_ink.gd")
const InkLook := preload("res://scripts/ink_look.gd")

## Light comes from the upper left; hatching rises to the right.
const LIGHT := Vector2(-1.0, -1.25)
const HATCH := -PI * 0.25

## The page's working colours on either face: ink on label paper, or the
## same drawing reversed out of wax (scratchboard).
static func palette(scratchboard: bool) -> Dictionary:
	var p := {
		"paper": InkLook.LABEL_PAPER, "ink": InkLook.LINE, "deep": InkLook.WAX,
		"stone": InkLook.STONE, "dust": InkLook.DUST, "brass": InkLook.BRASS,
		"umber": InkLook.UMBER, "red": InkLook.CANCEL_RED, "light": InkLook.GROOVE,
		"patina": Color("6f7d69"), "wood": Color("8a6440"), "slate": Color("5b5560"),
	}
	if scratchboard:
		p = {
			"paper": InkLook.WAX, "ink": InkLook.GROOVE, "deep": Color("050407"),
			"stone": Color("26222b"), "dust": Color("1d1a22"), "brass": Color("4a3a28"),
			"umber": Color("2a2430"), "red": Color("5c2b23"), "light": Color("d9d3c7"),
			"patina": Color("33403a"), "wood": Color("33281f"), "slate": Color("2b2832"),
		}
	p["hatch"] = Color(p.ink, 0.5)
	p["soft"] = Color(p.ink, 0.22)
	p["grime"] = Color(p.ink, 0.16)
	p["shade"] = p.paper.lerp(p.ink, 0.07)
	return p

# == the ground ========================================================================

## Street slabs along the top of a surface, the walking edge the heaviest
## line in the room, and bedding sand under them.
static func slabs(k: Ink, p: Dictionary, top: Rect2, thickness := 21.0) -> void:
	var ground := top.position.y
	var x := top.position.x
	while x < top.end.x:
		var width := minf(k.rand(42, 78), top.end.x - x)
		if width < 8.0:
			break
		var slab := k.rough_rect(Rect2(x + 1.5, ground + 1, width - 3, thickness), 0.7)
		k.fill(slab, p.stone.lerp(p.dust, k.rand(0.0, 0.55)))
		k.shade(slab, LIGHT, 0.3, 3.4, 0.8, Color(p.ink, 0.35))
		k.flecks_in(slab, int(width / 9.0), p.grime, 0.9)
		k.outline(slab, 1.3, Color(p.ink, 0.8), 0.3, 0.6)
		if k.chance(0.25) and width > 20.0:
			k.crack(Vector2(x + k.rand(8, width - 8), ground + 2), Vector2(k.rand(-0.4, 0.4), 1), minf(16.0, thickness - 4.0), 0.9, Color(p.ink, 0.7), 1)
		x += width
	k.stroke(PackedVector2Array([Vector2(top.position.x, ground), Vector2(top.end.x, ground)]), 3.6, p.ink, 0.7, 0.0, 1.0, 9.0)
	if top.size.y > thickness + 10.0:
		k.stipple(k.rect_points(Rect2(top.position.x, ground + thickness + 2, top.size.x, minf(16.0, top.size.y - thickness - 2))), int(top.size.x / 4.5), Color(p.ink, 0.35), 0.8)
		k.stroke(PackedVector2Array([Vector2(top.position.x, ground + thickness + 18), Vector2(top.end.x, ground + thickness + 18)]), 1.4, Color(p.ink, 0.55), 1.4, 0.0, 1.0, 12.0)

## A ledge: a stone slab with a lipped edge, hatched underneath, that stands
## free of the ground (a platform in the air).
static func ledge(k: Ink, p: Dictionary, box: Rect2, worn := 0.5, brackets := true) -> void:
	var slab := k.rough_rect(box, 1.0)
	k.fill(slab, p.stone.lerp(p.dust, 0.35 * worn))
	k.hatch(slab, HATCH, 5.0, 0.8, Color(p.ink, 0.12), 0.8)
	k.shade(slab, LIGHT, 0.45, 3.6, 0.9, Color(p.ink, 0.42))
	k.flecks_in(slab, int(box.size.x * box.size.y / 260.0), p.grime, 1.0)
	# Joints across the face.
	var x := box.position.x + k.rand(30, 70)
	while x < box.end.x - 12.0:
		k.hair(Vector2(x, box.position.y + 2), Vector2(x + k.rand(-2, 2), box.end.y - 2), 0.9, Color(p.ink, 0.5))
		x += k.rand(44, 96)
	if k.chance(0.6):
		k.crack(Vector2(box.position.x + k.rand(0.2, 0.8) * box.size.x, box.position.y + 2), Vector2(k.rand(-0.3, 0.3), 1), minf(box.size.y - 6.0, 26.0), 0.9, Color(p.ink, 0.6), 1)
	k.outline(slab, 2.4, p.ink, 0.4, 1.0)
	k.stroke(PackedVector2Array([box.position, Vector2(box.end.x, box.position.y)]), 3.2, p.ink, 0.6, 0.0, 1.0, 10.0)
	if not brackets:
		return
	# Iron brackets under it, one at each end.
	for bracket: float in [box.position.x + 18.0, box.end.x - 18.0]:
		var iron := PackedVector2Array([Vector2(bracket - 5.0, box.end.y), Vector2(bracket + 5.0, box.end.y), Vector2(bracket + 5.0, box.end.y + 22.0), Vector2(bracket - 5.0, box.end.y + 30.0)])
		k.shape(iron, p.slate, p.ink, 1.6)
		k.hair(Vector2(bracket - 5.0, box.end.y + 30.0), Vector2(bracket - 24.0, box.end.y + 2.0), 1.4, p.ink)

## The earth cut away under a street: strata, grit, pebbles and the long
## cracks of the dust the Overture begins in.
static func strata(k: Ink, p: Dictionary, earth: Rect2) -> void:
	k.fill(k.rect_points(earth), p.dust, 0.0)
	var bands := maxi(int(earth.size.y / 26.0), 1)
	for band in bands:
		var y := earth.position.y + 30 + band * 26 + k.rand(-4, 4)
		if y > earth.end.y - 8:
			break
		var points := PackedVector2Array()
		var phase := k.rand(0.0, TAU)
		var steps := maxi(int(earth.size.x / 48.0), 2)
		for i in steps + 1:
			var x := earth.position.x + i * earth.size.x / steps
			points.append(Vector2(x, y + sin(i * 0.7 + phase) * 4.0 + k.rand(-1.5, 1.5)))
		k.stroke(points, 1.0, Color(p.ink, 0.22 + band * 0.03), 0.6, 0.05, 0.4, 16.0)
	for i in int(earth.size.x * earth.size.y / 1900.0):
		var at := Vector2(k.rand(earth.position.x + 6, earth.end.x - 6), k.rand(earth.position.y + 22, earth.end.y - 6))
		var radius := k.rand(1.5, 4.5)
		var stone := k.ellipse_points(at, Vector2(radius * k.rand(1.0, 1.6), radius), k.rand(-0.4, 0.4), 7)
		k.fill(stone, p.stone.lerp(p.dust, k.rand(0.2, 0.7)))
		k.outline(stone, 0.9, Color(p.ink, 0.42), 0.2, 0.3)
	k.flecks(earth, int(earth.size.x * earth.size.y / 1000.0), Color(p.ink, 0.3), 1.0)
	for i in int(earth.size.x / 110.0):
		k.crack(Vector2(k.rand(earth.position.x, earth.end.x), earth.position.y + k.rand(0.3, 0.7) * earth.size.y), Vector2(k.rand(-0.3, 0.3), 1), k.rand(30, 90), 1.0, Color(p.ink, 0.5), 2)

## A thing the ground lost: a tape, a bone, or a broken pressing, buried in
## the earth beside the cut.
static func buried(k: Ink, p: Dictionary, at: Vector2, which: int) -> void:
	match which % 3:
		0:
			tape(k, p, at, 0.9, k.rand(-0.4, 0.4))
		1:
			# A bone the Hound buried.
			var tilt := k.rand(-0.3, 0.3)
			var a := at + Vector2(-16, 0).rotated(tilt)
			var b := at + Vector2(16, 0).rotated(tilt)
			k.line(a, b, 4.0, p.light, 0.1, 0.0)
			for end in [a, b]:
				for side: float in [-1.0, 1.0]:
					k.blob(end + Vector2(0, side * 3.5).rotated(tilt), 3.2, p.light, 6)
			k.path(PackedVector2Array([a, b]), 1.2, Color(p.ink, 0.7), 0.2)
		_:
			# Half a pressing, edge on in the dirt.
			var half := PackedVector2Array()
			for i in 9:
				var angle := PI + PI * i / 8.0
				half.append(at + Vector2(cos(angle) * 18.0, sin(angle) * 18.0 * 0.4))
			k.shape(half, p.deep, p.ink, 1.4)
			k.hair(at + Vector2(-12, -2), at + Vector2(12, -2), 0.8, Color(p.light, 0.5))

# == walls =============================================================================

## A brick wall: flat, hatched on its shadowed side, courses, weather and
## rising damp at its foot.
static func wall(k: Ink, p: Dictionary, area: Rect2, strength := 0.5, damp_height := 40.0) -> void:
	var face := k.rough_rect(area, 1.0)
	k.fill(face, p.paper.lerp(p.dust, 0.25))
	k.hatch(face, HATCH + 0.12, 6.5, 0.7, Color(p.ink, 0.07), 0.85)
	bricks(k, p, area, 10.0, 24.0, strength)
	k.shade(face, LIGHT, 0.3, 4.2, 0.8, p.hatch)
	weather(k, p, area, maxi(int(area.size.x / 180.0), 1))
	if damp_height > 0.0 and area.size.y > damp_height + 10.0:
		damp(k, p, Rect2(area.position.x, area.end.y - damp_height, area.size.x, damp_height))
	k.sketch(face, 3.4, p.ink)

## A papered wall inside: a flat tint, a faint pattern, a dado rail and the
## wear of years at its foot.
static func papered_wall(k: Ink, p: Dictionary, area: Rect2, seed_value: int) -> void:
	var face := k.rough_rect(area, 0.8)
	k.fill(face, p.paper.lerp(p.red, 0.06).lerp(p.dust, 0.2))
	k.hatch(face, HATCH + 0.2, 7.0, 0.6, Color(p.ink, 0.05), 0.9)
	# The pattern: a drop repeat of small marks.
	var step := 26.0
	var y := area.position.y + 10
	var row := 0
	while y < area.end.y - 10:
		var x := area.position.x + 8 + (step * 0.5 if row % 2 == 1 else 0.0)
		while x < area.end.x - 8:
			if (int(x) + seed_value) % 3 != 0:
				k.hair(Vector2(x - 3, y), Vector2(x + 3, y + 1), 0.8, Color(p.ink, 0.16))
				k.hair(Vector2(x, y - 3), Vector2(x + 1, y + 3), 0.8, Color(p.ink, 0.13))
			x += step
		y += step
		row += 1
	# A dado rail a third of the way up, and a soiled band under it.
	var dado := area.position.y + area.size.y * 0.62
	k.line(Vector2(area.position.x, dado), Vector2(area.end.x, dado), 2.2, p.umber, 0.3, 0.0)
	k.line(Vector2(area.position.x, dado + 3), Vector2(area.end.x, dado + 3), 0.9, Color(p.ink, 0.5), 0.3, 0.0)
	k.shade(face, LIGHT, 0.26, 4.4, 0.8, Color(p.ink, 0.32))
	weather(k, p, area, maxi(int(area.size.x / 260.0), 1), 0.12)
	damp(k, p, Rect2(area.position.x, area.end.y - 32, area.size.x, 32))
	k.sketch(face, 3.0, p.ink)

## Cut rock: a vault wall underground, its strata drawn in long hatched
## courses, seams and the drip of water.
static func rock(k: Ink, p: Dictionary, area: Rect2, seed_value: int) -> void:
	var face := k.rough_rect(area, 2.0)
	k.fill(face, p.paper.lerp(p.umber, 0.16).lerp(p.dust, 0.25))
	k.hatch(face, HATCH, 5.5, 0.8, Color(p.ink, 0.14), 0.9)
	var y := area.position.y + k.rand(20, 50)
	var course := 0
	while y < area.end.y - 12:
		var seam := PackedVector2Array()
		var steps := maxi(int(area.size.x / 40.0), 2)
		for i in steps + 1:
			var x := area.position.x + i * area.size.x / steps
			seam.append(Vector2(x, y + sin(i * 0.9 + course + seed_value) * 5.0 + k.rand(-2, 2)))
		k.stroke(seam, 1.6, Color(p.ink, 0.6), 0.8, 0.05, 0.5, 12.0)
		# Blocks between the seams, a few picked out.
		var x := area.position.x + k.rand(0, 40)
		while x < area.end.x - 10:
			var run := k.rand(50, 130)
			if k.chance(0.5):
				k.hair(Vector2(x, y + 2), Vector2(x + k.rand(-3, 3), minf(y + k.rand(34, 60), area.end.y - 2)), 1.0, Color(p.ink, 0.5))
			if k.chance(0.12):
				var block := k.rough_rect(Rect2(x + 2, y + 3, minf(run - 4, area.end.x - x - 4), 28), 0.8)
				k.crosshatch(block, HATCH, 4.0, 0.7, Color(p.ink, 0.3))
			x += run
		y += k.rand(40, 64)
		course += 1
	k.shade(face, LIGHT, 0.35, 4.0, 0.9, Color(p.ink, 0.4))
	for i in maxi(int(area.size.x / 150.0), 1):
		k.streak(Vector2(area.position.x + k.rand(0.05, 0.95) * area.size.x, area.position.y + k.rand(0.0, 0.3) * area.size.y), k.rand(40, 120), 1.6, Color(p.ink, 0.2))
	weather(k, p, area, maxi(int(area.size.x / 140.0), 2))
	k.sketch(face, 3.6, p.ink)

## Cut wax, below the Scratch: the groove walls themselves, drawn in the long
## parallel lines of a record's face, with the gouges of the cut.
static func wax_face(k: Ink, p: Dictionary, area: Rect2, seed_value: int) -> void:
	var face := k.rough_rect(area, 1.5)
	k.fill(face, p.paper.lerp(p.dust, 0.3))
	var y := area.position.y + 4
	var row := 0
	while y < area.end.y - 2:
		var groove := PackedVector2Array()
		var steps := maxi(int(area.size.x / 30.0), 2)
		for i in steps + 1:
			var x := area.position.x + i * area.size.x / steps
			groove.append(Vector2(x, y + sin(i * 0.5 + row * 0.3 + seed_value) * 1.4))
		k.stroke(groove, 0.9 if row % 4 != 0 else 1.6, Color(p.ink, 0.18 if row % 4 != 0 else 0.42), 0.3, 0.02, 0.4, 10.0)
		y += k.rand(7, 11)
		row += 1
	for i in maxi(int(area.size.x * area.size.y / 40000.0), 2):
		var from := area.position + Vector2(k.rand(0.05, 0.95) * area.size.x, k.rand(0.05, 0.8) * area.size.y)
		k.crack(from, Vector2(k.rand(-0.8, 0.8), 1.0), k.rand(30, 110), 1.6, Color(p.ink, 0.75), 2)
	k.shade(face, LIGHT, 0.3, 4.0, 0.9, Color(p.ink, 0.3))
	k.flecks(area, int(area.size.x * area.size.y / 700.0), Color(p.ink, 0.25), 1.0)
	k.sketch(face, 3.6, p.ink)

# == passages ==========================================================================

## An archway through a wall: voussoirs, a keystone, jambs, the way beyond
## receding in hatching, and the passage's name on a plate over it.
static func archway(k: Ink, p: Dictionary, at: Vector2, inner := 31.0, label := "") -> void:
	var ground := at.y
	var center := Vector2(at.x, ground - 78)
	var outer := inner + 9.0
	var opening := PackedVector2Array()
	opening.append(Vector2(at.x - inner, ground))
	for i in 17:
		opening.append(center + Vector2.from_angle(PI + PI * i / 16.0) * inner)
	opening.append(Vector2(at.x + inner, ground))
	k.fill(opening, p.deep.lerp(p.paper, 0.12))
	var beyond := PackedVector2Array([Vector2(at.x - 14, ground), Vector2(at.x - 10, ground - 52), Vector2(at.x + 10, ground - 52), Vector2(at.x + 14, ground)])
	k.fill(beyond, p.paper.lerp(p.dust, 0.5))
	k.hatch(beyond, HATCH, 3.0, 0.7, Color(p.ink, 0.35))
	k.line(Vector2(at.x - 10, ground - 52), Vector2(at.x + 10, ground - 52), 1.4, p.ink, 0.2, 0.0)
	for i in 7:
		var angle := PI + PI * (i + 0.5) / 7.0
		var a := center + Vector2.from_angle(angle) * inner
		var b := center + Vector2.from_angle(angle) * outer
		var c := center + Vector2.from_angle(angle + PI / 7.0) * outer
		var d := center + Vector2.from_angle(angle + PI / 7.0) * inner
		var voussoir := PackedVector2Array([a, b, c, d])
		k.fill(voussoir, p.stone.lerp(p.dust, k.rand(0.1, 0.5)))
		k.outline(voussoir, 1.5, p.ink, 0.3, 0.6)
	var key := PackedVector2Array([center + Vector2(-7, -inner + 2), center + Vector2(-9, -outer - 6), center + Vector2(9, -outer - 6), center + Vector2(7, -inner + 2)])
	k.shape(key, p.stone, p.ink, 2.0)
	for side: float in [-1.0, 1.0]:
		var jamb := k.rough_rect(Rect2(at.x + side * (inner + 4.5) - 4.5, center.y, 9, ground - center.y), 0.6)
		k.shape(jamb, p.stone.lerp(p.dust, 0.4), p.ink, 1.8)
	if not label.is_empty():
		var width := maxf(float(label.length()) * 8.5 + 16.0, 64.0)
		var plate := k.rough_rect(Rect2(at.x - width * 0.5, center.y - outer - 32, width, 22), 0.6)
		k.shape(plate, p.umber, p.ink, 2.0)
		k.text(p.display, Vector2(at.x - width * 0.5 + 7, center.y - outer - 15), label, 14, p.light)

## A doorway in a wall: the frame and the step, with the door itself left to
## the passage (press_ink_figures.gd draws it, open or sealed). A name plate
## beside it, and a bell.
static func doorway(k: Ink, p: Dictionary, at: Vector2, label := "") -> void:
	var ground := at.y
	var frame := k.rough_rect(Rect2(at.x - 34, ground - 102, 68, 102), 0.6)
	k.fill(frame, p.umber)
	k.outline(frame, 2.4, p.ink)
	var dark := k.rect_points(Rect2(at.x - 27, ground - 70, 54, 70))
	k.fill(dark, p.deep.lerp(p.paper, 0.15))
	var fanlight := k.rough_rect(Rect2(at.x - 22, ground - 96, 44, 20), 0.4)
	k.fill(fanlight, p.deep.lerp(p.paper, 0.3))
	for i in 3:
		k.hair(Vector2(at.x, ground - 76), Vector2(at.x - 18 + i * 18, ground - 95), 0.9, Color(p.ink, 0.7))
	k.outline(fanlight, 1.6, p.ink, 0.2, 0.3)
	var step := k.rough_rect(Rect2(at.x - 40, ground - 7, 80, 7), 0.5)
	k.shape(step, p.stone, p.ink, 1.8)
	k.blob(Vector2(at.x + 40, ground - 60), 2.2, p.brass)
	k.outline(k.ellipse_points(Vector2(at.x + 40, ground - 60), Vector2(3.5, 3.5), 0.0, 8), 1.0, p.ink, 0.1, 0.0)
	if not label.is_empty():
		var width := maxf(float(label.length()) * 7.0 + 14.0, 48.0)
		var plate := k.rough_rect(Rect2(at.x - width * 0.5, ground - 128, width, 18), 0.5)
		k.shape(plate, p.light, p.ink, 1.4)
		k.text(p.body, Vector2(at.x - width * 0.5 + 6, ground - 115), label, 10, p.ink)

## A cut in the rock or the wax for a passage, with a lintel of rougher stone
## and the way beyond going dark.
static func cut(k: Ink, p: Dictionary, at: Vector2, label := "") -> void:
	var ground := at.y
	var opening := PackedVector2Array([Vector2(at.x - 30, ground), Vector2(at.x - 34, ground - 60), Vector2(at.x - 22, ground - 92),
		Vector2(at.x + 6, ground - 100), Vector2(at.x + 30, ground - 86), Vector2(at.x + 33, ground - 40), Vector2(at.x + 29, ground)])
	k.fill(opening, p.deep.lerp(p.paper, 0.1))
	var beyond := PackedVector2Array([Vector2(at.x - 12, ground), Vector2(at.x - 9, ground - 48), Vector2(at.x + 9, ground - 48), Vector2(at.x + 12, ground)])
	k.fill(beyond, p.paper.lerp(p.dust, 0.55))
	k.hatch(beyond, HATCH, 3.0, 0.7, Color(p.ink, 0.4))
	k.crosshatch(opening, HATCH, 4.0, 0.8, Color(p.ink, 0.22))
	k.outline(opening, 3.0, p.ink, 0.8, 1.6)
	for i in 4:
		var from := Vector2(at.x - 36 + i * 24, ground - 100)
		k.crack(from, Vector2(k.rand(-0.6, 0.6), -1.0), k.rand(14, 36), 1.1, Color(p.ink, 0.6), 1)
	if not label.is_empty():
		k.text(p.display, Vector2(at.x - float(label.length()) * 4.2, ground - 112), label, 13, Color(p.ink, 0.85), k.rand(-0.04, 0.04))

# == shared pieces ===========================================================================

## Brick courses drawn the way a hand draws them: every course, joints here
## and there, a few bricks picked out darker.
static func bricks(k: Ink, p: Dictionary, area: Rect2, course: float, brick: float, strength: float) -> void:
	var y := area.position.y + course
	var row := 0
	while y < area.end.y - 2:
		var line_paint := Color(p.ink, 0.3 * strength + 0.08)
		var x := area.position.x
		while x < area.end.x:
			var run := minf(k.rand(40, 120), area.end.x - x)
			if k.chance(0.82):
				k.hair(Vector2(x, y + k.rand(-0.5, 0.5)), Vector2(x + run, y + k.rand(-0.5, 0.5)), 0.8, line_paint)
			x += run + k.rand(2, 10)
		var joint := area.position.x + (brick * 0.5 if row % 2 == 1 else 0.0) + k.rand(0, 3)
		while joint < area.end.x:
			if k.chance(0.7):
				k.hair(Vector2(joint, y - course + 1), Vector2(joint, y - 1), 0.8, line_paint)
			if k.chance(0.06 * strength + 0.02):
				var face := k.rough_rect(Rect2(joint + 1, y - course + 1.5, minf(brick - 2, area.end.x - joint - 1), course - 2.5), 0.4)
				if Ink.bounds(face).size.x > 3:
					k.fill(face, Color(p.umber, k.rand(0.08, 0.2)))
			joint += brick
		y += course
		row += 1
	k.flecks(area, int(area.size.x * area.size.y / 900.0), p.grime, 1.0)

## Years on a wall: blotches, a crack or two, soot settled under ledges.
static func weather(k: Ink, p: Dictionary, area: Rect2, cracks := 2, density := 1.0) -> void:
	for i in maxi(int(area.size.x * area.size.y * density / 9000.0), 2):
		var at := area.position + Vector2(k.rand(0.1, 0.9) * area.size.x, k.rand(0.1, 0.9) * area.size.y)
		k.stain(at, k.rand(10, 26), Color(p.umber, k.rand(0.04, 0.08)), k.chance(0.4))
	for i in cracks:
		var from := area.position + Vector2(k.rand(0.05, 0.95) * area.size.x, k.rand(0.0, 0.4) * area.size.y)
		k.crack(from, Vector2(k.rand(-0.5, 0.5), 1.0), k.rand(18, 40), 1.0, Color(p.ink, 0.7), 1)

## Rising damp: a soiled band along the foot of a wall, ragged at its top.
static func damp(k: Ink, p: Dictionary, band: Rect2) -> void:
	var edge := PackedVector2Array()
	var steps := maxi(int(band.size.x / 14.0), 2)
	for i in steps + 1:
		edge.append(Vector2(band.position.x + band.size.x * i / steps, band.position.y + k.rand(0, band.size.y * 0.45)))
	var soil := edge.duplicate()
	soil.append(band.end)
	soil.append(Vector2(band.position.x, band.end.y))
	k.fill(soil, Color(p.umber, 0.1), 2.0)
	k.stroke(edge, 0.9, Color(p.umber, 0.25), 0.4, 0.05, 0.5, 12.0)
	k.flecks(band, int(band.size.x / 6.0), Color(p.ink, 0.25), 1.1)
	for i in int(band.size.x / 40.0):
		k.streak(Vector2(band.position.x + k.rand(4, band.size.x - 4), band.position.y - k.rand(10, 40)), k.rand(14, 38), 1.4, p.grime)

## A sash window: frame, panes, a sill, the grime it sheds. Boarded on request.
static func window(k: Ink, p: Dictionary, box: Rect2, seed_value: int, boarded := false) -> void:
	var frame := k.rough_rect(box, 0.6)
	k.fill(frame, p.deep.lerp(p.paper, 0.3))
	k.hatch(frame, HATCH, 3.2, 0.8, Color(p.ink, 0.5))
	if seed_value % 3 == 0 and not boarded:
		# A drawn blind, half down.
		var blind := k.rough_rect(Rect2(box.position.x + 2, box.position.y + 2, box.size.x - 4, box.size.y * 0.45), 0.4)
		k.fill(blind, p.paper.lerp(p.dust, 0.3))
		k.line(Vector2(box.position.x + 4, box.position.y + box.size.y * 0.45), Vector2(box.end.x - 4, box.position.y + box.size.y * 0.45), 1.6, p.ink, 0.2, 0.0)
	k.line(Vector2(box.get_center().x, box.position.y), Vector2(box.get_center().x, box.end.y), 1.8, p.ink, 0.2, 0.0)
	k.line(Vector2(box.position.x, box.get_center().y), Vector2(box.end.x, box.get_center().y), 1.8, p.ink, 0.2, 0.0)
	if seed_value % 4 == 1 and not boarded:
		k.crack(box.position + Vector2(box.size.x * 0.7, 6), Vector2(-0.4, 1), 18, 0.8, Color(p.light, 0.8), 1)
	k.outline(frame, 2.4, p.ink, 0.4, 0.8)
	if boarded:
		for i in 3:
			var y := box.position.y + 12 + i * 18
			var board := PackedVector2Array([Vector2(box.position.x - 5, y + k.rand(-3, 3)), Vector2(box.end.x + 5, y + k.rand(-3, 3)),
				Vector2(box.end.x + 5, y + 9 + k.rand(-2, 2)), Vector2(box.position.x - 5, y + 9 + k.rand(-2, 2))])
			k.shape(board, p.wood, p.ink, 1.6)
			for end: float in [box.position.x - 1, box.end.x + 1]:
				k.blob(Vector2(end, y + 4.5), 1.2, p.ink)
		k.text(p.body, box.position + Vector2(-2, box.size.y * 0.62), "cancelled", 8, p.red, -0.2)
	var sill := k.rough_rect(Rect2(box.position.x - 4, box.end.y, box.size.x + 8, 5), 0.4)
	k.shape(sill, p.stone, p.ink, 1.5)
	k.streak(Vector2(box.position.x + k.rand(4, box.size.x * 0.4), box.end.y + 5), k.rand(16, 34), 1.8, p.grime)
	if k.chance(0.5):
		k.streak(Vector2(box.end.x - k.rand(4, 12), box.end.y + 5), k.rand(10, 22), 1.4, p.grime)

## A flyer pasted to a wall, torn at a corner, sometimes stamped.
static func poster(k: Ink, p: Dictionary, box: Rect2, words: String, tilt: float, stamped: bool) -> void:
	var center := box.get_center()
	var corners := k.rect_points(box)
	var sheet := PackedVector2Array()
	for corner in corners:
		sheet.append(center + (corner - center).rotated(tilt))
	sheet[2] = sheet[2].lerp(sheet[1], 0.25) + Vector2(-4, 2)
	k.fill(sheet, p.light.lerp(p.dust, 0.2))
	k.outline(sheet, 1.2, p.ink, 0.3, 0.4)
	var lines := words.split("\n")
	for i in lines.size():
		k.text(p.display, center + Vector2(-box.size.x * 0.42, -box.size.y * 0.2 + i * 11).rotated(tilt), lines[i], 10, p.ink, tilt)
	for i in 3:
		k.hair(center + Vector2(-box.size.x * 0.36, box.size.y * 0.12 + i * 4).rotated(tilt), center + Vector2(box.size.x * 0.3, box.size.y * 0.12 + i * 4).rotated(tilt), 0.6, Color(p.ink, 0.6))
	if stamped:
		var stamp := center + Vector2(0, -2)
		k.outline(k.ellipse_points(stamp, Vector2(box.size.x * 0.46, 7), tilt - 0.35, 16), 1.1, Color(p.red, 0.85), 0.3, 0.0)
		k.text(p.body, stamp + Vector2(-box.size.x * 0.4, 3).rotated(tilt - 0.35), "CANCELLED", 6, Color(p.red, 0.9), tilt - 0.35)
	k.streak(sheet[3] + Vector2(3, 0), 10, 1.2, p.grime)

static func crate(k: Ink, p: Dictionary, box: Rect2, stamp: String) -> void:
	var crate := k.rough_rect(box, 0.6)
	k.fill(crate, p.wood.lerp(p.paper, 0.35))
	for i in 3:
		var y := box.position.y + box.size.y * (i + 1) / 4.0
		k.line(Vector2(box.position.x + 2, y), Vector2(box.end.x - 2, y), 0.9, Color(p.ink, 0.5), 0.3, 0.0)
	k.line(box.position + Vector2(3, 3), box.end - Vector2(3, 3), 2.2, p.wood, 0.2, 0.0)
	k.path(PackedVector2Array([box.position + Vector2(3, 3), box.end - Vector2(3, 3)]), 0.9, p.ink, 0.2)
	k.shade(crate, LIGHT, 0.35, 3.2, 0.8, Color(p.ink, 0.45))
	if not stamp.is_empty():
		k.misregistered(k.rough_rect(Rect2(box.position.x + 4, box.get_center().y - 6, box.size.x - 8, 12), 0.4), Color(p.red, 0.2))
		k.text(p.body, Vector2(box.position.x + 5, box.get_center().y + 4), stamp, 7, p.red, -0.08)
	k.outline(crate, 2.2, p.ink, 0.4, 0.8)
	for corner in k.rect_points(box.grow(-3)):
		k.blob(corner, 1.1, p.ink)

static func barrel(k: Ink, p: Dictionary, base: Vector2, radius: float, height: float) -> void:
	var body := PackedVector2Array([base + Vector2(-radius * 0.86, 0), base + Vector2(-radius, -height * 0.5),
		base + Vector2(-radius * 0.86, -height), base + Vector2(radius * 0.86, -height),
		base + Vector2(radius, -height * 0.5), base + Vector2(radius * 0.86, 0)])
	k.fill(body, p.wood)
	for i in 4:
		var x := lerpf(-radius * 0.6, radius * 0.6, i / 3.0)
		k.line(base + Vector2(x * 0.9, -2), base + Vector2(x * 0.9, -height + 2), 0.8, Color(p.ink, 0.5), 0.3, 0.0)
	for band: float in [0.18, 0.82]:
		k.line(base + Vector2(-radius * 0.95, -height * band), base + Vector2(radius * 0.95, -height * band), 2.2, p.slate, 0.2, 0.0)
	k.shade(body, LIGHT, 0.35, 3.0, 0.8, Color(p.ink, 0.5))
	k.outline(body, 2.2, p.ink, 0.3, 0.6)
	var top := k.ellipse_points(base + Vector2(0, -height), Vector2(radius * 0.86, 3.5), 0.0, 14)
	k.shape(top, p.wood.lerp(p.paper, 0.3), p.ink, 1.4)

static func tape(k: Ink, p: Dictionary, center: Vector2, scale: float, tilt: float) -> void:
	var shell := PackedVector2Array()
	for corner: Vector2 in [Vector2(-14, -9), Vector2(14, -9), Vector2(14, 9), Vector2(-14, 9)]:
		shell.append(center + (corner * scale).rotated(tilt))
	k.fill(shell, p.deep.lerp(p.paper, 0.15))
	var window := PackedVector2Array()
	for corner: Vector2 in [Vector2(-8, -4), Vector2(8, -4), Vector2(8, 3), Vector2(-8, 3)]:
		window.append(center + (corner * scale).rotated(tilt))
	k.fill(window, p.light)
	for side: float in [-5.0, 5.0]:
		var reel := k.ellipse_points(center + (Vector2(side, -0.5) * scale).rotated(tilt), Vector2(2.4, 2.4) * scale, 0.0, 8)
		k.fill(reel, p.deep)
	var label := PackedVector2Array()
	for corner: Vector2 in [Vector2(-11, -8), Vector2(11, -8), Vector2(11, -5), Vector2(-11, -5)]:
		label.append(center + (corner * scale).rotated(tilt))
	k.fill(label, p.red.lerp(p.paper, 0.3))
	k.outline(shell, 1.2, p.ink, 0.2, 0.4)

static func lantern(k: Ink, p: Dictionary, hook: Vector2) -> void:
	k.line(hook, hook + Vector2(0, 10), 1.2, p.ink, 0.1, 0.0)
	var cap := PackedVector2Array([hook + Vector2(-8, 16), hook + Vector2(0, 9), hook + Vector2(8, 16)])
	k.shape(cap, p.slate, p.ink, 1.6)
	var glass := k.rough_rect(Rect2(hook.x - 6, hook.y + 16, 12, 16), 0.3)
	k.fill(glass, p.brass.lerp(p.light, 0.3))
	k.line(Vector2(hook.x, hook.y + 16), Vector2(hook.x, hook.y + 32), 1.0, p.ink, 0.1, 0.0)
	k.outline(glass, 1.6, p.ink, 0.2, 0.4)
	k.shape(k.rough_rect(Rect2(hook.x - 7, hook.y + 32, 14, 4), 0.2), p.slate, p.ink, 1.4)

static func bench(k: Ink, p: Dictionary, base: Vector2) -> void:
	var seat := k.rough_rect(Rect2(base.x - 36, base.y - 24, 72, 6), 0.4)
	k.shape(seat, p.wood, p.ink, 1.8)
	var back := k.rough_rect(Rect2(base.x - 34, base.y - 48, 68, 14), 0.4)
	k.fill(back, p.wood)
	k.line(Vector2(base.x - 34, base.y - 41), Vector2(base.x + 34, base.y - 41), 0.8, Color(p.ink, 0.6), 0.2, 0.0)
	k.outline(back, 1.8, p.ink, 0.3, 0.5)
	for side: float in [-1.0, 1.0]:
		var leg := PackedVector2Array([base + Vector2(side * 30, 0), base + Vector2(side * 32, -48), base + Vector2(side * 27, -48), base + Vector2(side * 25, 0)])
		k.shape(leg, p.slate, p.ink, 1.5)

static func cart(k: Ink, p: Dictionary, base: Vector2) -> void:
	var tray := PackedVector2Array([base + Vector2(-34, -20), base + Vector2(34, -20), base + Vector2(30, -46), base + Vector2(-38, -46)])
	k.fill(tray, p.wood)
	for i in 3:
		k.line(base + Vector2(-35, -28 - i * 7), base + Vector2(32, -28 - i * 7), 0.8, Color(p.ink, 0.5), 0.2, 0.0)
	# Records leaning in the tray, edge on.
	for i in 5:
		var x := -26.0 + i * 11.0
		var record := k.ellipse_points(base + Vector2(x, -52), Vector2(3.5, 17), k.rand(-0.25, 0.1), 12)
		k.shape(record, p.deep, p.ink, 1.0)
	k.shade(tray, LIGHT, 0.4, 3.0, 0.8, Color(p.ink, 0.5))
	k.outline(tray, 2.0, p.ink, 0.3, 0.6)
	k.line(base + Vector2(-38, -44), base + Vector2(-62, -62), 2.4, p.wood, 0.2, 0.0)
	k.path(PackedVector2Array([base + Vector2(-38, -44), base + Vector2(-62, -62)]), 1.0, p.ink, 0.2)
	var hub := base + Vector2(8, -14)
	var wheel := k.ellipse_points(hub, Vector2(14, 14), 0.0, 20)
	k.outline(wheel, 2.6, p.ink, 0.3, 0.0)
	for i in 6:
		k.line(hub, hub + Vector2.from_angle(TAU * i / 6.0) * 13.0, 1.2, p.ink, 0.1, 0.0)
	k.blob(hub, 2.4, p.ink)
	k.line(base + Vector2(-28, -20), base + Vector2(-28, 0), 2.0, p.ink, 0.2, 0.0)

## Somebody still does their washing: a line between the Practice and the
## market, a shirt, a pair of socks, and a sleeve pegged out to dry.
static func laundry(k: Ink, p: Dictionary, a: Vector2, b: Vector2, drop: float) -> void:
	var line := Ink.sag(a, b, drop, 24)
	k.stroke(line, 1.2, p.ink, 0.2, 0.0, 1.0, 12.0)
	var at := func(t: float) -> Vector2: return line[int(t * (line.size() - 1))]
	# A shirt.
	var shirt: Vector2 = at.call(0.2)
	var body := PackedVector2Array([shirt + Vector2(-9, 0), shirt + Vector2(9, 0), shirt + Vector2(15, 7), shirt + Vector2(11, 10),
		shirt + Vector2(9, 8), shirt + Vector2(9, 28), shirt + Vector2(-9, 28), shirt + Vector2(-9, 8), shirt + Vector2(-11, 10), shirt + Vector2(-15, 7)])
	k.fill(body, p.light)
	k.shade(body, LIGHT, 0.35, 3.0, 0.7, Color(p.ink, 0.45))
	k.outline(body, 1.6, p.ink, 0.3, 0.4)
	for peg: float in [-6.0, 6.0]:
		k.line(shirt + Vector2(peg, -3), shirt + Vector2(peg, 4), 2.2, p.wood, 0.0, 0.0)
	# Socks.
	for i in 2:
		var sock: Vector2 = at.call(0.45 + i * 0.07)
		var shape := PackedVector2Array([sock + Vector2(-3, 0), sock + Vector2(3, 0), sock + Vector2(3, 13), sock + Vector2(8, 17), sock + Vector2(6, 21), sock + Vector2(-3, 16)])
		k.fill(shape, p.red.lerp(p.paper, 0.35) if i == 0 else p.slate.lerp(p.paper, 0.4))
		k.outline(shape, 1.3, p.ink, 0.2, 0.3)
	# A record sleeve, pegged by one corner.
	var sleeve_at: Vector2 = at.call(0.72)
	var sleeve := PackedVector2Array([sleeve_at + Vector2(-2, 0), sleeve_at + Vector2(20, 4), sleeve_at + Vector2(16, 26), sleeve_at + Vector2(-6, 22)])
	k.fill(sleeve, p.paper.lerp(p.dust, 0.3))
	k.fill(k.ellipse_points(sleeve_at + Vector2(7, 13), Vector2(4, 4), 0.0, 10), p.deep)
	k.outline(sleeve, 1.4, p.ink, 0.2, 0.4)
	k.line(sleeve_at + Vector2(0, -3), sleeve_at + Vector2(0, 4), 2.2, p.wood, 0.0, 0.0)
