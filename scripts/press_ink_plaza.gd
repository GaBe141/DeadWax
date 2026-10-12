extends RefCounted
## Horn Plaza drawn in the canon's ink (ink_test.gd, docs/art/cutaway.html):
## black ink on aged label paper, thick tapering outlines, hatching on the
## shadowed third, grime, props and a cutaway of the ground beneath the street.
## The great horn stands silent in the square; the street keeps its passages
## exactly where the room put them.
##
## Pure drawing. The plate supplies its plane and a snapshot (the face of the
## pressing and the room's passages); nothing here adds collision, reads the
## player or owns a clock. Still planes are recorded once and replayed.

const Ink := preload("res://scripts/press_ink.gd")
const InkTest := preload("res://scripts/ink_test.gd")

const GROUND := 600.0
## Light comes from the upper left; hatching rises to the right.
const LIGHT := Vector2(-1.0, -1.25)
const HATCH := -PI * 0.25
const EXITS := {&"high_street": 85.0, &"headshell": 375.0, &"practice_room": 1190.0, &"the_stalls": 1680.0}
## Passages drawn as open arches; the others are doors in their buildings.
const ARCHES := [&"high_street", &"the_stalls"]

static var _tapes: Dictionary = {}

static func draw(canvas: CanvasItem, plane: StringName, state: Dictionary, display: Font, body: Font) -> void:
	var far_face := bool(state.get("far_face", false))
	var exits: Dictionary = state.get("exits", EXITS)
	var key := [plane, far_face, exits]
	if not _tapes.has(key):
		var k := Ink.new(canvas, hash(String(plane)) & 0x7fffffff, true)
		var p := palette(far_face)
		p["display"] = display
		p["body"] = body
		match plane:
			&"paper": _paper(k, p)
			&"far": _far_town(k, p)
			&"set": _square(k, p, exits)
		k.flush()
		_tapes[key] = k.tape
	Ink.play(canvas, _tapes[key])

## Forgets recorded planes (tests use this to draw from scratch).
static func clear_cache() -> void:
	_tapes.clear()

static func palette(far_face: bool) -> Dictionary:
	var p := {
		"paper": InkTest.LABEL_PAPER, "ink": InkTest.LINE, "deep": InkTest.WAX,
		"stone": InkTest.STONE, "dust": InkTest.DUST, "brass": InkTest.BRASS,
		"umber": InkTest.UMBER, "red": InkTest.CANCEL_RED, "light": InkTest.GROOVE,
		"patina": Color("6f7d69"), "wood": Color("8a6440"), "slate": Color("5b5560"),
	}
	if far_face:
		# Scratchboard: the same drawing, reversed out of the wax.
		p = {
			"paper": InkTest.WAX, "ink": InkTest.GROOVE, "deep": Color("050407"),
			"stone": Color("26222b"), "dust": Color("1d1a22"), "brass": Color("4a3a28"),
			"umber": Color("2a2430"), "red": Color("5c2b23"), "light": Color("d9d3c7"),
			"patina": Color("33403a"), "wood": Color("33281f"), "slate": Color("2b2832"),
		}
	p["hatch"] = Color(p.ink, 0.5)
	p["soft"] = Color(p.ink, 0.22)
	p["grime"] = Color(p.ink, 0.16)
	p["shade"] = p.paper.lerp(p.ink, 0.07)
	return p

# == the sheet =====================================================================

static func _paper(k: Ink, p: Dictionary) -> void:
	var sheet := Rect2(-420, -420, 2640, 1680)
	k.fill(k.rect_points(sheet), p.paper, 0.0)
	# Old water damage and handling: broad, faint tide-marked stains.
	for i in 14:
		var at := Vector2(k.rand(-200, 2000), k.rand(-100, 560))
		k.stain(at, k.rand(50, 170), Color(p.umber, k.rand(0.025, 0.05)))
	# A fold across the sheet: one light edge, one dark.
	for fold: Array in [[Vector2(690, -420), Vector2(705, 1260)], [Vector2(-420, 310), Vector2(2220, 296)]]:
		k.line(fold[0], fold[1], 2.2, Color(p.light, 0.35), 1.5, 0.0)
		k.line(fold[0] + Vector2(1.6, 1.6), fold[1] + Vector2(1.6, 1.6), 1.0, Color(p.ink, 0.07), 1.5, 0.0)
	# The label's own printed rim, far off: rings and rim type.
	var hub := Vector2(900, 1720)
	for radius: float in [1606.0, 1580.0, 1500.0]:
		var ring := k.ellipse_points(hub, Vector2(radius, radius), 0.0, 180, PI * 1.08, PI * 1.92)
		k.stroke(ring, 1.4 if radius != 1580.0 else 0.8, Color(p.ink, 0.08), 1.0, 0.04, 0.4, 14.0)
	k.arc_text(p.display, hub, 1592.0, PI * 1.262,
		"THE LABEL  ·  SIDE ONE  ·  ALL THAT WAS PLAYED  ·  33⅓  ·  MADE TO BE PLAYED ONCE  ·  KEEP AWAY FROM HEAT",
		20, Color(p.ink, 0.11), 1.18)
	# Tooth: fibres and specks over everything.
	for i in 1200:
		var at := Vector2(k.rand(-400, 2200), k.rand(-400, 1240))
		var turn := Vector2.from_angle(k.rand(0.0, TAU)) * k.rand(1.5, 5.0)
		k.hair(at - turn, at + turn, 0.6, Color(p.ink, k.rand(0.03, 0.07)))
	for i in 650:
		k.blob(Vector2(k.rand(-400, 2200), k.rand(-400, 1240)), k.rand(0.4, 1.2), Color(p.ink, k.rand(0.05, 0.14)), 4)

# == the far town (moves a little with the camera) ===============================

static func _far_town(k: Ink, p: Dictionary) -> void:
	# Drawn as a printer draws distance: thin, pale, barely there.
	var line := Color(p.ink, 0.2)
	var flat: Color = p.paper.lerp(p.dust, 0.2)
	var x := -140.0
	while x < 1960.0:
		var width := k.rand(70, 150)
		var top := k.rand(300, 400)
		var body := PackedVector2Array()
		var roof := k.rng.randi_range(0, 2)
		if roof == 0:
			body = PackedVector2Array([Vector2(x, 540), Vector2(x, top), Vector2(x + width * 0.5, top - k.rand(30, 55)), Vector2(x + width, top), Vector2(x + width, 540)])
		elif roof == 1:
			body = PackedVector2Array([Vector2(x, 540), Vector2(x, top), Vector2(x + width, top), Vector2(x + width, 540)])
		else:
			body = PackedVector2Array([Vector2(x, 540), Vector2(x, top + 14), Vector2(x + width * 0.2, top), Vector2(x + width * 0.8, top), Vector2(x + width, top + 14), Vector2(x + width, 540)])
		k.fill(body, flat)
		k.hatch(body, HATCH, 6.0, 0.7, Color(p.ink, 0.06), 0.6)
		k.outline(body, 1.0, line, 0.4, 1.0)
		for row in range(int((540 - top) / 34.0)):
			for column in range(int(width / 26.0)):
				if k.chance(0.3):
					var box := Rect2(x + 9 + column * 26, top + 16 + row * 34, 8, 12)
					if box.end.x < x + width - 5:
						k.fill(k.rough_rect(box, 0.6), Color(p.ink, k.rand(0.07, 0.13)))
		if k.chance(0.6):
			var stack := x + k.rand(12, width - 24)
			var chimney := k.rough_rect(Rect2(stack, top - 26, 10, 30), 0.6)
			k.fill(chimney, flat)
			k.outline(chimney, 1.1, line, 0.3, 0.8)
		if k.chance(0.35):
			var mast := x + k.rand(20, width - 20)
			k.line(Vector2(mast, top), Vector2(mast, top - k.rand(40, 70)), 1.0, line, 0.3, 0.0)
			k.line(Vector2(mast - 9, top - 46), Vector2(mast + 9, top - 50), 0.9, line, 0.3, 0.0)
		x += width + k.rand(-8, 18)
	# A distant water tower, and the long dark line of the next street's roofs.
	var tower := Vector2(1525, 300)
	var tank := k.rough_rect(Rect2(tower.x - 30, tower.y - 52, 60, 46), 0.8)
	k.fill(tank, flat)
	k.hatch(tank, HATCH, 5.0, 0.7, Color(p.ink, 0.08))
	k.outline(tank, 1.4, line)
	k.fill(PackedVector2Array([tower + Vector2(-36, -52), tower + Vector2(0, -78), tower + Vector2(36, -52)]), flat)
	k.outline(PackedVector2Array([tower + Vector2(-36, -52), tower + Vector2(0, -78), tower + Vector2(36, -52)]), 1.4, line)
	for leg: float in [-24.0, -8.0, 8.0, 24.0]:
		k.line(tower + Vector2(leg, -6), tower + Vector2(leg * 1.3, 70), 1.2, line, 0.3, 0.0)
	k.line(tower + Vector2(-30, 30), tower + Vector2(30, 30), 1.0, line, 0.3, 0.0)

# == the plaza ======================================================================

static func _square(k: Ink, p: Dictionary, exits: Dictionary) -> void:
	var gate_x := float(exits.get(&"high_street", 85.0))
	var home_x := float(exits.get(&"headshell", 375.0))
	var practice_x := float(exits.get(&"practice_room", 1190.0))
	var stalls_x := float(exits.get(&"the_stalls", 1680.0))
	_underground(k, p)
	_corner_gate(k, p, gate_x)
	_boarding_house(k, p, home_x)
	_practice(k, p, practice_x)
	_market(k, p, stalls_x)
	_lights(k, p)
	_horn(k, p)
	_street(k, p)
	_street_props(k, p)

# -- the ground: street slabs, then the cutaway below them --------------------------

static func _street(k: Ink, p: Dictionary) -> void:
	var x := -30.0
	while x < 1830.0:
		var width := k.rand(42, 78)
		var slab := k.rough_rect(Rect2(x + 1.5, GROUND + 1, width - 3, 21), 0.7)
		k.fill(slab, p.stone.lerp(p.dust, k.rand(0.0, 0.55)))
		k.shade(slab, LIGHT, 0.3, 3.4, 0.8, Color(p.ink, 0.35))
		k.flecks_in(slab, int(width / 9.0), p.grime, 0.9)
		k.outline(slab, 1.3, Color(p.ink, 0.8), 0.3, 0.6)
		if k.chance(0.25):
			k.crack(Vector2(x + k.rand(8, width - 8), GROUND + 2), Vector2(k.rand(-0.4, 0.4), 1), 16, 0.9, Color(p.ink, 0.7), 1)
		x += width
	# The walking edge: the heaviest line in the room.
	k.stroke(PackedVector2Array([Vector2(-30, GROUND), Vector2(1830, GROUND)]), 3.6, p.ink, 0.7, 0.0, 1.0, 9.0)
	# Bedding sand under the slabs.
	k.stipple(k.rect_points(Rect2(-30, GROUND + 23, 1860, 16)), 420, Color(p.ink, 0.35), 0.8)
	k.stroke(PackedVector2Array([Vector2(-30, GROUND + 39), Vector2(1830, GROUND + 39)]), 1.4, Color(p.ink, 0.55), 1.4, 0.0, 1.0, 12.0)

static func _underground(k: Ink, p: Dictionary) -> void:
	var earth := k.rect_points(Rect2(-40, GROUND + 22, 1880, 260))
	k.fill(earth, p.dust, 0.0)
	# Strata: soft wavy bands, darker as they go down.
	for band in 7:
		var y := GROUND + 52 + band * 26 + k.rand(-4, 4)
		var points := PackedVector2Array()
		var phase := k.rand(0.0, TAU)
		for i in 40:
			var x := -40.0 + i * 48.0
			points.append(Vector2(x, y + sin(i * 0.7 + phase) * 4.0 + k.rand(-1.5, 1.5)))
		k.stroke(points, 1.0, Color(p.ink, 0.22 + band * 0.03), 0.6, 0.05, 0.4, 16.0)
	# The Overture begins below: a wavy seam, worn darker dust and long cracks.
	var seam := PackedVector2Array()
	for i in 46:
		seam.append(Vector2(-40.0 + i * 41.0, GROUND + 182 + sin(i * 0.9) * 5.0 + k.rand(-2, 2)))
	var lower := seam.duplicate()
	lower.append(Vector2(1840, 1300))
	lower.append(Vector2(-40, 1300))
	k.fill(lower, p.dust.lerp(p.umber, 0.16), 0.0)
	k.hatch(lower, HATCH, 6.0, 0.8, Color(p.ink, 0.22))
	k.stroke(seam, 2.4, Color(p.ink, 0.85), 0.8, 0.05, 0.5, 10.0)
	for i in 16:
		k.crack(Vector2(k.rand(0, 1800), GROUND + 186), Vector2(k.rand(-0.3, 0.3), 1), k.rand(40, 120), 1.1, Color(p.ink, 0.6), 2)
	# Pebbles and grit through the earth.
	for i in 150:
		var at := Vector2(k.rand(-30, 1830), k.rand(GROUND + 44, GROUND + 176))
		var radius := k.rand(1.5, 4.5)
		var stone := k.ellipse_points(at, Vector2(radius * k.rand(1.0, 1.6), radius), k.rand(-0.4, 0.4), 7)
		k.fill(stone, p.stone.lerp(p.dust, k.rand(0.2, 0.7)))
		k.outline(stone, 0.9, Color(p.ink, 0.42), 0.2, 0.3)
	k.flecks(Rect2(-30, GROUND + 40, 1860, 230), 320, Color(p.ink, 0.3), 1.0)
	_cellar(k, p)
	_storeroom(k, p)
	_drain(k, p)
	_speaking_tube(k, p)
	_buried(k, p)

## Under the boarding house: its cellar, open to the cut.
static func _cellar(k: Ink, p: Dictionary) -> void:
	var room := Rect2(168, GROUND + 46, 284, 118)
	var walls := k.rough_rect(room, 1.0)
	k.fill(walls, p.paper.lerp(p.dust, 0.35))
	_bricks(k, p, room.grow(-4), 9.0, 22.0, 0.3)
	# Deep at the back and the ceiling: crosshatch fading down the wall.
	k.crosshatch(k.rect_points(Rect2(room.position, Vector2(room.size.x, 26))), HATCH, 4.0, 0.8, Color(p.ink, 0.45))
	k.hatch(k.rect_points(Rect2(room.position + Vector2(0, 26), Vector2(70, room.size.y - 26))), HATCH, 4.5, 0.8, Color(p.ink, 0.35))
	# Barrels, a crate and a shelf of jars.
	for barrel: Vector2 in [Vector2(230, GROUND + 160), Vector2(272, GROUND + 162)]:
		_barrel(k, p, barrel, 19.0, 38.0)
	_crate(k, p, Rect2(318, GROUND + 126, 46, 38), "")
	var shelf_y := GROUND + 84.0
	k.line(Vector2(372, shelf_y), Vector2(440, shelf_y), 2.4, p.ink, 0.4, 0.05)
	for i in 6:
		var jar := Rect2(376 + i * 11, shelf_y - 15 + k.rand(-2, 1), 8, 14 + k.rand(-1, 2))
		var glass := k.rough_rect(jar, 0.5)
		k.fill(glass, p.paper.lerp(p.patina, k.rand(0.1, 0.4)))
		k.outline(glass, 1.0, p.ink, 0.2, 0.4)
	k.line(Vector2(372, shelf_y + 30), Vector2(440, shelf_y + 30), 2.4, p.ink, 0.4, 0.05)
	for i in 4:
		_tape(k, p, Vector2(384 + i * 15, shelf_y + 22), 0.55, k.rand(-0.08, 0.08))
	k.outline(walls, 2.6, p.ink, 0.6, 1.0)
	k.line(Vector2(room.position.x, room.end.y - 1), Vector2(room.end.x, room.end.y - 1), 3.0, p.ink)

## Under the market: its storeroom, shelves of pressings nobody came for.
static func _storeroom(k: Ink, p: Dictionary) -> void:
	var room := Rect2(1318, GROUND + 48, 300, 116)
	var walls := k.rough_rect(room, 1.0)
	k.fill(walls, p.paper.lerp(p.dust, 0.4))
	k.crosshatch(k.rect_points(Rect2(room.position, Vector2(room.size.x, 22))), HATCH, 4.0, 0.8, Color(p.ink, 0.45))
	k.hatch(k.rect_points(Rect2(room.end.x - 80, room.position.y + 22, 80, room.size.y - 22)), HATCH, 4.0, 0.8, Color(p.ink, 0.4))
	for row in 3:
		var y := room.position.y + 40 + row * 32
		k.line(Vector2(room.position.x + 10, y), Vector2(room.position.x + 170, y), 2.2, p.ink, 0.4, 0.05)
		var x := room.position.x + 14
		while x < room.position.x + 164:
			var lean := k.rand(-0.12, 0.12)
			var height := k.rand(15, 22)
			var sleeve := PackedVector2Array([Vector2(x, y), Vector2(x + 3, y), Vector2(x + 3 + lean * height, y - height), Vector2(x + lean * height, y - height)])
			k.fill(sleeve, p.paper if k.chance(0.7) else p.red.lerp(p.paper, 0.4))
			k.outline(sleeve, 0.7, p.ink, 0.1, 0.2)
			x += k.rand(3.5, 6.5)
	_crate(k, p, Rect2(room.position.x + 190, room.end.y - 40, 50, 40), "")
	_crate(k, p, Rect2(room.position.x + 228, room.end.y - 70, 44, 32), "")
	# A dead bulb on its flex.
	var bulb := Vector2(room.position.x + 205, room.position.y + 46)
	k.line(Vector2(bulb.x, room.position.y + 2), bulb, 1.0, p.ink, 0.2, 0.0)
	var glass := k.ellipse_points(bulb + Vector2(0, 6), Vector2(5, 7), 0.0, 12)
	k.fill(glass, p.paper)
	k.outline(glass, 1.1, p.ink, 0.2, 0.3)
	k.outline(walls, 2.6, p.ink, 0.6, 1.0)

## A drain runs between the two cellars, with a shaft up to the grate.
static func _drain(k: Ink, p: Dictionary) -> void:
	var top := GROUND + 88.0
	var bottom := GROUND + 126.0
	var pipe := PackedVector2Array([Vector2(452, top), Vector2(1318, top), Vector2(1318, bottom), Vector2(452, bottom)])
	k.fill(pipe, p.slate.lerp(p.dust, 0.72))
	k.hatch(PackedVector2Array([Vector2(452, bottom - 12), Vector2(1318, bottom - 12), Vector2(1318, bottom), Vector2(452, bottom)]), HATCH, 3.5, 0.8, Color(p.ink, 0.5))
	k.stroke(PackedVector2Array([Vector2(452, top), Vector2(1318, top)]), 2.6, p.ink, 0.8, 0.02, 0.6, 12.0)
	k.stroke(PackedVector2Array([Vector2(452, bottom), Vector2(1318, bottom)]), 2.6, p.ink, 0.8, 0.02, 0.6, 12.0)
	var x := 470.0
	while x < 1310.0:
		k.line(Vector2(x, top - 2), Vector2(x, bottom + 2), 2.0, p.ink, 0.2, 0.0)
		k.line(Vector2(x + 4, top), Vector2(x + 4, bottom), 1.0, Color(p.ink, 0.45), 0.2, 0.0)
		for y: float in [top + 6, bottom - 6]:
			k.blob(Vector2(x - 4, y), 1.4, p.ink)
		k.streak(Vector2(x - 2, bottom), k.rand(10, 22), 1.6, Color(p.umber, 0.5))
		x += k.rand(70, 100)
	# The shaft and its rungs, under the grate by the horn.
	var shaft := Rect2(684, GROUND + 22, 30, top - GROUND - 22)
	k.fill(k.rect_points(shaft), p.deep.lerp(p.paper, 0.18))
	k.hatch(k.rect_points(shaft), HATCH, 3.0, 0.8, Color(p.ink, 0.6))
	for side: float in [shaft.position.x, shaft.end.x]:
		k.line(Vector2(side, shaft.position.y), Vector2(side, shaft.end.y), 2.2, p.ink, 0.3, 0.0)
	for i in 5:
		var y := shaft.position.y + 8 + i * 12
		k.line(Vector2(shaft.position.x + 4, y), Vector2(shaft.end.x - 4, y), 1.6, p.light, 0.2, 0.0)

## The great horn's speaking tube goes down from its plinth into the dark.
static func _speaking_tube(k: Ink, p: Dictionary) -> void:
	var left := 798.0
	var right := 824.0
	var tube := PackedVector2Array([Vector2(left, GROUND + 20), Vector2(right, GROUND + 20), Vector2(right + 6, GROUND + 300), Vector2(left - 6, GROUND + 300)])
	k.fill(tube, p.brass)
	k.shade(tube, LIGHT, 0.45, 3.0, 0.8, Color(p.ink, 0.55))
	k.line(Vector2(left + 5, GROUND + 26), Vector2(left + 3, GROUND + 230), 1.4, Color(p.light, 0.7), 0.4, 0.3)
	k.stroke(PackedVector2Array([Vector2(left, GROUND + 20), Vector2(left - 6, GROUND + 300)]), 2.6, p.ink, 0.5, 0.0, 1.0)
	k.stroke(PackedVector2Array([Vector2(right, GROUND + 20), Vector2(right + 6, GROUND + 300)]), 2.6, p.ink, 0.5, 0.0, 1.0)
	for y: float in [GROUND + 70.0, GROUND + 150.0, GROUND + 225.0]:
		var spread := (y - GROUND) / 280.0 * 6.0
		var flange := k.rough_rect(Rect2(left - 5 - spread, y - 4, right - left + 10 + spread * 2, 8), 0.5)
		k.fill(flange, p.brass.lerp(p.umber, 0.3))
		k.outline(flange, 1.6, p.ink, 0.2, 0.5)
		for bolt: float in [left - 1 - spread, right + 1 + spread]:
			k.blob(Vector2(bolt, y), 1.5, p.ink)

## Things the street lost: a tape, a bone the Hound buried, a broken pressing.
static func _buried(k: Ink, p: Dictionary) -> void:
	_tape(k, p, Vector2(560, GROUND + 150), 1.2, 0.35)
	var ribbon := Ink.cubic(Vector2(578, GROUND + 148), Vector2(610, GROUND + 120), Vector2(640, GROUND + 175), Vector2(672, GROUND + 140), 16)
	k.stroke(ribbon, 1.6, p.umber, 0.4, 0.1, 0.5)
	# The Hound's bone, just under the horn's step.
	var bone := Vector2(935, GROUND + 60)
	k.line(bone + Vector2(-16, 2), bone + Vector2(16, -2), 6.0, p.light, 0.3, 0.0)
	for end: Vector2 in [Vector2(-17, 2), Vector2(17, -2)]:
		for knob: float in [-3.5, 3.5]:
			k.blob(bone + end + Vector2(0, knob), 4.0, p.light)
	k.path(PackedVector2Array([bone + Vector2(-14, -1), bone + Vector2(14, -5)]), 1.3, p.ink, 0.2)
	k.path(PackedVector2Array([bone + Vector2(-14, 5), bone + Vector2(14, 1)]), 1.3, p.ink, 0.2)
	for end: Vector2 in [Vector2(-18, 2), Vector2(18, -2)]:
		k.outline(k.ellipse_points(bone + end, Vector2(4.5, 7), 0.0, 9), 1.2, p.ink, 0.2, 0.2)
	# Half a pressing, edge on in the dirt.
	var shard := PackedVector2Array([Vector2(1180, GROUND + 140), Vector2(1222, GROUND + 128), Vector2(1250, GROUND + 146), Vector2(1214, GROUND + 152)])
	k.fill(shard, p.deep)
	for i in 3:
		k.hair(Vector2(1188 + i * 4, GROUND + 141 - i), Vector2(1240 - i * 3, GROUND + 144 - i * 2), 0.6, Color(p.light, 0.5))
	k.outline(shard, 1.4, p.ink, 0.2, 0.5)
	for i in 5:
		var at := Vector2(k.rand(40, 1760), k.rand(GROUND + 190, GROUND + 230))
		k.line(at, at + Vector2(k.rand(6, 12), k.rand(-3, 3)), 2.4, p.light, 0.2, 0.1)

# -- buildings ----------------------------------------------------------------------

## The far-left corner: the High Street passes under it through an arch.
static func _corner_gate(k: Ink, p: Dictionary, gate_x: float) -> void:
	var body := Rect2(-60, 168, 228, GROUND - 168)
	var wall := k.rough_rect(body, 1.0)
	k.fill(wall, p.paper.lerp(p.dust, 0.25))
	k.hatch(wall, HATCH + 0.12, 6.5, 0.7, Color(p.ink, 0.07), 0.85)
	_bricks(k, p, body, 10.0, 24.0, 0.55)
	k.shade(wall, LIGHT, 0.3, 4.2, 0.8, p.hatch)
	_weather(k, p, body)
	_damp(k, p, Rect2(body.position.x, GROUND - 46, body.size.x, 46))
	# Cornice and a chimney stack.
	var cornice := k.rough_rect(Rect2(-64, 156, 236, 14), 0.8)
	k.shape(cornice, p.umber, p.ink, 2.4)
	var stack := k.rough_rect(Rect2(40, 118, 30, 40), 1.0)
	k.fill(stack, p.paper.lerp(p.dust, 0.3))
	_bricks(k, p, Rect2(40, 118, 30, 40), 8.0, 14.0, 0.5)
	k.outline(stack, 2.4, p.ink)
	for pot: float in [46.0, 58.0]:
		var chimney_pot := k.rough_rect(Rect2(pot, 104, 8, 15), 0.6)
		k.shape(chimney_pot, p.red.lerp(p.umber, 0.35), p.ink, 1.8)
	# Upper windows.
	for row in 2:
		for column in 2:
			var box := Rect2(8 + column * 78, 210 + row * 108, 40, 62)
			_window(k, p, box, row * 2 + column + 3)
	# The arch the street runs through.
	var center := Vector2(gate_x, 522)
	var outer := 40.0
	var inner := 31.0
	var opening := PackedVector2Array()
	opening.append(Vector2(gate_x - inner, GROUND))
	for i in 17:
		opening.append(center + Vector2.from_angle(PI + PI * i / 16.0) * inner)
	opening.append(Vector2(gate_x + inner, GROUND))
	k.fill(opening, p.deep.lerp(p.paper, 0.12))
	# The street beyond, receding: a lit slot, hatching thickening inward.
	var beyond := PackedVector2Array([Vector2(gate_x - 14, GROUND), Vector2(gate_x - 10, 548), Vector2(gate_x + 10, 548), Vector2(gate_x + 14, GROUND)])
	k.fill(beyond, p.paper.lerp(p.dust, 0.5))
	k.hatch(beyond, HATCH, 3.0, 0.7, Color(p.ink, 0.35))
	k.line(Vector2(gate_x - 10, 548), Vector2(gate_x + 10, 548), 1.4, p.ink, 0.2, 0.0)
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
		var jamb := k.rough_rect(Rect2(gate_x + side * (inner + 4.5) - 4.5, 522, 9, GROUND - 522), 0.6)
		k.shape(jamb, p.stone.lerp(p.dust, 0.4), p.ink, 1.8)
	# Its name over the arch.
	var plate := k.rough_rect(Rect2(gate_x - 46, 446, 92, 22), 0.6)
	k.shape(plate, p.umber, p.ink, 2.0)
	k.text(p.display, Vector2(gate_x - 40, 463), "← HIGH ST.", 15, p.light)
	# Flyers pasted by the arch, half torn.
	_poster(k, p, Rect2(132, 470, 30, 44), "LAST\nNIGHT", 0.05, true)
	_poster(k, p, Rect2(124, 520, 34, 40), "ONE\nNIGHT", -0.06, false)
	# A drainpipe down the corner.
	k.line(Vector2(161, 172), Vector2(161, GROUND - 2), 4.0, p.umber, 0.4, 0.0)
	k.line(Vector2(158, 172), Vector2(158, GROUND - 2), 1.0, p.ink, 0.3, 0.0)
	k.sketch(wall, 3.4, p.ink)

## The boarding house: rooms to let, a cellar, and the way home.
static func _boarding_house(k: Ink, p: Dictionary, home_x: float) -> void:
	var left := 168.0
	var right := 468.0
	var eave := 222.0
	var body := PackedVector2Array([Vector2(left, GROUND), Vector2(left, eave), Vector2(right, eave), Vector2(right, GROUND)])
	k.fill(body, p.paper.lerp(p.stone, 0.6))
	k.hatch(body, HATCH + 0.12, 6.5, 0.7, Color(p.ink, 0.07), 0.85)
	_bricks(k, p, Rect2(left, eave, right - left, GROUND - eave - 100), 9.0, 22.0, 0.45)
	k.shade(body, LIGHT, 0.28, 4.0, 0.8, p.hatch)
	_weather(k, p, Rect2(left, eave, right - left, GROUND - eave - 100), 3)
	# Shopfront in dark wood along the ground floor.
	var front := k.rough_rect(Rect2(left, GROUND - 100, right - left, 100), 0.6)
	k.fill(front, p.umber.lerp(p.paper, 0.18))
	k.hatch(front, HATCH, 5.0, 0.9, Color(p.ink, 0.35))
	var lintel := k.rough_rect(Rect2(left - 6, GROUND - 108, right - left + 12, 12), 0.6)
	k.shape(lintel, p.umber, p.ink, 2.4)
	# The shop window, with its card.
	var shop := Rect2(186, GROUND - 86, 120, 70)
	var glass := k.rough_rect(shop, 0.6)
	k.fill(glass, p.paper.lerp(p.dust, 0.25))
	k.hatch(glass, -PI * 0.3, 9.0, 0.8, Color(p.ink, 0.18), 0.6)
	k.line(Vector2(shop.get_center().x, shop.position.y), Vector2(shop.get_center().x, shop.end.y), 2.0, p.ink, 0.3, 0.0)
	var card := PackedVector2Array([Vector2(196, GROUND - 74), Vector2(244, GROUND - 77), Vector2(246, GROUND - 46), Vector2(197, GROUND - 44)])
	k.shape(card, p.light, p.ink, 1.4)
	k.text(p.display, Vector2(200, GROUND - 63), "ROOMS", 12, p.ink, -0.04)
	k.text(p.display, Vector2(201, GROUND - 50), "TO LET", 12, p.ink, -0.04)
	k.outline(glass, 2.6, p.ink)
	var sill := k.rough_rect(Rect2(180, GROUND - 16, 132, 8), 0.5)
	k.shape(sill, p.stone, p.ink, 1.8)
	# The door home: a step, a frame and a runtime plate for a street number.
	var frame := k.rough_rect(Rect2(home_x - 36, GROUND - 104, 72, 104), 0.6)
	k.fill(frame, p.umber)
	k.outline(frame, 2.4, p.ink)
	var step := k.rough_rect(Rect2(home_x - 40, GROUND - 7, 80, 7), 0.5)
	k.shape(step, p.stone, p.ink, 1.8)
	var plate := k.rough_rect(Rect2(home_x - 64, GROUND - 82, 22, 13), 0.4)
	k.shape(plate, p.light, p.ink, 1.3)
	k.text(p.body, Vector2(home_x - 62, GROUND - 72), "0:00", 9, p.ink)
	# Upper floors: windows, one boarded, one open to the room behind it.
	_window(k, p, Rect2(190, 418, 42, 62), 11)
	_cutaway_bedroom(k, p, Rect2(252, 410, 96, 70))
	_window(k, p, Rect2(368, 418, 42, 62), 12, true)
	_window(k, p, Rect2(190, 316, 42, 62), 13)
	_window(k, p, Rect2(268, 316, 42, 62), 14)
	# The balcony door, second storey, onto the ledge.
	var jamb := k.rough_rect(Rect2(404, 324, 52, 76), 0.6)
	k.shape(jamb, p.stone.lerp(p.dust, 0.3), p.ink, 2.2)
	var door := k.rough_rect(Rect2(411, 331, 38, 69), 0.5)
	k.fill(door, p.wood)
	for pane in 2:
		var light := k.rough_rect(Rect2(415 + pane * 16, 336, 13, 22), 0.4)
		k.fill(light, p.deep.lerp(p.paper, 0.25))
		k.outline(light, 1.2, p.ink, 0.2, 0.3)
	for panel in 2:
		k.outline(k.rough_rect(Rect2(415 + panel * 16, 364, 13, 30), 0.4), 1.0, Color(p.ink, 0.7), 0.2, 0.3)
	k.shade(door, LIGHT, 0.4, 3.0, 0.8, Color(p.ink, 0.5))
	k.blob(Vector2(444, 368), 1.6, p.brass)
	k.outline(door, 2.0, p.ink)
	# Roof: tiles in hatched courses, an attic porthole and a crooked chimney.
	var roof := PackedVector2Array([Vector2(left - 18, eave + 2), Vector2(318, 118), Vector2(right + 18, eave + 2)])
	k.fill(roof, p.umber.lerp(p.paper, 0.1))
	for course in 9:
		var y := 128.0 + course * 11.0
		var half := (y - 118.0) / (eave + 2.0 - 118.0) * (right + 18.0 - 318.0)
		k.stroke(PackedVector2Array([Vector2(318 - half, y), Vector2(318 + half, y)]), 1.0, Color(p.light, 0.35), 0.5, 0.1, 0.4, 14.0)
		var x := 318.0 - half + (course % 2) * 6.0
		while x < 318.0 + half - 4:
			k.hair(Vector2(x, y), Vector2(x + 1, y + 10), 0.8, Color(p.light, 0.3))
			x += 12.0
	k.shade(roof, LIGHT, 0.4, 3.4, 0.9, Color(p.deep, 0.55))
	k.sketch(roof, 3.4, p.ink)
	var porthole := k.ellipse_points(Vector2(318, 182), Vector2(15, 15), 0.0, 20)
	k.fill(porthole, p.deep.lerp(p.paper, 0.25))
	k.line(Vector2(303, 182), Vector2(333, 182), 1.6, p.ink, 0.2, 0.0)
	k.line(Vector2(318, 167), Vector2(318, 197), 1.6, p.ink, 0.2, 0.0)
	k.outline(porthole, 2.4, p.ink, 0.3, 0.5)
	var stack := PackedVector2Array([Vector2(214, 196), Vector2(212, 132), Vector2(240, 128), Vector2(244, 178)])
	k.fill(stack, p.paper.lerp(p.dust, 0.3))
	_bricks(k, p, Rect2(212, 130, 30, 60), 8.0, 14.0, 0.5)
	k.outline(stack, 2.4, p.ink)
	var cowl := PackedVector2Array([Vector2(218, 128), Vector2(222, 108), Vector2(238, 100), Vector2(246, 108), Vector2(234, 112), Vector2(234, 128)])
	k.shape(cowl, p.slate, p.ink, 2.0)
	# The ledge: planks on brackets, the post doubling as a lamp standard.
	var deck := k.rough_rect(Rect2(398, 400, 204, 30), 0.5)
	k.fill(deck, p.wood)
	for plank in 3:
		var y := 400.0 + plank * 10.0
		k.line(Vector2(400, y + 10), Vector2(600, y + 10 + k.rand(-0.6, 0.6)), 1.0, Color(p.ink, 0.6), 0.4, 0.05)
	for nail in range(408, 600, 32):
		k.blob(Vector2(nail, 405), 1.0, p.ink)
	k.shade(deck, Vector2(0, -1), 0.35, 3.0, 0.8, Color(p.ink, 0.5))
	k.outline(deck, 2.6, p.ink, 0.4, 1.0)
	# Its shadow on the wall below.
	k.hatch(PackedVector2Array([Vector2(left + 230, 430), Vector2(right, 430), Vector2(right, 452), Vector2(left + 238, 446)]), HATCH, 3.0, 0.8, Color(p.ink, 0.45))
	var post := k.rough_rect(Rect2(584, 430, 10, GROUND - 430), 0.5)
	k.shape(post, p.umber, p.ink, 2.2)
	k.line(Vector2(589, 470), Vector2(522, 432), 5.0, p.umber, 0.3, 0.0)
	k.path(PackedVector2Array([Vector2(589, 470), Vector2(522, 432)]), 1.4, p.ink, 0.3)
	for bracket: Vector2 in [Vector2(474, 430)]:
		var iron := PackedVector2Array([bracket, bracket + Vector2(0, 26), bracket + Vector2(-8, 26), bracket + Vector2(-8, 0)])
		k.shape(iron, p.slate, p.ink, 1.6)
	_lantern(k, p, Vector2(589, 470))
	_damp(k, p, Rect2(left, GROUND - 40, right - left, 40))
	k.sketch(body, 3.4, p.ink)

## The first-floor middle window opens on the room behind it: a bed, a
## gramophone, a picture of somebody.
static func _cutaway_bedroom(k: Ink, p: Dictionary, box: Rect2) -> void:
	var wall := k.rough_rect(box, 0.6)
	k.fill(wall, p.paper.lerp(p.red, 0.12))
	for x in range(int(box.position.x) + 6, int(box.end.x), 9):
		k.hair(Vector2(x, box.position.y + 2), Vector2(x, box.end.y - 2), 0.7, Color(p.red, 0.35))
	k.crosshatch(k.rect_points(Rect2(box.position, Vector2(box.size.x, 12))), HATCH, 3.6, 0.7, Color(p.ink, 0.4))
	k.hatch(k.rect_points(Rect2(box.end.x - 26, box.position.y + 12, 26, box.size.y - 12)), HATCH, 3.6, 0.8, Color(p.ink, 0.4))
	# The bed.
	var bed := Rect2(box.position.x + 8, box.end.y - 22, 52, 14)
	var frame := k.rough_rect(bed, 0.5)
	k.fill(frame, p.paper)
	k.hatch(frame, -PI * 0.15, 3.0, 0.8, Color(p.ink, 0.5))
	k.outline(frame, 1.5, p.ink, 0.3, 0.5)
	var pillow := k.ellipse_points(bed.position + Vector2(9, -1), Vector2(8, 4), 0.0, 12)
	k.shape(pillow, p.light, p.ink, 1.2)
	k.line(Vector2(bed.position.x, bed.position.y - 10), Vector2(bed.position.x, bed.end.y + 6), 2.0, p.ink, 0.2, 0.0)
	k.line(Vector2(bed.end.x, bed.position.y + 2), Vector2(bed.end.x, bed.end.y + 6), 2.0, p.ink, 0.2, 0.0)
	# A little gramophone on a stool.
	var stool := box.position + Vector2(76, box.size.y - 8)
	k.line(stool + Vector2(-6, 0), stool + Vector2(-6, -14), 1.4, p.ink, 0.2, 0.0)
	k.line(stool + Vector2(6, 0), stool + Vector2(6, -14), 1.4, p.ink, 0.2, 0.0)
	var cabinet := k.rough_rect(Rect2(stool.x - 9, stool.y - 24, 18, 10), 0.4)
	k.shape(cabinet, p.wood, p.ink, 1.3)
	var bell := PackedVector2Array([stool + Vector2(0, -26), stool + Vector2(-3, -36), stool + Vector2(-12, -48), stool + Vector2(4, -50), stool + Vector2(2, -36)])
	k.shape(bell, p.brass, p.ink, 1.2)
	# A small portrait on the wall.
	var portrait := k.rough_rect(Rect2(box.position.x + 34, box.position.y + 18, 14, 16), 0.4)
	k.shape(portrait, p.light, p.ink, 1.2)
	k.blob(Vector2(box.position.x + 41, box.position.y + 25), 3.0, Color(p.ink, 0.7))
	k.outline(wall, 2.6, p.ink)
	var sill := k.rough_rect(Rect2(box.position.x - 4, box.end.y, box.size.x + 8, 6), 0.4)
	k.shape(sill, p.stone, p.ink, 1.6)
	k.streak(Vector2(box.position.x + 12, box.end.y + 6), 30, 2.0, p.grime)
	k.streak(Vector2(box.end.x - 20, box.end.y + 6), 22, 1.6, p.grime)

## Tick's Practice: a narrow house with a metronome in the window.
static func _practice(k: Ink, p: Dictionary, door_x: float) -> void:
	var left := 1102.0
	var right := 1294.0
	var top := 268.0
	var body := PackedVector2Array([Vector2(left, GROUND), Vector2(left, top), Vector2(right, top), Vector2(right, GROUND)])
	k.fill(body, p.paper.lerp(p.dust, 0.42))
	k.hatch(body, HATCH + 0.12, 6.5, 0.7, Color(p.ink, 0.06), 0.85)
	k.stipple(PackedVector2Array([Vector2(left, top), Vector2(right, top), Vector2(right, GROUND - 110), Vector2(left, GROUND - 110)]), 260, Color(p.ink, 0.28), 0.8)
	_bricks(k, p, Rect2(left, GROUND - 110, right - left, 110), 9.0, 22.0, 0.55)
	k.shade(body, LIGHT, 0.3, 4.0, 0.8, p.hatch)
	_weather(k, p, Rect2(left, top, right - left, GROUND - top))
	_damp(k, p, Rect2(left, GROUND - 36, right - left, 36))
	# Parapet and the water tank on the roof.
	var parapet := k.rough_rect(Rect2(left - 5, top - 12, right - left + 10, 14), 0.6)
	k.shape(parapet, p.stone.lerp(p.dust, 0.4), p.ink, 2.4)
	var tank := k.rough_rect(Rect2(1132, 196, 54, 48), 1.0)
	k.fill(tank, p.wood)
	for i in 5:
		k.line(Vector2(1135 + i * 11, 198), Vector2(1135 + i * 11, 242), 0.9, Color(p.ink, 0.6), 0.3, 0.0)
	for band: float in [206.0, 232.0]:
		k.line(Vector2(1130, band), Vector2(1188, band), 2.0, p.slate, 0.3, 0.0)
	k.shade(tank, LIGHT, 0.35, 3.2, 0.8, Color(p.ink, 0.5))
	k.outline(tank, 2.4, p.ink)
	var lid := PackedVector2Array([Vector2(1128, 198), Vector2(1159, 180), Vector2(1190, 198)])
	k.shape(lid, p.umber, p.ink, 2.2)
	for leg: float in [1138.0, 1180.0]:
		k.line(Vector2(leg, 244), Vector2(leg - 2, top - 12), 2.4, p.ink, 0.2, 0.0)
	# The window: Tick's metronome, a music stand, the count on the wall.
	var window := Rect2(1146, 300, 102, 78)
	var room := k.rough_rect(window, 0.6)
	k.fill(room, p.paper.lerp(p.patina, 0.14))
	k.crosshatch(k.rect_points(Rect2(window.position, Vector2(window.size.x, 12))), HATCH, 3.6, 0.7, Color(p.ink, 0.4))
	k.hatch(k.rect_points(Rect2(window.end.x - 24, window.position.y + 12, 24, window.size.y - 12)), HATCH, 3.6, 0.8, Color(p.ink, 0.4))
	var table := window.position + Vector2(34, window.size.y - 14)
	k.line(table + Vector2(-20, 0), table + Vector2(20, 0), 2.4, p.ink, 0.2, 0.0)
	k.line(table + Vector2(-16, 0), table + Vector2(-16, 14), 1.6, p.ink, 0.2, 0.0)
	k.line(table + Vector2(16, 0), table + Vector2(16, 14), 1.6, p.ink, 0.2, 0.0)
	var metronome := PackedVector2Array([table + Vector2(-9, -1), table + Vector2(-3, -30), table + Vector2(3, -30), table + Vector2(9, -1)])
	k.shape(metronome, p.wood, p.ink, 1.5)
	k.line(table + Vector2(0, -4), table + Vector2(5, -34), 1.2, p.ink, 0.1, 0.0)
	k.blob(table + Vector2(3, -24), 2.0, p.brass)
	var stand := window.position + Vector2(78, window.size.y)
	k.line(stand, stand + Vector2(0, -40), 1.4, p.ink, 0.2, 0.0)
	var sheet := PackedVector2Array([stand + Vector2(-13, -52), stand + Vector2(12, -55), stand + Vector2(13, -38), stand + Vector2(-12, -36)])
	k.shape(sheet, p.light, p.ink, 1.2)
	for i in 3:
		k.hair(stand + Vector2(-10, -49 + i * 4), stand + Vector2(10, -51 + i * 4), 0.6, Color(p.ink, 0.6))
	k.text(p.body, window.position + Vector2(6, 26), "3 . . 3 . .", 9, Color(p.ink, 0.7))
	k.outline(room, 2.6, p.ink)
	var sill := k.rough_rect(Rect2(window.position.x - 4, window.end.y, window.size.x + 8, 6), 0.4)
	k.shape(sill, p.stone, p.ink, 1.6)
	k.streak(Vector2(window.position.x + 18, window.end.y + 6), 34, 2.0, p.grime)
	k.streak(Vector2(window.end.x - 12, window.end.y + 6), 26, 1.6, p.grime)
	# Ground floor: a small window with a lesson card, the door, the sign.
	var small := Rect2(1116, 512, 30, 46)
	_window(k, p, small, 21)
	var lesson := k.rough_rect(Rect2(1119, 520, 24, 14), 0.4)
	k.shape(lesson, p.light, p.ink, 1.0)
	k.text(p.body, Vector2(1121, 530), "ANY", 7, p.ink)
	var frame := k.rough_rect(Rect2(door_x - 36, GROUND - 104, 72, 104), 0.6)
	k.fill(frame, p.umber)
	k.outline(frame, 2.4, p.ink)
	var step := k.rough_rect(Rect2(door_x - 40, GROUND - 7, 80, 7), 0.5)
	k.shape(step, p.stone, p.ink, 1.8)
	var arm := Vector2(right - 18, 418)
	k.line(arm, arm + Vector2(46, 0), 2.6, p.ink, 0.2, 0.0)
	k.line(arm + Vector2(0, 14), arm + Vector2(22, 0), 1.6, p.ink, 0.2, 0.0)
	for hook: float in [10.0, 40.0]:
		k.line(arm + Vector2(hook, 0), arm + Vector2(hook, 9), 1.0, p.ink, 0.1, 0.0)
	var sign := PackedVector2Array([arm + Vector2(2, 9), arm + Vector2(50, 9), arm + Vector2(50, 46), arm + Vector2(2, 46)])
	k.shape(sign, p.light, p.ink, 2.0)
	var icon := arm + Vector2(14, 40)
	k.shape(PackedVector2Array([icon + Vector2(-6, 0), icon + Vector2(-2, -22), icon + Vector2(2, -22), icon + Vector2(6, 0)]), p.wood, p.ink, 1.2)
	k.line(icon + Vector2(0, -3), icon + Vector2(-4, -24), 1.0, p.ink, 0.1, 0.0)
	k.text(p.display, arm + Vector2(23, 26), "TICK", 10, p.ink)
	k.text(p.display, arm + Vector2(23, 39), "LESSONS", 8, p.ink)
	_poster(k, p, Rect2(1150, 440, 36, 50), "ANY\nTEMPO", 0.04, false)
	_poster(k, p, Rect2(1112, 446, 30, 40), "3 3 3", -0.05, true)
	k.sketch(body, 3.4, p.ink)

## The market front: shutters down, awnings out, nobody minding the stalls.
static func _market(k: Ink, p: Dictionary, stalls_x: float) -> void:
	var left := 1294.0
	var right := 1860.0
	var top := 218.0
	var body := PackedVector2Array([Vector2(left, GROUND), Vector2(left, top), Vector2(right, top), Vector2(right, GROUND)])
	k.fill(body, p.paper.lerp(p.stone, 0.5))
	k.hatch(body, HATCH + 0.12, 6.5, 0.7, Color(p.ink, 0.07), 0.85)
	_bricks(k, p, Rect2(left, top, right - left, 180), 9.0, 22.0, 0.4)
	k.shade(body, LIGHT, 0.22, 4.0, 0.8, p.hatch)
	_weather(k, p, Rect2(left, top, right - left, 180), 3)
	var cornice := k.rough_rect(Rect2(left - 6, top - 14, right - left + 12, 16), 0.6)
	k.shape(cornice, p.umber, p.ink, 2.6)
	for i in 4:
		_window(k, p, Rect2(1330 + i * 96, 236, 40, 52), 31 + i)
	# The signboard, and a runtime plate where a number would be.
	var board := k.rough_rect(Rect2(1312, 304, 316, 40), 0.6)
	k.fill(board, p.umber)
	k.hatch(board, HATCH, 4.0, 0.8, Color(p.deep, 0.35))
	k.outline(board, 2.6, p.ink)
	k.text(p.display, Vector2(1352, 336), "D R Y   G O O D S", 28, p.light)
	var runtime := k.rough_rect(Rect2(1640, 312, 70, 22), 0.4)
	k.shape(runtime, p.light, p.ink, 1.4)
	k.text(p.body, Vector2(1645, 327), "12:04–15:33", 10, p.ink)
	# Three stall bays: striped awnings over corrugated shutters.
	for bay in 3:
		var x := 1304.0 + bay * 110.0
		_stall(k, p, Rect2(x, 396, 104, GROUND - 396), bay)
	# The lane to the Stalls: an arch with the dark market beyond.
	var arch_left := stalls_x - 40.0
	var arch_right := stalls_x + 40.0
	var lane := PackedVector2Array([Vector2(arch_left, GROUND), Vector2(arch_left, 470)])
	for i in 13:
		lane.append(Vector2(stalls_x, 470) + Vector2.from_angle(PI + PI * i / 12.0) * 40.0)
	lane.append(Vector2(arch_right, GROUND))
	k.fill(lane, p.deep.lerp(p.paper, 0.14))
	var floor_beyond := PackedVector2Array([Vector2(arch_left + 6, GROUND), Vector2(stalls_x - 12, 560), Vector2(stalls_x + 12, 560), Vector2(arch_right - 6, GROUND)])
	k.fill(floor_beyond, p.dust.lerp(p.deep, 0.5))
	k.hatch(floor_beyond, HATCH, 3.0, 0.7, Color(p.ink, 0.4))
	for i in 3:
		var y := 540.0 - i * 26.0
		k.line(Vector2(stalls_x - 16 + i * 2, y), Vector2(stalls_x + 16 - i * 2, y + 2), 1.2, Color(p.light, 0.25), 0.3, 0.1)
	k.outline(lane, 3.0, p.ink, 0.5, 0.5)
	var sign := k.rough_rect(Rect2(stalls_x - 46, 400, 92, 22), 0.5)
	k.shape(sign, p.umber, p.ink, 2.0)
	k.text(p.display, Vector2(stalls_x - 40, 417), "THE STALLS →", 14, p.light)
	k.line(Vector2(right - 60, top + 2), Vector2(right - 60, GROUND - 2), 4.0, p.umber, 0.4, 0.0)
	k.line(Vector2(right - 63, top + 2), Vector2(right - 63, GROUND - 2), 1.0, p.ink, 0.3, 0.0)
	_poster(k, p, Rect2(1742, 430, 36, 52), "SOLD\nOUT", 0.05, true)
	_poster(k, p, Rect2(1786, 450, 32, 44), "LAST\nSHOW", -0.04, false)
	_damp(k, p, Rect2(left, GROUND - 38, right - left, 38))
	k.sketch(body, 3.4, p.ink)

static func _stall(k: Ink, p: Dictionary, box: Rect2, index: int) -> void:
	# The shutter: corrugations, a dent, a padlock and a count in chalk.
	var shutter := k.rough_rect(Rect2(box.position.x + 4, box.position.y + 50, box.size.x - 8, box.size.y - 52), 0.5)
	k.fill(shutter, p.slate.lerp(p.paper, 0.55))
	var x := box.position.x + 8.0
	while x < box.end.x - 6:
		k.hair(Vector2(x, box.position.y + 52), Vector2(x, box.end.y - 3), 0.9, Color(p.ink, 0.55))
		k.hair(Vector2(x + 2.2, box.position.y + 52), Vector2(x + 2.2, box.end.y - 3), 0.8, Color(p.light, 0.45))
		x += 6.0
	k.hatch(PackedVector2Array([Vector2(box.position.x + 4, box.end.y - 50), Vector2(box.end.x - 4, box.end.y - 50), Vector2(box.end.x - 4, box.end.y - 2), Vector2(box.position.x + 4, box.end.y - 2)]), HATCH, 4.0, 0.8, Color(p.ink, 0.35))
	var handle := Vector2(box.get_center().x, box.end.y - 14)
	k.line(handle + Vector2(-10, 0), handle + Vector2(10, 0), 2.6, p.ink, 0.2, 0.0)
	var lock := k.rough_rect(Rect2(handle.x - 4, handle.y + 2, 8, 9), 0.3)
	k.shape(lock, p.brass, p.ink, 1.2)
	if index == 1:
		for i in 7:
			var tx := box.position.x + 20 + i * 5.0 + (6.0 if i >= 5 else 0.0)
			if i == 4:
				k.hair(Vector2(tx - 22, box.position.y + 86), Vector2(tx + 2, box.position.y + 72), 1.2, Color(p.light, 0.85))
			else:
				k.hair(Vector2(tx, box.position.y + 70), Vector2(tx, box.position.y + 88), 1.2, Color(p.light, 0.85))
	k.outline(shutter, 2.2, p.ink, 0.4, 0.6)
	# The awning: stripes on its face, a scalloped hem, shade beneath.
	var awning := PackedVector2Array([Vector2(box.position.x - 2, box.position.y), Vector2(box.end.x + 2, box.position.y),
		Vector2(box.end.x + 8, box.position.y + 44), Vector2(box.position.x - 8, box.position.y + 44)])
	k.fill(awning, p.light)
	var stripes := 7
	for s in stripes:
		if s % 2 == 0:
			continue
		var t0 := float(s) / stripes
		var t1 := float(s + 1) / stripes
		var stripe := PackedVector2Array([
			awning[0].lerp(awning[1], t0), awning[0].lerp(awning[1], t1),
			awning[3].lerp(awning[2], t1), awning[3].lerp(awning[2], t0)])
		k.misregistered(stripe, p.red)
	k.hatch(PackedVector2Array([awning[0], awning[1], awning[1] + Vector2(3, 14), awning[0] + Vector2(-3, 14)]), HATCH, 3.2, 0.7, Color(p.ink, 0.4))
	var hem := PackedVector2Array()
	var scallops := 7
	for s in scallops:
		var a := awning[3].lerp(awning[2], float(s) / scallops)
		var b := awning[3].lerp(awning[2], float(s + 1) / scallops)
		for i in 7:
			var t := float(i) / 6.0
			hem.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * 7.0))
	var skirt := PackedVector2Array([awning[3]])
	skirt.append_array(hem)
	skirt.append(awning[2])
	k.fill(skirt, p.light)
	k.path(skirt, 2.0, p.ink, 0.3)
	k.outline(awning, 2.4, p.ink, 0.4, 1.0)
	if index == 2:
		k.crack(awning[3].lerp(awning[2], 0.7) + Vector2(0, -2), Vector2(0.3, -1), 22, 1.2, p.ink, 1)
	k.hatch(PackedVector2Array([Vector2(box.position.x + 4, box.position.y + 50), Vector2(box.end.x - 4, box.position.y + 50), Vector2(box.end.x - 4, box.position.y + 66), Vector2(box.position.x + 4, box.position.y + 62)]), HATCH, 2.6, 0.8, Color(p.ink, 0.5))

# -- the great horn -------------------------------------------------------------------

static func _horn(k: Ink, p: Dictionary) -> void:
	# The plinth: a step, a stone block with its plaque, a cornice.
	var step := k.rough_rect(Rect2(726, GROUND - 14, 168, 14), 0.6)
	k.shape(step, p.stone, p.ink, 2.2)
	var block := PackedVector2Array([Vector2(748, GROUND - 14), Vector2(752, 500), Vector2(868, 500), Vector2(872, GROUND - 14)])
	k.fill(block, p.stone.lerp(p.dust, 0.25))
	k.shade(block, LIGHT, 0.35, 3.6, 0.9, Color(p.ink, 0.5))
	k.flecks_in(block, 30, p.grime, 1.0)
	k.crack(Vector2(758, 504), Vector2(0.3, 1), 30, 1.1, Color(p.ink, 0.8), 1)
	k.crack(Vector2(862, 560), Vector2(-0.6, 0.5), 18, 1.0, Color(p.ink, 0.7), 0)
	var plaque := k.rough_rect(Rect2(768, 507, 84, 36), 0.4)
	k.fill(plaque, p.brass.lerp(p.umber, 0.25))
	k.outline(plaque, 1.8, p.ink, 0.3, 0.6)
	for corner: Vector2 in [Vector2(772, 511), Vector2(848, 511), Vector2(772, 539), Vector2(848, 539)]:
		k.blob(corner, 1.4, p.ink)
	k.text(p.display, Vector2(782, 526), "THE VOICE", 15, p.light)
	k.text(p.body, Vector2(776, 537), "RUNTIME: ALL OF IT", 7, p.light)
	k.streak(Vector2(788, 543), 26, 2.2, Color(p.patina, 0.55))
	k.streak(Vector2(834, 543), 18, 1.8, Color(p.patina, 0.45))
	k.outline(block, 2.6, p.ink)
	var cornice := PackedVector2Array([Vector2(738, 500), Vector2(742, 486), Vector2(878, 486), Vector2(882, 500)])
	k.shape(cornice, p.stone, p.ink, 2.4)
	k.hatch(PackedVector2Array([Vector2(742, 494), Vector2(878, 494), Vector2(882, 500), Vector2(738, 500)]), HATCH, 2.8, 0.7, Color(p.ink, 0.5))
	# The neck: a brass gooseneck rising out of a collar.
	var spine := Ink.cubic(Vector2(810, 488), Vector2(806, 446), Vector2(776, 424), Vector2(790, 388), 16)
	spine.append_array(Ink.cubic(Vector2(790, 388), Vector2(800, 364), Vector2(818, 356), Vector2(838, 350), 10).slice(1))
	var neck_left := PackedVector2Array()
	var neck_right := PackedVector2Array()
	for i in spine.size():
		var ahead := (spine[mini(i + 1, spine.size() - 1)] - spine[maxi(i - 1, 0)]).normalized()
		var normal := ahead.orthogonal()
		var radius := lerpf(15.0, 13.0, float(i) / spine.size())
		neck_left.append(spine[i] + normal * radius)
		neck_right.append(spine[i] - normal * radius)
	var neck := neck_left.duplicate()
	var back := neck_right.duplicate()
	back.reverse()
	neck.append_array(back)
	k.fill(neck, p.brass)
	k.shade(neck, LIGHT, 0.45, 3.0, 0.8, Color(p.ink, 0.55))
	k.stroke(spine.slice(2, spine.size() - 2), 1.6, Color(p.light, 0.55), 0.4, 0.2, 0.3)
	k.path(neck_left, 2.8, p.ink, 0.4)
	k.path(neck_right, 2.8, p.ink, 0.4)
	for t: float in [0.2, 0.55]:
		var at := spine[int(t * (spine.size() - 1))]
		var ahead := (spine[int(t * (spine.size() - 1)) + 1] - at).normalized()
		var band := PackedVector2Array([at + ahead.orthogonal() * 17 - ahead * 3, at + ahead.orthogonal() * 17 + ahead * 3,
			at - ahead.orthogonal() * 17 + ahead * 3, at - ahead.orthogonal() * 17 - ahead * 3])
		k.shape(band, p.brass.lerp(p.umber, 0.35), p.ink, 1.8)
	var collar := k.ellipse_points(Vector2(810, 487), Vector2(22, 6), 0.0, 18)
	k.shape(collar, p.brass.lerp(p.umber, 0.3), p.ink, 2.0)
	# The bell: eight brass petals flaring up and to the right.
	var mouth := Vector2(838, 350)
	var axis := Vector2(1.0, -1.0).normalized()
	var across := axis.orthogonal()
	var rim_center := mouth + axis * 172.0
	var rim := Vector2(114, 38)
	var spin := across.angle()
	var outer_a := Ink.cubic(mouth + across * 13.0, mouth + axis * 70.0 + across * 17.0, rim_center - axis * 42.0 + across * 62.0, rim_center + across * rim.x, 22)
	var outer_b := Ink.cubic(mouth - across * 13.0, mouth + axis * 70.0 - across * 17.0, rim_center - axis * 42.0 - across * 62.0, rim_center - across * rim.x, 22)
	# The flanks close straight across the rim; the near lip is its own half.
	var cone := outer_a.duplicate()
	var flank := outer_b.duplicate()
	flank.reverse()
	cone.append_array(flank)
	var lip := PackedVector2Array()
	for i in 41:
		var angle := lerpf(0.0, -PI, float(i) / 40.0)
		lip.append(rim_center + (Vector2(cos(angle) * rim.x, sin(angle) * rim.y)).rotated(spin))
	k.fill(cone, p.brass)
	k.fill(lip, p.brass)
	# Petal seams and alternate panels.
	# Each seam runs between the flanks and wraps onto the near lip, so the
	# petals stay inside the bell.
	var seams := [-0.72, -0.4, -0.1, 0.22, 0.52, 0.8]
	var seam_lines: Array[PackedVector2Array] = []
	for s: float in seams:
		var u := (s + 1.0) * 0.5
		var wrap := -axis * rim.y * sqrt(maxf(1.0 - s * s, 0.0))
		var curve := PackedVector2Array()
		for i in outer_a.size():
			var t := float(i) / float(outer_a.size() - 1)
			curve.append(outer_b[i].lerp(outer_a[i], u) + wrap * t * t)
		seam_lines.append(curve)
	for i in range(0, seam_lines.size() - 1, 2):
		var panel := seam_lines[i].duplicate()
		var other := seam_lines[i + 1].duplicate()
		other.reverse()
		panel.append_array(other)
		k.fill(panel, Color(p.umber, 0.16), 0.0)
	k.shade(cone, LIGHT, 0.42, 3.4, 0.9, Color(p.ink, 0.5))
	k.shade(cone, LIGHT, 0.16, 3.4, 0.9, Color(p.ink, 0.35), HATCH + PI * 0.5)
	for curve in seam_lines:
		k.stroke(curve, 1.5, Color(p.ink, 0.8), 0.4, 0.12, 0.4)
		for i in range(3, curve.size() - 1, 3):
			k.blob(curve[i] + across * 3.0, 1.2, p.ink)
	# Patina weeping from the seams; a couple of dents.
	for i in 9:
		var curve: PackedVector2Array = seam_lines[k.rng.randi_range(0, seam_lines.size() - 1)]
		var from := curve[k.rng.randi_range(8, curve.size() - 2)]
		k.streak(from, k.rand(14, 34), 2.2, Color(p.patina, 0.5))
	for dent: Vector2 in [mouth + axis * 96.0 + across * 18.0, mouth + axis * 128.0 - across * 34.0]:
		k.stroke(Ink.bezier(dent, dent + Vector2(6, 6), dent + Vector2(14, 2), 6), 1.3, Color(p.ink, 0.7), 0.2, 0.2)
		k.stroke(Ink.bezier(dent + Vector2(1, 3), dent + Vector2(7, 9), dent + Vector2(14, 5), 6), 1.0, Color(p.light, 0.6), 0.2, 0.2)
	k.path(outer_a, 3.2, p.ink, 0.5)
	k.path(outer_b, 3.2, p.ink, 0.5)
	# The open mouth: deep inside, scratched rings going down into the throat.
	var opening := k.ellipse_points(rim_center, rim, spin, 48)
	k.fill(opening, p.deep)
	for i in 4:
		var t := float(i + 1) / 5.0
		var ring := k.ellipse_points(rim_center - axis * t * 34.0, rim * (1.0 - t * 0.78), spin, 36)
		ring.append(ring[0])
		k.stroke(ring, 1.1, Color(p.light, 0.32 - t * 0.2), 0.3, 0.0, 1.0, 8.0)
	k.hatch(opening, PI * 0.15, 5.0, 0.7, Color(p.light, 0.08), 0.6)
	# The rolled lip.
	var lip_ring := opening.duplicate()
	lip_ring.append(opening[0])
	k.stroke(lip_ring, 7.0, p.brass.lerp(p.umber, 0.2), 0.3, 0.0, 1.0, 8.0)
	k.stroke(lip_ring, 1.6, Color(p.light, 0.6), 0.3, 0.0, 1.0, 8.0)
	k.outline(opening, 3.0, p.ink, 0.4, 0.0)
	var outer_lip := k.ellipse_points(rim_center, rim + Vector2(4.5, 4.5), spin, 48)
	k.outline(outer_lip, 2.6, p.ink, 0.4, 0.0)
	for i in 14:
		var angle := TAU * i / 14.0
		k.blob(rim_center + (Vector2(cos(angle) * (rim.x + 2.0), sin(angle) * (rim.y + 2.0))).rotated(spin), 1.3, p.ink)
	# An iron stay holds the bell to the plinth.
	var stay_end := mouth + axis * 96.0 - across * 40.0
	k.line(Vector2(872, 490), stay_end, 3.0, p.slate, 0.3, 0.0)
	k.path(PackedVector2Array([Vector2(872, 490), stay_end]), 1.2, p.ink, 0.3)
	var buckle := Vector2(872, 490).lerp(stay_end, 0.5)
	k.shape(k.ellipse_points(buckle, Vector2(6, 3), (stay_end - Vector2(872, 490)).angle(), 10), p.slate, p.ink, 1.3)

# -- lights, cables and flyers ----------------------------------------------------

static func _lights(k: Ink, p: Dictionary) -> void:
	var runs := [[Vector2(468, 232), Vector2(1104, 280), 56.0], [Vector2(1636, 452), Vector2(1724, 452), 16.0]]
	var colours := [p.light, p.brass, p.red, p.light, p.stone]
	var count := 0
	for run in runs:
		var cable := Ink.sag(run[0], run[1], run[2], 30)
		k.stroke(cable, 1.4, p.ink, 0.2, 0.0, 1.0, 12.0)
		var total := 0.0
		for i in range(1, cable.size()):
			total += cable[i].distance_to(cable[i - 1])
		var spacing := 30.0
		var walked := 0.0
		var next_bulb := spacing * 0.5
		for i in range(1, cable.size()):
			var a := cable[i - 1]
			var b := cable[i]
			var segment := a.distance_to(b)
			while walked + segment >= next_bulb:
				var at := a.lerp(b, (next_bulb - walked) / segment)
				var bulb := at + Vector2(0, 7)
				k.line(at, bulb + Vector2(0, -3), 1.0, p.ink, 0.0, 0.0)
				var glass := k.ellipse_points(bulb, Vector2(3.4, 4.6), 0.0, 10)
				k.fill(glass, colours[count % colours.size()])
				k.outline(glass, 1.1, p.ink, 0.1, 0.2)
				k.fill(k.rough_rect(Rect2(bulb.x - 2, bulb.y - 6, 4, 3), 0.2), p.ink)
				count += 1
				next_bulb += spacing
			walked += segment
	_laundry(k, p, Vector2(1296, 262), Vector2(1428, 268), 20.0)
	# Flyers hung on the long run, turning in no wind.
	var long_cable := Ink.sag(runs[0][0], runs[0][1], runs[0][2], 30)
	for t: float in [0.32, 0.58]:
		var at := long_cable[int(t * 30)]
		var flyer := PackedVector2Array([at + Vector2(-9, 2), at + Vector2(10, 1), at + Vector2(11, 27), at + Vector2(-8, 28)])
		k.shape(flyer, p.light, p.ink, 1.2)
		for i in 3:
			k.hair(at + Vector2(-5, 9 + i * 5), at + Vector2(7, 8 + i * 5), 0.7, Color(p.ink, 0.6))
		k.blob(at + Vector2(1, 2), 1.5, p.red)

## Somebody still does their washing: a line between the Practice and the
## market, a shirt, a pair of socks, and a sleeve pegged out to dry.
static func _laundry(k: Ink, p: Dictionary, a: Vector2, b: Vector2, drop: float) -> void:
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

# -- street furniture and litter ------------------------------------------------------

static func _street_props(k: Ink, p: Dictionary) -> void:
	# Crates by the first stall, stamped and never sent.
	_crate(k, p, Rect2(1306, GROUND - 46, 52, 46), "CANCELLED")
	_crate(k, p, Rect2(1360, GROUND - 38, 44, 38), "")
	_crate(k, p, Rect2(1318, GROUND - 82, 40, 36), "")
	_barrel(k, p, Vector2(1448, GROUND), 17.0, 40.0)
	# A hand cart with records leaning in it.
	_cart(k, p, Vector2(1560, GROUND))
	# A bench beside the horn for whoever comes to listen.
	_bench(k, p, Vector2(1046, GROUND))
	# A bin under the ledge, and a grate over the drain shaft.
	var bin := PackedVector2Array([Vector2(452, GROUND), Vector2(448, GROUND - 40), Vector2(476, GROUND - 40), Vector2(472, GROUND)])
	k.fill(bin, p.slate.lerp(p.paper, 0.4))
	for i in 4:
		k.line(Vector2(453 + i * 6, GROUND - 38), Vector2(454 + i * 5, GROUND - 2), 0.9, Color(p.ink, 0.6), 0.2, 0.0)
	k.outline(bin, 2.0, p.ink)
	k.shape(k.rough_rect(Rect2(445, GROUND - 45, 34, 6), 0.4), p.slate, p.ink, 1.8)
	var grate := Rect2(682, GROUND - 3, 34, 5)
	k.fill(k.rect_points(grate), p.deep)
	for i in 5:
		k.line(Vector2(686 + i * 6.5, GROUND - 3), Vector2(686 + i * 6.5, GROUND + 2), 1.0, p.stone, 0.0, 0.0)
	# Litter: dropped tapes and loose ribbon.
	_tape(k, p, Vector2(1490, GROUND - 4), 0.7, -0.1)
	_tape(k, p, Vector2(1615, GROUND - 3), 0.6, 0.15)
	_tape(k, p, Vector2(215, GROUND - 4), 0.6, 0.05)
	k.stroke(Ink.cubic(Vector2(1500, GROUND - 3), Vector2(1520, GROUND - 16), Vector2(1540, GROUND + 2), Vector2(1562, GROUND - 6), 14), 1.2, p.umber, 0.3, 0.1, 0.5)
	k.stroke(Ink.cubic(Vector2(226, GROUND - 3), Vector2(240, GROUND - 12), Vector2(262, GROUND + 1), Vector2(280, GROUND - 2), 12), 1.2, p.umber, 0.3, 0.1, 0.5)

# -- shared pieces ---------------------------------------------------------------------

## Brick courses drawn the way a hand draws them: every course, joints here
## and there, a few bricks picked out darker.
static func _bricks(k: Ink, p: Dictionary, area: Rect2, course: float, brick: float, strength: float) -> void:
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
static func _weather(k: Ink, p: Dictionary, area: Rect2, cracks := 2) -> void:
	for i in maxi(int(area.size.x * area.size.y / 9000.0), 2):
		var at := area.position + Vector2(k.rand(0.1, 0.9) * area.size.x, k.rand(0.1, 0.9) * area.size.y)
		k.stain(at, k.rand(10, 26), Color(p.umber, k.rand(0.04, 0.08)), k.chance(0.4))
	for i in cracks:
		var from := area.position + Vector2(k.rand(0.05, 0.95) * area.size.x, k.rand(0.0, 0.4) * area.size.y)
		k.crack(from, Vector2(k.rand(-0.5, 0.5), 1.0), k.rand(18, 40), 1.0, Color(p.ink, 0.7), 1)

## Rising damp: a soiled band along the foot of a wall, ragged at its top.
static func _damp(k: Ink, p: Dictionary, band: Rect2) -> void:
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
static func _window(k: Ink, p: Dictionary, box: Rect2, seed_value: int, boarded := false) -> void:
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
static func _poster(k: Ink, p: Dictionary, box: Rect2, words: String, tilt: float, stamped: bool) -> void:
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

static func _crate(k: Ink, p: Dictionary, box: Rect2, stamp: String) -> void:
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

static func _barrel(k: Ink, p: Dictionary, base: Vector2, radius: float, height: float) -> void:
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

static func _tape(k: Ink, p: Dictionary, center: Vector2, scale: float, tilt: float) -> void:
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

static func _lantern(k: Ink, p: Dictionary, hook: Vector2) -> void:
	k.line(hook, hook + Vector2(0, 10), 1.2, p.ink, 0.1, 0.0)
	var cap := PackedVector2Array([hook + Vector2(-8, 16), hook + Vector2(0, 9), hook + Vector2(8, 16)])
	k.shape(cap, p.slate, p.ink, 1.6)
	var glass := k.rough_rect(Rect2(hook.x - 6, hook.y + 16, 12, 16), 0.3)
	k.fill(glass, p.brass.lerp(p.light, 0.3))
	k.line(Vector2(hook.x, hook.y + 16), Vector2(hook.x, hook.y + 32), 1.0, p.ink, 0.1, 0.0)
	k.outline(glass, 1.6, p.ink, 0.2, 0.4)
	k.shape(k.rough_rect(Rect2(hook.x - 7, hook.y + 32, 14, 4), 0.2), p.slate, p.ink, 1.4)

static func _bench(k: Ink, p: Dictionary, base: Vector2) -> void:
	var seat := k.rough_rect(Rect2(base.x - 36, base.y - 24, 72, 6), 0.4)
	k.shape(seat, p.wood, p.ink, 1.8)
	var back := k.rough_rect(Rect2(base.x - 34, base.y - 48, 68, 14), 0.4)
	k.fill(back, p.wood)
	k.line(Vector2(base.x - 34, base.y - 41), Vector2(base.x + 34, base.y - 41), 0.8, Color(p.ink, 0.6), 0.2, 0.0)
	k.outline(back, 1.8, p.ink, 0.3, 0.5)
	for side: float in [-1.0, 1.0]:
		var leg := PackedVector2Array([base + Vector2(side * 30, 0), base + Vector2(side * 32, -48), base + Vector2(side * 27, -48), base + Vector2(side * 25, 0)])
		k.shape(leg, p.slate, p.ink, 1.5)

static func _cart(k: Ink, p: Dictionary, base: Vector2) -> void:
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
