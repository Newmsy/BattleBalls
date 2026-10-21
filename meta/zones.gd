## Campaign zone data (pve.md section 3). A stage is one enemy at a fixed power;
## its Power Rating is the Recommended Power shown to the player.
extends RefCounted

const STAGE_COST := 6
const BOSS_COST := 10
const LOSS_COST := 1 ## A loss refunds all but this much energy.
const BOSS_SIZE := 1.35 ## Radius multiplier for bosses.
const BRAWL_SIZE := 0.72 ## Radius multiplier in a 3v3 brawl: the arena holds about twice the room per ball, zoomed out.

## Stage formats in the trios zones (zone 3 on), mixed so no two stages in a
## row play the same: a relay (one at a time, sim/relay.gd), a brawl (all six
## at once on the zoomed-out arena) and a duo (your first two picks against
## the stage's first two foes, at once). Boss stages are brawls. A stage's
## own `format` wins.
const TRIO_FORMATS := ["relay", "brawl", "duo"]

## Foe tier by chapter (Newms 2026-10-21): T1 in chapters 1-2, T2 in 3-4, T3
## in 5-6, T4 in 7, T5 in 8. A higher tier's stronger ability is paid back by
## FOE_POWER, measured in fights (T1 vs Tn foe at a stage's power) so every
## stage plays about as hard as it did with T1 foes; `power` stays the stage's
## Recommended Power.
const FOE_TIERS := [1, 1, 2, 2, 3, 3, 4, 5]
const FOE_POWER := [1.0, 0.92, 0.76, 0.7, 0.65] ## By tier - 1.

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
	## Zone 3, Frostbite Caves: trios. A frozen lake (balls skate faster) with icicle-spike stages
	## mixed in; Frost foes (Chill's chilling hits, Drizzle's rain, Yeti and
	## Mammoth bulk, Blizz storms) backed by Sea critters, ending in a giant
	## Glacier Chill.
	{
		"id": "frostbite_caves",
		"name": "Frostbite Caves",
		"lineup": 3,
		"arena": "frost",
		"color": "a8e6ff",
		"twist": "Frozen lake and icicle spikes",
		"boss": "Glacier Chill",
		"icon": "frost",
		"featured": ["frost", "drizzle", "bubbles", "puff", "shelly", "fin"],
		"rare_bonus": ["yeti", "gust"],
		"boss_reward": "blizz",
		"stages": [
			{"enemy": "frost", "enemies": ["frost", "drizzle", "bubbles"], "power": 2.75},
			{"enemy": "drizzle", "enemies": ["drizzle", "puff", "frost"], "power": 2.85},
			{"enemy": "yeti", "enemies": ["yeti", "frost", "shelly"], "power": 2.95, "arena": "spikes"},
			{"enemy": "gust", "enemies": ["gust", "drizzle", "fin"], "power": 3.05},
			{"enemy": "yeti", "enemies": ["yeti", "gust", "ripple"], "power": 3.15, "arena": "spikes"},
			{"enemy": "blizz", "enemies": ["blizz", "frost", "clam"], "power": 3.25},
			{"enemy": "pounce", "enemies": ["pounce", "gust", "yeti"], "power": 3.35, "arena": "spikes"},
			{"enemy": "mammoth", "enemies": ["mammoth", "drizzle", "ink"], "power": 3.45},
			{"enemy": "blizz", "enemies": ["blizz", "pounce", "yeti"], "power": 3.55, "arena": "spikes"},
			{"enemy": "mammoth", "enemies": ["mammoth", "gust", "narwhal"], "power": 3.7},
			{"enemy": "frost", "enemies": ["yeti", "blizz", "frost"], "power": 3.85, "boss": true, "name": "Glacier Chill"},
		],
	},
	## Zone 4, Bramble Hollow: trios among thorn hedges (Thorn Garden), old
	## trees (Pillars) and sinkholes (Gravity Wells). Nature foes: Bramble's
	## thorns, Pollen and Glowbug clouds, Mole digging, Swarm splitting, and
	## the giant Thornking Bramble at the end.
	{
		"id": "bramble_hollow",
		"name": "Bramble Hollow",
		"lineup": 3,
		"arena": "thorn",
		"color": "9bd84a",
		"twist": "Thorn walls, old trees and sinkholes",
		"boss": "Thornking Bramble",
		"icon": "thorns",
		"featured": ["pip", "tumble", "mossy", "glowbug", "pollen", "crumb"],
		"rare_bonus": ["whiff", "zing", "mole", "sprout"],
		"boss_reward": "swarm",
		"stages": [
			{"enemy": "tumble", "enemies": ["tumble", "mossy", "pip"], "power": 4.0},
			{"enemy": "glowbug", "enemies": ["glowbug", "pollen", "spiker"], "power": 4.1, "arena": "pillars"},
			{"enemy": "thorns", "enemies": ["mossy", "thorns", "tumble"], "power": 4.2},
			{"enemy": "whiff", "enemies": ["whiff", "glowbug", "honey"], "power": 4.32, "arena": "wells"},
			{"enemy": "zing", "enemies": ["zing", "pollen", "mossy"], "power": 4.45},
			{"enemy": "mole", "enemies": ["mole", "sprout", "thorns"], "power": 4.58, "arena": "pillars"},
			{"enemy": "swarm", "enemies": ["swarm", "whiff", "glowbug"], "power": 4.72},
			{"enemy": "sprout", "enemies": ["sprout", "mole", "zing"], "power": 4.86, "arena": "wells"},
			{"enemy": "ivy", "enemies": ["ivy", "swarm", "pollen"], "power": 5.0},
			{"enemy": "old_oak", "enemies": ["old_oak", "swarm", "sprout"], "power": 5.15, "arena": "pillars"},
			{"enemy": "thorns", "enemies": ["mole", "swarm", "thorns"], "power": 5.3, "boss": true, "name": "Thornking Bramble"},
		],
	},
	## Zone 5, Haunted Arcade: trios through portals (roll into one, pop out
	## of the other) with Pinball Palace stages. Spooky and Toybox foes:
	## Vampire bites, Sonar pings, Ghost phasing, Puppeteer throws, Pixel and
	## Kaleido tricks, and the Wisp Swarm boss led by a giant Foxfire.
	{
		"id": "haunted_arcade",
		"name": "Haunted Arcade",
		"lineup": 3,
		"arena": "arcade",
		"color": "c77dff",
		"twist": "Portals and pinball bumpers",
		"boss": "Wisp Swarm",
		"icon": "ghost",
		"featured": ["vampire", "flicker", "pinball", "drum", "puff", "crumb"],
		"rare_bonus": ["sonar", "painter", "mortar", "disco"],
		"boss_reward": "ghost",
		"stages": [
			{"enemy": "vampire", "enemies": ["vampire", "flicker", "pinball"], "power": 5.45},
			{"enemy": "drum", "enemies": ["drum", "flicker", "vampire"], "power": 5.6, "arena": "pinball"},
			{"enemy": "sonar", "enemies": ["sonar", "pinball", "flicker"], "power": 5.75},
			{"enemy": "painter", "enemies": ["painter", "sonar", "drum"], "power": 5.9, "arena": "pinball"},
			{"enemy": "mortar", "enemies": ["mortar", "disco", "flicker"], "power": 6.05},
			{"enemy": "totem", "enemies": ["totem", "brewster", "sonar"], "power": 6.2, "arena": "pinball"},
			{"enemy": "ghost", "enemies": ["ghost", "yoyo", "painter"], "power": 6.35},
			{"enemy": "puppeteer", "enemies": ["puppeteer", "pixel", "disco"], "power": 6.5, "arena": "pinball"},
			{"enemy": "kaleido", "enemies": ["kaleido", "ghost", "totem"], "power": 6.65},
			{"enemy": "jackpot", "enemies": ["jackpot", "puppeteer", "brewster"], "power": 6.8, "arena": "pinball"},
			{"enemy": "foxfire", "enemies": ["ghost", "puppeteer", "foxfire"], "power": 7.0, "boss": true, "name": "Wisp Swarm"},
		],
	},
	## Zone 6, Starfall Rim: trios on a rim that closes in from 15 seconds,
	## with Orbit Station and Event Horizon stages. Cosmic foes (Comet
	## dashes, Gravity pulls, Prism beams, Eclipse flips, Black Hole) with
	## Tech and Sea heavyweights, ending in the Void Titan.
	{
		"id": "starfall_rim",
		"name": "Starfall Rim",
		"lineup": 3,
		"arena": "starfall",
		"color": "ffd23d",
		"twist": "Shrinking rim, moons and a black hole",
		"boss": "Void Titan",
		"icon": "blackhole",
		"featured": ["speedster", "sooty", "comet", "zigzag", "wrecker", "mirror"],
		"rare_bonus": ["gravity", "megabot"],
		"boss_reward": "prism",
		"stages": [
			{"enemy": "comet", "enemies": ["comet", "gravity", "zigzag"], "power": 7.2},
			{"enemy": "comet", "enemies": ["comet", "wrecker", "gravity"], "power": 7.35, "arena": "orbit"},
			{"enemy": "gravity", "enemies": ["gravity", "comet", "mirror"], "power": 7.5},
			{"enemy": "prism", "enemies": ["prism", "comet", "megabot"], "power": 7.65, "arena": "horizon"},
			{"enemy": "quasar", "enemies": ["quasar", "gravity", "clockwork"], "power": 7.8},
			{"enemy": "stormwing", "enemies": ["stormwing", "prism", "comet"], "power": 7.95, "arena": "orbit"},
			{"enemy": "eclipse", "enemies": ["eclipse", "quasar", "gravity"], "power": 8.1},
			{"enemy": "blackhole", "enemies": ["blackhole", "stormwing", "prism"], "power": 8.25, "arena": "horizon"},
			{"enemy": "eclipse", "enemies": ["eclipse", "kraken", "quasar"], "power": 8.4},
			{"enemy": "stormwing", "enemies": ["stormwing", "leviathan", "eclipse"], "power": 8.6, "arena": "orbit"},
			{"enemy": "blackhole", "enemies": ["quasar", "eclipse", "blackhole"], "power": 8.8, "boss": true, "name": "Void Titan"},
		],
	},
	## Zone 7, Magma Core: trios between lava pools, with Inferno Ring stages.
	## Fire foes (Sooty smoke, Magmo lava, Bomber blasts, Drako breath,
	## Supernova bursts) and the finale in the Glitch Grid: Ember Reborn,
	## a giant Phoenix that rises again.
	{
		"id": "magma_core",
		"name": "Magma Core",
		"lineup": 3,
		"arena": "magma",
		"color": "ff6a3d",
		"twist": "Lava pools and burning walls",
		"boss": "Ember Reborn",
		"icon": "phoenix",
		"featured": ["speedster", "sooty", "magmo", "bomber", "comet", "zigzag"],
		"rare_bonus": ["drako", "gravity"],
		"boss_reward": "phoenix",
		"stages": [
			{"enemy": "sooty", "enemies": ["sooty", "speedster", "magmo"], "power": 9.0},
			{"enemy": "magmo", "enemies": ["magmo", "bomber", "sooty"], "power": 9.2, "arena": "inferno"},
			{"enemy": "bomber", "enemies": ["bomber", "drako", "speedster"], "power": 9.4},
			{"enemy": "drako", "enemies": ["drako", "magmo", "comet"], "power": 9.6, "arena": "inferno"},
			{"enemy": "supernova", "enemies": ["supernova", "bomber", "sooty"], "power": 9.8},
			{"enemy": "drako", "enemies": ["drako", "supernova", "gravity"], "power": 10.0, "arena": "inferno"},
			{"enemy": "phoenix", "enemies": ["phoenix", "magmo", "drako"], "power": 10.2},
			{"enemy": "supernova", "enemies": ["supernova", "phoenix", "bomber"], "power": 10.4, "arena": "inferno"},
			{"enemy": "blackhole", "enemies": ["blackhole", "supernova", "drako"], "power": 10.6},
			{"enemy": "phoenix", "enemies": ["phoenix", "quasar", "supernova"], "power": 10.8, "arena": "inferno"},
			{"enemy": "phoenix", "enemies": ["drako", "supernova", "phoenix"], "power": 11.0, "arena": "glitch", "boss": true, "name": "Ember Reborn"},
		],
	},
]

## Zones on the world map that aren't built yet (pve.md section 3, glitch.md
## bosses). When one is built it moves into ZONES with its stages.
const COMING := [
]


## Every zone on the world map in order: the built ones, then the coming ones.
static func map_zones() -> Array:
	return ZONES + COMING


static func zone(zone_index: int) -> Dictionary:
	return ZONES[zone_index]


## A stage as it is fought: a duo stage in a trios zone keeps its first two
## foes; `tier` and `foe_power` are what its foes fight at.
static func stage(zone_index: int, stage_index: int) -> Dictionary:
	var st: Dictionary = ZONES[zone_index].stages[stage_index].duplicate()
	if ZONES[zone_index].lineup == 3 and format(zone_index, stage_index) == "duo" and st.get("enemies", []).size() > 2:
		st.enemies = st.enemies.slice(0, 2)
		st.enemy = st.enemies[0]
	st.tier = foe_tier(zone_index)
	st.foe_power = st.power * FOE_POWER[st.tier - 1]
	return st


## The tier the zone's foes fight at (FOE_TIERS).
static func foe_tier(zone_index: int) -> int:
	return FOE_TIERS[mini(zone_index, FOE_TIERS.size() - 1)]


## How a stage is fought: "solo" (zone 1), "duo" (2v2 at once), "relay" or "brawl" (3v3 at once).
static func format(zone_index: int, stage_index: int) -> String:
	var zn: Dictionary = ZONES[zone_index]
	var st: Dictionary = zn.stages[stage_index]
	if st.has("format"):
		return st.format
	if zn.lineup == 1:
		return "solo"
	if zn.lineup == 2:
		return "duo"
	if st.get("boss", false):
		return "brawl"
	return TRIO_FORMATS[stage_index % TRIO_FORMATS.size()]


## Critters you bring to a stage: 2 for a duo, else the zone's lineup.
static func team_size(zone_index: int, stage_index: int) -> int:
	return 2 if format(zone_index, stage_index) == "duo" else ZONES[zone_index].lineup


## The stage's format as a short chip: "3V3", "2V2", "RELAY" (empty for solo).
static func format_label(zone_index: int, stage_index: int) -> String:
	return {"duo": "2V2", "relay": "RELAY", "brawl": "3V3"}.get(format(zone_index, stage_index), "")


static func stage_key(zone_index: int, stage_index: int) -> String:
	return "%d-%d" % [zone_index + 1, stage_index + 1]


static func cost(st: Dictionary) -> int:
	return BOSS_COST if st.get("boss", false) else STAGE_COST


static func is_boss(st: Dictionary) -> bool:
	return st.get("boss", false)


## A stage's enemy lineup in order: `enemies`, or the one `enemy`.
static func enemies(st: Dictionary) -> Array:
	return st.get("enemies", [st.enemy])
