## Hard and Nightmare campaign check (not in CI): how often a maxed team wins
## each zone's first stage and boss on a difficulty. Teams are three random
## Epic or Legendary critters at T5 level 50 with 5-star gear, their faction's
## suggested talents and Ascension --ascend, fought exactly as the campaign
## fights them (Campaign.start / start_team / team_config, relays leg by leg).
## Newms 2026-11-05: an A3 team must be able to beat Nightmare.
##   godot --headless --script res://tools/campaign_difficulty.gd -- --diff=2 --ascend=3 [--fights=24] [--stages=all] [--mult=1.0]
## --mult scales the difficulty's foe power, to try a curve before writing it.
extends SceneTree

const Zones := preload("res://meta/zones.gd")
const Campaign := preload("res://meta/campaign.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Relay := preload("res://sim/relay.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Boons := preload("res://sim/boons.gd")
const Lineup := preload("res://sim/lineup.gd")
const Talents := preload("res://sim/talents.gd")
const Gear := preload("res://sim/gear.gd")
const Rng := preload("res://sim/rng.gd")

## Just enough of meta/profile.gd for Campaign.start and start_team.
class FakeProfile:
	var slots := {}
	var stars := {}
	var runs := 0
	func owns(id: String) -> bool:
		return slots.has(id)
	func slot_of(id: String) -> Dictionary:
		return slots[id]
	func spend_energy(_n: int, _now: int) -> bool:
		return true


func _init() -> void:
	var diff := 2
	var ascend := 3
	var fights := 24
	var all_stages := false
	var mult := 1.0
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		match kv[0]:
			"diff": diff = int(kv[1])
			"ascend": ascend = int(kv[1])
			"fights": fights = int(kv[1])
			"stages": all_stages = kv[1] == "all"
			"mult": mult = float(kv[1])
	var pool: Array = BallDefs.PLAYABLE.filter(func(id): return Boons.for_critter(id) != "" and BallDefs.get_def(id).get("rarity", "") in ["epic", "legendary"])
	var gear := []
	for t in ["bubble_shell", "spike_core", "overclock_charm"]:
		gear.append({"slot": Gear.PIECES[t].slot, "tier": 5, "stats": Gear.stats_for(t, 5)})
	var p := FakeProfile.new()
	for id in pool:
		p.slots[id] = Lineup.make(id, 5, 50, gear, Talents.suggested(Talents.faction_of(id)), ascend)
	for z in Zones.count():
		for s in Zones.zone(z).stages.size():
			p.stars[Zones.stage_key(z, s)] = 3
	var rating := 0
	for id in pool:
		rating += Lineup.rating(p.slots[id])
	print("%s, A%d teams (%d critters, mean rating %d), x%.2f foe power" % [Zones.DIFFICULTY_NAMES[diff], ascend, pool.size(), rating / maxi(1, pool.size()), mult])
	print("| Stage | Rec | Win |")
	print("|---|---|---|")
	var rng := Rng.new(77)
	for b in Zones.ZONES.size():
		var z := Zones.index(b, diff)
		var n: int = Zones.zone(z).stages.size()
		var stages: Array = range(n) if all_stages else [0, n - 1]
		for s in stages:
			var wins := 0.0
			for f in fights:
				p.runs = f
				var picks := []
				while picks.size() < Zones.team_size(z, s):
					var id: String = pool[rng.range_int(0, pool.size() - 1)]
					if not id in picks:
						picks.append(id)
				wins += _fight(p, z, s, picks, mult)
			print("| %s | %d | %.0f%% |" % [Zones.stage_key(z, s), Campaign.enemy_rating(z, s), 100.0 * wins / fights])
	quit(0)


## 1 for a win, 0.5 for a draw, 0 for a loss.
func _fight(p, z: int, s: int, picks: Array, mult: float) -> float:
	if Zones.zone(z).lineup == 1:
		var cfg: Dictionary = Campaign.start(p, z, s, picks[0], 0)
		cfg.powers[1] *= mult
		var sim := MatchSim.new(cfg)
		return _score(sim.run_to_end().winner)
	var rc: Dictionary = Campaign.start_team(p, z, s, picks, 0)
	rc.powers[1] = rc.powers[1].map(func(v): return v * mult)
	if Campaign.is_pair(z, s, picks) or Campaign.is_brawl(z, s, picks):
		var sim := MatchSim.new(Campaign.team_config(p, rc))
		return _score(sim.run_to_end().winner)
	var relay := Relay.new(rc)
	while not relay.finished:
		var leg := MatchSim.new(relay.leg_config())
		leg.run_to_end()
		relay.record_leg(leg)
	return _score(relay.winner)


func _score(winner: int) -> float:
	return 1.0 if winner == 0 else (0.5 if winner == -1 else 0.0)
