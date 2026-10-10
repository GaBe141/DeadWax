extends RefCounted
## One still of the frame already on screen, for transitions that must never
## delay the next frame. Reading it costs a single readback; a headless run or a
## failed read returns an empty capture, and every effect still draws without it.
## The image covers exactly the visible canvas, so canvas points map to UVs by
## the visible rect alone, at any window size or letterbox.

static func grab(viewport: Viewport) -> Dictionary:
	if viewport == null or DisplayServer.get_name() == "headless":
		return {}
	var source := viewport.get_texture()
	if source == null:
		return {}
	var image := source.get_image()
	if image == null or image.is_empty():
		return {}
	var texture := ImageTexture.create_from_image(image)
	if texture == null:
		return {}
	return {"texture": texture, "visible": viewport.get_visible_rect()}

static func texture_of(capture: Dictionary) -> Texture2D:
	return capture.get("texture") as Texture2D

## UVs for canvas-space points, for a textured polygon cut from the still.
static func uvs(capture: Dictionary, points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	var visible: Rect2 = capture.get("visible", Rect2(0, 0, 1, 1))
	var extent := Vector2(maxf(visible.size.x, 1.0), maxf(visible.size.y, 1.0))
	for point in points:
		result.append((point - visible.position) / extent)
	return result
