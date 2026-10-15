## Weight: a hidden per-critter number for how hard pulls move a ball.
## Light critters are dragged further by gravity wells and by pull or push
## effects (Flux's field, Orbit's pull, Void's collapse, Gust's wind...);
## heavy ones shrug them off. It never shows in the UI.
##
## Default: the critter's role times its size (area, against the usual 64
## radius). Overrides below are for critters whose look says otherwise: a
## bubble is light whatever its role, a wrecking ball is heavy. One table, so
## tuning weight never means editing critter files.
extends RefCounted

const CritterDb := preload("res://sim/critter_db.gd")

const ROLE := {"Bruiser": 1.25, "Zoner": 1.0, "Disruptor": 1.0, "Skirmisher": 0.85, "Baseline": 1.0}
const BASE_RADIUS := 64.0
const MIN := 0.55
const MAX := 1.8
## Pull scale = weight ^ -PULL_EXPONENT, so weight 0.6 is pulled ~1.47x and
## weight 1.8 ~0.64x. Below 1 keeps weight a tilt, not a verdict.
const PULL_EXPONENT := 0.75

## id -> weight at the critter's normal size.
const OVERRIDES := {
	# Light: floaty, airy, tiny or made of nothing much.
	"bubbles": 0.6, "ghost": 0.6, "pollen": 0.6, "gust": 0.65, "drizzle": 0.7,
	"zing": 0.7, "foxfire": 0.75, "tumble": 0.75, "puff": 0.8,
	"stormwing": 0.8, "pixel": 0.8, "flicker": 0.85, "disco": 0.9,
	# Heavy: dense, armoured or huge.
	"juggernaut": 1.8, "mammoth": 1.8, "old_oak": 1.7, "wrecker": 1.65,
	"blackhole": 1.6, "jawbreaker": 1.5, "shelly": 1.5, "megabot": 1.5,
	"yeti": 1.5, "totem": 1.4, "gravity": 1.4, "magmo": 1.35, "clam": 1.35,
	"mortar": 1.25, "gearbox": 1.2, "cogs": 1.15,
}


## The weight of critter `id` drawn at `size` times its normal radius.
## Unknown ids (tutorial foes) weigh 1.
static func of(id: String, size := 1.0) -> float:
	var w := 1.0
	if OVERRIDES.has(id):
		w = OVERRIDES[id]
	elif CritterDb.has(id):
		var c := CritterDb.get_critter(id)
		var r: float = float(c.stats.radius) / BASE_RADIUS
		w = ROLE.get(c.role, 1.0) * r * r
	return clampf(w * size * size, MIN, MAX)


## How much a pull on a ball of this weight is scaled.
static func pull_scale(weight: float) -> float:
	return pow(weight, -PULL_EXPONENT)
