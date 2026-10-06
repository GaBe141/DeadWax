extends CharacterBody2D
## SKIP — Dead Wax M1 player. (working name; the world calls you the Player)
## You are a stylus with legs. Jumps are stubby on purpose; the STRIKE does
## the flying. HOOD UP (hold) is silence. Every constant is a tuning knob.

signal struck(pos: Vector2, big: bool, launched: bool)
signal strike_input_rejected
signal on_beat
signal took_hit
signal shine_earned(amount: int)

const ProgressionScript := preload("res://scripts/progression_state.gd")
const PressScript := preload("res://scripts/press.gd")
const GestureScript := preload("res://scripts/press_skip_gesture.gd")

# -- RUN / JUMP (the honest legs) --------------------------------------------
const RUN_SPEED := 340.0
const RUN_ACCEL := 1900.0          # roughly eleven ticks to full speed at 60 Hz
const RUN_FRICTION := 2400.0       # a short coast; direction changes still bite
const SET_FRICTION := 3800.0       # kneeling plants the feet without the run coast
const AIR_ACCEL := 1170.0         # retain the existing airborne steering
const AIR_FRICTION := 760.0
const SHUFFLE_STEP := 1.0         # one pixel per fresh direction press until Walk
const AIR_CONTROL := AIR_ACCEL / RUN_ACCEL # ratio exposed to traversal fixtures
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
const STRIKE_BUFFER := 0.09       # a slightly early tap survives the end of recovery
const STRIKE_RECOVER := 0.10
const STRIKE_RECOVER_ACCEL := 0.80 # a little weight without trapping a change of direction
const ACCENT_COOLDOWN := 0.32     # the payoff leaves a short, deliberate follow-through
const ACCENT_RECOVER := 0.16
const ACCENT_RECOVER_ACCEL := 0.60
const COMBO_WINDOW := 0.65
const COMBO_LENGTH := 3
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
var abilities: RefCounted
var economy: RefCounted
## Main's room beat, held only while Groove pressure is on. A live groove
## decides which strikes hit big; without one the Accent keeps that role.
var groove: RefCounted
var hood_speed_mult := HOOD_SPEED_MULT
var warm_thread := false
## Optional equipment affects handling, never strike/parry clocks or jump height.
## Main installs the complete derived profile only after a saved transaction.
var equipment_speed := 1.0
var equipment_accel := 1.0
var equipment_friction := 1.0
var equipment_air_control := 1.0
var equipment_hood_speed := 1.0
var equipment_noise_decay := 1.0
## Saved level gains (xp_state.gd). Foes read these when Skip's strike or
## parry lands: Ring scales the resonance it builds, Bite the health it takes.
## They never touch reach, timing, launches, jumps or the parry window.
var resonance_mult := 1.0
var damage_mult := 1.0

# -- state --------------------------------------------------------------------
var air_strikes_left := 0
var noise := 0.0                   # crackle. loudness. the thing that hunts you.
var hooded := false
var setting := false               # SET: kneeling, defenseless, playing soft (mercy)
var facing := 1.0
var _loose_shine := 0
# Existing HUD and room code read the same wallet through Skip. Standalone
# mechanics rooms can still run without a campaign economy attached.
var shine: int:
	get:
		return int(economy.get("balance")) if economy != null else _loose_shine
	set(value):
		if economy != null:
			economy.call("restore", value, economy.call("snapshot").purchases)
		else:
			_loose_shine = clampi(value, 0, 2147483647)
var last_strike_ms := -100000      # parry checks read this
var last_strike_facing := 1.0      # executed input, independent of pose resets
var _stagger := 0.0

var _coyote := 0.0
var _buffer := 0.0
var _strike_cd := 0.0
var _strike_buffer := 0.0
var _recover := 0.0
var _hit_flash := 0.0
var combo_step := 0
var combo_remaining := 0.0
var free_combo_practice := false # only Main's disposable practice/development rooms
var executed_strike_step := 0
var last_strike_contact: StringName = &"miss"
## How a live groove judged the executed strike: &"pocket", &"flat", or empty
## when no groove was listening and the classic Accent rule applied.
var last_strike_groove: StringName = &""
var _strike_duration := STRIKE_COOLDOWN
var _recover_accel := STRIKE_RECOVER_ACCEL

# Presentation has its own clock and impulses. None feed back into movement,
# contact, strike cooldowns or the 100 ms combat clock.
const STRIDE_LENGTH := 112.0
const STRIKE_POSE_TIME := 0.22
const LAND_POSE_TIME := 0.24
const LAUNCH_POSE_TIME := 0.26
const CONTACT_POSE_TIME := 0.14
const HIT_HOLD_TIME := 0.035
const ACCENT_HOLD_TIME := 0.055
const PARRY_POSE_TIME := 0.24
const FLAT_POSE_TIME := 0.32      # an off-beat stroke's accent stays grey this long
var _print_time := 0.0
var _stride := 0.0
var _run_blend := 0.0
var _air_blend := 0.0
var _hood_blend := 0.0
var _set_blend := 0.0
var _look_face := 1.0
var _land_pose := 0.0
var _land_strength := 0.0
var _launch_pose := 0.0
var _strike_pose := 0.0
var _strike_big := false
var _strike_combo := 0
var _strike_face := 1.0
var _strike_pose_duration := STRIKE_POSE_TIME
var _strike_hold := 0.0
var _contact_pose := 0.0
var _parry_pose := 0.0
var _parry_face := 1.0
var _strike_launched := false
var _strike_pogo := false
var _flat_pose := 0.0
var _hit_direction := 1.0
var _animation_grounded := true

# Small moments. Main reports confirmed events (the Book closing, a find, a
# new level) and listening posts report a line; Skip only poses the drawn
# figure. Facing, velocity, collision and every combat clock stay put.
const BOOK_TIME := 0.95
const ITEM_TIME := 1.3
const NOD_TIME := 0.42
const ATTENTION_TIME := 4.0
const GLOW_TIME := 1.1
const TAP_PERIOD := 0.5           # the tapping foot's own count when no groove plays
const DUST_TIME := 0.45
const MAX_DUST := 24
const SKID_SPEED := 150.0
const SKID_GAP := 0.05
var _book_pose := 0.0
var _item_pose := 0.0
var _item_kind: StringName = &""
var _item_detail: StringName = &""
var _nod_pose := 0.0
var _attention := 0.0
var _attention_face := 1.0
var _listen_blend := 0.0
var _glow_pose := 0.0
var _idle_time := 0.0
var _dust: Array[Dictionary] = []
var _dust_count := 0
var _skid_clock := 0.0
var _takeoff_dust := false

const INK := Color(0.13, 0.12, 0.11)
const IRON := Color(0.36, 0.35, 0.37)
const PALE := Color(0.92, 0.90, 0.85)
const HOODGREY := Color(0.55, 0.52, 0.58)
const IRON_REVERSED := Color(0.62, 0.60, 0.63)
const DUST := Color(0.80, 0.72, 0.56)  # kicked-up wax: reads on dark and pale pages

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
	z_index = 10

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		cancel_pending_strike()

func cancel_pending_strike() -> void:
	_strike_buffer = 0.0
	combo_step = 0
	combo_remaining = 0.0

## Direction belongs to the executed stroke, even if Skip turns during its tail.
func executed_strike_facing() -> float:
	return last_strike_facing

func combo_snapshot() -> Dictionary:
	var label := ""
	if combo_step > 0:
		label = ["TAP", "SWEEP", "ACCENT"][combo_step - 1]
	var input_state := "ready"
	if not has_ability(&"strike"):
		input_state = "locked"
	elif hooded or setting or _stagger > 0.0:
		input_state = "blocked"
	elif _strike_buffer > 0.0:
		input_state = "queued"
	elif _strike_cd > STRIKE_BUFFER:
		input_state = "recover"
	elif _strike_cd > 0.0:
		input_state = "buffer"
	return {"step": combo_step, "remaining": combo_remaining, "window": COMBO_WINDOW, "label": label,
		"strike_unlocked": has_ability(&"strike"), "chain_unlocked": has_ability(&"combo"),
		"input_state": input_state, "queued": input_state == "queued",
		"cooldown_remaining": clampf(_strike_cd, 0.0, _strike_duration), "cooldown_duration": _strike_duration,
		"executed_step": executed_strike_step, "contact": last_strike_contact}

## Main supplies actual combat contact after every synchronous strike broadcast.
## An empty swing cannot bank a finisher in the campaign. The blank practice
## floor and standalone mechanics figures can still rehearse all three gestures.
func resolve_strike_contact(contact: StringName) -> void:
	last_strike_contact = contact if contact in [&"hit", &"guard", &"miss"] else &"miss"
	_contact_pose = CONTACT_POSE_TIME if last_strike_contact in [&"hit", &"guard"] else 0.0
	_strike_hold = (ACCENT_HOLD_TIME if _strike_combo == COMBO_LENGTH else HIT_HOLD_TIME) if last_strike_contact == &"hit" else 0.0
	if has_ability(&"combo") and not free_combo_practice and abilities != null and last_strike_contact != &"hit":
		combo_step = 0
		combo_remaining = 0.0

## A confirmed enemy catch supplies its origin even in disposable Echo Trials.
## Only the impression braces: the executed parry clock and body remain intact.
func present_parry(from_pos: Vector2) -> void:
	_clear_combat_impression()
	var toward := from_pos.x - global_position.x
	_parry_face = signf(toward) if absf(toward) > 0.01 else last_strike_facing
	_parry_pose = PARRY_POSE_TIME
	queue_redraw()

## Main calls this once play resumes after the Book closes: Skip snaps the
## small Book shut and tucks it into his coat.
func present_book_close() -> void:
	_item_pose = 0.0
	_book_pose = BOOK_TIME
	_idle_time = 0.0
	queue_redraw()

## A confirmed find (a move, a pressing, the map, a Refrain...) held overhead.
func present_item(kind: StringName, detail: StringName = &"") -> void:
	_book_pose = 0.0
	_item_pose = ITEM_TIME
	_item_kind = kind
	_item_detail = detail
	_idle_time = 0.0
	queue_redraw()

## A listening post or resident spoke a line: turn the drawn figure toward it
## and nod. `facing` (the strike direction) never changes.
func present_attention(from_pos: Vector2) -> void:
	var toward := from_pos.x - global_position.x
	_attention_face = signf(toward) if absf(toward) > 1.0 else (1.0 if _look_face >= 0.0 else -1.0)
	_attention = ATTENTION_TIME
	_nod_pose = NOD_TIME
	_idle_time = 0.0
	queue_redraw()

func present_level_up() -> void:
	_glow_pose = GLOW_TIME
	queue_redraw()

## Where the drawn small Book sits, in world space, for the closing Book.
func book_hand_position() -> Vector2:
	var face := 1.0 if _look_face >= 0.0 else -1.0
	return global_position + Vector2(GestureScript.BOOK_HAND.x * face, GestureScript.BOOK_HAND.y)

func dust_snapshot() -> Array[Dictionary]:
	return _dust.duplicate(true)

func _cancel_gestures() -> void:
	_book_pose = 0.0
	_item_pose = 0.0
	_nod_pose = 0.0
	_attention = 0.0
	_idle_time = 0.0

func _clear_combat_impression() -> void:
	_cancel_gestures()
	_strike_pose = 0.0
	_strike_big = false
	_strike_hold = 0.0
	_contact_pose = 0.0
	_parry_pose = 0.0
	_strike_launched = false
	_strike_pogo = false
	_flat_pose = 0.0

func add_shine(amount: int) -> bool:
	if amount <= 0 or amount > 2147483647 - shine:
		return false
	if economy != null:
		if not bool(economy.call("credit", amount)):
			return false
	else:
		_loose_shine += amount
	shine_earned.emit(amount)
	return true

func apply_equipment(profile: Dictionary) -> void:
	equipment_speed = float(profile.get("speed", 1.0))
	equipment_accel = float(profile.get("accel", 1.0))
	equipment_friction = float(profile.get("friction", 1.0))
	equipment_air_control = float(profile.get("air_control", 1.0))
	equipment_hood_speed = float(profile.get("hood_speed", 1.0))
	equipment_noise_decay = float(profile.get("noise_decay", 1.0))

## Main installs the complete level profile only after a saved choice.
func apply_growth(profile: Dictionary) -> void:
	resonance_mult = float(profile.get("resonance", 1.0))
	damage_mult = float(profile.get("damage", 1.0))

func air_strike_capacity() -> int:
	var capacity := air_strikes_max if has_ability(&"groove") else 0
	if _has_gather():
		capacity = maxi(capacity, GATHER_AIR_STRIKES)
	return capacity

func refill_air_strikes() -> void:
	air_strikes_left = air_strike_capacity()

func can_air_strike() -> bool:
	return has_ability(&"strike") and ((air_density > 0.0 and has_ability(&"groove")) or _has_gather())

## Standalone mechanics fixtures retain their complete moveset. The campaign
## always supplies Main's earned-ability model before play begins.
func has_ability(id: StringName) -> bool:
	return abilities == null or bool(abilities.call("has_ability", id))

func _has_gather() -> bool:
	return (
		progression != null
		and bool(progression.call("has_refrain", ProgressionScript.Refrain.GATHER))
	)

func _physics_process(delta: float) -> void:
	var grounded_before := is_on_floor()
	hooded = has_ability(&"hood") and Input.is_action_pressed("lift")
	setting = has_ability(&"set") and Input.is_action_pressed("set") and is_on_floor() and not hooded
	_stagger = maxf(_stagger - delta, 0.0)

	var dir := Input.get_axis("move_left", "move_right")
	if _stagger > 0.0 or setting:
		dir = 0.0
	if absf(dir) > 0.05:
		facing = signf(dir)
	if has_ability(&"walk"):
		var speed := RUN_SPEED * equipment_speed * (hood_speed_mult * equipment_hood_speed if hooded else 1.0)
		var accel := RUN_ACCEL * equipment_accel if is_on_floor() else AIR_ACCEL * equipment_air_control
		if _recover > 0.0 and is_on_floor():
			accel *= _recover_accel   # weight lives on the ground; the air stays free
		if absf(dir) > 0.01:
			velocity.x = move_toward(velocity.x, dir * speed, accel * delta)
		else:
			var ground_fric := SET_FRICTION if setting else RUN_FRICTION
			var fric := (ground_fric if is_on_floor() else AIR_FRICTION) * equipment_friction
			velocity.x = move_toward(velocity.x, 0.0, fric * delta)
	elif _stagger <= 0.0:
		# A held key/stick and key-repeat create no further travel, even in air.
		# Use the physics body's collision solver, with a fixed distance per tap
		# independent of frame rate or equipment. Damage retains its knockback.
		var edge := float(Input.is_action_just_pressed("move_right")) - float(Input.is_action_just_pressed("move_left"))
		velocity.x = signf(dir) * SHUFFLE_STEP / delta if delta > 0.0 and absf(dir) > 0.01 and edge * dir > 0.0 else 0.0

	var g := GRAVITY * gravity_mult
	if velocity.y > 0.0:
		g *= FALL_MULT
	velocity.y = minf(velocity.y + g * delta, MAX_FALL * fall_cap_mult)

	_coyote = COYOTE_TIME if is_on_floor() else _coyote - delta
	_buffer = JUMP_BUFFER if Input.is_action_just_pressed("jump") else _buffer - delta
	_strike_cd -= delta
	# A tap accepted in the final window survives the physics tick that crosses
	# zero. Cooldown and buffer expiring together must not drop a queued press.
	if _strike_cd > 0.0:
		_strike_buffer = maxf(_strike_buffer - delta, 0.0)
	combo_remaining = maxf(combo_remaining - delta, 0.0)
	if combo_remaining <= 0.0 and (has_ability(&"combo") or _strike_cd <= 0.0):
		combo_step = 0
	_recover = maxf(_recover - delta, 0.0)
	noise = maxf(noise - delta * (NOISE_DECAY_HOODED if hooded else NOISE_DECAY) * equipment_noise_decay, 0.0)

	if is_on_floor():
		refill_air_strikes()

	if _buffer > 0.0 and _coyote > 0.0 and _stagger <= 0.0 and not setting:
		_takeoff_dust = is_on_floor()
		velocity.y = JUMP_VELOCITY
		_launch_pose = LAUNCH_POSE_TIME
		_buffer = 0.0
		_coyote = 0.0
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# One fresh tap can wait briefly for cooldown. Silence, Set and damage
	# discard it; holding the button never starts a string of automatic hits.
	if not has_ability(&"strike") or hooded or _stagger > 0.0 or setting:
		cancel_pending_strike()
	else:
		if Input.is_action_just_pressed("strike"):
			if _strike_cd <= STRIKE_BUFFER:
				_strike_buffer = STRIKE_BUFFER
			else:
				strike_input_rejected.emit()
		if _strike_buffer > 0.0 and _strike_cd <= 0.0:
			_strike()

	var landing_speed := velocity.y
	move_and_slide()
	_animation_grounded = is_on_floor()
	if not grounded_before and _animation_grounded and landing_speed > 80.0:
		_land_pose = LAND_POSE_TIME
		_land_strength = clampf(landing_speed / 950.0, 0.25, 1.0)

func _strike() -> void:
	if not has_ability(&"strike"):
		cancel_pending_strike()
		return
	_clear_combat_impression()
	# Consume only this input edge. Public cancellation also clears the chain,
	# but an executed strike must carry its place into the next fresh press.
	_strike_buffer = 0.0
	combo_step = combo_step % COMBO_LENGTH + 1 if has_ability(&"combo") else 1
	combo_remaining = COMBO_WINDOW if has_ability(&"combo") else 0.0
	executed_strike_step = combo_step
	_strike_combo = combo_step
	_strike_face = facing
	_strike_duration = ACCENT_COOLDOWN if combo_step == COMBO_LENGTH else STRIKE_COOLDOWN
	_strike_cd = _strike_duration
	_recover = ACCENT_RECOVER if combo_step == COMBO_LENGTH else STRIKE_RECOVER
	_recover_accel = ACCENT_RECOVER_ACCEL if combo_step == COMBO_LENGTH else STRIKE_RECOVER_ACCEL
	_strike_pose_duration = [0.18, 0.24, 0.34][combo_step - 1]
	last_strike_contact = &"pending"
	noise = 1.0
	last_strike_ms = Time.get_ticks_msec()
	last_strike_facing = facing
	var launched := false
	var big := false
	var thick_air := air_density > 0.0 and has_ability(&"groove")

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

	if best != null and has_ability(&"groove"):
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
	elif foe != null and (has_ability(&"pogo") or (is_on_floor() and velocity.y >= 0.0)):
		# A grounded hit keeps the player's footing. Jumping into the same
		# strike still rebounds: floor contact updates after move_and_slide.
		if has_ability(&"pogo") and (not is_on_floor() or velocity.y < 0.0):
			_strike_pogo = true
			var pw: Vector2 = (global_position - foe.global_position).normalized()
			if pw.length_squared() < 0.01:
				pw = Vector2.UP
			var pdir := (pw + Vector2.UP * POGO_UP_BIAS).normalized()
			velocity = velocity * POGO_KEEP + pdir * POGO_IMPULSE
			refill_air_strikes()
			launched = true
	elif can_air_strike() and air_strikes_left > 0 and (thick_air or not is_on_floor() or velocity.y < 0.0):
		# Gather follows a jump into dry air; it never turns a grounded jab
		# into a launch. The room's own thick air still lifts from the floor.
		air_strikes_left -= 1
		# The carried breath lifts even while steering across a gap. Only
		# the room's pooled thick air uses directional jet aiming.
		var aim := Vector2.UP
		if thick_air:
			aim = Vector2(
				Input.get_axis("move_left", "move_right"),
				Input.get_axis("move_up", "move_down")
			)
			if aim.length_squared() < 0.01:
				aim = Vector2.UP
			aim = aim.normalized()
		velocity = velocity * AIR_KEEP + aim * AIR_IMPULSE
		launched = true

	# The accent strengthens the existing hit only after traversal resolves.
	# A hot groove can already be big; it receives no second beat or impulse.
	# While a live groove is listening, landing in its pocket is what hits big:
	# the Accent keeps its gesture and follow-through but must find the beat.
	# Launches, reach, breaths and the parry clock never read the beat.
	if groove != null and bool(groove.get("live")):
		var pocket := bool(groove.call("in_pocket"))
		if pocket:
			last_strike_groove = &"pocket"
		elif big:
			last_strike_groove = &"" # a hot groove's own echo already answered
		else:
			last_strike_groove = &"flat"
		big = big or pocket
		_flat_pose = FLAT_POSE_TIME if last_strike_groove == &"flat" else 0.0
	else:
		last_strike_groove = &""
		big = big or combo_step == COMBO_LENGTH
	_strike_pose = _strike_pose_duration
	_strike_big = big
	_strike_launched = launched
	_look_face = facing
	if launched:
		_launch_pose = LAUNCH_POSE_TIME
	struck.emit(global_position, big, launched)
	if last_strike_contact == &"pending":
		resolve_strike_contact(&"miss")

func take_hit(from_pos: Vector2) -> void:
	cancel_pending_strike()
	_clear_combat_impression()
	var away := (global_position - from_pos).normalized()
	if away.length_squared() < 0.01:
		away = Vector2.UP
	velocity = away * 520.0 + Vector2(0, -260)
	_stagger = 0.28
	_hit_flash = 0.35
	_hit_direction = signf(away.x) if absf(away.x) > 0.01 else -facing
	noise = 1.0
	took_hit.emit()

# -- the animated impression -------------------------------------------------

func _process(delta: float) -> void:
	var step := minf(delta, 0.1)
	_print_time += step
	_hit_flash = maxf(_hit_flash - delta, 0.0)
	_stride = fmod(_stride + absf(velocity.x) * step * TAU / STRIDE_LENGTH, TAU)
	var running := clampf(absf(velocity.x) / RUN_SPEED, 0.0, 1.0) if _animation_grounded else 0.0
	_run_blend = move_toward(_run_blend, running, step * 7.0)
	_air_blend = move_toward(_air_blend, 0.0 if _animation_grounded else 1.0, step * 10.0)
	_hood_blend = move_toward(_hood_blend, 1.0 if hooded else 0.0, step * 7.0)
	_set_blend = move_toward(_set_blend, 1.0 if setting else 0.0, step * 6.0)
	# While a speaker holds Skip's attention the drawn figure turns to it;
	# `facing` (the strike direction) is never touched.
	_look_face = lerpf(_look_face, _attention_face if _attention > 0.0 else facing, 1.0 - exp(-step * 18.0))
	_land_pose = maxf(_land_pose - step, 0.0)
	_launch_pose = maxf(_launch_pose - step, 0.0)
	# A few held draw frames make actual contact readable without hitstop,
	# gameplay delay, or a suspended parry/physics clock.
	var held := minf(step, _strike_hold)
	_strike_hold = maxf(_strike_hold - step, 0.0)
	_strike_pose = maxf(_strike_pose - (step - held), 0.0)
	_contact_pose = maxf(_contact_pose - step, 0.0)
	_parry_pose = maxf(_parry_pose - step, 0.0)
	_flat_pose = maxf(_flat_pose - step, 0.0)
	_advance_gestures(step)
	_advance_footwork(step)
	queue_redraw()

func _advance_gestures(step: float) -> void:
	# Hood and Set fold a held gesture away quickly; moving lowers a raised find.
	var busy := 4.0 if hooded or setting else 1.0
	_book_pose = maxf(_book_pose - step * busy, 0.0)
	_item_pose = maxf(_item_pose - step * maxf(busy, 1.0 + _run_blend * 2.0 + _air_blend), 0.0)
	_nod_pose = maxf(_nod_pose - step, 0.0)
	_glow_pose = maxf(_glow_pose - step, 0.0)
	if absf(velocity.x) > 30.0 or not _animation_grounded or hooded or setting:
		_attention = 0.0
	_attention = maxf(_attention - step, 0.0)
	_listen_blend = move_toward(_listen_blend, 1.0 if _attention > 0.0 else 0.0, step * 6.0)
	var still := (_animation_grounded and absf(velocity.x) < 4.0 and not hooded and not setting
		and _strike_pose <= 0.0 and _hit_flash <= 0.0 and _parry_pose <= 0.0 and _land_pose <= 0.0
		and _book_pose <= 0.0 and _item_pose <= 0.0 and _attention <= 0.0)
	_idle_time = _idle_time + step if still else 0.0

func _advance_footwork(step: float) -> void:
	for index in range(_dust.size() - 1, -1, -1):
		var puff := _dust[index]
		puff.age = float(puff.age) + step / DUST_TIME
		var drift: Vector2 = puff.velocity
		puff.at = Vector2(puff.at) + drift * step
		puff.velocity = drift * exp(-step * 6.0) + Vector2(0, -14.0 * step)
		if float(puff.age) >= 1.0:
			_dust.remove_at(index)
	if _takeoff_dust:
		_takeoff_dust = false
		for side in [-1.0, 1.0]:
			_kick_dust(global_position + Vector2(side * 11.0, 25.0), Vector2(side * 75.0 - velocity.x * 0.08, -14.0), 1.1)
		_kick_dust(global_position + Vector2(0, 26.0), Vector2(-velocity.x * 0.05, -6.0), 0.8)
	# Turning hard plants the leading foot; it kicks up a short skid.
	var skidding := (_animation_grounded and absf(velocity.x) > SKID_SPEED and signf(velocity.x) != signf(facing)
		and has_ability(&"walk"))
	if skidding:
		_skid_clock -= step
		if _skid_clock <= 0.0:
			_skid_clock = SKID_GAP
			var lead := signf(velocity.x)
			_kick_dust(global_position + Vector2(lead * 9.0, 25.0), Vector2(lead * 70.0, -26.0), 0.9)
	else:
		_skid_clock = 0.0

func _kick_dust(at: Vector2, drift: Vector2, size: float) -> void:
	_dust_count += 1
	var jitter := Vector2(sin(_dust_count * 12.9898), cos(_dust_count * 78.233)) * 0.5
	_dust.append({"at": at + jitter * 3.0, "velocity": drift + jitter * 20.0, "age": 0.0,
		"size": size * (1.0 + jitter.x * 0.3)})
	while _dust.size() > MAX_DUST:
		_dust.remove_at(0)

func _tap_phase() -> float:
	if groove != null and bool(groove.get("live")):
		var period := maxf(float(groove.get("period")), 0.05)
		return clampf(float(groove.call("since_beat")) / period, 0.0, 1.0)
	return fmod(_idle_time, TAP_PERIOD) / TAP_PERIOD

func _draw() -> void:
	PressScript.draw_skip(self, _animation_pose(), {
		"ink": INK, "body": _body, "pale": PALE, "pink": PressScript.PINK, "hood": HOODGREY,
		"warm_thread": warm_thread,
	})
	# Dust stays where it was kicked up, in front of the feet that raised it.
	if not _dust.is_empty():
		var puffs: Array[Dictionary] = []
		for puff in _dust:
			puffs.append({"at": Vector2(puff.at) - global_position, "age": puff.age, "size": puff.size})
		PressScript.draw_skip_dust(self, puffs, DUST)

func _animation_pose() -> Dictionary:
	return {
		"time": _print_time, "stride": _stride, "run": _run_blend,
		"air": _air_blend, "vertical": clampf(velocity.y / 950.0, -1.0, 1.0),
		"hood": _hood_blend, "set": _set_blend, "face": _look_face,
		"land": _land_pose / LAND_POSE_TIME, "impact": _land_strength,
		"launch": _launch_pose / LAUNCH_POSE_TIME,
		"strike": _strike_pose / _strike_pose_duration, "big": _strike_big,
		"combo_step": _strike_combo, "strike_face": _strike_face, "strike_contact": last_strike_contact,
		"strike_hold": _strike_hold / ACCENT_HOLD_TIME, "contact_pulse": _contact_pose / CONTACT_POSE_TIME,
		"parry": _parry_pose / PARRY_POSE_TIME, "parry_face": _parry_face,
		"queued": 1.0 if _strike_buffer > 0.0 else 0.0,
		"strike_launched": _strike_launched, "strike_pogo": _strike_pogo,
		"hurt": _hit_flash / 0.35, "hit_direction": _hit_direction, "noise": noise,
		"flat": _flat_pose / FLAT_POSE_TIME,
		"book": _book_pose / BOOK_TIME, "item": _item_pose / ITEM_TIME,
		"item_kind": _item_kind, "item_detail": _item_detail,
		"nod": _nod_pose / NOD_TIME, "listen": _listen_blend, "glow": _glow_pose / GLOW_TIME,
		"idle": _idle_time, "beat": _tap_phase(),
	}

## Recovery and passages move the body instantly; the impression starts at rest
## instead of carrying an old fall, hit, or landing into the next room.
func reset_animation() -> void:
	_print_time = 0.0
	_stride = 0.0
	_run_blend = 0.0
	_air_blend = 0.0
	_hood_blend = 1.0 if hooded else 0.0
	_set_blend = 0.0
	_look_face = facing
	_land_pose = 0.0
	_land_strength = 0.0
	_launch_pose = 0.0
	_strike_combo = 0
	_strike_face = facing
	_clear_combat_impression()
	_parry_face = facing
	executed_strike_step = 0
	last_strike_contact = &"miss"
	last_strike_groove = &""
	_hit_flash = 0.0
	_animation_grounded = true
	_item_kind = &""
	_item_detail = &""
	_listen_blend = 0.0
	_glow_pose = 0.0
	_dust.clear()
	_skid_clock = 0.0
	_takeoff_dust = false
	queue_redraw()

func set_page(stock: Color) -> void:
	_body = IRON_REVERSED if stock.get_luminance() < 0.45 else IRON
	queue_redraw()
