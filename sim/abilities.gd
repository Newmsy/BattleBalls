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
	"grow": ["grow_radius", "grow_speed", "grow_add", "grow_secs", "grow_stack", "grow_heal", "grow_pulse_radius", "grow_pulse_damage", "grow_bolts", "bolt_damage"],
	"grow_guard": ["grow_armor"],
	"grow_end": ["grow_end_bolts", "bolt_damage"],
	"chomp": ["chomp_every", "chomp_mult", "chomp_burn"],
	"chomp_heal": ["chomp_heal"],
	"twig": ["twig_grow", "twig_damage", "twig_max"],
	"twig_drop": ["twig_keep", "twig_burst", "twig_burst_radius"],
	"regrow": ["regrow_after", "regrow_hps", "regrow_spores"],
	"phase_fire": ["trail_every", "trail_width", "trail_life", "trail_dps"],
	"wind": ["wind_step", "wind_cap", "wind_secs", "wind_add"],
	"unwind": ["wind_crit"],
	"fizz": ["fizz_at", "fizz_speed", "fizz_secs", "fizz_damage", "fizz_puddle", "fizz_dash"],
	"fizz_hit": ["fizz_splash", "fizz_splash_radius"],
	"grow_spike": ["spike_max"],
	"spikes": ["spike_damage", "spike_max"],
	"accelerate": ["speed_gain", "max_speed_mult"],
	"momentum": [],
	"brake": [],
	"mark_slam": ["slam_window"],
	"slam": ["slam_damage"],
	"stack": ["stack_max", "stack_radius", "stack_add", "stack_heal"],
	"stack_guard": ["stack_max", "stack_armor", "stack_full_armor"],
	"stack_burp": ["stack_max", "burp_radius", "burp_damage", "burp_keep"],
	"stack_breath": ["stack_max", "stack_radius", "stack_add", "fire_count", "fire_cone", "fire_range", "fire_damage", "fire_burn", "fire_streak"],
	"stack_drop": ["drop_at", "splat_radius", "splat_slow", "splat_dps"],
	"stack_spray": ["stack_max", "spray_count", "bolt_damage"],
	"face": ["stack_max", "face_damage", "face_speed"],
	"face_guard": ["face_armor"],
	"face_shout": ["shout_radius", "shout_damage"],
	"kaleido": ["mode_count", "mode_secs", "mode_damage", "mode_shield", "mode_speed", "mode_pulse_radius", "mode_pulse_damage"],
	"eclipse": ["eclipse_secs", "flip_radius", "moon_shield", "total_secs", "total_damage"],
	"corona": ["sun_radius", "sun_dps", "moon_hps"],
	"bubble": ["bubble_every", "bubble_size", "bubble_secs"],
	"bubble_guard": ["bubble_min", "bubble_knock", "bubble_bolts", "bolt_damage"],
	"chill": [],
	"roar": ["roar_radius", "roar_damage", "roar_slow", "roar_secs", "roar_drifts"],
	"snow_mine": ["mine_arm", "mine_radius", "mine_damage", "mine_max", "mine_life", "mine_trigger", "frost_radius", "frost_secs", "frost_slow"],
	"frostbite": ["freeze_secs"],
	"nova": ["nova_every", "nova_radius", "nova_damage", "nova_burn", "nova_ring"],
	"nova_early": [],
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
	b.state.phase_from = sim.tick
	b.state.ambush_ready = true
	sim.events.append({"type": "phase", "ball": b.index, "pos": b.pos})


static func phased(sim, b) -> bool:
	return sim.tick < int(b.state.get("phase_until", -1))


## While phased it takes phase_guard x damage, from the tick after it faded:
## a fade set off by its own hit (Flicker) doesn't soften the foe's hit from
## the same bump, which would also favour one start corner.
func fx_phased(sim, b, ctx: Dictionary) -> void:
	if phased(sim, b) and sim.tick > int(b.state.get("phase_from", -1)):
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
		_end_copy(sim, b)
	var src = ctx.get("source")
	if src == null or src.team == b.team or ctx.kind == "reflect":
		return
	if sim.tick < int(b.state.get("copy_ready", 0)):
		return
	if b.state.has("copy_until"):
		_end_copy(sim, b)
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
		_end_copy(sim, b)


## Stat mods a borrowed effect set (a copied grow) end with the copy.
static func _end_copy(sim, b) -> void:
	for key in b.mods.keys():
		if b.mods[key].get("copied", false):
			sim.clear_mod(b, key)
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


# --- Self-buffs and stat shifts (grow and shrink) ------------------------------

## Heals `b` now (not while burning). Emits "heal".
static func _heal_now(sim, b, amount: float) -> void:
	if amount <= 0.0 or not b.dots.is_empty():
		return
	var gained := minf(amount, b.max_hp - b.hp)
	if gained > 0.0:
		b.hp += gained
		b.healed += gained
		sim.events.append({"type": "heal", "target": b.index, "amount": gained, "pos": b.pos})


## n short bolts fanned evenly around `b`, starting from its heading, each
## hitting a foe once for `damage` (crumbs, spines).
static func _spray(sim, b, n: int, damage: float) -> void:
	var start: float = b.vel.angle() if b.vel.length() > 0.001 else 0.0
	for k in n:
		var dir := Vector2.from_angle(start + k * TAU / n)
		sim.add_beam(b, b.pos + dir * b.radius, b.pos + dir * (b.radius + 200.0), {"life": 0.4, "damage": damage, "cooldown": 1.0})


## Grows or shrinks: radius x(1 + grow_radius), speed x(1 + grow_speed),
## grow_add more contact damage, for grow_secs (<= 0: rest of fight).
## grow_stack 1 adds a new step each time (Crumb's bites); 0 refreshes the one
## (Puff). A new step also heals grow_heal, pulses foes away within
## grow_pulse_radius (grow_pulse_damage each) and sprays grow_bolts bolts.
## State: b.state.grow_until (tick the last timed step ends).
func fx_grow(sim, b, _ctx: Dictionary) -> void:
	var stacking: bool = b.def.grow_stack > 0
	var key := "grow"
	if stacking:
		b.state.grow_steps = int(b.state.get("grow_steps", 0)) + 1
		key = "grow:%d" % b.state.grow_steps
	var fresh: bool = stacking or not sim.has_mod(b, key)
	sim.set_mod(b, key, {"radius": 1.0 + b.def.grow_radius, "speed": 1.0 + b.def.grow_speed, "add": b.def.grow_add}, b.def.grow_secs)
	if b.def.grow_secs > 0.0:
		b.state.grow_until = sim.tick + int(round(b.def.grow_secs * sim.TICK_RATE))
	if not fresh:
		return
	_heal_now(sim, b, b.def.grow_heal)
	if b.def.grow_pulse_radius > 0.0:
		sim.pulse(b, b.pos, b.def.grow_pulse_radius, b.def.grow_pulse_damage, true, "pulse")
	if b.def.grow_bolts > 0:
		_spray(sim, b, int(b.def.grow_bolts), b.def.bolt_damage)


## While any grow step is on, it takes (1 - grow_armor) x damage (Shelly's shell).
func fx_grow_guard(_sim, b, ctx: Dictionary) -> void:
	for key in b.mods:
		if String(key).begins_with("grow"):
			ctx.mult *= 1.0 - b.def.grow_armor
			return


## When a timed grow ends, sprays grow_end_bolts bolts (Puff deflating).
func fx_grow_end(sim, b, _ctx: Dictionary) -> void:
	if b.def.grow_end_bolts > 0 and sim.tick == int(b.state.get("grow_until", -1)):
		_spray(sim, b, int(b.def.grow_end_bolts), b.def.bolt_damage)


## Every chomp_every-th contact hit deals chomp_mult x and, when chomp_burn > 0,
## leaves the foe burning (that much a second for 3s). Emits "chomp".
func fx_chomp(sim, b, ctx: Dictionary) -> void:
	var n := int(b.state.get("chomps", 0)) + 1
	b.state.chomps = n
	b.state.chomping = n % int(b.def.chomp_every) == 0
	if not b.state.chomping:
		return
	ctx.mult *= b.def.chomp_mult
	sim.events.append({"type": "chomp", "ball": b.index, "pos": b.pos})
	if b.def.chomp_burn > 0.0:
		sim.add_burn(b, ctx.target, b.def.chomp_burn, 3.0)


## A big bite heals chomp_heal of the damage it dealt.
func fx_chomp_heal(_sim, b, ctx: Dictionary) -> void:
	if b.state.get("chomping", false) and b.def.chomp_heal > 0.0 and ctx.has("heals") and b.dots.is_empty():
		ctx.heals.append({"ball": b.index, "amount": ctx.amount * b.def.chomp_heal})


## True when a wall bounce at `point` was off the arena's edge (walls or cut
## corners), not a pillar or bumper. Bounce-counting critters only count those:
## Pillar Hall and Bumper Bash doubled their bounces (Fizz beat Mossy 80% there).
static func _outer_wall(sim, point: Vector2) -> bool:
	var r: Rect2 = sim.arena_rect()
	if not r.grow(-1.0).has_point(point):
		return true
	for wall in sim.corner_walls():
		if wall[0].dot(point - sim.centre) + wall[1] < 1.0:
			return true
	return false


## Each bounce off the arena's edge snags twigs: +twig_grow radius and
## +twig_damage contact damage per twig, up to twig_max. State: b.state.twigs.
func fx_twig(sim, b, ctx: Dictionary) -> void:
	if not _outer_wall(sim, ctx.point):
		return
	var n := mini(int(b.state.get("twigs", 0)) + 1, int(b.def.twig_max))
	if n == int(b.state.get("twigs", 0)):
		return
	b.state.twigs = n
	sim.set_mod(b, "twigs", {"radius": 1.0 + b.def.twig_grow * n, "add": b.def.twig_damage * n})


## A contact hit knocks the twigs loose, keeping twig_keep of them (beam and
## zone chip doesn't, or Spectra kept it bare: 78%). At full size with
## twig_burst > 0 they burst as a dust pulse (twig_burst damage within
## twig_burst_radius).
func fx_twig_drop(sim, b, ctx: Dictionary) -> void:
	var n := int(b.state.get("twigs", 0))
	if n == 0 or ctx.get("kind") != "contact":
		return
	if b.def.twig_burst > 0.0 and n >= int(b.def.twig_max):
		sim.pulse(b, b.pos, b.def.twig_burst_radius, b.def.twig_burst, true, "pulse")
	var left := int(floor(n * b.def.twig_keep))
	b.state.twigs = left
	if left == 0:
		sim.clear_mod(b, "twigs")
	else:
		sim.set_mod(b, "twigs", {"radius": 1.0 + b.def.twig_grow * left, "add": b.def.twig_damage * left})


## Regrows regrow_hps HP a second (in half-second steps) once it hasn't been
## bumped (a contact hit) for regrow_after seconds; burning still stops it, as
## burns stop every heal. Only contact resets it, so chip from beams and zones
## can't switch it off (BALANCE.md rule 3: Spectra won 74%). regrow_spores > 0
## also sheds a spore patch (that much damage a second) behind it while
## regrowing. Needs a "hurt" entry too, to note the last bump.
## State: b.state.regrowing.
func fx_regrow(sim, b, ctx: Dictionary) -> void:
	if ctx.has("amount"): # The hurt entry.
		if ctx.kind != "contact":
			return
		b.state.hurt_at = sim.tick
		b.state.regrowing = false
		return
	var calm: int = sim.tick - int(b.state.get("hurt_at", 0))
	b.state.regrowing = calm >= int(round(b.def.regrow_after * sim.TICK_RATE)) and b.dots.is_empty()
	if not b.state.regrowing or calm % (sim.TICK_RATE / 2) != 0:
		return
	_heal_now(sim, b, b.def.regrow_hps * 0.5)
	if b.def.regrow_spores > 0.0:
		sim.add_zone(b, b.pos, {"kind": "spore", "radius": 60.0, "life": 2.0, "dps": b.def.regrow_spores})


## A burning trail, only while phased (Flicker's T5).
func fx_phase_fire(sim, b, _ctx: Dictionary) -> void:
	if phased(sim, b):
		_drop_trail(sim, b, "fire")


## Every contact hit taken winds it up: +wind_step speed per hit, up to
## wind_cap, all lost after wind_secs without one. At full wind it hits for
## wind_add more. Beams, zones and burns don't wind it (Spectra's many small
## beam hits wound it fully every fight). State: b.state.wind (steps).
func fx_wind(sim, b, ctx: Dictionary) -> void:
	if ctx.kind != "contact" or ctx.source == b:
		return
	var cap := ceili(b.def.wind_cap / b.def.wind_step - 0.001)
	var n := 1 if not sim.has_mod(b, "wind") else mini(int(b.state.get("wind", 0)) + 1, cap)
	b.state.wind = n
	sim.set_mod(b, "wind", {"speed": 1.0 + minf(b.def.wind_step * n, b.def.wind_cap), "add": b.def.wind_add if n >= cap else 0.0}, b.def.wind_secs)


## At full wind, its next contact hit unwinds into a wind_crit x hit and resets.
func fx_unwind(sim, b, ctx: Dictionary) -> void:
	var cap := ceili(b.def.wind_cap / b.def.wind_step - 0.001)
	if b.def.wind_crit <= 0.0 or not sim.has_mod(b, "wind") or int(b.state.get("wind", 0)) < cap:
		return
	ctx.mult *= b.def.wind_crit
	b.state.wind = 0
	sim.clear_mod(b, "wind")
	sim.events.append({"type": "unwind", "ball": b.index, "pos": b.pos})


## Each bounce off the arena's edge adds pressure; at fizz_at it pops: +fizz_speed speed for
## fizz_secs and fizz_damage more on its next contact hit. fizz_puddle > 0
## leaves a slowing puddle (that share) behind; fizz_dash 1 turns it at the
## nearest foe. State: b.state.pressure. Emits "pop".
func fx_fizz(sim, b, ctx: Dictionary) -> void:
	if not _outer_wall(sim, ctx.point):
		return
	var n := int(b.state.get("pressure", 0)) + 1
	if n < int(b.def.fizz_at):
		b.state.pressure = n
		return
	b.state.pressure = 0
	sim.set_mod(b, "fizz_rush", {"speed": 1.0 + b.def.fizz_speed}, b.def.fizz_secs)
	sim.set_mod(b, "fizz_hit", {"add": b.def.fizz_damage})
	sim.events.append({"type": "pop", "ball": b.index, "pos": b.pos})
	if b.def.fizz_puddle > 0.0:
		sim.add_zone(b, b.pos, {"kind": "fizz", "radius": 70.0, "life": 2.0, "slow": b.def.fizz_puddle})
	if b.def.fizz_dash > 0:
		var f = sim.nearest_foe(b)
		if f != null and f.pos.distance_to(b.pos) > 0.001:
			b.vel = (f.pos - b.pos).normalized() * b.current_speed()


## The charged hit spends the pop's bonus (it already counts for this hit);
## fizz_splash > 0 also splashes foes within fizz_splash_radius.
func fx_fizz_hit(sim, b, ctx: Dictionary) -> void:
	if not sim.has_mod(b, "fizz_hit"):
		return
	sim.clear_mod(b, "fizz_hit")
	if b.def.fizz_splash > 0.0:
		sim.pulse(b, ctx.target.pos, b.def.fizz_splash_radius, b.def.fizz_splash, false, "pulse")


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


# --- Stacks and forms: stacking counters and mode switching -------------------

## Sets the ball's stack count (b.state.stacks, clamped to 0..stack_max) and
## the stat mod that goes with it: +stack_radius size and +stack_add contact
## damage per stack (Munch's bites, Sundae's scoops, Drako's stokes,
## Supernova's swell). A critter with face_* params (Totem) gets its faces'
## buffs instead. Emits "stack" with the count and whether it went up.
static func set_stacks(sim, b, n: int) -> void:
	var old := int(b.state.get("stacks", 0))
	n = clampi(n, 0, int(b.def.stack_max))
	b.state.stacks = n
	if n == old:
		return
	if n == 0:
		sim.clear_mod(b, "stack")
	elif b.def.has("face_damage"):
		sim.set_mod(b, "stack", {"add": b.def.face_damage, "speed": 1.0 + (b.def.face_speed if n >= 3 else 0.0)})
	else:
		sim.set_mod(b, "stack", {"radius": 1.0 + b.def.stack_radius * n, "add": b.def.stack_add * n})
	sim.events.append({"type": "stack", "ball": b.index, "pos": b.pos, "stacks": n, "up": n > old})


static func stacks(b) -> int:
	return int(b.state.get("stacks", 0))


## Adds a stack, up to stack_max, and heals stack_heal (a bite heals even when
## it's already full).
func fx_stack(sim, b, _ctx: Dictionary) -> void:
	_heal_now(sim, b, b.def.stack_heal)
	set_stacks(sim, b, stacks(b) + 1)


## stack_armor less damage per stack, plus stack_full_armor at stack_max.
func fx_stack_guard(_sim, b, ctx: Dictionary) -> void:
	var n := stacks(b)
	var armor: float = b.def.stack_armor * n
	if n >= int(b.def.stack_max):
		armor += b.def.stack_full_armor
	ctx.mult *= 1.0 - minf(armor, 0.6)


## At full stacks (when burp_radius > 0) it burps: burp_damage to foes within
## burp_radius, knocking them away, and drops back to burp_keep stacks.
func fx_stack_burp(sim, b, _ctx: Dictionary) -> void:
	if b.def.burp_radius <= 0.0 or stacks(b) < int(b.def.stack_max):
		return
	sim.events.append({"type": "burp", "ball": b.index, "pos": b.pos})
	sim.pulse(b, b.pos, b.def.burp_radius, b.def.burp_damage, true, "pulse")
	set_stacks(sim, b, int(b.def.burp_keep))


## Each contact hit stokes a stack (+stack_add contact damage) up to
## stack_max; with its throat full, the next hit breathes instead: fire_count
## short fire bolts fanned over fire_cone degrees at the nearest foe
## (fire_damage each, fire_range long), a burn on a foe inside the cone
## (fire_burn a second for 2s), and the stokes start again. fire_streak > 0
## leaves a burning streak along the cone's middle. Breathing on the hit after
## the throat fills (not the filling hit) gives a fading foe (Flicker) time to
## come back, and a full throat is the foe's cue to dodge.
func fx_stack_breath(sim, b, _ctx: Dictionary) -> void:
	if stacks(b) < int(b.def.stack_max):
		set_stacks(sim, b, stacks(b) + 1)
		return
	set_stacks(sim, b, 0)
	var f = sim.nearest_foe(b)
	if f == null:
		return
	var aim: Vector2 = f.pos - b.pos
	var dir: Vector2 = aim.normalized() if aim.length() > 0.001 else Vector2.RIGHT
	var n := int(b.def.fire_count)
	var cone: float = deg_to_rad(b.def.fire_cone)
	var reach: float = b.radius + b.def.fire_range
	sim.events.append({"type": "breath", "ball": b.index, "pos": b.pos, "dir": dir})
	# The fireballs land this tick (deal), so they hit before a fade the same
	# bump sets off; the beams only draw them.
	for k in n:
		var d := dir.rotated(cone * ((k / float(n - 1)) - 0.5) if n > 1 else 0.0)
		var from: Vector2 = b.pos + d * b.radius
		var to: Vector2 = b.pos + d * reach
		sim.add_beam(b, from, to, {"life": 0.3, "damage": 0.0, "cooldown": 1.0})
		for o in sim.foes(b):
			if Geometry2D.get_closest_point_to_segment(o.pos, from, to).distance_to(o.pos) <= o.radius + sim.BEAM_HALF_WIDTH:
				sim.deal(b, o, b.def.fire_damage, "fire", o.pos)
	for o in sim.foes(b):
		var off: Vector2 = o.pos - b.pos
		var half_width := asin(clampf(o.radius / maxf(off.length(), o.radius), 0.0, 1.0))
		if off.length() <= reach + o.radius and absf(dir.angle_to(off)) <= cone / 2.0 + half_width:
			sim.add_burn(b, o, b.def.fire_burn, 2.0)
	if b.def.fire_streak > 0.0:
		var steps := int(b.def.fire_range / 70.0)
		for k in steps:
			sim.add_zone(b, b.pos + dir * (b.radius + 40.0 + 70.0 * k), {"kind": "fire", "radius": 40.0, "life": 2.0, "dps": b.def.fire_streak})


## A foe's hit of drop_at or more knocks a stack off; splat_radius > 0 leaves
## a sticky puddle where it landed (splat_slow, splat_dps, 3s).
func fx_stack_drop(sim, b, ctx: Dictionary) -> void:
	if ctx.source == b or ctx.source.team == b.team or ctx.amount < b.def.drop_at or stacks(b) == 0:
		return
	set_stacks(sim, b, stacks(b) - 1)
	if b.def.splat_radius > 0.0:
		sim.add_zone(b, b.pos, {"kind": "splat", "radius": b.def.splat_radius, "life": 3.0, "slow": b.def.splat_slow, "dps": b.def.splat_dps})


## At full stacks, each contact hit sprays spray_count bolts (bolt_damage each).
func fx_stack_spray(sim, b, _ctx: Dictionary) -> void:
	if b.def.spray_count > 0 and stacks(b) >= int(b.def.stack_max):
		_spray(sim, b, int(b.def.spray_count), b.def.bolt_damage)


## Bumping a foe (or the start of the fight) adds a carved face, up to
## stack_max: the first hits face_damage harder, the second is face_armor
## tougher (fx_face_guard), the third rolls face_speed faster.
func fx_face(sim, b, ctx: Dictionary) -> void:
	if ctx.has("other") and ctx.other.team == b.team:
		return
	set_stacks(sim, b, stacks(b) + 1)


func fx_face_guard(_sim, b, ctx: Dictionary) -> void:
	if stacks(b) >= 2:
		ctx.mult *= 1.0 - b.def.face_armor


## With four faces the stack shouts: shout_damage to foes within shout_radius.
func fx_face_shout(sim, b, _ctx: Dictionary) -> void:
	if stacks(b) >= 4:
		sim.events.append({"type": "shout", "ball": b.index, "pos": b.pos})
		sim.pulse(b, b.pos, b.def.shout_radius, b.def.shout_damage, false, "pulse")


## Moves to the next of `count` modes (b.state.mode, from 0) and emits "mode".
static func next_mode(sim, b, count: int) -> int:
	var m := (int(b.state.get("mode", -1)) + 1) % count
	b.state.mode = m
	sim.events.append({"type": "mode", "ball": b.index, "pos": b.pos, "mode": m})
	return m


## Kaleido clicks to its next mode for mode_secs: 0 spikes (+mode_damage
## contact damage), 1 a mode_shield shield, 2 +mode_speed speed, and with
## mode_count 4 a prism mode with all three at half. mode_pulse_radius > 0
## flashes a small pulse each click.
func fx_kaleido(sim, b, _ctx: Dictionary) -> void:
	var m := next_mode(sim, b, int(b.def.mode_count))
	var k := 0.5 if m == 3 else 1.0
	b.shield = maxf(0.0, b.shield - float(b.state.get("mode_shield", 0.0)))
	b.state.mode_shield = 0.0
	var mod := {}
	if m == 0 or m == 3:
		mod.add = b.def.mode_damage * k
	if m == 2 or m == 3:
		mod.speed = 1.0 + b.def.mode_speed * k
	if mod.is_empty():
		sim.clear_mod(b, "mode")
	else:
		sim.set_mod(b, "mode", mod, b.def.mode_secs)
	if m == 1 or m == 3:
		b.state.mode_shield = b.def.mode_shield * k
		b.shield = maxf(b.shield, b.state.mode_shield)
	if b.def.mode_pulse_radius > 0.0:
		sim.pulse(b, b.pos, b.def.mode_pulse_radius, b.def.mode_pulse_damage, false, "pulse")


## Eclipse flips between Sun (mode 0, the start) and Moon (1), flashing a ring
## that knocks foes within flip_radius away. Moon arrives with a moon_shield
## shield; total_secs > 0 runs both for that long after each flip (Total
## Eclipse), and the flash then deals total_damage.
func fx_eclipse(sim, b, _ctx: Dictionary) -> void:
	if not b.state.has("mode"):
		b.state.mode = 0 # It starts in Sun, so the first flip is to Moon.
	var m := next_mode(sim, b, 2)
	var total: bool = b.def.total_secs > 0.0
	sim.pulse(b, b.pos, b.def.flip_radius, b.def.total_damage if total else 0.0, true, "flare")
	if m == 1 and b.def.moon_shield > 0.0:
		b.shield = maxf(b.shield, b.def.moon_shield)
	if total:
		b.state.total_until = sim.tick + int(round(b.def.total_secs * sim.TICK_RATE))


## Every half second: in Sun the corona sets foes within sun_radius of its
## edge burning (sun_dps a second, lasting 1s after they leave it, and a
## burning ball can't heal); in Moon it heals moon_hps a second.
func fx_corona(sim, b, _ctx: Dictionary) -> void:
	if sim.tick == 0 or sim.tick % (sim.TICK_RATE / 2) != 0:
		return
	var m := int(b.state.get("mode", 0))
	var both: bool = sim.tick < int(b.state.get("total_until", -1))
	if m == 0 or both:
		for o in sim.foes(b):
			if o.pos.distance_to(b.pos) <= b.radius + b.def.sun_radius + o.radius:
				sim.add_burn(b, o, b.def.sun_dps, 1.0)
	if m == 1 or both:
		_heal_now(sim, b, b.def.moon_hps * 0.5)


## Blows a bubble that soaks up to bubble_size of the next hit, then pops
## (fx_bubble_guard); it bursts on its own after bubble_secs.
func fx_bubble(sim, b, _ctx: Dictionary) -> void:
	b.state.bubble = b.def.bubble_size
	b.state.bubble_until = sim.tick + int(round(b.def.bubble_secs * sim.TICK_RATE))
	sim.events.append({"type": "bubble", "ball": b.index, "pos": b.pos})


## The first hit of bubble_min or more pops the bubble, soaking up to
## bubble_size; smaller pings land as normal and leave it. bubble_knock
## > 0 shoves the attacker away; bubble_bolts > 0 sprays little bubbles.
func fx_bubble_guard(sim, b, ctx: Dictionary) -> void:
	var size: float = b.state.get("bubble", 0.0)
	if size <= 0.0 or sim.tick >= int(b.state.get("bubble_until", -1)) or ctx.source.team == b.team:
		return
	if ctx.amount * ctx.mult < b.def.bubble_min:
		return # Pings (Spectra's beams, burns) land but don't pop it.
	b.state.bubble = 0.0
	var raw: float = ctx.amount * ctx.mult
	if raw > 0.0:
		ctx.mult *= maxf(0.0, raw - size) / raw
	sim.events.append({"type": "bubble_pop", "ball": b.index, "pos": b.pos})
	var src = ctx.source
	if b.def.bubble_knock > 0 and src.alive() and src.pos.distance_to(b.pos) > 0.001:
		src.vel = (src.pos - b.pos).normalized() * src.current_speed()
	if b.def.bubble_bolts > 0:
		_spray(sim, b, int(b.def.bubble_bolts), b.def.bolt_damage)


## Slows `o` by `amount` (1 = frozen) for `secs` (a chill that outlasts zones).
## The owner's "always" chill entry applies it each tick.
static func chill(sim, o, amount: float, secs: float) -> void:
	var until: int = sim.tick + int(round(secs * sim.TICK_RATE))
	var c: Dictionary = o.state.get("chill", {})
	if c.is_empty() or sim.tick >= int(c.until) or amount >= float(c.slow):
		o.state.chill = {"slow": amount, "until": until}


## Applies chills on its foes (before zones and movement each tick).
func fx_chill(sim, b, _ctx: Dictionary) -> void:
	for o in sim.foes(b):
		var c: Dictionary = o.state.get("chill", {})
		if not c.is_empty() and sim.tick < int(c.until):
			o.slow = maxf(o.slow, c.slow)


## Yeti's avalanche: roar_damage to foes within roar_radius, knocking them
## away and chilling them (roar_slow for roar_secs). roar_drifts > 0 leaves
## that many snowdrifts around it (radius 70, 4s, 30% slow).
func fx_roar(sim, b, _ctx: Dictionary) -> void:
	sim.events.append({"type": "roar", "ball": b.index, "pos": b.pos})
	sim.pulse(b, b.pos, b.def.roar_radius, b.def.roar_damage, true, "frost")
	for o in sim.foes(b):
		if o.pos.distance_to(b.pos) <= b.def.roar_radius + o.radius:
			chill(sim, o, b.def.roar_slow, b.def.roar_secs)
	for k in int(b.def.roar_drifts):
		var p: Vector2 = b.pos + Vector2.from_angle(k * TAU / b.def.roar_drifts) * (b.radius + 90.0)
		sim.add_zone(b, p, {"kind": "frost", "radius": 70.0, "life": 4.0, "slow": 0.3})


## Drops a snowflake mine where it is (see fx_mine): it arms after mine_arm,
## goes off when a foe comes within mine_trigger of it, and its blast leaves a
## frost patch (frost_radius, frost_secs, frost_slow).
func fx_snow_mine(sim, b, _ctx: Dictionary) -> void:
	var own: Array = sim.zones.filter(func(z): return z.owner == b.index and z.kind == "mine")
	if own.size() >= int(b.def.mine_max):
		sim.zones.erase(own[0])
	sim.add_zone(b, b.pos, {"kind": "mine", "radius": b.def.mine_trigger, "life": b.def.mine_life, "arm": b.def.mine_arm,
		"blast": b.def.mine_damage, "blast_radius": b.def.mine_radius,
		"after": {"kind": "snow", "radius": b.def.frost_radius, "life": b.def.frost_secs, "slow": b.def.frost_slow}})


## A foe standing in two of its frost patches at once freezes for freeze_secs
## (then can't freeze again for 3s). Needs a chill entry too.
func fx_frostbite(sim, b, _ctx: Dictionary) -> void:
	if b.def.freeze_secs <= 0.0:
		return
	for o in sim.foes(b):
		if sim.tick < int(o.state.get("freeze_ready", 0)):
			continue
		var n := 0
		for z in sim.zones:
			if z.owner == b.index and z.kind == "snow" and o.pos.distance_to(z.pos) <= z.radius + o.radius:
				n += 1
		if n >= 2:
			chill(sim, o, 1.0, b.def.freeze_secs)
			o.state.freeze_ready = sim.tick + int(round((b.def.freeze_secs + 3.0) * sim.TICK_RATE))
			sim.events.append({"type": "freeze", "ball": o.index, "pos": o.pos})


## Every nova_every seconds it goes nova: after a 1s flicker (b.state.nova_warn)
## it deals nova_damage to foes within nova_radius and burns them (nova_burn a
## second for 3s), then shrinks back to no stacks. nova_ring > 0 leaves a
## burning ring (radius 120, 3s, that much damage a second).
func fx_nova(sim, b, _ctx: Dictionary) -> void:
	var warn := int(sim.TICK_RATE)
	if not b.state.has("nova_at"):
		b.state.nova_at = int(round(b.def.nova_every * sim.TICK_RATE))
	var at: int = b.state.nova_at
	b.state.nova_warn = sim.tick >= at - warn
	if sim.tick < at:
		return
	sim.pulse(b, b.pos, b.def.nova_radius, b.def.nova_damage, false, "nova")
	for o in sim.foes(b):
		if o.pos.distance_to(b.pos) <= b.def.nova_radius + o.radius:
			sim.add_burn(b, o, b.def.nova_burn, 3.0)
	if b.def.nova_ring > 0.0:
		sim.add_zone(b, b.pos, {"kind": "ring", "radius": 120.0, "life": 3.0, "dps": b.def.nova_ring})
	set_stacks(sim, b, 0)
	b.state.nova_at = sim.tick + int(round(b.def.nova_every * sim.TICK_RATE))
	b.state.nova_warn = false


## Goes nova early: one second from now, unless it's due sooner.
func fx_nova_early(sim, b, _ctx: Dictionary) -> void:
	b.state.nova_at = mini(int(b.state.get("nova_at", 1 << 30)), sim.tick + sim.TICK_RATE)
