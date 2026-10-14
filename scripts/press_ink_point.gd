extends RefCounted
## Skip's point in the ink look (ink_look.gd): the canon's
## "oversized stylus-lance wrapped in unspooled cassette tape"
## (docs/BRAINSTORM.md, docs/CAST.md), the Engineer's stylus made a weapon.
## From the butt: a cartridge block, a taped grip, the cantilever shaft with
## loose wraps and one unspooled end, a ferrule, and the tip.
##
## Laws it keeps:
## - It is always touching something (docs/art/direction.html, 02): planted
##   on the street ahead at rest, dragged behind at a run (it scores a groove),
##   laid down to listen, stood upright beside the hood. It never goes through
##   the street; only the Accent bites into it.
## - The tip is part of the crackle meter (docs/CAST.md, "Costume is the
##   HUD"): pink while Skip is loud, grey when he is quiet or hooded.
## - The fitted Tip (the Book's Point slot) is the tip you see.
##
## The combo is a drummer's sticking. The Tap is a straight thrust; the Sweep
## is the up-stroke, rising from the street to over his head; the Accent is
## the down-stroke, the canon's flip-slam, over the top and into the street
## with both hands. A stroke lands on the frame it is struck (the game's strike
## has no wind-up), holds, then settles back to rest; its smear is the road the
## point took to get there.
##
## `solve` is pure: a pose in, the point's joints out, in Skip's local space
## (feet on y = 26). `draw`, `draw_swing` and `draw_contact` ink it.
## Presentation only: strike reach, timing and contact are the game's, never
## the drawing's.

const Ink := preload("res://scripts/press_ink.gd")

## Grip to the end of the tip, and grip to the butt: about as long as Skip is
## tall. Oversized on purpose.
const FRONT := 46.0
const BACK := 10.0
const TIP_LENGTH := 8.0
## Skip's feet in his own space: the street.
const GROUND := 26.0
## How far the Accent drives the tip into the street.
const BITE := 3.0

# Where the hand holds it and which way it points (degrees, 0 = ahead, +down),
# drawn facing right. Rest poses first, then the moments that move it.
const STAND := [Vector2(8, -3), 40.0]
const DRAG := [Vector2(-3, 1), 148.0]
const AIRBORNE := [Vector2(1, 2), 122.0]
const KNEEL := [Vector2(13, 14), 12.0]
const HOODED := [Vector2(21, -19), 90.0]
const POLISH := [Vector2(5, -9), -8.0]
const PARRY := [Vector2(10, -10), -55.0]
const KNOCKED := [Vector2(-5, -6), -130.0]
const POGO := [Vector2(3, 6), 92.0]
## The strokes: grip and line on the frame they land, then where the
## follow-through carries them. Tap: a straight thrust, level once he leans
## into it.
const TAP := [Vector2(19, -10), -12.0, Vector2(24, -10), -10.0]
## Sweep: the up-stroke. Its last number is where the stroke began, the tail of
## its smear: the street ahead.
const SWEEP := [Vector2(15, -8), -24.0, Vector2(9, -16), -78.0, 50.0]
## Accent: both hands raised before his face, the point driven down until the
## tip bites the street, then pressed in as he straightens; it came over the
## top from behind his head.
const ACCENT := [Vector2(27, -32), 66.0, Vector2(26, -20), 66.0, -140.0]
## A stroke's pose holds until this share of it has passed, then settles back
## to rest. Its follow-through runs over the first TRAVEL of it.
const HOLD := 0.45
const TRAVEL := 0.5

## Every fitted Tip by its item id (collection_catalog.gd, Point slot).
const TIPS := [&"", &"quicksilver_tip", &"blunt_stylus", &"spring_stylus", &"glass_needle", &"copper_stylus"]

static func solve(pose: Dictionary, combat: Dictionary, body: Transform2D, side: float, turn := 1.0, polish := 0.0) -> Dictionary:
	var run := clampf(float(pose.get("run", 0.0)), 0.0, 1.0)
	var air := clampf(float(pose.get("air", 0.0)), 0.0, 1.0)
	var hood := clampf(float(pose.get("hood", 0.0)), 0.0, 1.0)
	var kneel := clampf(float(pose.get("set", 0.0)), 0.0, 1.0)
	var strike := clampf(float(pose.get("strike", 0.0)), 0.0, 1.0)
	var step := clampi(int(pose.get("combo_step", 1)), 1, 3)
	var attack_face := -1.0 if float(pose.get("strike_face", side)) < 0.0 else 1.0
	var snap := float(combat.get("snap", 0.0))
	var guard := float(combat.get("guard", 0.0))
	var parry := float(combat.get("parry", 0.0))
	var hurt := float(combat.get("hurt_strength", 0.0))
	var pogo := float(combat.get("foot_tuck", 0.0))
	var queued := float(combat.get("queued", 0.0))
	polish = clampf(polish, 0.0, 1.0)

	# At rest: where the point lies while Skip is not swinging it.
	var grip: Vector2 = STAND[0]
	var angle: float = STAND[1]
	for blend in [[DRAG, run], [AIRBORNE, air], [KNEEL, kneel], [HOODED, hood], [POLISH, polish]]:
		grip = grip.lerp(blend[0][0], blend[1])
		angle = lerpf(angle, blend[0][1], blend[1])
	grip.x -= 3.0 * queued
	angle -= 18.0 * queued
	var rest_grip := grip * Vector2(side * turn, 1.0)
	var rest_dir := (_direction(angle, side) * Vector2(turn, 1.0)).normalized()

	# Swinging: the stroke's own clock runs from 0 on the frame it lands to 1
	# when its pose is spent (a hit's hold stops it). The pose holds, then
	# settles; the follow-through travels early.
	var progress := 1.0 - strike if strike > 0.0 else 1.0
	var held := snap
	if strike > 0.0:
		held = maxf(snap, (1.0 - smoothstep(HOLD, 1.0, progress)) * (1.0 - hurt) * (1.0 - parry))
	var travel := smoothstep(0.0, TRAVEL, progress)
	var attack_grip: Vector2 = TAP[0]
	var attack_angle: float = TAP[1]
	var arc_from := NAN
	match step:
		1:
			attack_grip = Vector2(TAP[0]).lerp(TAP[2], travel)
			attack_angle = lerpf(TAP[1], TAP[3], travel)
		2:
			attack_grip = Vector2(SWEEP[0]).lerp(SWEEP[2], travel)
			attack_angle = lerpf(SWEEP[1], SWEEP[3], travel)
			arc_from = SWEEP[4]
		3:
			attack_grip = Vector2(ACCENT[0]).lerp(ACCENT[2], travel)
			attack_angle = lerpf(ACCENT[1], ACCENT[3], travel)
			arc_from = ACCENT[4]
	attack_grip -= Vector2(7, 3) * guard
	attack_angle -= 30.0 * guard
	var grip_b := rest_grip.lerp(attack_grip * Vector2(attack_face, 1.0), held)
	var dir_b := rest_dir.slerp(_direction(attack_angle, attack_face), held)
	if parry > 0.0:
		var parry_face := -1.0 if float(combat.get("parry_face", side)) < 0.0 else 1.0
		grip_b = grip_b.lerp(PARRY[0] * Vector2(parry_face, 1.0), parry)
		dir_b = dir_b.slerp(_direction(PARRY[1], parry_face), parry)
	if hurt > 0.0:
		grip_b = grip_b.lerp(KNOCKED[0] * Vector2(side, 1.0), hurt)
		dir_b = dir_b.slerp(_direction(KNOCKED[1], side), hurt)
	if pogo > 0.0:
		grip_b = grip_b.lerp(POGO[0] * Vector2(attack_face, 1.0), pogo)
		dir_b = dir_b.slerp(_direction(POGO[1], attack_face), pogo)

	var grip_l := body * grip_b
	var dir_l := body.basis_xform(dir_b).normalized()
	# Touching something: at rest the tip finds the street exactly, whatever
	# the breath, bob or lean, and the Accent drives it a little way in.
	var moving := maxf(held, maxf(parry, maxf(hurt, pogo)))
	var slam := held * (1.0 if step == 3 else 0.0) * (1.0 - guard)
	var plant := (1.0 - air) * maxf((1.0 - moving) * (1.0 - polish), slam)
	var bite := BITE * (1.0 - air) * slam
	var slide := 0.0
	if plant > 0.0:
		var drop := GROUND + bite - grip_l.y
		if drop > 0.0:
			var lean := signf(dir_l.x) if absf(dir_l.x) > 0.05 else side
			var planted := Vector2(0.0, 1.0)
			if drop < FRONT:
				planted = Vector2(sqrt(FRONT * FRONT - drop * drop) * lean, drop).normalized()
			else:
				# Held too high to reach (a tall stretch under the hood), the
				# point slides down through the hand rather than lift off.
				slide = minf(drop - FRONT, BACK - 3.0) * plant
			dir_l = dir_l.slerp(planted, plant)
	# Never through the street: between poses, the shaft runs back up through
	# the hand rather than let the tip sink.
	var floor_y := GROUND + bite
	var sunk := grip_l.y + dir_l.y * (slide + FRONT) - floor_y
	if air < 0.5 and sunk > 0.0 and dir_l.y > 0.2:
		slide = maxf(slide - sunk / dir_l.y, 14.0 - FRONT)
	var origin := grip_l + dir_l * slide
	var tip := origin + dir_l * FRONT
	var two_hands := maxf(slam, parry)
	# The stroke's line in his own facing-right degrees: where its smear ends.
	var local := body.affine_inverse().basis_xform(dir_l)
	var centre := body * (attack_grip * Vector2(attack_face, 1.0))
	return {
		"grip": grip_l, "origin": origin, "dir": dir_l, "tip": tip, "butt": origin - dir_l * BACK,
		"planted": plant, "slam": slam * (1.0 - air), "two_hands": two_hands, "rear_grip": grip_l - dir_l * 7.0,
		"step": step, "snap": snap, "held": held, "progress": progress, "face": attack_face,
		"arc_from": arc_from, "arc_to": rad_to_deg(atan2(local.y, local.x * attack_face)),
		"centre": centre, "reach": maxf(tip.distance_to(centre), 20.0), "body": body,
		"run": run, "air": air, "hood": hood,
	}

## How loud the tip glows: the crackle meter, drained by the hood.
static func loudness(pose: Dictionary) -> float:
	var hood := clampf(float(pose.get("hood", 0.0)), 0.0, 1.0)
	return clampf(float(pose.get("noise", 0.0)) * 1.6, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.6, hood))

## The tip's paint: grey when quiet, crackle pink when loud.
static func tip_paint(quiet: Color, pink: Color, loud: float) -> Color:
	return quiet.lerp(pink, loud) if loud > 0.05 else quiet

static func _direction(degrees: float, face: float) -> Vector2:
	var radians := deg_to_rad(degrees)
	return Vector2(cos(radians) * face, sin(radians))

static func _jitter(points: PackedVector2Array, frame: int, salt: int, amount: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in points.size():
		var seed_value := float(i * 7 + salt * 131 + frame * 977)
		result.append(points[i] + Vector2(sin(seed_value * 12.9898), cos(seed_value * 78.233)) * amount)
	return result

# == drawing ===========================================================================

## The point itself. `c` is the figure palette (press_ink_figures.colours()).
static func draw(k: Ink, point: Dictionary, pose: Dictionary, c: Dictionary, pink: Color, tip_kind: StringName, frame: int) -> void:
	var grip: Vector2 = point.origin
	var dir: Vector2 = point.dir
	var across := dir.orthogonal()
	if across.y > 0.0:
		across = -across
	var at := func(d: float, w: float) -> Vector2: return grip + dir * d + across * w
	var time := float(pose.get("time", 0.0))
	var loud := loudness(pose)
	var shaft_end := FRONT - TIP_LENGTH - 1.0

	# The shaft: a tapered cantilever, light metal so it reads across Skip's
	# dark coat as well as the paper, with a lit edge.
	var shaft := PackedVector2Array([at.call(-3.0, 2.4), at.call(shaft_end, 1.3), at.call(shaft_end, -1.3), at.call(-3.0, -2.4)])
	shaft = _jitter(shaft, frame, 300, 0.3)
	k.fill(shaft, c.steel)
	k.outline(shaft, 1.3, c.edge, 0.1, 0.3, false)
	k.hair(at.call(2.0, 1.2), at.call(shaft_end - 3.0, 0.6), 0.8, Color(c.eye, 0.75))

	# The cartridge at the butt: a block, two screws, two pins.
	var cartridge := PackedVector2Array([at.call(-BACK, 3.6), at.call(-2.5, 3.2), at.call(-2.5, -3.2), at.call(-BACK, -3.6)])
	cartridge = _jitter(cartridge, frame, 301, 0.3)
	k.fill(cartridge, c.deep)
	k.outline(cartridge, 1.4, c.edge, 0.1, 0.3, false)
	for w: float in [-1.6, 1.6]:
		k.blob(at.call(-6.0, w), 0.7, c.eye, 5)
	k.hair(at.call(-BACK, 1.5), at.call(-BACK - 2.6, 1.9), 0.9, c.red)
	k.hair(at.call(-BACK, -1.5), at.call(-BACK - 2.6, -1.9), 0.9, c.eye)

	# Tape wound hard round the grip, looser down the shaft.
	for i in 6:
		var d := -2.4 + i * 1.95 + sin(i * 2.7) * 0.4
		var lean := 1.6 + sin(i * 1.9) * 0.6
		k.hair(at.call(d, -2.9), at.call(d + lean, 2.9), 1.9, c.tape)
		k.hair(at.call(d + 0.4, -2.5), at.call(d + lean * 0.8, 0.9), 0.6, Color(c.tape_shine, 0.8))
	for wrap: Array in [[13.0, 2.4], [19.0, 3.4], [25.5, 2.0]]:
		var d: float = wrap[0]
		k.hair(at.call(d, 2.4), at.call(d + float(wrap[1]), -2.4), 1.4, c.tape)
	# One end has come unwound and trails: hanging when he is still, streaming
	# behind at a run, whipping after a stroke.
	var side := -1.0 if float(pose.get("face", 1.0)) < 0.0 else 1.0
	var flow := Vector2(0, 1).lerp(Vector2(-side, 0.3), float(point.run))
	flow = flow.lerp(Vector2(-float(point.face) * 0.6, -0.5), float(point.held)).normalized()
	var unwound := PackedVector2Array([at.call(27.5, -1.6)])
	var flutter := 0.25 + float(point.run) * 0.4 + float(point.held) * 0.5
	var lengths := 6 + int(round(float(point.run) * 3.0))
	var grounded := false
	for i in range(1, lengths + 1):
		var sway := sin(time * 9.0 + i * 0.85) * flutter * float(i) / float(lengths)
		var heading := Vector2(-side, 0.0) if grounded else flow.rotated(sway)
		var next: Vector2 = unwound[i - 1] + heading * 4.6
		# Tape that reaches the street lies along it.
		if float(point.air) < 0.5 and next.y > GROUND - 0.6:
			next.y = GROUND - 0.6
			grounded = true
		unwound.append(next)
	var widths := PackedFloat32Array()
	for i in unwound.size():
		widths.append(lerpf(1.8, 0.8, float(i) / float(unwound.size() - 1)))
	k.ribbon(_jitter(unwound, frame, 302, 0.3), widths, c.tape)
	var shine := PackedVector2Array()
	for i in range(1, unwound.size() - 2):
		shine.append(unwound[i] + flow.orthogonal() * 0.3)
	if shine.size() >= 2:
		var thin := PackedFloat32Array()
		thin.resize(shine.size())
		thin.fill(0.45)
		k.ribbon(shine, thin, Color(c.tape_shine, 0.7))

	# Ferrule, then the tip.
	var ferrule := PackedVector2Array([at.call(shaft_end - 0.5, 2.3), at.call(shaft_end + 1.6, 2.1), at.call(shaft_end + 1.6, -2.1), at.call(shaft_end - 0.5, -2.3)])
	k.fill(ferrule, c.edge)
	_tip(k, at, shaft_end + 1.2, tip_kind, c, pink, loud, frame)

	# What it touches: the groove it scores in the street, the noise it makes.
	var tip: Vector2 = point.tip
	if float(point.planted) > 0.5 and float(point.air) < 0.3:
		var run := float(point.run)
		var trail := maxf(6.0, 36.0 * run)
		for line: float in [0.6, 2.2]:
			var groove := PackedVector2Array([tip + Vector2(0, line), tip + Vector2(-side * trail * 0.5, line), tip + Vector2(-side * trail, line)])
			k.ribbon(groove, PackedFloat32Array([0.9, 0.8, 0.5]), Color(c.line, 0.55), PackedFloat32Array([1.0, 0.55, 0.0]))
		if run > 0.15:
			for i in 3:
				var fleck := tip + Vector2(-side * (5.0 + i * 6.0 + sin(time * 17.0 + i) * 2.0), -2.0 - absf(sin(time * 13.0 + i * 2.0)) * 4.0)
				k.blob(fleck, 0.9, Color(c.line, 0.5 * run), 4)
			if loud > 0.05:
				for i in 3:
					var spark := tip + Vector2(-side * (2.0 + i * 3.5), -1.5 - i * 2.2)
					k.hair(spark, spark + Vector2(-side * 3.5, -2.4), 1.2, Color(pink, loud))

static func _tip(k: Ink, at: Callable, base: float, kind: StringName, c: Dictionary, pink: Color, loud: float, frame: int) -> void:
	var length := FRONT - base
	var glow := Color(pink, loud)
	var outline: Color = c.edge
	match kind:
		&"quicksilver_tip":
			# A long, liquid drop: likes the long straight streets.
			var drop := PackedVector2Array([at.call(base, 1.6), at.call(base + length * 0.45, 2.5), at.call(FRONT + 2.5, 0.0), at.call(base + length * 0.45, -2.5), at.call(base, -1.6)])
			k.fill(drop, c.silver.lerp(pink, loud * 0.5))
			k.hair(at.call(base + 1.0, 0.9), at.call(FRONT, 0.2), 0.8, Color(c.eye, 0.9))
			k.outline(_jitter(drop, frame, 310, 0.2), 1.2, outline, 0.0, 0.0, false)
		&"blunt_stylus":
			# A short rounded nub that finds its footing.
			k.fill(PackedVector2Array([at.call(base, 1.8), at.call(base + 2.0, 2.6), at.call(base + 2.0, -2.6), at.call(base, -1.8)]), c.steel)
			var nub := k.ellipse_points(at.call(base + 4.6, 0.0), Vector2(3.4, 3.4), 0.0, 12)
			k.fill(nub, c.steel.darkened(0.25).lerp(pink, loud * 0.6))
			k.outline(nub, 1.2, outline, 0.0, 0.0, false)
		&"spring_stylus":
			# A coiled spring behind a small point.
			for i in 4:
				var loop := k.ellipse_points(at.call(base + 0.8 + i * 1.5, 0.0), Vector2(0.9, 2.6), Vector2(at.call(1.0, 0.0) - at.call(0.0, 0.0)).angle(), 10)
				loop.append(loop[0])
				k.stroke(loop, 0.9, c.steel.darkened(0.3), 0.0, 0.0, 1.0, 100.0)
			var point := PackedVector2Array([at.call(base + 6.4, 1.6), at.call(FRONT, 0.0), at.call(base + 6.4, -1.6)])
			k.fill(point, c.steel.lerp(pink, loud))
			k.outline(point, 1.1, outline, 0.0, 0.0, false)
		&"glass_needle":
			# A clear shard: you see the street through it.
			var shard := PackedVector2Array([at.call(base, 2.4), at.call(base + length * 0.55, 3.1), at.call(FRONT + 1.0, 0.4), at.call(base + length * 0.5, -2.8), at.call(base, -2.2)])
			k.fill(shard, Color(c.glass.lerp(pink, loud * 0.6), 0.55))
			k.hair(at.call(base + 1.0, 1.4), at.call(FRONT - 1.5, 0.6), 0.7, Color(c.eye, 0.95))
			k.hair(at.call(base + 2.5, -1.0), at.call(base + 5.0, -1.6), 0.6, Color(c.eye, 0.8))
			k.outline(_jitter(shard, frame, 311, 0.2), 0.9, Color(outline, 0.8), 0.0, 0.0, false)
		&"copper_stylus":
			var diamond := PackedVector2Array([at.call(base, 0.0), at.call(base + length * 0.35, 3.3), at.call(FRONT, 0.0), at.call(base + length * 0.35, -3.3)])
			k.fill(diamond, c.copper.lerp(pink, loud * 0.6))
			k.hair(at.call(base + 1.2, 0.8), at.call(base + length * 0.7, 1.4), 0.8, Color(c.eye, 0.6))
			k.outline(_jitter(diamond, frame, 312, 0.2), 1.2, outline, 0.0, 0.0, false)
		_:
			# The Engineer's own point: a cut diamond, the crackle meter's tip.
			var diamond := PackedVector2Array([at.call(base, 0.0), at.call(base + length * 0.35, 3.3), at.call(FRONT, 0.0), at.call(base + length * 0.35, -3.3)])
			k.fill(diamond, tip_paint(c.quiet, pink, loud))
			k.hair(at.call(base + 1.2, 0.8), at.call(base + length * 0.7, 1.4), 0.8, Color(c.eye, 0.55))
			k.outline(_jitter(diamond, frame, 313, 0.2), 1.2, outline, 0.0, 0.0, false)
	if loud > 0.4:
		# Loud enough to see across a room: the tip glints.
		var centre: Vector2 = at.call(FRONT - 2.0, 0.0)
		for spoke in 4:
			var reach := (3.0 + loud * 3.0) * (1.0 if spoke % 2 == 0 else 0.6)
			var out := Vector2.from_angle(PI * 0.5 * spoke + 0.4) * reach
			k.hair(centre - out * 0.25, centre + out, 1.0, glow)

## The stroke's trace, drawn under Skip. A thrust leaves speed lines along the
## shaft; the Sweep and the Accent leave a smear: a band of paper cut through
## the scene with an ink edge, thin at the tail where the stroke began and full
## at the point. The band is a veil, never a wall: what it passes over (a foe
## and its tell) shows through, and more so on a hit. Heard, so its leading
## edge and the thrust's stab are pink; an off-beat stroke under a live groove
## prints them grey.
static func draw_swing(k: Ink, point: Dictionary, pose: Dictionary, c: Dictionary, pink: Color) -> void:
	var progress := float(point.progress)
	var fade := (1.0 - smoothstep(0.2, 0.62, progress)) * minf(float(point.held) * 2.0, 1.0)
	if fade <= 0.02:
		return
	var contact := StringName(pose.get("strike_contact", &"miss"))
	var strength := 0.75 if contact == &"miss" else (0.85 if contact == &"guard" else 1.0)
	var flat := clampf(float(pose.get("flat", 0.0)), 0.0, 1.0)
	var heard: Color = pink.lerp(c.quiet, flat)
	if int(point.step) == 1 or is_nan(float(point.arc_from)):
		_thrust(k, point, c, heard, fade, strength)
		return
	var veil := (0.3 if contact == &"hit" else 0.5) * (1.0 - smoothstep(0.1, 0.42, progress))
	_smear(k, point, c, heard, fade, strength, veil, bool(pose.get("big", false)))

static func _thrust(k: Ink, point: Dictionary, c: Dictionary, heard: Color, fade: float, strength: float) -> void:
	var tip: Vector2 = point.tip
	var dir: Vector2 = point.dir
	var across := dir.orthogonal()
	var length := lerpf(30.0, 10.0, smoothstep(0.0, 0.6, float(point.progress)))
	for lane: Array in [[-7.5, 0.55, 1.3], [-4.0, 1.0, 2.0], [4.0, 1.0, 2.0], [7.5, 0.55, 1.3]]:
		var w: float = lane[0]
		var front := tip - dir * 9.0 + across * w
		var back := front - dir * length * float(lane[1])
		k.stroke(PackedVector2Array([back, front]), float(lane[2]), Color(c.line, fade * strength), 0.0, 0.5, 0.15, 100.0)
	# The stab: three short strokes fanning ahead of the tip.
	for i in 3:
		var spoke := dir.rotated((i - 1) * 0.55)
		var reach := 9.0 if i == 1 else 6.0
		k.stroke(PackedVector2Array([tip + spoke * 2.5, tip + spoke * reach]), 2.0, Color(heard, fade * strength), 0.0, 0.3, 0.3, 100.0)

static func _smear(k: Ink, point: Dictionary, c: Dictionary, heard: Color, fade: float, strength: float, veil: float, heavy: bool) -> void:
	var centre: Vector2 = point.centre
	var body: Transform2D = point.body
	var face := float(point.face)
	var to := float(point.arc_to)
	# The tail catches up with the point as the stroke ends.
	var tail := lerpf(float(point.arc_from), to, smoothstep(0.0, 0.65, float(point.progress)))
	var reach := float(point.reach) + 2.0
	var depth := reach * (0.5 if heavy else 0.4)
	var count := 22
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	var swell := PackedFloat32Array()
	for i in count + 1:
		var t := float(i) / float(count)
		var a := deg_to_rad(lerpf(tail, to, t))
		var d := body.basis_xform(Vector2(cos(a) * face, sin(a))).normalized()
		var s := sin(t * PI * 0.5)
		outer.append(centre + d * reach)
		inner.append(centre + d * (reach - maxf(depth * s, 0.6)))
		swell.append(s)
	var band := outer.duplicate()
	var back := inner.duplicate()
	back.reverse()
	band.append_array(back)
	if veil > 0.02:
		k.fill(band, Color(c.paper, veil * fade))
	var heavy_edge := PackedFloat32Array()
	var light_edge := PackedFloat32Array()
	for s in swell:
		heavy_edge.append(lerpf(0.4, 3.0 if heavy else 2.3, s))
		light_edge.append(lerpf(0.3, 1.3, s))
	k.ribbon(outer, heavy_edge, Color(c.line, fade * strength))
	k.ribbon(inner, light_edge, Color(c.line, fade * strength * 0.8))
	# Speed lines through the band, starting late so the tail stays thin.
	for lane: Array in [[0.3, 0.3], [0.62, 0.55]]:
		var streak := PackedVector2Array()
		for i in range(int(count * float(lane[1])), count + 1):
			streak.append(outer[i].lerp(inner[i], float(lane[0])))
		var widths := PackedFloat32Array()
		for i in streak.size():
			widths.append(lerpf(0.3, 1.1, float(i) / float(maxi(streak.size() - 1, 1))))
		k.ribbon(streak, widths, Color(c.line, fade * strength * 0.7))
	# Heard: the leading half of the edge, just outside the ink.
	var ring := PackedVector2Array()
	var ring_widths := PackedFloat32Array()
	var half := int(count / 2.0)
	for i in range(half, count + 1):
		ring.append(outer[i] + (outer[i] - centre).normalized() * 2.6)
		ring_widths.append(lerpf(0.4, 3.0 if heavy else 2.2, float(i - half) / float(count - half)))
	k.ribbon(ring, ring_widths, Color(heard, fade * strength))

## What the stroke hits: a struck foe, a guard, the street under the Accent,
## a parry's ring. Drawn over Skip.
static func draw_contact(k: Ink, point: Dictionary, pose: Dictionary, combat: Dictionary, c: Dictionary, pink: Color) -> void:
	var tip: Vector2 = point.tip
	var dir: Vector2 = point.dir
	var impact := float(combat.get("impact", 0.0))
	if impact > 0.0:
		for i in 7:
			var out := Vector2.from_angle(TAU * i / 7.0 + 0.3)
			k.stroke(PackedVector2Array([tip + out * 3.0, tip + out * (6.0 + 6.0 * impact)]), 1.6, Color(c.line, impact), 0.0, 0.3, 0.2)
		var ring := k.ellipse_points(tip, Vector2.ONE * (5.0 + 9.0 * (1.0 - impact)), 0.0, 20)
		ring.append(ring[0])
		k.stroke(ring, 1.6, Color(pink, impact * 0.9), 0.0, 0.0, 1.0, 100.0)
	var guard := float(combat.get("guard", 0.0))
	if guard > 0.0:
		var face := float(point.face)
		k.hair(tip + Vector2(-face * 5.0, -4.0), tip + Vector2(face * 3.0, 2.0), 1.6, Color(c.quiet, guard))
		k.hair(tip + Vector2(-face * 3.0, 3.0), tip + Vector2(face * 4.0, -3.0), 1.2, Color(c.quiet, guard * 0.8))
	if int(point.step) == 3 and float(point.slam) > 0.5:
		_bite(k, point, pose, c, pink)
	var parry := float(combat.get("parry", 0.0))
	if parry > 0.0:
		# A parry rings: the shaft takes it and sings.
		var struck: Vector2 = point.grip + dir * 22.0
		var star := PackedVector2Array()
		for i in 8:
			var reach := (5.0 + parry * 4.0) if i % 2 == 0 else 1.8
			star.append(struck + Vector2.from_angle(TAU * i / 8.0 - PI * 0.5) * reach)
		k.fill(star, Color(c.eye, parry))
		k.outline(star, 1.1, Color(c.edge, parry), 0.0, 0.0, false)
		var ring := k.ellipse_points(struck, Vector2.ONE * (7.0 + (1.0 - parry) * 9.0), 0.0, 18)
		ring.append(ring[0])
		k.stroke(ring, 1.3, Color(pink, parry * 0.8), 0.0, 0.0, 1.0, 100.0)

## The Accent bites the street: cracks run from the tip, chips of it jump, and
## the canon's flip-slam marks (docs/art/direction.html, 02) curl up round the
## bite in pink. Off the beat it is only a knock: grey, smaller.
static func _bite(k: Ink, point: Dictionary, pose: Dictionary, c: Dictionary, pink: Color) -> void:
	var progress := float(point.progress)
	var burst := 1.0 - smoothstep(0.05, 0.75, progress)
	if burst <= 0.0:
		return
	var flat := clampf(float(pose.get("flat", 0.0)), 0.0, 1.0)
	var heavy := bool(pose.get("big", false))
	var scale := 1.0 if heavy else 0.6
	var heard: Color = pink.lerp(c.quiet, flat)
	var spread := smoothstep(0.0, 0.55, progress)
	var ground := Vector2(Vector2(point.tip).x, GROUND)
	var face := float(point.face)
	for side_sign: float in [-1.0, 1.0]:
		var reach := lerpf(9.0, 22.0, spread) * scale
		var crack := PackedVector2Array([ground, ground + Vector2(side_sign * reach * 0.35, 1.6),
			ground + Vector2(side_sign * reach * 0.62, 0.2), ground + Vector2(side_sign * reach, 1.8)])
		k.stroke(crack, 1.9, Color(c.line, burst), 0.2, 0.0, 1.0, 100.0)
		k.stroke(PackedVector2Array([crack[1], crack[1] + Vector2(side_sign * 4.0, 3.2) * scale]), 1.2, Color(c.line, burst * 0.8), 0.0, 0.0, 1.0, 100.0)
	for i in 6:
		var throw := Vector2((float(i) - 2.5) * 5.0 + face * 2.0, -16.0 - float(i % 3) * 7.0) * scale
		var chip := ground + throw * spread + Vector2(0.0, 34.0 * spread * spread)
		if chip.y < GROUND + 1.0:
			k.blob(chip, 2.3 - float(i % 2) * 0.7, Color(c.line, burst), 5)
	for mark: Array in [[-158.0, -1.0], [-124.0, -1.0], [-56.0, 1.0], [-22.0, 1.0]]:
		var a := deg_to_rad(float(mark[0]))
		var out := Vector2.from_angle(a)
		var start := ground + out * (6.0 + 5.0 * spread) * scale
		var bend := start + out * 6.0 * scale + Vector2(0.0, -3.0)
		var end := start + Vector2.from_angle(a + float(mark[1]) * 0.6) * 11.0 * scale
		k.stroke(Ink.bezier(start, bend, end, 8), 2.5 * scale, Color(heard, burst), 0.0, 0.3, 0.3, 100.0)
	if heavy:
		var arc := k.ellipse_points(ground, Vector2(12.0 + spread * 16.0, 4.0 + spread * 4.0), 0.0, 16, PI, TAU)
		k.stroke(arc, 1.6, Color(heard, burst * 0.8), 0.0, 0.3, 0.3, 100.0)
