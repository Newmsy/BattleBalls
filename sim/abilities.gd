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
	"moons": ["moon_count", "moon_orbit", "moon_size", "moon_damage", "moon_spin", "moon_cooldown"],
	"flare": ["flare_radius", "flare_slam"],
	"copy": ["copy_secs", "copy_cooldown", "copy_shield", "copy_scale"],
	"revive": ["revive_hp", "revive_radius", "revive_damage", "revive_burn", "revive_shield", "revive_bolts"],
	"fire_trail": ["trail_every", "trail_width", "trail_life", "trail_dps"],
	"beam_at": ["prism_damage", "prism_life", "prism_fan", "prism_full_every"],
	"collapse": ["collapse_every", "collapse_secs", "collapse_range", "collapse_accel", "collapse_damage", "collapse_radius", "collapse_ring"],
	"collapse_guard": ["collapse_guard"],
	"copy_tick": [],
	"scorch": ["scorch_dps", "scorch_secs"],
	"zap": ["zap_radius", "zap_damage", "zap_slow", "zap_slow_secs", "zap_big_every", "zap_big_radius", "zap_big_damage"],
	"boom": ["boom_radius", "boom_damage", "boom_slam", "boom_double_every"],
	"boom_echo": ["boom_radius", "boom_damage", "boom_slam"],
	"lava": ["lava_radius", "lava_life", "lava_dps", "lava_max"],
	"linger": ["linger_dps", "linger_slow", "linger_secs"],
	"home_guard": ["home_guard"],
	"stardust": ["trail_every", "trail_width", "trail_life", "trail_dps"],
	"star": ["star_damage"],
	"wind": ["wind_range", "wind_accel", "wind_huff"],
	"huff": ["wind_range", "huff_secs", "huff_damage", "huff_slow"],
	"patch": ["patch_radius", "patch_life", "patch_dps"],
	"patch_flare": ["patch_flare_radius", "patch_flare_damage"],
	"honey": ["honey_radius", "honey_life", "honey_slow", "honey_max", "honey_merge_radius"],
	"ink": ["ink_radius", "ink_life", "ink_slow", "ink_dps", "ink_cooldown", "ink_dash"],
	"stink": ["stink_radius", "stink_dps", "stink_slow", "stink_bloom_radius"],
	"bloom": ["stink_bloom_secs"],
	"rain": ["rain_radius", "rain_warn", "rain_life", "rain_dps", "rain_slow", "rain_storm_every"],
	"thunder": ["rain_storm_radius", "rain_storm_damage"],
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
## only works while copying. reflect_burn > 0 also burns them for 2s.
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
			if not b.state.has("copy_until"):
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
## touches for moon_damage, at most once per moon_cooldown. Positions are in
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
	b.state.moons = moons


## Flings foes within flare_radius straight away; one that hits a wall within
## a second takes flare_slam.
func fx_flare(sim, b, _ctx: Dictionary) -> void:
	sim.pulse(b, b.pos, b.def.flare_radius, 0.0, true, "flare")
	for o in sim.foes(b):
		if o.pos.distance_to(b.pos) <= b.def.flare_radius + o.radius:
			o.state.slam = {"source": b.index, "damage": b.def.flare_slam, "until": sim.tick + sim.TICK_RATE}


## When hurt by a foe (at most every copy_cooldown; not by auras), borrows that foe's ability
## for copy_secs: their effects and params join its own. copy_shield > 0 also
## gives a shield. The original definition is restored when the copy ends.
func fx_copy(sim, b, ctx: Dictionary) -> void:
	if b.state.has("copy_until") and sim.tick >= b.state.copy_until:
		_end_copy(b)
	var src = ctx.get("source")
	# A never-ending aura (Whiff's stink) would keep it copying all fight.
	if src == null or src.team == b.team or ctx.kind in ["reflect", "stink"]:
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
			if key.ends_with("_damage") or key.ends_with("_dps"): # A copy hits softer.
				copied[key] = src.def[key] * base.copy_scale
	var effects: Array = base.effects.duplicate()
	for e in src.def.effects:
		# A borrowed wind (Gust) would only blow foes out of reach of its reflect.
		if not e.do in ["copy", "revive", "reflect", "wind"]:
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
## foe (prism_damage per hit, 4 hits a second). prism_fan beams spread 15
## degrees apart; every prism_full_every-th bounce (when > 0) fans 7.
func fx_beam_at(sim, b, ctx: Dictionary) -> void:
	var f = sim.nearest_foe(b)
	if f == null or not ctx.has("point"):
		return
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
## (that much damage a second, 3s). State: b.state.collapsing.
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
		if b.def.collapse_ring > 0.0:
			sim.add_zone(b, b.pos, {"kind": "ring", "radius": b.def.collapse_radius, "life": 3.0, "dps": b.def.collapse_ring})


## While collapsing it takes collapse_guard x damage.
func fx_collapse_guard(_sim, b, ctx: Dictionary) -> void:
	if b.state.get("collapsing", false):
		ctx.mult *= b.def.collapse_guard


# --- Batch B: zones, pulses and wind --------------------------------------------

## The owner's floor zones of `kind` (not clinging ones), oldest first.
static func _own_zones(sim, b, kind := "") -> Array:
	return sim.zones.filter(func(z): return z.owner == b.index and z.follow < 0 and z.blast <= 0.0 and (kind == "" or z.kind == kind))


## Drops the oldest of the owner's `kind` zones until a new one fits under `most`.
static func _cap_zones(sim, b, kind: String, most: int) -> void:
	var own := _own_zones(sim, b, kind)
	while most > 0 and own.size() >= most:
		sim.zones.erase(own.pop_front())


## Slows `target` by `slow` for `secs` wherever it goes: a tiny zone riding on
## it. Refreshing keeps one per owner, target and kind.
static func _cling(sim, b, target, slow: float, secs: float, kind := "chill") -> void:
	for z in sim.zones:
		if z.owner == b.index and z.follow == target.index and z.kind == kind:
			z.life = maxf(z.life, z.age + secs)
			z.slow = maxf(z.slow, slow)
			return
	sim.add_zone(b, target.pos, {"kind": kind, "radius": 1.0, "life": secs, "slow": slow, "follow": target.index})


static func _foes_within(sim, b, pos: Vector2, radius: float) -> Array:
	return sim.foes(b).filter(func(o): return o.pos.distance_to(pos) <= radius + o.radius)


## Static: every wall bounce zaps foes within zap_radius for zap_damage (no
## knockback). zap_slow > 0 chills them that much for zap_slow_secs. Every
## zap_big_every-th bounce (when > 0) is a big zap instead.
func fx_zap(sim, b, _ctx: Dictionary) -> void:
	b.state.zaps = int(b.state.get("zaps", 0)) + 1
	var big: bool = b.def.zap_big_every > 0 and b.state.zaps % int(b.def.zap_big_every) == 0
	var radius: float = b.def.zap_big_radius if big else b.def.zap_radius
	var hit := _foes_within(sim, b, b.pos, radius)
	sim.pulse(b, b.pos, radius, b.def.zap_big_damage if big else b.def.zap_damage, false, "bigzap" if big else "zap")
	if b.def.zap_slow > 0.0:
		for o in hit:
			_cling(sim, b, o, b.def.zap_slow, b.def.zap_slow_secs)


## Drum: every contact hit booms a shockwave (boom_radius, boom_damage) that
## knocks foes straight away. boom_slam > 0: a foe knocked into a wall within
## 0.5s takes that much more. Every boom_double_every-th hit (when > 0) booms
## again 0.3s later (boom_echo, an "always" entry).
func fx_boom(sim, b, _ctx: Dictionary) -> void:
	_boom(sim, b)
	b.state.booms = int(b.state.get("booms", 0)) + 1
	if b.def.boom_double_every > 0 and b.state.booms % int(b.def.boom_double_every) == 0:
		b.state.boom_echo = sim.tick + int(round(0.3 * sim.TICK_RATE))


func fx_boom_echo(sim, b, _ctx: Dictionary) -> void:
	if sim.tick == int(b.state.get("boom_echo", -1)):
		_boom(sim, b)


func _boom(sim, b) -> void:
	var hit := _foes_within(sim, b, b.pos, b.def.boom_radius)
	sim.pulse(b, b.pos, b.def.boom_radius, b.def.boom_damage, true, "drum")
	if b.def.boom_slam > 0.0:
		for o in hit:
			o.state.slam = {"source": b.index, "damage": b.def.boom_slam, "until": sim.tick + sim.TICK_RATE / 2}


## Magmo: every contact hit splashes a lava puddle at the impact point
## (lava_radius, lava_dps for lava_life). Keeps at most lava_max.
func fx_lava(sim, b, ctx: Dictionary) -> void:
	if not ctx.has("target"):
		return
	var to: Vector2 = ctx.target.pos - b.pos
	var point: Vector2 = b.pos + (to.normalized() * b.radius if to.length() > 0.001 else Vector2.ZERO)
	_cap_zones(sim, b, "lava", int(b.def.lava_max))
	sim.add_zone(b, point, {"kind": "lava", "radius": b.def.lava_radius, "life": b.def.lava_life, "dps": b.def.lava_dps})


## Its floor zones cling to foes standing in them: linger_dps > 0 keeps them
## burning (linger_dps for linger_secs after they leave), linger_slow > 0 keeps
## them slowed for linger_secs.
func fx_linger(sim, b, _ctx: Dictionary) -> void:
	var own := _own_zones(sim, b)
	if own.is_empty():
		return
	for o in sim.foes(b):
		for z in own:
			if z.armed() and o.pos.distance_to(z.pos) <= z.radius + o.radius:
				if b.def.linger_dps > 0.0:
					sim.add_burn(b, o, b.def.linger_dps, b.def.linger_secs)
				if b.def.linger_slow > 0.0:
					_cling(sim, b, o, b.def.linger_slow, b.def.linger_secs, "sticky")
				break


## Standing in one of its own floor zones it takes home_guard x damage.
func fx_home_guard(sim, b, ctx: Dictionary) -> void:
	for z in _own_zones(sim, b):
		if b.pos.distance_to(z.pos) <= z.radius + b.radius * 0.5:
			ctx.mult *= b.def.home_guard
			return


## Comet: a stinging stardust trail (trail_dps while foes are in it).
func fx_stardust(sim, b, _ctx: Dictionary) -> void:
	_drop_trail(sim, b, "stardust")


## Comet T5: its tail flicks a shooting star (a short beam) at the nearest foe.
func fx_star(sim, b, _ctx: Dictionary) -> void:
	var f = sim.nearest_foe(b)
	if f == null:
		return
	var tail: Vector2 = b.pos - b.vel.normalized() * b.radius
	var to: Vector2 = f.pos - tail
	if to.length() < 0.001:
		return
	sim.add_beam(b, tail, tail + to.normalized() * maxf(to.length() * 1.15, 200.0), {"life": 0.4, "damage": b.def.star_damage, "cooldown": 1.0})


## Gust: wind always pushes foes away (wind_accel next to it, fading to 0 at
## wind_range), at wind_huff while a huff lasts. State: b.state.huff_until.
func fx_wind(sim, b, _ctx: Dictionary) -> void:
	var huffing: bool = sim.tick < int(b.state.get("huff_until", -1))
	sim.push_away(b, b.pos, b.def.wind_range, b.def.wind_huff if huffing else b.def.wind_accel)


## A strong gust for huff_secs (see fx_wind). huff_damage > 0 also pelts foes
## in the wind with ice for that much and chills them huff_slow for 1.5s.
func fx_huff(sim, b, _ctx: Dictionary) -> void:
	b.state.huff_until = sim.tick + int(round(b.def.huff_secs * sim.TICK_RATE))
	var hit := _foes_within(sim, b, b.pos, b.def.wind_range)
	sim.pulse(b, b.pos, b.def.wind_range, b.def.huff_damage, false, "wind")
	if b.def.huff_slow > 0.0:
		for o in hit:
			_cling(sim, b, o, b.def.huff_slow, 1.5)


## Sooty: drops a hot ember patch where it is (patch_radius, patch_dps for patch_life).
func fx_patch(sim, b, _ctx: Dictionary) -> void:
	sim.add_zone(b, b.pos, {"kind": "ember", "radius": b.def.patch_radius, "life": b.def.patch_life, "dps": b.def.patch_dps})


## When hurt, each of its ember patches that hasn't yet flares once
## (patch_flare_damage within patch_flare_radius of the patch).
func fx_patch_flare(sim, b, _ctx: Dictionary) -> void:
	var flared: Array = b.state.get("flared", []).filter(func(z): return sim.zones.has(z))
	for z in _own_zones(sim, b, "ember"):
		if not flared.has(z):
			flared.append(z)
			sim.pulse(b, z.pos, b.def.patch_flare_radius, b.def.patch_flare_damage, false, "fire")
	b.state.flared = flared


## Honey: every wall bounce drips a puddle at the bounce point that slows foes
## honey_slow (honey_radius, honey_life), at most honey_max. With
## honey_merge_radius > 0 a drip touching a puddle merges with it into one pool
## of that radius, halfway between.
func fx_honey(sim, b, ctx: Dictionary) -> void:
	if not ctx.has("point"):
		return
	var pos: Vector2 = ctx.point
	var radius: float = b.def.honey_radius
	if b.def.honey_merge_radius > 0.0:
		for z in _own_zones(sim, b, "honey"):
			if z.pos.distance_to(pos) < z.radius + radius:
				sim.zones.erase(z)
				pos = (z.pos + pos) / 2.0
				radius = b.def.honey_merge_radius
				break
	_cap_zones(sim, b, "honey", int(b.def.honey_max))
	sim.add_zone(b, pos, {"kind": "honey", "radius": radius, "life": b.def.honey_life, "slow": b.def.honey_slow})


## Ink: when hurt (at most every ink_cooldown) it squirts an ink cloud where
## it is (ink_radius, ink_slow for ink_life, ink_dps). ink_dash > 0 also gives
## it a bumper-style speed burst for that many seconds.
func fx_ink(sim, b, ctx: Dictionary) -> void:
	if ctx.get("source") == null or ctx.source.team == b.team or sim.tick < int(b.state.get("ink_ready", 0)):
		return
	b.state.ink_ready = sim.tick + int(round(b.def.ink_cooldown * sim.TICK_RATE))
	sim.add_zone(b, b.pos, {"kind": "ink", "radius": b.def.ink_radius, "life": b.def.ink_life, "slow": b.def.ink_slow, "dps": b.def.ink_dps})
	sim.events.append({"type": "pulse", "ball": b.index, "pos": b.pos, "radius": b.def.ink_radius, "kind": "ink"})
	if b.def.ink_dash > 0.0:
		b.boost_ticks = int(round(b.def.ink_dash * sim.TICK_RATE))
		b.vel = b.vel.normalized() * b.current_speed()


## Whiff: a stink cloud riding on it (stink_radius, stink_dps, stink_slow);
## stink_bloom_radius while a bloom lasts (fx_bloom).
func fx_stink(sim, b, _ctx: Dictionary) -> void:
	var z = b.state.get("stink")
	if z == null or not sim.zones.has(z):
		z = sim.add_zone(b, b.pos, {"kind": "stink", "radius": b.def.stink_radius, "life": 0.2, "dps": b.def.stink_dps, "slow": b.def.stink_slow, "follow": b.index})
		b.state.stink = z
	z.life = z.age + 0.2 # Kept alive while the effect runs, so a copied cloud (Echo) fades when the copy ends.
	z.radius = b.def.stink_bloom_radius if sim.tick < int(b.state.get("bloom_until", -1)) else b.def.stink_radius


## The stink cloud blooms for stink_bloom_secs.
func fx_bloom(sim, b, _ctx: Dictionary) -> void:
	b.state.bloom_until = sim.tick + int(round(b.def.stink_bloom_secs * sim.TICK_RATE))
	sim.events.append({"type": "pulse", "ball": b.index, "pos": b.pos, "radius": b.def.stink_bloom_radius, "kind": "stink"})


## Drizzle: rain on the nearest foe's spot. After rain_warn seconds of warning
## it hurts (rain_dps) and slows (rain_slow) for rain_life. Every
## rain_storm_every-th shower (when > 0) a lightning strike lands at its centre
## as the rain starts (fx_thunder, an "always" entry).
func fx_rain(sim, b, _ctx: Dictionary) -> void:
	var f = sim.nearest_foe(b)
	if f == null:
		return
	b.state.showers = int(b.state.get("showers", 0)) + 1
	sim.add_zone(b, f.pos, {"kind": "rain", "radius": b.def.rain_radius, "arm": b.def.rain_warn,
		"life": b.def.rain_warn + b.def.rain_life, "dps": b.def.rain_dps, "slow": b.def.rain_slow})
	if b.def.rain_storm_every > 0 and b.state.showers % int(b.def.rain_storm_every) == 0:
		b.state.thunder_at = sim.tick + int(round(b.def.rain_warn * sim.TICK_RATE))
		b.state.thunder_pos = f.pos


func fx_thunder(sim, b, _ctx: Dictionary) -> void:
	if sim.tick == int(b.state.get("thunder_at", -1)):
		sim.pulse(b, b.state.thunder_pos, b.def.rain_storm_radius, b.def.rain_storm_damage, false, "bigzap")
