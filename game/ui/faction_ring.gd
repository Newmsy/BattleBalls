## Faction XP on the result popup: the family's coin badge with a ring round
## it that sweeps from the old XP to the new while the gain counts up. When
## the ring closes it flashes gold, sparks burst out, the rank on its tab
## stamps in and a "+1 TALENT POINT" pill pops; then it fills on into the
## next rank. Takes Profile.take_faction_gains() (one entry per family; a
## mixed team shows a smaller ring per family, filling one after another).
## Render-only: tweens only, so nothing redraws once the ring has stopped.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const A11y := preload("res://game/a11y.gd")
const Dot := preload("res://game/dot.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")
const Families := preload("res://sim/families.gd")
const Talents := preload("res://sim/talents.gd")
const Profile := preload("res://meta/profile.gd")

const GOLD := Color("ffd25a")
const TRACK := Color("24204f")
const BIG := 150.0 ## One family: the ring's side.
const SMALL := 112.0 ## Two or three families side by side.


## The rings for a result's gains, or null when there are none. `sfx`
## (game/audio/sfx.gd, may be null) chimes on rank-ups; `delay` waits for
## the popup to pop in first. `on_spend(family)`, when given, adds a Spend
## button beside the talent point pill that opens that faction's tree.
static func rows(gains: Array, sfx = null, delay := .45, on_spend := Callable()) -> Control:
	if gains.is_empty():
		return null
	var side := BIG if gains.size() == 1 else SMALL
	var row := Kit.hbox(18, [], BoxContainer.ALIGNMENT_CENTER)
	var at := delay
	for g in gains:
		row.add_child(make(g, side, sfx, at, on_spend))
		at += .5
	return row


## One family's ring. On its own it sits left of its "+30 Fire XP" line,
## "76 / 100" and the talent point pill, so it takes one short row of the
## popup; side by side (a mixed team) each ring has just its gain under it.
static func make(g: Dictionary, side := BIG, sfx = null, delay := .45, on_spend := Callable()) -> Control:
	var ring := _Ring.new()
	ring.family = g.family
	ring.custom_minimum_size = Vector2(side, side)
	ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name := str(Families.info(g.family).get("name", ""))
	var of := Kit.label("", 22, Kit.MUTED)
	var box: BoxContainer
	var pill: Control
	if side >= BIG:
		pill = _pill("+1 TALENT POINT", 20)
		var info := Kit.vbox(6, [
			Kit.hbox(8, [Kit.label("+%d" % int(g.xp), 30, Kit.GOOD), Kit.label(name + " XP", 26)]),
			of, pill])
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		box = Kit.hbox(20, [ring, info], BoxContainer.ALIGNMENT_CENTER)
	else:
		pill = _pill("+1 POINT", 16)
		box = Kit.vbox(4, [ring, Kit.hbox(6, [Kit.label("+%d" % int(g.xp), 22, Kit.GOOD), Kit.label(name, 20)], BoxContainer.ALIGNMENT_CENTER), pill])
		box.alignment = BoxContainer.ALIGNMENT_CENTER
	if on_spend.is_valid():
		# The point and a way to spend it, showing together on the rank-up.
		var spend := Kit.button("Spend", on_spend.bind(g.family), "go", 20 if side >= BIG else 16, 52 if side >= BIG else 44)
		spend.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var parent := pill.get_parent()
		var at := pill.get_index()
		if parent != null:
			parent.remove_child(pill)
		var both := Kit.hbox(10, [pill, spend], BoxContainer.ALIGNMENT_CENTER)
		both.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if side >= BIG else Control.SIZE_SHRINK_CENTER
		if parent != null:
			parent.add_child(both)
			parent.move_child(both, at)
		pill = both
	pill.modulate.a = 0.0
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.ready.connect(_play.bind(box, ring, g, of, pill, sfx, delay), CONNECT_ONE_SHOT)
	return box


## The Spend action for a popup on the shell: closes it and opens the tree.
static func spend_in(shell) -> Callable:
	return func(family: String) -> void:
		shell.close_overlay()
		shell.go("faction", {"id": family})


static func _pill(text: String, font_size: int) -> Control:
	var st := Kit.box(GOLD, GOLD, 999, 0, 2)
	st.content_margin_left = 16
	st.content_margin_right = 16
	var p := Kit.panel(Kit.label(text, font_size, Color("2a1a00"), HORIZONTAL_ALIGNMENT_CENTER), st)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return p


## The shown rank: talent points from XP plus tier milestones, at most the cap.
static func _shown(xp_rank: int, marks: int) -> int:
	return mini(Talents.MAX_POINTS, xp_rank + marks)


## How far into rank `rank` `xp` is, 0..1 (full at the cap).
static func _frac(rank: int, xp: int) -> float:
	return 1.0 if rank >= Talents.MAX_POINTS else clampf(xp / float(Profile.faction_xp_to_next(rank)), 0.0, 1.0)


static func _play(box: Control, ring: _Ring, g: Dictionary, of: Label, pill: Control, sfx, delay: float) -> void:
	var from_rank := int(g.from_rank)
	var to_rank := int(g.to_rank)
	var marks := int(g.get("marks", 0))
	var ups := to_rank - from_rank
	var capped := to_rank >= Talents.MAX_POINTS
	var start := _frac(from_rank, int(g.from_xp))
	# The whole gain as one number: whole ranks plus the fraction into the
	# next, run by one eased tween (as XpBar does for levels).
	var total: float = ups + (0.0 if capped else _frac(to_rank, int(g.to_xp)))
	var show := func(p: float) -> void:
		var whole := int(p + 0.0001)
		while ring.reached < mini(whole, ups):
			ring.reached += 1
			_rank_up(box, ring, pill, sfx)
		var rank := from_rank + mini(whole, ups)
		ring.rank = _shown(rank, marks)
		ring.fill = 1.0 if (capped and p >= total - 0.0001) else p - whole
		var need := Profile.faction_xp_to_next(rank)
		of.text = "MAX" if rank >= Talents.MAX_POINTS else "%d / %d" % [roundi(ring.fill * need), need]
		ring.queue_redraw()
	ring.rank = _shown(from_rank, marks)
	ring.fill = start
	show.call(start)
	if A11y.reduced_motion:
		show.call(total)
		return
	var tw := box.create_tween()
	tw.tween_interval(delay)
	tw.tween_method(show, start, total, clampf(1.1 + .5 * ups, 1.1, 2.6)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(show.bind(total))


## The ring closed: a gold flash and a burst of sparks, the rank tab stamps
## in and the talent point pill pops.
static func _rank_up(box: Control, ring: _Ring, pill: Control, sfx) -> void:
	if sfx != null:
		sfx.play("knock_" + ring.family, 0.0, 1.0)
		sfx.play("twinkle", 0.0, 1.0 + .06 * ring.reached)
	pill.modulate.a = 1.0
	if A11y.reduced_motion:
		return
	var tw := box.create_tween().set_parallel()
	ring.flash = 1.0
	ring.burst = 0.0
	ring.stamp = 1.4
	tw.tween_property(ring, "flash", 0.0, .7).set_ease(Tween.EASE_IN)
	tw.tween_property(ring, "burst", 1.0, .7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(ring, "stamp", 1.0, .35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pill.pivot_offset = pill.size / 2.0
	pill.scale = Vector2(.2, .2)
	tw.tween_property(pill, "scale", Vector2.ONE, .3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var pop := func(s: float) -> void:
		ring.pivot_offset = ring.size / 2.0
		ring.scale = Vector2(s, s)
	tw.tween_method(pop, 1.12, 1.0, .4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


class _Ring extends Control:
	var family := ""
	var rank := 0
	var reached := 0 ## Rank-ups played so far.
	var fill := 0.0
	var flash := 0.0:
		set(v):
			flash = v
			queue_redraw()
	var burst := 1.0:
		set(v):
			burst = v
			queue_redraw()
	var stamp := 1.0:
		set(v):
			stamp = v
			queue_redraw()

	func _draw() -> void:
		var side := minf(size.x, size.y)
		var c := size / 2.0
		var w := side * .085
		var r := side / 2.0 - w / 2.0 - side * .04
		var FamilyIcon = load("res://game/ui/family_icon.gd")
		var col: Color = FamilyIcon.color(family)
		var gold := Color("ffd25a")
		if flash > 0.0:
			Dot.circle(self, c, r + w, Color(gold, .22 * flash))
		Dot.ring(self, c, r, w, Color("24204f"))
		if fill > .002:
			draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * fill, maxi(16, int(64 * fill)), col, w, true)
		if flash > 0.0:
			Dot.ring(self, c, r, w, Color(gold, flash))
		FamilyIcon.draw_coin(self, family, c, (r - w / 2.0) * 2.0 * .9)
		if burst > 0.0 and burst < 1.0:
			for k in 16:
				var a := TAU * k / 16.0 + .2
				var d := r * (1.0 + .45 * burst)
				Dot.circle(self, c + Vector2(cos(a), sin(a)) * d, (1.0 - burst) * w * .35 + 1.0, gold if k % 2 else col)
		# The rank on a tab across the bottom of the ring.
		var font: Font = load("res://game/fonts/ChakraPetch-Bold.ttf")
		var fs := int(side * .15)
		var tab := Vector2(side * .34, side * .2) * stamp
		var at := c + Vector2(0, r)
		var tab_col := gold if reached > 0 else col
		Dot.circle(self, at - Vector2(tab.x / 2.0 - tab.y / 2.0, 0), tab.y / 2.0, tab_col)
		Dot.circle(self, at + Vector2(tab.x / 2.0 - tab.y / 2.0, 0), tab.y / 2.0, tab_col)
		Dot.rect(self, Rect2(at - Vector2(tab.x / 2.0 - tab.y / 2.0, tab.y / 2.0), Vector2(tab.x - tab.y, tab.y)), tab_col)
		var text := str(rank)
		var tfs := int(fs * stamp)
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs).x
		draw_string(font, at + Vector2(-tw / 2.0, tfs * .36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs, Color("14102e"))
