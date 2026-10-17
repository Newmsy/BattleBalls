## Farming bosses (sim/bosses.gd, design/bosses.md): anchored set pieces with
## their own scripts, fought in a normal MatchSim.
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Bosses := preload("res://sim/bosses.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Arenas := preload("res://sim/arenas.gd")
const Profile := preload("res://meta/profile.gd")
const Economy := preload("res://meta/economy.gd")


func _cfg(p1: String, seed_value := 3, boss := "anvil_king") -> Dictionary:
	return {"seed": seed_value, "p1": p1, "p2": boss, "arena": Bosses.DEFS[boss].arena, "angles": [null, null]}


func test_boss_never_moves() -> void:
	var sim := MatchSim.new(_cfg("juggernaut"))
	var start: Vector2 = sim.balls[1].pos
	var bounced := false
	while not sim.finished:
		sim.step()
		bounced = bounced or sim.events.any(func(e): return e.type == "collide")
		check(sim.balls[1].pos == start, "pinned at tick %d" % sim.tick)
		if sim.balls[1].pos != start:
			break
	check(bounced, "the critter bumped into it")


func test_every_critter_finishes_a_boss_fight() -> void:
	for boss in Bosses.DEFS:
		for id in BallDefs.PLAYABLE:
			var s := MatchSim.new(_cfg(id, 11, boss)).run_to_end()
			check(s.reason != "", "%s vs %s has a result" % [id, boss])
			check(s.time <= Bosses.DEFS[boss].time + 0.05, "%s vs %s ends on the boss clock" % [id, boss])


func test_boss_wins_when_its_clock_runs_out() -> void:
	var sim := MatchSim.new(_cfg("plain"))
	sim.balls[0].max_hp = 9999.0
	sim.balls[0].hp = 9999.0
	sim.balls[0].contact_damage = 0.0 # It can't hurt the boss either.
	var s := sim.run_to_end()
	check_eq(s.winner, 1, "the boss outlasted you")
	check_eq(s.reason, "time_limit")


func test_stun_cancels_a_slam() -> void:
	var sim := MatchSim.new(_cfg("plain"))
	while not sim.balls[1].state.has("act"):
		sim.step()
	check_eq(sim.balls[1].state.act.kind, "slam", "the first swing is a slam")
	var shots := sim.shots.size()
	sim.stun(sim.balls[0], sim.balls[1], 0.3)
	sim.step()
	check(not sim.balls[1].state.has("act"), "wind-up cancelled")
	check_eq(sim.shots.size(), shots - 1, "the hammer is gone")
	check(sim.events.any(func(e): return e.type == "boss_fizzle"), "it fizzles")


func test_boss_fights_replay() -> void:
	var cfg := _cfg("laser", 21)
	cfg.angles = [300, null]
	cfg.powers = [1.6, 1.9]
	check_eq(MatchSim.new(cfg).run_to_end(), MatchSim.new(cfg).run_to_end(), "same config, same fight")


func test_boss_maps_stay_out_of_the_picker() -> void:
	for id in Arenas.BOSS_ARENAS:
		check(not Arenas.DEFS.has(id) and id not in Arenas.PLAYABLE, "%s is a boss map only" % id)
		check(Arenas.get_def(id).has("min_half"), "%s keeps room around its boss in overtime" % id)
	for boss in Bosses.DEFS:
		check(Arenas.BOSS_ARENAS.has(Bosses.DEFS[boss].arena), "%s has its own map" % boss)


func test_old_saves_get_starter_hammers() -> void:
	var p = Profile.new_game(1_800_000_000)
	check_eq(p.hammers, Economy.STARTER_HAMMERS, "new players start with hammers")
	var d: Dictionary = p.to_dict()
	d.erase("hammers")
	check_eq(Profile.from_dict(d, 1_800_000_000).hammers, Economy.STARTER_HAMMERS, "a save from before hammers gets them once")
	p.hammers = 3
	check_eq(Profile.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())), 1_800_000_000).hammers, 3, "hammers save")


func test_brood_queen_lays_eggs_that_hatch_or_crack() -> void:
	var sim := MatchSim.new(_cfg("plain", 5, "brood_queen"))
	sim.balls[0].contact_damage = 0.0
	var egg = null
	while egg == null and sim.tick < 600:
		sim.step()
		for m in sim.balls:
			if m.def.get("minion", false):
				egg = m
	check(egg != null, "she lays an egg")
	if egg == null:
		return
	check(egg.anchored, "eggs sit still")
	var start: Vector2 = egg.pos
	var hatched := false
	while not sim.finished and sim.tick < 1200 and not hatched:
		sim.step()
		hatched = egg.type_id == "brood_chick"
		if not hatched:
			check(egg.pos == start, "an egg never moves")
	check(hatched and not egg.anchored and egg.speed > 0.0, "it hatches into a chick that runs about")
	# Cracking: break the next egg before it hatches.
	var next = null
	while next == null and sim.tick < 2400 and not sim.finished:
		sim.step()
		for m in sim.balls:
			if m.type_id == "brood_egg" and m.alive():
				next = m
	if next != null:
		sim.deal(sim.balls[0], next, 999.0, "test")
		sim.step()
		sim.step()
		check_eq(sim.balls[1].state.cracked, 1, "a cracked egg counts")


func test_minions_never_keep_a_boss_fight_going() -> void:
	var sim := MatchSim.new(_cfg("plain", 5, "brood_queen"))
	for i in 400:
		sim.step()
	check(sim.balls.size() > 2, "eggs are out")
	sim.deal(sim.balls[0], sim.balls[1], 9999.0, "test")
	sim.step()
	check(sim.finished and sim.winner == 0, "the queen down wins it, eggs and all")


func test_brood_queen_pays_orbs_and_an_egg_bonus() -> void:
	var BroodNest = load("res://meta/brood_nest.gd")
	var Zones = load("res://meta/zones.gd")
	var p = Profile.new_game(1_800_000_000)
	check_eq(BroodNest.start(p, 0, "vampire", 1_800_000_000).get("error"), "locked", "locked before zone 2")
	for z in 2:
		for i in Zones.zone(z).stages.size():
			p.stars[Zones.stage_key(z, i)] = 3
	var cfg: Dictionary = BroodNest.start(p, 2, "vampire", 1_800_000_000)
	check_eq(cfg.get("p2"), "brood_queen", "she's the boss")
	var orbs: int = p.orbs
	var r: Dictionary = BroodNest.finish(p, 2, "vampire", {"winner": 0, "hp": [10.0, 0.0], "time": 20.0, "max_hp": 50.0, "cracked": 7}, 1_800_000_000)
	check_eq(r.orbs, BroodNest.DIFFICULTIES[2].orbs + BroodNest.BONUS_MAX, "Elite plus the capped egg bonus")
	check_eq(p.orbs - orbs, r.orbs, "orbs land")
	check_eq(BroodNest.runs_left(p, 1_800_000_000), BroodNest.RUNS_PER_DAY - 1, "a run used")


func test_summon_orbs_became_eggs_in_old_saves() -> void:
	var p = Profile.new_game(1_800_000_000)
	var d: Dictionary = p.to_dict()
	for i in d.items:
		if i.name == "Summon Egg":
			i.name = "Summon Orb"
			i.text = "Spend at the Summon Portal. Earned by playing, never sold."
	var q = Profile.from_dict(JSON.parse_string(JSON.stringify(d)), 1_800_000_000)
	check(q.items.any(func(i): return i.name == "Summon Egg"), "the item is a Summon Egg now")
	check(not q.items.any(func(i): return i.name == "Summon Orb"), "no orbs left")
	check(q.spend_orbs(1), "and spending still works")


func test_pinata_swings_never_hits_back_and_ends_on_its_clock() -> void:
	var sim := MatchSim.new(_cfg("vampire", 7, "pinata_titan"))
	var start: Vector2 = sim.balls[1].pos
	var moved := false
	var hp: float = sim.balls[0].hp
	while not sim.finished:
		sim.step()
		moved = moved or sim.balls[1].pos.distance_to(start) > 50.0
	check(moved, "it swings on its rope")
	check(sim.balls[0].hp >= hp, "it never hurts you")
	check(sim.balls[1].hp < sim.balls[1].max_hp, "you smashed some of it")
	check(sim.time() <= Bosses.DEFS.pinata_titan.time + 0.05, "30 seconds, then it's over")


func test_pinata_pays_coins_for_damage_and_a_jackpot() -> void:
	var PinataParty = load("res://meta/pinata_party.gd")
	var Zones = load("res://meta/zones.gd")
	var now := 1_800_000_000
	var p = Profile.new_game(now)
	check_eq(PinataParty.start(p, 0, "vampire", now).get("error"), "locked", "locked before stage 1-5")
	for i in PinataParty.UNLOCK_STAGE + 1:
		p.stars[Zones.stage_key(0, i)] = 1
	var cfg: Dictionary = PinataParty.start(p, 0, "vampire", now)
	check_eq(cfg.get("p2"), "pinata_titan", "the piñata's the boss")
	check(absf(cfg.powers[1] - p.power_of("vampire") / 1000.0) < 0.01 or cfg.powers[1] == 1.0, "it matches your power")
	var coins: int = p.coins
	var r: Dictionary = PinataParty.finish(p, 0, "vampire", {"winner": 1, "hp": [50.0, 100.0], "time": 30.0, "max_hp": 50.0, "boss_dealt": 50.0, "boss_max": 100.0}, now)
	check(r.won and not r.broken, "every smash pays")
	check_eq(r.coins, PinataParty.coins_for(0.5, false), "half smashed, half the damage coins")
	check_eq(p.coins - coins, r.coins, "coins land")
	var j: Dictionary = PinataParty.finish(p, 0, "vampire", {"winner": 0, "hp": [50.0, 0.0], "time": 20.0, "max_hp": 50.0, "boss_dealt": 100.0, "boss_max": 100.0}, now)
	check_eq(j.coins, PinataParty.coins_for(1.0, true), "broken: the jackpot")
	check_eq(PinataParty.runs_left(p, now), PinataParty.RUNS_PER_DAY - 1, "a run used")
	var q = Profile.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())), now)
	check_eq(PinataParty.runs_left(q, now), PinataParty.RUNS_PER_DAY - 1, "runs used save")
	check_eq(PinataParty.runs_left(q, now + 86400), PinataParty.RUNS_PER_DAY, "and reset the next day")


func test_boss_hall_and_boss_screens_build() -> void:
	var Shell = load("res://game/ui/shell.gd")
	var shell = Shell.new()
	shell.build()
	shell.profile.wishlist.assign(["vampire"])
	for screen in ["bosses", "pinata", "vault", "nest", "totem", "wyrm"]:
		shell.go(screen, {"notice": "Won"} if screen != "bosses" else {})
		check_eq(shell.current, screen, screen + " builds")
	shell.free()


func test_totem_lights_todays_family_and_rings_out_orbs() -> void:
	var Talents = load("res://sim/talents.gd")
	var cfg := _cfg("phoenix", 9, "totem_of_nine")
	cfg.boss = {"family": Talents.faction_of("phoenix")}
	var lit := MatchSim.new(cfg)
	check(lit.balls[0].attack >= Bosses.DEFS.totem_of_nine.family_bonus - 0.001, "today's family hits harder")
	cfg.boss = {"family": "sea" if Talents.faction_of("phoenix") != "sea" else "tech"}
	check(MatchSim.new(cfg).balls[0].attack < 0.001, "other families don't")
	var sim := MatchSim.new(_cfg("plain", 9, "totem_of_nine"))
	sim.balls[0].contact_damage = 0.0
	while not sim.balls[1].state.has("act") and sim.tick < 600:
		sim.step()
	check_eq(sim.balls[1].state.get("act", {}).get("kind", ""), "volley", "the heads glow first")
	var before := sim.shots.size()
	while sim.balls[1].state.has("act"):
		sim.step()
	check_eq(sim.shots.size() - before, int(Bosses.DEFS.totem_of_nine.ring_count) - 1, "a ring of orbs with one gap")
	while not sim.balls[1].state.has("act"):
		sim.step()
	sim.stun(sim.balls[0], sim.balls[1], 0.3)
	sim.step()
	check(not sim.balls[1].state.has("act"), "a stun cancels the volley")


func test_totem_pays_sigils_to_todays_family() -> void:
	var TotemShrine = load("res://meta/totem_shrine.gd")
	var Zones = load("res://meta/zones.gd")
	var now := 1_800_000_000
	var p = Profile.new_game(now)
	check_eq(TotemShrine.start(p, 0, "vampire", now).get("error"), "locked", "locked before zone 3")
	for z in 3:
		for i in Zones.zone(z).stages.size():
			p.stars[Zones.stage_key(z, i)] = 3
	var cfg: Dictionary = TotemShrine.start(p, 1, "vampire", now)
	check_eq(cfg.boss.family, TotemShrine.family_today(now), "the fight knows today's family")
	check(TotemShrine.family_today(now) != TotemShrine.family_today(now + 86400), "it turns daily")
	var fam: String = TotemShrine.family_today(now)
	var xp := int(p.factions.get(fam, {}).get("xp", 0))
	var r: Dictionary = TotemShrine.finish(p, 1, "vampire", {"winner": 0, "hp": [10.0, 0.0], "time": 20.0, "max_hp": 50.0}, now)
	check_eq(r.sigils, TotemShrine.DIFFICULTIES[1].sigils, "Hard pays its sigils")
	check(int(p.factions[fam].xp) - xp >= r.sigils, "into today's family's tree")


func test_wyrm_only_its_glowing_scale_takes_damage() -> void:
	var sim := MatchSim.new(_cfg("plain", 13, "prism_wyrm"))
	sim.balls[0].contact_damage = 0.0
	sim.step()
	var wyrm = sim.balls[1]
	check_eq(wyrm.state.scales.size(), int(Bosses.DEFS.prism_wyrm.segments), "its body is out")
	var scale = sim.balls[wyrm.state.scales[1]]
	var start: Vector2 = scale.pos
	for i in 30:
		sim.step()
	check(scale.pos.distance_to(start) > 5.0, "the body snakes along")
	wyrm.state.glow = 0
	var hp: float = wyrm.hp
	sim.deal(sim.balls[0], scale, 20.0, "test") # Armour: not glowing.
	sim.step()
	check(absf(wyrm.hp - hp) < 0.001, "a dull scale shrugs it off")
	wyrm.state.glow = int(scale.state.order)
	wyrm.state.next_glow = wyrm.state.clock + 99.0
	sim.step()
	sim.deal(sim.balls[0], scale, 20.0, "test")
	sim.step()
	sim.step()
	check(wyrm.hp < hp - 5.0, "the glowing scale's hit comes off the wyrm")
	check(scale.alive(), "scales never fall off")


func test_lures_buy_wishlisted_copies() -> void:
	var WyrmRift = load("res://meta/wyrm_rift.gd")
	var Zones = load("res://meta/zones.gd")
	var now := 1_800_000_000
	var p = Profile.new_game(now)
	check_eq(WyrmRift.start(p, 0, "vampire", now).get("error"), "locked", "locked before zone 4")
	for z in 4:
		for i in Zones.zone(z).stages.size():
			p.stars[Zones.stage_key(z, i)] = 3
	check_eq(WyrmRift.start(p, 2, "vampire", now).get("p2"), "prism_wyrm", "the wyrm's the boss")
	var r: Dictionary = WyrmRift.finish(p, 2, "vampire", {"winner": 0, "hp": [10.0, 0.0], "time": 40.0, "max_hp": 50.0}, now)
	check_eq(p.lures, WyrmRift.DIFFICULTIES[2].lures, "Elite pays its Lures")
	check(not p.use_lure("blackhole"), "only wishlisted critters")
	p.toggle_wishlist("blackhole")
	p.lures = Profile.lure_cost("blackhole") - 1
	check(not p.use_lure("blackhole"), "not enough Lures, nothing spent")
	p.lures += 1
	check(p.use_lure("blackhole"), "enough Lures buys one")
	check(p.owns("blackhole"), "the copy lands")
	check_eq(p.lures, 0, "the Lures are spent")
	check_eq(Profile.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())), now).lures, 0, "Lures save")
