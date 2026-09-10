extends RefCounted
const Paint := preload("res://scripts/figure_paint.gd")
## The keeper's engraving. Like every Press impression, this reads only the
## explicitly supplied pose and palette, never a player or gameplay singleton.

static func draw_tonearm(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color, display_font: Font, body_font: Font, heading_size: int, small_size: int) -> void:
	var phase: String = pose.phase
	var face: float = pose.face
	var page_ink := ink
	var paint := Paint.palette(ink,stock)
	ink = paint.edge
	var accent: Color = paint.coral
	var warm: Color = paint.gold
	var pale: Color = paint.cream
	var muted: Color = paint.teal
	var clock: float = pose.get("clock", pose.time)
	var recoil: float = pose.get("hit_recoil", 0.0)
	var settle := smoothstep(0.0, 1.0, float(pose.get("settle", 1.0)))
	var pivot := Vector2(175.0, -370.0)
	var elbow := Vector2(-130.0, -285.0)
	var idle := Vector2(sin(clock * 1.3) * 1.8, -1.5 - sin(clock * 1.9) * 1.5)
	var tip := idle
	var tip_rotation := 0.0
	# The mounting stays bolted to the wall. A little weight travels through
	# the two joints and the loose cartridge, entirely in drawing coordinates.
	elbow += Vector2(sin(clock * 1.3 - 0.4) * 2.8, sin(clock * 1.9 - 0.5) * 2.0)
	if phase == "gesture":
		var gesture: float = pose.gesture
		var raised := sin(smoothstep(0.0, 1.0, gesture) * PI)
		tip = idle.lerp(Vector2(-160.0, -245.0), raised)
		tip_rotation = -face * PI * raised
		elbow += Vector2(-raised * 22.0, -raised * 16.0)
	elif phase == "counting":
		var tension := smoothstep(0.0, 1.0, float(pose.windup))
		tip = idle.lerp(Vector2(-face * 55.0, -80.0), tension)
		elbow += Vector2(-face * tension * 8.0, -tension * 7.0)
		tip_rotation = -face * tension * 0.22
	elif phase == "sweep":
		# The accelerated arc reaches the node origin exactly at the existing
		# 160 ms contact. Motion never displaces that gameplay strike point.
		var sweep: float = pose.sweep
		var travel := sweep * sweep
		tip = Vector2(-face * 55.0, -80.0).lerp(Vector2.ZERO, travel)
		tip += Vector2(face * sin(sweep * PI) * 14.0, 0.0)
		tip_rotation = -face * 0.22 * (1.0 - travel)
		elbow += Vector2(-face * (1.0 - travel) * 8.0, -(1.0 - travel) * 7.0)
	elif phase == "recovery":
		var age: float = pose.time
		var follow := sin(minf(age / 0.24, 1.0) * PI) * exp(-age * 3.0)
		tip = Vector2(face * 23.0, 4.0) * follow
		tip += idle * smoothstep(0.24, 0.75, age)
		tip_rotation = face * follow * 0.19
		elbow += Vector2(face * follow * 10.0, follow * 3.0)
	elif phase == "stagger":
		var age: float = pose.time
		var catch := sin(minf(age / 0.35, 1.0) * PI)
		var tremor := sin(age * 18.0) * exp(-age * 4.0)
		tip = Vector2(-face * 32.0, -26.0) * catch
		tip += idle * smoothstep(0.3, 0.85, age)
		tip_rotation = -face * (catch * 0.28 + tremor * 0.07)
		elbow += Vector2(-face * catch * 12.0, -catch * 9.0)
	elif phase == "freed":
		tip = Vector2(-125.0, -230.0) * settle
		tip += Vector2(-sin(settle * PI) * 24.0, 0.0)
		tip_rotation = -face * 1.15 * settle
		elbow += Vector2(-sin(settle * PI) * 10.0, -30.0 * settle)
	elif phase == "down":
		var fall := minf(settle * 1.35, 1.0)
		var bounce := sin(clampf((settle - 0.72) / 0.28, 0.0, 1.0) * PI) * 6.0
		tip = Vector2(32.0, 15.0) * fall - Vector2(0.0, bounce)
		elbow += Vector2(15.0, 115.0) * settle
	if recoil > 0.0:
		var impact := sin((1.0 - recoil) * PI) * recoil
		tip += Vector2(-face * 12.0, -6.0) * impact
		tip_rotation += -face * impact * 0.16
	var bright: Color = accent if phase == "sweep" else (warm if phase == "freed" else paint.brass)
	var offset := Vector2(3.0, 2.0)
	# Counterweight and overhead mounting plate; fine rules repeat the record's
	# concentric geometry without making the silhouette read as another dummy.
	Paint.shape(canvas,PackedVector2Array([pivot+Vector2(-83,-60),pivot+Vector2(124,-60),pivot+Vector2(139,-43),pivot+Vector2(135,-10),pivot+Vector2(-80,-10)]),paint.coat,ink,3.0)
	canvas.draw_rect(Rect2(pivot+Vector2(-74,-51),Vector2(191,24)),paint.wood)
	canvas.draw_line(pivot+Vector2(-73,-49),pivot+Vector2(116,-49),paint.copper,5.0,true)
	canvas.draw_line(pivot + Vector2(-94.0, -62.0), pivot + Vector2(150.0, -62.0), ink, 2.0, true)
	for mark in range(7):
		var x := pivot.x - 60.0 + mark * 27.0
		canvas.draw_line(Vector2(x,pivot.y-42),Vector2(x,pivot.y-25),Color(paint.shadow,0.7),3.0,true)
	for x in [-65.0,118.0]: Paint.bolt(canvas,pivot+Vector2(x,-38),5.5,paint.brass,ink,pale)
	Paint.segment(canvas,pivot+Vector2(95,0),pivot,31,paint.wood,ink,paint.copper)
	# Broad bevelled beams, riveted collars and a dark underside make the arm
	# carry physical weight while the original two joints keep their exact arc.
	Paint.segment(canvas,pivot+offset*2,elbow+offset*2,37,paint.shadow,ink,paint.coat)
	Paint.segment(canvas,pivot,elbow,30,paint.brass,ink,paint.gold)
	canvas.draw_line(pivot+Vector2(0,5),elbow+Vector2(0,5),paint.wood,7.0,true)
	Paint.disc(canvas,pivot,43,paint.coat,ink,paint.teal)
	Paint.disc(canvas,pivot,32,paint.brass,ink,paint.gold)
	Paint.disc(canvas,pivot,22,paint.wood,ink,paint.copper)
	for index in range(8):
		var bolt := pivot+Vector2.from_angle(index*TAU/8.0)*35
		Paint.bolt(canvas,bolt,3.0,paint.gold,ink,pale)
	Paint.bolt(canvas,pivot,9,paint.brass,ink,pale)
	var shoulder := tip + Vector2(-face * 14.0, -77.0).rotated(tip_rotation)
	Paint.segment(canvas,elbow+offset,shoulder+offset,29,paint.shadow,ink,paint.teal)
	Paint.segment(canvas,elbow,shoulder,22,bright,ink,paint.gold)
	Paint.disc(canvas,elbow,25,paint.coat,ink,paint.teal)
	Paint.bolt(canvas,elbow,15,paint.brass,ink,pale)
	for index in range(4):
		var point := elbow.lerp(shoulder,0.20+index*0.18)
		canvas.draw_line(point+Vector2(-7,-2),point+Vector2(6,1),Color(paint.wood,0.6),2.0,true)
	# Headshell, cartridge and visibly grounded stylus. The open cartridge is
	# separated by a pale slot; the damage/parry point stays at the node origin.
	canvas.draw_set_transform(tip, tip_rotation)
	var cartridge := Rect2(Vector2(-32.0, -72.0), Vector2(64.0, 40.0))
	Paint.shape(canvas,PackedVector2Array([Vector2(-34,-76),Vector2(24,-76),Vector2(35,-64),Vector2(31,-31),Vector2(-29,-31),Vector2(-36,-43)]),paint.coat,ink,2.4)
	Paint.shape(canvas,PackedVector2Array([Vector2(-31,-73),Vector2(22,-73),Vector2(29,-65),Vector2(-28,-62)]),bright,ink,1.5)
	canvas.draw_rect(Rect2(cartridge.position+Vector2(7,13),Vector2(50,20)),pale)
	canvas.draw_rect(Rect2(cartridge.position+Vector2(8,26),Vector2(48,7)),paint.wax)
	Paint.bolt(canvas,Vector2(-27,-43),3,paint.brass,ink,pale)
	Paint.bolt(canvas,Vector2(27,-43),3,paint.brass,ink,pale)
	for vent in range(4):
		canvas.draw_line(Vector2(-18.0+vent*12,-52),Vector2(-18.0+vent*12,-44),paint.shadow,3.0,true)
	var nib := PackedVector2Array([Vector2(-15.0, -29.0), Vector2(15.0, -29.0), Vector2(4.0, 13.0), Vector2(-4.0, 13.0)])
	Paint.shape(canvas,nib,accent if pose.open else paint.brass,ink,2.0)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-12,-27),Vector2(0,-27),Vector2(-1,10),Vector2(-4,12)]),paint.gold)
	Paint.segment(canvas,Vector2(0,13),Vector2(face*13,24),3.5,paint.cream,ink,paint.light)
	canvas.draw_set_transform(Vector2.ZERO)
	if phase == "down":
		canvas.draw_line(tip + Vector2(-22.0, -55.0), tip + Vector2(8.0, -29.0), stock, 5.0, true)
		canvas.draw_line(tip + Vector2(8.0, -29.0), tip + Vector2(-2.0, 6.0), stock, 5.0, true)
		for shard in range(3):
			var spread := Vector2(-48.0 + shard * 27.0, 22.0)
			var leap := sin(settle * PI) * (34.0 + shard * 8.0)
			var shard_pos := Vector2.ZERO.lerp(spread, settle) - Vector2(0.0, leap)
			canvas.draw_line(shard_pos, shard_pos + Vector2(17.0, 4.0).rotated((1.0 - settle) * (shard + 1)), ink, 5.0, true)
	# A narrow floor impression matches the localized reach. Only the committed
	# face is marked, leaving the far side and above the point visibly clear.
	if phase == "counting" or phase == "sweep":
		canvas.draw_line(Vector2(-face * 18.0, 25.0), Vector2(face * 130.0, 25.0), Color(accent, 0.35), 2.0, true)
		canvas.draw_line(Vector2(face * 130.0, 19.0), Vector2(face * 130.0, 28.0), accent, 2.0, true)
		for beat in range(3):
			var beat_color := accent if beat < int(pose.count) else Color(ink, 0.25)
			var mark := Vector2(-25.0 + beat * 25.0, -125.0)
			canvas.draw_line(mark, mark + Vector2(0.0, 17.0), beat_color, 5.0, true)
	if phase == "recovery" or phase == "stagger":
		var remaining := 1.0 - float(pose.recovery)
		canvas.draw_arc(Vector2.ZERO, 46.0, -PI * 0.85, -PI * 0.85 + PI * 0.7 * remaining, 28, warm if phase == "stagger" else accent, 3.0, true)
	if float(pose.listening) > 0.0:
		canvas.draw_arc(Vector2.ZERO, 53.0, -PI / 2.0, -PI / 2.0 + TAU * float(pose.listening), 48, warm, 4.0, true)
	var label := "THE TONEARM"
	var prompt := "It waits for your answer."
	if phase == "gesture":
		prompt = "Above. Beyond the needle."
	elif phase == "waiting":
		prompt = "Kneel close. Let it hear you."
	elif phase == "counting":
		prompt = "Listen to the count."
	elif phase == "sweep":
		prompt = "NOW"
	elif phase == "recovery":
		prompt = "The cartridge is open." if pose.open else "The point settles."
	elif phase == "stagger":
		prompt = "Kneel close. There is still time."
	elif phase == "freed":
		label = "HEARD, AT LAST"
		prompt = "The arm lifts. The record goes on."
	elif phase == "down":
		label = "THE BROKEN ARM"
		prompt = "The record goes on."
	var label_width := display_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, heading_size).x
	var prompt_width := body_font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, small_size).x
	var card_width := maxf(prompt_width + 24.0, 240.0)
	canvas.draw_rect(Rect2(Vector2(-card_width * 0.5, -215.0), Vector2(card_width, 63.0)), stock.lerp(ink, 0.06))
	canvas.draw_line(Vector2(-card_width * 0.5 + 12.0, -153.0), Vector2(card_width * 0.5 - 12.0, -153.0), Color(accent, 0.8), 2.0, true)
	canvas.draw_string(display_font, Vector2(-label_width * 0.5, -192.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, heading_size, page_ink)
	canvas.draw_string(body_font, Vector2(-prompt_width * 0.5, -164.0), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, small_size, page_ink)
	if pose.engaged:
		var total: int = pose.health_total
		var remaining := int(ceil(float(pose.health) * total))
		for pip in range(total):
			var center := Vector2((pip - (total - 1) * 0.5) * 15.0, -144.0)
			canvas.draw_line(center, center + Vector2(8.0, 0.0), ink if pip < remaining else Color(ink, 0.22), 3.0, true)
