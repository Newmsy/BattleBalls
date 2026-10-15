## The critter pipeline: every file in sim/critters/ is valid, and everything
## that reads critters (sim, art, sound, summons) picks each one up.
extends "res://tests/test_case.gd"

const CritterDb := preload("res://sim/critter_db.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Abilities := preload("res://sim/abilities.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")
const Roster := preload("res://game/ui/roster.gd")
const Sfx := preload("res://game/audio/sfx.gd")


## Records every effect call instead of running it.
class Probe extends Abilities:
	var calls: Array = []

	func fx_probe(sim, b, ctx: Dictionary) -> void:
		calls.append([sim.tick, b.index, ctx.keys()])


func test_every_critter_file_is_valid() -> void:
	check(CritterDb.ids().size() >= 16, "critter files found")
	for id in CritterDb.ids():
		var errors := CritterDb.validate(id, CritterDb.get_critter(id))
		check(errors.is_empty(), "\n".join(errors))


func test_numbers_and_names_are_unique() -> void:
	var numbers := {}
	var names := {}
	for id in CritterDb.ids():
		var c := CritterDb.get_critter(id)
		check(not numbers.has(c.no), "%s reuses number %d (%s)" % [id, c.no, numbers.get(c.no, "")])
		check(not names.has(c.name), "%s reuses the name %s" % [id, c.name])
		numbers[c.no] = id
		names[c.name] = id


func test_art_and_sound_use_the_kit() -> void:
	for id in CritterDb.ids():
		var art: Dictionary = CritterDb.get_critter(id).art
		check(art.get("body", "gradient") in CritterArt.BODIES, "%s: unknown body %s" % [id, art.get("body")])
		for f in art.get("back", []) + art.get("front", []):
			check(f in CritterArt.FEATURES, "%s: unknown art feature %s" % [id, f])
		check(not art.get("eyes", {}).is_empty(), id + " has a face")
		check(art.get("eyes", {}).get("mouth", "smile") in CritterArt.MOUTHS, id + " mouth")
		var ouch: String = CritterDb.get_critter(id).sound.get("ouch", "")
		check(ouch == "" or Sfx.RULES.has(ouch), "%s: unknown ouch sound %s" % [id, ouch])


func test_live_critters_reach_the_sim_menus_and_summons() -> void:
	for id in CritterDb.live_ids():
		check(id in BallDefs.PLAYABLE, id + " is playable")
		check(Roster.ids().has(id), id + " is in the collection")
		var s1 := MatchSim.new({"seed": 5, "p1": id, "p2": "plain"}).run_to_end()
		var s2 := MatchSim.new({"seed": 5, "p1": id, "p2": "plain"}).run_to_end()
		check_eq(s1.hash, s2.hash, id + " fights deterministically")
	check(not "plain" in BallDefs.PLAYABLE, "the baseline is never offered")
	check(not Roster.ids().has("plain"), "the baseline isn't collectable")


func test_tiers_apply_the_ladder_upgrades() -> void:
	check_near(BallDefs.get_def("vampire").heal_ratio, 0.5, 0.0001, "T1")
	check_near(BallDefs.get_def("vampire", 3).heal_ratio, 0.7, 0.0001, "T3 keeps the T2 and T3 upgrades")
	var sim := MatchSim.new({"seed": 1, "p1": "laser", "p2": "laser", "tiers": [4, 1]})
	check_near(sim.balls[0].def.beam_life, 4.5, 0.0001, "the fight uses the T4 ladder")
	check_near(sim.balls[1].def.beam_life, 3.0, 0.0001, "the other ball stays T1")


func test_validation_catches_mistakes() -> void:
	var c := CritterDb.get_critter("vampire").duplicate(true)
	c.rarity = "mythic"
	c.ability = [{"on": "hit", "do": "explode"}, {"on": "sometimes", "do": "heal"}]
	c.tiers[2]["oops"] = 1.0
	var text := "\n".join(CritterDb.validate("vampire", c))
	for word in ["mythic", "explode", "sometimes", "oops"]:
		check(word in text, "flags " + word)


func test_every_trigger_fires() -> void:
	var sim := MatchSim.new({"seed": 3, "p1": "plain", "p2": "plain"})
	var probe := Probe.new()
	sim.abilities = probe
	var def: Dictionary = sim.balls[0].def.duplicate()
	def.effects = []
	for on in ["hit", "hurt", "wall", "bump", "start"]:
		def.effects.append({"on": on, "do": "probe"})
	def.effects.append({"on": "every", "secs": 2.0, "do": "probe"})
	def.effects.append({"on": "hp_below", "hp": 0.9, "do": "probe"})
	sim.balls[0].def = def
	sim.run_to_end()
	var keys := {}
	for c in probe.calls:
		keys[str(c[2])] = true
	check(probe.calls.any(func(c): return c[0] == 0), "start fires on the first tick")
	check(probe.calls.any(func(c): return c[0] == 120), "every 2s fires at 2s")
	check(keys.has(str(["point"])), "wall")
	check(keys.has(str(["other"])), "bump")
	check(keys.has(str(["target", "amount", "heals"])), "hit")
	check(keys.has(str(["source", "amount", "kind"])), "hurt")
	check(probe.calls.all(func(c): return c[1] == 0), "only the owner's effects fire")
