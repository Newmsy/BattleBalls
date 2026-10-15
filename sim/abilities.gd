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
	# Batch H: arena pieces (MatchSim.add_piece) and the set-piece legendaries.
	"slows": [],
	"seed": ["seed_radius", "seed_life", "seed_grow", "seed_max", "seed_damage"],
	"seed_wilt": ["seed_shots", "seed_shot_damage"],
	"vine": ["vine_offset", "vine_radius", "vine_life", "vine_lash", "vine_slack", "vine_pairs"],
	"vine_tick": ["vine_damage", "vine_burst_radius", "vine_thorn_damage"],
	"ice_ring": ["ring_count", "ring_radius", "ring_pillar", "ring_life", "ring_big_every", "ring_big_count"],
	"ice_ring_tick": ["shard_damage", "shard_hits", "shard_slow", "ring_volley_gap"],
	"root": ["root_count", "root_radius", "root_life", "root_pin", "root_shove", "root_shove_damage"],
	"root_tick": ["root_regen"],
	"tick_ring": ["tick_radius", "tick_damage", "tick_slow", "tick_slow_secs"],
	"rewind_track": ["rewind_secs"],
	"rewind": ["rewind_secs", "rewind_share", "rewind_place", "rewind_stop"],
	"illusions": ["illusion_count", "illusion_life", "illusion_size"],
	"illusion_tick": ["illusion_damage", "illusion_radius", "illusion_burn_damage", "illusion_trail_damage", "illusion_swap"],
	"spin": ["spin_prizes", "spin_jackpot_every", "spin_delay", "prize_mult", "prize_mine_damage", "prize_mine_radius", "prize_shield"],
	"spin_tick": ["prize_mult", "prize_beam_damage", "prize_coin_count", "prize_coin_damage", "prize_coin_reach"],
	"disco": ["disco_rays", "disco_length", "disco_damage", "disco_slow", "disco_slow_secs", "disco_bounce"],
	"ripple": ["ripple_reach", "ripple_life", "ripple_damage", "ripple_slow", "ripple_corner"],
	"zz_arm": ["zz_segments"],
	"zz_beam": ["zz_life", "zz_damage", "zz_slow"],
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
		if not e.do in ["copy", "revive", "reflect", "rewind"]:
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


# --- Batch H: arena pieces and set pieces --------------------------------------

## A timed slow on `target` (0-1 share of its movement, 1.0 holds it still),
## the strongest one winning. Any critter that slows lists an "always" ->
## "slows" entry, which applies them each tick.
static func slow_for(sim, target, amount: float, secs: float) -> void:
	var until: int = sim.tick + int(round(secs * sim.TICK_RATE))
	var cur: Dictionary = target.state.get("timed_slow", {})
	if cur.is_empty() or sim.tick >= int(cur.until):
		target.state.timed_slow = {"amount": amount, "until": until}
	else:
		cur.amount = maxf(float(cur.amount), amount)
		cur.until = maxi(int(cur.until), until)


## Applies every ball's timed slows, and slows foes touching this ball's
## slowing segments (b.state.slow_segs: {a, b, amount, until}).
func fx_slows(sim, b, _ctx: Dictionary) -> void:
	for o in sim.balls:
		var t: Dictionary = o.state.get("timed_slow", {})
		if t.is_empty():
			continue
		if sim.tick < int(t.until):
			o.slow = maxf(o.slow, t.amount)
		else:
			o.state.erase("timed_slow")
	var segs: Array = b.state.get("slow_segs", [])
	if segs.is_empty():
		return
	for seg in segs.duplicate():
		if sim.tick >= int(seg.until):
			segs.erase(seg)
			continue
		for o in sim.foes(b):
			if Geometry2D.get_closest_point_to_segment(o.pos, seg.a, seg.b).distance_to(o.pos) <= o.radius + sim.BEAM_HALF_WIDTH:
				slow_for(sim, o, seg.amount, 1.0)
				o.slow = maxf(o.slow, seg.amount)


static func _add_slow_seg(sim, b, a: Vector2, c: Vector2, life: float, amount: float) -> void:
	if amount <= 0.0:
		return
	var segs: Array = b.state.get("slow_segs", [])
	segs.append({"a": a, "b": c, "amount": amount, "until": sim.tick + int(round(life * sim.TICK_RATE))})
	b.state.slow_segs = segs


## Instant shots along segments (shards, coins, light rays): each segment hits
## each foe it passes within reach of once, for `damage`, and slows it when
## `slow` > 0. Emits one "rays" event for the renderer.
## At most `max_hits` segments hit the same foe (0: no limit).
static func _shoot(sim, b, segments: Array, damage: float, kind: String, slow := 0.0, slow_secs := 1.0, max_hits := 0) -> void:
	var hits := {}
	for seg in segments:
		for o in sim.foes(b):
			if max_hits > 0 and int(hits.get(o.index, 0)) >= max_hits:
				continue
			var hit := Geometry2D.get_closest_point_to_segment(o.pos, seg[0], seg[1])
			if hit.distance_to(o.pos) <= o.radius + 8.0:
				hits[o.index] = int(hits.get(o.index, 0)) + 1
				sim.deal(b, o, damage, kind, hit)
				if slow > 0.0:
					slow_for(sim, o, slow, slow_secs)
	sim.events.append({"type": "rays", "ball": b.index, "kind": kind, "segments": segments})


## True when `point` is on a placed or arena obstacle rather than the arena's edge.
static func _off_obstacle(sim, point: Vector2) -> bool:
	for o in sim.obstacles():
		if absf(point.distance_to(o.pos) - o.radius) < 1.0:
			return true
	return false


## Sprout: a wall bounce (the arena's edge, not a pillar) plants a seed that
## grows into a pillar: seed_radius, seed_life seconds, solid after seed_grow.
## At most seed_max stand; the oldest goes first. seed_damage > 0 hurts foes
## that bounce off one.
func fx_seed(sim, b, ctx: Dictionary) -> void:
	if not ctx.has("point") or _off_obstacle(sim, ctx.point):
		return
	var own: Array = sim.pieces_of(b, "seed")
	if own.size() >= int(b.def.seed_max):
		sim.pieces.erase(own[0])
	sim.add_piece(b, ctx.point, {"kind": "seed", "radius": b.def.seed_radius, "life": b.def.seed_life,
		"grow": b.def.seed_grow, "damage": b.def.seed_damage})


## Sprout T5: a wilting seed pillar scatters seed_shots seeds at the nearest foe.
func fx_seed_wilt(sim, b, _ctx: Dictionary) -> void:
	var f = sim.nearest_foe(b)
	if f == null:
		return
	for p in sim.pieces_of(b, "seed"):
		if not p.ending(sim.DT):
			continue
		var segs := []
		var to: Vector2 = f.pos - p.pos
		for k in int(b.def.seed_shots):
			var dir := to.normalized().rotated(deg_to_rad(10.0 * (k - (b.def.seed_shots - 1) / 2.0)))
			segs.append([p.pos, p.pos + dir * maxf(to.length() * 1.2, 150.0)])
		_shoot(sim, b, segs, b.def.seed_shot_damage, "seed")


## Ivy: raises vine_pairs vine pillars vine_offset from the foe (a seeded side;
## two face each other) and lashes the foe to them for vine_lash seconds, with
## vine_slack of give beyond where it stood.
func fx_vine(sim, b, _ctx: Dictionary) -> void:
	var f = sim.nearest_foe(b)
	if f == null:
		return
	var ang: float = sim.rng.next_float() * TAU
	var anchors := []
	# A spot an arena obstacle crowds out tries the next quarter turn.
	for turn in 4:
		for k in int(b.def.vine_pairs):
			var p = sim.add_piece(b, f.pos + Vector2.from_angle(ang + turn * PI / 2.0 + k * PI) * b.def.vine_offset,
				{"kind": "vine", "radius": b.def.vine_radius, "life": b.def.vine_life, "grow": 0.2})
			if p != null:
				anchors.append({"piece": p, "length": maxf(p.pos.distance_to(f.pos), f.radius + p.radius) + b.def.vine_slack})
		if not anchors.is_empty():
			break
	if anchors.is_empty():
		return
	b.state.lash = {"target": f.index, "anchors": anchors, "until": sim.tick + int(round(b.def.vine_lash * sim.TICK_RATE))}
	sim.events.append({"type": "lash", "ball": b.index, "target": f.index})


## Holds the lashed foe within its vine's length (it swings round the pillar
## at full speed), then snaps round it: vine_damage within vine_burst_radius
## of the foe, plus a thorn patch at each pillar (vine_thorn_damage a second)
## when above 0.
func fx_vine_tick(sim, b, _ctx: Dictionary) -> void:
	var lash: Dictionary = b.state.get("lash", {})
	if lash.is_empty():
		return
	var f = sim.balls[lash.target]
	if sim.tick >= int(lash.until) or not f.alive():
		b.state.erase("lash")
		# The vine snaps round the foe it held, wherever it swung to.
		if f.alive():
			sim.pulse(b, f.pos, b.def.vine_burst_radius, b.def.vine_damage, false, "petal")
		for a in lash.anchors:
			if b.def.vine_thorn_damage > 0.0:
				sim.add_zone(b, a.piece.pos, {"kind": "thorn", "radius": 80.0, "life": 3.0, "dps": b.def.vine_thorn_damage})
		return
	for a in lash.anchors:
		var anchor: Vector2 = a.piece.pos
		var d: Vector2 = f.pos - anchor
		var dist := d.length()
		if dist <= a.length or dist < 0.001:
			continue
		var n := d / dist
		f.pos = anchor + n * a.length
		var out: float = f.vel.dot(n)
		if out > 0.0:
			var v: Vector2 = f.vel - n * out
			f.vel = (v if v.length() > 0.001 else n.orthogonal()).normalized() * f.current_speed()


## Glacia: ring_count ice pillars ring_radius around the foe (wider round a
## bigger ball, so the gaps stay as easy to slip through) for ring_life seconds; every ring_big_every-th ring (when above 0) has ring_big_count and
## fires two volleys. When the ring shatters, each pillar shoots a shard at the
## ring's centre (see fx_ice_ring_tick); at most shard_hits of a volley hit the
## same foe, so a ball that can't slip out (rooted, or huge) isn't shredded.
func fx_ice_ring(sim, b, _ctx: Dictionary) -> void:
	var f = sim.nearest_foe(b)
	if f == null:
		return
	b.state.rings = int(b.state.get("rings", 0)) + 1
	var big: bool = b.def.ring_big_every > 0 and b.state.rings % int(b.def.ring_big_every) == 0
	var n := int(b.def.ring_big_count if big else b.def.ring_count)
	var turn: float = sim.rng.next_float() * TAU
	var spots := []
	for k in n:
		var p = sim.add_piece(b, f.pos + Vector2.from_angle(turn + k * TAU / n) * b.def.ring_radius * f.radius / 64.0,
			{"kind": "ice", "radius": b.def.ring_pillar, "life": b.def.ring_life, "grow": 0.25})
		if p != null:
			spots.append(p.pos)
	if spots.is_empty():
		return
	var at: int = sim.tick + int(round(b.def.ring_life * sim.TICK_RATE))
	var volleys := [at]
	if big:
		volleys.append(at + int(round(b.def.ring_volley_gap * sim.TICK_RATE)))
	b.state.ring = {"centre": f.pos, "spots": spots, "volleys": volleys}


func fx_ice_ring_tick(sim, b, _ctx: Dictionary) -> void:
	var ring: Dictionary = b.state.get("ring", {})
	if ring.is_empty() or sim.tick < int(ring.volleys[0]):
		return
	ring.volleys.pop_front()
	var segs := []
	for spot in ring.spots:
		var c: Vector2 = ring.centre
		segs.append([spot, c + (c - spot) * 0.25])
	_shoot(sim, b, segs, b.def.shard_damage, "shard", b.def.shard_slow, 1.0, int(b.def.shard_hits))
	if ring.volleys.is_empty():
		b.state.erase("ring")


## Old Oak: takes root. root_count root pillars rise around it (root_life
## seconds) and it regrows root_regen HP a second until they wilt. For the
## first root_pin seconds it holds still; the gaps between roots then let it
## out. root_shove > 0 also blasts foes in that radius for root_shove_damage
## and knocks them away.
func fx_root(sim, b, _ctx: Dictionary) -> void:
	var n := int(b.def.root_count)
	for k in n:
		var dir := Vector2.from_angle(PI / 4.0 + k * TAU / n)
		sim.add_piece(b, b.pos + dir * (b.radius + b.def.root_radius + 55.0),
			{"kind": "root", "radius": b.def.root_radius, "life": b.def.root_life, "grow": 0.3})
	b.state.rooted_until = sim.tick + int(round(b.def.root_life * sim.TICK_RATE))
	b.state.pinned_until = sim.tick + int(round(b.def.root_pin * sim.TICK_RATE))
	b.state.regrow_next = sim.tick + sim.TICK_RATE / 2
	sim.events.append({"type": "root", "ball": b.index, "pos": b.pos})
	if b.def.root_shove > 0.0:
		sim.pulse(b, b.pos, b.def.root_shove, b.def.root_shove_damage, true, "root")


func fx_root_tick(sim, b, _ctx: Dictionary) -> void:
	if sim.tick >= int(b.state.get("rooted_until", -1)):
		return
	if sim.tick < int(b.state.pinned_until):
		b.slow = 1.0
	if sim.tick < int(b.state.regrow_next):
		return
	b.state.regrow_next = sim.tick + sim.TICK_RATE / 2
	var gained := minf(b.def.root_regen * 0.5, b.max_hp - b.hp)
	if gained > 0.0 and b.dots.is_empty(): # Burning balls can't heal.
		b.hp += gained
		b.healed += gained
		sim.events.append({"type": "heal", "target": b.index, "amount": gained, "pos": b.pos})


## Clockwork: ticks out a ring: tick_damage within tick_radius, slowing foes
## by tick_slow for tick_slow_secs.
func fx_tick_ring(sim, b, _ctx: Dictionary) -> void:
	sim.pulse(b, b.pos, b.def.tick_radius, b.def.tick_damage, false, "tick")
	for o in sim.foes(b):
		if o.pos.distance_to(b.pos) <= b.def.tick_radius + o.radius:
			slow_for(sim, o, b.def.tick_slow, b.def.tick_slow_secs)


## Remembers its HP and spot for the last rewind_secs seconds.
func fx_rewind_track(sim, b, _ctx: Dictionary) -> void:
	var hist: Array = b.state.get("history", [])
	hist.append([b.hp, b.pos])
	var keep := int(round(b.def.rewind_secs * sim.TICK_RATE)) + 1
	if hist.size() > keep:
		hist.pop_front()
	b.state.history = hist


## Winds its HP back toward what it had rewind_secs ago (rewind_share of the
## way; never lower than now).
## rewind_place 1 also puts it back where it was; rewind_stop > 0 freezes
## foes for that long.
func fx_rewind(sim, b, _ctx: Dictionary) -> void:
	var hist: Array = b.state.get("history", [])
	if hist.is_empty():
		return
	var then: Array = hist[0]
	var from: Vector2 = b.pos
	b.hp = maxf(b.hp, b.hp + (minf(then[0], b.max_hp) - b.hp) * b.def.rewind_share)
	if b.def.rewind_place > 0:
		b.pos = then[1]
	sim.events.append({"type": "rewind", "ball": b.index, "from": from, "pos": b.pos})
	if b.def.rewind_stop > 0.0:
		for o in sim.foes(b):
			slow_for(sim, o, 1.0, minf(b.def.rewind_stop, 0.6))


## Foxfire: illusion_count fox-fire illusions dart off at its speed in seeded
## directions for illusion_life seconds (illusion_size x its radius).
func fx_illusions(sim, b, _ctx: Dictionary) -> void:
	var n := int(b.def.illusion_count)
	var turn: float = sim.rng.next_float() * TAU
	for k in n:
		var dir := Vector2.from_angle(turn + k * TAU / n)
		sim.add_piece(b, b.pos + dir * b.radius * 0.5, {"kind": "illusion", "radius": b.radius * b.def.illusion_size,
			"life": b.def.illusion_life, "block": false, "vel": dir * b.speed})
	sim.events.append({"type": "illusions", "ball": b.index, "pos": b.pos})


## An illusion a foe touches bursts: illusion_damage within
## illusion_radius, burning them (illusion_burn_damage a second, 2s).
## illusion_trail_damage > 0 leaves flame patches behind illusions; illusion_swap 1
## blinks the real Foxfire to a bursting illusion's spot.
func fx_illusion_tick(sim, b, _ctx: Dictionary) -> void:
	for p in sim.pieces_of(b, "illusion"):
		var touched := false
		for o in sim.foes(b):
			if o.pos.distance_to(p.pos) <= o.radius + p.radius:
				touched = true
				break
		if not touched:
			if b.def.illusion_trail_damage > 0.0 and sim.tick % 12 == 0:
				sim.add_zone(b, p.pos, {"kind": "fire", "radius": 26.0, "life": 1.2, "dps": b.def.illusion_trail_damage})
			continue
		sim.pieces.erase(p)
		sim.pulse(b, p.pos, b.def.illusion_radius, b.def.illusion_damage, false, "fire")
		for o in sim.foes(b):
			if o.pos.distance_to(p.pos) <= b.def.illusion_radius + o.radius:
				sim.add_burn(b, o, b.def.illusion_burn_damage, 2.0)
		if b.def.illusion_swap > 0:
			var from: Vector2 = b.pos
			b.pos = p.pos
			sim.events.append({"type": "swap", "ball": b.index, "from": from, "pos": b.pos})


## Jackpot: spins its reels and, spin_delay seconds later, pays out one seeded
## prize of spin_prizes (mines round the foe, a laser cross through its spot,
## a ring of coins, a shield). Every spin_jackpot_every-th spin (when above 0)
## pays them all. The target spot is locked when the reels stop.
const PRIZES := ["mines", "cross", "coins", "shield"]

func fx_spin(sim, b, _ctx: Dictionary) -> void:
	var f = sim.nearest_foe(b)
	if f == null:
		return
	b.state.spins = int(b.state.get("spins", 0)) + 1
	var won := []
	if b.def.spin_jackpot_every > 0 and b.state.spins % int(b.def.spin_jackpot_every) == 0:
		won = PRIZES.slice(0, int(b.def.spin_prizes))
	else:
		won = [PRIZES[sim.rng.range_int(0, int(b.def.spin_prizes) - 1)]]
	var at: int = sim.tick + int(round(b.def.spin_delay * sim.TICK_RATE))
	var spot: Vector2 = f.pos
	var pending: Array = b.state.get("prizes", [])
	for prize in won:
		match prize:
			"mines": # Placed now, armed when the reels stop: they show where they'll land.
				var turn: float = sim.rng.next_float() * TAU
				for k in 3:
					sim.add_zone(b, sim.inside(spot + Vector2.from_angle(turn + k * TAU / 3.0) * 90.0, 30.0), {"kind": "mine", "radius": 16.0,
						"life": 4.0, "arm": b.def.spin_delay, "blast": b.def.prize_mine_damage * b.def.prize_mult, "blast_radius": b.def.prize_mine_radius})
			"shield":
				b.shield = maxf(b.shield, b.def.prize_shield)
			_:
				pending.append({"prize": prize, "at": at, "spot": spot})
	b.state.prizes = pending
	sim.events.append({"type": "spin", "ball": b.index, "pos": b.pos, "prizes": won, "spot": spot})


func fx_spin_tick(sim, b, _ctx: Dictionary) -> void:
	var pending: Array = b.state.get("prizes", [])
	while not pending.is_empty() and sim.tick >= int(pending[0].at):
		var p: Dictionary = pending.pop_front()
		match p.prize:
			"cross":
				var r: Rect2 = sim.arena_rect()
				var c: Vector2 = p.spot
				var dmg: float = b.def.prize_beam_damage * b.def.prize_mult * 0.5
				sim.add_beam(b, Vector2(r.position.x, c.y), Vector2(r.end.x, c.y), {"life": 1.0, "damage": dmg, "cooldown": 0.5})
				sim.add_beam(b, Vector2(c.x, r.position.y), Vector2(c.x, r.end.y), {"life": 1.0, "damage": dmg, "cooldown": 0.5})
			"coins":
				var segs := []
				var n := int(b.def.prize_coin_count)
				for k in n:
					var dir := Vector2.from_angle(k * TAU / n + PI / 8.0)
					segs.append([b.pos + dir * b.radius, b.pos + dir * (b.radius + b.def.prize_coin_reach)])
				_shoot(sim, b, segs, b.def.prize_coin_damage * b.def.prize_mult, "coin")


## Disco: flashes disco_rays light rays outward (disco_length long), each
## hitting a foe once for disco_damage and slowing it by disco_slow for
## disco_slow_secs. disco_bounce 1 bends each ray off the first wall it meets.
func fx_disco(sim, b, _ctx: Dictionary) -> void:
	var n := int(b.def.disco_rays)
	b.state.flashes = int(b.state.get("flashes", 0)) + 1
	var turn: float = b.state.flashes * deg_to_rad(17.0)
	var r: Rect2 = sim.arena_rect()
	var segs := []
	for k in n:
		var dir := Vector2.from_angle(turn + k * TAU / n)
		var from: Vector2 = b.pos + dir * b.radius
		var reach: float = b.def.disco_length
		var to: Vector2 = from + dir * reach
		if b.def.disco_bounce > 0 and not r.has_point(to):
			var t := _exit_t(r, from, dir)
			var wall: Vector2 = from + dir * t
			segs.append([from, wall])
			var bent := dir
			if wall.x <= r.position.x + 0.5 or wall.x >= r.end.x - 0.5:
				bent.x = -bent.x
			if wall.y <= r.position.y + 0.5 or wall.y >= r.end.y - 0.5:
				bent.y = -bent.y
			segs.append([wall, wall + bent * (reach - t)])
		else:
			segs.append([from, to])
	_shoot(sim, b, segs, b.def.disco_damage, "disco", b.def.disco_slow, b.def.disco_slow_secs)


## Distance along `dir` from `from` (inside `r`) to the rect's edge.
static func _exit_t(r: Rect2, from: Vector2, dir: Vector2) -> float:
	var t := INF
	if dir.x > 0.0001:
		t = minf(t, (r.end.x - from.x) / dir.x)
	elif dir.x < -0.0001:
		t = minf(t, (r.position.x - from.x) / dir.x)
	if dir.y > 0.0001:
		t = minf(t, (r.end.y - from.y) / dir.y)
	elif dir.y < -0.0001:
		t = minf(t, (r.position.y - from.y) / dir.y)
	return maxf(0.0, t)


## Ripple: a bounce off the arena's edge sends a damaging ripple along that
## wall, ripple_reach each way (ripple_damage a second for ripple_life). ripple_slow
## > 0 also slows; ripple_corner 1 turns a ripple that reaches a corner up the
## next wall with the reach it has left.
func fx_ripple(sim, b, ctx: Dictionary) -> void:
	if not ctx.has("point") or _off_obstacle(sim, ctx.point):
		return
	var r: Rect2 = sim.arena_rect()
	var p: Vector2 = ctx.point
	var normal: Vector2 = (b.pos - p).normalized()
	var along := normal.orthogonal()
	for side in [1.0, -1.0]:
		var dir: Vector2 = along * side
		var reach: float = b.def.ripple_reach
		var t := minf(reach, _exit_t(r, p, dir))
		var end: Vector2 = p + dir * t
		_ripple_seg(sim, b, p, end)
		if b.def.ripple_corner > 0 and t < reach - 1.0:
			# Up the next wall: away from the wall it came along.
			_ripple_seg(sim, b, end, end + normal * (reach - t))


func _ripple_seg(sim, b, a: Vector2, c: Vector2) -> void:
	if a.distance_to(c) < 1.0:
		return
	sim.add_beam(b, a, c, {"life": b.def.ripple_life, "damage": b.def.ripple_damage * 0.5, "cooldown": 0.5})
	_add_slow_seg(sim, b, a, c, b.def.ripple_life, b.def.ripple_slow)


## Zigzag: a contact hit charges its path: the stretch from the hit to its
## next wall bounce becomes a beam (fx_zz_beam), for zz_segments bounces.
func fx_zz_arm(sim, b, _ctx: Dictionary) -> void:
	b.state.zz = {"from": b.pos, "left": int(b.def.zz_segments)}


func fx_zz_beam(sim, b, ctx: Dictionary) -> void:
	var zz: Dictionary = b.state.get("zz", {})
	if zz.is_empty() or not ctx.has("point"):
		return
	var from: Vector2 = zz.from
	if from.distance_to(ctx.point) >= sim.MIN_BEAM_LENGTH:
		sim.add_beam(b, from, ctx.point, {"life": b.def.zz_life, "damage": b.def.zz_damage * 0.5, "cooldown": 0.5})
		_add_slow_seg(sim, b, from, ctx.point, b.def.zz_life, b.def.zz_slow)
	zz.left -= 1
	zz.from = ctx.point
	if zz.left <= 0:
		b.state.erase("zz")
