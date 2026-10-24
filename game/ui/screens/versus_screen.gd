## The Versus hub, opened from the Versus door on Play: Ghost Arena, Quick
## fight with your fighter, 2v2 and Friends. Each mode is a card with its own
## painting (game/ui/versus_art, from tools/event_art/scenes/versus_modes.mjs);
## the cards share the room so nothing scrolls. A new PvP mode adds one card.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const PlayScreen := preload("res://game/ui/screens/play_screen.gd")
const HomePainting := preload("res://game/ui/home_painting.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const Ladder := preload("res://game/pvp/ladder.gd")

const ART := "res://game/ui/versus_art/%s.png"


static func build(shell, _params: Dictionary) -> Control:
	var root := Kit.vbox(20)
	root.add_child(shell.title_row("Versus", {"back_mark": "versus_back", "info_mark": "versus_info", "info": [
		"Ghost Arena: fight other players' saved trios for trophies and Tokens.",
		"Quick fight: your fighter against a random foe. Practice, nothing at stake.",
		"2v2: pick a pair for a four-ball brawl.",
		"Friends: add friends, send energy and rematch their teams."]}))
	var store = ArenaStore.open()
	var arena := painted(shell, "hub_arena", "vs_ghost", Vector2(.85, .5), "Ghost Arena",
		"%s · %s" % [Ladder.league_label(store.trophies), Kit.commas(store.trophies)], PlayScreen.VERSUS, func(): shell.go("arena"), true)
	arena.custom_minimum_size.y = 150
	var quick := PlayScreen.quick_fight_card(shell, band("vs_quick", "Quick fight", "Random foe · practice", Color("cfc8ff")))
	var fr = shell.friends
	var duo := painted(shell, "hub_duo", "vs_duo", Vector2(.5, .8), "2v2", "Pick a pair", PlayScreen.VERSUS, func(): shell.request_play("", true))
	var friends := painted(shell, "friends", "vs_friends", Vector2(.5, .75), "Friends", PlayScreen._friends_line(fr),
		Kit.GOOD if fr.attention() > 0 else PlayScreen.VERSUS, func(): shell.go("friends"))
	if fr.attention() > 0:
		friends.add_child(PlayScreen.red_dot())
	var pair := Kit.hbox(14, [duo, friends])
	pair.custom_minimum_size.y = 170
	# Spare height grows the paintings, roughly in step with their shapes.
	var cards := [arena, quick, pair]
	for i in cards.size():
		cards[i].size_flags_vertical = Control.SIZE_EXPAND_FILL
		cards[i].size_flags_stretch_ratio = [3.0, 3.6, 3.0][i]
	var col := Kit.vbox(16, cards)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(col)
	return root


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
