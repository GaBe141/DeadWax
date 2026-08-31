extends RefCounted
## Which side of the pressing is face-up, and how much of it is left to play.
##
## Session-owned like progression, and owned by Main for the same reason: a
## room describes what it is on each side, but only Main decides which side the
## world is currently showing.
##
## A side has a runtime. The B-side plays down while you stand on it and rewinds
## while you are back on the A-side, so a flip is always a round trip you have
## to plan rather than a toggle you hold.

signal side_changed(side: int)
signal runtime_changed(remaining: float)
signal side_ended

enum Side { A, B }

const SIDE_RUNTIME := 12.0     # how long the B-side plays before the needle lifts
const REWIND_RATE := 0.6       # B-side runtime recovered per second on the A-side
const MIN_FLIP_RUNTIME := 2.5  # refuse a flip that would end almost immediately
const WARN_RUNTIME := 3.0      # the wow-and-flutter warning window

var side := Side.A
var runtime_left := SIDE_RUNTIME

func reset() -> void:
	side = Side.A
	runtime_left = SIDE_RUNTIME

func on_b_side() -> bool:
	return side == Side.B

## True when the pressing may be turned over right now. Carrying the Refrain is
## checked by the caller: this model holds world state, never permissions.
func can_flip() -> bool:
	return side == Side.B or runtime_left >= MIN_FLIP_RUNTIME

func flip() -> bool:
	if not can_flip():
		return false
	_set_side(Side.A if side == Side.B else Side.B)
	return true

## Plays the current side forward. Returns true when the needle lifted on its
## own, so Main can distinguish a forced return from a deliberate one.
func advance(delta: float) -> bool:
	var before := runtime_left
	if side == Side.B:
		runtime_left = maxf(runtime_left - delta, 0.0)
		if runtime_left <= 0.0:
			_emit_runtime(before)
			_set_side(Side.A)
			side_ended.emit()
			return true
	else:
		runtime_left = minf(runtime_left + delta * REWIND_RATE, SIDE_RUNTIME)
	_emit_runtime(before)
	return false

func runtime_ratio() -> float:
	return clampf(runtime_left / SIDE_RUNTIME, 0.0, 1.0)

func is_running_out() -> bool:
	return side == Side.B and runtime_left <= WARN_RUNTIME

func side_label(for_side: int = -1) -> String:
	var wanted := side if for_side < 0 else for_side
	return "B" if wanted == Side.B else "A"

## The air a room actually presents on this side. Rooms keep their authored
## A-side profile; the B-side is that pressing read from the other face.
func effective_density(authored_density: float) -> float:
	return authored_density if side == Side.A else 1.0 - authored_density

## Breaths follow the air, not the room's authored count: thick wax answers a
## strike wherever it is thick. The A-side keeps the room's authored value so
## nothing about the current prototype loop changes until the player flips.
func effective_air_strikes(authored_max: int, authored_density: float) -> int:
	if side == Side.A:
		return authored_max
	return 2 if effective_density(authored_density) > 0.0 else 0

func _set_side(next_side: int) -> void:
	if side == next_side:
		return
	side = next_side
	side_changed.emit(side)

func _emit_runtime(before: float) -> void:
	if not is_equal_approx(before, runtime_left):
		runtime_changed.emit(runtime_left)
