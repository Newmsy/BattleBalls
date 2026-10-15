## Bracket of Legends, the event around sim/bracket.gd: when each bracket
## runs (from the live-ops schedule), which rounds are out, the player's
## champion pick, and the pick shares from the online backend.
##
## Timeline, all UTC: picks open the Monday before the bracket's week. Rounds
## come out one a day at 00:00 so that the final always lands on the Sunday
## (64 entrants: Tuesday to Sunday; 8 entrants: Friday to Sunday). Picks lock
## when the first round comes out. Results stay up for another week.
##
## The bracket itself is the same on every device: it comes from the seed and
## the entrant list alone. When a schedule entry leaves `entrants` out, every
## critter playable in this build enters (a seeded 64 of them past 64).
extends RefCounted

const LiveOps := preload("res://game/liveops.gd")
const Bracket := preload("res://sim/bracket.gd")
const BallDefs := preload("res://sim/ball_defs.gd")

const SAVE_PATH := "user://legends.cfg"
const DAY := LiveOps.DAY
const WEEK := LiveOps.WEEK
const SHOW_AFTER := WEEK ## Results stay on the board this long after the final.

static var _brackets := {}


## Every scheduled bracket, oldest first: { id, name, week (unix Monday),
## seed, entrants }. Seasons without an entry get one in their last week.
static func events() -> Array:
	var d := LiveOps.data()
	var out := []
	var listed := []
	for b in d.get("brackets", []):
		var week := LiveOps.date_unix(b.week)
		listed.append(week)
		out.append(_event(b.get("name", "Bracket of Legends"), week, int(b.seed), b.get("entrants", [])))
	for s in d.get("seasons", []):
		var start := LiveOps.date_unix(s.start)
		var end := start + int(s.weeks) * WEEK
		if listed.any(func(w): return w >= start and w < end):
			continue
		var week := end - WEEK
		# A seed from the season's dates alone, so every device agrees.
		out.append(_event("%s Bracket of Legends" % s.name, week, (week / DAY) * 7919 + 1, []))
	out.sort_custom(func(x, y): return x.week < y.week)
	return out


static func _event(name: String, week: int, seed_value: int, entrants: Array) -> Dictionary:
	var e: Array = entrants if not entrants.is_empty() else _field(seed_value)
	return {"id": "%s-%d" % [Time.get_date_string_from_unix_time(week), seed_value], "name": name,
		"week": week, "seed": seed_value, "entrants": e}


## Every live critter, or a seeded pick of MAX_ENTRANTS of them once the
## roster outgrows a bracket (same pick on every device).
static func _field(seed_value: int) -> Array:
	var ids: Array = BallDefs.PLAYABLE.duplicate()
	if ids.size() <= Bracket.MAX_ENTRANTS:
		return ids
	var rng := Bracket.Rng.new(seed_value)
	for i in Bracket.MAX_ENTRANTS:
		var j := rng.range_int(i, ids.size() - 1)
		var t = ids[i]
		ids[i] = ids[j]
		ids[j] = t
	return ids.slice(0, Bracket.MAX_ENTRANTS)


## The bracket on the board at `t` (picks open, running or just finished), or {}.
static func current(t: int) -> Dictionary:
	var found := {}
	for ev in events():
		if t >= opens(ev) and t < ev.week + WEEK + SHOW_AFTER:
			found = ev
	return found


## The next bracket after `t`, or {}.
static func next_event(t: int) -> Dictionary:
	for ev in events():
		if opens(ev) > t:
			return ev
	return {}


static func bracket(ev: Dictionary) -> Bracket:
	if not _brackets.has(ev.id):
		_brackets[ev.id] = Bracket.new({"seed": ev.seed, "entrants": ev.entrants})
	return _brackets[ev.id]


static func round_count(ev: Dictionary) -> int:
	var n := 1
	while (1 << n) < ev.entrants.size():
		n += 1
	return n


static func opens(ev: Dictionary) -> int:
	return ev.week - WEEK


## When round `r` comes out: the final on Sunday, earlier rounds a day apart.
static func reveal_at(ev: Dictionary, r: int) -> int:
	return ev.week + (7 - round_count(ev) + r) * DAY


static func locks(ev: Dictionary) -> int:
	return reveal_at(ev, 0)


## How many rounds are out at `t` (0 while picks are open).
static func rounds_out(ev: Dictionary, t: int) -> int:
	var n := 0
	for r in round_count(ev):
		if t >= reveal_at(ev, r):
			n += 1
	return n


## "picks" (before the lock), "live" (rounds coming out) or "done".
static func phase(ev: Dictionary, t: int) -> String:
	if t < locks(ev):
		return "picks"
	return "done" if rounds_out(ev, t) >= round_count(ev) else "live"


# --- The player's pick and what they've watched ----------------------------------

static func _cfg() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	return cfg


## The champion the player picked for `ev`, or "".
static func pick_of(ev: Dictionary) -> String:
	return _cfg().get_value("picks", ev.id, "")


## Picks (or changes) the champion. Refused once picks lock.
static func set_pick(ev: Dictionary, id: String, t: int) -> bool:
	if t >= locks(ev) or not id in ev.entrants:
		return false
	var cfg := _cfg()
	cfg.set_value("picks", ev.id, id)
	cfg.save(SAVE_PATH)
	return true


## Results of the latest round are hidden until the player opens them, so the
## day's matches aren't spoiled by the bracket view.
static func is_seen(ev: Dictionary, r: int, i: int) -> bool:
	return _cfg().get_value("seen", "%s:%d:%d" % [ev.id, r, i], false)


static func mark_seen(ev: Dictionary, r: int, i: int) -> void:
	var cfg := _cfg()
	cfg.set_value("seen", "%s:%d:%d" % [ev.id, r, i], true)
	cfg.save(SAVE_PATH)


## Whether match (r, i) shows its winner at `t`: rounds before today's always
## do; today's round once the player has opened that match (or it's a bye).
static func shows_result(ev: Dictionary, r: int, i: int, t: int) -> bool:
	var out := rounds_out(ev, t)
	if r >= out:
		return false
	if r < out - 1 or bracket(ev).get_match(r, i).bye:
		return true
	return is_seen(ev, r, i)


## Whether the player has seen who won the whole thing.
static func champion_known(ev: Dictionary, t: int) -> bool:
	return shows_result(ev, round_count(ev) - 1, 0, t)


## Brackets the player called right: [{ name, champion }], newest first.
## The reward is the "Oracle" title for that bracket (cosmetic only).
static func oracle_titles(t: int) -> Array:
	var out := []
	for ev in events():
		if phase(ev, t) == "done" and pick_of(ev) != "" and pick_of(ev) == bracket(ev).champion():
			out.push_front({"name": ev.name, "champion": pick_of(ev)})
	return out


# --- Online ---------------------------------------------------------------------

## Sends the pick to the server (it stamps the time; picks after the lock
## don't count there). Best effort: offline it just stays on the device.
static func submit_pick(backend, ev: Dictionary, id: String) -> void:
	if backend == null or not backend.enabled():
		return
	await backend.call_rpc("predict_bracket", {"p_event": ev.id, "p_champion": id})


## { critter id: share 0..1 } of everyone's picks, or {} offline.
static func pick_shares(backend, ev: Dictionary) -> Dictionary:
	if backend == null or not backend.enabled():
		return {}
	var res: Dictionary = await backend.call_rpc("bracket_pick_shares", {"p_event": ev.id})
	if not res.ok or not res.data is Array:
		return {}
	var total := 0
	for row in res.data:
		total += int(row.get("picks", 0))
	var out := {}
	for row in res.data:
		if total > 0:
			out[str(row.get("champion", ""))] = float(row.picks) / total
	return out
