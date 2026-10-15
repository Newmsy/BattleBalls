## The fight sim's view of every critter. Critters live one per file in
## sim/critters/ (read by sim/critter_db.gd); this turns them into the flat
## definitions the sim reads and keeps the old BallDefs API for callers.
extends RefCounted

const CritterDb := preload("res://sim/critter_db.gd")

## id -> flat T1 definition, for every critter the sim can fight with.
static var DEFS: Dictionary = _defs()
## Critters offered to players (status "live"), in Critterpedia order.
static var PLAYABLE: Array = CritterDb.live_ids()


## Onboarding foes (design/onboarding.md): weak, ability-free Plain balls,
## never offered in pickers and skipped by the balance sim. They are not
## critters, so they draw with Plain's art ("id" stays "plain").
const TUTORIAL_FOES := {
	"dummy": {"display_name": "Training Dummy", "description": "A practice target. It barely fights back.",
		"hp": 32.0, "radius": 76.0, "speed": 380.0, "contact_damage": 3.0},
	"sparring": {"display_name": "Sparring Bot", "description": "A practice bot that hits back a little.",
		"hp": 45.0, "radius": 70.0, "speed": 420.0, "contact_damage": 5.0},
}


static func get_def(id: String, tier := 1) -> Dictionary:
	assert(DEFS.has(id), "Unknown ball id: %s" % id)
	return DEFS[id] if tier == 1 else CritterDb.sim_def(id, tier)


static func _defs() -> Dictionary:
	var out := {}
	for id in CritterDb.sim_ids():
		out[id] = CritterDb.sim_def(id)
	for id in TUTORIAL_FOES:
		var def := CritterDb.sim_def("plain")
		def.merge(TUTORIAL_FOES[id], true)
		def.tutorial = true
		out[id] = def
	return out
