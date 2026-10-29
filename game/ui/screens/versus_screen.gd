## The Versus hub, opened from the Versus door on Play: Ghost Arena, its
## rooms (Trophy Room, Bazaar and the weekly chest), Critter Plunge (a
## marble-run race) and Quick fight with your fighter (while live fights are on). Each mode is a card with its own
## painting (game/ui/versus_art, from tools/event_art/scenes/versus_modes.mjs);
## the cards share the room so nothing scrolls. A new PvP mode adds one card.
## Friends are behind the level badge (the profile screen).
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const PlayScreen := preload("res://game/ui/screens/play_screen.gd")
const HomePainting := preload("res://game/ui/home_painting.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const Dev := preload("res://game/dev.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const Intro := preload("res://game/ui/intro.gd")
const ArenaScreen := preload("res://game/ui/screens/arena_screen.gd")
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
	info.append("Critter Plunge: race your critter down a marble run against others, abilities flying. Coins for every place.")
	info.append_array(["Trophy Room: spend Arena Points on stat boosts for each family, Ghost Arena only.",
		"Bazaar: spend Tokens on gear, eggs and energy. New stock every day.",
		"Weekly chest: the best league you reach each week opens that league's chest."])
	root.add_child(shell.title_row("Versus", {"back_mark": "versus_back", "info_mark": "versus_info", "info": info}))
	var store = ArenaStore.open()
	var arena := painted(shell, "hub_arena", "vs_ghost", Vector2(.85, .5), "Ghost Arena",
		"%s · %s" % [Ladder.league_label(store.trophies), Kit.commas(store.trophies)], PlayScreen.VERSUS, func(): shell.go("arena"), true)
	arena.custom_minimum_size.y = 150
	# The Arena's rooms, a level up from the Arena itself.
	var rooms := Kit.hbox(10)
	if Intro.shows(p, "trophy"):
		rooms.add_child(ArenaScreen._room(shell, "arena_boosts", "room_trophy", "Trophy Room", Kit.commas(store.points), Kit.WARN, func(): shell.go("boosts", {"store": store})))
	if Intro.done(p):
		rooms.add_child(ArenaScreen._room(shell, "arena_bazaar", "room_bazaar", "Bazaar", Kit.commas(store.coins), Color("ff4fd8"), func(): shell.go("bazaar", {"store": store})))
		rooms.add_child(chest_room(shell, store))
	var plunge := Kit.card_button(band("vs_plunge", "Critter Plunge", "Marble-run race · 4 to 8 critters", Color("27c8ff")), func(): shell.go("plunge"), Color("27c8ff").darkened(.45), Color("27c8ff").darkened(.84), 28, 3)
	plunge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("vs_plunge", plunge)
	var cards := [arena, plunge]
	var ratios := [3.0, 2.4]
	if quick_on:
		cards.append(PlayScreen.quick_fight_card(shell, band("vs_quick", "Quick fight", "Live foe · just for fun", Color("cfc8ff"))))
		ratios.append(3.6)
	# The cards share the room, each in step with its painting.
	for i in cards.size():
		cards[i].size_flags_vertical = Control.SIZE_EXPAND_FILL
		cards[i].size_flags_stretch_ratio = ratios[i]
	var col := Kit.vbox(16, [arena])
	if rooms.get_child_count() > 0:
		col.add_child(rooms)
	for c in cards.slice(1):
		col.add_child(c)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(col)
	return root


## The weekly chest's tile, beside the rooms: the chest your league earns
## and Open when last week's is waiting, else the time left this week.
static func chest_room(shell, store) -> Button:
	var ready: bool = store.chest_ready()
	var league: int = int(store.chest.league) if ready else Ladder.league_index(store.trophies)
	var look := ArenaChest.look(league)
	var art := ChestArt.make(str(look.id), 92.0)
	if look.has("tint"):
		art.modulate = look.tint
	var pic := CenterContainer.new()
	pic.custom_minimum_size.y = 104
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.add_child(art)
	var col: Color = look.color
	var line := "Open!" if ready else ArenaChest.time_text(ArenaChest.seconds_left())
	var words := Kit.vbox(0, [Kit.label("Weekly", 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER), Kit.label(line, 18, Kit.GOOD if ready else col, HORIZONTAL_ALIGNMENT_CENTER)])
	var b := Kit.card_button(Kit.vbox(2, [pic, words]), func(): shell.go("arena_chests", {"store": store}), Color(col, .8), Color(col, .10), 24, 3)
	var st: StyleBoxFlat = b.get_theme_stylebox("normal")
	st.content_margin_bottom = 8
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if ready:
		b.add_child(PlayScreen.red_dot())
	shell.mark("arena_chest", b)
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
