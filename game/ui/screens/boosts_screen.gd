## Arena Boosts (sim/arena_boosts.gd): spend Arena Points, earned with every
## trophy won in the Ghost Arena, on small per-family stat upgrades. Reached
## from the Arena screen. One row per family; tap a stat to buy its next
## level. The rules sit behind the "i".
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const ArenaBoosts := preload("res://sim/arena_boosts.gd")
const Families := preload("res://sim/families.gd")
const Intro := preload("res://game/ui/intro.gd")

const NAME_WIDTH := 140


static func build(shell, params: Dictionary) -> Control:
	var store = params.get("store", null)
	if store == null:
		store = ArenaStore.open()
	var root := Kit.vbox(8)
	# The last of a new player's guided steps: the rest of the game opens.
	if Intro.step(shell.profile) == Intro.TROPHY and Intro.reach(shell.profile, Intro.DONE):
		Intro.moment.call_deferred(shell, Intro.DONE)
	var how := [
		"Every trophy you win in the Ghost Arena also earns an Arena Point. Losing trophies never costs points.",
		"Spend points on a family's Health, Attack, Defense and Speed. Every critter of that family gets the boost in the Ghost Arena, attacking and defending.",
		"Each line has 5 levels. Level 1 costs %d points and each level costs %d more. A fully boosted family is about +%d%% power, so a higher tier still wins." % [
			ArenaBoosts.cost(1), ArenaBoosts.COST_STEP, roundi(100.0 * ArenaBoosts.LINE_POWER * ArenaBoosts.ORDER.size())],
		"Points only come from Arena play; they're never sold. Even Arena and practice modes ignore boosts.",
		"Reset gives back every point you spent, free, so you can follow your trio.",
	]
	var info: Control = shell.info_button("Trophy Room", how, "boosts_info")
	root.add_child(Kit.hbox(18, [shell.back_button("back"), Kit.label("Trophy Room", 40), Kit.spacer(), info], BoxContainer.ALIGNMENT_CENTER))

	var reset := Kit.card_button(Kit.chip("Reset", Kit.MUTED), func():
		var back: int = store.reset_boosts()
		shell.toast("Refunded %s points." % Kit.commas(back) if back > 0 else "Nothing to reset yet.")
		shell.refresh_with({"store": store}), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 999, 0)
	shell.mark("boosts_reset", reset)
	var pts := Kit.hbox(10, [Glyph.make("stars", 30), Kit.label(Kit.commas(store.points), 34), Kit.label("Arena Points", 22, Kit.MUTED), Kit.spacer(), reset], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(Kit.panel(pts, Kit.box(Color("17143e"), Kit.ACCENT, 28, 2, 16)))

	# Your trio's families first, then the rest in roster order.
	var trio_fams := {}
	for id in store.trio:
		trio_fams[Families.of(id)] = true
	var fams: Array = Families.ids()
	fams.sort_custom(func(a, b):
		if trio_fams.has(a) != trio_fams.has(b):
			return trio_fams.has(a)
		return Families.ids().find(a) < Families.ids().find(b))
	# Column heads once, so each family is one short row.
	var heads := Kit.hbox(6, [], BoxContainer.ALIGNMENT_CENTER)
	var pad := Control.new()
	pad.custom_minimum_size.x = NAME_WIDTH + 10
	heads.add_child(pad)
	for line in ArenaBoosts.ORDER:
		var h := Kit.label(ArenaBoosts.LINES[line].short, 18, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heads.add_child(h)
	root.add_child(heads)
	var list := Kit.vbox(8)
	for fam in fams:
		list.add_child(_family_row(shell, store, fam, trio_fams.has(fam)))
	root.add_child(list)
	return root


static func _family_row(shell, store, fam: String, in_trio: bool) -> Control:
	var f: Dictionary = Families.info(fam)
	var col := Color(f.color)
	var lv := ArenaBoosts.family_level(store.boosts.get(fam, {}))
	var name := Kit.vbox(0, [
		Kit.label(f.name, 24, col),
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


static func _stat_button(shell, store, fam: String, line: String, col: Color) -> Button:
	var lv: int = store.level_of(fam, line)
	var c: int = store.next_cost(fam, line)
	var afford: bool = c > 0 and store.points >= c
	var bottom := Kit.label("MAX" if c == 0 else Kit.commas(c), 18, Kit.GOOD if c == 0 else (Kit.FG if afford else Kit.MUTED), HORIZONTAL_ALIGNMENT_CENTER)
	var content := Kit.vbox(0, [
		Kit.label("%d/%d" % [lv, ArenaBoosts.MAX_LEVEL], 22, col if lv > 0 else Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
		bottom,
	])
	var fname: String = Families.info(fam).name
	var lname: String = ArenaBoosts.LINES[line].name
	return Kit.card_button(content, func():
		if c == 0:
			shell.toast("%s %s is maxed: %s." % [fname, lname, ArenaBoosts.text(line, lv)])
		elif store.upgrade(fam, line):
			shell.toast("%s %s %d/%d: %s." % [fname, lname, lv + 1, ArenaBoosts.MAX_LEVEL, ArenaBoosts.text(line, lv + 1)])
			shell.refresh_with({"store": store})
		else:
			shell.toast("Needs %d Arena Points. Win Arena fights to earn more." % c),
		col if afford else Kit.LINE, Kit.PANEL2, 18, 4)
