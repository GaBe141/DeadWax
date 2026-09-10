extends RefCounted
## Fixed light sources in the authored architecture. The room controller owns
## their nodes, pause behavior and outcome lookup; a profile only supplies data.
## Radius is the unstretched world-space reach. Pulse is a small relative
## amplitude; windows and every combat pool remain steady.

const DAYLIGHT := Color(0.92, 0.96, 1.0)
const PAPER_LIGHT := Color(1.0, 0.95, 0.84)
const BRASS_LIGHT := Color(1.0, 0.86, 0.64)
const LAMP_LIGHT := Color(1.0, 0.80, 0.59)
const WELL_LIGHT := Color(0.86, 0.90, 1.0)
const STAGE_LIGHT := Color(0.91, 0.93, 1.0)
const UNPLAYED_LIGHT := Color(0.84, 0.83, 1.0)
const COPPER_LIGHT := Color(1.0, 0.73, 0.55)

static func get_profile(room_id: StringName) -> Dictionary:
	match room_id:
		&"headshell":
			return _profile(Color(0.84, 0.82, 0.78), [
				# The tall window and the small hanging brass eye already exist.
				_light(&"label_window", Vector2(1195, 320), 470, Vector2(0.92, 1.15), PAPER_LIGHT, 0.34),
				_light(&"cradle_eye", Vector2(590, 290), 360, Vector2(1.0, 1.15), BRASS_LIGHT, 0.26, false, 0.0, true),
			])
		&"horn_plaza":
			return _profile(Color(0.82, 0.83, 0.81), [
				_light(&"west_arcade", Vector2(255, 285), 450, Vector2(1.05, 1.05), DAYLIGHT, 0.28),
				_light(&"horn_reflection", Vector2(810, 290), 470, Vector2(1.15, 1.15), PAPER_LIGHT, 0.32),
				_light(&"market_daylight", Vector2(1510, 310), 450, Vector2(1.10, 1.05), DAYLIGHT, 0.28),
			])
		&"high_street":
			return _profile(Color(0.79, 0.79, 0.77), [
				_light(&"west_eaves", Vector2(365, 290), 450, Vector2(1.10, 1.15), BRASS_LIGHT, 0.31, true),
				_light(&"roof_gap", Vector2(1040, 230), 510, Vector2(1.25, 1.10), DAYLIGHT, 0.33),
				_light(&"east_eaves", Vector2(1690, 275), 450, Vector2(1.10, 1.15), BRASS_LIGHT, 0.31, true),
			])
		&"practice_room":
			return _profile(Color(0.81, 0.80, 0.77), [
				_light(&"lesson_lamp", Vector2(380, 240), 480, Vector2(1.15, 1.30), PAPER_LIGHT, 0.33, true),
				_light(&"count_in_window", Vector2(1160, 325), 490, Vector2(1.10, 1.10), DAYLIGHT, 0.35),
			])
		&"the_stalls":
			return _profile(Color(0.78, 0.77, 0.73), [
				_light(&"west_awning", Vector2(430, 265), 470, Vector2(1.10, 1.20), LAMP_LIGHT, 0.34, true),
				# The uncovered service lane must read as clearly as the upper walk.
				_light(&"service_daylight", Vector2(1040, 615), 540, Vector2(1.35, 0.80), DAYLIGHT, 0.29),
				_light(&"east_awning", Vector2(1830, 240), 470, Vector2(1.15, 1.15), LAMP_LIGHT, 0.34, true),
			])
		&"groove_yard":
			return _profile(Color(0.77, 0.79, 0.80), [
				_light(&"west_open_sky", Vector2(380, 300), 440, Vector2(1.10, 1.10), DAYLIGHT, 0.27),
				_light(&"worn_names", Vector2(1080, 290), 480, Vector2(1.15, 1.10), PAPER_LIGHT, 0.28),
				_light(&"east_open_sky", Vector2(1750, 315), 440, Vector2(1.10, 1.10), DAYLIGHT, 0.27),
			])
		&"label_descent":
			return _profile(Color(0.75, 0.76, 0.76), [
				_light(&"last_street_lamp", Vector2(320, 285), 440, Vector2(1.05, 1.20), BRASS_LIGHT, 0.32, true),
				_light(&"gate_oculus", Vector2(1130, 280), 540, Vector2(1.0, 1.20), DAYLIGHT, 0.38),
			])
		&"overture_stair":
			return _profile(Color(0.75, 0.71, 0.69), [
				_light(&"label_spill", Vector2(260, 220), 430, Vector2(1.10, 1.10), DAYLIGHT, 0.31),
				_light(&"cut_wall_lamp", Vector2(920, 450), 490, Vector2(0.95, 1.30), BRASS_LIGHT, 0.33, true),
				_light(&"lower_arch_lamp", Vector2(1530, 630), 440, Vector2(1.0, 1.15), LAMP_LIGHT, 0.34, true),
			])
		&"bootlegger":
			return _profile(Color(0.74, 0.70, 0.66), [
				# Match the printed shade; do not hang a second fixture over it.
				_light(&"counter_shade", Vector2(765, 118), 550, Vector2(1.10, 1.50), LAMP_LIGHT, 0.40, false, 0.015, true),
				_light(&"west_recess", Vector2(190, 360), 330, Vector2(0.90, 1.0), PAPER_LIGHT, 0.25),
				_light(&"stair_spill", Vector2(1470, 350), 370, Vector2(0.95, 1.0), DAYLIGHT, 0.27),
			])
		&"whistlers":
			return _profile(Color(0.70, 0.71, 0.74), [
				# Open channels light both banks, the launch islands and the catch lane.
				_light(&"west_split", Vector2(360, 320), 460, Vector2(0.85, 1.30), DAYLIGHT, 0.32),
				_light(&"upper_splits", Vector2(1250, 350), 530, Vector2(1.35, 1.05), WELL_LIGHT, 0.35),
				_light(&"east_split", Vector2(2200, 350), 480, Vector2(0.90, 1.25), DAYLIGHT, 0.33),
				_light(&"lower_reflection", Vector2(1300, 765), 550, Vector2(1.50, 0.65), PAPER_LIGHT, 0.25),
			])
		&"addie":
			var sconce := _light(&"doorway_sconce", Vector2(1216, 342), 400, Vector2(1.0, 1.15), LAMP_LIGHT, 0.30, false, 0.012, true)
			sconce["outcome_key"] = "addie/addie"
			sconce["freed_energy"] = 0.34
			sconce["shattered_energy"] = 0.25
			return _profile(Color(0.75, 0.71, 0.67), [
				_light(&"doorway_spill", Vector2(855, 295), 460, Vector2(0.95, 1.25), BRASS_LIGHT, 0.32),
				sconce,
				_light(&"well_passage", Vector2(200, 355), 350, Vector2(1.0, 1.05), DAYLIGHT, 0.26),
			])
		&"overture_well":
			return _profile(Color(0.66, 0.67, 0.71), [
				# Overlapping reaches follow the whole return climb, not just its mouth.
				_light(&"well_mouth", Vector2(360, 225), 490, Vector2(1.25, 1.10), DAYLIGHT, 0.37),
				_light(&"shaft_sconce", Vector2(1030, 680), 530, Vector2(1.35, 1.15), WELL_LIGHT, 0.39, true),
				_light(&"bottom_lamp", Vector2(480, 1210), 550, Vector2(1.35, 0.90), BRASS_LIGHT, 0.38, true),
			])
		&"worn_gallery":
			return _profile(Color(0.70, 0.68, 0.68), [
				_light(&"west_portraits", Vector2(300, 285), 430, Vector2(1.0, 1.20), BRASS_LIGHT, 0.30, true),
				_light(&"clerestory", Vector2(960, 225), 480, Vector2(1.15, 1.20), DAYLIGHT, 0.33),
				_light(&"service_arch", Vector2(1740, 330), 450, Vector2(1.15, 1.10), BRASS_LIGHT, 0.31, true),
				_light(&"hush_spill", Vector2(2350, 345), 390, Vector2(1.0, 1.0), STAGE_LIGHT, 0.29),
			])
		&"smoothed_floor":
			return _profile(Color(0.72, 0.73, 0.76), [
				# Nothing here pulses against HUSH's three counted beats.
				_light(&"hush_stage", Vector2(1100, 270), 550, Vector2(1.40, 1.10), STAGE_LIGHT, 0.42),
				_light(&"west_stage_lamp", Vector2(320, 340), 400, Vector2(1.0, 1.10), STAGE_LIGHT, 0.27, true),
				_light(&"east_stage_lamp", Vector2(1860, 340), 400, Vector2(1.0, 1.10), STAGE_LIGHT, 0.27, true),
			])
		&"the_arm":
			var focus := _light(&"tonearm_overhead", Vector2(1255, 235), 550, Vector2(1.0, 1.25), BRASS_LIGHT, 0.40)
			focus["outcome_key"] = "the_arm/tonearm"
			focus["freed_energy"] = 0.44
			focus["shattered_energy"] = 0.36
			return _profile(Color(0.68, 0.65, 0.67), [
				focus,
				_light(&"spindle_reflection", Vector2(650, 320), 460, Vector2(1.20, 1.10), WELL_LIGHT, 0.29),
				_light(&"return_arch_lamp", Vector2(1890, 360), 400, Vector2(1.0, 1.10), LAMP_LIGHT, 0.30, true),
			])
		&"the_drop":
			return _profile(Color(0.67, 0.62, 0.71), [
				# Four pools follow the full descent and its reversible stair. Lamp
				# origins are clear of the alternating real platforms and top pier.
				_light(&"scar_mouth", Vector2(320, 130), 470, Vector2(1.20, 1.05), PAPER_LIGHT, 0.35),
				_light(&"torn_copper", Vector2(1140, 620), 540, Vector2(1.10, 1.25), COPPER_LIGHT, 0.38, true),
				_light(&"return_glimmer", Vector2(430, 1040), 520, Vector2(1.10, 1.25), UNPLAYED_LIGHT, 0.36, true),
				_light(&"lower_wound", Vector2(1270, 1150), 480, Vector2(1.10, 1.05), COPPER_LIGHT, 0.34),
			])
		&"the_landing":
			return _profile(Color(0.73, 0.68, 0.76), [
				_light(&"west_reflection", Vector2(340, 340), 460, Vector2(1.10, 1.10), UNPLAYED_LIGHT, 0.31),
				_light(&"dormant_spindle", Vector2(980, 205), 540, Vector2(1.20, 1.10), COPPER_LIGHT, 0.37),
				_light(&"verse_sconce", Vector2(1580, 335), 450, Vector2(1.10, 1.10), BRASS_LIGHT, 0.34, true),
			])
		&"verse_hall":
			return _profile(Color(0.69, 0.66, 0.75), [
				_light(&"first_written_arch", Vector2(340, 380), 440, Vector2(1.10, 1.15), COPPER_LIGHT, 0.32, true),
				_light(&"high_verse", Vector2(920, 295), 500, Vector2(1.15, 1.15), UNPLAYED_LIGHT, 0.35),
				_light(&"answer_arch", Vector2(1560, 335), 500, Vector2(1.10, 1.20), BRASS_LIGHT, 0.34, true),
				_light(&"warren_spill", Vector2(2160, 390), 450, Vector2(1.10, 1.10), UNPLAYED_LIGHT, 0.31),
			])
		&"verse_warren_n":
			return _profile(Color(0.69, 0.65, 0.73), [
				_light(&"upper_west_burrow", Vector2(300, 210), 420, Vector2(1.10, 1.10), COPPER_LIGHT, 0.33, true),
				_light(&"upper_east_burrow", Vector2(1450, 245), 440, Vector2(1.10, 1.10), BRASS_LIGHT, 0.32, true),
				_light(&"lower_gathering", Vector2(660, 705), 490, Vector2(1.20, 0.95), UNPLAYED_LIGHT, 0.35),
				_light(&"lower_way", Vector2(1190, 720), 430, Vector2(1.10, 1.0), COPPER_LIGHT, 0.32, true),
			])
		&"verse_warren_s":
			return _profile(Color(0.69, 0.64, 0.71), [
				_light(&"west_record_house", Vector2(300, 460), 450, Vector2(1.10, 1.10), BRASS_LIGHT, 0.33, true),
				# The pressing's centre stays steady: scenery never adds a false
				# pulse to the encounter's own count and swing presentation.
				_light(&"quiet_bar", Vector2(910, 350), 550, Vector2(1.20, 1.20), UNPLAYED_LIGHT, 0.38),
				_light(&"gallery_sconce", Vector2(1550, 485), 460, Vector2(1.05, 1.15), COPPER_LIGHT, 0.34, true),
			])
		&"deep_gallery":
			return _profile(Color(0.67, 0.65, 0.75), [
				_light(&"unheard_duet", Vector2(500, 575), 520, Vector2(1.20, 1.15), COPPER_LIGHT, 0.37),
				_light(&"closed_score", Vector2(910, 425), 500, Vector2(1.10, 1.20), UNPLAYED_LIGHT, 0.35),
				_light(&"upper_gallery", Vector2(1660, 300), 410, Vector2(1.10, 1.05), BRASS_LIGHT, 0.32, true),
				_light(&"lower_gallery", Vector2(1500, 695), 450, Vector2(1.10, 1.0), UNPLAYED_LIGHT, 0.32, true),
			])
	return _profile(Color.WHITE, [])

static func _profile(ambient: Color, lights: Array) -> Dictionary:
	# Fresh dictionaries keep controller adjustments out of later room visits.
	# Cool reflected fill preserves brush colour between the warm local lamps.
	# Unknown/development identities remain neutral white with no light rig.
	var fill := ambient.lerp(Color(0.95, 0.97, 1.0), 0.35) if not lights.is_empty() else ambient
	return {"ambient": fill, "lights": lights}

static func _light(id: StringName, position: Vector2, radius: float, stretch: Vector2, color: Color, energy: float, fixture: bool = false, pulse: float = 0.0, glow: bool = false) -> Dictionary:
	return {"id": id, "position": position, "radius": radius, "stretch": stretch,
		"color": color, "energy": energy, "fixture": fixture, "pulse": pulse, "glow": fixture or glow}
