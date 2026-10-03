extends RefCounted
## Pure joint samples for Skip's combat impression. These values deform only
## drawn wax and brass; their explicit event weights never run combat clocks.

static func sample(pose: Dictionary) -> Dictionary:
	var face := -1.0 if float(pose.get("face", 1.0)) < 0.0 else 1.0
	var attack_face := -1.0 if float(pose.get("strike_face", face)) < 0.0 else 1.0
	var parry_face := -1.0 if float(pose.get("parry_face", face)) < 0.0 else 1.0
	var strike := clampf(float(pose.get("strike", 0.0)), 0.0, 1.0)
	var hold := clampf(float(pose.get("strike_hold", 0.0)), 0.0, 1.0)
	var contact := StringName(pose.get("strike_contact", &"miss"))
	var pulse := clampf(float(pose.get("contact_pulse", 0.0)), 0.0, 1.0)
	var hurt := clampf(float(pose.get("hurt", 0.0)), 0.0, 1.0)
	# A fresh hit bends the figure immediately. It settles quickly enough that
	# a newly permitted stroke still reads during the tail of the damage flash.
	var hurt_strength := hurt * hurt
	var parry := pow(clampf(float(pose.get("parry", 0.0)), 0.0, 1.0), 0.8) * (1.0 - hurt_strength)
	var snap := (1.0 if hold > 0.0 and contact == &"hit" else pow(strike, 1.25)) * (1.0 - hurt_strength) * (1.0 - parry)
	var follow := sin((1.0 - strike) * PI) * sqrt(strike) * (1.0 - hurt_strength) * (1.0 - parry)
	if hold > 0.0 and contact == &"hit":
		follow = 0.0
	var impact := pulse * (1.0 - hurt_strength) if contact == &"hit" else 0.0
	var guard := clampf(pulse * 0.85 + follow * 0.35, 0.0, 1.0) * (1.0 - hurt_strength) if contact == &"guard" else 0.0
	var overswing := follow if contact in [&"miss", &"pending"] else follow * 0.35
	var queued := clampf(float(pose.get("queued", 0.0)), 0.0, 1.0) * (1.0 - snap) * (1.0 - hurt_strength) * (1.0 - parry)
	var combo_step := clampi(int(pose.get("combo_step", 1)), 1, 3)
	var run := clampf(float(pose.get("run", 0.0)), 0.0, 1.0)
	var stride := float(pose.get("stride", 0.0))
	var kneel := clampf(float(pose.get("set", 0.0)), 0.0, 1.0)
	var tip_face := attack_face if strike > 0.0 else face
	var rest_tip := Vector2(tip_face * (24.0 - run * 6.0), -39.0 + sin(stride) * run * 5.0 + kneel * 14.0)
	var rest_elbow := Vector2(tip_face * (11.0 - run * 5.0), -43.0 + sin(stride) * run * 3.0)
	# Only an already accepted buffer cocks the brass arm during recovery.
	# The first/contact pose still reaches full extension with no anticipation.
	rest_tip += Vector2(-attack_face * 10.0, -8.0) * queued
	rest_elbow += Vector2(-attack_face * 4.0, -3.0) * queued
	var attack_tip: Vector2
	var attack_elbow: Vector2
	var body_tilt: float
	var body_offset: Vector2
	var body_stretch := Vector2.ZERO
	match combo_step:
		1:
			attack_tip = Vector2(attack_face * (55.0 + overswing * 8.0 - guard * 29.0), -9.0 + follow * 9.0 - guard * 9.0)
			attack_elbow = Vector2(attack_face * (22.0 - guard * 13.0), -27.0 - guard * 8.0)
			body_tilt = attack_face * (snap * 0.17 + overswing * 0.09 - guard * 0.26)
			body_offset = Vector2(attack_face * (snap * 5.0 - guard * 8.0), impact * 1.8)
		2:
			attack_tip = Vector2(attack_face * (55.0 - follow * 22.0 - guard * 25.0), 9.0 + overswing * 16.0 - guard * 19.0)
			attack_elbow = Vector2(attack_face * (20.0 - follow * 13.0 - guard * 7.0), -20.0 + follow * 10.0 - guard * 11.0)
			body_tilt = attack_face * (-snap * 0.19 + overswing * 0.24 - guard * 0.13)
			body_offset = Vector2(attack_face * (-snap * 4.0 - guard * 5.0), snap * 2.0 + impact * 1.5)
			body_stretch = Vector2(0.06, -0.04) * snap
		3:
			attack_tip = Vector2(attack_face * (39.0 + overswing * 16.0 - guard * 22.0), 23.0 + overswing * 11.0 - guard * 23.0)
			attack_elbow = Vector2(attack_face * (33.0 - guard * 15.0), -25.0 + follow * 18.0 - guard * 13.0)
			body_tilt = attack_face * (snap * 0.27 + overswing * 0.11 - guard * 0.35)
			body_offset = Vector2(attack_face * (snap * 5.0 - guard * 8.0), snap * 3.2 + impact * 2.0)
			body_stretch = Vector2(0.13, -0.11) * snap + Vector2(-0.04, 0.07) * follow
	var tip := rest_tip.lerp(attack_tip, snap)
	var elbow := rest_elbow.lerp(attack_elbow, snap)
	var pogo := snap if bool(pose.get("strike_pogo", false)) else 0.0
	if pogo > 0.0:
		# A genuine vulnerable-foe rebound points the needle down beneath tucked
		# knees. Groove launches and empty airborne strokes keep their own pose.
		tip = tip.lerp(Vector2(attack_face * 12.0, 43.0), pogo)
		elbow = elbow.lerp(Vector2(attack_face * 26.0, 2.0), pogo)
		body_tilt *= 1.0 - pogo * 0.65
		body_offset.y -= pogo * 3.0
		body_stretch += Vector2(-0.05, 0.07) * pogo
	var rear_elbow := Vector2(-attack_face * (21.0 + snap * 8.0), 6.0 - snap * 12.0)
	var rear_hand := Vector2(-attack_face * (17.0 + snap * 13.0), 13.0 + follow * 5.0)
	if parry > 0.0:
		tip = tip.lerp(Vector2(parry_face * 35.0, -35.0), parry)
		elbow = elbow.lerp(Vector2(parry_face * 15.0, -43.0), parry)
		rear_elbow = rear_elbow.lerp(Vector2(-parry_face * 18.0, -1.0), parry)
		rear_hand = rear_hand.lerp(Vector2(parry_face * 3.0, 6.0), parry)
		body_tilt -= parry_face * parry * 0.14
		body_offset += Vector2(-parry_face * 4.0, 1.5) * parry
		body_stretch += Vector2(0.07, -0.06) * parry
	var hit_direction := float(pose.get("hit_direction", -face))
	if hurt_strength > 0.0:
		tip = tip.lerp(Vector2(-hit_direction * 15.0, -27.0), hurt_strength)
		elbow = elbow.lerp(Vector2(-hit_direction * 11.0, -38.0), hurt_strength)
		rear_elbow = rear_elbow.lerp(Vector2(-hit_direction * 21.0, 1.0), hurt_strength)
		rear_hand = rear_hand.lerp(Vector2(-hit_direction * 8.0, 10.0), hurt_strength)
		body_tilt += hit_direction * hurt_strength * 0.29
		body_offset += Vector2(hit_direction * 8.0, -2.0) * hurt_strength
		body_stretch += Vector2(-0.08, 0.05) * hurt_strength
	body_stretch += Vector2(0.055, -0.065) * impact
	return {
		"snap": snap, "follow": follow, "guard": guard, "impact": impact,
		"parry": parry, "parry_face": parry_face, "hurt_strength": hurt_strength,
		"queued": queued, "body_tilt": body_tilt, "body_offset": body_offset,
		"body_stretch": body_stretch, "tip": tip, "elbow": elbow,
		"rear_elbow": rear_elbow, "rear_hand": rear_hand, "foot_tuck": pogo,
		"attack_face": attack_face,
	}
