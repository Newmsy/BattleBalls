## Ghost Arena (design/pvp.md): your league and trophies, your trio, and the
## three opponent cards. Picking a card starts the attack and opens the
## relay fight scene (game/ghost_arena.gd).
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const ArenaGhosts := preload("res://game/pvp/arena_ghosts.gd")
const Loaner := preload("res://game/loaner.gd")

const CARD_COLORS := {"easier": Kit.GOOD, "even": Kit.ACCENT, "harder": Kit.WARN}
const FIGHT_SCENE := "res://game/ghost_arena.tscn"


static func build(shell, params: Dictionary) -> Control:
	var store = params.get("store", null)
	if store == null:
		store = ArenaStore.open()
	var abandoned: int = store.settle_abandoned()
	if abandoned != 0:
		shell.toast.call_deferred("Your last attack wasn't finished, so it counted as a loss (%d)." % abandoned)
	var owned := owned_critters(shell.profile)
	store.fit_to(owned)
	var root := Kit.vbox(12)

	var back: Control = shell.back_button("back")
	var how := [
		"Your trio fights theirs in order. A winner stays in with the HP it has left. Each ball's last shot is saved for your ghost.",
		"Tap a trio slot to swap in another critter you own.",
		"Easier cards risk fewer trophies, harder ones win more. One free refresh a day.",
		"Arena Ghosts are practice opponents run by the game. Other players' trios join once online play opens.",
	]
	for h in store.history.slice(0, 5):
		how.append("%s vs %s (%+d)" % ["Won" if h.won else "Lost", str(h.name), int(h.delta)])
	how.insert(3, "Every trophy you win also earns an Arena Point. Spend them in Boosts on your families' stats.")
	var info: Control = shell.info_button("How the Arena works", how, "arena_info")
	var boosts := Kit.card_button(Kit.hbox(6, [Kit.label("Boosts", 22, Kit.WARN), Kit.label(Kit.commas(store.points), 22)], BoxContainer.ALIGNMENT_CENTER),
		func(): shell.go("boosts", {"store": store}), Kit.WARN, Kit.PANEL, 999, 10)
	boosts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shell.mark("arena_boosts", boosts)
	root.add_child(Kit.hbox(14, [back, Kit.label("Ghost Arena", 40), Kit.spacer(), boosts, info], BoxContainer.ALIGNMENT_CENTER))
	root.add_child(_league_panel(store))
	root.add_child(_trio_panel(shell, store, owned))

	var refresh_left: int = store.refreshes_left()
	var refresh := Kit.chip("Refresh" if refresh_left > 0 else "New cards tomorrow", Kit.ACCENT if refresh_left > 0 else Kit.MUTED)
	var refresh_btn := Kit.card_button(refresh, func():
		if store.refresh():
			shell.refresh_with({"store": store})
		else:
			shell.toast("One free refresh a day. New cards tomorrow."), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 999, 0)
	shell.mark("arena_refresh", refresh_btn)
	root.add_child(Kit.hbox(0, [Kit.caption("Pick an opponent"), Kit.spacer(), refresh_btn]))
	var cards: Array[Dictionary] = store.offers()
	for i in cards.size():
		var btn := _opponent_card(shell, store, cards[i])
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
		Kit.hbox(12, [Kit.label(Ladder.league_label(t), 36, lg.color), Kit.spacer(), Glyph.make("stars", 30), Kit.label(Kit.commas(t), 34)], BoxContainer.ALIGNMENT_CENTER),
		Kit.bar(frac, lg.color),
		Kit.hbox(0, [Kit.label(next_text, 22, Kit.MUTED), Kit.spacer(), Kit.label("%d W · %d L" % [store.wins, store.losses], 22, Kit.MUTED)]),
	])
	return Kit.panel(v, Kit.box(Color("17143e"), lg.color, 32, 2, 20))


## Critters that can go in a ranked trio: owned ones only, so no loaner
## (Try-a-Critter) and nothing the player hasn't got.
static func owned_critters(profile) -> Array:
	return BallDefs.PLAYABLE.filter(func(id): return Loaner.can_use(profile, id, "ghost_arena"))


static func _trio_panel(shell, store, owned: Array) -> Control:
	var row := Kit.hbox(12, [], BoxContainer.ALIGNMENT_CENTER)
	var slots: Array = store.slots(shell.profile)
	for i in 3:
		var critter: String = store.trio[i]
		var name := _fit(Kit.label("%d · %s" % [i + 1, BallDefs.get_def(critter).display_name], 20, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER))
		var content := Kit.vbox(0, [
			name,
			FighterTag.of_slot(slots[i], 72),
		])
		var slot := Kit.card_button(content, func():
			if owned.is_empty():
				return
			store.set_slot(i, owned[(owned.find(critter) + 1) % owned.size()])
			shell.refresh_with({"store": store}), Kit.LINE, Kit.PANEL2, 28, 10)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("arena_slot_%d" % i, slot)
		row.add_child(slot)
	return Kit.vbox(10, [
		Kit.hbox(0, [Kit.caption("Your trio · fights in this order"), Kit.spacer(), Kit.label("Tap to swap", 20, Kit.MUTED)]),
		row,
	])


static func _opponent_card(shell, store, offer: Dictionary) -> Button:
	var bot: Dictionary = offer.bot
	var card: Dictionary = Ladder.CARDS[offer.card]
	var col: Color = CARD_COLORS[offer.card]
	# Show which critters they bring, with tier and power, not the order they
	# come out in.
	var slots: Array = bot.lineup.slots.duplicate()
	slots.sort_custom(func(a, b): return str(a.critter) < str(b.critter))
	var icons := Kit.hbox(4)
	for s in slots:
		icons.add_child(FighterTag.of_slot(s, 68))
	var info := Kit.vbox(4, [
		Kit.hbox(8, [Kit.chip(card.name, col), Kit.chip("Arena Ghost", Kit.MUTED)]),
		_fit(Kit.label(str(bot.name), 28)),
		Kit.hbox(6, [Glyph.make("stars", 22), Kit.label(Kit.commas(bot.trophies), 22, Kit.MUTED), Kit.label("·  +%d / %d" % [card.win, card.loss], 22, Kit.MUTED)]),
	])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(10, [info, icons])
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	return Kit.card_button(row, func():
		store.start_attack(offer.card, bot.id, randi_range(1, 0x7FFFFFFF), store.slots(shell.profile))
		shell.get_tree().change_scene_to_file(FIGHT_SCENE), col, Kit.PANEL, 28, 14)


## A label that ends in "..." rather than widening the screen.
static func _fit(l: Label) -> Label:
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.custom_minimum_size.x = 40
	return l
