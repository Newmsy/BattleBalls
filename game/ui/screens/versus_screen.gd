## The Arena hub (the "versus" screen), opened from the Arena door on Home:
## the Arena Tokens you hold, the two modes as painted doors (the 3v3
## Series and the 2v2 League, each with its league and trophies), then the
## rooms they share (Trophy Room, Bazaar, weekly chest), and Quick fight
## with your fighter while live fights are on. Paintings are
## game/ui/versus_art (from tools/event_art/scenes/versus_*.mjs); the cards
## share the room so nothing scrolls.
## Critter Plunge has its own door on Home, so it isn't here too. Friends are
## behind the level badge (the profile screen).
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Idle := preload("res://game/ui/idle.gd")
const PlayScreen := preload("res://game/ui/screens/play_screen.gd")
const HomePainting := preload("res://game/ui/home_painting.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const Dev := preload("res://game/dev.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const Intro := preload("res://game/ui/intro.gd")
const ArenaChest := preload("res://game/pvp/arena_chest.gd")
const ChestArt := preload("res://game/ui/chest_art.gd")
const ArenaScreen := preload("res://game/ui/screens/arena_screen.gd")
const ArenaChestsScreen := preload("res://game/ui/screens/arena_chests_screen.gd")

const ART := "res://game/ui/versus_art/%s.png"


static func build(shell, _params: Dictionary) -> Control:
	var root := Kit.vbox(16)
	var quick_on := Dev.quick_fight_shown()
	var p = shell.profile
	var store = ArenaStore.open()
	var info := ["Every Arena fight costs an Arena Token. You get one an hour and hold up to %d." % ArenaStore.TOKEN_MAX,
		"3v3 Series: three critters each, one at a time. A winner stays in with its HP left.",
		"2v2 League: two critters each, all on the field at once.",
		"Each mode has its own trophies, league and weekly chest: your best league each week opens that league's chest."]
	if quick_on:
		info.append("Quick fight: your fighter against a live foe. Nothing at stake.")
	info.append_array(["Trophy Room: spend Arena Points on stat boosts for each family, in both Arena modes.",
		"Bazaar: spend Arena Coins on gear, eggs and energy. New stock every day."])
	root.add_child(shell.title_row("Arena", {"back_mark": "versus_back", "info_mark": "versus_info", "info": info,
		"extra": [ArenaScreen.token_pill(shell, store)]}))
	var col := Kit.vbox(12)
	var doors: Array = [mode_door(shell, store, ArenaStore.SERIES)]
	if Intro.done(p):
		doors.append(mode_door(shell, store, ArenaStore.LEAGUE))
	for d in doors:
		d.size_flags_vertical = Control.SIZE_EXPAND_FILL
		d.size_flags_stretch_ratio = 1.4
		col.add_child(d)
	var rooms: Array = []
	if Intro.shows(p, "trophy"):
		rooms.append(["arena_boosts", "room_trophy", "Trophy Room", store.points, "points", Kit.WARN, func(): shell.go("boosts", {"store": store})])
	if Intro.done(p):
		rooms.append(["arena_bazaar", "room_bazaar", "Bazaar", store.coins, "arena_coin", Color("ff4fd8"), func(): shell.go("bazaar", {"store": store})])
	if rooms.size() == 2:
		# Side by side, so the modes get the room.
		var pair := Kit.hbox(12)
		for r in rooms:
			pair.add_child(room_tile(shell, r[0], _room_art(r[1], r[5]), r[2], Kit.amount(r[4], r[3], 22, Kit.FG, r[5]), r[5], r[6]))
		pair.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(pair)
	else:
		for r in rooms:
			var row := room_row(shell, r[0], _room_art(r[1], r[5]), r[2], Kit.commas(r[3]) + " Arena Points", "Stat boosts for each family", r[5], r[6])
			row.size_flags_vertical = Control.SIZE_EXPAND_FILL
			col.add_child(row)
	if Intro.done(p):
		# Each mode's own weekly chest, side by side.
		var was: String = store.mode
		var chests := Kit.hbox(12, [chest_tile(shell, store, ArenaStore.SERIES), chest_tile(shell, store, ArenaStore.LEAGUE)])
		store.use(was)
		chests.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(chests)
	if quick_on:
		var quick := PlayScreen.quick_fight_card(shell, band("vs_quick", "Quick fight", "Live foe · just for fun", Color("cfc8ff")))
		quick.size_flags_vertical = Control.SIZE_EXPAND_FILL
		quick.size_flags_stretch_ratio = 1.8
		col.add_child(quick)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(col)
	return root


## One Arena mode as a painted door: its name, league and trophies, and a ›.
static func mode_door(shell, store, m: String) -> Button:
	var d: Dictionary = ArenaStore.MODES[m]
	var t: int = store.trophies_in(m)
	var b := painted(shell, "hub_" + m, str(d.art), Vector2(.72, .62), str(d.name),
		"%s · %s" % [Ladder.league_label(t), Kit.commas(t)], d.color, func(): shell.go("arena", {"store": store, "mode": m}), true)
	b.custom_minimum_size.y = 170
	return b


## A room as a half-width tile: its doorway painting over its name and
## what you hold to spend there.
static func room_tile(shell, mark: String, art: Control, title: String, status: Control, col: Color, on_press: Callable) -> Button:
	art.custom_minimum_size = Vector2(0, 70)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name := _fit(Kit.label(title, 26))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.custom_minimum_size.x = 60
	var v := Kit.vbox(4, [art, Kit.hbox(8, [name, status], BoxContainer.ALIGNMENT_CENTER)])
	var b := Kit.card_button(v, on_press, Color(col, .7), Color(col, .08), 24, 8)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark(mark, b)
	return b


## A room's doorway painting, framed for the left of its row.
static func _room_art(art: String, col: Color) -> Control:
	return HomePainting.make(art, Vector2(.5, .55), 22.0, Vector4(0, 0, 0, 0), Kit.BG.lerp(col, .10), ART)


## One room as a wide row: its painting on the left, then its name, what you
## hold to spend there and what it's for.
static func room_row(shell, mark: String, art: Control, title: String, status: String, line: String, col: Color, on_press: Callable, dot := false) -> Button:
	art.custom_minimum_size = Vector2(200, 112)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var head := _fit(Kit.label(title, 28))
	var words := Kit.vbox(2, [head, _fit(Kit.label(status, 21, col)), _fit(Kit.label(line, 18, Kit.MUTED))])
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(16, [art, words, Kit.label("›", 40, col)], BoxContainer.ALIGNMENT_CENTER)
	var b := Kit.card_button(row, on_press, Color(col, .7), Color(col, .08), 24, 6)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if dot:
		b.add_child(PlayScreen.red_dot())
	shell.mark(mark, b)
	return b


## One mode's weekly chest as a half-width tile: the chest its league
## earns (in the mode's look), and Open when last week's is waiting, else
## the time left this week. Opens that mode's chests.
static func chest_tile(shell, store, m: String) -> Button:
	store.use(m)
	var ready: bool = store.chest_ready()
	var league: int = int(store.chest.league) if ready else maxi(store.week_best, Ladder.league_index(store.trophies))
	var look := ArenaChest.look(league, m)
	var col: Color = look.color
	var chest := ArenaChestsScreen.chest_art(look, 96.0, m)
	if ready:
		Idle.breathe(chest, .1, .6) # Last week's chest is waiting to be opened.
	var centre := CenterContainer.new()
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(chest)
	var line := Kit.label("Open now!" if ready else ArenaChest.time_text(ArenaChest.seconds_left()), 20, Kit.GOOD if ready else Kit.MUTED)
	var name := _fit(Kit.label(look.name, 22, col))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.custom_minimum_size.x = 60
	var v := Kit.vbox(2, [centre, name, line])
	var b := Kit.card_button(v, func(): shell.go("arena_chests", {"store": store, "mode": m}), Color(col, .7), Color(col, .08), 24, 8)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if ready:
		b.add_child(PlayScreen.red_dot())
	shell.mark("arena_chest_" + m, b)
	return b


## A card that is all painting, its title and status line over the top-left.
static func painted(shell, mark: String, art: String, focus: Vector2, title: String, status: String, accent: Color, on_press: Callable, chevron := false) -> Button:
	var stack := MarginContainer.new()
	stack.add_child(HomePainting.make(art, focus, 25.0, Vector4(.45, .55, 1.0, 0.0), Kit.BG, ART))
	var words := Kit.vbox(0, [_fit(Kit.label(title, 32)), _fit(Kit.label(status, 20, accent))])
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := Kit.hbox(8, [words], BoxContainer.ALIGNMENT_BEGIN)
	if chevron:
		head.add_child(Kit.label("›", 44, Kit.FG))
	head.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	PlayScreen._on_art(head)
	stack.add_child(PlayScreen._padded(head, 12, 0))
	var b := Kit.card_button(stack, on_press, accent.darkened(.45), accent.darkened(.84), 28, 3)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark(mark, b)
	return b


## A band of painting with a title on it, for the top of a card.
static func band(art: String, title: String, status: String, accent: Color) -> Control:
	var m := MarginContainer.new()
	m.custom_minimum_size.y = 96
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	m.add_child(HomePainting.make(art, Vector2(.75, .5), 34.0, Vector4(.45, .55, .7, 1.0), Kit.PANEL, ART))
	var words := Kit.vbox(0, [Kit.label(title, 32), Kit.label(status, 20, accent)])
	words.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	PlayScreen._on_art(words)
	m.add_child(PlayScreen._padded(words, 12, 0))
	return m


static func _fit(l: Label) -> Label:
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	return l
