## Critter Plunge (sim/plunge.gd) as a Versus mode: you race one of your
## racing critters (Plunge.RACERS) against a field of CPU critters at its
## tier, so its abilities show at their tier but the drop decides it, not who
## levelled more. Watch only: nothing to aim.
## Pays critter XP, account XP and Faction XP after every race, coins by place
## for the day's first PRIZE_RACES, and a medal for a podium you watched to
## the end. Field size is the trade-off: 4 racers pay coins only, 6 the medal
## podium, 8 a better podium and COINS_8 times the coins. Your best medal on
## each course is its stamp (Profile.plunge_stamps: {course id: medal}).
##
## Same flow as the bosses (meta/pinata_party.gd): start() spends the energy
## and returns the race, finish() pays out the finished race.
extends RefCounted

const Plunge := preload("res://sim/plunge.gd")
const PlungeCourse := preload("res://sim/plunge_course.gd")
const Rng := preload("res://sim/rng.gd")
const Campaign := preload("res://meta/campaign.gd")
const PlungeTalents := preload("res://meta/plunge_talents.gd")
const BossRuns := preload("res://meta/boss_runs.gd")

const ENERGY_COST := 4
const FIELD_SIZES := Plunge.FIELD_SIZES
const DEFAULT_FIELD := 6
const WIN_COINS := 100 ## 1st pays this...
const LAST_COINS := 10 ## ...last (or knocked out) this, sliding in between.
const COINS_8 := 1.5 ## An 8-racer field pays this times the coins.
const PRIZE_RACES := 8 ## Races a day that pay coins (Profile.boss_days[PRIZE_KEY]).
const PRIZE_KEY := "plunge"
const XP := 6
## Medal by place, per field size: 4 racers race for coins only.
const PODIUM := {
	4: [],
	6: ["gold", "silver", "bronze"],
	8: ["gold", "gold", "silver", "bronze", "bronze"],
}
const MEDALS := ["gold", "silver", "bronze"] ## Best first.

## The race the Plunge screen started, for the race scene (game/plunge.gd):
## {cfg (Plunge config, your fighter first), fighter}.
static var pending := {}
## Set by the race scene so the home screen reopens on the Plunge screen.
static var reopen := false
## The racer picked last on the Plunge screen, kept while the game runs.
static var racer := ""


## Who races for you: the racer picked last, else your lineup's fighter if it
## races, else your strongest racing critter; "" when you own none.
static func racer_for(profile) -> String:
	if racer != "" and profile.owns(racer) and Plunge.can_race(racer):
		return racer
	if Plunge.can_race(profile.lineup) and Campaign.can_fight(profile, profile.lineup):
		return profile.lineup
	var best := ""
	var best_power := -1
	for id in Plunge.RACERS:
		if profile.owns(id) and profile.power_of(id) > best_power:
			best = id
			best_power = profile.power_of(id)
	return best


## Coins for `place` (1 = winner) out of `n` racers.
static func coins_for(place: int, n: int) -> int:
	var k := COINS_8 if n == 8 else 1.0
	if n <= 1:
		return roundi(WIN_COINS * k)
	var f := 1.0 - float(clampi(place, 1, n) - 1) / float(n - 1)
	return roundi((LAST_COINS + (WIN_COINS - LAST_COINS) * f * f) * k)


## The medal for `place` (1 = winner) in a field of `n`, or "" for none.
static func medal_for(place: int, n: int) -> String:
	var row: Array = PODIUM.get(n, PODIUM[DEFAULT_FIELD])
	return row[place - 1] if place >= 1 and place <= row.size() else ""


## Races left today that pay coins.
static func prize_races_left(profile, now: int) -> int:
	return BossRuns.runs_left(profile, PRIZE_KEY, PRIZE_RACES, now)


## The seed of your next race, so the Plunge screen can show its course
## before you start it; start() races this one.
static func next_seed(profile) -> int:
	return (int(profile.runs) * 7727 + 101) & 0x7FFFFFFF


## The course a race on `seed_value` runs, as sim/plunge_course.gd picks it.
static func course_for(seed_value: int) -> Dictionary:
	return PlungeCourse.COURSES[Rng.new(seed_value * 17 + 5).range_int(0, PlungeCourse.COURSES.size() - 1)]


## The race config for `fighter` in a field of `n`: {seed, racers, tiers,
## boosts}. Your fighter is racer 0 with your race talents for its family; the
## rest are drawn by the seed, all at its tier.
static func race_for(profile, fighter: String, n: int, seed_value: int) -> Dictionary:
	var ids := [fighter] + Plunge.draw_field(seed_value, n - 1, [fighter])
	var tier: int = int(profile.best(fighter).get("tier", 1)) if profile != null else 1
	var boosts := [PlungeTalents.effects(profile, fighter) if profile != null else null]
	return {"seed": seed_value, "racers": ids, "tiers": ids.map(func(_id): return tier), "boosts": boosts}


## Spends the energy and returns the next race (next_seed, on the course the
## screen showed).
static func start(profile, fighter: String, n: int, now: int) -> Dictionary:
	if not Campaign.can_fight(profile, fighter) or not Plunge.can_race(fighter):
		return {"error": "no_ball"}
	if not FIELD_SIZES.has(n):
		return {"error": "field"}
	if not profile.spend_energy(ENERGY_COST, now):
		return {"error": "energy"}
	var seed_value := next_seed(profile)
	var cfg := race_for(profile, fighter, n, seed_value)
	cfg.course = course_for(seed_value).id
	profile.runs += 1
	profile.changed.emit()
	return cfg


## Pays out a finished race for your racer 0 that came `place` of `n`
## (`knocked_out` if it didn't make it down) on `course`. Coins only in the
## day's prize races; a medal (and its stamp) only for a race `watched` to
## the end. Returns {place, n, coins, xp, medal ("" for none), knocked_out,
## levels, account_levels, critters}.
static func finish(profile, fighter: String, place: int, n: int, knocked_out: bool, watched := true, course := "", now := -1) -> Dictionary:
	if now < 0:
		now = int(Time.get_unix_time_from_system())
	var prize := prize_races_left(profile, now) > 0
	var result := {"place": place, "n": n, "coins": coins_for(place, n) if prize else 0, "xp": XP, "knocked_out": knocked_out,
		"medal": "" if knocked_out or not watched else medal_for(place, n), "levels": 0, "account_levels": 0, "critters": []}
	if prize:
		BossRuns.use(profile, PRIZE_KEY, PRIZE_RACES, now, 1)
		profile.grant({"kind": "coins", "n": result.coins})
	PlungeTalents.add_medal(profile, result.medal)
	_add_stamp(profile, course, result.medal)
	Campaign.give_xp(profile, result, fighter)
	result.account_levels = profile.add_account_xp(ENERGY_COST)
	# Faction XP as a fight pays it: a win for 1st, a draw for the top half.
	profile.fight_faction_xp([fighter], 0 if place == 1 else (-1 if place <= n / 2.0 else 1))
	profile.changed.emit()
	return result


## Your stamp on `course_id`: the best medal won there, "" for none.
static func stamp(profile, course_id: String) -> String:
	return str(profile.plunge_stamps.get(course_id, ""))


## A save's stamps with only real courses and medals in them.
static func clean_stamps(d) -> Dictionary:
	var out := {}
	if d is Dictionary:
		for c in PlungeCourse.COURSES:
			if MEDALS.has(str(d.get(c.id, ""))):
				out[c.id] = str(d[c.id])
	return out


## Keeps `medal` as the course's stamp when it beats the one there.
static func _add_stamp(profile, course_id: String, medal: String) -> void:
	if medal == "" or PlungeCourse.find(course_id).id != course_id:
		return
	var had := stamp(profile, course_id)
	if had == "" or MEDALS.find(medal) < MEDALS.find(had):
		profile.plunge_stamps[course_id] = medal


## ?demo=1&plunge=1: a few race talents, medals and stamps, for screenshots.
static func demo(profile) -> void:
	for k in 8:
		PlungeTalents.add_medal(profile, "gold")
	for tal in PlungeTalents.TALENTS:
		PlungeTalents.buy(profile, "spooky", tal.id)
		PlungeTalents.buy(profile, "spooky", tal.id)
	for k in 10:
		_add_stamp(profile, PlungeCourse.COURSES[k * 2].id, MEDALS[k % 3])
