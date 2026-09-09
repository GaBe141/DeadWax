extends RefCounted
## The keeper's engraving. Like every Press impression, this reads only the
## explicitly supplied pose and palette, never a player or gameplay singleton.

static func draw_tonearm(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color, display_font: Font, body_font: Font, heading_size: int, small_size: int) -> void:
	var phase: String = pose.phase
	var face: float = pose.face
	var accent := Color(0.90, 0.25, 0.50)
	var warm := Color(0.80, 0.54, 0.24)
	var pale := stock.lerp(Color.WHITE, 0.28)
	var muted := stock.lerp(ink, 0.48)
	var pivot := Vector2(175.0, -370.0)
	var elbow := Vector2(-130.0, -285.0)
	var tip := Vector2.ZERO
	var tip_rotation := 0.0
	if phase == "gesture":
		var raised := sin(float(pose.gesture) * PI)
		tip = Vector2(-160.0, -245.0) * raised
		tip_rotation = -face * PI * raised
	elif phase == "counting":
		var tension: float = pose.windup
		tip = Vector2(-face * 55.0, -80.0) * tension
	elif phase == "sweep":
		tip = Vector2(-face * 55.0, -80.0).lerp(Vector2.ZERO, float(pose.sweep))
	elif phase == "freed":
		tip = Vector2(-125.0, -230.0)
		tip_rotation = -face * 1.15
		elbow += Vector2(0.0, -30.0)
	elif phase == "down":
		tip = Vector2(32.0, 15.0)
		elbow += Vector2(15.0, 115.0)
	var bright := accent if phase == "sweep" else (warm if phase == "freed" else ink)
	var offset := Vector2(3.0, 2.0)
	# Counterweight and overhead mounting plate; fine rules repeat the record's
	# concentric geometry without making the silhouette read as another dummy.
	canvas.draw_rect(Rect2(pivot + Vector2(-76.0, -52.0), Vector2(210.0, 38.0)), ink)
	canvas.draw_line(pivot + Vector2(-94.0, -62.0), pivot + Vector2(150.0, -62.0), ink, 2.0, true)
	for mark in range(7):
		var x := pivot.x - 60.0 + mark * 27.0
		canvas.draw_line(Vector2(x, pivot.y - 46.0), Vector2(x, pivot.y - 22.0), muted, 1.0, true)
	canvas.draw_line(pivot + Vector2(90.0, 0.0), pivot, ink, 27.0, true)
	canvas.draw_line(pivot + offset, elbow + offset, Color(accent, 0.50), 28.0, true)
	canvas.draw_line(pivot, elbow, ink, 28.0, true)
	canvas.draw_line(pivot + Vector2(0.0, -5.0), elbow + Vector2(0.0, -5.0), pale, 3.0, true)
	canvas.draw_circle(pivot, 38.0, ink, true, -1.0, true)
	canvas.draw_arc(pivot, 30.0, 0.0, TAU, 64, pale, 2.0, true)
	canvas.draw_arc(pivot, 23.0, 0.0, TAU, 48, muted, 1.0, true)
	canvas.draw_circle(pivot, 5.0, pale, true, -1.0, true)
	var shoulder := tip + Vector2(-face * 14.0, -77.0).rotated(tip_rotation)
	canvas.draw_line(elbow + offset, shoulder + offset, Color(accent, 0.45), 21.0, true)
	canvas.draw_line(elbow, shoulder, bright, 21.0, true)
	canvas.draw_line(elbow + Vector2(4.0, 0.0), shoulder + Vector2(4.0, 0.0), pale, 2.0, true)
	canvas.draw_circle(elbow, 20.0, ink, true, -1.0, true)
	canvas.draw_arc(elbow, 13.0, 0.0, TAU, 36, pale, 2.0, true)
	# Headshell, cartridge and visibly grounded stylus. The open cartridge is
	# separated by a pale slot; the damage/parry point stays at the node origin.
	canvas.draw_set_transform(tip, tip_rotation)
	var cartridge := Rect2(Vector2(-32.0, -72.0), Vector2(64.0, 40.0))
	canvas.draw_rect(cartridge, bright)
	canvas.draw_rect(Rect2(cartridge.position + Vector2(7.0, 7.0), Vector2(50.0, 7.0)), pale)
	for vent in range(4):
		canvas.draw_line(Vector2(-19.0 + vent * 12.0, -48.0), Vector2(-19.0 + vent * 12.0, -39.0), muted, 2.0)
	var nib := PackedVector2Array([Vector2(-15.0, -29.0), Vector2(15.0, -29.0), Vector2(4.0, 13.0), Vector2(-4.0, 13.0)])
	canvas.draw_colored_polygon(nib, accent if pose.open else bright)
	canvas.draw_line(Vector2(0.0, 13.0), Vector2(face * 13.0, 24.0), ink, 3.0, true)
	canvas.draw_set_transform(Vector2.ZERO)
	if phase == "down":
		canvas.draw_line(Vector2(-22.0, -55.0), Vector2(8.0, -29.0), stock, 5.0, true)
		canvas.draw_line(Vector2(8.0, -29.0), Vector2(-2.0, 6.0), stock, 5.0, true)
		for shard in range(3):
			canvas.draw_line(Vector2(-48.0 + shard * 27.0, 22.0), Vector2(-31.0 + shard * 27.0, 26.0), ink, 5.0, true)
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
	canvas.draw_string(display_font, Vector2(-label_width * 0.5, -192.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, heading_size, ink)
	canvas.draw_string(body_font, Vector2(-prompt_width * 0.5, -164.0), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, small_size, ink)
	if pose.engaged:
		var total: int = pose.health_total
		var remaining := int(ceil(float(pose.health) * total))
		for pip in range(total):
			var center := Vector2((pip - (total - 1) * 0.5) * 15.0, -144.0)
			canvas.draw_line(center, center + Vector2(8.0, 0.0), ink if pip < remaining else Color(ink, 0.22), 3.0, true)
