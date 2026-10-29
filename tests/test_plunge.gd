## Critter Plunge (sim/plunge.gd, meta/critter_plunge.gd, game/plunge.gd):
## races replay exactly from the seed, every critter has a race verb, the
## course never traps a racer, about a quarter of the field is knocked out,
## and a race pays out into the save through the scene's own flow.
extends "res://tests/test_case.gd"

const Plunge := preload("res://sim/plunge.gd")
const CritterPlunge := preload("res://meta/critter_plunge.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const Profile := preload("res://meta/profile.gd")
const SaveGame := preload("res://game/online/save_game.gd")

const T0 := 1_800_000_000


func _race(cfg: Dictionary) -> Dictionary:
	var p := Plunge.new(cfg)
	var res := p.run()
	res.ticks = p.tick
	res.positions = p.racers.map(func(r): return r.pos)
	res.hp = p.racers.map(func(r): return r.hp)
	return res


func test_races_replay_from_the_seed() -> void:
	var cfg := {"seed": 77, "racers": Plunge.draw_field(77, 8)}
	check_eq(_race(cfg), _race(cfg), "same seed, same race")
	var other := {"seed": 78, "racers": cfg.racers}
	check(_race(cfg).positions != _race(other).positions, "seeds differ")


## A pinned race. If a deliberate change moves it, update this and bump
## Plunge.RULES_VERSION.
func test_golden_race() -> void:
	var p := Plunge.new({"seed": 2026, "racers": Plunge.draw_field(2026, 6)})
	var res := p.run()
	check_eq(p.racers.map(func(r): return r.id), GOLDEN_RACERS, "racers")
	check_eq(res.order, GOLDEN_ORDER, "finishing order")
	check_eq(res.kos, GOLDEN_KOS, "knocked out")
	check_eq(p.tick, GOLDEN_TICKS, "race length in ticks")

const GOLDEN_RACERS := ["ripple", "glowbug", "jackpot", "pip", "ivy", "megabot"]
const GOLDEN_ORDER := [2, 1, 5, 0, 4, 3]
const GOLDEN_KOS := [3, 4, 0]
const GOLDEN_TICKS := 2791


func test_every_critter_has_a_race_verb() -> void:
	for id in CritterDb.live_ids():
		check(Plunge.VERBS.has(id), "%s has a race verb in Plunge.VERBS" % id)
	for id in Plunge.VERBS:
		check(CritterDb.has(id), "%s in Plunge.VERBS is a critter" % id)
		check(Plunge.VERB_STATS.has(Plunge.VERBS[id]), "%s's verb %s exists" % [id, Plunge.VERBS[id]])
	for v in Plunge.VERB_STATS:
		check(Plunge.VERB_NAMES.has(v) and Plunge.VERB_TEXT.has(v), "%s has a name and a line" % v)
		check(Plunge.VERBS.values().count(v) >= 5, "%s has at least 5 critters" % v)


func test_fields_are_different_live_critters() -> void:
	for seed in range(1, 30):
		for n in Plunge.FIELD_SIZES:
			var ids := Plunge.draw_field(seed, n, ["vampire"])
			check_eq(ids.size(), n, "seed %d field size" % seed)
			check(not ids.has("vampire"), "the excluded critter stays out")
			for id in ids:
				check_eq(ids.count(id), 1, "seed %d repeats %s" % [seed, id])
				check(CritterDb.live_ids().has(id), "%s is live" % id)


## Pegs leave a racer-wide gap to the walls and the fork's divider; the only
## things on a wall are the half-bumpers that kick racers back in.
func test_course_has_no_wedges() -> void:
	for seed in range(1, 40):
		var p := Plunge.new({"seed": seed, "racers": Plunge.draw_field(seed, 4)})
		for g in p.pegs:
			if g.bumper and g.r == Plunge.KICKER_R:
				check(g.pos.x == 0.0 or g.pos.x == Plunge.WIDTH, "seed %d kicker on a wall" % seed)
				continue
			var gap: float = minf(g.pos.x, Plunge.WIDTH - g.pos.x) - g.r
			check(gap >= 2.0 * Plunge.RADIUS + 4.0, "seed %d peg at %s is %.0f from a wall" % [seed, g.pos, gap])
		check(p.finish_y > 3000.0 and p.finish_y < 7000.0, "seed %d course length %.0f" % [seed, p.finish_y])


## Power scales HP and race damage by its 4th root each.
func test_power_counts_a_little() -> void:
	var p := Plunge.new({"seed": 3, "racers": ["vampire", "laser", "pip", "bomber"], "powers": [16.0, 1.0, 1.0, 1.0]})
	check_near(p.racers[0].max_hp, Plunge.HP * 2.0, 0.001, "x16 power, x2 HP")
	check_near(p.racers[0].potency, 2.0, 0.001, "and x2 race damage")
	check_near(p.racers[1].max_hp, Plunge.HP, 0.001, "power 1 is plain")


## About a quarter knocked out, races end in watchable time, and a fair
## spread of gates and verbs wins (loose bands: a small sample; use
## tools/plunge_stats.gd for the real numbers).
func test_races_are_watchable_and_fair() -> void:
	var s: Dictionary = load("res://tools/plunge_stats.gd").measure(8, 30, 500)
	check(s.ko_rate >= 0.1 and s.ko_rate <= 0.4, "knocked out %.0f%% (target ~25%%)" % (100.0 * s.ko_rate))
	check(s.median >= 15.0 and s.median <= 60.0, "median winning time %.1fs" % s.median)
	for g in s.gate_wins:
		check(g <= 12, "no gate wins 12 of 30 (%s)" % [s.gate_wins])


func test_coins_slide_with_place() -> void:
	for n in Plunge.FIELD_SIZES:
		check_eq(CritterPlunge.coins_for(1, n), CritterPlunge.WIN_COINS, "%d racers: 1st" % n)
		check_eq(CritterPlunge.coins_for(n, n), CritterPlunge.LAST_COINS, "%d racers: last" % n)
		for k in range(1, n):
			check(CritterPlunge.coins_for(k, n) > CritterPlunge.coins_for(k + 1, n), "%d racers: %d pays more than %d" % [n, k, k + 1])


func test_start_spends_energy_and_races_your_fighter() -> void:
	var p = Profile.new_game(T0)
	var fighter: String = p.lineup
	var before: int = p.energy
	var cfg := CritterPlunge.start(p, fighter, 8, T0)
	check(not cfg.has("error"), "starts: %s" % [cfg])
	check_eq(p.energy, before - CritterPlunge.ENERGY_COST, "energy spent")
	check_eq(cfg.racers[0], fighter, "your fighter is racer 0")
	check_eq(cfg.racers.size(), 8, "field of 8")
	check_eq(cfg.racers.count(fighter), 1, "your fighter races once")
	check(cfg.powers.all(func(x): return x == cfg.powers[0]), "everyone at your power")
	check_eq(CritterPlunge.start(p, fighter, 5, T0).get("error", ""), "field", "only 4, 6 or 8")
	p.energy = 0
	check_eq(CritterPlunge.start(p, fighter, 6, T0).get("error", ""), "energy", "no energy, no race")


func test_finish_pays_coins_xp_and_faction_xp() -> void:
	var p = Profile.new_game(T0)
	var fighter: String = p.lineup
	var coins: int = p.coins
	var r := CritterPlunge.finish(p, fighter, 2, 6, false)
	check_eq(p.coins, coins + CritterPlunge.coins_for(2, 6), "coins by place")
	check_eq(r.xp, CritterPlunge.XP, "critter XP")
	check(not p.take_faction_gains().is_empty(), "Faction XP after every race")


## The race scene plays a race to its result popup and pays into the save.
func test_scene_races_and_pays() -> void:
	var path := "user://test_plunge_save.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var p = Profile.new_game(T0)
	var save := SaveGame.new(path)
	save.data.profile = p.to_dict()
	save.commit()
	var cfg := CritterPlunge.race_for(p, p.lineup, 6, 11)
	CritterPlunge.pending = {"cfg": cfg, "fighter": p.lineup}
	var scene = load("res://game/plunge.tscn").instantiate()
	scene.game_save_path = path
	runner.root.add_child(scene)
	scene._ready()
	check(not scene.practice, "a real race")
	scene._skip_race()
	var frames := 0
	while not scene._done and frames < 200:
		frames += 1
		scene._process(0.016)
	check(scene._done, "the race ends")
	check(scene.result.get("coins", 0) >= CritterPlunge.LAST_COINS, "paid coins: %s" % [scene.result])
	var after := SaveGame.new(path)
	after.load_local()
	check_eq(int(after.data.profile.coins), int(p.coins) + int(scene.result.coins), "into the save")
	scene.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
