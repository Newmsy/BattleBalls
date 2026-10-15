extends "res://tests/test_case.gd"

const Lineup := preload("res://sim/lineup.gd")
const Power := preload("res://sim/power.gd")
const Gear := preload("res://sim/gear.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Relay := preload("res://sim/relay.gd")
const Spire := preload("res://sim/spire.gd")
const Profile := preload("res://meta/profile.gd")
const Campaign := preload("res://meta/campaign.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const ArenaGhosts := preload("res://game/pvp/arena_ghosts.gd")
const GhostLineup := preload("res://game/online/ghost_lineup.gd")
const CritterDb := preload("res://sim/critter_db.gd")

const T0 := 1_800_000_000
const TEST_SAVE := "user://test_lineup_arena.cfg"


## A player with a T3 level 12 Laser wearing a Legendary attack Core.
func _veteran():
	var p = Profile.new_game(T0)
	p.stacks.append({"id": "laser", "tier": 3, "count": 1, "level": 12, "xp": 0})
	var core: Dictionary = p.add_gear("Summit Core", "Core", "legendary")
	p.equip(core.uid, "laser")
	p.set_lineup("laser")
	return p


func test_slots_are_clamped_to_the_rules() -> void:
	var s := Lineup.clean({"critter": "laser", "tier": 9, "level": 400, "gear": [
		{"slot": "Core", "rarity": "legendary", "stats": {"attack": 5.0, "laser_eyes": 9.0}},
		{"slot": "Core", "rarity": "legendary", "stats": {"attack": 0.07}},
		{"slot": "Hat", "rarity": "legendary", "stats": {"health": 0.07}},
	]})
	check_eq(s.tier, 5, "tier capped at T5")
	check_eq(s.level, 50, "level capped at the tier's cap")
	check_eq(s.gear.size(), 1, "one piece per gear slot, known slots only")
	check_near(s.gear[0].stats.attack, Gear.LINES.attack.legendary, 0.0001, "a line can't beat a Legendary piece")
	check(not s.gear[0].stats.has("laser_eyes"), "unknown lines dropped")
	check_eq(Lineup.clean({"critter": "vampire", "tier": -2, "level": 0}).tier, 1, "tier floor")


func test_power_is_rarity_tier_and_level() -> void:
	check_near(Lineup.power(Lineup.make("vampire")), 1.0, 0.0001, "T1 Common is the base")
	check_near(Lineup.power(Lineup.make("laser", 3, 12)), Power.multiplier("rare", 3, 12), 0.0001, "matches sim/power.gd")


func test_profile_slot_is_what_the_player_owns() -> void:
	var p = _veteran()
	var s: Dictionary = p.slot_of("laser")
	check_eq([s.critter, s.tier, s.level], ["laser", 3, 12], "best stack")
	check_eq(s.gear.size(), 1, "worn gear")
	check_near(s.gear[0].stats.attack, Gear.value("attack", "legendary"), 0.0001, "Summit Core hits")
	check(p.slot_of("magnet").is_empty(), "nothing for a critter not owned")


func test_old_gear_gets_stat_lines_and_honest_text() -> void:
	var p = Profile.new_game(T0)
	var d: Dictionary = p.to_dict()
	d.gear = [{"uid": 1, "name": "Iron Shell", "slot": "Shell", "rarity": "common", "text": "Take 2 less damage per hit", "on": "vampire"},
		{"uid": 2, "name": "Mystery Core", "slot": "Core", "rarity": "rare", "text": "?", "on": ""}]
	var back = Profile.from_dict(JSON.parse_string(JSON.stringify(d)), T0)
	check_near(back.gear[0].stats.defense, Gear.value("defense", "common"), 0.0001, "named piece keeps its theme")
	check_near(back.gear[1].stats.attack, Gear.value("attack", "rare"), 0.0001, "unknown Core hits")
	check_eq(back.gear[0].text, "-3% damage taken", "text says what fights")
	var again = Profile.from_dict(JSON.parse_string(JSON.stringify(back.to_dict())), T0)
	check_eq(again.gear[0].stats, back.gear[0].stats, "stats survive a save")


func test_campaign_fights_with_the_owned_tier_and_gear() -> void:
	var p = _veteran()
	var cfg: Dictionary = Campaign.start(p, 0, 0, "laser", T0)
	check_eq(cfg.p1, "laser", "fighter")
	check_eq(cfg.tiers, [3, 1], "owned tier brings its ability upgrades")
	check_near(cfg.powers[0], Power.multiplier("rare", 3, 12), 0.0001, "owned power")
	check_eq(cfg.gear[0].size(), 1, "worn gear")
	cfg.angles = [-450, null]
	var a := MatchSim.new(cfg)
	a.run_to_end()
	var b := MatchSim.new(cfg.duplicate(true))
	b.run_to_end()
	check_eq(a.summary(), b.summary(), "replays from the config")
	var bare := MatchSim.new(cfg.merged({"gear": [null, null], "tiers": [1, 1]}, true))
	check(a.balls[0].attack > bare.balls[0].attack, "the attack Core reaches the ball")


func test_new_player_fights_their_starter_at_t1() -> void:
	var p = Profile.new_game(T0)
	var cfg: Dictionary = Campaign.start(p, 0, 0, Campaign.fighter_for(p), T0)
	check_eq([cfg.p1, cfg.tiers[0]], [Profile.STARTER, 1], "starter, T1")
	check_near(cfg.powers[0], 1.0, 0.0001, "a T1 Common starter is the base power")


func test_relay_applies_tiers_per_ball() -> void:
	var mine := Lineup.side([Lineup.make("laser", 4, 30), Lineup.make("vampire")])
	var relay := Relay.new({"seed": 3, "sides": [mine.sides, ["vampire"]], "aims": [[-450, null], [null]],
		"tiers": [mine.tiers, [1]], "powers": [mine.powers, [1.0]], "gear": [mine.gear, [null]]})
	var leg := relay.leg_config()
	check_eq(leg.tiers, [4, 1], "first ball's tier")
	check_near(leg.powers[0], Power.multiplier("rare", 4, 30), 0.0001, "first ball's power")


func test_ghost_arena_attack_freezes_the_owned_trio() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	var s = ArenaStore.open(TEST_SAVE)
	var p = _veteran()
	s.trio = ["laser", "vampire", "laser"]
	var slots: Array = s.slots(p)
	check_eq(slots.map(func(x): return x.tier), [3, 1, 3], "owned tiers")
	s.start_attack("even", ArenaGhosts.pool()[0].id, 7, slots)
	var reopened = ArenaStore.open(TEST_SAVE)
	check_eq(Lineup.side(reopened.pending.slots).tiers, [3, 1, 3], "frozen with the attack")
	check_eq(s.lineup(p).slots[0].tier, 3, "defence lineup carries the tier")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func test_ghost_bots_grow_with_the_ladder() -> void:
	check_eq([ArenaGhosts.bot_tier(0), ArenaGhosts.bot_level(0)], [1, 1], "Bronze starts at T1 L1")
	check_eq(ArenaGhosts.bot_tier(49), 5, "the top of the ladder is T5")
	for band in 50:
		check(ArenaGhosts.bot_level(band) <= Lineup.level_cap(ArenaGhosts.bot_tier(band)), "level within cap")
	for bot in ArenaGhosts.pool():
		if bot.trophies < 400:
			for slot in bot.lineup.slots:
				check(CritterDb.RARITIES.find(CritterDb.get_critter(slot.critter).rarity) <= 1, "Bronze ghosts bring Commons and Uncommons")


func test_spire_picks_fight_as_owned() -> void:
	var p = _veteran()
	var spec := Spire.floor_def(40, 1)
	var cfg := Spire.relay_config(spec, [{"id": "laser", "power": 9.9, "slot": p.slot_of("laser")}])
	check_eq(cfg.tiers[0], [3], "owned tier")
	check_near(cfg.powers[0][0], Power.multiplier("rare", 3, 12), 0.0001, "power from the slot, not the shown rating")
	check_eq(cfg.gear[0][0].size(), 1, "worn gear")
	var plain := Spire.relay_config(spec, [{"id": "laser", "power": 1.3}])
	check_eq(plain.powers[0], [1.3], "picks without a slot keep their power")


func test_published_ghost_carries_the_owned_setup() -> void:
	var p = _veteran()
	var l := GhostLineup.make([p.slot_of("laser")], [10])
	check_eq([l.slots[0].critter, l.slots[0].tier, l.slots[0].level], ["laser", 3, 12], "owned setup")
	check(GhostLineup.is_playable(l), "still a playable v1 lineup")
	check_eq(GhostLineup.make(["vampire"], []).slots[0].tier, 1, "ids still make bare T1 slots")
