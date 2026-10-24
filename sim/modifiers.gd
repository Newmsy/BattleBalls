## Rule twists (they ran as Chaos Weekends until 2026-10-24; no game mode
## uses them now, the balance tool still can). Pure data plus a few helpers: the sim applies a
## modifier to both balls at the start of a fight, so every modifier is
## symmetric and the same config still gives the same fight.
##
## Fields (all optional, missing means "unchanged"):
##   radius, hp, damage, speed  multipliers on the ball's base stats; `damage`
##                              scales contact damage and every *_damage,
##                              *_dps and *_burn stat
##   ability                    multiplier on ability strength: Vampire's heal
##                              ratio, Laser's beam cap (how many beams at once),
##                              (by sqrt) beam damage and Flux's snap bonus, and
##                              (by 4th root) every other ability's damage, dps,
##                              burn, slow and reflect share
##   beam_life                  multiplier on how long Laser beams last
##   overtime_start             seconds before the arena starts closing in
##   mirror                     both sides use the same seed-picked ball
extends RefCounted

const NONE := ""

const DEFS := {
	"big_head": {
		"display_name": "Big Head",
		"description": "Every ball is 1.35x bigger.",
		"radius": 1.35,
	},
	"glass_cannon": {
		"display_name": "Glass Cannon",
		"description": "Three quarters HP, 1.35x damage.",
		"hp": 0.75,
		"damage": 1.35,
	},
	"hyper_speed": {
		"display_name": "Hyper Speed",
		"description": "Every ball moves 1.4x faster. Beams fade faster too.",
		"speed": 1.4,
		# Faster balls bounce more often; shorter beams keep Laser from running away with it.
		"beam_life": 0.7,
	},
	"double_trouble": {
		"display_name": "Double Trouble",
		"description": "Abilities hit harder.",
		"ability": 1.5,
	},
	"mirror_match": {
		"display_name": "Mirror Match",
		"description": "Both sides get the same random ball.",
		"mirror": true,
	},
	"closing_walls": {
		"display_name": "Closing Walls",
		"description": "Overtime starts at 10 seconds: the arena shrinks early.",
		"overtime_start": 10.0,
	},
}


static func has(id: String) -> bool:
	return id == NONE or DEFS.has(id)


static func get_def(id: String) -> Dictionary:
	assert(has(id), "Unknown modifier id: %s" % id)
	return DEFS.get(id, {})


static func display_name(id: String) -> String:
	return "Normal rules" if id == NONE else get_def(id).display_name


## A copy of a ball def with the modifier applied.
static func apply_to_def(def: Dictionary, id: String) -> Dictionary:
	var mod := get_def(id)
	var out := def.duplicate()
	out.radius *= mod.get("radius", 1.0)
	out.hp *= mod.get("hp", 1.0)
	out.speed *= mod.get("speed", 1.0)
	var damage: float = mod.get("damage", 1.0)
	for key in out:
		var k := String(key)
		if k.ends_with("_damage") or k.ends_with("_dps") or k.ends_with("_burn"): # Burns too.
			out[key] *= damage
	var ability: float = mod.get("ability", 1.0)
	if out.has("heal_ratio"):
		out.heal_ratio *= sqrt(ability)
	if out.has("beam_life"):
		out.beam_life *= mod.get("beam_life", 1.0)
	if out.has("beam_max"):
		out.beam_max = roundi(out.beam_max * ability)
	# Since Optic's rebalance (beams 4.5 damage) and Flux's arrival, a bigger
	# beam cap alone left Optic at 34% to Nibbles under Double Trouble. Beam
	# damage and Flux's snap bonus (above a plain hit) grow by the square root,
	# which keeps every pairing within 43-57%.
	if out.has("beam_damage"):
		out.beam_damage *= sqrt(ability)
	if out.has("snap_mult"):
		out.snap_mult = 1.0 + (out.snap_mult - 1.0) * sqrt(ability)
	# Prickles's spikes and Zip's build-up are their abilities: they grow in full.
	# (Boulder's slam is a small share of its damage, so it gains nothing here.)
	if out.has("spike_damage"):
		out.spike_damage *= ability
	if out.has("speed_gain"):
		out.speed_gain *= ability
	# Every other ability's damage, burn, slow and reflect share grow too, so
	# critters past the original three aren't left behind.
	# A gentler root than the beam's: these critters' whole kit is ability
	# damage, and the square root left Spectra over Chill 75% here.
	if ability != 1.0:
		var boost := sqrt(sqrt(ability)) # ability ^ 0.25 without pow(), see sim/dmath.gd
		for key in out:
			var k := String(key)
			if k in ["contact_damage", "beam_damage", "heal_ratio", "spike_damage", "slam_damage"]:
				continue
			if k.ends_with("_damage") or k.ends_with("_dps") or k.ends_with("_burn") or k == "reflect_ratio":
				out[key] *= boost
			elif k.ends_with("_slow"):
				out[key] = minf(out[key] * boost, 0.8)
	# A critter file's optional "chaos" block fine-tunes how one twist treats
	# that critter: {modifier_id: {stat_or_param: multiplier}}.
	for key in def.get("chaos", {}).get(id, {}):
		out[key] *= float(def.chaos[id][key])
	return out


## A copy of a ball def with its critter file's "chaos" entry for this arena
## applied ({arena_id: {stat_or_param: multiplier}}), like the modifier ones.
static func apply_arena_tweaks(def: Dictionary, arena_id: String) -> Dictionary:
	var tweaks: Dictionary = def.get("chaos", {}).get(arena_id, {})
	if tweaks.is_empty():
		return def
	var out := def.duplicate()
	for key in tweaks:
		out[key] *= float(tweaks[key])
	return out


## Balls a Mirror Match picks from. Fixed rather than every live critter, so a
## mirror replay code still plays the same ball after new critters go live.
## Adding to it changes mirror fights: bump MatchSim.RULES_VERSION and
## re-record the golden replays.
const MIRROR_POOL := ["vampire", "laser", "magnet"]


## The ball both sides use in a Mirror Match, picked from the seed.
static func mirror_ball(seed_value: int, playable: Array = MIRROR_POOL) -> String:
	return playable[posmod(seed_value, playable.size())]
