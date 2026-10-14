extends "res://tests/test_case.gd"

const SaveGame := preload("res://game/online/save_game.gd")
const GhostLineup := preload("res://game/online/ghost_lineup.gd")
const Backend := preload("res://game/online/backend.gd")
const MatchSim := preload("res://sim/match_sim.gd")

const TEST_SAVE := "user://test_save.json"


func _fresh_save() -> SaveGame:
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	return SaveGame.new(TEST_SAVE)


func test_save_round_trips_and_bumps_rev() -> void:
	var s := _fresh_save()
	s.record_fight(0, -30)
	s.record_fight(1, 15)
	var t := SaveGame.new(TEST_SAVE)
	t.load_local()
	check_eq(t.rev, 2, "rev")
	check_eq(int(t.data.stats.wins), 1, "wins")
	check_eq(int(t.data.stats.losses), 1, "losses")
	check_eq(t.data.aim_offsets.map(func(a): return int(a)), [-30, 15], "aim history")


func test_aim_history_is_capped() -> void:
	var s := _fresh_save()
	for i in SaveGame.AIM_HISTORY + 5:
		s.record_fight(-1, i)
	check_eq(s.data.aim_offsets.size(), SaveGame.AIM_HISTORY, "capped")
	check_eq(int(s.data.aim_offsets[-1]), SaveGame.AIM_HISTORY + 4, "keeps the newest")


func test_only_newer_cloud_saves_are_adopted() -> void:
	var s := _fresh_save()
	s.record_fight(0, 0)
	s.record_fight(0, 0)
	check(not s.adopt_if_newer(1, {"stats": {"wins": 9}}), "older cloud ignored")
	check(not s.adopt_if_newer(2, {"stats": {"wins": 9}}), "equal cloud ignored")
	check_eq(int(s.data.stats.wins), 2, "local kept")
	check(s.adopt_if_newer(5, {"stats": {"wins": 9}}), "newer cloud adopted")
	check_eq(s.rev, 5, "rev follows cloud")
	check_eq(int(s.data.stats.wins), 9, "cloud data")


func test_old_saves_gain_new_keys() -> void:
	var up := SaveGame.upgrade({"stats": {"wins": 4}})
	check_eq(int(up.stats.wins), 4, "kept value")
	check_eq(int(up.stats.fights), 0, "filled nested default")
	check(up.has("aim_offsets") and up.has("picks"), "filled top-level defaults")


func test_lineup_shape() -> void:
	var l := GhostLineup.make(["vampire", "laser", "vampire", "laser"], range(20))
	check_eq(l.v, 1, "version")
	check_eq(l.rules, MatchSim.RULES_VERSION, "rules")
	check_eq(l.slots.size(), GhostLineup.MAX_SLOTS, "slots capped")
	check_eq(l.slots[0], {"critter": "vampire", "tier": 1, "level": 1, "gear": []}, "slot")
	check_eq(l.aim.size(), GhostLineup.MAX_AIM, "aim capped")
	check_eq(int(l.aim[-1]), 19, "newest aims kept")
	check(GhostLineup.is_playable(l), "own lineup is playable")
	# Survives a JSON round trip (numbers come back as floats).
	check(GhostLineup.is_playable(JSON.parse_string(JSON.stringify(l))), "playable after JSON")


func test_unplayable_lineups_are_rejected() -> void:
	var good := GhostLineup.make(["laser"], [])
	var other_rules := good.duplicate(true)
	other_rules.rules = MatchSim.RULES_VERSION + 1
	var unknown := good.duplicate(true)
	unknown.slots[0].critter = "not-a-critter"
	var empty := good.duplicate(true)
	empty.slots = []
	for bad in [null, {}, other_rules, unknown, empty]:
		check(not GhostLineup.is_playable(bad), "rejects %s" % str(bad))


func test_ghost_aim_is_deterministic_and_mirrored() -> void:
	var l := GhostLineup.make(["laser"], [-100, 0, 250])
	check_eq(GhostLineup.ghost_angle(l, 7), GhostLineup.ghost_angle(l, 7), "same seed, same aim")
	check_eq(GhostLineup.ghost_angle(l, 2), MatchSim.AIM_AT_CENTRE[1] + 250, "seed picks a habit")
	check_eq(GhostLineup.ghost_angle(GhostLineup.make(["laser"], []), 5), MatchSim.AIM_AT_CENTRE[1], "no habits: centre")
	check_eq(GhostLineup.aim_offset(MatchSim.AIM_AT_CENTRE[0] + 40), 40, "offset")
	check_eq(GhostLineup.aim_offset(MatchSim.AIM_AT_CENTRE[0] + 3590), -10, "offset wraps")


func test_backend_is_offline_without_config() -> void:
	var b := Backend.new()
	if not FileAccess.file_exists(Backend.CONFIG_PATH):
		check(not b.enabled(), "no config, no backend")
	b.url = "https://example.supabase.co"
	b.key = "anon"
	check(b.enabled(), "configured")
	b.disabled = true
	check(not b.enabled(), "?offline=1 wins")
	b.free()
