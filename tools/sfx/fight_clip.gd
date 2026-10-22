## Headless: runs one fight through the sound router and writes every sound
## it would play, with its time, volume and pitch, as JSON. tools/sfx/mix_clip.py
## turns that into an audio file, to judge a fight's sound without a browser.
## Usage: godot --headless --script res://tools/sfx/fight_clip.gd -- --p1=id --p2=id [--tiers=5,5] [--seed=1] [--secs=20] --out=/abs/path.json
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const Sfx := preload("res://game/audio/sfx.gd")


func _init() -> void:
	var cfg := {"seed": 1, "p1": "vampire", "p2": "laser", "angles": [null, null], "tiers": [5, 5]}
	var out := ""
	var secs := 20.0
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"p1", "p2":
				cfg[kv[0]] = kv[1]
			"seed":
				cfg.seed = int(kv[1])
			"tiers":
				cfg.tiers = Array(kv[1].split(",")).map(func(t): return int(t))
			"secs":
				secs = float(kv[1])
			"out":
				out = kv[1]
	var sfx: Sfx = Sfx.new()
	root.add_child(sfx)
	sfx.mode = "all"
	sfx.record = []
	var sim := MatchSim.new(cfg)
	sfx.on_fight_start(sim)
	while not sim.finished and sim.time() < secs:
		sim.step()
		sfx.consume_events(sim.events, sim)
		sfx._process(MatchSim.DT)
	var cues: Array = sfx.record.map(func(c): return {"file": ProjectSettings.globalize_path(c[1]), "db": c[2], "pitch": c[3], "t": c[4]})
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify({"cues": cues, "length": sim.time(), "winner": sim.winner}))
	f.close()
	print("%d sounds over %.1fs" % [cues.size(), sim.time()])
	sfx.free()
	quit()
