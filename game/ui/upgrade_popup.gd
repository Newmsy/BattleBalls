## The popup after a fuse or a gear merge: what you made, then what changed,
## one line per change with its icon (old → new, the new value lit). A
## centred modal (shell.sheet); everything in it is drawn once.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const ResultPopup := preload("res://game/ui/result_popup.gd")
const Roster := preload("res://game/ui/roster.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const AbilityText := preload("res://game/ui/ability_text.gd")
const Gear := preload("res://sim/gear.gd")
const A11y := preload("res://game/a11y.gd")
const Motion := preload("res://game/ui/motion.gd")
const GearArt := preload("res://game/ui/gear_art.gd")
const LivingArt := preload("res://game/bounce_run/living_art.gd")
const GearTier := preload("res://game/ui/gear_tier.gd")

const GOLD := Color("ffd166")

## The icon for each gear stat line.
const LINE_GLYPHS := {"attack": "swords", "health": "heart", "defense": "shield", "speed": "speed",
	"crit_chance": "target", "crit_damage": "target", "cooldown": "sparkle", "thorns": "shield",
	"mend": "heart", "lifesteal": "heart"}


## One change: icon, what it is, then old → new.
static func row(glyph: String, tint: Color, what: String, before: String, after: String) -> Control:
	var name := Kit.label(what, 22, Kit.MUTED)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var parts: Array = [Kit.glyph(glyph, 30, tint), name]
	if before != "":
		parts.append_array([Kit.label(before, 24, Kit.MUTED), Kit.label("→", 24, Kit.MUTED)])
	parts.append(Kit.label(after, 26, Kit.GOOD))
	return Kit.hbox(10, parts, BoxContainer.ALIGNMENT_CENTER)


## Old stars → new stars, the new ones in `tint`.
static func stars(before: int, after: int, tint := GOLD) -> Control:
	var now := Kit.glyph("stars", 34, tint, after)
	Motion.pop(now, 1.8, .3, .3)
	return Kit.hbox(12, [Kit.glyph("stars", 28, Kit.MUTED, before), Kit.label("→", 26, Kit.MUTED), now],
		BoxContainer.ALIGNMENT_CENTER)


## A fused critter. `pv`: Profile.fuse_preview from before the fuse.
## `on_continue` runs after Continue closes the popup.
static func critter(shell, pv: Dictionary, on_continue := Callable()) -> void:
	var c := Roster.get_critter(pv.id)
	var face := CritterIcon.make(pv.id, pv.tier, 150, true)
	face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var power := row("power", Kit.WARN, "Power", Kit.commas(pv.power_before), Kit.commas(pv.power_after))
	var lines := Kit.vbox(12, [
		power,
		row("crown", Kit.FG, "Max level", str(pv.cap_before), str(pv.cap_after)),
	])
	if pv.level > 1:
		lines.add_child(row("bolt", Kit.ACCENT, "Level", "", "Keeps Lv %d" % pv.level))
	var ability := Kit.label(AbilityText.change(pv.id, pv.tier, pv.level), 23, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)
	ability.custom_minimum_size.x = _text_width(shell)
	var tint: Color = Roster.RARITY_COLORS.get(c.rarity, Kit.ACCENT)
	var new_box := Kit.panel(Kit.vbox(6, [Kit.hbox(8, [Kit.glyph("sparkle", 24, GOLD), Kit.caption("New at T%d" % pv.tier, GOLD)]), ability]),
		Kit.box(Color(GOLD, .08), Color(GOLD, .5), 24, 2, 16))
	_open(shell, "Fused!", [face, Kit.label("%s T%d" % [c.name, pv.tier], 34, tint, HORIZONTAL_ALIGNMENT_CENTER),
		stars(pv.tier - 1, pv.tier), lines, new_box], on_continue, "fuse_done")
	count_up(power.get_child(power.get_child_count() - 1), pv.power_before, pv.power_after)


## The new number counts up from the old one, then pops and flashes, so the
## gain is the moment the eye lands on. Shows the final number straight away
## with Reduced motion.
static func count_up(num: Label, from: int, to: int) -> void:
	if A11y.reduced_motion or from == to:
		return
	num.text = Kit.commas(from)
	var tw := num.create_tween()
	tw.tween_interval(.35)
	tw.tween_method(func(v: float): num.text = Kit.commas(roundi(v)), float(from), float(to), .9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(func():
		num.pivot_offset = num.size / 2.0
		num.scale = Vector2(1.35, 1.35)
		num.modulate = Color(1.6, 1.6, 1.6))
	tw.set_parallel(true)
	tw.chain().tween_property(num, "scale", Vector2.ONE, .35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(num, "modulate", Color.WHITE, .45)


## A merged gear piece. `made`: the new piece (Profile.merge_gear).
static func gear(shell, made: Dictionary, tier_color: Color, spent: int, on_continue := Callable()) -> void:
	var before := Gear.stats_for(made.type, made.tier - 1)
	var lines := Kit.vbox(12)
	for line in Gear.ORDER:
		if made.stats.has(line):
			var was: float = before.get(line, 0.0)
			var now: float = made.stats[line]
			# Forged steps are small: a decimal shows the gain when whole numbers tie.
			var fine := _pct(line, was) == _pct(line, now)
			lines.add_child(row(LINE_GLYPHS.get(line, "gear"), tier_color, Gear.LINES[line].name, _pct(line, was, fine), _pct(line, now, fine)))
	var forged := GearTier.forged(made.tier)
	var body: Array = [_forge(made), Kit.label(made.name, 34, tier_color, HORIZONTAL_ALIGNMENT_CENTER), stars(made.tier - 1, made.tier, tier_color), lines]
	if forged:
		var rank := Kit.label(GearTier.label(made.tier), 28, GearTier.hot(made.tier), HORIZONTAL_ALIGNMENT_CENTER)
		Motion.pop(rank, 1.6, .35, .3)
		body.insert(2, rank)
	var foot := Kit.hbox(10, [Kit.amount("hammer", "-%d" % spent, 22, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)
	if made.on != "":
		foot.add_child(Kit.label("· still on %s" % Roster.get_critter(made.on).name, 22, Kit.MUTED))
	body.append(foot)
	_open(shell, "Forged!" if forged else "Merged!", body, on_continue, "merge_done", GearTier.color(made.tier) if forged else Kit.GOOD)


## The merge popup's header: the new piece glowing over the Anvil King's
## anvil (tools/event_art/scenes/gear_forge.mjs, anvil at about 65% across).
static func _forge(made: Dictionary) -> Control:
	var art := LivingArt.make("gear_forge", "res://game/ui/gear_art/gear_forge.png")
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.soften(40.0) # No hard edge onto the sheet.
	var piece := GearArt.piece(made.type, made.tier, 140)
	var glow: Control = _ember_glow(made.tier)
	piece.anchor_left = .653
	piece.anchor_right = .653
	piece.anchor_top = .42
	piece.anchor_bottom = .42
	piece.offset_left = -70
	piece.offset_right = 70
	piece.offset_top = -70
	piece.offset_bottom = 70
	var box := Control.new()
	box.custom_minimum_size.y = 240
	box.clip_contents = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(art)
	if glow != null:
		for k in ["anchor_left", "anchor_right", "anchor_top", "anchor_bottom"]:
			glow.set(k, piece.get(k))
		glow.offset_left = -130
		glow.offset_right = 130
		glow.offset_top = -130
		glow.offset_bottom = 130
		box.add_child(glow)
	box.add_child(piece)
	return box


## A soft ember heat haze behind an Emberforged piece (one smooth radial
## gradient, hotter per forged level), breathing slowly. null below 6 stars.
static func _ember_glow(tier: int) -> Control:
	if not GearTier.forged(tier):
		return null
	var g := Gradient.new()
	var heat := .45 + .1 * GearTier.level(tier)
	var cols: Array = GearTier.colors(tier)
	# Several colours: a white haze the tween below tints through them.
	var col: Color = cols[0] if cols.size() == 1 else Color.WHITE
	g.set_color(0, Color(GearTier.hot(tier) if cols.size() == 1 else Color.WHITE, heat))
	g.set_offset(0, 0.0)
	g.set_color(1, Color(col, 0.0))
	g.add_point(.45, Color(col, heat * .55))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(.5, .5)
	tex.fill_to = Vector2(1, .5)
	tex.width = 128
	tex.height = 128
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not Motion.calm():
		var tw := t.create_tween().set_loops()
		if cols.size() == 1:
			tw.tween_property(t, "modulate:a", .6, .9).set_trans(Tween.TRANS_SINE)
			tw.tween_property(t, "modulate:a", 1.0, .9).set_trans(Tween.TRANS_SINE)
		else:
			# Higher levels cycle the haze through their colours (a rainbow at 5).
			for c in cols:
				tw.tween_property(t, "modulate", Color(c).lerp(Color.WHITE, .25), .7).set_trans(Tween.TRANS_SINE)
	return t


## Several merges at once (Merge all): one line per piece made.
static func gear_list(shell, made: Array, tier_color: Callable, spent: int, on_continue := Callable()) -> void:
	var lines := Kit.vbox(10)
	for g in made:
		var col: Color = tier_color.call(g.tier)
		var name := Kit.label(g.name, 24)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lines.add_child(Kit.hbox(12, [GearArt.piece(g.type, g.tier, 56, col), name, stars(g.tier - 1, g.tier, col)], BoxContainer.ALIGNMENT_CENTER))
	_open(shell, "Merged %d!" % made.size(), [lines, Kit.hbox(0, [Kit.amount("hammer", "-%d" % spent, 22, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)],
		on_continue, "merge_done")


## The beat before a merge's popup: `n` copies of the piece (3, or 2 when
## forging) slide in from the sides, slam into one with a clank and a ring of
## sparks, then `then` runs (at once with Reduced motion). Forging past 5
## stars also throws a burst of ember sparks and a white-hot flash. About
## 0.4s; taps go through.
static func slam(shell, kind: String, col: Color, then: Callable, tier := 1, n := 3) -> void:
	if Motion.calm():
		then.call()
		return
	var layer: Control = shell._fx
	var centre: Vector2 = shell.get_global_rect().get_center() - layer.get_global_rect().position
	var side := 120.0
	var froms := [Vector2(-230, 0), Vector2(230, 0), Vector2(0, -230)].slice(0, clampi(n, 1, 3))
	var forging := GearTier.forged(tier + 1)
	var pieces: Array = []
	for f in froms:
		var g: Control = GearArt.piece(kind, tier, side, col)
		g.size = Vector2(side, side)
		g.position = centre + f - g.size / 2.0
		g.pivot_offset = g.size / 2.0
		g.modulate.a = 0.0
		layer.add_child(g)
		pieces.append(g)
	var tw := layer.create_tween().set_parallel()
	for g in pieces:
		tw.tween_property(g, "modulate:a", 1.0, .1)
		tw.tween_property(g, "position", centre - g.size / 2.0, .26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		if shell.sfx != null:
			shell.sfx.play("clunk", 0.0, 1.2)
		var ring := Panel.new()
		ring.add_theme_stylebox_override("panel", Kit.box(Color(0, 0, 0, 0), col.lerp(Color.WHITE, .4), 999, 6, 0))
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.size = Vector2(side, side)
		ring.position = centre - ring.size / 2.0
		ring.pivot_offset = ring.size / 2.0
		layer.add_child(ring)
		var out := ring.create_tween().set_parallel()
		out.tween_property(ring, "scale", Vector2(3, 3), .4).set_ease(Tween.EASE_OUT)
		out.tween_property(ring, "modulate:a", 0.0, .4)
		out.chain().tween_callback(ring.queue_free)
		if forging:
			_ember_burst(shell, layer, centre, tier + 1)
		for g in pieces:
			var fade: Tween = g.create_tween().set_parallel()
			fade.tween_property(g, "scale", Vector2(1.4, 1.4), .14)
			fade.tween_property(g, "modulate:a", 0.0, .14)
			fade.chain().tween_callback(g.queue_free)
		then.call())


## Ember sparks flung out from `centre` and a white-hot flash: the forge
## moment. A handful of small rounded panels, gone in half a second.
static func _ember_burst(shell, layer: Control, centre: Vector2, made_tier: int) -> void:
	var count := 8 + 2 * GearTier.level(made_tier)
	var cols: Array = GearTier.colors(made_tier)
	var hot := GearTier.hot(made_tier)
	if shell.sfx != null:
		shell.sfx.play("clunk", 2.0, .7)
	var flash := Panel.new()
	flash.add_theme_stylebox_override("panel", Kit.box(Color(hot, .85), Color(0, 0, 0, 0), 999, 0, 0))
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.size = Vector2(90, 90)
	flash.position = centre - flash.size / 2.0
	flash.pivot_offset = flash.size / 2.0
	layer.add_child(flash)
	var ft := flash.create_tween().set_parallel()
	ft.tween_property(flash, "scale", Vector2(2.6, 2.6), .3).set_ease(Tween.EASE_OUT)
	ft.tween_property(flash, "modulate:a", 0.0, .3)
	ft.chain().tween_callback(flash.queue_free)
	for i in count:
		var a := TAU * (float(i) + .5 * float(i % 2)) / float(count)
		var spark := Panel.new()
		var big := 10.0 + 6.0 * float(i % 3)
		spark.add_theme_stylebox_override("panel", Kit.box(hot if i % 3 == 0 else cols[i % cols.size()], Color(0, 0, 0, 0), 999, 0, 0))
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.size = Vector2(big, big)
		spark.position = centre - spark.size / 2.0
		layer.add_child(spark)
		var reach := 150.0 + 40.0 * float(i % 3)
		var st := spark.create_tween().set_parallel()
		st.tween_property(spark, "position", centre + Vector2(cos(a), sin(a)) * reach - spark.size / 2.0, .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		st.tween_property(spark, "modulate:a", 0.0, .5).set_ease(Tween.EASE_IN)
		st.chain().tween_callback(spark.queue_free)


static func _open(shell, title: String, body: Array, on_continue: Callable, mark_as: String, title_color := Kit.GOOD) -> void:
	var v := Kit.vbox(16, [Kit.label(title, 40, title_color, HORIZONTAL_ALIGNMENT_CENTER)])
	for c in body:
		v.add_child(c)
	# What changed arrives line by line.
	for c in body:
		if c is VBoxContainer and c.get_child_count() > 0 and c.get_child(0) is HBoxContainer:
			Motion.cascade(c.get_children())
	var ok := Kit.button("Continue", func():
		shell.close_overlay()
		if on_continue.is_valid():
			on_continue.call(), "go", 28, 88)
	shell.mark(mark_as, ok)
	v.add_child(ok)
	shell.sheet(v)


static func _pct(line: String, v: float, fine := false) -> String:
	var pct := 100.0 * v
	if fine and not Gear.LINES[line].has("dp"):
		return "%.1f%%" % pct
	return ("%.1f%%" % pct).replace(".0%", "%") if Gear.LINES[line].has("dp") else "%d%%" % roundi(pct)


## Wrapped text needs a width before the modal measures itself.
static func _text_width(shell) -> float:
	return ResultPopup.inner_width(shell.size.x)
