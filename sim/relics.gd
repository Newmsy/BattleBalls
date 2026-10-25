## Bounce Run relics: run-only keepsakes, each a small version of one
## critter's ability that the whole trio carries for the rest of the run. A
## relic is pure bonus (about +10-15% power: tools/relic_check.gd) and never
## has a downside. You pick one at the start of a run; elites, the floor-10
## chest and two events drop more (sim/bounce_run.gd).
##
## A relic adds that critter's own ability entries (sim/abilities.gd) to the
## holder, run with the relic's own params: Abilities swaps the ball's def for
## the relic's while one of its entries fires (Ball.relic_defs), so a relic's
## numbers never mix with the holder's own ability. Holder stats, boons and
## gear stay in that def, so a relic hits as hard as its holder does.
##
## Fields:
##   critter   whose ability it tames (icon, face badge, name "Relic of X")
##   text      card text (sim text never says "glow")
##   entries   ability entries, as in a critter file
##   set       params as plain numbers
##   bump      params as a share of the holder's bump (contact) damage
##   of_hp     params as a share of the holder's max HP
## A holder that already has the relic's ability gets OWN_BOOST on its own
## ability's numbers instead.
extends RefCounted

const CritterDb := preload("res://sim/critter_db.gd")

const OWN_BOOST := 0.25 ## Same as one tier of ability potency (CritterDb.ABILITY_TIER_STEP).
const OWN_TEXT := "Your %s already has this ability: it hits 25% harder instead."

const DEFS := {
	"spiker": {"text": "Every 3rd bump you land fires 3 spikes outward (60% of a bump each).",
		"entries": [{"on": "hit", "do": "relic_nth"}],
		"set": {"relic_every": 3, "relic_do": "relic_spikes", "shot_count": 3, "shot_speed": 500.0, "shot_kind": "spike"},
		"bump": {"shot_damage": 0.6}},
	"swarm": {"text": "A bee circles you and stings foes it touches (20% of a bump).",
		"entries": [{"on": "always", "do": "swarm"}],
		"set": {"bee_count": 1, "bee_orbit": 30.0, "bee_size": 10.0, "bee_spin": 4.0, "bee_cooldown": 0.6, "bee_speed": 560.0,
			"bee_turn": 5.0, "bee_life": 3.0, "bee_poison_dps": 0.0},
		"bump": {"bee_damage": 0.2, "bee_launch_damage": 0.2}},
	"mossy": {"text": "Bumps plant moss on the foe: it drains 2.5% of a bump a second for 3s and heals you the same.",
		"entries": [{"on": "hit", "do": "moss"}, {"on": "always", "do": "regrow"}],
		"set": {"moss_secs": 3.0, "regrow_after": 9999.0, "regrow_hps": 0.0, "regrow_spores": 0.0},
		"bump": {"moss_dps": 0.025, "moss_heal": 0.025}},
	"old_oak": {"text": "Once, at 50% HP, 2 roots burst up beside you and you regrow 1.5% max HP a second while they stand (6s).",
		"entries": [{"on": "hp_below", "hp": 0.5, "do": "root"}, {"on": "always", "do": "root_tick"}],
		"set": {"root_count": 2, "root_radius": 32.0, "root_life": 6.0, "root_stay": 0, "root_pin": 0.5, "root_shove": 0.0, "root_shove_damage": 0.0},
		"of_hp": {"root_regen": 0.015}},
	"bubbles": {"text": "Every 10s a bubble shield soaks up to a quarter of a bump, then pops and knocks the attacker back.",
		"entries": [{"on": "every", "secs": "bubble_every", "do": "bubble"}, {"on": "guard", "do": "bubble_guard"}],
		"set": {"bubble_every": 10.0, "bubble_secs": 4.0, "bubble_min": 4.0, "bubble_knock": 1.0, "bubble_bolts": 0.0, "bubble_splash": 0.0, "bolt_damage": 0.0},
		"bump": {"bubble_size": 0.25}},
	"fin": {"text": "Every 5th bump is a big bite for x1.6 damage.",
		"entries": [{"on": "strike", "do": "chomp"}],
		"set": {"chomp_every": 5.0, "chomp_mult": 1.6, "chomp_burn": 0.0, "chomp_heal": 0.0}},
	"clam": {"text": "Every 7s you fire 2 pearls at the foe (10% of a bump each).",
		"entries": [{"on": "every", "secs": 7.0, "do": "shoot"}],
		"set": {"shot_count": 2, "shot_aim": "foe", "shot_speed": 600.0, "shot_kind": "pearl", "shot_radius": 13.0},
		"bump": {"shot_damage": 0.1}},
	"kraken": {"text": "One short tentacle sweeps round you (25% of a bump a touch).",
		"entries": [{"on": "always", "do": "tentacles"}],
		"set": {"tentacle_count": 1, "tentacle_orbit": 70.0, "tentacle_size": 16.0, "tentacle_spin": 1.4, "tentacle_cooldown": 1.0, "hug_range": 0.0, "hug_accel": 0.0},
		"bump": {"tentacle_damage": 0.25}},
	"bolt": {"text": "Every 4th bump teleports you right behind the foe; your next bump hits 40% harder.",
		"entries": [{"on": "hit", "do": "blink"}, {"on": "strike", "do": "blink_bonus"}],
		"set": {"blink_every": 4, "blink_away": 60.0, "blink_behind": 1, "blink_crackle": 0.0, "blink_crackle_radius": 70.0, "blink_zap": 0.0},
		"bump": {"blink_bonus": 0.4}},
	"laser": {"text": "Your wall bounces fire a short beam back to your last bounce point (lasts 1s).",
		"entries": [{"on": "wall", "do": "beam"}],
		"set": {"beam_life": 1.0, "beam_hit_cooldown": 0.5, "beam_max": 6},
		"bump": {"beam_damage": 0.04}},
	"megabot": {"text": "Every 5th bump fires 2 homing rockets (35% of a bump each).",
		"entries": [{"on": "hit", "do": "salvo"}, {"on": "always", "do": "salvo_tick"}],
		"set": {"salvo_hits": 5, "salvo_shield": 0.0, "salvo_shield_secs": 0.0, "salvo_delay": 0.4, "shot_count": 2, "shot_speed": 450.0, "shot_aim": "foe",
			"shot_homing": 3.0, "shot_spread": 30.0, "shot_life": 2.5, "shot_radius": 9.0, "shot_kind": "rocket"},
		"bump": {"shot_damage": 0.35}},
	"clockwork": {"text": "Every 6s you tick out a small ring: 50% of a bump and 20% slow for 1s.",
		"entries": [{"on": "every", "secs": 6.0, "do": "tick_ring"}],
		"set": {"tick_radius": 130.0, "tick_slow": 0.2, "tick_slow_secs": 1.0, "face_secs": 0.0},
		"bump": {"tick_damage": 0.5}},
	"crumb": {"text": "At 50% HP a bite breaks off you: +6% speed, 2 crumbs fly at the foe and a cookie piece drops that heals 3% HP if you roll over it.",
		"entries": [{"on": "hp_below", "hp": 0.5, "do": "grow"}, {"on": "always", "do": "crumb_pick"}],
		"set": {"grow_radius": -0.1, "grow_speed": 0.06, "grow_add": 0.0, "grow_secs": 0.0, "grow_stack": 1.0, "grow_heal": 0.0,
			"grow_pulse_radius": 0.0, "grow_pulse_damage": 0.0, "grow_bolts": 2.0, "crumb_pieces": 1},
		"bump": {"bolt_damage": 0.12}, "of_hp": {"crumb_heal": 0.03}},
	"jawbreaker": {"text": "Bumps you land add a candy that circles you (up to 2) and bonks foes for 14% of a bump.",
		"entries": [{"on": "always", "do": "candies"}, {"on": "hit", "do": "candy"}],
		"set": {"candy_max": 2, "candy_orbit": 34.0, "candy_size": 11.0, "candy_spin": 3.0, "candy_cooldown": 0.5, "candy_start": 0,
			"candy_blast_radius": 140.0, "candy_blast_damage": 0.0},
		"bump": {"candy_damage": 0.14}},
	"pucker": {"text": "Bumps make the foe sour: +12% damage taken for 3s, stacking to +24%.",
		"entries": [{"on": "hit", "do": "sour"}],
		"set": {"sour_amount": 0.12, "sour_secs": 3.0, "sour_max": 0.24, "sour_puddle": 0.0, "sour_puddle_slow": 0.25, "pucker_stun": 0.0, "pucker_damage": 0.0}},
	"frost": {"text": "You leave a short icy trail that slows foes 35%.",
		"entries": [{"on": "always", "do": "trail"}],
		"set": {"trail_every": 0.1, "trail_width": 26.0, "trail_life": 1.5, "trail_slow": 0.35, "trail_dps": 0.0}},
	"blizz": {"text": "Every 7s you drop a snowflake mine (one at a time) that blasts for 17% of a bump and leaves a frost patch.",
		"entries": [{"on": "every", "secs": 7.0, "do": "snow_mine"}],
		"set": {"mine_arm": 1.0, "mine_radius": 70.0, "mine_max": 1.0, "mine_life": 20.0, "mine_trigger": 16.0, "frost_radius": 90.0,
			"frost_secs": 2.5, "frost_slow": 0.2, "freeze_secs": 0.0},
		"bump": {"mine_damage": 0.17}},
	"frostfang": {"text": "Every 14s an ice wolf runs at the foe: 10% of a bump and 20% slow.",
		"entries": [{"on": "every", "secs": 14.0, "do": "howl"}],
		"set": {"wolf_count": 1, "howl_every": 14.0},
		"bump": {"wolf_damage": 0.1}},
	"drum": {"text": "Every 3rd bump sends out a shockwave ring: 25% of a bump and a knockback.",
		"entries": [{"on": "hit", "do": "relic_nth"}],
		"set": {"relic_every": 3, "relic_do": "boom", "boom_radius": 110.0, "boom_slam": 0.0, "boom_double_every": 0},
		"bump": {"boom_damage": 0.25}},
	"mortar": {"text": "Every 7s you lob a toy shell at where the foe is heading (9% of a bump).",
		"entries": [{"on": "every", "secs": 7.0, "do": "lob"}],
		"set": {"lob_radius": 80.0, "lob_lead": 0.7, "lob_flight": 0.7, "lob_crater_dps": 0.0, "lob_barrage_every": 0},
		"bump": {"lob_damage": 0.09}},
	"jackpot": {"text": "Every 10s the reels spin a small prize: 3 mines, a beam cross or a coin spray.",
		"entries": [{"on": "every", "secs": 10.0, "do": "spin"}, {"on": "always", "do": "spin_tick"}],
		"set": {"spin_prizes": 3, "spin_delay": 0.5, "spin_jackpot_every": 0, "prize_mult": 1.0, "prize_mine_radius": 60.0,
			"prize_coin_count": 4, "prize_coin_reach": 350.0, "prize_coin_hits": 3, "prize_shield": 0.0},
		"bump": {"prize_mine_damage": 0.1, "prize_beam_damage": 0.13, "prize_coin_damage": 0.05}},
	"puppeteer": {"text": "Every 9s your next bump ties a string to the foe and flings it into the nearest wall (30% of a bump).",
		"entries": [{"on": "hit", "do": "string"}, {"on": "always", "do": "string_fling"}],
		"set": {"string_cooldown": 9.0, "string_length": 120.0, "string_secs": 0.6, "string_fling": 0.7, "string_slam_stun": 0.0},
		"bump": {"string_slam": 0.3}},
	"ghost": {"text": "Every 10s you fade for 0.8s (-20% damage taken), and your next bump after deals x1.15.",
		"entries": [{"on": "every", "secs": "phase_every", "do": "phase"}, {"on": "guard", "do": "phased"}, {"on": "strike", "do": "ambush"}],
		"set": {"phase_every": 10.0, "phase_secs": 0.8, "phase_guard": 0.8, "ambush_mult": 1.15}},
	"foxfire": {"text": "Every 10s a fox-fire copy of you splits off; a foe that touches it takes 17% of a bump and a burn.",
		"entries": [{"on": "every", "secs": 10.0, "do": "illusions"}, {"on": "always", "do": "illusion_tick"}],
		"set": {"illusion_count": 1, "illusion_life": 4.0, "illusion_size": 0.7, "illusion_radius": 90.0, "illusion_trail_damage": 0.0, "illusion_swap": 0},
		"bump": {"illusion_damage": 0.17, "illusion_burn_damage": 0.03}},
	"magmo": {"text": "Every 3rd bump splashes a small lava puddle (one at a time) that burns foes in it.",
		"entries": [{"on": "hit", "do": "relic_nth"}],
		"set": {"relic_every": 3, "relic_do": "lava", "lava_radius": 55.0, "lava_life": 2.5, "lava_max": 1},
		"bump": {"lava_dps": 0.45}},
	"drako": {"text": "Every 5th bump breathes 3 small fireballs (15% of a bump each, plus a burn).",
		"entries": [{"on": "hit", "do": "relic_nth"}],
		"set": {"relic_every": 5, "relic_do": "breath_timer", "breath_every": 0.0, "fire_count": 3.0, "fire_cone": 30.0, "fire_range": 260.0, "fire_streak": 0.0},
		"bump": {"fire_damage": 0.15, "fire_burn": 0.06}},
	"supernova": {"text": "Every 12s you swell a little, then pop in a small blast (75% of a bump).",
		"entries": [{"on": "always", "do": "relic_nova"}],
		"set": {"nova_every": 12.0, "nova_radius": 240.0},
		"bump": {"nova_damage": 0.75}},
	"comet": {"text": "You leave a short stardust trail that stings foes crossing it.",
		"entries": [{"on": "always", "do": "stardust"}],
		"set": {"trail_every": 0.1, "trail_width": 26.0, "trail_life": 1.0},
		"bump": {"trail_dps": 0.1}},
	"gravity": {"text": "A small moon circles you and bonks foes (20% of a bump).",
		"entries": [{"on": "always", "do": "moons"}],
		"set": {"moon_count": 1, "moon_orbit": 40.0, "moon_size": 13.0, "moon_spin": 3.0, "moon_cooldown": 0.5, "moon_burn": 0.0},
		"bump": {"moon_damage": 0.2}},
	"blackhole": {"text": "Every 12s you collapse for 1s, tugging the foe a little closer, then burst in a ring (90% of a bump).",
		"entries": [{"on": "always", "do": "collapse"}],
		"set": {"collapse_every": 12.0, "collapse_secs": 1.0, "collapse_range": 350.0, "collapse_accel": 600.0, "collapse_radius": 200.0,
			"collapse_ring": 0.0, "collapse_burn": 0.0},
		"bump": {"collapse_damage": 0.9}},
}

## Every relic, in a fixed order (offers and drops index into this): by
## family, as the draft page lists them.
const IDS := ["spiker", "swarm", "mossy", "old_oak", "bubbles", "fin", "clam", "kraken", "bolt", "laser", "megabot", "clockwork",
	"crumb", "jawbreaker", "pucker", "frost", "blizz", "frostfang", "drum", "mortar", "jackpot", "puppeteer", "ghost", "foxfire",
	"magmo", "drako", "supernova", "comet", "gravity", "blackhole"]


static func has(id: String) -> bool:
	return DEFS.has(id)


## "Relic of Fin".
static func name_of(id: String) -> String:
	return "Relic of %s" % CritterDb.get_critter(id).name


static func text_of(id: String) -> String:
	return DEFS[id].text


## {def, relic_defs}: `def` with every relic in `ids` added, and the def each
## relic's entries run with (id -> def), for Ball.relic_defs.
static func apply_to_def(def: Dictionary, ids: Array) -> Dictionary:
	var out := def.duplicate()
	var own: Array = _own_keys(str(def.get("ability", "")))
	var effects: Array = def.get("effects", []).duplicate()
	var adds := []
	for id in ids:
		if not DEFS.has(id):
			continue
		if id == def.get("ability", ""):
			_boost_own(out)
			continue
		adds.append(id)
	var relic_defs := {}
	for id in adds:
		var r: Dictionary = DEFS[id]
		for e in r.entries:
			var entry: Dictionary = e.duplicate()
			entry.relic = id
			effects.append(entry)
	out.effects = effects
	for id in adds:
		var r: Dictionary = DEFS[id]
		var rd := out.duplicate()
		for key in own: # The holder's own ability numbers stay out of the relic's way.
			rd.erase(key)
		rd.merge(r.get("set", {}), true)
		for key in r.get("bump", {}):
			rd[key] = float(r.bump[key]) * float(out.contact_damage)
		for key in r.get("of_hp", {}):
			rd[key] = float(r.of_hp[key]) * float(out.hp)
		rd.relic_id = id
		rd.effects = effects
		relic_defs[id] = rd
	return {"def": out, "relic_defs": relic_defs}


## Param keys of a critter's own ability (its file's params and tier keys).
static func _own_keys(critter: String) -> Array:
	if critter == "" or not CritterDb.ids().has(critter):
		return []
	var c := CritterDb.get_critter(critter)
	var keys: Array = c.params.keys()
	for t in c.tiers:
		for key in t:
			if not key in CritterDb.TEXT_KEYS and key != "ability" and not key in keys:
				keys.append(key)
	return keys


## A relic of the holder's own critter: its ability hits OWN_BOOST harder.
static func _boost_own(def: Dictionary) -> void:
	for key in _own_keys(str(def.ability)):
		if not def.has(key) or not (def[key] is float or def[key] is int):
			continue
		var k := String(key)
		if k.ends_with("_damage") or k.ends_with("_dps") or k.ends_with("_burn") or k.ends_with("_shield") or k.ends_with("_hps"):
			def[key] = def[key] * (1.0 + OWN_BOOST)
		elif k in CritterDb.HIT_MULTS and def[key] > 1.0:
			def[key] = 1.0 + (def[key] - 1.0) * (1.0 + OWN_BOOST)
