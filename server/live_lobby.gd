## The live-fight referee's rules, without any networking (server/live_server.gd
## carries the messages). Pairs queued players by power, collects both launch
## angles, then runs the fight itself: the server's result is the one that
## counts, the phones replay it for the show and report their end hash so a
## desync or an edited client shows up. See design/live-quick-fight.md.
##
## Every call returns the messages to send as [[player_id, message], ...].
## Time is passed in (seconds), so tests can drive it.
extends RefCounted

const MatchSim := preload("res://sim/match_sim.gd")
const Lineup := preload("res://sim/lineup.gd")
const LiveMatch := preload("res://sim/live_match.gd")

const MODES := {"1v1": 1, "2v2": 2} ## Slots each player brings.
const POWER_BAND := 0.10 ## Pair within ±10% Power Rating...
const BAND_GROWTH := 0.05 ## ...widening by 5% for every BAND_STEP seconds waited.
const BAND_STEP := 5.0
const GHOST_AFTER := 15.0 ## No match by then: the phone fights a ghost instead.
const AIM_SECONDS := 12.0 ## Aim window; a missing angle comes from the seed.
## Friends meet in a room (a key both phones send): paired whatever their
## power, never given a ghost, and told after ROOM_WAIT that nobody came.
const ROOM_WAIT := 90.0
const ROOM_CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:-"
const ROOM_MAX := 40

## player_id -> {mode, slots, rating, since, room}
var queue := {}
## match_id -> {players: [a, b], seed, sides: [slots, slots], aims: [angle|null, angle|null], deadline, result, hashes}
var matches := {}
## player_id -> match_id while matched.
var in_match := {}
## Hash mismatches seen: [{match, player, theirs, ours}], for the stats screen.
var mismatches: Array = []
var finished := 0

var _next_id := 1
var _seeds: Callable


## seeds: returns a fresh fight seed (the server uses crypto randomness; tests a counter).
func _init(seeds: Callable) -> void:
	_seeds = seeds


func join(pid: String, mode: String, raw_slots: Array, now: float, room := "") -> Array:
	var slots: Array = LiveMatch.clean_slots(raw_slots, MODES.get(mode, 0)) if MODES.has(mode) else []
	if slots.is_empty():
		return [[pid, {"t": "error", "code": "bad_setup"}]]
	leave(pid)
	var rating := 0
	for s in slots:
		rating += Lineup.rating(s)
	room = clean_room(room)
	queue[pid] = {"mode": mode, "slots": slots, "rating": rating, "since": now, "room": room}
	return [[pid, {"t": "queued", "rating": rating, "room": room}]]


## Upper-case letters, digits, ":" and "-" only, at most ROOM_MAX long.
static func clean_room(room: String) -> String:
	var out := ""
	for c in room.to_upper().left(ROOM_MAX):
		if ROOM_CHARS.contains(c):
			out += c
	return out


## A player left (closed the socket or cancelled). Mid-aim, their angle will
## come from the seed; mid-fight, nothing changes: the server has the result.
func leave(pid: String) -> void:
	queue.erase(pid)


func aim(pid: String, match_id: int, angle: int, now: float) -> Array:
	var m: Dictionary = matches.get(match_id, {})
	if m.is_empty() or m.result != null or in_match.get(pid, -1) != match_id:
		return []
	var side: int = m.players.find(pid)
	if m.aims[side] == null:
		m.aims[side] = clampi(angle, -1800, 1799)
	if m.aims[0] != null and m.aims[1] != null:
		return _resolve(match_id)
	return []


## A phone's end-of-fight hash. Only compared, never trusted.
func report(pid: String, match_id: int, end_hash: String) -> void:
	var m: Dictionary = matches.get(match_id, {})
	if m.is_empty() or m.result == null or not pid in m.players:
		return
	m.hashes[pid] = end_hash
	if end_hash != m.result.hash:
		mismatches.append({"match": match_id, "player": pid, "theirs": end_hash, "ours": m.result.hash})


## Pairs the queue, sends ghost fallbacks and settles aim deadlines.
func tick(now: float) -> Array:
	var out: Array = []
	for id in matches.keys():
		var m: Dictionary = matches[id]
		if m.result == null and now >= m.deadline:
			out.append_array(_resolve(id))
	var ids: Array = queue.keys()
	ids.sort_custom(func(a, b): return queue[a].since < queue[b].since)
	var taken := {}
	for i in ids.size():
		var a: String = ids[i]
		if taken.has(a):
			continue
		var qa: Dictionary = queue[a]
		var band := POWER_BAND + BAND_GROWTH * floorf((now - qa.since) / BAND_STEP)
		var best := ""
		var best_gap := INF
		for j in range(i + 1, ids.size()):
			var b: String = ids[j]
			var qb: Dictionary = queue[b]
			if taken.has(b) or qb.mode != qa.mode or qb.room != qa.room:
				continue
			if qa.room != "": # Friends: power doesn't matter.
				best = b
				break
			var gap := absf(qb.rating - qa.rating) / float(maxi(1, mini(qa.rating, qb.rating)))
			if gap <= band and gap < best_gap:
				best = b
				best_gap = gap
		if best != "":
			taken[a] = true
			taken[best] = true
			out.append_array(_start(a, best, now))
		elif qa.room != "":
			if now - qa.since >= ROOM_WAIT:
				taken[a] = true
				out.append([a, {"t": "room_timeout", "room": qa.room}])
		elif now - qa.since >= GHOST_AFTER:
			taken[a] = true
			out.append([a, {"t": "ghost", "rating": qa.rating}])
	for pid in taken:
		queue.erase(pid)
	return out


## Drops finished matches older than `keep` seconds.
func prune(now: float, keep := 120.0) -> void:
	for id in matches.keys():
		var m: Dictionary = matches[id]
		if m.result != null and now - m.deadline > keep:
			for pid in m.players:
				if in_match.get(pid, -1) == id:
					in_match.erase(pid)
			matches.erase(id)


func _start(a: String, b: String, now: float) -> Array:
	var id := _next_id
	_next_id += 1
	var qa: Dictionary = queue[a]
	var qb: Dictionary = queue[b]
	matches[id] = {"players": [a, b], "seed": int(_seeds.call()), "sides": [qa.slots, qb.slots],
		"aims": [null, null], "deadline": now + AIM_SECONDS, "result": null, "hashes": {}}
	in_match[a] = id
	in_match[b] = id
	var out: Array = []
	for side in 2:
		out.append([[a, b][side], {"t": "matched", "match": id, "side": side, "seed": matches[id].seed,
			"sides": matches[id].sides, "aim_seconds": AIM_SECONDS, "foe_rating": [qb, qa][side].rating}])
	return out


func _resolve(id: int) -> Array:
	var m: Dictionary = matches[id]
	m.result = MatchSim.new(LiveMatch.config(m.seed, m.sides, m.aims)).run_to_end()
	finished += 1
	var out: Array = []
	for pid in m.players:
		out.append([pid, {"t": "go", "match": id, "angles": m.aims, "winner": m.result.winner, "hash": m.result.hash}])
	return out
