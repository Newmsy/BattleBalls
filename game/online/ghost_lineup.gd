## Ghost Arena lineups: the defence a player leaves for others to fight, and
## how the ghost AI aims. Shape (v1), stored in public.ghost_lineups:
##   {"v": 1, "rules": MatchSim.RULES_VERSION,
##    "slots": [{"critter": "vampire", "tier": 1, "level": 1, "gear": []}],  # 1 to 3
##    "aim": [-30, 12, ...]}  # owner's recent launches, tenths of a degree off the centre line
## A fight is fully described by (rules, both lineups, seed, attacker inputs),
## so the server can re-run it to verify a claimed result.
extends RefCounted

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Lineup := preload("res://sim/lineup.gd")

const VERSION := 1
const MAX_SLOTS := 3
const MAX_AIM := 12
const MAX_AIM_OFFSET := 1800


## Builds a lineup from critter ids (bare T1) or lineup slots (sim/lineup.gd,
## e.g. Profile.slot_of: the tier, level and gear the player owns).
static func make(critters: Array, aim_offsets: Array) -> Dictionary:
	var slots := []
	for c in critters.slice(0, MAX_SLOTS):
		slots.append(Lineup.clean(c) if c is Dictionary else Lineup.make(str(c)))
	var aim := []
	for a in aim_offsets.slice(-MAX_AIM):
		aim.append(clampi(int(a), -MAX_AIM_OFFSET, MAX_AIM_OFFSET))
	return {"v": VERSION, "rules": MatchSim.RULES_VERSION, "slots": slots, "aim": aim}


## True if this client can fight the lineup (known critters, same sim rules).
static func is_playable(lineup) -> bool:
	if not lineup is Dictionary or int(lineup.get("rules", -1)) != MatchSim.RULES_VERSION:
		return false
	var slots = lineup.get("slots")
	if not slots is Array or slots.is_empty() or slots.size() > MAX_SLOTS:
		return false
	for s in slots:
		if not s is Dictionary or not str(s.get("critter", "")) in BallDefs.PLAYABLE:
			return false
	return true


## The angle the ghost launches with for slot index `player` (0 or 1 in the
## sim), picked from its owner's habits by the fight seed. Deterministic, so a
## re-run of the fight makes the same choice.
static func ghost_angle(lineup: Dictionary, seed_value: int, player := 1) -> int:
	var aim: Array = lineup.get("aim", [])
	var offset := 0
	if not aim.is_empty():
		offset = clampi(int(aim[posmod(seed_value, aim.size())]), -MAX_AIM_OFFSET, MAX_AIM_OFFSET)
	return MatchSim.AIM_AT_CENTRE[player] + offset


## A launch angle as an offset from the centre line, for the aim history.
static func aim_offset(angle: int, player := 0) -> int:
	return wrapi(angle - MatchSim.AIM_AT_CENTRE[player] + 1800, 0, 3600) - 1800


# --- Server calls (see supabase/migrations) ---------------------------------

## Saves `lineup` as this player's Ghost Arena defence.
static func publish(backend, lineup: Dictionary) -> bool:
	if not await backend.ensure_session():
		return false
	var row := {"user_id": backend.user_id(), "lineup": lineup, "rules_version": lineup.rules,
		"updated_at": Time.get_datetime_string_from_system(true) + "Z"}
	var res: Dictionary = await backend.rest("POST", "/rest/v1/ghost_lineups", row,
		["Prefer: resolution=merge-duplicates,return=minimal"])
	return res.ok


## Finds an opponent and opens a fight. Returns {fight_id, seed, defender:
## {name, trophies, lineup}}, or {} when there is nobody to fight (or no
## connection): the game then fights a bot ghost offline.
static func start_fight(backend, attacker: Dictionary) -> Dictionary:
	var res: Dictionary = await backend.call_rpc("start_ghost_fight", {"p_attacker_lineup": attacker})
	if res.ok and res.data is Dictionary and is_playable(res.data.get("defender", {}).get("lineup")):
		return res.data
	return {}


## Reports the attacker's inputs and result. Returns {attacker_delta, trophies}.
static func finish_fight(backend, fight_id: int, angles: Array, winner: int, state_hash: String) -> Dictionary:
	var res: Dictionary = await backend.call_rpc("finish_ghost_fight", {"p_fight_id": fight_id,
		"p_inputs": {"angles": angles}, "p_winner": winner, "p_hash": state_hash})
	return res.data if res.ok and res.data is Dictionary else {}
