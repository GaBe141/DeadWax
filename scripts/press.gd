extends RefCounted
## THE PRESS — every surface, every letterform, one place.
##
## Dead Wax is printed matter: a label, a sleeve, a poster for tomorrow. This
## holds the whole visual language so a room only ever says *what* is there,
## never how it is inked. Rooms keep authoring `ink` and `bg_color`; the press
## decides what those mean on the page.
##
## Nothing here reads gameplay state. Colours arrive as arguments.

const PlateShader := preload("res://assets/shaders/plate.gdshader")
const PaperShader := preload("res://assets/shaders/paper.gdshader")
const BackdropShader := preload("res://assets/shaders/backdrop.gdshader")
const RoomAirShader := preload("res://assets/shaders/room_air.gdshader")

const DisplayFont := preload("res://assets/fonts/BigShoulders-Bold.ttf")
const DisplayLight := preload("res://assets/fonts/BigShoulders-Regular.ttf")
const BodyFont := preload("res://assets/fonts/IBMPlexMono-Regular.ttf")
const BodyBold := preload("res://assets/fonts/IBMPlexMono-Bold.ttf")

# -- the type case ------------------------------------------------------------
## Display sizes are set in the wood-type tradition: few, and far apart.
const SIZE_BANNER := 46
const SIZE_TITLE := 27
const SIZE_HEADING := 17
const SIZE_BODY := 15
const SIZE_SMALL := 13
const SIZE_TINY := 11
const SIZE_COVER := 108
const SIZE_MENU_TITLE := 62
const SIZE_MENU_ACTION := 23

const TRACKING_DISPLAY := 2
const LINE_SPACING := 2

# -- the ink ------------------------------------------------------------------
const PINK := Color(0.90, 0.25, 0.50)

# -- plate defaults -----------------------------------------------------------
const PLATE_BITE := 2.4
const PLATE_TOOTH := 0.16
const PLATE_FRINGE := 0.5
const MISREGISTER := Vector2(2.0, -1.5)

# A card's stock sits between the room's paper and its ink, so signage reads as
# something laid ON the page rather than printed into it.
const CARD_STOCK_MIX := 0.10
const CARD_PAD := Vector2(12.0, 7.0)
const CARD_RULE := 2.0

static var _lamp_texture: GradientTexture2D
static var _unshaded: CanvasItemMaterial
static var _glow: CanvasItemMaterial

## Soft native light falloff, shared by the lamps and their small printed glow.
static func light_texture() -> GradientTexture2D:
	if _lamp_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.18, 0.42, 0.72, 1.0])
		gradient.colors = PackedColorArray([Color.WHITE, Color(0.82, 0.82, 0.82),
			Color(0.38, 0.38, 0.38), Color(0.08, 0.08, 0.08), Color.BLACK])
		_lamp_texture = GradientTexture2D.new()
		_lamp_texture.width = 256
		_lamp_texture.height = 256
		_lamp_texture.gradient = gradient
		_lamp_texture.fill = GradientTexture2D.FILL_RADIAL
		_lamp_texture.fill_from = Vector2(0.5, 0.5)
		_lamp_texture.fill_to = Vector2(1.0, 0.5)
	return _lamp_texture

static func unshaded_material() -> CanvasItemMaterial:
	if _unshaded == null:
		_unshaded = CanvasItemMaterial.new()
		_unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return _unshaded

static func glow_material() -> CanvasItemMaterial:
	if _glow == null:
		_glow = CanvasItemMaterial.new()
		_glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _glow

static func draw_lamp(canvas: CanvasItem, ink: Color, stock: Color, tint: Color) -> void:
	var frame := ink.lerp(stock, 0.20)
	canvas.draw_line(Vector2(0, -66), Vector2(0, -13), frame, 2.0, true)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-15, -8), Vector2(-6, -17),
		Vector2(6, -17), Vector2(15, -8)]), frame)
	canvas.draw_rect(Rect2(-8, -7, 16, 19), tint.lerp(Color.WHITE, 0.48))
	canvas.draw_rect(Rect2(-8, -7, 16, 19), frame, false, 2.0)
	canvas.draw_line(Vector2(-12, 14), Vector2(12, 14), frame, 3.0, true)
	canvas.draw_line(Vector2(0, -6), Vector2(0, 12), Color(frame, 0.6), 1.0)

static func menu_button_style(ink: Color, stock: Color, highlighted := false, focused := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ink if highlighted else stock.lerp(ink, 0.045)
	style.border_color = PINK if focused else ink.lerp(stock, 0.78)
	style.set_border_width_all(2 if focused else 1)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

## Focus is drawn over the current button state, so its backing stays clear.
static func menu_focus_style(ink: Color, stock: Color) -> StyleBoxFlat:
	var style := menu_button_style(ink, stock, false, true)
	style.bg_color = Color.TRANSPARENT
	return style

## Non-colliding printed architecture. Rooms select the subject and scale;
## the press holds the drawing vocabulary just as it holds their plates.
static func impression(kind: StringName, size: Vector2, ink: Color, stock: Color) -> Node2D:
	var mark := preload("res://scripts/press_impression.gd").new()
	mark.kind = kind
	mark.extent = size
	mark.ink = ink
	mark.stock = stock
	return mark

static func draw_tonearm(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	preload("res://scripts/press_tonearm.gd").draw_tonearm(
		canvas, pose, ink, stock, DisplayFont, BodyFont, SIZE_HEADING, SIZE_SMALL
	)

static func draw_hush(canvas: CanvasItem, pose: int, ticks: int, parries: int, face: float, time: float, ink: Color, stock: Color, motion: Dictionary = {}) -> void:
	preload("res://scripts/press_hush.gd").draw(canvas, pose, ticks, parries, face, time, ink, stock, motion)

static func draw_skip(canvas: CanvasItem, pose: Dictionary, palette: Dictionary) -> void:
	preload("res://scripts/press_skip.gd").draw(canvas, pose, palette)

static func draw_strike_wave(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	preload("res://scripts/press_strike.gd").draw(canvas, pose, ink, stock)

static func draw_campaign_map(canvas: CanvasItem, size: Vector2, pose: Dictionary, ink: Color, stock: Color) -> void:
	preload("res://scripts/press_map.gd").draw_chart(canvas, size, pose, ink, stock, BodyFont, DisplayFont)

static func draw_map_pickup(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	preload("res://scripts/press_map.gd").draw_pickup(canvas, pose, ink, stock)

static func draw_loft_voice(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	preload("res://scripts/press_discovery.gd").draw_voice(canvas, pose, ink, stock)

static func draw_refrain_pickup(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	preload("res://scripts/press_discovery.gd").draw_refrain(canvas, pose, ink, stock)

static func map_backing(stock: Color) -> ColorRect:
	var backing := ColorRect.new()
	backing.color = stock
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return backing

static func draw_resident(canvas: CanvasItem, kind: StringName, pose: Dictionary, ink: Color, stock: Color) -> void:
	preload("res://scripts/press_resident.gd").draw(canvas, kind, pose, ink, stock)

static func draw_hound(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	preload("res://scripts/press_hound.gd").draw(canvas, pose, ink, stock)

static func draw_shop_item(canvas: CanvasItem, item_id: StringName, size: Vector2, ink: Color, stock: Color) -> void:
	preload("res://scripts/press_shop.gd").draw(canvas, item_id, size, ink, stock)

static func draw_room_depth(canvas: CanvasItem, room_id: StringName, layer: StringName, bounds: Rect2, pose: Dictionary, ink: Color, stock: Color) -> void:
	if room_id in [&"bootlegger", &"whistlers", &"addie", &"overture_well", &"worn_gallery", &"smoothed_floor", &"the_arm"]:
		preload("res://scripts/press_overture_depth.gd").draw(canvas, room_id, layer, bounds, pose, ink, stock)
	else:
		preload("res://scripts/press_label_depth.gd").draw(canvas, room_id, layer, bounds, pose, ink, stock)

static func draw_auditioner(canvas: CanvasItem, pose: Dictionary, ink: Color, body: Color, pale: Color, accent: Color, grey: Color, warm: Color) -> void:
	preload("res://scripts/press_auditioner.gd").draw_auditioner(canvas, pose, ink, body, pale, accent, grey, warm)

static func draw_pressing(canvas: CanvasItem, pose: Dictionary, ink: Color, wax: Color, pale: Color, accent: Color, grey: Color) -> void:
	preload("res://scripts/press_pressing.gd").draw_pressing(canvas, pose, ink, wax, pale, accent, grey)

# -- surfaces -----------------------------------------------------------------

## An inked plate of `size`, centred on the origin. Replaces a flat ColorRect
## anywhere a solid surface is wanted.
static func plate(size: Vector2, ink: Color, stock: Color, accent := PINK, seed := 0.0) -> ColorRect:
	var rect := ColorRect.new()
	rect.size = size
	rect.position = -size / 2.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = PlateShader
	mat.set_shader_parameter("ink", ink)
	mat.set_shader_parameter("stock", stock)
	mat.set_shader_parameter("accent", accent)
	mat.set_shader_parameter("plate_px", size)
	mat.set_shader_parameter("misregister", MISREGISTER)
	mat.set_shader_parameter("bite", PLATE_BITE)
	mat.set_shader_parameter("tooth", PLATE_TOOTH)
	mat.set_shader_parameter("fringe", PLATE_FRINGE)
	mat.set_shader_parameter("plate_seed", seed)
	rect.material = mat
	return rect

## Re-inks a plate in place. Used when the pressing turns over: same platform,
## other face, no rebuild.
static func reink(rect: ColorRect, ink: Color, stock: Color, accent := PINK) -> void:
	var mat := rect.material as ShaderMaterial
	if mat == null:
		rect.color = ink
		return
	mat.set_shader_parameter("ink", ink)
	mat.set_shader_parameter("stock", stock)
	mat.set_shader_parameter("accent", accent)

## The halftone tint block a room is printed over.
static func backdrop(size: Vector2, ink: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = BackdropShader
	mat.set_shader_parameter("ink", ink)
	mat.set_shader_parameter("field_px", size)
	rect.material = mat
	return rect

static func retint_backdrop(rect: ColorRect, ink: Color) -> void:
	var mat := rect.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("ink", ink)

static func room_air(size: Vector2, ink: Color, stock: Color, warmth: float, depth: float) -> ColorRect:
	var rect := ColorRect.new()
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = RoomAirShader
	material.set_shader_parameter("field_px", size)
	material.set_shader_parameter("ink", ink)
	material.set_shader_parameter("stock", stock)
	material.set_shader_parameter("warmth", warmth)
	material.set_shader_parameter("depth", depth)
	rect.material = material
	return rect

static func reink_room_air(rect: ColorRect, ink: Color, stock: Color) -> void:
	var material := rect.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("ink", ink)
		material.set_shader_parameter("stock", stock)

## The sheet itself: tooth and a pressed-in vignette, over everything.
static func paper_overlay(tint: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = PaperShader
	mat.set_shader_parameter("tint", tint)
	rect.material = mat
	return rect

static func repaper(rect: ColorRect, tint: Color) -> void:
	var mat := rect.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("tint", tint)

# -- type ---------------------------------------------------------------------

## Wood type: room names, the one word a moment is worth.
static func set_display(label: Label, size: int, color: Color, outline := Color(0, 0, 0, 0)) -> void:
	label.add_theme_font_override("font", DisplayFont)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("line_spacing", LINE_SPACING)
	_set_outline(label, outline)

## Set text: everything the world says to you.
static func set_body(label: Label, size: int, color: Color, outline := Color(0, 0, 0, 0), bold := false) -> void:
	label.add_theme_font_override("font", BodyBold if bold else BodyFont)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("line_spacing", LINE_SPACING)
	_set_outline(label, outline)

static func _set_outline(label: Label, outline: Color) -> void:
	if outline.a <= 0.0:
		label.add_theme_constant_override("outline_size", 0)
		return
	label.add_theme_color_override("font_outline_color", outline)
	label.add_theme_constant_override("outline_size", 5)

# -- signage ------------------------------------------------------------------

## A pasted-up card: stock, a rule in the accent, and set text. Returns the
## card so a caller can re-ink it; the text sits on it as a child.
static func card(
	text: String,
	ink: Color,
	stock: Color,
	accent := PINK,
	size := SIZE_BODY,
	heading := ""
) -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var body := Label.new()
	body.text = text
	set_body(body, size, ink)
	var body_size := _card_text_size(text, BodyFont, size)

	var head: Label = null
	var head_size := Vector2.ZERO
	if not heading.is_empty():
		head = Label.new()
		head.text = heading
		set_display(head, SIZE_HEADING, ink)
		head.add_theme_constant_override("font_spacing_glyph", TRACKING_DISPLAY)
		head_size = _card_text_size(heading, DisplayFont, SIZE_HEADING)

	var inner := Vector2(
		maxf(body_size.x, head_size.x),
		body_size.y + head_size.y + (CARD_RULE + 9.0 if head != null else 0.0)
	)
	var full := inner + CARD_PAD * 2.0

	var sheet := ColorRect.new()
	sheet.size = full
	sheet.color = stock.lerp(ink, CARD_STOCK_MIX)
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sheet)

	# The rule: a single struck line, the cheapest mark that says "printed".
	var rule := ColorRect.new()
	rule.position = Vector2(CARD_PAD.x, full.y - CARD_PAD.y * 0.45)
	rule.size = Vector2(inner.x, CARD_RULE)
	rule.color = Color(accent.r, accent.g, accent.b, 0.85)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rule)

	var cursor := CARD_PAD.y
	if head != null:
		head.position = Vector2(CARD_PAD.x, cursor)
		root.add_child(head)
		cursor += head_size.y + CARD_RULE + 9.0
		var head_rule := ColorRect.new()
		head_rule.position = Vector2(CARD_PAD.x, cursor - 7.0)
		head_rule.size = Vector2(inner.x, 1.0)
		head_rule.color = Color(ink.r, ink.g, ink.b, 0.35)
		head_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(head_rule)

	body.position = Vector2(CARD_PAD.x, cursor)
	root.add_child(body)

	root.custom_minimum_size = full
	root.size = full
	return root

## Labels created outside the tree can still report a cached fallback-font
## minimum after overrides. Measure the chosen face directly, with the same
## interline spacing, so the stock already fits when a room positions its card.
static func _card_text_size(text: String, font: Font, size: int) -> Vector2:
	var measured := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size)
	measured.y += LINE_SPACING * text.count("\n")
	return measured.ceil()

## Re-inks a card built above, in the order its children were added.
static func recard(root: Control, ink: Color, stock: Color, accent := PINK) -> void:
	for child in root.get_children():
		if child is ColorRect:
			var rect := child as ColorRect
			if is_equal_approx(rect.size.y, CARD_RULE):
				rect.color = Color(accent.r, accent.g, accent.b, 0.85)
			elif rect.size.y <= 1.5:
				rect.color = Color(ink.r, ink.g, ink.b, 0.35)
			else:
				rect.color = stock.lerp(ink, CARD_STOCK_MIX)
		elif child is Label:
			(child as Label).add_theme_color_override("font_color", ink)


## Only groove glints turn; the label and its type stay upright on the sleeve.
static func draw_record(canvas: CanvasItem, size: Vector2, ink: Color, paper: Color, accent := PINK, phase: float = 0.0) -> void:
	var radius := minf(size.x, size.y) * 0.47
	var center := size * 0.5
	canvas.draw_circle(center + Vector2(5.0, 7.0), radius, Color(ink, 0.12))
	canvas.draw_circle(center, radius, ink, true, -1.0, true)
	for groove in range(34):
		var groove_radius := radius * (0.40 + float(groove) * 0.017)
		canvas.draw_arc(center, groove_radius, 0.0, TAU, 160, Color(paper, 0.09), 1.0, true)
	canvas.draw_arc(center, radius * 0.975, 0.0, TAU, 160, Color(paper, 0.30), 1.0, true)
	canvas.draw_arc(center, radius * 0.83, -0.91 + phase, -0.11 + phase, 48, Color(paper, 0.17), 2.0, true)
	canvas.draw_arc(center, radius * 0.64, 2.18 + phase, 3.17 + phase, 48, Color(paper, 0.13), 2.0, true)
	for groove in 5:
		var start := phase + groove * 1.7
		canvas.draw_arc(center, radius * (0.46 + groove * 0.08), start, start + 0.32, 16, Color(paper, 0.09), 1.0, true)
	canvas.draw_circle(center + Vector2(1.5, -1.0), radius * 0.33, accent, true, -1.0, true)
	canvas.draw_arc(center, radius * 0.29, 0.0, TAU, 96, Color(ink, 0.30), 1.0, true)
	canvas.draw_circle(center, 5.0, paper, true, -1.0, true)

## A short ink stroke responds to focus without moving the button or its text.
static func draw_ui_focus(canvas: CanvasItem, size: Vector2, accent: Color, level: float, press: float) -> void:
	var width := maxf(size.x - 24.0, 0.0)
	var y := maxf(size.y - 5.0, 0.0)
	if level > 0.0 and width > 0.0:
		canvas.draw_line(Vector2(12, y), Vector2(12 + width * level, y), Color(accent, level * 0.72), 2.0, true)
	if press > 0.0:
		var reach := minf(width, 28.0 + (1.0 - press) * 70.0)
		canvas.draw_line(Vector2(12, y - 3), Vector2(12 + reach, y - 3), Color(accent, press * 0.7), 3.0, true)


## A constant-size focus frame around a slider, visible with keyboard or pad.
static func menu_slider_style(focused := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = PINK if focused else Color.TRANSPARENT
	style.set_border_width_all(2)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style
