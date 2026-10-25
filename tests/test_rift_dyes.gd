## Rift Keys and Spark Dyes (design/dyes-rift-keys.md): a key opens a
## three-round run against one family that pays its copies and dye drops,
## keys and dyes drop from the right places, dyes unlock with a full bar,
## recolour only cosmetics you own, and never touch a fight config.
extends "res://tests/test_case.gd"

const Profile := preload("res://meta/profile.gd")
const Zones := preload("res://meta/zones.gd")
const Campaign := preload("res://meta/campaign.gd")
const FamilyRift := preload("res://meta/family_rift.gd")
const Families := preload("res://sim/families.gd")
const Roster := preload("res://game/ui/roster.gd")
const Summon := preload("res://game/ui/summon.gd")
const Dyes := preload("res://game/glow/dyes.gd")
const Catalog := preload("res://game/glow/catalog.gd")
const GlowState := preload("res://game/glow/glow_state.gd")
const SaveGame := preload("res://game/online/save_game.gd")
const ArenaView := preload("res://game/arena_view.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Shell := preload("res://game/ui/shell.gd")
const SpireClimb := preload("res://meta/spire_climb.gd")
const GlowPass := preload("res://game/glow/glow_pass.gd")

const NOW := 1_800_000_000
const WIN := {"winner": 0, "hp": [50.0, 0.0], "time": 10.0, "max_hp": 50.0}
const LOSS := {"winner": 1, "hp": [0.0, 10.0], "time": 40.0, "max_hp": 50.0}

var TEST_SAVE := "user://test_rift_save_%d.json" % OS.get_process_id()


func _zone1_done():
	var p = Profile.new_game(NOW)
	for i in Zones.zone(0).stages.size():
		p.stars[Zones.stage_key(0, i)] = 3
	return p


func test_a_key_opens_a_rift_into_one_family() -> void:
	var p = Profile.new_game(NOW)
	p.add_rift_keys(1)
	check_eq(FamilyRift.open(p, "fire", NOW).get("error"), "locked", "locked before the Zone 1 boss")
	p = _zone1_done()
	check_eq(FamilyRift.open(p, "fire", NOW).get("error"), "key", "needs a key")
	p.add_rift_keys(2)
	var run: Dictionary = FamilyRift.open(p, "fire", NOW)
	check_eq(p.rift_keys(), 1, "the key is spent")
	check_eq(FamilyRift.open(p, "sea", NOW).get("error"), "run", "one Rift at a time")
	check_eq(run.foes.size(), 3, "three foes")
	for id in run.foes:
		check_eq(Families.of(id), "fire", "%s is a Fire critter" % id)
	check(Roster.RARITIES.find(Roster.get_critter(run.foes[2]).rarity) >= 3, "the Rift Boss is the family's star")
	check(run.arena in FamilyRift.ARENAS.fire, "on a Fire arena")
	var cfg: Dictionary = FamilyRift.start(p, 0, "vampire", NOW)
	check_eq(cfg.p2, run.foes[0], "round 1 fights the first foe")
	check_eq(cfg.p1, "vampire", "with your fighter")
	check_eq(FamilyRift.start(p, 1, "vampire", NOW).get("error"), "run", "rounds go in order")
	check_eq(FamilyRift.start(p, 0, "vampire", NOW), cfg, "the same round builds the same fight (replayable)")
	check(cfg.powers[1] < FamilyRift.start(p, 0, "vampire", NOW).powers[0] * 10.0, "foe power is sane")


func test_wins_pay_family_copies_and_dyes_and_a_loss_keeps_them() -> void:
	var p = _zone1_done()
	p.add_rift_keys(2)
	FamilyRift.open(p, "sea", NOW)
	var r: Dictionary = FamilyRift.finish(p, 0, "vampire", WIN, NOW)
	check(r.won and not r.done, "round 1 won, run goes on")
	check_eq(r.copies.size(), 2, "two copies")
	for id in r.copies:
		check_eq(Families.of(id), "sea", "%s is a Sea critter" % id)
		check(p.owns(id), "%s lands in the collection" % id)
	check_eq(r.dyes.size(), 1, "one dye drop")
	check_eq(int(p.rift.round), 1, "on to round 2")
	var saved = Profile.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())), NOW)
	check_eq(int(saved.rift.round), 1, "a run survives the save")
	check_eq(saved.rift.foes, p.rift.foes, "with its foes")
	r = FamilyRift.finish(p, 1, "vampire", LOSS, NOW)
	check(not r.won and r.done, "a loss ends the run")
	check(not FamilyRift.in_run(p), "the Rift closes")
	check_eq(p.rift_keys(), 1, "and no key comes back")


func test_a_full_clear_pays_a_rare_or_better() -> void:
	var p = _zone1_done()
	p.add_rift_keys(1)
	FamilyRift.open(p, "cosmic", NOW)
	FamilyRift.finish(p, 0, "vampire", WIN, NOW)
	FamilyRift.finish(p, 1, "vampire", WIN, NOW)
	var r: Dictionary = FamilyRift.finish(p, 2, "vampire", WIN, NOW)
	check(r.cleared and r.done, "cleared")
	check_eq(r.copies.size(), 3, "boss pays three copies")
	check(Roster.RARITIES.find(Roster.get_critter(r.copies[0]).rarity) >= 2, "the first is Rare or better")
	check_eq(r.dyes.size(), 2, "and two dye drops")
	check(not FamilyRift.in_run(p), "the tear seals")


func test_roll_in_stays_in_the_pool_and_keeps_pity() -> void:
	var p = Profile.new_game(NOW)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var pool := FamilyRift.members("toybox")
	var pity: int = p.legendary_pity
	for i in 200:
		check(Summon.roll_in(p, rng, pool) in pool, "toybox only")
	check(p.legendary_pity != pity, "Rare+ rolls count toward the shared pity")


func test_keys_drop_from_zone_bosses_spire_and_the_pass() -> void:
	var p = Profile.new_game(NOW)
	var last: int = Zones.zone(0).stages.size() - 1
	for i in last:
		p.stars[Zones.stage_key(0, i)] = 1
	var r: Dictionary = Campaign.finish(p, 0, last, "vampire", WIN)
	check_eq(r.keys, 1, "the Zone 1 boss's first clear drops a key")
	check_eq(p.rift_keys(), 1, "into the Bag")
	r = Campaign.finish(p, 0, last, "vampire", WIN)
	check_eq(r.keys, 0, "only the first clear")
	p.add_rift_keys(50)
	check_eq(p.rift_keys(), Profile.RIFT_KEY_CAP, "keys stop at the cap")
	var climb = SpireClimb.new()
	climb.unclaimed = [19, 20, 40]
	check_eq(climb.unclaimed_total().keys, 2, "Spire floors 20 and 40 pay a key")
	var kinds := {}
	for l in range(1, GlowPass.LEVELS + 1):
		kinds[GlowPass.free_reward(l).kind] = int(kinds.get(GlowPass.free_reward(l).kind, 0)) + 1
	check_eq(kinds.get("rift_key", 0), GlowPass.FREE_KEYS.size(), "keys on the free track")
	check_eq(kinds.get("dye", 0), GlowPass.FREE_DYES.size(), "dyes on the free track")


func test_three_crowns_drop_a_dye_once() -> void:
	var p = Profile.new_game(NOW)
	var r: Dictionary = Campaign.finish(p, 0, 0, "vampire", WIN)
	check_eq(r.stars, 3, "a clean fast win is three crowns")
	check_eq(r.dyes.size(), 1, "the first three crowns drop a dye")
	r = Campaign.finish(p, 0, 0, "vampire", WIN)
	check_eq(r.dyes.size(), 0, "not again")


func test_dyes_unlock_with_a_full_bar_and_never_repeat() -> void:
	var p = Profile.new_game(NOW)
	for i in Dyes.need("dye_fire"):
		check(not Dyes.unlocked(p, "dye_fire"), "locked before the bar fills")
		p.add_dye_drop("dye_fire")
	check(Dyes.unlocked(p, "dye_fire"), "a full bar unlocks it")
	var rng := RandomNumberGenerator.new()
	for i in 300:
		check(Dyes.roll(p, rng) != "dye_fire", "an unlocked dye never drops again")
	for d in Dyes.DYES:
		for k in Dyes.need(d.id):
			p.add_dye_drop(d.id)
	check_eq(Dyes.roll(p, rng), "", "nothing left to drop")
	check_eq(Profile.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())), NOW).dyes.size(), Dyes.DYES.size(), "dyes save")
	p.grant({"kind": "dye", "n": 2})
	p.grant({"kind": "rift_key", "n": 1})
	check_eq(p.rift_keys(), 1, "a granted key lands")


func test_dye_colours_stay_clear_of_the_team_rings() -> void:
	var ids := {}
	for d in Dyes.DYES:
		check(not ids.has(d.id), "%s is unique" % d.id)
		ids[d.id] = true
		check(Dyes.NEED.has(d.grade), "%s has a grade" % d.id)
		for hex in d.colors:
			var c := Color(hex)
			for team in ArenaView.TEAM_COLORS:
				check(Vector3(c.r - team.r, c.g - team.g, c.b - team.b).length() > 0.25, "%s %s is too close to a team ring" % [d.id, hex])


func test_dyes_recolour_owned_cosmetics_only() -> void:
	var p = Profile.new_game(NOW)
	var glow = GlowState.new(SaveGame.new(TEST_SAVE), p)
	glow.g().owned.append("trail_comet")
	glow.equip("trail_comet")
	check(not glow.set_dye("trail_comet", "dye_sunset"), "a locked dye can't go on")
	check(not glow.set_dye("hat_crown", ""), "only cosmetics you own")
	for i in Dyes.need("dye_sunset"):
		p.add_dye_drop("dye_sunset")
	check(glow.set_dye("trail_comet", "dye_sunset"), "an unlocked one can")
	var look: Dictionary = glow.loadout()
	check_eq(look.get("dye_trail"), "dye_sunset", "the loadout carries the dye")
	check_eq(Catalog.worn(look, "trail").colors, Dyes.dye("dye_sunset").colors, "the trail wears its colours")
	check_eq(Catalog.worn(look, "trail").style, Catalog.item("trail_comet").style, "and keeps its shape")
	check_eq(Catalog.item("trail_comet").colors, ["8f7bff", "f0eeff"], "the catalog entry itself is untouched")
	glow.set_dye("trail_comet", "")
	check(not glow.loadout().has("dye_trail"), "taken off")
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func test_a_rift_round_fights_to_the_end() -> void:
	var p = _zone1_done()
	p.add_rift_keys(1)
	FamilyRift.open(p, "nature", NOW)
	var cfg: Dictionary = FamilyRift.start(p, 0, "vampire", NOW)
	cfg.angles = [450, null]
	var sim := MatchSim.new(cfg)
	var steps := 0
	while not sim.finished and steps < 20000:
		sim.step()
		steps += 1
	check(sim.finished, "the fight ends")


func test_the_rift_screens_build() -> void:
	var shell = Shell.new()
	shell.profile = _zone1_done()
	shell.build()
	shell.go("adventure")
	check_eq(shell.current, "adventure", "adventure hub with the Rift card")
	shell.go("rift")
	check_eq(shell.current, "rift", "the Rift Gate")
	shell.refresh_with({"family": "frost"})
	shell.profile.add_rift_keys(1)
	FamilyRift.open(shell.profile, "frost", NOW)
	shell.refresh_with({})
	FamilyRift.finish(shell.profile, 0, "vampire", WIN, NOW)
	shell.refresh_with({"notice": "won", "caption": "Rift", "xp": {"won": true, "round": 0, "copies": ["frost"], "dyes": [{"id": "dye_frost", "drops": 1, "need": 5, "unlocked": false}], "xp": 15, "critters": []}})
	check_eq(shell.current, "rift", "a run with a result")
	shell.show_tab("bag")
	shell.free()
