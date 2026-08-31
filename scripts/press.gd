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
	var body_size := body.get_minimum_size()

	var head: Label = null
	var head_size := Vector2.ZERO
	if not heading.is_empty():
		head = Label.new()
		head.text = heading
		set_display(head, SIZE_HEADING, ink)
		head.add_theme_constant_override("font_spacing_glyph", TRACKING_DISPLAY)
		head_size = head.get_minimum_size()

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
