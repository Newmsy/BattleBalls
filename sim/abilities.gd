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
	"overheal": ["overheal_cap"],
	"relight": ["relight_damage", "relight_radius"],
	"afterimage": ["trail_every", "trail_width", "trail_life", "trail_dps"],
	"spike_burst": ["shot_damage", "shot_speed", "shot_count", "spike_burst_at"],
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
	"split": ["split_gens", "split_radius", "split_speed", "split_damage"],
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
	"honey": ["honey_radius", "honey_life", "honey_slow", "honey_max", "honey_merge_radius", "honey_dps"],
	"honey_trap": ["honey_stick", "honey_pull", "honey_sting_damage"],
	"honey_crush": ["honey_crush"],
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
	"fizz": ["fizz_at", "fizz_speed", "fizz_secs", "fizz_damage", "fizz_puddle", "fizz_dash", "fizz_blast", "fizz_blast_radius"],
	"fizz_hit": ["fizz_splash", "fizz_splash_radius"],
	# Batch D statuses: stun (freeze), vulnerable and timed slows (MatchSim.stun, add_status).
	"gum": ["gum_slow", "gum_secs", "gum_burn", "gum_stacks", "gum_cap"],
	"sour": ["sour_amount", "sour_secs", "sour_max", "sour_puddle", "sour_puddle_slow"],
	"arc": ["zap_damage", "zap_stun", "zap_linger_dps", "zap_storm_every"],
	"arc_tick": [],
	"frostbite": ["bite_slow", "bite_max", "bite_secs", "bite_freeze", "shard_damage", "shard_radius", "bite_sour", "bite_sour_secs"],
	"shatter": ["shatter_mult"],
	"frost_hunt": ["hunt_accel"],
	"paint": ["paint_every", "paint_width", "paint_life", "paint_vuln", "paint_linger"],
	"paint_flash": ["paint_flash_damage"],
	"lamp": ["lamp_life", "lamp_dps", "lamp_vuln", "lamp_vuln_secs", "lamp_sweep", "lamp_back"],
	"lamp_sweep": [],
	"wrap": ["wrap_hold", "wrap_vuln", "wrap_vuln_secs", "wrap_confetti", "wrap_pull_every", "wrap_pull"],
	"wrap_tick": [],
	"shove": ["slam_damage", "slam_window", "slam_freeze", "slam_patch", "slam_patch_slow"],
	"spark": ["spark_max"],
	"storm": ["storm_dps", "storm_stun", "storm_burn", "thunder_radius", "thunder_damage"],
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
	"spin_tick": ["prize_mult", "prize_beam_damage", "prize_coin_count", "prize_coin_damage", "prize_coin_reach", "prize_coin_hits"],
	"disco": ["disco_rays", "disco_length", "disco_damage", "disco_slow", "disco_slow_secs", "disco_bounce"],
	"ripple": ["ripple_reach", "ripple_life", "ripple_damage", "ripple_slow", "ripple_corner", "ripple_wave_radius", "ripple_wave_damage"],
	"zz_arm": ["zz_segments"],
	"zz_beam": ["zz_life", "zz_damage", "zz_slow"],
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
	"salvo": ["salvo_hits", "salvo_shield", "salvo_shield_secs", "salvo_delay", "shot_damage", "shot_speed", "shot_count"],
	"salvo_tick": [],
	"mega": ["mega_secs"],
	"lob": ["lob_damage", "lob_radius", "lob_lead", "lob_flight", "lob_crater_dps", "lob_barrage_every"],
	"brew": ["brew_count", "brew_spread", "brew_radius", "brew_life", "brew_dps", "brew_slow", "brew_flight", "brew_big_every", "brew_big_radius"],
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
	"roar": ["roar_radius", "roar_damage", "roar_slow", "roar_secs", "roar_drifts"],
	"snow_mine": ["mine_arm", "mine_radius", "mine_damage", "mine_max", "mine_life", "mine_trigger", "frost_radius", "frost_secs", "frost_slow"],
	"snow_freeze": ["freeze_secs"],
	"nova": ["nova_every", "nova_radius", "nova_damage", "nova_burn", "nova_ring"],
	"nova_early": [],
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
	# Movement (batch F): teleport, charge, tether.
	"blink": ["blink_every", "blink_away", "blink_crackle", "blink_crackle_radius", "blink_zap"],
	"blink_bonus": ["blink_bonus"],
	"glitch": ["glitch_away", "bomb_arm", "bomb_radius", "bomb_damage", "bomb_max", "bomb_line", "glitch_pulse", "glitch_pulse_radius"],
	"yank": ["yank_impulse", "yank_big_every", "yank_big_slow"],
	"yank_bonus": ["yank_bonus"],
	"string": ["string_cooldown", "string_length", "string_secs"],
	"string_fling": ["string_fling", "string_slam", "string_slam_stun"],
	"string_snap": ["string_stun", "string_shield"],
	"mark": ["mark_cooldown", "mark_min", "mark_secs", "pounce_delay"],
	"pounce": ["pounce_speed_mult", "pounce_secs"],
	"marked": ["marked_mult", "pounce_slow", "pounce_remark"],
	"ping": ["ping_gap", "ping_turn", "ping_dash_mult", "ping_dash_secs", "ping_radius", "ping_damage", "ping_slow", "ping_slow_secs", "ping_mark"],
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


## Vampire T5: healing past full HP becomes a shield, up to overheal_cap.
func fx_overheal(sim, b, ctx: Dictionary) -> void:
	if not ctx.has("heals") or not b.dots.is_empty():
		return
	var spare: float = b.hp + ctx.amount * b.def.heal_ratio - b.max_hp
	if spare > 0.0 and b.shield < b.def.overheal_cap:
		b.shield = minf(b.def.overheal_cap, b.shield + spare)
		sim.events.append({"type": "shield", "target": b.index, "amount": spare, "pos": b.pos})


## Speedster T5: above 1.3x its base speed it leaves a damaging afterimage.
func fx_afterimage(sim, b, _ctx: Dictionary) -> void:
	if b.speed > b.def.speed * 1.3:
		_drop_trail(sim, b, "afterimage")


## Spiker T5: a hit landed with spike_burst_at or more spikes fires a ring of shot_count spikes.
func fx_spike_burst(sim, b, _ctx: Dictionary) -> void:
	if int(b.state.get("spikes", 0)) >= int(b.def.spike_burst_at):
		_volley(sim, b, int(b.def.shot_count), "ring")
		sim.events.append({"type": "spike_burst", "ball": b.index, "pos": b.pos})


## A damaging segment from the previous wall bounce point to this one.
func fx_beam(sim, b, ctx: Dictionary) -> void:
	if not ctx.has("point") or not b.has_bounce or b.last_bounce.distance_to(ctx.point) < sim.MIN_BEAM_LENGTH:
		return
	sim.add_beam(b, b.last_bounce, ctx.point)
	# Laser T5: also links the bounce before last to this one (a triangle).
	if b.def.get("beam_link", 0) > 0 and b.state.has("bounce_before") and b.state.bounce_before.distance_to(ctx.point) >= sim.MIN_BEAM_LENGTH:
		sim.add_beam(b, b.state.bounce_before, ctx.point)
	b.state.bounce_before = b.last_bounce


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
		if b.def.get("flip_pulse", 0.0) > 0.0: # Magnet T5: every flip fires a pulse ring.
			sim.pulse(b, b.pos, b.def.flip_pulse_radius, b.def.flip_pulse, true, "pulse")
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
		sim.pull(other, pull)
		sim.pull(b, -pull)


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


## Flicker: the candle goes out after a hit (fx_phase) and relights with a
## burst of flame (relight_damage within relight_radius) when the fade ends.
func fx_relight(sim, b, _ctx: Dictionary) -> void:
	if sim.tick == int(b.state.get("phase_until", -1)) and b.def.relight_damage > 0.0:
		sim.pulse(b, b.pos, b.def.relight_radius, b.def.relight_damage, false, "flame")
		sim.events.append({"type": "relight", "ball": b.index, "pos": b.pos})


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
		sim.pull(o, delta / dist * b.def.pull_accel * k)


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
		if not e.do in ["copy", "revive", "reflect", "gale", "rewind", "split"]:
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
## Splits into two minis, each with half its HP left (that is also their max
## HP), split_radius x size, split_speed x speed and split_damage more contact
## damage. Each ball splits at most split_gens times in all; a mini with a
## split left splits again below half of its own HP.
func fx_split(sim, b, _ctx: Dictionary) -> void:
	var gen: int = b.state.get("split_gen", 0)
	var hp: float = b.hp * 0.5
	if gen >= int(b.def.split_gens) or hp < 1.0:
		return
	b.state.split_gen = gen + 1
	var twin = sim.spawn_twin(b, hp, b.def.split_radius, b.def.split_speed, b.def.split_damage, deg_to_rad(35.0))
	if gen + 1 < int(b.def.split_gens):
		for m in [b, twin]:
			for key in m.fired.keys():
				if String(key).begins_with("hp_below:"):
					m.fired.erase(key)
	sim.events.append({"type": "split", "ball": b.index, "twin": twin.index, "pos": b.pos})


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
				sim.pull(o, delta / dist * b.def.collapse_accel)
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
	if b.def.fizz_blast > 0.0:
		# The can bursts: a soda geyser that blasts nearby foes away.
		sim.pulse(b, b.pos, b.def.fizz_blast_radius, b.def.fizz_blast, true, "fizz")
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
	# A gum string: the foe stays stuck to Gumdrop and gets dragged along.
	if b.def.get("gum_string", 0.0) > 0.0 and sim.tick >= int(b.state.get("gum_ready", 0)):
		b.state.gum_ready = sim.tick + int(round(b.def.gum_string_cooldown * sim.TICK_RATE))
		sim.tether(b, t, 40.0, b.def.gum_string)
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
	# Full sour: the foe puckers up (stunned) and sour juice splashes out.
	if b.def.get("pucker_stun", 0.0) > 0.0 and b.def.sour_max > 0.0 and amount >= b.def.sour_max - 0.001 and not held.is_empty():
		if sim.stun(b, t, b.def.pucker_stun):
			sim.clear_status(t, key)
			sim.pulse(b, t.pos, 120.0, b.def.pucker_damage, false, "sour")
			sim.events.append({"type": "pucker", "ball": t.index, "source": b.index, "pos": t.pos})
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
	if sim.stun(b, t, b.def.bite_freeze):
		_lunge(sim, b, t)
	sim.pulse(b, t.pos, b.def.shard_radius, b.def.shard_damage, false, "shards")
	if b.def.bite_sour > 0.0:
		sim.add_status(b, t, "bite_sour:%d" % b.index, "vulnerable", b.def.bite_sour, b.def.bite_sour_secs)


## Its first contact hit on a foe it froze, while still frozen, deals
## shatter_mult x (0 = off) and bursts a second round of ice shards, once per freeze.
func fx_shatter(sim, b, ctx: Dictionary) -> void:
	var t = ctx.target
	if b.def.shatter_mult <= 0.0 or not sim.stunned(t) or int(t.state.get("stun_source", -1)) != b.index:
		return
	if int(b.state.get("shattered", -1)) == t.stun_until:
		return
	b.state.shattered = t.stun_until
	ctx.mult *= b.def.shatter_mult
	sim.events.append({"type": "shatter", "ball": t.index, "pos": t.pos})
	if b.def.get("shard_damage", 0.0) > 0.0:
		sim.pulse(b, t.pos, b.def.shard_radius, b.def.shard_damage, false, "shards")


## Rushes at `target` (1.5x speed for half a second) to cash in a stun it set up.
static func _lunge(sim, b, target) -> void:
	var d: Vector2 = target.pos - b.pos
	if d.length() > 0.001:
		sim.charge(b, d, 1.5, 0.5)


## While a foe it froze is frozen, it hunts it down (turns toward it at
## hunt_accel) to land the shatter.
func fx_frost_hunt(sim, b, _ctx: Dictionary) -> void:
	for o in sim.foes(b):
		if sim.stunned(o) and int(o.state.get("stun_source", -1)) == b.index and int(b.state.get("shattered", -1)) != o.stun_until:
			var d: Vector2 = o.pos - b.pos
			if d.length() > 0.001:
				sim.steer(b, d.normalized() * b.def.hunt_accel)
			return


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
			sim.pull(f, delta.normalized() * b.def.wrap_pull)
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
	# Foes it blows into a wall get slammed (at most every gust_slam_gap seconds).
	if b.def.get("gust_slam", 0.0) > 0.0:
		for o in _foes_within(sim, b, b.pos, b.def.wind_range):
			var key := "gust_ready_%d" % b.index
			if sim.tick >= int(o.state.get(key, 0)) and not o.state.has("slam"):
				o.state.slam = {"source": b.index, "damage": b.def.gust_slam, "until": sim.tick + sim.TICK_RATE / 4}
				o.state[key] = sim.tick + int(round(b.def.gust_slam_gap * sim.TICK_RATE))


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
	sim.add_zone(b, pos, {"kind": "honey", "radius": radius, "life": b.def.honey_life, "slow": b.def.honey_slow, "dps": b.def.honey_dps})


## Honey trap: a foe that rolls into one of its puddles gets stuck fast
## (stunned honey_stick seconds) and the puddle is used up. The stun's own
## immunity window lets it wade through puddles for a while after.
## honey_pull > 0 (T5): puddles drag foes within twice their size inwards.
func fx_honey_trap(sim, b, _ctx: Dictionary) -> void:
	for z in _own_zones(sim, b, "honey"):
		for o in sim.foes(b):
			if b.def.honey_pull > 0.0 and o.alive() and not sim.stunned(o):
				var d: Vector2 = z.pos - o.pos
				if d.length() < z.radius * 2.0 + o.radius and d.length() > 0.001:
					sim.pull(o, d.normalized() * b.def.honey_pull)
			if not o.alive() or sim.stunned(o) or o.pos.distance_to(z.pos) > z.radius + o.radius:
				continue
			if sim.stun(b, o, b.def.honey_stick):
				sim.zones.erase(z)
				sim.events.append({"type": "honey_stuck", "ball": o.index, "source": b.index, "pos": o.pos})
				if b.def.honey_sting_damage > 0.0:
					sim.pulse(b, o.pos, z.radius, b.def.honey_sting_damage, false, "honey")
				_lunge(sim, b, o)
				break


## Its contact hit on a foe stuck in its honey deals honey_crush x.
func fx_honey_crush(sim, b, ctx: Dictionary) -> void:
	var t = ctx.target
	if sim.stunned(t) and int(t.state.get("stun_source", -1)) == b.index:
		ctx.mult *= b.def.honey_crush
		sim.events.append({"type": "honey_crush", "ball": t.index, "source": b.index, "pos": t.pos})


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
	b.shield = maxf(b.shield, b.def.salvo_shield)
	b.state.salvo_shield_until = sim.tick + int(round(b.def.salvo_shield_secs * sim.TICK_RATE))
	var delay := int(round(b.def.get("salvo_delay", 0.0) * sim.TICK_RATE))
	if delay <= 0:
		_salvo_fire(sim, b)
		return
	# Locks on first: it brakes and its launchers open, so the salvo reads.
	b.state.salvo_at = sim.tick + delay
	sim.events.append({"type": "salvo_lock", "ball": b.index, "pos": b.pos, "secs": b.def.salvo_delay})


func _salvo_fire(sim, b) -> void:
	_volley(sim, b, int(b.def.shot_count), str(b.def.get("shot_aim", "foe")))
	sim.events.append({"type": "salvo", "ball": b.index, "pos": b.pos})


## Drops what's left of a salvo shield when its time is up (an "always" entry).
func fx_salvo_tick(sim, b, _ctx: Dictionary) -> void:
	if b.state.has("salvo_at"):
		if sim.tick >= int(b.state.salvo_at):
			b.state.erase("salvo_at")
			_salvo_fire(sim, b)
		else:
			b.slow = maxf(b.slow, 0.7)
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


## Slows `o` by `amount` for `secs`: a timed slow status (MatchSim.add_status)
## keyed to `b`, kept at the stronger of the old and new chill.
static func chill(sim, b, o, amount: float, secs: float) -> void:
	var key := "chill:%d" % b.index
	var held: Dictionary = sim.status(o, key)
	if held.is_empty() or amount >= float(held.amount):
		sim.add_status(b, o, key, "slow", amount, secs)


## Yeti's avalanche: roar_damage to foes within roar_radius, knocking them
## away and chilling them (roar_slow for roar_secs). roar_drifts > 0 leaves
## that many snowdrifts around it (radius 70, 4s, 30% slow).
func fx_roar(sim, b, _ctx: Dictionary) -> void:
	sim.events.append({"type": "roar", "ball": b.index, "pos": b.pos})
	sim.pulse(b, b.pos, b.def.roar_radius, b.def.roar_damage, true, "frost")
	for o in sim.foes(b):
		if o.pos.distance_to(b.pos) <= b.def.roar_radius + o.radius:
			chill(sim, b, o, b.def.roar_slow, b.def.roar_secs)
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


## A foe standing in two of its frost patches at once freezes (a stun) for
## freeze_secs; the stun's own immunity keeps it from chaining.
func fx_snow_freeze(sim, b, _ctx: Dictionary) -> void:
	if b.def.freeze_secs <= 0.0:
		return
	for o in sim.foes(b):
		if sim.stunned(o):
			continue
		var n := 0
		for z in sim.zones:
			if z.owner == b.index and z.kind == "snow" and o.pos.distance_to(z.pos) <= z.radius + o.radius:
				n += 1
		if n >= 2:
			sim.stun(b, o, b.def.freeze_secs)


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
				sim.pull(o, delta / dist * b.def.hug_accel)


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
		var length: float = _wall_reach(sim, from, dir) if flaring else b.def.quasar_length
		_hold_beam(sim, b, name, from, from + dir * length, dps)


## Distance from p along dir to the arena's outer wall.
static func _wall_reach(sim, p: Vector2, dir: Vector2) -> float:
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
	var t = ctx.target
	if b.def.get("blink_behind", 0) > 0 and t.alive():
		# Lands right behind the foe, facing it: a backstab waiting to happen.
		var back: Vector2 = -t.vel.normalized() if t.vel.length() > 0.001 else (b.pos - t.pos).normalized()
		var spot: Vector2 = sim.inside(t.pos + back * (t.radius + b.radius + b.def.blink_away), b.radius + 10.0)
		sim.teleport(b, spot)
		if t.pos.distance_to(b.pos) > 0.001:
			b.vel = (t.pos - b.pos).normalized() * b.current_speed()
	else:
		sim.teleport(b, sim.teleport_spot(b, t.pos, b.def.blink_away))
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


## Puppet throw: when its string runs out it hurls the foe straight away from
## it at 1.8x speed for string_fling seconds; the first wall (or pillar) the
## foe hits in that time slams it for string_slam, stunned string_stun at T3+.
func fx_string_fling(sim, b, _ctx: Dictionary) -> void:
	if not b.state.has("string_until") or sim.tick != int(b.state.string_until) + 1:
		return
	var t = sim.balls[int(b.state.string_target)]
	if not t.alive() or not sim.ability_moves():
		return
	var away: Vector2 = t.pos - b.pos
	if away.length() < 0.001:
		away = t.vel
	sim.charge(t, away, 1.8, b.def.string_fling)
	t.state.slam = {"source": b.index, "damage": b.def.string_slam, "stun": b.def.get("string_slam_stun", 0.0),
		"until": sim.tick + int(round(b.def.string_fling * sim.TICK_RATE))}
	sim.events.append({"type": "fling", "ball": t.index, "source": b.index, "pos": t.pos})


## When a string runs out, the foe spins out dizzy (slowed 90% for string_stun
## seconds) and it bows behind a string_shield shield.
func fx_string_snap(sim, b, _ctx: Dictionary) -> void:
	if not b.state.has("string_until") or sim.tick != int(b.state.string_until) + 1:
		return
	var t = sim.balls[int(b.state.string_target)]
	if t.alive() and b.def.get("string_fling", 0.0) <= 0.0: # A thrown foe isn't stopped.
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
	if b.def.ping_mark > 0.0: # T5: the ping finds the foe wherever it is; its next hit on it crits.
		f.state.heard_until = sim.tick + int(round(b.def.ping_mark * sim.TICK_RATE))
		f.state.heard_by = b.index
		sim.events.append({"type": "heard", "ball": f.index, "source": b.index, "pos": f.pos})
	for o in sim.foes(b):
		if o.pos.distance_to(b.pos) <= b.def.ping_radius + o.radius:
			sim.slow_for(o, b.def.ping_slow, b.def.ping_slow_secs)


## A contact hit while still swerving from a ping, or on a foe its ping
## marked (ping_mark, T5), deals ping_hit_mult x.
func fx_ping_crit(sim, b, ctx: Dictionary) -> void:
	var t = ctx.target
	var heard: bool = int(t.state.get("heard_by", -1)) == b.index and sim.tick < int(t.state.get("heard_until", -1))
	if heard or (sim.charging(b) and sim.tick < int(b.state.get("ping_until", -1))):
		b.state.ping_until = -1
		t.state.heard_until = -1
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
	var f = sim.nearest_foe(b)
	for spot in ring.spots:
		# Aim at where the foe is when they fire, not where it was ringed.
		var c: Vector2 = f.pos if f != null else ring.centre
		var to: Vector2 = c - spot
		segs.append([spot, spot + to.normalized() * (to.length() + 60.0)] if to.length() > 0.001 else [spot, c])
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
## a spray of coins at the foe, a shield). Every spin_jackpot_every-th spin (when above 0)
## pays them all. The target spot is locked when the reels stop.
const PRIZES := ["mines", "cross", "coins", "shield"]
const COIN_FAN := 50.0 ## Degrees the coin spray spans.

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
			"mines": # Placed now round where the foe is heading, armed when the reels stop.
				var turn: float = sim.rng.next_float() * TAU
				var ahead: Vector2 = spot + f.vel * b.def.spin_delay
				for k in 3:
					sim.add_zone(b, sim.inside(ahead + Vector2.from_angle(turn + k * TAU / 3.0) * 90.0, 30.0), {"kind": "mine", "radius": 16.0,
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
			"cross": # Through the foe's spot as the reels stop.
				var f = sim.nearest_foe(b)
				var r: Rect2 = sim.arena_rect()
				var c: Vector2 = f.pos if f != null else p.spot
				var dmg: float = b.def.prize_beam_damage * b.def.prize_mult * 0.5
				sim.add_beam(b, Vector2(r.position.x, c.y), Vector2(r.end.x, c.y), {"life": 1.0, "damage": dmg, "cooldown": 0.5})
				sim.add_beam(b, Vector2(c.x, r.position.y), Vector2(c.x, r.end.y), {"life": 1.0, "damage": dmg, "cooldown": 0.5})
			"coins":
				# A fan of coins sprayed at the nearest foe, at most prize_coin_hits landing.
				var f = sim.nearest_foe(b)
				if f == null:
					continue
				var segs := []
				var n := int(b.def.prize_coin_count)
				var aim: float = (f.pos - b.pos).angle()
				for k in n:
					var dir := Vector2.from_angle(aim + (k - (n - 1) / 2.0) * deg_to_rad(COIN_FAN) / maxf(n - 1, 1))
					segs.append([b.pos + dir * b.radius, b.pos + dir * (b.radius + b.def.prize_coin_reach)])
				_shoot(sim, b, segs, b.def.prize_coin_damage * b.def.prize_mult, "coin", 0.0, 1.0, int(b.def.prize_coin_hits))


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
	if b.def.ripple_wave_radius > 0.0: # T5: the bounce also breaks as a wave.
		sim.pulse(b, p, b.def.ripple_wave_radius, b.def.ripple_wave_damage, false, "tide")


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
