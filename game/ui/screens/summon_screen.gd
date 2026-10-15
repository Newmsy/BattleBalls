## Summon Portal: random Tier 1 critters for Summon Orbs (earned, never sold).
## Odds on screen, x10 guarantees a Rare or better, shared Legendary pity, one
## free summon a day, weekly featured critter, and the Wishlist (3 picks that
## come up twice as often within their rarity). Capsules glow in their rarity's
## colour, then open on their own one by one with a burst that grows with rarity.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const Summon := preload("res://game/ui/summon.gd")
const Analytics := preload("res://game/online/analytics.gd")
const Dev := preload("res://game/dev.gd")

static var _rng: RandomNumberGenerator


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(18)
	var odds_lines := []
	for r in Roster.RARITIES:
		for o in Summon.ODDS:
			if o[0] == r:
				odds_lines.append("%s %s" % [Roster.RARITY_NAMES[r], ("%.1f%%" % o[1]).replace(".0%", "%")])
	var how: Control = shell.info_button("Odds and pity", [
		"Every summon is a Tier 1 critter. Odds (the same as campaign drops): " + ", ".join(odds_lines) + ".",
		"A x10 always has a Rare or better.",
		"Wishlist: your picks come up twice as often as others of their rarity, in summons and campaign drops. Rarity odds and pity stay the same.",
		"Legendary pity: a Legendary is guaranteed within %d Rare+ rolls. It's shared with campaign and hunt drops, so switching never resets it." % Summon.PITY_RESET,
		"Summon Orbs come from boss first clears, daily login, account levels and achievements. They are never sold."], "summon_info")
	var orb := Glyph.make("orb", 30)
	orb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root.add_child(Kit.hbox(10, [Kit.label("Summon Portal", 40), Kit.spacer(), orb, Kit.label(str(p.orbs), 26), how], BoxContainer.ALIGNMENT_CENTER))

	var featured := Roster.get_critter(Summon.featured())
	var portal := _Portal.new()
	portal.custom_minimum_size = Vector2(0, 200)
	portal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var feat := Kit.hbox(14, [CritterIcon.make(featured.id, 1, 84), Kit.vbox(2, [Kit.caption("This week · Spotlight", Color("e8c8ff")),
		Kit.label("%s week" % featured.name, 30), Kit.label("%s gets half of all %s rolls." % [featured.name, Roster.RARITY_NAMES[featured.rarity]], 21, Color("e8c8ff"), HORIZONTAL_ALIGNMENT_LEFT, true)])])
	feat.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := Kit.box(Color("221046"), Color("6b3fb0"), 36, 2, 20)
	root.add_child(Kit.panel(Kit.vbox(4, [portal, feat]), st))
	root.add_child(_wishlist_panel(shell))

	var pity: int = p.legendary_pity
	root.add_child(Kit.panel(Kit.vbox(8, [Kit.hbox(0, [Kit.caption("Legendary pity"), Kit.spacer(), Kit.label("%d Rare+ rolls left" % pity, 22)]),
		Kit.bar(float(Summon.PITY_RESET - pity) / Summon.PITY_RESET, Glyph.GOLD)]), Kit.box(Kit.PANEL, Kit.LINE, 28, 2, 18)))

	var free := Dev.free_summons()
	var one := Kit.button("Free x1" if p.free_summon or free else "x1  (1 orb)", func(): _pull(shell, 1), "ghost", 28, 96)
	var ten := Kit.button("Free x10" if free else "x10  (10 orbs)", func(): _pull(shell, 10), "primary", 28, 96)
	one.disabled = not (p.free_summon or free) and p.orbs < 1
	ten.disabled = not free and p.orbs < 10
	shell.mark("pull1", one)
	shell.mark("pull10", ten)
	shell.pin(Kit.hbox(14, [one, ten]))
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
		Kit.label("Picks come up twice as often within their rarity.", 21, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)]), Kit.box(Kit.PANEL, Kit.LINE, 32, 2, 20))


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
	if Dev.free_summons():
		pass # Testing: summons cost nothing.
	elif n == 1 and p.free_summon:
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
	Analytics.track("summon", {"count": n, "new": fresh.count(true)})
	shell.overlay(_reveal(shell, ids, fresh), "reveal")


static func _reveal(shell, ids: Array, fresh: Array) -> Control:
	var root := _Reveal.new()
	root.add_theme_stylebox_override("panel", Kit.box(Color("120a2e"), Color(0, 0, 0, 0), 0, 0, 40))
	var v := Kit.vbox(24)
	v.add_child(Kit.caption("Summon x%d" % ids.size(), Color("e8c8ff")))
	v.get_child(0).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title := Kit.label("Opening...", 36, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 1 if ids.size() == 1 else 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 18)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var caps: Array = []
	var side := 360.0 if ids.size() == 1 else 120.0
	for i in ids.size():
		var cap := _Capsule.new()
		cap.setup(ids[i], fresh[i], side, shell.sfx)
		cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caps.append(cap)
		grid.add_child(cap)
	var mid := CenterContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(grid)
	v.add_child(mid)
	var skip := Kit.button("Skip", root.skip, "ghost", 28, 96)
	var done := Kit.button("Done", func(): shell.close_overlay(); shell.refresh(), "go", 28, 96)
	shell.mark("open_all", skip)
	shell.mark("reveal_done", done)
	v.add_child(Kit.hbox(14, [skip, done]))
	root.add_child(v)
	var flash := _Flash.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)
	root.setup(caps, title, skip, flash)
	return root


## Opens the capsules one by one, OPEN_GAP apart, so a x10 takes about 4
## seconds. A Legendary shakes and charges first (an extra beat), then bursts
## with a screen flash. Tap anywhere (or Skip) to open the rest at once.
class _Reveal extends PanelContainer:
	const OPEN_GAP := 0.4
	const CHARGE := 0.6
	const Roster := preload("res://game/ui/roster.gd")
	const A11y := preload("res://game/a11y.gd")

	var caps: Array = []
	var title: Label
	var skip_button: Button
	var flash
	var _next := 0
	var _wait := OPEN_GAP
	var _charging := false
	var _best := 0

	func setup(caps_: Array, title_: Label, skip_: Button, flash_) -> void:
		caps = caps_
		title = title_
		skip_button = skip_
		flash = flash_
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed and _next < caps.size():
			skip()
			accept_event()

	func _process(delta: float) -> void:
		if _next >= caps.size():
			return
		_wait -= delta
		if _wait > 0.0:
			return
		var cap = caps[_next]
		if cap.rarity_index() == 4 and not _charging:
			_charging = true
			cap.charge()
			_wait = CHARGE
			return
		_charging = false
		_open(cap, true)
		_next += 1
		_wait = OPEN_GAP
		if _next >= caps.size():
			_finish()

	func _open(cap, animate: bool) -> void:
		cap.open(animate)
		_best = maxi(_best, cap.rarity_index())
		if animate and cap.rarity_index() == 4:
			flash.fire(Roster.RARITY_COLORS["legendary"])

	## Opens everything left, quietly and without the burst.
	func skip() -> void:
		while _next < caps.size():
			_open(caps[_next], false)
			_next += 1
		_finish()

	func _finish() -> void:
		skip_button.disabled = true
		var r: String = Roster.RARITIES[_best]
		title.text = "LEGENDARY!" if _best == 4 else ("Epic pull!" if _best == 3 else "Summoned!")
		title.add_theme_color_override("font_color", Roster.RARITY_COLORS[r] if _best >= 3 else Color.WHITE)


## A full-screen flash for a Legendary burst. Off with Reduced motion.
class _Flash extends Control:
	const A11y := preload("res://game/a11y.gd")
	var _t := 1.0
	var _col := Color.WHITE

	func fire(col: Color) -> void:
		if A11y.reduced_motion:
			return
		_col = col
		_t = 0.0

	func _process(delta: float) -> void:
		if _t < 1.0:
			_t = minf(1.0, _t + delta / .5)
			queue_redraw()

	func _draw() -> void:
		if _t < 1.0:
			draw_rect(Rect2(-Vector2(80, 80), size + Vector2(160, 160)), Color(_col.lerp(Color.WHITE, .5), .55 * (1.0 - _t) * (1.0 - _t)))


## A capsule that glows in its critter's rarity colour, then bursts open:
## the shell halves fly apart, a ring and sparks shoot out and a halo stays
## behind the critter. Rarer critters get a bigger burst, more sparks, a
## higher pop, and (Epic and up) rotating light rays.
class _Capsule extends Control:
	const Kit := preload("res://game/ui/ui_kit.gd")
	const CritterIcon := preload("res://game/ui/critter_icon.gd")
	const Roster := preload("res://game/ui/roster.gd")
	const A11y := preload("res://game/a11y.gd")
	## Burst size by rarity index (Common .. Legendary).
	const BURST := [1.0, 1.15, 1.35, 1.7, 2.3]
	const SPARKS := [8, 10, 14, 20, 32]
	const BURST_TIME := .7

	var id := ""
	var is_new := false
	var opened := false
	var side := 120.0
	var sfx = null
	var _t := 0.0
	var _open_t := 10.0
	var _charge_t := -1.0
	var _col := Color.WHITE
	var _ri := 0
	var _spark_dirs: Array = []
	var _content: VBoxContainer

	func setup(id_: String, is_new_: bool, side_: float, sfx_) -> void:
		id = id_
		is_new = is_new_
		side = side_
		sfx = sfx_
		custom_minimum_size = Vector2(side, side + side * .35)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var c := Roster.get_critter(id)
		_col = Roster.RARITY_COLORS[c.rarity]
		_ri = maxi(0, Roster.RARITIES.find(c.rarity))
		# Render-only randomness: spark directions and speeds.
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(id) ^ int(Time.get_ticks_usec())
		for k in SPARKS[_ri]:
			_spark_dirs.append(Vector3(TAU * k / SPARKS[_ri] + rng.randf_range(-.25, .25), rng.randf_range(.7, 1.3), rng.randf_range(.6, 1.0)))

	func rarity_index() -> int:
		return _ri

	## The Legendary wind-up: the capsule shakes and its glow swells.
	func charge() -> void:
		_charge_t = 0.0
		if sfx:
			sfx.play("summon_charge")

	func open(animate := true) -> void:
		if opened:
			return
		opened = true
		_charge_t = -1.0
		var c := Roster.get_critter(id)
		_content = Kit.vbox(0, [CritterIcon.make(id, 1, side), Kit.label(c.name, 34 if side > 200 else 17, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)])
		_content.get_child(1).clip_text = true
		_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_content)
		if not animate:
			return
		_open_t = 0.0
		if sfx:
			if _ri == 4:
				sfx.play("summon_legend")
			sfx.play("summon_pop", 0.0, 1.0 + _ri * .09)
		_content.pivot_offset = custom_minimum_size / 2.0
		if A11y.reduced_motion:
			_content.modulate.a = 0.0
			create_tween().tween_property(_content, "modulate:a", 1.0, .25)
		else:
			_content.scale = Vector2(.2, .2)
			var over := 1.0 + .06 * _ri
			var tw := create_tween()
			tw.tween_property(_content, "scale", Vector2(over, over), .22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(_content, "scale", Vector2.ONE, .18).set_trans(Tween.TRANS_SINE)

	func _process(delta: float) -> void:
		_t += delta
		_open_t += delta
		if _charge_t >= 0.0:
			_charge_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(size.x / 2.0, side * .56)
		var r := side * .36
		var still := A11y.reduced_motion
		if not opened:
			var pulse := .5 + .5 * sin(_t * 5.0)
			var grow := 0.0
			if _charge_t >= 0.0:
				grow = clampf(_charge_t / .6, 0.0, 1.0)
				if not still:
					var amp := r * .08 * grow
					c += Vector2(sin(_t * 61.0), cos(_t * 47.0)) * amp
			for k in 4:
				draw_circle(c, r * (1.1 + k * .1 + pulse * .05 + grow * .4), Color(_col, .12 + grow * .1))
			draw_circle(c, r, _col)
			_draw_top_shell(c, r, 0.0, Color.WHITE)
			draw_line(c - Vector2(r, 0), c + Vector2(r, 0), Color("1b1842"), r * .12)
			draw_circle(c, r * .16, Color("1b1842"))
			draw_circle(c, r * .09, Color.WHITE.lerp(_col, grow))
			return
		var s: float = BURST[_ri]
		# The halo that stays behind the critter.
		var hp := .5 + .5 * sin(_t * 3.0)
		if _ri >= 3:
			var spin := 0.0 if still else _t * (.6 if _ri == 3 else 1.0)
			var rays := 8 if _ri == 3 else 12
			for k in rays:
				var a := spin + TAU * k / rays
				var tip := c + Vector2(cos(a), sin(a)) * r * (1.25 + .25 * s)
				var w := .13
				draw_colored_polygon(PackedVector2Array([c + Vector2(cos(a - w), sin(a - w)) * r * .5, tip,
					c + Vector2(cos(a + w), sin(a + w)) * r * .5]), Color(_col, .18 + .08 * hp))
		for k in 5:
			draw_circle(c, r * (1.25 - k * .15) * (1.0 + .1 * _ri), Color(_col, (.05 + .025 * _ri) * (1.0 + hp * .4)))
		if _open_t >= BURST_TIME:
			_draw_new_tag()
			return
		var e := _open_t / BURST_TIME
		var out := 1.0 - pow(1.0 - e, 3.0)
		if not still:
			# Shell halves fly apart and fade.
			var fade := clampf(1.0 - e * 1.8, 0.0, 1.0)
			if fade > 0.0:
				_draw_top_shell(c - Vector2(0, r * 1.2 * out), r, -.6 * out, Color(1, 1, 1, fade))
				_draw_bottom_shell(c + Vector2(0, r * 1.0 * out), r, .5 * out, Color(_col, fade))
			# Expanding ring.
			draw_arc(c, r * (.6 + 1.6 * s * out), 0.0, TAU, 48, Color(_col.lerp(Color.WHITE, .4), 1.0 - e), maxf(1.0, r * .14 * (1.0 - e)), true)
			if _ri >= 2:
				draw_arc(c, r * (.4 + 1.1 * s * out), 0.0, TAU, 48, Color(Color.WHITE, (1.0 - e) * .7), maxf(1.0, r * .06 * (1.0 - e)), true)
			# Sparks.
			for d in _spark_dirs:
				var dist: float = r * (.5 + 1.9 * s * d.y * out)
				var p := c + Vector2(cos(d.x), sin(d.x)) * dist
				var tail := c + Vector2(cos(d.x), sin(d.x)) * dist * .82
				draw_line(tail, p, Color(_col.lerp(Color.WHITE, .5), (1.0 - e) * d.z), maxf(1.5, r * .07), true)
			# The flash at the core.
			if e < .35:
				draw_circle(c, r * (.9 + .6 * s * e), Color(1, 1, 1, .9 * (1.0 - e / .35)))
		else:
			draw_circle(c, r * 1.2, Color(_col, .35 * (1.0 - e)))
		_draw_new_tag()

	func _draw_new_tag() -> void:
		if not is_new:
			return
		var tag := Vector2(size.x / 2.0, side * .1)
		draw_rect(Rect2(tag - Vector2(side * .2, side * .07), Vector2(side * .4, side * .14)), Kit.BAD)
		draw_string(Kit.FONT, tag + Vector2(-side * .17, side * .045), "NEW", HORIZONTAL_ALIGNMENT_CENTER, side * .34, int(side * .12), Color.WHITE)

	func _draw_top_shell(c: Vector2, r: float, rot: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 17:
			var a := PI + i * PI / 16 + rot
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, col)

	func _draw_bottom_shell(c: Vector2, r: float, rot: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 17:
			var a := i * PI / 16 + rot
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, col)


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
