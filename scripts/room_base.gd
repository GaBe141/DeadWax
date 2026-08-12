extends Node2D
## Base for graybox rooms (strata). Rooms build their geometry in _ready
## and expose an air profile the player body reads.

const GrooveScript := preload("res://scripts/hot_groove.gd")
const PatchScript := preload("res://scripts/polish_patch.gd")

var band_name := ""
var band_desc := ""
var spawn_pos := Vector2.ZERO
var death_y := 2000.0
var cam_limits := Rect2(-500, -2000, 4000, 4000)

# air profile
var air_density := 0.0
var gravity_mult := 1.0
var fall_cap_mult := 1.0
var groove_mult := 1.0
var air_strikes_max := 0
var muted := false                 # HUSH rules: resonance systems off

var bg_color := Color(0.85, 0.83, 0.78)
var ink := Color(0.14, 0.13, 0.12)

func platform(pos: Vector2, size: Vector2) -> void:
	var b := StaticBody2D.new()
	b.position = pos
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	var vis := ColorRect.new()
	vis.color = ink
	vis.size = size
	vis.position = -size / 2.0
	b.add_child(vis)
	add_child(b)

func groove(pos: Vector2) -> void:
	var p := GrooveScript.new()
	p.position = pos
	add_child(p)

func patch(pos: Vector2) -> void:
	var d := PatchScript.new()
	d.position = pos
	add_child(d)

func sign_label(pos: Vector2, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_color_override("font_color", Color(ink.r, ink.g, ink.b, 0.85))
	l.add_theme_font_size_override("font_size", 15)
	add_child(l)
