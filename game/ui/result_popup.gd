## The one popup every fight ends on, in every mode: a modal card that pops
## up in the middle of the screen with what the fight was (caption), the outcome on a banner
## (Victory! / Defeated / Draw), what it earned, and the buttons for what's
## next. The campaign's stage result was the model; Quick fight, 2v2, Rival,
## Challenge, Live, bosses, the Spire, Ghost Arena and Bounce Run all use it.
## The shell's own sheets use the same frame (`frame`).
extends RefCounted

const A11y := preload("res://game/a11y.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const ResultBanner := preload("res://game/ui/result_banner.gd")
const XpBar := preload("res://game/ui/xp_bar.gd")
const FactionRing := preload("res://game/ui/faction_ring.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Motion := preload("res://game/ui/motion.gd")

enum Outcome { LOSE, WIN, DRAW }

const SHEET_BG := Color("16133a")
const SLIDE_SECS := .22
const MAX_WIDTH := 760.0 ## A phone-width column on a wide screen.
const MARGIN := 24.0 ## Kept clear round the card, so it never touches an edge.
const PAD := 32.0 ## The card's own padding inside its border.
const RISE := 48.0 ## How far the card rises as it fades in.
const POP_FROM := .88 ## The scale the card grows from as it rises.
const OUT_SECS := .12


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


## The modal's card: dark, round corners, an accent line round the edge.
static func panel(child: Control) -> PanelContainer:
	var st := Kit.box(SHEET_BG, Kit.ACCENT, 44, 3, int(PAD))
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", st)
	p.add_child(child)
	return p


## Side margin for a card on a screen `width` wide: MARGIN on a phone, a
## centred MAX_WIDTH column on anything wider.
static func side(width: float) -> float:
	return maxf(MARGIN, (width - MAX_WIDTH) / 2.0)


## The width a card's content gets on a screen `width` wide: what wrapped
## text should measure itself against so the card never runs off the side.
static func inner_width(width: float) -> float:
	return width - 2.0 * (side(width) + PAD)


## Nothing in a card may ask to be wider than the card's inside, or the card
## grows past the screen's right edge.
static func _clamp_width(c: Node, limit: float) -> void:
	if c is Control and c.custom_minimum_size.x > limit:
		c.custom_minimum_size.x = limit
	for k in c.get_children():
		_clamp_width(k, limit)


## Fades `c` in while it rises RISE px into place (just the fade with reduced
## motion). `move` sets its offset from the resting place.
static func pop_in(_host: Node, c: CanvasItem, move: Callable, done := Callable()) -> Tween:
	var rise := RISE * A11y.motion()
	c.modulate.a = 0.0
	move.call(rise)
	# Bound to `c`, so a sheet replaced mid pop-in (Settings re-opening on a
	# toggle) takes its tween with it instead of animating a freed card.
	var tw := c.create_tween().set_parallel()
	tw.tween_property(c, "modulate:a", 1.0, SLIDE_SECS * .8)
	tw.tween_method(move, rise, 0.0, SLIDE_SECS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if A11y.motion() > 0.0 and c is Control:
		# And grows into place with a little overshoot.
		var card := c as Control
		card.scale = Vector2(POP_FROM, POP_FROM)
		tw.tween_method(func(s: float) -> void:
			card.pivot_offset = card.size / 2.0
			card.scale = Vector2(s, s), POP_FROM, 1.0, SLIDE_SECS * 1.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if done.is_valid():
		tw.finished.connect(done)
	return tw


## Earned crowns (or stars) slam into place one by one with a thud, after
## the banner has opened; unearned ones just fade in. `slots`: the row's
## children, `earned` how many from the left are lit. Returns when it ends.
static func stamp(slots: Array, earned: int, sfx = null, start := .45) -> float:
	var at := start
	for k in slots.size():
		var c: Control = slots[k]
		if A11y.motion() == 0.0:
			continue
		var lit := k < earned
		c.modulate.a = 0.0
		var tw := c.create_tween()
		tw.tween_interval(at)
		tw.tween_callback(func():
			c.modulate.a = 1.0
			c.pivot_offset = c.size / 2.0
			c.scale = Vector2(2.3, 2.3) if lit else Vector2(.8, .8)
			c.rotation = -.25 if lit else 0.0
			if lit and sfx != null:
				sfx.play("clunk", -4.0, 1.0 + .08 * k))
		tw.set_parallel()
		tw.tween_property(c, "scale", Vector2.ONE, .24 if lit else .15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "rotation", 0.0, .2).set_ease(Tween.EASE_OUT)
		at += .2 if lit else .08
	return at


## Reward cards pop out one after another from `start`; a card with a glow
## colour (Rare and up, a new critter) sends out a ring of it as it lands.
## `cards`: [[Control, Color or null], ...].
static func drop_in(cards: Array, sfx = null, start := 1.0) -> void:
	var at := start
	for k in cards.size():
		var c: Control = cards[k][0]
		var glow = cards[k][1]
		if A11y.motion() == 0.0:
			return
		c.modulate.a = 0.0
		var tw := c.create_tween()
		tw.tween_interval(at)
		tw.tween_callback(func():
			c.modulate.a = 1.0
			c.pivot_offset = c.size / 2.0
			c.scale = Vector2.ZERO
			c.rotation = -.3
			if sfx != null:
				sfx.play("summon_pop", -6.0, 1.0 + .06 * k))
		tw.set_parallel()
		tw.tween_property(c, "scale", Vector2.ONE, .3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "rotation", 0.0, .26).set_ease(Tween.EASE_OUT)
		if glow is Color:
			tw.set_parallel(false)
			tw.tween_property(c, "modulate", Color(1.0 + glow.r * .8, 1.0 + glow.g * .8, 1.0 + glow.b * .8), .08)
			tw.tween_property(c, "modulate", Color.WHITE, .4)
		at += .14


## What a result paid, as a row of cards that drop in one by one, each
## number counting up as its card lands. `items`: [{"icon": Control,
## "n": int (0 for none), "text": String (under the icon, instead of a
## number), "glow": Color or null, "pill": a top-bar pill ("coin", "orb",
## "energy"), or "tab" + "home_icon" (see send_home)}]. Whatever a card
## shows flies from it to its pill or tab when the popup closes.
static func reward_cards(items: Array, sfx = null, start := .55) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var cards: Array = []
	var at := start
	for it in items:
		var icon: Control = it.icon
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var n := int(it.get("n", 0))
		var words := Kit.label(str(it.get("text", "")) if n == 0 else "+0", 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
		var glow = it.get("glow")
		var card := Kit.panel(Kit.vbox(4, [icon, words]), Kit.box(Kit.PANEL2, Color(glow, .8) if glow is Color else Kit.LINE, 22, 2, 10))
		card.custom_minimum_size.x = 104
		send_home(card, str(it.get("pill", "")), str(it.get("tab", "")), it.get("home_icon", Callable()))
		row.add_child(card)
		cards.append([card, glow])
		if n > 0:
			if A11y.motion() == 0.0:
				words.text = "+" + Kit.commas(n)
			else:
				Motion.count(words, 0, n, .45, func(v: int) -> String: return "+" + Kit.commas(v), at + .1)
		at += .14
	drop_in(cards, sfx, start)
	return row


## Tags a reward card so that when its popup closes (shell.close_overlay)
## what it shows flies from it: into a top-bar `pill` ("coin", "orb",
## "energy"), or as `icon` (a Callable making a Control) into a tab's icon.
static func send_home(card: Control, pill := "", tab := "", icon := Callable()) -> Control:
	if pill != "":
		card.set_meta("home_pill", pill)
	elif tab != "" and icon.is_valid():
		card.set_meta("home_tab", tab)
		card.set_meta("home_icon", icon)
	return card


## A boss result's prizes ({coins, orbs, hammers, lures, sigils, bundle,
## gear, dyes, xp}, whichever it has) as reward_cards.
static func boss_rewards(r: Dictionary, sfx = null) -> Control:
	var items: Array = []
	var pill_of := {"coins": ["coin", "coin"], "orbs": ["orb", "orb"], "hammers": ["hammer", ""], "lures": ["target", ""]}
	var counts := {}
	for k in pill_of:
		counts[k] = int(r.get(k, 0))
	for b in r.get("bundle", []):
		if counts.has(str(b.kind)):
			counts[b.kind] += int(b.n)
	for g in r.get("gear", []):
		var col: Color = load("res://game/ui/gear_tier.gd").color(int(g.tier))
		var art: Control = load("res://game/ui/gear_art.gd").piece(g.type, g.tier, 64, col)
		items.append({"icon": art, "text": load("res://game/ui/gear_tier.gd").label(int(g.tier)), "glow": col if int(g.tier) >= 3 else null,
			"tab": "bag", "home_icon": func(): return load("res://game/ui/gear_art.gd").piece(g.type, g.tier, 48, col)})
	for k in counts:
		if counts[k] > 0:
			var jackpot: bool = k == "coins" and r.get("broken", false)
			var glyph: String = pill_of[k][0]
			items.append({"icon": Glyph.make(glyph, 56, Kit.FG), "n": counts[k], "pill": pill_of[k][1], "glow": Color("ffd34e") if jackpot else null,
				"tab": "bag", "home_icon": func(): return Glyph.make(glyph, 46, Kit.FG)})
	if int(r.get("sigils", 0)) > 0:
		var fam_col: Color = load("res://sim/talents.gd").COLORS.get(str(r.get("family", "")), Kit.ACCENT)
		items.append({"icon": Glyph.make("token", 56, fam_col), "n": int(r.sigils), "glow": fam_col})
	for d in r.get("dyes", []):
		var dye: Dictionary = load("res://game/glow/dyes.gd").dye(str(d.id))
		var col := Color(dye.colors[0])
		items.append({"icon": Glyph.make("dye", 56, col), "text": "Unlocked!" if d.unlocked else "%d/%d" % [d.drops, d.need], "glow": col if d.unlocked else null})
	if items.is_empty():
		return null
	return reward_cards(items, sfx)


## A closed popup (frame's root) shrinks and fades away, then frees itself.
## It takes no taps meanwhile, so the screen under it is live at once.
static func pop_out(root: Control) -> void:
	root.propagate_call("set", ["mouse_filter", Control.MOUSE_FILTER_IGNORE])
	var card: Control = null
	for c in root.get_children():
		if c is PanelContainer:
			card = c
	var tw := root.create_tween().set_parallel()
	tw.tween_property(root, "modulate:a", 0.0, OUT_SECS)
	if card != null:
		card.pivot_offset = card.size / 2.0
		tw.tween_property(card, "scale", Vector2(.92, .92), OUT_SECS).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(root.queue_free)


## A full-screen dim with `content` in a card in the middle of the screen,
## popping in. Tapping the dim calls `on_dim` (nothing when it's empty). Add
## the returned root to a full-screen parent; `done` runs once it has stopped.
## `height` is the screen height: a card taller than it scrolls inside.
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
	# A zero-height rect across the middle, growing both ways: the card is
	# always exactly as tall as its content, even after wrapped text reflows.
	var w: float = (host as Control).size.x if host is Control else MAX_WIDTH
	var x := side(w)
	_clamp_width(content, inner_width(w))
	p.anchor_left = 0.0
	p.anchor_right = 1.0
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = x
	p.offset_right = -x
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	_fit(p, content, height)
	pop_in(host, p, func(v: float) -> void:
		p.offset_top = v
		p.offset_bottom = v, done)
	return root


## Never off-screen: content taller than the screen (less margins) moves into
## a scroll box once it has laid out.
static func _fit(p: PanelContainer, content: Control, height: float) -> void:
	var limit := height - MARGIN * 2.0 - 64.0 # The card's own padding.
	if content.get_combined_minimum_size().y <= limit or content is ScrollContainer:
		return
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = limit
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.remove_child(content)
	scroll.add_child(content)
	p.add_child(scroll)


## For a fight scene outside the shell: the popup over the whole screen, on
## `parent` (a full-screen Control). Returns the popup root (free it to close).
static func show_over(parent: Control, content: Control, done := Callable()) -> Control:
	var root := frame(parent, content, parent.get_viewport_rect().size.y, Callable(), done)
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
	if row == null and xp.get("won", xp.has("broken")):
		row = boss_rewards(xp, shell.sfx) # Won: the prizes drop in as cards.
	if row == null:
		row = Kit.label(str(params.notice), 24, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)
		row.custom_minimum_size.x = inner_width(shell.size.x) # Wrapped text needs a width first.
	var body: Array = [row, FactionRing.rows(shell.profile.take_faction_gains(), shell.sfx, .45, FactionRing.spend_in(shell))]
	var bars := XpBar.rows(xp, shell.sfx)
	if bars != null:
		body.append(bars)
	var ok := Kit.button("Continue", shell.close_overlay, "go", 26, 84)
	shell.mark("result_continue", ok)
	var popup := content(str(params.get("caption", "Boss")), Outcome.WIN if xp.get("won", false) else Outcome.LOSE, body, [ok])
	shell.sheet(popup)
	params.erase("notice")
