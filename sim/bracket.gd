## Bracket of Legends: a single-elimination tournament between critters at
## equal power, worked out entirely from a seed and the entrant list, so every
## device (and anyone checking) gets the same bracket, the same fights and the
## same champion. See liveops/README.md for how a bracket is scheduled.
##
## Config: { seed: int, entrants: [type, ...] } (2 to 64 sim-playable ids,
## no repeats). The bracket is the next power of two up from the entrant count;
## the seed shuffles the entrants into a draw (seed 1 = first drawn) and the
## top seeds get the byes, in the usual bracket order (1 meets 2 only in the
## final).
##
## Every match is a series: first to 2 wins, the final first to 3. Game N's
## launch angles come from its own seed (derived from the bracket seed, the
## round, the match and N); the two critters swap corners every game. A drawn
## game doesn't count and another is played; after MAX_EXTRA_GAMES draws the
## better seed goes through.
##
## Matches are simulated the first time they are asked for and then cached,
## so showing round 1 doesn't pay for the final. work() fights them out a bit
## at a time (the game calls it once a frame), and results() / load_results()
## let the game keep finished matches on the device; the results are the same
## whichever way a match gets played.
extends RefCounted

const Rng := preload("res://sim/rng.gd")
const MatchSim := preload("res://sim/match_sim.gd")

const MAX_ENTRANTS := 64
const WINS_NEEDED := 2
const FINAL_WINS_NEEDED := 3
const MAX_EXTRA_GAMES := 3

var seed_value: int
## Entrants in draw order: draw[0] is seed 1.
var draw: Array = []
## Bracket size (a power of two) and number of rounds (size = 2^rounds).
var size := 2
var rounds := 1
## Round 0 slots, top to bottom: an entrant id, or "" for a bye.
var slots: Array = []

var _matches := {} ## "round:index" -> match
## The series work() is part-way through: { m, need, rng, draws, sim, sides, seed }.
var _job := {}


func _init(cfg: Dictionary) -> void:
	seed_value = int(cfg.get("seed", 1))
	var entrants: Array = cfg.get("entrants", [])
	assert(entrants.size() >= 2 and entrants.size() <= MAX_ENTRANTS, "A bracket needs 2-64 entrants")
	draw = entrants.duplicate()
	# Fisher-Yates with the bracket's own rng: the draw is the seed's alone.
	var rng := Rng.new(seed_value)
	for i in range(draw.size() - 1, 0, -1):
		var j := rng.range_int(0, i)
		var tmp = draw[i]
		draw[i] = draw[j]
		draw[j] = tmp
	while size < draw.size():
		size *= 2
		rounds += 1
	for s in seed_order(size):
		slots.append(draw[s - 1] if s <= draw.size() else "")


## Seed numbers top to bottom for a bracket of `n` slots: 1 and 2 can only
## meet in the final, 1-4 only in the semis, and so on. 8 -> 1 8 4 5 2 7 3 6.
static func seed_order(n: int) -> Array:
	var order := [1]
	while order.size() < n:
		var m := order.size() * 2
		var next := []
		for s in order:
			next.append_array([s, m + 1 - s])
		order = next
	return order


## 1 for seed 1 ... draw.size() for the last seed.
func seed_of(id: String) -> int:
	return draw.find(id) + 1


func matches_in(round_index: int) -> int:
	return size >> (round_index + 1)


## Every match of a round, top to bottom.
func round_matches(round_index: int) -> Array:
	var out := []
	for i in matches_in(round_index):
		out.append(get_match(round_index, i))
	return out


## { round, index, a, b, bye, games, wins: [a, b], winner } where a and b
## are entrant ids ("" for a bye) and each game is { seed, p1, p2, angles,
## winner (an id, "" for a draw), reason, time }.
func get_match(round_index: int, index: int) -> Dictionary:
	var key := "%d:%d" % [round_index, index]
	if _matches.has(key):
		return _matches[key]
	var a: String
	var b: String
	if round_index == 0:
		a = slots[index * 2]
		b = slots[index * 2 + 1]
	else:
		a = get_match(round_index - 1, index * 2).winner
		b = get_match(round_index - 1, index * 2 + 1).winner
	var m := {"round": round_index, "index": index, "a": a, "b": b, "bye": a == "" or b == "",
		"games": [], "wins": [0, 0], "winner": a if b == "" else b}
	if not m.bye:
		var job := _job if not _job.is_empty() and _job.m.round == round_index and _job.m.index == index else _start_series(m)
		_advance(job, Callable())
		_job = {}
		m = job.m
	_matches[key] = m
	return m


## Whether match (r, i) is already fought out (asking for it costs nothing).
func has_match(round_index: int, index: int) -> bool:
	return _matches.has("%d:%d" % [round_index, index])


## Only round 1 has byes: a top seed with no opponent.
func is_bye(round_index: int, index: int) -> bool:
	return round_index == 0 and (slots[index * 2] == "" or slots[index * 2 + 1] == "")


## Whether every match up to and including round `through` is fought out.
func ready_through(through: int) -> bool:
	return _next_missing(through).is_empty()


## [matches fought out, matches] for rounds 0 to `through`.
func progress(through: int) -> Array:
	var done := 0
	var total := 0
	for r in through + 1:
		for i in matches_in(r):
			total += 1
			done += 1 if has_match(r, i) else 0
	return [done, total]


## Fights out rounds 0 to `through` in order, a few ticks at a time, until
## `out_of_time` returns true (an empty Callable never does). Returns true
## once they are all done. Picks up where it left off on the next call.
func work(through: int, out_of_time: Callable) -> bool:
	while true:
		var next := _next_missing(through)
		if next.is_empty():
			return true
		if is_bye(next[0], next[1]):
			get_match(next[0], next[1])
			continue
		if _job.is_empty() or _job.m.round != next[0] or _job.m.index != next[1]:
			_job = _start_series({"round": next[0], "index": next[1],
				"a": get_match(next[0] - 1, next[1] * 2).winner if next[0] > 0 else slots[next[1] * 2],
				"b": get_match(next[0] - 1, next[1] * 2 + 1).winner if next[0] > 0 else slots[next[1] * 2 + 1],
				"bye": false, "games": [], "wins": [0, 0], "winner": ""})
		if not _advance(_job, out_of_time):
			return false
		_matches["%d:%d" % next] = _job.m
		_job = {}
		if out_of_time.is_valid() and out_of_time.call():
			return ready_through(through)
	return true


## Every finished match, for keeping on the device.
func results() -> Dictionary:
	return {"key": cache_key(), "matches": _matches.duplicate(true)}


## Takes back what results() gave, if it was for this same bracket.
func load_results(saved) -> void:
	if not saved is Dictionary or saved.get("key") != cache_key() or not saved.get("matches") is Dictionary:
		return
	for key in saved.matches:
		var m: Dictionary = saved.matches[key]
		# JSON brings numbers back as floats.
		for k in ["round", "index"]:
			m[k] = int(m[k])
		m.wins = [int(m.wins[0]), int(m.wins[1])]
		for g in m.games:
			g.seed = int(g.seed)
			g.angles = [int(g.angles[0]), int(g.angles[1])]
		_matches[key] = m


## Changes whenever the same seed would give different fights.
func cache_key() -> String:
	return "%d|%d|%s" % [seed_value, MatchSim.RULES_VERSION, ",".join(draw)]


func _next_missing(through: int) -> Array:
	for r in through + 1:
		for i in matches_in(r):
			if not has_match(r, i):
				return [r, i]
	return []


func champion() -> String:
	return get_match(rounds - 1, 0).winner


## The round an entrant went out in (rounds for the champion).
func reached(id: String) -> int:
	for r in rounds:
		for m in round_matches(r):
			if (m.a == id or m.b == id) and m.winner != id:
				return r
	return rounds


## "Round of 64" ... "Quarter-finals", "Semi-finals", "Final".
func round_name(round_index: int) -> String:
	var left := rounds - round_index
	match left:
		1: return "Final"
		2: return "Semi-finals"
		3: return "Quarter-finals"
	return "Round of %d" % (size >> round_index)


## Hash over every game's fight hash; equal hashes mean identical brackets.
func state_hash() -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	for r in rounds:
		for m in round_matches(r):
			for g in m.games:
				ctx.update(String(g.hash).to_utf8_buffer())
	return ctx.finish().hex_encode()


func _start_series(m: Dictionary) -> Dictionary:
	return {"m": m, "need": FINAL_WINS_NEEDED if m.round == rounds - 1 else WINS_NEEDED,
		"rng": Rng.new((seed_value * 31 + (m.round + 1) * 7919 + m.index * 104729) & Rng.MASK),
		"draws": 0, "sim": null, "sides": [], "seed": 0}


## Plays the series on. Returns true once it is decided, or false when
## `out_of_time` (checked every few ticks; an empty Callable never runs out)
## says to stop for now.
func _advance(job: Dictionary, out_of_time: Callable) -> bool:
	var m: Dictionary = job.m
	var max_ticks := int(MatchSim.TIME_LIMIT * MatchSim.TICK_RATE) + 1
	while true:
		if job.sim == null:
			if m.wins[0] >= job.need or m.wins[1] >= job.need:
				m.winner = m.a if m.wins[0] >= job.need else m.b
				return true
			var n: int = m.games.size()
			job.sides = [m.a, m.b] if n % 2 == 0 else [m.b, m.a]
			job.seed = int(job.rng.next_u32() & 0x7FFFFFFF)
			job.sim = MatchSim.new({"seed": job.seed, "p1": job.sides[0], "p2": job.sides[1], "angles": [null, null]})
		var sim = job.sim
		while not sim.finished and sim.tick <= max_ticks:
			sim.step()
			if sim.tick % 30 == 0 and out_of_time.is_valid() and out_of_time.call():
				return false
		var result: Dictionary = sim.summary()
		var won: String = "" if result.winner < 0 else job.sides[result.winner]
		m.games.append({"seed": job.seed, "p1": job.sides[0], "p2": job.sides[1], "angles": sim.launch_angles.duplicate(),
			"winner": won, "reason": result.reason, "time": result.time, "hash": result.hash})
		job.sim = null
		if won == "":
			job.draws += 1
			if job.draws > MAX_EXTRA_GAMES:
				# Endless stalemate: the better seed goes through.
				m.winner = m.a if seed_of(m.a) < seed_of(m.b) else m.b
				return true
			continue
		m.wins[0 if won == m.a else 1] += 1
	return true
