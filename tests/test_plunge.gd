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
const Campaign := preload("res://meta/campaign.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const PlungeStory := preload("res://game/plunge_story.gd")
const GlowState := preload("res://game/glow/glow_state.gd")
const Quests := preload("res://meta/quests.gd")

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

const GOLDEN_RACERS := ["zapper", "gust", "drako", "pucker", "ripple", "blizz"]
const GOLDEN_ORDER := [2, 1, 0, 5, 4, 3]
const GOLDEN_KOS := []
const GOLDEN_TICKS := 2087


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


## Race-only balance knobs name real params and racers, and stay tweaks
## (an ability stays true to the fight's: numbers move, never the verb).
## The win-share band itself is tools/plunge_stats.gd --check: it takes
## thousands of races to measure, too many for the test run.
func test_race_balance_knobs() -> void:
	for id in Plunge.RACE_TWEAKS:
		check(Plunge.RACERS.has(id), "%s is tuned and races" % id)
		for key in Plunge.RACE_TWEAKS[id]:
			check(BallDefs.get_def(id).has(key), "%s has %s" % [id, key])
			var m: float = Plunge.RACE_TWEAKS[id][key]
			var switch: bool = m == 0.0 and BallDefs.get_def(id, 5)[key] in [0, 1]
			check(switch or (m >= 0.25 and m <= 3.0), "%s %s x%.2f stays a tweak" % [id, key, m])
	for id in Plunge.RACE_HP:
		check(Plunge.RACERS.has(id), "%s's race HP and it races" % id)
		check(Plunge.RACE_HP[id] >= 0.6 and Plunge.RACE_HP[id] <= 1.6, "%s race HP x%.2f stays a tweak" % [id, Plunge.RACE_HP[id]])
	var plain := Plunge.new({"seed": 4, "racers": ["pip", "honey", "laser", "frost"]})
	for b in plain.balls:
		check_near(b.max_hp, BallDefs.get_def(b.type_id).hp * Plunge.HP_BY_FIELD[4] * Plunge.RACE_HP.get(b.type_id, 1.0), 0.01, "%s race HP" % b.type_id)


func test_fields_are_different_live_critters() -> void:
	for seed in range(1, 30):
		for n in Plunge.FIELD_SIZES:
			var ids := Plunge.draw_field(seed, n, ["vampire"])
			check_eq(ids.size(), n, "seed %d field size" % seed)
			check(not ids.has("vampire"), "the excluded critter stays out")
			for id in ids:
				check_eq(ids.count(id), 1, "seed %d repeats %s" % [seed, id])
				check(Plunge.can_race(id), "%s races" % id)


## On every course, pegs leave a racer-wide gap to the walls and to every
## ramp and divider; the only things on a wall are the half-bumpers that kick
## racers back in.
func test_course_has_no_wedges() -> void:
	var wide := 2.0 * Plunge.RADIUS + 4.0
	for c in PlungeCourse.COURSES:
		for seed in range(1, 6):
			var course := PlungeCourse.new(seed, c.id)
			var at := "%s seed %d" % [c.id, seed]
			for g in course.pegs:
				if g.bumper and g.r == PlungeCourse.KICKER_R:
					check(g.pos.x == 0.0 or g.pos.x == Plunge.WIDTH, "%s kicker on a wall" % at)
					continue
				if g.bumper:
					continue
				var gap: float = minf(g.pos.x, Plunge.WIDTH - g.pos.x) - g.r
				check(gap >= wide, "%s peg at %s is %.0f from a wall" % [at, g.pos, gap])
				for rp in course.ramps:
					var d: float = g.pos.distance_to(Geometry2D.get_closest_point_to_segment(g.pos, rp.a, rp.b))
					check(d - g.r - PlungeCourse.RAMP_THICK >= wide, "%s peg at %s is %.0f from a ramp" % [at, g.pos, d - g.r - PlungeCourse.RAMP_THICK])
			check(course.finish_y > 6000.0 and course.finish_y < 14000.0, "%s course length %.0f" % [at, course.finish_y])
			# A ramp's free end either joins another ramp or leaves a racer-wide
			# gap to it (two candy canes' ends 62 apart wedged racers for good).
			# Ends shared with another ramp's end are a curve's or a shape's
			# joints, and a shape is measured against other shapes only.
			var shape := _ramp_shapes(course.ramps)
			for i in course.ramps.size():
				for end in [course.ramps[i].a, course.ramps[i].b]:
					if course.ramps.any(func(rp): return rp != course.ramps[i] and (end.distance_to(rp.a) < 1.0 or end.distance_to(rp.b) < 1.0)):
						continue
					for j in course.ramps.size():
						var rp: Dictionary = course.ramps[j]
						if shape[j] == shape[i]:
							continue
						var d: float = end.distance_to(Geometry2D.get_closest_point_to_segment(end, rp.a, rp.b))
						check(d < 1.0 or d - 2.0 * PlungeCourse.RAMP_THICK >= wide, "%s ramp end %s is %.0f from a ramp" % [at, end, d - 2.0 * PlungeCourse.RAMP_THICK])


## Which shape each ramp belongs to: ramps that share an end are one shape.
func _ramp_shapes(ramps: Array) -> Array:
	var shape := []
	for i in ramps.size():
		shape.append(i)
	var changed := true
	while changed:
		changed = false
		for i in ramps.size():
			for j in range(i + 1, ramps.size()):
				if shape[i] == shape[j]:
					continue
				var joined := false
				for x in [ramps[i].a, ramps[i].b]:
					for y in [ramps[j].a, ramps[j].b]:
						if x.distance_to(y) < 1.0:
							joined = true
				if joined:
					var lo: int = mini(shape[i], shape[j])
					var hi: int = maxi(shape[i], shape[j])
					for k in ramps.size():
						if shape[k] == hi:
							shape[k] = lo
					changed = true
	return shape


## Every course is mostly moving pieces (Newms 2026-10-29: most of each
## course moves), built from its own three shared pieces and its own
## machine, and every moving part stays under the mover speed, so it bats
## racers about but never pins one.
func test_courses_are_moving_machines() -> void:
	var sets := {}
	var machines := {}
	for c in PlungeCourse.COURSES:
		var pieces: Array = c.plan.filter(func(k): return PlungeCourse.PIECES.has(k))
		var own := {}
		for k in pieces:
			own[k] = true
		check_eq(own.size(), 3, "%s uses three shared pieces" % c.id)
		var key := own.keys()
		key.sort()
		sets[str(key)] = true
		var mine: Array = c.plan.filter(func(k): return PlungeCourse.MACHINES.has(k))
		check_eq(mine.size(), 1, "%s has one machine" % c.id)
		machines[mine[0]] = true
		var p := Plunge.new({"seed": 5, "racers": Plunge.draw_field(5, 4), "course": c.id})
		var moving := 0.0
		for sec in p.course.sections:
			if p.course.movers.any(func(o): return o.pos.y >= sec.y0 and o.pos.y < sec.y1 and (o.has("orbit") or o.has("slide") or o.has("blink"))):
				moving += sec.y1 - sec.y0
		check(moving / p.finish_y >= 0.7, "%s is %.0f%% moving" % [c.id, 100.0 * moving / p.finish_y])
		for k in 8:
			for o in _all_parts(p):
				if o.has("vel"):
					check(o.vel.length() <= PlungeCourse.MOVER_SPEED + 1.0, "%s part at %s moves %.0f" % [c.id, o.pos, o.vel.length()])
			for t in 37:
				p.step()
	check_eq(sets.size(), 20, "no two courses share their pieces")
	check_eq(machines.size(), 20, "every course has its own machine")


## Twenty courses, each a different run in an arena's painted look, and the
## seed picks among them.
func test_twenty_painted_courses() -> void:
	var ArenaArt = load("res://game/arena_art.gd")
	check_eq(PlungeCourse.COURSES.size(), 20, "courses")
	var ids := {}
	var arts := {}
	var plans := {}
	for c in PlungeCourse.COURSES:
		ids[c.id] = true
		arts[c.art] = true
		plans[str(c.plan)] = true
		check(ArenaArt.family(c.art) != "", "%s wears painted art" % c.id)
		for kind in c.plan:
			check(PlungeCourse.SECTIONS.has(kind), "%s section %s" % [c.id, kind])
		for k in range(1, c.plan.size()):
			check(c.plan[k] != c.plan[k - 1], "%s repeats %s" % [c.id, c.plan[k]])
	check_eq(ids.size(), 20, "course ids")
	check_eq(arts.size(), 20, "course looks")
	check_eq(plans.size(), 20, "course layouts")
	for c in PlungeCourse.COURSES:
		check_eq(c.plan.filter(func(k): return PlungeCourse.HAZARDS.has(k)).size(), 1, "%s has one hazard section" % c.id)
	var picked := {}
	for seed in range(1, 200):
		picked[PlungeCourse.new(seed).info.id] = true
	check_eq(picked.size(), 20, "the seed picks every course")
	check_eq(Plunge.new({"seed": 9, "racers": Plunge.draw_field(9, 4), "course": "lava"}).course.info.name, "Lava Tubes", "a course by id")


## Tiers bring each critter's tier upgrades into the race.
func test_tiers_upgrade_abilities() -> void:
	var t1 := Plunge.new({"seed": 3, "racers": ["honey", "laser", "pip", "bomber"]})
	var t5 := Plunge.new({"seed": 3, "racers": ["honey", "laser", "pip", "bomber"], "tiers": [5, 5, 5, 5]})
	check_eq(t5.balls[0].def.effects, BallDefs.get_def("honey", 5).effects, "T5 honey races as T5")
	check_near(t5.balls[0].def.honey_pull, BallDefs.get_def("honey", 5).honey_pull * Plunge.RACE_TWEAKS.honey.get("honey_pull", 1.0), 0.001, "with its T5 numbers (and race tweaks)")
	check(t5.balls[0].def.effects.size() > t1.balls[0].def.effects.size(), "with its T5 extras")


## About 1 in 10 knocked out at T1 and at T5, races end in watchable time, and a fair
## spread of gates and verbs wins (loose bands: a small sample; use
## tools/plunge_stats.gd for the real numbers).
func test_races_are_watchable_and_fair() -> void:
	var s: Dictionary = load("res://tools/plunge_stats.gd").measure(8, 20, 500)
	check(s.ko_rate >= 0.03 and s.ko_rate <= 0.25, "knocked out %.0f%% (target ~10%%)" % (100.0 * s.ko_rate))
	var t5: Dictionary = load("res://tools/plunge_stats.gd").measure(6, 10, 500, 5)
	check(t5.ko_rate <= 0.25, "T5 fields knocked out %.0f%% (target ~10%%)" % (100.0 * t5.ko_rate))
	check(s.median >= 15.0 and s.median <= 60.0, "median winning time %.1fs" % s.median)
	for g in s.gate_wins:
		check(g <= 9, "no gate wins 9 of 20 (%s)" % [s.gate_wins])


func test_coins_slide_with_place() -> void:
	for n in Plunge.FIELD_SIZES:
		var mult := CritterPlunge.COINS_8 if n == 8 else 1.0
		check_eq(CritterPlunge.coins_for(1, n), roundi(CritterPlunge.WIN_COINS * mult), "%d racers: 1st" % n)
		check_eq(CritterPlunge.coins_for(n, n), roundi(CritterPlunge.LAST_COINS * mult), "%d racers: last" % n)
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
	check_eq(cfg.course, CritterPlunge.course_for(cfg.seed).id, "on the course the screen showed")
	check_eq(Plunge.new(cfg).course.info.id, Plunge.new({"seed": cfg.seed, "racers": cfg.racers}).course.info.id, "the seed's own course")
	var next := CritterPlunge.course_for(CritterPlunge.next_seed(p))
	check_eq(CritterPlunge.start(p, fighter, 6, T0).course, next.id, "the screen's next course is the one raced")
	check_eq(CritterPlunge.start(p, fighter, 5, T0).get("error", ""), "field", "only 4, 6 or 8")
	p.energy = 0
	check_eq(CritterPlunge.start(p, fighter, 6, T0).get("error", ""), "energy", "no energy, no race")


func test_finish_pays_coins_xp_and_faction_xp() -> void:
	var p = Profile.new_game(T0)
	var fighter: String = p.lineup
	var coins: int = p.coins
	var r := CritterPlunge.finish(p, fighter, 2, 6, false, true, "vines", T0)
	check_eq(p.coins, coins + CritterPlunge.coins_for(2, 6), "coins by place")
	check_eq(r.xp, CritterPlunge.XP, "critter XP")
	check(not p.take_faction_gains().is_empty(), "Faction XP after every race")
	check_eq(r.medal, "silver", "2nd of 6 wins silver")
	check_eq(PlungeTalents.medals(p).silver, 1, "the medal is kept")
	check_eq(CritterPlunge.finish(p, fighter, 1, 6, true, true, "", T0).medal, "", "no medal when knocked out")
	var skipped := CritterPlunge.finish(p, fighter, 1, 6, false, false, "vines", T0)
	check_eq(skipped.medal, "", "no medal when skipped")
	check(skipped.coins > 0, "a skipped race still pays coins")
	check_eq(CritterPlunge.stamp(p, "vines"), "silver", "a skipped win stamps nothing")


## Coins for the day's first 8 races only; medals and XP after that.
func test_prize_races_a_day() -> void:
	var p = Profile.new_game(T0)
	var fighter: String = p.lineup
	for k in CritterPlunge.PRIZE_RACES:
		check_eq(CritterPlunge.prize_races_left(p, T0), CritterPlunge.PRIZE_RACES - k, "left before race %d" % k)
		check(CritterPlunge.finish(p, fighter, 1, 6, false, true, "", T0).coins > 0, "race %d pays coins" % k)
	var coins: int = p.coins
	var r := CritterPlunge.finish(p, fighter, 1, 6, false, true, "", T0)
	check_eq(r.coins, 0, "no coins after the prize races")
	check_eq(p.coins, coins, "none paid")
	check_eq(r.medal, "gold", "the medal still drops")
	check_eq(CritterPlunge.prize_races_left(p, T0 + 86400), CritterPlunge.PRIZE_RACES, "a new day, new prize races")
	var back = Profile.from_dict(p.to_dict(), T0)
	check_eq(CritterPlunge.prize_races_left(back, T0), 0, "saved")


## 4 racers race for coins, 6 for medals, 8 for better medals and more coins.
func test_medals_by_place_and_field() -> void:
	check_eq(CritterPlunge.medal_for(1, 8), "gold", "8: 1st gold")
	check_eq(CritterPlunge.medal_for(2, 8), "gold", "8: 2nd gold")
	check_eq(CritterPlunge.medal_for(3, 8), "silver", "8: 3rd silver")
	check_eq(CritterPlunge.medal_for(5, 8), "bronze", "8: 5th bronze")
	check_eq(CritterPlunge.medal_for(6, 8), "", "8: 6th nothing")
	check_eq(CritterPlunge.medal_for(1, 6), "gold", "6: 1st gold")
	check_eq(CritterPlunge.medal_for(4, 6), "", "6: 4th nothing")
	check_eq(CritterPlunge.medal_for(1, 4), "", "4: coins only")
	check(CritterPlunge.coins_for(1, 8) > CritterPlunge.coins_for(1, 6), "8 pays more coins")


## The stamp album: the best medal per course, never downgraded, saved.
func test_stamps_keep_the_best_medal() -> void:
	var p = Profile.new_game(T0)
	var fighter: String = p.lineup
	CritterPlunge.finish(p, fighter, 3, 6, false, true, "lava", T0)
	check_eq(CritterPlunge.stamp(p, "lava"), "bronze", "bronze stamp")
	CritterPlunge.finish(p, fighter, 1, 6, false, true, "lava", T0)
	check_eq(CritterPlunge.stamp(p, "lava"), "gold", "upgraded to gold")
	CritterPlunge.finish(p, fighter, 2, 6, false, true, "lava", T0)
	check_eq(CritterPlunge.stamp(p, "lava"), "gold", "never downgraded")
	CritterPlunge.finish(p, fighter, 1, 6, false, true, "nowhere", T0)
	check_eq(p.plunge_stamps.size(), 1, "only real courses")
	var back = Profile.from_dict(p.to_dict(), T0)
	check_eq(back.plunge_stamps, {"lava": "gold"}, "saved")
	check_eq(CritterPlunge.clean_stamps({"lava": "tin", "vines": "silver", "x": "gold"}), {"vines": "silver"}, "cleaned")


## Race talents stay in Critter Plunge: a profile with every one maxed builds
## the same fight configs as one with none (every fight takes your critter
## from Profile.slot_of through Lineup.apply).
func test_race_talents_never_reach_a_fight() -> void:
	var plain = Profile.new_game(T0)
	var boosted = Profile.new_game(T0)
	var fighter: String = plain.lineup
	var fam := Families.of(fighter)
	for k in 200:
		PlungeTalents.add_medal(boosted, "gold")
	for tal in PlungeTalents.TALENTS:
		while PlungeTalents.buy(boosted, fam, tal.id):
			pass
	var fx := PlungeTalents.effects(boosted, fighter)
	check(fx.values().any(func(v): return float(v) > 0.0), "the race talents are bought: %s" % [fx])
	check_eq(boosted.slot_of(fighter), plain.slot_of(fighter), "your critter's fight slot")
	var a := Campaign.start(plain, 0, 0, fighter, T0)
	var b := Campaign.start(boosted, 0, 0, fighter, T0)
	check(not a.has("error"), "a stage fight: %s" % [a])
	check_eq(b, a, "same stage fight config")
	check(not b.has("boosts"), "no race boosts in a fight")
	check_eq(MatchSim.new(b).balls[0].max_hp, MatchSim.new(a).balls[0].max_hp, "same HP in the fight")
	check_eq(Campaign.start_team(boosted, 0, 0, [fighter], T0), Campaign.start_team(plain, 0, 0, [fighter], T0), "same team fight config")


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
	check_near(race.balls[0].max_hp, plain.balls[0].max_hp * 1.06, 0.01, "+6% HP for a Spooky racer")
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
	check(scene.skipped, "skipped from the start: not watched")
	check_eq(scene.result.get("medal", "x"), "", "so no medal")
	var after := SaveGame.new(path)
	after.load_local()
	check_eq(int(after.data.profile.coins), int(p.coins) + int(scene.result.coins), "into the save")
	check_eq(int(after.data.glow.quest_day.progress.get("fight", 0)), 1, "counts as a fight for quests")
	check_eq(after.data.glow.quest_week.courses, [scene.sim.course.info.id], "and its course")
	scene.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Hazards ride on the arena's pieces and act on racers: wells pull (never
## harder than gravity), goo drags, lava burns under the fight's hazard cap,
## sliding bumpers move, and pickups are lit from the start.
func test_course_hazards_act_on_racers() -> void:
	check(PlungeCourse.WELL_ACCEL < Plunge.GRAVITY, "a well never holds a racer")
	var kinds := {}
	for c in PlungeCourse.COURSES:
		var p := Plunge.new({"seed": 3, "racers": Plunge.draw_field(3, 4), "course": c.id})
		check(not p.cores().is_empty() and p.cores().all(func(k): return k.lit), "%s has lit pickups" % c.id)
		for f in p.floors():
			kinds[f.kind] = true
		if not p.wells().is_empty():
			kinds["wells"] = true
		if not _all_parts(p).is_empty():
			kinds["sliders"] = true
	for kind in ["wells", "lava", "goo", "sliders", "wind", "portal", "launch"]:
		check(kinds.has(kind), "%s appear on some course" % kind)
	var lava := Plunge.new({"seed": 3, "racers": ["pip", "honey", "frost", "laser"], "course": "lava"})
	var pool: Vector2 = lava.floors()[0].pos
	for k in 70:
		lava.step()
	var b = lava.balls[0]
	for k in 60 * 20:
		b.pos = pool
		b.vel = Vector2.ZERO
		lava.step()
	check_near(b.hazard_taken, Plunge.HAZARD_CAP * b.max_hp, 0.01, "lava burns up to the cap and no further")
	var slide := Plunge.new({"seed": 3, "racers": Plunge.draw_field(3, 4), "course": "toys"})
	var at: Vector2 = _all_parts(slide)[0].pos
	for k in 60:
		slide.step()
	check(_all_parts(slide)[0].pos != at, "sliders move")


## Every moving part on the course, in course order (obstacles() only
## places the ones near the race).
static func _all_parts(p: Plunge) -> Array[Dictionary]:
	return p.parts_between(0.0, p.finish_y + 1000.0)


## The set pieces' parts do what they look like: a portal sends a racer on,
## a launch pad throws one, wind pushes, flippers swing.
func test_course_parts_act_on_racers() -> void:
	var placed := func(course: String, kind: String, test: Callable) -> void:
		var p := Plunge.new({"seed": 3, "racers": Plunge.draw_field(3, 4), "course": course})
		for k in 70:
			p.step()
		var pads: Array = p.floors()
		for i in pads.size():
			var f: Dictionary = pads[i]
			if f.kind == kind and (kind != "portal" or f.has("to")):
				var b = p.balls[0]
				b.pos = f.rect.get_center() if f.has("rect") else f.pos
				b.vel = Vector2(0.0, 50.0)
				p.step()
				test.call(p, b, f, pads)
				return
		check(false, "%s has a %s" % [course, kind])
	placed.call("nebula", "portal", func(p, b, f, pads): check(b.pos.distance_to(pads[f.to].pos) < 30.0, "a portal sends a racer to its exit"))
	placed.call("pinball", "launch", func(p, b, f, _pads): check(b.vel.y < -300.0, "a launch pad throws a racer up"))
	placed.call("storm", "wind", func(p, b, f, _pads): check(signf(b.vel.x) == signf(f.dir.x), "wind pushes a racer along"))
	var pin := Plunge.new({"seed": 3, "racers": Plunge.draw_field(3, 4), "course": "pinball"})
	var flipper := -1
	for i in pin.arena.obstacles.size():
		if pin.arena.obstacles[i].has("swing"):
			flipper = i
	check(flipper >= 0, "pinball has flippers")
	var tip: Vector2 = _all_parts(pin)[flipper].pos
	for k in 30:
		pin.step()
	check(_all_parts(pin)[flipper].pos.distance_to(tip) > 5.0, "flippers swing")


## The Plunge screen builds with talents, medals and stamps (the demo's
## &plunge=1 profile), shows no power, and opens the stamp album and picker.
func test_screen_and_stamp_album_build() -> void:
	var shell = load("res://game/ui/shell.gd").new()
	shell.build()
	shell.profile.lineup = "vampire"
	CritterPlunge.demo(shell.profile)
	check(shell.profile.plunge_stamps.size() >= 9, "the demo has stamps")
	check_eq(load("res://game/ui/plunge_stamps_sheet.gd").count(shell.profile), shell.profile.plunge_stamps.size(), "album count")
	for n in Plunge.FIELD_SIZES:
		load("res://game/ui/screens/plunge_screen.gd").field = n
		shell.go("plunge")
		check_eq(shell.current, "plunge", "builds with %d racers" % n)
	check(shell._marks.has("plunge_stamps") and shell._marks.has("plunge_talents"), "talents and stamps buttons")
	shell._marks.plunge_stamps.pressed.emit()
	check(shell._marks.has("plunge_stamp_lava"), "the album has a tile per course")
	shell.close_overlay()
	shell._marks.plunge_fighter.pressed.emit()
	check(shell._marks.has("pick_vampire"), "the picker lists your racers")
	shell.close_overlay()
	load("res://game/ui/screens/plunge_screen.gd").field = CritterPlunge.DEFAULT_FIELD
	shell.free()


## Your race read from the events (game/plunge_story.gd): watching every
## step leaves the race as it was, and the story only names what happened.
func test_story_reads_your_race_without_changing_it() -> void:
	for seed_value in [5, 21, 77]:
		var cfg := {"seed": seed_value, "racers": Plunge.draw_field(seed_value, 8)}
		var plain := _race(cfg)
		var p := Plunge.new(cfg)
		var story := PlungeStory.new(0)
		var callouts := []
		while not p.finished:
			p.step()
			callouts.append_array(story.watch(p))
		check_eq(p.order, plain.order, "seed %d: same race while watched" % seed_value)
		for j in story.knocked:
			check(j in p.kos and j != 0, "seed %d: you only knock out racers that went out" % seed_value)
		check_eq(callouts.filter(func(c): return c.text == "KO by you!").size(), story.knocked.size(), "a callout per knockout")
		check(story.ko_by < 0 or p.ko_ticks[0] >= 0, "knocked out by someone only when out")
		var line := story.line(p)
		check(line != "" and not line.contains("  "), "seed %d: a story line: %s" % [seed_value, line])
	check_eq(PlungeStory.new(-1).watch(Plunge.new({"seed": 1})), [], "nothing to tell when only watching")
	var q := Plunge.new({"seed": 1})
	q.events.append({"type": "talent", "ball": 0, "talent": "lava", "pos": Vector2.ZERO})
	q.events.append({"type": "talent", "ball": 2, "talent": "lava", "pos": Vector2.ZERO})
	check_eq(PlungeStory.new(0).watch(q).map(func(c): return c.text), ["Scorch!"], "your race talent firing by its name, nobody else's")


## Skip before your racer is done and the race pays no medal (coins and XP still).
func test_unwatched_races_drop_no_medal() -> void:
	var p = Profile.new_game(T0)
	var r := CritterPlunge.finish(p, p.lineup, 1, 8, false, false, "lava")
	check_eq(r.medal, "", "skipped: no medal")
	check_eq(r.coins, CritterPlunge.coins_for(1, 8), "still coins")
	check_eq(CritterPlunge.finish(p, p.lineup, 1, 8, false, true, "lava").medal, "gold", "watched: gold")


## A race counts as a fight (Glow Pass, "Play 4 fights") and for the Plunge
## quests: podium, wins and distinct courses this week.
func test_races_count_for_quests() -> void:
	var path := "user://test_plunge_quests.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var g = GlowState.new(SaveGame.new(path))
	g.record_plunge(1, false, "lava")
	g.record_plunge(3, false, "lava")
	g.record_plunge(2, true, "ice")
	g.record_plunge(6, false, "")
	var day: Dictionary = g.g().quest_day.progress
	var week: Dictionary = g.g().quest_week.progress
	check_eq(int(day.get("plunge_podium", 0)), 2, "podium: 1st and 3rd, not a knockout")
	check_eq(int(week.get("plunge_win", 0)), 1, "one win")
	check_eq(int(week.get("plunge_courses", 0)), 2, "two different courses")
	var ctx := {"bosses": true, "families": ["frost"], "rare": true, "t3": true, "fuse": true, "egg": true, "racer": true}
	var none := ctx.duplicate()
	none.racer = false
	var seen := {}
	for d in 120:
		for q in Quests.roll_day(d, none) + Quests.roll_week(d, none):
			check(not str(q.id) in ["plunge_pod", "w_plunge3", "w_courses5"], "no Plunge quest without a racer")
		for q in Quests.roll_day(d, ctx) + Quests.roll_week(d, ctx):
			seen[q.id] = true
	for id in ["plunge_pod", "w_plunge3", "w_courses5"]:
		check(seen.has(id), "%s rolls for a racer" % id)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
