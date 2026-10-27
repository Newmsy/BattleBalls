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
			lines.add_child(row(LINE_GLYPHS.get(line, "gear"), tier_color, Gear.LINES[line].name, _pct(line, before.get(line, 0.0)), _pct(line, made.stats[line])))
	var body: Array = [_forge(made), Kit.label(made.name, 34, tier_color, HORIZONTAL_ALIGNMENT_CENTER), stars(made.tier - 1, made.tier, tier_color), lines]
	var foot := Kit.hbox(10, [Kit.amount("hammer", "-%d" % spent, 22, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)
	if made.on != "":
		foot.add_child(Kit.label("· still on %s" % Roster.get_critter(made.on).name, 22, Kit.MUTED))
	body.append(foot)
	_open(shell, "Merged!", body, on_continue, "merge_done")


## The merge popup's header: the new piece glowing over the Anvil King's
## anvil (tools/event_art/scenes/gear_forge.mjs, anvil at about 65% across).
static func _forge(made: Dictionary) -> Control:
	var art := LivingArt.make("gear_forge", "res://game/ui/gear_art/gear_forge.png")
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.soften(40.0) # No hard edge onto the sheet.
	var piece := GearArt.piece(made.type, made.tier, 140)
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
	box.add_child(piece)
	return box


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


## The beat before a merge's popup: three copies of the piece slide in from
## the sides, slam into one with a clank and a ring of sparks, then `then`
## runs (at once with Reduced motion). About 0.4s; taps go through.
static func slam(shell, kind: String, col: Color, then: Callable, tier := 1) -> void:
	if Motion.calm():
		then.call()
		return
	var layer: Control = shell._fx
	var centre: Vector2 = shell.get_global_rect().get_center() - layer.get_global_rect().position
	var side := 120.0
	var froms := [Vector2(-230, 0), Vector2(230, 0), Vector2(0, -230)]
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
		for g in pieces:
			var fade: Tween = g.create_tween().set_parallel()
			fade.tween_property(g, "scale", Vector2(1.4, 1.4), .14)
			fade.tween_property(g, "modulate:a", 0.0, .14)
			fade.chain().tween_callback(g.queue_free)
		then.call())


static func _open(shell, title: String, body: Array, on_continue: Callable, mark_as: String) -> void:
	var v := Kit.vbox(16, [Kit.label(title, 40, Kit.GOOD, HORIZONTAL_ALIGNMENT_CENTER)])
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


static func _pct(line: String, v: float) -> String:
	var pct := 100.0 * v
	return ("%.1f%%" % pct).replace(".0%", "%") if Gear.LINES[line].has("dp") else "%d%%" % roundi(pct)


## Wrapped text needs a width before the modal measures itself.
static func _text_width(shell) -> float:
	return ResultPopup.inner_width(shell.size.x)
