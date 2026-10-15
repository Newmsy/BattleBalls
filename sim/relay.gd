## Deterministic lineup relay (pve.md "relay", pvp.md section 2): each side
## brings 1-3 balls in a fixed order and fights are 1v1 legs. The winner of a
## leg stays in with the HP it has left and launches again; the loser's next
## ball comes out. A drawn leg knocks out both balls. The side with a ball
## left at the end wins.
##
## Config: { seed: int, sides: [[type, ...], [type, ...]], aims: [[aim, ...], [aim, ...]],
##           powers: [[w, ...], [w, ...]], sizes: [[s, ...], [s, ...]],
##           tiers: [[t, ...], [t, ...]] }
## `aims[side][slot]` is that ball's launch angle in tenths of a degree from
## its own corner (screen space), or null to let the leg seed pick. A ball
## that stays in launches with the same aim again. `powers`, `sizes` and
## `tiers` (optional) are per-ball MatchSim `powers` / `sizes` / `tiers`
## (progression, boss scale, tier ability upgrades); left out, legs use the
## MatchSim defaults. sim/lineup.gd side() builds them from lineup slots. `gear[side][slot]`
## (optional) is that ball's gear (sim/gear.gd), null for none.
##
## The game can drive it leg by leg (leg_config() -> run a MatchSim, maybe
## rendering it -> record_leg(sim)) or call run_to_end() headless; both give
## the same fight.
extends RefCounted

const Rng := preload("res://sim/rng.gd")
const MatchSim := preload("res://sim/match_sim.gd")

const MAX_SLOTS := 3

var config: Dictionary
var sides: Array = [[], []]
var aims: Array = [[], []]
var gear: Array = [[], []]
## Index of the ball currently in (or next up) for each side.
var slot: Array[int] = [0, 0]
## HP each side's current ball carries into its next leg (null = full).
var carry_hp: Array = [null, null]
var legs: Array[Dictionary] = []
var finished := false
var winner := -1 ## 0, 1, or -1 for a draw (only meaningful when finished).

var _rng
var _leg_seeds: Array[int] = []


func _init(cfg: Dictionary) -> void:
	config = cfg
	_rng = Rng.new(int(cfg.get("seed", 1)))
	var cfg_aims: Array = cfg.get("aims", [[], []])
	var cfg_gear: Array = cfg.get("gear", [[], []])
	for s in 2:
		var lineup: Array = cfg.sides[s]
		assert(lineup.size() >= 1 and lineup.size() <= MAX_SLOTS, "A side brings 1-3 balls")
		sides[s] = lineup.duplicate()
		var side_aims: Array = cfg_aims[s] if s < cfg_aims.size() else []
		var side_gear: Array = cfg_gear[s] if s < cfg_gear.size() else []
		for i in lineup.size():
			aims[s].append(side_aims[i] if i < side_aims.size() else null)
			gear[s].append(side_gear[i] if i < side_gear.size() else null)


## Config for the next leg's MatchSim. Leg seeds come from the relay seed in
## order, so a relay is reproducible from its config alone.
func leg_config() -> Dictionary:
	assert(not finished, "Relay already finished")
	var leg := {
		"seed": _leg_seed(legs.size()),
		"p1": sides[0][slot[0]],
		"p2": sides[1][slot[1]],
		"angles": [aims[0][slot[0]], aims[1][slot[1]]],
		"hp": carry_hp.duplicate(),
		"gear": [gear[0][slot[0]], gear[1][slot[1]]],
	}
	for key in ["powers", "sizes", "tiers"]:
		if config.has(key):
			leg[key] = [config[key][0][slot[0]], config[key][1][slot[1]]]
	return leg


## Records a finished leg and brings out the next balls.
func record_leg(sim) -> void:
	assert(sim.finished, "Record a leg only once its MatchSim has finished")
	var result: Dictionary = sim.summary()
	legs.append({
		"p1": sim.balls[0].type_id,
		"p2": sim.balls[1].type_id,
		"slots": slot.duplicate(),
		"seed": int(sim.config.seed),
		"angles": sim.launch_angles.duplicate(),
		"winner": result.winner,
		"reason": result.reason,
		"hp": result.hp,
		"hash": result.hash,
	})
	for s in 2:
		if result.winner == s:
			carry_hp[s] = maxf(result.hp[s], 0.01)
		else:
			slot[s] += 1
			carry_hp[s] = null
	var left := [slot[0] < sides[0].size(), slot[1] < sides[1].size()]
	if left[0] and left[1]:
		return
	finished = true
	winner = -1 if left[0] == left[1] else (0 if left[0] else 1)


func run_to_end() -> Dictionary:
	while not finished:
		var sim := MatchSim.new(leg_config())
		sim.run_to_end()
		record_leg(sim)
	return summary()


func summary() -> Dictionary:
	return {"winner": winner, "legs": legs.size(), "hash": state_hash()}


## Hash over every leg's hash; equal hashes mean identical relays.
func state_hash() -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	for leg in legs:
		ctx.update(String(leg.hash).to_utf8_buffer())
	return ctx.finish().hex_encode()


func _leg_seed(index: int) -> int:
	# Draw in order so leg N's seed never depends on how earlier legs went.
	while _leg_seeds.size() <= index:
		_leg_seeds.append(int(_rng.next_u32() & 0x7FFFFFFF))
	return _leg_seeds[index]

