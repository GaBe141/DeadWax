extends Node2D
## A fixed engraving left by the first Yard voice. It presents an injected
## outcome; Main alone stores that choice. No collision or reward lives here.

const Press := preload("res://scripts/press.gd")
const REVEAL_TIME := 1.2
const FIRST_MEMORY_DELAY := 6.0
const MEMORY_REST := 9.0
const HEARING_RADIUS := 380.0

var ink := Color("26221e")
var stock := Color("e8e0cc")
var outcome := ""
var _clock := 0.0
var _reveal := 1.0
var _memory_wait := FIRST_MEMORY_DELAY
var _reduced_motion := false

func _ready() -> void:
	z_index = -20

func _process(delta: float) -> void:
	if delta <= 0.0 or get_tree().paused:
		return
	if not _reduced_motion:
		_clock += delta
		_reveal = minf(_reveal + delta / REVEAL_TIME, 1.0)
	if outcome == "freed":
		var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
		var quiet := player != null and player.is_on_floor() and absf(player.velocity.x) < 35.0 and float(player.get("noise")) < 0.18
		if quiet and player.global_position.distance_to(global_position) <= HEARING_RADIUS:
			_memory_wait -= delta
			if _memory_wait <= 0.0:
				_memory_wait = MEMORY_REST
				var bank := get_tree().get_first_node_in_group("audio_bank")
				if bank != null:
					bank.play("yard_memory", -12.0)
		else:
			_memory_wait = FIRST_MEMORY_DELAY
	queue_redraw()

func present_outcome(value: String) -> void:
	if value not in ["freed", "shattered"] or outcome == value:
		return
	outcome = value
	_reveal = 1.0 if _reduced_motion else 0.0
	_memory_wait = FIRST_MEMORY_DELAY
	queue_redraw()

func restore_outcome(value: String) -> void:
	outcome = value if value in ["freed", "shattered"] else ""
	_reveal = 1.0
	_memory_wait = FIRST_MEMORY_DELAY
	queue_redraw()

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if enabled:
		_reveal = 1.0
	queue_redraw()

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	queue_redraw()

func animation_pose() -> Dictionary:
	return {"outcome": outcome, "clock": 0.0 if _reduced_motion else _clock,
		"reveal": _reveal, "reduced_motion": _reduced_motion}

func _draw() -> void:
	Press.draw_yard_memory(self, animation_pose(), ink, stock)
