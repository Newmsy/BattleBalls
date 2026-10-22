## Per-critter rarity check (BALANCE.md rule 5): each critter at T2 against
## every critter one rarity down at T3 and one rarity up at T1, all at equal
## Power with real tiers and rarity potency. A critter far above 50% fights
## like a rarer one (a candidate to move up a rarity), far below like a
## commoner one (move down).
## Usage: godot --headless --script res://tools/rarity_critters.gd -- [--seeds=2] [--shard=1/4] [--only=old_oak,sundae]
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const Power := preload("res://sim/power.gd")


func _init() -> void:
	var seeds := 2
	var shard := 1
	var shards := 1
	var only: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="):
			seeds = int(arg.get_slice("=", 1))
		elif arg.begins_with("--shard="):
			shard = int(arg.get_slice("=", 1).get_slice("/", 0))
			shards = int(arg.get_slice("=", 1).get_slice("/", 1))
		elif arg.begins_with("--only="):
			only = Array(arg.get_slice("=", 1).split(","))
	var by_rarity := {}
	var ids := CritterDb.live_ids()
	for id in ids:
		by_rarity.get_or_add(CritterDb.get_critter(id).rarity, []).append(id)
	for n in ids.size():
		if n % shards != shard - 1 or (not only.is_empty() and not ids[n] in only):
			continue
		var id: String = ids[n]
		var r := Power.RARITIES.find(CritterDb.get_critter(id).rarity)
		var wins := 0.0
		var fights := 0
		for side in [[-1, 3], [1, 1]]:
			var rr: int = r + side[0]
			if rr < 0 or rr >= Power.RARITIES.size():
				continue
			for foe in by_rarity[Power.RARITIES[rr]]:
				for s in seeds:
					for corner in 2:
						var tiers := [2, side[1]]
						var pw := [Power.multiplier(Power.RARITIES[r], 2, 1), Power.multiplier(Power.RARITIES[rr], side[1], 1)]
						var cfg := {"seed": 7000 + s, "angles": [null, null]}
						if corner == 0:
							cfg.merge({"p1": id, "p2": foe, "tiers": tiers, "powers": pw})
						else:
							cfg.merge({"p1": foe, "p2": id, "tiers": [tiers[1], tiers[0]], "powers": [pw[1], pw[0]]})
						var w: int = MatchSim.new(cfg).run_to_end().winner
						if w == corner:
							wins += 1.0
						elif w < 0:
							wins += 0.5
						fights += 1
		print("ROW|%s|%s|%d|%d" % [id, Power.RARITIES[r], roundi(100.0 * wins / fights), fights])
	quit(0)
