## Talent node probe: how much each faction talent is worth on its own, and
## whether a full tree still loses to one tier up (BALANCE.md: tier > talents).
## Usage: godot --headless --script res://tools/talent_nodes.gd -- [--fights=24] [--per=4] [--only=<faction>] [--mode=nodes|tier]
##   nodes  each node at max rank (a capstone with its partner node maxed) on
##          a T5 critter vs the same critter bare
##   tier   T4 with the suggested tree vs T5 bare, and T4 bare vs T5 bare
##   equiv  the suggested tree vs bare twins with +10/20/30/40% power: where
##          it crosses 50% is what the tree is worth (Talents.POINT_POWER)
## Prints a Markdown table.
extends SceneTree

const Talents := preload("res://sim/talents.gd")
const Lineup := preload("res://sim/lineup.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")

## Capstone -> the node it doubles, so the capstone is measured on top of it.
const PARTNER := {"wildfire": "kindling", "deep_freeze": "shatter", "overgrowth": "photosynth", "riptide": "undertow",
	"overdrive": "overclock", "supernova_cap": "", "candy_coat": "sugar_shell", "jackpot_cap": "bouncy", "undying": "", "seed_pod": ""}


func _init() -> void:
	var fights := 24
	var per := 4
	var only := ""
	var mode := "nodes"
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		if kv.size() == 2:
			match kv[0]:
				"fights": fights = int(kv[1])
				"per": per = int(kv[1])
				"only": only = kv[1]
				"mode": mode = kv[1]
	for f in Talents.FACTIONS:
		if only != "" and f != only:
			continue
		var ids: Array = Talents.MEMBERS[f].filter(func(id): return id in BallDefs.PLAYABLE).slice(0, per)
		if mode == "equiv":
			var cells := []
			for k in [1.1, 1.2, 1.3, 1.4]:
				cells.append("%d%%" % roundi(100 * _rate(ids, fights, func(id): return Lineup.make(id, 5, 1, [], Talents.suggested(f)), func(id): return Lineup.make(id, 5, 1), {}, k)))
			print("| %s | %s |" % [Talents.NAMES[f], " | ".join(cells)])
			continue
		if mode == "tier":
			var full := _rate(ids, fights, func(id): return Lineup.make(id, 4, 1, [], Talents.suggested(f)), func(id): return Lineup.make(id, 5, 1))
			var bare := _rate(ids, fights, func(id): return Lineup.make(id, 4, 1), func(id): return Lineup.make(id, 5, 1))
			print("| %s | T4 + tree vs T5: %d%% | T4 bare vs T5: %d%% |" % [Talents.NAMES[f], roundi(100 * full), roundi(100 * bare)])
			continue
		print("| %s | (bare control) | - | %d%% |" % [Talents.NAMES[f], roundi(100 * _rate(ids, fights, func(id): return Lineup.make(id, 5, 1), func(id): return Lineup.make(id, 5, 1)))])
		for n in Talents.tree(f):
			var picks := {n.id: n.max}
			if PARTNER.get(n.id, "") != "":
				picks[PARTNER[n.id]] = 3
			var r := _rate(ids, fights, func(id): return Lineup.make(id, 5, 1), func(id): return Lineup.make(id, 5, 1), Talents.effects(f, picks))
			print("| %s | %s | %d | %d%% |" % [Talents.NAMES[f], n.name + (" (+%s)" % PARTNER[n.id] if PARTNER.get(n.id, "") != "" else ""), n.row, roundi(100 * r)])
	quit(0)


## `tal` (nodes mode) is set straight on my ball after setup, skipping the
## row gates, so one node can be measured alone.
## `boost` multiplies the other side's power.
func _rate(ids: Array, fights: int, mine: Callable, theirs: Callable, tal := {}, boost := 1.0) -> float:
	var wins := 0.0
	var n := 0
	for id in ids:
		for s in fights:
			var me := s % 2
			var cfg := {"seed": 1000 + s, "angles": [null, null], "family_edges": false}
			Lineup.apply(cfg, me, mine.call(id))
			Lineup.apply(cfg, 1 - me, theirs.call(id))
			cfg.powers[1 - me] *= boost
			var sim := MatchSim.new(cfg)
			if not tal.is_empty():
				sim.balls[me].tal = tal
				Talents.setup(sim, sim.balls[me])
			sim.run_to_end()
			n += 1
			if sim.winner == me:
				wins += 1.0
			elif sim.winner == -1:
				wins += 0.5
	return wins / maxf(1.0, n)
