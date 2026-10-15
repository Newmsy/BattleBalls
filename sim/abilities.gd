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
	# Movement (batch F): teleport, charge, tether.
	"blink": ["blink_every", "blink_away", "blink_crackle", "blink_crackle_radius", "blink_zap"],
	"blink_bonus": ["blink_bonus"],
	"glitch": ["glitch_away", "bomb_arm", "bomb_radius", "bomb_damage", "bomb_max", "bomb_line", "glitch_pulse", "glitch_pulse_radius"],
	"yank": ["yank_impulse", "yank_big_every", "yank_big_slow"],
	"yank_bonus": ["yank_bonus"],
	"string": ["string_cooldown", "string_length", "string_secs", "string_slam"],
	"string_snap": ["string_stun", "string_shield"],
	"mark": ["mark_cooldown", "mark_min", "mark_secs", "pounce_delay"],
	"pounce": ["pounce_speed_mult", "pounce_secs"],
	"marked": ["marked_mult", "pounce_slow", "pounce_remark"],
	"ping": ["ping_gap", "ping_turn", "ping_dash_mult", "ping_dash_secs", "ping_radius", "ping_damage", "ping_slow", "ping_slow_secs"],
	"ping_crit": ["ping_hit_mult"],
	"dig": ["phase_secs"],
	"surface": ["dig_radius", "dig_damage", "dig_rush", "dig_clods", "clod_damage"],
	"lance": ["lance_speed_mult", "lance_secs", "lance_retry"],
	"lance_tick": ["lance_beam_life", "lance_beam_dps"],
	"lance_hit": ["lance_hit_mult", "lance_knock"],
	"shift": ["gear_step", "gear_max"],
	"downshift": ["gear_keep"],
	"gear_slam": ["gear_slam_mult", "gear_knock"],
	"gear_trail": ["trail_every", "trail_width", "trail_life", "trail_dps"],
	"light": ["bulb_max"],
	"cash_in": ["bulb_damage", "bulb_knock", "bulb_tilt"],
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


# --- Movement (batch F): teleport, charge and tether -----------------------------
# The primitives live in MatchSim: teleport()/teleport_spot(), charge()/
# end_charge(), tether(), plus slow_for() for timed slows.

## Flings `target` straight away from `from`, at `mult` x speed for `secs`.
static func _knock(sim, target, from: Vector2, mult: float, secs: float) -> void:
	var away: Vector2 = target.pos - from
	if away.length() > 0.001:
		sim.charge(target, away, mult, secs)


## Every blink_every-th contact hit it teleports to a seeded spot at least
## blink_away from the foe. blink_crackle > 0 pulses the spot it left;
## blink_zap > 0 leaves a beam (that much damage a second) from there to where
## it lands. Readies blink_bonus.
func fx_blink(sim, b, ctx: Dictionary) -> void:
	b.state.blink_hits = int(b.state.get("blink_hits", 0)) + 1
	if b.state.blink_hits % int(b.def.blink_every) != 0 or not ctx.has("target"):
		return
	var old: Vector2 = b.pos
	sim.teleport(b, sim.teleport_spot(b, ctx.target.pos, b.def.blink_away))
	b.state.landed = true
	if b.def.blink_crackle > 0.0:
		sim.pulse(b, old, b.def.blink_crackle_radius, b.def.blink_crackle, false, "zap")
	if b.def.blink_zap > 0.0:
		sim.add_beam(b, old, b.pos, {"life": 0.5, "damage": b.def.blink_zap * 0.25, "cooldown": 0.25})


## Its first contact hit after a teleport deals blink_bonus more.
func fx_blink_bonus(_sim, b, ctx: Dictionary) -> void:
	if b.state.get("landed", false) and b.def.blink_bonus > 0.0:
		b.state.landed = false
		ctx.mult *= 1.0 + b.def.blink_bonus / b.contact_damage


## Teleports to a seeded spot at least glitch_away from where it was and leaves
## a pixel bomb there (bomb_line bombs back along its path when > 1), keeping
## at most bomb_max. glitch_pulse > 0 pulses where it lands.
func fx_glitch(sim, b, _ctx: Dictionary) -> void:
	var old: Vector2 = b.pos
	var back: Vector2 = -b.vel.normalized() if b.vel.length() > 0.001 else Vector2.ZERO
	sim.teleport(b, sim.teleport_spot(b, old, b.def.glitch_away))
	var r: Rect2 = sim.arena_rect().grow(-20.0)
	for k in int(b.def.bomb_line):
		var own: Array = sim.zones.filter(func(z): return z.owner == b.index and z.kind == "pixel")
		if own.size() >= int(b.def.bomb_max):
			sim.zones.erase(own[0])
		var p: Vector2 = (old + back * 90.0 * k).clamp(r.position, r.end)
		sim.add_zone(b, p, {"kind": "pixel", "radius": 18.0, "life": 12.0, "arm": b.def.bomb_arm,
			"blast": b.def.bomb_damage, "blast_radius": b.def.bomb_radius})
	if b.def.glitch_pulse > 0.0:
		sim.pulse(b, b.pos, b.def.glitch_pulse_radius, b.def.glitch_pulse, false, "glitch")


## On a wall bounce it yanks the foe toward itself: a quarter second of
## yank_impulse (units/s), so 220 drags it 55 closer, never past touching.
## The foe keeps its heading, so it isn't thrown into Hook. Every yank_big_every-th
## bounce (when > 0) yanks twice as hard and slows by yank_big_slow for 1s.
## Marks the foe yanked for 1s (see fx_yank_bonus). Emits "yank".
func fx_yank(sim, b, _ctx: Dictionary) -> void:
	var f = sim.nearest_foe(b)
	if f == null or f.pos.distance_to(b.pos) < 0.001:
		return
	b.state.yanks = int(b.state.get("yanks", 0)) + 1
	var big: bool = b.def.yank_big_every > 0 and b.state.yanks % int(b.def.yank_big_every) == 0
	if not sim.ability_moves():
		return
	var gap: float = f.pos.distance_to(b.pos) - f.radius - b.radius
	var pull: float = minf(b.def.yank_impulse * (2.0 if big else 1.0) * 0.25, maxf(0.0, gap))
	f.pos += (b.pos - f.pos).normalized() * pull
	sim.keep_inside(f)
	if big:
		sim.slow_for(f, b.def.yank_big_slow, 1.0)
	f.state["yanked_by_%d" % b.index] = sim.tick + sim.TICK_RATE
	sim.events.append({"type": "yank", "ball": b.index, "target": f.index, "from": b.pos, "to": f.pos, "big": big})


## A foe it yanked in the last second takes yank_bonus more when they collide.
func fx_yank_bonus(sim, b, ctx: Dictionary) -> void:
	var key := "yanked_by_%d" % b.index
	if ctx.has("target") and sim.tick < int(ctx.target.state.get(key, -1)):
		ctx.target.state.erase(key)
		sim.deal(b, ctx.target, b.def.yank_bonus, "hook")


## A contact hit (at most every string_cooldown) ties the foe on a string
## string_length long for string_secs, dragging it along. string_slam > 0: the
## first wall the foe hits while tied deals that much.
func fx_string(sim, b, ctx: Dictionary) -> void:
	if not ctx.has("target") or sim.tick < int(b.state.get("string_ready", 0)):
		return
	var secs := int(round(b.def.string_secs * sim.TICK_RATE))
	b.state.string_ready = sim.tick + int(round(b.def.string_cooldown * sim.TICK_RATE))
	b.state.string_until = sim.tick + secs
	b.state.string_target = ctx.target.index
	sim.tether(b, ctx.target, b.def.string_length, b.def.string_secs)
	if b.def.string_slam > 0.0:
		ctx.target.state.slam = {"source": b.index, "damage": b.def.string_slam, "until": sim.tick + secs}


## When a string runs out, the foe spins out dizzy (slowed 90% for string_stun
## seconds) and it bows behind a string_shield shield.
func fx_string_snap(sim, b, _ctx: Dictionary) -> void:
	if not b.state.has("string_until") or sim.tick != int(b.state.string_until) + 1:
		return
	var t = sim.balls[int(b.state.string_target)]
	if t.alive():
		sim.slow_for(t, 0.9, b.def.string_stun)
		t.state.dizzy_until = sim.tick + int(round(b.def.string_stun * sim.TICK_RATE))
	b.shield = maxf(b.shield, b.def.string_shield)
	sim.events.append({"type": "bow", "ball": b.index, "pos": b.pos})


## When a foe hurts it for at least mark_min (at most every mark_cooldown) it
## marks that foe for mark_secs and pounces at it pounce_delay later (fx_pounce).
func fx_mark(sim, b, ctx: Dictionary) -> void:
	var src = ctx.get("source")
	if src == null or src.team == b.team or not src.alive() or ctx.amount < b.def.mark_min or sim.tick < int(b.state.get("mark_ready", 0)):
		return
	b.state.mark_ready = sim.tick + int(round(b.def.mark_cooldown * sim.TICK_RATE))
	b.state.remarked = false
	_mark(sim, b, src)


static func _mark(sim, b, target) -> void:
	var until: int = sim.tick + int(round(b.def.mark_secs * sim.TICK_RATE))
	b.state.mark = {"target": target.index, "until": until}
	b.state.pounce_at = sim.tick + int(round(b.def.pounce_delay * sim.TICK_RATE))
	target.state.marked_until = until
	sim.events.append({"type": "mark", "ball": b.index, "target": target.index, "pos": target.pos})


## The pounce: a charge at the marked foe (pounce_speed_mult x speed, pounce_secs).
func fx_pounce(sim, b, _ctx: Dictionary) -> void:
	if sim.tick != int(b.state.get("pounce_at", -1)) or not b.state.has("mark"):
		return
	var t = sim.balls[int(b.state.mark.target)]
	if t.alive() and sim.tick < int(b.state.mark.until):
		sim.charge(b, t.pos - b.pos, b.def.pounce_speed_mult, b.def.pounce_secs)


## Its contact hit on the marked foe deals marked_mult x and spends the mark.
## pounce_slow > 0 slows that foe for 1.5s; pounce_remark > 0 marks it again
## for one more pounce (once per mark from being hurt).
func fx_marked(sim, b, ctx: Dictionary) -> void:
	var m: Dictionary = b.state.get("mark", {})
	if m.is_empty() or m.target != ctx.target.index or sim.tick >= int(m.until):
		return
	b.state.erase("mark")
	ctx.target.state.erase("marked_until")
	ctx.mult *= b.def.marked_mult
	sim.end_charge(b)
	sim.events.append({"type": "pounce", "ball": b.index, "pos": ctx.target.pos})
	if b.def.pounce_slow > 0.0:
		sim.slow_for(ctx.target, b.def.pounce_slow, 1.5)
	if b.def.pounce_remark > 0 and not b.state.get("remarked", false):
		b.state.remarked = true
		_mark(sim, b, ctx.target)


## On a wall bounce (at most every ping_gap seconds) it swerves up to
## ping_turn degrees to cut the foe off (ping_dash_mult x speed for ping_dash_secs) and pings: a ring of ping_radius
## dealing ping_damage and slowing foes by ping_slow for ping_slow_secs.
func fx_ping(sim, b, _ctx: Dictionary) -> void:
	var f = sim.nearest_foe(b)
	if f == null or sim.tick < int(b.state.get("ping_next", 0)):
		return
	b.state.ping_next = sim.tick + int(round(b.def.ping_gap * sim.TICK_RATE))
	# It hears where the foe is going and turns up to ping_turn degrees to cut
	# it off: a swerve, not a straight chase down the foe's trail.
	var to: Vector2 = f.pos + f.vel * 0.5 - b.pos
	var turn: float = clampf(b.vel.angle_to(to), -deg_to_rad(b.def.ping_turn), deg_to_rad(b.def.ping_turn))
	sim.charge(b, b.vel.rotated(turn) if b.vel.length() > 0.001 else to, b.def.ping_dash_mult, b.def.ping_dash_secs)
	b.state.ping_until = sim.tick + int(round(b.def.ping_dash_secs * sim.TICK_RATE))
	sim.pulse(b, b.pos, b.def.ping_radius, b.def.ping_damage, false, "ping")
	for o in sim.foes(b):
		if o.pos.distance_to(b.pos) <= b.def.ping_radius + o.radius:
			sim.slow_for(o, b.def.ping_slow, b.def.ping_slow_secs)


## A contact hit while still swerving from a ping deals ping_hit_mult x.
func fx_ping_crit(sim, b, ctx: Dictionary) -> void:
	if sim.charging(b) and sim.tick < int(b.state.get("ping_until", -1)):
		b.state.ping_until = -1
		ctx.mult *= b.def.ping_hit_mult
		sim.events.append({"type": "ping_crit", "ball": b.index, "pos": ctx.target.pos})


## Burrows for phase_secs: phased (fx_phased guards it), then fx_surface.
func fx_dig(sim, b, _ctx: Dictionary) -> void:
	b.state.phase_until = sim.tick + int(round(b.def.phase_secs * sim.TICK_RATE))
	b.state.digging = true
	sim.events.append({"type": "dig", "ball": b.index, "pos": b.pos})


## As it surfaces: a shove (dig_damage within dig_radius, knocking foes away),
## dig_rush > 0 speeds it up that much for 1s, and dig_clods > 0 lobs that
## many dirt clods (clod_damage each) where the foe is heading.
func fx_surface(sim, b, _ctx: Dictionary) -> void:
	if not b.state.get("digging", false) or sim.tick < int(b.state.get("phase_until", -1)):
		return
	b.state.digging = false
	sim.pulse(b, b.pos, b.def.dig_radius, b.def.dig_damage, true, "dirt")
	if b.def.dig_rush > 0.0:
		sim.charge(b, b.vel, 1.0 + b.def.dig_rush, 1.0)
	var f = sim.nearest_foe(b)
	if f == null:
		return
	var aim: Vector2 = f.pos + f.vel * 0.4
	var side: Vector2 = (aim - b.pos).normalized().orthogonal() if aim.distance_to(b.pos) > 0.001 else Vector2.RIGHT
	for k in int(b.def.dig_clods):
		var p: Vector2 = aim + side * 45.0 * (k - (b.def.dig_clods - 1) / 2.0)
		sim.add_zone(b, p, {"kind": "clod", "radius": 26.0, "life": 0.7, "arm": 0.4, "blast": b.def.clod_damage, "blast_radius": 30.0})
		sim.events.append({"type": "clod", "ball": b.index, "from": b.pos, "to": p})


## Charges at the foe (lance_speed_mult x speed, lance_secs). fx_lance_tick lays the
## glittering beam along its path; fx_lance_hit makes the charge hit count.
func fx_lance(sim, b, _ctx: Dictionary) -> void:
	var f = sim.nearest_foe(b)
	if f == null:
		return
	_start_lance(sim, b, f, b.def.lance_retry > 0)


static func _start_lance(sim, b, f, retry: bool) -> void:
	sim.charge(b, f.pos - b.pos, b.def.lance_speed_mult, b.def.lance_secs)
	b.state.lance = {"from": b.pos, "bounce": b.last_bounce, "start": sim.tick, "hit": false, "retry": retry}


## When a charge ends: a beam along the path it took (lance_beam_dps a second,
## lance_beam_life), bent at the wall it bounced off. A charge that missed
## curves round for one more when lance_retry > 0.
func fx_lance_tick(sim, b, _ctx: Dictionary) -> void:
	var l: Dictionary = b.state.get("lance", {})
	if l.is_empty() or sim.tick <= int(l.start) or sim.charging(b):
		return
	b.state.erase("lance")
	var path: Array[Vector2] = [l.from]
	if b.last_bounce != l.bounce:
		path.append(b.last_bounce)
	path.append(b.pos)
	for k in path.size() - 1:
		if path[k].distance_to(path[k + 1]) >= sim.MIN_BEAM_LENGTH:
			sim.add_beam(b, path[k], path[k + 1], {"life": b.def.lance_beam_life, "damage": b.def.lance_beam_dps * 0.25, "cooldown": 0.25})
	var f = sim.nearest_foe(b)
	if not l.hit and l.retry and f != null:
		_start_lance(sim, b, f, false)


## A contact hit during its charge deals lance_hit_mult x and ends the charge;
## lance_knock > 0 sends the foe flying (that x speed for 0.4s).
func fx_lance_hit(sim, b, ctx: Dictionary) -> void:
	var l: Dictionary = b.state.get("lance", {})
	if l.is_empty() or l.hit or not sim.charging(b):
		return
	l.hit = true
	ctx.mult *= b.def.lance_hit_mult
	sim.end_charge(b)
	sim.events.append({"type": "lance", "ball": b.index, "pos": ctx.target.pos})
	if b.def.lance_knock > 0.0:
		_knock(sim, ctx.target, b.pos, b.def.lance_knock, 0.4)


static func _set_gear(sim, b, gear: int) -> void:
	b.state.gear = gear
	if sim.ability_moves():
		b.speed = b.def.speed * (1.0 + b.def.gear_step * gear)
	if b.vel.length() > 0.001:
		b.vel = b.vel.normalized() * b.current_speed()
	sim.events.append({"type": "gear", "ball": b.index, "gear": gear, "pos": b.pos})


## Shifts up a gear (gear_step more speed each), up to gear_max.
func fx_shift(sim, b, _ctx: Dictionary) -> void:
	var g := int(b.state.get("gear", 0))
	if g < int(b.def.gear_max):
		_set_gear(sim, b, g + 1)


## Every gear_drop-th contact hit on it knocks it down a gear (not out of top
## gear), unless gear_keep > 0.
func fx_downshift(sim, b, ctx: Dictionary) -> void:
	var g := int(b.state.get("gear", 0))
	if b.def.gear_keep > 0 or ctx.kind != "contact" or g <= 0 or g >= int(b.def.gear_max):
		return
	b.state.gear_jolts = int(b.state.get("gear_jolts", 0)) + 1
	if b.state.gear_jolts % int(b.def.get("gear_drop", 1)) == 0:
		_set_gear(sim, b, g - 1)


## In top gear its contact hit deals gear_slam_mult x, sends the foe flying
## (gear_knock x speed for 0.4s) and drops it back to first.
func fx_gear_slam(sim, b, ctx: Dictionary) -> void:
	if int(b.state.get("gear", 0)) < int(b.def.gear_max):
		return
	ctx.mult *= b.def.gear_slam_mult
	if b.def.gear_knock > 0.0:
		_knock(sim, ctx.target, b.pos, b.def.gear_knock, 0.4)
	sim.events.append({"type": "gear_slam", "ball": b.index, "pos": ctx.target.pos})
	_set_gear(sim, b, 0)


## A burning trail while in its fourth (turbo) gear.
func fx_gear_trail(sim, b, _ctx: Dictionary) -> void:
	if int(b.state.get("gear", 0)) >= 4:
		_drop_trail(sim, b, "fire")


## Each wall bounce lights a bulb, up to bulb_max.
func fx_light(sim, b, _ctx: Dictionary) -> void:
	b.state.lit = mini(int(b.def.bulb_max), int(b.state.get("lit", 0)) + 1)


## Its next contact hit cashes the bulbs in: bulb_damage more per bulb.
## bulb_knock > 0: cashing that many or more also knocks the foe back.
## bulb_tilt > 0: a full board deals that x on top (TILT!).
func fx_cash_in(sim, b, ctx: Dictionary) -> void:
	var lit := int(b.state.get("lit", 0))
	if lit <= 0:
		return
	b.state.lit = 0
	ctx.mult *= 1.0 + lit * b.def.bulb_damage / b.contact_damage
	var tilt: bool = b.def.bulb_tilt > 0.0 and lit >= int(b.def.bulb_max)
	if tilt:
		ctx.mult *= b.def.bulb_tilt
	if b.def.bulb_knock > 0 and lit >= int(b.def.bulb_knock):
		_knock(sim, ctx.target, b.pos, 1.3, 0.3)
	sim.events.append({"type": "tilt" if tilt else "ding", "ball": b.index, "lit": lit, "pos": ctx.target.pos})
