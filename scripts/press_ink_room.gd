extends RefCounted
## Any room but Horn Plaza, printed in the canon's ink from its own geometry
## (ink_look.gd, ink_plate.gd). The room's solid faces become its street,
## ledges and walls; its passages become archways, doorways and cuts, named;
## its authored landmarks are drawn again in ink where the room put them; and
## the rest is dressed by the kind of place it is, from the set kit
## (press_ink_set.gd): building fronts between the passages of a street, the
## earth cut away beneath it, papered walls and fittings inside, brick vaults
## and cut rock in the Overture, cut wax below the Scratch.
##
## Pure drawing. `describe` turns what the plate read from the room into
## plain data; `draw` composes a plane from that data and a seed, records it
## once and replays it. Nothing here adds collision, reads the player or owns
## a clock. Light comes from the upper left; hatching rises to the right.

const Ink := preload("res://scripts/press_ink.gd")
const InkLook := preload("res://scripts/ink_look.gd")
const Set := preload("res://scripts/press_ink_set.gd")
const Light := preload("res://scripts/press_ink_light.gd")
const Profiles := preload("res://scripts/lighting_profiles.gd")

const LIGHT := Set.LIGHT
const HATCH := Set.HATCH

## What kind of place each room is. The kind decides the dressing.
##   street    the Label above ground: the town behind, building fronts
##             between the passages, cobbles, the earth cut away beneath
##   interior  a room off the street: papered walls, a ceiling, fittings
##   yard      the Groove Yard: a brick wall, the roofs beyond, headstones
##   stair     cut stone going down: the Label Descent, the Overture Stair
##   vault     the Overture, underground: brick vaults and cut rock
##   deep      the Unplayed, below the Scratch: cut wax, scratchboard
const KINDS := {
	&"headshell": &"interior", &"horn_plaza": &"street", &"high_street": &"street", &"practice_room": &"interior",
	&"the_stalls": &"street", &"groove_yard": &"yard", &"label_descent": &"stair", &"overture_stair": &"stair",
	&"rooms_to_let": &"interior", &"print_shop": &"interior", &"stall_cache": &"interior", &"label_balcony": &"street",
	&"unsigned_alcove": &"vault",
	&"bootlegger": &"vault", &"whistlers": &"vault", &"addie": &"vault", &"overture_well": &"vault",
	&"worn_gallery": &"vault", &"smoothed_floor": &"vault", &"the_arm": &"vault",
	&"the_drop": &"deep", &"the_landing": &"deep", &"verse_hall": &"deep", &"verse_warren_n": &"deep",
	&"verse_warren_s": &"deep", &"deep_gallery": &"deep",
}

## Trades on the shop cards along a street. Nobody says needle or stylus.
const TRADES := ["RECORDS", "REPAIRS", "SLEEVES", "PRESSINGS", "TAPES", "ALL NIGHT", "CLOSED", "TO LET", "LABELS", "ONE OWNER"]
const FLYERS := ["LAST\nNIGHT", "ONE\nNIGHT", "ANY\nTEMPO", "33⅓", "NO\nDUST", "SOLD\nOUT"]

static var _tapes: Dictionary = {}

static func kind_of(room_id: StringName) -> StringName:
	return KINDS.get(room_id, &"street")

## Whether the passage from `room_id` to `target` is an open way (an archway
## or a cut) rather than a door in a building.
static func is_arch(room_id: StringName, target: StringName) -> bool:
	var here := kind_of(room_id)
	var there := kind_of(target)
	if here == &"interior" or there == &"interior":
		return false
	if here == &"street" and there == &"stair":
		return false
	return true

## Forgets a room's recorded planes (a surface was added, or a test wants a
## fresh drawing).
static func forget(room_id: StringName) -> void:
	for key in _tapes.keys():
		if key[0] == room_id:
			_tapes.erase(key)

static func clear_cache() -> void:
	_tapes.clear()

# == the room as data =================================================================

## Turns what the plate read from the room into the drawing's plain data:
## which faces are the street, the ledges and the walls, where the ground
## is, what each passage is and where it stands.
static func describe(room_id: StringName, bounds: Rect2, surfaces: Array[Rect2], passages: Array[Dictionary],
		landmarks: Array[Dictionary], spawn: Vector2) -> Dictionary:
	var kind := kind_of(room_id)
	var floors: Array[Rect2] = []
	var walls: Array[Rect2] = []
	for surface in surfaces:
		if surface.size.y > 240.0 and surface.size.x <= 80.0:
			walls.append(surface)
		elif surface.size.x >= 60.0 and surface.size.y >= 12.0:
			floors.append(surface)
	# The ground: the widest face, the lowest of those if two tie.
	var ground := Rect2(bounds.position.x, bounds.end.y - 60.0, bounds.size.x, 60.0)
	var best := -1.0
	for floor in floors:
		var score := floor.size.x + floor.position.y * 0.01
		if score > best:
			best = score
			ground = floor
	var ground_y := ground.position.y
	var ways: Array[Dictionary] = []
	for passage in passages:
		var at: Vector2 = passage.at
		var foot := _ground_under(at, floors)
		ways.append({"target": StringName(passage.target), "at": Vector2(at.x, foot), "name": String(passage.get("name", "")),
			"arch": is_arch(room_id, StringName(passage.target))})
	ways.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return Vector2(a.at).x < Vector2(b.at).x)
	var seed_value := hash(String(room_id)) & 0x7fffffff
	var scene := {
		"room_id": room_id, "kind": kind, "bounds": bounds, "floors": floors, "walls": walls, "ground": ground,
		"ground_y": ground_y, "ways": ways, "landmarks": landmarks, "spawn": spawn, "seed": seed_value,
	}
	scene["lots"] = _plan_lots(scene) if kind in [&"street", &"yard"] else []
	scene["props"] = _plan_props(scene)
	scene["lanterns"] = _plan_lanterns(scene)
	return scene

## The face a passage stands on: the nearest floor top under it.
static func _ground_under(at: Vector2, floors: Array[Rect2]) -> float:
	var foot := at.y + 26.0
	var nearest := 160.0
	for floor in floors:
		if at.x >= floor.position.x - 8.0 and at.x <= floor.end.x + 8.0:
			var drop := floor.position.y - at.y
			if drop >= -4.0 and drop < nearest:
				nearest = drop
				foot = floor.position.y
	return foot

## A street's building lots: a gate lot round every archway, a house round
## every door, and ordinary fronts filling the gaps between them.
static func _plan_lots(scene: Dictionary) -> Array[Dictionary]:
	var bounds: Rect2 = scene.bounds
	var ground_y := float(scene.ground_y)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(scene.seed) + 7
	var fixed: Array[Dictionary] = []
	for way: Dictionary in scene.ways:
		var x := Vector2(way.at).x
		if bool(way.arch):
			fixed.append({"left": x - 112.0, "right": x + 112.0, "gate": x, "door": -1.0, "name": way.name})
		else:
			var left := x - rng.randf_range(90.0, 170.0)
			fixed.append({"left": left, "right": left + rng.randf_range(240.0, 330.0), "gate": -1.0, "door": x, "name": way.name})
	fixed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.left) < float(b.left))
	# Overlapping fixed lots share their boundary.
	for i in range(1, fixed.size()):
		if float(fixed[i].left) < float(fixed[i - 1].right) + 20.0:
			var middle := (float(fixed[i].left) + float(fixed[i - 1].right)) * 0.5
			fixed[i - 1]["right"] = middle - 10.0
			fixed[i]["left"] = middle + 10.0
	var lots: Array[Dictionary] = []
	var x := bounds.position.x - 60.0
	var index := 0
	var market_boxes: Array[Rect2] = []
	for landmark: Dictionary in scene.landmarks:
		if landmark.kind == &"market":
			var size: Vector2 = landmark.size
			market_boxes.append(Rect2(Vector2(landmark.at) - size * 0.5, size))
	var stop := bounds.end.x + 60.0
	while x < stop:
		var next_fixed: Dictionary = fixed[index] if index < fixed.size() else {}
		var lot: Dictionary
		if not next_fixed.is_empty() and x >= float(next_fixed.left) - 90.0:
			lot = next_fixed.duplicate()
			lot["left"] = maxf(float(lot.left), x)
			index += 1
		else:
			var width := rng.randf_range(170.0, 320.0)
			if not next_fixed.is_empty():
				width = minf(width, float(next_fixed.left) - x - 4.0)
			if width < 70.0:
				x = float(next_fixed.left)
				continue
			lot = {"left": x, "right": x + width, "gate": -1.0, "door": -1.0, "name": ""}
		lot["eave"] = ground_y - rng.randf_range(300.0, 430.0)
		lot["seed"] = rng.randi()
		lot["shop"] = float(lot.gate) < 0.0 and float(lot.right) - float(lot.left) > 210.0 and rng.randf() < 0.6
		lot["market"] = false
		for box in market_boxes:
			if box.position.x < float(lot.right) and box.end.x > float(lot.left) and float(lot.gate) < 0.0:
				lot["market"] = true
		lots.append(lot)
		x = float(lot.right) + rng.randf_range(0.0, 12.0)
	return lots

## Street furniture along the ground, clear of the passages and the spawn.
static func _plan_props(scene: Dictionary) -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	var kind: StringName = scene.kind
	if kind == &"deep":
		return props
	var ground: Rect2 = scene.ground
	var ground_y := float(scene.ground_y)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(scene.seed) + 11
	var kinds: Array = [&"crate", &"barrel", &"tapes", &"bench", &"cart", &"crates", &"bin"]
	if kind in [&"vault", &"stair"]:
		kinds = [&"crate", &"barrel", &"tapes", &"crates", &"chain", &"pipe"]
	elif kind == &"interior":
		kinds = [&"crate", &"tapes", &"crates", &"stool"]
	var count := clampi(int(ground.size.x / 260.0), 1, 7)
	var tries := 0
	while props.size() < count and tries < 40:
		tries += 1
		var x := rng.randf_range(ground.position.x + 60.0, ground.end.x - 60.0)
		if not _clear(x, scene, 80.0):
			continue
		var clear := true
		for prop in props:
			if absf(float(prop.x) - x) < 110.0:
				clear = false
		if not clear:
			continue
		props.append({"x": x, "kind": kinds[rng.randi() % kinds.size()], "seed": rng.randi(), "y": ground_y})
	return props

## Where the lamps stand: a post or a wall lantern or two, clear of the
## passages, near the middle of the street and by its ends.
static func _plan_lanterns(scene: Dictionary) -> Array[Vector2]:
	var lanterns: Array[Vector2] = []
	var ground: Rect2 = scene.ground
	var ground_y := float(scene.ground_y)
	var kind: StringName = scene.kind
	var rng := RandomNumberGenerator.new()
	rng.seed = int(scene.seed) + 13
	var count := 1 if ground.size.x < 1000.0 else 2
	if kind == &"deep":
		count = 1
	for i in count:
		var share := (i + 0.5) / count
		for attempt in 8:
			var x := ground.position.x + ground.size.x * share + rng.randf_range(-120.0, 120.0)
			if _clear(x, scene, 90.0):
				var height := 118.0 if kind in [&"street", &"yard"] else 150.0
				lanterns.append(Vector2(x, ground_y - height))
				break
	return lanterns

static func _clear(x: float, scene: Dictionary, margin: float) -> bool:
	for way: Dictionary in scene.ways:
		if absf(Vector2(way.at).x - x) < margin:
			return false
	if absf(Vector2(scene.spawn).x - x) < margin * 0.7:
		return false
	for landmark: Dictionary in scene.landmarks:
		if landmark.kind in [&"headstone", &"column", &"counter", &"headshell", &"resting_arm"] and absf(Vector2(landmark.at).x - x) < margin:
			return false
	return true

# == drawing ============================================================================

static func draw(canvas: CanvasItem, plane: StringName, state: Dictionary, display: Font, body: Font) -> void:
	var scene: Dictionary = state.get("scene", {})
	if scene.is_empty():
		return
	var scratchboard := bool(state.get("scratchboard", state.get("far_face", false)))
	var room_id: StringName = scene.room_id
	var key := [room_id, plane, scratchboard]
	if not _tapes.has(key):
		var k := Ink.new(canvas, (int(scene.seed) + hash(String(plane))) & 0x7fffffff, true)
		var p := Set.palette(scratchboard)
		p["display"] = display
		p["body"] = body
		p["scratchboard"] = scratchboard
		match plane:
			&"paper": _paper(k, p, scene)
			&"far": _far(k, p, scene)
			&"set": _set_plane(k, p, scene)
			&"light": Light.draw_plane(k, light_rig(scene), scratchboard)
		k.flush()
		_tapes[key] = k.tape
	Ink.play(canvas, _tapes[key])

# -- the sheet -------------------------------------------------------------------------

static func _paper(k: Ink, p: Dictionary, scene: Dictionary) -> void:
	var bounds: Rect2 = scene.bounds
	var sheet := bounds.grow(420.0)
	k.fill(k.rect_points(sheet), p.paper, 0.0)
	var area := sheet.size.x * sheet.size.y
	if bool(p.scratchboard):
		# Wax: the grooves of the record itself, faint rings across the page.
		var hub := Vector2(bounds.get_center().x, bounds.end.y + 1400.0)
		for i in 26:
			var radius := 1200.0 + i * 38.0 + k.rand(-6, 6)
			var ring := k.ellipse_points(hub, Vector2(radius, radius), 0.0, 140, PI * 1.1, PI * 1.9)
			k.stroke(ring, 0.8 if i % 5 != 0 else 1.4, Color(p.ink, 0.05 if i % 5 != 0 else 0.1), 0.6, 0.02, 0.4, 16.0)
	else:
		# Old water damage and handling: broad, faint tide-marked stains.
		for i in int(area / 320000.0):
			var at := Vector2(k.rand(sheet.position.x + 200, sheet.end.x - 200), k.rand(sheet.position.y + 200, sheet.end.y - 400))
			k.stain(at, k.rand(50, 170), Color(p.umber, k.rand(0.025, 0.05)))
		# A fold across the sheet: one light edge, one dark.
		var fold_x := bounds.position.x + bounds.size.x * 0.38
		var fold_y := bounds.position.y + bounds.size.y * 0.38
		for fold: Array in [[Vector2(fold_x, sheet.position.y), Vector2(fold_x + 15, sheet.end.y)], [Vector2(sheet.position.x, fold_y), Vector2(sheet.end.x, fold_y - 14)]]:
			k.line(fold[0], fold[1], 2.2, Color(p.light, 0.35), 1.5, 0.0)
			k.line(fold[0] + Vector2(1.6, 1.6), fold[1] + Vector2(1.6, 1.6), 1.0, Color(p.ink, 0.07), 1.5, 0.0)
		# The label's own printed rim, far off: rings and rim type.
		var hub := Vector2(bounds.get_center().x, bounds.end.y + 900.0)
		for radius: float in [1606.0, 1580.0, 1500.0]:
			var ring := k.ellipse_points(hub, Vector2(radius, radius), 0.0, 180, PI * 1.08, PI * 1.92)
			k.stroke(ring, 1.4 if radius != 1580.0 else 0.8, Color(p.ink, 0.08), 1.0, 0.04, 0.4, 14.0)
		k.arc_text(p.display, hub, 1592.0, PI * 1.262,
			"THE LABEL  ·  SIDE ONE  ·  ALL THAT WAS PLAYED  ·  33⅓  ·  MADE TO BE PLAYED ONCE  ·  KEEP AWAY FROM HEAT",
			20, Color(p.ink, 0.11), 1.18)
	# Tooth: fibres and specks over everything.
	for i in int(area / 3700.0):
		var at := Vector2(k.rand(sheet.position.x, sheet.end.x), k.rand(sheet.position.y, sheet.end.y))
		var turn := Vector2.from_angle(k.rand(0.0, TAU)) * k.rand(1.5, 5.0)
		k.hair(at - turn, at + turn, 0.6, Color(p.ink, k.rand(0.03, 0.07)))
	for i in int(area / 6800.0):
		k.blob(Vector2(k.rand(sheet.position.x, sheet.end.x), k.rand(sheet.position.y, sheet.end.y)), k.rand(0.4, 1.2), Color(p.ink, k.rand(0.05, 0.14)), 4)

# -- the far plane (moves a little with the camera) --------------------------------------

static func _far(k: Ink, p: Dictionary, scene: Dictionary) -> void:
	var kind: StringName = scene.kind
	var bounds: Rect2 = scene.bounds
	var ground_y := float(scene.ground_y)
	match kind:
		&"street", &"yard":
			_far_town(k, p, bounds.position.x - 160.0, bounds.end.x + 160.0, ground_y - 60.0)
		&"stair", &"vault":
			# The rock further back, darker and softer.
			var back := Rect2(bounds.position.x - 160.0, bounds.position.y - 160.0, bounds.size.x + 320.0, bounds.size.y + 320.0)
			k.fill(k.rect_points(back), p.paper.lerp(p.umber, 0.22).lerp(p.dust, 0.3), 0.0)
			k.hatch(k.rect_points(back), HATCH, 7.0, 0.8, Color(p.ink, 0.12), 0.9)
			k.flecks(back, int(back.size.x * back.size.y / 1400.0), Color(p.ink, 0.22), 1.1)
		&"deep":
			var back := Rect2(bounds.position.x - 160.0, bounds.position.y - 160.0, bounds.size.x + 320.0, bounds.size.y + 320.0)
			k.fill(k.rect_points(back), p.paper.lerp(p.dust, 0.35), 0.0)
			var y := back.position.y
			while y < back.end.y:
				k.hair(Vector2(back.position.x, y), Vector2(back.end.x, y + k.rand(-2, 2)), 0.8, Color(p.ink, 0.12))
				y += k.rand(9, 16)
		_:
			pass

## Drawn as a printer draws distance: thin, pale, barely there.
static func _far_town(k: Ink, p: Dictionary, from_x: float, to_x: float, base: float) -> void:
	var line := Color(p.ink, 0.2)
	var flat: Color = p.paper.lerp(p.dust, 0.2)
	var x := from_x
	while x < to_x:
		var width := k.rand(70, 150)
		var top := base - k.rand(140, 240)
		var body := PackedVector2Array()
		var roof := k.rng.randi_range(0, 2)
		if roof == 0:
			body = PackedVector2Array([Vector2(x, base), Vector2(x, top), Vector2(x + width * 0.5, top - k.rand(30, 55)), Vector2(x + width, top), Vector2(x + width, base)])
		elif roof == 1:
			body = PackedVector2Array([Vector2(x, base), Vector2(x, top), Vector2(x + width, top), Vector2(x + width, base)])
		else:
			body = PackedVector2Array([Vector2(x, base), Vector2(x, top + 14), Vector2(x + width * 0.2, top), Vector2(x + width * 0.8, top), Vector2(x + width, top + 14), Vector2(x + width, base)])
		k.fill(body, flat)
		k.hatch(body, HATCH, 6.0, 0.7, Color(p.ink, 0.06), 0.6)
		k.outline(body, 1.0, line, 0.4, 1.0)
		for row in range(int((base - top) / 34.0)):
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
	var tower := Vector2(lerpf(from_x, to_x, 0.78), base - 240.0)
	var tank := k.rough_rect(Rect2(tower.x - 30, tower.y - 52, 60, 46), 0.8)
	k.fill(tank, flat)
	k.hatch(tank, HATCH, 5.0, 0.7, Color(p.ink, 0.08))
	k.outline(tank, 1.4, line)
	for leg: float in [-22.0, 22.0]:
		k.line(tower + Vector2(leg, -6), tower + Vector2(leg * 1.3, 240), 1.2, line, 0.2, 0.0)
	k.line(tower + Vector2(-24, 90), tower + Vector2(24, 90), 1.0, line, 0.2, 0.0)
	var roofs := PackedVector2Array()
	var rx := from_x
	while rx < to_x:
		roofs.append(Vector2(rx, base + k.rand(-6, 6)))
		rx += k.rand(60, 140)
	roofs.append(Vector2(to_x, base))
	k.stroke(roofs, 2.0, Color(p.ink, 0.35), 0.6, 0.02, 0.3, 12.0)

# -- the set ---------------------------------------------------------------------------

static func _set_plane(k: Ink, p: Dictionary, scene: Dictionary) -> void:
	var kind: StringName = scene.kind
	match kind:
		&"street": _street_set(k, p, scene)
		&"yard": _yard_set(k, p, scene)
		&"interior": _interior_set(k, p, scene)
		&"stair", &"vault": _vault_set(k, p, scene)
		&"deep": _deep_set(k, p, scene)
	_floors(k, p, scene)
	_passages(k, p, scene)
	for landmark: Dictionary in scene.landmarks:
		_landmark(k, p, landmark, scene)
	_props(k, p, scene)
	_lanterns(k, p, scene)

## The Label's streets: building fronts along the back of the street, the
## earth cut away beneath it.
static func _street_set(k: Ink, p: Dictionary, scene: Dictionary) -> void:
	_cutaway(k, p, scene)
	for lot: Dictionary in scene.lots:
		if float(lot.gate) >= 0.0:
			_gate(k, p, lot, scene)
		else:
			_facade(k, p, lot, scene)
	_side_walls(k, p, scene, &"brick")

## The Groove Yard: a low brick wall with the town's roofs beyond, the earth
## below it full of what was buried.
static func _yard_set(k: Ink, p: Dictionary, scene: Dictionary) -> void:
	var bounds: Rect2 = scene.bounds
	var ground_y := float(scene.ground_y)
	_cutaway(k, p, scene)
	var wall := Rect2(bounds.position.x - 60.0, ground_y - 230.0, bounds.size.x + 120.0, 230.0)
	Set.wall(k, p, wall, 0.5, 46.0)
	var coping := k.rough_rect(Rect2(wall.position.x, wall.position.y - 10.0, wall.size.x, 12.0), 0.8)
	k.shape(coping, p.stone, p.ink, 2.2)
	# Ivy over the coping here and there, trailing down the brick.
	for i in maxi(int(wall.size.x / 420.0), 1):
		var x := wall.position.x + k.rand(0.1, 0.9) * wall.size.x
		for strand in 4:
			var top := Vector2(x + strand * 16.0 - 24.0 + k.rand(-6, 6), wall.position.y - 12.0)
			var length := k.rand(40, 120)
			var stem := Ink.cubic(top, top + Vector2(k.rand(-10, 10), length * 0.4), top + Vector2(k.rand(-14, 14), length * 0.7), top + Vector2(k.rand(-8, 8), length), 10)
			k.stroke(stem, 1.1, Color(p.ink, 0.6), 0.3, 0.05, 0.5, 12.0)
			for leaf in int(length / 11.0):
				var at: Vector2 = stem[mini(int(leaf * stem.size() / (length / 11.0)), stem.size() - 1)] + Vector2(k.rand(-5, 5), 0)
				var sprig := k.ellipse_points(at, Vector2(k.rand(3, 5.5), k.rand(2, 3.5)), k.rand(-0.6, 0.6), 6)
				k.fill(sprig, p.patina.lerp(p.paper, 0.2))
				k.outline(sprig, 0.9, Color(p.ink, 0.55), 0.2, 0.3)
	for lot: Dictionary in scene.lots:
		if float(lot.gate) >= 0.0:
			_gate(k, p, lot, scene)
	_side_walls(k, p, scene, &"brick")

## Inside: papered walls, a ceiling line with its cord and lamp, a skirting,
## and the fittings of whatever this room is for.
static func _interior_set(k: Ink, p: Dictionary, scene: Dictionary) -> void:
	var bounds: Rect2 = scene.bounds
	var ground_y := float(scene.ground_y)
	var ceiling := maxf(bounds.position.y + 70.0, ground_y - 470.0)
	var wall := Rect2(bounds.position.x - 60.0, ceiling, bounds.size.x + 120.0, ground_y - ceiling)
	Set.papered_wall(k, p, wall, int(scene.seed))
	# The ceiling: a cornice, the boards above it going dark.
	var above := Rect2(wall.position.x, bounds.position.y - 200.0, wall.size.x, ceiling - bounds.position.y + 200.0)
	k.fill(k.rect_points(above), p.paper.lerp(p.umber, 0.3), 0.0)
	k.hatch(k.rect_points(above), HATCH, 4.5, 0.9, Color(p.ink, 0.35))
	var y := ceiling - 14.0
	while y > above.position.y:
		k.hair(Vector2(above.position.x, y), Vector2(above.end.x, y + k.rand(-1, 1)), 1.0, Color(p.ink, 0.45))
		y -= k.rand(12, 22)
	var cornice := k.rough_rect(Rect2(wall.position.x, ceiling - 8.0, wall.size.x, 10.0), 0.6)
	k.shape(cornice, p.stone.lerp(p.dust, 0.3), p.ink, 2.2)
	# A skirting board along the floor.
	var skirting := k.rough_rect(Rect2(wall.position.x, ground_y - 12.0, wall.size.x, 12.0), 0.5)
	k.shape(skirting, p.umber, p.ink, 2.0)
	# The floorboards under the street's slabs are the room's floor: the
	# ground is drawn as boards here (see _floors).
	_fittings(k, p, scene, wall, ceiling)
	_side_walls(k, p, scene, &"paper")

## Underground: cut rock either side, brick vaulting overhead, the arches of
## the vault along the back, a pipe and a chain or two.
static func _vault_set(k: Ink, p: Dictionary, scene: Dictionary) -> void:
	var bounds: Rect2 = scene.bounds
	var back := Rect2(bounds.position.x - 80.0, bounds.position.y - 120.0, bounds.size.x + 160.0, bounds.size.y + 320.0)
	Set.rock(k, p, back, int(scene.seed))
	# Brick vaulting along the back wall: arches on piers.
	var ground_y := float(scene.ground_y)
	var pitch := 300.0
	var x := bounds.position.x + 40.0
	var index := 0
	while x + pitch < bounds.end.x + 40.0:
		var center := Vector2(x + pitch * 0.5, ground_y - 230.0)
		var radius := pitch * 0.42
		var bay := PackedVector2Array()
		bay.append(Vector2(center.x - radius, ground_y))
		for i in 15:
			bay.append(center + Vector2.from_angle(PI + PI * i / 14.0) * radius)
		bay.append(Vector2(center.x + radius, ground_y))
		k.fill(bay, p.paper.lerp(p.deep, 0.16).lerp(p.dust, 0.25))
		k.crosshatch(bay, HATCH, 5.0, 0.8, Color(p.ink, 0.2))
		for i in 11:
			var angle := PI + PI * (i + 0.5) / 11.0
			var a := center + Vector2.from_angle(angle) * radius
			var b := center + Vector2.from_angle(angle) * (radius + 16.0)
			var c := center + Vector2.from_angle(angle + PI / 11.0) * (radius + 16.0)
			var d := center + Vector2.from_angle(angle + PI / 11.0) * radius
			var voussoir := PackedVector2Array([a, b, c, d])
			k.fill(voussoir, p.stone.lerp(p.umber, k.rand(0.2, 0.6)))
			k.outline(voussoir, 1.3, p.ink, 0.3, 0.5)
		for side: float in [-1.0, 1.0]:
			var pier := Rect2(center.x + side * (radius + 2.0) - 12.0, center.y, 24.0, ground_y - center.y)
			var face := k.rough_rect(pier, 0.8)
			k.fill(face, p.paper.lerp(p.dust, 0.4))
			Set.bricks(k, p, pier, 9.0, 24.0, 0.6)
			k.shade(face, LIGHT, 0.4, 3.4, 0.8, Color(p.ink, 0.45))
			k.outline(face, 2.2, p.ink, 0.4, 0.8)
		if index % 2 == 1:
			# A chain hanging in the bay, and a ring it hangs from.
			var hook := Vector2(center.x + k.rand(-60, 60), center.y - radius + 10.0)
			k.blob(hook, 3.0, p.slate, 8)
			var link := hook
			for i in int(k.rand(5, 11)):
				var next := link + Vector2(sin(i * 1.7) * 1.5, 11.0)
				k.outline(k.ellipse_points(link.lerp(next, 0.5), Vector2(2.6, 5.5), 0.0, 8), 1.4, p.ink, 0.1, 0.0)
				link = next
		index += 1
		x += pitch
	# A pipe along the vault, dripping.
	var pipe_y := ground_y - 300.0
	k.line(Vector2(bounds.position.x - 40.0, pipe_y), Vector2(bounds.end.x + 40.0, pipe_y + 6.0), 7.0, p.slate, 0.2, 0.0)
	k.line(Vector2(bounds.position.x - 40.0, pipe_y - 3.0), Vector2(bounds.end.x + 40.0, pipe_y + 3.0), 1.2, Color(p.ink, 0.7), 0.2, 0.0)
	for i in int(bounds.size.x / 200.0):
		var joint := Vector2(bounds.position.x + 60.0 + i * 200.0, pipe_y + i * 6.0 * 200.0 / bounds.size.x)
		k.shape(k.rough_rect(Rect2(joint.x - 5.0, joint.y - 6.0, 10.0, 12.0), 0.3), p.slate.darkened(0.2), p.ink, 1.4)
		if i % 3 == 1:
			for drip in 4:
				k.blob(joint + Vector2(1.0, 10.0 + drip * 14.0), 1.2 - drip * 0.2, Color(p.light, 0.5), 5)
	_cutaway(k, p, scene, 0.6)
	_side_walls(k, p, scene, &"rock")

## Below the Scratch: cut wax, the groove walls, the gouge of the cut going
## through, and the litter of the world above where it fell.
static func _deep_set(k: Ink, p: Dictionary, scene: Dictionary) -> void:
	var bounds: Rect2 = scene.bounds
	var back := Rect2(bounds.position.x - 80.0, bounds.position.y - 120.0, bounds.size.x + 160.0, bounds.size.y + 320.0)
	Set.wax_face(k, p, back, int(scene.seed))
	# The cut itself: a ragged gouge across the back wall, hatched deep.
	var gouge := PackedVector2Array()
	var gy := bounds.position.y + bounds.size.y * 0.3
	var x := back.position.x
	while x < back.end.x:
		gouge.append(Vector2(x, gy + sin(x * 0.012 + float(scene.seed)) * 26.0 + k.rand(-6, 6)))
		x += 46.0
	var lower := gouge.duplicate()
	for i in range(gouge.size() - 1, -1, -1):
		lower.append(gouge[i] + Vector2(0, 30.0 + k.rand(-8, 8)))
	k.fill(lower, p.deep.lerp(p.paper, 0.1))
	k.crosshatch(lower, HATCH, 3.5, 0.8, Color(p.ink, 0.35))
	k.stroke(gouge, 3.0, p.ink, 1.2, 0.0, 1.0, 10.0)
	# Flyers that fell from the world above: the only paper down here.
	for i in 3:
		var at := Vector2(k.rand(bounds.position.x + 100, bounds.end.x - 100), k.rand(bounds.position.y + 80, float(scene.ground_y) - 60))
		var tilt := k.rand(-0.5, 0.5)
		var flyer := PackedVector2Array()
		for corner: Vector2 in [Vector2(-12, -16), Vector2(12, -16), Vector2(12, 16), Vector2(-12, 16)]:
			flyer.append(at + corner.rotated(tilt))
		k.fill(flyer, InkLook.LABEL_PAPER.lerp(InkLook.DUST, 0.3))
		k.outline(flyer, 1.0, Color(InkLook.LINE, 0.8), 0.2, 0.3)
		for line in 3:
			k.hair(at + Vector2(-7, -8 + line * 6).rotated(tilt), at + Vector2(7, -8 + line * 6).rotated(tilt), 0.8, Color(InkLook.LINE, 0.6))
	_side_walls(k, p, scene, &"wax")

## The room's own side walls, as the kind of stuff the room is cut from.
static func _side_walls(k: Ink, p: Dictionary, scene: Dictionary, stuff: StringName) -> void:
	for wall: Rect2 in scene.walls:
		var face := wall.grow_individual(0.0, 160.0, 0.0, 160.0)
		match stuff:
			&"brick": Set.wall(k, p, face, 0.6, 0.0)
			&"rock": Set.rock(k, p, face, int(scene.seed) + int(wall.position.x))
			&"wax": Set.wax_face(k, p, face, int(scene.seed) + int(wall.position.x))
			_:
				var flat := k.rough_rect(face, 0.8)
				k.fill(flat, p.paper.lerp(p.umber, 0.35))
				k.hatch(flat, HATCH, 4.0, 0.9, Color(p.ink, 0.4))
				k.outline(flat, 3.0, p.ink, 0.5, 1.0)

## The earth cut away under the street: strata down to the bottom of the
## page, and the things the ground lost.
static func _cutaway(k: Ink, p: Dictionary, scene: Dictionary, depth_scale := 1.0) -> void:
	var ground: Rect2 = scene.ground
	var bounds: Rect2 = scene.bounds
	var top := ground.position.y + 22.0
	var earth := Rect2(bounds.position.x - 60.0, top, bounds.size.x + 120.0, maxf(bounds.end.y + 240.0 - top, 120.0))
	Set.strata(k, p, earth)
	if depth_scale >= 1.0:
		# The Overture begins below: a wavy seam, worn darker dust.
		var seam_y := top + minf(earth.size.y * 0.55, 180.0)
		var seam := PackedVector2Array()
		var x := earth.position.x
		while x <= earth.end.x:
			seam.append(Vector2(x, seam_y + sin(x * 0.02) * 5.0 + k.rand(-2, 2)))
			x += 41.0
		var lower := seam.duplicate()
		lower.append(Vector2(earth.end.x, earth.end.y))
		lower.append(Vector2(earth.position.x, earth.end.y))
		k.fill(lower, p.dust.lerp(p.umber, 0.16), 0.0)
		k.hatch(lower, HATCH, 6.0, 0.8, Color(p.ink, 0.22))
		k.stroke(seam, 2.4, Color(p.ink, 0.85), 0.8, 0.05, 0.5, 10.0)
	for i in clampi(int(ground.size.x / 500.0), 1, 4):
		Set.buried(k, p, Vector2(k.rand(ground.position.x + 80, ground.end.x - 80), top + k.rand(60, 120)), int(scene.seed) + i)

## A building front on its lot: brick, windows in rows, a shopfront or a
## market front or a plain door, posters, a drainpipe, a cornice and a roof.
static func _facade(k: Ink, p: Dictionary, lot: Dictionary, scene: Dictionary) -> void:
	var ground_y := float(scene.ground_y)
	var left := float(lot.left)
	var right := float(lot.right)
	var eave := float(lot.eave)
	var seed_value := int(lot.seed)
	k.reseed(seed_value)
	var body := Rect2(left, eave, right - left, ground_y - eave)
	var rendered := seed_value % 3 == 0
	var face := k.rough_rect(body, 1.0)
	if rendered:
		k.fill(face, p.paper.lerp(p.stone, 0.6))
		k.hatch(face, HATCH + 0.12, 6.5, 0.7, Color(p.ink, 0.07), 0.85)
		Set.bricks(k, p, Rect2(left, eave, body.size.x, body.size.y * 0.45), 9.0, 22.0, 0.25)
	else:
		k.fill(face, p.paper.lerp(p.dust, 0.25))
		k.hatch(face, HATCH + 0.12, 6.5, 0.7, Color(p.ink, 0.07), 0.85)
		Set.bricks(k, p, body, 10.0, 24.0, 0.5)
	k.shade(face, LIGHT, 0.28, 4.0, 0.8, p.hatch)
	Set.weather(k, p, body, 3)
	# Windows in rows above the ground floor.
	var row_top := eave + 34.0
	var row := 0
	while row_top + 62.0 < ground_y - 118.0:
		var columns := maxi(int((body.size.x - 40.0) / 78.0), 1)
		var pitch := (body.size.x - 40.0) / columns
		for column in columns:
			var box := Rect2(left + 20.0 + column * pitch + pitch * 0.5 - 21.0, row_top, 42.0, 62.0)
			if k.chance(0.88):
				Set.window(k, p, box, seed_value + row * 7 + column, k.chance(0.12))
		row_top += 100.0
		row += 1
	# The ground floor: a shopfront, a market front, or a plain wall with the door.
	var door_x := float(lot.door)
	if bool(lot.market):
		_market_front(k, p, body, scene)
	elif bool(lot.shop):
		_shopfront(k, p, body, door_x, seed_value)
	# A poster or two pasted up low on the wall.
	for i in (2 if body.size.x > 220.0 else 1):
		var x := left + 14.0 + k.rand(0.0, body.size.x - 48.0)
		if door_x < 0.0 or absf(x - door_x) > 60.0:
			Set.poster(k, p, Rect2(x, ground_y - k.rand(120, 190), 32, 44), FLYERS[(seed_value + i) % FLYERS.size()], k.rand(-0.08, 0.08), k.chance(0.4))
	# A drainpipe down one side.
	var pipe_x := right - 10.0 if seed_value % 2 == 0 else left + 10.0
	k.line(Vector2(pipe_x, eave + 4.0), Vector2(pipe_x, ground_y - 2.0), 4.0, p.umber, 0.4, 0.0)
	k.line(Vector2(pipe_x - 3.0, eave + 4.0), Vector2(pipe_x - 3.0, ground_y - 2.0), 1.0, p.ink, 0.3, 0.0)
	Set.damp(k, p, Rect2(left, ground_y - 36.0, body.size.x, 36.0))
	_roof(k, p, body, seed_value)
	k.sketch(face, 3.4, p.ink)

static func _shopfront(k: Ink, p: Dictionary, body: Rect2, door_x: float, seed_value: int) -> void:
	var ground_y := body.end.y
	var front := k.rough_rect(Rect2(body.position.x, ground_y - 100.0, body.size.x, 100.0), 0.6)
	k.fill(front, p.umber.lerp(p.paper, 0.18))
	k.hatch(front, HATCH, 5.0, 0.9, Color(p.ink, 0.35))
	var lintel := k.rough_rect(Rect2(body.position.x - 6.0, ground_y - 108.0, body.size.x + 12.0, 12.0), 0.6)
	k.shape(lintel, p.umber, p.ink, 2.4)
	# The shop window, with its card, beside the door if there is one.
	var window_left := body.position.x + 18.0
	if door_x >= 0.0 and door_x < body.get_center().x:
		window_left = door_x + 48.0
	var width := minf(120.0, body.end.x - 18.0 - window_left)
	if door_x >= 0.0 and door_x >= body.get_center().x:
		width = minf(width, door_x - 44.0 - window_left)
	if width > 50.0:
		var shop := Rect2(window_left, ground_y - 86.0, width, 70.0)
		var glass := k.rough_rect(shop, 0.6)
		k.fill(glass, p.paper.lerp(p.dust, 0.25))
		k.hatch(glass, -PI * 0.3, 9.0, 0.8, Color(p.ink, 0.18), 0.6)
		k.line(Vector2(shop.get_center().x, shop.position.y), Vector2(shop.get_center().x, shop.end.y), 2.0, p.ink, 0.3, 0.0)
		var card := PackedVector2Array([shop.position + Vector2(10, 12), shop.position + Vector2(58, 9), shop.position + Vector2(60, 40), shop.position + Vector2(11, 42)])
		k.shape(card, p.light, p.ink, 1.4)
		k.text(p.display, shop.position + Vector2(14, 30), TRADES[seed_value % TRADES.size()], 11, p.ink, -0.04)
		# Pressings in the window, edge on.
		for i in int((width - 70.0) / 14.0):
			var record := k.ellipse_points(shop.position + Vector2(70.0 + i * 13.0, 50.0), Vector2(3.0, 14.0), k.rand(-0.2, 0.1), 10)
			k.shape(record, p.deep, p.ink, 1.0)
		k.outline(glass, 2.6, p.ink)
		var sill := k.rough_rect(Rect2(shop.position.x - 6.0, ground_y - 16.0, shop.size.x + 12.0, 8.0), 0.5)
		k.shape(sill, p.stone, p.ink, 1.8)
	# A sign board over the front.
	var sign := k.rough_rect(Rect2(body.position.x + 20.0, ground_y - 134.0, minf(body.size.x - 40.0, 160.0), 20.0), 0.5)
	k.shape(sign, p.umber.darkened(0.2), p.ink, 2.0)
	k.text(p.display, Vector2(body.position.x + 28.0, ground_y - 119.0), TRADES[(seed_value * 7 + 3) % TRADES.size()], 13, p.light)

## The market front: shutters down, awnings out, nobody minding the stalls.
static func _market_front(k: Ink, p: Dictionary, body: Rect2, scene: Dictionary) -> void:
	var ground_y := body.end.y
	var stalls := maxi(int(body.size.x / 150.0), 1)
	var pitch := body.size.x / stalls
	for i in stalls:
		var box := Rect2(body.position.x + i * pitch + 8.0, ground_y - 104.0, pitch - 16.0, 104.0)
		# The shutter: a roller box and slats.
		var roller := k.rough_rect(Rect2(box.position.x, box.position.y, box.size.x, 14.0), 0.5)
		k.shape(roller, p.slate, p.ink, 2.0)
		var shutter := k.rough_rect(Rect2(box.position.x + 2.0, box.position.y + 14.0, box.size.x - 4.0, box.size.y - 14.0), 0.6)
		k.fill(shutter, p.stone.lerp(p.dust, 0.5))
		var y := box.position.y + 22.0
		while y < box.end.y - 4.0:
			k.hair(Vector2(box.position.x + 4.0, y), Vector2(box.end.x - 4.0, y + k.rand(-0.5, 0.5)), 1.0, Color(p.ink, 0.55))
			y += 8.0
		k.shade(shutter, LIGHT, 0.3, 3.6, 0.8, Color(p.ink, 0.4))
		k.outline(shutter, 2.0, p.ink, 0.3, 0.5)
		# The awning over it, striped, sagging.
		var awning := PackedVector2Array([Vector2(box.position.x - 6.0, box.position.y - 2.0), Vector2(box.end.x + 6.0, box.position.y - 2.0),
			Vector2(box.end.x + 14.0, box.position.y + 26.0), Vector2(box.position.x - 14.0, box.position.y + 26.0)])
		k.fill(awning, p.light)
		var stripes := int(box.size.x / 18.0)
		for s in stripes:
			if s % 2 == 0:
				var sx := box.position.x - 6.0 + s * (box.size.x + 12.0) / stripes
				var stripe := PackedVector2Array([Vector2(sx, box.position.y - 2.0), Vector2(sx + (box.size.x + 12.0) / stripes, box.position.y - 2.0),
					Vector2(sx + (box.size.x + 12.0) / stripes + 8.0 * (sx - box.get_center().x) / box.size.x, box.position.y + 26.0), Vector2(sx + 8.0 * (sx - box.get_center().x) / box.size.x, box.position.y + 26.0)])
				k.fill(stripe, p.red.lerp(p.paper, 0.3) if int(scene.seed) % 2 == 0 else p.patina.lerp(p.paper, 0.2))
		k.shade(awning, LIGHT, 0.3, 3.0, 0.8, Color(p.ink, 0.35))
		k.outline(awning, 2.0, p.ink, 0.3, 0.5)
		var scallops := int((box.size.x + 28.0) / 12.0)
		for s in scallops:
			var sx := box.position.x - 14.0 + s * 12.0
			k.path(PackedVector2Array([Vector2(sx, box.position.y + 26.0), Vector2(sx + 6.0, box.position.y + 31.0), Vector2(sx + 12.0, box.position.y + 26.0)]), 1.2, p.ink, 0.1)

## A gate lot: a wall standing over an archway, with windows above and the
## passage's name on its plate.
static func _gate(k: Ink, p: Dictionary, lot: Dictionary, scene: Dictionary) -> void:
	var ground_y := float(scene.ground_y)
	var left := float(lot.left)
	var right := float(lot.right)
	var eave := float(lot.eave)
	k.reseed(int(lot.seed))
	var body := Rect2(left, eave, right - left, ground_y - eave)
	Set.wall(k, p, body, 0.55, 46.0)
	var cornice := k.rough_rect(Rect2(left - 4.0, eave - 12.0, body.size.x + 8.0, 14.0), 0.8)
	k.shape(cornice, p.umber, p.ink, 2.4)
	var stack := k.rough_rect(Rect2(left + body.size.x * 0.3, eave - 50.0, 30.0, 40.0), 1.0)
	k.fill(stack, p.paper.lerp(p.dust, 0.3))
	Set.bricks(k, p, Rect2(left + body.size.x * 0.3, eave - 50.0, 30.0, 40.0), 8.0, 14.0, 0.5)
	k.outline(stack, 2.4, p.ink)
	var row_top := eave + 40.0
	while row_top + 62.0 < ground_y - 150.0:
		for column in 2:
			var box := Rect2(left + body.size.x * (0.3 + column * 0.4) - 21.0, row_top, 42.0, 62.0)
			Set.window(k, p, box, int(lot.seed) + column + int(row_top))
		row_top += 108.0
	Set.archway(k, p, Vector2(float(lot.gate), ground_y), 31.0, String(lot.name))
	Set.poster(k, p, Rect2(float(lot.gate) + 48.0, ground_y - 130.0, 30.0, 44.0), FLYERS[int(lot.seed) % FLYERS.size()], 0.05, true)

## A roof over a lot: a gable or a flat with a parapet, tiles in hatched
## courses, a crooked chimney.
static func _roof(k: Ink, p: Dictionary, body: Rect2, seed_value: int) -> void:
	var eave := body.position.y
	var left := body.position.x
	var right := body.end.x
	if seed_value % 4 == 3:
		# A parapet and a flat roof behind it.
		var parapet := k.rough_rect(Rect2(left - 8.0, eave - 22.0, body.size.x + 16.0, 24.0), 0.8)
		k.fill(parapet, p.paper.lerp(p.dust, 0.3))
		Set.bricks(k, p, Rect2(left - 8.0, eave - 22.0, body.size.x + 16.0, 24.0), 8.0, 20.0, 0.5)
		k.outline(parapet, 2.4, p.ink, 0.4, 0.8)
		var cope := k.rough_rect(Rect2(left - 12.0, eave - 28.0, body.size.x + 24.0, 8.0), 0.6)
		k.shape(cope, p.stone, p.ink, 2.0)
		return
	var ridge := Vector2(lerpf(left, right, 0.5 + (seed_value % 5 - 2) * 0.05), eave - body.size.x * 0.32 - 20.0)
	var roof := PackedVector2Array([Vector2(left - 18.0, eave + 2.0), ridge, Vector2(right + 18.0, eave + 2.0)])
	k.fill(roof, p.umber.lerp(p.paper, 0.1))
	var courses := int((eave - ridge.y) / 11.0)
	for course in courses:
		var y := ridge.y + 10.0 + course * 11.0
		var half := (y - ridge.y) / (eave + 2.0 - ridge.y) * (right + 18.0 - ridge.x)
		var half_left := (y - ridge.y) / (eave + 2.0 - ridge.y) * (ridge.x - left + 18.0)
		k.stroke(PackedVector2Array([Vector2(ridge.x - half_left, y), Vector2(ridge.x + half, y)]), 1.0, Color(p.light, 0.35), 0.5, 0.1, 0.4, 14.0)
		var x := ridge.x - half_left + (course % 2) * 6.0
		while x < ridge.x + half - 4.0:
			k.hair(Vector2(x, y), Vector2(x + 1.0, y + 10.0), 0.8, Color(p.light, 0.3))
			x += 12.0
	k.shade(roof, LIGHT, 0.4, 3.4, 0.9, Color(p.deep, 0.55))
	k.sketch(roof, 3.4, p.ink)
	var stack_x := lerpf(left, ridge.x, 0.4 if seed_value % 2 == 0 else 0.7)
	var stack_top := ridge.y + (eave - ridge.y) * 0.5 - 50.0
	var stack := PackedVector2Array([Vector2(stack_x - 14.0, stack_top + 70.0), Vector2(stack_x - 15.0, stack_top), Vector2(stack_x + 13.0, stack_top - 4.0), Vector2(stack_x + 16.0, stack_top + 60.0)])
	k.fill(stack, p.paper.lerp(p.dust, 0.3))
	Set.bricks(k, p, Rect2(stack_x - 14.0, stack_top, 28.0, 60.0), 8.0, 14.0, 0.5)
	k.outline(stack, 2.4, p.ink)
	for pot: float in [-8.0, 4.0]:
		k.shape(k.rough_rect(Rect2(stack_x + pot, stack_top - 16.0, 8.0, 15.0), 0.6), p.red.lerp(p.umber, 0.35), p.ink, 1.8)

## What a room is for: the fittings of its trade, drawn against its back wall.
static func _fittings(k: Ink, p: Dictionary, scene: Dictionary, wall: Rect2, ceiling: float) -> void:
	var room_id: StringName = scene.room_id
	var ground_y := float(scene.ground_y)
	var bounds: Rect2 = scene.bounds
	match room_id:
		&"practice_room":
			# Tick's room: a shelf with the metronome, a music stand, the
			# count chalked on the wall, a tall window that the count-in
			# light comes through.
			_tall_window(k, p, Rect2(bounds.position.x + bounds.size.x * 0.62, ceiling + 70.0, 96.0, 200.0))
			var shelf := Vector2(bounds.position.x + 300.0, ground_y - 250.0)
			_shelf(k, p, shelf, 130.0)
			_metronome(k, p, shelf + Vector2(60.0, -2.0))
			_chalk_count(k, p, Vector2(bounds.position.x + 150.0, ground_y - 300.0), 4)
			_music_stand(k, p, Vector2(bounds.position.x + 520.0, ground_y))
		&"rooms_to_let":
			# A hall: the key board, every room's key still on its hook, the
			# stair going up, radiator pipes along the skirting.
			_key_board(k, p, Vector2(bounds.position.x + 520.0, ground_y - 310.0))
			_stair_up(k, p, Vector2(bounds.end.x - 420.0, ground_y), 8)
			for pipe in 2:
				var y := ground_y - 52.0 + pipe * 14.0
				k.line(Vector2(wall.position.x + 20.0, y), Vector2(bounds.position.x + 480.0, y + 1.0), 5.0, p.umber, 0.3, 0.0)
				k.line(Vector2(wall.position.x + 20.0, y - 2.0), Vector2(bounds.position.x + 480.0, y - 1.0), 1.0, Color(p.ink, 0.6), 0.3, 0.0)
			for rib in 9:
				var x := bounds.position.x + 120.0 + rib * 24.0
				k.shape(k.rough_rect(Rect2(x - 3.0, ground_y - 80.0, 6.0, 55.0), 0.3), p.umber.lerp(p.paper, 0.2), p.ink, 1.2)
			_tall_window(k, p, Rect2(bounds.position.x + 300.0, ceiling + 60.0, 80.0, 150.0))
		&"print_shop":
			# Lines of tomorrow's sheets drying, the type cases, and the
			# press itself at rest.
			for line in 2:
				var y := ceiling + 90.0 + line * 70.0
				_drying_line(k, p, Vector2(bounds.position.x + 120.0, y), Vector2(bounds.end.x - 120.0, y), 24.0, 5 + line)
			_type_case(k, p, Vector2(bounds.position.x + 260.0, ground_y - 200.0))
			_type_case(k, p, Vector2(bounds.position.x + 420.0, ground_y - 200.0))
			_press(k, p, Vector2(bounds.position.x + bounds.size.x * 0.67, ground_y))
		&"stall_cache":
			# Crates of unsold wax stacked to the lintel, shelves of pressings.
			for stack in 3:
				var x := bounds.position.x + 980.0 + stack * 86.0
				for crate in 3 - stack:
					Set.crate(k, p, Rect2(x - 36.0, ground_y - 52.0 - crate * 56.0, 72.0, 50.0), "" if crate != 0 else "UNSOLD")
			for shelf in 2:
				var at := Vector2(bounds.position.x + 200.0, ground_y - 180.0 - shelf * 90.0)
				_shelf(k, p, at, 360.0)
				for i in 14:
					var record := k.ellipse_points(at + Vector2(20.0 + i * 24.0, -18.0), Vector2(4.0, 18.0), k.rand(-0.12, 0.12), 12)
					k.shape(record, p.deep, p.ink, 1.1)
		&"headshell":
			# Home: a tall window, a shelf of what he kept, a kettle on the
			# stove and the cradle he rests in (its landmark).
			_tall_window(k, p, Rect2(bounds.position.x + bounds.size.x * 0.64, ceiling + 50.0, 110.0, 230.0))
			_shelf(k, p, Vector2(bounds.position.x + 120.0, ground_y - 260.0), 170.0)
			for i in 5:
				Set.tape(k, p, Vector2(bounds.position.x + 140.0 + i * 30.0, ground_y - 272.0), 0.55, k.rand(-0.1, 0.1))
			_stove(k, p, Vector2(bounds.end.x - 300.0, ground_y))
		_:
			_tall_window(k, p, Rect2(bounds.position.x + bounds.size.x * 0.6, ceiling + 60.0, 90.0, 180.0))

static func _tall_window(k: Ink, p: Dictionary, box: Rect2) -> void:
	var frame := k.rough_rect(box, 0.8)
	k.fill(frame, p.paper.lerp(p.light, 0.5))
	k.hatch(frame, -PI * 0.3, 8.0, 0.7, Color(p.ink, 0.12), 0.6)
	var columns := 2
	var rows := maxi(int(box.size.y / 50.0), 2)
	for c in range(1, columns):
		k.line(Vector2(box.position.x + box.size.x * c / columns, box.position.y), Vector2(box.position.x + box.size.x * c / columns, box.end.y), 2.2, p.ink, 0.2, 0.0)
	for r in range(1, rows):
		k.line(Vector2(box.position.x, box.position.y + box.size.y * r / rows), Vector2(box.end.x, box.position.y + box.size.y * r / rows), 2.0, p.ink, 0.2, 0.0)
	k.outline(frame, 3.0, p.ink, 0.4, 0.8)
	var sill := k.rough_rect(Rect2(box.position.x - 8.0, box.end.y, box.size.x + 16.0, 8.0), 0.5)
	k.shape(sill, p.stone, p.ink, 1.8)
	# The light it lets in, laid down the wall and across the boards.
	var spill := PackedVector2Array([box.position + Vector2(4, 4), Vector2(box.end.x - 4, box.position.y + 4), Vector2(box.end.x + 60.0, box.end.y + 140.0), Vector2(box.position.x - 30.0, box.end.y + 140.0)])
	k.graded(spill, PackedColorArray([Color(p.light, 0.18), Color(p.light, 0.18), Color(p.light, 0.0), Color(p.light, 0.0)]))

static func _shelf(k: Ink, p: Dictionary, at: Vector2, length: float) -> void:
	var board := k.rough_rect(Rect2(at.x, at.y, length, 7.0), 0.4)
	k.shape(board, p.wood, p.ink, 1.8)
	for bracket: float in [16.0, length - 16.0]:
		var iron := PackedVector2Array([at + Vector2(bracket, 7.0), at + Vector2(bracket, 26.0), at + Vector2(bracket - 10.0, 7.0)])
		k.shape(iron, p.slate, p.ink, 1.4)
	k.hatch(PackedVector2Array([at + Vector2(0, 7), at + Vector2(length, 7), at + Vector2(length, 20), at + Vector2(0, 16)]), HATCH, 3.0, 0.8, Color(p.ink, 0.35))

static func _metronome(k: Ink, p: Dictionary, base: Vector2) -> void:
	var body := PackedVector2Array([base + Vector2(-16, 0), base + Vector2(16, 0), base + Vector2(9, -44), base + Vector2(-9, -44)])
	k.fill(body, p.wood.lerp(p.paper, 0.2))
	k.shade(body, LIGHT, 0.35, 3.0, 0.8, Color(p.ink, 0.45))
	k.outline(body, 2.0, p.ink, 0.3, 0.6)
	var slot := k.rough_rect(Rect2(base.x - 2.0, base.y - 40.0, 4.0, 30.0), 0.2)
	k.fill(slot, p.deep)
	k.line(base + Vector2(0, -8), base + Vector2(-7, -40), 1.6, p.ink, 0.1, 0.0)
	k.blob(base + Vector2(-5.5, -34), 2.4, p.brass, 6)

static func _chalk_count(k: Ink, p: Dictionary, at: Vector2, marks: int) -> void:
	for mark in marks:
		k.line(at + Vector2(mark * 12.0, 0), at + Vector2(mark * 12.0 + 2.0, 34.0), 2.4, Color(p.light, 0.85), 0.5, 0.1)
	k.line(at + Vector2(-6, 40), at + Vector2(marks * 12.0 + 6.0, 38.0), 1.8, Color(p.light, 0.7), 0.5, 0.1)
	k.text(p.body, at + Vector2(-4, 60), "and", 9, Color(p.light, 0.7), -0.06)

static func _music_stand(k: Ink, p: Dictionary, base: Vector2) -> void:
	k.line(base, base + Vector2(0, -90), 2.0, p.slate, 0.1, 0.0)
	for leg: float in [-14.0, 0.0, 14.0]:
		k.line(base + Vector2(0, -12), base + Vector2(leg, 0), 1.6, p.slate, 0.1, 0.0)
	var desk := PackedVector2Array([base + Vector2(-20, -92), base + Vector2(20, -96), base + Vector2(22, -122), base + Vector2(-18, -118)])
	k.shape(desk, p.slate.lerp(p.paper, 0.2), p.ink, 1.6)
	var sheet := PackedVector2Array([base + Vector2(-14, -96), base + Vector2(12, -98), base + Vector2(14, -120), base + Vector2(-12, -118)])
	k.shape(sheet, p.light, p.ink, 1.0)
	for i in 4:
		k.hair(base + Vector2(-10, -102 - i * 4), base + Vector2(8, -103 - i * 4), 0.6, Color(p.ink, 0.6))

static func _key_board(k: Ink, p: Dictionary, at: Vector2) -> void:
	var board := k.rough_rect(Rect2(at.x, at.y, 250.0, 70.0), 0.6)
	k.fill(board, p.wood.lerp(p.paper, 0.25))
	k.hatch(board, HATCH, 4.0, 0.8, Color(p.ink, 0.2))
	k.outline(board, 2.2, p.ink, 0.3, 0.6)
	for hook in 7:
		var x := at.x + 22.0 + hook * 34.0
		k.blob(Vector2(x, at.y + 14.0), 1.6, p.ink)
		k.line(Vector2(x, at.y + 14.0), Vector2(x, at.y + 30.0 + k.rand(0, 8)), 1.2, p.ink, 0.1, 0.0)
		var bow := k.ellipse_points(Vector2(x, at.y + 38.0 + k.rand(0, 8)), Vector2(4.5, 4.5), 0.0, 8)
		k.shape(bow, p.brass, p.ink, 1.2)
		k.text(p.body, Vector2(x - 4.0, at.y + 62.0), str(hook + 1), 8, Color(p.ink, 0.8))

static func _stair_up(k: Ink, p: Dictionary, base: Vector2, steps: int) -> void:
	for i in steps:
		var tread := k.rough_rect(Rect2(base.x + i * 34.0, base.y - (i + 1) * 26.0, 40.0, 10.0), 0.5)
		k.shape(tread, p.wood.lerp(p.paper, 0.2), p.ink, 1.8)
		var riser := k.rough_rect(Rect2(base.x + i * 34.0, base.y - (i + 1) * 26.0 + 10.0, 6.0, 16.0), 0.4)
		k.fill(riser, p.umber)
		k.hatch(PackedVector2Array([Vector2(base.x + i * 34.0 + 6.0, base.y - (i + 1) * 26.0 + 10.0), Vector2(base.x + i * 34.0 + 40.0, base.y - (i + 1) * 26.0 + 10.0),
			Vector2(base.x + i * 34.0 + 40.0, base.y - i * 26.0), Vector2(base.x + i * 34.0 + 6.0, base.y - i * 26.0)]), HATCH, 3.0, 0.8, Color(p.ink, 0.4))
	# A rail up the flight.
	k.line(Vector2(base.x + 8.0, base.y - 60.0), Vector2(base.x + steps * 34.0, base.y - steps * 26.0 - 60.0), 3.0, p.wood, 0.2, 0.0)
	k.line(Vector2(base.x + 8.0, base.y - 62.0), Vector2(base.x + steps * 34.0, base.y - steps * 26.0 - 62.0), 1.0, p.ink, 0.2, 0.0)
	for i in range(0, steps, 2):
		k.line(Vector2(base.x + i * 34.0 + 20.0, base.y - (i + 1) * 26.0), Vector2(base.x + i * 34.0 + 20.0, base.y - (i + 1) * 26.0 - 50.0), 1.6, p.slate, 0.1, 0.0)

static func _drying_line(k: Ink, p: Dictionary, a: Vector2, b: Vector2, drop: float, sheets: int) -> void:
	var line := Ink.sag(a, b, drop, 24)
	k.stroke(line, 1.2, p.ink, 0.2, 0.0, 1.0, 12.0)
	for i in sheets:
		var t := (i + 0.5) / sheets
		var at: Vector2 = line[int(t * (line.size() - 1))]
		var sheet := PackedVector2Array([at + Vector2(-26, 0), at + Vector2(26, 1), at + Vector2(24, 62), at + Vector2(-28, 60)])
		k.fill(sheet, p.light)
		k.shade(sheet, LIGHT, 0.3, 3.0, 0.7, Color(p.ink, 0.3))
		k.outline(sheet, 1.4, p.ink, 0.3, 0.4)
		for row in 4:
			k.hair(at + Vector2(-16, 14 + row * 9), at + Vector2(14 - (row % 2) * 6, 14 + row * 9), 0.8, Color(p.ink, 0.6))
		for peg: float in [-14.0, 14.0]:
			k.line(at + Vector2(peg, -3), at + Vector2(peg, 4), 2.2, p.wood, 0.0, 0.0)

static func _type_case(k: Ink, p: Dictionary, at: Vector2) -> void:
	var box := Rect2(at.x, at.y, 130.0, 90.0)
	var frame := k.rough_rect(box, 0.6)
	k.fill(frame, p.wood.lerp(p.paper, 0.2))
	for row in 6:
		for column in 9:
			var cell := Rect2(box.position.x + 4.0 + column * 13.6, box.position.y + 4.0 + row * 13.6, 11.0, 11.0)
			k.outline(k.rough_rect(cell, 0.2), 0.7, Color(p.ink, 0.55), 0.1, 0.1)
			if k.chance(0.6):
				k.blob(cell.get_center(), 1.4, p.slate, 5)
	k.shade(frame, LIGHT, 0.3, 3.2, 0.8, Color(p.ink, 0.35))
	k.outline(frame, 2.2, p.ink, 0.3, 0.6)

static func _press(k: Ink, p: Dictionary, base: Vector2) -> void:
	# The bed, the flywheel, the lever: a hand press at rest.
	var bed := k.rough_rect(Rect2(base.x - 130.0, base.y - 44.0, 260.0, 44.0), 0.8)
	k.fill(bed, p.slate.lerp(p.paper, 0.3))
	k.shade(bed, LIGHT, 0.35, 3.4, 0.8, Color(p.ink, 0.45))
	k.outline(bed, 2.6, p.ink, 0.4, 0.8)
	var hub := base + Vector2(0, -130)
	var wheel := k.ellipse_points(hub, Vector2(62, 62), 0.0, 28)
	k.outline(wheel, 4.0, p.ink, 0.3, 0.0)
	k.outline(k.ellipse_points(hub, Vector2(52, 52), 0.0, 28), 1.4, Color(p.ink, 0.6), 0.2, 0.0)
	for spoke in 6:
		var angle := spoke * PI / 3.0 + 0.2
		k.line(hub + Vector2.from_angle(angle) * 14.0, hub + Vector2.from_angle(angle) * 58.0, 3.0, p.ink, 0.1, 0.0)
	k.blob(hub, 14.0, p.slate, 10)
	k.outline(k.ellipse_points(hub, Vector2(14, 14), 0.0, 10), 2.0, p.ink, 0.1, 0.0)
	var post := k.rough_rect(Rect2(base.x - 8.0, base.y - 190.0, 16.0, 146.0), 0.5)
	k.shape(post, p.slate, p.ink, 2.2)
	var lever := PackedVector2Array([hub + Vector2(60, -4), hub + Vector2(110, -70), hub + Vector2(114, -64), hub + Vector2(66, 2)])
	k.shape(lever, p.wood, p.ink, 2.0)
	k.blob(hub + Vector2(112, -67), 4.0, p.brass, 8)
	# A sheet on the bed, the last thing printed.
	var sheet := PackedVector2Array([base + Vector2(-60, -46), base + Vector2(40, -48), base + Vector2(44, -44), base + Vector2(-58, -42)])
	k.shape(sheet, p.light, p.ink, 1.0)

static func _stove(k: Ink, p: Dictionary, base: Vector2) -> void:
	var body := k.rough_rect(Rect2(base.x - 40.0, base.y - 70.0, 80.0, 70.0), 0.6)
	k.fill(body, p.slate.darkened(0.2))
	k.hatch(body, HATCH, 3.6, 0.8, Color(p.ink, 0.45))
	k.outline(body, 2.4, p.ink, 0.3, 0.6)
	var door := k.rough_rect(Rect2(base.x - 24.0, base.y - 52.0, 32.0, 32.0), 0.4)
	k.fill(door, p.deep)
	k.outline(door, 1.6, p.ink, 0.2, 0.3)
	k.blob(base + Vector2(14, -36), 1.8, p.brass)
	var flue := k.rough_rect(Rect2(base.x + 12.0, base.y - 190.0, 14.0, 122.0), 0.5)
	k.shape(flue, p.slate, p.ink, 2.0)
	# A kettle on the hob, cold.
	var kettle := k.ellipse_points(base + Vector2(-8, -80), Vector2(16, 10), 0.0, 12)
	k.shape(kettle, p.brass.lerp(p.paper, 0.2), p.ink, 1.6)
	k.path(PackedVector2Array([base + Vector2(8, -84), base + Vector2(20, -94), base + Vector2(22, -88)]), 1.6, p.ink, 0.1)
	k.path(PackedVector2Array([base + Vector2(-16, -90), base + Vector2(-8, -98), base + Vector2(0, -90)]), 1.6, p.ink, 0.1)

## The floors: the ground as slabs (or boards inside, or cut stone or wax
## below), every other face as a ledge.
static func _floors(k: Ink, p: Dictionary, scene: Dictionary) -> void:
	var kind: StringName = scene.kind
	var ground: Rect2 = scene.ground
	for floor: Rect2 in scene.floors:
		var is_ground := floor == ground
		match kind:
			&"interior":
				if is_ground:
					_boards(k, p, floor)
				else:
					Set.ledge(k, p, Rect2(floor.position, Vector2(floor.size.x, minf(floor.size.y, 40.0))), 0.3)
			&"deep":
				_wax_ledge(k, p, Rect2(floor.position, Vector2(floor.size.x, minf(floor.size.y, 60.0))), int(scene.seed) + int(floor.position.x))
			&"stair", &"vault":
				if is_ground:
					Set.slabs(k, p, Rect2(floor.position, Vector2(floor.size.x, minf(floor.size.y, 60.0))), 19.0)
				else:
					Set.ledge(k, p, Rect2(floor.position, Vector2(floor.size.x, minf(floor.size.y, 44.0))), 0.8, false)
			_:
				if is_ground:
					Set.slabs(k, p, Rect2(floor.position, Vector2(floor.size.x, minf(floor.size.y, 60.0))))
				else:
					Set.ledge(k, p, Rect2(floor.position, Vector2(floor.size.x, minf(floor.size.y, 40.0))), 0.5)

## Floorboards: the ground of a room inside, boards end to end with their
## nails and the gaps between them.
static func _boards(k: Ink, p: Dictionary, floor: Rect2) -> void:
	var top := Rect2(floor.position, Vector2(floor.size.x, minf(floor.size.y, 26.0)))
	var face := k.rough_rect(top, 0.5)
	k.fill(face, p.wood.lerp(p.paper, 0.45))
	var x := top.position.x
	while x < top.end.x:
		var run := minf(k.rand(90, 200), top.end.x - x)
		k.hair(Vector2(x + run, top.position.y + 1.0), Vector2(x + run, top.end.y - 1.0), 1.0, Color(p.ink, 0.6))
		for nail in 2:
			k.blob(Vector2(x + 8.0 + nail * (run - 16.0), top.position.y + 8.0), 1.0, p.ink)
		if k.chance(0.5):
			k.hair(Vector2(x + 6.0, top.position.y + k.rand(4, 20)), Vector2(x + run - 6.0, top.position.y + k.rand(4, 20)), 0.7, Color(p.ink, 0.35))
		x += run
	for row in 2:
		k.hair(Vector2(top.position.x, top.position.y + 9.0 + row * 8.0), Vector2(top.end.x, top.position.y + 9.0 + row * 8.0), 0.8, Color(p.ink, 0.4))
	k.shade(face, LIGHT, 0.25, 3.4, 0.8, Color(p.ink, 0.3))
	k.outline(face, 2.0, p.ink, 0.3, 0.6)
	k.stroke(PackedVector2Array([top.position, Vector2(top.end.x, top.position.y)]), 3.4, p.ink, 0.6, 0.0, 1.0, 10.0)

## A ledge cut in the wax: its top the groove's own edge, its face the
## scratch of the cut.
static func _wax_ledge(k: Ink, p: Dictionary, box: Rect2, seed_value: int) -> void:
	var slab := k.rough_rect(box, 1.6)
	k.fill(slab, p.paper.lerp(p.dust, 0.5))
	var y := box.position.y + 5.0
	var row := 0
	while y < box.end.y - 3.0:
		k.hair(Vector2(box.position.x + 2.0, y), Vector2(box.end.x - 2.0, y + sin(row + seed_value) * 1.2), 0.9, Color(p.ink, 0.3 if row % 3 != 0 else 0.6))
		y += k.rand(6, 10)
		row += 1
	k.crosshatch(PackedVector2Array([box.position, Vector2(box.end.x, box.position.y), Vector2(box.end.x, box.position.y + 10.0), Vector2(box.position.x, box.position.y + 10.0)]), HATCH, 3.0, 0.7, Color(p.ink, 0.3))
	k.outline(slab, 2.6, p.ink, 0.6, 1.2)
	k.stroke(PackedVector2Array([box.position, Vector2(box.end.x, box.position.y)]), 3.6, p.ink, 0.8, 0.0, 1.0, 9.0)

## Every passage, by what it is and where it stands.
static func _passages(k: Ink, p: Dictionary, scene: Dictionary) -> void:
	var kind: StringName = scene.kind
	for way: Dictionary in scene.ways:
		var at: Vector2 = way.at
		var label := String(way.name)
		if bool(way.arch):
			if kind in [&"street", &"yard"]:
				# The gate lot drew the archway with its wall.
				continue
			Set.cut(k, p, at, label)
		else:
			Set.doorway(k, p, at, label)

## The room's authored landmarks, drawn again in ink where the room put them.
static func _landmark(k: Ink, p: Dictionary, record: Dictionary, scene: Dictionary) -> void:
	var kind: StringName = record.kind
	var at: Vector2 = record.at
	var size: Vector2 = record.size
	var box := Rect2(at - size * 0.5, size)
	var ground_y := float(scene.ground_y)
	k.reseed(int(scene.seed) + int(at.x) + int(at.y))
	match kind:
		&"arch":
			_grand_arch(k, p, Vector2(at.x, minf(box.end.y, ground_y)), size.x * 0.34, size.y * 0.9)
		&"column":
			_column(k, p, Vector2(at.x, minf(box.end.y, ground_y)), size.x * 0.4, size.y)
		&"headstone":
			_headstone(k, p, Vector2(at.x, ground_y), size)
		&"counter":
			_counter(k, p, Vector2(at.x, ground_y), size.x)
		&"stair":
			_stone_stair(k, p, box, ground_y)
		&"organ", &"overture":
			_organ(k, p, box, ground_y)
		&"headshell":
			_cradle(k, p, box)
		&"resting_arm":
			_resting_arm(k, p, box)
		_:
			pass

static func _grand_arch(k: Ink, p: Dictionary, foot: Vector2, radius: float, height: float) -> void:
	var spring := foot.y - height + radius
	var center := Vector2(foot.x, spring)
	var inside := PackedVector2Array()
	inside.append(Vector2(foot.x - radius, foot.y))
	for i in 21:
		inside.append(center + Vector2.from_angle(PI + PI * i / 20.0) * radius)
	inside.append(Vector2(foot.x + radius, foot.y))
	k.fill(inside, p.paper.lerp(p.deep, 0.2).lerp(p.dust, 0.3))
	k.crosshatch(inside, HATCH, 5.0, 0.8, Color(p.ink, 0.25))
	var ring := 18.0
	for i in 13:
		var angle := PI + PI * (i + 0.5) / 13.0
		var a := center + Vector2.from_angle(angle) * radius
		var b := center + Vector2.from_angle(angle) * (radius + ring)
		var c := center + Vector2.from_angle(angle + PI / 13.0) * (radius + ring)
		var d := center + Vector2.from_angle(angle + PI / 13.0) * radius
		var voussoir := PackedVector2Array([a, b, c, d])
		k.fill(voussoir, p.stone.lerp(p.dust, k.rand(0.1, 0.5)))
		k.outline(voussoir, 1.6, p.ink, 0.3, 0.6)
	for side: float in [-1.0, 1.0]:
		var pier := Rect2(foot.x + side * (radius + ring * 0.5) - ring * 0.5, spring, ring, foot.y - spring)
		var face := k.rough_rect(pier, 0.8)
		k.fill(face, p.stone.lerp(p.dust, 0.35))
		var y := pier.position.y + 24.0
		while y < pier.end.y - 8.0:
			k.hair(Vector2(pier.position.x + 2.0, y), Vector2(pier.end.x - 2.0, y + k.rand(-1, 1)), 0.9, Color(p.ink, 0.55))
			y += k.rand(26, 44)
		k.shade(face, LIGHT, 0.4, 3.4, 0.8, Color(p.ink, 0.45))
		k.outline(face, 2.4, p.ink, 0.4, 0.8)
	var key := PackedVector2Array([center + Vector2(-8, -radius + 2), center + Vector2(-11, -radius - ring - 6), center + Vector2(11, -radius - ring - 6), center + Vector2(8, -radius + 2)])
	k.shape(key, p.stone, p.ink, 2.2)

static func _column(k: Ink, p: Dictionary, foot: Vector2, radius: float, height: float) -> void:
	var shaft := Rect2(foot.x - radius, foot.y - height + radius * 0.6, radius * 2.0, height - radius * 0.6)
	var face := k.rough_rect(shaft, 1.0)
	k.fill(face, p.stone.lerp(p.dust, 0.3))
	for flute in 5:
		var x := shaft.position.x + shaft.size.x * (flute + 0.5) / 5.0
		k.hair(Vector2(x, shaft.position.y + 10.0), Vector2(x + k.rand(-1, 1), shaft.end.y - 6.0), 1.0, Color(p.ink, 0.3 + 0.1 * flute))
	var y := shaft.position.y + k.rand(30, 60)
	while y < shaft.end.y - 20.0:
		k.hair(Vector2(shaft.position.x + 2.0, y), Vector2(shaft.end.x - 2.0, y + k.rand(-2, 2)), 1.1, Color(p.ink, 0.5))
		y += k.rand(50, 90)
	k.shade(face, LIGHT, 0.4, 4.0, 0.9, Color(p.ink, 0.45))
	Set.weather(k, p, shaft, 2)
	k.outline(face, 2.8, p.ink, 0.4, 1.0)
	var capital := PackedVector2Array([Vector2(shaft.position.x - radius * 0.5, shaft.position.y), Vector2(shaft.end.x + radius * 0.5, shaft.position.y),
		Vector2(shaft.end.x + radius * 0.3, shaft.position.y - radius * 0.6), Vector2(shaft.position.x - radius * 0.3, shaft.position.y - radius * 0.6)])
	k.shape(capital, p.stone, p.ink, 2.4)
	var plinth := k.rough_rect(Rect2(shaft.position.x - radius * 0.4, foot.y - 12.0, shaft.size.x + radius * 0.8, 12.0), 0.6)
	k.shape(plinth, p.stone.lerp(p.dust, 0.2), p.ink, 2.2)

static func _headstone(k: Ink, p: Dictionary, foot: Vector2, size: Vector2) -> void:
	var width := minf(size.x * 0.7, 80.0)
	var height := minf(size.y * 0.6, 120.0)
	var stone := PackedVector2Array()
	stone.append(foot + Vector2(-width * 0.5, 0))
	stone.append(foot + Vector2(-width * 0.5, -height + width * 0.5))
	for i in 9:
		var angle := PI + PI * i / 8.0
		stone.append(foot + Vector2(0, -height + width * 0.5) + Vector2.from_angle(angle) * width * 0.5)
	stone.append(foot + Vector2(width * 0.5, 0))
	k.fill(stone, p.stone.lerp(p.dust, 0.4))
	k.shade(stone, LIGHT, 0.35, 3.4, 0.8, Color(p.ink, 0.4))
	Set.weather(k, p, Rect2(foot.x - width * 0.5, foot.y - height, width, height), 1)
	k.outline(stone, 2.6, p.ink, 0.5, 1.0)
	# Its lines, worn past reading.
	for line in 4:
		var y := foot.y - height * 0.6 + line * 12.0
		k.hair(foot + Vector2(-width * 0.3, y - foot.y), foot + Vector2(width * (0.1 + 0.15 * (line % 2)), y - foot.y), 1.2, Color(p.ink, 0.45))
	# Moss at its foot, and the ground heaved a little.
	for i in 6:
		var tuft := k.ellipse_points(foot + Vector2(k.rand(-width * 0.6, width * 0.6), k.rand(-6, 0)), Vector2(k.rand(4, 8), k.rand(2, 4)), 0.0, 6)
		k.fill(tuft, p.patina.lerp(p.paper, 0.3))
		k.outline(tuft, 0.8, Color(p.ink, 0.5), 0.2, 0.2)

static func _counter(k: Ink, p: Dictionary, foot: Vector2, width: float) -> void:
	var top := k.rough_rect(Rect2(foot.x - width * 0.5, foot.y - 64.0, width, 10.0), 0.6)
	var front := k.rough_rect(Rect2(foot.x - width * 0.5 + 6.0, foot.y - 54.0, width - 12.0, 54.0), 0.6)
	k.fill(front, p.wood.lerp(p.paper, 0.2))
	var x := foot.x - width * 0.5 + 20.0
	while x < foot.x + width * 0.5 - 20.0:
		k.outline(k.rough_rect(Rect2(x, foot.y - 46.0, 38.0, 38.0), 0.4), 1.2, Color(p.ink, 0.6), 0.2, 0.3)
		x += 48.0
	k.shade(front, LIGHT, 0.3, 3.2, 0.8, Color(p.ink, 0.4))
	k.outline(front, 2.2, p.ink, 0.3, 0.6)
	k.shape(top, p.wood, p.ink, 2.2)
	# Pressings and a tape left on it.
	for i in 3:
		var record := k.ellipse_points(Vector2(foot.x - width * 0.3 + i * 26.0, foot.y - 68.0), Vector2(18.0, 4.0), 0.0, 14)
		k.shape(record, p.deep, p.ink, 1.2)
	Set.tape(k, p, Vector2(foot.x + width * 0.3, foot.y - 70.0), 0.6, -0.1)

static func _stone_stair(k: Ink, p: Dictionary, box: Rect2, ground_y: float) -> void:
	var steps := clampi(int(box.size.y / 48.0), 4, 14)
	var rise := box.size.y / steps
	var run := box.size.x / steps
	for i in steps:
		var tread := Rect2(box.position.x + i * run, box.end.y - (i + 1) * rise, run + 6.0, rise)
		var face := k.rough_rect(tread, 0.8)
		k.fill(face, p.stone.lerp(p.dust, k.rand(0.2, 0.5)))
		k.hatch(PackedVector2Array([tread.position + Vector2(0, 12), Vector2(tread.end.x, tread.position.y + 12.0), tread.end, Vector2(tread.position.x, tread.end.y)]), HATCH, 4.0, 0.8, Color(p.ink, 0.35))
		k.outline(face, 2.2, p.ink, 0.4, 0.8)
		k.stroke(PackedVector2Array([tread.position, Vector2(tread.end.x, tread.position.y)]), 3.0, p.ink, 0.6, 0.0, 1.0, 10.0)
		if k.chance(0.3):
			k.crack(tread.position + Vector2(k.rand(6, run - 6), 2.0), Vector2(k.rand(-0.3, 0.3), 1), rise * 0.6, 0.9, Color(p.ink, 0.6), 1)
	# A rope rail on iron eyes beside it.
	var rope := Ink.sag(Vector2(box.position.x + 10.0, box.end.y - 70.0), Vector2(box.end.x - 10.0, box.position.y - 60.0), 14.0, 20)
	k.stroke(rope, 2.6, p.umber, 0.4, 0.0, 1.0, 12.0)
	for i in range(0, 20, 5):
		k.blob(rope[i], 2.6, p.slate, 6)

static func _organ(k: Ink, p: Dictionary, box: Rect2, ground_y: float) -> void:
	# Pipes in a rank, tallest in the middle, on a case with its stops.
	var pipes := clampi(int(box.size.x / 34.0), 5, 40)
	var pitch := box.size.x / pipes
	var foot := minf(box.end.y, ground_y)
	var case := k.rough_rect(Rect2(box.position.x, foot - 70.0, box.size.x, 70.0), 0.8)
	k.fill(case, p.wood.lerp(p.paper, 0.15))
	k.hatch(case, HATCH, 4.0, 0.8, Color(p.ink, 0.3))
	for i in pipes:
		var t := absf((i + 0.5) / pipes - 0.5) * 2.0
		var height := (box.size.y - 90.0) * (1.0 - 0.55 * pow(t, 1.4)) + k.rand(-8, 8)
		var x := box.position.x + (i + 0.5) * pitch
		var width := pitch * 0.7
		var pipe := PackedVector2Array([Vector2(x - width * 0.5, foot - 70.0), Vector2(x - width * 0.5, foot - 70.0 - height),
			Vector2(x, foot - 82.0 - height), Vector2(x + width * 0.5, foot - 70.0 - height), Vector2(x + width * 0.5, foot - 70.0)])
		k.fill(pipe, p.brass.lerp(p.paper, 0.35) if i % 3 != 1 else p.slate.lerp(p.paper, 0.4))
		k.shade(pipe, LIGHT, 0.4, 2.8, 0.8, Color(p.ink, 0.5))
		k.hair(Vector2(x - width * 0.3, foot - 74.0 - height * 0.95), Vector2(x - width * 0.3, foot - 76.0), 0.9, Color(p.light, 0.5))
		k.outline(pipe, 1.8, p.ink, 0.3, 0.6)
		var mouth := PackedVector2Array([Vector2(x - width * 0.3, foot - 86.0), Vector2(x + width * 0.3, foot - 86.0), Vector2(x, foot - 96.0)])
		k.fill(mouth, p.deep)
	k.outline(case, 2.6, p.ink, 0.4, 0.8)
	for stop in int(box.size.x / 60.0):
		k.blob(Vector2(box.position.x + 30.0 + stop * 60.0, foot - 40.0), 3.0, p.light, 8)
		k.outline(k.ellipse_points(Vector2(box.position.x + 30.0 + stop * 60.0, foot - 40.0), Vector2(3.5, 3.5), 0.0, 8), 1.0, p.ink, 0.1, 0.0)

static func _cradle(k: Ink, p: Dictionary, box: Rect2) -> void:
	# The headshell: the arm's end, where the point rests. A curved shell
	# hanging from the arm that comes in at the top of the box.
	var arm_from := Vector2(box.end.x, box.position.y + 20.0)
	var shell := Vector2(box.position.x + box.size.x * 0.4, box.end.y - 90.0)
	var arm := Ink.cubic(arm_from, Vector2(box.get_center().x + 60.0, box.position.y + 10.0), Vector2(shell.x + 40.0, shell.y - 120.0), shell + Vector2(20.0, -40.0), 20)
	var widths := PackedFloat32Array()
	for i in arm.size():
		widths.append(lerpf(22.0, 14.0, float(i) / float(arm.size() - 1)))
	k.ribbon(arm, widths, p.slate.lerp(p.paper, 0.35), PackedFloat32Array(), 1.0)
	k.stroke(arm, 2.4, p.ink, 0.3, 0.0, 1.0, 12.0)
	var head := PackedVector2Array([shell + Vector2(-50, -42), shell + Vector2(46, -48), shell + Vector2(62, 10), shell + Vector2(30, 48), shell + Vector2(-44, 44), shell + Vector2(-66, 2)])
	k.fill(head, p.stone.lerp(p.dust, 0.2))
	k.hatch(head, HATCH, 4.0, 0.8, Color(p.ink, 0.22))
	k.shade(head, LIGHT, 0.35, 3.4, 0.9, Color(p.ink, 0.45))
	k.outline(head, 3.0, p.ink, 0.4, 1.0)
	k.fill(k.ellipse_points(shell + Vector2(-2, 2), Vector2(26, 18), 0.0, 16), p.deep.lerp(p.paper, 0.2))
	k.outline(k.ellipse_points(shell + Vector2(-2, 2), Vector2(26, 18), 0.0, 16), 1.8, p.ink, 0.2, 0.3)
	for screw: Vector2 in [Vector2(-40, -30), Vector2(40, -34), Vector2(44, 30)]:
		k.blob(shell + screw, 2.6, p.brass, 7)
	# A blanket thrown over its lip.
	var blanket := PackedVector2Array([shell + Vector2(-60, 10), shell + Vector2(-30, 36), shell + Vector2(-20, 70), shell + Vector2(-54, 80), shell + Vector2(-78, 40)])
	k.fill(blanket, p.patina.lerp(p.paper, 0.3))
	k.hatch(blanket, HATCH + 0.4, 4.0, 0.8, Color(p.ink, 0.3))
	k.outline(blanket, 2.0, p.ink, 0.3, 0.5)

static func _resting_arm(k: Ink, p: Dictionary, box: Rect2) -> void:
	var rest := Vector2(box.get_center().x, box.end.y - 30.0)
	var post := k.rough_rect(Rect2(rest.x - 10.0, rest.y - 120.0, 20.0, 120.0), 0.6)
	k.shape(post, p.slate, p.ink, 2.2)
	var fork := PackedVector2Array([rest + Vector2(-24, -130), rest + Vector2(-18, -150), rest + Vector2(-8, -128), rest + Vector2(8, -128), rest + Vector2(18, -150), rest + Vector2(24, -130)])
	k.shape(fork, p.slate.lerp(p.paper, 0.2), p.ink, 2.0)
	var arm := Ink.cubic(Vector2(box.position.x, box.position.y + 30.0), Vector2(box.position.x + 100.0, box.position.y), rest + Vector2(-60, -180), rest + Vector2(0, -140), 18)
	var widths := PackedFloat32Array()
	for i in arm.size():
		widths.append(lerpf(16.0, 10.0, float(i) / float(arm.size() - 1)))
	k.ribbon(arm, widths, p.slate.lerp(p.paper, 0.35), PackedFloat32Array(), 1.0)
	k.stroke(arm, 2.2, p.ink, 0.3, 0.0, 1.0, 12.0)
	k.blob(Vector2(box.position.x, box.position.y + 30.0), 14.0, p.slate, 12)
	k.outline(k.ellipse_points(Vector2(box.position.x, box.position.y + 30.0), Vector2(14, 14), 0.0, 12), 2.2, p.ink, 0.2, 0.0)

## Street furniture and litter along the ground.
static func _props(k: Ink, p: Dictionary, scene: Dictionary) -> void:
	for prop: Dictionary in scene.props:
		var x := float(prop.x)
		var y := float(prop.y)
		k.reseed(int(prop.seed))
		match StringName(prop.kind):
			&"crate": Set.crate(k, p, Rect2(x - 26.0, y - 46.0, 52.0, 46.0), "CANCELLED" if k.chance(0.4) else "")
			&"crates":
				Set.crate(k, p, Rect2(x - 30.0, y - 42.0, 52.0, 42.0), "")
				Set.crate(k, p, Rect2(x + 20.0, y - 36.0, 44.0, 36.0), "")
				Set.crate(k, p, Rect2(x - 18.0, y - 78.0, 40.0, 36.0), "")
			&"barrel": Set.barrel(k, p, Vector2(x, y), 17.0, 40.0)
			&"bench": Set.bench(k, p, Vector2(x, y))
			&"cart": Set.cart(k, p, Vector2(x, y))
			&"tapes":
				Set.tape(k, p, Vector2(x, y - 4.0), 0.7, k.rand(-0.2, 0.2))
				Set.tape(k, p, Vector2(x + 34.0, y - 3.0), 0.6, k.rand(-0.2, 0.2))
				k.stroke(Ink.cubic(Vector2(x + 10.0, y - 3.0), Vector2(x + 30.0, y - 16.0), Vector2(x + 50.0, y + 2.0), Vector2(x + 72.0, y - 6.0), 14), 1.2, p.umber, 0.3, 0.1, 0.5)
			&"bin":
				var bin := PackedVector2Array([Vector2(x - 12, y), Vector2(x - 16, y - 40), Vector2(x + 12, y - 40), Vector2(x + 8, y)])
				k.fill(bin, p.slate.lerp(p.paper, 0.4))
				for i in 4:
					k.line(Vector2(x - 11 + i * 6, y - 38), Vector2(x - 10 + i * 5, y - 2), 0.9, Color(p.ink, 0.6), 0.2, 0.0)
				k.outline(bin, 2.0, p.ink)
				k.shape(k.rough_rect(Rect2(x - 19.0, y - 45.0, 34.0, 6.0), 0.4), p.slate, p.ink, 1.8)
			&"stool":
				k.shape(k.rough_rect(Rect2(x - 16.0, y - 40.0, 32.0, 6.0), 0.4), p.wood, p.ink, 1.6)
				for leg: float in [-12.0, 12.0]:
					k.line(Vector2(x + leg, y - 34.0), Vector2(x + leg * 1.2, y), 2.4, p.wood, 0.1, 0.0)
					k.line(Vector2(x + leg - 1.0, y - 34.0), Vector2(x + leg * 1.2 - 1.0, y), 0.9, Color(p.ink, 0.7), 0.1, 0.0)
			&"chain":
				var hook := Vector2(x, y - 220.0)
				k.blob(hook, 3.0, p.slate, 8)
				var link := hook
				for i in 12:
					var next := link + Vector2(sin(i * 1.3) * 1.2, 11.0)
					k.outline(k.ellipse_points(link.lerp(next, 0.5), Vector2(2.6, 5.5), 0.0, 8), 1.4, p.ink, 0.1, 0.0)
					link = next
				k.blob(link, 4.0, p.slate, 8)
			&"pipe":
				k.line(Vector2(x, y), Vector2(x, y - 230.0), 7.0, p.slate, 0.2, 0.0)
				k.line(Vector2(x - 2.0, y), Vector2(x - 2.0, y - 230.0), 1.2, Color(p.ink, 0.7), 0.2, 0.0)
				for i in 3:
					k.shape(k.rough_rect(Rect2(x - 6.0, y - 40.0 - i * 80.0, 12.0, 10.0), 0.3), p.slate.darkened(0.2), p.ink, 1.4)
			_:
				pass

## The lamps: a post on a street, a wall lantern underground.
static func _lanterns(k: Ink, p: Dictionary, scene: Dictionary) -> void:
	var kind: StringName = scene.kind
	var ground_y := float(scene.ground_y)
	for hook: Vector2 in scene.lanterns:
		if kind in [&"street", &"yard"]:
			var post := k.rough_rect(Rect2(hook.x - 5.0, hook.y + 20.0, 10.0, ground_y - hook.y - 20.0), 0.5)
			k.shape(post, p.umber, p.ink, 2.2)
			k.line(hook + Vector2(0, 22), hook + Vector2(0, 2), 5.0, p.umber, 0.3, 0.0)
			k.path(PackedVector2Array([hook + Vector2(0, 22), hook + Vector2(-14, 8), hook + Vector2(0, 2)]), 1.4, p.ink, 0.3)
			k.shape(k.rough_rect(Rect2(hook.x - 12.0, ground_y - 8.0, 24.0, 8.0), 0.4), p.stone, p.ink, 1.8)
		else:
			var bracket := PackedVector2Array([hook + Vector2(-16, -6), hook + Vector2(0, 0), hook + Vector2(-16, 10)])
			k.path(bracket, 2.4, p.slate, 0.2)
		Set.lantern(k, p, hook)

# == the light ===========================================================================

## The room's light rig (press_ink_light.gd): the dawn down the page for the
## kind of place it is, the lamps the set drew, and the room's own authored
## light sources (lighting_profiles.gd) as the night's last lamps or the day
## coming in.
static func light_rig(scene: Dictionary) -> Dictionary:
	var bounds: Rect2 = scene.bounds
	var ground_y := float(scene.ground_y)
	var kind: StringName = scene.kind
	var top := bounds.position.y - 160.0
	var bottom := bounds.end.y + 240.0
	var dawn: Array = []
	match kind:
		&"street", &"yard":
			dawn = [[top, 0.6], [ground_y - 500.0, 0.5], [ground_y - 300.0, 0.34], [ground_y - 130.0, 0.26], [ground_y - 40.0, 0.22], [ground_y - 2.0, 0.3], [ground_y + 30.0, 0.5], [ground_y + 180.0, 0.64], [bottom, 0.72]]
		&"interior":
			dawn = [[top, 0.55], [ground_y - 420.0, 0.42], [ground_y - 200.0, 0.3], [ground_y - 40.0, 0.26], [ground_y, 0.3], [ground_y + 40.0, 0.5], [bottom, 0.6]]
		&"deep":
			dawn = [[top, 0.72], [ground_y - 300.0, 0.6], [ground_y - 80.0, 0.5], [ground_y, 0.56], [bottom, 0.74]]
		_:
			dawn = [[top, 0.7], [ground_y - 320.0, 0.56], [ground_y - 120.0, 0.42], [ground_y - 30.0, 0.36], [ground_y, 0.44], [ground_y + 60.0, 0.62], [bottom, 0.74]]
	var lamps: Array = []
	var first := true
	for hook: Vector2 in scene.lanterns:
		lamps.append({"at": hook + Vector2(0, 24), "reach": 260.0 if kind != &"deep" else 200.0, "warmth": 0.9, "glow": 90.0, "kind": &"lantern",
			"street": true, "flicker": first, "rays": 16 if first else 0})
		first = false
	var profile: Dictionary = Profiles.get_profile(StringName(scene.room_id))
	for source: Dictionary in profile.get("lights", []):
		var at: Vector2 = source.position
		var fixture := bool(source.get("fixture", false))
		var colour: Color = source.color
		var daylight := colour.b >= colour.r
		lamps.append({"at": at, "reach": float(source.radius) * 0.55, "warmth": 0.5 if daylight else 0.62, "glow": 0.0 if daylight else 36.0,
			"kind": &"daylight" if daylight else (&"bulb" if fixture else &"window"), "street": false})
	var sky: Array = []
	if kind in [&"street", &"yard"]:
		sky = [bounds.position.x + bounds.size.x * 0.28, bounds.position.x + bounds.size.x * 0.72, ground_y - 380.0, ground_y - 40.0, 0.5]
	var props: Array = []
	for prop: Dictionary in scene.props:
		props.append([float(prop.x), 40.0, 44.0])
	return {
		"area": Rect2(bounds.position.x - 120.0, top, bounds.size.x + 240.0, bottom - top),
		"dawn": dawn, "sky": sky, "lamps": lamps, "windows": [], "props": props, "shafts": [], "sheens": [],
		"street": ground_y, "failing": -1,
	}
