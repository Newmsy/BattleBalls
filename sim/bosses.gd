## Farming bosses (design/bosses.md): set pieces, not bouncing balls. A boss is
## ball 1 of a normal MatchSim fight, so damage, statuses, shots and replays
## all work as usual, but it's anchored where it starts (critters bounce off
## it like a wall; pulls and knockbacks never move it) and it attacks from a
## script run on its own clock:
##   - a stun cancels the attack it is winding up (it fizzles);
##   - slows stretch its clock, so attacks come less often.
##   - its magnet core drags what critters leave on the floor into it.
## Boss attacks are pulses, lobs and zones owned by the boss, scripted from
## that clock and the fight rng, so a boss fight still replays from the seed
## and the launch angle. The boss wins if the clock runs out (`time`).
##
## A boss fight config names the boss as p2 and its map as arena (boss maps
## live in sim/arenas.gd BOSS_ARENAS and needn't be point-symmetric).
extends RefCounted

const CritterDb := preload("res://sim/critter_db.gd")

## id -> the boss: stats like a critter's plus its script's params. Keys
## ending in _damage or _dps scale with the fight's power (sim/power.gd).
const DEFS := {
	"anvil_king": {
		"display_name": "Anvil King",
		"description": "A forge golem rooted in the middle of The Forge. It slams its hammer where you're heading and leaves embers burning; every fourth swing it quakes the whole floor near it. Its magnet core drags mines and trails into it.",
		"color": "ff8a3d",
		"arena": "forge",
		"hp": 260.0, "radius": 128.0, "speed": 0.0, "contact_damage": 6.0,
		"time": 75.0, ## Seconds to bring it down, or it wins.
		"script": "anvil",
		"draw_in": 110.0, ## Units/s your floor zones slide toward it (Magnet core).
		"slam_every": 2.0, ## Boss-clock seconds between swings (slows stretch it).
		"slam_windup": 1.1, ## The hammer's flight: the telegraph you dodge.
		"slam_lead": 0.3, ## 0 aims where you are, 1 where you'll be when it lands.
		"slam_radius": 105.0,
		"slam_damage": 13.0,
		"ember_radius": 58.0,
		"ember_life": 3.5,
		"ember_dps": 5.0,
		"quake_every": 4, ## Every Nth swing is a quake instead.
		"quake_windup": 1.2,
		"quake_radius": 360.0,
		"quake_damage": 12.0,
	},
}


static func has(id: String) -> bool:
	return DEFS.has(id)


## The flat sim definition for boss `id`: Plain's keys (so every ability that
## reads a foe's def finds them) with the boss's on top.
static func sim_def(id: String) -> Dictionary:
	var def := CritterDb.sim_def("plain")
	def.merge(DEFS[id], true)
	def.id = id
	def.boss = true
	def.color = Color(DEFS[id].color)
	def.effects = []
	return def


## Puts the boss on its anchor point, the arena's centre unless its def
## names a `home` (MatchSim pins it there).
static func setup(b) -> void:
	b.pos = b.def.get("home", Vector2(500, 500))
	b.state.anchor = b.pos
	b.state.clock = 0.0
	b.state.next = b.def.get("slam_every", 2.0) * 0.6
	b.state.swings = 0
	b.vel = Vector2.ZERO


## One tick of the boss's script, before anything moves.
static func tick(sim, b) -> void:
	var st: Dictionary = b.state
	if sim.stunned(b):
		if st.has("act"):
			_fizzle(sim, b)
		return
	_draw_in(sim, b)
	st.clock += sim.DT * (1.0 - clampf(b.slow, 0.0, 0.9))
	if st.has("act"):
		_resolve(sim, b)
		return
	if st.clock >= st.next:
		match b.def.script:
			"anvil":
				_anvil_swing(sim, b)


## Magnet core: what critters leave on the floor (mines, trails, puddles)
## slides toward the boss, so floor kits hit a target that never walks into
## them.
static func _draw_in(sim, b) -> void:
	var pull: float = b.def.get("draw_in", 0.0)
	if pull <= 0.0:
		return
	var step: float = pull * sim.DT
	for z in sim.zones:
		if z.owner == b.index or z.follow >= 0 or sim.balls[z.owner].team == b.team:
			continue
		var d: Vector2 = b.pos - z.pos
		var room: float = d.length() - b.radius * 0.5
		if room > 0.0:
			z.pos += d.normalized() * minf(step, room)


## Pins the boss back on its anchor (after movement and anything that
## teleports or shoves it).
static func pin(b) -> void:
	b.pos = b.state.anchor
	b.vel = Vector2.ZERO


# --- Anvil King ---------------------------------------------------------------

static func _anvil_swing(sim, b) -> void:
	var st: Dictionary = b.state
	var d: Dictionary = b.def
	st.swings += 1
	st.next = st.clock + d.slam_every
	var target = sim.nearest_foe(b)
	if target == null:
		return
	if st.swings % int(d.quake_every) == 0:
		# A quake: a warning ring, then a shockwave out from the anvil.
		var tell = sim.add_zone(b, st.anchor, {"kind": "quake", "radius": d.quake_radius, "life": d.quake_windup * 10.0})
		st.act = {"kind": "quake", "at": st.clock + d.quake_windup, "tell": tell}
		sim.events.append({"type": "boss_windup", "ball": b.index, "kind": "quake", "pos": st.anchor})
		return
	# A slam a little ahead of the target: keep moving (or bounce away) and
	# it misses; get pinned or slowed and it lands.
	var aim: Vector2 = target.pos.lerp(sim.predict(target, d.slam_windup), d.slam_lead)
	aim += Vector2(sim.rng.range_int(-40, 40), sim.rng.range_int(-40, 40))
	var shot = sim.add_lob(b, aim, d.slam_windup, {"kind": "hammer", "radius": 24.0, "damage": d.slam_damage,
		"land_radius": d.slam_radius, "knock": true,
		"zone": {"kind": "ember", "radius": d.ember_radius, "life": d.ember_life, "dps": d.ember_dps}})
	st.act = {"kind": "slam", "shot": shot}
	sim.events.append({"type": "boss_windup", "ball": b.index, "kind": "slam", "pos": shot.land})


## Finishes the attack in progress when its time comes.
static func _resolve(sim, b) -> void:
	var st: Dictionary = b.state
	var act: Dictionary = st.act
	match act.kind:
		"slam":
			if not sim.shots.has(act.shot): # Landed (the lob dealt its own pulse).
				st.erase("act")
		"quake":
			if st.clock >= act.at:
				sim.zones.erase(act.tell)
				sim.pulse(b, st.anchor, b.def.quake_radius, b.def.quake_damage, true, "quake")
				st.erase("act")


## A stun on the boss cancels its wind-up.
static func _fizzle(sim, b) -> void:
	var st: Dictionary = b.state
	var act: Dictionary = st.act
	var at: Vector2 = st.anchor
	match act.kind:
		"slam":
			if sim.shots.has(act.shot):
				at = act.shot.land
				sim.shots.erase(act.shot)
		"quake":
			sim.zones.erase(act.tell)
	st.erase("act")
	sim.events.append({"type": "boss_fizzle", "ball": b.index, "kind": act.kind, "pos": at})
