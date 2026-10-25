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
const CritterPicker := preload("res://game/ui/critter_picker.gd")
const Intro := preload("res://game/ui/intro.gd")
const ArenaTeams := preload("res://game/pvp/arena_teams.gd")
const Families := preload("res://sim/families.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")
const FamilyEdge := preload("res://game/ui/family_edge.gd")
const HomePainting := preload("res://game/ui/home_painting.gd")
const Painted := preload("res://game/ui/painted.gd")
const PlayScreen := preload("res://game/ui/screens/play_screen.gd")

const Motion := preload("res://game/ui/motion.gd")
const LevelUp := preload("res://game/ui/level_up.gd")
const FIGHT_SCENE := "res://game/ghost_arena.tscn"
const ART := "res://game/ui/versus_art/%s.png"
## Opponent cards: the painted stage's height, and the least it shrinks to
## when the phone is short.
const STAGE_H := 112.0
const STAGE_MIN := 72.0


static func build(shell, params: Dictionary) -> Control:
	var store = params.get("store", null)
	if store == null:
		store = ArenaStore.open()
	var abandoned: int = store.settle_abandoned()
	if abandoned != 0:
		shell.toast.call_deferred("Unfinished attack: counted as a loss (%d)" % abandoned)
	var owned := owned_critters(shell.profile)
	store.fit_to(owned)
	var raids: Array = store.run_raids(shell.profile)
	if not raids.is_empty():
		var held := raids.filter(func(r): return r.held).size()
		var dt := 0
		for r in raids:
			dt += int(r.delta)
		shell.toast.call_deferred("Defence held %d/%d raids (%+d)" % [held, raids.size(), dt])
	var root := Kit.vbox(10)

	var how := [
		"Trios fight in order; a winner stays in with its HP left. Their order is hidden. Your last shots become your ghost.",
		"Best trio fills in your strongest three.",
		"Opponents are themed teams with trophies near yours. Beating a team above you wins more and losing to it costs less. One free refresh a day.",
		"Every trophy you win also earns an Arena Point for the Trophy Room. Every attack earns Tokens for the Bazaar.",
		"Set your Defence trio: each day a few teams raid it. Holding wins trophies and Tokens.",
	]
	root.add_child(shell.title_row("Ghost Arena", {"info_mark": "arena_info", "info": how}))
	root.add_child(_league_panel(shell, store))
	var held_today: int = store.raids.filter(func(r): return r.held).size() if store.raid_day == ArenaStore.today() else 0
	# A new player's first Arena win opens the Trophy Room; the rest come after.
	var p = shell.profile
	if Intro.step(p) == Intro.ARENA and Intro.arena_fought:
		Intro.reach(p, Intro.TROPHY)
		Intro.moment.call_deferred(shell, Intro.TROPHY)
	var rooms := Kit.hbox(10)
	if Intro.shows(p, "trophy"):
		rooms.add_child(_room(shell, "arena_boosts", "room_trophy", "Trophy Room", Kit.commas(store.points), Kit.WARN, func(): shell.go("boosts", {"store": store})))
	if Intro.done(p):
		rooms.add_child(_room(shell, "arena_bazaar", "room_bazaar", "Bazaar", Kit.commas(store.coins), Color("ff4fd8"), func(): shell.go("bazaar", {"store": store})))
		rooms.add_child(_room(shell, "arena_defence", "room_defence", "Defence", "Held %d/%d" % [held_today, store.raids.size()] if not store.raids.is_empty() else "Set trio", Kit.GOOD, func(): shell.go("defence", {"store": store})))
	if rooms.get_child_count() > 0:
		root.add_child(rooms)
	root.add_child(trio_panel(shell, store, owned, "trio"))

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
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	var tiles: Array = []
	for i in cards.size():
		var btn := _opponent_card(shell, store, cards[i])
		shell.mark("arena_card_%d" % i, btn)
		grid.add_child(btn)
		tiles.append(btn)
	root.add_child(grid)
	# As many opponents as the phone has room for (at least two rows).
	_fit_cards(shell, root, grid, tiles)

	return root


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


## A hub tile: an arch-topped doorway painting of the room
## (game/ui/versus_art/room_*.png), its name and one status line.
static func _room(shell, mark: String, art: String, title: String, line: String, col: Color, on_press: Callable) -> Button:
	var pic := HomePainting.make(art, Vector2(.5, .5), 52.0, Vector4(0, 0, .6, .9), Kit.BG.lerp(col, .10), ART)
	pic.custom_minimum_size.y = 104
	var words := Kit.vbox(0, [Kit.label(title, 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER), Kit.label(line, 18, col, HORIZONTAL_ALIGNMENT_CENTER)])
	var v := Kit.vbox(2, [pic, words])
	var b := Kit.card_button(v, on_press, Color(col, .8), Color(col, .10), 24, 3)
	# The tile's top follows the doorway's arch.
	var st: StyleBoxFlat = b.get_theme_stylebox("normal")
	st.corner_radius_top_left = 55
	st.corner_radius_top_right = 55
	st.content_margin_bottom = 8
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark(mark, b)
	return b


## Your attack trio ("trio") or Defence trio ("defence"): tap a slot to pick the team.
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
			var on_team := func(picks: Array) -> void:
				for k in picks.size():
					store.set_slot(k, picks[k], which)
				shell.refresh_with({"store": store})
			CritterPicker.open_team(shell, owned, {
				"title": "Your trio" if which == "trio" else "Defence trio",
				"hint": "Slot 1 fights first.",
				"size": mini(3, owned.size()), "current": team, "on_confirm": on_team,
			}), Kit.LINE, Kit.PANEL2, 28, 10)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("%s_slot_%d" % [prefix, i], slot)
		row.add_child(slot)
	var best := Kit.card_button(Kit.chip("Best trio", Kit.ACCENT), func():
		store.fill_best(owned, which)
		shell.refresh_with({"store": store}), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 999, 0)
	shell.mark("%s_best_trio" % prefix, best)
	var caption := "Your trio" if which == "trio" else "Defence trio"
	return Kit.vbox(10, [
		Kit.hbox(0, [Kit.caption(caption), Kit.spacer(), best], BoxContainer.ALIGNMENT_CENTER),
		row,
	])


## One opponent: a window onto the team's family home with their three
## faces standing on its stage (and your trio's family edge on them), then the
## team name in its family colour, their trophies and power, and the trophies
## a win or a loss is worth.
static func _opponent_card(shell, store, offer: Dictionary) -> Button:
	var bot: Dictionary = offer.bot
	var fam: String = bot.get("family", "")
	var fam_col: Color = Color(Families.info(fam).color) if fam != "" else Kit.FG
	var stake := Ladder.stake(store.trophies, int(bot.get("trophies", store.trophies)))
	var slots: Array = bot.lineup.slots.duplicate()
	slots.sort_custom(func(a, b): return str(a.critter) < str(b.critter))
	var stage := Control.new()
	stage.custom_minimum_size.y = STAGE_H
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if fam != "" and ResourceLoader.exists(Painted.ART % ("families/" + fam)):
		var home := Painted.make("families/" + fam, {"focus": Vector2(200, 300), "at": Vector2(0.5, 0.62), "px": 1.4,
			"radius": Vector4(19, 19, 0, 0), "bottom_fade": 0.3})
		home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stage.add_child(home)
	var faces := Kit.hbox(2, [], BoxContainer.ALIGNMENT_CENTER)
	for s in slots:
		faces.add_child(CritterIcon.make(s.critter, int(s.get("tier", 1)), 84))
	faces.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	faces.grow_horizontal = Control.GROW_DIRECTION_BOTH
	faces.grow_vertical = Control.GROW_DIRECTION_BEGIN
	faces.offset_bottom = 4
	stage.add_child(faces)
	FamilyEdge.attach(stage, store.trio, slots.map(func(s): return str(s.critter)), 6.0, 20.0)
	var name: Control = _fit(Kit.label(str(bot.name), 24, fam_col))
	if fam != "":
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name = Kit.hbox(6, [FamilyIcon.make(fam, 26), name], BoxContainer.ALIGNMENT_CENTER)
	var line := Kit.hbox(6, [
		Kit.amount("trophy", int(bot.get("trophies", 0)), 18, Kit.MUTED, Glyph.GOLD), Kit.power(ArenaTeams.rating(bot), 18, Kit.MUTED), Kit.spacer(),
		Kit.label("%+d" % int(stake.win), 20, Kit.GOOD), Kit.label("%d" % int(stake.loss), 20, Kit.BAD),
	], BoxContainer.ALIGNMENT_CENTER)
	var words := Kit.vbox(0, [name, line])
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, 8)
	pad.add_theme_constant_override("margin_bottom", 6)
	pad.add_child(words)
	var b := Kit.card_button(Kit.vbox(2, [stage, pad]), _attack.bind(shell, store, offer), Color(fam_col, .7), Kit.PANEL, 22, 3)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.set_meta("stage", stage)
	return b


## Fits the opponent cards to the room the screen has: whole rows of two come
## off the bottom while it's too tall (keeping at least two rows), then the
## painted stages get shorter.
static func _fit_cards(shell, root: Control, grid: GridContainer, tiles: Array) -> void:
	# Text sizes settle a frame after the screen is built.
	if not shell.is_inside_tree() or tiles.is_empty():
		return
	await shell.get_tree().process_frame
	if not is_instance_valid(shell) or not is_instance_valid(root) or not is_instance_valid(shell._scroll):
		return
	var room: float = shell._scroll.size.y - 32.0 # The page's top and bottom margins.
	# Minimum sizes only update next frame, so take each hidden row off by hand.
	var need: float = root.get_combined_minimum_size().y
	var step: float = tiles[0].get_combined_minimum_size().y + grid.get_theme_constant("v_separation")
	var shown := tiles.size()
	while shown > 4 and need > room:
		var gone := 2 if shown % 2 == 0 else 1
		for k in gone:
			shown -= 1
			tiles[shown].visible = false
		need -= step
	if need > room:
		var rows := ceili(shown / 2.0)
		var stage_h := maxf(STAGE_MIN, STAGE_H - (need - room) / rows)
		for t in tiles:
			t.get_meta("stage").custom_minimum_size.y = stage_h


static func _attack(shell, store, offer: Dictionary) -> void:
	store.start_attack(offer.card, offer.bot, randi_range(1, 0x7FFFFFFF), store.slots(shell.profile))
	shell.get_tree().change_scene_to_file(FIGHT_SCENE)


## A label that ends in "..." rather than widening the screen.
static func _fit(l: Label) -> Label:
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.custom_minimum_size.x = 40
	return l
