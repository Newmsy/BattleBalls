## Every critter's Bounce Run boon (the "boon" key of its file, sim/boons.gd)
## visibly changes its signature mechanic. Each boon names a "proof": what
## its critter does more of with the boon, measured over a few fights against
## Plain at T1 and at T5 (so a boon that only unlocks the T5 trick early
## still does something at T5). A number that never binds, like a cap the
## critter never reaches (Optic's old "+1 beam"), fails here.
##
## Proofs (per second of fight, so a shorter win doesn't count against it):
##   dmg            the holder's non-bump damage
##   dmg:<kind>     the holder's damage of that hit kind
##   all            all the holder's damage
##   bump           the holder's average bump (per hit, not per second)
##   heal           HP the holder heals plus shield it gains
##   hp             the holder's average HP plus shield
##   slow           how slowed, stunned or lifted the foe is
##   taken          damage the holder takes (must go DOWN)
##   event:<type>   events of that type the holder sets off
##   size           the holder's average radius
##   balls          the holder's team's balls on the field (minis, splits)
extends "res://tests/test_case.gd"

const Boons := preload("res://sim/boons.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const Families := preload("res://sim/families.gd")

const SEEDS := [11, 12, 13, 14, 15, 16, 17, 18]
const GAIN := 1.12 ## The boon must lift its proof by at least this much.
const FOE := "plain"


func test_every_live_critter_has_a_boon() -> void:
	var seen := {}
	for cid in CritterDb.live_ids():
		var id := Boons.for_critter(cid)
		check(id != "", "%s has a Bounce Run boon" % cid)
		if id == "":
			continue
		check(not seen.has(id), "boon id %s is used once" % id)
		seen[id] = true
		check(id in Boons.ALL and not id in Boons.GENERAL, "%s is offered only to its critter" % id)
		var def := Boons.get_def(id)
		check(def.has("proof"), "%s names its proof" % id)
		for r in ["common", "rare", "epic"]:
			var t: String = Boons.get_def(Boons.with_rarity(id, r)).text
			check(not "{" in t and t.length() <= 80, "%s %s text: %s" % [id, r, t])
		check_eq(def.rarity, "epic", "%s is always Epic" % id)
		check_eq(Boons.with_rarity(id, "common"), id, "%s has no other rarities" % id)
		check(Boons.applies_to(id, cid) and not Boons.applies_to(id, FOE), "%s is for %s only" % [id, cid])


## Optic's Prism used to add a 7th beam slot it never filled (it peaks at 5
## live beams): now every bounce links an older bounce too.
func test_prism_really_adds_beams() -> void:
	var peak := [0, 0]
	for k in 2:
		for s in SEEDS:
			var sim := MatchSim.new({"seed": s, "p1": "laser", "p2": FOE, "boons": [[] if k == 0 else ["prism"], []]})
			while not sim.finished and sim.tick < 20000:
				sim.step()
				peak[k] = maxi(peak[k], sim.beams.filter(func(x): return x.owner == 0).size())
	check(peak[1] >= peak[0] + 3, "Prism: more beams up at once (%d -> %d)" % peak)


func test_stacked_boons_add_up() -> void:
	var two := Boons.stacked(["prism", "prism"])
	check_eq(two.add.beam_link, 2 * Boons.get_def("prism").add.beam_link, "beam links add")
	check(two.text != Boons.get_def("prism").text and "2 more beam" in two.text, "and the text shows it: %s" % two.text)
	var def := Boons.apply_to_def(CritterDb.sim_def("laser"), ["prism", "prism"])
	check_eq(def.beam_link, two.add.beam_link, "and the def gets both")


## Copies stack strength, never trigger rate: Choo with two Express Lines
## used to run trains every 1.4s and do less than with one.
func test_stacking_never_hurts() -> void:
	var one := Boons.apply_to_def(CritterDb.sim_def("choo"), ["c_choo"])
	var two := Boons.apply_to_def(CritterDb.sim_def("choo"), ["c_choo", "c_choo"])
	check_eq(two.train_every, one.train_every, "trains don't come any sooner")
	check(two.train_cars > one.train_cars and two.train_damage > one.train_damage, "but are longer and hit harder")
	for cid in CritterDb.live_ids():
		var id := Boons.for_critter(cid)
		var a := Boons.apply_to_def(CritterDb.sim_def(cid), [id])
		var b := Boons.apply_to_def(CritterDb.sim_def(cid), [id, id, id])
		var base := CritterDb.sim_def(cid)
		for key in Boons.get_def(id).get("mul", {}).keys() + Boons.get_def(id).get("add", {}).keys():
			if not base.has(key) or not (base[key] is float or base[key] is int):
				continue
			var up := float(a[key]) >= float(base[key])
			check(float(b[key]) >= float(a[key]) if up else float(b[key]) == float(a[key]), "%s x3 %s: %s -> %s" % [id, key, a[key], b[key]])
		for tier in range(1, 6): # A cut never reaches 0 ("every 0th bounce").
			var t := CritterDb.sim_def(cid, tier)
			var c := Boons.apply_to_def(t, [id, id])
			for key in Boons.get_def(id).get("add", {}):
				if t.get(key) is int and t[key] >= 1:
					check(c[key] >= 1, "%s T%d %s stays >= 1 (%s)" % [id, tier, key, c[key]])
	var dmg := [measure("choo", ["c_choo"], "dmg"), measure("choo", ["c_choo", "c_choo"], "dmg")]
	check(dmg[1] > dmg[0], "two Express Lines out-damage one (%s -> %s)" % dmg)


func test_nature_boons_work() -> void:
	_family("nature")


func test_sea_boons_work() -> void:
	_family("sea")


func test_tech_boons_work() -> void:
	_family("tech")


func test_sweet_boons_work() -> void:
	_family("sweet")


func test_frost_boons_work() -> void:
	_family("frost")


func test_toybox_boons_work() -> void:
	_family("toybox")


func test_spooky_boons_work() -> void:
	_family("spooky")


func test_fire_boons_work() -> void:
	_family("fire")


func test_cosmic_boons_work() -> void:
	_family("cosmic")


func _family(family: String) -> void:
	for cid in Families.MEMBERS[family]:
		var id := Boons.for_critter(cid)
		if id == "" or not CritterDb.get_critter(cid).status == "live":
			continue
		var proof: String = Boons.get_def(id).proof
		for tier in [1, 5]:
			var without := measure(cid, [], proof, tier)
			var with := measure(cid, [id], proof, tier)
			var ok := with <= without / GAIN if proof == "taken" else with >= maxf(without * GAIN, without + 0.001)
			check(ok, "%s T%d: %s %s -> %s with %s" % [cid, tier, proof, snappedf(without, 0.001), snappedf(with, 0.001), id])


## The proof's per-second total for `critter` holding `boons`, over SEEDS.
static func measure(critter: String, boons: Array, proof: String, tier := 1) -> float:
	var total := 0.0
	var secs := 0.0
	var bumps := 0
	var kind := proof.get_slice(":", 1) if ":" in proof else ""
	for s in SEEDS:
		var sim := MatchSim.new({"seed": s, "p1": critter, "p2": FOE, "tiers": [tier, 1], "boons": [boons, []]})
		var me = sim.balls[0]
		while not sim.finished and sim.tick < 30 * MatchSim.TICK_RATE:
			var shield_before: float = me.shield
			sim.step()
			for e in sim.events:
				match proof.get_slice(":", 0):
					"dmg", "all":
						if e.type == "damage" and e.get("source", -1) == 0 and e.get("target", -1) != 0:
							if proof == "all" or (kind == "" and e.kind != "contact") or e.kind == kind:
								total += e.amount
					"bump":
						if e.type == "damage" and e.get("source", -1) == 0 and e.kind == "contact":
							total += e.amount
							bumps += 1
					"taken":
						if e.type in ["damage", "shield_hit"] and e.get("target", -1) == 0:
							total += e.amount
					"heal":
						if e.type == "heal" and e.target == 0:
							total += e.amount
					"event":
						if e.type == kind and _mine(e):
							total += 1.0
			match proof:
				"heal":
					total += maxf(0.0, me.shield - shield_before)
				"slow":
					var foe = sim.balls[1]
					total += MatchSim.DT * (1.0 if sim.stunned(foe) or sim.airborne(foe) else maxf(foe.slow, sim.status_amount(foe, "slow")))
				"hp":
					total += MatchSim.DT * (me.hp + me.shield)
				"size":
					total += MatchSim.DT * me.radius
				"balls":
					total += MatchSim.DT * sim.balls.filter(func(b): return b.team == 0 and b.alive()).size()
		secs += sim.time()
	if proof == "bump":
		return total / maxi(bumps, 1)
	return total / maxf(secs, 0.001)


## An event set off by ball 0 (events name their ball in different keys).
static func _mine(e: Dictionary) -> bool:
	for key in ["source", "owner", "ball"]:
		if e.has(key):
			return e[key] == 0
	return true
