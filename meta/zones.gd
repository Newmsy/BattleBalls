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
		"color": "45f5a6", ## Its node and path on the world map.
		"twist": "Plain arena",
		"boss": "Mega Boulder",
		"icon": "juggernaut",
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
	## Zone 2, Circuit Lab: pairs (2 vs 2 relay, sim/relay.gd) on the Bumpers
	## arena, Tech-family foes that each show off a signature trick (Cogs winds
	## up when bumped, Pinball loves the bumpers, Flux pulls, Sonar pings). A
	## stage's `enemies` come out in order; `enemy` is the first, for one-icon
	## spots. The boss stage's last ball is the boss, at BOSS_SIZE.
	{
		"id": "circuit_lab",
		"name": "Circuit Lab",
		"lineup": 2,
		"arena": "bumpers",
		"color": "39d7ff",
		"twist": "Bumpers in the middle",
		"boss": "Overclocked Optic",
		"icon": "laser",
		"featured": ["gumdrop", "crumb", "static", "cogs", "bolt", "shelly"],
		"rare_bonus": ["laser", "mirror"],
		"boss_reward": "mirror",
		"stages": [
			{"enemy": "pinball", "enemies": ["pinball", "cogs"], "power": 1.55},
			{"enemy": "bolt", "enemies": ["bolt", "static"], "power": 1.65},
			{"enemy": "cogs", "enemies": ["cogs", "zapper"], "power": 1.72},
			{"enemy": "pinball", "enemies": ["pinball", "bolt"], "power": 1.8},
			{"enemy": "static", "enemies": ["static", "sonar"], "power": 1.9},
			{"enemy": "zapper", "enemies": ["zapper", "magnet"], "power": 2.0},
			{"enemy": "gearbox", "enemies": ["gearbox", "cogs"], "power": 2.1},
			{"enemy": "sonar", "enemies": ["sonar", "pinball"], "power": 2.2},
			{"enemy": "beacon", "enemies": ["beacon", "static"], "power": 2.32},
			{"enemy": "magnet", "enemies": ["magnet", "gearbox"], "power": 2.45},
			{"enemy": "laser", "enemies": ["zapper", "laser"], "power": 2.6, "boss": true, "name": "Overclocked Optic"},
		],
	},
]

## Zones on the world map that aren't built yet (pve.md section 3, glitch.md
## bosses). When one is built it moves into ZONES with its stages.
const COMING := [
	{"id": "frostbite_caves", "name": "Frostbite Caves", "lineup": 3, "color": "a8e6ff", "twist": "Ice patches", "boss": "Glacier Chill"},
	{"id": "bramble_hollow", "name": "Bramble Hollow", "lineup": 3, "color": "9bd84a", "twist": "Thorn walls", "boss": "Thornking Bramble"},
	{"id": "haunted_arcade", "name": "Haunted Arcade", "lineup": 3, "color": "c77dff", "twist": "Portals", "boss": "Wisp Swarm"},
	{"id": "starfall_rim", "name": "Starfall Rim", "lineup": 3, "color": "ffd23d", "twist": "Shrinking arena", "boss": "Void Titan"},
	{"id": "magma_core", "name": "Magma Core", "lineup": 3, "color": "ff6a3d", "twist": "Lava zones", "boss": "Ember Reborn"},
]


## Every zone on the world map in order: the built ones, then the coming ones.
static func map_zones() -> Array:
	return ZONES + COMING


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


## A stage's enemy lineup in order: `enemies`, or the one `enemy`.
static func enemies(st: Dictionary) -> Array:
	return st.get("enemies", [st.enemy])
