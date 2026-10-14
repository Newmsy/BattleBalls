## One player's week in The Spire (design/spire.md): the highest floor
## cleared, each critter's Stamina, first-clear rewards waiting to be
## collected and the log of clears (enough to replay every one).
##
## Pure logic, no nodes: the clock is passed in as unix seconds. Stored as
## JSON in user://spire.json (load_file / save_file), apart from the profile,
## so the fight scene can record a result without the menu being loaded.
extends RefCounted

const Spire := preload("res://sim/spire.gd")
const MatchSim := preload("res://sim/match_sim.gd")

const PATH := "user://spire.json"
const STAMINA := 3

var week := -1
## Highest floor cleared this week (0 = none). The next floor is cleared + 1.
var cleared := 0
## Critter id -> Stamina spent this week.
var spent: Dictionary = {}
## Floors cleared this week whose rewards haven't been added to the profile.
var unclaimed: Array = []
## One entry per clear: {floor, picks: [{id, power}], aims, rules}. With the
## week, each one replays the fight (Spire.relay_config).
var clears: Array = []
## The attempt in progress: {floor, picks: [{id, power}], launched}, or empty.
var pending: Dictionary = {}
## Best floor of the last week played, for its end-of-week badge.
var last_week_best := 0
var path := PATH


static func load_file(now: int, file_path := PATH):
	var c = load("res://meta/spire_climb.gd").new()
	c.path = file_path
	if FileAccess.file_exists(file_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(file_path))
		if parsed is Dictionary:
			c.from_dict(parsed)
	c.roll_week(now)
	return c


func save_file() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(to_dict()))


func to_dict() -> Dictionary:
	return {"week": week, "cleared": cleared, "spent": spent, "unclaimed": unclaimed, "clears": clears,
		"pending": pending, "last_week_best": last_week_best}


func from_dict(d: Dictionary) -> void:
	week = int(d.get("week", -1))
	cleared = int(d.get("cleared", 0))
	spent = {}
	var s = d.get("spent", {})
	if s is Dictionary:
		for id in s:
			spent[id] = int(s[id])
	unclaimed = (d.get("unclaimed", []) as Array).map(func(f): return int(f))
	clears = d.get("clears", [])
	pending = d.get("pending", {})
	last_week_best = int(d.get("last_week_best", 0))


## Starts a fresh tower when the week has changed. Rewards already earned
## stay claimable. Returns true on a reset.
func roll_week(now: int) -> bool:
	var w := Spire.week_of(now)
	if w == week:
		return false
	if week >= 0:
		last_week_best = cleared
	week = w
	cleared = 0
	spent = {}
	clears = []
	pending = {}
	return true


func next_floor() -> int:
	return cleared + 1


func finished() -> bool:
	return cleared >= Spire.FLOORS


func stamina(id: String) -> int:
	return maxi(0, STAMINA - int(spent.get(id, 0)))


func tired(id: String) -> bool:
	return stamina(id) <= 0


## The next floor's spec for this week.
func floor_spec(floor_no := -1) -> Dictionary:
	return Spire.floor_def(week, next_floor() if floor_no < 0 else floor_no)


## Checks a pick for the next floor. `picks` are [{id, power}] in order.
## Returns "" when it's fine, else why not.
func check_picks(picks: Array) -> String:
	if finished():
		return "You've cleared the whole Spire this week."
	var spec := floor_spec()
	if picks.is_empty():
		return "Pick at least one critter."
	if picks.size() > spec.lineup:
		return "This floor takes %d." % spec.lineup
	var seen := {}
	for p in picks:
		if seen.has(p.id):
			return "Each critter can only go in once."
		seen[p.id] = true
		if tired(p.id):
			return "%s is tired until Monday." % p.id
	return ""


## Records the start of an attempt on the next floor.
func begin(picks: Array) -> void:
	assert(check_picks(picks) == "", check_picks(picks))
	pending = {"floor": next_floor(), "picks": picks.duplicate(true), "launched": 0}


## Settles the pending attempt from its relay (sim/relay.gd). Every ball
## that came out spends Stamina, win or lose; a win clears the floor and
## queues its reward. An unfinished relay (the player quit) is a loss; pass
## `came_out` then, as the balls that had launched. Returns {won, floor, spent}.
func settle(relay, came_out := -1) -> Dictionary:
	if pending.is_empty():
		return {}
	var picks: Array = pending.picks
	if came_out < 0:
		came_out = int(relay.slot[0]) + 1
	came_out = clampi(came_out, 0, picks.size())
	var won: bool = relay.finished and relay.winner == 0
	var used: Array = []
	for i in came_out:
		var id: String = picks[i].id
		spent[id] = int(spent.get(id, 0)) + 1
		used.append(id)
	var floor_no := int(pending.floor)
	if won and floor_no == next_floor():
		cleared = floor_no
		unclaimed.append(floor_no)
		clears.append({"floor": floor_no, "picks": picks, "aims": relay.aims[0].duplicate(), "rules": MatchSim.RULES_VERSION})
	pending = {}
	return {"won": won, "floor": floor_no, "spent": used}


## Settles an attempt that was left without a result (the app closed
## mid-floor) as a loss for the balls that had launched (pending.launched,
## which the fight scene keeps up to date). Returns the ids that spent Stamina.
func abandon() -> Array:
	if pending.is_empty():
		return []
	var used: Array = []
	for i in mini(int(pending.get("launched", 0)), pending.picks.size()):
		var id: String = pending.picks[i].id
		spent[id] = int(spent.get(id, 0)) + 1
		used.append(id)
	pending = {}
	return used


## Rewards waiting to be collected, summed: {coins, orbs, xp_chips, gear: [rarity...], floors}.
func unclaimed_total() -> Dictionary:
	var t := {"coins": 0, "orbs": 0, "xp_chips": 0, "gear": [], "floors": unclaimed.duplicate()}
	for f in unclaimed:
		var r := Spire.reward(f)
		t.coins += r.coins
		t.orbs += r.orbs
		t.xp_chips += r.xp_chips
		if r.gear != "":
			t.gear.append(r.gear)
	return t


## Hands the waiting rewards over and forgets them. The caller adds them to
## the profile (see Spire screen) and saves.
func take_rewards() -> Dictionary:
	var t := unclaimed_total()
	unclaimed = []
	return t


## Seconds until Monday's reset.
func seconds_left(now: int) -> int:
	return maxi(0, Spire.week_end(week) - now)
