extends RefCounted
## Shared distance entry point for rooms, menus and the opening. Runtime art
## is authored silhouettes; the original paintings remain an importable archive.

const Distance := preload("res://scripts/press_distance.gd")

const LABEL_PATH := "res://assets/art/label-district.png"
const OVERTURE_PATH := "res://assets/art/overture-interior.png"
const WELL_PATH := "res://assets/art/overture-shaft.png"
const UNPLAYED_PATH := "res://assets/art/unplayed-district.png"
static var _paintings: Dictionary = {}

static func draw(canvas: CanvasItem, room_id: StringName, area: Rect2, ink: Color, stock: Color) -> void:
	Distance.draw(canvas, room_id, area, ink, stock)

static func texture(path: String) -> Texture2D:
	if _paintings.has(path):
		return _paintings[path]
	if not ResourceLoader.exists(path):
		return null
	var painting := load(path) as Texture2D
	if painting != null:
		_paintings[path] = painting
	return painting
