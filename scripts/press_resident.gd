extends RefCounted
const Paint := preload("res://scripts/figure_paint.gd")
## Two familiar faces, cut from the same stock as their rooms. All attention,
## conversation and rhythm arrive as pose values; the engraving owns no state.

static func draw(canvas: CanvasItem, kind: StringName, pose: Dictionary, ink: Color, stock: Color) -> void:
	var clean := {
		"clock": fposmod(maxf(_number(pose, "clock"), 0.0), 86400.0),
		"face": -1.0 if _number(pose, "face", 1.0) < 0.0 else 1.0,
		"near": bool(pose.get("near", false)),
		"talking": clampf(_number(pose, "talking"), 0.0, 1.0),
		"startle": clampf(_number(pose, "startle"), 0.0, 1.0),
		"greeting": clampf(_number(pose, "greeting"), 0.0, 1.0),
		"beat": clampi(int(_number(pose, "beat")), 0, 3),
		"beat_phase": clampf(_number(pose, "beat_phase"), 0.0, 1.0),
		"opened": bool(pose.get("opened", false)),
	}
	match kind:
		&"bootlegger":
			_bootlegger(canvas, clean, ink, stock)
		&"tick":
			_tick(canvas, clean, ink, stock)

static func _number(pose: Dictionary, key: String, fallback := 0.0) -> float:
	var value: Variant = pose.get(key, fallback)
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return fallback
	var number := float(value)
	return number if is_finite(number) else fallback

static func _bootlegger(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var paint := Paint.palette(ink,stock)
	ink = paint.edge
	var clock: float = pose.clock
	var face: float = pose.face
	var talking: float = pose.talking
	var greeting: float = pose.greeting
	var startle: float = pose.startle
	var breath := sin(clock * 1.9)
	var cycle := fposmod(clock, 8.0) / 8.0
	# Thumb through the waist stock, lift a tape to the light, then tuck it away.
	var inspect := smoothstep(0.24, 0.43, cycle) * (1.0 - smoothstep(0.69, 0.91, cycle))
	inspect *= 1.0 - talking * 0.7
	var rummage := sin(clock * 7.0) * (1.0 - inspect) * (1.0 - greeting)
	var fold: Color = paint.coat
	var apron: Color = paint.wood
	var edge: Color = paint.cream
	var label: Color = paint.cream
	var coat_shift := Vector2(face * (talking * 1.5 - startle * 3.0), breath * 1.2 + startle * 2.0)
	var head := Vector2(face * (3.0 + (2.0 if pose.near else 0.0)) - face * startle * 5.0, -111.0 + breath * 1.5 + sin(clock * 3.1) * talking - startle * 3.0)
	# Long folded coat, planted boots and the contrasting work apron.
	canvas.draw_line(Vector2(-17.0, 25.0), Vector2(-3.0, 25.0), ink, 5.0, true)
	canvas.draw_line(Vector2(9.0, 25.0), Vector2(24.0, 25.0), ink, 5.0, true)
	canvas.draw_set_transform(coat_shift)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-24.0, -95.0), Vector2(18.0, -98.0), Vector2(33.0, -67.0),
		Vector2(29.0, 18.0), Vector2(5.0, 22.0), Vector2(-1.0, 5.0),
		Vector2(-10.0, 21.0), Vector2(-31.0, 17.0), Vector2(-35.0, -57.0),
	]),paint.shadow)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-22.0, -90.0), Vector2(-8.0, -81.0), Vector2(-5.0, 11.0),
		Vector2(-23.0, 15.0), Vector2(-29.0, -54.0),
	]), fold)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-9.0, -87.0), Vector2(16.0, -87.0), Vector2(24.0, -7.0),
		Vector2(-14.0, -3.0), Vector2(-18.0, -54.0),
	]),paint.copper)
	Paint.shape(canvas,PackedVector2Array([Vector2(-25,-91),Vector2(-10,-81),Vector2(-3,-52),Vector2(-22,-67)]),paint.teal,ink,1.2)
	Paint.shape(canvas,PackedVector2Array([Vector2(18,-95),Vector2(8,-82),Vector2(8,-54),Vector2(28,-72)]),paint.coat,ink,1.2)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-6,-79),Vector2(8,-78),Vector2(14,-39),Vector2(-4,-41)]),paint.wood)
	Paint.hatch(canvas,Vector2(-20,11),16,45,Color(paint.teal,0.45),6)
	Paint.hatch(canvas,Vector2(18,-9),18,33,Color(paint.coral,0.32),5)
	for y in [-70.0,-57.0]: Paint.bolt(canvas,Vector2(0,y),2.6,paint.brass,ink,paint.light)
	canvas.draw_line(Vector2(-9.0, -87.0), Vector2(-17.0, -95.0), edge, 2.0, true)
	canvas.draw_line(Vector2(15.0, -87.0), Vector2(13.0, -97.0), edge, 2.0, true)
	canvas.draw_line(Vector2(22.0, -71.0), Vector2(28.0, 11.0), Color(edge, 0.35), 1.2, true)
	canvas.draw_line(Vector2(-14.0, -47.0), Vector2(21.0, -50.0), ink, 2.0, true)
	# A belt of tape reels and torn, anonymous paper labels.
	canvas.draw_rect(Rect2(Vector2(-25.0,-35.0),Vector2(52.0,18.0)),paint.wood)
	canvas.draw_line(Vector2(-25,-34),Vector2(26,-34),paint.brass,2.0,true)
	for index in range(3):
		var reel := Vector2(-16.0 + index * 17.0, -27.0)
		Paint.disc(canvas,reel,6.2,paint.brass,ink,paint.gold)
		canvas.draw_arc(reel, 3.5, clock * 0.25 + index, clock * 0.25 + index + PI * 1.35, 18, ink, 1.1, true)
		canvas.draw_circle(reel, 1.2, ink, true, -1.0, true)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-24.0, -15.0), Vector2(-7.0, -17.0), Vector2(-9.0, -3.0), Vector2(-22.0, -2.0)]), label)
	canvas.draw_line(Vector2(-20.0, -11.0), Vector2(-11.0, -12.0), fold, 1.5, true)
	canvas.draw_line(Vector2(-18.0, -7.0), Vector2(-12.0, -8.0), fold, 1.0, true)
	canvas.draw_set_transform(Vector2.ZERO)
	# The brim is never a static sticker: its tilt follows the neck and startle.
	canvas.draw_set_transform(head, face * (-0.085 + talking * 0.025 + startle * 0.10))
	Paint.shape(canvas,PackedVector2Array([Vector2(-16,-14),Vector2(13,-14),Vector2(17,8),Vector2(5,19),Vector2(-15,12)]),paint.cream,ink,1.8)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(7,-12),Vector2(14,-9),Vector2(16,8),Vector2(5,18),Vector2(4,1)]),paint.wax)
	Paint.shape(canvas,PackedVector2Array([Vector2(-23,-16),Vector2(-15,-30),Vector2(9,-28),Vector2(23,-15)]),paint.coat,ink,2.0)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-20,-18),Vector2(-13,-24),Vector2(17,-22),Vector2(20,-16)]),paint.copper)
	Paint.shape(canvas,PackedVector2Array([Vector2(-34,-15),Vector2(-21,-19),Vector2(23,-18),Vector2(35,-13),Vector2(17,-10),Vector2(-26,-10)]),paint.shadow,ink,1.5)
	canvas.draw_line(Vector2(-28,-14),Vector2(24,-14),paint.teal,2.1,true)
	for side in [-1.0,1.0]:
		var eye := Vector2(face*3+side*5.5,-2-startle*1.2)
		canvas.draw_circle(eye,2.6,ink,true,-1,true)
		canvas.draw_circle(eye+Vector2(-0.6,-0.7),0.7,paint.light,true,-1,true)
	canvas.draw_line(Vector2(-2,9),Vector2(6,8+sin(clock*12)*talking*1.6),ink,1.5,true)
	canvas.draw_line(Vector2(-10,3),Vector2(-5,4),Color(paint.copper,0.6),1.6,true)
	canvas.draw_set_transform(Vector2.ZERO)
	var tape_hand := Vector2(face * (20.0 + inspect * 5.0), -42.0 - inspect * 38.0 + rummage * 2.0)
	var greeting_hand := Vector2(-face * (40.0 + greeting * 14.0), -45.0 - greeting * 43.0 + sin(clock * 4.5) * talking * 9.0)
	var near_shoulder := Vector2(face * 25.0, -82.0) + coat_shift
	var far_shoulder := Vector2(-face * 24.0, -82.0) + coat_shift
	_arm(canvas,far_shoulder,Vector2(-face*42,-56),greeting_hand,paint.coat,edge,12.0)
	_arm(canvas,near_shoulder,Vector2(face*40,-56-inspect*4),tape_hand,paint.teal,edge,12.0)
	canvas.draw_line(greeting_hand + Vector2(-4.0, 0.0), greeting_hand + Vector2(4.0, -2.0), edge, 2.5, true)
	canvas.draw_set_transform(tape_hand, face * (-0.16 + inspect * 0.36 + sin(clock * 3.4) * 0.035))
	_cassette(canvas, ink, label)
	canvas.draw_set_transform(Vector2.ZERO)
	if pose.opened:
		# One loosened coat seam is the only trace of having unfolded from the wall.
		canvas.draw_line(Vector2(-34.0, 8.0), Vector2(-40.0, 13.0), Color(ink, 0.65), 1.5, true)

static func _cassette(canvas: CanvasItem, ink: Color, paper: Color) -> void:
	canvas.draw_rect(Rect2(Vector2(-15.0, -8.0), Vector2(30.0, 17.0)), ink)
	canvas.draw_rect(Rect2(Vector2(-12.0, -5.0), Vector2(24.0, 10.0)), paper)
	for x in [-6.0, 6.0]:
		canvas.draw_circle(Vector2(x, 0.0), 3.3, ink, true, -1.0, true)
		canvas.draw_circle(Vector2(x, 0.0), 1.1, paper, true, -1.0, true)
	canvas.draw_line(Vector2(-5.0, 6.0), Vector2(5.0, 6.0), paper, 1.0, true)

static func _tick(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var paint := Paint.palette(ink,stock)
	ink = paint.edge
	var clock: float = pose.clock
	var face: float = pose.face
	var beat: int = pose.beat
	var beat_phase: float = pose.beat_phase
	var talking: float = pose.talking
	var greeting: float = pose.greeting
	var startle: float = pose.startle
	var paper: Color = paint.cream
	var shell: Color = paint.wood
	var warm: Color = paint.brass
	var on_beat := sin(minf(beat_phase * 4.0, 1.0) * PI) if beat < 3 else 0.0
	var shift := Vector2(face * (1.4 if pose.near else 0.0) - face * startle * 3.0, -on_beat * 2.6 + sin(clock * 2.2) * 0.7)
	var shuffle := sin(clock * 1.8) * 1.3
	canvas.draw_line(Vector2(-13.0 + shuffle, 24.0), Vector2(-2.0 + shuffle, 25.0), ink, 4.0, true)
	canvas.draw_line(Vector2(6.0 - shuffle, 25.0), Vector2(17.0 - shuffle, 24.0), ink, 4.0, true)
	canvas.draw_set_transform(shift)
	# A small wooden metronome case, its triangular silhouette distinct from wax.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-26.0, 18.0), Vector2(-13.0, -71.0), Vector2(13.0, -71.0), Vector2(26.0, 18.0)]), ink)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-20.0, 12.0), Vector2(-9.0, -64.0), Vector2(9.0, -64.0), Vector2(20.0, 12.0)]), shell)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-20,12),Vector2(-9,-64),Vector2(-4,-58),Vector2(-11,9)]),paint.copper)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(9,-64),Vector2(20,12),Vector2(12,9),Vector2(5,-58)]),paint.shadow)
	Paint.shape(canvas,PackedVector2Array([Vector2(-10,-52),Vector2(9,-52),Vector2(13,4),Vector2(-13,4)]),paint.coat,paint.brass,1.7)
	Paint.hatch(canvas,Vector2(-15,9),7,53,Color(paint.gold,0.22),4)
	canvas.draw_rect(Rect2(-20,10,40,7),paint.brass)
	Paint.bolt(canvas,Vector2(-17,13),2.5,paint.gold,ink,paper)
	Paint.bolt(canvas,Vector2(17,13),2.5,paint.gold,ink,paper)
	canvas.draw_line(Vector2(-21.0, 12.0), Vector2(21.0, 12.0), paper, 2.0, true)
	canvas.draw_line(Vector2(-9.0, -63.0), Vector2(-19.0, 6.0), Color(paper, 0.22), 1.2, true)
	for mark in range(5):
		var mark_y := -53.0 + mark * 10.0
		canvas.draw_line(Vector2(-3.0, mark_y), Vector2(3.0, mark_y), Color(paper, 0.46), 1.0, true)
	# Three clicks, then a held breath: the fourth interval has no tap or mark.
	var pendulum_angle := 0.0
	if beat < 3:
		pendulum_angle = lerpf(-0.42 if beat % 2 == 0 else 0.42, 0.42 if beat % 2 == 0 else -0.42, smoothstep(0.0, 1.0, beat_phase))
	else:
		pendulum_angle = 0.42 * (1.0 - smoothstep(0.0, 0.4, beat_phase))
	var pivot := Vector2(0.0, 1.0)
	var tip := pivot + Vector2(0.0, -60.0).rotated(pendulum_angle)
	Paint.segment(canvas,pivot,tip,3.5,paint.brass,ink,paint.gold)
	var weight := pivot.lerp(tip, 0.64)
	canvas.draw_set_transform(shift + weight, pendulum_angle)
	Paint.shape(canvas,PackedVector2Array([Vector2(-7,-6),Vector2(5,-6),Vector2(7,-3),Vector2(6,5),Vector2(-6,5)]),paint.brass,ink,1.2)
	canvas.draw_line(Vector2(-4.0, -3.0), Vector2(4.0, -3.0), paper, 1.1, true)
	canvas.draw_set_transform(shift)
	canvas.draw_circle(pivot, 4.0, ink, true, -1.0, true)
	canvas.draw_circle(pivot, 1.7, paper, true, -1.0, true)
	# Tiny attentive eyes sit above the mechanism; nods do not alter the count.
	var head := Vector2(face * 2.0, -81.0 + on_beat * 1.8 - startle * 4.0)
	canvas.draw_set_transform(shift + head, face * (talking * sin(clock * 4.0) * 0.09 - startle * 0.12))
	Paint.shape(canvas,PackedVector2Array([Vector2(-12,-10),Vector2(10,-12),Vector2(14,6),Vector2(-11,8)]),paint.cream,ink,1.6)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-13,-9),Vector2(-7,-16),Vector2(12,-12),Vector2(15,-7)]),paint.coat)
	canvas.draw_line(Vector2(-12,-9),Vector2(12,-8),paint.brass,2.2,true)
	for side in [-1.0,1.0]:
		var eye := Vector2(face*2+side*4,-1)
		canvas.draw_circle(eye,2.1,ink,true,-1,true)
		canvas.draw_circle(eye+Vector2(-0.6,-0.7),0.6,paint.light,true,-1,true)
	canvas.draw_line(Vector2(-1,5),Vector2(5,5-talking),ink,1.0,true)
	canvas.draw_set_transform(Vector2.ZERO)
	var raised_hand := shift + Vector2(face * (35.0 + talking * 3.0), -27.0 - greeting * 24.0 - on_beat * 4.0)
	var resting_hand := shift + Vector2(-face * 31.0, -8.0 + sin(clock * 3.0) * 2.0)
	_arm(canvas, shift + Vector2(face * 17.0, -34.0), shift + Vector2(face * 29.0, -21.0), raised_hand, ink, paper, 3.5)
	_arm(canvas, shift + Vector2(-face * 18.0, -30.0), shift + Vector2(-face * 29.0, -18.0), resting_hand, ink, paper, 3.5)
	if talking > 0.02 or pose.near:
		for mark in range(3):
			var mark_color := warm if mark <= beat and beat < 3 else Color(ink, 0.25)
			var point := shift + Vector2(-10.0 + mark * 10.0, -111.0)
			canvas.draw_line(point, point + Vector2(0.0, 5.0), mark_color, 2.5, true)

static func _arm(canvas: CanvasItem, shoulder: Vector2, elbow: Vector2, hand: Vector2, ink: Color, paper: Color, width: float) -> void:
	# Overlapping rounded segments keep folded elbows clean even when an
	# inspecting hand comes back toward its shoulder; a miter would grow a spike.
	Paint.segment(canvas,shoulder,elbow,width,ink,Color("13292e"),Color("aab995"))
	Paint.segment(canvas,elbow,hand,width*0.82,ink,Color("13292e"),Color("aab995"))
	Paint.disc(canvas,hand,maxf(width*0.43,3.0),paper,Color("13292e"),Color("fff0ce"))
