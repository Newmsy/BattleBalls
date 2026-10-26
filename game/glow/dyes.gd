## Spark Dyes (design/dyes-rift-keys.md, project files): earned colours for
## the cosmetics you own. A dye swaps a hat, trail, hit spark or KO effect's
## two colours and keeps its shape. Drops fill a colour's bar (profile.dyes);
## a full bar unlocks it for good. A drop only rolls colours you haven't
## finished, so nothing is ever a duplicate. Never sold (money never buys
## anything random, and dyes stay a free player's chase). Render-only like
## every cosmetic: nothing in sim/ reads them.
extends RefCounted

## Drops a colour needs, by grade.
const NEED := {"basic": 5, "bright": 10, "prism": 20}
## How often each grade comes up in a drop, among the colours not yet finished.
const WEIGHT := {"basic": 6.0, "bright": 3.0, "prism": 1.0}
## Every dye: id, name, grade and two colours (a cosmetic's first and second).
## Basic ones are the nine family colours (sim/families.gd); Prism ones
## shimmer between their colours in the arena (CosmeticArt draws `shimmer`).
const DYES := [
	{"id": "dye_nature", "name": "Moss", "grade": "basic", "colors": ["5fd068", "c8f2a0"]},
	{"id": "dye_sea", "name": "Tide", "grade": "basic", "colors": ["3fa9f5", "bfe6ff"]},
	{"id": "dye_tech", "name": "Chrome", "grade": "basic", "colors": ["9aa8c7", "eef2fb"]},
	{"id": "dye_sweet", "name": "Candy", "grade": "basic", "colors": ["ff7ac8", "ffd6ee"]},
	{"id": "dye_frost", "name": "Frost", "grade": "basic", "colors": ["8fe6ff", "f0fcff"]},
	{"id": "dye_toybox", "name": "Sunshine", "grade": "basic", "colors": ["ffc93c", "fff0b0"]},
	{"id": "dye_spooky", "name": "Haunt", "grade": "basic", "colors": ["b07cff", "e6d6ff"]},
	{"id": "dye_fire", "name": "Ember", "grade": "basic", "colors": ["ff8a1e", "ffc27a"]},
	{"id": "dye_cosmic", "name": "Nebula", "grade": "basic", "colors": ["6f6bff", "c9c6ff"]},
	{"id": "dye_sunset", "name": "Sunset", "grade": "bright", "colors": ["ff8a3d", "ff6fd0"]},
	{"id": "dye_aurora", "name": "Aurora", "grade": "bright", "colors": ["5ce1ff", "b07cff"]},
	{"id": "dye_lagoon", "name": "Lagoon", "grade": "bright", "colors": ["2fb6e8", "a6fff0"]},
	{"id": "dye_lava", "name": "Lava", "grade": "bright", "colors": ["ffd23f", "e0402a"]},
	{"id": "dye_bubblegum", "name": "Bubblegum", "grade": "bright", "colors": ["ff9ee0", "9fd8ff"]},
	{"id": "dye_midnight", "name": "Midnight", "grade": "bright", "colors": ["3d3bb0", "8fb8ff"]},
	{"id": "dye_prism", "name": "Prism Shimmer", "grade": "prism", "colors": ["ff6fd0", "5ce1ff"], "shimmer": true},
	{"id": "dye_glitch", "name": "Glitch Flicker", "grade": "prism", "colors": ["3ee6ff", "e04cff"], "shimmer": true},
	{"id": "dye_starfield", "name": "Starfield", "grade": "prism", "colors": ["fff2b0", "8f7bff"], "shimmer": true},
]
const GRADE_NAMES := {"basic": "Basic", "bright": "Bright", "prism": "Prism"}


static func dye(id: String) -> Dictionary:
	for d in DYES:
		if d.id == id:
			return d
	return {}


static func need(id: String) -> int:
	return int(NEED.get(str(dye(id).get("grade", "basic")), 5))


## Drops collected toward `id` (capped at what it needs).
static func drops(profile, id: String) -> int:
	return mini(int(profile.dyes.get(id, 0)), need(id))


static func unlocked(profile, id: String) -> bool:
	return not dye(id).is_empty() and drops(profile, id) >= need(id)


static func unlocked_count(profile) -> int:
	return DYES.filter(func(d): return unlocked(profile, d.id)).size()


## Which colour a drop goes to: weighted by grade among the colours not yet
## finished, from `rng` (sim/rng.gd or RandomNumberGenerator: next_float or
## randf). "" once every colour is unlocked.
static func roll(profile, rng) -> String:
	var open := DYES.filter(func(d): return not unlocked(profile, d.id))
	if open.is_empty():
		return ""
	var total := 0.0
	for d in open:
		total += WEIGHT[d.grade]
	var x: float = (rng.next_float() if rng.has_method("next_float") else rng.randf()) * total
	for d in open:
		x -= WEIGHT[d.grade]
		if x < 0.0:
			return d.id
	return open[-1].id


## A cosmetic catalog entry wearing dye `id`: the same entry with the dye's
## colours (and shimmer for a Prism dye). The entry itself when `id` is "".
static func apply(item: Dictionary, id: String) -> Dictionary:
	var d := dye(id)
	if item.is_empty() or d.is_empty():
		return item
	var out := item.duplicate()
	out.colors = d.colors.duplicate()
	if d.get("shimmer", false):
		out.shimmer = true
	return out


## One drop's line for a result popup: "+1 Sunset Dye (3/10)", or
## "Sunset Dye unlocked!" when that drop finished the bar.
static func drop_text(got: Dictionary) -> String:
	var name: String = dye(str(got.get("id", ""))).get("name", "Spark")
	if got.get("unlocked", false):
		return "%s Dye unlocked!" % name
	return "+1 %s Dye (%d/%d)" % [name, int(got.drops), int(got.need)]
