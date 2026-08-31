extends Node2D
## A world pickup for an earned Refrain. The session owner performs the
## actual unlock; this node only presents and reports the encounter.

signal collected(refrain: int)

const ProgressionScript := preload("res://scripts/progression_state.gd")
const COLLECT_RADIUS := 62.0
const INK := Color(0.10, 0.085, 0.115)
const CHALK := Color(0.95, 0.92, 0.86)
const PINK := Color(0.90, 0.25, 0.50)

var progression: RefCounted
var refrain := ProgressionScript.Refrain.GATHER
var _collected := false
var _float_t := 0.0
var _origin_y := 0.0

func _ready() -> void:
	add_to_group("refrain_pickup")
	_origin_y = position.y
	if _is_unlocked():
		queue_free()
		return
	var label := Label.new()
	label.text = ProgressionScript.refrain_label(refrain)
	label.position = Vector2(-36, 38)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", CHALK)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 5)
	add_child(label)

func _process(delta: float) -> void:
	if _collected:
		return
	_float_t += delta
	position.y = _origin_y + sin(_float_t * 2.4) * 5.0
	queue_redraw()
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and global_position.distance_to(player.global_position) <= COLLECT_RADIUS:
		collect()

func collect() -> void:
	if _collected:
		return
	_collected = true
	if not _is_unlocked():
		collected.emit(refrain)
	queue_free()

func _is_unlocked() -> bool:
	return (
		progression != null
		and bool(progression.call("has_refrain", refrain))
	)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 29.0, Color(INK.r, INK.g, INK.b, 0.78))
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 48, CHALK, 4.0)
	draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 32, PINK, 3.0)
	draw_circle(Vector2.ZERO, 4.0, CHALK)
	draw_line(Vector2(-32, -34), Vector2(-24, -45), CHALK, 2.0)
	draw_line(Vector2(28, -32), Vector2(37, -42), CHALK, 2.0)
