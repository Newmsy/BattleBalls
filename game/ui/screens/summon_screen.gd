## Summon Portal: random Tier 1 critters for Summon Orbs (earned, never sold).
## Odds on screen, x10 guarantees a Rare or better, shared Legendary pity, one
## free summon a day, weekly featured critter, and the Wishlist (3 picks that
## come up twice as often within their rarity). Capsules glow in their rarity's
## colour before they open.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const Summon := preload("res://game/ui/summon.gd")

static var _rng: RandomNumberGenerator


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(22)
	root.add_child(Kit.hbox(0, [Kit.label("Summon Portal", 44), Kit.spacer(), Kit.label("Orbs: %d" % p.orbs, 24, Kit.MUTED)]))

	var featured := Roster.get_critter(Summon.featured())
	var portal := _Portal.new()
	portal.custom_minimum_size = Vector2(0, 300)
	portal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var feat := Kit.hbox(14, [CritterIcon.make(featured.id, 1, 96), Kit.vbox(2, [Kit.caption("This week · Spotlight", Color("e8c8ff")),
		Kit.label("%s week" % featured.name, 32), Kit.label("%s gets half of all %s rolls." % [featured.name, Roster.RARITY_NAMES[featured.rarity]], 21, Color("e8c8ff"), HORIZONTAL_ALIGNMENT_LEFT, true)])])
	feat.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := Kit.box(Color("221046"), Color("6b3fb0"), 40, 2, 26)
	root.add_child(Kit.panel(Kit.vbox(8, [portal, feat]), st))
	root.add_child(_wishlist_panel(shell))

	var one := Kit.button("Free x1" if p.free_summon else "x1  (1 orb)", func(): _pull(shell, 1), "ghost", 28, 96)
	var ten := Kit.button("x10  (10 orbs)", func(): _pull(shell, 10), "primary", 28, 96)
	one.disabled = not p.free_summon and p.orbs < 1
	ten.disabled = p.orbs < 10
	shell.mark("pull1", one)
	shell.mark("pull10", ten)
	root.add_child(Kit.hbox(14, [one, ten]))
	root.add_child(Kit.label("Every summon is Tier 1. A x10 always has a Rare or better.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))

	var odds := GridContainer.new()
	odds.columns = Roster.RARITIES.size()
	odds.add_theme_constant_override("h_separation", 6)
	for r in Roster.RARITIES:
		var pct: float = 0.0
		for o in Summon.ODDS:
			if o[0] == r:
				pct = o[1]
		var col: Color = Roster.RARITY_COLORS[r]
		var cell := Kit.panel(Kit.vbox(0, [Kit.label(("%.1f%%" % pct).replace(".0%", "%"), 24, col, HORIZONTAL_ALIGNMENT_CENTER), Kit.label(Roster.RARITY_NAMES[r], 15, col, HORIZONTAL_ALIGNMENT_CENTER)]),
			Kit.box(Kit.PANEL2, Kit.LINE, 16, 2, 6))
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		odds.add_child(cell)
	root.add_child(Kit.panel(Kit.vbox(12, [Kit.caption("Odds (same as campaign drops)"), odds])))

	var pity: int = p.legendary_pity
	root.add_child(Kit.panel(Kit.vbox(10, [Kit.hbox(0, [Kit.caption("Legendary pity"), Kit.spacer(), Kit.label("%d Rare+ rolls left" % pity, 22)]),
		Kit.bar(float(Summon.PITY_RESET - pity) / Summon.PITY_RESET, Glyph.GOLD),
		Kit.label("Shared with campaign and hunt drops, so switching never resets it.", 21, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])))
	root.add_child(Kit.label("Summon Orbs come from boss first clears, daily login, account levels and achievements. They are never sold.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	return root


const WISH := Color("ff5fc8")


static func _wishlist_panel(shell) -> Control:
	var p = shell.profile
	var edit := Kit.button("Edit", func(): _open_picker(shell), "ghost", 22, 64)
	edit.size_flags_horizontal = Control.SIZE_SHRINK_END
	edit.custom_minimum_size.x = 150
	shell.mark("wishlist_edit", edit)
	var head := Kit.hbox(12, [Kit.caption("Wishlist", WISH), Kit.label("%d / %d" % [p.wishlist.size(), p.WISHLIST_MAX], 22, Kit.MUTED), Kit.spacer(), edit])
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	var slots := Kit.hbox(12)
	for i in p.WISHLIST_MAX:
		var v: Control
		if i < p.wishlist.size():
			var id: String = p.wishlist[i]
			var c := Roster.get_critter(id)
			var name := Kit.label(c.name, 20, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
			name.clip_text = true
			name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			v = Kit.vbox(0, [_centered(CritterIcon.make(id, 1, 96, false, not p.owns(id))), name,
				Kit.label(_pct(Summon.chance(p, id)) + " a pull", 18, Roster.RARITY_COLORS[c.rarity], HORIZONTAL_ALIGNMENT_CENTER)])
		else:
			v = Kit.vbox(0, [Kit.label("+", 64, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER), Kit.label("Pick one", 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)])
		var slot := Kit.card_button(v, func(): _open_picker(shell), Color(WISH, .6) if i < p.wishlist.size() else Kit.LINE, Kit.PANEL2, 24, 8)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slots.add_child(slot)
	return Kit.panel(Kit.vbox(12, [head, slots,
		Kit.label("Wishlisted critters come up twice as often as others of their rarity, in summons and campaign drops. Rarity odds and pity stay the same.", 21, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)]))


## Bottom sheet listing every critter by rarity; tap to add or remove a pick.
static func _open_picker(shell) -> void:
	var p = shell.profile
	var count := Kit.label("", 22, Kit.MUTED)
	var tiles := {}
	var refresh := func():
		count.text = "%d / %d picked" % [p.wishlist.size(), p.WISHLIST_MAX]
		for id in tiles:
			var on: bool = p.on_wishlist(id)
			tiles[id].get_theme_stylebox("normal").border_color = WISH if on else Kit.LINE
			tiles[id].get_theme_stylebox("normal").bg_color = Color(WISH, .18) if on else Kit.PANEL2
	var list := Kit.vbox(14)
	var rows := 0
	for r in Roster.RARITIES:
		var pool: Array = Roster.CRITTERS.filter(func(c): return c.rarity == r)
		if pool.is_empty():
			continue
		list.add_child(Kit.caption(Roster.RARITY_NAMES[r], Roster.RARITY_COLORS[r]))
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		for c in pool:
			var name := Kit.label(c.name, 16, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
			name.clip_text = true
			name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			var id: String = c.id
			var t := Kit.card_button(Kit.vbox(0, [_centered(CritterIcon.make(id, 1, 84, false, not p.owns(id))), name]), func():
				if not p.toggle_wishlist(id):
					shell.toast("Your wishlist is full. Tap a pick to remove it.")
				refresh.call(), Kit.LINE, Kit.PANEL2, 20, 6)
			t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tiles[id] = t
			shell.mark("wish_" + id, t)
			grid.add_child(t)
		rows += ceili(pool.size() / 5.0)
		list.add_child(grid)
	refresh.call()
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = minf(rows * 130.0 + Roster.RARITIES.size() * 44.0, maxf(400.0, shell.size.y * .55))
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var done := Kit.button("Done", func(): shell.close_overlay(); shell.refresh(), "go", 28, 90)
	shell.mark("wishlist_done", done)
	shell.sheet(Kit.vbox(16, [Kit.hbox(0, [Kit.label("Wishlist", 36), Kit.spacer(), count]),
		# Fixed line breaks: a wrapping label has no width yet when the sheet measures itself.
		Kit.label("Pick up to 3 critters you're chasing. Each comes up\ntwice as often as others of its rarity. Change any time.", 21, Kit.MUTED),
		scroll, done]))


static func _pct(x: float) -> String:
	return ("%.2f%%" % x) if x < 1.0 else ("%.1f%%" % x)


static func _centered(c: Control) -> Control:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc


static func _pull(shell, n: int) -> void:
	var p = shell.profile
	if n == 1 and p.free_summon:
		p.free_summon = false
	elif not p.spend_orbs(n):
		shell.toast("Not enough Summon Orbs.")
		return
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()
	var ids: Array = Summon.pull(p, n, _rng)
	var fresh: Array = ids.map(func(id): return not p.owns(id))
	p.add_copies(ids)
	print("UI_SUMMON ", ",".join(ids))
	shell.overlay(_reveal(shell, ids, fresh), "reveal")


static func _reveal(shell, ids: Array, fresh: Array) -> Control:
	var root := PanelContainer.new()
	root.add_theme_stylebox_override("panel", Kit.box(Color("120a2e"), Color(0, 0, 0, 0), 0, 0, 40))
	var v := Kit.vbox(24)
	v.add_child(Kit.caption("Summon x%d" % ids.size(), Color("e8c8ff")))
	v.get_child(0).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(Kit.label("Tap a capsule to open it", 36, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 1 if ids.size() == 1 else 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 18)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var caps: Array = []
	var side := 360.0 if ids.size() == 1 else 120.0
	for i in ids.size():
		var cap := _Capsule.new()
		cap.setup(ids[i], fresh[i], side)
		cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caps.append(cap)
		grid.add_child(cap)
	var mid := CenterContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(grid)
	v.add_child(mid)
	var open_all := Kit.button("Open all", func():
		for i in caps.size():
			caps[i].get_tree().create_timer(i * .14).timeout.connect(caps[i].open), "ghost", 28, 96)
	var done := Kit.button("Done", func(): shell.close_overlay(); shell.refresh(), "go", 28, 96)
	shell.mark("open_all", open_all)
	shell.mark("reveal_done", done)
	v.add_child(Kit.hbox(14, [open_all, done]))
	root.add_child(v)
	return root


## A capsule that glows in its critter's rarity colour, then pops open.
class _Capsule extends Button:
	const Kit := preload("res://game/ui/ui_kit.gd")
	const CritterIcon := preload("res://game/ui/critter_icon.gd")
	const Roster := preload("res://game/ui/roster.gd")

	var id := ""
	var is_new := false
	var opened := false
	var side := 120.0
	var _t := 0.0
	var _content: VBoxContainer

	func setup(id_: String, is_new_: bool, side_: float) -> void:
		id = id_
		is_new = is_new_
		side = side_
		custom_minimum_size = Vector2(side, side + side * .35)
		var empty := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			add_theme_stylebox_override(s, empty)
		pressed.connect(open)

	func open() -> void:
		if opened:
			return
		opened = true
		var c := Roster.get_critter(id)
		_content = Kit.vbox(0, [CritterIcon.make(id, 1, side), Kit.label(c.name, 34 if side > 200 else 17, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)])
		_content.get_child(1).clip_text = true
		_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_content)
		pivot_offset = custom_minimum_size / 2.0
		scale = Vector2(.3, .3)
		create_tween().tween_property(self, "scale", Vector2.ONE, .4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var col: Color = Roster.RARITY_COLORS[Roster.get_critter(id).rarity]
		var c := Vector2(size.x / 2.0, side * .56)
		var r := side * .36
		if not opened:
			var pulse := .5 + .5 * sin(_t * 5.0)
			for k in 4:
				draw_circle(c, r * (1.1 + k * .1 + pulse * .05), Color(col, .12))
			draw_circle(c, r, col)
			# Top half white shell, seam band.
			var top := PackedVector2Array()
			for i in 17:
				var a := PI + i * PI / 16
				top.append(c + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(top, Color.WHITE)
			draw_line(c - Vector2(r, 0), c + Vector2(r, 0), Color("1b1842"), r * .12)
			draw_circle(c, r * .16, Color("1b1842"))
			draw_circle(c, r * .09, Color.WHITE)
		elif is_new:
			var tag := Vector2(size.x / 2.0, side * .1)
			draw_rect(Rect2(tag - Vector2(side * .2, side * .07), Vector2(side * .4, side * .14)), Kit.BAD)
			draw_string(Kit.FONT, tag + Vector2(-side * .17, side * .045), "NEW", HORIZONTAL_ALIGNMENT_CENTER, side * .34, int(side * .12), Color.WHITE)


## The swirling portal at the top of the screen.
class _Portal extends Control:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		for i in range(6, 0, -1):
			var rx := 30.0 + i * 24.0
			var a0 := _t * (.3 + i * .12) * (1.0 if i % 2 else -1.0)
			var pts := PackedVector2Array()
			for k in 25:
				var a := a0 + k * (PI * 1.4) / 24
				pts.append(c + Vector2(cos(a) * rx, sin(a) * rx * .62))
			draw_polyline(pts, Color.from_hsv((270.0 + i * 12.0) / 360.0, .7, 1.0, .3 + i * .08), 5.0, true)
		for k in 8:
			draw_circle(c, 70.0 - k * 8.0, Color(.9, .78, 1.0, .1 + k * .06))
		for i in 14:
			var a := float(i) * 2.4 + _t * .5
			var rr := fmod(_t * 50.0 + i * 37.0, 160.0)
			draw_circle(c + Vector2(cos(a) * rr, sin(a) * rr * .62), 3.0, Color(1, .9, 1, 1.0 - rr / 160.0))
