extends "res://tests/test_case.gd"

const Royale := preload("res://sim/royale.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Rng := preload("res://sim/rng.gd")
const RoyaleScene := preload("res://game/royale.gd")

## FFA balance sample: every critter's win share per entry must stay under
## 20% at equal power (fair is 12.5%), and none may be starved under 5%.
const BALANCE_FIGHTS := 240
const MAX_SHARE := 0.20
const MIN_SHARE := 0.05


func _cfg(seed_value: int, angles: Array = []) -> Dictionary:
	return {"seed": seed_value, "critters": RoyaleScene.lineup_for("laser", seed_value), "angles": angles}


func test_royale_is_deterministic() -> void:
	for s in [1, 7, 99]:
		check_eq(Royale.new(_cfg(s)).run_to_end(), Royale.new(_cfg(s)).run_to_end(), "seed %d" % s)


func test_replays_from_seed_and_launch_angles() -> void:
	var first := Royale.new(_cfg(5, [-300]))
	var expected := first.run_to_end()
	var again := Royale.new(_cfg(5, first.launch_angles.duplicate()))
	check_eq(again.run_to_end(), expected, "same fight from the recorded angles")
	check_eq(first.launch_angles[0], -300, "your aim is used")


func test_seats_ring_the_centre_and_aim_at_it() -> void:
	var sim := Royale.new(_cfg(3))
	check_eq(sim.balls.size(), 8, "eight balls")
	for i in 8:
		var seat := Royale.seat(i)
		check_near(seat.distance_to(Vector2(500, 500)), Royale.SEAT_RADIUS, 0.01, "seat %d on the ring" % i)
		var to_centre := (Vector2(500, 500) - seat).angle()
		check_near(deg_to_rad(Royale.aim_at_centre(i) / 10.0), to_centre, 0.002, "seat %d aims at the centre" % i)
		for j in range(i + 1, 8):
			check(seat.distance_to(Royale.seat(j)) > sim.balls[i].radius + sim.balls[j].radius + 40.0, "seats %d and %d apart" % [i, j])
	check(sim.balls[0].pos.x < 500 and sim.balls[0].pos.y > 500, "you start bottom left")


func test_placings_kos_and_end() -> void:
	for s in 12:
		var sim := Royale.new(_cfg(s))
		var kos_seen := 0
		while not sim.finished:
			sim.step()
			for e in sim.events:
				if e.type == "ko":
					kos_seen += 1
					check_eq(sim.place_of(e.ball), e.place, "KO event carries the place")
		var result := sim.summary()
		var sorted: Array = result.placings.duplicate()
		sorted.sort()
		check_eq(sorted, [0, 1, 2, 3, 4, 5, 6, 7], "seed %d: everyone placed once" % s)
		check_eq(result.winner, result.placings[0], "winner places first")
		check(sim.time() <= Royale.ROYALE_TIME_LIMIT + 0.001, "ends by the time limit")
		var credited := 0
		for k in sim.kos:
			credited += k
		check_eq(credited, kos_seen, "seed %d: every KO credited" % s)
		for i in 8:
			check(sim.ko_by[i] != i, "no self KOs")


func test_arena_shrinks_early() -> void:
	var sim := Royale.new(_cfg(4))
	sim.tick = int(Royale.ROYALE_SHRINK_START * Royale.TICK_RATE) + 120
	sim.step()
	check(sim.in_overtime(), "shrink has started")
	check(sim.half_size < Royale.ARENA_SIZE / 2.0, "arena smaller")


func test_lineup_is_yours_plus_seven_from_the_seed() -> void:
	var a := RoyaleScene.lineup_for("vampire", 42)
	check_eq(a, RoyaleScene.lineup_for("vampire", 42), "same seed, same bots")
	check_eq(a.size(), 8, "eight")
	check_eq(a[0], "vampire", "yours first")
	for id in a:
		check(id in BallDefs.PLAYABLE, "%s is playable" % id)
	check_eq(RoyaleScene.ordinal(1), "1st", "1st")
	check_eq(RoyaleScene.ordinal(2), "2nd", "2nd")
	check_eq(RoyaleScene.ordinal(3), "3rd", "3rd")
	check_eq(RoyaleScene.ordinal(8), "8th", "8th")


## Balance: random lineups at equal power; a critter's win share per entry is
## judged on its 95% Wilson interval so sampling noise can't fail CI.
func test_ffa_win_shares_stay_fair() -> void:
	var playable: Array = BallDefs.PLAYABLE.filter(func(id): return id != "plain")
	var entries := {}
	var wins := {}
	for id in playable:
		entries[id] = 0
		wins[id] = 0
	for s in BALANCE_FIGHTS:
		var rng := Rng.new(s * 7919 + 13)
		var lineup := []
		for i in 8:
			lineup.append(playable[rng.range_int(0, playable.size() - 1)])
		var result := Royale.new({"seed": s, "critters": lineup}).run_to_end()
		for id in lineup:
			entries[id] += 1
		wins[lineup[result.winner]] += 1
	for id in playable:
		var n: float = entries[id]
		var p: float = wins[id] / n
		var z := 1.96
		var centre := (p + z * z / (2.0 * n)) / (1.0 + z * z / n)
		var half := z * sqrt(p * (1.0 - p) / n + z * z / (4.0 * n * n)) / (1.0 + z * z / n)
		print("    royale %s: %.1f%% win share per entry (%d entries)" % [id, p * 100.0, n])
		check(centre - half <= MAX_SHARE, "%s wins %.1f%% of its royales, over %d%%" % [id, p * 100.0, int(MAX_SHARE * 100)])
		check(centre + half >= MIN_SHARE, "%s wins %.1f%% of its royales, under %d%%" % [id, p * 100.0, int(MIN_SHARE * 100)])
