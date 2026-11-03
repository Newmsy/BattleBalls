## One Arena mode's page (params.mode: ArenaStore.SERIES, the 3v3 Series,
## or LEAGUE, the 2v2 League; the mode last played when left out), under an
## "ARENA" eyebrow with the Arena Tokens left: your league and trophies in
## that mode (tap for the weekly chests), your team, and ten opponents:
## other players' Defence squads mixed in with seeded player-style squads.
## Picking one spends a token, starts the attack and opens its fight: the
## relay fight scene (game/ghost_arena.gd) for the Series, a 2v2 in the main
## fight screen for the League (shell.arena_duo_requested). The Trophy Room,
## Bazaar and weekly chest are on the Arena hub (versus_screen.gd).
extends RefCounted

const Matchup := preload("res://game/ui/matchup.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const ArenaGhosts := preload("res://game/pvp/arena_ghosts.gd")
const CritterPicker := preload("res://game/ui/critter_picker.gd")
const Intro := preload("res://game/ui/intro.gd")
const ArenaTeams := preload("res://game/pvp/arena_teams.gd")
const ArenaPlayers := preload("res://game/pvp/arena_players.gd")
const Families := preload("res://sim/families.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")
const FamilyEdge := preload("res://game/ui/family_edge.gd")
const HomePainting := preload("res://game/ui/home_painting.gd")
const Painted := preload("res://game/ui/painted.gd")
const PlayScreen := preload("res://game/ui/screens/play_screen.gd")
const ResultPopup := preload("res://game/ui/result_popup.gd")
const FactionRing := preload("res://game/ui/faction_ring.gd")

const Motion := preload("res://game/ui/motion.gd")
const LevelUp := preload("res://game/ui/level_up.gd")
const FIGHT_SCENE := "res://game/ghost_arena.tscn"
const ART := "res://game/ui/versus_art/%s.png"
const ROW_H := 96.0 ## About one opponent row's height, for the list's least room.


static func build(shell, params: Dictionary) -> Control:
	var store = params.get("store", null)
	if store == null:
		store = ArenaStore.open()
	store.use(str(params.get("mode", store.mode)))
	var m: Dictionary = ArenaStore.MODES[store.mode]
	var league_mode: bool = store.mode == ArenaStore.LEAGUE
	var abandoned: int = store.settle_abandoned()
	if abandoned != 0:
		shell.toast.call_deferred("Unfinished attack: counted as a loss (%d)" % abandoned)
	var owned := owned_critters(shell.profile)
	# A first visit (to either mode) starts on your strongest team.
	var first_league: bool = league_mode and store.wins + store.losses == 0 and store.raid_day == 0 and store.pending.is_empty()
	if (store.is_new or first_league) and not owned.is_empty():
		# A first visit starts on your strongest three, attack and defence.
		store.fill_best(owned, "defence")
		store.fill_best(owned)
		store.is_new = false
	store.fit_to(owned)
	var raids: Array = store.run_raids(shell.profile)
	if not raids.is_empty():
		var held := raids.filter(func(r): return r.held).size()
		var dt := 0
		for r in raids:
			dt += int(r.delta)
		shell.toast.call_deferred("Defence held %d/%d raids (%+d)" % [held, raids.size(), dt])

	store.note_league()
	store.save()
	# Real players' squads near your trophies come in the background; the list
	# redraws when they arrive (game/pvp/arena_players.gd).
	ArenaPlayers.sync(shell.backend, store, shell.profile, func():
		if is_instance_valid(shell) and shell.current == "arena" and not shell.overlay_open():
			shell.refresh_with({"store": store}))
	var root := Kit.vbox(10)

	var how := [
		"Every fight costs an Arena Token. You get one an hour and hold up to %d." % ArenaStore.TOKEN_MAX,
		"Opponents are players near your trophies. Beating one above you wins more and losing to it costs less. One free refresh a day.",
		"Both pairs fight at once. The last pair standing wins." if league_mode else "Trios fight in order; a winner stays in with its HP left. Their order is hidden. Your last shots become your ghost.",
		"Your Defence is the team other players fight. Each day a few raid it: holding wins trophies and Arena Coins.",
		"Every trophy you win also earns an Arena Point for the Trophy Room. Every fight earns Arena Coins for the Bazaar.",
		"Your best league here each week opens this mode's chest for that league when the week ends. Tap your league to see them.",
	]
	root.add_child(shell.title_row(str(m.name), {"eyebrow": "ARENA", "eyebrow_color": m.color, "info_mark": "arena_info", "info": how,
		"extra": [token_pill(shell, store)]}))
	var league := Kit.card_button(_league_panel(shell, store), func(): shell.go("arena_chests", {"store": store, "mode": store.mode}), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 32, 0)
	shell.mark("arena_league", league)
	root.add_child(league)
	# A new player's first Arena win opens the Trophy Room (on the Versus hub).
	var p = shell.profile
	# Any Arena fight on record counts too (a relaunch since, or 2v2 League
	# fights from before they counted), so no save stays stuck here.
	if Intro.step(p) == Intro.ARENA and (Intro.arena_fought or int(store.wins) + int(store.losses) > 0):
		Intro.reach(p, Intro.TROPHY)
		Intro.moment.call_deferred(shell, Intro.TROPHY)
	root.add_child(trio_panel(shell, store, owned, "trio", _defence_chip(shell, store) if Intro.done(p) else null))
	_duo_result.call_deferred(shell, store, params)

	var refresh_left: int = store.refreshes_left()
	var refresh := Kit.chip("Refresh", Kit.ACCENT if refresh_left > 0 else Kit.MUTED)
	var refresh_btn := Kit.card_button(refresh, func():
		if store.refresh():
			shell.refresh_with({"store": store})
		else:
			shell.toast("Refresh used. New teams tomorrow."), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 999, 0)
	shell.mark("arena_refresh", refresh_btn)
	root.add_child(Kit.hbox(0, [Kit.caption("Opponents"), Kit.spacer(), refresh_btn]))
	var cards: Array[Dictionary] = store.offers(shell.profile)
	var list := Kit.vbox(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in cards.size():
		var btn := _opponent_row(shell, store, cards[i])
		shell.mark("arena_card_%d" % i, btn)
		list.add_child(btn)
	# The list is the one part of the screen that scrolls: it takes whatever
	# height is left, and always shows at least three rows.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = ROW_H * 3 + 20
	scroll.add_child(list)
	shell.mark("arena_list", scroll)
	root.add_child(scroll)
	return root


## The Defence trio's room, as a chip beside Best trio: how it held today.
static func _defence_chip(shell, store) -> Control:
	var held: int = store.raids.filter(func(r): return r.held).size() if store.raid_day == ArenaStore.today() else 0
	var text := "Defence %d/%d" % [held, store.raids.size()] if not store.raids.is_empty() else "Defence"
	var b := Kit.card_button(Kit.chip(text, Kit.GOOD), func(): shell.go("defence", {"store": store, "mode": store.mode}), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 999, 0)
	shell.mark("arena_defence", b)
	return b


static func _league_panel(shell, store) -> Control:
	var t: int = store.trophies
	var idx := Ladder.league_index(t)
	var lg: Dictionary = Ladder.LEAGUES[idx]
	var next_text := "Top league"
	var frac := 1.0
	if idx < Ladder.LEAGUES.size() - 1:
		var nxt: Dictionary = Ladder.LEAGUES[idx + 1]
		frac = float(t - lg.min) / float(nxt.min - lg.min)
		next_text = "%d to %s" % [nxt.min - t, nxt.name]
	var count := Kit.amount("trophy", t, 30, Kit.FG, Glyph.GOLD)
	var bar := Kit.bar(frac, lg.color)
	var head := Kit.hbox(12, [Kit.label(Ladder.league_label(t), 36, lg.color), count], BoxContainer.ALIGNMENT_BEGIN)
	_trophy_change(shell, t, idx, head, count, bar)
	var v := Kit.vbox(8, [
		head,
		bar,
		Kit.hbox(0, [Kit.label(next_text, 20, Kit.MUTED), Kit.spacer(), Kit.label("%d W · %d L" % [store.wins, store.losses], 20, Kit.MUTED)]),
	])
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_stretch_ratio = 1.5
	PlayScreen._on_art(v)
	# The words on the left, the league's crest on its plinth on the right
	# (game/ui/versus_art/league_<id>.png).
	var crest_room := Control.new()
	crest_room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crest_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var words := Kit.hbox(8, [v, crest_room])
	var stack := MarginContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(HomePainting.make("league_" + str(lg.id), Vector2(.85, .62), 29.0, Vector4(0, 0, 1, 0), Kit.BG, ART))
	stack.add_child(PlayScreen._padded(words, 16, 16))
	var st := Kit.box(Kit.BG, lg.color, 32, 3, 3)
	return Kit.panel(stack, st)


## Back from a fight: the trophy count ticks from what you last saw to now,
## with a +/- chip, and reaching a new league gets its own moment.
static func _trophy_change(shell, t: int, league: int, head: HBoxContainer, count: HBoxContainer, bar: ProgressBar) -> void:
	var was := ArenaStore.seen_trophies
	var was_league := ArenaStore.seen_league
	ArenaStore.seen_trophies = t
	ArenaStore.seen_league = league
	if was < 0 or was == t:
		return
	var num: Label = count.get_child(1)
	Motion.count(num, was, t, .7, Kit.commas)
	var gain := t - was
	var chip := Kit.chip(("+%d" if gain > 0 else "%d") % gain, Kit.GOOD if gain > 0 else Kit.BAD, 22)
	head.add_child(chip)
	Motion.pop(chip, .4, .3, .1)
	var tw := chip.create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(chip, "modulate:a", 0.0, .3)
	if league == was_league:
		var to := bar.value
		bar.value = clampf(bar.value - float(gain) / maxf(1.0, float(Ladder.LEAGUES[mini(league + 1, Ladder.LEAGUES.size() - 1)].min - Ladder.LEAGUES[league].min)), 0.0, 1.0)
		bar.create_tween().tween_property(bar, "value", to, .7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	elif league > was_league:
		var lg: Dictionary = Ladder.LEAGUES[league]
		LevelUp.celebrate(shell._fx, {"caption": "NEW LEAGUE", "head": str(lg.name).to_upper() + "!", "color": lg.color}, shell.sfx)


## Critters that can go in a ranked trio: owned ones only.
## Strongest first.
static func owned_critters(profile) -> Array:
	return CritterPicker.by_power(profile, BallDefs.PLAYABLE.filter(func(id): return profile.owns(id)))


## Your attack trio ("trio") or Defence trio ("defence"): tap a slot to pick the team.
## `extra` sits beside Best trio (the Arena's Defence chip).
static func trio_panel(shell, store, owned: Array, which := "trio", extra: Control = null) -> Control:
	var row := Kit.hbox(12, [], BoxContainer.ALIGNMENT_CENTER)
	var slots: Array = store.slots(shell.profile, which)
	var team: Array = store.get(which)
	var prefix := "arena" if which == "trio" else "defence"
	var n: int = store.size()
	var pair := n == 2
	var team_name: String = ArenaStore.MODES[store.mode].team if which == "trio" else ("Defence pair" if pair else "Defence trio")
	for i in n:
		var critter: String = team[i]
		var text: String = BallDefs.get_def(critter).display_name if pair else "%d · %s" % [i + 1, BallDefs.get_def(critter).display_name]
		var name := _fit(Kit.label(text, 20, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER))
		var content := Kit.vbox(0, [
			name,
			FighterTag.of_slot(slots[i], 72),
		])
		var slot := Kit.card_button(content, func():
			if owned.is_empty():
				return
			var on_team := func(picks: Array) -> void:
				for k in picks.size():
					store.set_slot(k, picks[k], which)
				shell.refresh_with({"store": store})
			CritterPicker.open_team(shell, owned, {
				"title": team_name,
				"hint": "Both fight at once." if pair else "Slot 1 fights first.",
				"size": mini(n, owned.size()), "current": team, "on_confirm": on_team,
			}), Kit.LINE, Kit.PANEL2, 28, 10)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("%s_slot_%d" % [prefix, i], slot)
		row.add_child(slot)
	var best := Kit.card_button(Kit.chip("Best pair" if pair else "Best trio", Kit.ACCENT), func():
		store.fill_best(owned, which)
		shell.refresh_with({"store": store}), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 999, 0)
	shell.mark("%s_best_trio" % prefix, best)
	var head := Kit.hbox(0, [Kit.caption(team_name), Kit.spacer()], BoxContainer.ALIGNMENT_CENTER)
	if extra != null:
		head.add_child(extra)
	head.add_child(best)
	return Kit.vbox(10, [head, row])


## One opponent: team name in its family colour, their trophies and power,
## their three faces standing in a strip of their family's home painting
## (game/ui/art/families), and the trophies a win or a loss is worth.
static func _opponent_row(shell, store, offer: Dictionary) -> Button:
	var bot: Dictionary = offer.bot
	var fam: String = bot.get("family", "")
	var fam_col: Color = Color(Families.info(fam).color) if fam != "" else Kit.FG
	var stake := Ladder.stake(store.trophies, int(bot.get("trophies", store.trophies)))
	var name: Control = _fit(Kit.label(str(bot.name), 24, Kit.FG))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if bot.has("level"):
		name = Kit.hbox(8, [level_badge(int(bot.level)), name], BoxContainer.ALIGNMENT_CENTER)
	var info := Kit.vbox(2, [
		name,
		Kit.hbox(6, [Kit.amount("trophy", int(bot.get("trophies", 0)), 20, Kit.MUTED, Glyph.GOLD), Kit.power(ArenaTeams.rating(bot), 20, Kit.MUTED)]),
	])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var faces := Kit.hbox(0)
	var slots: Array = bot.lineup.slots.duplicate()
	slots.sort_custom(func(a, b): return str(a.critter) < str(b.critter))
	for s in slots:
		faces.add_child(CritterIcon.make(s.critter, int(s.get("tier", 1)), 50))
	var stakes := Kit.vbox(0, [
		Kit.label("%+d" % int(stake.win), 22, Kit.GOOD, HORIZONTAL_ALIGNMENT_RIGHT),
		Kit.label("%d" % int(stake.loss), 20, Kit.BAD, HORIZONTAL_ALIGNMENT_RIGHT),
	])
	stakes.custom_minimum_size.x = 44
	# Your trio's family edge on theirs, as a badge over their faces.
	var edge := FamilyEdge.team(store.trio, slots.map(func(s): return str(s.critter)))
	var mark := FamilyEdge.badge(edge, 20)
	mark.custom_minimum_size.y = 20 # Holds the line when even, so faces line up row to row.
	var foe_side := Kit.vbox(0, [mark, faces])
	var odds := Matchup.chip(Matchup.rate(store.power(shell.profile), ArenaTeams.rating(bot), edge), 16)
	odds.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := Kit.hbox(8, [info, odds, foe_side, Kit.glyph("trophy", 22, Glyph.GOLD), stakes], BoxContainer.ALIGNMENT_CENTER)
	var b := Kit.card_button(row, _attack.bind(shell, store, offer), Color(fam_col, .6), Kit.PANEL, 22, 10)
	if fam != "" and ResourceLoader.exists(Painted.ART % ("families/" + fam)):
		# The stage sits behind the faces; the words' side is shaded so they read.
		var home := Painted.make("families/" + fam, {"focus": Vector2(200, 300), "at": Vector2(0.68, 0.72), "px": 1.0,
			"radius": 19.0, "left_dark": 0.85, "right_dark": 0.35})
		home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left", "top"]:
			home.set("offset_" + side, 3)
		for side in ["right", "bottom"]:
			home.set("offset_" + side, -3)
		b.add_child(home)
		b.move_child(home, 0)
	return b


static func _attack(shell, store, offer: Dictionary) -> void:
	if not store.spend_token():
		shell.toast(out_of_tokens(store))
		return
	start_fight(shell, store, offer)


## Starts the attack on `offer` (a token already spent) and opens its fight.
static func start_fight(shell, store, offer: Dictionary) -> void:
	store.start_attack(offer.card, offer.bot, randi_range(1, 0x7FFFFFFF), store.slots(shell.profile))
	if store.mode == ArenaStore.LEAGUE:
		shell.arena_duo_requested.emit()
	else:
		shell.get_tree().change_scene_to_file(FIGHT_SCENE)


## What a tap says with no tokens left.
static func out_of_tokens(store) -> String:
	return "Out of Arena Tokens. Next one in " + ArenaStore.clock_text(store.next_token_in())


## Home's Fight: straight into a fight in the mode last played, against the
## opponent nearest your trophies, for a token. False (with a toast) when
## out of tokens or there's no team to fight with.
static func fight_now(shell) -> bool:
	var store = ArenaStore.open()
	var owned := owned_critters(shell.profile)
	if owned.size() < store.size():
		shell.go("arena", {"store": store})
		return false
	if store.is_new:
		store.fill_best(owned, "defence")
		store.fill_best(owned)
		store.is_new = false
	store.fit_to(owned)
	var offers: Array = store.offers(shell.profile)
	if offers.is_empty():
		return false
	var t: int = store.trophies
	offers.sort_custom(func(a, b): return absi(int(a.bot.trophies) - t) < absi(int(b.bot.trophies) - t))
	if not store.spend_token():
		shell.toast(out_of_tokens(store))
		return false
	start_fight(shell, store, offers[0])
	return true


## The Arena Tokens you hold, as icon + "7/10"; a tap says when the next one comes.
static func token_pill(shell, store) -> Control:
	var n: int = store.tokens_now()
	var row := Kit.hbox(6, [Kit.glyph("token", 30, Color.WHITE), Kit.label("%d/%d" % [n, ArenaStore.TOKEN_MAX], 24, Kit.FG if n > 0 else Kit.BAD)], BoxContainer.ALIGNMENT_CENTER)
	var b := Kit.card_button(row, func():
		var secs: int = store.next_token_in()
		shell.toast("Arena Tokens full" if secs == 0 else "Next Arena Token in " + ArenaStore.clock_text(secs)), Kit.LINE, Kit.PANEL, 999, 6)
	shell.mark("arena_tokens", b)
	return b


## An account level as a small badge, as players' rows show it.
static func level_badge(level: int) -> Control:
	var l := Kit.label(str(level), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	var p := Kit.panel(l, Kit.box(Kit.ACCENT, Kit.ACCENT.lightened(.3), 10, 1, 6))
	p.custom_minimum_size = Vector2(40, 0)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


## Back from a 2v2 League fight (main.gd passes params.duo): its result popup.
## Shows once: a refresh doesn't bring it back.
static func _duo_result(shell, store, params: Dictionary) -> void:
	if not params.has("duo") or not is_instance_valid(shell):
		return
	var d: Dictionary = params.duo
	params.erase("duo")
	var delta := int(d.get("delta", 0))
	var col: Color = Kit.GOOD if delta > 0 else (Kit.BAD if delta < 0 else Kit.MUTED)
	var head := Kit.hbox(12, [Kit.glyph("trophy", 64, Color("ffc23d")), Kit.label("%+d" % delta, 72, col)], BoxContainer.ALIGNMENT_CENTER)
	var rewards := Kit.hbox(28, [], BoxContainer.ALIGNMENT_CENTER)
	if int(d.get("coins", 0)) > 0:
		rewards.add_child(Kit.hbox(6, [Kit.glyph("arena_coin", 34, Color.WHITE), Kit.label("+%d" % int(d.coins), 30)], BoxContainer.ALIGNMENT_CENTER))
	if delta > 0:
		rewards.add_child(Kit.hbox(6, [Kit.glyph("points", 30, Kit.WARN), Kit.label("+%d" % delta, 26, Kit.WARN)], BoxContainer.ALIGNMENT_CENTER))
	var body: Array = [head, Kit.label(Ladder.league_label(store.trophies), 26, Ladder.league(store.trophies).color, HORIZONTAL_ALIGNMENT_CENTER)]
	if rewards.get_child_count() > 0:
		body.append(rewards)
	var rings = FactionRing.rows(shell.profile.take_faction_gains(), shell.sfx, .45, FactionRing.spend_in(shell))
	if rings != null:
		body.append(rings)
	var next := Kit.button("Next fight", func():
		shell.close_overlay()
		fight_now(shell), "go", 26, 84)
	var back := Kit.button("Back", shell.close_overlay, "ghost", 26, 84)
	shell.mark("arena_next", next)
	shell.mark("arena_back", back)
	next.size_flags_stretch_ratio = 1.5
	var outcome: int = ResultPopup.outcome_of(int(d.get("winner", 0)))
	var popup := ResultPopup.content("2v2 League · vs " + str(d.get("name", "?")), outcome, body, [back, next])
	shell.sheet(popup)


## A label that ends in "..." rather than widening the screen.
static func _fit(l: Label) -> Label:
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.custom_minimum_size.x = 40
	return l
