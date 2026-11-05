## Arena Defence, for one Arena mode (the store's): the team other players
## fight. A few seeded player-style squads raid it each day too
## (ArenaStore.run_raids); holding wins trophies and Arena Coins. Reached
## from a mode's page.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const ArenaScreen := preload("res://game/ui/screens/arena_screen.gd")
const Families := preload("res://sim/families.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")
const ArenaBadges := preload("res://game/ui/arena_badges.gd")


static func build(shell, params: Dictionary) -> Control:
	var store = params.get("store", null)
	if store == null:
		store = ArenaStore.open()
	store.use(str(params.get("mode", store.mode)))
	var owned := ArenaScreen.owned_critters(shell.profile)
	store.fit_to(owned)
	var root := Kit.vbox(12)
	var how := [
		"Your Defence gets raided by %d players near its power each day, using your attack team's last saved shots." % ArenaStore.RAIDS_PER_DAY,
		"Each raid you hold wins +5 trophies and %d Arena Coins. A lost raid costs a few trophies, capped each day, never below your league floor." % ArenaStore.COINS_DEFENCE,
		"Beat a raider who won back with Revenge, for %sx trophies, once per raid. It costs an Arena Token like any fight." % str(ArenaStore.REVENGE_MULT),
	]
	root.add_child(shell.title_row("Defence", {"eyebrow": str(ArenaStore.MODES[store.mode].name).to_upper(), "eyebrow_color": ArenaStore.MODES[store.mode].color, "info_mark": "defence_info", "info": how}))
	var pow := Kit.hbox(10, [Kit.label("Defence power", 24, Kit.MUTED), Kit.spacer(), Kit.power(store.power(shell.profile, "defence"), 30)], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(Kit.panel(pow, Kit.box(Color("17143e"), Kit.GOOD, 28, 2, 16)))
	root.add_child(ArenaScreen.trio_panel(shell, store, owned, "defence"))
	root.add_child(Kit.caption("Today's raids"))
	if store.raids.is_empty():
		root.add_child(Kit.label("No raids yet today.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	for i in store.raids.size():
		var r: Dictionary = store.raids[i]
		var fam: Dictionary = Families.info(str(r.family))
		var col: Color = Color(fam.get("color", "ffffff"))
		var line := Kit.hbox(10, [
			FamilyIcon.make(str(r.family), 32) if not fam.is_empty() else Kit.chip("?", col),
			Kit.label(str(r.name), 24),
			Kit.spacer(),
			Kit.label("Held" if r.held else "Lost", 24, Kit.GOOD if r.held else Kit.BAD),
			Kit.label("%+d" % int(r.delta), 22, Kit.MUTED),
		], BoxContainer.ALIGNMENT_CENTER)
		if not r.held and r.has("seed") and store.raid_day == ArenaStore.today():
			if r.get("avenged", false):
				line.add_child(Kit.label("Avenged", 20, Kit.MUTED))
			else:
				var go := Kit.button("Revenge", ArenaScreen._attack.bind(shell, store, store.revenge_offer(i)), "go", 20, 52)
				shell.mark("defence_revenge_%d" % i, go)
				line.add_child(go)
		root.add_child(Kit.panel(line, Kit.box(Kit.PANEL, Kit.LINE, 22, 2, 12)))
	return root
