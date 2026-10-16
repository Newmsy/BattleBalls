## Determinism probe: a fixed, varied set of fights (every arena, random
## critters, tiers, aims, 2v2s and modifiers) hashed into one value. The web
## build (?probe=1), headless Godot and later the store builds must all print
## the same hash, or two players' phones could see different fights.
extends RefCounted

const MatchSim := preload("res://sim/match_sim.gd")
const Rng := preload("res://sim/rng.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const Arenas := preload("res://sim/arenas.gd")
const Modifiers := preload("res://sim/modifiers.gd")

const DEFAULT_FIGHTS := 200


static func configs(count := DEFAULT_FIGHTS) -> Array:
	var ids: Array = CritterDb.live_ids()
	var mods: Array = Modifiers.DEFS.keys()
	var r := Rng.new(20261016)
	var out := []
	for i in count:
		var c := {"seed": int(r.next_u32()), "p1": _pick(r, ids), "p2": _pick(r, ids),
			"arena": Arenas.PLAYABLE[i % Arenas.PLAYABLE.size()],
			"angles": [r.range_int(-1800, 1799), r.range_int(-1800, 1799)],
			"tiers": [r.range_int(1, 5), r.range_int(1, 5)]}
		if i % 4 == 0:
			c.p3 = _pick(r, ids)
			c.p4 = _pick(r, ids)
			c.angles = [r.range_int(-1800, 1799), null, null, null]
			c.tiers = [r.range_int(1, 5), r.range_int(1, 5), r.range_int(1, 5), r.range_int(1, 5)]
		if i % 7 == 0:
			c.modifier = _pick(r, mods)
		out.append(c)
	return out


## {"hash": one hash over every fight, "fights": how many ran}.
static func run(count := DEFAULT_FIGHTS) -> Dictionary:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	var cs := configs(count)
	for c in cs:
		var s: Dictionary = MatchSim.new(c).run_to_end()
		ctx.update(("%d|%d|%s" % [s.winner, s.ticks, s.hash]).to_utf8_buffer())
	return {"hash": ctx.finish().hex_encode(), "fights": cs.size()}


static func _pick(r: Rng, from: Array) -> Variant:
	return from[r.range_int(0, from.size() - 1)]
