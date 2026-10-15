## Tunes The Spire's power curve (sim/spire.gd, design/spire.md).
##
## 1. Floor check: on sample floors, a lineup at exactly the floor's power
##    (unaimed, random critters) should win about half the time, bosses too.
## 2. Climbs: sample rosters climb a week's tower with a simple strategy
##    (weakest fresh critters that match the floor's power, 3 Stamina each)
##    and report how high they get.
##
## godot --headless --script res://tools/spire_curve.gd -- --fights=100 --weeks=4
extends SceneTree

const Spire := preload("res://sim/spire.gd")
const Relay := preload("res://sim/relay.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Rng := preload("res://sim/rng.gd")

const STAMINA := 3
## Sample rosters: [label, count, rarity-free power range]. Power is the
## sim/power.gd multiplier (T2 level 15 Common ~ 1.69, T4 level 35 Epic ~ 4.2).
const ROSTERS := [
	["new player (6 critters, T1)", 6, 1.0, 1.35],
	["early (10 critters, T1-T2)", 10, 1.1, 1.9],
	["mid-game (15 critters, T2-T3)", 15, 1.5, 2.8],
	["late (25 critters, T3-T4)", 25, 2.2, 4.4],
	["endgame (35 critters, T4-T5)", 35, 3.5, 7.0],
]


func _init() -> void:
	var fights := 100
	var weeks := 4
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fights="):
			fights = int(arg.get_slice("=", 1))
		elif arg.begins_with("--weeks="):
			weeks = int(arg.get_slice("=", 1))
	print("Floor check: lineup at the floor's own power, unaimed (%d fights per floor)" % fights)
	for n in [1, 4, 5, 9, 10, 14, 15, 20, 25, 30, 40, 50]:
		var wins := 0.0
		for i in fights:
			var spec := Spire.floor_def(i % 7, n)
			var rng := Rng.new(i * 31 + n)
			var picks: Array = []
			for k in spec.lineup:
				picks.append({"id": BallDefs.PLAYABLE[rng.range_int(0, BallDefs.PLAYABLE.size() - 1)], "power": Spire.power_at(n)})
			var cfg := Spire.relay_config(spec, picks)
			cfg.seed = int(rng.next_u32() & 0x7FFFFFFF)
			var r := Relay.new(cfg).run_to_end()
			wins += 1.0 if r.winner == 0 else (0.5 if r.winner == -1 else 0.0)
		print("  floor %2d%s power %.2f: %3.0f%%" % [n, " (boss)" if Spire.is_boss(n) else "", Spire.power_at(n), 100.0 * wins / fights])
	print("")
	print("Climbs: highest floor cleared (%d weeks each)" % weeks)
	for r in ROSTERS:
		var reached: Array = []
		for w in weeks:
			reached.append(_climb(w, _roster(r[1], r[2], r[3], w)))
		print("  %-32s %s" % [r[0], str(reached)])
	quit(0)


func _roster(count: int, lo: float, hi: float, salt: int) -> Array:
	var rng := Rng.new(count * 977 + salt)
	var out: Array = []
	for i in count:
		out.append({"id": BallDefs.PLAYABLE[i % BallDefs.PLAYABLE.size()], "power": lo + (hi - lo) * rng.next_float(), "stamina": STAMINA})
	return out


## Greedy climb: for each floor, send the weakest fresh critters that are at
## least 90% of the floor's power (or the strongest left), retry until out.
func _climb(week: int, roster: Array) -> int:
	var cleared := 0
	for n in range(1, Spire.FLOORS + 1):
		var spec := Spire.floor_def(week, n)
		var won := false
		while not won:
			var fresh := roster.filter(func(c): return c.stamina > 0)
			if fresh.is_empty():
				return cleared
			fresh.sort_custom(func(a, b): return a.power < b.power)
			var need: float = Spire.power_at(n) * 0.9
			var good := fresh.filter(func(c): return c.power >= need)
			var pool: Array = good if good.size() >= spec.lineup else fresh.slice(maxi(0, fresh.size() - spec.lineup))
			var picks := pool.slice(0, spec.lineup)
			var relay := Relay.new(Spire.relay_config(spec, picks))
			relay.run_to_end()
			var came_out := mini(relay.slot[0] + 1, picks.size())
			for i in came_out:
				picks[i].stamina -= 1
			won = relay.winner == 0
		cleared = n
	return cleared
