extends Node
## The Book's paper motion. A leather board swings off a page that is already
## live and focused; changing tabs turns the old page over onto the new one;
## and on closing, the board swings shut over a still of the last page while
## the closed Book shrinks into Skip's hands. All three are mouse-ignoring
## drawings: input, focus, hitboxes, page content and the close itself never
## wait for them. Resizing, reopening and Reduced motion settle them at once.

const Press := preload("res://scripts/press.gd")
const Capture := preload("res://scripts/screen_capture.gd")
const COVER_TIME := 0.30
const TURN_TIME := 0.34
const FOLD_TIME := 0.38
## A hitch on the first frame of a menu must not swallow its motion.
const MAX_STEP := 1.0 / 30.0

var reduced_motion := false
var cover: Control
var turn: Control
var fold: Control
var _cover_age := -1.0
var _turn_age := -1.0
var _turn_rect := Rect2()
var _turn_direction := 1.0
var _turn_capture: Dictionary = {}
var _fold_age := -1.0
var _fold_rect := Rect2()
var _fold_target := Vector2.ZERO
var _fold_capture: Dictionary = {}
var _held_capture: Dictionary = {}
var _held_rect := Rect2()

class Sheet extends Control:
	var motion: Node
	var kind: StringName = &""
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE
	func _draw() -> void:
		motion.draw_sheet(self, kind)

## The turning page and the board ride above the Book's content; the closing
## fold lives beside the overlay, so it can play after the overlay has hidden.
func attach(overlay: Control, layer: CanvasLayer) -> void:
	turn = _sheet(&"PageTurn", &"turn")
	overlay.add_child(turn)
	cover = _sheet(&"BookBoard", &"cover")
	overlay.add_child(cover)
	fold = _sheet(&"BookFold", &"fold")
	layer.add_child(fold)
	for sheet in [turn, cover, fold]:
		sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settle()

func _sheet(node_name: StringName, kind: StringName) -> Control:
	var sheet := Sheet.new()
	sheet.name = node_name
	sheet.motion = self
	sheet.kind = kind
	sheet.visible = false
	return sheet

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if enabled:
		settle()

func open_cover() -> void:
	_stop_fold()
	_held_capture = {}
	_held_rect = Rect2()
	if reduced_motion or cover == null:
		return
	_cover_age = 0.0
	cover.visible = true
	cover.queue_redraw()

func turn_page(rect: Rect2, direction: float, viewport: Viewport) -> void:
	if reduced_motion or turn == null or rect.size.x < 2.0 or rect.size.y < 2.0:
		return
	_turn_capture = Capture.grab(viewport)
	_turn_rect = rect
	_turn_direction = -1.0 if direction < 0.0 else 1.0
	_turn_age = 0.0
	turn.visible = true
	turn.queue_redraw()

## Called while the last page is still the frame on screen, before the
## overlay hides. Main later sends it into Skip's hands or lets it go.
func hold_last_page(rect: Rect2, viewport: Viewport) -> void:
	_stop_cover()
	_stop_turn()
	_held_capture = {}
	_held_rect = Rect2()
	if reduced_motion or rect.size.x < 2.0 or rect.size.y < 2.0:
		return
	_held_capture = Capture.grab(viewport)
	_held_rect = rect

func fold_into(target: Vector2) -> bool:
	if reduced_motion or fold == null or _held_rect.size.x < 2.0:
		_held_capture = {}
		return false
	_fold_capture = _held_capture
	_fold_rect = _held_rect
	_fold_target = target
	_held_capture = {}
	_held_rect = Rect2()
	_fold_age = 0.0
	fold.visible = true
	fold.queue_redraw()
	return true

func settle() -> void:
	_stop_cover()
	_stop_turn()
	_stop_fold()
	_held_capture = {}
	_held_rect = Rect2()

func is_covering() -> bool:
	return _cover_age >= 0.0

func is_turning() -> bool:
	return _turn_age >= 0.0

func is_folding() -> bool:
	return _fold_age >= 0.0

func active_count() -> int:
	return int(is_covering()) + int(is_turning()) + int(is_folding())

func cover_progress() -> float:
	return clampf(_cover_age / COVER_TIME, 0.0, 1.0) if is_covering() else 1.0

func turn_progress() -> float:
	return clampf(_turn_age / TURN_TIME, 0.0, 1.0) if is_turning() else 1.0

func fold_progress() -> float:
	return clampf(_fold_age / FOLD_TIME, 0.0, 1.0) if is_folding() else 1.0

func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	var step := minf(delta, MAX_STEP)
	if is_covering():
		_cover_age += step
		if _cover_age >= COVER_TIME: _stop_cover()
		else: cover.queue_redraw()
	if is_turning():
		_turn_age += step
		if _turn_age >= TURN_TIME: _stop_turn()
		else: turn.queue_redraw()
	if is_folding():
		_fold_age += step
		if _fold_age >= FOLD_TIME: _stop_fold()
		else: fold.queue_redraw()

func draw_sheet(canvas: Control, kind: StringName) -> void:
	match kind:
		&"cover":
			var opened := cover_progress()
			Press.draw_book_cover(canvas, Rect2(Vector2.ZERO, canvas.size), 1.0 - (1.0 - opened) * (1.0 - opened))
		&"turn":
			Press.draw_page_turn(canvas, {"rect": _turn_rect, "progress": turn_progress(), "direction": _turn_direction}, _turn_capture)
		&"fold":
			Press.draw_book_fold(canvas, {"rect": _fold_rect, "progress": fold_progress(), "target": _fold_target}, _fold_capture)

func _stop_cover() -> void:
	_cover_age = -1.0
	if cover != null: cover.visible = false

func _stop_turn() -> void:
	_turn_age = -1.0
	_turn_capture = {}
	if turn != null: turn.visible = false

func _stop_fold() -> void:
	_fold_age = -1.0
	_fold_capture = {}
	if fold != null: fold.visible = false
