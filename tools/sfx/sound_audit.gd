## Headless list of the sounds each critter's fights make, to spot critters
## that only sound generic. For each live critter it runs a T5 mirror match and
## prints the battle sounds heard (after each sound's caps), minus the ones
## every fight has.
## Usage: godot --headless --script res://tools/sfx/sound_audit.gd -- [--only=id,id] [--tier=5] [--events]
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const Sfx := preload("res://game/audio/sfx.gd")

## Heard in nearly every fight, so they say nothing about the critter.
const COMMON := ["hit", "hit_big", "wall", "crit", "backstab", "ko", "ko_final", "heartbeat", "overtime", "ot_tick", "go", "zing", "t5_shine", "dizzy", "shield_tink"]


func _init() -> void:
	var only: Array = []
	var tier := 5
	var verbose := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = Array(a.split("=")[1].split(","))
		elif a == "--events":
			verbose = true
		elif a.begins_with("--tier="):
			tier = int(a.split("=")[1])
	var sfx: Sfx = Sfx.new()
	root.add_child(sfx)
	sfx.mode = "all"
	for id in CritterDb.live_ids():
		if not only.is_empty() and not id in only:
			continue
		var heard := {}
		var kinds := {}
		for seed in 3:
			var sim := MatchSim.new({"seed": 100 + seed, "p1": id, "p2": id, "angles": [null, null], "tiers": [tier, tier]})
			sfx.record = []
			while not sim.finished:
				sim.step()
				sfx.consume_events(sim.events, sim)
				sfx._process(MatchSim.DT)
				for e in sim.events:
					var k: String = e.type
					if k in ["collide", "bounce", "end"]:
						continue
					if e.has("kind"):
						k += ":" + str(e.kind)
					kinds[k] = int(kinds.get(k, 0)) + 1
			for cue in sfx.record:
				var n: String = cue[0]
				if not n in COMMON and not n.begins_with("ouch_") and not n.begins_with("knock_"):
					heard[n] = int(heard.get(n, 0)) + 1
		var names := heard.keys()
		names.sort_custom(func(x, y): return heard[x] > heard[y])
		print("%-12s %s" % [id, ", ".join(names.map(func(n): return "%s x%d" % [n, heard[n]]))])
		if verbose:
			print("    events: %s" % ", ".join(kinds.keys().map(func(k): return "%s x%d" % [k, kinds[k]])))
	sfx.free()
	quit()
