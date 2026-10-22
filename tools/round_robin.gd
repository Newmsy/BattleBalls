## Every live critter against every other at the same tier and level, real
## rarity power and potency (an on-demand audit, not CI).
## --mode=equal: both at --tier. --mode=down: the rarer critter at --tier
## against every critter one rarity down at --tier+1.
## --only=a,b keeps pairings whose first critter is listed (each against the
## field); --same keeps only pairings within one rarity.
## Prints PAIR|a|b|a_wins|fights (draws count half).
## Usage: godot --headless --script res://tools/round_robin.gd -- [--mode=equal] [--tier=3] [--seeds=2] [--shard=1/4] [--only=ids] [--same]
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const Power := preload("res://sim/power.gd")


func _init() -> void:
	var seeds := 2
	var shard := 1
	var shards := 1
	var tier := 3
	var mode := "equal"
	var only: Array = []
	var same := false
	for arg in OS.get_cmdline_user_args():
		var v := arg.get_slice("=", 1)
		if arg.begins_with("--seeds="):
			seeds = int(v)
		elif arg.begins_with("--tier="):
			tier = int(v)
		elif arg.begins_with("--mode="):
			mode = v
		elif arg.begins_with("--only="):
			only = Array(v.split(","))
		elif arg == "--same":
			same = true
		elif arg.begins_with("--shard="):
			shard = int(v.get_slice("/", 0))
			shards = int(v.get_slice("/", 1))
	var ids := CritterDb.live_ids()
	var pairs := []
	for i in ids.size():
		for j in ids.size():
			var ri := Power.RARITIES.find(CritterDb.get_critter(ids[i]).rarity)
			var rj := Power.RARITIES.find(CritterDb.get_critter(ids[j]).rarity)
			if (not only.is_empty() and not ids[i] in only) or (same and ri != rj) or i == j:
				continue
			if mode == "equal" and (j > i or not only.is_empty()):
				pairs.append([ids[i], ids[j], tier, tier])
			elif mode == "down" and rj == ri - 1:
				pairs.append([ids[i], ids[j], tier, tier + 1])
	for n in pairs.size():
		if n % shards != shard - 1:
			continue
		var p: Array = pairs[n]
		var ra: String = CritterDb.get_critter(p[0]).rarity
		var rb: String = CritterDb.get_critter(p[1]).rarity
		var pw := [Power.multiplier(ra, p[2], 1), Power.multiplier(rb, p[3], 1)]
		var wins := 0.0
		var fights := 0
		for s in seeds:
			for corner in 2:
				var cfg := {"seed": 9100 + s, "angles": [null, null]}
				if corner == 0:
					cfg.merge({"p1": p[0], "p2": p[1], "tiers": [p[2], p[3]], "powers": pw})
				else:
					cfg.merge({"p1": p[1], "p2": p[0], "tiers": [p[3], p[2]], "powers": [pw[1], pw[0]]})
				var w: int = MatchSim.new(cfg).run_to_end().winner
				if w == corner:
					wins += 1.0
				elif w < 0:
					wins += 0.5
				fights += 1
		print("PAIR|%s|%s|%s|%d" % [p[0], p[1], wins, fights])
	quit(0)
