## The player's Ghost Arena state on this device: trophies, peak, their trio
## (which attacks and, once online, defends), the shots it last used, the
## daily card refresh, and the attack in progress. Until the online trophy
## rules land this is the source of truth; the server takes over trophies
## later and this keeps the trio and shots.
extends RefCounted

const Ladder := preload("res://game/pvp/ladder.gd")
const ArenaGhosts := preload("res://game/pvp/arena_ghosts.gd")
const BallDefs := preload("res://sim/ball_defs.gd")

const SAVE_PATH := "user://ghost_arena.cfg"
const HISTORY_SIZE := 10
const FREE_REFRESHES := 1

## Set by the arena fight scene so the home screen reopens on the Arena.
static var reopen := false

var path := SAVE_PATH
var trophies := 0
var peak := 0 ## Best trophies this season (sets the league floor).
var trio: Array = ["vampire", "laser", "vampire"]
var shots: Array = [0, 0, 0] ## Launch offsets off the centre line, tenths of a degree.
var refresh_day := 0
var refreshes := 0
var wins := 0
var losses := 0
var history: Array = [] ## Newest first: {name, card, won, delta}
## The attack in progress: {card, bot_id, seed}. A started attack is a spent
## attack, so one left unfinished counts as a loss next time the Arena opens.
var pending: Dictionary = {}


static func open(save_path := SAVE_PATH):
	var s = load("res://game/pvp/arena_store.gd").new()
	s.path = save_path
	s._load()
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


func set_slot(slot: int, critter: String) -> void:
	assert(critter in BallDefs.PLAYABLE, "Not playable: %s" % critter)
	trio[slot] = critter
	save()


## Ranked trios use only critters the player owns: never a loaner or one
## they haven't got. Swaps any other slot for the first owned critter.
## Returns true if the trio changed.
func fit_to(owned: Array) -> bool:
	if owned.is_empty():
		return false
	var changed := false
	for i in trio.size():
		if not trio[i] in owned:
			trio[i] = owned[0]
			changed = true
	if changed:
		save()
	return changed


## The trio as a lineup in the backend's v1 shape, plus per-slot shots.
func lineup() -> Dictionary:
	var slots: Array = []
	for i in trio.size():
		slots.append({"critter": trio[i], "tier": 1, "level": 1, "gear": {}, "aim": shots[i]})
	return {"v": 1, "slots": slots, "aim": shots.duplicate()}


func start_attack(card: String, bot_id: String, seed_value: int) -> void:
	settle_abandoned()
	pending = {"card": card, "bot_id": bot_id, "seed": seed_value}
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
	for key in ["trophies", "peak", "trio", "shots", "refresh_day", "refreshes", "wins", "losses", "history", "pending"]:
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
	var saved_trio: Array = f.get_value("arena", "trio", trio)
	var saved_shots: Array = f.get_value("arena", "shots", shots)
	if saved_trio.size() == 3 and saved_trio.all(func(c): return c in BallDefs.PLAYABLE):
		trio = saved_trio
	if saved_shots.size() == 3:
		shots = saved_shots
