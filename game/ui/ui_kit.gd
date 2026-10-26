## Neon Critters UI kit: colours, theme and small factories for labels,
## panels, buttons and chips. Sizes are in the 720-wide design space.
extends RefCounted

const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")
const Glyph := preload("res://game/ui/glyph.gd")
const A11y := preload("res://game/a11y.gd")
const Motion := preload("res://game/ui/motion.gd")

const BG := Color("0b0a1f")
const PANEL := Color("141233")
const PANEL2 := Color("1b1842")
const LINE := Color("2b2760")
const FG := Color("f0eeff")
const MUTED := Color("a29fc9")
const ACCENT := Color("8f7bff")
const GOOD := Color("45f5a6")
const WARN := Color("ffb020")
const BAD := Color("ff5a7a")

const BUTTON_STYLES := {
	"primary": [ACCENT, Color("4b3bb0"), BG],
	"go": [GOOD, Color("1d9a65"), BG],
	"ghost": [PANEL2, Color("0a0820"), FG],
	"danger": [BAD, Color("8a1f35"), BG], ## Only for a step that can't be undone.
}


static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = FONT
	t.default_font_size = A11y.font(26)
	t.set_color("font_color", "Label", FG)
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		t.set_stylebox(s, "Button", empty)
	t.set_stylebox("panel", "ScrollContainer", empty)
	return t


static func box(bg: Color, border := Color(0, 0, 0, 0), radius := 32, border_w := 2, pad := 24) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(border_w if border.a > 0.0 else 0)
	b.set_corner_radius_all(radius)
	b.set_content_margin_all(pad)
	b.anti_aliasing = true
	return b


static func label(text: String, size := 26, color := FG, align := HORIZONTAL_ALIGNMENT_LEFT, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", A11y.font(size))
	l.set_meta("base_font", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 40
	return l


## A soft dark shadow under `l` (`spread` px wide, `drop` px down), drawn by
## a twin label behind it. Godot's own shadow_outline_size draws shadow and
## text glyph by glyph from two font textures, so every letter costs its own
## draw calls (~50 for a short line); the twin draws in two.
static func soft_shadow(l: Label, color: Color, drop := 2, spread := 6) -> void:
	var twin := Label.new()
	twin.name = "SoftShadow"
	twin.show_behind_parent = true
	twin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	twin.set_anchors_preset(Control.PRESET_FULL_RECT)
	twin.offset_top = drop
	twin.offset_bottom = drop
	twin.add_theme_color_override("font_color", color)
	twin.add_theme_color_override("font_outline_color", color)
	twin.add_theme_constant_override("outline_size", spread)
	l.add_child(twin, false, Node.INTERNAL_MODE_FRONT)
	# The label redraws whenever its words, size or font change: copy them then.
	var sync := func():
		twin.text = l.text
		twin.uppercase = l.uppercase
		twin.visible_characters = l.visible_characters
		twin.horizontal_alignment = l.horizontal_alignment
		twin.vertical_alignment = l.vertical_alignment
		twin.autowrap_mode = l.autowrap_mode
		twin.text_overrun_behavior = l.text_overrun_behavior
		twin.clip_text = l.clip_text
		twin.add_theme_font_size_override("font_size", l.get_theme_font_size("font_size"))
		twin.add_theme_constant_override("line_spacing", l.get_theme_constant("line_spacing"))
	sync.call()
	l.draw.connect(sync)


## Small uppercase section label.
static func caption(text: String, color := MUTED) -> Label:
	var l := label(text.to_upper(), 20, color)
	return l


static func vbox(sep := 16, children: Array = []) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	for c in children:
		b.add_child(c)
	return b


static func hbox(sep := 16, children: Array = [], align := BoxContainer.ALIGNMENT_BEGIN) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	b.alignment = align
	for c in children:
		b.add_child(c)
	return b


## Centres a column's content in the height it is given (put it straight in a
## ScrollContainer or a full-height parent), keeping the first `keep_top`
## children (a title row) at the top. Content taller than the room lays out
## exactly as before, so it still scrolls.
static func centre_column(col: VBoxContainer, keep_top := 0) -> void:
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if keep_top == 0:
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		return
	if col.get_child_count() <= keep_top:
		return
	var body := vbox(col.get_theme_constant("separation"))
	for c in col.get_children().slice(keep_top):
		c.reparent(body, false)
	col.add_child(body)
	centre_column(body)


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func panel(child: Control, style: StyleBox = null) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style if style else box(PANEL, LINE))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(child)
	return p


## A chunky arcade button with a darker "lip" under it.
static func button(text: String, on_press: Callable, kind := "primary", font_size := 30, height := 96) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.custom_minimum_size = Vector2(0, height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", A11y.font(font_size))
	b.set_meta("base_font", font_size)
	var cols: Array = BUTTON_STYLES[kind]
	var normal := box(cols[0], LINE if kind == "ghost" else Color(0, 0, 0, 0), 26, 2, 12)
	# A lit top edge over the dark lip below, so buttons read as raised keys.
	normal.border_color = LINE.lightened(.15) if kind == "ghost" else cols[0].lightened(.35)
	normal.set_border_width_all(0)
	normal.border_width_top = 3
	if kind == "ghost":
		normal.set_border_width_all(2)
		normal.border_width_top = 3
	normal.shadow_color = cols[1]
	normal.shadow_offset = Vector2(0, 8)
	normal.shadow_size = 1
	var pressed := normal.duplicate()
	pressed.shadow_offset = Vector2(0, 3)
	pressed.expand_margin_top = -5
	var disabled := normal.duplicate()
	disabled.bg_color = Color(cols[0], .35)
	disabled.shadow_color = Color(cols[1], .35)
	disabled.border_color = Color(normal.border_color, .35)
	for s in ["normal", "hover", "focus"]:
		b.add_theme_stylebox_override(s, normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(s, cols[2])
	b.add_theme_color_override("font_disabled_color", Color(cols[2], .5))
	b.pressed.connect(on_press)
	Motion.press(b)
	return b


## A button with a cost: "MERGE ALL (4) · 40" then the currency's glyph, never
## the currency's name. `glyph_kind` is a Glyph kind (hammer, coin, egg, gem, energy...).
static func cost_button(text: String, cost: int, glyph_kind: String, on_press: Callable, kind := "primary", font_size := 28, height := 96) -> Button:
	var b := button("", on_press, kind, font_size, height)
	var col: Color = BUTTON_STYLES[kind][2]
	var words := label((text + "  ·  " if text != "" else "").to_upper() + commas(cost), font_size, col)
	var row := hbox(8, [words, glyph(glyph_kind, font_size * 1.2, col)], BoxContainer.ALIGNMENT_CENTER)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	b.set_meta("row", row)
	# A disabled cost button fades its words and glyph with it.
	b.draw.connect(func(): row.modulate.a = .5 if b.disabled else 1.0)
	return b


## A tappable card: a flat Button with a panel look and arbitrary content.
static func card_button(content: Control, on_press: Callable, border := LINE, bg := PANEL, radius := 32, pad := 12) -> Button:
	var b := Button.new()
	var st := box(bg, border, radius, 3, pad)
	for s in ["normal", "hover", "focus", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, st)
	b.pressed.connect(on_press)
	Motion.press(b)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, pad)
	m.add_child(content)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(m)
	m.minimum_size_changed.connect(func(): b.custom_minimum_size = m.get_combined_minimum_size())
	b.custom_minimum_size = m.get_combined_minimum_size()
	return b


static func chip(text: String, color: Color, font_size := 18) -> PanelContainer:
	var st := box(Color(0, 0, 0, 0), color, 999, 2, 0)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	var p := panel(label(text.to_upper(), font_size, color), st)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return p


## "1,789" power with its burst (never the energy bolt).
static func power(value: int, size := 26, color := FG) -> HBoxContainer:
	return hbox(4, [glyph("power", size, WARN), label(commas(value), size, color)])


## A currency or count as its icon and number ("[hammer] 1,240"), never the
## currency's name. `value`: an int (gets commas) or ready text ("12+",
## "40 to 90"). `tint` colours the icon (white keeps a currency's own colours).
static func amount(kind: String, value, size := 24, color := FG, tint := Color.WHITE) -> HBoxContainer:
	var text: String = commas(value) if value is int else str(value)
	return hbox(6, [glyph(kind, roundf(size * 1.2), tint), label(text, size, color)])


## A glyph kept at its own height in a row: glyphs draw to their height, so a
## row that stretched one to the text's height would draw it into the text.
static func glyph(kind: String, side: float, color: Color, count := 1) -> Control:
	var g := Glyph.make(kind, side, color, count)
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return g


static func bar(frac: float, color: Color, height := 18) -> Control:
	var p := ProgressBar.new()
	p.show_percentage = false
	p.min_value = 0.0
	p.max_value = 1.0
	p.step = 0.0 # ProgressBar snaps to 0.01 by default: a 1% jump is several pixels on a phone.
	p.value = clampf(frac, 0.0, 1.0)
	p.custom_minimum_size = Vector2(0, height)
	p.add_theme_stylebox_override("background", box(Color("221e4f"), Color(0, 0, 0, 0), 999, 0, 0))
	p.add_theme_stylebox_override("fill", box(color, Color(0, 0, 0, 0), 999, 0, 0))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func commas(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
