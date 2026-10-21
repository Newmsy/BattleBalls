## Arena Defence: the trio other players fight once online play opens. Until
## then a few seeded themed teams raid it each day (ArenaStore.run_raids);
## holding wins trophies and Tokens. Reached from the Arena hub.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const ArenaScreen := preload("res://game/ui/screens/arena_screen.gd")
const Families := preload("res://sim/families.gd")


static func build(shell, params: Dictionary) -> Control:
	var store = params.get("store", null)
	if store == null:
		store = ArenaStore.open()
	var owned := ArenaScreen.owned_critters(shell.profile)
	store.fit_to(owned)
	var root := Kit.vbox(12)
	var how := [
		"Your Defence trio is the team other players will fight once online play opens. It uses your attack trio's last saved shots.",
		"Until then, %d themed teams near your Defence's power raid it each day, the first time you open the Arena." % ArenaStore.RAIDS_PER_DAY,
		"Each raid you hold wins +5 trophies and %d Tokens. A lost raid costs a few trophies, capped each day, never below your league floor." % ArenaStore.COINS_DEFENCE,
	]
	var info: Control = shell.info_button("Defence", how, "defence_info")
	root.add_child(Kit.hbox(18, [shell.back_button("back"), Kit.label("Defence", 40), Kit.spacer(), info], BoxContainer.ALIGNMENT_CENTER))
	var pow := Kit.hbox(10, [Kit.label("Defence power", 24, Kit.MUTED), Kit.spacer(), Kit.power(store.power(shell.profile, "defence"), 30)], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(Kit.panel(pow, Kit.box(Color("17143e"), Kit.GOOD, 28, 2, 16)))
	root.add_child(ArenaScreen.trio_panel(shell, store, owned, "defence"))
	root.add_child(Kit.caption("Today's raids"))
	if store.raids.is_empty():
		root.add_child(Kit.label("No raids yet today.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	for r in store.raids:
		var fam: Dictionary = Families.info(str(r.family))
		var col: Color = Color(fam.get("color", "ffffff"))
		var line := Kit.hbox(10, [
			Kit.chip(fam.get("name", "?"), col),
			Kit.label(str(r.name), 24),
			Kit.spacer(),
			Kit.label("Held" if r.held else "Lost", 24, Kit.GOOD if r.held else Kit.BAD),
			Kit.label("%+d" % int(r.delta), 22, Kit.MUTED),
		], BoxContainer.ALIGNMENT_CENTER)
		root.add_child(Kit.panel(line, Kit.box(Kit.PANEL, Kit.LINE, 22, 2, 12)))
	return root
