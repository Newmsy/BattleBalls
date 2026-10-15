## Per-hit damage rolls (spread and crits), backstabs and gear stat lines.
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Gear := preload("res://sim/gear.gd")
const BallDefs := preload("res://sim/ball_defs.gd")


func _sim(cfg := {}) -> MatchSim:
	var base := {"seed": 5, "p1": "plain", "p2": "plain", "angles": [null, null]}
	base.merge(cfg, true)
	return MatchSim.new(base)


## Two balls meeting head on along x: one contact hit each.
func _head_on(sim: MatchSim) -> void:
	var a := sim.balls[0]
	var b := sim.balls[1]
	a.pos = Vector2(400, 500)
	b.pos = Vector2(400 + a.radius + b.radius - 1.0, 500)
	a.vel = Vector2(a.speed, 0)
	b.vel = Vector2(-b.speed, 0)


func _damage_events(sim: MatchSim) -> Array:
	return sim.events.filter(func(e): return e.type == "damage")


func test_spread_stays_within_ten_percent_and_varies() -> void:
	var dmg: float = BallDefs.get_def("plain").contact_damage
	var low := INF
	var high := -INF
	for seed_value in 200:
		var sim := _sim({"seed": seed_value})
		for b in sim.balls:
			b.crit_chance = 0.0
		_head_on(sim)
		sim.step()
		for e in _damage_events(sim):
			check(not e.crit, "no crits at 0% crit chance")
			low = minf(low, e.amount)
			high = maxf(high, e.amount)
	check(low >= dmg * 0.9 - 0.001 and high <= dmg * 1.1 + 0.001, "hits stay within +-10%%: %.3f-%.3f" % [low, high])
	check(low < dmg * 0.95 and high > dmg * 1.05, "hits use the whole spread: %.3f-%.3f" % [low, high])


func test_crit_multiplies_damage_and_is_flagged() -> void:
	var dmg: float = BallDefs.get_def("plain").contact_damage
	var sim := _sim()
	sim.balls[0].crit_chance = 1.0
	sim.balls[1].crit_chance = 0.0
	_head_on(sim)
	sim.step()
	var hits := _damage_events(sim)
	check_eq(hits.size(), 2, "both balls hit")
	for e in hits:
		check_eq(e.crit, e.source == 0, "only the sure-crit ball crits")
		var expected := dmg * (MatchSim.BASE_CRIT_MULT if e.crit else 1.0)
		check(e.amount >= expected * 0.9 - 0.001 and e.amount <= expected * 1.1 + 0.001, "crit hit %.3f near %.3f" % [e.amount, expected])


func test_base_crit_rate_is_about_five_percent() -> void:
	var hits := 0
	var crits := 0
	for seed_value in 150:
		var sim := _sim({"seed": seed_value, "p1": "vampire", "p2": "laser"})
		while not sim.finished:
			sim.step()
			for e in _damage_events(sim):
				hits += 1
				crits += 1 if e.crit else 0
	var rate := float(crits) / hits
	check(rate > 0.035 and rate < 0.065, "crit rate %.3f over %d hits" % [rate, hits])


func test_rolls_replay_from_the_seed() -> void:
	var runs: Array = []
	for i in 2:
		var sim := _sim({"seed": 77, "p1": "vampire", "p2": "magnet"})
		var amounts: Array[float] = []
		while not sim.finished:
			sim.step()
			for e in _damage_events(sim):
				amounts.append(e.amount)
		runs.append(amounts)
	check_eq(runs[0], runs[1], "same seed, same hits")


func test_backstab_from_behind_hits_harder() -> void:
	var dmg: float = BallDefs.get_def("plain").contact_damage
	var sim := _sim({"damage_rolls": false})
	var a := sim.balls[0]
	var b := sim.balls[1]
	# a catches b up from behind, both heading right-ish.
	a.pos = Vector2(400, 500)
	b.pos = Vector2(400 + a.radius + b.radius - 1.0, 500)
	a.vel = Vector2(a.speed, 0)
	b.vel = Vector2(b.speed * 0.5, b.speed * 0.2)
	sim.step()
	var hits := _damage_events(sim)
	var on_b: Dictionary = hits.filter(func(e): return e.target == 1)[0]
	var on_a: Dictionary = hits.filter(func(e): return e.target == 0)[0]
	check(on_b.backstab, "the chaser's hit is a backstab")
	check(not on_a.backstab, "the fleeing ball's hit isn't")
	check_near(on_b.amount, dmg * sim._impact_scale(1.0) * MatchSim.BACKSTAB_MULT, 0.001, "backstab damage")


func test_head_on_and_side_hits_are_not_backstabs() -> void:
	var sim := _sim({"damage_rolls": false})
	_head_on(sim)
	sim.step()
	check(_damage_events(sim).all(func(e): return not e.backstab), "head on is no backstab")
	var n := Vector2.RIGHT
	check_eq(MatchSim._backstabber(Vector2(400, 0), Vector2(0, 400), n), -1, "crossing at 90 degrees")
	check_eq(MatchSim._backstabber(Vector2(400, 0), Vector2(300, 250), n), 0, "within 45 degrees, a behind")
	check_eq(MatchSim._backstabber(Vector2(-400, 0), Vector2(-300, 100), n), 1, "b catches a from behind")


func test_gear_totals_sum_clamp_and_drop_unknown_lines() -> void:
	var pieces := [
		{"slot": "Shell", "rarity": "legendary", "stats": {"defense": 0.2, "health": 0.05}},
		{"slot": "Core", "rarity": "legendary", "stats": {"defense": 0.2, "crit_chance": 0.1, "laser_eyes": 9.0}},
	]
	var t := Gear.totals(pieces)
	check_near(t.defense, Gear.LINES.defense.max, 0.0001, "defense clamps to its cap")
	check_near(t.health, 0.05, 0.0001, "health sums")
	check(not t.has("laser_eyes"), "unknown lines are dropped")
	check_eq(Gear.totals(null), {}, "no gear")
	check_eq(Gear.totals([]), {}, "empty list")
	check_near(Gear.totals({"attack": 0.1}).attack, 0.1, 0.0001, "totals pass through")


func test_gear_reaches_the_ball() -> void:
	var kit := {"attack": 0.1, "defense": 0.2, "health": 0.1, "speed": 0.1, "crit_chance": 0.1, "crit_damage": 0.5, "cooldown": 0.25}
	var sim := _sim({"p1": "laser", "gear": [kit, null], "damage_rolls": false})
	var g := sim.balls[0]
	var ldef := BallDefs.get_def("laser")
	check_near(g.max_hp, ldef.hp * 1.1, 0.001, "health")
	check_near(g.speed, ldef.speed * 1.1, 0.001, "speed")
	check_near(g.def.beam_hit_cooldown, ldef.beam_hit_cooldown / 1.25, 0.0001, "cooldown speed")
	check_near(g.crit_chance, MatchSim.BASE_CRIT_CHANCE + 0.1, 0.0001, "crit chance")
	check_near(g.crit_mult, MatchSim.BASE_CRIT_MULT + 0.5, 0.0001, "crit damage")
	check_eq(sim.balls[1].crit_chance, MatchSim.BASE_CRIT_CHANCE, "bare ball keeps base crit")


func test_attack_and_defense_scale_hits() -> void:
	var dmg: float = BallDefs.get_def("plain").contact_damage
	var sim := _sim({"gear": [{"attack": 0.2}, {"defense": 0.25}], "damage_rolls": false})
	_head_on(sim)
	sim.step()
	for e in _damage_events(sim):
		var expected := dmg * 1.2 * 0.75 if e.source == 0 else dmg
		check_near(e.amount, expected, 0.001, "hit by ball %d" % e.source)


func test_relay_passes_each_balls_gear() -> void:
	const Relay := preload("res://sim/relay.gd")
	var relay := Relay.new({"seed": 3, "sides": [["vampire", "laser"], ["magnet"]], "gear": [[{"health": 0.1}], []]})
	var cfg := relay.leg_config()
	check_eq(cfg.gear, [{"health": 0.1}, null], "first leg gear")
	var sim := MatchSim.new(cfg)
	check_near(sim.balls[0].max_hp, BallDefs.get_def("vampire").hp * 1.1, 0.001, "gear reaches the leg")
