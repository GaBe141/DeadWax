extends RefCounted
## Figures and fixtures in the art-direction test's ink (ink_test.gd).
##
## The canon's Tier B (docs/art/tier_compare.html): readable gameplay figures,
## a bold silhouette first, detail from texture and a thick line rather than
## frame count, one pink accent. Skip v2 (docs/art/direction.html, 02): a
## jagged asymmetric head, void-almond eyes with pinprick pupils, no mouth
## ever, one big boot, a tape-wrapped point that is always touching
## something, and the 45-sleeve hood whose centre hole is his face. His crack
## chips are the crackle meter: pink while he is loud, grey when quiet, gone
## under the hood. The Hound v2 is angular with its tag in etch gold.
##
## Boil is state: a freed soul's line redraws four times at about ten a
## second. Skip and the Hound boil; fixtures (machines and things) do not.
##
## Pure drawing from explicit poses. Joints come from the same combat and
## gesture samplers Quiet Wax uses, so the two looks move alike.

const Ink := preload("res://scripts/press_ink.gd")
const InkTest := preload("res://scripts/ink_test.gd")
const Combat := preload("res://scripts/press_skip_combat.gd")
const Gesture := preload("res://scripts/press_skip_gesture.gd")
const Plaza := preload("res://scripts/press_ink_plaza.gd")
const Point := preload("res://scripts/press_ink_point.gd")

const BOIL_RATE := 10.0
const BOIL_FRAMES := 4
const BOIL := 0.7

## Skip's head, facing right, feet at y = 26. Asymmetric on purpose: if it
## looks balanced, redraw it.
const HEAD := [Vector2(-18, -20), Vector2(-11, -32), Vector2(-3, -41), Vector2(10, -35), Vector2(20, -30),
	Vector2(14, -22), Vector2(21, -15), Vector2(11, -7), Vector2(-5, -6), Vector2(-14, -10)]
const BODY := [Vector2(-6, -9), Vector2(6, -9), Vector2(9, 8), Vector2(1, 10), Vector2(-9, 8)]
const EYES := [Vector2(-4.5, -22.0), Vector2(7.5, -21.5)]
## Where the crack chips sit: the left jag and the right notch of the head.
const CHIPS := [[Vector2(-17, -20), -1.0], [Vector2(15, -22), 1.0]]

static func colours() -> Dictionary:
	var far := InkTest.far_face
	var paper := InkTest.stock(far)
	var line := InkTest.ink(far)
	return {
		"paper": paper, "line": line,
		"body": InkTest.WAX if far else Color("17141b"),
		"edge": InkTest.GROOVE if far else InkTest.WAX,
		"eye": InkTest.GROOVE, "pupil": InkTest.WAX,
		"scratch": Color(InkTest.GROOVE, 0.55),
		"hood": InkTest.DUST.lerp(paper, 0.25) if not far else Color("2a2531"),
		"hood_edge": Color(line, 0.55),
		"quiet": InkTest.DUST.darkened(0.15) if not far else Color("6b6475"),
		"tape": Color("5e4231") if not far else Color("a3836a"),
		"tape_shine": Color("a07a5c") if not far else Color("d8bfa6"),
		"steel": Color("cfcac1") if not far else Color("3e3946"),
		"silver": Color("e3e6e8") if not far else Color("8d939a"),
		"glass": Color("dfeef0") if not far else Color("6f8a90"),
		"copper": Color("b06a42") if not far else Color("7a4a33"),
		"coat": InkTest.GROOVE.lerp(paper, 0.4) if not far else Color("cfc8bb"),
		"brass": InkTest.BRASS, "umber": InkTest.UMBER, "red": InkTest.CANCEL_RED,
		"stone": InkTest.STONE if not far else Color("2c2832"),
		"wood": Color("8a6440") if not far else Color("3a2e25"),
		"deep": InkTest.WAX,
	}

## Moves every point by this boil frame's small, fixed offset.
static func boiled(points: PackedVector2Array, frame: int, salt: int, amount := BOIL) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in points.size():
		var seed_value := float(i * 7 + salt * 131 + frame * 977)
		result.append(points[i] + Vector2(sin(seed_value * 12.9898) , cos(seed_value * 78.233)) * amount)
	return result

static func _boil_frame(time: float) -> int:
	return int(floor(time * BOIL_RATE)) % BOIL_FRAMES

# == Skip ===========================================================================

## Skip's body in his own space: the same squash, lean and bob as Quiet Wax,
## pivoting on the planted feet. Pure, so the point's laws can be checked
## against the body it is drawn with.
static func skip_body(pose: Dictionary) -> Transform2D:
	return _skip_body(pose, Combat.sample(pose), Gesture.sample(pose))

static func _skip_body(pose: Dictionary, combat: Dictionary, gesture: Dictionary) -> Transform2D:
	var time := float(pose.get("time", 0.0))
	var stride := float(pose.get("stride", 0.0))
	var run := clampf(float(pose.get("run", 0.0)), 0.0, 1.0)
	var air := clampf(float(pose.get("air", 0.0)), 0.0, 1.0)
	var kneel := clampf(float(pose.get("set", 0.0)), 0.0, 1.0)
	var land := float(pose.get("land", 0.0))
	var side := -1.0 if float(pose.get("face", 1.0)) < 0.0 else 1.0
	var quiet := (1.0 - float(combat.snap)) * (1.0 - float(combat.parry)) * (1.0 - float(combat.hurt_strength))
	var breath := sin(time * 2.7)
	var compression := sin(land * PI) * float(pose.get("impact", 0.0))
	var rise := maxf(-float(pose.get("vertical", 0.0)), 0.0) * air
	var stretch := Vector2(1.0 + compression * 0.22 - rise * 0.10 + kneel * 0.12,
		1.0 - compression * 0.22 + rise * 0.14 - kneel * 0.28)
	stretch.y += breath * 0.016 * (1.0 - run) + cos(stride * 2.0) * run * 0.04
	stretch += Vector2(combat.body_stretch) + Vector2(gesture.stretch) * quiet
	var tilt := side * (run * 0.16 + kneel * 0.06) + float(combat.body_tilt) + float(gesture.tilt) * quiet
	var bob := -absf(sin(stride)) * run * 3.0 - sin(float(pose.get("launch", 0.0)) * PI) * 2.0
	var anchor := Vector2(0, 26)
	var offset := Vector2(combat.body_offset) + Vector2(0, bob)
	var translation := anchor + offset - (anchor * stretch).rotated(tilt)
	return Transform2D(tilt, stretch, 0.0, translation)

static func draw_skip(canvas: CanvasItem, pose: Dictionary, pink: Color, tip_kind: StringName = &"") -> void:
	var c := colours()
	var k := Ink.new(canvas, 23)
	var time := float(pose.get("time", 0.0))
	var frame := _boil_frame(time)
	k.reseed(frame + 1)
	var stride := float(pose.get("stride", 0.0))
	var run := clampf(float(pose.get("run", 0.0)), 0.0, 1.0)
	var air := clampf(float(pose.get("air", 0.0)), 0.0, 1.0)
	var hood := clampf(float(pose.get("hood", 0.0)), 0.0, 1.0)
	var kneel := clampf(float(pose.get("set", 0.0)), 0.0, 1.0)
	var face := float(pose.get("face", 1.0))
	var land := float(pose.get("land", 0.0))
	var noise := clampf(float(pose.get("noise", 0.0)), 0.0, 1.0)
	var hurt := float(pose.get("hurt", 0.0))
	var attack_face := -1.0 if float(pose.get("strike_face", face)) < 0.0 else 1.0
	var combat := Combat.sample(pose)
	var gesture := Gesture.sample(pose)
	var snap: float = combat.snap
	var parry: float = combat.parry
	var hurt_strength: float = combat.hurt_strength
	var quiet := (1.0 - snap) * (1.0 - parry) * (1.0 - hurt_strength)
	var side := -1.0 if face < 0.0 else 1.0
	var turn := lerpf(0.6, 1.0, clampf(absf(face), 0.0, 1.0))
	var flip := Vector2(side * turn, 1.0)
	var body := _skip_body(pose, combat, gesture)

	# The point (press_ink_point.gd): where it is held, where it rests, how
	# each stroke carries it. Polishing it is an idle fidget.
	var fidget := Gesture.fidget(float(pose.get("idle", 0.0)))
	var polish := float(fidget.weight) * quiet * (1.0 - hood) * (1.0 - kneel) if fidget.kind == &"polish" else 0.0
	var point := Point.solve(pose, combat, body, side, turn, polish)
	var swing := maxf(snap, maxf(parry, hurt_strength))
	var rear_hand := body * (Vector2(-9, 5) * flip)
	if swing > 0.0:
		rear_hand = rear_hand.lerp(body * Vector2(combat.rear_hand), swing)
	var two_hands := float(point.two_hands)
	if two_hands > 0.0:
		rear_hand = rear_hand.lerp(point.rear_grip, two_hands)
	if polish > 0.0:
		var rub := 0.5 + 0.5 * sin(float(fidget.phase) * 2.4 * 13.0)
		rear_hand = rear_hand.lerp(Vector2(point.grip) + Vector2(point.dir) * lerpf(8.0, 30.0, rub), polish)

	# The stroke's trace through the air, under everything else.
	Point.draw_swing(k, point, pose, c, pink)
	# Legs next: the feet stay where they stand.
	for index in 2:
		var leg_side := -1.0 if index == 0 else 1.0
		var phase := stride + (PI if index == 0 else 0.0)
		var foot := Vector2(leg_side * 6.0 + sin(phase) * run * 10.0, 25.0 - maxf(0.0, cos(phase)) * run * 8.0)
		foot += Vector2(-side * air * 5.0, -air * (5.0 + leg_side * 2.0))
		foot += Vector2(-attack_face * 4.0, -14.0 + leg_side * 3.0) * float(combat.foot_tuck)
		if leg_side * side > 0.0:
			foot.y -= float(gesture.tap) * quiet
		var hip := body * (Vector2(leg_side * 4.0, 8.0) * flip)
		var knee := hip.lerp(foot, 0.5) + Vector2(side * (2.0 + kneel * 5.0) - side * run * 2.0, kneel * 2.0)
		var leg := boiled(PackedVector2Array([hip, knee, foot]), frame, 40 + index)
		k.path(leg, 3.0, c.body, 0.2)
		var rear := leg_side * side < 0.0
		_foot(k, leg[2], side, rear, c, frame, 50 + index)

	# The rear arm, behind the coat.
	var shoulder_back := body * (Vector2(-4, -6) * flip)
	var rear := rear_hand
	k.path(boiled(PackedVector2Array([shoulder_back, shoulder_back.lerp(rear, 0.5) + Vector2(-side * 2, 2), rear]), frame, 60), 2.6, c.body, 0.2)

	# Coat and head: one dark shape, thick-lined, a scratch of light on its edge.
	# Pulling the hood down, he folds into the sleeve.
	var squeeze := lerpf(1.0, 0.4, hood)
	var fold := Vector2(flip.x * squeeze, 1.0)
	var coat := _transformed(BODY, body, fold)
	coat = boiled(coat, frame, 1)
	var flash := hurt > 0.82 or (hurt > 0.0 and int(hurt * 7.0) % 2 == 0)
	var fill: Color = c.coat if flash else c.body
	k.fill(coat, fill)
	k.outline(coat, 2.4, c.edge, 0.2, 0.4)
	var head := _transformed(HEAD, body, fold)
	head = boiled(head, frame, 2)
	k.fill(head, fill)
	k.outline(head, 2.4, c.edge, 0.2, 1.2, false)
	if not flash:
		var lit := PackedVector2Array([head[1].lerp(head[0], 0.15), head[1].lerp(head[2], 0.1), head[2]])
		k.path(lit, 1.0, c.scratch, 0.2)
		k.hair(coat[0].lerp(coat[4], 0.2) + Vector2(side * 1.5, 0), coat[0].lerp(coat[4], 0.8) + Vector2(side * 1.5, 0), 0.8, c.scratch)

	# The point over the coat (beside the sleeve, it is drawn after the hood),
	# and the front arm over the point to the grip.
	var grip: Vector2 = point.grip
	var shoulder := body * (Vector2(4, -6) * flip)
	if hood <= 0.5:
		Point.draw(k, point, pose, c, pink, tip_kind, frame)
		k.path(boiled(PackedVector2Array([shoulder, shoulder.lerp(grip, 0.5) + Vector2(side * 2, 3), grip]), frame, 61), 2.6, c.body, 0.2)
		k.blob(grip, 2.6, c.body)

	# Eyes: void almonds with pinprick pupils. No mouth, ever.
	var look := Vector2(gesture.eye) * quiet + Vector2(side * 1.0, kneel * 2.0)
	var blink_phase := fmod(time, 4.7)
	var blink := clampf(1.0 - absf(blink_phase - 4.43) / 0.085, 0.0, 1.0)
	var lid := maxf(blink, 0.72 if hurt > 0.1 else kneel * 0.3)
	var happy := float(gesture.happy) * quiet > 0.5 and hurt <= 0.1
	if hood < 0.6:
		for i in 2:
			var eye_center: Vector2 = EYES[i] * Vector2(side * turn * squeeze, 1.0) + look
			var slant := -0.18 if i == 0 else 0.14
			if happy:
				var arc := PackedVector2Array()
				for j in 7:
					var a := PI + PI * j / 6.0
					arc.append(body * (eye_center + Vector2(cos(a) * 3.6, sin(a) * 2.4 + 1.0)))
				k.path(boiled(arc, frame, 80 + i, 0.3), 1.6, c.eye, 0.0)
			elif lid > 0.65:
				k.hair(body * (eye_center + Vector2(-4, 0.5)), body * (eye_center + Vector2(4, -0.5)), 1.6, c.eye)
			else:
				var height := 2.7 * (1.0 - lid * 0.5)
				var almond := PackedVector2Array()
				for v: Vector2 in [Vector2(-5.2, 0.4), Vector2(-2.6, -0.9), Vector2(1.0, -1.0), Vector2(4.8, -0.2), Vector2(2.4, 0.8), Vector2(-1.6, 1.0)]:
					almond.append((v * Vector2(1.0, height)).rotated(slant * side))
				var drawn := PackedVector2Array()
				for v in almond:
					drawn.append(body * (eye_center + v))
				drawn = boiled(drawn, frame, 90 + i, 0.25)
				k.fill(drawn, c.eye)
				var pupil := eye_center + Vector2(side * 1.2, 0.0) + Vector2(gesture.eye) * 0.3 * quiet
				k.blob(body * pupil, 0.8, c.pupil, 5)
				if snap > 0.0 or parry > 0.0:
					# A hard brow: the eye narrows from above as the point lands.
					k.hair(body * (eye_center + Vector2(-5, -3.6 + i * 0.6)), body * (eye_center + Vector2(4.5, -2.4 - i * 0.6)), 1.6, c.body)

	# Crack chips: the crackle meter. Pink while heard, grey when quiet.
	if hood < 0.5:
		var loud := clampf(noise * 1.6, 0.0, 1.0)
		var chip_paint: Color = c.quiet.lerp(pink, loud) if loud > 0.05 else c.quiet
		for chip in CHIPS:
			var at: Vector2 = chip[0] * Vector2(side * turn * squeeze, 1.0)
			var out := float(chip[1]) * side
			var mark := PackedVector2Array([at + Vector2(out * 5.0, -4.5), at + Vector2(out * 0.5, 0.0), at + Vector2(out * 5.0, 4.0)])
			var drawn := PackedVector2Array()
			for v in mark:
				drawn.append(body * v)
			k.path(boiled(drawn, frame, 100 + int(out), 0.3), 1.8 + loud * 0.8, chip_paint, 0.0)
		if loud > 0.35:
			for i in 3:
				var fleck := body * (Vector2(side * (-18.0 - i * 3.0), -30.0 + i * 5.0))
				k.blob(fleck, 1.0 + loud * 0.6, Color(pink, loud * 0.8), 4)

	# The hood: a 45 sleeve pulled down over him. Its centre hole is the face.
	if hood > 0.0:
		var apex := lerpf(18.0, -50.0, hood)
		var spread := lerpf(9.0, 25.0, hood)
		var sleeve := PackedVector2Array([Vector2(-spread, 26), Vector2(-3.0, apex), Vector2(3.0, apex - 1.0), Vector2(spread, 26)])
		var drawn := PackedVector2Array()
		for v in sleeve:
			drawn.append(body * (v * Vector2(side, 1.0)))
		drawn = boiled(drawn, frame, 120, 0.5)
		k.fill(drawn, Color(c.hood, minf(hood * 1.6, 1.0)))
		var shadow := k.shadow_side(drawn, Vector2(-side, -1.0), 0.4)
		for piece in shadow:
			k.hatch(piece, -PI * 0.25 if side > 0 else -PI * 0.75, 3.0, 0.8, Color(c.hood_edge, 0.6 * hood))
		k.outline(drawn, 2.0, Color(c.hood_edge, hood), 0.2, 0.5)
		if hood > 0.45:
			var hole := body * Vector2(side * 0.5, -20.0)
			var ring := k.ellipse_points(hole, Vector2(7.2, 7.2), 0.0, 14)
			ring = boiled(ring, frame, 130, 0.3)
			var open := clampf((hood - 0.45) / 0.3, 0.0, 1.0)
			k.fill(ring, Color(c.body, open))
			k.outline(ring, 1.4, Color(c.hood_edge, open), 0.1, 0.0)
			for eye_side: float in [-1.0, 1.0]:
				k.blob(hole + Vector2(eye_side * 2.6 + side * 0.8, -0.5), 1.1, Color(c.eye, open), 5)
	if hood > 0.5:
		Point.draw(k, point, pose, c, pink, tip_kind, frame)
		k.path(boiled(PackedVector2Array([shoulder, shoulder.lerp(grip, 0.5) + Vector2(side * 2, 3), grip]), frame, 61), 2.6, c.hood_edge, 0.2)

	# Heard: what the stroke hits, the knock of a landing.
	Point.draw_contact(k, point, pose, combat, c, pink)
	if land > 0.0 and float(pose.get("impact", 0.0)) > 0.35:
		for foot_side: float in [-1.0, 1.0]:
			var puff := Vector2(foot_side * (18 + (1.0 - land) * 18), 25 - sin(land * PI) * 4)
			k.hair(puff, puff + Vector2(foot_side * 6, -2), 1.4, Color(c.line, land * 0.6))
	if kneel > 0.0:
		# Kneeling to listen: the street's sound coming in, drawn soft.
		for i in 3:
			var arc := PackedVector2Array()
			var radius := 8.0 + i * 5.0 + sin(time * 3.0 + i) * 1.0
			for j in 7:
				var a := -0.7 + 1.4 * j / 6.0
				arc.append(body * (Vector2(side * 20.0, -18.0) + Vector2(cos(a) * radius * side, sin(a) * radius)))
			k.path(arc, 1.3, Color(c.line, kneel * (0.5 - i * 0.12)), 0.0)
	k.flush()

static func _transformed(design: Array, body: Transform2D, flip: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in design:
		result.append(body * (Vector2(point) * flip))
	return result

## One big boot behind, a small sharp foot in front.
static func _foot(k: Ink, at: Vector2, side: float, big: bool, c: Dictionary, frame: int, salt: int) -> void:
	var shape := PackedVector2Array()
	if big:
		for v: Vector2 in [Vector2(-6, -6), Vector2(3, -7), Vector2(4, -3), Vector2(9, -2), Vector2(9, 1), Vector2(-7, 1)]:
			shape.append(at + Vector2(v.x * side, v.y))
	else:
		for v: Vector2 in [Vector2(-2, -3), Vector2(2, -3), Vector2(7, 1), Vector2(-3, 1)]:
			shape.append(at + Vector2(v.x * side, v.y))
	shape = boiled(shape, frame, salt, 0.35)
	k.fill(shape, c.body)
	k.outline(shape, 1.6, c.edge, 0.1, 0.3)
	if big:
		k.hair(at + Vector2(-6 * side, -1), at + Vector2(8 * side, -1), 1.0, c.scratch)

static func _star(k: Ink, center: Vector2, size: float, fill: Color, edge: Color) -> void:
	var star := PackedVector2Array()
	for i in 8:
		var radius := size if i % 2 == 0 else size * 0.32
		star.append(center + Vector2.from_angle(TAU * i / 8.0 - PI * 0.5) * radius)
	k.fill(star, fill)
	k.outline(star, 1.2, edge, 0.0, 0.0)

## Kicked-up street dust: small scribbled puffs that fade.
static func draw_dust(canvas: CanvasItem, puffs: Array) -> void:
	var c := colours()
	var k := Ink.new(canvas, 5)
	for puff in puffs:
		var age := clampf(float(puff.get("age", 0.0)), 0.0, 1.0)
		var at: Vector2 = puff.get("at", Vector2.ZERO)
		var size := float(puff.get("size", 1.0)) * (3.0 + age * 6.0)
		var ring := k.ellipse_points(at, Vector2(size, size * 0.7), age * 2.0, 9)
		ring.append(ring[0])
		k.stroke(ring, 1.1, Color(c.line, (1.0 - age) * 0.55), 0.6, 0.3, 0.2, 100.0)
	k.flush()

# == the Hound ========================================================================

## The Engineer's dog, still waiting by the great horn, one ear to the ground.
static func draw_hound(canvas: CanvasItem, pose: Dictionary, gold: Color) -> void:
	var c := colours()
	var k := Ink.new(canvas, 31)
	var clock := float(pose.get("clock", 0.0))
	var frame := _boil_frame(clock)
	k.reseed(frame + 3)
	var phase := String(pose.get("phase", "patrol"))
	var gait := float(pose.get("gait", 0.0))
	var stride := float(pose.get("speed", 0.0))
	var sit := float(pose.get("sit", 0.0))
	var wag := float(pose.get("wag", 0.25))
	var side := -1.0 if float(pose.get("face", 1.0)) < 0.0 else 1.0
	var state_time := float(pose.get("time", 0.0))
	var startle := 0.0
	if phase == "startled":
		startle = sin(clampf(state_time / 0.3, 0.0, 1.0) * PI)
	# Listening at the end of a round: the head goes down, one ear to the ground.
	var listen := 0.0
	if phase == "notice":
		listen = sin(clampf(state_time / 0.85, 0.0, 1.0) * PI)
	var breath := sin(clock * 2.8) * 0.8
	var bob := -absf(sin(gait)) * stride * 2.5 - startle * 7.0
	var mirror := Vector2(side, 1.0)
	var body_at := Vector2(-4.0, -6.0 + breath + bob + sit * 5.0)
	var lean := -sit * 0.28 + listen * 0.08
	var xform := Transform2D(lean * side, Vector2.ONE, 0.0, body_at * mirror)
	var p := func(v: Vector2) -> Vector2: return xform * (v * mirror)

	# Far legs, then the body, then near legs: all short and planted.
	var legs := [[Vector2(-20, 8), -22.0, gait + PI, true], [Vector2(16, 8), 22.0, gait, true],
		[Vector2(-15, 10), -14.0, gait, false], [Vector2(20, 9), 28.0, gait + PI, false]]
	for leg in legs:
		if bool(leg[3]):
			_hound_leg(k, p.call(leg[0]), Vector2(leg[1], 0), float(leg[2]), stride, sit if float(leg[1]) < 0.0 else 0.0, side, c, frame, Color(c.line, 0.75))
	# The tail: up and going when he is glad, tucked when he is startled.
	var tail_root: Vector2 = p.call(Vector2(-27, -6))
	var swing := sin(clock * (5.0 + wag * 11.0)) * (0.15 + wag * 0.5)
	var tail_tip := tail_root + Vector2(-side * 10.0, -22.0).rotated(swing * side)
	var curl := tail_tip + Vector2(side * 7.0, -3.0).rotated(swing * side)
	if phase == "startled":
		tail_tip = tail_root + Vector2(-side * 12.0, 12.0)
		curl = tail_tip + Vector2(side * 3.0, 4.0)
	var tail := Ink.cubic(tail_root, tail_root + Vector2(-side * 12.0, -4.0), tail_tip + Vector2(-side * 6.0, 4.0), tail_tip, 8)
	tail.append(curl)
	k.stroke(boiled(tail, frame, 200, 0.5), 4.4, c.line, 0.2, 0.3, 0.35)
	# Body: angular, paper-pale, hatched underneath, thick-lined.
	var torso := PackedVector2Array()
	for v: Vector2 in [Vector2(-30, -6), Vector2(-21, -21), Vector2(4, -24), Vector2(22, -17), Vector2(30, -2), Vector2(22, 13), Vector2(-6, 15), Vector2(-27, 9)]:
		torso.append(p.call(v))
	torso = boiled(torso, frame, 210)
	k.fill(torso, c.coat)
	for piece in k.shadow_side(torso, Vector2(-side * 0.4, -1.0), 0.42):
		k.hatch(piece, -PI * 0.25 if side > 0 else -PI * 0.75, 3.2, 0.9, Color(c.line, 0.6))
	for piece in k.shadow_side(torso, Vector2(-side * 0.4, -1.0), 0.18):
		k.hatch(piece, PI * 0.25 if side > 0 else PI * 0.75, 3.6, 0.8, Color(c.line, 0.5))
	k.outline(torso, 2.8, c.line, 0.3, 0.8)
	# A patch on his back, the colour of an old label.
	var patch := PackedVector2Array()
	for v: Vector2 in [Vector2(-14, -20), Vector2(2, -22), Vector2(6, -12), Vector2(-10, -10)]:
		patch.append(p.call(v))
	k.fill(boiled(patch, frame, 215, 0.4), Color(c.umber, 0.55))
	for leg in legs:
		if not bool(leg[3]):
			_hound_leg(k, p.call(leg[0]), Vector2(leg[1], 0), float(leg[2]), stride, sit if float(leg[1]) < 0.0 else 0.0, side, c, frame, c.line)
	# Head: down to the ground when listening, up and nuzzling when petted.
	var pet := float(pose.get("pet", 0.0))
	var sniff := sin(clock * 7.0) * 1.6 * (1.0 - listen)
	var nuzzle := sin(clock * 3.5) * 2.4 * pet
	var head_at: Vector2 = p.call(Vector2(30.0 + sniff + nuzzle, -26.0 - sit * 4.0 - startle * 5.0))
	head_at += Vector2(side * listen * 6.0, listen * 24.0)
	var tilt_head := side * (listen * 0.5 - pet * 0.1)
	var h := func(v: Vector2) -> Vector2: return head_at + (v * mirror).rotated(tilt_head)
	var neck := PackedVector2Array([p.call(Vector2(14, -16)), p.call(Vector2(24, -8)), h.call(Vector2(-4, 8)), h.call(Vector2(-10, -4))])
	k.fill(boiled(neck, frame, 220, 0.4), c.coat)
	var skull := PackedVector2Array()
	for v: Vector2 in [Vector2(-11, -7), Vector2(-3, -12), Vector2(7, -11), Vector2(12, -6), Vector2(23, -4), Vector2(26, 1), Vector2(21, 6), Vector2(9, 7), Vector2(-6, 8)]:
		skull.append(h.call(v))
	skull = boiled(skull, frame, 230)
	k.fill(skull, c.coat)
	for piece in k.shadow_side(skull, Vector2(-side * 0.3, -1.0), 0.3):
		k.hatch(piece, -PI * 0.25 if side > 0 else -PI * 0.75, 3.0, 0.8, Color(c.line, 0.55))
	k.outline(skull, 2.6, c.line, 0.3, 0.6)
	k.path(PackedVector2Array([neck[0], neck[3]]), 2.4, c.line, 0.3)
	k.path(PackedVector2Array([neck[1], neck[2]]), 2.4, c.line, 0.3)
	k.blob(h.call(Vector2(25, -1)), 3.0, c.line)
	k.path(PackedVector2Array([h.call(Vector2(23, 4)), h.call(Vector2(16, 5)), h.call(Vector2(12, 4))]), 1.3, c.line, 0.1)
	# The ear: a jag that stands when he listens to you, lies flat on the ground.
	var ear_lift := 7.0 * startle + (3.0 if phase == "notice" else 0.0) - listen * 10.0
	var ear := PackedVector2Array([h.call(Vector2(-13, -7)), h.call(Vector2(-15, -20 - ear_lift)), h.call(Vector2(-9, -15 - ear_lift * 0.6)), h.call(Vector2(-1, -10))])
	if listen > 0.5:
		ear = PackedVector2Array([h.call(Vector2(-8, -6)), h.call(Vector2(-22, 5)), h.call(Vector2(-15, 4)), h.call(Vector2(-17, 9)), h.call(Vector2(-4, -1))])
	ear = boiled(ear, frame, 240, 0.4)
	k.fill(ear, c.umber)
	k.outline(ear, 1.8, c.line, 0.2, 0.4)
	k.hair(ear[0].lerp(ear[2], 0.5), ear[1].lerp(ear[2], 0.25), 1.0, Color(c.coat, 0.6))
	# Eye: a dot; shut in a contented curve while he is petted.
	var eye: Vector2 = h.call(Vector2(9, -5))
	if phase == "pet":
		var curve := PackedVector2Array()
		for j in 6:
			var a := PI + PI * j / 5.0
			curve.append(eye + Vector2(cos(a) * 2.8, sin(a) * 1.8 + 1.0))
		k.path(curve, 1.4, c.line, 0.0)
	else:
		k.blob(eye, 1.6 + startle * 0.5, c.line, 6)
	# Collar and its tag, in etch gold.
	var collar_a: Vector2 = h.call(Vector2(-9, 4))
	var collar_b: Vector2 = p.call(Vector2(20, -12))
	k.path(PackedVector2Array([collar_a, collar_a.lerp(collar_b, 0.5) + Vector2(0, 2), collar_b]), 2.6, c.red.lerp(c.line, 0.3), 0.1)
	var tag := collar_a.lerp(collar_b, 0.5) + Vector2(side * 1.0, 6.0 + sin(clock * 4.0) * stride * 1.2)
	k.line(collar_a.lerp(collar_b, 0.5) + Vector2(0, 2), tag + Vector2(0, -2.6), 1.0, c.line, 0.0, 0.0)
	var disc := k.ellipse_points(tag, Vector2(3.4, 3.4), 0.0, 10)
	k.fill(disc, gold)
	k.outline(disc, 1.2, c.line, 0.0, 0.0)
	k.flush()

static func _hound_leg(k: Ink, hip: Vector2, stance: Vector2, gait: float, stride: float, sit: float, side: float, c: Dictionary, frame: int, paint: Color) -> void:
	var swing := sin(gait)
	var foot := Vector2(hip.x + side * (stance.x * 0.3) + side * swing * stride * 8.0, 26.0 - maxf(swing, 0.0) * stride * 7.0)
	foot.x = lerpf(foot.x, hip.x - side * 10.0, sit)
	var knee := hip.lerp(foot, 0.5) + Vector2(-side * (2.0 + sit * 6.0), 0)
	var leg := boiled(PackedVector2Array([hip, knee, foot]), frame, int(hip.x * 3.0) & 255, 0.4)
	k.path(leg, 3.6, paint, 0.2)
	k.path(PackedVector2Array([foot + Vector2(-side * 2.0, 0), foot + Vector2(side * 5.0, 0.5)]), 3.4, paint, 0.1)

# == fixtures (no boil: these are things, not souls) ===================================

## The polish patch: an old pressing propped against the plinth, filmed in
## dust until a hooded, quiet buff brings its black back.
static func draw_polish(canvas: CanvasItem, pose: Dictionary) -> void:
	var c := colours()
	var k := Ink.new(canvas, 41)
	var done := bool(pose.get("done", false))
	var progress := clampf(float(pose.get("progress", 0.0)), 0.0, 1.0)
	var disc := k.ellipse_points(Vector2.ZERO, Vector2(26, 26), 0.0, 32)
	k.fill(disc, c.deep if done else c.deep.lerp(c.paper, 0.55 - progress * 0.4))
	for radius: float in [22.0, 18.5, 15.0, 11.5]:
		var ring := k.ellipse_points(Vector2.ZERO, Vector2(radius, radius), 0.0, 28)
		ring.append(ring[0])
		k.stroke(ring, 0.7, Color(c.paper if done else c.line, 0.35), 0.2, 0.0, 1.0, 100.0)
	if not done:
		k.stipple(disc, 70, Color(c.paper, 0.6 - progress * 0.4), 0.9)
		k.hatch(disc, -PI * 0.25, 4.0, 0.8, Color(c.line, 0.3))
	var label := k.ellipse_points(Vector2.ZERO, Vector2(7, 7), 0.0, 14)
	k.fill(label, c.paper if done else c.paper.lerp(c.line, 0.15))
	k.blob(Vector2.ZERO, 1.4, c.line)
	k.outline(disc, 2.4, c.line, 0.2, 0.0)
	if done:
		for arc: Array in [[-2.6, -1.9], [-1.5, -1.1]]:
			var shine := k.ellipse_points(Vector2.ZERO, Vector2(20, 20), 0.0, 8, arc[0], arc[1])
			k.stroke(shine, 2.0, Color(c.paper, 0.9), 0.0, 0.3, 0.3, 100.0)
		var sparkle := float(pose.get("sparkle", 0.0))
		if sparkle > 0.0:
			for i in 4:
				var at := Vector2.from_angle(i * 1.9 - 0.6) * (26.0 + (1.0 - sparkle) * 12.0)
				_star(k, at, 4.0 + sparkle * 3.0, Color(c.paper, sparkle), Color(c.line, sparkle))
	elif progress > 0.0:
		var ring := k.ellipse_points(Vector2.ZERO, Vector2(34, 34), 0.0, 48, -PI * 0.5, -PI * 0.5 + TAU * progress)
		k.stroke(ring, 2.0, c.line, 0.3, 0.1, 0.4, 100.0)
	k.flush()

## A passage: the plaza draws the doorway or arch; this is what moves in it.
static func draw_passage(canvas: CanvasItem, pose: Dictionary, font: Font) -> void:
	var c := colours()
	var k := Ink.new(canvas, 43)
	var near := bool(pose.get("near", false))
	var locked := bool(pose.get("locked", false))
	var arch := StringName(pose.get("target", &"")) in Plaza.ARCHES
	if arch:
		if near and not locked:
			# Two small ink chevrons at the threshold: this way.
			for i in 2:
				var x := -6.0 + i * 9.0
				k.path(PackedVector2Array([Vector2(x - 3, 14), Vector2(x + 2, 18), Vector2(x - 3, 22)]), 1.8, c.paper, 0.0)
		k.flush()
		return
	var opening := Rect2(-27, -70, 54, 96)
	k.fill(k.rect_points(opening), c.deep)
	if near and not locked:
		# Ajar: the panel swings in on its hinge and the dark shows past it.
		var panel := PackedVector2Array([Vector2(-27, -70), Vector2(-5, -64), Vector2(-5, 21), Vector2(-27, 26)])
		k.fill(panel, c.wood)
		k.hatch(panel, -PI * 0.25, 3.0, 0.8, Color(c.line, 0.55))
		k.outline(panel, 2.0, c.line, 0.2, 0.4)
		k.blob(Vector2(-9, -20), 1.8, c.brass)
		for i in 3:
			k.hair(Vector2(-1 + i * 7, -62 + i * 10), Vector2(-1 + i * 7, 22), 0.7, Color(c.paper, 0.12 - i * 0.03))
	else:
		var panel := k.rect_points(Rect2(-27, -70, 54, 96))
		k.fill(panel, c.wood)
		for i in 3:
			k.hair(Vector2(-27 + 13.5 * (i + 1), -68), Vector2(-27 + 13.5 * (i + 1), 24), 0.8, Color(c.line, 0.55))
		k.shade(panel, Vector2(-1, -1), 0.35, 3.2, 0.8, Color(c.line, 0.45))
		var pane := k.rough_rect(Rect2(-16, -60, 32, 22), 0.4)
		k.fill(pane, c.deep.lerp(c.paper, 0.2))
		k.line(Vector2(0, -60), Vector2(0, -38), 1.2, c.line, 0.0, 0.0)
		k.outline(pane, 1.6, c.line, 0.2, 0.3)
		k.blob(Vector2(18, -18), 2.0, c.brass)
		k.outline(panel, 2.2, c.line, 0.2, 0.4)
	if locked:
		for y: float in [-40.0, 0.0]:
			var board := PackedVector2Array([Vector2(-31, y - 4), Vector2(31, y + 2), Vector2(31, y + 10), Vector2(-31, y + 4)])
			k.fill(board, c.wood.lerp(c.paper, 0.2))
			k.outline(board, 1.6, c.line, 0.2, 0.4)
		k.flush()
		k.text(font, Vector2(-24, -14), "SEALED", 11, c.red, -0.12)
	k.flush()

## A lost pressing's cabinet on its ledge: glass front, a sleeve inside.
static func draw_lost_pressing(canvas: CanvasItem, state: Dictionary, font: Font) -> void:
	var c := colours()
	var k := Ink.new(canvas, 47)
	var collected := bool(state.get("collected", false))
	var available := bool(state.get("available", false))
	var near := bool(state.get("near", false))
	var cabinet := k.rough_rect(Rect2(-34, -60, 68, 82), 0.5)
	k.fill(cabinet, c.wood)
	k.shade(cabinet, Vector2(-1, -1), 0.3, 3.2, 0.8, Color(c.line, 0.5))
	var top := k.rough_rect(Rect2(-38, -66, 76, 8), 0.4)
	k.fill(top, c.wood.lerp(c.line, 0.25))
	for leg: float in [-28.0, 28.0]:
		k.line(Vector2(leg, 22), Vector2(leg, 26), 3.0, c.line, 0.0, 0.0)
	var glass := k.rough_rect(Rect2(-26, -50, 52, 62), 0.4)
	k.fill(glass, c.paper.lerp(c.deep, 0.65))
	if not collected:
		var bob := sin(float(state.get("clock", 0.0)) * 1.8) * 1.2 if available else 0.0
		var sleeve := k.rough_rect(Rect2(-17, -42 + bob, 34, 40), 0.5)
		k.fill(sleeve, c.paper)
		var hole := k.ellipse_points(Vector2(0, -22 + bob), Vector2(6, 6), 0.0, 12)
		k.fill(hole, c.deep)
		k.text(font, Vector2(-13, -30 + bob), "SEAM", 8, c.line)
		k.outline(sleeve, 1.4, c.line, 0.2, 0.4)
		if not available:
			k.line(Vector2(-24, -48), Vector2(24, 10), 2.2, Color(c.red, 0.85), 0.3, 0.1)
			k.line(Vector2(24, -48), Vector2(-24, 10), 2.2, Color(c.red, 0.85), 0.3, 0.1)
	else:
		k.text(font, Vector2(-17, -16), "empty", 9, c.paper)
	k.hatch(glass, PI * 0.35, 7.0, 0.8, Color(c.paper, 0.25), 0.5)
	k.outline(glass, 1.8, c.line, 0.2, 0.4)
	k.outline(cabinet, 2.4, c.line, 0.3, 0.6)
	k.outline(top, 2.0, c.line, 0.2, 0.4)
	if near:
		for x: float in [-46.0, 46.0]:
			k.path(PackedVector2Array([Vector2(x, -30), Vector2(x * 0.92, -22), Vector2(x, -14)]), 1.8, c.line, 0.0)
	k.flush()

## A recovered move's sleeve, standing in the street.
static func draw_ability_pickup(canvas: CanvasItem, state: Dictionary) -> void:
	if bool(state.get("owned", false)):
		return
	var c := colours()
	var k := Ink.new(canvas, 53)
	var available := bool(state.get("available", true))
	var near := bool(state.get("near", false))
	var bob := sin(float(state.get("clock", 0.0)) * 2.0) * 2.0
	var sleeve := k.rough_rect(Rect2(-24, -34 + bob, 48, 50), 0.6)
	k.fill(sleeve, c.paper.lerp(c.coat, 0.5))
	k.shade(sleeve, Vector2(-1, -1), 0.3, 3.2, 0.8, Color(c.line, 0.4))
	var hole := k.ellipse_points(Vector2(0, -9 + bob), Vector2(9, 9), 0.0, 16)
	k.fill(hole, c.deep)
	# The engraving: the point itself, taped at the grip.
	k.line(Vector2(-14, 6 + bob), Vector2(15, -26 + bob), 2.6, c.line, 0.2, 0.0)
	for i in 3:
		var at := Vector2(-10, 1 + bob).lerp(Vector2(15, -26 + bob), 0.1 + i * 0.08)
		k.hair(at + Vector2(-2.5, -2.5), at + Vector2(2.5, 2.5), 1.2, c.tape)
	k.outline(sleeve, 2.4, c.line, 0.3, 0.6)
	if not available:
		k.line(Vector2(-22, -30 + bob), Vector2(22, 12 + bob), 2.6, Color(c.red, 0.85), 0.3, 0.1)
	if near:
		for x: float in [-34.0, 34.0]:
			k.path(PackedVector2Array([Vector2(x, -16 + bob), Vector2(x * 0.9, -8 + bob), Vector2(x, 0 + bob)]), 1.8, c.line, 0.0)
	k.line(Vector2(-26, 25), Vector2(26, 25), 2.0, Color(c.line, 0.6), 0.3, 0.1)
	k.flush()
