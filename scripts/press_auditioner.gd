extends RefCounted
const Paint := preload("res://scripts/figure_paint.gd")
## A little voice printed in articulated pieces. Pose values are supplied by
## the actor; this engraving never moves its origin or reads the scene tree.

static func draw_auditioner(canvas: CanvasItem, pose: Dictionary, ink: Color, body: Color, pale: Color, accent: Color, grey: Color, warm: Color) -> void:
	var paint := Paint.palette(ink,pale)
	ink = paint.edge
	body = paint.coat
	pale = paint.cream
	accent = paint.coral
	grey = paint.brass
	warm = paint.gold
	var phase: String = pose.phase
	var face: float = pose.face
	var clock: float = pose.clock
	var breath := sin(clock * 2.8)
	var stride: float = pose.stride
	var resident: Dictionary = pose.get("resident", {})
	var walking := phase == "pursue" or phase == "reach" or bool(resident.get("walking", false))
	var step := sin(stride) if walking else 0.0
	var lift := absf(cos(stride)) * 1.8 if walking else breath * 1.4
	var recoil: float = pose.recoil
	var reach: float = pose.reach if phase == "reach" else 0.0
	var anticipation := sin(reach * PI)
	var extension := reach * reach
	var center := Vector2(face * (extension * 8.0 - anticipation * 3.0 - recoil * 8.0), -26.0 - lift)
	center += Vector2(pose.jitter)
	var rotation := face * (extension * 0.15 - recoil * 0.23)
	if phase == "stagger":
		rotation += -face * cos(float(pose.state_time) * 22.0) * exp(-float(pose.state_time) * 5.0) * 0.24
	if phase == "recover":
		center.x += face * 7.0 * (1.0 - float(pose.recover))
		rotation += face * 0.13 * (1.0 - float(pose.recover))
	if phase == "down":
		_burst(canvas, Vector2(0.0, -26.0), float(pose.burst), ink, pale, accent)
		return
	var alpha := 1.0
	var heard := phase == "freed"
	if heard:
		var leave: float = pose.leave
		alpha = 1.0 if pose.held else pow(1.0 - leave, 1.1)
		center = Vector2(sin(clock * 1.9) * 1.1, -28.0 - breath * 1.8 - (0.0 if pose.held else leave * 18.0))
		rotation = sin(clock * 1.9) * 0.025
		body = body.lerp(warm, 0.35)
		canvas.draw_circle(center, 25.0 + breath * 1.0, Color(warm, 0.11 * alpha), true, -1.0, true)
		canvas.draw_arc(center, 29.0 + (0.0 if pose.held else leave * 16.0), -PI * 0.9, PI * 0.9, 42, Color(warm, 0.75 * alpha), 2.0, true)
	var inked := Color(ink, alpha)
	var edge := Color(pale, alpha)
	var limb_color := Color(warm if heard else (accent if phase == "reach" else grey), alpha)
	# Each foot lifts on its own half of the stride. Hips follow the breathing
	# body while planted feet stay on the baseline, so the figure has weight.
	var left_foot := Vector2(-10.0 + step * 7.0, 8.0 - maxf(step, 0.0) * 5.0)
	var right_foot := Vector2(10.0 - step * 7.0, 8.0 - maxf(-step, 0.0) * 5.0)
	if heard and not walking:
		left_foot = Vector2(-9.0, 8.0)
		right_foot = Vector2(9.0, 8.0)
	_limb(canvas, center + Vector2(-7.0, 10.0), left_foot, -4.0 - step * 2.0, Color(paint.brass,alpha), 5.0)
	_limb(canvas, center + Vector2(7.0, 10.0), right_foot, 4.0 + step * 2.0, Color(paint.brass,alpha), 5.0)
	canvas.draw_line(left_foot + Vector2(-4.0, 0.0), left_foot + Vector2(5.0, 0.0), inked, 4.5, true)
	canvas.draw_line(right_foot + Vector2(-4.0, 0.0), right_foot + Vector2(5.0, 0.0), inked, 4.5, true)
	# Squash the soft wax on impact. Only the printing transform changes.
	var squash := Vector2(1.0 + recoil * 0.14 - breath * 0.016, 1.0 - recoil * 0.10 + breath * 0.025)
	canvas.draw_set_transform(center, rotation, squash)
	Paint.disc(canvas,Vector2.ZERO,22.0,body,ink,paint.teal,alpha)
	# The wax face is nestled in an asymmetric hood and a heavy copper wrap.
	Paint.disc(canvas,Vector2(face*2,-3),15.5,pale,paint.wax,paint.light,alpha)
	Paint.shape(canvas,PackedVector2Array([Vector2(-21,-10),Vector2(-12,-23),Vector2(7,-23),Vector2(16,-13),Vector2(-6,-17),Vector2(-16,-5)]),Color(paint.teal,alpha),inked,1.2)
	Paint.shape(canvas,PackedVector2Array([Vector2(-22,8),Vector2(-8,11),Vector2(16,7),Vector2(23,14),Vector2(9,24),Vector2(-14,21)]),Color(paint.copper,alpha),inked,1.3)
	canvas.draw_line(Vector2(-15,12),Vector2(15,12),Color(paint.coral,alpha*0.8),2.1,true)
	Paint.hatch(canvas,Vector2(-4,21),22,5,Color(paint.wood,alpha*0.48),5)
	# The eye narrows through the recoil, then opens as the voice settles.
	for side in [-1.0,1.0]:
		var eye := Vector2(face*3+side*4.8,-4)
		if heard:
			canvas.draw_arc(eye+Vector2(0,-1),2.8,0.15,PI-0.15,12,inked,1.7,true)
		elif recoil > 0.35:
			canvas.draw_line(eye+Vector2(-2,-1),eye+Vector2(2,1),inked,1.8,true)
		else:
			canvas.draw_circle(eye,2.6,inked,true,-1,true)
			canvas.draw_circle(eye+Vector2(-0.6,-0.7),0.7,edge,true,-1,true)
	canvas.draw_arc(Vector2(face*3,1),3.6,0.1,PI-0.1,13,inked,1.1,true)
	canvas.draw_set_transform(Vector2.ZERO)
	var far_hand := center + Vector2(face * (13.0 + extension * 22.0), 13.0 + step * 3.0)
	var near_hand := center + Vector2(face * (18.0 + extension * 48.0 - anticipation * 10.0), -7.0 - extension * 13.0 + breath)
	if heard:
		near_hand = center + Vector2(-29.0, -8.0 + breath * 2.0)
		far_hand = center + Vector2(29.0, -8.0 - breath * 2.0)
		if not resident.is_empty():
			# Freed Addie offers a small touch, never a reaching attack. One
			# hand pats the hood while the other quietly holds her own sleeve.
			var pat := clampf(float(resident.get("pat", 0.0)), 0.0, 1.0)
			near_hand = center + Vector2(face * 24.0, 6.0 + step * 2.0)
			far_hand = center + Vector2(-face * 16.0, 13.0 - step * 2.0)
			var hand_target: Vector2 = resident.get("hand_target", near_hand)
			hand_target.y -= (0.5 + 0.5 * sin(float(resident.get("clock", clock)) * 5.0)) * 3.0
			near_hand = near_hand.lerp(hand_target, pat)
	elif phase == "stagger":
		near_hand = center + Vector2(-face * (27.0 + recoil * 13.0), -18.0)
		far_hand = center + Vector2(-face * 20.0, 15.0)
	_limb(canvas, center + Vector2(-face * 9.0, 5.0), far_hand, 8.0, Color(paint.coat,alpha), 6.5)
	_limb(canvas, center + Vector2(face * 10.0, -4.0), near_hand, -6.0 - anticipation * 5.0, Color(paint.teal,alpha), 7.0)
	canvas.draw_circle(near_hand,4.6,edge,true,-1,true)
	canvas.draw_circle(far_hand,3.8,edge,true,-1,true)
	canvas.draw_line(near_hand + Vector2(0.0, -3.0), near_hand + Vector2(face * 4.0, 3.0), limb_color, 2.0, true)
	if heard:
		return
	if float(pose.resonance) > 0.01:
		canvas.draw_arc(center, 27.0, -PI / 2.0, -PI / 2.0 + TAU * float(pose.resonance), 36, accent, 4.0, true)
	if float(pose.listening) > 0.01:
		canvas.draw_arc(center, 34.0 + breath * 0.8, -PI / 2.0, -PI / 2.0 + TAU * float(pose.listening), 36, Color(warm, 0.9), 3.0, true)
	for index in int(pose.hp_total):
		var pip := Vector2(-((int(pose.hp_total) - 1) * 9.0) * 0.5 + index * 9.0, 22.0)
		canvas.draw_line(pip + Vector2(0.0, -5.0), pip + Vector2(0.0, 5.0), ink, 5.0, true)
		canvas.draw_line(pip + Vector2(0.0, -4.0), pip + Vector2(0.0, 4.0), pale if index < int(ceil(float(pose.hp))) else Color(grey, 0.4), 3.0, true)

static func _limb(canvas: CanvasItem, start: Vector2, end: Vector2, bend: float, color: Color, width: float) -> void:
	var joint := start.lerp(end, 0.54) + Vector2(bend, absf(bend) * 0.3)
	Paint.segment(canvas,start,joint,width,color,Color("13292e",color.a),Color("a3b596",color.a))
	Paint.segment(canvas,joint,end,width*0.82,color,Color("13292e",color.a),Color("a3b596",color.a))

static func _burst(canvas: CanvasItem, center: Vector2, progress: float, ink: Color, pale: Color, accent: Color) -> void:
	var alpha := 1.0 - progress
	canvas.draw_arc(center, 27.0 + progress * 43.0, 0.0, TAU, 40, Color(accent, alpha * 0.8), 2.5, true)
	for index in range(7):
		var angle := TAU * float(index) / 7.0 + 0.3
		var direction := Vector2.from_angle(angle)
		var shard_center := center + direction * (12.0 + progress * 48.0) + Vector2(0.0, progress * progress * 20.0)
		canvas.draw_set_transform(shard_center, angle + progress * (1.4 if index % 2 == 0 else -1.8))
		var shard := PackedVector2Array([Vector2(-8.0, -4.0), Vector2(7.0, -6.0), Vector2(3.0, 8.0)])
		canvas.draw_colored_polygon(shard, Color(ink, alpha))
		canvas.draw_line(Vector2(-8.0, -4.0), Vector2(7.0, -6.0), Color(pale, alpha), 1.5, true)
	canvas.draw_set_transform(Vector2.ZERO)
