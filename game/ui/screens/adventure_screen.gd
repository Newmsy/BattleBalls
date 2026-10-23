## The Adventure hub, opened from the Adventure door on Play: the campaign,
## the Spire and the farming bosses. A new PvE mode adds one tile here.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const PlayScreen := preload("res://game/ui/screens/play_screen.gd")
const BossesScreen := preload("res://game/ui/screens/bosses_screen.gd")
const LiveOps := preload("res://game/liveops.gd")
const Spire := preload("res://sim/spire.gd")
const SpireClimb := preload("res://meta/spire_climb.gd")


static func build(shell, _params: Dictionary) -> Control:
	var root := Kit.vbox(20)
	root.add_child(shell.title_row("Adventure", {"back_mark": "adventure_back", "info_mark": "adventure_info", "info": [
		"Campaign: the Neon Circuit, zone by zone. Stages drop critter copies, Summon Orbs and gear.",
		"The Spire: 50 floors, one critter per floor, resets every week.",
		"Bosses: farm coins, gear, Hammers and eggs. They open from stage 1-5."]}))
	root.add_child(PlayScreen.campaign_card(shell))
	var climb = SpireClimb.load_file(LiveOps.now())
	root.add_child(PlayScreen.group("More adventures", PlayScreen.DAILY, [
		PlayScreen.mode_tile(shell, "hub_spire", "The Spire", "Floor %d/%d" % [climb.cleared, Spire.FLOORS], PlayScreen.DAILY,
			func(): shell.go("spire"), "tower"),
		BossesScreen.tile(shell) if BossesScreen.any_open(shell.profile) else PlayScreen.locked_bosses_tile(shell),
	]))
	return root
