extends Node2D
## THE AUDITIONER — the baseline Unplayed: not attacking, auditioning.
## It reaches for you. Contact hurts a little — being touched by the Player is
## the only time it has ever been heard. Two ways to end it:
##   FIGHT — strike / parry until it peaks and shatters (the fast, sad way).
##   FREE  — SET-play it for one bar: kneel close, hold [L], defenseless; it is
##           heard at last, and leaves. Freed stays freed. Shattered stays gone.
## The mercy is the design (ENEMIES.md #5). The B5 audit remembers which.

signal parried
signal shattered(pos: Vector2)
signal bout_won                    # unused here; kept so main's wiring stays uniform
signal freed(pos: Vector2)

const SENSE_RANGE := 460.0         # how near the Player must be to be reached-for
const SENSE_HOODED := 220.0        # a hooded Player is quieter, less noticed
const REACH_RANGE := 150.0         # the reach begins here
const CONTACT_RANGE := 120.0       # contact lands within this at the hum's peak
const MOVE_SPEED := 62.0           # slow, open-armed — never a chase
const REACH_WIND := 0.5            # the reach-hum swells this long before contact (the tell)

const PARRY_WINDOW_MS := 100       # matches Skip's M2 window
const STRIKE_HIT_RANGE := 120.0

const RES_HIT := 0.14
const RES_PARRY := 0.40
const RES_DECAY := 0.045

const HP_MAX := 4.0
const HP_PER_HIT := 1.0
const HP_PER_BIG := 1.6

const SET_RANGE := 175.0           # how near you must kneel to be heard
const SET_FREE_TIME := 1.2         # one bar of SET frees it
const STAGGER_TIME := 0.85
const RECOVER_TIME := 0.7
const BURST_TIME := 0.5            # shattered -> gone
const LEAVE_TIME := 1.1            # freed -> gone

enum S { CALM, PURSUE, REACH, STAGGER, RECOVER, FREED, DOWN }
var state: int = S.CALM
var resonance := 0.0
var hp := HP_MAX
var _set := 0.0                    # SET-mercy progress toward one bar
var _t := 0.0                      # state timer
var _reach_t := 0.0
var _face := -1.0
var _sid := 0
var _player: Node2D
var _boil := 0.0
var _jit := Vector2.ZERO

func _ready() -> void:
	add_to_group("hears_strikes")
	add_to_group("strikable")
	_sid = randi()
	z_index = 9

func is_pogoable() -> bool:
	return state != S.DOWN and state != S.FREED

func _bank() -> Node:
	return get_tree().get_first_node_in_group("audio_bank")

func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var d := global_position.distance_to(_player.global_position)
	_face = signf(_player.global_position.x - global_position.x)
	if _face == 0.0:
		_face = -1.0
	resonance = maxf(resonance - RES_DECAY * delta, 0.0)
	_t += delta

	# boil (~10fps), jittering harder as it rings toward shatter
	_boil -= delta
	if _boil <= 0.0:
		_boil = 0.1
		var amp := 1.4 + resonance * 2.0
		_jit = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))

	# SET-mercy: kneel near it and hold, and it is heard at last
	if state == S.CALM or state == S.PURSUE or state == S.REACH or state == S.STAGGER or state == S.RECOVER:
		if _is_player_setting() and d < SET_RANGE:
			_set += delta
			if _set >= SET_FREE_TIME:
				_free()
		else:
			_set = maxf(_set - delta * 1.5, 0.0)

	match state:
		S.CALM:
			var sense := SENSE_HOODED if _player.hooded else SENSE_RANGE
			if d < sense:
				_go(S.PURSUE)
		S.PURSUE:
			var sense2 := SENSE_HOODED if _player.hooded else SENSE_RANGE
			_creep(MOVE_SPEED, delta)
			if d > sense2 * 1.4:
				_go(S.CALM)
			elif d <= REACH_RANGE:
				_go(S.REACH)
				_reach_t = 0.0
				var b := _bank()
				if b != null:
					b.play("reach", -10.0)
		S.REACH:
			_creep(MOVE_SPEED * 0.35, delta)   # a slow lean, arms opening
			_reach_t += delta
			if _reach_t >= REACH_WIND:
				_resolve_reach(d)
		S.STAGGER:
			if _t >= STAGGER_TIME:
				_go(S.PURSUE)
		S.RECOVER:
			if _t >= RECOVER_TIME:
				_go(S.PURSUE)
		S.FREED:
			if _t >= LEAVE_TIME:
				queue_free()
		S.DOWN:
			if _t >= BURST_TIME:
				queue_free()
	queue_redraw()

func _go(s: int) -> void:
	state = s
	_t = 0.0

func _is_player_setting() -> bool:
	return _player != null and _player.get("setting") == true

func _creep(speed: float, delta: float) -> void:
	global_position.x = move_toward(global_position.x, _player.global_position.x, speed * delta)

func _resolve_reach(d: float) -> void:
	var b := _bank()
	if d <= CONTACT_RANGE:
		var since_strike: int = Time.get_ticks_msec() - _player.last_strike_ms
		if since_strike >= 0 and since_strike <= PARRY_WINDOW_MS:
			# RUNG BACK — its reach caught on your point and played back
			_gain(RES_PARRY)
			parried.emit()
			if b != null:
				b.play("parry", -3.0)
			if state != S.DOWN:
				_go(S.STAGGER)
			return
		# contact — it touches you, and hears itself for a second (it costs you)
		_player.take_hit(global_position)
		if b != null:
			b.play("thud", -6.0)
	_go(S.RECOVER)

func on_player_strike(pos: Vector2, big: bool) -> void:
	if state == S.DOWN or state == S.FREED:
		return
	if global_position.distance_to(pos) <= STRIKE_HIT_RANGE:
		_gain(RES_HIT * (1.6 if big else 1.0))
		if state == S.DOWN:
			return
		hp = maxf(hp - (HP_PER_BIG if big else HP_PER_HIT), 0.0)
		if hp <= 0.0:
			_down()
			return
		if state == S.REACH:
			# you struck the reaching arm — the reach breaks
			_go(S.STAGGER)

func _gain(amount: float) -> void:
	resonance += amount
	if resonance >= 1.0:
		_down()

func _down() -> void:
	state = S.DOWN
	_t = 0.0
	resonance = 0.0
	shattered.emit(global_position)
	var b := _bank()
	if b != null:
		b.play("shatter", -2.0)

func _free() -> void:
	state = S.FREED
	_t = 0.0
	resonance = 0.0
	freed.emit(global_position)
	var b := _bank()
	if b != null:
		b.play("freed", -6.0)

# -- scratchy visuals ---------------------------------------------------------

const INK := Color(0.15, 0.13, 0.14)
const BODY := Color(0.24, 0.21, 0.26)
const PALE := Color(0.92, 0.90, 0.86)
const PINK := Color(0.90, 0.25, 0.50)
const GREY := Color(0.55, 0.52, 0.58)
const WARM := Color(0.96, 0.80, 0.42)      # the "heard" glow

func _draw() -> void:
	var j := _jit
	var c := Vector2(0, -26) + j

	# freed — a calm figure, standing, fading warm
	if state == S.FREED:
		var a := clampf(1.0 - _t / LEAVE_TIME, 0.0, 1.0)
		draw_circle(Vector2(0, -28), 20.0, Color(WARM.r, WARM.g, WARM.b, 0.5 * a))
		draw_arc(Vector2(0, -28), 25.0, 0, TAU, 24, Color(WARM.r, WARM.g, WARM.b, a), 2.5)
		draw_line(Vector2(-9, 8), Vector2(-7, -18), Color(INK.r, INK.g, INK.b, a), 3.0)
		draw_line(Vector2(9, 8), Vector2(7, -18), Color(INK.r, INK.g, INK.b, a), 3.0)
		return

	# shattered — bursting into the words it was mid-saying (main draws the splatter)
	if state == S.DOWN:
		var bb := clampf(1.0 - _t / BURST_TIME, 0.0, 1.0)
		draw_arc(c, 30.0 + (1.0 - bb) * 26.0, 0, TAU, 22, Color(PINK.r, PINK.g, PINK.b, bb), 3.0)
		return

	var reaching := state == S.REACH
	var accent := PINK if reaching else GREY

	# legs
	draw_line(Vector2(-9, 8), c + Vector2(-5, 4), INK, 3.0)
	draw_line(Vector2(9, 8), c + Vector2(5, 4), INK, 3.0)
	# body: a longing figure
	draw_circle(c, 22.0, BODY)
	draw_arc(c, 22.0, 0, TAU, 22, PALE, 2.5)

	# arms reach OUT as the hum swells — the visual half of the tell
	var ext := clampf(_reach_t / REACH_WIND, 0.0, 1.0) if reaching else 0.0
	draw_line(c, c + Vector2(_face * (16.0 + ext * 46.0), -6.0 - ext * 6.0), accent, 3.5)
	draw_line(c, c + Vector2(_face * (11.0 + ext * 22.0), 9.0 + ext * 8.0), accent, 3.0)

	# resonance rim (pink): posture / shatter meter
	if resonance > 0.01:
		draw_arc(c, 27.0, -PI / 2.0, -PI / 2.0 + TAU * resonance, 26, PINK, 4.0)

	# HP pips under it
	var total := int(round(HP_MAX))
	var remaining := int(ceil(hp))
	for i in range(total):
		var px := Vector2(-((total - 1) * 9.0) * 0.5 + i * 9.0, 22.0)
		var pip := PALE if i < remaining else Color(GREY.r, GREY.g, GREY.b, 0.4)
		draw_line(px + Vector2(0, -4), px + Vector2(0, 4), pip, 3.0)

	# the eye: open, longing; pink when reaching
	draw_circle(c + Vector2(_face * 5.0, -2.0), 3.4, PALE)
	draw_circle(c + Vector2(_face * 6.0, -2.0), 1.6, accent)

	# SET-mercy halo: fills warm as you kneel near — heard at last
	if _set > 0.01:
		var p := clampf(_set / SET_FREE_TIME, 0.0, 1.0)
		draw_arc(c, 34.0, -PI / 2.0, -PI / 2.0 + TAU * p, 28, Color(WARM.r, WARM.g, WARM.b, 0.9), 3.0)
