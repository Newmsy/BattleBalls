## Summon Portal: random Tier 1 critters for Summon Eggs (earned, never sold).
## Odds on screen, x10 guarantees a Rare or better, shared Legendary pity, one
## free summon a day, and the Wishlist (3 picks that
## come up twice as often within their rarity). Capsules glow in their rarity's
## colour, then open on their own one by one with a burst that grows with rarity.
extends RefCounted

const Intro := preload("res://game/ui/intro.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const Summon := preload("res://game/ui/summon.gd")
const Analytics := preload("res://game/online/analytics.gd")
const Painted := preload("res://game/ui/painted.gd")
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
	var title: Control = shell.title_row("Summon Portal", {"back": false, "info_title": "Odds and pity", "info_mark": "summon_info", "info": [
		"Every summon is a Tier 1 critter. Odds: " + ", ".join(odds_lines) + ".",
		"A x10 always has a Rare or better.",
		"Every critter of a rarity is equally likely; Wishlist picks come up 2x as often.",
		"Legendary within %d Rare+ rolls. Campaign drops count too." % Summon.PITY_RESET,
		"Eggs: boss first clears, daily login, account levels, Brood Queen."]})

	# The Portal Hall painting fills whatever room the cards below leave, with
	# the title on it. One child in root, so the shell stretches it instead of
	# centring a short column.
	var body := Kit.vbox(18, [_Hall.make(title)])
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	if not Intro.done(p):
		# A new player's first summon: just the portal and the button.
		var first := Kit.button("Free x1", func(): _pull(shell, 1), "go", 30, 96) if p.free_summon else Kit.cost_button("x1", 1, "egg", func(): _pull(shell, 1), "go", 30, 96)
		first.disabled = not p.free_summon and p.orbs < 1
		_egg_on(first, HATCH_X1)
		shell.mark("pull1", first)
		shell.pin(first)
		return root
	body.add_child(_wishlist_panel(shell))

	var pity: int = p.legendary_pity
	body.add_child(Kit.panel(Kit.vbox(8, [Kit.hbox(0, [Kit.caption("Legendary"), Kit.spacer(), Kit.label("in %d" % pity, 22)]),
		Kit.bar(float(Summon.PITY_RESET - pity) / Summon.PITY_RESET, Glyph.GOLD)]), Kit.box(Kit.PANEL, Kit.LINE, 28, 2, 18)))

	var free := Dev.free_summons()
	# A free pull is the green button; paid pulls show their cost in eggs.
	var one := Kit.button("Free x1", func(): _pull(shell, 1), "go", 28, 96) if p.free_summon or free \
		else Kit.cost_button("x1", 1, "egg", func(): _pull(shell, 1), "ghost", 28, 96)
	var ten := Kit.button("Free x10", func(): _pull(shell, 10), "primary", 28, 96) if free \
		else Kit.cost_button("x10", 10, "egg", func(): _pull(shell, 10), "primary", 28, 96)
	one.disabled = not (p.free_summon or free) and p.orbs < 1
	ten.disabled = not free and p.orbs < 10
	_egg_on(one, HATCH_X1)
	_egg_on(ten, HATCH_X10)
	shell.mark("pull1", one)
	shell.mark("pull10", ten)
	shell.pin(Kit.hbox(14, [one, ten]))
	return root


const WISH := Color("ff5fc8")
const HATCH_X1 := preload("res://game/ui/art/summon/hatch_x1.png")
const HATCH_X10 := preload("res://game/ui/art/summon/hatch_x10.png")


## A painted egg (or clutch of eggs) in front of a hatch button's label.
static func _egg_on(b: Button, art: Texture2D) -> void:
	var row: HBoxContainer = b.get_meta("row") if b.has_meta("row") else null
	if row == null:
		var words := Kit.label(b.text, b.get_meta("base_font", 28), b.get_theme_color("font_color"))
		b.text = ""
		row = Kit.hbox(4, [words], BoxContainer.ALIGNMENT_CENTER)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(row)
		b.draw.connect(func(): row.modulate.a = .5 if b.disabled else 1.0)
	var pic := TextureRect.new()
	pic.texture = art
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(88, 72)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pic)
	row.move_child(pic, 0)


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
		var home := Painted.habitat(p.wishlist[i]) if i < p.wishlist.size() else ""
		if home != "":
			# The wished critter stands on its family home's lit stage.
			var win := Painted.make(home, {"focus": Vector2(200, 250), "at": Vector2(0.5, 0.36), "px": 1.8,
				"radius": 21.0, "bottom_dark": 0.55, "bottom_fade": 0.2})
			win.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			for side in ["left", "top"]:
				win.set("offset_" + side, 3)
			for side in ["right", "bottom"]:
				win.set("offset_" + side, -3)
			slot.add_child(win)
			slot.move_child(win, 0)
		slots.add_child(slot)
	return Kit.panel(Kit.vbox(12, [head, slots]), Kit.box(Kit.PANEL, Kit.LINE, 32, 2, 20))


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
				elif p.on_wishlist(id) and p.wishlist.size() >= p.WISHLIST_MAX:
					# That was the last pick: nothing left to choose, so close the sheet.
					shell.close_overlay()
					shell.refresh()
					shell.toast("Wishlist set.")
					return
				refresh.call(), Roster.rarity_border(c.rarity, Kit.LINE), Roster.rarity_bg(c.rarity, Kit.PANEL2), 20, 6)
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
		Kit.label("They show up 2x as often.", 21, Kit.MUTED),
		scroll, done]))


static func _pct(x: float) -> String:
	return ("%.2f%%" % x) if x < 1.0 else ("%.1f%%" % x)


static func _centered(c: Control) -> Control:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc


static var _reveal_unlocks := false


static func _pull(shell, n: int) -> void:
	var p = shell.profile
	if Dev.free_summons():
		pass # Testing: summons cost nothing.
	elif n == 1 and p.free_summon:
		p.free_summon = false
	elif not p.spend_orbs(n):
		shell.toast("Not enough eggs.")
		return
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()
	var ids: Array = Summon.pull(p, n, _rng)
	shell.glow.record("hatch", ids.size())
	# NEW only on a critter's first copy: a second one in the same x10 is a dupe.
	var fresh: Array = []
	for i in ids.size():
		fresh.append(not p.owns(ids[i]) and not ids[i] in ids.slice(0, i))
	p.add_copies(ids)
	print("UI_SUMMON ", ",".join(ids))
	Analytics.track("summon", {"count": n, "new": fresh.count(true)})
	# A new player's first summon opens Critters: shown once the reveal is done.
	_reveal_unlocks = Intro.step(p) == Intro.SUMMON and Intro.reach(p, Intro.FIGHTER)
	# The portal winds up for a beat (its vortex spins up and flares), then the eggs drop.
	var swirl = _Vortex.shown
	if is_instance_valid(swirl) and swirl.is_visible_in_tree() and not preload("res://game/a11y.gd").reduced_motion:
		if shell.sfx != null:
			shell.sfx.play("summon_charge", -6.0, 1.3)
		swirl.surge(func(): shell.overlay(_reveal(shell, ids, fresh), "reveal"))
		return
	shell.overlay(_reveal(shell, ids, fresh), "reveal")


static func _reveal(shell, ids: Array, fresh: Array) -> Control:
	var root := _Reveal.new()
	root.add_theme_stylebox_override("panel", Kit.box(Color("120a2e"), Color(0, 0, 0, 0), 0, 0, 40))
	var back := _Backdrop.new()
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(back)
	var v := Kit.vbox(24)
	v.add_child(Kit.caption("Summon x%d" % ids.size(), Color("e8c8ff")))
	v.get_child(0).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title := Kit.label("Opening...", 36, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(title)
	# Rows of eggs, each centred: a x10 is a 3 / 4 / 3 honeycomb (4 x 150 fits
	# the 640 inside the margins).
	var rows := Kit.vbox(56 if shell.size.y >= 1400 else 18) # Tall phones spread the rows out.
	var caps: Array = []
	var side := 360.0 if ids.size() == 1 else 150.0
	var row: HBoxContainer = null
	var left := 0
	var plan := _row_plan(ids.size())
	for i in ids.size():
		if left == 0:
			row = Kit.hbox(10, [], BoxContainer.ALIGNMENT_CENTER)
			rows.add_child(row)
			left = plan.pop_front()
		var cap := _Capsule.new()
		cap.setup(ids[i], fresh[i], side, shell.sfx)
		if not fresh[i]:
			cap.note = _fuse_note(shell.profile, ids[i])
		caps.append(cap)
		row.add_child(cap)
		left -= 1
	var mid := CenterContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(rows)
	v.add_child(mid)
	# Summon the same number again (tap anywhere opens the rest at once).
	# Lit once every egg is open, if you can pay for it.
	var n := ids.size()
	var free := Dev.free_summons()
	var again := Kit.button("Again x%d" % n, func(): _again(shell, n), "primary", 26, 96) if free \
		else Kit.cost_button("Again x%d" % n, n, "egg", func(): _again(shell, n), "primary", 26, 96)
	again.size_flags_stretch_ratio = 1.5
	again.disabled = true
	again.set_meta("affordable", free or shell.profile.orbs >= n)
	# A new player's first summon ends on Done, which opens the next step.
	again.visible = Intro.done(shell.profile) and not _reveal_unlocks
	var done := Kit.button("Done", func():
		shell.close_overlay()
		shell.refresh()
		if _reveal_unlocks:
			_reveal_unlocks = false
			Intro.moment(shell, Intro.FIGHTER), "go", 28, 96)
	shell.mark("summon_again", again)
	shell.mark("reveal_done", done)
	v.add_child(Kit.hbox(14, [again, done]))
	root.add_child(v)
	var flash := _Flash.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)
	root.setup(caps, title, again, flash)
	return root


static func _again(shell, n: int) -> void:
	shell.refresh() # The screen under the reveal shows the eggs left.
	_pull(shell, n)


## Eggs per row, at most 4 a row, the rows as even as they can be and
## the longer ones in the middle: 10 -> [3, 4, 3].
static func _row_plan(n: int) -> Array:
	var count := ceili(n / 4.0)
	var out: Array = []
	for r in count:
		out.append(floori(float(n) / count))
	var mid := floori(count / 2.0)
	for k in n % count:
		out[(mid + floori((k + 1) / 2.0) * (1 if k % 2 == 0 else -1)) % count] += 1
	return out


## A copy's progress to its next fuse: T1 copies held out of 3, uncapped ("2/3", "10/3").
static func _fuse_note(p, id: String) -> String:
	var t1 := 0
	for s in p.copies(id):
		if s.tier == 1:
			t1 = s.count
	return "%d/3" % t1


## The eggs drop in from above one after another (DROP_GAP apart) and land
## in place, then open one by one, OPEN_GAP apart, so a x10 takes about 4
## seconds after its 1 second drop. A Legendary shakes and charges first (an
## extra beat), then bursts with a screen flash. Tap anywhere to open the
## rest at once.
class _Reveal extends PanelContainer:
	const OPEN_GAP := 0.4
	const CHARGE := 0.6
	const DROP_GAP := 0.08
	const SETTLE := 0.15 ## A beat after the last egg lands before the first cracks.
	const Roster := preload("res://game/ui/roster.gd")
	const A11y := preload("res://game/a11y.gd")

	var caps: Array = []
	var title: Label
	var again_button: Button ## Summon the same number again, lit when all are open.
	var flash
	var _next := 0
	var _wait := OPEN_GAP
	var _charging := false
	var _best := 0
	var _intro := 0.0 ## Seconds of drop-in left before the first egg cracks.

	func setup(caps_: Array, title_: Label, again_: Button, flash_) -> void:
		caps = caps_
		title = title_
		again_button = again_
		flash = flash_
		mouse_filter = Control.MOUSE_FILTER_STOP
		# A little jitter so a x10 falls like hail, not a metronome.
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		for i in caps.size():
			var at := i * DROP_GAP + (rng.randf_range(-.025, .025) if i > 0 else 0.0)
			caps[i].drop(at)
			_intro = maxf(_intro, at + caps[i].fall_time())
		_intro += SETTLE

	## Seconds before the first egg opens: the drop-in plus one OPEN_GAP.
	func intro_time() -> float:
		return _intro + OPEN_GAP

	func _gui_input(e: InputEvent) -> void:
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed and _next < caps.size():
			skip()
			accept_event()

	func _process(delta: float) -> void:
		if _next >= caps.size():
			return
		if _intro > 0.0:
			_intro -= delta
			if _intro <= 0.0:
				caps[0].crack(OPEN_GAP)
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
		else:
			caps[_next].crack(OPEN_GAP)

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
		again_button.disabled = not again_button.get_meta("affordable", false)
		for cap in caps:
			cap.enable_info() # All out: now a tap on one opens its card.
		var r: String = Roster.RARITIES[_best]
		title.text = "LEGENDARY!" if _best == 4 else ("Epic pull!" if _best == 3 else "Summoned!")
		title.add_theme_color_override("font_color", Roster.RARITY_COLORS[r] if _best >= 3 else Color.WHITE)
		if caps.size() > 1:
			var fresh := caps.filter(func(cap): return cap.is_new).size()
			var head: Label = title.get_parent().get_child(0)
			var dupes: int = caps.size() - fresh
			var copies := "%d COP%s" % [dupes, "Y" if dupes == 1 else "IES"]
			head.text = ("%d NEW · %s" % [fresh, copies]) if fresh > 0 else copies


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
	const Families := preload("res://sim/families.gd")
	const CritterArt := preload("res://game/ui/critter_art.gd")
	const Dot := preload("res://game/dot.gd")
	const CritterIcon := preload("res://game/ui/critter_icon.gd")
	const Roster := preload("res://game/ui/roster.gd")
	const A11y := preload("res://game/a11y.gd")
	## Burst size by rarity index (Common .. Legendary).
	const BURST := [1.0, 1.15, 1.35, 1.7, 2.3]
	const SPARKS := [8, 10, 14, 20, 32]
	const BURST_TIME := .7
	const FALL := .42 ## Seconds from above the screen to landing (FALL_ONE for a x1).
	const FALL_ONE := .55
	const LAND := .4 ## The squash and dust puff after landing.

	var id := ""
	var is_new := false
	var note := "" ## Under a copy's name: its fuse progress.
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
	var _crack_t := -1.0
	var _crack_len := .4
	var _phase := 0.0
	var _egg := PackedVector2Array() ## Unit egg outline, centred on (0, 0).
	var _crack := PackedVector2Array() ## Zigzag across the middle, left to right.
	var _pattern: Array = [] ## [kind, points, width or 0 for filled] in unit egg space.
	var _shards: Array = [] ## Vector4(angle, speed, spin, size) per shell shard.
	var _ink := Color(1, 1, 1) ## The family's colour, for its pattern.
	var _specks: Array = [] ## Vector3(x, y, radius): the shell's natural speckles.
	var _drop_t := 10.0 ## Seconds since it started falling (negative: still waiting).
	var _landed := true
	var _tick := -1

	func setup(id_: String, is_new_: bool, side_: float, sfx_) -> void:
		id = id_
		is_new = is_new_
		side = side_
		sfx = sfx_
		custom_minimum_size = Vector2(side, side + side * .5)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var c := Roster.get_critter(id)
		_col = Roster.RARITY_COLORS[c.rarity]
		_ri = maxi(0, Roster.RARITIES.find(c.rarity))
		# Render-only randomness: spark directions and speeds.
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(id) ^ int(Time.get_ticks_usec())
		for k in SPARKS[_ri]:
			_spark_dirs.append(Vector3(TAU * k / SPARKS[_ri] + rng.randf_range(-.25, .25), rng.randf_range(.7, 1.3), rng.randf_range(.6, 1.0)))
		_phase = rng.randf_range(0.0, TAU)
		for i in 32:
			var a := TAU * i / 32
			var up := maxf(0.0, -sin(a))
			_egg.append(Vector2(.8 * cos(a) * (1.0 - .16 * up), sin(a) * (1.12 if sin(a) < 0.0 else .92)))
		for i in 9:
			_crack.append(Vector2(-.8 + 1.6 * i / 8.0, -.08 + (.11 if i % 2 else -.07)))
		for k in 6 + _ri * 2:
			_shards.append(Vector4(-PI / 2 + rng.randf_range(-1.6, 1.6), rng.randf_range(.8, 1.6), rng.randf_range(-6.0, 6.0), rng.randf_range(.16, .3)))
		var fam := Families.of(id)
		_pattern = EggArt.pattern(fam, rng)
		for k in 9:
			_specks.append(Vector3(rng.randf_range(-.5, .5), rng.randf_range(-.75, .6), rng.randf_range(.025, .055)))
		for f in Families.FAMILIES:
			if f.id == fam:
				_ink = Color(f.color)

	func rarity_index() -> int:
		return _ri

	func fall_time() -> float:
		return FALL_ONE if side > 200 else FALL

	## Drops the egg in from above the screen after `delay` seconds. Reduced
	## motion fades it in where it sits instead.
	func drop(delay: float) -> void:
		_landed = false
		_drop_t = -delay
		if A11y.reduced_motion:
			modulate.a = 0.0
			var tw := create_tween()
			tw.tween_interval(delay)
			tw.tween_property(self, "modulate:a", 1.0, .2)

	func _land() -> void:
		_landed = true
		if sfx and not A11y.reduced_motion:
			sfx.play("summon_land", 0.0, 1.0 + randf_range(-.08, .08) - (.15 if side > 200 else 0.0))

	## Cracks start spreading across the shell; it hatches after `len` seconds.
	func crack(len: float) -> void:
		if opened:
			return
		_crack_t = 0.0
		_crack_len = len

	## Lets a tap on the revealed critter open its mini Critterpedia card.
	func enable_info() -> void:
		if _content != null:
			_content.get_child(0).info = true

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
		_landed = true
		_drop_t = maxf(_drop_t, 10.0)
		modulate.a = 1.0
		var c := Roster.get_critter(id)
		# The rarity word in its colour; a copy of one you had shows its fuse progress
		# instead (both on a single big reveal).
		var word: String = Roster.RARITY_NAMES[c.rarity]
		var big := side > 200
		var text := word if note == "" else (word + " · " + note if big else note)
		var tag := Kit.label(text, 26 if big else 17, _col, HORIZONTAL_ALIGNMENT_CENTER)
		var face := CritterIcon.make(id, 1, side)
		face.info = false # A tap skips the reveal; the card opens once it's done (enable_info).
		if not big:
			face.radius_frac = .34 # Fill the small eggs' space: the face is what you came for.
		_content = Kit.vbox(0, [face, Kit.label(c.name, 34 if big else 20, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER), tag])
		for l in [_content.get_child(1), tag]:
			l.clip_text = true
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
		_drop_t += delta
		if not _landed and _drop_t >= fall_time():
			_land()
		if _charge_t >= 0.0:
			_charge_t += delta
		if _crack_t >= 0.0:
			_crack_t += delta
		if _drop_t < 0.0:
			return # Still waiting to fall: nothing drawn yet.
		# Once hatched and settled only the halo moves: idle on the shared clock.
		if opened and _open_t >= BURST_TIME:
			var tick := CritterIcon.clock()
			if tick == _tick:
				return
			_tick = tick
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(size.x / 2.0, side * .56)
		var r := side * .36
		var still := A11y.reduced_motion
		if not opened:
			if _drop_t < 0.0:
				return
			var pulse := .5 + .5 * sin(_t * 4.0 + _phase)
			var grow := 0.0
			if _charge_t >= 0.0:
				grow = clampf(_charge_t / .6, 0.0, 1.0)
			# Falling in: from above the screen, speeding up like a dropped thing;
			# the shadow gathers under it as it comes down. Then a squash and a
			# little rebound, with a puff of dust either side.
			var fall := 0.0
			var squash := Vector2.ONE
			var land_e := 1.0
			if not still:
				var ft := fall_time()
				if _drop_t < ft:
					var e := _drop_t / ft
					fall = -(1.0 - e * e) * (global_position.y + side * 1.6)
					land_e = e * e
				else:
					var k := clampf((_drop_t - ft) / LAND, 0.0, 1.0)
					var bounce := sin(k * PI * 2.0) * (1.0 - k) * (1.0 - k)
					squash = Vector2(1.0 + .2 * bounce, 1.0 - .22 * bounce)
					if k < 1.0:
						var puff := 1.0 - pow(1.0 - k, 2.0)
						for sgn in [-1.0, 1.0]:
							for j in 3:
								var at := c + Vector2(sgn * r * (.45 + .6 * puff + j * .14), r * (.9 - .12 * j * puff))
								Dot.circle(self, at, r * (.09 + .07 * puff) * (1.0 - j * .2), Color(Color("c9b8e8"), .35 * (1.0 - k)))
			# A soft shadow on the ground; only Epic and Legendary eggs (and the
			# Legendary wind-up) give off a faint glow.
			draw_set_transform(c + Vector2(0, r * .95), 0.0, Vector2(.4 + .6 * land_e, .28 * (.4 + .6 * land_e)))
			Dot.circle(self, Vector2.ZERO, r * .7, Color(0, 0, 0, .35 * land_e))
			draw_set_transform_matrix(Transform2D.IDENTITY)
			var halo := (.03 * (_ri - 2) if _ri >= 3 else 0.0) * (.8 + .2 * pulse) + grow * .1
			if halo > 0.0:
				for k in 3:
					Dot.circle(self, c, r * (1.1 + k * .14 + grow * .4), Color(_col, halo))
			var cracked := clampf(_crack_t / maxf(.05, _crack_len * .85), 0.0, 1.0) if _crack_t >= 0.0 else 0.0
			if _charge_t >= 0.0:
				cracked = maxf(cracked, grow)
			var tilt := 0.0
			var shake := Vector2.ZERO
			if not still:
				tilt = sin(_t * 2.6 + _phase) * .05 + sin(_t * 31.0) * .12 * cracked
				shake = Vector2(sin(_t * 61.0), cos(_t * 47.0)) * r * .07 * grow
			# Wobble about the egg's base.
			var base := c + Vector2(0, r * .92 + fall) + shake
			draw_set_transform_matrix(Transform2D(tilt, base) * Transform2D(0.0, Vector2(r, r) * squash, 0.0, Vector2(0, -.92 * r * squash.y)))
			_draw_egg(cracked, pulse + grow)
			draw_set_transform_matrix(Transform2D.IDENTITY)
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
			var fade := clampf(1.0 - e * 1.6, 0.0, 1.0)
			if fade > 0.0:
				var shell := _shell_color()
				# The cap pops up and tumbles; shards fly out and fall.
				draw_set_transform(c + Vector2(r * .3 * out, -r * 1.3 * out), -.9 * out, Vector2(r, r))
				draw_colored_polygon(_cap(), Color(shell, fade))
				draw_polyline(_cap(), Color(_col.darkened(.15), fade), .05, true)
				for d in _shards:
					var dist: float = d.y * 1.8 * out
					var at := c + (Vector2(cos(d.x), sin(d.x)) * dist + Vector2(0, 1.4 * e * e)) * r
					draw_set_transform(at, d.z * e, Vector2(r, r))
					var tri := PackedVector2Array([Vector2(-d.w, -d.w * .6), Vector2(d.w, -d.w * .2), Vector2(-d.w * .1, d.w * .8)])
					draw_colored_polygon(tri, Color(shell, fade))
					draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color(_col, fade), .05, true)
				draw_set_transform_matrix(Transform2D.IDENTITY)
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

	## The shell's body colour: a matte bone shell with a hint of the family.
	func _shell_color() -> Color:
		return Color("ddd2bd").lerp(_ink, .3).darkened(.12)

	## The egg in unit space (the caller sets the transform): a matte shell
	## lit from the top left, natural speckles, the family motif pressed faintly
	## into it, a thin rim in the rarity colour, and cracks spreading as it
	## gets ready.
	func _draw_egg(cracked: float, _glow: float) -> void:
		var shell := _shell_color()
		draw_colored_polygon(_egg, shell.darkened(.28))
		var lit := PackedVector2Array()
		for q in _egg:
			lit.append(Vector2(q.x * .9 - .05, q.y * .9 - .06))
		draw_colored_polygon(lit, shell)
		var ink := Color(shell.darkened(.32), .55)
		for part in _pattern:
			if part[2] > 0.0:
				draw_polyline(part[1], ink, part[2], true)
			else:
				draw_colored_polygon(part[1], ink)
		for sp in _specks:
			Dot.circle(self, Vector2(sp.x, sp.y), sp.z, Color(shell.darkened(.45), .45))
		var rim := _egg.duplicate()
		rim.append(_egg[0])
		draw_polyline(rim, _col.darkened(.15), .045 + .01 * _ri, true)
		# A soft matte sheen, not a gloss.
		Dot.circle(self, Vector2(-.3, -.52), .14, Color(1, 1, 1, .16))
		if _ri == 4:
			for k in 3:
				var tw := .5 + .5 * sin(_t * 5.0 + k * 2.1)
				draw_colored_polygon(CritterArt.star_pts(Vector2(-.5 + k * .5, -.95 + k * .28 + (k % 2) * .2), .07 * tw + .02, .025, 4), Color(1, .92, .7, .75))
		if cracked > 0.0:
			var n := int(ceil(cracked * (_crack.size() - 1)))
			var line := PackedVector2Array()
			for i in n + 1:
				line.append(_crack[i])
			if line.size() >= 2:
				draw_polyline(line, Color(1, 1, 1, .95), .06, true)
				draw_polyline(line, Color(_col.lerp(Color.WHITE, .5), .4), .16, true)

	## The top of the shell above the crack line, for the hatch.
	func _cap() -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in range(_crack.size() - 1, -1, -1):
			pts.append(_crack[i])
		for q in _egg:
			if q.y < -.1 and q.x < 0.0:
				pts.append(q)
		for q in _egg:
			if q.y < -.1 and q.x >= 0.0:
				pts.append(q)
		return pts


## Each family's shell pattern, so the egg hints at what's inside before it
## hatches: leaves for Nature, waves for Sea, circuits for Tech, sprinkles for
## Sweet, a snowflake for Frost, polka dots for Toybox, a bat band for Spooky,
## flames for Fire, stars and a ring for Cosmic. Built once per egg in unit
## egg space (x -0.8..0.8, y -1.1..0.9); the egg tints it by rarity.
class EggArt:
	const CritterArt := preload("res://game/ui/critter_art.gd")

	static func pattern(family: String, rng: RandomNumberGenerator) -> Array:
		var out := []
		match family:
			"nature":
				out.append(["vine", _wave(-.55, .55, .25, .12, 2.2), .05])
				for p in [Vector2(-.35, .05), Vector2(.12, .38), Vector2(.4, -.2), Vector2(-.1, -.55)]:
					out.append(["leaf", _leaf(p, .2, rng.randf_range(-1.0, 1.0)), 0.0])
			"sea":
				out.append(["wave", _wave(-.72, .72, -.05, .1, 3.0), .07])
				out.append(["wave", _wave(-.68, .68, .35, .08, 3.0), .06])
				for p in [Vector2(-.3, -.5), Vector2(.15, -.7), Vector2(.35, -.42)]:
					out.append(["bubble", _ring(p, .08 + rng.randf() * .05), .04])
			"tech":
				out.append(["trace", PackedVector2Array([Vector2(-.7, .1), Vector2(-.3, .1), Vector2(-.15, -.15), Vector2(.2, -.15), Vector2(.2, -.55)]), .05])
				out.append(["trace", PackedVector2Array([Vector2(-.5, .55), Vector2(-.1, .55), Vector2(.05, .3), Vector2(.6, .3)]), .05])
				out.append(["trace", PackedVector2Array([Vector2(-.35, -.45), Vector2(-.35, -.75)]), .05])
				for p in [Vector2(.2, -.55), Vector2(.6, .3), Vector2(-.35, -.75), Vector2(-.5, .55), Vector2(-.7, .1)]:
					out.append(["pad", _ring(p, .065), 0.0])
			"sweet":
				# Icing drip over the top, sprinkles below.
				var drip := PackedVector2Array()
				for i in 13:
					var x := -.62 + 1.24 * i / 12.0
					drip.append(Vector2(x, -.42 + (.12 if i % 3 == 1 else 0.0) + .05 * sin(x * 7.0)))
				drip.append(Vector2(.4, -.85))
				drip.append(Vector2(0, -1.0))
				drip.append(Vector2(-.4, -.85))
				out.append(["icing", drip, 0.0])
				for k in 9:
					var p := Vector2(rng.randf_range(-.5, .5), rng.randf_range(-.15, .65))
					var a := rng.randf_range(0.0, PI)
					out.append(["sprinkle", PackedVector2Array([p - Vector2(cos(a), sin(a)) * .07, p + Vector2(cos(a), sin(a)) * .07]), .05])
			"frost":
				var c := Vector2(0, -.05)
				for k in 6:
					var a := k * PI / 3
					var d := Vector2(cos(a), sin(a))
					out.append(["arm", PackedVector2Array([c, c + d * .42]), .06])
					var m := c + d * .26
					out.append(["twig", PackedVector2Array([m + d.rotated(.9) * .1, m, m + d.rotated(-.9) * .1]), .045])
				for p in [Vector2(-.45, -.65), Vector2(.45, .5), Vector2(-.5, .45)]:
					out.append(["flake", CritterArt.star_pts(p, .07, .025, 6), 0.0])
			"toybox":
				for p in [Vector2(-.4, -.4), Vector2(.3, -.6), Vector2(.05, -.05), Vector2(-.45, .35), Vector2(.45, .2), Vector2(.1, .58)]:
					out.append(["dot", _ring(p, .1 + rng.randf() * .04), 0.0])
				var zig := PackedVector2Array()
				for i in 9:
					zig.append(Vector2(-.76 + 1.52 * i / 8.0, .3 + (-.07 if i % 2 else .07)))
				out.append(["zig", zig, .06])
			"spooky":
				var bat := PackedVector2Array([Vector2(-.6, .05), Vector2(-.4, -.08), Vector2(-.3, .08), Vector2(-.12, -.05), Vector2(0, -.18),
					Vector2(.12, -.05), Vector2(.3, .08), Vector2(.4, -.08), Vector2(.6, .05), Vector2(.3, .2), Vector2(0, .1), Vector2(-.3, .2)])
				out.append(["bat", bat, 0.0])
				out.append(["moon", _crescent(Vector2(.3, -.6), .17), 0.0])
				for p in [Vector2(-.22, .5), Vector2(.18, .5)]:
					out.append(["eye", _ring(p, .07), 0.0])
			"fire":
				var flame := PackedVector2Array([Vector2(-.66, .45)])
				for k in 5:
					var x := -.55 + k * .27
					flame.append(Vector2(x - .07, .1))
					flame.append(Vector2(x + .02, -.35 - .25 * float(k % 2 == 0) * (1.0 if k == 2 else .6)))
					flame.append(Vector2(x + .1, .05))
				flame.append(Vector2(.66, .45))
				flame.append(Vector2(.45, .8))
				flame.append(Vector2(-.45, .8))
				out.append(["flame", flame, 0.0])
				for p in [Vector2(-.3, -.7), Vector2(.25, -.85), Vector2(.05, -.6)]:
					out.append(["ember", _ring(p, .045 + rng.randf() * .03), 0.0])
			"cosmic":
				out.append(["orbit", _ellipse(Vector2(0, .05), Vector2(.95, .22), -.35), .05])
				for p in [Vector2(-.3, -.55), Vector2(.35, -.3), Vector2(-.15, .45), Vector2(.4, .45)]:
					var big := rng.randf_range(.07, .12)
					out.append(["star", CritterArt.star_pts(p, big, big * .4, 5), 0.0])
				out.append(["planet", _ring(Vector2(.05, .05), .13), 0.0])
			_:
				for k in 7:
					out.append(["speck", _ring(Vector2(rng.randf_range(-.5, .5), rng.randf_range(-.7, .6)), rng.randf_range(.04, .08)), 0.0])
		return out

	static func _wave(x0: float, x1: float, y: float, amp: float, waves: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 17:
			var x := x0 + (x1 - x0) * i / 16.0
			pts.append(Vector2(x, y + amp * sin(i / 16.0 * TAU * waves * .5)))
		return pts

	static func _ring(c: Vector2, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 13:
			pts.append(c + Vector2(cos(TAU * i / 12), sin(TAU * i / 12)) * r)
		return pts

	static func _ellipse(c: Vector2, rad: Vector2, rot: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 25:
			var a := TAU * i / 24
			pts.append(c + Vector2(cos(a) * rad.x, sin(a) * rad.y).rotated(rot))
		return pts

	static func _leaf(c: Vector2, len: float, rot: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 9:
			var t := i / 8.0
			pts.append(c + Vector2(len * (t - .5) * 2.0, -sin(t * PI) * len * .45).rotated(rot))
		for i in range(7, 0, -1):
			var t := i / 8.0
			pts.append(c + Vector2(len * (t - .5) * 2.0, sin(t * PI) * len * .45).rotated(rot))
		return pts

	static func _crescent(c: Vector2, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 13:
			var a := PI * .3 + PI * 1.4 * i / 12
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		for i in range(12, -1, -1):
			var a := PI * .4 + PI * 1.2 * i / 12
			pts.append(c + Vector2(r * .35, 0) + Vector2(cos(a), sin(a)) * r * .8)
		return pts


## The Portal Hall at the top of the screen, title on it: a painting
## (tools/event_art/scenes/portal_hall.mjs) of the carved portal, a gem for
## each family, with an egg of every family on a stone pedestal before it. It
## grows to the room the cards below leave and crops around the portal,
## bleeding out to the phone's edges. The eggs idle as living layers and the
## lanterns flicker (LivingArt), and the vortex spins over the portal's
## opening, all on the shared idle clock and only while on screen.
class _Hall extends Control:
	const LivingArt := preload("res://game/bounce_run/living_art.gd")
	const CritterIcon := preload("res://game/ui/critter_icon.gd")
	const A11y := preload("res://game/a11y.gd")
	const PATH := "res://game/ui/art/summon/portal_hall.png"
	## Portal centre and opening radius in the painting (portal_hall.mjs PORTAL).
	const PORTAL := Vector3(360, 300, 125.8)
	const MIN_H := 360.0
	const BLEED := 28.0 ## The shell's side margin on a phone.
	const FADE := Color("0d0f26")
	var _art: Texture2D
	var _mat: ShaderMaterial
	var _swirl: _Vortex
	var _t := 0.0
	var _tick := -1

	static func make(title: Control) -> Control:
		var h := _Hall.new()
		h._art = load(PATH)
		h.custom_minimum_size = Vector2(0, MIN_H)
		h.size_flags_vertical = Control.SIZE_EXPAND_FILL
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h._mat = LivingArt.material_for("portal_hall", PATH)
		# Fade the cropped foot into the page so the cards below sit on it.
		h._mat.set_shader_parameter("fade", Vector4(0.0, 0.0, 0.8, 1.0))
		h._mat.set_shader_parameter("fade_col", Vector3(FADE.r, FADE.g, FADE.b))
		h.material = h._mat
		h._swirl = _Vortex.new()
		h._swirl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h._swirl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.add_child(h._swirl)
		title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		h.add_child(title)
		h.resized.connect(h._place)
		return h

	## Where the painting lands: [dest rect, source rect], cropped to keep the
	## portal about 45% down and as much of the egg crescent as fits.
	func _fit() -> Array:
		var dest := Rect2(-BLEED, 0, size.x + BLEED * 2.0, size.y)
		var tex := Vector2(_art.get_size())
		var s := maxf(dest.size.x / tex.x, dest.size.y / tex.y)
		var src_size := dest.size / s
		var y := clampf(PORTAL.y - src_size.y * .45, 0.0, tex.y - src_size.y)
		return [dest, Rect2(Vector2((tex.x - src_size.x) / 2.0, y), src_size)]

	func _place() -> void:
		var f := _fit()
		var dest: Rect2 = f[0]
		var src: Rect2 = f[1]
		var s := dest.size.x / src.size.x
		_swirl.centre = dest.position + (Vector2(PORTAL.x, PORTAL.y) - src.position) * s
		_swirl.hole = PORTAL.z * s
		_mat.set_shader_parameter("px_size", dest.size)
		queue_redraw()
		_swirl.queue_redraw()

	func _process(delta: float) -> void:
		if A11y.reduced_motion or not is_visible_in_tree():
			return
		_t += delta
		var tick := CritterIcon.clock()
		if tick != _tick:
			_tick = tick
			LivingArt.animate(_mat, _t)
			queue_redraw()

	func _draw() -> void:
		var f := _fit()
		var dest: Rect2 = f[0]
		# Drawn from the shader's own origin so its edge mask doesn't clip the bleed.
		draw_set_transform(dest.position)
		draw_texture_rect_region(_art, Rect2(Vector2.ZERO, dest.size), f[1])


## The vortex inside the portal ring: a deep well with three spiral arms and
## motes drifting in. Slow, so it redraws on the shared idle clock and only
## while it shows.
class _Vortex extends Control:
	const Dot := preload("res://game/dot.gd")
	const CritterIcon := preload("res://game/ui/critter_icon.gd")
	const A11y := preload("res://game/a11y.gd")
	const ARMS := 3
	const MOTES := 12
	const SURGE_SECS := .35
	## The vortex on the Summon screen now (a summon winds it up first).
	static var shown: Control
	var centre := Vector2.ZERO ## Set by _Hall: the painted portal's opening.
	var hole := 0.0
	var _tick := -1
	var _t := 0.0 ## Its own clock: runs faster while it surges.
	var _surge := 0.0 ## 0 idle .. 1 flaring.

	func _ready() -> void:
		shown = self
		_t = Time.get_ticks_msec() / 1000.0

	## Spin up and flare for SURGE_SECS, then `then` (the reveal opens).
	func surge(then: Callable) -> void:
		var tw := create_tween()
		tw.tween_property(self, "_surge", 1.0, SURGE_SECS).set_ease(Tween.EASE_IN)
		tw.tween_callback(then)
		tw.tween_property(self, "_surge", 0.0, .4)

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t += delta * (1.0 + 7.0 * _surge)
		if _surge > 0.0:
			queue_redraw() # Every frame, only while it winds up.
			return
		var tick := CritterIcon.clock()
		if tick != _tick:
			_tick = tick
			queue_redraw()

	func _draw() -> void:
		if hole <= 0.0:
			return
		var c := centre
		var t := 0.0 if A11y.reduced_motion else _t
		# The well darkening toward its edge with a pale core (the glow around
		# the ring is in the painting).
		Dot.circle(self, c, hole, Color("1a0f38"))
		for k in 6:
			var f := 1.0 - k / 6.0
			Dot.circle(self, c, hole * f, Color(.36 + .1 * k, .24 + .08 * k, .7 + .04 * k, .16))
		Dot.circle(self, c, hole * (.16 + .5 * _surge), Color(.95, .9, 1.0, .85))
		# Spiral arms turning inward.
		for arm in ARMS:
			var a0 := -t * .5 + TAU * arm / ARMS
			var pts := PackedVector2Array()
			for i in 15:
				var u := i / 14.0
				pts.append(c + Vector2.from_angle(a0 + u * 3.4) * hole * (.95 - .8 * u))
			draw_polyline(pts, Color(.82, .7, 1.0, .35), hole * .07, true)
			draw_polyline(pts, Color(1, .95, 1, .3), hole * .025, true)
		# Motes spiralling in and fading at the core.
		for i in MOTES:
			var u := fmod(t * .18 + float(i) / MOTES, 1.0)
			var a := i * 2.4 - u * 3.0 - t * .5
			Dot.circle(self, c + Vector2.from_angle(a) * hole * (1.0 - u * .85), hole * .035 * (1.0 - u * .5), Color(1, .92, 1, sin(u * PI) * .8))


## Behind the reveal: a soft violet glow where the eggs land and a few faint
## stars. Drawn once.
class _Backdrop extends Control:
	const Dot := preload("res://game/dot.gd")

	func _draw() -> void:
		var c := Vector2(size.x / 2.0, size.y * .48)
		var r := maxf(size.x, size.y) * .5
		for k in 6:
			Dot.circle(self, c, r * (1.0 - k * .14), Color(.42, .26, .8, .035))
		for k in 3:
			draw_arc(c, r * (.35 + k * .17), 0.0, TAU, 72, Color(.7, .6, 1.0, .05), 2.0, true)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for k in 28:
			var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
			Dot.circle(self, p, rng.randf_range(1.0, 2.6), Color(.9, .85, 1.0, rng.randf_range(.15, .45)))
