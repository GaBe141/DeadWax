extends RefCounted
const Paint := preload("res://scripts/figure_paint.gd")
## The plaza Hound is a little record on four feet. The print receives a pose
## and palette only: no player, input, progression or campaign access lives here.

static func draw(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var paint := Paint.palette(ink,stock)
	ink = paint.edge
	var phase: String = pose.phase
	var clock: float = pose.clock
	var gait: float = pose.gait
	var stride: float = pose.speed
	var sit: float = pose.sit
	var wag: float = pose.wag
	var pale: Color = paint.cream
	var faded: Color = paint.coat
	var warm: Color = paint.brass
	var breath := sin(clock * 2.8) * 1.2
	var bob := -absf(sin(gait)) * stride * 2.5
	var startle := 0.0
	if phase == "startled":
		startle = sin(clampf(float(pose.time) / 0.3, 0.0, 1.0) * PI)
		bob -= startle * 5.0
	var body := Vector2(-4.0 - sit * 8.0, -8.0 + breath + bob + sit * 4.0)
	var sniff := sin(clock * 7.0) * 2.0 if phase == "notice" else 0.0
	var nuzzle := sin(clock * 3.5) * 2.6 * float(pose.pet)
	var head := body + Vector2(34.0 + sniff + nuzzle, -22.0 - sit * 4.0)
	head.y -= startle * 5.0
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(pose.face), 1.0))
	# The rear pair leads the gait by half a cycle; front legs carry the sit.
	_leg(canvas, body + Vector2(-19, 8), -24.0, gait + PI, stride, sit, faded)
	_leg(canvas, body + Vector2(15, 8), 23.0, gait, stride, 0.0, faded)
	var tail_root := body + Vector2(-23, -2)
	var wag_angle := sin(clock * (5.0 + wag * 11.0)) * (0.12 + wag * 0.40)
	var tail_tip := tail_root + Vector2(-38, -14).rotated(wag_angle)
	if phase == "startled":
		tail_tip = tail_root + Vector2(-24, 13)
	var tail_bend := tail_root.lerp(tail_tip,0.55)+Vector2(0,-7)
	Paint.segment(canvas,tail_root,tail_bend,7.5,paint.coat,ink,paint.teal)
	Paint.segment(canvas,tail_bend,tail_tip,4.5,paint.copper,ink,paint.coral)
	Paint.disc(canvas,body+Vector2(-13,14),12.0*sit+2.0,paint.coat,ink,paint.teal)
	# Soft shoulder/haunch shapes carry a recessed record-rib saddle, rather
	# than making the entire animal a single flat wheel.
	Paint.shape(canvas,PackedVector2Array([body+Vector2(-28,-8),body+Vector2(-17,-24),body+Vector2(10,-25),body+Vector2(25,-15),body+Vector2(32,2),body+Vector2(23,18),body+Vector2(-17,20),body+Vector2(-31,7)]),paint.coat,ink,2.0)
	canvas.draw_colored_polygon(PackedVector2Array([body+Vector2(-22,-15),body+Vector2(-14,-24),body+Vector2(11,-22),body+Vector2(23,-9),body+Vector2(3,-14)]),paint.teal)
	Paint.disc(canvas,body,19.5,paint.shadow,paint.brass,paint.teal)
	for radius in [15.0,10.0]:
		canvas.draw_arc(body,radius,-2.8,2.8,34,Color(paint.brass,0.55),1.6,true)
	Paint.disc(canvas,body,5.5,warm,ink,paint.gold)
	Paint.shape(canvas,PackedVector2Array([body+Vector2(20,-11),body+Vector2(30,-12),body+Vector2(35,2),body+Vector2(27,16),body+Vector2(21,10)]),pale,paint.wax,1.0)
	Paint.hatch(canvas,body+Vector2(-19,12),12,8,Color(paint.teal,0.65),4)
	_leg(canvas, body + Vector2(-14, 11), -15.0, gait, stride, sit, paint.coat)
	_leg(canvas, body + Vector2(19, 9), 30.0, gait + PI, stride, 0.0, paint.coat)
	# Folded paper ears, a sloped muzzle, and a small needle for a nose.
	var ear_lift := 8.0 * startle + (4.0 if phase == "notice" else 0.0)
	var ear_swing := sin(clock * 3.0 - 0.8) * 2.0 + stride * sin(gait - 0.5) * 3.0
	Paint.shape(canvas,PackedVector2Array([
		head + Vector2(-14, -4), head + Vector2(-24 + ear_swing, -22 - ear_lift), head + Vector2(-4, -8),
	]),paint.coat,ink,1.5)
	Paint.shape(canvas,PackedVector2Array([
		head + Vector2(-13, 5), head + Vector2(-10, -14), head + Vector2(7, -11),
		head + Vector2(22, 2), head + Vector2(9, 10),
	]),pale,ink,1.7)
	canvas.draw_colored_polygon(PackedVector2Array([head+Vector2(7,-9),head+Vector2(21,2),head+Vector2(9,9),head+Vector2(4,3)]),paint.wax)
	canvas.draw_polyline(PackedVector2Array([
		head + Vector2(-13, 5), head + Vector2(-10, -14), head + Vector2(7, -11), head + Vector2(22, 2),
	]),paint.light,1.8,true)
	Paint.segment(canvas,head+Vector2(21,2),head+Vector2(29,1),3.5,paint.brass,ink,paint.gold)
	Paint.shape(canvas,PackedVector2Array([head+Vector2(-11,-13),head+Vector2(-4,-9),head+Vector2(-6+ear_swing,10),head+Vector2(-13+ear_swing,14),head+Vector2(-17,0)]),paint.teal,ink,1.5)
	canvas.draw_line(head+Vector2(-13,-5),head+Vector2(-11+ear_swing,7),paint.coat,2.3,true)
	Paint.segment(canvas,head+Vector2(-10,10),head+Vector2(7,13),5.0,paint.copper,ink,paint.coral)
	Paint.bolt(canvas,head+Vector2(0,18),3.0,paint.brass,ink,paint.light)
	if phase == "pet":
		canvas.draw_arc(head + Vector2(6, -3), 3.4, PI, TAU, 10, ink, 1.7, true)
	else:
		canvas.draw_circle(head + Vector2(6, -3), 2.7 + startle * 0.6, ink, true, -1, true)
		canvas.draw_circle(head+Vector2(5,-4),0.9,paint.light,true,-1,true)
	canvas.draw_set_transform(Vector2.ZERO)

static func _leg(canvas: CanvasItem, hip: Vector2, stance_x: float, gait: float, stride: float, sit: float, color: Color) -> void:
	var swing := sin(gait)
	var foot := Vector2(stance_x + swing * stride * 8.0, 26.0 - maxf(swing, 0.0) * stride * 7.0)
	foot.x = lerpf(foot.x, stance_x - 9.0, sit)
	var knee := hip.lerp(foot, 0.56) + Vector2(-4.0 - sit * 6.0, 0)
	Paint.segment(canvas,hip,knee,5.2,color,Color("13292e"),Color("487a78"))
	Paint.segment(canvas,knee,foot,4.3,Color("b48c4e"),Color("13292e"),Color("e5bd70"))
	canvas.draw_line(foot+Vector2(-4,0),foot+Vector2(5,0),Color("13292e"),4.0,true)
