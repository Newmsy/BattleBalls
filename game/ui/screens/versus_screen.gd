## The Versus hub, opened from the Versus door on Play: Ghost Arena, Quick
## fight with your fighter, 2v2 and Friends. A new PvP mode adds one tile here.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const PlayScreen := preload("res://game/ui/screens/play_screen.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const Ladder := preload("res://game/pvp/ladder.gd")


static func build(shell, _params: Dictionary) -> Control:
	var root := Kit.vbox(20)
	root.add_child(shell.title_row("Versus", {"back_mark": "versus_back", "info_mark": "versus_info", "info": [
		"Ghost Arena: fight other players' saved trios for trophies and Tokens.",
		"Quick fight: your fighter against a random foe. Practice, nothing at stake.",
		"2v2: pick a pair for a four-ball brawl.",
		"Friends: add friends, send energy and rematch their teams."]}))
	var store = ArenaStore.open()
	root.add_child(PlayScreen.mode_tile(shell, "hub_arena", "Ghost Arena", "%s · %s" % [Ladder.league_label(store.trophies), Kit.commas(store.trophies)],
		PlayScreen.VERSUS, func(): shell.go("arena"), "ghost"))
	root.add_child(PlayScreen.quick_fight_card(shell))
	root.add_child(PlayScreen.group("More", PlayScreen.VERSUS, [
		PlayScreen.mode_tile(shell, "hub_duo", "2v2", "Pick a pair", PlayScreen.VERSUS, func(): shell.request_play("", true), "critters"),
		PlayScreen.friends_tile(shell),
	]))
	return root
