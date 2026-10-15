## Headless PvE difficulty check: for every campaign stage, the win rate and
## star spread of reference player balls at a few power levels. Use it to set
## stage powers from real fights rather than guesses (BALANCE.md rule 7).
## Usage: godot --headless --script res://tools/pve_difficulty.gd -- [--fights=50]
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const Zones := preload("res://meta/zones.gd")
const Campaign := preload("res://meta/campaign.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Roster := preload("res://game/ui/roster.gd")

## Player power levels to test (Common, no gear): T1 L1, T2 L1, T2 L10, T3 L10.
const PLAYER_POWERS := [1.0, 1.25, 1.53, 1.91]

var fights := 50


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fights="):
			fights = int(arg.split("=")[1])
	# Reference players: every Common, so no single matchup skews a stage.
	var players: Array = BallDefs.PLAYABLE.filter(func(t): return BallDefs.get_def(t).rarity == "common")
	var lines: Array[String] = []
	for z in Zones.ZONES.size():
		lines.append("### %s: win rate (3-star rate) by player power, %d fights per cell" % [Zones.zone(z).name, fights * players.size()])
		lines.append("")
		var header := "| Stage | Enemy power |"
		for p in PLAYER_POWERS:
			header += " x%.2f |" % p
		lines.append(header)
		lines.append("|---".repeat(PLAYER_POWERS.size() + 2) + "|")
		for s in Zones.zone(z).stages.size():
			var st := Zones.stage(z, s)
			var row := "| %s %s | %d |" % [Zones.stage_key(z, s), st.get("name", Roster.get_critter(st.enemy).name), Campaign.enemy_rating(z, s)]
			for p in PLAYER_POWERS:
				var wins := 0
				var three := 0
				for i in fights:
					for t in players:
						var sim := MatchSim.new({"seed": 5000 + i, "p1": t, "p2": st.enemy, "angles": [null, null],
							"powers": [p, st.power], "sizes": [1.0, Zones.BOSS_SIZE if Zones.is_boss(st) else 1.0]})
						var r := sim.run_to_end()
						if r.winner == 0:
							wins += 1
							if r.hp[0] / sim.balls[0].max_hp >= Campaign.STAR_CLEAN_FRACTION and r.time < MatchSim.OVERTIME_START:
								three += 1
				var n := fights * players.size()
				row += " %d%% (%d%%) |" % [roundi(100.0 * wins / n), roundi(100.0 * three / n)]
			lines.append(row)
		lines.append("")
	print("\n".join(lines))
	quit(0)
