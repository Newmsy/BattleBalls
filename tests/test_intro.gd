## The new player's guided first fights (game/ui/intro.gd): each step opens
## only the next part of the game, and old saves keep everything.
extends "res://tests/test_case.gd"

const Profile := preload("res://meta/profile.gd")
const Intro := preload("res://game/ui/intro.gd")
const Shell := preload("res://game/ui/shell.gd")
const SummonScreen := preload("res://game/ui/screens/summon_screen.gd")


func test_a_new_game_starts_the_intro_and_old_saves_skip_it() -> void:
	var p = Profile.new_game(1_800_000_000)
	check_eq(Intro.step(p), Intro.FIGHT_1, "a new player starts at the first fight")
	var d: Dictionary = p.to_dict()
	check_eq(Intro.step(Profile.from_dict(d, 1_800_000_000)), Intro.FIGHT_1, "the step survives a save")
	d.erase("intro")
	d.stars = {"1-1": 3}
	check(Intro.done(Profile.from_dict(d, 1_800_000_000)), "a save from before the intro has everything open")


func test_only_the_opened_tabs_show() -> void:
	var shell = Shell.new()
	shell.profile = Profile.new_game(1_800_000_000)
	shell.build()
	var visible := func(t): return shell._tab_buttons[t].visible
	check(visible.call("play") and visible.call("fuse"), "Play and Fuse are open")
	for t in ["critters", "bag", "summon"]:
		check(not visible.call(t), t + " waits")
	check(not shell._marks.has("quickfight"), "no Quick fight yet")
	check(shell._marks.has("campaign"), "the campaign is the way in")
	check(shell._coach.visible, "a hint says what to do next")
	shell.profile.intro = Intro.DONE
	shell.profile.changed.emit()
	shell.refresh()
	for t in Shell.TAB_IDS:
		check(visible.call(t), t + " is open at the end")
	check(shell._marks.has("arena"), "Versus is open")
	check(not shell._coach.visible, "no hint once everything is open")
	shell.free()


func test_stage_wins_open_summon_then_the_bag_then_the_arena() -> void:
	var p = Profile.new_game(1_800_000_000)
	var r := {"won": true, "orbs": 0, "gear": []}
	var orbs: int = p.orbs
	Intro.after_stage(p, 0, 0, r)
	check_eq(Intro.step(p), Intro.SUMMON, "1-1 opens Summon")
	check_eq(p.orbs, orbs + 1, "with an orb")
	check_eq(r.intro, Intro.SUMMON, "the popup knows")
	p.intro = Intro.FIGHT_2
	r = {"won": true, "orbs": 0, "gear": []}
	var gear: int = p.gear.size()
	Intro.after_stage(p, 0, 1, r)
	check_eq(Intro.step(p), Intro.EQUIP, "1-2 opens the Bag")
	check_eq(p.gear.size(), gear + 1, "with a piece of gear")
	p.intro = Intro.FIGHT_3
	Intro.after_stage(p, 0, 2, {"won": false})
	check_eq(Intro.step(p), Intro.FIGHT_3, "a loss opens nothing")
	Intro.after_stage(p, 0, 2, {"won": true})
	check_eq(Intro.step(p), Intro.ARENA, "1-3 opens the Arena")


func test_the_first_summon_opens_critters() -> void:
	var shell = Shell.new()
	shell.profile = Profile.new_game(1_800_000_000)
	shell.profile.intro = Intro.SUMMON
	shell.build()
	shell.show_tab("summon")
	check(shell._marks.has("pull1") and not shell._marks.has("pull10"), "one summon button for a new player")
	shell._marks.pull1.pressed.emit()
	check_eq(Intro.step(shell.profile), Intro.FIGHTER, "summoning opens Critters")
	shell.free()


func test_picking_a_fighter_heads_to_the_next_stage() -> void:
	var shell = Shell.new()
	shell.profile = Profile.new_game(1_800_000_000)
	shell.profile.intro = Intro.FIGHTER
	shell.build()
	shell.go("detail", {"id": shell.profile.lineup})
	check(shell._footer.is_ancestor_of(shell._marks.detail_fighter), "the fighter button is pinned")
	shell._marks.detail_fighter.pressed.emit()
	check_eq(Intro.step(shell.profile), Intro.FIGHT_2, "picking a fighter moves on")
	check_eq(shell.current, "campaign", "straight to the stage list")
	shell.free()
