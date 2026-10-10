extends CanvasLayer
## The ink wipe between rooms. Main hands it a still of the frame on screen
## before a passage loads, then loads the next room exactly as before; this
## layer only draws the old room being brushed away over a room that is
## already live. It owns no input, rooms, saves or timers, pauses with play,
## and sits beneath every menu. Reduced motion dissolves the still instead.

const Press := preload("res://scripts/press.gd")
const WIPE_TIME := 0.42
const DISSOLVE_TIME := 0.24
## A long room build must not swallow the stroke: each frame advances it at
## most this far, so the wipe always reads even after a hitch.
const MAX_STEP := 1.0 / 30.0

var reduced_motion := false
var _art: Control
var _capture: Dictionary = {}
var _age := -1.0
var _direction := 1.0
var _reduced := false

class WipeArt extends Control:
	var wipe: CanvasLayer
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE
	func _draw() -> void:
		Press.draw_room_wipe(self, size, wipe.pose(), wipe._capture)

func _ready() -> void:
	layer = 90
	_art = WipeArt.new()
	_art.name = "WipeArt"
	_art.wipe = self
	add_child(_art)
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.visible = false

## Any menu or pause ends the stroke: the room underneath is already live,
## and a still must never outlast the moment it belongs to.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		settle()

## Starts over the still. The room may change underneath on this same frame.
func begin(capture: Dictionary) -> void:
	_capture = capture
	_age = 0.0
	_direction = 1.0
	_reduced = reduced_motion
	_art.visible = true
	_art.queue_redraw()

## Main reports where Skip stands in the new room so the stroke uncovers that
## side first.
func arrive(screen_x: float) -> void:
	if not is_active():
		return
	_direction = 1.0 if screen_x <= _art.size.x * 0.5 else -1.0
	_art.queue_redraw()

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if enabled and is_active():
		_reduced = true
		_art.queue_redraw()

func settle() -> void:
	_age = -1.0
	_capture = {}
	if _art != null:
		_art.visible = false

func is_active() -> bool:
	return _age >= 0.0

func progress() -> float:
	if not is_active():
		return 1.0
	return clampf(_age / (DISSOLVE_TIME if _reduced else WIPE_TIME), 0.0, 1.0)

func direction() -> float:
	return _direction

func pose() -> Dictionary:
	return {"progress": progress(), "direction": _direction, "reduced": _reduced}

func _process(delta: float) -> void:
	if not is_active() or delta <= 0.0:
		return
	_age += minf(delta, MAX_STEP)
	if progress() >= 1.0:
		settle()
		return
	_art.queue_redraw()
