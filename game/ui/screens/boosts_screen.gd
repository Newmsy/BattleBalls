## Arena Boosts (sim/arena_boosts.gd): spend Arena Points, earned with every
## trophy won in the Ghost Arena, on small per-family stat upgrades. Reached
## from the Arena screen. One row per family (stat icons over the columns,
## a 5-pip bar and trophy cost per cell); tap a stat to buy its next level. The rules sit behind the "i".
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const ArenaBoosts := preload("res://sim/arena_boosts.gd")
const Families := preload("res://sim/families.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")
const Intro := preload("res://game/ui/intro.gd")
const ArenaScreen := preload("res://game/ui/screens/arena_screen.gd")

const NAME_WIDTH := 140
## Column heads: one icon per stat line.
const STAT_GLYPHS := {"health": "heart", "attack": "swords", "defense": "shield", "speed": "speed"}
const STAT_COLORS := {"health": Color("ff5c8a"), "attack": Color("ffb02e"), "defense": Color("4fe08a"), "speed": Color("5ce1ff")}


static func build(shell, params: Dictionary) -> Control:
	var store = params.get("store", null)
	if store == null:
		store = ArenaStore.open()
	var root := Kit.vbox(8)
	# The last of a new player's guided steps: the rest of the game opens.
	if Intro.step(shell.profile) == Intro.TROPHY and Intro.reach(shell.profile, Intro.DONE):
		Intro.moment.call_deferred(shell, Intro.DONE)
	var how := [
		"Every trophy you win in the Ghost Arena also earns an Arena Point (the amber arrow). Losing never costs points.",
		"Spend points on a family's Health, Attack, Defense and Speed. Every critter of that family gets the boost in the Ghost Arena, attacking and defending.",
		"%d levels per stat. Max boost is about +%d%% power." % [
			ArenaBoosts.MAX_LEVEL, roundi(100.0 * ArenaBoosts.LINE_POWER * ArenaBoosts.ORDER.size())],
		"Points only come from the Arena. Boosts only work in the Ghost Arena.",
		"Reset is free: every point comes back.",
	]
	root.add_child(shell.title_row("Trophy Room", {"info_mark": "boosts_info", "info": how}))

	var reset := Kit.card_button(Kit.chip("Reset", Kit.MUTED), func():
		var back: int = store.reset_boosts()
		shell.toast("Refunded %s points." % Kit.commas(back) if back > 0 else "Nothing to reset yet.")
		shell.refresh_with({"store": store}), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 999, 0)
	shell.mark("boosts_reset", reset)
	var pts := Kit.hbox(10, [Glyph.make("points", 34, Glyph.GOLD), Kit.label(Kit.commas(store.points), 34), Kit.spacer(), reset], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(Kit.panel(pts, Kit.box(Color("17143e"), Kit.ACCENT, 28, 2, 16)))

	# Your trio's families first, then families you own a critter of; the
	# ones you can't use yet sink to the bottom as one dim line each.
	var trio_fams := {}
	for id in store.trio:
		trio_fams[Families.of(id)] = true
	var owned_fams := {}
	for id in ArenaScreen.owned_critters(shell.profile):
		owned_fams[Families.of(id)] = true
	var rank := func(f: String) -> int:
		if trio_fams.has(f):
			return 0
		if owned_fams.has(f) or ArenaBoosts.family_level(store.boosts.get(f, {})) > 0:
			return 1
		return 2
	var fams: Array = Families.ids()
	fams.sort_custom(func(a, b):
		if rank.call(a) != rank.call(b):
			return rank.call(a) < rank.call(b)
		return Families.ids().find(a) < Families.ids().find(b))
	# Stat icons once over the columns, so each family is one short row.
	var heads := Kit.hbox(6, [], BoxContainer.ALIGNMENT_CENTER)
	var pad := Control.new()
	pad.custom_minimum_size.x = NAME_WIDTH + 10
	heads.add_child(pad)
	for line in ArenaBoosts.ORDER:
		var h := CenterContainer.new()
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(Glyph.make(STAT_GLYPHS[line], 30, STAT_COLORS[line]))
		heads.add_child(h)
	root.add_child(heads)
	var list := Kit.vbox(8)
	for fam in fams:
		list.add_child(_family_row(shell, store, fam, trio_fams.has(fam)) if rank.call(fam) < 2 else _locked_row(fam))
	root.add_child(list)
	return root


static func _family_row(shell, store, fam: String, in_trio: bool) -> Control:
	var f: Dictionary = Families.info(fam)
	var col := Color(f.color)
	var lv := ArenaBoosts.family_level(store.boosts.get(fam, {}))
	var name := Kit.vbox(0, [
		Kit.hbox(6, [FamilyIcon.make(fam, 28), Kit.label(f.name, 24, col)]),
		Kit.label("%d/%d" % [lv, ArenaBoosts.MAX_LEVEL * ArenaBoosts.ORDER.size()] + (" · trio" if in_trio else ""), 18, Kit.MUTED),
	])
	name.custom_minimum_size.x = NAME_WIDTH
	var row := Kit.hbox(6, [name], BoxContainer.ALIGNMENT_CENTER)
	for line in ArenaBoosts.ORDER:
		var btn := _stat_button(shell, store, fam, line, col)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("boost_%s_%s" % [fam, line], btn)
		row.add_child(btn)
	return Kit.panel(row, Kit.box(Kit.PANEL, col if in_trio else Kit.LINE, 22, 2, 8))


## A family you have no critter of yet: one dim line, nothing to tap.
static func _locked_row(fam: String) -> Control:
	var f: Dictionary = Families.info(fam)
	var row := Kit.hbox(8, [
		FamilyIcon.make(fam, 24),
		Kit.label(f.name, 20, Color(f.color, .7)),
		Kit.glyph("lock", 18, Kit.MUTED),
		Kit.label("Own one to unlock", 18, Kit.MUTED),
	], BoxContainer.ALIGNMENT_CENTER)
	return Kit.panel(row, Kit.box(Color(0, 0, 0, 0), Kit.LINE, 18, 1, 6))


## A 5-pip level bar over its next cost (a trophy chip), or MAX.
static func _stat_button(shell, store, fam: String, line: String, col: Color) -> Button:
	var lv: int = store.level_of(fam, line)
	var c: int = store.next_cost(fam, line)
	var afford: bool = c > 0 and store.points >= c
	var pips := Kit.hbox(3, [], BoxContainer.ALIGNMENT_CENTER)
	for i in ArenaBoosts.MAX_LEVEL:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(14, 12)
		pip.add_theme_stylebox_override("panel", Kit.box(col if i < lv else Glyph.OFF, Color(0, 0, 0, 0), 4, 0, 0))
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.add_child(pip)
	var cost: Control
	if c == 0:
		cost = Kit.label("MAX", 18, Kit.GOOD, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		var tint: Color = Kit.FG if afford else Kit.MUTED
		cost = Kit.hbox(3, [Kit.glyph("points", 18, Glyph.GOLD if afford else Kit.MUTED), Kit.label(Kit.commas(c), 18, tint)], BoxContainer.ALIGNMENT_CENTER)
	var content := Kit.vbox(4, [pips, cost])
	var fname: String = Families.info(fam).name
	var lname: String = ArenaBoosts.LINES[line].name
	return Kit.card_button(content, func():
		if c == 0:
			shell.toast("%s %s is maxed: %s." % [fname, lname, ArenaBoosts.text(line, lv)])
		elif store.upgrade(fam, line):
			shell.toast("%s %s %d/%d: %s." % [fname, lname, lv + 1, ArenaBoosts.MAX_LEVEL, ArenaBoosts.text(line, lv + 1)])
			shell.refresh_with({"store": store})
		else:
			shell.toast("Need %d more points" % (c - store.points)),
		col if afford else Kit.LINE, Kit.PANEL2, 18, 6)
