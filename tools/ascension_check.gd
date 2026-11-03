## Ascension strength probe (not in CI): each critter at T5 with Ascension
## A1-A5 against its own plain T5 twin, mirrored sides. Prints the win rate
## per level over the roster sample.
##   godot --headless --script res://tools/ascension_check.gd -- [--fights=20] [--every=4]
extends SceneTree

const Boons := preload("res://sim/boons.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const CritterDb := preload("res://sim/critter_db.gd")


func _init() -> void:
	var fights := 20
	var every := 4
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fights="):
			fights = int(arg.get_slice("=", 1))
		if arg.begins_with("--every="):
			every = int(arg.get_slice("=", 1))
	var ids: Array = CritterDb.live_ids().filter(func(id): return Boons.for_critter(id) != "")
	var sample: Array = []
	for i in ids.size():
		if i % every == 0:
			sample.append(ids[i])
	for lv in range(1, Boons.ASCEND_MAX + 1):
		var wins := 0.0
		var n := 0
		for cid in sample:
			for f in fights:
				var side := f % 2
				var asc := [0, 0]
				asc[side] = lv
				var sim := MatchSim.new({"seed": 1000 + f, "p1": cid, "p2": cid, "tiers": [5, 5], "ascend": asc})
				while not sim.finished and sim.tick < 30000:
					sim.step()
				var w: int = sim.summary().winner
				wins += 1.0 if w == side else (0.5 if w < 0 else 0.0)
				n += 1
		print("A%d: %.0f%% wins vs plain T5 twin (%d critters, %d fights)" % [lv, 100.0 * wins / n, sample.size(), n])
	quit(0)
