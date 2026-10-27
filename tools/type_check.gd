## Family edges check (design/type-advantage.md): how often the side with the
## edge wins, on same-rarity pairs at real tiers, with edges on and off, and
## when the foe is one tier up. Targets (Newms 2026-10-22 "Bold"): very good
## ~72%, and the tier-up foe still wins ~65-70% into its very-bad
## (2026-10-22: 71%, tier-up foe 72%). The chart has no "good" level now, so that row is skipped.
## Usage: godot --headless --script res://tools/type_check.gd -- [--pairs=300]
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const Families := preload("res://sim/families.gd")
const Power := preload("res://sim/power.gd")


func _init() -> void:
	var pairs := 300
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pairs="):
			pairs = int(arg.get_slice("=", 1))
	var by_edge := {1: [], 2: []}
	var ids := CritterDb.live_ids()
	for a in ids:
		for b in ids:
			var e := Families.edge(a, b)
			if e > 0 and CritterDb.get_critter(a).rarity == CritterDb.get_critter(b).rarity:
				by_edge[e].append([a, b])
	print("| Edge | foe tier | edges on | edges off | fights |")
	print("|---|---|---|---|---|")
	for e in [2, 1]:
		if by_edge[e].is_empty():
			continue
		for foe_tier in [1, 2]:
			var on := _run(by_edge[e], pairs, foe_tier, true)
			var off := _run(by_edge[e], pairs, foe_tier, false)
			print("| %s | T%d | %d%% | %d%% | %d |" % ["very good" if e == 2 else "good", foe_tier, roundi(on), roundi(off), pairs * 2])
	quit(0)


## Win % for the side with the edge (a T1), over both corners.
func _run(pool: Array, pairs: int, foe_tier: int, edges: bool) -> float:
	var wins := 0.0
	for i in pairs:
		var pair: Array = pool[(i * 37) % pool.size()]
		var rarity: String = CritterDb.get_critter(pair[0]).rarity
		var pa := Power.multiplier(rarity, 1, 1)
		var pb := Power.multiplier(rarity, foe_tier, 1)
		for corner in 2:
			var cfg := {"seed": 9000 + i, "angles": [null, null], "family_edges": edges}
			if corner == 0:
				cfg.merge({"p1": pair[0], "p2": pair[1], "tiers": [1, foe_tier], "powers": [pa, pb]})
			else:
				cfg.merge({"p1": pair[1], "p2": pair[0], "tiers": [foe_tier, 1], "powers": [pb, pa]})
			var w: int = MatchSim.new(cfg).run_to_end().winner
			if w == corner:
				wins += 1.0
			elif w < 0:
				wins += 0.5
	return 100.0 * wins / (pairs * 2)
