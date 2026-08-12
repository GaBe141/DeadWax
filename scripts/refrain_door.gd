extends StaticBody2D
## A GROOVE-LOCK — a door that listens.
## It opens for the COUNT-IN: four even strikes, any tempo. It has always
## listened. It will open in minute one for anyone who knows. That's the law.

signal opened

const SIZE := Vector2(26, 150)
const GAP_MIN := 0.22
const GAP_MAX := 1.10
const EVENNESS := 0.28            # allowed drift from the running average gap

var is_open := false
var _times: Array[float] = []
var _sid := 0
var _open_anim := 0.0

func _ready() -> void:
	add_to_group("hears_strikes")
	_sid = randi()
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = SIZE
	cs.shape = sh
	cs.name = "block"
	add_child(cs)
	z_index = 6

func on_player_strike(pos: Vector2, _big: bool) -> void:
	if is_open:
		return
	# it listens from anywhere in the room — that's what doors are for
	var now := Time.get_ticks_msec() / 1000.0
	if _times.is_empty():
		_times.append(now)
	else:
		var gap := now - _times[_times.size() - 1]
		if gap < GAP_MIN:
			return  # a flam, not a count — ignore
		if gap > GAP_MAX:
			_times = [now]
		else:
			# check evenness against the running average
			if _times.size() >= 2:
				var avg := 0.0
				for i in range(1, _times.size()):
					avg += _times[i] - _times[i - 1]
				avg /= float(_times.size() - 1)
				if absf(gap - avg) / avg > EVENNESS:
					_times = [_times[_times.size() - 1], now]
					queue_redraw()
					return
			_times.append(now)
	if _times.size() >= 4:
		_open()
	queue_redraw()

func _open() -> void:
	is_open = true
	_open_anim = 1.0
	var cs := get_node_or_null("block")
	if cs != null:
		cs.set_deferred("disabled", true)
	var bank := get_tree().get_first_node_in_group("audio_bank")
	if bank != null:
		bank.play("door", -4.0)
	opened.emit()

func _process(delta: float) -> void:
	if _open_anim > 0.0:
		_open_anim = maxf(_open_anim - delta * 0.8, 0.0)
	queue_redraw()

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _sid + int(Time.get_ticks_msec() / 100)
	var half := SIZE / 2.0
	var ink := Color(0.16, 0.14, 0.15)
	var pink := Color(0.90, 0.25, 0.50)

	if is_open:
		# bars swing aside and fade
		var a := _open_anim
		if a > 0.0:
			for i in range(4):
				var y := -half.y + 20 + i * 36
				draw_line(Vector2(-half.x - 14, y), Vector2(half.x + 14, y + rng.randf_range(-2, 2)), Color(pink.r, pink.g, pink.b, a * 0.7), 3.0)
		draw_line(Vector2(0, -half.y), Vector2(0, -half.y + 12), ink, 3.0)
		draw_line(Vector2(0, half.y - 12), Vector2(0, half.y), ink, 3.0)
		return

	# closed: a barred lock of taut lines
	draw_rect(Rect2(-half, SIZE), Color(ink.r, ink.g, ink.b, 0.12))
	for i in range(4):
		var y := -half.y + 20 + i * 36
		draw_line(Vector2(-half.x - 10, y + rng.randf_range(-1.5, 1.5)), Vector2(half.x + 10, y + rng.randf_range(-1.5, 1.5)), ink, 3.5)
	# the four listening ticks: fill as the count holds even
	var got := _times.size()
	for i in range(4):
		var p := Vector2(0, -half.y - 18 - 0)
		p.x = -27 + i * 18
		if i < got:
			draw_circle(p, 5.0, pink)
		else:
			draw_arc(p, 5.0, 0, TAU, 12, ink, 1.8)
