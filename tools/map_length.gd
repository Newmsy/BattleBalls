## Headless fight-length check per map: plays the same seeded fights on every
## playable arena and prints the mean, median and 90th percentile length, how
## many reach overtime (MatchSim.OVERTIME_START) and how many time out. Maps
## whose fights run long against the field are flagged.
## Groups: "std" random pairings at equal power; "big" one of the biggest
## critters against the field; "bigbig" two of them; "br_late", "br_elite"
## and "br_boss" replay Bounce Run fights a greedy bot met on floors 11+
## (big, tanky foes) on every map.
## --strip=cores,motion,obstacles,floors plays each map without those parts, to see what makes it long.
## Usage: godot --headless --script res://tools/map_length.gd -- [--fights=60] [--runs=120] [--maps=id,id] [--shard=k/n]
##        [--groups=std,big] [--strip=cores,motion]
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Arenas := preload("res://sim/arenas.gd")
const BounceRun := preload("res://sim/bounce_run.gd")
const BounceBot := preload("res://tools/bounce_bot.gd")
const Rng := preload("res://sim/rng.gd")

const BIG_RADIUS := 68.0 ## This radius or more counts as a big critter.
const BR_PER_GROUP := 60 ## Bounce Run fights per group replayed on each map.
## A map is flagged when its mean beats the all-map mean of the group by this much.
const FLAG_RATIO := 1.3


func _init() -> void:
	var fights := 60
	var runs := 120
	var maps: Array = Arenas.PLAYABLE.duplicate()
	var shard := [1, 1]
	var only_groups: Array = []
	var strip: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fights="):
			fights = int(arg.split("=")[1])
		elif arg.begins_with("--runs="):
			runs = int(arg.split("=")[1])
		elif arg.begins_with("--maps="):
			maps = Array(arg.split("=")[1].split(","))
		elif arg.begins_with("--shard="):
			var p: PackedStringArray = arg.split("=")[1].split("/")
			shard = [int(p[0]), int(p[1])]
		elif arg.begins_with("--groups="):
			only_groups = Array(arg.split("=")[1].split(","))
		elif arg.begins_with("--strip="):
			strip = Array(arg.split("=")[1].split(","))
	var groups := _groups(fights, runs if only_groups.is_empty() or only_groups.any(func(g): return g.begins_with("br")) else 0)
	for g in groups.keys():
		if not only_groups.is_empty() and not g in only_groups:
			groups.erase(g)
	var mine: Array = []
	for i in maps.size():
		if i % shard[1] == shard[0] - 1:
			mine.append(maps[i])
	# One line per map and group: id group n mean median p90 overtime timeouts
	for id in mine:
		var def := _stripped(Arenas.get_def(id), strip)
		for g in groups:
			var times: Array = []
			var ot := 0
			var outs := 0
			for base in groups[g]:
				var cfg: Dictionary = base.duplicate(true)
				cfg.arena = id
				if not strip.is_empty():
					cfg.arena_def = def
				var s: Dictionary = MatchSim.new(cfg).run_to_end()
				times.append(s.time)
				if s.time > MatchSim.OVERTIME_START:
					ot += 1
				if s.reason == "time":
					outs += 1
			times.sort()
			var mean: float = times.reduce(func(a, t): return a + t, 0.0) / times.size()
			print("ROW %s %s %d %.2f %.2f %.2f %d %d" % [id, g, times.size(), mean, times[times.size() / 2], times[int(times.size() * 0.9)], ot, outs])
	quit()


## The fights each group plays, as MatchSim configs without an arena.
func _groups(fights: int, runs: int) -> Dictionary:
	var field: Array = BallDefs.PLAYABLE
	var big: Array = field.filter(func(c): return float(BallDefs.DEFS[c].radius) >= BIG_RADIUS)
	var rng := Rng.new(4242)
	var out := {"std": [], "big": [], "bigbig": [], "br_late": [], "br_elite": [], "br_boss": []}
	for s in fights:
		out.std.append({"seed": 1000 + s, "p1": field[rng.range_int(0, field.size() - 1)], "p2": field[rng.range_int(0, field.size() - 1)], "tiers": [3, 3], "tie_to": 0})
		out.big.append({"seed": 2000 + s, "p1": big[rng.range_int(0, big.size() - 1)], "p2": field[rng.range_int(0, field.size() - 1)], "tiers": [3, 3], "tie_to": 0})
		out.bigbig.append({"seed": 3000 + s, "p1": big[rng.range_int(0, big.size() - 1)], "p2": big[rng.range_int(0, big.size() - 1)], "tiers": [3, 3], "tie_to": 0})
	# Bounce Run: the configs a greedy bot fought on floors 11+, aims fixed.
	for r in runs:
		var brng := Rng.new(r * 31 + 7)
		var setup := BounceRun.generate(1 + r % 60)
		var run := BounceBot.greedy_start(setup, brng)
		var guard := 0
		while not run.over and guard < 400:
			guard += 1
			if BounceRun.phase(setup, run) == "fight":
				var row: int = BounceRun.node(setup, run.at).row
				var kind: String = BounceRun.foe(setup, run).kind
				var g := "br_boss" if kind == "boss" else ("br_elite" if kind == "elite" else "br_late")
				if row >= 10 and out[g].size() < BR_PER_GROUP:
					var slot: int = BounceBot._best(BounceRun.living(run), func(s): return BounceBot.critter_rank(run.critters[s]))
					out[g].append(BounceRun.fight_config(setup, run, slot, -450))
			BounceBot.greedy_step(setup, run, brng)
	for g in out.keys():
		if out[g].is_empty():
			out.erase(g)
	return out


## `def` without the parts named in `strip`.
static func _stripped(def: Dictionary, strip: Array) -> Dictionary:
	var out := def.duplicate(true)
	if "cores" in strip:
		out.erase("cores")
	if "floors" in strip:
		out.erase("floors")
	if "obstacles" in strip:
		out.obstacles = []
	if "motion" in strip:
		for o in out.get("obstacles", []):
			o.erase("slide")
			o.erase("orbit")
	return out
