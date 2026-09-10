extends StaticBody2D
## A LIVE GROOVE — a hot passage still pressed loud enough to answer.
## Strike it -> after ECHO_DELAY its loop comes back around (watch it converge).
## Strike again exactly as it lands: ON BEAT (amplified launch).

const Press := preload("res://scripts/press.gd")
const PressingScript := preload("res://scripts/pressing_state.gd")

const ECHO_DELAY := 0.38
const ECHO_WINDOW := 0.10
const SIZE := Vector2(56, 56)

const WAXPALE := Color(0.93, 0.91, 0.86)
const INK := Color(0.18, 0.15, 0.12)
const HOT := Color(0.95, 0.25, 0.55)
const SPENT := Color(0.62, 0.60, 0.58)
const SPENT_INK := Color(0.44, 0.42, 0.44)

## Which face of the pressing carries this groove. A groove only answers a
## strike while its own side is up; turned over, it is just spent wax.
var side := PressingScript.Side.A

var _ping_at := -100.0
var _sid := 0
var _live := true

func _ready() -> void:
	if _live:
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

func is_live() -> bool:
	return _live

## Called by the room whenever the pressing turns over. A quieted groove leaves
## the strike group entirely, so nothing has to re-check sides mid-strike.
func set_current_side(current_side: int) -> void:
	var live_now := current_side == side
	if live_now == _live:
		return
	_live = live_now
	if not is_inside_tree():
		return
	if _live:
		add_to_group("live_groove")
	else:
		remove_from_group("live_groove")
		_ping_at = -100.0
	queue_redraw()

func ping() -> void:
	_ping_at = _now()

func is_echo_hot() -> bool:
	return _live and _ping_at > 0.0 and absf(_now() - (_ping_at + ECHO_DELAY)) <= ECHO_WINDOW

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var time := _now()
	var echo := -1.0
	if _live and _ping_at > 0.0 and time < _ping_at + ECHO_DELAY + ECHO_WINDOW:
		echo = clampf((time - _ping_at) / ECHO_DELAY, 0.0, 1.0)
	Press.draw_live_groove(self, {"live": _live, "hot": is_echo_hot(), "echo": echo})
