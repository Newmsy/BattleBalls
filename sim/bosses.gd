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

const DMath := preload("res://sim/dmath.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const Talents := preload("res://sim/talents.gd")

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
	"brood_queen": {
		"display_name": "Brood Queen",
		"description": "A great neon hen gliding round The Nest. She lays eggs that hatch into darting chicks and flings feathers at you. Crack eggs before they hatch: every egg cracked adds to your reward.",
		"color": "ff6fae",
		"arena": "nest",
		"hp": 185.0, "radius": 96.0, "speed": 0.0, "contact_damage": 6.0,
		"time": 75.0,
		"script": "brood",
		"draw_in": 0.0,
		"glide_radius": 290.0, ## Her loop round the nest, centred on the arena.
		"glide_speed": 0.42, ## Radians per boss-clock second.
		"glide_start": -0.785, ## Where on the loop she starts (top right, away from you).
		"lay_every": 3.4, ## Boss-clock seconds between eggs.
		"eggs_max": 3, ## Eggs and chicks alive at once.
		"egg_hp": 14.0,
		"egg_hatch": 5.0, ## Seconds (fight time) an egg takes to hatch.
		"chick_speed": 430.0,
		"chick_hunt": 650.0, ## How hard a chick turns toward you (units/s^2).
		"chick_damage": 5.0,
		"feather_every": 4.5,
		"feather_count": 3,
		"feather_spread": 18.0, ## Degrees between feathers in a volley.
		"feather_speed": 560.0,
		"feather_damage": 9.0,
	},
	"pinata_titan": {
		"display_name": "Piñata Titan",
		"description": "A giant party piñata swinging on its rope over Fiesta Plaza. It never hits back: 30 seconds to smash out as many coins as you can. Break it for the jackpot.",
		"color": "ffb627",
		"arena": "plaza",
		"hp": 360.0, "radius": 92.0, "speed": 0.0, "contact_damage": 0.0,
		"time": 30.0, ## A smash-fest: no one loses, the coins are the damage done.
		"script": "pinata",
		"draw_in": 0.0,
		"pivot": Vector2(500, 30), ## Where its rope hangs from.
		"rope": 430.0,
		"swing": 0.8, ## Radians either side of straight down.
		"swing_speed": 1.5, ## Radians of phase per boss-clock second (slows stretch it).
	},
	"totem_of_nine": {
		"display_name": "Totem of Nine",
		"description": "A spirit totem of nine family heads in the Spirit Shrine. Today's family head is lit: critters of that family hit it half as hard again. It rings out spirit orbs, then aims a fan of them at you.",
		"color": "c9a6ff",
		"arena": "shrine",
		"hp": 215.0, "radius": 104.0, "speed": 0.0, "contact_damage": 6.0,
		"time": 75.0,
		"script": "totem",
		"draw_in": 60.0,
		"family_bonus": 0.5, ## Attack for critters of today's family.
		"volley_every": 2.9, ## Boss-clock seconds between volleys.
		"volley_windup": 0.8, ## The heads light up before they fire: stun it then and it fizzles.
		"ring_count": 9, ## A ring volley: one orb per head, a gap to slip through.
		"fan_count": 3, ## Every other volley: a fan aimed at you.
		"fan_spread": 16.0,
		"orb_speed": 400.0,
		"orb_damage": 10.0,
	},
}

## Minions: a boss's eggs and chicks. Plain-based like bosses; HP and damage
## scale with the boss's power when spawned.
const MINIONS := {
	"brood_egg": {"display_name": "Egg", "radius": 30.0, "speed": 0.0, "contact_damage": 0.0},
	"brood_chick": {"display_name": "Chick", "radius": 30.0, "speed": 430.0, "contact_damage": 5.0},
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


static func minion_def(id: String) -> Dictionary:
	var def := CritterDb.sim_def("plain")
	def.merge(MINIONS[id], true)
	def.id = id
	def.minion = true
	def.effects = []
	return def


## The boss's power multiplier on HP and damage (sqrt of its fight power),
## for its minions. Its own *_damage and *_dps keys are scaled already.
static func _scale(b) -> float:
	return b.max_hp / float(DEFS[b.def.id].hp)


## Puts the boss on its anchor point, the arena's centre unless its def
## names a `home` (MatchSim pins it there).
## `opts` is the fight config's "boss" entry (the Totem's `family`).
static func setup(b, opts := {}) -> void:
	b.pos = b.def.get("home", Vector2(500, 500))
	b.state.family = str(opts.get("family", ""))
	b.state.volleys = 0
	if b.def.script == "brood":
		b.pos = _glide(b.def, 0.0)
	elif b.def.script == "pinata":
		b.pos = _swing(b.def, 0.0)
	b.state.anchor = b.pos
	b.state.clock = 0.0
	b.state.cracked = 0 ## Eggs broken before they hatched (Brood Queen's reward).
	b.state.next_lay = b.def.get("lay_every", 0.0) * 0.5
	b.state.next_feather = b.def.get("feather_every", 0.0)
	b.state.next = b.def.get("slam_every", 2.0) * 0.6
	b.state.swings = 0
	b.anchored = true
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
	match b.def.script:
		"anvil":
			if st.clock >= st.next:
				_anvil_swing(sim, b)
		"brood":
			_brood(sim, b)
		"pinata":
			st.anchor = _swing(b.def, st.clock)
		"totem":
			if st.clock >= st.next:
				_totem_windup(sim, b)


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


## Pins the boss and its eggs back on their anchors (after movement and
## anything that teleports or shoves them).
static func pin_all(sim) -> void:
	for b in sim.balls:
		if b.anchored:
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
		"volley":
			if st.clock >= act.at:
				_totem_fire(sim, b, act)
				st.erase("act")


# --- Brood Queen ---------------------------------------------------------------

static func _glide(d: Dictionary, clock: float) -> Vector2:
	return Vector2(500, 500) + DMath.from_angle(d.glide_start + clock * d.glide_speed) * d.glide_radius


static func _brood(sim, b) -> void:
	var st: Dictionary = b.state
	var d: Dictionary = b.def
	st.anchor = _glide(d, st.clock)
	var k := _scale(b)
	var target = sim.nearest_foe(b)
	# Eggs hatch; chicks hunt you; broken eggs count toward the reward.
	var alive := 0
	for m in sim.balls:
		if m.team != b.team or not m.def.get("minion", false):
			continue
		if not m.alive():
			if m.def.id == "brood_egg" and not m.state.get("counted", false):
				m.state.counted = true
				st.cracked += 1
				sim.events.append({"type": "egg_crack", "ball": b.index, "pos": m.pos, "cracked": st.cracked})
			continue
		alive += 1
		if m.def.id == "brood_egg" and sim.tick >= int(m.state.hatch_at):
			_hatch(sim, m, k, target)
		elif m.def.id == "brood_chick" and target != null and m.pos.distance_to(target.pos) > 0.001 and not sim.stunned(m):
			sim.steer(m, (target.pos - m.pos).normalized() * d.chick_hunt)
	if st.clock >= st.next_lay:
		st.next_lay = st.clock + d.lay_every
		if alive < int(d.eggs_max):
			# Dropped just behind her on the loop.
			var behind: Vector2 = _glide(d, st.clock - 0.45) - st.anchor
			var egg = sim.spawn_minion(b, minion_def("brood_egg"), st.anchor + behind.normalized() * (b.radius + 40.0), d.egg_hp * k)
			egg.anchored = true
			egg.state.anchor = egg.pos
			egg.state.hatch_at = sim.tick + int(round(d.egg_hatch * sim.TICK_RATE))
			sim.events.append({"type": "egg_lay", "ball": b.index, "pos": egg.pos})
	if st.clock >= st.next_feather and target != null:
		st.next_feather = st.clock + d.feather_every
		var dir: Vector2 = (target.pos - st.anchor).normalized()
		var n := int(d.feather_count)
		for i in n:
			var v: Vector2 = DMath.rotated(dir, deg_to_rad(d.feather_spread * (i - (n - 1) / 2.0))) * d.feather_speed
			sim.add_shot(b, st.anchor + dir * b.radius, v, {"kind": "feather", "radius": 10.0, "damage": d.feather_damage, "life": 2.0})


static func _hatch(sim, m, k: float, target) -> void:
	var def := minion_def("brood_chick")
	def.contact_damage *= k
	m.def = def
	m.type_id = def.id
	m.anchored = false
	m.radius = def.radius
	m.speed = def.speed
	m.contact_damage = def.contact_damage
	var dir: Vector2 = (target.pos - m.pos).normalized() if target != null and target.pos.distance_to(m.pos) > 0.001 else Vector2.UP
	m.vel = dir * m.speed
	sim.events.append({"type": "egg_hatch", "ball": m.index, "pos": m.pos})


# --- Piñata Titan --------------------------------------------------------------

## Where the piñata hangs at `clock`: a pendulum under its pivot. A stun
## stops the swing and a slow drags it out, so it's easier to hit.
static func _swing(d: Dictionary, clock: float) -> Vector2:
	var a: float = d.swing * DMath.sin(clock * d.swing_speed)
	return d.pivot + Vector2(DMath.sin(a), DMath.cos(a)) * d.rope


# --- Totem of Nine ------------------------------------------------------------

## Today's family gets its bonus (the lit head): call once the fight's balls exist.
static func bless(sim, b) -> void:
	if b.state.family == "":
		return
	for o in sim.balls:
		if o.team != b.team and Talents.faction_of(o.type_id) == b.state.family:
			o.attack += b.def.family_bonus


static func _totem_windup(sim, b) -> void:
	var st: Dictionary = b.state
	var d: Dictionary = b.def
	st.next = st.clock + d.volley_every
	st.volleys += 1
	var ring: bool = st.volleys % 2 == 1
	var tell = sim.add_zone(b, st.anchor, {"kind": "spirit", "radius": b.radius + 30.0, "life": d.volley_windup * 10.0})
	# A ring's gap turns a seeded step each time; a fan aims where you'll be.
	var turn := float(sim.rng.range_int(0, 359))
	st.act = {"kind": "volley", "at": st.clock + d.volley_windup, "tell": tell, "ring": ring, "turn": turn}
	sim.events.append({"type": "boss_windup", "ball": b.index, "kind": "volley", "pos": st.anchor})


static func _totem_fire(sim, b, act: Dictionary) -> void:
	sim.zones.erase(act.tell)
	var d: Dictionary = b.def
	var dirs: Array[Vector2] = []
	if act.ring:
		var n := int(d.ring_count)
		for i in n - 1: # One head stays quiet: the gap.
			dirs.append(DMath.from_angle(deg_to_rad(act.turn + i * 360.0 / n)))
	else:
		var target = sim.nearest_foe(b)
		if target == null:
			return
		var aim: Vector2 = sim.predict(target, 0.5) - b.state.anchor
		var dir := aim.normalized() if aim.length() > 0.001 else Vector2.DOWN
		var n := int(d.fan_count)
		for i in n:
			dirs.append(DMath.rotated(dir, deg_to_rad(d.fan_spread * (i - (n - 1) / 2.0))))
	for dir in dirs:
		sim.add_shot(b, b.state.anchor + dir * (b.radius + 12.0), dir * d.orb_speed, {"kind": "spirit", "radius": 14.0, "damage": d.orb_damage, "life": 2.6})


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
		"quake", "volley":
			sim.zones.erase(act.tell)
	st.erase("act")
	sim.events.append({"type": "boss_fizzle", "ball": b.index, "kind": act.kind, "pos": at})
