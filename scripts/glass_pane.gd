extends StaticBody2D
## DISPLAY GLASS — a shop window that only gives way to a heavy stroke.
## A light Tap bounces off it with a dry clack, which is the whole joke; the
## Accent (or any stroke the groove makes big) shatters it for good. It is a
## physical lock like the listening doors: Main remembers `opened` under its
## chapter_state_id and the room disables the block when it restores.

signal opened

const PressScript := preload("res://scripts/press.gd")
const SIZE := Vector2(26, 150)
const REACH := 120.0            # Skip's hit reach; the pane never listens from afar
const SHARD_LIFE := 1.6

var is_open := false
var ink := Color("26221e")
var stock := Color("e3bfb6")
var _sid := 0
var _bounce := 0.0
var _break_anim := 0.0
var _hits := 0

func _ready() -> void:
	add_to_group("hears_strikes")
	_sid = randi()
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = SIZE
	cs.shape = sh
	cs.name = "block"
	add_child(cs)
	z_index = 6
	if is_open:
		cs.set_deferred("disabled", true)

## A strike within reach: a light stroke only makes the pane ring, a heavy one
## breaks it. Both are confirmed contact (a `hit` receipt) so the chain can
## reach its Accent against the glass; glass is not a foe, so Main pays no XP
## for it, and the breaking blow adds the shatter to the ordinary impact.
func on_player_strike(pos: Vector2, big: bool) -> Variant:
	if is_open or get_tree().paused:
		return null
	if not _within_reach(pos):
		return null
	_hits += 1
	if not big:
		_bounce = 1.0
		var bank := get_tree().get_first_node_in_group("audio_bank")
		if bank != null:
			bank.call("play", "tick", -16.0, 2.4)
		queue_redraw()
		return &"hit"
	_shatter()
	return &"hit"

func _within_reach(pos: Vector2) -> bool:
	var half := SIZE / 2.0
	var nearest := Vector2(clampf(pos.x, global_position.x - half.x, global_position.x + half.x),
		clampf(pos.y, global_position.y - half.y, global_position.y + half.y))
	return nearest.distance_to(pos) <= REACH

func _shatter() -> void:
	is_open = true
	_break_anim = SHARD_LIFE
	var cs := get_node_or_null("block")
	if cs != null:
		cs.set_deferred("disabled", true)
	var bank := get_tree().get_first_node_in_group("audio_bank")
	if bank != null:
		bank.call("play", "shatter", -9.0, 1.35)
	opened.emit()
	queue_redraw()

func _process(delta: float) -> void:
	if get_tree().paused or delta <= 0.0:
		return
	var step := minf(delta, 0.1)
	var busy := _bounce > 0.0 or _break_anim > 0.0
	_bounce = maxf(_bounce - step * 3.2, 0.0)
	_break_anim = maxf(_break_anim - step, 0.0)
	if busy:
		queue_redraw()

func snapshot() -> Dictionary:
	return {"open": is_open, "bounce": _bounce, "shards": _break_anim / SHARD_LIFE,
		"hits": _hits, "seed": _sid, "size": SIZE}

func _draw() -> void:
	PressScript.draw_glass_pane(self, snapshot(), ink, stock)

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	queue_redraw()
