## Critters tab ("My critters"): only the critters you own, one card per copy
## (three T1 Zips are three cards), strongest first. Each card shows tier
## stars, level and power; a FUSE ribbon marks copies with 3 at one tier.
## The Critterpedia button opens every critter, found or not (dex_screen.gd).
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")

static var filter := "all"


## Every owned copy as {id, tier, level, power, stack}, strongest first. Gear
## sits on a critter's best copy, so only that copy counts it.
static func cards(p) -> Array:
	var out: Array = []
	for c in Roster.CRITTERS:
		var best: Dictionary = p.best(c.id)
		for s in p.copies(c.id):
			var pw: int = p.power_of(c.id) if s == best else Roster.power(c.id, s.tier, s.level)
			for i in s.count:
				out.append({"id": c.id, "tier": s.tier, "level": s.level, "power": pw, "stack": s})
	out.sort_custom(func(a, b): return a.power > b.power if a.power != b.power else a.id < b.id)
	return out


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(22)
	var dex := Kit.card_button(Kit.hbox(8, [Kit.glyph("critters", 26, Kit.ACCENT), Kit.label("Critterpedia", 22, Kit.FG)], BoxContainer.ALIGNMENT_CENTER),
		func(): shell.go("dex"), Kit.ACCENT, Kit.PANEL2, 999, 12)
	dex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shell.mark("critterpedia", dex)
	var factions := Kit.card_button(Kit.label("Factions", 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER), func(): shell.go("factions"), Kit.ACCENT, Kit.PANEL2, 999, 12)
	factions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shell.mark("factions", factions)
	root.add_child(Kit.hbox(12, [Kit.label("My critters", 40), Kit.spacer(), factions, dex], BoxContainer.ALIGNMENT_CENTER))

	var chips := Kit.hbox(6)
	for f in ["all"] + Roster.RARITIES:
		var on: bool = f == filter
		var col: Color = Kit.FG if f == "all" else Roster.RARITY_COLORS[f]
		var name: String = "All" if f == "all" else Roster.RARITY_NAMES[f]
		var l := Kit.label(name, 20, Kit.BG if on else col, HORIZONTAL_ALIGNMENT_CENTER)
		var b := Kit.card_button(l, func(): filter = f; shell.refresh(), Kit.ACCENT if on else Kit.LINE, Kit.ACCENT if on else Kit.PANEL, 999, 8)
		chips.add_child(b)
	root.add_child(chips)

	var all := cards(p)
	var shown := all.filter(func(k): return filter == "all" or Roster.get_critter(k.id).rarity == filter)
	root.add_child(Kit.label("%d critters · %d / %d species found" % [all.size(), p.found_count(), Roster.CRITTERS.size()], 21, Kit.MUTED))
	if shown.is_empty():
		var what: String = "" if filter == "all" else Roster.RARITY_NAMES[filter] + " "
		root.add_child(Kit.label("No %scritters yet. Summon or win them, and see them all in the Critterpedia." % what, 23, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
		return root

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	var seen := {}
	for k in shown:
		var n: int = seen.get(k.id, 0)
		seen[k.id] = n + 1
		grid.add_child(_tile(shell, k, "tile_" + k.id + ("" if n == 0 else "_%d" % n)))
	root.add_child(grid)
	return root


static func _tile(shell, k: Dictionary, mark_as: String) -> Control:
	var c := Roster.get_critter(k.id)
	var info := Kit.hbox(6, [Kit.label("Lv %d" % k.level, 20, Kit.MUTED), Kit.power(k.power, 20, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)
	var stars := CenterContainer.new()
	stars.add_child(Glyph.make("stars", 22, Kit.FG, k.tier))
	var name := Kit.label(c.name, 23, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var icon_layer := Control.new()
	icon_layer.custom_minimum_size = Vector2(170, 170)
	icon_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := CritterIcon.make(k.id, k.tier, 170)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_layer.add_child(icon)
	if k.stack.count >= 3 and k.tier < Roster.MAX_TIER:
		var rib := Kit.panel(Kit.label("FUSE", 18, Kit.BG), Kit.box(Kit.GOOD, Color(0, 0, 0, 0), 10, 0, 4))
		rib.get_theme_stylebox("panel").content_margin_left = 10
		rib.get_theme_stylebox("panel").content_margin_right = 10
		icon_layer.add_child(rib)
	var v := Kit.vbox(4, [icon_layer, name, stars, info])
	var t := Kit.card_button(v, func(): shell.go("detail", {"id": k.id, "tier": k.tier}), Roster.rarity_border(c.rarity, Kit.LINE), Roster.rarity_bg(c.rarity, Kit.PANEL), 28, 8)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark(mark_as, t)
	return t
