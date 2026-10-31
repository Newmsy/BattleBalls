## The nine theme families (design/roster.md "Theme sets"): which family each
## critter belongs to. Arena Boosts (sim/arena_boosts.gd) are bought per
## family, and faction talent trees (design/talents.md) use the same map.
## Families also have edges on each other (EDGES, design/type-advantage.md):
## a hit on a family the attacker has the edge on deals extra damage.
extends RefCounted

## In the order screens list them, with each family's colour.
const FAMILIES := [
	{"id": "nature", "name": "Nature", "color": "5fd068"},
	{"id": "sea", "name": "Sea", "color": "3fa9f5"},
	{"id": "tech", "name": "Tech", "color": "9aa8c7"},
	{"id": "sweet", "name": "Sweet", "color": "ff7ac8"},
	{"id": "frost", "name": "Frost", "color": "8fe6ff"},
	{"id": "toybox", "name": "Toybox", "color": "ffc93c"},
	{"id": "spooky", "name": "Spooky", "color": "b07cff"},
	{"id": "fire", "name": "Fire", "color": "ff6a3d"},
	{"id": "cosmic", "name": "Cosmic", "color": "6f6bff"},
]

const MEMBERS := {
	"nature": ["juggernaut", "spiker", "pip", "tumble", "mossy", "glowbug", "thorns", "pollen", "whiff", "zing", "mole", "sprout", "swarm", "old_oak", "ivy"],
	"sea": ["bubbles", "puff", "shelly", "fin", "minnow", "ink", "clam", "ripple", "hook", "beacon", "leviathan", "kraken"],
	"tech": ["static", "cogs", "bolt", "laser", "zigzag", "zapper", "wrecker", "gearbox", "mirror", "magnet", "megabot", "clockwork", "boing"],
	"sweet": ["crumb", "gumdrop", "honey", "fizz", "pucker", "jawbreaker", "munch", "splitter", "sundae", "bonbon", "beans"],
	"frost": ["frost", "drizzle", "yeti", "gust", "mammoth", "blizz", "pounce", "frostfang", "narwhal", "glacia", "snowbo"],
	"toybox": ["pinball", "drum", "painter", "mortar", "disco", "yoyo", "pixel", "kaleido", "jackpot", "boomer"],
	"spooky": ["vampire", "flicker", "sonar", "totem", "brewster", "ghost", "puppeteer", "foxfire", "gourdo", "shade"],
	"fire": ["speedster", "sooty", "magmo", "bomber", "drako", "phoenix", "supernova", "kernel", "blaze"],
	"cosmic": ["comet", "gravity", "prism", "quasar", "stormwing", "blackhole", "eclipse", "zorp", "snooze", "astra", "rift"],
}

## Family edges (Newms 2026-10-27, replacing the 2026-10-23 triangles): only
## matchups you could guess from the themes, Pokemon style (Sea douses Fire,
## Fire burns Nature, Nature drinks Sea, Spooky haunts Toybox). Each family
## has the advantage (2) over as many families as have it over them, so no
## family is stronger on the chart; every other matchup is even. The reasons
## are design notes only: players just see "type advantage".
const EDGES := {
	"sea": {"fire": 2, "tech": 2},
	"fire": {"nature": 2, "frost": 2, "sweet": 2},
	"nature": {"sea": 2},
	"frost": {"sea": 2},
	"tech": {"cosmic": 2},
	"sweet": {"spooky": 2},
	"spooky": {"toybox": 2, "fire": 2},
	"cosmic": {"spooky": 2},
	"toybox": {"fire": 2},
}
## A hit on a family you have the advantage over deals +10%; a hit on one
## that has it over you deals -10% (Newms 2026-10-27).
const EDGE_BONUS := 0.10

static var _of := {}


## The family id of a critter, or "" for one outside every family (Plain).
static func of(critter: String) -> String:
	if _of.is_empty():
		for fam in MEMBERS:
			for id in MEMBERS[fam]:
				_of[id] = fam
	return _of.get(critter, "")


static func ids() -> Array:
	return FAMILIES.map(func(f): return f.id)


static func info(family: String) -> Dictionary:
	for f in FAMILIES:
		if f.id == family:
			return f
	return {}


## How much `attacker`'s family has the edge on `target`'s: 2 very good,
## 1 good, 0 none (also for Plain, bosses and the attacker's own family),
## -1 bad, -2 very bad. Takes critter ids.
static func edge(attacker: String, target: String) -> int:
	var a := of(attacker)
	var t := of(target)
	if a == "" or t == "":
		return 0
	var e: int = EDGES[a].get(t, 0)
	return e if e != 0 else -int(EDGES[t].get(a, 0))


## The damage multiplier for a hit from `attacker` on `target` (critter ids).
static func edge_mult(attacker: String, target: String) -> float:
	return mult_for(edge(attacker, target))


## The damage multiplier for an edge score: +10% with the advantage, -10%
## into a weakness, 1 when even.
static func mult_for(edge_score: int) -> float:
	return 1.0 + EDGE_BONUS * signi(edge_score)
