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
## so showing round 1 doesn't pay for the final.
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
		_play_series(m)
	_matches[key] = m
	return m


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


func _play_series(m: Dictionary) -> void:
	var need := FINAL_WINS_NEEDED if m.round == rounds - 1 else WINS_NEEDED
	var rng := Rng.new((seed_value * 31 + (m.round + 1) * 7919 + m.index * 104729) & Rng.MASK)
	var draws := 0
	while m.wins[0] < need and m.wins[1] < need:
		var n: int = m.games.size()
		var sides: Array = [m.a, m.b] if n % 2 == 0 else [m.b, m.a]
		var game_seed := int(rng.next_u32() & 0x7FFFFFFF)
		var sim := MatchSim.new({"seed": game_seed, "p1": sides[0], "p2": sides[1], "angles": [null, null]})
		var result := sim.run_to_end()
		var won: String = "" if result.winner < 0 else sides[result.winner]
		m.games.append({"seed": game_seed, "p1": sides[0], "p2": sides[1], "angles": sim.launch_angles.duplicate(),
			"winner": won, "reason": result.reason, "time": result.time, "hash": result.hash})
		if won == "":
			draws += 1
			if draws > MAX_EXTRA_GAMES:
				# Endless stalemate: the better seed goes through.
				var better: String = m.a if seed_of(m.a) < seed_of(m.b) else m.b
				m.winner = better
				return
			continue
		m.wins[0 if won == m.a else 1] += 1
	m.winner = m.a if m.wins[0] >= need else m.b
