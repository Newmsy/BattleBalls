## The trigger + effect library every critter ability is built from
## (combat-foundation.md section 2). A critter file lists entries like
## {"on": "wall", "do": "beam"}; the sim fires the trigger and this library
## runs the effect with the critter's params. Effects get the MatchSim, the
## ball that owns the ability and the trigger's context. A new critter that reuses these
## needs no code; a new effect is one fx_<name> method plus its EFFECTS entry.
## Effects must stay deterministic: no randf(), no time, only sim.rng.
extends RefCounted

## Trigger -> what fires it and the extra keys its entry may carry.
const TRIGGERS := {
	"hit": "lands a contact hit (ctx: target, amount, heals)",
	"hurt": "takes damage from anything (ctx: source, amount, kind)",
	"wall": "bounces off a wall (ctx: point)",
	"foe_wall": "the other ball bounces off a wall (ctx: other, point)",
	"bump": "touches the other ball, even during the contact cooldown (ctx: other)",
	"every": "every `secs` seconds of fight time, first at `secs`",
	"hp_below": "once, when its HP first drops below `hp` (a 0-1 share of max HP)",
	"start": "once, on the first tick",
	"always": "every tick, before balls move (auras, fields)",
	"strike": "its contact hit is about to land (ctx: target, mult); effects scale ctx.mult",
	"guard": "any damage is about to land on it (ctx: source, kind, mult); effects scale ctx.mult",
	"fall": "once, the first time its HP hits 0; an effect may bring it back (revive)",
}
## Effect -> the params it reads from the critter's "params".
const EFFECTS := {
	"heal": ["heal_ratio"],
	"beam": ["beam_life", "beam_damage", "beam_hit_cooldown", "beam_max"],
	"field": ["field_period", "field_range", "field_accel", "push_scale"],
	"snap": ["snap_mult"],
	"mine": ["mine_arm", "mine_radius", "mine_damage", "mine_max", "mine_life", "mine_chain"],
	"trail": ["trail_every", "trail_width", "trail_life", "trail_slow", "trail_dps"],
	"breath": ["breath_radius", "breath_slow", "breath_secs"],
	"reflect": ["reflect_ratio", "reflect_low", "reflect_burn", "reflect_from", "reflect_cap"],
	"phase": ["phase_secs"],
	"phased": ["phase_guard"],
	"ambush": ["ambush_mult"],
	"phase_dash": [],
	"phase_trail": ["trail_every", "trail_width", "trail_life", "trail_slow", "trail_dps"],
	"pull": ["pull_range", "pull_accel", "pull_close"],
	"moons": ["moon_count", "moon_orbit", "moon_size", "moon_damage", "moon_spin", "moon_cooldown", "moon_burn"],
	"flare": ["flare_radius", "flare_slam"],
	"copy": ["copy_secs", "copy_cooldown", "copy_shield", "copy_scale"],
	"revive": ["revive_hp", "revive_radius", "revive_damage", "revive_burn", "revive_shield", "revive_bolts"],
	"fire_trail": ["trail_every", "trail_width", "trail_life", "trail_dps"],
	"beam_at": ["prism_damage", "prism_life", "prism_fan", "prism_full_every", "prism_gap"],
	"collapse": ["collapse_every", "collapse_secs", "collapse_range", "collapse_accel", "collapse_damage", "collapse_radius", "collapse_ring", "collapse_burn"],
	"collapse_guard": ["collapse_guard"],
	"copy_tick": [],
	"scorch": ["scorch_dps", "scorch_secs"],
	# Batch D statuses: stun (freeze), vulnerable and timed slows (MatchSim.stun, add_status).
	"gum": ["gum_slow", "gum_secs", "gum_burn", "gum_stacks", "gum_cap"],
	"sour": ["sour_amount", "sour_secs", "sour_max", "sour_puddle", "sour_puddle_slow"],
	"zap": ["zap_damage", "zap_stun", "zap_linger_dps", "zap_storm_every"],
	"zap_tick": [],
	"frostbite": ["bite_slow", "bite_max", "bite_secs", "bite_freeze", "shard_damage", "shard_radius", "bite_sour", "bite_sour_secs"],
	"shatter": ["shatter_mult"],
	"paint": ["paint_every", "paint_width", "paint_life", "paint_vuln", "paint_linger"],
	"paint_flash": ["paint_flash_damage"],
	"lamp": ["lamp_life", "lamp_dps", "lamp_vuln", "lamp_vuln_secs", "lamp_sweep", "lamp_back"],
	"lamp_sweep": [],
	"wrap": ["wrap_hold", "wrap_vuln", "wrap_vuln_secs", "wrap_confetti", "wrap_pull_every", "wrap_pull"],
	"wrap_tick": [],
	"shove": ["slam_damage", "slam_window", "slam_freeze", "slam_patch", "slam_patch_slow"],
	"spark": ["spark_max"],
	"storm": ["storm_dps", "storm_stun", "storm_burn", "thunder_radius", "thunder_damage"],
	"grow_spike": ["spike_max"],
	"spikes": ["spike_damage", "spike_max"],
	"accelerate": ["speed_gain", "max_speed_mult"],
	"momentum": [],
	"brake": [],
	"mark_slam": ["slam_window"],
	"slam": ["slam_damage"],
}

## Problems with a live critter's ability entries (see CritterDb.validate).
static func validate(id: String, entries: Array, params: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for e in entries:
		if not TRIGGERS.has(e.get("on", "")):
			errors.append("%s: unknown trigger \"%s\"; use one of %s" % [id, e.get("on", ""), TRIGGERS.keys()])
		if not EFFECTS.has(e.get("do", "")):
			errors.append("%s: unknown effect \"%s\"; add it to sim/abilities.gd or use one of %s" % [id, e.get("do", ""), EFFECTS.keys()])
			continue
		for p in EFFECTS[e.do]:
			if not params.has(p):
				errors.append("%s: effect \"%s\" needs param \"%s\"" % [id, e.do, p])
		var secs = e.get("secs", 0.0)
		if e.get("on") == "every" and not (secs is String and params.has(secs)) and float(secs if not secs is String else 0.0) <= 0.0:
			errors.append("%s: an \"every\" trigger needs \"secs\" > 0 (or the name of a param)" % id)
		if e.get("on") == "hp_below" and not (float(e.get("hp", -1.0)) >= 0.0 and float(e.get("hp", -1.0)) < 1.0):
			errors.append("%s: an \"hp_below\" trigger needs \"hp\" between 0 and 1" % id)
	return errors


## Runs every effect `b` has for `trigger`.
func fire(sim, trigger: String, b, ctx := {}) -> void:
	var def: Dictionary = b.def
	for e in def.effects:
		if not is_same(b.def, def):
			return # A copy started or ended (Echo): its effects no longer apply.
		if e.on == trigger:
			call("fx_" + e.do, sim, b, ctx)


## Timer and HP-threshold triggers, checked once per tick after hits land.
func tick_triggers(sim, b) -> void:
	var def: Dictionary = b.def
	for e in def.effects:
		if not is_same(b.def, def):
			return
		match e.on:
			"start":
				if sim.tick == 0:
					call("fx_" + e.do, sim, b, {})
			"every":
				var secs: float = b.def[e.secs] if e.secs is String else e.secs
				var every := maxi(1, int(round(secs * sim.TICK_RATE)))
				if sim.tick > 0 and sim.tick % every == 0:
					call("fx_" + e.do, sim, b, {})
			"hp_below":
				var key := "hp_below:%s" % e.hp
				if not b.fired.has(key) and b.hp < b.max_hp * e.hp:
					b.fired[key] = true
					call("fx_" + e.do, sim, b, {})


# --- Effects ------------------------------------------------------------------

## Heals for heal_ratio of the damage just dealt. Heals land after all damage
## in the tick, so a lethal hit can't be out-healed.
func fx_heal(_sim, b, ctx: Dictionary) -> void:
	if ctx.has("heals") and b.dots.is_empty(): # Burning balls can't heal.
		ctx.heals.append({"ball": b.index, "amount": ctx.amount * b.def.heal_ratio})


## A damaging segment from the previous wall bounce point to this one.
func fx_beam(sim, b, ctx: Dictionary) -> void:
	if not ctx.has("point") or not b.has_bounce or b.last_bounce.distance_to(ctx.point) < sim.MIN_BEAM_LENGTH:
		return
	sim.add_beam(b, b.last_bounce, ctx.point)


## A pull/push field that flips every field_period seconds (Pull first). It
## steers both balls, the owner too, so they really attract; steering only
## turns a ball and keeps its speed. Strength fades to 0 at field_range; Push
## steers at push_scale of Pull. State: b.state.pulling, and a flip back to
## Pull re-arms snap. Emits "flip" events.
func fx_field(sim, b, _ctx: Dictionary) -> void:
	var period := maxi(1, int(round(b.def.field_period * sim.TICK_RATE)))
	var pulling: bool = (sim.tick / period) % 2 == 0
	if pulling != b.state.get("pulling", true):
		b.state.pulling = pulling
		if pulling:
			b.state.snap_ready = true
		sim.events.append({"type": "flip", "ball": b.index, "pulling": pulling, "pos": b.pos})
	for other in sim.balls:
		if other == b or not other.alive():
			continue
		var delta: Vector2 = b.pos - other.pos
		var dist := delta.length()
		if dist < 0.001 or dist >= b.def.field_range:
			continue
		var strength: float = b.def.field_accel * (1.0 - dist / b.def.field_range)
		if not pulling:
			strength *= -b.def.push_scale
		var pull := delta / dist * strength
		sim.steer(other, pull)
		sim.steer(b, -pull)


## The first contact hit while a field is on Pull deals snap_mult damage; it
## re-arms on the next flip to Pull (see fx_field). Emits "snap" events.
func fx_snap(sim, b, ctx: Dictionary) -> void:
	if not b.state.get("pulling", true) or not b.state.get("snap_ready", true):
		return
	b.state.snap_ready = false
	sim.events.append({"type": "snap", "ball": b.index, "pos": b.pos})
	ctx.mult *= b.def.snap_mult


## Drops a mine where it bounced; it arms after mine_arm, explodes on the first
## foe that touches it (mine_damage within mine_radius) and fizzles after
## mine_life. Keeps at most mine_max, dropping the oldest. mine_chain 1 makes a
## blast set off its other armed mines in reach.
func fx_mine(sim, b, _ctx: Dictionary) -> void:
	var own: Array = sim.zones.filter(func(z): return z.owner == b.index and z.kind == "mine")
	if own.size() >= int(b.def.mine_max):
		sim.zones.erase(own[0])
	sim.add_zone(b, b.pos, {"kind": "mine", "radius": 16.0, "life": b.def.mine_life, "arm": b.def.mine_arm,
		"blast": b.def.mine_damage, "blast_radius": b.def.mine_radius, "chain": b.def.mine_chain > 0})


func _drop_trail(sim, b, kind: String) -> void:
	var every := maxi(1, int(round(b.def.trail_every * sim.TICK_RATE)))
	if sim.tick % every == 0:
		sim.add_zone(b, b.pos, {"kind": kind, "radius": b.def.trail_width, "life": b.def.trail_life,
			"slow": b.def.get("trail_slow", 0.0), "dps": b.def.trail_dps})


## Leaves a trail of zones behind it that slow foes by trail_slow and deal
## trail_dps while they're in it.
func fx_trail(sim, b, _ctx: Dictionary) -> void:
	_drop_trail(sim, b, "ice")


## A short-lived slowing cloud around it.
func fx_breath(sim, b, _ctx: Dictionary) -> void:
	sim.add_zone(b, b.pos, {"kind": "frost", "radius": b.def.breath_radius, "life": b.def.breath_secs, "slow": b.def.breath_slow})
	sim.events.append({"type": "pulse", "ball": b.index, "pos": b.pos, "radius": b.def.breath_radius, "kind": "frost"})


## Sends reflect_ratio of damage taken back at the attacker (reflect_low below
## half HP when > 0), at most reflect_cap per hit when > 0. reflect_from
## "ability" ignores contact hits, "contact" only answers contact hits, "copying"
## only answers contact hits while copying. reflect_burn > 0 also burns them for 2s.
## Reflected damage and burns never reflect.
func fx_reflect(sim, b, ctx: Dictionary) -> void:
	if ctx.kind in ["reflect", "burn", "slam"] or ctx.source == b or ctx.source.team == b.team:
		return
	match str(b.def.reflect_from):
		"ability":
			if ctx.kind == "contact":
				return
		"contact":
			if ctx.kind != "contact":
				return
		"copying":
			if ctx.kind != "contact" or not b.state.has("copy_until"):
				return
	var ratio: float = b.def.reflect_ratio
	if b.def.reflect_low > 0.0 and b.hp < b.max_hp * 0.5:
		ratio = b.def.reflect_low
	var amount: float = ctx.amount * ratio
	if b.def.reflect_cap > 0.0:
		amount = minf(amount, b.def.reflect_cap)
	sim.deal(b, ctx.source, amount, "reflect")
	sim.events.append({"type": "reflect", "ball": b.index, "from": b.pos, "to": ctx.source.pos})
	if b.def.reflect_burn > 0.0:
		sim.add_burn(b, ctx.source, b.def.reflect_burn, 2.0)


## Fades out for phase_secs (see fx_phased) and readies an ambush (fx_ambush).
func fx_phase(sim, b, _ctx: Dictionary) -> void:
	b.state.phase_until = sim.tick + int(round(b.def.phase_secs * sim.TICK_RATE))
	b.state.ambush_ready = true
	sim.events.append({"type": "phase", "ball": b.index, "pos": b.pos})


static func phased(sim, b) -> bool:
	return sim.tick < int(b.state.get("phase_until", -1))


## While phased it takes phase_guard x damage.
func fx_phased(sim, b, ctx: Dictionary) -> void:
	if phased(sim, b):
		ctx.mult *= b.def.phase_guard


## Its first contact hit after phasing deals ambush_mult x.
func fx_ambush(sim, b, ctx: Dictionary) -> void:
	if b.state.get("ambush_ready", false) and not phased(sim, b):
		b.state.ambush_ready = false
		ctx.mult *= b.def.ambush_mult
		sim.events.append({"type": "ambush", "ball": b.index, "pos": b.pos})


## When a phase ends, it turns to fly straight at the nearest foe.
func fx_phase_dash(sim, b, _ctx: Dictionary) -> void:
	if sim.tick == int(b.state.get("phase_until", -1)):
		var f = sim.nearest_foe(b)
		if f != null and f.pos.distance_to(b.pos) > 0.001:
			b.vel = (f.pos - b.pos).normalized() * b.speed


## A slowing trail, only while phased.
func fx_phase_trail(sim, b, _ctx: Dictionary) -> void:
	if phased(sim, b):
		_drop_trail(sim, b, "wisp")


## Steers foes toward it, fading to 0 at pull_range. pull_close 1 makes it
## stronger the closer they are (otherwise even across the range).
func fx_pull(sim, b, _ctx: Dictionary) -> void:
	for o in sim.foes(b):
		var delta: Vector2 = b.pos - o.pos
		var dist := delta.length()
		if dist < 0.001 or dist >= b.def.pull_range:
			continue
		var k: float = 1.0 - dist / b.def.pull_range if b.def.pull_close > 0 else 1.0
		sim.steer(o, delta / dist * b.def.pull_accel * k)


## moon_count moons circle it moon_orbit beyond its edge; each hits a foe it
## touches for moon_damage, at most once per moon_cooldown, and moon_burn > 0
## sets it burning (that much a second for 2s). Positions are in
## b.state.moons for the renderer.
func fx_moons(sim, b, _ctx: Dictionary) -> void:
	var n := int(b.def.moon_count)
	var moons: Array[Vector2] = []
	var hit_at: Dictionary = b.state.get("moon_hits", {})
	b.state.moon_hits = hit_at
	var dist: float = b.radius + b.def.moon_orbit
	for k in n:
		var ang: float = sim.tick * sim.DT * b.def.moon_spin + k * TAU / n
		var p: Vector2 = b.pos + Vector2.from_angle(ang) * dist
		moons.append(p)
		for o in sim.foes(b):
			var key := "%d:%d" % [k, o.index]
			if p.distance_to(o.pos) <= o.radius + b.def.moon_size and sim.tick >= int(hit_at.get(key, 0)):
				hit_at[key] = sim.tick + int(round(b.def.moon_cooldown * sim.TICK_RATE))
				sim.deal(b, o, b.def.moon_damage, "moon", p)
				if b.def.moon_burn > 0.0:
					sim.add_burn(b, o, b.def.moon_burn, 2.0)
	b.state.moons = moons


## Flings foes within flare_radius straight away; one that hits a wall within
## a second takes flare_slam.
func fx_flare(sim, b, _ctx: Dictionary) -> void:
	sim.pulse(b, b.pos, b.def.flare_radius, 0.0, true, "flare")
	for o in sim.foes(b):
		if o.pos.distance_to(b.pos) <= b.def.flare_radius + o.radius:
			o.state.slam = {"source": b.index, "damage": b.def.flare_slam, "until": sim.tick + sim.TICK_RATE}


## When hurt by a foe (at most every copy_cooldown), borrows that foe's ability
## for copy_secs: their effects and params join its own. copy_shield > 0 also
## gives a shield. The original definition is restored when the copy ends.
func fx_copy(sim, b, ctx: Dictionary) -> void:
	if b.state.has("copy_until") and sim.tick >= b.state.copy_until:
		_end_copy(b)
	var src = ctx.get("source")
	if src == null or src.team == b.team or ctx.kind == "reflect":
		return
	if sim.tick < int(b.state.get("copy_ready", 0)):
		return
	if b.state.has("copy_until"):
		_end_copy(b)
	var base: Dictionary = b.def
	var copied := base.duplicate()
	for key in src.def:
		if not copied.has(key):
			copied[key] = src.def[key]
			if key.ends_with("_damage") or key.ends_with("_dps") or key.ends_with("_accel"): # A copy hits (and pulls) softer.
				copied[key] = src.def[key] * base.copy_scale
			elif key.ends_with("_mult"): # ...and multiplies softer.
				copied[key] = 1.0 + (src.def[key] - 1.0) * base.copy_scale
	var effects: Array = base.effects.duplicate()
	for e in src.def.effects:
		if not e.do in ["copy", "revive", "reflect"]:
			effects.append(e)
	copied.effects = effects
	b.state.base_def = base
	b.def = copied
	b.state.copy_until = sim.tick + int(round(base.copy_secs * sim.TICK_RATE))
	b.state.copy_ready = sim.tick + int(round(base.copy_cooldown * sim.TICK_RATE))
	b.state.copy_of = src.type_id
	if base.copy_shield > 0.0:
		b.shield = maxf(b.shield, base.copy_shield)
	sim.events.append({"type": "copy", "ball": b.index, "from": src.index, "pos": b.pos})


## Ends a copy when its time is up (an "always" entry next to copy).
func fx_copy_tick(sim, b, _ctx: Dictionary) -> void:
	if b.state.has("copy_until") and sim.tick >= b.state.copy_until:
		_end_copy(b)


static func _end_copy(b) -> void:
	b.def = b.state.base_def
	b.state.erase("base_def")
	b.state.erase("copy_until")
	b.state.erase("copy_of")


## The first time it falls, it comes back at revive_hp of max HP, blasting foes
## within revive_radius for revive_damage and burning them (revive_burn per
## second for 3s). revive_shield > 0 adds a shield; revive_bolts > 0 also fires
## that many short beams outward (5 damage each).
func fx_revive(sim, b, _ctx: Dictionary) -> void:
	b.hp = b.max_hp * b.def.revive_hp
	b.state.revived = true
	sim.events.append({"type": "revive", "ball": b.index, "pos": b.pos})
	sim.pulse(b, b.pos, b.def.revive_radius, b.def.revive_damage, false, "fire")
	if b.def.revive_burn > 0.0:
		for o in sim.foes(b):
			if o.pos.distance_to(b.pos) <= b.def.revive_radius + o.radius:
				sim.add_burn(b, o, b.def.revive_burn, 3.0)
	if b.def.revive_shield > 0.0:
		b.shield = maxf(b.shield, b.def.revive_shield)
	for k in int(b.def.revive_bolts):
		var dir := Vector2.from_angle(k * TAU / b.def.revive_bolts)
		sim.add_beam(b, b.pos + dir * b.radius, b.pos + dir * (b.radius + 260.0), {"life": 0.6, "damage": 5.0, "cooldown": 1.0})


## Hits set the target burning (scorch_dps per second for scorch_secs).
## A burning ball can't heal.
func fx_scorch(sim, b, ctx: Dictionary) -> void:
	if ctx.has("target"):
		sim.add_burn(b, ctx.target, b.def.scorch_dps, b.def.scorch_secs)


## After reviving, a fire trail (dps zones) for the rest of the fight.
func fx_fire_trail(sim, b, _ctx: Dictionary) -> void:
	if b.state.get("revived", false):
		_drop_trail(sim, b, "fire")


## On a wall bounce, a rainbow beam from the bounce point toward the nearest
## foe (prism_damage per hit, 4 hits a second), at most one cast every
## prism_gap seconds (pillar and bumper arenas bounce a lot). prism_fan beams
## spread 15 degrees apart; every prism_full_every-th cast (when > 0) fans 7.
func fx_beam_at(sim, b, ctx: Dictionary) -> void:
	var f = sim.nearest_foe(b)
	if f == null or not ctx.has("point") or sim.tick < int(b.state.get("prism_next", 0)):
		return
	b.state.prism_next = sim.tick + int(round(b.def.prism_gap * sim.TICK_RATE))
	b.state.bounces = int(b.state.get("bounces", 0)) + 1
	var n := int(b.def.prism_fan)
	if b.def.prism_full_every > 0 and b.state.bounces % int(b.def.prism_full_every) == 0:
		n = 7
	var to: Vector2 = f.pos - ctx.point
	var length := maxf(to.length() * 1.15, 200.0)
	for k in n:
		var dir := to.normalized().rotated(deg_to_rad(15.0 * (k - (n - 1) / 2.0)))
		sim.add_beam(b, ctx.point, ctx.point + dir * length, {"life": b.def.prism_life, "damage": b.def.prism_damage, "cooldown": 0.25})


## Every collapse_every seconds it collapses for collapse_secs, dragging foes
## within collapse_range in hard, then explodes: collapse_damage within
## collapse_radius, knocking them away. collapse_ring > 0 leaves a burning ring
## (that much damage a second, 3s); collapse_burn > 0 sets foes it blasts
## burning for 3s. State: b.state.collapsing.
func fx_collapse(sim, b, _ctx: Dictionary) -> void:
	var every := int(round(b.def.collapse_every * sim.TICK_RATE))
	var dur := int(round(b.def.collapse_secs * sim.TICK_RATE))
	var t: int = sim.tick % every
	var collapsing: bool = sim.tick >= every and t < dur
	b.state.collapsing = collapsing
	if collapsing:
		for o in sim.foes(b):
			var delta: Vector2 = b.pos - o.pos
			var dist := delta.length()
			if dist > 0.001 and dist < b.def.collapse_range:
				sim.steer(o, delta / dist * b.def.collapse_accel)
	elif sim.tick >= every and t == dur:
		sim.pulse(b, b.pos, b.def.collapse_radius, b.def.collapse_damage, true, "nova")
		if b.def.collapse_burn > 0.0:
			for o in sim.foes(b):
				if o.pos.distance_to(b.pos) <= b.def.collapse_radius + o.radius:
					sim.add_burn(b, o, b.def.collapse_burn, 3.0)
		if b.def.collapse_ring > 0.0:
			sim.add_zone(b, b.pos, {"kind": "ring", "radius": b.def.collapse_radius, "life": 3.0, "dps": b.def.collapse_ring})


## While collapsing it takes collapse_guard x damage.
func fx_collapse_guard(_sim, b, ctx: Dictionary) -> void:
	if b.state.get("collapsing", false):
		ctx.mult *= b.def.collapse_guard



# --- Batch D: stuns, vulnerable, timed slows -----------------------------------

## Hits gum the target up: slowed gum_slow for gum_secs. gum_stacks > 1 lets
## repeat hits stack it (gum_slow each, at most gum_cap); gum_burn > 0 also
## burns it (that much a second for 2s).
func fx_gum(sim, b, ctx: Dictionary) -> void:
	var t = ctx.get("target")
	if t == null:
		return
	var key := "gum:%d" % b.index
	var amount: float = b.def.gum_slow
	var held: Dictionary = sim.status(t, key)
	if b.def.gum_stacks > 1 and not held.is_empty():
		amount = minf(held.amount + b.def.gum_slow, minf(b.def.gum_cap, b.def.gum_slow * b.def.gum_stacks))
	sim.add_status(b, t, key, "slow", amount, b.def.gum_secs)
	if b.def.gum_burn > 0.0:
		sim.add_burn(b, t, b.def.gum_burn, 2.0)


## Hits make the target sour: it takes sour_amount more damage for sour_secs.
## Repeat hits stack up to sour_max when that's higher. sour_puddle > 0 also
## leaves a sour puddle that big under it (2s, slows sour_puddle_slow).
func fx_sour(sim, b, ctx: Dictionary) -> void:
	var t = ctx.get("target")
	if t == null:
		return
	var key := "sour:%d" % b.index
	var amount: float = b.def.sour_amount
	var held: Dictionary = sim.status(t, key)
	if b.def.sour_max > amount and not held.is_empty():
		amount = minf(held.amount + b.def.sour_amount, b.def.sour_max)
	sim.add_status(b, t, key, "vulnerable", amount, b.def.sour_secs)
	sim.events.append({"type": "sour", "ball": t.index, "pos": t.pos})
	if b.def.sour_puddle > 0.0:
		sim.add_zone(b, t.pos, {"kind": "sour", "radius": b.def.sour_puddle, "life": 2.0, "slow": b.def.sour_puddle_slow})


## Zaps the nearest foe with an arc: zap_damage and a zap_stun stun.
## zap_linger_dps > 0 leaves the arc as a beam for 1s; every zap_storm_every-th
## zap (when > 0) is a storm: two more arcs follow over the next second
## (needs zap_tick on "always").
func fx_zap(sim, b, _ctx: Dictionary) -> void:
	b.state.zaps = int(b.state.get("zaps", 0)) + 1
	if b.def.zap_storm_every > 0 and b.state.zaps % int(b.def.zap_storm_every) == 0:
		b.state.storm = [sim.tick + sim.TICK_RATE / 3, sim.tick + 2 * sim.TICK_RATE / 3]
	_arc(sim, b)


func _arc(sim, b) -> void:
	var f = sim.nearest_foe(b)
	if f == null:
		return
	sim.deal(b, f, b.def.zap_damage, "zap", f.pos)
	sim.stun(b, f, b.def.zap_stun)
	if b.def.zap_linger_dps > 0.0:
		sim.add_beam(b, b.pos, f.pos, {"life": 1.0, "damage": b.def.zap_linger_dps * 0.25, "cooldown": 0.25})
	else:
		sim.add_beam(b, b.pos, f.pos, {"life": 0.2, "damage": 0.0})


## Fires a storm's follow-up arcs on time.
func fx_zap_tick(sim, b, _ctx: Dictionary) -> void:
	var storm: Array = b.state.get("storm", [])
	if not storm.is_empty() and sim.tick >= storm[0]:
		storm.pop_front()
		_arc(sim, b)


## Hits frost the target: bite_slow slow per stack for bite_secs. At bite_max
## stacks it freezes (stunned bite_freeze) and bursts into ice shards
## (shard_damage to foes within shard_radius of it), and the frost resets.
## bite_sour > 0 also makes the frozen foe take that much more damage for
## bite_sour_secs.
func fx_frostbite(sim, b, ctx: Dictionary) -> void:
	var t = ctx.get("target")
	if t == null:
		return
	var key := "bite:%d" % b.index
	var held: Dictionary = sim.status(t, key)
	var stacks: int = 1 + (int(held.stacks) if not held.is_empty() else 0)
	if stacks < int(b.def.bite_max):
		sim.add_status(b, t, key, "slow", b.def.bite_slow * stacks, b.def.bite_secs)
		t.statuses[key].stacks = stacks
		return
	sim.clear_status(t, key)
	sim.stun(b, t, b.def.bite_freeze)
	sim.pulse(b, t.pos, b.def.shard_radius, b.def.shard_damage, false, "shards")
	if b.def.bite_sour > 0.0:
		sim.add_status(b, t, "bite_sour:%d" % b.index, "vulnerable", b.def.bite_sour, b.def.bite_sour_secs)


## Its first contact hit on a foe it froze, while still frozen, deals
## shatter_mult x (0 = off), once per freeze.
func fx_shatter(sim, b, ctx: Dictionary) -> void:
	var t = ctx.target
	if b.def.shatter_mult <= 0.0 or not sim.stunned(t) or int(t.state.get("stun_source", -1)) != b.index:
		return
	if int(b.state.get("shattered", -1)) == t.stun_until:
		return
	b.state.shattered = t.stun_until
	ctx.mult *= b.def.shatter_mult
	sim.events.append({"type": "shatter", "ball": t.index, "pos": t.pos})


## Leaves a paint trail: blobs every paint_every seconds, paint_width wide,
## lasting paint_life. Foes on paint take paint_vuln more damage, and keep it
## for paint_linger seconds after leaving.
func fx_paint(sim, b, _ctx: Dictionary) -> void:
	var every := maxi(1, int(round(b.def.paint_every * sim.TICK_RATE)))
	if sim.tick % every == 0:
		sim.add_zone(b, b.pos, {"kind": "paint", "radius": b.def.paint_width, "life": b.def.paint_life,
			"vulnerable": b.def.paint_vuln, "vulnerable_linger": b.def.paint_linger})


## All its paint dries with a flash: paint_flash_damage to each foe on paint.
func fx_paint_flash(sim, b, _ctx: Dictionary) -> void:
	for o in sim.foes(b):
		for z in sim.zones:
			if z.owner == b.index and z.kind == "paint" and o.pos.distance_to(z.pos) <= z.radius + o.radius:
				sim.deal(b, o, b.def.paint_flash_damage, "paint", o.pos)
				sim.events.append({"type": "pulse", "ball": b.index, "pos": o.pos, "radius": o.radius * 1.4, "kind": "paint"})
				break


## A lighthouse beam straight ahead to the wall: lamp_dps a second for
## lamp_life, and a foe it touches takes lamp_vuln more damage for
## lamp_vuln_secs. lamp_sweep > 0 swings it that many degrees over its life
## (needs lamp_sweep on "always"); lamp_back 1 also shines one backwards.
func fx_lamp(sim, b, _ctx: Dictionary) -> void:
	if b.vel.length() < 0.001:
		return
	var dirs: Array[Vector2] = [b.vel.normalized()]
	if b.def.lamp_back > 0:
		dirs.append(-dirs[0])
	var sweeps: Array = b.state.get("lamps", [])
	for d in dirs:
		var from: Vector2 = b.pos + d * b.radius
		var beam = sim.add_beam(b, from, _to_wall(sim, from, d), {"life": b.def.lamp_life, "damage": b.def.lamp_dps * 0.25, "cooldown": 0.25,
			"on_hit": {"vulnerable": b.def.lamp_vuln, "vulnerable_secs": b.def.lamp_vuln_secs}})
		if b.def.lamp_sweep > 0.0:
			sweeps.append({"beam": beam, "dir": d})
	b.state.lamps = sweeps


## Swings live lamp beams through lamp_sweep degrees over their life.
func fx_lamp_sweep(sim, b, _ctx: Dictionary) -> void:
	var sweeps: Array = b.state.get("lamps", [])
	for s in sweeps.duplicate():
		var beam = s.beam
		if not sim.beams.has(beam):
			sweeps.erase(s)
			continue
		var d: Vector2 = s.dir.rotated(deg_to_rad(b.def.lamp_sweep) * beam.age / beam.life)
		beam.b = _to_wall(sim, beam.a, d)


## Where a ray from `from` along unit `dir` leaves the arena's square.
static func _to_wall(sim, from: Vector2, dir: Vector2) -> Vector2:
	var r: Rect2 = sim.arena_rect()
	var t := INF
	if dir.x > 0.0001:
		t = minf(t, (r.end.x - from.x) / dir.x)
	elif dir.x < -0.0001:
		t = minf(t, (r.position.x - from.x) / dir.x)
	if dir.y > 0.0001:
		t = minf(t, (r.end.y - from.y) / dir.y)
	elif dir.y < -0.0001:
		t = minf(t, (r.position.y - from.y) / dir.y)
	return from + dir * maxf(t, 0.0)


## Gift-wraps the nearest foe: stunned wrap_hold, then it takes wrap_vuln more
## damage for wrap_vuln_secs after the ribbon pops. On the pop (needs
## wrap_tick on "always"): wrap_confetti > 0 hits foes within 120 of it for
## that much; every wrap_pull_every-th wrap (when > 0) steers it toward
## Bonbon at wrap_pull for 0.5s.
func fx_wrap(sim, b, _ctx: Dictionary) -> void:
	var f = sim.nearest_foe(b)
	if f == null:
		return
	b.state.wraps = int(b.state.get("wraps", 0)) + 1
	var hold := int(round(minf(b.def.wrap_hold, sim.STUN_MAX) * sim.TICK_RATE))
	sim.stun(b, f, b.def.wrap_hold)
	sim.add_status(b, f, "wrap:%d" % b.index, "vulnerable", b.def.wrap_vuln, hold * sim.DT + b.def.wrap_vuln_secs)
	b.state.wrap = {"target": f.index, "pop": sim.tick + hold,
		"pull": b.def.wrap_pull_every > 0 and b.state.wraps % int(b.def.wrap_pull_every) == 0}
	sim.events.append({"type": "wrap", "ball": f.index, "from": b.pos, "pos": f.pos})


func fx_wrap_tick(sim, b, _ctx: Dictionary) -> void:
	var w: Dictionary = b.state.get("wrap", {})
	if w.is_empty():
		return
	var f = sim.balls[w.target]
	if sim.tick == w.pop:
		sim.events.append({"type": "pop", "ball": f.index, "pos": f.pos})
		if b.def.wrap_confetti > 0.0:
			sim.pulse(b, f.pos, 120.0, b.def.wrap_confetti, false, "confetti")
	if w.pull and sim.tick >= w.pop and sim.tick < w.pop + sim.TICK_RATE / 2 and f.alive():
		var delta: Vector2 = b.pos - f.pos
		if delta.length() > 0.001:
			sim.steer(f, delta.normalized() * b.def.wrap_pull)
	elif sim.tick >= w.pop + sim.TICK_RATE / 2:
		b.state.erase("wrap")


## Its hits shove the target straight away; if it slams the arena's edge (not
## a pillar or bumper) within slam_window seconds it takes slam_damage and
## freezes for slam_freeze.
## slam_patch > 0 leaves an icy patch that big on the wall (3s, slows
## slam_patch_slow). A slam freeze can shatter (fx_shatter).
func fx_shove(sim, b, ctx: Dictionary) -> void:
	var t = ctx.get("target")
	if t == null:
		return
	var d: Vector2 = t.pos - b.pos
	if d.length() > 0.001:
		t.vel = d.normalized() * t.current_speed()
	var slam := {"source": b.index, "damage": b.def.slam_damage, "until": sim.tick + int(round(b.def.slam_window * sim.TICK_RATE)), "stun": b.def.slam_freeze, "walls_only": true}
	if b.def.slam_patch > 0.0:
		slam.zone = {"kind": "ice", "radius": b.def.slam_patch, "life": 3.0, "slow": b.def.slam_patch_slow}
	t.state.slam = slam


## Each wall bounce charges a spark (at most spark_max), remembering where.
func fx_spark(_sim, b, ctx: Dictionary) -> void:
	if not ctx.has("point"):
		return
	var sparks: Array = b.state.get("sparks", [])
	sparks.append(ctx.point)
	if sparks.size() > int(b.def.spark_max):
		sparks.pop_front()
	b.state.sparks = sparks


## A hit spends the sparks as chain lightning: a beam from the target to each
## charged bounce point (storm_dps a second for 1s, burning storm_burn a
## second for 2s when > 0) and a storm_stun stun. At full sparks with
## thunder_damage > 0, a thunderclap hits foes within thunder_radius of it.
func fx_storm(sim, b, ctx: Dictionary) -> void:
	var t = ctx.get("target")
	var sparks: Array = b.state.get("sparks", [])
	if t == null or sparks.is_empty():
		return
	var on_hit := {"burn": b.def.storm_burn, "burn_secs": 2.0} if b.def.storm_burn > 0.0 else {}
	for p in sparks:
		sim.add_beam(b, t.pos, p, {"life": 1.0, "damage": b.def.storm_dps * 0.25, "cooldown": 0.25, "on_hit": on_hit})
	sim.stun(b, t, b.def.storm_stun)
	if sparks.size() >= int(b.def.spark_max) and b.def.thunder_damage > 0.0:
		sim.pulse(b, t.pos, b.def.thunder_radius, b.def.thunder_damage, false, "thunder")
	sim.events.append({"type": "storm", "ball": b.index, "pos": t.pos, "sparks": sparks.size()})
	b.state.sparks = []
## Grows one spike per contact hit landed, up to spike_max. State:
## b.state.spikes. Emits "spike" events.
func fx_grow_spike(sim, b, _ctx: Dictionary) -> void:
	var spikes: int = b.state.get("spikes", 0)
	if spikes < b.def.spike_max:
		b.state.spikes = spikes + 1
		sim.events.append({"type": "spike", "ball": b.index, "spikes": spikes + 1})


## Each grown spike adds spike_damage to the owner's contact hits.
func fx_spikes(_sim, b, ctx: Dictionary) -> void:
	var spikes: int = mini(b.state.get("spikes", 0), b.def.spike_max)
	if spikes > 0:
		ctx.mult *= (b.contact_damage + b.def.spike_damage * spikes) / b.contact_damage


## Speeds up by speed_gain on every wall bounce, up to max_speed_mult of base.
func fx_accelerate(_sim, b, _ctx: Dictionary) -> void:
	b.speed = minf(b.def.speed * b.def.max_speed_mult, b.speed * (1.0 + b.def.speed_gain))
	b.vel = b.vel.normalized() * b.speed


## Contact hits scale with speed above base (see fx_accelerate).
func fx_momentum(_sim, b, ctx: Dictionary) -> void:
	ctx.mult *= b.speed / b.def.speed


## A contact hit taken knocks the ball back to its base speed.
func fx_brake(_sim, b, ctx: Dictionary) -> void:
	if ctx.get("kind") == "contact" and b.speed > b.def.speed:
		b.speed = b.def.speed
		b.vel = b.vel.normalized() * b.speed


## A contact hit landed arms a slam for slam_window seconds (see fx_slam).
func fx_mark_slam(sim, b, _ctx: Dictionary) -> void:
	b.state.slam_until = sim.tick + int(round(b.def.slam_window * sim.TICK_RATE))


## If the foe hits a wall while a slam is armed, it takes slam_damage.
func fx_slam(sim, b, ctx: Dictionary) -> void:
	if sim.tick <= b.state.get("slam_until", -1):
		b.state.slam_until = -1
		sim.add_hit(b, ctx.other, b.def.slam_damage, "slam", ctx.point)
