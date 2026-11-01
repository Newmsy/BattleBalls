## The Versus hub, opened from the Arena door's › on Play: Ghost Arena on its
## painting, then its rooms (Trophy Room, Bazaar and the weekly chest) as wide
## rows, doorway painting beside what each is for, and Quick fight with your
## fighter (while live fights are on). Paintings are game/ui/versus_art (from
## tools/event_art/scenes/versus_*.mjs); the cards share the room so nothing
## scrolls. A new PvP mode adds one card.
## Critter Plunge has its own door on Home, so it isn't here too. Friends are
## behind the level badge (the profile screen).
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const PlayScreen := preload("res://game/ui/screens/play_screen.gd")
const HomePainting := preload("res://game/ui/home_painting.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const Dev := preload("res://game/dev.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const Intro := preload("res://game/ui/intro.gd")
const ArenaChest := preload("res://game/pvp/arena_chest.gd")
const ChestArt := preload("res://game/ui/chest_art.gd")

const ART := "res://game/ui/versus_art/%s.png"


static func build(shell, _params: Dictionary) -> Control:
	var root := Kit.vbox(20)
	var quick_on := Dev.quick_fight_shown()
	var p = shell.profile
	var info := ["Ghost Arena: fight other players' saved trios for trophies and Tokens."]
	if quick_on:
		info.append("Quick fight: your fighter against a live foe. Nothing at stake.")
	info.append_array(["Trophy Room: spend Arena Points on stat boosts for each family, Ghost Arena only.",
		"Bazaar: spend Tokens on gear, eggs and energy. New stock every day.",
		"Weekly chest: the best league you reach each week opens that league's chest."])
	root.add_child(shell.title_row("Versus", {"back_mark": "versus_back", "info_mark": "versus_info", "info": info}))
	var store = ArenaStore.open()
	var arena := painted(shell, "hub_arena", "vs_ghost", Vector2(.85, .5), "Ghost Arena",
		"%s · %s" % [Ladder.league_label(store.trophies), Kit.commas(store.trophies)], PlayScreen.VERSUS, func(): shell.go("arena"), true)
	arena.custom_minimum_size.y = 220
	# The Arena's rooms, a level up from the Arena itself: one wide row each,
	# its doorway painting beside what it's for.
	var col := Kit.vbox(14, [arena])
	var rows: Array = []
	if Intro.shows(p, "trophy"):
		rows.append(room_row(shell, "arena_boosts", _room_art("room_trophy", Kit.WARN), "Trophy Room", Kit.commas(store.points) + " Arena Points", "Stat boosts for each family", Kit.WARN, func(): shell.go("boosts", {"store": store})))
	if Intro.done(p):
		rows.append(room_row(shell, "arena_bazaar", _room_art("room_bazaar", Color("ff4fd8")), "Bazaar", Kit.commas(store.coins) + " Tokens", "Gear, eggs and energy, new daily", Color("ff4fd8"), func(): shell.go("bazaar", {"store": store})))
		rows.append(chest_row(shell, store))
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.size_flags_stretch_ratio = 1.5
	for r in rows:
		r.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(r)
	if quick_on:
		var quick := PlayScreen.quick_fight_card(shell, band("vs_quick", "Quick fight", "Live foe · just for fun", Color("cfc8ff")))
		quick.size_flags_vertical = Control.SIZE_EXPAND_FILL
		quick.size_flags_stretch_ratio = 1.8
		col.add_child(quick)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(col)
	return root


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


## The weekly chest's row: the chest your league earns and Open when last
## week's is waiting, else the time left this week.
static func chest_row(shell, store) -> Button:
	var ready: bool = store.chest_ready()
	var league: int = int(store.chest.league) if ready else Ladder.league_index(store.trophies)
	var look := ArenaChest.look(league)
	var chest := ChestArt.make(str(look.id), 124.0)
	if look.has("tint"):
		chest.modulate = look.tint
	var col: Color = look.color
	var pic := PanelContainer.new()
	pic.add_theme_stylebox_override("panel", Kit.box(Color(col, .14), Color(0, 0, 0, 0), 22, 0, 0))
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var centre := CenterContainer.new()
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(chest)
	pic.add_child(centre)
	var line := "Open now!" if ready else "Opens in " + ArenaChest.time_text(ArenaChest.seconds_left())
	return room_row(shell, "arena_chest", pic, "Weekly chest", line, "Your best league this week", Kit.GOOD if ready else col,
		func(): shell.go("arena_chests", {"store": store}), ready)


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
