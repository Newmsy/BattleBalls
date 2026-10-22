## The Critterpedia: every critter in number order, found or not. Found ones
## are in colour; the rest are dark silhouettes with their name and rarity.
## Tapping any entry opens its page (dex_entry_screen.gd).
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const LazyTile := preload("res://game/ui/lazy_tile.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const DetailScreen := preload("res://game/ui/screens/detail_screen.gd")

static var filter := "all"


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(20)
	root.add_child(DetailScreen.header(shell, "Critterpedia", Kit.label("%d / %d" % [p.found_count(), Roster.CRITTERS.size()], 24, Kit.MUTED)))

	var chips := Kit.hbox(6)
	for f in ["all"] + Roster.RARITIES:
		var on: bool = f == filter
		var col: Color = Kit.FG if f == "all" else Roster.RARITY_COLORS[f]
		var name: String = "All" if f == "all" else Roster.RARITY_NAMES[f]
		var l := Kit.label(name, 20, Kit.BG if on else col, HORIZONTAL_ALIGNMENT_CENTER)
		chips.add_child(Kit.card_button(l, func(): filter = f; shell.refresh(), Kit.ACCENT if on else Kit.LINE, Kit.ACCENT if on else Kit.PANEL, 999, 8))
	root.add_child(chips)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for c in Roster.CRITTERS:
		if filter == "all" or c.rarity == filter:
			var owned: bool = p.owns(c.id)
			grid.add_child(LazyTile.wrap(func(): return _entry(shell, owned, c), grid.get_child_count(), 20))
	root.add_child(grid)
	return root


static func _entry(shell, owned: bool, c: Dictionary) -> Control:
	var rcol: Color = Roster.RARITY_COLORS[c.rarity]
	var num := Kit.label("#%03d" % CritterDb.get_critter(c.id).no, 17, Kit.MUTED if owned else Color(Kit.MUTED, .6), HORIZONTAL_ALIGNMENT_CENTER)
	var name := Kit.label(c.name, 20, Kit.FG if owned else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var rarity := Kit.label(Roster.RARITY_NAMES[c.rarity], 17, Color(rcol, 1.0 if owned else .7), HORIZONTAL_ALIGNMENT_CENTER)
	var art := CritterIcon.make(c.id, 1, 124, false, not owned)
	art.family_badge = true
	var v := Kit.vbox(0, [num, art, name, rarity])
	# Found critters get the full rarity tint; unfound ones a faint one, so the silhouette still reads.
	var border := Roster.rarity_border(c.rarity, Kit.LINE) if owned else Color(Roster.rarity_border(c.rarity, Kit.LINE), .45)
	var bg := Roster.rarity_bg(c.rarity, Kit.PANEL) if owned else Roster.rarity_bg(c.rarity, Color("0f0d27"), .08)
	var t := Kit.card_button(v, func(): shell.go("dex_entry", {"id": c.id}), border, bg, 24, 6)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("dex_" + c.id, t)
	return t
