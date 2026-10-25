## Headless relic check for Bounce Run: every relic (sim/relics.gd), held by
## a critter against the same critter without it, over a fixed spread of
## playable critters, each seed fought from both corners. A relic should be
## worth about +10-15% power: at equal power it wins RELIC_MIN to RELIC_MAX
## (the sim amplifies edges: +14% HP alone wins ~63%). --power=1.12 gives the
## side without the relic that much power instead, so ~50% there is on target.
## Not in CI (balance checks are run on demand).
## Usage: godot --headless --script res://tools/relic_check.gd -- [--fights=4] [--critters=30] [--power=1.0] [--only=<id>] [--tier=1]
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Relics := preload("res://sim/relics.gd")

const RELIC_MIN := 0.56
const RELIC_MAX := 0.66


func _init() -> void:
	var fights := 4
	var critters := 30
	var power := 1.0
	var only := ""
	var tier := 1
	for arg in OS.get_cmdline_user_args():
		var kv: PackedStringArray = arg.trim_prefix("--").split("=")
		match kv[0]:
			"fights": fights = int(kv[1])
			"critters": critters = int(kv[1])
			"power": power = float(kv[1])
			"only": only = kv[1]
			"tier": tier = int(kv[1])
	var field: Array = []
	var playable: Array = BallDefs.PLAYABLE
	for i in mini(critters, playable.size()):
		field.append(playable[i * playable.size() / mini(critters, playable.size())])
	var lines: Array[String] = ["### Bounce Run relics vs the same critter without (power %.2f, T%d, %d critters x %d seeds x 2 corners)" % [power, tier, field.size(), fights], "", "| Relic | Win rate | Flag |", "|---|---|---|"]
	for id in Relics.IDS:
		if only != "" and not id in only.split(","):
			continue
		var score := 0.0
		var n := 0
		for c in field:
			for s in fights:
				for side in 2:
					var held := [[id], []] if side == 0 else [[], [id]]
					var cfg := {"seed": 500 + s * 7, "p1": c, "p2": c, "relics": held, "family_edges": false,
						"powers": [1.0, power] if side == 0 else [power, 1.0], "tiers": [tier, tier]}
					var w: int = MatchSim.new(cfg).run_to_end().winner
					score += 0.5 if w == -1 else (1.0 if w == side else 0.0)
					n += 1
		var rate := score / maxf(1.0, n)
		var flag := ""
		if power == 1.0 and (rate < RELIC_MIN or rate > RELIC_MAX):
			flag = "outside %d-%d%%" % [roundi(RELIC_MIN * 100), roundi(RELIC_MAX * 100)]
		lines.append("| %s | %.1f%% | %s |" % [Relics.name_of(id), rate * 100.0, flag])
	print("\n".join(lines))
	quit(0)
