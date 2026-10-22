## The one popup every fight ends on, in every mode: a sheet that slides up
## from the bottom with what the fight was (caption), the outcome on a banner
## (Victory! / Defeated / Draw), what it earned, and the buttons for what's
## next. The campaign's stage result was the model; Quick fight, 2v2, Rival,
## Challenge, Live, bosses, the Spire, Ghost Arena and Bounce Run all use it.
## The shell's own sheets use the same frame (`frame`).
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const ResultBanner := preload("res://game/ui/result_banner.gd")
const XpBar := preload("res://game/ui/xp_bar.gd")

enum Outcome { LOSE, WIN, DRAW }

const SHEET_BG := Color("16133a")
const SLIDE_SECS := .22


## The headline for an outcome, the same words in every mode.
static func headline(outcome: int) -> String:
	return ["Defeated", "Victory!", "Draw"][outcome]


static func color(outcome: int) -> Color:
	return [Kit.BAD, Kit.GOOD, Color("ffd84a")][outcome]


## WIN, LOSE or DRAW for a fight's winner side as seen from `you`.
static func outcome_of(winner: int, you := 0) -> int:
	return Outcome.DRAW if winner < 0 else (Outcome.WIN if winner == you else Outcome.LOSE)


## The caption over the banner ("STAGE 1-1 · PRICKLES", "THE SPIRE · FLOOR 3").
static func caption(text: String) -> Label:
	var cap := Kit.caption(text)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return cap


## The headline on its banner. `face`: a critter face beside it (or null).
## `text` overrides the words (a replay's "OPTIC WINS", "DOUBLE KO!").
static func banner(outcome: int, face: Control = null, text := "") -> Node:
	var head := Kit.label(text if text != "" else headline(outcome), 52, color(outcome), HORIZONTAL_ALIGNMENT_CENTER)
	var row := Kit.hbox(16, [head], BoxContainer.ALIGNMENT_CENTER) if face == null else Kit.hbox(16, [face, head], BoxContainer.ALIGNMENT_CENTER)
	var b = ResultBanner.wrap(row)
	b.set_mood(color(outcome), outcome == Outcome.WIN)
	return b


## The popup's content: caption and banner, then `body` rows, then `buttons`
## side by side (each fills its share of the row).
static func content(caption_text: String, outcome: int, body: Array = [], buttons: Array = [], face: Control = null, text := "") -> VBoxContainer:
	var v := Kit.vbox(18, [Kit.vbox(2, [caption(caption_text), banner(outcome, face, text)])])
	for c in body:
		if c != null:
			v.add_child(c)
	if not buttons.is_empty():
		for b in buttons:
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(Kit.hbox(14, buttons))
	return v


## The bottom sheet's panel: dark, an accent line along the top, round top corners.
static func panel(child: Control) -> PanelContainer:
	var st := Kit.box(SHEET_BG, Kit.ACCENT, 0, 0, 32)
	st.border_width_top = 3
	st.corner_radius_top_left = 44
	st.corner_radius_top_right = 44
	st.content_margin_bottom = 60
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", st)
	p.add_child(child)
	return p


## A full-screen dim with `content` in a sheet along the bottom edge, sliding
## up. Tapping the dim calls `on_dim` (nothing when it's empty). Add the
## returned root to a full-screen parent; `done` runs once it has stopped.
static func frame(host: Node, content: Control, height: float, on_dim := Callable(), done := Callable()) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := Button.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.focus_mode = Control.FOCUS_NONE
	var dim_style := Kit.box(Color(.02, .015, .06, .65), Color(0, 0, 0, 0), 0, 0, 0)
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		dim.add_theme_stylebox_override(st, dim_style)
	if on_dim.is_valid():
		dim.pressed.connect(on_dim)
	root.add_child(dim)
	var p := panel(content)
	root.add_child(p)
	# A zero-height rect on the bottom edge, growing upwards: the panel is
	# always exactly as tall as its content, even after wrapped text reflows.
	p.anchor_left = 0.0
	p.anchor_right = 1.0
	p.anchor_top = 1.0
	p.anchor_bottom = 1.0
	p.offset_left = 0.0
	p.offset_right = 0.0
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var slide := func(v: float) -> void:
		p.offset_top = v
		p.offset_bottom = v
	slide.call(height)
	var tw := host.create_tween()
	tw.tween_method(slide, height, 0.0, SLIDE_SECS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if done.is_valid():
		tw.finished.connect(done)
	return root


## For a fight scene outside the shell: the popup over the whole screen, on
## `parent` (a full-screen Control). On a wide screen the sheet keeps a
## phone-width column. Returns the popup root (free it to close).
static func show_over(parent: Control, content: Control, done := Callable()) -> Control:
	var size := parent.get_viewport_rect().size
	var side := maxf(0.0, (size.x - 760.0) / 2.0)
	var root := frame(parent, content, size.y, Callable(), done)
	var p: Control = root.get_child(1)
	p.offset_left = side # The slide only moves the top and bottom edges.
	p.offset_right = -side
	parent.add_child(root)
	return root


## A farming boss run's result, on the boss's screen when the run comes back
## (main.gd passes `notice`, `xp` and `caption`). `row`: the boss's own
## reward row instead of the notice text. Pops up once: a refresh doesn't
## bring it back.
static func boss_result(shell, params: Dictionary, row: Control = null) -> void:
	if not params.has("notice"):
		return
	var xp: Dictionary = params.get("xp", {})
	if row == null:
		row = Kit.label(str(params.notice), 24, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)
		row.custom_minimum_size.x = minf(640.0, shell.size.x - 80.0) # Wrapped text needs a width first.
	var body: Array = [row]
	var bars := XpBar.rows(xp, shell.sfx)
	if bars != null:
		body.append(bars)
	var ok := Kit.button("Continue", shell.close_overlay, "go", 26, 84)
	shell.mark("result_continue", ok)
	shell.sheet(content(str(params.get("caption", "Boss")), Outcome.WIN if xp.get("won", false) else Outcome.LOSE, body, [ok]))
	params.erase("notice")
