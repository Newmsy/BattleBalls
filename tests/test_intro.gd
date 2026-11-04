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
	check(shell._marks.has("daily_quests") and shell._marks.has("spire"), "the whole Home shows from the start, the closed parts locked")
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


## Fights stay hands-off (review choice 1D): screens before a fight say how
## it stacks up in one word.
func test_matchup_words_follow_power_and_edges() -> void:
	var M := preload("res://game/ui/matchup.gd")
	check_eq(M.word(M.rate(2441, 820)), "Easy", "far ahead is easy")
	check_eq(M.word(M.rate(1000, 1000)), "Close", "even is close")
	check_eq(M.word(M.rate(700, 1000)), "Tough", "far behind is tough")
	check_eq(M.word(M.rate(1000, 1000, 2)), "Easy", "a big family edge tips an even fight")
	check_eq(M.word(M.rate(1000, 1000, -2)), "Tough", "and the other way round")


func test_bounce_run_and_plunge_open_with_later_stages_for_a_new_player() -> void:
	var p = Profile.new_game(1_800_000_000)
	p.intro = Intro.DONE
	check(not Intro.mode_open(p, "bouncerun") and not Intro.mode_open(p, "plunge"), "both wait after the guided fights")
	var r := {"won": true, "first_clear": true}
	Intro.after_stage(p, 0, 5, r)
	check(r.get("intro") not in [Intro.BOUNCE_RUN, Intro.PLUNGE], "1-6 opens neither")
	r = {"won": true, "first_clear": true}
	p.stars["1-7"] = 1
	Intro.after_stage(p, 0, 6, r)
	check_eq(r.get("intro"), Intro.BOUNCE_RUN, "1-7 shows Bounce Run opening")
	check(Intro.mode_open(p, "bouncerun") and not Intro.mode_open(p, "plunge"), "Bounce Run first")
	r = {"won": true, "first_clear": false}
	Intro.after_stage(p, 0, 6, r)
	check(not r.has("intro"), "a replay doesn't show it again")
	p.stars["1-9"] = 1
	r = {"won": true, "first_clear": true}
	Intro.after_stage(p, 0, 8, r)
	check_eq(r.get("intro"), Intro.PLUNGE, "1-9 shows Critter Plunge opening")
	check(Intro.mode_open(p, "plunge"), "then Plunge")
	var d: Dictionary = p.to_dict()
	check(Profile.from_dict(d, 1_800_000_000).paced, "pacing survives a save")
	d.erase("paced")
	d.stars = {}
	check(Intro.mode_open(Profile.from_dict(d, 1_800_000_000), "plunge"), "older saves keep every mode open")


## Each guided step lights the one control to tap (Newms 2026-11-03): the
## target is on the screen it names, and the hint follows it.
func test_every_guided_step_lights_a_control_that_exists() -> void:
	var shell = Shell.new()
	shell.profile = Profile.new_game(1_800_000_000)
	shell.size = Vector2(720, 1280)
	shell.build()
	var p = shell.profile
	var cases := [
		[Intro.FIGHT_1, "play", {}], [Intro.FIGHT_1, "world", {}], [Intro.FIGHT_1, "campaign", {"zone": 0}],
		[Intro.SUMMON, "summon", {}], [Intro.SUMMON, "play", {}],
		[Intro.FIGHTER, "critters", {}], [Intro.FIGHTER, "detail", {"id": p.lineup}],
		[Intro.EQUIP, "bag", {}], [Intro.EQUIP, "play", {}],
		[Intro.ARENA, "play", {}],
	]
	p.add_gear("bubble_shell", 1)
	for c in cases:
		p.intro = c[0]
		if c[1] in Shell.TAB_IDS:
			shell.show_tab(c[1])
		else:
			shell.go(c[1], c[2])
		var aim := Intro.target(p, c[1], c[2])
		check(aim != "", "step %d on %s has a target" % [c[0], c[1]])
		var found = shell._marks.get(aim) if not aim.begins_with("tab_") else shell._tab_buttons.get(aim.substr(4))
		check(found is Control, "step %d on %s: %s is on screen" % [c[0], c[1], aim])
		check_eq(shell._spot.target, found, "step %d on %s: the spotlight follows %s" % [c[0], c[1], aim])
	p.intro = Intro.DONE
	shell.show_tab("play")
	check(shell._spot.target == null, "no spotlight once everything is open")
	shell.free()


func test_the_hint_names_the_button_on_screen() -> void:
	var p = Profile.new_game(1_800_000_000)
	p.intro = Intro.FIGHTER
	check(Intro.coach(p, "detail", {"id": p.lineup}).contains("Your fighter"), "your fighter already: the hint says its button")
	check(Intro.coach(p, "detail", {"id": "spiker"}).contains("Pick"), "another critter: Pick")
	p.intro = Intro.EQUIP
	var old: Dictionary = p.add_gear("bubble_shell", 1)
	var fresh: Dictionary = p.add_gear("spike_core", 1)
	check_eq(Intro.target(p, "bag", {}), "gear_%d" % fresh.uid, "the newest piece is the one to tap")
	check_eq(Intro.target(p, "detail", {"id": p.lineup}), "slot_core", "and its slot on the critter page")
	check(old.uid != fresh.uid, "two pieces")


func test_the_boss_teaser_names_the_real_boss_stage() -> void:
	var Onboarding := preload("res://game/onboarding.gd")
	var Zones := preload("res://meta/zones.gd")
	var n: int = Onboarding.boss_stage()
	check(Zones.is_boss(Zones.zone(0).stages[n - 1]), "stage 1-%d is Mega Boulder" % n)


## The Trophy step ends when you buy a boost, not when the room opens.
func test_the_trophy_step_ends_on_a_bought_boost() -> void:
	var ArenaStore := preload("res://game/pvp/arena_store.gd")
	var Families := preload("res://sim/families.gd")
	var path := "user://test_intro_trophy_%d.cfg" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var store = ArenaStore.open(path)
	store.points = 24
	var shell = Shell.new()
	shell.profile = Profile.new_game(1_800_000_000)
	shell.profile.intro = Intro.TROPHY
	shell.build()
	shell.go("boosts", {"store": store})
	check_eq(Intro.step(shell.profile), Intro.TROPHY, "opening the room isn't the end")
	check(shell._marks.has("boost_trophy_pick"), "one boost is lit")
	check_eq(shell._marks.boost_trophy_pick, shell._marks.get("boost_%s_attack" % Families.of(store.trio[0])), "your lead critter's family, Attack")
	shell._marks.boost_trophy_pick.pressed.emit()
	check_eq(Intro.step(shell.profile), Intro.DONE, "buying it opens everything")
	shell.free()
	var broke = ArenaStore.open(path)
	broke.points = 0
	var p = Profile.new_game(1_800_000_000)
	p.intro = Intro.TROPHY
	var shell2 = Shell.new()
	shell2.profile = p
	shell2.build()
	shell2.go("boosts", {"store": broke})
	check_eq(Intro.step(p), Intro.DONE, "with nothing to spend it opens at once")
	shell2.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## After the guided fights the side features arrive one stage at a time:
## Trick Shot 1-4, Bosses 1-5, the Spire 1-6, Rifts 1-11, each with its moment.
func test_side_features_open_one_stage_at_a_time() -> void:
	var p = Profile.new_game(1_800_000_000)
	p.intro = Intro.DONE
	check(not Intro.side_open(p, "trickshot") and not Intro.side_open(p, "spire"), "both wait after the guided fights")
	for c in [[3, Intro.TRICK_SHOT], [4, Intro.BOSSES], [5, Intro.SPIRE], [10, Intro.RIFTS]]:
		var r := {"won": true, "first_clear": true}
		p.stars["1-%d" % (c[0] + 1)] = 1
		Intro.after_stage(p, 0, c[0], r)
		check_eq(r.get("intro"), c[1], "1-%d shows its moment" % (c[0] + 1))
		check(Intro.MOMENTS.has(c[1]), "and the moment exists")
	check(Intro.side_open(p, "trickshot") and Intro.side_open(p, "spire"), "open once their stages are won")
	var shell = Shell.new()
	shell.profile = Profile.new_game(1_800_000_000)
	shell.profile.intro = Intro.DONE
	shell.build()
	shell.show_tab("play")
	check(shell._marks.has("locked_trickshot") and shell._marks.has("locked_spire"), "Home shows them locked with their stage")
	shell.free()
	var old = Profile.new()
	check(Intro.side_open(old, "spire"), "older saves keep everything open")
