## Shared painted-card helpers (tile, painted, line, lines) and Trick Shot's
## daily status. The Daily board that used to live here was removed
## (2026-11-03): Quests, Trick Shot, Spire, Bosses and the Bracket of Legends
## all sit on Home's "More to play" strip, and Fight of the Day is gone.
## Cards wear painted fair stalls (game/ui/home_art/daily_*.png,
## tools/event_art/scenes/daily_*.mjs).
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const HomePainting := preload("res://game/ui/home_painting.gd")
const TrickShot := preload("res://sim/trick_shot.gd")

const TRICK_SAVE := "user://trick_shot.cfg"
const TRICK_TRIES := 3
const QUESTS := Color("ffd36b")
## Painted header height on a card.
const ART_H := 132


## One painted card: a painted stall with the caption on it, then a
## body and the card's action at the bottom, lined up with its neighbour's.
## `art` names the painting (game/ui/home_art/<art>.png); `over` sits on the
## painting above the caption (Fight of the Day's critters). `border` and `bg`
## are kept for callers but no longer change the card.
## A tap anywhere on the card presses `door` (by default `action`, if a button).
static func tile(caption: String, accent: Color, _border: Color, _bg: Color, body: Array, action: Control = null, badge: Control = null, art := "", over: Control = null, art_h := ART_H, door: BaseButton = null) -> Control:
	var head := Kit.hbox(6, [line(caption.to_upper(), 18, accent)])
	if badge != null:
		head.add_child(badge)
	var v := Kit.vbox(8, [])
	for c in body:
		v.add_child(c)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(gap)
	if action != null:
		v.add_child(action)
	var p: PanelContainer
	if art == "":
		v.add_child(head)
		v.move_child(head, 0)
		p = Kit.panel(v, Kit.box(Kit.PANEL, Kit.LINE, 30, 2, 18))
	else:
		var st := Kit.box(Kit.PANEL, Kit.LINE, 30, 2, 18)
		st.set_content_margin_all(2)
		p = Kit.panel(Kit.vbox(6, [painted(art, head, over, art_h), _pad(v)]), st)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size.x = 0
	if door == null and action is BaseButton:
		door = action
	if door == null:
		return p
	var b := Kit.tap_card(p, func():
		if not door.disabled:
			door.pressed.emit(), 30)
	b.custom_minimum_size.x = 0
	return b


## A painted band with `head` on its bottom edge and `over` above it. The
## painting fades into the card at the bottom, so its lower corners vanish.
static func painted(art: String, head: Control, over: Control = null, height := ART_H) -> Control:
	var band := MarginContainer.new()
	band.custom_minimum_size.y = height
	band.add_child(HomePainting.make(art, Vector2(.5, .6), 28.0, Vector4(0, 0, .5, 1.0), Kit.PANEL))
	_shadowed(head)
	var on := Kit.vbox(2, [])
	var room := Control.new()
	room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	on.add_child(room)
	if over != null:
		on.add_child(over)
	on.add_child(head)
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 16)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 2)
	m.add_child(on)
	band.add_child(m)
	return band


## Text on a painting gets a soft dark shadow so it reads on any colour.
static func _shadowed(n: Node) -> void:
	if n is Label:
		Kit.soft_shadow(n, Color(0, 0, 0, .7), 2, 6)
	for c in n.get_children():
		_shadowed(c)


## A card's body under its painting: the card's 18px sides and bottom.
static func _pad(c: Control) -> MarginContainer:
	var m := MarginContainer.new()
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 16)
	m.add_child(c)
	return m


## A one-line label that trims with an ellipsis instead of widening its tile.
static func line(text: String, size := 22, color := Kit.FG) -> Label:
	var l := Kit.label(text, size, color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	return l


## Up to two lines of text in a tile.
static func lines(text: String, size := 21, color := Kit.FG) -> Label:
	var l := Kit.label(text, size, color, HORIZONTAL_ALIGNMENT_LEFT, true)
	l.max_lines_visible = 2
	l.custom_minimum_size.x = 200
	return l


# --- Daily Trick Shot --------------------------------------------------------------

## { tries, solved, streak } for Trick Shot `day`, from its save file.
static func trick_status(day: int) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(TRICK_SAVE) != OK:
		return {"tries": 0, "solved": false, "streak": 0}
	var tries: Array = cfg.get_value("days", str(day), [])
	return {"tries": tries.size(), "solved": tries.any(func(x): return x.result == TrickShot.SOLVED),
		"streak": cfg.get_value("stats", "streak", 0)}
