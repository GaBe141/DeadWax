extends RefCounted
const Paint := preload("res://scripts/figure_paint.gd")
const Combat := preload("res://scripts/press_skip_combat.gd")
## Skip's living ink. Only an explicit pose and palette enter the Press;
## deformation is confined to draw commands, with the planted feet as pivot.

static func draw(canvas: CanvasItem, pose: Dictionary, palette: Dictionary) -> void:
	var paint := Paint.palette(palette.ink, palette.pale)
	var ink: Color = paint.edge
	var pale: Color = paint.cream
	var pink: Color = paint.coral
	var hood_ink: Color = paint.teal
	var time: float = pose.time
	var stride: float = pose.stride
	var run: float = pose.run
	var air: float = pose.air
	var hood: float = pose.hood
	var kneel: float = pose.set
	var face: float = pose.face
	var land: float = pose.land
	var combo_step := clampi(int(pose.get("combo_step", 1)), 1, 3)
	var attack_face := -1.0 if float(pose.get("strike_face", face)) < 0.0 else 1.0
	var contact := StringName(pose.get("strike_contact", &"miss"))
	var combat := Combat.sample(pose)
	var snap: float = combat.snap
	var parry: float = combat.parry
	var hurt: float = pose.hurt
	var noise: float = pose.noise
	var breath := sin(time * 2.7)
	var step := sin(stride)
	var compression := sin(land * PI) * float(pose.impact)
	var rise := maxf(-float(pose.vertical), 0.0) * air
	var stretch := Vector2(
		1.0 + compression * 0.24 - rise * 0.10 + kneel * 0.15,
		1.0 - compression * 0.24 + rise * 0.16 - kneel * 0.30
	)
	stretch.y += breath * 0.018 * (1.0 - run) + cos(stride * 2.0) * run * 0.045
	stretch += Vector2(combat.body_stretch)
	var tilt := face * (run * 0.13 + kneel * 0.08) + float(combat.body_tilt)
	var bob := -absf(step) * run * 3.5 - sin(float(pose.launch) * PI) * 2.0
	var offset := Vector2(combat.body_offset) + Vector2(0, bob)
	var anchor := Vector2(0, 26)
	var translation := anchor + offset - (anchor * stretch).rotated(tilt)

	# Small articulated feet sell the stride while preserving the stylus body.
	for index in range(2):
		var side := -1.0 if index == 0 else 1.0
		var phase := stride + (PI if index == 0 else 0.0)
		var foot := Vector2(side * 8 + sin(phase) * run * 10, 25 - maxf(0, cos(phase)) * run * 8)
		foot += Vector2(-face * air * 5, -air * (4 + side * 2))
		foot += Vector2(-attack_face * 4.0, -14.0 + side * 3.0) * float(combat.foot_tuck)
		var hip := Vector2(side * 7, 15 + kneel * 6)
		var knee := hip.lerp(foot, 0.5) + Vector2(-face * run * 3, 0)
		Paint.segment(canvas, hip, knee, 4.0, paint.coat, ink, paint.teal)
		Paint.segment(canvas, knee, foot, 4.5, paint.brass, ink, paint.gold)
		var toe := Vector2(face * 5, 0)
		Paint.shape(canvas, PackedVector2Array([foot + Vector2(-face*4,-2), foot + Vector2(face*3,-2), foot + toe + Vector2(0,1), foot + Vector2(-face*4,1)]), paint.shadow, ink, 1.2)
		canvas.draw_line(foot + Vector2(-face*2,-1.5), foot + toe + Vector2(-face,-1.5), Color(paint.rim,0.62), 1.1, true)

	canvas.draw_set_transform(translation, tilt, stretch)
	# The opposite arm counterbalances the stylus. Feet stay on their original
	# pivots above while these joints and the coat move only in the impression.
	if snap > 0.0 or parry > 0.0 or float(combat.hurt_strength) > 0.0:
		var shoulder := Vector2(-attack_face * 10, 2)
		var rear_elbow: Vector2 = combat.rear_elbow
		var hand: Vector2 = combat.rear_hand
		Paint.segment(canvas, shoulder, rear_elbow, 5.0, paint.coat, ink, paint.teal)
		Paint.segment(canvas, rear_elbow, hand, 4.0, paint.brass, ink, paint.gold)
	var body := PackedVector2Array([Vector2(0,-34), Vector2(8,-22), Vector2(17,2),
		Vector2(19,15), Vector2(13,21), Vector2(-3,20), Vector2(-13,22),
		Vector2(-18,14), Vector2(-15,-5), Vector2(-5,-28)])
	var flash := hurt > 0.82 or (hurt > 0.0 and int(hurt * 7.0) % 2 == 0)
	var fill: Color = paint.light if flash else paint.coat
	Paint.shape(canvas, body, fill, ink, 2.3)
	# A folded petrol coat surrounds the cream wax face. Broad painted planes
	# carry its volume; the needle-shaped outer silhouette remains recognizable.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,-31),Vector2(-15,-2),Vector2(-17,16),Vector2(-5,20),Vector2(-3,3)]), paint.shadow)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(2,-25),Vector2(13,-3),Vector2(17,13),Vector2(9,20),Vector2(4,5)]), paint.teal)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-3,3),Vector2(-6,19),Vector2(1,19),Vector2(5,9)]),paint.shadow)
	canvas.draw_polyline(PackedVector2Array([Vector2(-3,-28),Vector2(-13,-4),Vector2(-16,11)]),Color(paint.rim,0.56),1.25,true)
	canvas.draw_line(Vector2(8,18),Vector2(13,16),Color(paint.rim,0.38),1.0,true)
	var mask := PackedVector2Array([Vector2(0,-25),Vector2(10,-10),Vector2(12,4),Vector2(5,13),Vector2(-6,12),Vector2(-11,3),Vector2(-8,-11)])
	Paint.shape(canvas, mask, pale, paint.wax.lerp(ink,0.25), 0.9)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(4,-18),Vector2(10,-8),Vector2(11,4),Vector2(5,12),Vector2(3,1)]), paint.wax)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-8,-11),Vector2(-4,-18),Vector2(6,-10),Vector2(4,-4),Vector2(-6,-5)]),Color(paint.wax,0.58))
	canvas.draw_line(Vector2(-5,-12),Vector2(-8,1),Color(paint.light,0.70),1.5,true)
	canvas.draw_line(Vector2(6,6),Vector2(5,10),Color(ink,0.22),1.0,true)
	# The short copper scarf follows the body rather than the collision node.
	Paint.shape(canvas,PackedVector2Array([Vector2(-14,12),Vector2(12,12),Vector2(16,16),Vector2(2,19),Vector2(-13,17)]),paint.copper.lerp(paint.wood,0.24),ink,0.8)
	var cloth_face := attack_face if snap > 0.0 else face
	var cloth_drag := maxf(run, maxf(snap * 0.7, float(combat.hurt_strength)))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-cloth_face*9,15),Vector2(-cloth_face*(26+cloth_drag*6),11+sin(time*6)*2),Vector2(-cloth_face*19,20),Vector2(-cloth_face*8,19)]),paint.copper)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-14,15),Vector2(7,16),Vector2(2,19),Vector2(-13,17)]),Color(paint.wood,0.55))
	canvas.draw_line(Vector2(-10,13),Vector2(5,14),Color(paint.coral,0.65),1.0,true)

	# Each stroke has a different silhouette: direct jab, low crossing sweep,
	# then a planted downward accent. Captured facing survives a running turn.
	var tip: Vector2 = combat.tip
	var elbow: Vector2 = combat.elbow
	var stem := PackedVector2Array([Vector2(0, -34), elbow, tip])
	canvas.draw_polyline(stem, Color(ink, 1.0 - hood), 5.0, true)
	canvas.draw_polyline(stem, Color(paint.brass, 1.0 - hood), 3.2, true)
	canvas.draw_line(elbow + Vector2(0,-1),tip + Vector2(0,-1),Color(paint.gold,1.0-hood),1.1,true)
	canvas.draw_circle(elbow,2.4,Color(paint.gold,1.0-hood),true,-1,true)
	if snap > 0.0 or parry > 0.0:
		var point := (tip - elbow).normalized()
		canvas.draw_line(tip - point * 7.0, tip + point * 3.0, Color(paint.light, maxf(snap, parry) * (1.0 - hood)), 2.6, true)
	if parry > 0.0:
		canvas.draw_line(elbow.lerp(tip, 0.18), tip, Color(pale, parry * 0.80), 1.4, true)
	if noise > 0.03:
		canvas.draw_line(elbow, tip, Color(pink, noise * (1.0 - hood)), 2.0, true)

	# Lifting the sleeve is a short opening/closing motion, not a sprite swap.
	if hood > 0.0:
		var sleeve := PackedVector2Array([
			Vector2(-23, 22), Vector2(-12 * (1.0 - hood), lerpf(18, -44, hood)),
			Vector2(12 * (1.0 - hood), lerpf(18, -44, hood)), Vector2(23, 22),
		])
		Paint.shape(canvas,sleeve,fill.lerp(paint.shadow,hood*0.7),ink,2.0)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(3,-36*hood),Vector2(21,21),Vector2(10,20),Vector2(0,-15*hood)]),Color(paint.teal,hood*0.82))
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-4,-27*hood),Vector2(-15,21),Vector2(2,21),Vector2(2,-9*hood)]),Color(paint.shadow,hood*0.65))
		canvas.draw_polyline(PackedVector2Array([Vector2(-2,-39*hood),Vector2(-11,-10*hood),Vector2(-19,17)]),Color(paint.rim,hood*0.58),1.3,true)
		canvas.draw_line(Vector2(-17, 22), Vector2(-4, -24 * hood), Color(hood_ink, hood * 0.40), 1.5, true)
		canvas.draw_line(Vector2(17, 22), Vector2(5, -21 * hood), Color(hood_ink, hood * 0.30), 1.5, true)
		if bool(palette.get("warm_thread", false)):
			var thread := Color(0.96, 0.69, 0.32, hood)
			canvas.draw_polyline(PackedVector2Array([
				Vector2(-20, 24), Vector2(-8 * (1.0 - hood), lerpf(20, -38, hood)),
				Vector2(8 * (1.0 - hood), lerpf(20, -38, hood)), Vector2(20, 24),
			]), thread, 1.35, true)
			canvas.draw_line(Vector2(-17, 20), Vector2(16, 20), thread, 1.1, true)
	var eye_center := Vector2(face * 1.5, lerpf(-2, -12, hood) + kneel * 6)
	if hood > 0.35:
		var opening := PackedVector2Array([eye_center+Vector2(-10,-4),eye_center+Vector2(-5,-10),
			eye_center+Vector2(6,-9),eye_center+Vector2(10,-3),eye_center+Vector2(8,7),eye_center+Vector2(-7,8)])
		Paint.shape(canvas,opening,Color(pale,hood),Color(ink,hood),1.2)
		canvas.draw_colored_polygon(PackedVector2Array([eye_center+Vector2(3,-8),eye_center+Vector2(9,-3),eye_center+Vector2(7,6),eye_center+Vector2(2,7)]),Color(paint.wax,hood))
		canvas.draw_line(eye_center+Vector2(-7,-4),eye_center+Vector2(6,-5),Color(paint.shadow,hood*0.42),1.8,true)
	var blink_phase := fmod(time, 4.7)
	var blink := clampf(1.0 - absf(blink_phase - 4.43) / 0.085, 0.0, 1.0)
	var lid := maxf(blink, 0.72 if hurt > 0.1 else kneel * 0.25)
	var eye_color: Color = ink
	for side in [-1.0, 1.0]:
		var eye := eye_center + Vector2(side * lerpf(5.0, 3.2, hood), 0)
		if lid > 0.65:
			canvas.draw_line(eye + Vector2(-2.4, 0), eye + Vector2(2.4, 0), eye_color, 1.7, true)
		else:
			var eye_height := lerpf(2.2,1.7,hood)*(1.0-lid*0.45)
			Paint.shape(canvas,PackedVector2Array([eye+Vector2(-2.4,-eye_height*0.50),eye+Vector2(1.8,-eye_height*0.75),eye+Vector2(2.1,eye_height*0.55),eye+Vector2(-1.9,eye_height*0.72)]),eye_color,eye_color,0.6)
			canvas.draw_line(eye+Vector2(-0.9,-0.8),eye+Vector2(0.3,-0.7),Color(paint.light,0.64),0.8,true)
			if noise > 0.03 and hood < 0.5:
				canvas.draw_line(eye+Vector2(-2,-4),eye+Vector2(2,-3),Color(ink,noise*(1.0-hood)),1.2,true)
			if snap > 0.0 or parry > 0.0:
				canvas.draw_line(eye+Vector2(-2.5,-4.0-side*0.8),eye+Vector2(2.0,-3.3+side*0.8),Color(ink,maxf(snap,parry)*0.68),1.3,true)
	canvas.draw_line(eye_center+Vector2(-2,6),eye_center+Vector2(2,6+hurt*2),ink,1.0,true)
	canvas.draw_set_transform(Vector2.ZERO)

	# Strike and landing marks are short impressions, rooted at the actual body.
	if snap > 0.0:
		_strike_cut(canvas, combo_step, attack_face, snap, pink, bool(pose.big), contact)
	# Compact wax chips and a brass glint sit at Skip's real drawn stylus.
	# The target's separate hit impression remains owned by Main.
	var stylus_tip := translation + (tip * stretch).rotated(tilt)
	if float(combat.impact) > 0.0:
		_contact_mark(canvas, stylus_tip, attack_face, float(combat.impact), paint.gold, pale, combo_step == 3)
	if float(combat.guard) > 0.0:
		var recoil: float = combat.guard
		canvas.draw_line(stylus_tip + Vector2(-attack_face * 5.0, -4.0), stylus_tip + Vector2(attack_face * 3.0, 2.0), Color(paint.brass, recoil * 0.72), 1.6, true)
	if parry > 0.0:
		_contact_mark(canvas, stylus_tip, float(combat.parry_face), parry, pale, paint.gold, false)
	if land > 0.0 and float(pose.impact) > 0.35:
		for side in [-1.0, 1.0]:
			var puff := Vector2(side * (20 + (1.0 - land) * 21), 25 - sin(land * PI) * 5)
			canvas.draw_line(puff, puff + Vector2(side * 6, -2), Color(ink, land * 0.35), 1.5, true)
	if kneel > 0.0:
		var pulse := 0.70 + sin(time * 4.0) * 0.15
		for radius in [14.0, 23.0]:
			canvas.draw_arc(Vector2(face * 7, 22), radius + sin(time * 3.0) * 1.5, PI, TAU, 24, Color(pink, kneel * pulse * (0.6 if radius == 14 else 0.3)), 2.0, true)

static func _contact_mark(canvas: CanvasItem, center: Vector2, face: float, strength: float, brass: Color, wax: Color, heavy: bool) -> void:
	var length := (8.0 if heavy else 5.0) * strength
	canvas.draw_line(center + Vector2(-face * 2.0, 2.0), center + Vector2(face * length, -length), Color(wax, strength * 0.85), 1.8, true)
	canvas.draw_line(center + Vector2(face * 2.0, 2.0), center + Vector2(face * (length + 3.0), 4.0), Color(brass, strength * 0.72), 1.4, true)
	canvas.draw_line(center + Vector2(-face * 3.0, -2.0), center + Vector2(-face * 6.0, -length - 2.0), Color(brass, strength * 0.65), 1.2, true)

static func _strike_cut(canvas: CanvasItem, step: int, face: float, snap: float, color: Color, big: bool, contact: StringName) -> void:
	var radius := 42.0 + (1.0 - snap) * 13.0
	var start := -1.15 if step == 1 else (-2.5 if step == 2 else -1.0)
	var sweep := 1.65 if step == 1 else (3.35 if step == 2 else 1.90)
	var points := PackedVector2Array()
	for index in 30:
		var point := Vector2.from_angle(start + sweep * index / 29.0) * radius
		point.x *= -1.0 if face < 0.0 else 1.0
		points.append(point + Vector2(0, -7))
	var strength := 0.28 if contact == &"miss" else (0.55 if contact == &"guard" else 0.80)
	canvas.draw_polyline(points, Color(color, snap * strength), 2.8 if big or step == 3 else 1.8, true)
	if step == 3:
		var direction := -1.0 if face < 0.0 else 1.0
		for side in [-1.0, 1.0]:
			var mark := Vector2(direction * (radius - 3), -7 + side * 17)
			canvas.draw_line(mark, mark + Vector2(direction * 10, side * 5), Color(color, snap * strength), 1.8, true)

static func _outline(canvas: CanvasItem, points: PackedVector2Array, color: Color, time: float, amplitude: float) -> void:
	var outline := PackedVector2Array()
	var frame := floorf(time * 11.0)
	for index in range(points.size()):
		var jitter := Vector2(sin(index * 11.3 + frame * 7.1), cos(index * 9.7 + frame * 5.3)) * amplitude
		outline.append(points[index] + jitter)
	outline.append(outline[0])
	canvas.draw_polyline(outline, color, 2.5, true)
