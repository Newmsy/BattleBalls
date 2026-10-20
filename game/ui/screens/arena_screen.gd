## Ghost Arena (design/pvp.md): your league and trophies, your trio, and the
## three opponent cards. Picking a card starts the attack and opens the
## relay fight scene (game/ghost_arena.gd).
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const ArenaGhosts := preload("res://game/pvp/arena_ghosts.gd")
const Loaner := preload("res://game/loaner.gd")
const CritterPicker := preload("res://game/ui/critter_picker.gd")
const Intro := preload("res://game/ui/intro.gd")
const ArenaTeams := preload("res://game/pvp/arena_teams.gd")
const Families := preload("res://sim/families.gd")

const CARD_COLORS := {"easier": Kit.GOOD, "even": Kit.ACCENT, "harder": Kit.WARN}
const FIGHT_SCENE := "res://game/ghost_arena.tscn"
## Below this screen height (an iPhone SE) opponents are one-line rows.
const COMPACT_HEIGHT := 1500.0


static func build(shell, params: Dictionary) -> Control:
	var store = params.get("store", null)
	if store == null:
		store = ArenaStore.open()
	var abandoned: int = store.settle_abandoned()
	if abandoned != 0:
		shell.toast.call_deferred("Your last attack wasn't finished, so it counted as a loss (%d)." % abandoned)
	var owned := owned_critters(shell.profile)
	store.fit_to(owned)
	var raids: Array = store.run_raids(shell.profile)
	if not raids.is_empty():
		var held := raids.filter(func(r): return r.held).size()
		var dt := 0
		for r in raids:
			dt += int(r.delta)
		shell.toast.call_deferred("Your defence held %d of %d raids overnight (%+d trophies)." % [held, raids.size(), dt])
	var root := Kit.vbox(10)

	var back: Control = shell.back_button("back")
	var how := [
		"Your trio fights theirs in order; their order stays hidden until each ball comes out. A winner stays in with the HP it has left. Each ball's last shot is saved for your ghost.",
		"Tap a trio slot to pick a critter you own. Each critter fits in a trio once; picking one already in it swaps the two. Best trio fills in your strongest three.",
		"Opponents are themed teams sized to your trio's power, a little stronger the more trophies you have. Easier cards risk fewer trophies, harder ones win more. One free refresh a day.",
		"Every trophy you win also earns an Arena Point for the Trophy Room. Every attack earns Tokens for the Bazaar.",
		"Set your Defence trio: each day a few teams raid it. Holding wins trophies and Tokens.",
	]
	for h in store.history.slice(0, 5):
		how.append("%s vs %s (%+d)" % ["Won" if h.won else "Lost", str(h.name), int(h.delta)])
	var info: Control = shell.info_button("How the Arena works", how, "arena_info")
	root.add_child(Kit.hbox(14, [back, Kit.label("Ghost Arena", 40), Kit.spacer(), info], BoxContainer.ALIGNMENT_CENTER))
	root.add_child(_league_panel(store))
	var held_today: int = store.raids.filter(func(r): return r.held).size() if store.raid_day == ArenaStore.today() else 0
	# A new player's first Arena win opens the Trophy Room; the rest come after.
	var p = shell.profile
	if Intro.step(p) == Intro.ARENA and Intro.arena_fought:
		Intro.reach(p, Intro.TROPHY)
		Intro.moment.call_deferred(shell, Intro.TROPHY)
	var rooms := Kit.hbox(10)
	if Intro.shows(p, "trophy"):
		rooms.add_child(_room(shell, "arena_boosts", "trophy", "Trophy Room", "%s pts" % Kit.commas(store.points), Kit.WARN, func(): shell.go("boosts", {"store": store})))
	if Intro.done(p):
		rooms.add_child(_room(shell, "arena_bazaar", "token", "Bazaar", "%s tokens" % Kit.commas(store.coins), Color("ff4fd8"), func(): shell.go("bazaar", {"store": store})))
		rooms.add_child(_room(shell, "arena_defence", "shield", "Defence", "Held %d/%d" % [held_today, store.raids.size()] if not store.raids.is_empty() else "Set trio", Kit.GOOD, func(): shell.go("defence", {"store": store})))
	if rooms.get_child_count() > 0:
		root.add_child(rooms)
	root.add_child(trio_panel(shell, store, owned, "trio"))

	var refresh_left: int = store.refreshes_left()
	var refresh := Kit.chip("Refresh" if refresh_left > 0 else "New cards tomorrow", Kit.ACCENT if refresh_left > 0 else Kit.MUTED)
	var refresh_btn := Kit.card_button(refresh, func():
		if store.refresh():
			shell.refresh_with({"store": store})
		else:
			shell.toast("One free refresh a day. New cards tomorrow."), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 999, 0)
	shell.mark("arena_refresh", refresh_btn)
	root.add_child(Kit.hbox(0, [Kit.caption("Pick an opponent"), Kit.spacer(), refresh_btn]))
	var cards: Array[Dictionary] = store.offers(shell.profile)
	# Short phones get one-line rows so all three cards fit.
	var compact: bool = shell.size.y < COMPACT_HEIGHT
	for i in cards.size():
		var btn := _opponent_row(shell, store, cards[i]) if compact else _opponent_card(shell, store, cards[i])
		shell.mark("arena_card_%d" % i, btn)
		root.add_child(btn)

	return root


static func _league_panel(store) -> Control:
	var t: int = store.trophies
	var idx := Ladder.league_index(t)
	var lg: Dictionary = Ladder.LEAGUES[idx]
	var next_text := "Top league"
	var frac := 1.0
	if idx < Ladder.LEAGUES.size() - 1:
		var nxt: Dictionary = Ladder.LEAGUES[idx + 1]
		frac = float(t - lg.min) / float(nxt.min - lg.min)
		next_text = "%d to %s" % [nxt.min - t, nxt.name]
	var v := Kit.vbox(8, [
		Kit.hbox(12, [Kit.label(Ladder.league_label(t), 36, lg.color), Kit.spacer(), Glyph.make("trophy", 34, Glyph.GOLD), Kit.label(Kit.commas(t), 34)], BoxContainer.ALIGNMENT_CENTER),
		Kit.bar(frac, lg.color),
		Kit.hbox(0, [Kit.label(next_text, 22, Kit.MUTED), Kit.spacer(), Kit.label("%d W · %d L" % [store.wins, store.losses], 22, Kit.MUTED)]),
	])
	return Kit.panel(v, Kit.box(Color("17143e"), lg.color, 32, 2, 20))


## Critters that can go in a ranked trio: owned ones only, so no loaner
## (Try-a-Critter) and nothing the player hasn't got.
## Strongest first.
static func owned_critters(profile) -> Array:
	return CritterPicker.by_power(profile, BallDefs.PLAYABLE.filter(func(id): return Loaner.can_use(profile, id, "ghost_arena")))


## A hub tile: icon, name and one status line.
static func _room(shell, mark: String, glyph: String, title: String, line: String, col: Color, on_press: Callable) -> Button:
	var v := Kit.vbox(2, [Glyph.make(glyph, 34, col), Kit.label(title, 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER), Kit.label(line, 18, col, HORIZONTAL_ALIGNMENT_CENTER)])
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.get_child(0).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var b := Kit.card_button(v, on_press, Color(col, .8), Color(col, .10), 24, 8)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark(mark, b)
	return b


## Your attack trio ("trio") or Defence trio ("defence"): tap a slot to pick.
static func trio_panel(shell, store, owned: Array, which := "trio") -> Control:
	var row := Kit.hbox(12, [], BoxContainer.ALIGNMENT_CENTER)
	var slots: Array = store.slots(shell.profile, which)
	var team: Array = store.get(which)
	var prefix := "arena" if which == "trio" else "defence"
	for i in 3:
		var critter: String = team[i]
		var name := _fit(Kit.label("%d · %s" % [i + 1, BallDefs.get_def(critter).display_name], 20, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER))
		var content := Kit.vbox(0, [
			name,
			FighterTag.of_slot(slots[i], 72),
		])
		var slot := Kit.card_button(content, func():
			if owned.is_empty():
				return
			var tags := {}
			for j in 3:
				tags[team[j]] = "#%d" % (j + 1)
			var on_pick := func(id: String) -> void:
				store.set_slot(i, id, which)
				shell.refresh_with({"store": store})
			CritterPicker.open(shell, owned, {
				"title": "Slot %d" % (i + 1),
				"hint": "Already in your trio? Picking it swaps the two slots.",
				"current": critter, "tags": tags, "on_pick": on_pick,
			}), Kit.LINE, Kit.PANEL2, 28, 10)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("%s_slot_%d" % [prefix, i], slot)
		row.add_child(slot)
	var best := Kit.card_button(Kit.chip("Best trio", Kit.ACCENT), func():
		store.fill_best(owned, which)
		shell.refresh_with({"store": store}), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 999, 0)
	shell.mark("%s_best_trio" % prefix, best)
	var caption := "Your trio · fights in this order" if which == "trio" else "Defence · fights in this order"
	return Kit.vbox(10, [
		Kit.hbox(0, [Kit.caption(caption), Kit.spacer(), best], BoxContainer.ALIGNMENT_CENTER),
		row,
	])


static func _opponent_card(shell, store, offer: Dictionary) -> Button:
	var bot: Dictionary = offer.bot
	var card: Dictionary = Ladder.CARDS[offer.card]
	var col: Color = CARD_COLORS[offer.card]
	var fam: String = bot.get("family", "")
	var fam_col: Color = Color(Families.info(fam).color) if fam != "" else Kit.MUTED
	# Show which critters they bring, with tier and power, not the order they
	# come out in.
	var slots: Array = bot.lineup.slots.duplicate()
	slots.sort_custom(func(a, b): return str(a.critter) < str(b.critter))
	var icons := Kit.hbox(4)
	for s in slots:
		icons.add_child(FighterTag.of_slot(s, 68))
	var info := Kit.vbox(4, [
		Kit.hbox(8, [Kit.chip(card.name, col), Kit.chip(Families.info(fam).name if fam != "" else "Arena Ghost", fam_col)]),
		_fit(Kit.label(str(bot.name), 28)),
		Kit.hbox(6, [Kit.power(ArenaTeams.rating(bot), 22), Kit.label("·", 22, Kit.MUTED), _delta(card, 22)]),
	])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(10, [info, icons])
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	return Kit.card_button(row, _attack.bind(shell, store, offer), col, Kit.PANEL, 28, 12)


## The same opponent on one line: card chip, team name in its family colour,
## their three faces and the trophies at stake.
static func _opponent_row(shell, store, offer: Dictionary) -> Button:
	var bot: Dictionary = offer.bot
	var card: Dictionary = Ladder.CARDS[offer.card]
	var col: Color = CARD_COLORS[offer.card]
	var fam: String = bot.get("family", "")
	var name := _fit(Kit.label(str(bot.name), 22, Color(Families.info(fam).color) if fam != "" else Kit.FG))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var faces := Kit.hbox(0)
	var slots: Array = bot.lineup.slots.duplicate()
	slots.sort_custom(func(a, b): return str(a.critter) < str(b.critter))
	for s in slots:
		faces.add_child(CritterIcon.make(s.critter, int(s.get("tier", 1)), 44))
	var row := Kit.hbox(8, [Kit.chip(card.name, col, 16), name, faces, _delta(card, 18)], BoxContainer.ALIGNMENT_CENTER)
	return Kit.card_button(row, _attack.bind(shell, store, offer), col, Kit.PANEL, 22, 8)


## "+18 / -20" with the trophy cup.
static func _delta(card: Dictionary, size: int) -> Control:
	return Kit.hbox(3, [Kit.glyph("trophy", size, Glyph.GOLD), Kit.label("+%d / %d" % [card.win, card.loss], size, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)


static func _attack(shell, store, offer: Dictionary) -> void:
	store.start_attack(offer.card, offer.bot, randi_range(1, 0x7FFFFFFF), store.slots(shell.profile))
	shell.get_tree().change_scene_to_file(FIGHT_SCENE)


## A label that ends in "..." rather than widening the screen.
static func _fit(l: Label) -> Label:
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.custom_minimum_size.x = 40
	return l
