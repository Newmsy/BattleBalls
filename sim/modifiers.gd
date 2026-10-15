## Chaos Weekend rule twists. Pure data plus a few helpers: the sim applies a
## modifier to both balls at the start of a fight, so every modifier is
## symmetric and the same config still gives the same fight.
##
## Fields (all optional, missing means "unchanged"):
##   radius, hp, damage, speed  multipliers on the ball's base stats; `damage`
##                              scales contact damage and every *_damage stat
##   ability                    multiplier on ability strength: Vampire's heal
##                              ratio, Laser's beam cap (how many beams at once),
##                              (by sqrt) beam damage and Flux's snap bonus
##   beam_life                  multiplier on how long Laser beams last
##   overtime_start             seconds before the arena starts closing in
##   mirror                     both sides use the same seed-picked ball
## Design notes and the rotation live in design/events.md (project files).
extends RefCounted

const NONE := ""

const DEFS := {
	"big_head": {
		"display_name": "Big Head",
		"description": "Every ball is 1.35x bigger. More bumps, fewer misses.",
		"radius": 1.35,
	},
	"glass_cannon": {
		"display_name": "Glass Cannon",
		"description": "Three quarters HP, 1.35x damage. Fights end fast.",
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
		"description": "Abilities hit harder: bigger heals, more and hotter beams, bigger snaps.",
		"ability": 1.5,
	},
	"mirror_match": {
		"display_name": "Mirror Match",
		"description": "Both sides get the same random ball. Only your aim decides.",
		"mirror": true,
	},
	"closing_walls": {
		"display_name": "Closing Walls",
		"description": "Overtime starts at 10 seconds: the arena shrinks early.",
		"overtime_start": 10.0,
	},
}

## Weekend rotation order, one per week. Mirror Match sits between two stat
## twists so back-to-back weekends never feel alike.
const ROTATION := ["big_head", "glass_cannon", "mirror_match", "hyper_speed", "closing_walls", "double_trouble"]

## Monday 2026-01-05 00:00 UTC: week 0 of the rotation.
const ROTATION_EPOCH := 1767571200
const WEEK := 7 * 24 * 3600
const DAY := 24 * 3600


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
		if String(key).ends_with("_damage"):
			out[key] *= damage
	var ability: float = mod.get("ability", 1.0)
	if out.has("heal_ratio"):
		out.heal_ratio *= ability
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
	return out


## Balls a Mirror Match picks from. Fixed rather than every live critter, so a
## mirror replay code still plays the same ball after new critters go live.
## Adding to it changes mirror fights: bump MatchSim.RULES_VERSION and
## re-record the golden replays.
const MIRROR_POOL := ["vampire", "laser", "magnet"]


## The ball both sides use in a Mirror Match, picked from the seed.
static func mirror_ball(seed_value: int, playable: Array = MIRROR_POOL) -> String:
	return playable[posmod(seed_value, playable.size())]


## The modifier for the weekend containing `unix_time`, or NONE on weekdays.
## Weekends run Friday 00:00 to Monday 00:00 UTC.
static func weekend_modifier(unix_time: int) -> String:
	var since := unix_time - ROTATION_EPOCH
	var day_of_week := posmod(floori(float(since) / DAY), 7) ## 0 = Monday.
	if day_of_week < 4:
		return NONE
	return ROTATION[posmod(floori(float(since) / WEEK), ROTATION.size())]
