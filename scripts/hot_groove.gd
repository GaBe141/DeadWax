extends StaticBody2D
## A LIVE GROOVE — a hot passage still pressed loud enough to answer.
## Strike it -> after ECHO_DELAY its loop comes back around (watch it converge).
## Strike again exactly as it lands: ON BEAT (amplified launch).

const ECHO_DELAY := 0.38
const ECHO_WINDOW := 0.10
const SIZE := Vector2(56, 56)

const WAXPALE := Color(0.93, 0.91, 0.86)
const INK := Color(0.18, 0.15, 0.12)
const HOT := Color(0.95, 0.25, 0.55)

var _ping_at := -100.0
var _sid := 0

func _ready() -> void:
	add_to_group("live_groove")
	_sid = randi()
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = SIZE
	cs.shape = sh
	add_child(cs)
	z_index = 5

func reach() -> float:
	return 36.0

func ping() -> void:
	_ping_at = _now()

func is_echo_hot() -> bool:
	return _ping_at > 0.0 and absf(_now() - (_ping_at + ECHO_DELAY)) <= ECHO_WINDOW

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var t := _now()
	var half := SIZE / 2.0
	draw_rect(Rect2(-half, SIZE), WAXPALE)
	draw_rect(Rect2(-half * 0.55, SIZE * 0.55), Color(0.80, 0.76, 0.70))

	# scribble outline, boiling at ~10fps
	var rng := RandomNumberGenerator.new()
	rng.seed = _sid + int(t * 10.0)
	var corners := [
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y)
	]
	var pts := PackedVector2Array()
	for i in range(5):
		var c: Vector2 = corners[i % 4]
		pts.append(c + Vector2(rng.randf_range(-2.0, 2.0), rng.randf_range(-2.0, 2.0)))
	var hot := is_echo_hot()
	draw_polyline(pts, HOT if hot else INK, 4.5 if hot else 3.0)

	# the returning echo, made visible — this teaches the timing
	var echo_t := _ping_at + ECHO_DELAY
	if _ping_at > 0.0 and t < echo_t + ECHO_WINDOW:
		var prog := clampf((t - _ping_at) / ECHO_DELAY, 0.0, 1.0)
		var r := 36.0 + (1.0 - prog) * 150.0
		var col := Color(HOT.r, HOT.g, HOT.b, 0.25 + 0.75 * prog)
		var n := 22
		var ring := PackedVector2Array()
		for i in range(n + 1):
			var ang := TAU * float(i) / float(n)
			var rr := r + rng.randf_range(-2.5, 2.5)
			ring.append(Vector2(cos(ang), sin(ang)) * rr)
		draw_polyline(ring, col, 2.0 + 2.0 * prog)
