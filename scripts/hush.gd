extends "res://scripts/test_pressing.gd"
## HUSH keeps the proven three-parry rules; his defeat is a held bow,
## not the practice pressing's timed reformation.

const PressScript := preload("res://scripts/press.gd")

var print_ink := Color("494450")
var print_stock := Color("ded5df")
var _won := false

func _ready() -> void:
	muted = true
	super._ready()
	add_to_group("chapter_boss")

func _process(delta: float) -> void:
	if _won:
		return
	super._process(delta)

func on_player_strike(pos: Vector2, big: bool) -> void:
	# HUSH keeps his time. Rewinding the swing on a close raw strike would
	# postpone contact beyond the same strike's 100 ms parry window.
	if muted:
		return
	super.on_player_strike(pos, big)

func _down(spill: bool) -> void:
	if _won:
		return
	super._down(spill)
	if not spill:
		_won = true
		remove_from_group("strikable")
	queue_redraw()

func restore_outcome(outcome: String) -> void:
	if outcome != "won":
		return
	_won = true
	state = S.DOWN
	parry_count = 0
	resonance = 0.0
	_t = 0.0
	remove_from_group("strikable")
	queue_redraw()

func reset_attempt() -> void:
	if _won:
		return
	state = S.CALM
	parry_count = 0
	resonance = 0.0
	hp = HP_MAX
	_count = 0
	_t = 0.0
	queue_redraw()

func _draw() -> void:
	PressScript.draw_hush(self, state, _count, 3 if _won else parry_count, _face, _t, print_ink, print_stock)
