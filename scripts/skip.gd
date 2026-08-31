extends CharacterBody2D
## SKIP — Dead Wax M1 player. (working name; the world calls you the Player)
## You are a stylus with legs. Jumps are stubby on purpose; the STRIKE does
## the flying. HOOD UP (hold) is silence. Every constant is a tuning knob.

signal struck(pos: Vector2, big: bool, launched: bool)
signal on_beat
signal took_hit

const ProgressionScript := preload("res://scripts/progression_state.gd")

# -- RUN / JUMP (the honest legs) --------------------------------------------
const RUN_SPEED := 340.0
const RUN_ACCEL := 2600.0
const RUN_FRICTION := 3800.0
const AIR_CONTROL := 0.45          # M2: trimmed from 0.55 — grounded feels planted
const JUMP_VELOCITY := -640.0
const JUMP_CUT := 0.45
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12
const HOOD_SPEED_MULT := 0.62      # hooded = slower, softer

# -- WEIGHT -------------------------------------------------------------------
const GRAVITY := 1650.0
const FALL_MULT := 1.35
const MAX_FALL := 1150.0

# -- STRIKE (the whole game) --------------------------------------------------
const STRIKE_RADIUS := 190.0       # how far your point reaches a live groove
const STRIKE_COOLDOWN := 0.20
const STRIKE_RECOVER := 0.16       # M2: real recovery — the swing commits (weight)
const STRIKE_RECOVER_ACCEL := 0.35 # movement damped mid-recovery so a swing feels planted
const GROOVE_IMPULSE := 900.0
const GROOVE_KEEP := 0.25
const AIR_IMPULSE := 620.0         # thick-air jet (below the Scratch only)
const AIR_KEEP := 0.30
const BEAT_MULT := 1.55            # ON BEAT bonus multiplier
const GATHER_AIR_STRIKES := 1      # one held breath follows you into dry rooms

# -- POGO (flow: combat feeds platforming) ------------------------------------
const POGO_RANGE := 120.0          # match enemy hit reach: every pogo is a confirmed strike
const POGO_IMPULSE := 820.0        # recoil off a struck enemy
const POGO_UP_BIAS := 1.2          # bounces bias upward — keep the pendulum airborne
const POGO_KEEP := 0.40            # carry more momentum through a bounce than off a groove

# -- NOISE (crackle: the aggro economy) ---------------------------------------
const NOISE_DECAY := 1.4
const NOISE_DECAY_HOODED := 5.0    # hood swallows your crackle fast

# -- air profile: the ROOM sets these -----------------------------------------
var air_density := 0.0             # 0 = spent wax above the Scratch, 1 = thick
var gravity_mult := 1.0
var fall_cap_mult := 1.0
var groove_mult := 1.0
var air_strikes_max := 0           # room-provided baseline; progression derives capacity
var progression: RefCounted

# -- state --------------------------------------------------------------------
var air_strikes_left := 0
var noise := 0.0                   # crackle. loudness. the thing that hunts you.
var hooded := false
var setting := false               # SET: kneeling, defenseless, playing soft (mercy)
var facing := 1.0
var shine := 0                     # polish currency
var last_strike_ms := -100000      # parry checks read this
var _stagger := 0.0

var _coyote := 0.0
var _buffer := 0.0
var _strike_cd := 0.0
var _recover := 0.0
var _boil_t := 0.0
var _hit_flash := 0.0
var _shape_pts := PackedVector2Array()
var _jit := []

const INK := Color(0.13, 0.12, 0.11)
const IRON := Color(0.36, 0.35, 0.37)
const PALE := Color(0.92, 0.90, 0.85)
const PINK := Color(0.90, 0.25, 0.50)
const HOODGREY := Color(0.55, 0.52, 0.58)
const IRON_REVERSED := Color(0.62, 0.60, 0.63)

## Skip is inked to stay legible on whatever stock the room is printed on:
## the same figure, reversed out when the page goes dark.
var _body := IRON

func _ready() -> void:
	add_to_group("player")
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(34, 52)
	cs.shape = rect
	add_child(cs)
	_shape_pts = _teardrop()
	_jit.resize(_shape_pts.size())
	for i in _jit.size():
		_jit[i] = Vector2.ZERO
	z_index = 10

func air_strike_capacity() -> int:
	var capacity := air_strikes_max
	if _has_gather():
		capacity = maxi(capacity, GATHER_AIR_STRIKES)
	return capacity

func refill_air_strikes() -> void:
	air_strikes_left = air_strike_capacity()

func can_air_strike() -> bool:
	return air_density > 0.0 or _has_gather()

func _has_gather() -> bool:
	return (
		progression != null
		and bool(progression.call("has_refrain", ProgressionScript.Refrain.GATHER))
	)

func _physics_process(delta: float) -> void:
	hooded = Input.is_action_pressed("lift")
	setting = Input.is_action_pressed("set") and is_on_floor() and not hooded
	_stagger = maxf(_stagger - delta, 0.0)

	var dir := Input.get_axis("move_left", "move_right")
	if _stagger > 0.0 or setting:
		dir = 0.0
	if absf(dir) > 0.05:
		facing = signf(dir)
	var speed := RUN_SPEED * (HOOD_SPEED_MULT if hooded else 1.0)
	var accel := RUN_ACCEL if is_on_floor() else RUN_ACCEL * AIR_CONTROL
	if _recover > 0.0 and is_on_floor():
		accel *= STRIKE_RECOVER_ACCEL   # weight lives on the GROUND; the air stays free (flow)
	if absf(dir) > 0.01:
		velocity.x = move_toward(velocity.x, dir * speed, accel * delta)
	else:
		var fric := RUN_FRICTION if is_on_floor() else RUN_FRICTION * 0.2
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)

	var g := GRAVITY * gravity_mult
	if velocity.y > 0.0:
		g *= FALL_MULT
	velocity.y = minf(velocity.y + g * delta, MAX_FALL * fall_cap_mult)

	_coyote = COYOTE_TIME if is_on_floor() else _coyote - delta
	_buffer = JUMP_BUFFER if Input.is_action_just_pressed("jump") else _buffer - delta
	_strike_cd -= delta
	_recover = maxf(_recover - delta, 0.0)
	noise = maxf(noise - delta * (NOISE_DECAY_HOODED if hooded else NOISE_DECAY), 0.0)

	if is_on_floor():
		refill_air_strikes()

	if _buffer > 0.0 and _coyote > 0.0 and _stagger <= 0.0 and not setting:
		velocity.y = JUMP_VELOCITY
		_buffer = 0.0
		_coyote = 0.0
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# a raised point is silence: no striking while hooded
	if Input.is_action_just_pressed("strike") and _strike_cd <= 0.0 and not hooded and _stagger <= 0.0 and not setting:
		_strike()

	move_and_slide()

func _strike() -> void:
	_strike_cd = STRIKE_COOLDOWN
	_recover = STRIKE_RECOVER
	noise = 1.0
	last_strike_ms = Time.get_ticks_msec()
	var launched := false
	var big := false

	var best: Node2D = null
	var best_d := 999999.0
	for p in get_tree().get_nodes_in_group("live_groove"):
		var d: float = global_position.distance_to(p.global_position)
		if d <= STRIKE_RADIUS + p.reach() and d < best_d:
			best_d = d
			best = p

	# nearest pogoable enemy (flow: strike a foe to bounce off it)
	var foe: Node2D = null
	var foe_d := 999999.0
	for f in get_tree().get_nodes_in_group("strikable"):
		if f.has_method("is_pogoable") and not f.is_pogoable():
			continue
		var fd: float = global_position.distance_to(f.global_position)
		if fd <= POGO_RANGE and fd < foe_d:
			foe_d = fd
			foe = f

	if best != null:
		var away: Vector2 = (global_position - best.global_position).normalized()
		if away.length_squared() < 0.01:
			away = Vector2.UP
		var mult: float = groove_mult
		if best.is_echo_hot():
			mult *= BEAT_MULT
			big = true
			on_beat.emit()
		velocity = velocity * GROOVE_KEEP + away * GROOVE_IMPULSE * mult
		best.ping()
		refill_air_strikes()                   # a launch refuels your breaths (flow)
		launched = true
	elif foe != null:
		# POGO — recoil off the foe you struck; a room of enemies is a set of trampolines
		var pw: Vector2 = (global_position - foe.global_position).normalized()
		if pw.length_squared() < 0.01:
			pw = Vector2.UP
		var pdir := (pw + Vector2.UP * POGO_UP_BIAS).normalized()
		velocity = velocity * POGO_KEEP + pdir * POGO_IMPULSE
		refill_air_strikes()                   # bouncing off a foe refuels your breaths (flow)
		launched = true
	elif can_air_strike() and air_strikes_left > 0:
		# Gather holds one breath even when the pooled unplayed is far away.
		air_strikes_left -= 1
		var aim := Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)
		if aim.length_squared() < 0.01:
			aim = Vector2.UP
		aim = aim.normalized()
		velocity = velocity * AIR_KEEP + aim * AIR_IMPULSE
		launched = true

	struck.emit(global_position, big, launched)

func take_hit(from_pos: Vector2) -> void:
	var away := (global_position - from_pos).normalized()
	if away.length_squared() < 0.01:
		away = Vector2.UP
	velocity = away * 520.0 + Vector2(0, -260)
	_stagger = 0.28
	_hit_flash = 0.35
	noise = 1.0
	took_hit.emit()

# -- scratchy visuals: boil = crackle readout; hood = silhouette change -------

func _process(delta: float) -> void:
	_hit_flash = maxf(_hit_flash - delta, 0.0)
	_boil_t -= delta
	if _boil_t <= 0.0:
		_boil_t = 0.09
		var amp := 1.2 + noise * 4.0
		for i in _jit.size():
			_jit[i] = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
		queue_redraw()

func _draw() -> void:
	if hooded:
		# the 45-sleeve comes up: a cone, accents drained
		var hood := PackedVector2Array([
			Vector2(-24, 26), Vector2(0, -44), Vector2(24, 26), Vector2(-24, 26)
		])
		draw_colored_polygon(hood, Color(0.30, 0.28, 0.33))
		var outline := PackedVector2Array()
		for i in hood.size():
			outline.append(hood[i] + _jit[i % _jit.size()] * 0.5)
		draw_polyline(outline, HOODGREY, 3.0, true)
		draw_circle(Vector2(0, -12), 9.0, Color(0.08, 0.07, 0.09))
		draw_circle(Vector2(-3.0, -13.0), 1.6, HOODGREY)
		draw_circle(Vector2(3.5, -12.0), 1.6, HOODGREY)
		return
	var flash := _hit_flash > 0.0 and int(_hit_flash * 20.0) % 2 == 0
	draw_colored_polygon(_shape_pts, PALE if flash else _body)
	var outline := PackedVector2Array()
	for i in _shape_pts.size():
		outline.append(_shape_pts[i] + _jit[i])
	outline.append(_shape_pts[0] + _jit[0])
	draw_polyline(outline, INK, 3.0, true)
	draw_polyline(PackedVector2Array([Vector2(0, -34), Vector2(12, -43), Vector2(25, -39)]), INK, 2.5, true)
	# eyes
	draw_circle(Vector2(-5.0, 0.0), 2.6, PALE)
	draw_circle(Vector2(5.0, 0.0), 2.6, PALE)
	# pink accents ARE the crackle meter: glow with noise, drain when quiet
	if noise > 0.03:
		var pa := Color(PINK.r, PINK.g, PINK.b, clampf(noise, 0.0, 1.0))
		draw_circle(Vector2(-5.0, 0.0), 1.1, pa)
		draw_circle(Vector2(5.0, 0.0), 1.1, pa)
		draw_polyline(PackedVector2Array([Vector2(12, -43), Vector2(25, -39)]), pa, 2.0, true)
		draw_line(Vector2(facing * 8.0, 18.0), Vector2(facing * 15.0, 24.0), pa, 2.0)
	if setting:
		# SET: point lowered, playing soft — defenseless, listening
		draw_arc(Vector2(0, 20), 13.0, 0, TAU, 20, Color(PINK.r, PINK.g, PINK.b, 0.55), 2.0)
		draw_arc(Vector2(0, 20), 21.0, 0, TAU, 24, Color(PINK.r, PINK.g, PINK.b, 0.28), 2.0)
		draw_line(Vector2(facing * 6.0, 8.0), Vector2(facing * 11.0, 22.0), PINK, 2.5)

func _teardrop() -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, -34))
	for i in range(15):
		var t := lerpf(-0.55, 3.69, i / 14.0)
		pts.append(Vector2(0, 8) + Vector2(cos(t), sin(t)) * 19.0)
	return pts

func set_page(stock: Color) -> void:
	_body = IRON_REVERSED if stock.get_luminance() < 0.45 else IRON
	queue_redraw()
