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

const SAVE_PATH := "user://ghost_arena.cfg"
const HISTORY_SIZE := 10
const FREE_REFRESHES := 1

## Set by the arena fight scene so the home screen reopens on the Arena.
static var reopen := false

var path := SAVE_PATH
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
	s.boosts = {"spooky": {"health": 3, "attack": 4, "defense": 2, "speed": 1}, "nature": {"attack": 2, "health": 1}, "fire": {"speed": 1}}
	return s


static func today() -> int:
	var d := Time.get_date_dict_from_system()
	return d.year * 10000 + d.month * 100 + d.day


func offers(day: int = today()) -> Array[Dictionary]:
	return ArenaGhosts.offers(trophies, day, "local", refreshes if refresh_day == day else 0)


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
func set_slot(slot: int, critter: String) -> void:
	assert(critter in BallDefs.PLAYABLE, "Not playable: %s" % critter)
	var was: int = trio.find(critter)
	if was != -1 and was != slot:
		trio[was] = trio[slot]
	trio[slot] = critter
	save()


## The strongest trio from `owned` (strongest first): its first three.
## Repeats only when the player owns fewer than three critters.
static func best_trio(owned: Array) -> Array:
	var out: Array = []
	for i in 3:
		out.append(owned[i] if i < owned.size() else owned[i % owned.size()])
	return out


## Fills the trio with the strongest trio from `owned` (strongest first).
func fill_best(owned: Array) -> void:
	if owned.is_empty():
		return
	trio = best_trio(owned)
	save()


## Ranked trios use only critters the player owns, never a loaner or one
## they haven't got, and never the same critter twice (older saves could).
## Any other slot takes the strongest owned critter not already in the trio
## (`owned` is strongest first). Returns true if the trio changed.
func fit_to(owned: Array) -> bool:
	if owned.is_empty():
		return false
	var changed := false
	var seen: Array = []
	for i in trio.size():
		if trio[i] in owned and not trio[i] in seen:
			seen.append(trio[i])
			continue
		var spare: Array = owned.filter(func(id): return not id in seen and not id in trio.slice(i + 1))
		var pick: String = spare[0] if not spare.is_empty() else owned[i % owned.size()]
		if pick != trio[i]:
			trio[i] = pick
			changed = true
		seen.append(pick)
	if changed:
		save()
	return changed


## The trio as lineup slots (sim/lineup.gd): each critter at the tier, level
## and gear the player owns it with (Profile.slot_of). Without a profile, or
## for a critter not owned, a bare T1.
func slots(profile = null) -> Array:
	var out: Array = []
	for id in trio:
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
func lineup(profile = null) -> Dictionary:
	var out: Array = slots(profile)
	for i in out.size():
		out[i].aim = shots[i]
	return {"v": 1, "slots": out, "aim": shots.duplicate()}


func start_attack(card: String, bot_id: String, seed_value: int, attack_slots: Array = []) -> void:
	settle_abandoned()
	pending = {"card": card, "bot_id": bot_id, "seed": seed_value, "arena": Arenas.pick(seed_value),
		"slots": attack_slots if not attack_slots.is_empty() else slots()}
	save()


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
	var delta := Ladder.attack_delta(trophies, peak, pending.card, won)
	trophies += delta
	peak = maxi(peak, trophies)
	if delta > 0:
		points += delta
		points_earned += delta
	if won:
		wins += 1
	else:
		losses += 1
	var bot := ArenaGhosts.by_id(pending.bot_id)
	history.push_front({"name": bot.get("name", "?"), "card": pending.card, "won": won, "delta": delta})
	history = history.slice(0, HISTORY_SIZE)
	return delta


func save() -> void:
	var f := ConfigFile.new()
	for key in ["trophies", "peak", "trio", "shots", "refresh_day", "refreshes", "wins", "losses", "history", "pending", "points", "points_earned", "boosts"]:
		f.set_value("arena", key, get(key))
	f.save(path)


func _load() -> void:
	var f := ConfigFile.new()
	if f.load(path) != OK:
		return
	for key in ["trophies", "peak", "refresh_day", "refreshes", "wins", "losses"]:
		set(key, int(f.get_value("arena", key, get(key))))
	for key in ["history", "pending"]:
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
	if saved_shots.size() == 3:
		shots = saved_shots
