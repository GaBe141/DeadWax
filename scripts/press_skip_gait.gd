extends RefCounted
## Pure locomotion samples for Skip's impression: the stride, the lean into a
## run, the skid of a hard turn, the arc of a jump and the settle of a
## landing. Everything here deforms drawn wax only. The feet are planted on
## the collider's sole (y = 26) whenever they bear weight; nothing moves the
## node, the collider or a combat clock.

const SOLE := 26.0
const HIP_Y := 15.0
const HIP_X := 7.0
const STANCE_X := 8.0

## Sample the gait for one drawn frame.
##   stride   phase of the step cycle (radians; advances with ground speed)
##   run      ground-speed blend, 0 still .. 1 full run
##   face     drawn facing, -1 or 1
##   air      airborne blend; vertical = velocity.y / 950, negative rising
##   launch   take-off impulse, 1 at the jump .. 0
##   land     landing impulse, 1 at touchdown .. 0; impact its strength
##   accel    smoothed horizontal acceleration, -1 .. 1 (positive = forward)
##   skid     a hard turn: sliding against the facing, 0 .. 1
##   kneel    the Set blend
static func sample(pose: Dictionary) -> Dictionary:
	var stride := float(pose.get("stride", 0.0))
	var run := clampf(float(pose.get("run", 0.0)), 0.0, 1.0)
	var face := -1.0 if float(pose.get("face", 1.0)) < 0.0 else 1.0
	var air := clampf(float(pose.get("air", 0.0)), 0.0, 1.0)
	var vertical := clampf(float(pose.get("vertical", 0.0)), -1.0, 1.0)
	var launch := clampf(float(pose.get("launch", 0.0)), 0.0, 1.0)
	var land := clampf(float(pose.get("land", 0.0)), 0.0, 1.0)
	var impact := clampf(float(pose.get("impact", 0.0)), 0.0, 1.0)
	var accel := clampf(float(pose.get("accel", 0.0)), -1.0, 1.0)
	var skid := clampf(float(pose.get("skid", 0.0)), 0.0, 1.0)
	var kneel := clampf(float(pose.get("set", 0.0)), 0.0, 1.0)
	var rise := maxf(-vertical, 0.0) * air
	var fall := maxf(vertical, 0.0) * air
	var ground := 1.0 - air
	# A skid plants both feet; the step cycle fades out under it.
	var step := run * (1.0 - skid) * ground
	# Take-off is a short upward stretch; touchdown a squash that overshoots
	# once on its way back, so a hard landing reads as weight, not a stamp.
	var kick := sin(launch * PI) * (1.0 - land)
	var squash := sin(land * PI) * impact
	var settle := -sin(land * TAU) * impact * 0.22 * (1.0 - clampf(land * 2.0 - 1.0, 0.0, 1.0))
	# The body rises when both feet are off the ground mid-stride (a little
	# trot, not a stroll) and drops at each plant.
	var flight := pow(0.5 - 0.5 * cos(stride * 2.0), 0.7)
	var bob := -flight * (3.0 + 2.5 * run) * step
	bob -= kick * 2.0
	# Lean into acceleration and against a skid; a run leans a little anyway.
	var lean := face * (run * 0.12 * ground + accel * 0.16 * ground + skid * 0.24) - face * rise * 0.05 + face * fall * 0.04
	var stretch := Vector2(
		squash * 0.22 + settle * 0.5 - kick * 0.10 - rise * 0.07 + fall * 0.05 + kneel * 0.15,
		-squash * 0.22 - settle + kick * 0.16 + rise * 0.12 - fall * 0.04 - kneel * 0.30
	)
	stretch.y += cos(stride * 2.0) * step * 0.04
	var feet: Array[Vector2] = []
	var knees: Array[Vector2] = []
	var hips: Array[Vector2] = []
	for index in range(2):
		var side := -1.0 if index == 0 else 1.0
		var phase := stride + (PI if index == 0 else 0.0)
		# The foot moves forward (the facing direction) while it is lifted and
		# back along the ground while it bears weight.
		var swing := sin(phase)
		var lifted := maxf(cos(phase), 0.0)
		var lift := pow(lifted, 0.8) * (7.0 + 4.0 * run) * step
		var foot := Vector2(side * STANCE_X + face * swing * (9.0 + 5.0 * run) * step, SOLE - lift)
		# A skid spreads the feet and plants them; a landing splays them.
		foot.x += side * (skid * 6.0 + squash * 5.0)
		# Airborne: tuck up while rising, drop and reach forward to land.
		foot += Vector2(-face * rise * 4.0 + face * fall * 3.0, -rise * (6.0 + side * 2.0) + fall * 2.0 + kick * 4.0)
		var hip := Vector2(side * HIP_X, HIP_Y + kneel * 6.0)
		# The swinging knee comes up and forward; the planted leg stays long.
		var knee := hip.lerp(foot, 0.5) + Vector2(face * (lift * 0.35 + run * 2.0 * ground - skid * 3.0), -lift * 0.45 - rise * 3.0)
		feet.append(foot)
		knees.append(knee)
		hips.append(hip)
	# The free arm swings against the legs once Skip is really running; still,
	# it stays folded in the coat as before.
	var arm := clampf((run - 0.3) / 0.6, 0.0, 1.0) * ground * (1.0 - skid)
	var arm_swing := sin(stride) * arm
	var shoulder := Vector2(-face * 9.0, 0.0)
	var elbow := shoulder + Vector2(-face * (4.0 - arm_swing * 4.0), 9.0 - absf(arm_swing) * 2.0)
	var hand := elbow + Vector2(face * arm_swing * 10.0, 7.0 - arm_swing * 3.0)
	# The point sways against the stride and lifts with a jump.
	var point_sway := Vector2(-face * sin(stride) * 3.0 * step, cos(stride * 2.0) * 1.5 * step - rise * 5.0 + fall * 2.0 + kick * 3.0)
	# The scarf trails with speed, flaps with the stride and lifts in a fall.
	var scarf := {
		"drag": run * 6.0 * ground + skid * 4.0 + fall * 2.0,
		"lift": -rise * 2.0 + fall * 9.0 + kick * 3.0 - skid * 4.0,
		"flap": sin(stride * 2.0) * 2.0 * step,
	}
	return {
		"bob": bob, "lean": lean, "stretch": stretch, "feet": feet, "knees": knees, "hips": hips,
		"arm": arm, "shoulder": shoulder, "elbow": elbow, "hand": hand,
		"point_sway": point_sway, "scarf": scarf, "squash": squash, "settle": settle, "kick": kick,
		"rise": rise, "fall": fall, "step": step,
	}
