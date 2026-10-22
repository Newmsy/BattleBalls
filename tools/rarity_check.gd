## Rarity vs tier check (BALANCE.md rule 5): one rarity step is worth a
## whole tier, so pairs of equal Power (sim/power.gd) should split about 50/50, with
## each side at its real tier (ability upgrades and potency included), level 1.
## Usage: godot --headless --script res://tools/rarity_check.gd -- [--pairs=150] [--case=L1-C3]
##   Cases are <rarity letter><tier>-<rarity letter><tier>, e.g. L1-E2, L1-C5.
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const Power := preload("res://sim/power.gd")

const LETTERS := {"C": "common", "U": "uncommon", "R": "rare", "E": "epic", "L": "legendary"}
const CASES := ["U1-C2", "R1-U2", "E1-R2", "L1-E2", "R1-C3", "E1-U3", "L1-R3", "E1-C4", "L1-U4", "L1-C5", "L2-R4", "L3-E4", "R1-R1"]


func _init() -> void:
	var pairs := 150
	var cases: Array = CASES
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pairs="):
			pairs = int(arg.get_slice("=", 1))
		elif arg.begins_with("--case="):
			cases = arg.get_slice("=", 1).split(",")
	var by_rarity := {}
	for id in CritterDb.live_ids():
		by_rarity.get_or_add(CritterDb.get_critter(id).rarity, []).append(id)
	print("| Case | power A / B | A wins | fights |")
	print("|---|---|---|---|")
	for c in cases:
		var a_side: String = c.get_slice("-", 0)
		var b_side: String = c.get_slice("-", 1)
		var ra: String = LETTERS[a_side[0]]
		var rb: String = LETTERS[b_side[0]]
		var ta := int(a_side.substr(1))
		var tb := int(b_side.substr(1))
		var pa := Power.multiplier(ra, ta, 1)
		var pb := Power.multiplier(rb, tb, 1)
		var wins := 0.0
		var n := 0
		var pool_a: Array = by_rarity[ra]
		var pool_b: Array = by_rarity[rb]
		for i in pairs:
			var a: String = pool_a[(i * 7) % pool_a.size()]
			var b: String = pool_b[(i * 13 + i / pool_a.size()) % pool_b.size()]
			for corner in 2:
				var cfg := {"seed": 5000 + i, "angles": [null, null], "family_edges": false}
				if corner == 0:
					cfg.merge({"p1": a, "p2": b, "tiers": [ta, tb], "powers": [pa, pb]})
				else:
					cfg.merge({"p1": b, "p2": a, "tiers": [tb, ta], "powers": [pb, pa]})
				var s := MatchSim.new(cfg).run_to_end()
				var a_index := 0 if corner == 0 else 1
				if s.winner == a_index:
					wins += 1.0
				elif s.winner < 0:
					wins += 0.5
				n += 1
		print("| %s | %.2f / %.2f | %d%% | %d |" % [c, pa, pb, roundi(100.0 * wins / n), n])
	quit(0)
