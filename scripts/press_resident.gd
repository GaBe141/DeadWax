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
		&"matron":
			_matron(canvas, clean, ink, stock)
		&"typesetter":
			_typesetter(canvas, clean, ink, stock)

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
	]),paint.copper.lerp(paint.wood, 0.30))
	# Long, broad folds read at walking distance; the hem keeps its old outline.
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(14, -84), Vector2(27, -67), Vector2(25, 12), Vector2(7, 17), Vector2(3, -22),
	]), paint.coat.lerp(paint.shadow, 0.62))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-27, -52), Vector2(-14, -39), Vector2(-13, 14), Vector2(-24, 12),
	]), paint.coat.lerp(paint.shadow, 0.38))
	Paint.shape(canvas,PackedVector2Array([Vector2(-25,-91),Vector2(-10,-81),Vector2(-3,-52),Vector2(-22,-67)]),paint.teal,ink,1.2)
	Paint.shape(canvas,PackedVector2Array([Vector2(18,-95),Vector2(8,-82),Vector2(8,-54),Vector2(28,-72)]),paint.coat,ink,1.2)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-6,-79),Vector2(8,-78),Vector2(14,-39),Vector2(-4,-41)]),paint.wood)
	Paint.hatch(canvas,Vector2(-20,11),12,30,Color(paint.teal,0.28),3)
	Paint.hatch(canvas,Vector2(18,-9),10,22,Color(paint.copper,0.24),2)
	for y in [-70.0,-57.0]: Paint.bolt(canvas,Vector2(0,y),2.6,paint.brass,ink,paint.light)
	canvas.draw_line(Vector2(-9.0, -87.0), Vector2(-17.0, -95.0), edge.lerp(fold, 0.40), 1.8, true)
	canvas.draw_line(Vector2(15.0, -87.0), Vector2(13.0, -97.0), edge.lerp(fold, 0.40), 1.8, true)
	canvas.draw_line(Vector2(22.0, -71.0), Vector2(28.0, 11.0), Color(edge, 0.22), 1.2, true)
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
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(5,-12),Vector2(14,-9),Vector2(16,8),Vector2(5,18),Vector2(1,7)]),paint.wax.lerp(paint.wood, 0.20))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-15,-12),Vector2(13,-12),Vector2(13,-3),Vector2(-13,-2)]),paint.wax.lerp(paint.shadow, 0.34))
	Paint.shape(canvas,PackedVector2Array([Vector2(-23,-16),Vector2(-15,-30),Vector2(9,-28),Vector2(23,-15)]),paint.coat,ink,2.0)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-20,-18),Vector2(-13,-24),Vector2(17,-22),Vector2(20,-16)]),paint.copper)
	Paint.shape(canvas,PackedVector2Array([Vector2(-34,-15),Vector2(-21,-19),Vector2(23,-18),Vector2(35,-13),Vector2(17,-10),Vector2(-26,-10)]),paint.shadow,ink,1.5)
	canvas.draw_line(Vector2(-28,-14),Vector2(24,-14),paint.teal.lerp(paint.coat, 0.30),1.7,true)
	for side in [-1.0,1.0]:
		var eye := Vector2(face*3+side*5.5,-2-startle*1.2)
		canvas.draw_line(eye + Vector2(-2.1, -0.5), eye + Vector2(2.1, -0.5), ink, 1.7, true)
		canvas.draw_line(eye + Vector2(-2.4, -2.2), eye + Vector2(2.0, -1.7), Color(paint.wood, 0.60), 1.2, true)
	canvas.draw_line(Vector2(-2,9),Vector2(6,8+sin(clock*12)*talking*1.6),ink,1.5,true)
	canvas.draw_line(Vector2(-10,3),Vector2(-5,4),Color(paint.copper,0.6),1.6,true)
	canvas.draw_set_transform(Vector2.ZERO)
	var tape_hand := Vector2(face * (20.0 + inspect * 5.0), -42.0 - inspect * 38.0 + rummage * 2.0)
	var greeting_hand := Vector2(-face * (40.0 + greeting * 14.0), -45.0 - greeting * 43.0 + sin(clock * 4.5) * talking * 9.0)
	var near_shoulder := Vector2(face * 25.0, -82.0) + coat_shift
	var far_shoulder := Vector2(-face * 24.0, -82.0) + coat_shift
	_arm(canvas,far_shoulder,Vector2(-face*42,-56),greeting_hand,paint.coat,edge,12.0,ink,paint.wax)
	_arm(canvas,near_shoulder,Vector2(face*40,-56-inspect*4),tape_hand,paint.teal,edge,12.0,ink,paint.wax)
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
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-7,-62),Vector2(5,-62),Vector2(11,9),Vector2(-7,9)]),shell.lerp(paint.shadow, 0.24))
	Paint.shape(canvas,PackedVector2Array([Vector2(-10,-52),Vector2(9,-52),Vector2(13,4),Vector2(-13,4)]),paint.coat,paint.brass,1.7)
	Paint.hatch(canvas,Vector2(-15,9),7,43,Color(paint.wax,0.20),3)
	canvas.draw_rect(Rect2(-20,10,40,7),paint.brass)
	Paint.bolt(canvas,Vector2(-17,13),2.5,paint.gold,ink,paper)
	Paint.bolt(canvas,Vector2(17,13),2.5,paint.gold,ink,paper)
	canvas.draw_line(Vector2(-21.0, 12.0), Vector2(21.0, 12.0), paper.lerp(warm, 0.52), 1.6, true)
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
	# Quiet eyelids sit above the mechanism; nods do not alter the count.
	var head := Vector2(face * 2.0, -81.0 + on_beat * 1.8 - startle * 4.0)
	canvas.draw_set_transform(shift + head, face * (talking * sin(clock * 4.0) * 0.09 - startle * 0.12))
	Paint.shape(canvas,PackedVector2Array([Vector2(-12,-10),Vector2(10,-12),Vector2(14,6),Vector2(-11,8)]),paint.cream,ink,1.6)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(5,-10),Vector2(10,-10),Vector2(13,5),Vector2(2,7),Vector2(1,-2)]),paint.wax.lerp(paint.wood, 0.22))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-13,-9),Vector2(-7,-16),Vector2(12,-12),Vector2(15,-7)]),paint.coat)
	canvas.draw_line(Vector2(-12,-9),Vector2(12,-8),paint.brass,2.2,true)
	for side in [-1.0,1.0]:
		var eye := Vector2(face*2+side*4,-1)
		canvas.draw_line(eye + Vector2(-1.7, -0.5), eye + Vector2(1.7, -0.5), ink, 1.5, true)
		canvas.draw_line(eye + Vector2(-2.0, -2.1), eye + Vector2(1.7, -1.8), Color(paint.wood, 0.52), 1.0, true)
	canvas.draw_line(Vector2(-1,5),Vector2(5,5-talking),ink,1.0,true)
	canvas.draw_set_transform(Vector2.ZERO)
	var raised_hand := shift + Vector2(face * (35.0 + talking * 3.0), -27.0 - greeting * 24.0 - on_beat * 4.0)
	var resting_hand := shift + Vector2(-face * 31.0, -8.0 + sin(clock * 3.0) * 2.0)
	_arm(canvas, shift + Vector2(face * 17.0, -34.0), shift + Vector2(face * 29.0, -21.0), raised_hand, ink, paper, 3.5,paint.shadow,paint.wax)
	_arm(canvas, shift + Vector2(-face * 18.0, -30.0), shift + Vector2(-face * 29.0, -18.0), resting_hand, ink, paper, 3.5,paint.shadow,paint.wax)
	if talking > 0.02 or pose.near:
		for mark in range(3):
			var mark_color := warm if mark <= beat and beat < 3 else Color(ink, 0.25)
			var point := shift + Vector2(-10.0 + mark * 10.0, -111.0)
			canvas.draw_line(point, point + Vector2(0.0, 5.0), mark_color, 2.5, true)

## MATRON 33⅓. Worn-smooth pleasantries, hands that still improvise: she
## crochets sleeve-patches from unravelled tape ribbon while she talks. Her
## hair is a stacked spindle of 45s. Warm as radiator pipes, planted as one.
static func _matron(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var paint := Paint.palette(ink, stock)
	ink = paint.edge
	var clock: float = pose.clock
	var face: float = pose.face
	var talking: float = pose.talking
	var greeting: float = pose.greeting
	var startle: float = pose.startle
	var breath := sin(clock * 1.4)
	var paper: Color = paint.cream
	var housecoat: Color = paint.coat.lerp(paint.copper, 0.28)
	var apron: Color = paint.cream.lerp(paint.wax, 0.35)
	var shift := Vector2(face * (talking * 1.2 - startle * 2.0), breath * 1.1 + startle * 1.5)
	# Slippers, planted. She has not left this floor in a long time.
	canvas.draw_line(Vector2(-19.0, 25.0), Vector2(-4.0, 25.0), paint.wood, 5.0, true)
	canvas.draw_line(Vector2(6.0, 25.0), Vector2(21.0, 25.0), paint.wood, 5.0, true)
	canvas.draw_set_transform(shift)
	# A broad housecoat over a broader apron: the silhouette is a bell.
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-24, -88), Vector2(22, -89), Vector2(36, -40), Vector2(38, 18),
		Vector2(-38, 19), Vector2(-36, -42),
	]), paint.shadow)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-21, -84), Vector2(19, -85), Vector2(32, -42), Vector2(34, 14),
		Vector2(-34, 15), Vector2(-32, -44),
	]), housecoat)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(19, -85), Vector2(32, -42), Vector2(34, 14), Vector2(22, 14), Vector2(16, -40)]), housecoat.lerp(paint.shadow, 0.45))
	Paint.shape(canvas, PackedVector2Array([Vector2(-20, -52), Vector2(20, -52), Vector2(26, 10), Vector2(-26, 10)]), apron, ink, 1.3)
	Paint.hatch(canvas, Vector2(-8, 6), 26, 30, Color(paint.wax, 0.26), 4)
	canvas.draw_line(Vector2(-21, -52), Vector2(21, -52), paint.copper, 2.2, true)
	# Pockets that hold tape ends, and a line of tiny buttons, each a 45's label.
	for y in [-40.0, -28.0, -16.0]:
		Paint.disc(canvas, Vector2(0, y), 2.4, paint.light, ink, paint.light)
	canvas.draw_rect(Rect2(-22, -22, 13, 11), Color(paint.wax, 0.45))
	canvas.draw_rect(Rect2(9, -22, 13, 11), Color(paint.wax, 0.45))
	# A collar of cream wool. Her coat has outlived every guest.
	Paint.shape(canvas, PackedVector2Array([Vector2(-22, -90), Vector2(-8, -78), Vector2(8, -78), Vector2(22, -90), Vector2(12, -96), Vector2(-12, -96)]), paper, ink, 1.4)
	canvas.draw_set_transform(Vector2.ZERO)
	var head := shift + Vector2(face * (2.0 + (1.5 if pose.near else 0.0)) - face * startle * 4.0, -108.0 + breath * 1.2 - startle * 2.0)
	var tilt := face * (-0.05 + talking * sin(clock * 3.6) * 0.03 + greeting * 0.06)
	canvas.draw_set_transform(head, tilt)
	# A soft round face, cheeks warm from the pipes.
	Paint.shape(canvas, PackedVector2Array([Vector2(-15, -12), Vector2(14, -13), Vector2(17, 6), Vector2(8, 16), Vector2(-10, 16), Vector2(-17, 6)]), paint.cream, ink, 1.6)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(6, -11), Vector2(14, -12), Vector2(17, 6), Vector2(8, 16), Vector2(3, 8)]), paint.wax.lerp(paint.wood, 0.14))
	for side in [-1.0, 1.0]:
		canvas.draw_circle(Vector2(face * 2.0 + side * 8.0, 7.0), 3.4, Color(paint.coral, 0.34), true, -1.0, true)
		var eye := Vector2(face * 2.5 + side * 5.5, -2.0)
		canvas.draw_line(eye + Vector2(-2.2, 0.4), eye + Vector2(2.2, 0.2), ink, 1.6, true)
		canvas.draw_line(eye + Vector2(-2.3, -2.1), eye + Vector2(2.1, -2.1), Color(paint.wood, 0.5), 1.0, true)
	canvas.draw_line(Vector2(-3, 11), Vector2(4, 11 - talking * 1.4), ink, 1.2, true)
	# The spindle of 45s: a leaning stack of small records, labels out.
	var lean := face * 0.09 + sin(clock * 0.9) * 0.02
	for index in range(5):
		var y := -16.0 - index * 7.5
		var record := Vector2(index * lean * 6.0, y)
		canvas.draw_set_transform(head + record.rotated(tilt), tilt + lean)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-15, 3.5), Vector2(15, 3.5), Vector2(14, -3.5), Vector2(-14, -3.5)]), ink)
		canvas.draw_line(Vector2(-13, 0), Vector2(13, 0), Color(paint.shadow.lerp(paint.light, 0.25), 0.7), 1.2, true)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-5, 2.5), Vector2(5, 2.5), Vector2(5, -2.5), Vector2(-5, -2.5)]), [paint.coral, paint.gold, paint.teal, paint.copper, paint.cream][index])
		canvas.draw_circle(Vector2(0, 0), 1.1, ink, true, -1.0, true)
	canvas.draw_set_transform(head + Vector2(5 * lean * 6.0, -53.0).rotated(tilt), tilt + lean)
	canvas.draw_line(Vector2(0, 4), Vector2(0, -6), paint.brass, 2.2, true)
	canvas.draw_set_transform(Vector2.ZERO)
	# Hands. One holds the crochet hook, the other the ribbon it pulls from a
	# basket; the greeting lifts the work, the pleasantry barely moves it.
	var work := sin(clock * 5.0) * (1.0 - greeting) * 1.6
	var hook_hand := shift + Vector2(face * (26.0 + talking * 2.0), -48.0 - greeting * 20.0 + work)
	var ribbon_hand := shift + Vector2(-face * 20.0, -42.0 - greeting * 6.0 - work)
	_arm(canvas, shift + Vector2(face * 22.0, -74.0), shift + Vector2(face * 34.0, -60.0), hook_hand, housecoat, paper, 11.0, ink, paint.wax)
	_arm(canvas, shift + Vector2(-face * 22.0, -74.0), shift + Vector2(-face * 32.0, -58.0), ribbon_hand, housecoat, paper, 11.0, ink, paint.wax)
	canvas.draw_line(hook_hand, hook_hand + Vector2(face * 9.0, -7.0), paint.brass, 2.2, true)
	canvas.draw_arc(hook_hand + Vector2(face * 9.5, -8.5), 2.2, 0, PI * 1.5, 8, paint.brass, 1.6, true)
	var basket := shift + Vector2(-face * 44.0, 12.0)
	Paint.shape(canvas, PackedVector2Array([basket + Vector2(-13, -9), basket + Vector2(13, -9), basket + Vector2(10, 11), basket + Vector2(-10, 11)]), paint.wood, ink, 1.3)
	Paint.hatch(canvas, basket + Vector2(0, 8), 18, 14, Color(paint.cream, 0.3), 4)
	var ribbon: Color = paint.copper.lerp(paint.coral, 0.3)
	var strand := PackedVector2Array()
	for sample in range(9):
		var t := sample / 8.0
		var along := ribbon_hand.lerp(basket + Vector2(0, -8), t)
		strand.append(along + Vector2(sin(t * PI * 2.0 + clock * 2.0) * 5.0 * (1.0 - t), sin(t * PI) * 10.0))
	canvas.draw_polyline(strand, ribbon, 2.0, true)
	var patch := hook_hand.lerp(ribbon_hand, 0.5) + Vector2(0, 6)
	for row in range(3):
		canvas.draw_line(patch + Vector2(-7, row * 3.0 - 3.0), patch + Vector2(7, row * 3.0 - 2.5), Color(ribbon, 0.75), 1.4, true)
	if pose.near or talking > 0.02:
		# The teapot waits on its ring; there is always the pot.
		var pot := shift + Vector2(face * 46.0, 8.0)
		Paint.disc(canvas, pot, 8.0, paint.teal, ink, paint.light)
		canvas.draw_line(pot + Vector2(-face * 8.0, -2.0), pot + Vector2(-face * 15.0, -8.0), ink, 2.0, true)
		canvas.draw_line(pot + Vector2(face * 7.0, -3.0), pot + Vector2(face * 11.0, 1.0), ink, 2.2, true)
		canvas.draw_line(pot + Vector2(0, -8.0), pot + Vector2(0, -11.0), paint.brass, 2.0, true)
		for wisp in range(2):
			var y := -14.0 - fposmod(clock * 9.0 + wisp * 7.0, 14.0)
			canvas.draw_line(pot + Vector2(wisp * 3.0 - 1.0, y), pot + Vector2(wisp * 3.0 + 1.0, y - 4.0), Color(paint.light, 0.35 * (1.0 + y / 28.0)), 1.0, true)

## THE TYPESETTER. The last printer; deadpan; every sentence set before it is
## spoken. Composing stick in one hand, the other picking sorts from the case
## at his waist. He sets tomorrow's poster every night, for no one.
static func _typesetter(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var paint := Paint.palette(ink, stock)
	ink = paint.edge
	var clock: float = pose.clock
	var face: float = pose.face
	var talking: float = pose.talking
	var greeting: float = pose.greeting
	var startle: float = pose.startle
	var breath := sin(clock * 1.7) * 0.8
	var paper: Color = paint.cream
	var apron: Color = paint.shadow.lerp(paint.coat, 0.35)
	var shirt: Color = paint.cream.lerp(paint.wax, 0.5)
	# Type is picked in a steady rhythm; the hand returns to the stick each beat.
	var beat := fposmod(clock, 1.1) / 1.1
	var pick := sin(beat * PI) * (1.0 - greeting) * (1.0 - talking * 0.6)
	var shift := Vector2(face * (talking * 0.8 - startle * 2.5), breath + startle * 1.5)
	# Narrow boots, a long still stance.
	canvas.draw_line(Vector2(-13.0, 25.0), Vector2(-1.0, 25.0), ink, 4.5, true)
	canvas.draw_line(Vector2(5.0, 25.0), Vector2(17.0, 25.0), ink, 4.5, true)
	canvas.draw_set_transform(shift)
	# A tall thin figure: shirt sleeves, a long apron stained to the hem.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-18, -96), Vector2(16, -97), Vector2(22, -40), Vector2(20, 20), Vector2(-20, 20), Vector2(-22, -42)]), paint.shadow)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-15, -92), Vector2(13, -93), Vector2(18, -46), Vector2(-18, -47)]), shirt)
	Paint.shape(canvas, PackedVector2Array([Vector2(-14, -78), Vector2(13, -78), Vector2(19, 16), Vector2(-19, 16)]), apron, ink, 1.4)
	canvas.draw_line(Vector2(-14, -78), Vector2(-9, -94), paint.wood, 2.0, true)
	canvas.draw_line(Vector2(13, -78), Vector2(8, -94), paint.wood, 2.0, true)
	# Ink: a thumbprint and two wiped smears on the apron, never cleaned.
	canvas.draw_circle(Vector2(6, -30), 3.0, Color(ink, 0.55), true, -1.0, true)
	Paint.hatch(canvas, Vector2(-7, 4), 10, 22, Color(ink, 0.42), 2)
	Paint.hatch(canvas, Vector2(9, -4), 8, 14, Color(ink, 0.36), 2)
	# Sleeve garters, brass: the one bright thing he allows himself.
	for side in [-1.0, 1.0]:
		canvas.draw_line(Vector2(side * 17.0, -70.0), Vector2(side * 21.0, -66.0), paint.brass, 2.4, true)
	# The type case at his waist: rows of sorts, a few picked clean.
	canvas.draw_rect(Rect2(-24, -40, 48, 15), paint.wood)
	canvas.draw_line(Vector2(-24, -40), Vector2(24, -40), paint.brass, 1.6, true)
	for column in range(8):
		for row in range(2):
			var cell := Vector2(-21 + column * 6, -37 + row * 6)
			var empty := (column * 3 + row * 5) % 7 == 0
			canvas.draw_rect(Rect2(cell, Vector2(4, 4)), Color(paint.shadow, 0.6) if empty else paper.lerp(ink, 0.25))
	canvas.draw_set_transform(Vector2.ZERO)
	# A long face under a green eyeshade; spectacles; the mouth barely moves.
	var head := shift + Vector2(face * (2.5 + (1.0 if pose.near else 0.0)) - face * startle * 3.0, -114.0 + breath * 0.6 - startle * 2.0)
	var nod := face * (-0.04 + greeting * 0.08 - startle * 0.08 + talking * sin(clock * 2.0) * 0.015)
	canvas.draw_set_transform(head, nod)
	Paint.shape(canvas, PackedVector2Array([Vector2(-11, -16), Vector2(10, -17), Vector2(13, 10), Vector2(6, 20), Vector2(-7, 20), Vector2(-13, 9)]), paint.cream, ink, 1.6)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(4, -15), Vector2(10, -17), Vector2(13, 10), Vector2(6, 20), Vector2(2, 9)]), paint.wax.lerp(paint.wood, 0.18))
	# The eyeshade: a translucent green visor on a band, tilted as he reads.
	Paint.shape(canvas, PackedVector2Array([Vector2(-19, -12), Vector2(17, -13), Vector2(23, -4), Vector2(-25, -3)]), Color(paint.teal, 0.82), ink, 1.3)
	canvas.draw_line(Vector2(-13, -14), Vector2(12, -15), paint.shadow, 2.0, true)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-12, -22), Vector2(11, -23), Vector2(12, -15), Vector2(-13, -14)]), paint.shadow)
	for side in [-1.0, 1.0]:
		var eye := Vector2(face * 2.0 + side * 5.5, 1.5)
		canvas.draw_arc(eye, 4.2, 0, TAU, 14, Color(paint.brass, 0.9), 1.0, true)
		canvas.draw_line(eye + Vector2(-1.8, 0.3), eye + Vector2(1.8, 0.3), ink, 1.5, true)
	canvas.draw_line(Vector2(-2.5, 1.5), Vector2(2.5, 1.5), Color(paint.brass, 0.9), 1.0, true)
	canvas.draw_line(Vector2(-3, 13), Vector2(4, 13 - talking * 0.6), ink, 1.3, true)
	canvas.draw_set_transform(Vector2.ZERO)
	# The composing stick rides level in the near hand. While he talks the
	# line he set tilts toward whoever is listening: typeset, then spoken.
	var stick_hand := shift + Vector2(face * (24.0 + talking * 4.0), -56.0 - greeting * 10.0 - talking * 6.0)
	var pick_hand := shift + Vector2(-face * (6.0 + pick * 14.0), -34.0 - pick * 20.0 + greeting * 2.0)
	_arm(canvas, shift + Vector2(face * 15.0, -84.0), shift + Vector2(face * 28.0, -70.0), stick_hand, shirt, paper, 8.5, ink, paint.light)
	_arm(canvas, shift + Vector2(-face * 15.0, -84.0), shift + Vector2(-face * 26.0, -62.0), pick_hand, shirt, paper, 8.5, ink, paint.light)
	canvas.draw_set_transform(stick_hand, face * (-0.12 - talking * 0.22))
	canvas.draw_rect(Rect2(-16, -6, 32, 8), paint.brass)
	canvas.draw_rect(Rect2(-15, -5, 30, 6), paint.brass.lerp(ink, 0.35))
	for sort in range(7):
		var set_count := 4 + int(talking * 3.0)
		if sort < set_count:
			canvas.draw_rect(Rect2(-14 + sort * 4, -4, 3, 4), paper.lerp(ink, 0.2))
	canvas.draw_line(Vector2(-16, 3), Vector2(16, 3), Color(paint.light, 0.5), 1.0, true)
	canvas.draw_set_transform(Vector2.ZERO)
	if pick > 0.6:
		# One sort between finger and thumb, on its way to the line.
		canvas.draw_rect(Rect2(pick_hand + Vector2(-1.5, -2), Vector2(3, 4)), paper.lerp(ink, 0.2))
	if pose.near or talking > 0.02:
		# Tomorrow's poster, pegged to dry: set tonight, like every night.
		var poster := shift + Vector2(-face * 52.0, -74.0)
		canvas.draw_line(poster + Vector2(-16, -22), poster + Vector2(16, -22), paint.copper, 1.6, true)
		Paint.shape(canvas, PackedVector2Array([poster + Vector2(-13, -20), poster + Vector2(13, -20), poster + Vector2(13, 16), poster + Vector2(-13, 16)]), paper, ink, 1.2)
		for line in range(4):
			var width: float = [18.0, 10.0, 16.0, 7.0][line]
			canvas.draw_line(poster + Vector2(-width * 0.5, -13 + line * 7), poster + Vector2(width * 0.5, -13 + line * 7), Color(ink, 0.7 if line == 0 else 0.45), 2.0 if line == 0 else 1.2, true)
		canvas.draw_line(poster + Vector2(-8, 10), poster + Vector2(8, 10), Color(paint.coral, 0.85), 2.2, true)

static func _arm(canvas: CanvasItem, shoulder: Vector2, elbow: Vector2, hand: Vector2, ink: Color, paper: Color, width: float, edge: Color, highlight: Color) -> void:
	# Overlapping rounded segments keep folded elbows clean even when an
	# inspecting hand comes back toward its shoulder; a miter would grow a spike.
	Paint.segment(canvas,shoulder,elbow,width,ink,edge,highlight)
	Paint.segment(canvas,elbow,hand,width*0.82,ink,edge,highlight)
	Paint.disc(canvas,hand,maxf(width*0.43,3.0),paper,edge,highlight)
