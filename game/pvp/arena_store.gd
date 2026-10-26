## The player's Ghost Arena state on this device: trophies, peak, their trio
## (which attacks and, once online, defends), the shots it last used, the
## daily card refresh, and the attack in progress. Until the online trophy
## rules land this is the source of truth; the server takes over trophies
## later and this keeps the trio and shots.
##
## Arena Points and Arena Boosts live here too: every trophy won on attack
## also earns one spendable point (losing trophies never costs points), spent
## on per-family stat lines (sim/arena_boosts.gd). Points come only from
## arena play; nothing sells them.
extends RefCounted

const Arenas := preload("res://sim/arenas.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const ArenaGhosts := preload("res://game/pvp/arena_ghosts.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Lineup := preload("res://sim/lineup.gd")
const ArenaBoosts := preload("res://sim/arena_boosts.gd")
const Families := preload("res://sim/families.gd")
const ArenaTeams := preload("res://game/pvp/arena_teams.gd")
const Rng := preload("res://sim/rng.gd")
const Gear := preload("res://sim/gear.gd")

const SAVE_PATH := "user://ghost_arena.cfg"
const HISTORY_SIZE := 10
const FREE_REFRESHES := 1
## Tokens (Arena Coins in code and saves) won per attack (by card) and per lost attack, and per raid
## your defence holds. Spent only in the Bazaar.
const COINS_WIN := {"easier": 10, "even": 15, "harder": 25}
const COINS_LOSS := 3
const COINS_DEFENCE := 8
const RAIDS_PER_DAY := 3

## Set by the arena fight scene so the home screen reopens on the Arena.
static var reopen := false
## The trophies and league the Arena screen last showed (render-only: it
## ticks from these after a fight). Here because this script stays loaded
## through the fight scene.
static var seen_trophies := -1
static var seen_league := -1

var path := SAVE_PATH
## True until this device first saves the Arena: the trios are still the
## placeholder ones, not anything the player picked.
var is_new := false
var trophies := 0
var peak := 0 ## Best trophies this season (sets the league floor).
var trio: Array = ["vampire", "laser", "spiker"]
var shots: Array = [0, 0, 0] ## Launch offsets off the centre line, tenths of a degree.
var refresh_day := 0
var refreshes := 0
var wins := 0
var losses := 0
var history: Array = [] ## Newest first: {name, card, won, delta}
## The attack in progress: {card, bot_id, seed, slots}. `slots` freezes the
## trio as it fought (sim/lineup.gd), so the attack replays from it. A
## started attack is a spent attack, so one left unfinished counts as a loss
## next time the Arena opens.
var pending: Dictionary = {}
var points := 0 ## Arena Points to spend.
var points_earned := 0 ## Every point ever earned.
var boosts: Dictionary = {} ## {family: {line: level}}
## The trio other players (and, offline, the daily raids) fight. Same rules
## as `trio`: three different owned critters.
var defence: Array = ["vampire", "laser", "spiker"]
var coins := 0 ## Tokens to spend in the Bazaar (shown as Tokens).
var coins_earned := 0
var bazaar_day := 0
var bought: Array = [] ## Bazaar item indexes bought on bazaar_day.
var raid_day := 0
var raids: Array = [] ## Today's raids on your defence: {name, family, held, delta, coins}


static func open(save_path := SAVE_PATH):
	var s = load("res://game/pvp/arena_store.gd").new()
	s.path = save_path
	s._load()
	return s


## A filled-in store for ?demo=1 screenshots, saved apart from the real one.
static func sample():
	var s = load("res://game/pvp/arena_store.gd").new()
	s.path = "user://demo_ghost_arena.cfg"
	s.trophies = 1240
	s.peak = 1240
	s.wins = 41
	s.losses = 17
	s.points = 385
	s.points_earned = 1240
	s.trio = ["vampire", "spiker", "speedster"]
	s.defence = ["spiker", "vampire", "speedster"]
	s.coins = 140
	s.raid_day = today()
	s.raids = [{"name": "Frost Squad", "family": "frost", "held": true, "delta": 5, "coins": 8},
		{"name": "Circuit Gang", "family": "tech", "held": false, "delta": -10, "coins": 0},
		{"name": "Petal Patrol", "family": "nature", "held": true, "delta": 5, "coins": 8}]
	s.coins_earned = 610
	s.boosts = {"spooky": {"health": 3, "attack": 4, "defense": 2, "speed": 1}, "nature": {"attack": 2, "health": 1}, "fire": {"speed": 1}}
	return s


static func today() -> int:
	var d := Time.get_date_dict_from_system()
	return d.year * 10000 + d.month * 100 + d.day


## Today's opponents: seeded themed teams with trophies near yours, as
## strong as their trophies say (game/pvp/arena_teams.gd). `profile` is
## unused; kept so callers needn't change.
func offers(_profile = null, day: int = today()) -> Array[Dictionary]:
	return ArenaTeams.offers(trophies, day, refreshes if refresh_day == day else 0)


## Your attack trio's summed Power Rating, as the Arena fights it.
func power(profile = null, which := "trio") -> int:
	var total := 0
	for s in slots(profile, which):
		total += Lineup.rating(s)
	return total


func refreshes_left(day: int = today()) -> int:
	return FREE_REFRESHES - (refreshes if refresh_day == day else 0)


func refresh(day: int = today()) -> bool:
	if refreshes_left(day) <= 0:
		return false
	if refresh_day != day:
		refresh_day = day
		refreshes = 0
	refreshes += 1
	save()
	return true


## Puts `critter` in `slot`. A trio never holds the same critter twice: if
## it is already in another slot, the two slots swap.
## `which` is "trio" (attack) or "defence".
func set_slot(slot: int, critter: String, which := "trio") -> void:
	assert(critter in BallDefs.PLAYABLE, "Not playable: %s" % critter)
	var team: Array = get(which)
	var was: int = team.find(critter)
	if was != -1 and was != slot:
		team[was] = team[slot]
	team[slot] = critter
	save()


## The strongest trio from `owned` (strongest first): its first three.
## Repeats only when the player owns fewer than three critters.
static func best_trio(owned: Array) -> Array:
	var out: Array = []
	for i in 3:
		out.append(owned[i] if i < owned.size() else owned[i % owned.size()])
	return out


## Fills the trio with the strongest trio from `owned` (strongest first).
func fill_best(owned: Array, which := "trio") -> void:
	if owned.is_empty():
		return
	set(which, best_trio(owned))
	save()


## Ranked trios use only critters the player owns, and never the same critter twice (older saves could).
## Any other slot takes the strongest owned critter not already in the trio
## (`owned` is strongest first). Returns true if the trio changed.
func fit_to(owned: Array) -> bool:
	if owned.is_empty():
		return false
	var a := _fit(trio, owned)
	var b := _fit(defence, owned)
	if a or b:
		save()
	return a or b


func _fit(team: Array, owned: Array) -> bool:
	var changed := false
	var seen: Array = []
	for i in team.size():
		if team[i] in owned and not team[i] in seen:
			seen.append(team[i])
			continue
		var spare: Array = owned.filter(func(id): return not id in seen and not id in team.slice(i + 1))
		var pick: String = spare[0] if not spare.is_empty() else owned[i % owned.size()]
		if pick != team[i]:
			team[i] = pick
			changed = true
		seen.append(pick)
	return changed


## The trio as lineup slots (sim/lineup.gd): each critter at the tier, level
## and gear the player owns it with (Profile.slot_of). Without a profile, or
## for a critter not owned, a bare T1.
func slots(profile = null, which := "trio") -> Array:
	var out: Array = []
	for id in get(which):
		var s: Dictionary = profile.slot_of(id) if profile != null else {}
		s = s.duplicate() if not s.is_empty() else Lineup.make(id)
		var b := boost_of(id)
		if not b.is_empty():
			s.boost = b
		out.append(s)
	return out


## The stat lines a critter's family boosts add (sim/arena_boosts.gd).
func boost_of(critter: String) -> Dictionary:
	return ArenaBoosts.stats(boosts.get(Families.of(critter), {}))


func level_of(family: String, line: String) -> int:
	return int(boosts.get(family, {}).get(line, 0))


## Points the next level of a line costs, or 0 when it is maxed.
func next_cost(family: String, line: String) -> int:
	var lv := level_of(family, line)
	return 0 if lv >= ArenaBoosts.MAX_LEVEL else ArenaBoosts.cost(lv + 1)


## Buys the next level of a family's line. False if maxed or short of points.
func upgrade(family: String, line: String) -> bool:
	var c := next_cost(family, line)
	if c == 0 or points < c or not family in Families.ids() or not ArenaBoosts.LINES.has(line):
		return false
	points -= c
	if not boosts.has(family):
		boosts[family] = {}
	boosts[family][line] = level_of(family, line) + 1
	save()
	return true


## Gives back every point spent on boosts, so the player can plan again.
func reset_boosts() -> int:
	var back := 0
	for fam in boosts:
		for line in boosts[fam]:
			for lv in range(1, int(boosts[fam][line]) + 1):
				back += ArenaBoosts.cost(lv)
	boosts = {}
	points += back
	save()
	return back


## The trio as a lineup in the backend's v1 shape, plus per-slot shots.
func lineup(profile = null, which := "trio") -> Dictionary:
	var out: Array = slots(profile, which)
	for i in out.size():
		out[i].aim = shots[i]
	return {"v": 1, "slots": out, "aim": shots.duplicate()}


## `bot`: the opponent, as a full team (ArenaTeams) or a pool bot's id.
## A seeded team carries its own trophies, so what the attack is worth
## (Ladder.stake) is fixed here, when it starts.
func start_attack(card: String, bot, seed_value: int, attack_slots: Array = []) -> void:
	settle_abandoned()
	var foe: Dictionary = bot if bot is Dictionary else ArenaGhosts.by_id(str(bot))
	pending = {"card": card, "bot_id": str(foe.get("id", "")), "bot": foe, "seed": seed_value, "arena": Arenas.pick(seed_value),
		"slots": attack_slots if not attack_slots.is_empty() else slots()}
	if not Ladder.CARDS.has(card):
		pending.stake = Ladder.stake(trophies, int(foe.get("trophies", trophies)))
	save()


## {win, loss, coins} for the attack in progress.
func pending_stake() -> Dictionary:
	if pending.has("stake"):
		return pending.stake
	var c: Dictionary = Ladder.CARDS.get(pending.get("card", "even"), Ladder.CARDS.even)
	return {"win": c.win, "loss": c.loss, "coins": COINS_WIN.get(pending.get("card", "even"), 0)}


## Records the result of the pending attack. Returns the trophy change.
func finish_attack(won: bool, used_shots: Array = []) -> int:
	if pending.is_empty():
		return 0
	var delta := _apply(won)
	for i in mini(used_shots.size(), shots.size()):
		if used_shots[i] != null:
			shots[i] = int(used_shots[i])
	pending = {}
	save()
	return delta


## An attack that was started but never finished counts as a loss.
func settle_abandoned() -> int:
	if pending.is_empty():
		return 0
	var delta := _apply(false)
	pending = {}
	save()
	return delta


func _apply(won: bool) -> int:
	var delta := Ladder.stake_delta(trophies, peak, pending_stake(), won)
	trophies += delta
	peak = maxi(peak, trophies)
	if delta > 0:
		points += delta
		points_earned += delta
	if won:
		wins += 1
	else:
		losses += 1
	var got: int = int(pending_stake().coins) if won else COINS_LOSS
	coins += got
	coins_earned += got
	var bot: Dictionary = pending_bot()
	history.push_front({"name": bot.get("name", "?"), "card": pending.card, "won": won, "delta": delta, "coins": got})
	history = history.slice(0, HISTORY_SIZE)
	return delta


## The opponent of the attack in progress.
func pending_bot() -> Dictionary:
	if pending.get("bot", null) is Dictionary and not pending.bot.is_empty():
		return pending.bot
	return ArenaGhosts.by_id(str(pending.get("bot_id", "")))


## Today's raids on your defence: RAIDS_PER_DAY seeded themed teams at even
## strength fight your defence trio, on the first Arena visit of the day.
## Held raids win trophies and coins; lost ones cost a few trophies (capped,
## Ladder.defence_delta). Returns the raids just fought (empty if already
## fought today).
func run_raids(profile = null, day: int = today()) -> Array:
	if raid_day == day:
		return []
	raid_day = day
	raids = []
	var mine := slots(profile, "defence")
	var rng = Rng.new(hash("raids|%d" % day))
	var lost := 0
	for n in RAIDS_PER_DAY:
		var fams: Array = Families.ids()
		var team := ArenaTeams.make(fams[rng.range_int(0, fams.size() - 1)], ArenaTeams.target(power(profile, "defence"), trophies, "even"), rng.range_int(1, 0x7FFFFFFF))
		var r := fight(team.lineup.slots, mine, rng.range_int(1, 0x7FFFFFFF), team.lineup.aim, shots)
		var held: bool = r.winner == 1
		var delta := Ladder.defence_delta(trophies, peak, "even", not held, lost)
		trophies = maxi(0, trophies + delta)
		peak = maxi(peak, trophies)
		if delta < 0:
			lost -= delta
		var got := COINS_DEFENCE if held else 0
		coins += got
		coins_earned += got
		raids.append({"name": team.name, "family": team.family, "held": held, "delta": delta, "coins": got})
	save()
	return raids


## Runs a relay (sim/relay.gd) of two lineups to the end: {winner, legs, hash}.
## Aims are offsets off the centre line, per slot.
static func fight(a: Array, b: Array, seed_value: int, a_aims: Array, b_aims: Array) -> Dictionary:
	var sa := Lineup.side(a)
	var sb := Lineup.side(b)
	var relay = load("res://sim/relay.gd").new({
		"seed": seed_value,
		"arena": Arenas.pick(seed_value),
		"sides": [sa.sides, sb.sides],
		"aims": [_angles(a_aims, a.size(), 0), _angles(b_aims, b.size(), 1)],
		"tiers": [sa.tiers, sb.tiers],
		"powers": [sa.powers, sb.powers],
		"gear": [sa.gear, sb.gear],
		"talents": [sa.talents, sb.talents],
	})
	return relay.run_to_end()


static func _angles(offsets: Array, n: int, side: int) -> Array:
	var out: Array = []
	for i in n:
		out.append(ArenaGhosts.MatchSim.AIM_AT_CENTRE[side] + (int(offsets[i]) if i < offsets.size() else 0))
	return out


## Today's Bazaar stock: gear at your league's tier plus Summon Eggs and an
## energy refill, all for Tokens. Each item sells once a day.
func bazaar(day: int = today()) -> Array:
	var rng = Rng.new(hash("bazaar|%d" % day))
	var tier := clampi(1 + Ladder.league_index(maxi(trophies, peak)), 1, 5)
	var types: Array = Gear.TYPES.duplicate()
	var out: Array = []
	for n in 3:
		var t: String = types.pop_at(rng.range_int(0, types.size() - 1))
		var gt := clampi(tier - 1 + n / 2, 1, 5)
		out.append({"kind": "gear", "type": t, "tier": gt, "name": Gear.PIECES[t].name, "price": 40 + 40 * gt})
	out.append({"kind": "orbs", "n": 1, "name": "Summon Egg", "price": 120})
	out.append({"kind": "energy", "n": 30, "name": "Energy +30", "price": 50})
	return out


func is_bought(index: int, day: int = today()) -> bool:
	return bazaar_day == day and index in bought


## Buys Bazaar item `index` for `profile`. False if sold out or short of coins.
func buy(profile, index: int, day: int = today()) -> bool:
	var stock := bazaar(day)
	if index < 0 or index >= stock.size() or is_bought(index, day) or coins < int(stock[index].price):
		return false
	if bazaar_day != day:
		bazaar_day = day
		bought = []
	var item: Dictionary = stock[index]
	match item.kind:
		"gear":
			profile.add_gear(item.type, item.tier)
		"orbs":
			profile.orbs += int(item.n)
			profile.changed.emit()
		"energy":
			profile.energy += int(item.n)
			profile.changed.emit()
	coins -= int(item.price)
	bought.append(index)
	save()
	return true


func save() -> void:
	var f := ConfigFile.new()
	for key in ["trophies", "peak", "trio", "shots", "refresh_day", "refreshes", "wins", "losses", "history", "pending", "points", "points_earned", "boosts", "defence", "coins", "coins_earned", "bazaar_day", "bought", "raid_day", "raids"]:
		f.set_value("arena", key, get(key))
	f.save(path)


func _load() -> void:
	var f := ConfigFile.new()
	if f.load(path) != OK:
		is_new = true
		return
	for key in ["trophies", "peak", "refresh_day", "refreshes", "wins", "losses", "coins", "coins_earned", "bazaar_day", "raid_day"]:
		set(key, int(f.get_value("arena", key, get(key))))
	for key in ["history", "pending", "bought", "raids"]:
		set(key, f.get_value("arena", key, get(key)))
	# Saves from before Arena Points start with a point per trophy they hold.
	points_earned = int(f.get_value("arena", "points_earned", trophies))
	points = maxi(0, int(f.get_value("arena", "points", points_earned)))
	var saved_boosts = f.get_value("arena", "boosts", {})
	boosts = {}
	if saved_boosts is Dictionary:
		for fam in saved_boosts:
			if str(fam) in Families.ids() and saved_boosts[fam] is Dictionary:
				var lines := {}
				for line in saved_boosts[fam]:
					if ArenaBoosts.LINES.has(str(line)):
						lines[str(line)] = clampi(int(saved_boosts[fam][line]), 0, ArenaBoosts.MAX_LEVEL)
				boosts[str(fam)] = lines
	var saved_trio: Array = f.get_value("arena", "trio", trio)
	var saved_shots: Array = f.get_value("arena", "shots", shots)
	if saved_trio.size() == 3 and saved_trio.all(func(c): return c in BallDefs.PLAYABLE):
		trio = saved_trio
	var saved_defence: Array = f.get_value("arena", "defence", trio)
	if saved_defence.size() == 3 and saved_defence.all(func(c): return c in BallDefs.PLAYABLE):
		defence = saved_defence
	else:
		defence = trio.duplicate()
	if saved_shots.size() == 3:
		shots = saved_shots
