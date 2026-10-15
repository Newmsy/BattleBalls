## Ghost Arena (design/pvp.md): your league and trophies, your trio, and the
## three opponent cards. Picking a card starts the attack and opens the
## relay fight scene (game/ghost_arena.gd).
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const ArenaGhosts := preload("res://game/pvp/arena_ghosts.gd")

const CARD_COLORS := {"easier": Kit.GOOD, "even": Kit.ACCENT, "harder": Kit.WARN}
const FIGHT_SCENE := "res://game/ghost_arena.tscn"


static func build(shell, params: Dictionary) -> Control:
	var store = params.get("store", null)
	if store == null:
		store = ArenaStore.open()
	var abandoned: int = store.settle_abandoned()
	if abandoned != 0:
		shell.toast.call_deferred("Your last attack wasn't finished, so it counted as a loss (%d)." % abandoned)
	var root := Kit.vbox(26)

	var back := Kit.card_button(Glyph.make("back", 34, Kit.FG), shell.back, Kit.LINE, Kit.PANEL, 999, 14)
	shell.mark("back", back)
	root.add_child(Kit.hbox(18, [back, Kit.label("Ghost Arena", 40)]))
	root.add_child(_league_panel(store))
	root.add_child(_trio_panel(shell, store, params))

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

	root.add_child(Kit.label("Arena Ghosts are practice opponents run by the game. Other players' trios join once online play opens.", 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	if not store.history.is_empty():
		var lines := Kit.vbox(6, [Kit.caption("Recent")])
		for h in store.history.slice(0, 5):
			lines.add_child(Kit.hbox(10, [
				Kit.label("WIN" if h.won else "LOSS", 22, Kit.GOOD if h.won else Kit.BAD),
				Kit.label(str(h.name), 22),
				Kit.spacer(),
				Kit.label("%+d" % int(h.delta), 22, Kit.MUTED),
			]))
		root.add_child(Kit.panel(lines, Kit.box(Kit.PANEL, Kit.LINE, 32, 2, 22)))
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
	var v := Kit.vbox(10, [
		Kit.caption("League", lg.color),
		Kit.hbox(12, [Kit.label(Ladder.league_label(t), 44, lg.color), Kit.spacer(), Glyph.make("stars", 34), Kit.label(Kit.commas(t), 40)]),
		Kit.bar(frac, lg.color),
		Kit.hbox(0, [Kit.label(next_text, 22, Kit.MUTED), Kit.spacer(), Kit.label("%d W · %d L" % [store.wins, store.losses], 22, Kit.MUTED)]),
	])
	return Kit.panel(v, Kit.box(Color("17143e"), lg.color, 40, 2, 28))


static func _trio_panel(shell, store, params: Dictionary) -> Control:
	var row := Kit.hbox(12, [], BoxContainer.ALIGNMENT_CENTER)
	for i in 3:
		var critter: String = store.trio[i]
		var content := Kit.vbox(4, [
			Kit.label(str(i + 1), 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER),
			CritterIcon.make(critter, 1, 120),
			Kit.label(BallDefs.get_def(critter).display_name, 20, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
		])
		var slot := Kit.card_button(content, func():
			var at := BallDefs.PLAYABLE.find(critter)
			store.set_slot(i, BallDefs.PLAYABLE[(at + 1) % BallDefs.PLAYABLE.size()])
			shell.refresh_with({"store": store}), Kit.LINE, Kit.PANEL2, 28, 10)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("arena_slot_%d" % i, slot)
		row.add_child(slot)
	return Kit.vbox(12, [
		Kit.hbox(0, [Kit.caption("Your trio"), Kit.spacer(), Kit.label("Tap to swap", 20, Kit.MUTED)]),
		row,
		Kit.label("They fight in this order. Each ball's last shot is saved for your ghost.", 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
	])


static func _opponent_card(shell, store, offer: Dictionary) -> Button:
	var bot: Dictionary = offer.bot
	var card: Dictionary = Ladder.CARDS[offer.card]
	var col: Color = CARD_COLORS[offer.card]
	# Show which critters they bring, not the order they come out in.
	var critters: Array = ArenaGhosts.critters(bot.lineup)
	critters.sort()
	var icons := Kit.hbox(0)
	for c in critters:
		icons.add_child(CritterIcon.make(c, 1, 76))
	var info := Kit.vbox(4, [
		Kit.hbox(8, [Kit.chip(card.name, col), Kit.chip("Arena Ghost", Kit.MUTED)]),
		Kit.label(str(bot.name), 30),
		Kit.hbox(6, [Glyph.make("stars", 22), Kit.label(Kit.commas(bot.trophies), 22, Kit.MUTED), Kit.label("·  +%d / %d" % [card.win, card.loss], 22, Kit.MUTED)]),
	])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(10, [info, icons])
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	return Kit.card_button(row, func():
		store.start_attack(offer.card, bot.id, randi_range(1, 0x7FFFFFFF))
		shell.get_tree().change_scene_to_file(FIGHT_SCENE), col, Kit.PANEL, 32, 18)
