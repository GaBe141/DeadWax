extends RefCounted
## Light in the ink look (ink_look.gd). The Label at the hour
## the story keeps for it, dawn-grey (docs/STORY.md, beats 2 and the last):
## the page takes a cool second printing that is heaviest overhead and under
## the street, and the night's last lamps knock it back where they still burn.
## Ink has no white to add, so light is drawn as a printer draws it: a warm
## tint laid over the grey, rays scratched out of it, beams through a grate,
## a sheen left bare on brass.
##
## A rig is plain data, the room's own (press_ink_plaza.gd `light_rig`):
##   "area": Rect2 the wash covers; "dawn": [[y, darkness], ...] down the page;
##   "lamps": [{at, reach, warmth, glow, kind, street, flicker, rays}];
##   "windows": [{box, warmth}]; "shafts": [{x, top, bottom, width}];
##   "sheens": [PackedVector2Array]; "failing": the index of a dying lamp.
##
## Still light (`draw_plane`) is recorded with the room; what moves (`draw_live`:
## the lantern's flicker, the dying bulb, dust in the light) is drawn each frame
## and holds still under Reduced motion. `figure_shadows` and `rim` light what
## walks through it. Presentation only: none of it reaches collision or timing.

const Ink := preload("res://scripts/press_ink.gd")

const CELL := 24.0

## The rig's colours on either face: a cool grey over label paper, a darker
## wax over scratchboard; warm lamp light on both.
static func colours(far_face: bool) -> Dictionary:
	if far_face:
		return {"dawn": Color(0.0, 0.0, 0.0, 1.0), "dawn_scale": 1.25, "lamp": Color("efe6d2"), "lamp_scale": 0.5,
			"window": Color("e8d6ae"), "sheen": Color("f2eee4"), "shadow": Color("000000")}
	return {"dawn": Color("2b3245"), "dawn_scale": 1.0, "lamp": Color("ffe9bc"), "lamp_scale": 1.0,
		"window": Color("ffdf9c"), "sheen": Color("fbf5e6"), "shadow": Color("1d1a22")}

## How dark the page is at `at`: the dawn down the page, paler where the sky
## opens, knocked back by every lamp within reach.
static func darkness(rig: Dictionary, at: Vector2) -> float:
	var dark := _dawn(rig.dawn, at.y) * (1.0 - _sky(rig.get("sky", []), at))
	for lamp: Dictionary in rig.lamps:
		var t := at.distance_to(lamp.at) / float(lamp.reach)
		if t < 1.0:
			dark *= 1.0 - float(lamp.warmth) * (1.0 - t) * (1.0 - t)
	return dark

## How much paler the open sky is at `at`: soft-edged, strongest at its
## middle height.
static func _sky(sky: Array, at: Vector2) -> float:
	if sky.is_empty():
		return 0.0
	var across := smoothstep(float(sky[0]), float(sky[0]) + 90.0, at.x) * (1.0 - smoothstep(float(sky[1]) - 90.0, float(sky[1]), at.x))
	var height := sin(clampf(inverse_lerp(float(sky[2]), float(sky[3]), at.y), 0.0, 1.0) * PI)
	return float(sky[4]) * across * height

static func _dawn(keys: Array, y: float) -> float:
	if y <= float(keys[0][0]):
		return float(keys[0][1])
	for i in range(1, keys.size()):
		if y <= float(keys[i][0]):
			var t := inverse_lerp(float(keys[i - 1][0]), float(keys[i][0]), y)
			return lerpf(float(keys[i - 1][1]), float(keys[i][1]), smoothstep(0.0, 1.0, t))
	return float(keys[keys.size() - 1][1])

## How much a lamp lights `at`: its warmth, falling off to nothing at its reach.
static func influence(lamp: Dictionary, at: Vector2) -> float:
	var t := at.distance_to(lamp.at) / float(lamp.reach)
	return float(lamp.warmth) * (1.0 - t) * (1.0 - t) if t < 1.0 else 0.0

# == the still light, recorded with the room ===========================================

static func draw_plane(k: Ink, rig: Dictionary, far_face: bool) -> void:
	var c := colours(far_face)
	# The dawn: one tint over the whole page, computed corner by corner.
	var lamps: Array = rig.lamps
	var positions := PackedVector2Array()
	var reaches := PackedFloat32Array()
	var warmths := PackedFloat32Array()
	for lamp: Dictionary in lamps:
		positions.append(lamp.at)
		reaches.append(float(lamp.reach))
		warmths.append(float(lamp.warmth))
	var keys: Array = rig.dawn
	var sky: Array = rig.get("sky", [])
	var scale := float(c.dawn_scale)
	k.wash(rig.area, CELL, c.dawn, func(at: Vector2) -> float:
		var dark := _dawn(keys, at.y) * scale * (1.0 - _sky(sky, at))
		for i in positions.size():
			var t := at.distance_to(positions[i]) / reaches[i]
			if t < 1.0:
				dark *= 1.0 - warmths[i] * (1.0 - t) * (1.0 - t)
		return dark)
	# What stands near a low lamp throws a long shadow down the street.
	for prop: Array in rig.get("props", []):
		figure_shadows(k, rig, Color(c.shadow, 1.0), Vector2(float(prop[0]), float(rig.street)), float(rig.street), float(prop[1]), 0.0,
			clampf(float(prop[2]) / 60.0, 0.6, 2.0))
	# Lit windows: warm glass and a spill down the wall beneath.
	for window: Dictionary in rig.windows:
		var box: Rect2 = window.box
		var warmth := float(window.warmth) * float(c.lamp_scale)
		k.fill(k.rect_points(box.grow(-2.0)), Color(c.window, 0.3 * warmth), 1.2)
		var spill := PackedVector2Array([Vector2(box.position.x + 4, box.end.y + 6), Vector2(box.end.x - 4, box.end.y + 6),
			Vector2(box.end.x + 16, box.end.y + 96), Vector2(box.position.x - 16, box.end.y + 96)])
		k.graded(spill, PackedColorArray([Color(c.window, 0.2 * warmth), Color(c.window, 0.2 * warmth), Color(c.window, 0.0), Color(c.window, 0.0)]))
		k.glow(box.get_center(), box.size.x * 0.9, Color(c.window, 0.14 * warmth), 0.4)
	# Every lamp still burning, except the lantern and the dying bulb, whose
	# light moves (draw_live): a warm halo and a hot core.
	for i in lamps.size():
		var lamp: Dictionary = lamps[i]
		if bool(lamp.get("flicker", false)) or i == int(rig.get("failing", -1)):
			continue
		_halo(k, lamp, c, 1.0)
	# Rays scratched out round the lantern.
	for lamp: Dictionary in lamps:
		var rays := int(lamp.get("rays", 0))
		for i in rays:
			var angle := TAU * (i + 0.5 * (i % 2)) / rays + 0.2
			var length := float(lamp.glow) * (0.55 + 0.35 * absf(sin(i * 2.3)))
			var start: Vector2 = Vector2(lamp.at) + Vector2.from_angle(angle) * 15.0
			var finish: Vector2 = Vector2(lamp.at) + Vector2.from_angle(angle) * length
			k.stroke(PackedVector2Array([start, finish]), 1.0, Color(c.lamp, 0.4 * float(c.lamp_scale)), 0.0, 0.0, 0.2, 100.0)
	# Beams through the grate, falling into the shaft and pooling below.
	for shaft: Dictionary in rig.shafts:
		var x := float(shaft.x)
		var top := float(shaft.top)
		var bottom := float(shaft.bottom)
		for bar in int(shaft.bars):
			var left := x + bar * float(shaft.pitch)
			var width := float(shaft.width)
			var beam := PackedVector2Array([Vector2(left, top), Vector2(left + width, top),
				Vector2(left + width + 2.0, bottom), Vector2(left - 2.0, bottom)])
			k.graded(beam, PackedColorArray([Color(c.lamp, 0.5 * float(c.lamp_scale)), Color(c.lamp, 0.5 * float(c.lamp_scale)),
				Color(c.lamp, 0.0), Color(c.lamp, 0.0)]))
		var pool := Vector2(x + float(shaft.bars) * float(shaft.pitch) * 0.5, bottom + 10.0)
		k.glow(pool, 46.0, Color(c.lamp, 0.22 * float(c.lamp_scale)), 0.3)
	# Brass catches what light there is: a sheen left bare along its lit flank.
	for sheen: PackedVector2Array in rig.sheens:
		var widths := PackedFloat32Array()
		var alphas := PackedFloat32Array()
		for i in sheen.size():
			var t := float(i) / float(maxi(sheen.size() - 1, 1))
			widths.append(lerpf(1.0, 5.0, sin(t * PI)))
			alphas.append(sin(t * PI))
		k.ribbon(sheen, widths, Color(c.sheen, 0.5), alphas, 1.6)

## A lamp's light: the warm halo, and the glass burning hot inside it.
static func _halo(k: Ink, lamp: Dictionary, c: Dictionary, strength: float) -> void:
	var scale := float(c.lamp_scale) * strength
	k.glow(lamp.at, float(lamp.glow), Color(c.lamp, 0.34 * float(lamp.warmth) * scale), 0.25)
	k.glow(lamp.at, float(lamp.glow) * 0.3, Color(c.lamp, 0.6 * scale), 0.5)

# == what moves ==========================================================================

## The light that moves, drawn every frame: the lantern breathing, the dying
## bulb catching and failing, dust turning in the light. `time` stops under
## Reduced motion, so all of it holds still.
static func draw_live(k: Ink, rig: Dictionary, far_face: bool, time: float) -> void:
	var c := colours(far_face)
	var lamps: Array = rig.lamps
	for i in lamps.size():
		var lamp: Dictionary = lamps[i]
		if bool(lamp.get("flicker", false)):
			var breath := 0.9 + 0.07 * sin(time * 7.3 + i) + 0.05 * sin(time * 13.1 + i * 2.0)
			_halo(k, lamp, c, breath)
			_motes(k, lamp.at, float(lamp.glow) * 0.85, 18, c, time, i)
	var failing := int(rig.get("failing", -1))
	if failing >= 0 and failing < lamps.size():
		# A bulb on its last night: mostly on, then a stutter, then dark.
		var beat := fmod(time, 5.3)
		var on := 1.0
		if beat > 4.1:
			on = 0.0 if beat < 4.5 or (beat > 4.7 and beat < 4.85) else 0.45
		_halo(k, lamps[failing], c, on)
	for shaft: Dictionary in rig.shafts:
		var x := float(shaft.x) + float(shaft.bars) * float(shaft.pitch) * 0.5
		_motes(k, Vector2(x, (float(shaft.top) + float(shaft.bottom)) * 0.5), 26.0, 8, c, time * 0.6, 40)

## Dust drifting in a light: specks turning slowly round it, brightest near it.
static func _motes(k: Ink, center: Vector2, radius: float, count: int, c: Dictionary, time: float, salt: int) -> void:
	for i in count:
		var seed_value := float(salt * 31 + i * 7)
		var angle := seed_value * 2.399 + time * (0.09 + 0.04 * sin(seed_value))
		var reach := radius * (0.25 + 0.75 * fmod(absf(sin(seed_value * 12.9898)) * 7.0, 1.0))
		var drift := Vector2(sin(time * 0.37 + seed_value) * 4.0, -fmod(time * 3.0 + seed_value * 5.0, 18.0) + 9.0)
		var at := center + Vector2.from_angle(angle) * reach + drift
		var near := 1.0 - clampf(at.distance_to(center) / radius, 0.0, 1.0)
		if near > 0.05:
			k.blob(at, 0.9 + 0.7 * near, Color(c.lamp, 0.85 * near * float(c.lamp_scale) + 0.1), 4)

# == figures in the light ===========================================================

## Long soft shadows thrown along the street by lamps near the ground, one per
## lamp in reach, falling away from it.
## `tall` stretches the shadow for something taller than a figure.
static func figure_shadows(k: Ink, rig: Dictionary, ink: Color, foot: Vector2, surface: float, width: float, lift: float, tall := 1.0) -> void:
	for lamp: Dictionary in rig.lamps:
		if not bool(lamp.get("street", false)):
			continue
		var chest := foot + Vector2(0.0, -30.0)
		var light := influence(lamp, chest)
		if light < 0.03:
			continue
		var dx := foot.x - Vector2(lamp.at).x
		var away := signf(dx) if absf(dx) > 3.0 else 0.0
		var length := clampf(absf(dx) * 0.8 + 14.0, 14.0, 84.0) * (1.0 - lift) * tall
		var center := Vector2(foot.x + away * (length * 0.5 + width * 0.3), surface + 4.0)
		var strength := minf(0.5, light * 1.1) * (1.0 - lift * 0.7)
		var shadow := k.ellipse_points(center, Vector2(length * 0.5 + width * 0.4, 3.2 * (1.0 - lift * 0.6)), 0.0, 18)
		k.fill(shadow, Color(ink, strength), 2.4)
		# Hatched along its length, as the ink shades a cast shadow.
		var ticks := int(length / 7.0)
		for i in ticks:
			var x := center.x - away * (length * 0.5) + away * (i + 0.5) * length / ticks if away != 0.0 else center.x + (i - ticks * 0.5) * 6.0
			k.hair(Vector2(x - 2.0, surface + 7.0), Vector2(x + 2.5, surface + 1.5), 0.8, Color(ink, strength * 1.2))

## A rim of lamplight along the side of a figure's outline that faces a lamp.
## `outline` and `lamps` are in the same space; the outline winds either way.
static func rim(k: Ink, outline: PackedVector2Array, lamps: Array, paint: Color, width := 1.5) -> void:
	if outline.size() < 3:
		return
	var center := Vector2.ZERO
	for point in outline:
		center += point
	center /= outline.size()
	for lamp: Dictionary in lamps:
		var light := influence(lamp, center)
		if light < 0.04:
			continue
		var toward := (Vector2(lamp.at) - center).normalized()
		for i in outline.size():
			var a := outline[i]
			var b := outline[(i + 1) % outline.size()]
			var normal := (b - a).orthogonal().normalized()
			# Outward: away from the centre.
			if normal.dot((a + b) * 0.5 - center) < 0.0:
				normal = -normal
			var facing := normal.dot(toward)
			if facing > 0.25:
				var inset := normal * width * 0.6
				k.hair(a - inset, b - inset, width, Color(paint, paint.a * clampf(light * 2.2, 0.0, 1.0) * facing))
