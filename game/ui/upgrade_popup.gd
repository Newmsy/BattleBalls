## The popup after a fuse or a gear merge: what you made, then what changed,
## one line per change with its icon (old → new, the new value lit). A
## centred modal (shell.sheet); everything in it is drawn once.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Roster := preload("res://game/ui/roster.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const AbilityText := preload("res://game/ui/ability_text.gd")
const Gear := preload("res://sim/gear.gd")

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
	return Kit.hbox(12, [Kit.glyph("stars", 28, Kit.MUTED, before), Kit.label("→", 26, Kit.MUTED), Kit.glyph("stars", 34, tint, after)],
		BoxContainer.ALIGNMENT_CENTER)


## A fused critter. `pv`: Profile.fuse_preview from before the fuse.
## `on_continue` runs after Continue closes the popup.
static func critter(shell, pv: Dictionary, on_continue := Callable()) -> void:
	var c := Roster.get_critter(pv.id)
	var face := CritterIcon.make(pv.id, pv.tier, 150, true)
	face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var lines := Kit.vbox(12, [
		row("power", Kit.WARN, "Power", Kit.commas(pv.power_before), Kit.commas(pv.power_after)),
		row("crown", Kit.FG, "Max level", str(pv.cap_before), str(pv.cap_after)),
	])
	if pv.level > 1:
		lines.add_child(row("bolt", Kit.ACCENT, "Level", "", "Keeps Lv %d" % pv.level))
	var ability := Kit.label(AbilityText.change(pv.id, pv.tier), 23, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)
	ability.custom_minimum_size.x = _text_width(shell)
	var tint: Color = Roster.RARITY_COLORS.get(c.rarity, Kit.ACCENT)
	var new_box := Kit.panel(Kit.vbox(6, [Kit.hbox(8, [Kit.glyph("sparkle", 24, GOLD), Kit.caption("New at T%d" % pv.tier, GOLD)]), ability]),
		Kit.box(Color(GOLD, .08), Color(GOLD, .5), 24, 2, 16))
	_open(shell, "Fused!", [face, Kit.label("%s T%d" % [c.name, pv.tier], 34, tint, HORIZONTAL_ALIGNMENT_CENTER),
		stars(pv.tier - 1, pv.tier), lines, new_box], on_continue, "fuse_done")


## A merged gear piece. `made`: the new piece (Profile.merge_gear).
static func gear(shell, made: Dictionary, tier_color: Color, spent: int, on_continue := Callable()) -> void:
	var before := Gear.stats_for(made.type, made.tier - 1)
	var lines := Kit.vbox(12)
	for line in Gear.ORDER:
		if made.stats.has(line):
			lines.add_child(row(LINE_GLYPHS.get(line, "gear"), tier_color, Gear.LINES[line].name, _pct(line, before.get(line, 0.0)), _pct(line, made.stats[line])))
	var icon := Glyph.make(made.type, 120, tier_color)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var body: Array = [icon, Kit.label(made.name, 34, tier_color, HORIZONTAL_ALIGNMENT_CENTER), stars(made.tier - 1, made.tier, tier_color), lines]
	var foot := Kit.hbox(10, [Kit.amount("hammer", "-%d" % spent, 22, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)
	if made.on != "":
		foot.add_child(Kit.label("· still on %s" % Roster.get_critter(made.on).name, 22, Kit.MUTED))
	body.append(foot)
	_open(shell, "Merged!", body, on_continue, "merge_done")


## Several merges at once (Merge all): one line per piece made.
static func gear_list(shell, made: Array, tier_color: Callable, spent: int, on_continue := Callable()) -> void:
	var lines := Kit.vbox(10)
	for g in made:
		var col: Color = tier_color.call(g.tier)
		var name := Kit.label(g.name, 24)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lines.add_child(Kit.hbox(12, [Kit.glyph(g.type, 48, col), name, stars(g.tier - 1, g.tier, col)], BoxContainer.ALIGNMENT_CENTER))
	_open(shell, "Merged %d!" % made.size(), [lines, Kit.hbox(0, [Kit.amount("hammer", "-%d" % spent, 22, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)],
		on_continue, "merge_done")


static func _open(shell, title: String, body: Array, on_continue: Callable, mark_as: String) -> void:
	var v := Kit.vbox(16, [Kit.label(title, 40, Kit.GOOD, HORIZONTAL_ALIGNMENT_CENTER)])
	for c in body:
		v.add_child(c)
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
	return minf(640.0, shell.size.x - 120.0)
