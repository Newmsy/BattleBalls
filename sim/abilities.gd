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
	"grow_spike": ["spike_max"],
	"spikes": ["spike_damage", "spike_max"],
	"accelerate": ["speed_gain", "max_speed_mult"],
	"momentum": [],
	"brake": [],
	"mark_slam": ["slam_window"],
	"slam": ["slam_damage"],
	"orb_flare": ["orb_flare_radius", "orb_flare_damage"],
	"candies": ["candy_max", "candy_orbit", "candy_size", "candy_damage", "candy_spin", "candy_cooldown", "candy_start"],
	"candy": ["candy_max", "candy_blast_radius", "candy_blast_damage"],
	"candy_loss": ["candy_loss_hit"],
	"wrecker": ["wreck_orbit", "wreck_size", "wreck_damage", "wreck_spin", "wreck_cooldown", "wreck_slam_damage", "wreck_chain_dps", "wreck_windup_every", "wreck_windup_reach"],
	"swarm": ["bee_count", "bee_orbit", "bee_size", "bee_damage", "bee_spin", "bee_cooldown", "bee_speed", "bee_turn", "bee_life", "bee_launch_damage", "bee_poison_dps"],
	"bee_launch": ["bee_respawn"],
	"swarm_all": ["bee_respawn"],
	"tentacles": ["tentacle_count", "tentacle_orbit", "tentacle_size", "tentacle_damage", "tentacle_spin", "tentacle_cooldown", "hug_range", "hug_accel"],
	"ink_slam": ["ink_radius", "ink_life", "ink_slow", "ink_dps", "ink_shove", "hug_every", "hug_secs"],
	"quasar": ["quasar_length", "quasar_spin", "quasar_dps", "quasar_flare_dps", "quasar_cross"],
	"quasar_flare": ["quasar_flare_secs", "quasar_reverse"],
	"yoyo": ["yoyo_string", "yoyo_dps", "yoyo_fling", "yoyo_strings"],
	"yoyo_bounce": ["yoyo_every", "yoyo_secs"],
	"tail": ["tail_count", "tail_size", "tail_damage", "tail_cooldown", "tail_slow"],
	"dive": ["dive_secs"],
	"dive_tick": ["dive_lock", "wave_radius", "wave_damage", "pool_radius", "pool_life", "pool_dps", "pool_slow"],
	"dive_guard": ["dive_guard"],
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
## sets it burning (that much a second for 2s). moon_look (optional) names how
## the renderer draws them (see _publish_orbs).
func fx_moons(sim, b, _ctx: Dictionary) -> void:
	var n := int(b.def.moon_count)
	var ring := _ring(sim, b, n, b.radius + b.def.moon_orbit, b.def.moon_spin)
	var items := []
	for k in n:
		for o in _orb_hit(sim, b, ring[k], b.def.moon_size, b.def.moon_damage, b.def.moon_cooldown, "moon%d" % k, "moon"):
			if b.def.moon_burn > 0.0:
				sim.add_burn(b, o, b.def.moon_burn, 2.0)
		items.append({"pos": ring[k], "size": b.def.moon_size, "look": b.def.get("moon_look", "moon")})
	_publish_orbs(sim, b, "moons", items)


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


# --- Orbiters and attachments (batch E) -------------------------------------
# Things that circle, swing from or trail a ball and hit foes they touch:
# Orbit's moons, the firefly's bugs, Jawbreaker's candies, Wrecker's ball, Swarm's
# bees, Kraken's tentacles, Leviathan's tail. Each effect publishes what it
# draws in b.state.orbs (see _publish_orbs), and beams that follow their owner
# (Wrecker's chain, Quasar's jets, Yo-Yo's string) go through _hold_beam.

## n points evenly spaced on a circle of radius `dist` round b, turning at
## `spin` radians a second (plus `offset`).
static func _ring(sim, b, n: int, dist: float, spin: float, offset := 0.0) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for k in n:
		var ang: float = sim.tick * sim.DT * spin + offset + k * TAU / maxi(1, n)
		out.append(b.pos + Vector2.from_angle(ang) * dist)
	return out


## An orbiter of radius `size` at `p` hits each foe it touches for `damage`,
## at most once per `cooldown` seconds per foe (`key` names the orbiter).
## Returns the foes it hit this tick.
func _orb_hit(sim, b, p: Vector2, size: float, damage: float, cooldown: float, key: String, kind: String) -> Array:
	var hit_at: Dictionary = b.state.get("orb_hits", {})
	b.state.orb_hits = hit_at
	var out := []
	for o in sim.foes(b):
		var k := "%s:%d" % [key, o.index]
		if p.distance_to(o.pos) <= o.radius + size and sim.tick >= int(hit_at.get(k, 0)):
			hit_at[k] = sim.tick + int(round(cooldown * sim.TICK_RATE))
			sim.deal(b, o, damage, kind, p)
			out.append(o)
	return out


## What the renderer draws for one orbiter set: b.state.orbs[name] holds the
## tick and a list of {pos, size, look, from (optional: a tether point)}. A set
## not refreshed this tick (a copy ended, a dive) stops being drawn.
static func _publish_orbs(sim, b, name: String, items: Array) -> void:
	var orbs: Dictionary = b.state.get("orbs", {})
	b.state.orbs = orbs
	orbs[name] = {"tick": sim.tick, "items": items}


## Every orbiter b drew this tick or last.
static func orb_items(sim, b) -> Array:
	var out := []
	var orbs: Dictionary = b.state.get("orbs", {})
	for name in orbs:
		if orbs[name].tick >= sim.tick - 1:
			out.append_array(orbs[name].items)
	return out


## A beam that follows its owner: made once, then moved and kept at full
## strength every tick it's held. One not held for 0.2s fades out on its own.
## It hits a foe on it for dps a second (dps / 4 every 0.25s).
func _hold_beam(sim, b, name: String, from: Vector2, to: Vector2, dps: float) -> void:
	var held: Dictionary = b.state.get("held_beams", {})
	b.state.held_beams = held
	var beam = held.get(name)
	if beam == null or not sim.beams.has(beam):
		sim.add_beam(b, from, to, {"life": 0.2, "damage": dps * 0.25, "cooldown": 0.25})
		beam = sim.beams.back()
		held[name] = beam
	beam.a = from
	beam.b = to
	beam.age = 0.0
	beam.damage = dps * 0.25


func _drop_beam(sim, b, name: String) -> void:
	var held: Dictionary = b.state.get("held_beams", {})
	if held.has(name):
		sim.beams.erase(held[name])
		held.erase(name)


## Every orbiter it has flares: a pulse of orb_flare_damage within
## orb_flare_radius of each one (the firefly's bugs).
func fx_orb_flare(sim, b, _ctx: Dictionary) -> void:
	for item in orb_items(sim, b):
		sim.pulse(b, item.pos, b.def.orb_flare_radius, b.def.orb_flare_damage, false, "bugflare")


## Jawbreaker's candies: b.state.candies of them (candy_start at first) circle
## it candy_orbit beyond its edge, each bonking foes for candy_damage.
func fx_candies(sim, b, _ctx: Dictionary) -> void:
	if not b.state.has("candies"):
		b.state.candies = int(b.def.candy_start)
	var n: int = b.state.candies
	var ring := _ring(sim, b, n, b.radius + b.def.candy_orbit, b.def.candy_spin)
	var items := []
	for k in n:
		_orb_hit(sim, b, ring[k], b.def.candy_size, b.def.candy_damage, b.def.candy_cooldown, "candy%d" % k, "candy")
		items.append({"pos": ring[k], "size": b.def.candy_size, "look": "candy", "hue": k})
	_publish_orbs(sim, b, "candies", items)


## A contact hit adds a candy, up to candy_max. With candy_blast_damage > 0, a
## hit with every candy out cracks them all instead: a sugar blast of that much
## within candy_blast_radius, and the count starts over.
func fx_candy(sim, b, _ctx: Dictionary) -> void:
	var n := int(b.state.get("candies", b.def.get("candy_start", 0)))
	if b.def.candy_blast_damage > 0.0 and n >= int(b.def.candy_max):
		b.state.candies = 0
		sim.pulse(b, b.pos, b.def.candy_blast_radius, b.def.candy_blast_damage, false, "candy")
		return
	b.state.candies = mini(n + 1, int(b.def.candy_max))


## A single hit of candy_loss_hit or more knocks a candy off.
func fx_candy_loss(sim, b, ctx: Dictionary) -> void:
	var n := int(b.state.get("candies", 0))
	if n > 0 and ctx.amount >= b.def.candy_loss_hit:
		b.state.candies = n - 1
		sim.events.append({"type": "orb_lost", "ball": b.index, "pos": b.pos})


## Wrecker's ball swings wreck_orbit beyond its edge at wreck_spin radians a
## second, hitting for wreck_damage and knocking the foe straight away; a foe
## that then hits a wall within 0.5s takes wreck_slam_damage. wreck_chain_dps
## > 0 makes the chain a beam. wreck_windup_every > 0: every that many seconds
## the next full lap swings at wreck_windup_reach from its centre and hits double.
func fx_wrecker(sim, b, _ctx: Dictionary) -> void:
	var reach: float = b.radius + b.def.wreck_orbit
	var damage: float = b.def.wreck_damage
	var size: float = b.def.wreck_size
	var big := false
	if b.def.wreck_windup_every > 0.0:
		var every := int(round(b.def.wreck_windup_every * sim.TICK_RATE))
		var lap := int(round(TAU / b.def.wreck_spin * sim.TICK_RATE))
		big = sim.tick >= every and sim.tick % every < lap
	if big:
		reach = b.def.wreck_windup_reach
		damage *= 2.0
		size *= 1.3
	b.state.windup = big
	var dir := Vector2.from_angle(sim.tick * sim.DT * b.def.wreck_spin)
	var p: Vector2 = b.pos + dir * reach
	for o in _orb_hit(sim, b, p, size, damage, b.def.wreck_cooldown, "wreck", "wreck"):
		var away: Vector2 = o.pos - p
		if away.length() > 0.001:
			o.vel = away.normalized() * o.speed
		o.state.slam = {"source": b.index, "damage": b.def.wreck_slam_damage, "until": sim.tick + sim.TICK_RATE / 2}
	var from: Vector2 = b.pos + dir * b.radius
	if b.def.wreck_chain_dps > 0.0:
		_hold_beam(sim, b, "chain", from, p - dir * size, b.def.wreck_chain_dps)
	_publish_orbs(sim, b, "wreck", [{"pos": p, "size": size, "look": "wreck", "from": from, "big": big}])


## Swarm's bees: bee_count circle it, each stinging for bee_damage. A launched
## bee leaves its slot (it hatches again after bee_respawn) and homes on the
## nearest foe at bee_speed, turning up to bee_turn radians a second, for
## bee_launch_damage (plus a bee_poison_dps burn for 2s when > 0). It fizzles
## after bee_life seconds. State: b.state.bee_ready (tick each slot is back),
## b.state.bees_out (flying bees).
func fx_swarm(sim, b, _ctx: Dictionary) -> void:
	var n := int(b.def.bee_count)
	var ready := _bee_slots(b)
	var ring := _ring(sim, b, n, b.radius + b.def.bee_orbit, b.def.bee_spin)
	var items := []
	for k in n:
		if sim.tick < ready[k]:
			continue
		_orb_hit(sim, b, ring[k], b.def.bee_size, b.def.bee_damage, b.def.bee_cooldown, "bee%d" % k, "bee")
		items.append({"pos": ring[k], "size": b.def.bee_size, "look": "bee"})
	var out: Array = b.state.get("bees_out", [])
	var rect: Rect2 = sim.arena_rect()
	for bee in out.duplicate():
		var f = sim.nearest_foe(b)
		if f != null:
			var want: float = bee.vel.angle_to(f.pos - bee.pos)
			var turn: float = b.def.bee_turn * sim.DT
			bee.vel = bee.vel.rotated(clampf(want, -turn, turn))
		bee.pos += bee.vel * sim.DT
		bee.age += sim.DT
		var gone: bool = bee.age >= b.def.bee_life or not rect.grow(40.0).has_point(bee.pos)
		for o in sim.foes(b):
			if not gone and bee.pos.distance_to(o.pos) <= o.radius + b.def.bee_size:
				sim.deal(b, o, b.def.bee_launch_damage, "bee", bee.pos)
				if b.def.bee_poison_dps > 0.0:
					sim.add_burn(b, o, b.def.bee_poison_dps, 2.0)
				gone = true
		if gone:
			out.erase(bee)
		else:
			items.append({"pos": bee.pos, "size": b.def.bee_size, "look": "bee", "flying": true})
	b.state.bees_out = out
	_publish_orbs(sim, b, "bees", items)


static func _bee_slots(b) -> Array:
	var ready: Array = b.state.get("bee_ready", [])
	while ready.size() < int(b.def.bee_count):
		ready.append(0)
	b.state.bee_ready = ready
	return ready


## Sends `count` circling bees at the nearest foe (see fx_swarm).
func _launch_bees(sim, b, count: int) -> void:
	var f = sim.nearest_foe(b)
	if f == null:
		return
	var n := int(b.def.bee_count)
	var ready := _bee_slots(b)
	var ring := _ring(sim, b, n, b.radius + b.def.bee_orbit, b.def.bee_spin)
	var out: Array = b.state.get("bees_out", [])
	for k in n:
		if count <= 0:
			break
		if sim.tick < ready[k]:
			continue
		ready[k] = sim.tick + int(round(b.def.bee_respawn * sim.TICK_RATE))
		var dir: Vector2 = (f.pos - ring[k]).normalized() if f.pos.distance_to(ring[k]) > 0.001 else Vector2.RIGHT
		out.append({"pos": ring[k], "vel": dir * b.def.bee_speed, "age": 0.0})
		count -= 1
	b.state.bees_out = out
	sim.events.append({"type": "launch", "ball": b.index, "pos": b.pos})


## One bee flies off at the foe.
func fx_bee_launch(sim, b, _ctx: Dictionary) -> void:
	_launch_bees(sim, b, 1)


## The whole swarm flies off at once (they hatch again after bee_respawn).
func fx_swarm_all(sim, b, _ctx: Dictionary) -> void:
	_launch_bees(sim, b, int(b.def.bee_count))


## Kraken's tentacles: tentacle_count tips sweep tentacle_orbit beyond its
## edge, each hitting for tentacle_damage. During a hug (see fx_ink_slam) they
## pull foes within hug_range toward it at hug_accel.
func fx_tentacles(sim, b, _ctx: Dictionary) -> void:
	var n := int(b.def.tentacle_count)
	var reach: float = b.radius + b.def.tentacle_orbit
	var ring := _ring(sim, b, n, reach, b.def.tentacle_spin, PI / 4.0)
	var items := []
	for k in n:
		_orb_hit(sim, b, ring[k], b.def.tentacle_size, b.def.tentacle_damage, b.def.tentacle_cooldown, "tentacle%d" % k, "tentacle")
		var dir: Vector2 = (ring[k] - b.pos) / reach
		items.append({"pos": ring[k], "size": b.def.tentacle_size, "look": "tentacle", "from": b.pos + dir * b.radius * 0.7})
	_publish_orbs(sim, b, "tentacles", items)
	if sim.tick < int(b.state.get("hug_until", -1)):
		for o in sim.foes(b):
			var delta: Vector2 = b.pos - o.pos
			var dist := delta.length()
			if dist > 0.001 and dist < b.def.hug_range:
				sim.steer(o, delta / dist * b.def.hug_accel)


## The tentacles slam down: an ink puddle at each tip (ink_radius, ink_life
## seconds, slowing by ink_slow and dealing ink_dps). ink_shove > 0 also
## knocks foes within 60 of a tip away. hug_every > 0: every that many slams,
## the tentacles hug for hug_secs (see fx_tentacles).
func fx_ink_slam(sim, b, _ctx: Dictionary) -> void:
	var orbs: Dictionary = b.state.get("orbs", {})
	if not orbs.has("tentacles"):
		return
	for item in orbs.tentacles.items:
		sim.add_zone(b, item.pos, {"kind": "inkpool", "radius": b.def.ink_radius, "life": b.def.ink_life,
			"slow": b.def.ink_slow, "dps": b.def.ink_dps})
		sim.pulse(b, item.pos, 60.0 if b.def.ink_shove > 0 else b.def.ink_radius, 0.0, b.def.ink_shove > 0, "inkslam")
	b.state.slams = int(b.state.get("slams", 0)) + 1
	if b.def.hug_every > 0 and b.state.slams % int(b.def.hug_every) == 0:
		b.state.hug_until = sim.tick + int(round(b.def.hug_secs * sim.TICK_RATE))
		sim.events.append({"type": "hug", "ball": b.index, "pos": b.pos})


## Quasar's jets: two opposite beams from its edge, quasar_length long, turning
## at quasar_spin radians a second and burning quasar_dps. While a flare is on
## (fx_quasar_flare) they reach the walls and burn quasar_flare_dps, and with
## quasar_cross > 0 two more beams make a cross.
func fx_quasar(sim, b, _ctx: Dictionary) -> void:
	var turn: float = b.state.get("quasar_dir", 1.0)
	b.state.quasar_angle = float(b.state.get("quasar_angle", 0.0)) + turn * b.def.quasar_spin * sim.DT
	var flaring: bool = sim.tick < int(b.state.get("flare_until", -1))
	var n := 4 if flaring and b.def.quasar_cross > 0 else 2
	var dps: float = b.def.quasar_flare_dps if flaring else b.def.quasar_dps
	for k in 4:
		var name := "jet%d" % k
		if k >= n:
			_drop_beam(sim, b, name)
			continue
		var dir := Vector2.from_angle(b.state.quasar_angle + k * TAU / n)
		var from: Vector2 = b.pos + dir * b.radius
		var length: float = _to_wall(sim, from, dir) if flaring else b.def.quasar_length
		_hold_beam(sim, b, name, from, from + dir * length, dps)


## Distance from p along dir to the arena's outer wall.
static func _to_wall(sim, p: Vector2, dir: Vector2) -> float:
	var r: Rect2 = sim.arena_rect()
	var t := INF
	if dir.x > 0.001:
		t = minf(t, (r.end.x - p.x) / dir.x)
	elif dir.x < -0.001:
		t = minf(t, (r.position.x - p.x) / dir.x)
	if dir.y > 0.001:
		t = minf(t, (r.end.y - p.y) / dir.y)
	elif dir.y < -0.001:
		t = minf(t, (r.position.y - p.y) / dir.y)
	return maxf(0.0, t)


## The jets flare for quasar_flare_secs; quasar_reverse > 0 flips their spin.
func fx_quasar_flare(sim, b, _ctx: Dictionary) -> void:
	b.state.flare_until = sim.tick + int(round(b.def.quasar_flare_secs * sim.TICK_RATE))
	if b.def.quasar_reverse > 0:
		b.state.quasar_dir = -float(b.state.get("quasar_dir", 1.0))
	sim.events.append({"type": "pulse", "ball": b.index, "pos": b.pos, "radius": b.radius * 1.6, "kind": "quasar"})


## Every yoyo_every-th wall bounce it pins its string at the bounce point and
## swings round it for yoyo_secs (fx_yoyo). Bounces mid-swing don't count.
func fx_yoyo_bounce(sim, b, ctx: Dictionary) -> void:
	if not ctx.has("point") or sim.tick < int(b.state.get("swing_until", -1)):
		return
	b.state.yoyo_bounces = int(b.state.get("yoyo_bounces", 0)) + 1
	if b.state.yoyo_bounces % int(b.def.yoyo_every) != 0:
		return
	var anchor: Vector2 = ctx.point
	var out: Vector2 = b.pos - anchor
	var normal: Vector2 = out.normalized() if out.length() > 0.001 else -b.vel.normalized()
	b.state.anchor = anchor
	b.state.anchor_normal = normal
	b.state.swing_turn = 1.0 if Vector2(-normal.y, normal.x).dot(b.vel) >= 0.0 else -1.0
	b.state.swing_until = sim.tick + int(round(b.def.yoyo_secs * sim.TICK_RATE))
	sim.events.append({"type": "yoyo", "ball": b.index, "pos": anchor})


## While swinging it circles the anchor at its usual speed, easing out to
## yoyo_string, and the taut string burns foes it sweeps for yoyo_dps.
## yoyo_strings 2 adds a mirrored second string. When the swing ends,
## yoyo_fling > 0 flings it at the nearest foe at that x speed for half a second.
func fx_yoyo(sim, b, _ctx: Dictionary) -> void:
	var until := int(b.state.get("swing_until", -1))
	if sim.tick >= until:
		_drop_beam(sim, b, "string0")
		_drop_beam(sim, b, "string1")
		if sim.tick == until and b.def.yoyo_fling > 0.0:
			var f = sim.nearest_foe(b)
			if f != null and f.pos.distance_to(b.pos) > 0.001:
				b.vel = (f.pos - b.pos).normalized() * b.speed * b.def.yoyo_fling
				b.boost_ticks = sim.TICK_RATE / 2
				sim.events.append({"type": "fling", "ball": b.index, "pos": b.pos})
		return
	var anchor: Vector2 = b.state.anchor
	var rel: Vector2 = b.pos - anchor
	var d := rel.length()
	var u: Vector2 = rel / d if d > 0.001 else b.state.anchor_normal
	var step: float = b.current_speed() * sim.DT
	var r := move_toward(d, b.def.yoyo_string, step * 0.6)
	var next: Vector2 = anchor + u.rotated(b.state.swing_turn * step / maxf(r, step)) * r
	b.vel = (next - b.pos).normalized() * b.current_speed()
	_hold_beam(sim, b, "string0", anchor, b.pos - u * b.radius, b.def.yoyo_dps)
	if int(b.def.yoyo_strings) >= 2:
		var mirror: Vector2 = anchor + rel.reflect(b.state.anchor_normal)
		var mu: Vector2 = (mirror - anchor).normalized()
		_hold_beam(sim, b, "string1", anchor, mirror - mu * b.radius, b.def.yoyo_dps)
		_publish_orbs(sim, b, "yoyo", [{"pos": mirror, "size": b.radius * 0.5, "look": "yoyo"}])


## Leviathan's tail: tail_count bright segments follow its path, each
## stinging foes it touches for tail_damage (and slowing them by tail_slow).
## Hidden, and harmless, while it dives.
func fx_tail(sim, b, _ctx: Dictionary) -> void:
	var path: Array = b.state.get("path", [])
	path.push_front(b.pos)
	var n := int(b.def.tail_count)
	var size: float = b.def.tail_size
	var step: float = maxf(1.0, b.speed * sim.DT)
	var need := int(ceil((b.radius + size * (2 * n + 1)) / step)) + 1
	while path.size() > need:
		path.pop_back()
	b.state.path = path
	var items := []
	if sim.tick < int(b.state.get("dive_until", -1)):
		_publish_orbs(sim, b, "tail", items)
		return
	for k in n:
		var at := int(round((b.radius + size * (2 * k + 1)) / step))
		if at >= path.size():
			break
		var p: Vector2 = path[at]
		_orb_hit(sim, b, p, size, b.def.tail_damage, b.def.tail_cooldown, "tail%d" % k, "tail")
		if b.def.tail_slow > 0.0:
			for o in sim.foes(b):
				if p.distance_to(o.pos) <= o.radius + size:
					o.slow = maxf(o.slow, b.def.tail_slow)
		items.append({"pos": p, "size": size * (1.0 - 0.12 * k), "look": "segment"})
	_publish_orbs(sim, b, "tail", items)


## It dives for dive_secs (taking dive_guard x damage, see fx_dive_guard).
func fx_dive(sim, b, _ctx: Dictionary) -> void:
	b.state.dive_until = sim.tick + int(round(b.def.dive_secs * sim.TICK_RATE))
	b.state.phase_until = b.state.dive_until
	var f = sim.nearest_foe(b)
	b.state.dive_target = f.pos if f != null else b.pos
	sim.events.append({"type": "dive", "ball": b.index, "pos": b.pos})


## While diving, the splash point follows the nearest foe until dive_lock
## seconds before it erupts. Then it bursts up there: a wave of wave_damage
## within wave_radius that knocks foes away, and with pool_dps > 0 a whirlpool
## (pool_radius, pool_life seconds, pool_slow).
func fx_dive_tick(sim, b, _ctx: Dictionary) -> void:
	var until := int(b.state.get("dive_until", -1))
	if sim.tick > until:
		return
	var f = sim.nearest_foe(b)
	if f != null and sim.tick < until - int(round(b.def.dive_lock * sim.TICK_RATE)):
		b.state.dive_target = f.pos
	if sim.tick < until:
		return
	var t: Vector2 = b.state.dive_target
	b.state.path = []
	sim.pulse(b, t, b.def.wave_radius, b.def.wave_damage, true, "wave")
	if b.def.pool_dps > 0.0:
		sim.add_zone(b, t, {"kind": "whirlpool", "radius": b.def.pool_radius, "life": b.def.pool_life,
			"slow": b.def.pool_slow, "dps": b.def.pool_dps})
	# It surfaces beside the splash, on the side toward the middle, clear of the foe it just threw.
	var side: Vector2 = sim.centre - t
	side = side.normalized() if side.length() > 0.001 else Vector2.UP
	var r: Rect2 = sim.arena_rect().grow(-b.radius)
	var at: Vector2 = t + side * (b.radius * 2.0 + 8.0)
	b.pos = Vector2(clampf(at.x, r.position.x, r.end.x), clampf(at.y, r.position.y, r.end.y))


## While diving it takes dive_guard x damage.
func fx_dive_guard(sim, b, ctx: Dictionary) -> void:
	if sim.tick < int(b.state.get("dive_until", -1)):
		ctx.mult *= b.def.dive_guard
