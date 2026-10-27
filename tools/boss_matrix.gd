## Every critter against every boss (design/bosses.md): one CSV row per
## critter, boss and level with the win rate, the boss HP knocked off and the
## average fight time. Feed it to a spreadsheet or a script to find critters
## that trivialise a boss or can't touch it, and levels that jump.
##   --mode=kit   (default) every critter at the same footing: T5 at --you
##                power, rarity's ability potency off, so only the kit differs.
##   --mode=even  T5 at --you power with rarity's ability potency on, like
##                tools/boss_difficulty.gd (what the level curves aim at).
##   --mode=real  every critter as a maxed slot of its own rarity (T5, level 50).
##   --talents    adds the critter's faction tree (Talents.suggested).
##   --mult=1.4   multiplies the levelled bosses' power (for retuning a curve).
##   --levels=9   comma list of 1-based levels for the levelled bosses
##                (Piñata matches your power, The Glitch has one level).
## godot --headless --script res://tools/boss_matrix.gd -- [--boss=anvil_king] [--fights=16] [--you=7.7] [--shard=1/4]
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Bosses := preload("res://sim/bosses.gd")
const Lineup := preload("res://sim/lineup.gd")
const Talents := preload("res://sim/talents.gd")

const RULES := {
	"anvil_king": "res://meta/gear_vault.gd",
	"brood_queen": "res://meta/brood_nest.gd",
	"totem_of_nine": "res://meta/totem_shrine.gd",
	"prism_wyrm": "res://meta/wyrm_rift.gd",
	"pinata_titan": "res://meta/pinata_party.gd",
	"the_glitch": "res://meta/glitch_core.gd",
}


func _init() -> void:
	var bosses: Array = RULES.keys()
	var mode := "kit"
	var you := 7.7
	var fights := 16
	var talents := false
	var levels := [9]
	var shard := [1, 1]
	var mult := 1.0 ## --mult=1.4 tries a level table 40% stronger (to retune a curve).
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		match kv[0]:
			"boss": bosses = kv[1].split(",")
			"mode": mode = kv[1]
			"you": you = float(kv[1])
			"fights": fights = int(kv[1])
			"talents": talents = true
			"levels": levels = Array(kv[1].split(",")).map(func(s): return int(s))
			"mult": mult = float(kv[1])
			"shard": shard = Array(kv[1].split("/")).map(func(s): return int(s))
	var ids: Array = []
	for i in BallDefs.PLAYABLE.size():
		if i % shard[1] == shard[0] - 1:
			ids.append(BallDefs.PLAYABLE[i])
	for boss in bosses:
		var table: Array = load(RULES[boss]).DIFFICULTIES
		var lv: Array = levels if table.size() > 1 else [1]
		for level in lv:
			for id in ids:
				var slot := Lineup.make(id, 5, 50, [], Talents.suggested(Talents.faction_of(id)) if talents else {})
				var w := 0.0
				var dealt := 0.0
				var secs := 0.0
				for k in fights:
					var cfg := {"seed": 1000 + k * 7919, "p2": boss, "arena": Bosses.DEFS[boss].arena,
						"angles": [null, null], "tiers": [1, 1], "powers": [1.0, 1.0]}
					Lineup.apply(cfg, 0, slot)
					if mode != "real":
						cfg.powers[0] = you
						cfg.rarity_potency = mode == "even"
					var pinata: float = cfg.powers[0] if mode != "real" else Lineup.rating(slot) / 1000.0 ## Your Power Rating.
					cfg.powers[1] = pinata if boss == "pinata_titan" else float(table[level - 1].power) * mult
					var sim := MatchSim.new(cfg)
					var s := sim.run_to_end()
					dealt += 1.0 - maxf(0.0, sim.balls[1].hp) / sim.balls[1].max_hp
					w += 1.0 if s.winner == 0 else (0.5 if s.winner == -1 else 0.0)
					secs += s.time
				print("ROW,%s,%s,%s,%d,%s,%d,%.3f,%.3f,%.1f" % [mode, boss, id, level, BallDefs.DEFS[id].get("rarity", ""),
					1 if talents else 0, w / fights, dealt / fights, secs / fights])
	quit(0)
