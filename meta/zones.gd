## Campaign zone data (pve.md section 3). A stage is one enemy at a fixed power;
## its Power Rating is the Recommended Power shown to the player.
extends RefCounted

const STAGE_COST := 6
const BOSS_COST := 10
const LOSS_COST := 1 ## A loss refunds all but this much energy.
const BOSS_SIZE := 1.35 ## Radius multiplier for bosses.

## Zone 1, Glow Garden: plain arena, 1v1, featured Commons. Enemy power rises
## ~9% a stage from an easy 0.75; the boss is tuned (with its size) so a T2 level 10 ball wins about half the time.
const ZONES := [
	{
		"id": "glow_garden",
		"name": "Glow Garden",
		"lineup": 1,
		"featured": ["spiker", "speedster", "vampire", "juggernaut"],
		"rare_bonus": ["laser"], ## Small chance at the next rarity up.
		"boss_reward": "laser", ## Guaranteed on first boss clear.
		"stages": [
			{"enemy": "spiker", "power": 0.75},
			{"enemy": "speedster", "power": 0.82},
			{"enemy": "vampire", "power": 0.89},
			{"enemy": "juggernaut", "power": 0.97},
			{"enemy": "spiker", "power": 1.06},
			{"enemy": "speedster", "power": 1.15},
			{"enemy": "juggernaut", "power": 1.26},
			{"enemy": "vampire", "power": 1.37},
			{"enemy": "spiker", "power": 1.49},
			{"enemy": "speedster", "power": 1.63},
			{"enemy": "juggernaut", "power": 1.75, "boss": true, "name": "Mega Boulder"},
		],
	},
]


static func zone(zone_index: int) -> Dictionary:
	return ZONES[zone_index]


static func stage(zone_index: int, stage_index: int) -> Dictionary:
	return ZONES[zone_index].stages[stage_index]


static func stage_key(zone_index: int, stage_index: int) -> String:
	return "%d-%d" % [zone_index + 1, stage_index + 1]


static func cost(st: Dictionary) -> int:
	return BOSS_COST if st.get("boss", false) else STAGE_COST


static func is_boss(st: Dictionary) -> bool:
	return st.get("boss", false)
