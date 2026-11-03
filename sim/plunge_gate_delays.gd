## How long after GO each Critter Plunge gate opens, per course and field
## size, so no starting gate is ahead (Newms 2026-11-02: "No starting
## position should be inherently at a disadvantage"). A course's opener can
## favour the middle gates (a funnel drops them straight through) or the
## outer ones; the favoured gates open a little later. Measured, not
## designed: tools/plunge_gates.gd --calibrate writes DELAYS from many
## seeded races (the same mean place for every gate pair).
##
## DELAYS[course][field size] = seconds per gate pair, outermost pair
## first; gate g and its mirror (size - 1 - g) share a delay because every
## section is mirrored on a coin flip. Missing entries open on GO.
extends RefCounted

## Each gate also waits a seeded 0 to JITTER s more (sim/plunge.gd), so
## neighbouring gates open in a different order every race.
const JITTER := 0.5
## Courses whose opener is a hopper racers leave single file (Gumdrop's
## gumball chute, Honey's hive door) need more: whoever reaches the hole a
## tick first goes through first, so a fixed delay only moved the lucky gate.
const JITTER_BY_COURSE := {"gumdrop": 1.2, "honey": 1.2}

const DELAYS := {
	"clouds": {4: [0.55, 0.00], 6: [1.05, 0.55, 0.00], 8: [0.60, 0.50, 0.20, 0.00]},
	"crystal": {4: [0.60, 0.00], 6: [0.30, 0.05, 0.00], 8: [0.05, 0.60, 0.15, 0.00]},
	"dunes": {4: [0.00, 0.50], 6: [0.00, 0.35, 0.65], 8: [0.00, 0.35, 0.50, 0.80]},
	"glitch": {4: [0.00, 0.15], 6: [0.00, 0.50, 0.45], 8: [0.05, 0.00, 0.25, 0.75]},
	"graves": {4: [0.00, 0.60], 6: [0.00, 0.35, 1.00], 8: [0.00, 0.45, 0.75, 1.15]},
	"gumdrop": {4: [0.00, 0.35], 6: [0.00, 0.45, 0.55], 8: [0.00, 0.30, 0.55, 0.85]},
	"honey": {4: [0.00, 0.65], 6: [0.00, 0.55, 1.00], 8: [0.00, 0.35, 0.70, 0.95]},
	"icicles": {4: [0.00, 0.15], 6: [0.55, 0.00, 0.60], 8: [0.75, 0.15, 0.00, 0.45]},
	"kelp": {4: [0.55, 0.00], 6: [0.25, 0.00, 0.35], 8: [0.30, 0.40, 0.00, 0.65]},
	"lava": {4: [0.00, 0.55], 6: [0.00, 0.50, 0.90], 8: [0.00, 0.30, 0.55, 0.80]},
	"manor": {4: [0.00, 0.50], 6: [0.00, 0.45, 0.85], 8: [0.00, 0.40, 0.50, 0.90]},
	"nebula": {4: [0.00, 0.05], 6: [0.00, 0.30, 0.05], 8: [0.00, 0.25, 0.30, 0.05]},
	"pinball": {4: [0.00, 0.40], 6: [0.00, 0.65, 0.95], 8: [0.00, 0.40, 0.55, 0.65]},
	"rocks": {4: [0.00, 0.40], 6: [0.00, 0.40, 0.90], 8: [0.00, 0.30, 0.35, 1.15]},
	"storm": {4: [0.00, 0.50], 6: [0.00, 0.45, 0.90], 8: [0.00, 0.20, 0.60, 0.85]},
	"sunset": {4: [0.00, 0.75], 6: [0.00, 1.05, 1.15], 8: [0.00, 0.70, 1.05, 1.50]},
	"sunstone": {4: [0.25, 0.00], 6: [0.90, 0.50, 0.00], 8: [1.40, 1.05, 0.50, 0.00]},
	"toys": {4: [0.45, 0.00], 6: [0.00, 0.45, 0.70], 8: [0.00, 0.45, 0.60, 0.85]},
	"trench": {4: [0.00, 0.20], 6: [0.00, 0.35, 0.75], 8: [0.00, 0.30, 0.65, 0.85]},
	"vines": {4: [0.00, 0.80], 6: [0.80, 0.00, 0.25], 8: [1.20, 0.00, 0.65, 0.10]},
}


static func delay(course: String, n: int, gate: int) -> float:
	var by_n: Dictionary = DELAYS.get(course, {})
	var pairs: Array = by_n.get(n, [])
	var k := mini(gate, n - 1 - gate)
	return float(pairs[k]) if k < pairs.size() else 0.0


static func jitter(course: String) -> float:
	return float(JITTER_BY_COURSE.get(course, JITTER))
