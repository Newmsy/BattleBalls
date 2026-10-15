## Headless check that every critter's ability, and its T2-T5 upgrades, change
## fights. For each live critter it prints:
##   ability  win rate of the critter against its own "stat twin" (same stats,
##            no ability) at T1, equal power. ~50% = the ability does nothing.
##   t5_abil  win rate of its T5 ability against its T1 ability, both at T1
##            power, so only the ability upgrades differ. ~50% = upgrades are
##            just noise.
##   share    share of its damage that comes from the ability (not contact) at T1 / T5.
##   behaviour  tiers that add new behaviour (an "ability" entry), out of 4.
##   dead     tier keys the sim never reads (an upgrade that changes nothing).
## Usage: godot --headless --script res://tools/tier_check.gd -- [--fights=40] [--only=id,id] [--shard=k/n] [--out=file.md]
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const CritterDb := preload("res://sim/critter_db.gd")

const STATS := ["hp", "radius", "speed", "contact_damage"]


func _init() -> void:
	var fights := 40
	var only: Array = []
	var out := ""
	var shard := [1, 1]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fights="):
			fights = int(a.split("=")[1])
		elif a.begins_with("--only="):
			only = Array(a.split("=")[1].split(","))
		elif a.begins_with("--shard="):
			shard = Array(a.split("=")[1].split("/")).map(func(x): return int(x))
		elif a.begins_with("--out="):
			out = a.split("=")[1]
	var source := _sim_source()
	var lines: Array[String] = ["| critter | rarity | ability | t5_abil | share T1/T5 | behaviour | dead keys |", "|---|---|---|---|---|---|---|"]
	var ids: Array = CritterDb.ids().filter(func(id): return CritterDb.get_critter(id).status == "live" and id != "plain")
	for n in ids.size():
		var id: String = ids[n]
		if (not only.is_empty() and not id in only) or n % shard[1] != shard[0] - 1:
			continue
		var c := CritterDb.get_critter(id)
		var behaviour := 0
		var dead: Array[String] = []
		var timers := {} # Params an "every" trigger reads by name.
		for t in c.tiers.size():
			for e in (c.ability if t == 0 else c.tiers[t].get("ability", [])):
				if e.get("secs") is String:
					timers[e.secs] = true
		for t in range(1, c.tiers.size()):
			for key in c.tiers[t]:
				if key == "ability":
					behaviour += 1
				elif key != "text" and not key in STATS and not timers.has(key) and not source.contains('"%s"' % key) and not source.contains(".%s" % key):
					dead.append(key)
		var vs_twin := _rate(id, 1, 1, true, fights)
		var t5 := _rate(id, 5, 1, false, fights)
		lines.append("| %s | %s | %d%% | %d%% | %d%% / %d%% | %d/4 | %s |" % [id, c.rarity, roundi(vs_twin.win * 100), roundi(t5.win * 100),
			roundi(vs_twin.share * 100), roundi(t5.share * 100), behaviour, ", ".join(dead)])
		print(lines[-1])
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string("\n".join(lines) + "\n")
	quit()


## Win rate (draws half) of `id` at tier `ta` against `id` at tier `tb`, or
## against its ability-less twin when `twin`; plus the share of side 0's
## damage that isn't contact.
func _rate(id: String, ta: int, tb: int, twin: bool, fights: int) -> Dictionary:
	var score := 0.0
	var ability := 0.0
	var total := 0.0
	for s in fights:
		for side in 2:
			var tiers := [ta, tb] if side == 0 else [tb, ta]
			var sim := MatchSim.new({"seed": 1000 + s, "p1": id, "p2": id, "tiers": tiers, "angles": [null, null]})
			if twin:
				var b = sim.balls[1 - side]
				var d: Dictionary = b.def.duplicate()
				d.effects = []
				b.def = d
			while not sim.finished:
				sim.step()
				for e in sim.events:
					if e.type == "damage" and e.source == side:
						total += e.amount
						if e.kind != "contact":
							ability += e.amount
				sim.events.clear()
			if sim.winner == side:
				score += 1.0
			elif sim.winner == -1:
				score += 0.5
	return {"win": score / (fights * 2), "share": ability / maxf(total, 0.001)}


func _sim_source() -> String:
	var text := ""
	for path in ["res://sim/abilities.gd", "res://sim/match_sim.gd", "res://sim/modifiers.gd", "res://sim/power.gd"]:
		text += FileAccess.get_file_as_string(path)
	return text
