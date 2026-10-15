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
	"zap": ["zap_radius", "zap_damage", "zap_slow", "zap_slow_secs", "zap_big_every", "zap_big_radius", "zap_big_damage"],
	"boom": ["boom_radius", "boom_damage", "boom_slam", "boom_double_every"],
	"boom_echo": ["boom_radius", "boom_damage", "boom_slam"],
	"lava": ["lava_radius", "lava_life", "lava_dps", "lava_max"],
	"linger": ["linger_dps", "linger_slow", "linger_secs"],
	"home_guard": ["home_guard"],
	"stardust": ["trail_every", "trail_width", "trail_life", "trail_dps"],
	"star": ["star_damage"],
	"gale": ["wind_range", "wind_accel", "wind_huff"],
	"huff": ["wind_range", "huff_secs", "huff_damage", "huff_slow"],
	"patch": ["patch_radius", "patch_life", "patch_dps"],
	"patch_flare": ["patch_flare_radius", "patch_flare_damage"],
	"honey": ["honey_radius", "honey_life", "honey_slow", "honey_max", "honey_merge_radius"],
	"ink": ["ink_radius", "ink_life", "ink_slow", "ink_dps", "ink_cooldown", "ink_dash"],
	"stink": ["stink_radius", "stink_dps", "stink_slow", "stink_bloom_radius"],
	"bloom": ["stink_bloom_secs"],
	"rain": ["rain_radius", "rain_warn", "rain_life", "rain_dps", "rain_slow", "rain_storm_every"],
	"thunder": ["rain_storm_radius", "rain_storm_damage"],
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
	# Batch D statuses: stun (freeze), vulnerable and timed slows (MatchSim.stun, add_status).
	"gum": ["gum_slow", "gum_secs", "gum_burn", "gum_stacks", "gum_cap"],
	"sour": ["sour_amount", "sour_secs", "sour_max", "sour_puddle", "sour_puddle_slow"],
	"arc": ["zap_damage", "zap_stun", "zap_linger_dps", "zap_storm_every"],
	"arc_tick": [],
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
	"shoot": ["shot_damage", "shot_speed", "shot_count", "shot_aim"],
	"shut": ["shut_secs", "shut_armor"],
	"shut_guard": ["shut_armor"],
	"shut_open": ["shot_damage", "shot_speed", "shot_count", "shot_aim"],
	"salvo": ["salvo_hits", "salvo_shield", "salvo_shield_secs", "shot_damage", "shot_speed", "shot_count"],
	"salvo_tick": [],
	"mega": ["mega_secs"],
	"lob": ["lob_damage", "lob_radius", "lob_lead", "lob_flight", "lob_crater_dps", "lob_barrage_every"],
	"brew": ["brew_count", "brew_spread", "brew_radius", "brew_life", "brew_dps", "brew_slow", "brew_flight", "brew_big_every", "brew_big_radius"],
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


## When hurt by a foe (at most every copy_cooldown; not by auras), borrows that foe's ability
## for copy_secs: their effects and params join its own. copy_shield > 0 also
## gives a shield. The original definition is restored when the copy ends.
func fx_copy(sim, b, ctx: Dictionary) -> void:
	if b.state.has("copy_until") and sim.tick >= b.state.copy_until:
		_end_copy(sim, b)
	var src = ctx.get("source")
	# A never-ending aura (Whiff's stink) would keep it copying all fight.
	if src == null or src.team == b.team or ctx.kind in ["reflect", "stink"]:
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
		# A borrowed wind (Gust) would only blow foes out of reach of its reflect.
		if not e.do in ["copy", "revive", "reflect", "gale"]:
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
## (needs arc_tick on "always").
func fx_arc(sim, b, _ctx: Dictionary) -> void:
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
func fx_arc_tick(sim, b, _ctx: Dictionary) -> void:
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
		sim.events.append({"type": "wrap_pop", "ball": f.index, "pos": f.pos})
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
func fx_gale(sim, b, _ctx: Dictionary) -> void:
	var huffing: bool = sim.tick < int(b.state.get("huff_until", -1))
	sim.push_away(b, b.pos, b.def.wind_range, b.def.wind_huff if huffing else b.def.wind_accel)


## A strong gust for huff_secs (see fx_gale). huff_damage > 0 also pelts foes
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


# --- Projectiles (MatchSim.add_shot / add_lob) ----------------------------------

## Fires a volley of shot_count shots at shot_speed for shot_damage each.
## shot_aim: "heading" (the way it's moving), "foe" (at the nearest foe) or
## "ring" (evenly all round). Volleys fan shot_spread degrees apart (default
## 20); every shot_big_every-th volley (when > 0) is shot_big_count shots.
## Optional riders: shot_homing (radians a second), shot_bounces, shot_split
## (splits off a wall), shot_burn (per second, 2s), shot_knock, shot_slow (1s),
## shot_life, shot_radius, shot_kind (look), shot_burst_damage and
## shot_burst_radius (a pop when it fizzles), and fire_cooldown (seconds
## between volleys, e.g. on a hurt trigger) and shot_when_bumped (on a hurt
## trigger, only contact hits fire it).
func fx_shoot(sim, b, ctx: Dictionary) -> void:
	if b.def.get("shot_when_bumped", 0) > 0 and ctx.get("kind", "contact") != "contact":
		return
	if b.def.has("fire_cooldown"):
		if sim.tick < int(b.state.get("fire_ready", 0)):
			return
		b.state.fire_ready = sim.tick + int(round(b.def.fire_cooldown * sim.TICK_RATE))
	var n := int(b.def.shot_count)
	var big := int(b.def.get("shot_big_every", 0))
	b.state.volleys = int(b.state.get("volleys", 0)) + 1
	if big > 0 and b.state.volleys % big == 0:
		n = int(b.def.shot_big_count)
	_volley(sim, b, n, str(b.def.shot_aim))


func _volley(sim, b, n: int, aim: String) -> void:
	var dir: Vector2 = b.vel.normalized() if b.vel.length() > 0.001 else Vector2.RIGHT
	if aim == "foe":
		var f = sim.nearest_foe(b)
		if f == null:
			return
		if f.pos.distance_to(b.pos) > 0.001:
			dir = (f.pos - b.pos).normalized()
	var spread: float = deg_to_rad(b.def.get("shot_spread", 20.0))
	var radius: float = b.def.get("shot_radius", 10.0)
	var opts: Dictionary = {
		"kind": b.def.get("shot_kind", "pea"), "radius": radius, "damage": b.def.shot_damage,
		"life": b.def.get("shot_life", 3.0), "homing": b.def.get("shot_homing", 0.0),
		"bounces": int(b.def.get("shot_bounces", 0)), "split": int(b.def.get("shot_split", 0)),
		"burn": b.def.get("shot_burn", 0.0), "knock": b.def.get("shot_knock", 0) > 0,
		"slow": b.def.get("shot_slow", 0.0), "burst_damage": b.def.get("shot_burst_damage", 0.0),
		"burst_radius": b.def.get("shot_burst_radius", 0.0) if b.def.get("shot_burst_damage", 0.0) > 0.0 else 0.0,
	}
	for k in n:
		var d: Vector2 = dir.rotated(k * TAU / n) if aim == "ring" else dir.rotated(spread * (k - (n - 1) / 2.0))
		sim.add_shot(b, b.pos + d * (b.radius + radius + 2.0), d * b.def.shot_speed, opts)


## Snaps shut for shut_secs, taking shut_armor less damage (shut_guard), then
## pops open and fires its shot volley (shut_open, an "always" entry).
## State: b.state.shut_until.
func fx_shut(sim, b, _ctx: Dictionary) -> void:
	b.state.shut_until = sim.tick + int(round(b.def.shut_secs * sim.TICK_RATE))
	sim.events.append({"type": "shut", "ball": b.index, "pos": b.pos})


func fx_shut_guard(sim, b, ctx: Dictionary) -> void:
	if sim.tick < int(b.state.get("shut_until", -1)):
		ctx.mult *= 1.0 - b.def.shut_armor


func fx_shut_open(sim, b, _ctx: Dictionary) -> void:
	if sim.tick == int(b.state.get("shut_until", -1)):
		_volley(sim, b, int(b.def.shot_count), str(b.def.shot_aim))


## Every salvo_hits-th contact hit fires shot_count shots (aimed as
## shot_aim, usually homing) and raises a salvo_shield shield for
## salvo_shield_secs. During Mega Mode (fx_mega) each hit counts double.
func fx_salvo(sim, b, _ctx: Dictionary) -> void:
	var step: int = 2 if sim.tick < int(b.state.get("mega_until", -1)) else 1
	b.state.salvo = int(b.state.get("salvo", 0)) + step
	if b.state.salvo < int(b.def.salvo_hits):
		return
	b.state.salvo = 0
	_volley(sim, b, int(b.def.shot_count), str(b.def.get("shot_aim", "foe")))
	b.shield = maxf(b.shield, b.def.salvo_shield)
	b.state.salvo_shield_until = sim.tick + int(round(b.def.salvo_shield_secs * sim.TICK_RATE))
	sim.events.append({"type": "salvo", "ball": b.index, "pos": b.pos})


## Drops what's left of a salvo shield when its time is up (an "always" entry).
func fx_salvo_tick(sim, b, _ctx: Dictionary) -> void:
	if b.state.has("salvo_shield_until") and sim.tick >= b.state.salvo_shield_until:
		b.state.erase("salvo_shield_until")
		b.shield = 0.0


## Mega Mode: for mega_secs every contact hit counts double toward the salvo.
func fx_mega(sim, b, _ctx: Dictionary) -> void:
	b.state.mega_until = sim.tick + int(round(b.def.mega_secs * sim.TICK_RATE))
	sim.events.append({"type": "mega", "ball": b.index, "pos": b.pos})


## Lobs a shell at where the nearest foe will be in lob_lead seconds (if no
## other ball turns it: the maths banks off walls and pillars); after lob_flight it lands for lob_damage within
## lob_radius. lob_crater_dps > 0 leaves a burning crater (radius 70, 2s);
## every lob_barrage_every-th shot (when > 0) is 3 shells around the spot.
func fx_lob(sim, b, _ctx: Dictionary) -> void:
	var f = sim.nearest_foe(b)
	if f == null:
		return
	var spot: Vector2 = sim.predict(f, b.def.lob_lead)
	b.state.lobs = int(b.state.get("lobs", 0)) + 1
	var spots: Array = [spot]
	if b.def.lob_barrage_every > 0 and b.state.lobs % int(b.def.lob_barrage_every) == 0:
		var turn: float = sim.rng.next_float() * TAU
		spots = [spot]
		for k in 2:
			spots.append(spot + Vector2.from_angle(turn + k * PI) * b.def.lob_radius * 1.2)
	for p in spots:
		var opts: Dictionary = {"kind": "shell", "damage": b.def.lob_damage, "land_radius": b.def.lob_radius}
		if b.def.lob_crater_dps > 0.0:
			opts.zone = {"kind": "fire", "radius": 70.0, "life": 2.0, "dps": b.def.lob_crater_dps}
		sim.add_lob(b, p, b.def.lob_flight, opts)


## Lobs brew_count blobs to seeded spots within brew_spread of the nearest
## foe; each lands as a puddle (brew_radius, brew_life), alternating burning
## (brew_dps a second) and slowing (brew_slow). Every brew_big_every-th brew
## (when > 0) is one huge puddle (brew_big_radius) that does both.
func fx_brew(sim, b, _ctx: Dictionary) -> void:
	var f = sim.nearest_foe(b)
	if f == null:
		return
	b.state.brews = int(b.state.get("brews", 0)) + 1
	if b.def.brew_big_every > 0 and b.state.brews % int(b.def.brew_big_every) == 0:
		sim.add_lob(b, f.pos, b.def.brew_flight, {"kind": "blob", "zone": {"kind": "brew", "radius": b.def.brew_big_radius,
			"life": b.def.brew_life, "dps": b.def.brew_dps, "slow": b.def.brew_slow}})
		return
	for k in int(b.def.brew_count):
		var at: Vector2 = f.pos + Vector2.from_angle(sim.rng.next_float() * TAU) * b.def.brew_spread * sqrt(sim.rng.next_float())
		var burn: bool = (int(b.state.get("blobs", 0)) + k) % 2 == 0
		var zone: Dictionary = {"kind": "fire", "radius": b.def.brew_radius, "life": b.def.brew_life, "dps": b.def.brew_dps} if burn \
			else {"kind": "goo", "radius": b.def.brew_radius, "life": b.def.brew_life, "slow": b.def.brew_slow}
		sim.add_lob(b, at, b.def.brew_flight, {"kind": "blob", "zone": zone})
	b.state.blobs = int(b.state.get("blobs", 0)) + int(b.def.brew_count)
