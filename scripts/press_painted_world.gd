extends RefCounted
## Painted distance is a cached art plate. Rooms supply its palette and bounds;
## this helper never inspects the world or advances a presentation clock.

const LABEL_PATH := "res://assets/art/label-district.png"
const OVERTURE_PATH := "res://assets/art/overture-interior.png"
const WELL_PATH := "res://assets/art/overture-shaft.png"
const UNPLAYED_PATH := "res://assets/art/unplayed-district.png"
const OVERTURE := [&"overture_stair", &"bootlegger", &"whistlers", &"addie", &"overture_well", &"worn_gallery", &"smoothed_floor", &"the_arm"]
const UNPLAYED := [&"the_landing", &"verse_hall", &"verse_warren_n", &"verse_warren_s", &"deep_gallery"]
static var _paintings: Dictionary = {}

static func draw(canvas: CanvasItem, room_id: StringName, area: Rect2, ink: Color, stock: Color) -> void:
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return
	var path := LABEL_PATH
	if room_id in [&"overture_well", &"the_drop"]:
		path = WELL_PATH
	elif room_id in UNPLAYED:
		path = UNPLAYED_PATH
	elif room_id in OVERTURE:
		path = OVERTURE_PATH
	var painting := texture(path)
	if painting == null:
		return
	var source := Rect2(Vector2.ZERO, painting.get_size())
	var scale_factor := maxf(area.size.x / source.size.x, area.size.y / source.size.y)
	var crop := area.size / scale_factor
	source.position = (source.size - crop) * 0.5
	source.size = crop
	var light_stock := stock.get_luminance() > ink.get_luminance()
	var tint := Color.WHITE.lerp(stock, 0.12)
	if room_id == &"the_drop":
		tint = tint.lerp(Color("f3bfa4"), 0.29)
	tint.a = 0.38 if light_stock else 0.94
	canvas.draw_texture_rect_region(painting, area, source, tint)
	# An explicit room-colour glaze unifies different districts and reverses the
	# exposure on the far face without changing the authored room palette.
	canvas.draw_rect(area, Color(stock, 0.24 if light_stock else 0.10))

static func texture(path: String) -> Texture2D:
	if _paintings.has(path):
		return _paintings[path]
	if not ResourceLoader.exists(path):
		return null
	var painting := load(path) as Texture2D
	if painting != null:
		_paintings[path] = painting
	return painting
