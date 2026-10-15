## The fight sim's view of every critter. Critters live one per file in
## sim/critters/ (read by sim/critter_db.gd); this turns them into the flat
## definitions the sim reads and keeps the old BallDefs API for callers.
extends RefCounted

const CritterDb := preload("res://sim/critter_db.gd")

## id -> flat T1 definition, for every critter the sim can fight with.
static var DEFS: Dictionary = _defs()
## Critters offered to players (status "live"), in Critterpedia order.
static var PLAYABLE: Array = CritterDb.live_ids()


static func get_def(id: String, tier := 1) -> Dictionary:
	assert(DEFS.has(id), "Unknown ball id: %s" % id)
	return DEFS[id] if tier == 1 else CritterDb.sim_def(id, tier)


static func _defs() -> Dictionary:
	var out := {}
	for id in CritterDb.sim_ids():
		out[id] = CritterDb.sim_def(id)
	return out
