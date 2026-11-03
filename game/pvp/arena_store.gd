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
const ArenaPlayers := preload("res://game/pvp/arena_players.gd")
const ArenaChest := preload("res://game/pvp/arena_chest.gd")
const Rng := preload("res://sim/rng.gd")
const Gear := preload("res://sim/gear.gd")

const SAVE_PATH := "user://ghost_arena.cfg"
const HISTORY_SIZE := 10
const FREE_REFRESHES := 1
## Arena Coins (the Bazaar money; `coins` in code and saves) won per attack (by card) and per lost attack, and per raid
## your defence holds. Spent only in the Bazaar.
const COINS_WIN := {"easier": 10, "even": 15, "harder": 25}
const COINS_LOSS := 3
const COINS_DEFENCE := 8
const RAIDS_PER_DAY := 3
## Arena Tokens (Newms 2026-11-02): every Arena fight costs one. One comes
## back every TOKEN_SECONDS, up to TOKEN_MAX held. Never sold.
const TOKEN_MAX := 10
const TOKEN_SECONDS := 3600

## The Arena's two modes (Newms 2026-11-02), each with its own trophies,
## league, team, Defence and opponents: the 3v3 Series (a relay of three,
## sim/relay.gd) and the 2v2 League (two critters each on the field at
## once, a 2v2 MatchSim). Points, boosts, coins, tokens and the weekly chest
## are shared.
const SERIES := "series"
const LEAGUE := "league"
const MODES := {
	SERIES: {"name": "3v3 Series", "size": 3, "color": Color("ff4fd8"), "art": "vs_series", "team": "Your trio", "short": "3v3"},
	LEAGUE: {"name": "2v2 League", "size": 2, "color": Color("27c8ff"), "art": "vs_league", "team": "Your pair", "short": "2v2"},
}
## What each mode keeps of its own; everything else is shared.
const MODE_KEYS := ["trophies", "peak", "trio", "shots", "refresh_day", "refreshes", "wins", "losses", "history", "pending", "defence", "raid_day", "raids", "week", "week_best", "chest"]

## Set by the arena fight scene so the home screen reopens on the Arena.
static var reopen := false
## The trophies and league the Arena screen last showed (render-only: it
## ticks from these after a fight). Here because this script stays loaded
## through the fight scene.
static var seen_trophies := -1
static var seen_league := -1

var path := SAVE_PATH
## The mode the top-level MODE_KEYS fields hold now (use()); the other
## mode's are kept in _other. Saved as the last mode played.
var mode := SERIES
var _other: Dictionary = {}
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
var coins := 0 ## Arena Coins to spend in the Bazaar.
var coins_earned := 0
var bazaar_day := 0
var bought: Array = [] ## Bazaar item indexes bought on bazaar_day.
var raid_day := 0
var raids: Array = [] ## Today's raids on your defence: {name, family, held, delta, coins}
var week := 0 ## The week week_best counts (ArenaChest.week_of).
var week_best := -1 ## Best league index reached in `week`; -1 before any Arena visit.
var chest: Dictionary = {} ## The weekly chest waiting to open: {week, league}.
## Arena Tokens held (see tokens_now()) and the unix time the next one
## started charging. A new save starts full.
var tokens := TOKEN_MAX
var token_clock := 0


## `with_mode`: SERIES or LEAGUE, or "" for the mode last played.
static func open(save_path := SAVE_PATH, with_mode := ""):
	var s = load("res://game/pvp/arena_store.gd").new()
	s.path = save_path
	s._other = s._fresh(LEAGUE)
	s._load()
	if with_mode != "":
		s.use(with_mode)
	return s


## Switches the store to `m`: the mode fields (MODE_KEYS) now hold its state.
func use(m: String) -> void:
	if m == mode or not MODES.has(m):
		return
	var cur := {}
	for k in MODE_KEYS:
		cur[k] = get(k)
	for k in MODE_KEYS:
		set(k, _other[k])
	_other = cur
	mode = m


## Team size in the current mode (3 or 2).
func size() -> int:
	return int(MODES[mode].size)


## A mode's state before any play.
func _fresh(m: String) -> Dictionary:
	var n: int = MODES[m].size
	var team: Array = ["vampire", "laser", "spiker"].slice(0, n)
	return {"trophies": 0, "peak": 0, "trio": team, "shots": team.map(func(_c): return 0), "refresh_day": 0, "refreshes": 0,
		"wins": 0, "losses": 0, "history": [], "pending": {}, "defence": team.duplicate(), "raid_day": 0, "raids": [],
		"week": 0, "week_best": -1, "chest": {}}


## Trophies in mode `m` (either mode, whichever is in use).
func trophies_in(m: String) -> int:
	return int(trophies) if m == mode else int(_other.trophies)


## Your best trophies over both modes (the Bazaar's stock tier).
func best_trophies() -> int:
	return maxi(maxi(trophies, peak), maxi(int(_other.trophies), int(_other.peak)))


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
	s.raids = [{"name": "frostbyte92", "family": "frost", "held": true, "delta": 5, "coins": 8},
		{"name": "Kaz_Plays", "family": "tech", "held": false, "delta": -10, "coins": 0},
		{"name": "MossyMaya", "family": "nature", "held": true, "delta": 5, "coins": 8}]
	s.coins_earned = 610
	s.week = ArenaChest.this_week()
	s.week_best = Ladder.league_index(s.trophies)
	s.boosts = {"spooky": {"health": 3, "attack": 4, "defense": 2, "speed": 1}, "nature": {"attack": 2, "health": 1}, "fire": {"speed": 1}}
	return s


static func today() -> int:
	var d := Time.get_date_dict_from_system()
	return d.year * 10000 + d.month * 100 + d.day


static func now_unix() -> int:
	return int(Time.get_unix_time_from_system())


## Brings tokens up to date: one per TOKEN_SECONDS since token_clock, up to
## TOKEN_MAX. Returns the tokens held.
func tokens_now(now: int = now_unix()) -> int:
	if tokens >= TOKEN_MAX or token_clock <= 0 or now < token_clock:
		# Full (or a clock that ran backwards): the next one starts charging now.
		token_clock = now
		return tokens
	var got := (now - token_clock) / TOKEN_SECONDS
	if got > 0:
		tokens = mini(TOKEN_MAX, tokens + got)
		token_clock = now if tokens >= TOKEN_MAX else token_clock + got * TOKEN_SECONDS
	return tokens


## Seconds until the next token, or 0 when full.
func next_token_in(now: int = now_unix()) -> int:
	if tokens_now(now) >= TOKEN_MAX:
		return 0
	return maxi(1, TOKEN_SECONDS - (now - token_clock))


## Spends one token for a fight. False (and nothing spent) when out.
func spend_token(now: int = now_unix()) -> bool:
	if tokens_now(now) <= 0:
		return false
	if tokens >= TOKEN_MAX:
		token_clock = now # The first token spent from full starts the clock.
	tokens -= 1
	save()
	return true


## "41:12" until the next token (or "1:02:00" past an hour).
static func clock_text(secs: int) -> String:
	if secs >= 3600:
		return "%d:%02d:%02d" % [secs / 3600, secs / 60 % 60, secs % 60]
	return "%d:%02d" % [secs / 60, secs % 60]


## Today's opponents: other players' saved squads near your trophies
## (game/pvp/arena_players.gd) mixed in with seeded player-style squads as
## strong as their trophies say (game/pvp/arena_teams.gd). `profile` is unused; kept so
## callers needn't change.
func offers(_profile = null, day: int = today()) -> Array[Dictionary]:
	var refresh: int = refreshes if refresh_day == day else 0
	if mode == LEAGUE:
		# Real players' pairs aren't online yet: the League is all seeded squads.
		return ArenaTeams.offers(trophies, day, refresh, ArenaTeams.OFFER_COUNT, 2)
	return ArenaPlayers.offers(trophies, day, refresh)


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


## The strongest team from `owned` (strongest first): its first `n`.
## Repeats only when the player owns fewer than `n` critters.
static func best_trio(owned: Array, n := 3) -> Array:
	var out: Array = []
	for i in n:
		out.append(owned[i] if i < owned.size() else owned[i % owned.size()])
	return out


## Fills the trio with the strongest trio from `owned` (strongest first).
func fill_best(owned: Array, which := "trio") -> void:
	if owned.is_empty():
		return
	set(which, best_trio(owned, size()))
	save()


## Ranked trios use only critters the player owns, and never the same critter twice (older saves could).
## Any other slot takes the strongest owned critter not already in the trio
## (`owned` is strongest first). Returns true if the trio changed.
func fit_to(owned: Array) -> bool:
	if owned.is_empty():
		return false
	var a := _fit(trio, owned)
	var b := _fit(defence, owned)
	var c := _fit(_other.trio, owned)
	var d := _fit(_other.defence, owned)
	if a or b or c or d:
		save()
	return a or b or c or d


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
	pending = {"card": card, "mode": mode, "bot_id": str(foe.get("id", "")), "bot": foe, "seed": seed_value, "arena": Arenas.pick(seed_value),
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
	note_league()
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


## Today's raids on your defence: RAIDS_PER_DAY seeded player-style squads at even
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
	var rng = Rng.new(hash("raids|%d" % day) if mode == SERIES else hash("raids|%s|%d" % [mode, day]))
	var lost := 0
	for n in RAIDS_PER_DAY:
		var team := ArenaTeams.make_player(ArenaTeams.target(power(profile, "defence"), trophies, "even"), rng.range_int(1, 0x7FFFFFFF), trophies, size())
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
	note_league()
	save()
	return raids


## A finished week's best league becomes its chest (replacing one left
## unopened), and a new week starts counting.
func roll_week(now_week: int = ArenaChest.this_week()) -> void:
	if week == now_week:
		return
	if week_best >= 0 and week < now_week:
		chest = {"week": week, "league": week_best}
	week = now_week
	week_best = -1


## True when either mode has a finished week's chest waiting.
func any_chest_ready() -> bool:
	if chest_ready():
		return true
	var m := mode
	use(LEAGUE if m == SERIES else SERIES)
	var other := chest_ready()
	use(m)
	return other


## True when a finished week's chest is waiting to open (this mode's).
func chest_ready() -> bool:
	roll_week()
	return not chest.is_empty()


## Counts the league you're in now towards this week's chest.
func note_league(now_week: int = ArenaChest.this_week()) -> void:
	roll_week(now_week)
	week_best = maxi(week_best, Ladder.league_index(trophies))


## Runs a relay (sim/relay.gd) of two lineups to the end: {winner, legs, hash}.
## Aims are offsets off the centre line, per slot.
static func fight(a: Array, b: Array, seed_value: int, a_aims: Array, b_aims: Array) -> Dictionary:
	if a.size() == 2 and b.size() == 2:
		var sim = load("res://sim/match_sim.gd").new(duo_config(a, b, seed_value))
		sim.run_to_end()
		return {"winner": sim.winner, "hash": sim.state_hash()}
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
		"ascend": [sa.ascend, sb.ascend],
		"tie_to": 0, # Both out together goes to the attacker (side a).
	})
	return relay.run_to_end()


## A 2v2 League fight as a MatchSim config: a's pair are p1 and p3, b's
## p2 and p4, all on the field at once, on the arena the seed picks. Both
## sides' launch angles come from the seed (the attacker aims p1 in the fight
## scene). Both out together goes to the attacker.
static func duo_config(a: Array, b: Array, seed_value: int) -> Dictionary:
	var cfg := {"seed": seed_value, "arena": Arenas.pick(seed_value), "tie_to": 0}
	Lineup.apply(cfg, 0, a[0])
	Lineup.apply(cfg, 1, b[0])
	Lineup.apply(cfg, 2, a[1])
	Lineup.apply(cfg, 3, b[1])
	return cfg


static func _angles(offsets: Array, n: int, side: int) -> Array:
	var out: Array = []
	for i in n:
		out.append(ArenaGhosts.MatchSim.AIM_AT_CENTRE[side] + (int(offsets[i]) if i < offsets.size() else 0))
	return out


## Today's Bazaar stock: gear at your league's tier plus Summon Eggs and an
## energy refill, all for Tokens. Each item sells once a day.
func bazaar(day: int = today()) -> Array:
	var rng = Rng.new(hash("bazaar|%d" % day))
	var tier := clampi(1 + Ladder.league_index(best_trophies()), 1, 4)
	var types: Array = Gear.TYPES.duplicate()
	var out: Array = []
	for n in 3:
		var t: String = types.pop_at(rng.range_int(0, types.size() - 1))
		var gt := clampi(tier - 1 + n / 2, 1, 4) # 5 stars are merged only
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


## The 3v3 Series' fields stay in the "arena" section, as they always were;
## the 2v2 League's are in "league"; shared ones in "arena".
func save() -> void:
	var f := ConfigFile.new()
	for key in ["points", "points_earned", "boosts", "coins", "coins_earned", "bazaar_day", "bought", "tokens", "token_clock", "mode"]:
		f.set_value("arena", key, get(key))
	for key in MODE_KEYS:
		var mine = get(key)
		f.set_value("arena", key, mine if mode == SERIES else _other[key])
		f.set_value("league", key, mine if mode == LEAGUE else _other[key])
	f.save(path)


func _load() -> void:
	var f := ConfigFile.new()
	if f.load(path) != OK:
		is_new = true
		return
	for key in ["coins", "coins_earned", "bazaar_day", "tokens", "token_clock"]:
		set(key, int(f.get_value("arena", key, get(key))))
	for key in ["bought"]:
		set(key, f.get_value("arena", key, get(key)))
	_load_mode(f, "arena", SERIES)
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
	# The League's fields load through the same checks, then go aside.
	var series := {}
	for k in MODE_KEYS:
		series[k] = get(k)
	mode = LEAGUE
	for k in MODE_KEYS:
		set(k, _other[k])
	_load_mode(f, "league", LEAGUE)
	_other = series
	if str(f.get_value("arena", "mode", SERIES)) != LEAGUE:
		use(SERIES)


## Loads one mode's fields from `section` into the top-level fields.
func _load_mode(f: ConfigFile, section: String, m: String) -> void:
	var n: int = MODES[m].size
	for key in ["trophies", "peak", "refresh_day", "refreshes", "wins", "losses", "raid_day", "week", "week_best"]:
		set(key, int(f.get_value(section, key, get(key))))
	for key in ["history", "pending", "raids", "chest"]:
		set(key, f.get_value(section, key, get(key)))
	var saved_trio: Array = f.get_value(section, "trio", trio)
	var saved_shots: Array = f.get_value(section, "shots", shots)
	if saved_trio.size() == n and saved_trio.all(func(c): return c in BallDefs.PLAYABLE):
		trio = saved_trio
	var saved_defence: Array = f.get_value(section, "defence", trio)
	if saved_defence.size() == n and saved_defence.all(func(c): return c in BallDefs.PLAYABLE):
		defence = saved_defence
	else:
		defence = trio.duplicate()
	if saved_shots.size() == n:
		shots = saved_shots
