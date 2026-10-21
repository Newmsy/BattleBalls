## Gear types, tiers, merging, sources and the gear power budget (design/gear.md).
extends "res://tests/test_case.gd"

const Gear := preload("res://sim/gear.gd")
const Lineup := preload("res://sim/lineup.gd")
const Profile := preload("res://meta/profile.gd")
const Campaign := preload("res://meta/campaign.gd")
const GearVault := preload("res://meta/gear_vault.gd")
const Economy := preload("res://meta/economy.gd")
const Zones := preload("res://meta/zones.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const GlowPass := preload("res://game/glow/glow_pass.gd")
const Roster := preload("res://game/ui/roster.gd")

const T0 := 1_800_000_000


func _player(hammers := 10000):
	var p = Profile.new_game(T0)
	p.hammers = hammers
	return p


func test_every_piece_is_worth_the_same_power_at_a_tier() -> void:
	for type in Gear.TYPES:
		check(Gear.PIECES[type].slot in Gear.SLOTS, "%s has a slot" % type)
		for tier in range(1, 6):
			check_near(Gear.stats_power(Gear.stats_for(type, tier)), Gear.tier_power(tier), 0.001, "%s %d-star" % [type, tier])
	check_near(Gear.tier_power(5), 0.05, 0.0001, "a 5-star piece is +5%")
	check_eq(Gear.TYPES.size(), 12, "twelve pieces")
	for slot in Gear.SLOTS:
		check_eq(Gear.TYPES.filter(func(t): return Gear.PIECES[t].slot == slot).size(), 4, "four pieces per %s" % slot)
	for type in Gear.PIECES:
		check(type in Gear.TYPES, "%s is listed in TYPES" % type)


func test_full_best_in_slot_stays_inside_the_budget() -> void:
	# power-progression.md section 5: full gear ~ +15%, always less than a tier (+25%).
	var full := Gear.tier_power(5) * Gear.SLOTS.size()
	check_near(full, 0.15, 0.001, "three 5-star pieces")
	check(full < 0.25, "gear never replaces a tier")


func test_three_of_a_kind_merge_into_the_next_tier() -> void:
	var p = _player()
	for i in 3:
		p.add_gear("iron_shell", 1)
	p.add_gear("iron_shell", 2)
	check(p.can_merge_gear("iron_shell", 1), "three 1-stars merge")
	check(not p.can_merge_gear("iron_shell", 2), "one 2-star doesn't")
	var made: Dictionary = p.merge_gear("iron_shell", 1)
	check_eq([made.type, made.tier], ["iron_shell", 2], "a 2-star Iron Shell")
	check_eq(p.hammers, 10000 - Economy.GEAR_MERGE_COST[1], "costs hammers")
	check_eq(p.gear_of("iron_shell", 1).size(), 0, "the three are used up")
	check_eq(p.gear_of("iron_shell", 2).size(), 2, "two 2-stars now")
	check(not p.can_merge_gear("bubble_shell", 1), "types don't mix")


func test_merging_needs_hammers_and_stops_at_five_stars() -> void:
	var p = _player(0)
	for i in 3:
		p.add_gear("spike_core", 1)
	check(p.has_gear_set("spike_core", 1) and not p.can_merge_gear("spike_core", 1), "a set, but no hammers")
	check(p.merge_gear("spike_core", 1).is_empty(), "nothing happens")
	check_eq(p.gear.size(), 3, "nothing lost")
	for i in 3:
		p.add_gear("spike_core", 5)
	p.hammers = 99999
	check(not p.has_gear_set("spike_core", 5), "5 stars is the top")


func test_merged_piece_stays_on_the_critter_that_wore_one() -> void:
	var p = _player()
	var worn: Dictionary = p.add_gear("echo_core", 2)
	p.equip(worn.uid, "vampire")
	for i in 3:
		p.add_gear("echo_core", 2)
	var made: Dictionary = p.merge_gear("echo_core", 2)
	check_eq(made.on, "", "spares merge first, the worn one stays")
	check_eq(p.gear_on("vampire").size(), 1, "still wearing it")
	for i in 2:
		p.add_gear("echo_core", 2)
	made = p.merge_gear("echo_core", 2)
	check_eq(made.on, "vampire", "a worn piece used in a merge hands over to the new piece")
	check_eq(p.gear_on("vampire")[0].tier, 3, "the new one is on")


func test_merge_all_climbs_tiers_in_one_go() -> void:
	var p = _player()
	for i in 9:
		p.add_gear("bubble_shell", 1)
	var plan: Dictionary = p.merge_all_plan()
	check_eq(plan.merges.size(), 4, "three 1-star merges then one 2-star")
	check_eq(plan.hammers, 3 * Economy.GEAR_MERGE_COST[1] + Economy.GEAR_MERGE_COST[2], "cost up front")
	var made: Array = p.merge_all_gear()
	check_eq(p.gear.size(), 1, "one piece left")
	check_eq(p.gear[0].tier, 3, "a 3-star")
	check_eq(made.size(), 1, "reports what's left, not the steps")


func test_merge_all_only_spends_hammers_it_has() -> void:
	var p = _player(Economy.GEAR_MERGE_COST[1])
	for i in 6:
		p.add_gear("jet_charm", 1)
	check_eq(p.merge_all_plan().merges.size(), 1, "one merge affordable")
	p.merge_all_gear()
	check_eq(p.hammers, 0, "spent")
	check_eq(p.gear.size(), 4, "one merge done")


func test_charms_open_at_three_stars() -> void:
	var p = _player()
	var charm: Dictionary = p.add_gear("jet_charm", 1)
	check(not p.equip(charm.uid, "vampire"), "a 1-star critter has no Charm slot")
	check_eq(charm.on, "", "not equipped")
	p.stacks.append({"id": "laser", "tier": 3, "count": 1, "level": 1, "xp": 0})
	check(p.equip(charm.uid, "laser"), "a 3-star critter does")
	var s: Dictionary = Lineup.clean({"critter": "vampire", "tier": 2, "gear": [{"slot": "Charm", "stats": {"speed": 0.07}}]})
	check(s.gear.is_empty(), "a lineup can't sneak a Charm onto a 2-star")


func test_power_rating_counts_each_pieces_worth() -> void:
	var p = _player()
	var bare: int = p.power_of("vampire")
	var shell: Dictionary = p.add_gear("bubble_shell", 5)
	p.equip(shell.uid, "vampire")
	check_eq(p.power_of("vampire"), Roster.power("vampire", 1, 1, 0.05), "+5% for a 5-star")
	check(p.power_of("vampire") > bare, "gear shows")
	check_eq(Lineup.rating(p.slot_of("vampire")), p.power_of("vampire"), "lineup tags agree with the critter screen")


func test_old_saves_convert_and_drop_charms_from_low_tiers() -> void:
	var p = _player()
	var d: Dictionary = p.to_dict()
	d.gear = [{"uid": 1, "name": "Rubber Shell", "slot": "Shell", "rarity": "epic", "on": "vampire"},
		{"uid": 2, "name": "Echo Core", "slot": "Core", "rarity": "legendary", "on": "vampire"}]
	var q = Profile.from_dict(JSON.parse_string(JSON.stringify(d)), T0)
	check_eq([q.gear[0].type, q.gear[0].tier, q.gear[0].on], ["jet_charm", 4, ""], "Rubber Shell became a Jet Charm, off a 1-star")
	check_eq([q.gear[1].type, q.gear[1].tier, q.gear[1].on], ["echo_core", 5, "vampire"], "Echo Core stays on")


func _clear_zone_one(p) -> void:
	for i in Zones.zone(0).stages.size():
		p.stars[Zones.stage_key(0, i)] = 3


func test_vault_opens_after_zone_one_and_drops_its_tier() -> void:
	var p = _player()
	check_eq(GearVault.start(p, 0, "vampire", T0).get("error"), "locked", "locked before the boss")
	_clear_zone_one(p)
	check_eq(GearVault.start(p, 1, "vampire", T0).get("error"), "level", "level 2 opens after level 1")
	for d in GearVault.DIFFICULTIES.size():
		p.vault = {}
		p.energy = 99
		var cfg: Dictionary = GearVault.start(p, d, "vampire", T0)
		check(not cfg.has("error"), "starts")
		check_eq(cfg.p2, "anvil_king", "the Anvil King guards it")
		var hammers: int = p.hammers
		var r: Dictionary = GearVault.finish(p, d, "vampire", {"winner": 0, "hp": [10.0, 0.0], "time": 20.0, "max_hp": 50.0}, T0)
		check_eq(r.gear.size(), 1, "one piece per win")
		check_eq(p.hammers - hammers, GearVault.DIFFICULTIES[d].hammers, "and hammers")
		check_eq(r.gear[0].tier, GearVault.DIFFICULTIES[d].tier, "tier by difficulty")
		check(r.gear[0].type in GearVault.types_today(T0), "today's slot")


func test_vault_runs_are_capped_per_day_and_refunded_on_cancel() -> void:
	var p = _player()
	_clear_zone_one(p)
	p.energy = 999
	for i in GearVault.RUNS_PER_DAY:
		check(not GearVault.start(p, 0, "vampire", T0).has("error"), "run %d" % (i + 1))
	check_eq(GearVault.start(p, 0, "vampire", T0).get("error"), "runs", "out of runs")
	GearVault.cancel(p, T0)
	check_eq(GearVault.runs_left(p, T0), 1, "backing out gives the run back")
	check_eq(GearVault.runs_left(p, T0 + GearVault.DAY_SECONDS), GearVault.RUNS_PER_DAY, "new day, new runs")


func test_vault_rotation_covers_every_slot_each_week() -> void:
	var seen := {}
	for d in 7:
		for t in GearVault.types_today(T0 + d * GearVault.DAY_SECONDS):
			seen[t] = true
	check_eq(seen.size(), Gear.TYPES.size(), "every piece can drop in a week")
	check_eq(GearVault.types_today(0).size(), 4, "Thursday 1970 is a Shell day")
	check_eq(Gear.PIECES[GearVault.types_today(0)[0]].slot, "Shell", "Shell day")


func test_vault_fights_replay() -> void:
	var p = _player()
	_clear_zone_one(p)
	p.boss_levels["vault"] = 1
	var cfg: Dictionary = GearVault.start(p, 1, "vampire", T0)
	cfg.angles = [0.3, null]
	var a := MatchSim.new(cfg).run_to_end()
	var b := MatchSim.new(cfg).run_to_end()
	check_eq(a, b, "same config, same fight")


func test_campaign_boss_first_clear_drops_gear() -> void:
	var p = _player()
	var boss: int = Zones.zone(0).stages.size() - 1
	_clear_zone_one(p)
	p.stars.erase(Zones.stage_key(0, boss))
	var r: Dictionary = Campaign.finish(p, 0, boss, "vampire", {"winner": 0, "hp": [10.0, 0.0], "time": 20.0, "max_hp": 50.0})
	check(r.gear.any(func(g): return g.tier == Economy.GEAR_BOSS_TIER), "a %d-star piece" % Economy.GEAR_BOSS_TIER)
	var found := 0
	for i in 200:
		found += Campaign.finish(p, 0, 0, "vampire", {"winner": 0, "hp": [10.0, 0.0], "time": 20.0, "max_hp": 50.0}).gear.size()
	check(found > 20 and found < 65, "about one win in five drops gear (%d of 200)" % found)
	check_eq(Economy.gear_tier(0, 0), 1, "early stages drop 1-star gear")
	check(Economy.gear_tier(0, 8) > Economy.gear_tier(0, 0) and Economy.gear_tier(2, 0) > Economy.gear_tier(0, 8), "later stages and zones drop better gear")


func test_glow_pass_gear_is_free_track_only() -> void:
	var free := 0
	for l in range(1, GlowPass.LEVELS + 1):
		if GlowPass.free_reward(l).get("kind") == "gear":
			free += 1
		check(GlowPass.premium_reward(l).get("kind") != "gear", "no gear on the premium track (L%d)" % l)
	check_eq(free, GlowPass.FREE_GEAR.size(), "free track gear")
	var p = _player()
	p.grant({"kind": "gear", "type": "iron_shell", "tier": 3})
	check_eq([p.gear[0].type, p.gear[0].tier], ["iron_shell", 3], "granted")


func _fight(gear0, p1 := "plain", p2 := "plain", seed := 7) -> MatchSim:
	return MatchSim.new({"seed": seed, "p1": p1, "p2": p2, "angles": [null, null], "gear": [gear0, null]})


func _events(sim: MatchSim, type: String, ticks := 1800) -> Array:
	var out := []
	for i in ticks:
		if sim.finished:
			break
		sim.step()
		out.append_array(sim.events.filter(func(e): return e.type == type))
	return out


func test_effect_pieces_show_in_the_fight() -> void:
	var ward := _fight([{"stats": Gear.stats_for("ward_charm", 5)}])
	check_near(ward.balls[0].shield, ward.balls[0].max_hp * Gear.value("ward", 5), 0.01, "Ward Charm starts with a shield")
	check_eq(ward.balls[1].shield, 0.0, "the bare foe has none")
	check(not _events(_fight([{"stats": Gear.stats_for("thorn_shell", 5)}]), "reflect").is_empty(), "Thorn Shell hits bumpers back")
	check(not _events(_fight([{"stats": Gear.stats_for("ricochet_core", 5)}]), "ricochet").is_empty(), "Ricochet Core boosts a bank shot")
	var leech := _fight([{"stats": Gear.stats_for("leech_core", 5)}])
	_events(leech, "heal")
	check(leech.balls[0].healed > 0.0, "Leech Core heals off its bumps")
	var spring := _fight([{"stats": Gear.stats_for("spring_shell", 5)}])
	_events(spring, "heal")
	check(spring.balls[0].healed > 0.0, "Spring Shell heals on wall bounces")
	var phoenix := _fight([{"stats": Gear.stats_for("phoenix_charm", 5)}], "plain", "juggernaut")
	var revives := _events(phoenix, "revive", 20000)
	check(revives.size() <= 1, "Phoenix Charm revives at most once")
	check_eq(MatchSim.new({"seed": 7, "p1": "plain", "p2": "plain", "angles": [null, null]}).balls[0].shield, 0.0, "no gear, no shield")


func test_effect_pieces_stack_with_bounce_run_boons() -> void:
	const Boons := preload("res://sim/boons.gd")
	var def := Gear.apply_def({"hp": 100.0, "speed": 300.0}, Gear.totals([{"stats": Gear.stats_for("thorn_shell", 5)}]))
	check_near(def.thorns, Gear.value("thorns", 5), 0.0001, "Thorn Shell sets thorns")
	var both := Boons.apply_to_def(def, ["thorn_crown"])
	check_near(both.thorns, Gear.value("thorns", 5) + Boons.get_def("thorn_crown").thorns, 0.0001, "a boon adds to it")
