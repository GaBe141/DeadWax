extends VBoxContainer
## The Book's LEVEL page. It reads Main's experience snapshot and emits one
## intent per choice; Main validates, saves and applies the gain, then refreshes
## this page. Nothing here mutates XP, health or Skip.

signal growth_requested(stat: String)

const Press := preload("res://scripts/press.gd")
const XpScript := preload("res://scripts/xp_state.gd")
const AuditionerScript := preload("res://scripts/auditioner.gd")
const TonearmScript := preload("res://scripts/tonearm.gd")
const INK := Color("f2e1bc")
const FADED := Color("c2ae87")
const ACCENT := Color("d6a968")
const TITLES := {"ring": "RING", "body": "BODY", "bite": "BITE"}
const FIGHT_LABELS := {
	"ring": "A rung-back rings a voice",
	"body": "Hits your needle can take",
	"bite": "Light hits to down the Tonearm",
}
const BLURBS := {
	"ring": "Strikes and rung-back parries ring harder, so a voice peaks and shatters sooner.",
	"body": "One more notch on your needle. It arrives filled.",
	"bite": "Every hit takes more from a foe's health, the Tonearm's included.",
}

var book: CanvasLayer
var motion: Node
## Needle capacity before levels (stall, equipment), supplied by Main.
var needle_base := 3
var _model: RefCounted
var _level: Label
var _totals: Label
var _bar_fill: ColorRect
var _bar: Control
var _waiting: Label
var _notice: Label
var _rules: Label
var _ranks: Dictionary = {}
var _effects: Dictionary = {}
var _fights: Dictionary = {}
var _buttons: Dictionary = {}
var _cards: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_build()

func _build() -> void:
	var header := HBoxContainer.new()
	add_child(header)
	_level = _label("LEVEL 1", Press.SIZE_TITLE, INK)
	_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_level)
	_totals = _label("", Press.SIZE_BODY, ACCENT)
	_totals.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_totals.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_totals)
	_bar = Control.new()
	_bar.custom_minimum_size.y = 4
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar)
	var track := ColorRect.new()
	track.color = Color("2e4c4d")
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(track)
	track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bar_fill = ColorRect.new()
	_bar_fill.color = ACCENT
	_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_bar_fill)
	_bar.resized.connect(_layout_bar)
	_waiting = _text(self, Press.SIZE_BODY, ACCENT)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 14)
	add_child(cards)
	for stat in XpScript.STATS:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", book._panel_style())
		cards.add_child(panel)
		_cards[stat] = panel
		var margin := MarginContainer.new()
		for side in ["left", "top", "right", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 16)
		panel.add_child(margin)
		var body := VBoxContainer.new()
		body.add_theme_constant_override("separation", 8)
		margin.add_child(body)
		var heading := HBoxContainer.new()
		body.add_child(heading)
		var title := _label(String(TITLES[stat]), Press.SIZE_HEADING, INK)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(title)
		var rank := _label("", Press.SIZE_BODY, ACCENT)
		heading.add_child(rank)
		_ranks[stat] = rank
		var blurb := _text(body, Press.SIZE_SMALL, FADED)
		blurb.text = String(BLURBS[stat])
		blurb.custom_minimum_size.y = 44
		body.add_child(_rule())
		var effect := _text(body, Press.SIZE_SMALL, INK)
		_effects[stat] = effect
		var fight := _text(body, Press.SIZE_SMALL, ACCENT)
		_fights[stat] = fight
		var button := Button.new()
		button.name = "Choose" + String(TITLES[stat]).capitalize()
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size.y = 40
		button.add_theme_font_override("font", Press.BodyFont)
		button.add_theme_font_size_override("font_size", Press.SIZE_SMALL)
		for key in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			button.add_theme_color_override(key, INK)
		button.add_theme_color_override("font_disabled_color", FADED)
		button.pressed.connect(_request.bind(stat))
		book._apply_card_style(button, true)
		button.add_theme_stylebox_override("disabled", book._card_style(false, false, false))
		motion.bind_button(button, ACCENT)
		body.add_child(button)
		_buttons[stat] = button
	_notice = _text(self, Press.SIZE_SMALL, ACCENT)
	_rules = _text(self, Press.SIZE_TINY, FADED)
	_rules.text = ("XP · hit %d · Accent, hot groove or pocket hit %d · rung-back parry %d · kill %d–%d · freeing 0.\n"
		+ "A story foe's hits and parries pay up to %d XP over its whole life, and its kill pays once. Echo Trials can be cleared again.") % [
		XpScript.HIT_XP, XpScript.BIG_HIT_XP, XpScript.PARRY_XP,
		XpScript.kill_xp(&"voice"), XpScript.kill_xp(&"tonearm"), XpScript.FOE_BUDGET]

func refresh(model: RefCounted, notice := "") -> void:
	_model = model
	if _level == null:
		return
	var progress: Dictionary = model.progress() if model != null else XpScript.new().progress()
	var picks := int(progress.picks)
	_level.text = "LEVEL %d" % int(progress.level)
	_totals.text = "XP %d  ·  MAX LEVEL" % int(progress.xp) if bool(progress.max) else "XP %d / %d" % [int(progress.xp), int(progress.next)]
	_layout_bar()
	if picks > 0:
		_waiting.text = "%d %s WAITING · each level grants one gain" % [picks, "CHOICE" if picks == 1 else "CHOICES"]
	elif bool(progress.max):
		_waiting.text = "Every level is earned."
	else:
		_waiting.text = "Next choice at level %d · %d XP to go" % [int(progress.level) + 1, int(progress.next) - int(progress.xp)]
	var ranks: Dictionary = progress.ranks
	for stat in XpScript.STATS:
		var rank := int(ranks.get(stat, 0))
		var cap := int(XpScript.RANK_CAPS[stat])
		(_ranks[stat] as Label).text = "RANK %d / %d" % [rank, cap]
		(_effects[stat] as Label).text = _effect_text(stat, rank, cap)
		(_fights[stat] as Label).text = _fight_text(stat, rank, cap)
		var button: Button = _buttons[stat]
		var full := rank >= cap
		button.text = "FULL" if full else "Choose %s" % String(TITLES[stat]).capitalize()
		button.disabled = model == null or not bool(model.can_choose(stat))
		book._apply_card_style(button, not button.disabled)
	_notice.text = notice
	_notice.visible = not notice.is_empty()
	# A completed choice can disable the focused button. Restore a usable target.
	var focus := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if focus != null and is_ancestor_of(focus) and focus is Button and focus.disabled:
		call_deferred("focus_selected")

## What a rank changes in an actual fight, from the foes' own constants.
func _fight_text(stat: String, rank: int, cap: int) -> String:
	var now := _fight_value(stat, rank)
	var label: String = String(FIGHT_LABELS.get(stat, ""))
	if rank >= cap:
		return "%s: %s" % [label, now]
	return "%s: %s → %s" % [label, now, _fight_value(stat, rank + 1)]

func _fight_value(stat: String, rank: int) -> String:
	match stat:
		"ring":
			return "%d%%" % roundi(AuditionerScript.RES_PARRY * (1.0 + XpScript.RING_STEP * rank) * 100.0)
		"body":
			return "%d" % (needle_base + XpScript.BODY_STEP * rank)
		_:
			var damage := TonearmScript.HP_PER_HIT * (1.0 + XpScript.BITE_STEP * rank)
			return "%d" % ceili(TonearmScript.HP_MAX / damage - 0.0001)

func _rule() -> ColorRect:
	var rule := ColorRect.new()
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.custom_minimum_size.y = 1
	rule.color = Color("52716d")
	return rule

func _effect_text(stat: String, rank: int, cap: int) -> String:
	var now := _value(stat, rank)
	if rank >= cap:
		return "%s · full" % now
	return "%s → %s" % [now, _value(stat, rank + 1)]

func _value(stat: String, rank: int) -> String:
	match stat:
		"ring": return "Resonance ×%.2f" % (1.0 + XpScript.RING_STEP * rank)
		"body": return "Needle %+d" % (XpScript.BODY_STEP * rank)
		_: return "Damage ×%.2f" % (1.0 + XpScript.BITE_STEP * rank)

func focus_selected() -> void:
	if not is_visible_in_tree():
		return
	for stat in XpScript.STATS:
		var button: Button = _buttons[stat]
		if not button.disabled:
			button.grab_focus()
			return
	(_buttons[XpScript.STATS[0]] as Button).grab_focus()

func waiting_text() -> String:
	return _waiting.text if _waiting != null else ""

func choice_button(stat: String) -> Button:
	return _buttons.get(stat) as Button

func _request(stat: String) -> void:
	var button: Button = _buttons.get(stat)
	if button == null or button.disabled or not book.is_open() or not is_visible_in_tree():
		return
	growth_requested.emit(stat)

func _layout_bar() -> void:
	if _bar == null or _bar_fill == null:
		return
	var ratio := 0.0
	if _model != null:
		var progress: Dictionary = _model.progress()
		ratio = 1.0 if bool(progress.max) or int(progress.span) <= 0 else float(progress.into) / float(progress.span)
	_bar_fill.position = Vector2.ZERO
	_bar_fill.size = Vector2(_bar.size.x * clampf(ratio, 0.0, 1.0), _bar.size.y)

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	if font_size >= Press.SIZE_TITLE:
		Press.set_display(label, font_size, color)
	else:
		Press.set_body(label, font_size, color)
	return label

func _text(parent: Node, font_size: int, color: Color) -> Label:
	var label := _label("", font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label
