extends RefCounted
## THE GROOVE — the room's beat while Groove pressure is on.
##
## Main owns one clock: it sets each room's period, advances it with the
## unpaused world and marks it live while something in the room is roused.
## Skip asks whether an executed strike landed in the pocket; counting foes
## ask when their next tick may fall so their tells land on the beat.
## The clock reads no input, plays no sound and owns no combat outcome. With
## the setting off nobody holds it, and every foe keeps its own count.

const DEFAULT_PERIOD := 0.42    # Tick's count: the Test Pressing's TICK_GAP
const POCKET_MS := 100.0        # half the pocket's width; never tighter than the 100 ms parry
const POCKET_LATENCY_MS := 40.0 # the pocket's centre sits this far after the beat: the heard
                                # pulse, the screen and the pad all reach the player late
const MIN_TICK_LEAD := 0.5      # a count's first tick never arrives sooner than half a beat
const MAX_STEP := 0.1           # a hitch delays the beat, like a foe's own clock; it never skips one

var period := DEFAULT_PERIOD
## Seconds of unpaused world time since the clock began. Rooms change the
## period, never the phase, so a passage cannot jerk the pocket.
var time := 0.0
## Main's per-frame judgement that something in the room is listening. Only a
## live groove judges strikes; a quiet room keeps time without pressure.
var live := false

## Changes tempo in place. The fraction of the current beat is preserved.
func set_period(next_period: float) -> void:
	var next := maxf(next_period, 0.05)
	if is_equal_approx(next, period):
		return
	time = time / period * next
	period = next

## Returns how many beats began during this step.
func advance(delta: float) -> int:
	if delta <= 0.0:
		return 0
	var before := beat_index()
	time += minf(delta, MAX_STEP)
	return beat_index() - before

func beat_index() -> int:
	return int(floor(time / period))

func since_beat() -> float:
	return maxf(time - float(beat_index()) * period, 0.0)

## Signed seconds to the nearest beat: negative is early, positive is late.
func offset() -> float:
	var into := since_beat()
	return into if into <= period * 0.5 else into - period

func in_pocket() -> bool:
	return absf(offset() * 1000.0 - POCKET_LATENCY_MS) <= POCKET_MS

## Seconds until the beat a newly started count should tick on.
func next_tick_wait() -> float:
	var wait := period - since_beat()
	if wait < period * MIN_TICK_LEAD:
		wait += period
	return wait

func snapshot() -> Dictionary:
	return {
		"period": period, "live": live, "beat": beat_index(),
		"phase": since_beat() / period, "offset": offset(), "in_pocket": in_pocket(),
	}
