## The economy check (meta/economy.gd, meta/economy_model.gd): the drop and
## orb numbers must keep simulated players on the pacing targets, and the
## tables must cover the launch set.
extends "res://tests/test_case.gd"

const Economy := preload("res://meta/economy.gd")
const Model := preload("res://meta/economy_model.gd")
const Summon := preload("res://game/ui/summon.gd")
const CritterDb := preload("res://sim/critter_db.gd")

const DAYS := 90


func test_odds_add_up() -> void:
	var total := 0.0
	for r in Economy.RARITIES:
		total += Economy.SUMMON_ODDS[r]
	check_near(total, 100.0, 0.001, "summon odds")


## The Summon Portal rolls with the numbers the model checks.
func test_summon_portal_uses_the_economy_odds() -> void:
	check_eq(Summon.ODDS.size(), Economy.RARITIES.size(), "rarities")
	for o in Summon.ODDS:
		check_eq(o[1], Economy.SUMMON_ODDS[o[0]], "%s odds" % o[0])
	check_eq(Summon.PITY_RESET, Economy.PITY_RESET, "pity")


func test_launch_set_matches_the_critter_files() -> void:
	for r in Economy.RARITIES:
		for id in Economy.LAUNCH[r]:
			check(CritterDb.has(id), "%s has no critter file" % id)
			if CritterDb.has(id):
				check_eq(CritterDb.get_critter(id).rarity, r, "%s rarity" % id)


func test_launch_set_is_35_and_every_critter_can_be_found() -> void:
	var n := 0
	var dropped := {}
	for r in Economy.RARITIES:
		n += Economy.LAUNCH[r].size()
	check_eq(n, 35, "launch critters")
	for z in Economy.ZONE_DROPS:
		for id in z.featured + z.bonus + [z.boss] + z.get("enemies", []):
			check(Economy.rarity_of(id) != "", "%s is not in the launch set" % id)
			dropped[id] = true
		for id in z.bonus:
			check(Economy.RARITIES.find(Economy.rarity_of(id)) > Economy.RARITIES.find(Economy.rarity_of(z.featured[0])), "%s should be a rarity up" % id)
	for r in ["common", "uncommon", "rare", "epic"]:
		for id in Economy.LAUNCH[r]:
			check(dropped.has(id), "%s drops nowhere in the campaign" % id)


func test_same_seed_same_player() -> void:
	var a = Model.new(Economy.tuned(), 7)
	var b = Model.new(Economy.tuned(), 7)
	check_eq(a.play("regular", 20), b.play("regular", 20), "milestones")


## pve.md section 6 targets: the regular player's median inside each window,
## casual players within CASUAL_SLACK of it, heavy players not racing past
## the week-scale ones (a day-1 or day-3 goal can't be reached much sooner).
func test_tuned_economy_hits_the_pacing_targets() -> void:
	var r := Model.report(Economy.tuned(), 60, DAYS, 1, false, ["regular"])
	r.merge(Model.report(Economy.tuned(), 20, DAYS, 2, false, ["casual", "heavy"]))
	for m in Model.MILESTONES:
		var t: Array = Economy.TARGETS[m]
		var reg := Model.median(r.regular[m])
		check(reg >= t[0] and reg <= t[1], "regular %s on day %s, target %d-%d" % [m, reg, t[0], t[1]])
		var cas := Model.median(r.casual[m])
		check(cas <= t[1] * Economy.CASUAL_SLACK or cas > DAYS, "casual %s on day %s, over %sx the target" % [m, cas, Economy.CASUAL_SLACK])
		var heavy := Model.median(r.heavy[m])
		check(t[0] < 7 or heavy >= t[0] * Economy.HEAVY_FLOOR, "heavy %s on day %s, too fast" % [m, heavy])
	check_eq(Model.median(r.regular.first_fusion_session), 1.0, "first fusion session")
