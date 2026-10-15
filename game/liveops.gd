## Live-ops calendar: the season, the weekly Critter Spotlight, Chaos
## Weekends, the Fight of the Day and the Try-a-Critter loaner, read from one schedule file
## (liveops/liveops.json, see liveops/README.md) so a season can be planned
## ahead without an app update.
##
## The schedule ships inside the build and is refreshed from the web at boot
## (fetch()); a fetched copy is cached and wins while it is valid. Anything the
## schedule leaves out falls back to a rotation worked out from the clock, so
## the board always shows something sensible offline.
##
## All dates are UTC. Weeks start Monday 00:00; Chaos Weekends run Friday
## 00:00 to Monday 00:00 (design/events.md).
extends RefCounted

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Rng := preload("res://sim/rng.gd")
const Roster := preload("res://game/ui/roster.gd")
const Derby := preload("res://sim/derby.gd")

const BUNDLED := "res://liveops/liveops.json"
const CACHE := "user://liveops.json"
const REMOTE := "https://battleballs.vercel.app/liveops.json"

const DAY := 86400
const WEEK := 7 * DAY
## Monday 2026-01-05 00:00 UTC: week 0 of every fallback rotation (matches
## the Chaos Weekend rotation in sim/modifiers.gd).
const EPOCH := 1767571200
const WEEKEND_START := 4 * DAY ## Friday, from Monday 00:00.

## Chaos Weekend rotation and display text. sim/modifiers.gd owns the rules;
## this copy keeps the board working without it.
const CHAOS_ROTATION := ["big_head", "glass_cannon", "mirror_match", "hyper_speed", "closing_walls", "double_trouble"]
const CHAOS_TEXT := {
	"big_head": ["Big Head", "Every ball is 1.35x bigger. More bumps, fewer misses."],
	"glass_cannon": ["Glass Cannon", "Three quarters HP, 1.5x damage. Fights end fast."],
	"mirror_match": ["Mirror Match", "Both sides get the same random ball. Only your aim decides."],
	"hyper_speed": ["Hyper Speed", "Every ball moves 1.4x faster. Beams fade faster too."],
	"closing_walls": ["Closing Walls", "Overtime starts at 10 seconds: the arena shrinks early."],
	"double_trouble": ["Double Trouble", "Abilities hit 1.5x harder: bigger heals, more beams at once."],
}

## Bounce Derby #1 is 2026-10-14 (the same launch day as Trick Shot).
const DERBY_EPOCH := 1791936000
## Course colour themes for derby events (render only, game/derby_view.gd).
const DERBY_THEMES := ["neon", "spooky", "frost", "festive"]
const DERBY_MAX_RACERS := 8

## Fight of the Day generator: keep the first seed whose fight is close.
const FIGHT_TRIES := 12
const CLOSE_HP := 0.45 ## Winner ends at or under this fraction of its HP.
const FIGHT_TIME := [12.0, 70.0] ## Seconds.

## Set to pin the clock (tests, ?today=YYYY-MM-DD). 0 means the real clock.
static var now_override := 0
static var _data := {}
static var _fights := {}


static func now() -> int:
	return now_override if now_override > 0 else int(Time.get_unix_time_from_system())


## The schedule in use: a valid cached download, else the bundled file.
static func data() -> Dictionary:
	if _data.is_empty():
		_data = _read(BUNDLED)
		var cached := _read(CACHE)
		if not cached.is_empty() and validate(cached).is_empty() and int(cached.revision) >= int(_data.get("revision", 0)):
			_data = cached
	return _data


## Use `d` from now on (tests, or a fresh download).
static func use(d: Dictionary) -> void:
	_data = d
	_fights.clear()


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Downloads the schedule (web builds read it from their own site). Calls
## `on_change` if the download is valid and differs from the one in use.
static func fetch(parent: Node, on_change: Callable) -> void:
	var url := REMOTE
	if OS.has_feature("web"):
		url = str(JavaScriptBridge.eval("location.origin + location.pathname.replace(/[^/]*$/, '') + 'liveops.json'", true))
	var req := HTTPRequest.new()
	req.timeout = 10.0
	parent.add_child(req)
	req.request_completed.connect(func(result: int, code: int, _headers, body: PackedByteArray):
		req.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			return
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		if not parsed is Dictionary or not validate(parsed).is_empty():
			print("LIVEOPS rejected download from ", url)
			return
		if int(parsed.revision) < int(_read(BUNDLED).get("revision", 0)):
			return
		var f := FileAccess.open(CACHE, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(parsed))
		if JSON.stringify(parsed) != JSON.stringify(data()):
			use(parsed)
			on_change.call())
	if req.request(url) != OK:
		req.queue_free()


# --- Validation ----------------------------------------------------------------

## Every problem with a schedule, or [] if it is good to use.
static func validate(d: Dictionary) -> Array:
	var errors := []
	for key in ["version", "revision"]:
		if not _num(d.get(key)):
			errors.append("%s must be a number" % key)
	for key in ["seasons", "spotlight", "chaos", "fights", "loaners", "derbies"]:
		if not d.get(key, []) is Array:
			errors.append("%s must be a list" % key)
			return errors
	for s in d.get("seasons", []):
		if not (s is Dictionary and s.get("name") is String and _num(s.get("weeks")) and s.weeks >= 1):
			errors.append("season needs a name and weeks: %s" % [s])
		elif _monday(s.get("start")) < 0:
			errors.append("season %s must start on a Monday" % s.name)
	for s in d.get("spotlight", []):
		if not s is Dictionary or _monday(s.get("week")) < 0:
			errors.append("spotlight week must be a Monday: %s" % [s])
		elif Roster.CRITTERS.all(func(c): return c.id != s.get("critter")):
			errors.append("spotlight critter unknown: %s" % [s.get("critter")])
	for c in d.get("chaos", []):
		if not c is Dictionary or date_unix(c.get("weekend")) < 0 or _weekday(date_unix(c.weekend)) != 4:
			errors.append("chaos weekend must be a Friday: %s" % [c])
		elif not CHAOS_TEXT.has(c.get("modifier")):
			errors.append("chaos modifier unknown: %s" % [c.get("modifier")])
	# A loaner only has to be a known critter: a newer schedule may name one
	# this build cannot play yet, and loaner() falls back for that day.
	for l in d.get("loaners", []):
		if not l is Dictionary or date_unix(l.get("date")) < 0:
			errors.append("loaner needs a date: %s" % [l])
		elif Roster.CRITTERS.all(func(c): return c.id != l.get("critter")):
			errors.append("loaner critter unknown: %s" % [l.get("critter")])
	for e in d.get("derbies", []):
		errors.append_array(_derby_errors(e))
	for f in d.get("fights", []):
		if not f is Dictionary or date_unix(f.get("date")) < 0:
			errors.append("fight needs a date: %s" % [f])
		elif not (f.get("p1") in BallDefs.PLAYABLE and f.get("p2") in BallDefs.PLAYABLE):
			errors.append("fight balls must be playable: %s" % [f])
		elif not _num(f.get("seed")):
			errors.append("fight needs a seed: %s" % [f])
		elif f.has("angles") and not (f.angles is Array and f.angles.size() == 2 and f.angles.all(_num)):
			errors.append("fight angles must be two numbers: %s" % [f])
	return errors


static func _derby_errors(e) -> Array:
	if not e is Dictionary or date_unix(e.get("start")) < 0 or not e.get("title") is String or e.title == "":
		return ["derby needs a start date and a title: %s" % [e]]
	if e.has("end") and date_unix(e.end) < date_unix(e.start):
		return ["derby %s must end on or after its start" % e.title]
	if e.has("theme") and not e.theme in DERBY_THEMES:
		return ["derby %s theme unknown: %s" % [e.title, e.theme]]
	if e.has("seed") and not _num(e.seed):
		return ["derby %s seed must be a number" % e.title]
	if e.has("racers"):
		var ids = e.racers
		if not ids is Array or ids.size() < 2 or ids.size() > DERBY_MAX_RACERS:
			return ["derby %s needs 2-%d racers" % [e.title, DERBY_MAX_RACERS]]
		for id in ids:
			if Roster.CRITTERS.all(func(c): return c.id != id) or ids.count(id) > 1:
				return ["derby %s racer unknown or repeated: %s" % [e.title, id]]
	return []


static func _num(v) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT]


## Unix time of a "YYYY-MM-DD" date (UTC midnight), or -1.
static func date_unix(s) -> int:
	if not s is String or RegEx.create_from_string("^\\d{4}-\\d{2}-\\d{2}$").search(s) == null:
		return -1
	var p: PackedStringArray = s.split("-")
	var y := int(p[0])
	var m := int(p[1])
	var leap := y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)
	if m < 1 or m > 12 or int(p[2]) < 1 or int(p[2]) > [31, 29 if leap else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]:
		return -1
	return Time.get_unix_time_from_datetime_string(s)


static func _monday(s) -> int:
	var t := date_unix(s)
	return t if t >= 0 and _weekday(t) == 0 else -1


## 0 = Monday ... 6 = Sunday.
static func _weekday(t: int) -> int:
	return posmod(floori(float(t - EPOCH) / DAY), 7)


static func week_start(t: int) -> int:
	return EPOCH + floori(float(t - EPOCH) / WEEK) * WEEK


static func day_start(t: int) -> int:
	return EPOCH + floori(float(t - EPOCH) / DAY) * DAY


static func _week_index(t: int) -> int:
	return floori(float(t - EPOCH) / WEEK)


# --- What's on -------------------------------------------------------------------

## { name, week, weeks, ends } for the season running at `t`, or {}.
static func season(t: int) -> Dictionary:
	for s in data().get("seasons", []):
		var start := _monday(s.start)
		var end := start + int(s.weeks) * WEEK
		if t >= start and t < end:
			return {"name": s.name, "week": (t - start) / WEEK + 1, "weeks": int(s.weeks), "ends": end}
	return {}


## { critter, blurb, ends } for the Spotlight week holding `t`.
static func spotlight(t: int) -> Dictionary:
	var week := week_start(t)
	for s in data().get("spotlight", []):
		if _monday(s.week) == week:
			return {"critter": s.critter, "blurb": s.get("blurb", ""), "ends": week + WEEK}
	# Fallback: rotate through the Rare and better critters.
	var pool: Array = Roster.CRITTERS.filter(func(c): return c.rarity != "common")
	return {"critter": pool[posmod(_week_index(t), pool.size())].id, "blurb": "", "ends": week + WEEK}


## This week's Chaos Weekend: { modifier, name, description, starts, ends,
## live }. Before Friday it is the coming weekend; on the weekend it is live.
static func chaos(t: int) -> Dictionary:
	var starts := week_start(t) + WEEKEND_START
	var id: String = CHAOS_ROTATION[posmod(_week_index(t), CHAOS_ROTATION.size())]
	for c in data().get("chaos", []):
		if date_unix(c.weekend) == starts:
			id = c.modifier
	var text: Array = CHAOS_TEXT[id]
	return {"modifier": id, "name": text[0], "description": text[1], "starts": starts, "ends": starts + 3 * DAY, "live": t >= starts}


## Today's Try-a-Critter loaner: { critter, blurb, date, ends }. A scheduled
## critter this build cannot fight with is skipped for the rotation, which
## walks the playable critters rarest first, one a day.
static func loaner(t: int) -> Dictionary:
	var day := day_start(t)
	var date := Time.get_date_string_from_unix_time(day)
	for l in data().get("loaners", []):
		if l.date == date and l.critter in BallDefs.PLAYABLE:
			return {"critter": l.critter, "blurb": l.get("blurb", ""), "date": date, "ends": day + DAY}
	var pool := loaner_pool()
	var id: String = pool[posmod(floori(float(day - EPOCH) / DAY), pool.size())]
	return {"critter": id, "blurb": "", "date": date, "ends": day + DAY}


## Critters that can be lent: on the roster and playable in the sim, rarest first.
static func loaner_pool() -> Array:
	var pool: Array = Roster.CRITTERS.filter(func(c): return c.id in BallDefs.PLAYABLE)
	var rank := func(c): return Roster.RARITIES.find(c.rarity) * 1000 - Roster.CRITTERS.find(c)
	pool.sort_custom(func(a, b): return rank.call(a) > rank.call(b))
	return pool.map(func(c): return c.id)


## Today's Bounce Derby: { number, date, title, blurb, theme, seed, racers,
## event, ends }. Every device gets the same race on the same day (so a
## Discord watch party sees one race), and a scheduled derby event renames
## it, picks its theme and can pin its racers or seed.
static func derby(t: int) -> Dictionary:
	var day := day_start(t)
	var date := Time.get_date_string_from_unix_time(day)
	var number := floori(float(day - DERBY_EPOCH) / DAY) + 1
	var out := {"number": number, "date": date, "title": "Bounce Derby", "blurb": "", "theme": "neon",
		"seed": number * 7349 + 101, "racers": Derby.draw_racers(number * 7349 + 101), "event": false, "ends": day + DAY}
	for e in data().get("derbies", []):
		var start := date_unix(e.start)
		var end := date_unix(e.get("end", e.start))
		if day < start or day > end:
			continue
		out.title = e.title
		out.blurb = e.get("blurb", "")
		out.theme = e.get("theme", "neon")
		out.event = true
		out.ends = end + DAY
		if e.has("seed"):
			out.seed = int(e.seed)
			out.racers = Derby.draw_racers(out.seed)
		if e.has("racers"):
			out.racers = e.racers.duplicate()
	return out


## Today's Fight of the Day: { date, p1, p2, seed, angles, title, winner,
## time }. `winner` is 0 or 1 (the sim is deterministic, so it is known).
static func fight_of_the_day(t: int) -> Dictionary:
	var day := day_start(t)
	if _fights.has(day):
		return _fights[day]
	var date := Time.get_date_string_from_unix_time(day)
	var fight := {}
	for f in data().get("fights", []):
		if f.date == date:
			var angles: Array = f.get("angles", [null, null]).map(func(a): return null if a == null else int(a))
			fight = _play({"p1": f.p1, "p2": f.p2, "seed": int(f.seed), "angles": angles})
			fight.title = f.get("title", "")
	if fight.is_empty():
		fight = _generate(floori(float(day - EPOCH) / DAY))
	fight.date = date
	_fights[day] = fight
	return fight


## A close fight picked from the day number alone.
static func _generate(day: int) -> Dictionary:
	var rng := Rng.new(day * 7907 + 3)
	var p1: String = BallDefs.PLAYABLE[rng.range_int(0, BallDefs.PLAYABLE.size() - 1)]
	# A cross matchup when there is one: that's the showcase.
	var others: Array = BallDefs.PLAYABLE.filter(func(id): return id != p1)
	var p2: String = p1 if others.is_empty() else others[rng.range_int(0, others.size() - 1)]
	var fallback := {}
	for k in FIGHT_TRIES:
		var f := _play({"p1": p1, "p2": p2, "seed": rng.range_int(1, 99999), "angles": [null, null]})
		if f.winner < 0:
			continue
		if fallback.is_empty():
			fallback = f
		if f.close:
			return f
	return fallback


## Runs the fight to the end. Returns the config with the launch angles
## resolved, plus winner, time and whether it was close.
static func _play(config: Dictionary) -> Dictionary:
	var sim := MatchSim.new(config)
	var angles := [sim.launch_angles[0], sim.launch_angles[1]]
	while not sim.finished:
		sim.step()
	var close := false
	if sim.winner >= 0:
		var w = sim.balls[sim.winner]
		close = w.hp / w.max_hp <= CLOSE_HP and sim.time() >= FIGHT_TIME[0] and sim.time() <= FIGHT_TIME[1]
	return {"p1": config.p1, "p2": config.p2, "seed": config.seed, "angles": angles, "title": "",
		"winner": sim.winner, "time": sim.time(), "close": close}


## "2d 4h", "3h 12m" or "45m": time left until `until`.
static func countdown(t: int, until: int) -> String:
	var s := maxi(0, until - t)
	if s >= DAY:
		return "%dd %dh" % [s / DAY, (s % DAY) / 3600]
	if s >= 3600:
		return "%dh %dm" % [s / 3600, (s % 3600) / 60]
	return "%dm" % maxi(1, s / 60)
