## Critter Plunge (sim/plunge.gd, meta/critter_plunge.gd, game/plunge.gd):
## races replay exactly from the seed, racers use their real abilities, the
## course never traps a racer, about a quarter of the field is knocked out,
## and a race pays out into the save through the scene's own flow.
extends "res://tests/test_case.gd"

const Plunge := preload("res://sim/plunge.gd")
const PlungeCourse := preload("res://sim/plunge_course.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const CritterPlunge := preload("res://meta/critter_plunge.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const Families := preload("res://sim/families.gd")
const Profile := preload("res://meta/profile.gd")
const SaveGame := preload("res://game/online/save_game.gd")
const PlungeTalents := preload("res://meta/plunge_talents.gd")

const T0 := 1_800_000_000


func _race(cfg: Dictionary) -> Dictionary:
	var p := Plunge.new(cfg)
	var res := p.run()
	res.ticks = p.tick
	res.positions = p.balls.map(func(b): return b.pos)
	res.hp = p.balls.map(func(b): return b.hp)
	return res


func test_races_replay_from_the_seed() -> void:
	var cfg := {"seed": 77, "racers": Plunge.draw_field(77, 8)}
	check_eq(_race(cfg), _race(cfg), "same seed, same race")
	var other := {"seed": 78, "racers": cfg.racers}
	check(_race(cfg).positions != _race(other).positions, "seeds differ")


## A pinned race. If a deliberate change moves it, update this and bump
## Plunge.RACE_RULES.
func test_golden_race() -> void:
	var p := Plunge.new({"seed": 2026, "racers": Plunge.draw_field(2026, 6)})
	var res := p.run()
	check_eq(p.balls.map(func(b): return b.type_id), GOLDEN_RACERS, "racers")
	check_eq(res.order, GOLDEN_ORDER, "finishing order")
	check_eq(res.kos, GOLDEN_KOS, "knocked out")
	check_eq(p.tick, GOLDEN_TICKS, "race length in ticks")

const GOLDEN_RACERS := ["thorns", "comet", "gumdrop", "frost", "prism", "honey"]
const GOLDEN_ORDER := [1, 5, 0, 4, 2, 3]
const GOLDEN_KOS := [3, 2]
const GOLDEN_TICKS := 2471


## Racers are live critters, every family races, and they race with their
## real abilities (the fight's ability list, untouched).
func test_racers_use_their_real_abilities() -> void:
	var live := CritterDb.live_ids()
	for id in Plunge.RACERS:
		check(live.has(id), "%s races and is live" % id)
	for fam in Families.MEMBERS:
		check(Families.MEMBERS[fam].any(func(id): return Plunge.RACERS.has(id)), "%s has a racer" % fam)
	var p := Plunge.new({"seed": 5, "racers": ["laser", "bomber", "frost", "honey"]})
	for b in p.balls:
		check_eq(b.def.effects, BallDefs.get_def(b.type_id).effects, "%s's abilities" % b.type_id)
		check_near(b.radius, Plunge.RADIUS, 0.001, "%s races at racer size" % b.type_id)
	for k in 30 * 60:
		p.step()
	check(p.zones.size() + p.beams.size() > 0 or p.balls.any(func(b): return b.damage_dealt > 0.0), "abilities did something")


func test_fields_are_different_live_critters() -> void:
	for seed in range(1, 30):
		for n in Plunge.FIELD_SIZES:
			var ids := Plunge.draw_field(seed, n, ["vampire"])
			check_eq(ids.size(), n, "seed %d field size" % seed)
			check(not ids.has("vampire"), "the excluded critter stays out")
			for id in ids:
				check_eq(ids.count(id), 1, "seed %d repeats %s" % [seed, id])
				check(Plunge.can_race(id), "%s races" % id)


## Pegs leave a racer-wide gap to the walls and the fork's divider; the only
## things on a wall are the half-bumpers that kick racers back in.
func test_course_has_no_wedges() -> void:
	for seed in range(1, 40):
		var p := Plunge.new({"seed": seed, "racers": Plunge.draw_field(seed, 4)})
		for g in p.course.pegs:
			if g.bumper and g.r == PlungeCourse.KICKER_R:
				check(g.pos.x == 0.0 or g.pos.x == Plunge.WIDTH, "seed %d kicker on a wall" % seed)
				continue
			var gap: float = minf(g.pos.x, Plunge.WIDTH - g.pos.x) - g.r
			check(gap >= 2.0 * Plunge.RADIUS + 4.0, "seed %d peg at %s is %.0f from a wall" % [seed, g.pos, gap])
		check(p.finish_y > 3000.0 and p.finish_y < 7000.0, "seed %d course length %.0f" % [seed, p.finish_y])


## Tiers bring each critter's tier upgrades into the race.
func test_tiers_upgrade_abilities() -> void:
	var t1 := Plunge.new({"seed": 3, "racers": ["honey", "laser", "pip", "bomber"]})
	var t5 := Plunge.new({"seed": 3, "racers": ["honey", "laser", "pip", "bomber"], "tiers": [5, 5, 5, 5]})
	check_eq(t5.balls[0].def, BallDefs.get_def("honey", 5), "T5 honey races as T5")
	check(t5.balls[0].def.effects.size() > t1.balls[0].def.effects.size(), "with its T5 extras")


## About a quarter knocked out, races end in watchable time, and a fair
## spread of gates and verbs wins (loose bands: a small sample; use
## tools/plunge_stats.gd for the real numbers).
func test_races_are_watchable_and_fair() -> void:
	var s: Dictionary = load("res://tools/plunge_stats.gd").measure(8, 30, 500)
	check(s.ko_rate >= 0.1 and s.ko_rate <= 0.45, "knocked out %.0f%% (target ~25%%)" % (100.0 * s.ko_rate))
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
	check(cfg.tiers.all(func(x): return x == cfg.tiers[0]), "everyone at your tier")
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
	check_eq(r.medal, "silver", "2nd of 6 wins silver")
	check_eq(PlungeTalents.medals(p).silver, 1, "the medal is kept")
	check_eq(CritterPlunge.finish(p, fighter, 1, 6, true).medal, "", "no medal when knocked out")


func test_medals_by_place_and_field() -> void:
	check_eq(PlungeTalents.medal_for(1, 8), "gold", "8: 1st gold")
	check_eq(PlungeTalents.medal_for(4, 8), "bronze", "8: 4th bronze")
	check_eq(PlungeTalents.medal_for(5, 8), "", "8: 5th nothing")
	check_eq(PlungeTalents.medal_for(1, 4), "silver", "4: 1st silver")
	check_eq(PlungeTalents.medal_for(3, 4), "", "4: 3rd nothing")


## 1 gold = 2 silver = 4 bronze: higher medals break to pay for lower ones.
func test_paying_breaks_higher_medals() -> void:
	check_eq(PlungeTalents.pay({"gold": 0, "silver": 0, "bronze": 3}, {"bronze": 3}), {"gold": 0, "silver": 0, "bronze": 0}, "exact")
	check_eq(PlungeTalents.pay({"gold": 0, "silver": 1, "bronze": 1}, {"bronze": 3}), {"gold": 0, "silver": 0, "bronze": 0}, "a silver for two bronze")
	check_eq(PlungeTalents.pay({"gold": 1, "silver": 0, "bronze": 0}, {"bronze": 1}), {"gold": 0, "silver": 1, "bronze": 1}, "change comes back")
	check_eq(PlungeTalents.pay({"gold": 0, "silver": 4, "bronze": 0}, {"gold": 1}), {}, "silver never pays for gold")
	check_eq(PlungeTalents.pay({"gold": 2, "silver": 0, "bronze": 0}, {"gold": 1, "silver": 1, "bronze": 2}), {"gold": 0, "silver": 0, "bronze": 0}, "a mixed price from gold")


func test_talents_buy_save_and_boost_your_racer() -> void:
	var p = Profile.new_game(T0)
	check(not PlungeTalents.buy(p, "spooky", "tough"), "no medals, no talent")
	for k in 3:
		PlungeTalents.add_medal(p, "gold")
	check(PlungeTalents.buy(p, "spooky", "tough"), "buys rank 1")
	check(PlungeTalents.buy(p, "spooky", "tough"), "and rank 2")
	check_eq(PlungeTalents.rank(p, "spooky", "tough"), 2, "rank 2")
	var back = Profile.from_dict(p.to_dict(), T0)
	check_eq(back.plunge, p.plunge, "saved")
	var cfg := CritterPlunge.race_for(p, "vampire", 4, 9)
	var race := Plunge.new(cfg)
	var plain := Plunge.new({"seed": 9, "racers": cfg.racers, "tiers": cfg.tiers})
	check_near(race.balls[0].max_hp, plain.balls[0].max_hp * 1.1, 0.01, "+10% HP for a Spooky racer")
	check_near(race.balls[1].max_hp, plain.balls[1].max_hp, 0.01, "the field gets none")


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
