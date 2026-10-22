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
	"tech": ["static", "cogs", "bolt", "laser", "zigzag", "zapper", "wrecker", "gearbox", "mirror", "magnet", "megabot", "clockwork"],
	"sweet": ["crumb", "gumdrop", "honey", "fizz", "pucker", "jawbreaker", "munch", "splitter", "sundae", "bonbon"],
	"frost": ["frost", "drizzle", "yeti", "gust", "mammoth", "blizz", "pounce", "frostfang", "narwhal", "glacia"],
	"toybox": ["pinball", "drum", "painter", "mortar", "disco", "yoyo", "pixel", "kaleido", "jackpot"],
	"spooky": ["vampire", "flicker", "sonar", "totem", "brewster", "ghost", "puppeteer", "foxfire"],
	"fire": ["speedster", "sooty", "magmo", "bomber", "drako", "phoenix", "supernova"],
	"cosmic": ["comet", "gravity", "prism", "quasar", "stormwing", "blackhole", "eclipse"],
}

## Family edges (Newms 2026-10-22, the "Bold" strength): each family is very
## good (2) against one family, good (1) against two, even with two, and bad
## or very bad against the rest, the mirror of these. The very-good arrows
## make one loop: Fire > Nature > Sweet > Spooky > Toybox > Frost > Sea >
## Tech > Cosmic > Fire. Only the attacker gains; there is no penalty side.
const EDGES := {
	"nature": {"sweet": 2, "sea": 1, "tech": 1},
	"sea": {"tech": 2, "sweet": 1, "fire": 1},
	"tech": {"cosmic": 2, "toybox": 1, "spooky": 1},
	"sweet": {"spooky": 2, "tech": 1, "toybox": 1},
	"frost": {"sea": 2, "nature": 1, "sweet": 1},
	"toybox": {"frost": 2, "fire": 1, "cosmic": 1},
	"spooky": {"toybox": 2, "nature": 1, "cosmic": 1},
	"fire": {"nature": 2, "frost": 1, "spooky": 1},
	"cosmic": {"fire": 2, "sea": 1, "frost": 1},
}
## Extra damage per edge level: very good ~72% at equal power, good ~64%,
## and a ball one tier up still wins ~65% into its very-bad matchup.
const EDGE_BONUS := [0.0, 0.10, 0.20]

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
	return 1.0 + EDGE_BONUS[maxi(0, edge(attacker, target))]
