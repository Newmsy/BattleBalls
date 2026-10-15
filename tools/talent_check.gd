## Faction talent check: each faction's suggested 30-point tree (T5, so every
## row is active) on its critters against the same critter bare, from random
## launch angles. A full tree is sized at about +10% power (design/talents.md
## section 6), so every faction should win clearly but well under the 70%+ a
## whole tier gives, and the factions should land near each other.
## Usage: godot --headless --script res://tools/talent_check.gd -- [--fights=40] [--per=4] [--only=<faction>]
##   --fights=N  fights per critter (seeds 1..N, players swap corners every other fight)
##   --per=N     critters per faction (the first N in each faction's list)
## Prints a Markdown table and exits 1 if a faction leaves BAND.
extends SceneTree

const Talents := preload("res://sim/talents.gd")
const Lineup := preload("res://sim/lineup.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")

## Win share band per faction (loose: Newms 2026-10-15 "we can be a bit unbalanced").
const BAND := [0.55, 0.80]


func _init() -> void:
	var fights := 40
	var per := 4
	var only := ""
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		if kv.size() == 2:
			match kv[0]:
				"fights": fights = int(kv[1])
				"per": per = int(kv[1])
				"only": only = kv[1]
	var bad := 0
	print("| Faction | Critters | Full tree win % | Draws |")
	print("|---|---|---|---|")
	for f in Talents.FACTIONS:
		if only != "" and f != only:
			continue
		var ids: Array = Talents.MEMBERS[f].filter(func(id): return id in BallDefs.PLAYABLE).slice(0, per)
		var wins := 0.0
		var draws := 0
		var n := 0
		for id in ids:
			for s in fights:
				var me := s % 2
				var cfg := {"seed": 1000 + s, "angles": [null, null]}
				Lineup.apply(cfg, me, Lineup.make(id, 5, 1, [], Talents.suggested(f)))
				Lineup.apply(cfg, 1 - me, Lineup.make(id, 5, 1))
				var sim := MatchSim.new(cfg)
				sim.run_to_end()
				n += 1
				if sim.winner == me:
					wins += 1.0
				elif sim.winner == -1:
					wins += 0.5
					draws += 1
		var rate := wins / maxf(1.0, n)
		var ok := rate >= BAND[0] and rate <= BAND[1]
		if not ok:
			bad += 1
		print("| %s | %s | %d%%%s | %d |" % [Talents.NAMES[f], ", ".join(ids), roundi(100.0 * rate), "" if ok else " (outside %d-%d%%)" % [roundi(100 * BAND[0]), roundi(100 * BAND[1])], draws])
	quit(1 if bad > 0 else 0)
