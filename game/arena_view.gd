## Draws a MatchSim in the Neon Critters style (design/critters.md). Holds no
## game rules: everything it shows comes from the sim's state and the events
## of each step. Effects use their own RNG and never feed back into the sim.
extends Node2D

const Dot := preload("res://game/dot.gd")
const BossArt := preload("res://game/boss_art.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Bosses := preload("res://sim/bosses.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Modifiers := preload("res://sim/modifiers.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")
const Roster := preload("res://game/ui/roster.gd")
const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")
const Catalog := preload("res://game/glow/catalog.gd")
const CosmeticArt := preload("res://game/glow/cosmetic_art.gd")
const A11y := preload("res://game/a11y.gd")
const RarityMark := preload("res://game/ui/rarity_mark.gd")
const Abilities := preload("res://sim/abilities.gd")
const BattleFx := preload("res://game/battle_fx.gd")
const ArenaTheme := preload("res://game/arena_theme.gd")

const INK := Color("1a1530")
const ARENA_FILL := Color("120f33")
const GRID := Color(120 / 255.0, 110 / 255.0, 1.0, 0.08)
const BORDER := Color("8f7bff")
const OVERTIME_BORDER := Color("ff5a7a")
const BEAM := Color("27c8ff")
const BURST := Color("ffe28a")
const POP_DAMAGE := Color("ff5a7a")
const POP_HEAL := Color("45f5a6")
const POP_BEAM := Color("7cc4ff")
const POP_SNAP := Color("ffe066")
const MINE := Color("ff4d4d")
## Floor zone fills by kind (sim Zone.kind).
const ZONE_COLORS := {"ice": Color("bfe9ff"), "frost": Color("9fd8ff"), "wisp": Color("e3d6ff"), "fire": Color("ff7a1f"), "ring": Color("b366ff"), "spore": Color("8fd16a"), "fizz": Color("ff8cc6"),
	"lava": Color("ff4500"), "stardust": Color("ff8ae2"), "ember": Color("ff9a3d"), "honey": Color("ffb627"), "ink": Color("8a5cc8"),
	"stink": Color("9be36b"), "rain": Color("8fa2ff"), "goo": Color("7cff6b"), "brew": Color("b6ff3b"), "sour": Color("9ef01a"),
	"snow": Color("dff6ff"), "splat": Color("ffc2d1"), "inkpool": Color("5a2a8a"), "whirlpool": Color("3fd0c9"), "clod": Color("b08968"), "thorn": Color("3fbf6a")}
## Pulse and blast ring colours by kind.
const RING_COLORS := {"pulse": Color("ffe28a"), "frost": Color("9fd8ff"), "fire": Color("ff7a1f"), "nova": Color("e8d6ff"), "flare": Color("a89cff"), "boom": Color("ff8a3d"),
	"zap": Color("c9a6ff"), "bigzap": Color("f0e2ff"), "drum": Color("ff5a6a"), "wind": Color("c7f9cc"), "ink": Color("8a5cc8"), "stink": Color("9be36b"),
	"shell": Color("ffb347"), "blob": Color("7cff6b"), "hammer": Color("ff8a3d"), "quake": Color("ffd166"), "lash": Color("7af0ff"),
	"shards": Color("cdf3ff"), "paint": Color("ffd23f"), "confetti": Color("f15bb5"), "thunder": Color("8ecbff"),
	"bugflare": Color("e8ff7a"), "candy": Color("ff9de2"), "inkslam": Color("b36bff"), "wave": Color("5ff0e6"), "quasar": Color("e0b3ff"),
	"glitch": Color("7cff4f"), "ping": Color("b48cff"), "dirt": Color("b08968"),
	"petal": Color("ff9ecf"), "tick": Color("ffd166"), "root": Color("a5743a"), "sunfire": Color("ffe14d")}
## Statuses: frozen (stunned) balls sit in an ice block; vulnerable ones glow sour green.
const FROZEN := Color("bfefff")
const VULNERABLE := Color("9ef01a")
const STRING := Color("ffd1e8")
const MARK := Color("ff5a5a")
## Placed arena pieces (sim Piece.kind): {body, rim}.
const PIECE_COLORS := {"seed": [Color("2f6b12"), Color("8ac926")], "vine": [Color("0b4f37"), Color("2ee59d")],
	"ice": [Color("4b4a8f"), Color("d9d0ff")], "root": [Color("4a2c10"), Color("b7864a")]}
## Instant shots (sim "rays" events) by kind; "disco" cycles the rainbow.
const RAY_COLORS := {"shard": Color("d9d0ff"), "coin": Color("ffd23f"), "seed": Color("8ac926")}
const RAY_LIFE := 0.35
## What Jackpot's reels landed on.
const PRIZE_TEXT := {"mines": "MINES!", "cross": "LASERS!", "coins": "COINS!", "shield": "SHIELD!"}
const RING_LIFE := 0.45
## Mode call-outs by critter (Kaleido's clicks, Eclipse's flips), by b.state.mode.
const MODE_NAMES := {"kaleido": ["SPIKES!", "SHIELD!", "SPEED!", "PRISM!"], "eclipse": ["SUN!", "MOON!"]}
const MODE_COLORS := {"kaleido": [Color("ff4d6d"), Color("7fe6ff"), Color("ffe066"), Color("ffffff")], "eclipse": [Color("ffb347"), Color("b8c4ff")]}
## Crits pop bigger in gold; backstabs get their own call-out.
const POP_CRIT := Color("ffb627")
const POP_BACKSTAB := Color("d68cff")
const CRIT_POP_SCALE := 1.5
## Field rings (the "field" effect): Pull draws in blue, Push pushes out red.
const FIELD_PULL := Color("4d8dff")
const WELL := Color("b36bff")
const WELL_CORE := Color("07051a")
const SPIKE := Color("ff3d7f")
const LAVA := Color("ff5a1f")
const PORTAL := Color("7cff9b")
const PORTAL_B := Color("c77dff")
const ICE := Color("bfe9ff")
const GOO := Color("ffb627")
const CONVEYOR := Color("ffd23f")
const FIELD_PUSH := Color("ff4d6a")
const RARITY_COLORS := Roster.RARITY_COLORS
## Side markers so mirror matches stay readable: index 0 is always the player.
## Colour is never the only cue: the player's ring is solid, the foe's is
## dashed with four spikes, so red-green colourblind players can tell them apart.
const TEAM_COLORS := [Color("45f5a6"), Color("ff5a7a")]
const TEAM_TAGS := ["YOU", "FOE"]
const TEAM_RING_ALPHA := 0.5
## Critters whose speed-ups trail bubbles instead of a blur.
const SWIMMERS := ["minnow", "fin", "ripple", "narwhal", "leviathan", "kraken"]

const POPUP_LIFE := 0.9
const HIT_LIFE := 0.35
const BURST_LIFE := 0.35
const BLINK_PERIOD := 4.3
const PILLAR := Color("6d79b8")
const BUMPER := Color("ff6fae")
const BUMPER_FLASH_LIFE := 0.2
const BANNER_LIFE := 1.6
## HP share under which the badge turns red (matches the heartbeat sound).
const LOW_HP_SHARE := 0.35

var sim: MatchSim
var _tag_at := {} ## Ball index -> where its tag is drawn this frame (_place_tags).
var team_tags: Array = TEAM_TAGS ## Labels under each ball; a shared replay uses P1/P2.
## The sim side the viewer plays: a live match puts you on side 1 half the
## time, and the rings, tags and aim line follow you, not the sim's order.
var you_side := 0
var view_scale := 0.68
## Launch aim preview for the player's ball (world direction), or ZERO to hide.
var aim_dir := Vector2.ZERO
## Onboarding's suggested launch (world direction), drawn as a pulsing ghost
## arrow, or ZERO to hide.
var ghost_dir := Vector2.ZERO
## Ball types to show before a sim exists (menu preview).
var preview_types: Array = ["vampire", "laser"]
var preview_modifier := Modifiers.NONE
## Arena to show before a sim exists (menu preview).
var preview_arena := "square"
## Tier of each ball (stars on the badge, how big its feature grows).
var tiers: Array = [1, 1]
## Where the arena sits at zoom 1; the finisher cam moves and scales from here.
var origin := Vector2.ZERO
var cam_zoom := 1.0
var cam_focus := Vector2.ONE * MatchSim.ARENA_SIZE / 2.0
## Finisher cam: the knocked-out ball, drawn with its KO face after it falls.
var ko_ball := -1
## 0..1: how far into the finisher (letterbox bars and the K.O. banner).
var finisher_amount := 0.0
## 0..1: how far the frame is between the previous sim step and the current one.
var render_alpha := 1.0
var _prev_pos: Array = []
## Cosmetics per side ({slot: id}, see game/glow/catalog.gd); index 0 is the
## player. Render-only: the sim never sees these.
var loadouts: Array = [{}, {}]

var _time := 0.0
var _shake := 0.0
var _popups: Array[Dictionary] = []
var _particles: Array[Dictionary] = []
var _bursts: Array[Dictionary] = []
var _wisps: Array[Dictionary] = []
var _rings: Array[Dictionary] = [] ## Expanding pulse / blast rings: {pos, radius, color, age}.
var _flashes: Array[Dictionary] = [] ## Reflect zaps: {from, to, age}.
var _rays: Array[Dictionary] = [] ## Instant shots: {segments, kind, age, life}.
var _look: Array[Vector2] = [Vector2(1, -1).normalized(), Vector2(-1, 1).normalized()]
var _hit := [0.0, 0.0]
var _squash := [0.0, 0.0]
var _eye_flash := [0.0, 0.0]
var _bumper_flash := 0.0
var _spike_flash := 0.0
var _grid := GRID ## This arena's grid colour (game/arena_theme.gd).
var _pillar := PILLAR
## Field pole spin: eases 0 (Pull) <-> 1 (Push) after each flip.
var _pole_swap := [0.0, 0.0]
var _fx_rng := RandomNumberGenerator.new()
var _ko_age := 0.0
var _banner := 0.0 ## Seconds left on the OVERTIME banner.
var _was_overtime := false
var _trails: Array = [[], []] ## Recent world positions per ball, oldest first.
var _kos: Array[Dictionary] = []
var _chomps: Array[Dictionary] = [] ## Count Nibbles' bites: {pos, dir, size, age}.
var _novas: Array[Dictionary] = [] ## Void/Supernova blasts: {pos, radius, color, age}.
var _fx: Array[Dictionary] = [] ## One-off effects: {kind, pos, age, life, ...} (see _draw_fx).
var _rebirths: Array[Dictionary] = [] ## Ember rising again: {ball, age}.
var _revives: Dictionary = {} ## Phoenix revives seen per ball, for "REBORN AGAIN!".
var _bolts: Array[Dictionary] = [] ## Lightning: {from, to, age, seed}; ring ones have a radius instead of to.
var _grow_flash := [0.0, 0.0] ## Prickles' spike flash.
var _dot_seen: Array = [[], []] ## Damage-over-time looks each side already showed a popup for.
const TRAIL_LEN := 18


func to_world(screen_pos: Vector2) -> Vector2:
	return (get_global_transform().affine_inverse() * screen_pos) / view_scale


## Zooms the view in on a world point. Zoom 1 shows the whole arena at `origin`.
func set_camera(zoom: float, focus: Vector2) -> void:
	cam_zoom = zoom
	cam_focus = focus
	scale = Vector2.ONE * zoom
	var side := MatchSim.ARENA_SIZE * view_scale
	position = origin + Vector2.ONE * side / 2.0 - focus * view_scale * zoom


func reset_camera() -> void:
	ko_ball = -1
	finisher_amount = 0.0
	set_camera(1.0, Vector2.ONE * MatchSim.ARENA_SIZE / 2.0)


## Where to draw a ball: between its last two sim positions, so motion stays
## smooth when frames fall between sim steps (most visible in slow motion).
## Render-only; the sim never sees it.
func ball_pos(b) -> Vector2:
	if render_alpha >= 1.0 or b.index >= _prev_pos.size():
		return b.pos
	var from: Vector2 = _prev_pos[b.index]
	# A teleport (blink, respawn) snaps rather than sliding across the arena.
	if from.distance_squared_to(b.pos) > b.radius * b.radius:
		return b.pos
	return from.lerp(b.pos, render_alpha)


## Call just before each sim step so ball_pos can blend from here.
func snapshot_positions() -> void:
	_prev_pos.resize(sim.balls.size())
	for b in sim.balls:
		_prev_pos[b.index] = b.pos


func clear_effects() -> void:
	_prev_pos.clear()
	render_alpha = 1.0
	_popups.clear()
	_particles.clear()
	_bursts.clear()
	_rings.clear()
	_flashes.clear()
	_rays.clear()
	_kos.clear()
	_chomps.clear()
	_bolts.clear()
	_novas.clear()
	_fx.clear()
	_rebirths.clear()
	_revives.clear()
	_dot_seen = [[], []]
	_trails = [[], []]
	_wisps.clear()
	_shake = 0.0
	_hit = [0.0, 0.0]
	_squash = [0.0, 0.0]
	_eye_flash = [0.0, 0.0]
	_bumper_flash = 0.0
	_spike_flash = 0.0
	_pole_swap = [0.0, 0.0]
	_banner = 0.0
	_was_overtime = false
	_look = [Vector2(1, -1).normalized(), Vector2(-1, 1).normalized()]
	if sim:
		for b in sim.balls:
			if b.index < _look.size():
				_look[b.index] = b.vel.normalized()
		_fit_slots() # balls past the first two (a Splitter's minis) get their slots back


## Per-ball effect slots for balls past the first two (a 2v2's mates, a
## Splitter's minis).
func _fit_slots() -> void:
	if sim == null:
		return
	while _hit.size() < sim.balls.size():
		var b = sim.balls[_hit.size()]
		_dot_seen.append([])
		_hit.append(0.0)
		_squash.append(0.3)
		_eye_flash.append(0.0)
		_pole_swap.append(0.0)
		_trails.append([])
		_look.append(b.vel.normalized() if b.vel.length() > 0.001 else Vector2.RIGHT)


## The side (0 = you, 1 = foe) ball `i` fights for: its team.
## The tier ball i fights at: from the fight's config (tier ability upgrades),
## else the `tiers` the screen set. Twins share their side's tier.
func _tier_of(i: int) -> int:
	var side: int = sim.balls[i].team if sim and i < sim.balls.size() else i % 2
	if sim:
		var ts: Array = sim.config.get("tiers", [])
		if i < sim.starters and i < ts.size(): # A 2v2's mates have their own tier.
			return int(ts[i])
		if side < ts.size():
			return int(ts[side])
	return int(tiers[side]) if side < tiers.size() else 1


## The side as the viewer sees it (0 = you, 1 = foe).
func _side(i: int) -> int:
	return (sim.balls[i].team if sim and i < sim.balls.size() else i % 2) ^ you_side


## Effect slots for `n` preview balls (the menu's 2v2 shows four).
func _pad_slots(n: int) -> void:
	while _hit.size() < n:
		_dot_seen.append([])
		_hit.append(0.0)
		_squash.append(0.0)
		_eye_flash.append(0.0)
		_pole_swap.append(0.0)
		_trails.append([])
		_look.append(Vector2(1, -1).normalized() if _hit.size() % 2 == 1 else Vector2(-1, 1).normalized())


## Turns the events of the latest sim step into visual effects.
func consume_events(events: Array[Dictionary]) -> void:
	_fit_slots()
	var hitters: Array = [] ## Balls that dealt damage this step, so a heal right after is life steal.
	for e in events:
		match e.type:
			"damage":
				_hit[e.target] = HIT_LIFE
				var col := POP_DAMAGE if e.kind == "contact" else POP_BEAM
				var t := sim.balls[e.target]
				if e.get("crit", false):
					_add_popup(t.pos + Vector2(28, -t.radius - 10), "CRIT -%d" % ceili(e.amount), POP_CRIT, CRIT_POP_SCALE)
					_shake = maxf(_shake, 7.0 * A11y.motion())
					_spawn_particles(t.pos, 8)
				else:
					_add_popup(t.pos + Vector2(28, -t.radius - 10), "-%d" % ceili(e.amount), col)
				if e.get("backstab", false):
					_add_popup(t.pos + Vector2(-30, -t.radius - 52), "BACKSTAB!", POP_BACKSTAB, 1.15)
					_shake = maxf(_shake, 8.0 * A11y.motion())
				var src: int = e.get("source", -1)
				if src >= 0 and src < sim.balls.size() and src != e.target:
					hitters.append(src)
					var a := sim.balls[src]
					if e.kind == "contact" and a.type_id in ["vampire", "munch"]:
						var dir: Vector2 = (t.pos - a.pos).normalized()
						_chomps.append({"pos": e.pos, "dir": dir, "size": a.radius * 0.55, "age": 0.0})
					elif a.type_id == "mammoth" and e.kind == "contact":
						_shake = maxf(_shake, 6.0 * A11y.motion())
						_rings.append({"pos": e.pos, "radius": a.radius * 0.9, "color": RING_COLORS.dirt, "age": 0.0})
						_burst(e.pos, 10, [Color("c9a27e"), Color("e8d5b5")], Vector2(100.0, 260.0), (t.pos - a.pos).normalized(), PI * 0.8)
					elif a.type_id == "juggernaut" and e.kind in ["contact", "slam"]:
						_shake = maxf(_shake, (10.0 if e.kind == "slam" else 7.0) * A11y.motion())
						_rings.append({"pos": e.pos, "radius": a.radius * (1.4 if e.kind == "slam" else 0.9), "color": RING_COLORS.dirt, "age": 0.0})
				if t.type_id == "pinata_titan": # Coins pop out; a crit is a candy shower.
					_burst(e.pos, 14 if e.get("crit", false) else 4, [Color("ffd166"), Color("ffb627")] if not e.get("crit", false) else [Color("ff6fae"), Color("5ce1ff"), Color("7cff9b"), Color("ffd166")],
						Vector2(160.0, 420.0), Vector2.ZERO, TAU, Vector2(4.0, 7.0), 180.0)
					if e.get("crit", false):
						_add_popup(t.pos + Vector2(-60, -t.radius - 60), "CANDY!", Color("ff6fae"), 1.15)
				if t.type_id == "crumb": # Bits of cookie fly off.
					for i in 5:
						_particles.append({"pos": e.pos, "vel": _rand_dir() * _fx_rng.randf_range(90.0, 300.0) + Vector2(0, 120), "age": 0.0, "life": 0.7, "col": Color("c68642"), "size": 5.0})
			"heal":
				var b := sim.balls[e.target]
				_add_popup(b.pos + Vector2(48, -b.radius - 40), "+%d" % ceili(e.amount), POP_HEAL)
				var victim = sim.nearest_foe(b)
				if victim != null and e.target in hitters:
					# Life steal (it just landed a hit): red wisps drawn out of the foe.
					for i in 8:
						_wisps.append({"from": victim.pos + _rand_dir() * victim.radius * 0.5, "to": e.target, "age": -i * 0.03, "life": 0.45})
				else:
					# Healing itself: a green glow swelling out of the ball.
					_rings.append({"pos": b.pos, "radius": b.radius * 1.35, "color": POP_HEAL, "age": 0.0})
					for i in 6:
						_particles.append({"pos": b.pos + _rand_dir() * b.radius * 0.6, "vel": Vector2(_fx_rng.randf_range(-30.0, 30.0), -_fx_rng.randf_range(120.0, 220.0)), "age": 0.0, "life": 0.7, "col": POP_HEAL, "size": 5.0})
			"collide":
				_squash[e.a] = 0.2
				_squash[e.b] = 0.2
				_shake = maxf(_shake, 5.0 * A11y.motion())
				_bursts.append({"pos": e.pos, "age": 0.0, "spark": _cosmetic(0, "spark"), "seed": _fx_rng.randf() * 10.0})
				_spawn_particles(e.pos, 10)
			"flip":
				var m := sim.balls[e.ball]
				for i in 6:
					_particles.append({"pos": m.pos + Vector2(0, -m.radius * 1.3), "vel": _rand_dir() * _fx_rng.randf_range(80.0, 260.0), "age": 0.0, "life": 0.4})
			"pulse", "boom":
				var pk: String = e.get("kind", "")
				if pk == "tide": # Ripple's T5 wave rolling out from the wall.
					_fx.append({"kind": "splash", "pos": e.pos, "radius": e.radius, "age": 0.0, "life": BattleFx.SPLASH_LIFE, "seed": _fx_rng.randf() * TAU})
					_burst(e.pos, 16, [Color("bff8ff"), Color.WHITE, BattleFx.WATER], Vector2(200.0, 460.0), Vector2.ZERO, TAU, Vector2(3.0, 6.0), 80.0)
				elif pk == "sunfire": # Phoenix T5: a flash of sunfire.
					_fx.append({"kind": "sunfire", "pos": e.pos, "radius": e.radius, "age": 0.0, "life": BattleFx.SUNFIRE_LIFE, "seed": _fx_rng.randf() * TAU})
					_burst(e.pos, 22, [BattleFx.SUN, Color("ff8a1f"), Color.WHITE], Vector2(240.0, 520.0), Vector2.ZERO, TAU, Vector2(3.0, 6.0), 60.0)
					_shake = maxf(_shake, 5.0 * A11y.motion())
				elif pk == "honey": # Honey's T5 sting on a stuck foe.
					_add_popup(e.pos + Vector2(-30, -70), "STING!", BattleFx.HONEY)
					_burst(e.pos, 12, [BattleFx.HONEY, Color("ffe08a")], Vector2(80.0, 240.0), Vector2.ZERO, TAU, Vector2(4.0, 7.0))
				if pk == "ping": # Sonar: ripples of sound.
					_fx.append({"kind": "sonar", "pos": e.pos, "radius": e.radius, "age": 0.0, "life": BattleFx.SONAR_LIFE})
				elif pk == "paint": # Painter's paint dries with a splat.
					_burst(e.pos, 14, BattleFx.PAINTS, Vector2(120.0, 320.0), Vector2.ZERO, TAU, Vector2(4.0, 8.0))
					_add_popup(e.pos + Vector2(-30, -70), "SPLAT!", BattleFx.PAINTS[_fx_rng.randi() % 5])
				elif pk == "wind": # Gust's big huff.
					_add_popup(e.pos + Vector2(-46, -90), "WHOOSH!", Color("e8fff0"), 1.1)
					_burst(e.pos, 18, [Color("c7f9cc"), Color("8ac926"), Color("e8fff0")], Vector2(300.0, 600.0), Vector2.ZERO, TAU, Vector2(3.0, 6.0))
				if pk == "candy": # Jawbreaker's sugar blast: sprinkles everywhere.
					_burst(e.pos, 30, [Color("ff5fa2"), Color("ffd23f"), Color("6ee7ff"), Color("a6ff6e"), Color.WHITE], Vector2(180.0, 480.0), Vector2.ZERO, TAU, Vector2(3.0, 5.0))
					_add_popup(e.pos + Vector2(-50, -90), "SUGAR RUSH!", Color("ff9de2"), 1.1)
				elif pk == "stink": # Whiff's cloud blooming.
					_add_popup(e.pos + Vector2(-40, -90), "PEE-YOO!", BattleFx.STINK, 1.15)
					_burst(e.pos, 18, [Color(BattleFx.STINK, 0.8), Color("c8f7a0", 0.7)], Vector2(80.0, 220.0), Vector2.ZERO, TAU, Vector2(8.0, 14.0))
				if pk == "dirt": # Mole bursting up.
					_dirt_spray(e.pos, 20)
					_shake = maxf(_shake, 7.0 * A11y.motion())
				if pk in ["zap", "bigzap"]:
					# Lightning forks out to every foe in reach, inside a crackling ring.
					_bolts.append({"from": e.pos, "radius": e.radius, "age": 0.0, "seed": _fx_rng.randf() * 10.0})
					var team: int = sim.balls[e.ball].team if e.get("ball", -1) >= 0 and e.ball < sim.balls.size() else -1
					var owner_pos: Vector2 = sim.balls[e.ball].pos if team >= 0 else e.pos
					if owner_pos.distance_to(e.pos) > 1.0: # A strike from the sky (Drizzle's thunder).
						_bolts.append({"from": e.pos + Vector2(_fx_rng.randf_range(-60.0, 60.0), -520.0), "to": e.pos, "age": 0.0, "seed": _fx_rng.randf() * 10.0})
					for o in sim.balls:
						if o.alive() and o.team != team and o.pos.distance_to(e.pos) <= e.radius + o.radius:
							_bolts.append({"from": e.pos, "to": o.pos, "age": 0.0, "seed": _fx_rng.randf() * 10.0})
				elif pk == "tick": # Clockwork: a clock face ticks out.
					_fx.append({"kind": "clock", "pos": e.pos, "radius": e.radius, "age": 0.0, "life": BattleFx.CLOCK_LIFE})
				elif pk == "wave": # Leviathan bursts up in a wall of spray.
					_fx.append({"kind": "splash", "pos": e.pos, "radius": e.radius, "age": 0.0, "life": BattleFx.SPLASH_LIFE, "seed": _fx_rng.randf() * TAU})
					for q in 22:
						var dir := Vector2.from_angle(_fx_rng.randf() * TAU)
						_particles.append({"pos": e.pos + dir * 20.0, "vel": dir * _fx_rng.randf_range(200.0, 520.0) + Vector2(0, -150.0), "age": 0.0, "life": _fx_rng.randf_range(0.4, 0.8), "col": Color("bff8ff") if q % 3 else Color.WHITE, "size": _fx_rng.randf_range(3.0, 6.0)})
					_shake = maxf(_shake, 10.0 * A11y.motion())
					_add_popup(e.pos + Vector2(-50, -110), "SPLASH!", BattleFx.WATER, 1.2)
				elif pk == "nova":
					var owner_type: String = sim.balls[e.ball].type_id if e.get("ball", -1) >= 0 and e.ball < sim.balls.size() else ""
					_novas.append({"pos": e.pos, "radius": e.radius, "color": Color("c58bff") if owner_type == "blackhole" else Color("ffd6a5"), "age": 0.0})
				else:
					_rings.append({"pos": e.pos, "radius": e.radius, "color": RING_COLORS.get(e.get("kind", "boom"), BURST), "age": 0.0})
				if e.type == "boom" or e.get("kind", "") in ["nova", "fire", "bigzap", "drum", "hammer", "quake"]:
					_shake = maxf(_shake, 8.0 * A11y.motion())
					_spawn_particles(e.pos, 14)
			"reflect":
				_flashes.append({"from": e.from, "to": e.to, "age": 0.0})
			"egg_crack": # A Brood Queen egg broken before it hatched: more orbs.
				_add_popup(e.pos + Vector2(-44, -50), "CRACK! x%d" % e.cracked, Color("fff1d6"), 1.1)
				_spawn_particles(e.pos, 10)
			"egg_hatch":
				_add_popup(e.pos + Vector2(-30, -50), "PEEP!", Color("ffe066"))
			"glitch_phase": # The Glitch rewrote the rules.
				_add_popup(e.pos + Vector2(-70, -130), {"static": "STATIC!", "warp": "WARP!", "pull": "PULL!"}.get(e.phase, "GLITCH!"), Color("7cff4f"), 1.3)
				_shake = maxf(_shake, 6.0 * A11y.motion())
			"glitch_warp":
				_burst(e.pos, 16, [Color("7cff4f"), Color("ff4fd8")], Vector2(140.0, 380.0))
			"wyrm_shine": # The Prism Wyrm's weak spot moved.
				_rings.append({"pos": e.pos, "radius": 60.0, "color": Color("7af0ff"), "age": 0.0})
			"boss_fizzle": # A stun cancelled the boss's wind-up.
				_add_popup(e.pos + Vector2(-50, -60), "FIZZLE!", POP_SNAP, 1.15)
				_spawn_particles(e.pos, 8)
			"overcharge": # A Legendary Bounce Run boon: every 3rd bump hits double.
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-60, -g.radius - 40), "OVERCHARGE!", POP_SNAP)
				_shake = maxf(_shake, 5.0 * A11y.motion())
			"phase":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-30, -g.radius - 34), "BOO!", POP_SNAP)
			"ambush":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-50, -g.radius - 34), "AMBUSH!", POP_SNAP)
			"copy":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-30, -g.radius - 34), "COPY!", POP_SNAP)
			"shot":
				if e.get("kind", "") == "shell" and e.ball < sim.balls.size() and sim.balls[e.ball].type_id == "mortar":
					var g := sim.balls[e.ball]
					var f = sim.nearest_foe(g)
					var d: Vector2 = (f.pos - g.pos).normalized() if f != null else Vector2.UP
					_burst(g.pos + d * g.radius * 1.3, 10, [Color("9aa0a6", 0.8), Color("d0d4d8", 0.7), BattleFx.BURN], Vector2(60.0, 200.0), d, 1.2, Vector2(6.0, 11.0))
					_shake = maxf(_shake, 4.0 * A11y.motion())
			"split":
				var g := sim.balls[e.ball]
				if e.get("twin", -1) >= 0:
					_fx.append({"kind": "mitosis", "ball": e.ball, "twin": e.twin, "age": 0.0, "life": BattleFx.MITOSIS_LIFE})
				_add_popup(e.pos + Vector2(-34, -g.radius - 40), "SPLIT!", POP_SNAP)
				_rings.append({"pos": e.pos, "radius": g.radius * 2.2, "color": g.def.color, "age": 0.0})
				_spawn_particles(e.pos, 16)
				_squash[g.index] = 0.3
			"revive":
				var g := sim.balls[e.ball]
				_revives[e.ball] = int(_revives.get(e.ball, 0)) + 1
				_add_popup(g.pos + Vector2(-50, -g.radius - 40), "REBORN!" if _revives[e.ball] == 1 else "REBORN AGAIN!", POP_SNAP)
				_rebirths.append({"ball": e.ball, "age": 0.0})
				_shake = maxf(_shake, 9.0 * A11y.motion())
			"shut":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-34, -g.radius - 34), "CLAMP!", POP_SNAP)
			"salvo":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-40, -g.radius - 34), "SALVO!", POP_SNAP)
			"mega":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-60, -g.radius - 46), "MEGA MODE!", POP_CRIT, CRIT_POP_SCALE)
				_shake = maxf(_shake, 8.0 * A11y.motion())
			"shot_pop":
				_spawn_particles(e.pos, 3)
			"orb_lost":
				_spawn_particles(e.pos, 6)
			"yoyo", "fling", "hug", "dive":
				var g := sim.balls[e.ball]
				var words := {"yoyo": "SWING!", "fling": "WALKIES!", "hug": "HUG!", "dive": "DIVE!"}
				var word: String = "THROWN!" if e.type == "fling" and e.has("source") else words[e.type]
				_add_popup(g.pos + Vector2(-40, -g.radius - 34), word, POP_SNAP)
				if e.type == "dive": # Leviathan plunges under.
					_fx.append({"kind": "splash", "pos": g.pos, "radius": g.radius * 1.6, "age": 0.0, "life": BattleFx.SPLASH_LIFE, "seed": 0.0})
			"launch":
				_spawn_particles(e.pos, 4)
			"shielded":
				var g := sim.balls[e.target]
				_add_popup(g.pos + Vector2(28, -g.radius - 10), "0", POP_BEAM)
			"grow":
				# Grow and shrink: a squash pop and a ring at the new size.
				var g := sim.balls[e.ball]
				_squash[e.ball] = maxf(_squash[e.ball], 0.25)
				_rings.append({"pos": g.pos, "radius": g.radius, "color": Color(g.def.color, 0.9).lightened(0.4), "age": 0.0})
			"chomp":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-50, -g.radius - 34), "CHOMP!", POP_SNAP)
				var dir: Vector2 = _look[e.ball] if e.ball < _look.size() else Vector2.RIGHT
				_chomps.append({"pos": g.pos + dir * g.radius * 1.05, "dir": dir, "size": g.radius * 0.8, "age": 0.0})
				_shake = maxf(_shake, 7.0 * A11y.motion())
			"unwind":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-56, -g.radius - 34), "UNWIND!", POP_SNAP)
			"pop":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-30, -g.radius - 34), "POP!", POP_SNAP)
				_spawn_particles(g.pos, 10)
				if g.type_id == "fizz": # A shaken can bursting: a fizzy spray out the back.
					var back: Vector2 = -g.vel.normalized() if g.vel.length() > 0.001 else Vector2.DOWN
					for i in 26:
						var spread := back.rotated(_fx_rng.randf_range(-0.5, 0.5))
						_particles.append({"pos": g.pos + back * g.radius, "vel": spread * _fx_rng.randf_range(250.0, 650.0), "age": 0.0, "life": _fx_rng.randf_range(0.4, 0.8), "col": Color("ffd6ec") if i % 3 else Color.WHITE, "size": _fx_rng.randf_range(3.0, 6.0)})
					_rings.append({"pos": g.pos, "radius": g.radius * 1.6, "color": ZONE_COLORS.fizz, "age": 0.0})
			"stun":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-40, -g.radius - 34), "FROZEN!", FROZEN)
				_spawn_particles(g.pos, 8)
			"wrap":
				var g := sim.balls[e.ball]
				_flashes.append({"from": e.from, "to": e.pos, "age": 0.0})
				_add_popup(g.pos + Vector2(-44, -g.radius - 60), "WRAPPED!", RING_COLORS.confetti)
			"wrap_pop": # The ribbon bursts into confetti.
				var hues := [Color("ff5fa2"), Color("ffd23f"), Color("6ee7ff"), Color("a6ff6e"), Color.WHITE]
				for q in 26:
					var dir := Vector2.from_angle(_fx_rng.randf() * TAU)
					_particles.append({"pos": e.pos, "vel": dir * _fx_rng.randf_range(160.0, 460.0), "age": 0.0, "life": _fx_rng.randf_range(0.5, 0.9), "col": hues[q % hues.size()], "size": _fx_rng.randf_range(3.0, 5.5)})
			"shatter":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-44, -g.radius - 60), "SHATTER!", FROZEN, 1.2)
				_shake = maxf(_shake, 9.0 * A11y.motion())
				for q in 20: # Ice chunks fly off.
					var dir := Vector2.from_angle(_fx_rng.randf() * TAU)
					_particles.append({"pos": e.pos + dir * g.radius * 0.6, "vel": dir * _fx_rng.randf_range(220.0, 560.0), "age": 0.0, "life": _fx_rng.randf_range(0.4, 0.8), "col": Color("d9f6ff") if q % 2 else Color("6fb7ff"), "size": _fx_rng.randf_range(4.0, 8.0)})
			"storm":
				var m := sim.balls[e.ball]
				if e.sparks >= 3:
					_add_popup(m.pos + Vector2(-34, -m.radius - 34), "ZAP!", RING_COLORS.thunder)
				# Thunderbird calls lightning down on the foe, forking to Thunderbird too.
				_bolts.append({"from": e.pos + Vector2(_fx_rng.randf_range(-80.0, 80.0), -560.0), "to": e.pos, "age": 0.0, "seed": _fx_rng.randf() * 10.0})
				_bolts.append({"from": m.pos, "to": e.pos, "age": 0.0, "seed": _fx_rng.randf() * 10.0})
				_bolts.append({"from": e.pos, "radius": 90.0, "age": 0.0, "seed": _fx_rng.randf() * 10.0})
				_shake = maxf(_shake, 6.0 * A11y.motion())
			"stack":
				# Stacks and forms: a little squash per stack gained.
				if e.up:
					_squash[e.ball] = maxf(_squash[e.ball], 0.15)
			"burp", "breath", "shout", "roar":
				var g := sim.balls[e.ball]
				if e.type == "breath": # A gout of flame down the cone.
					_burst(e.pos + e.dir * g.radius, 26, [BattleFx.BURN, BattleFx.BURN_CORE, Color("ff4d1f")], Vector2(300.0, 700.0), e.dir, 0.7, Vector2(4.0, 8.0))
				elif e.type == "roar" and g.type_id == "yeti": # The avalanche rolls out.
					_fx.append({"kind": "avalanche", "pos": e.pos, "radius": g.def.get("roar_radius", 200.0), "age": 0.0, "life": BattleFx.AVALANCHE_LIFE, "seed": _fx_rng.randf() * TAU})
					_burst(e.pos, 28, [BattleFx.SNOW, Color("cfeaff")], Vector2(220.0, 560.0), Vector2.ZERO, TAU, Vector2(4.0, 9.0), 60.0)
				var call: String = {"burp": "BURP!", "breath": "FWOOSH!", "shout": "HOO!", "roar": "ROAR!"}[e.type]
				_add_popup(g.pos + Vector2(-48, -g.radius - 34), call, POP_SNAP)
				_shake = maxf(_shake, (8.0 if e.type == "roar" else 5.0) * A11y.motion())
			"mode":
				var g := sim.balls[e.ball]
				var names: Array = MODE_NAMES.get(g.type_id, [])
				if e.mode < names.size():
					_add_popup(g.pos + Vector2(-44, -g.radius - 34), names[e.mode], MODE_COLORS[g.type_id][e.mode])
				if g.type_id == "eclipse": # The moon slides over the sun, or off it.
					_fx.append({"kind": "eclipse", "ball": e.ball, "moon": int(e.mode) == 1, "age": 0.0, "life": BattleFx.FLIP_LIFE})
			"bubble_pop":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-30, -g.radius - 34), "POP!", Color("9ff3f6"))
				_rings.append({"pos": g.pos, "radius": g.radius * 1.3, "color": Color("9ff3f6"), "age": 0.0})
				_spawn_particles(g.pos, 12)
			"spike":
				if e.ball < 2:
					_grow_flash[e.ball] = 0.18
				_spawn_particles(sim.balls[e.ball].pos, 4)
			"teleport":
				var g := sim.balls[e.ball]
				_flashes.append({"from": e.from, "to": e.to, "age": 0.0})
				_spawn_particles(e.from, 10)
				_spawn_particles(e.to, 10)
				_bursts.append({"pos": e.to, "age": 0.0, "spark": {}, "seed": 0.0})
				_squash[g.index] = 0.25
			"honey_lob": # Honey T5 flings a glob of honey under the foe.
				_fx.append({"kind": "honey_lob", "from": e.from, "pos": e.pos, "age": 0.0, "life": BattleFx.HONEY_LOB_LIFE})
			"heard": # Sonar T5 has heard the foe: a sound mark on it.
				_add_popup(e.pos + Vector2(-34, -80), "HEARD!", BattleFx.SONAR)
				_fx.append({"kind": "sonar", "pos": e.pos, "radius": 90.0, "age": 0.0, "life": BattleFx.SONAR_LIFE})
			"yank":
				_fx.append({"kind": "hook", "ball": e.ball, "target": e.target, "age": 0.0, "life": BattleFx.HOOK_LIFE})
				if e.big:
					var g := sim.balls[e.ball]
					_add_popup(g.pos + Vector2(-40, -g.radius - 34), "REEL IN!", POP_SNAP)
			"charge":
				_squash[e.ball] = maxf(_squash[e.ball], 0.2)
			"mark":
				var t := sim.balls[e.target]
				_add_popup(t.pos + Vector2(-30, -t.radius - 34), "MARKED", MARK)
			"pounce", "lance", "ping_crit", "gear_slam", "tilt":
				var g := sim.balls[e.ball]
				if e.type == "gear_slam":
					_rings.append({"pos": e.pos, "radius": g.radius * 1.4, "color": Color("ff5a3d"), "age": 0.0})
					_burst(e.pos, 16, [BattleFx.COG, Color("ffd23f"), Color("ff5a3d")], Vector2(200.0, 520.0), Vector2.ZERO, TAU, Vector2(4.0, 7.0))
				var call: String = {"pounce": "POUNCE!", "lance": "CHARGE!", "ping_crit": "ECHO HIT!", "gear_slam": "TOP GEAR!", "tilt": "TILT!"}[e.type]
				_add_popup(g.pos + Vector2(-50, -g.radius - 40), call, POP_SNAP, 1.15)
				_shake = maxf(_shake, 8.0 * A11y.motion())
			"ding":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-30, -g.radius - 34), "DING x%d" % e.lit, POP_SNAP)
			"bow":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-30, -g.radius - 34), "BOW!", POP_SNAP)
			"dig":
				_rings.append({"pos": e.pos, "radius": sim.balls[e.ball].radius * 1.2, "color": RING_COLORS.dirt, "age": 0.0})
				_dirt_spray(e.pos, 14)
			"relight": # Flicker's candle bursts back into flame.
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-40, -g.radius - 40), "RELIT!", BattleFx.BURN)
				for q in 24:
					var dir := Vector2.from_angle(_fx_rng.randf() * TAU)
					_particles.append({"pos": e.pos + dir * g.radius * 0.5, "vel": dir * _fx_rng.randf_range(140.0, 380.0) + Vector2(0, -160.0), "age": 0.0, "life": _fx_rng.randf_range(0.4, 0.8), "col": BattleFx.BURN_CORE if q % 3 == 0 else BattleFx.BURN, "size": _fx_rng.randf_range(3.0, 7.0)})
				_shake = maxf(_shake, 6.0 * A11y.motion())
			"pucker": # Pucker's full sour splashes the foe.
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-50, -g.radius - 50), "PUCKER!", BattleFx.SOUR, 1.15)
				for q in 22:
					var dir := Vector2.from_angle(_fx_rng.randf() * TAU)
					_particles.append({"pos": e.pos, "vel": dir * _fx_rng.randf_range(160.0, 420.0), "age": 0.0, "life": _fx_rng.randf_range(0.4, 0.7), "col": BattleFx.SOUR if q % 2 else Color("9ef01a"), "size": _fx_rng.randf_range(4.0, 7.0)})
			"spike_burst": # Spiker fires its ring of spikes.
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-46, -g.radius - 40), "SPIKES!", SPIKE)
				_rings.append({"pos": e.pos, "radius": g.radius * 1.8, "color": SPIKE, "age": 0.0})
			"snap":
				var m := sim.balls[e.ball]
				_add_popup(m.pos + Vector2(-34, -m.radius - 34), "SNAP!", POP_SNAP)
				_shake = maxf(_shake, 9.0 * A11y.motion())
			"bounce":
				_squash[e.ball] = maxf(_squash[e.ball], 0.15)
				if not A11y.reduced_motion:
					_eye_flash[e.ball] = 0.3
			"bumper":
				_bumper_flash = BUMPER_FLASH_LIFE
				_spawn_particles(e.pos, 6)
			"lava":
				_spawn_particles(e.pos, 3)
				_rings.append({"pos": e.pos, "radius": 40.0, "color": LAVA, "age": 0.0})
			"portal":
				_rings.append({"pos": e.from, "radius": 70.0, "color": PORTAL, "age": 0.0})
				_rings.append({"pos": e.to, "radius": 70.0, "color": PORTAL, "age": 0.0})
				_spawn_particles(e.to, 6)
			"spike":
				_spike_flash = BUMPER_FLASH_LIFE
				_spawn_particles(e.pos, 5)
				_rings.append({"pos": e.pos, "radius": 34.0, "color": SPIKE, "age": 0.0})
			"rays":
				_rays.append({"segments": e.segments, "kind": e.kind, "age": 0.0, "life": 0.6 if e.kind == "disco" else RAY_LIFE})
			"piece":
				if e.kind != "illusion":
					_spawn_particles(e.pos, 4)
			"lash":
				var t := sim.balls[e.target]
				_add_popup(t.pos + Vector2(-40, -t.radius - 34), "LASHED!", POP_SNAP)
			"root":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-46, -g.radius - 40), "ROOTED!", POP_HEAL)
			"rewind":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-46, -g.radius - 40), "REWIND!", BattleFx.CLOCK)
				_fx.append({"kind": "rewind", "from": e.from, "pos": e.pos, "ball": e.ball, "age": 0.0, "life": 0.9})
			"swap":
				_flashes.append({"from": e.from, "to": e.pos, "age": 0.0})
				_spawn_particles(e.pos, 10)
			"spin":
				var g := sim.balls[e.ball]
				var text: String = "JACKPOT!" if e.prizes.size() > 1 else PRIZE_TEXT.get(e.prizes[0], "")
				_add_popup(g.pos + Vector2(-40, -g.radius - 40), text, POP_CRIT if e.prizes.size() > 1 else POP_SNAP, 1.2 if e.prizes.size() > 1 else 1.0)
			"end":
				for b in sim.balls:
					if not b.alive() and b.def.get("boss", false):
						_fx.append({"kind": "boss_death", "id": b.def.id, "pos": b.pos, "r": b.radius, "age": 0.0, "life": BossArt.DEATH_LIFE})
						_burst(b.pos, 40, BossArt.DEATH_COLORS.get(b.def.id, [Color.WHITE]), Vector2(200.0, 620.0), Vector2.ZERO, TAU, Vector2(4.0, 9.0))
						_add_popup(b.pos + Vector2(-90, -b.radius - 50), "BOSS DOWN!", POP_CRIT, 1.5)
						_shake = 18.0 * A11y.motion()
						continue
					if not b.alive():
						_spawn_particles(b.pos, 36)
						_shake = 10.0 * A11y.motion()
						var ko := _cosmetic(1 - _side(b.index), "ko")
						if not ko.is_empty():
							_kos.append({"pos": b.pos, "r": b.radius, "item": ko, "age": 0.0, "seed": _fx_rng.randf() * 10.0})
	# Name a damage-over-time the moment it lands: BURN!, POISON!, BLEED!
	for b in sim.balls:
		if b.index >= sim.starters or b.index >= _dot_seen.size():
			continue
		var kinds := BattleFx.dot_kinds(sim, b)
		for k in kinds:
			if not k in _dot_seen[b.index]:
				_add_popup(b.pos + Vector2(-44, -b.radius - 64), BattleFx.DOT_WORDS[k], BattleFx.DOT_COLORS[k], 1.1)
		_dot_seen[b.index] = kinds


func advance_effects(delta: float) -> void:
	_time += delta
	_ko_age = _ko_age + delta if ko_ball >= 0 else 0.0
	_shake = maxf(0.0, _shake - delta * 30.0)
	_banner = maxf(0.0, _banner - delta)
	if sim:
		# Visual twin of the overtime sound cue.
		var ot := sim.in_overtime()
		if ot and not _was_overtime and A11y.sound_cues:
			_banner = BANNER_LIFE
		_was_overtime = ot
	_fit_slots()
	for i in _hit.size():
		_hit[i] = maxf(0.0, _hit[i] - delta)
		_squash[i] = maxf(0.0, _squash[i] - delta)
		_eye_flash[i] = maxf(0.0, _eye_flash[i] - delta)
	_bumper_flash = maxf(0.0, _bumper_flash - delta)
	_spike_flash = maxf(0.0, _spike_flash - delta)
	if sim:
		for b in sim.balls:
			_pole_swap[b.index] = move_toward(_pole_swap[b.index], 0.0 if b.state.get("pulling", true) else 1.0, delta / 0.25)
		for b in sim.balls:
			var trail: Array = _trails[b.index]
			if b.alive():
				trail.append(b.pos)
			while trail.size() > (TRAIL_LEN if b.alive() else 0):
				trail.pop_front()
			if b.vel.length() > 0.001:
				_look[b.index] = _look[b.index].lerp(b.vel.normalized(), clampf(delta * 9.0, 0.0, 1.0)).normalized()
	for p in _popups:
		p.age += delta
	_popups = _popups.filter(func(p): return p.age < POPUP_LIFE)
	for p in _particles:
		p.age += delta
		p.pos += p.vel * delta
		p.vel *= pow(0.96, delta * 60.0)
	_particles = _particles.filter(func(p): return p.age < p.life)
	for k in _bursts:
		k.age += delta
	_bursts = _bursts.filter(func(k): return k.age < (CosmeticArt.SPARK_LIFE if k.get("spark") else BURST_LIFE))
	for k in _kos:
		k.age += delta
	for k in _chomps:
		k.age += delta
	_chomps = _chomps.filter(func(k): return k.age < BattleFx.CHOMP_LIFE)
	for k in _bolts:
		k.age += delta
	_bolts = _bolts.filter(func(k): return k.age < BattleFx.BOLT_LIFE)
	for k in _novas:
		k.age += delta
	_novas = _novas.filter(func(k): return k.age < BattleFx.NOVA_LIFE)
	for k in _fx:
		k.age += delta
	_fx = _fx.filter(func(k): return k.age < k.life)
	for k in _rebirths:
		k.age += delta
	_rebirths = _rebirths.filter(func(k): return k.age < BattleFx.REBIRTH_LIFE)
	for i in 2:
		_grow_flash[i] = maxf(0.0, _grow_flash[i] - delta)
	_kos = _kos.filter(func(k): return k.age < CosmeticArt.KO_LIFE)
	for w in _wisps:
		w.age += delta
	_wisps = _wisps.filter(func(w): return w.age < w.life)
	for k in _rings:
		k.age += delta
	_rings = _rings.filter(func(k): return k.age < RING_LIFE)
	for k in _flashes:
		k.age += delta
	_flashes = _flashes.filter(func(k): return k.age < 0.25)
	for k in _rays:
		k.age += delta
	_rays = _rays.filter(func(k): return k.age < k.life)
	queue_redraw()


func _add_popup(pos: Vector2, text: String, color: Color, size := 1.0) -> void:
	_popups.append({"pos": pos, "text": text, "color": color, "age": 0.0, "size": size})


func _spawn_particles(pos: Vector2, count: int) -> void:
	for i in count:
		_particles.append({"pos": pos, "vel": _rand_dir() * _fx_rng.randf_range(120.0, 460.0), "age": 0.0, "life": _fx_rng.randf_range(0.5, 1.1)})


## A coloured burst: n particles from `at`, spreading `cone` radians round `dir`.
func _burst(at: Vector2, n: int, cols: Array, speed: Vector2, dir := Vector2.ZERO, cone := TAU, size := Vector2(3.0, 6.0), lift := 0.0) -> void:
	for q in n:
		var d := Vector2.from_angle(_fx_rng.randf() * TAU) if dir == Vector2.ZERO else dir.rotated(_fx_rng.randf_range(-cone / 2.0, cone / 2.0))
		_particles.append({"pos": at, "vel": d * _fx_rng.randf_range(speed.x, speed.y) + Vector2(0, -lift), "age": 0.0, "life": _fx_rng.randf_range(0.4, 0.8), "col": cols[q % cols.size()], "size": _fx_rng.randf_range(size.x, size.y)})


func _rand_dir() -> Vector2:
	return Vector2.from_angle(_fx_rng.randf() * TAU)


# --- Drawing ----------------------------------------------------------------

func _draw() -> void:
	_fit_slots()
	var s := view_scale
	var shake := Vector2(_fx_rng.randf_range(-1, 1), _fx_rng.randf_range(-1, 1)) * _shake if _shake > 0.0 else Vector2.ZERO
	draw_set_transform(shake)
	var full := Rect2(Vector2.ZERO, Vector2.ONE * MatchSim.ARENA_SIZE * s)
	# The menu has no fight yet; a fresh sim gives the arena's starting shape.
	var shape: MatchSim = sim if sim else MatchSim.new({"arena": preview_arena})
	var r := shape.arena_rect()
	var arena := Rect2(r.position * s, r.size * s)
	var theme := ArenaTheme.get_theme(shape.arena_id)
	_pillar = Color(theme.pillar)
	var outline := shape.arena_outline()
	for i in outline.size():
		outline[i] *= s
	_paint_floor_if_changed(shape, outline)
	_floor.position = shake
	_draw_ambient(theme.ambient, arena, PackedVector2Array() if outline.size() == 4 else outline)
	_draw_floors(shape.floors())
	_draw_wells(shape.wells())
	_draw_spike_walls(shape)
	_draw_obstacles(shape.obstacles())

	if sim == null:
		var n := preview_types.size()
		var starts: Array = MatchSim.start_positions(n)
		_pad_slots(n)
		for i in n:
			var def := Modifiers.apply_to_def(BallDefs.get_def(preview_types[i]), preview_modifier)
			_draw_critter(i, def, starts[i] * s, def.radius * s, def.hp, def.hp, shake)
		_tag_at.clear()
		for i in n:
			var def := BallDefs.get_def(preview_types[i])
			_draw_overlay(i, def, starts[i] * s, def.radius * s, def.hp, def.hp, shake)
		return

	for z in sim.zones:
		_draw_zone(z, s)
	for p in sim.pieces:
		_draw_piece(p, s, shake)
	for b in sim.balls:
		_draw_lash(b, s)
		_draw_prize_tells(b, s)

	for shot in sim.shots:
		_draw_shot(shot, s)
	for t in sim.tethers:
		if sim.balls[t.owner].type_id == "gumdrop":
			BattleFx.draw_gum_string(self, sim.balls[t.owner].pos * s, sim.balls[t.target].pos * s, _time)
		else:
			_draw_string(sim.balls[t.owner].pos * s, sim.balls[t.target].pos * s)

	var bi := 0
	for beam in sim.beams:
		var k := beam.strength()
		var a: Vector2 = beam.a * s
		var b: Vector2 = beam.b * s
		var col := BEAM
		if sim.balls[beam.owner].def.has("fire_count"): # Drako's fireballs.
			col = ZONE_COLORS.fire
		elif sim.balls[beam.owner].def.has("beam_color"):
			col = Color(sim.balls[beam.owner].def.beam_color)
		elif sim.balls[beam.owner].def.get("beam_rainbow", 0):
			col = Color.from_hsv(fmod(bi * 0.14 + _time * 0.5, 1.0), 0.7, 1.0)
		bi += 1
		if sim.balls[beam.owner].type_id == "comet": # A shooting star.
			BattleFx.draw_shooting_star(self, a, b, k, _time)
			continue
		if sim.balls[beam.owner].type_id == "zigzag": # Forked lightning along its path.
			BattleFx.draw_bolt(self, a, b, 0.05, floorf(_time * 18.0) + bi, BattleFx.ZIG)
			continue
		if sim.balls[beam.owner].type_id == "drako": # A stream of fireballs.
			BattleFx.draw_fireballs(self, a, b, k, _time, 12.0 * s * 1.6)
			continue
		if sim.balls[beam.owner].type_id == "zapper": # A crackling arc.
			BattleFx.draw_bolt(self, a, b, 0.05, floorf(_time * 20.0) + bi, Color("c9a6ff"))
			continue
		if sim.balls[beam.owner].type_id == "beacon": # A lighthouse cone, not a laser.
			BattleFx.draw_cone(self, a, b, k, 10.0 * s * 3.0, 90.0 * s * 3.0)
		draw_line(a, b, Color(col, 0.18 * k), 14.0, true)
		draw_line(a, b, Color(col, 0.35 * k), 7.0, true)
		draw_line(a, b, Color(col, 0.9 * k), 3.5, true)
		draw_line(a, b, Color("e6f7ff", k), 1.4, true)

	for b in sim.balls:
		if not b.alive():
			continue
		if b.def.has("field_range"):
			_draw_field(b, s)
		if b.def.has("pull_range"):
			_draw_inflow(ball_pos(b) * s, b.radius * s, b.def.pull_range * s, Color("8f7bff"), 0.18)
		if b.def.has("wind_range"):
			var huffing: bool = sim.tick < int(b.state.get("huff_until", -1))
			_draw_outflow(ball_pos(b) * s, b.radius * s, b.def.wind_range * s, ZONE_COLORS.stink.lightened(0.5), 0.5 if huffing else 0.2, 3.0 if huffing else 0.8)
			BattleFx.draw_gusts(self, ball_pos(b) * s, b.radius * s, b.def.wind_range * s, _time, huffing)
		if b.state.get("collapsing", false):
			_draw_inflow(ball_pos(b) * s, b.radius * s, b.def.collapse_range * s, Color("c58bff"), 0.45)
		if sim.tick < int(b.state.get("dive_until", -1)):
			_draw_dive(b, s)
		for item in Abilities.orb_items(sim, b):
			_draw_orb(b, item, s)

	for k in _rings:
		var t: float = k.age / RING_LIFE
		Dot.arc(self, k.pos * s, k.radius * s * (0.3 + 0.7 * sqrt(t)), 0.0, TAU, 64, Color(k.color, 0.8 * (1.0 - t)), 6.0 * (1.0 - t) + 1.0, true)
	for k in _rays:
		var t: float = k.age / k.life
		var col: Color = RAY_COLORS.get(k.kind, BEAM)
		if k.kind == "shard": # Glacia's shards fly inward as crystals.
			for i in k.segments.size():
				BattleFx.draw_shard(self, k.segments[i][0] * s, k.segments[i][1] * s, minf(1.0, t * 1.8), 11.0)
			continue
		for i in k.segments.size():
			if k.kind == "disco":
				col = Color.from_hsv(fmod(i * 0.13 + _time * 0.6, 1.0), 0.55, 1.0)
			var a: Vector2 = k.segments[i][0] * s
			var b: Vector2 = k.segments[i][1] * s
			draw_line(a, b, Color(col, 0.3 * (1.0 - t)), 10.0, true)
			draw_line(a, b, Color(col, 0.95 * (1.0 - t)), 3.0, true)
	for k in _flashes:
		var t: float = k.age / 0.25
		draw_line(k.from * s, k.to * s, Color(Color.from_hsv(fmod(_time, 1.0), 0.5, 1.0), 0.9 * (1.0 - t)), 3.0, true)

	for b in sim.balls:
		var trail := _cosmetic(_side(b.index), "trail")
		if not trail.is_empty():
			CosmeticArt.draw_trail(self, trail, _trails[b.index].map(func(p): return p * s), b.radius * s, _time)

	for k in _bursts:
		if k.get("spark"):
			CosmeticArt.draw_spark(self, k.spark, k.pos * s, k.age / CosmeticArt.SPARK_LIFE, 1.0, k.get("seed", 0.0))
			continue
		var t: float = k.age / BURST_LIFE
		var grow := 70.0 if not A11y.reduced_motion else 25.0
		_star(k.pos * s, 10.0 + t * grow, 5.0 + t * grow * 0.43, 8, Color(BURST, 1.0 - t))

	if aim_dir != Vector2.ZERO:
		var b := sim.balls[you_side]
		for i in 12:
			Dot.circle(self, b.pos * s + aim_dir * (b.radius + 40.0 + i * 38.0) * s, 5.0, Color(TEAM_COLORS[0], 1.0 - i / 12.0))

	if ghost_dir != Vector2.ZERO:
		_ghost_arrow(sim.balls[you_side], s)

	for w in _wisps:
		if w.age < 0.0:
			continue
		var t: float = w.age / w.life
		var target: Vector2 = ball_pos(sim.balls[w.to])
		var p: Vector2 = w.from.lerp(target, t * t)
		Dot.circle(self, p * s, 6.0 * (1.0 - t) + 2.0, Color(1.0, 0.2, 0.35, 0.8 * (1.0 - t)))

	for b in sim.balls:
		if not b.alive():
			continue
		if b.type_id == "yoyo" and sim.tick < int(b.state.get("swing_until", -1)) and b.state.has("anchor"):
			BattleFx.draw_swing(self, b.state.anchor * s, ball_pos(b) * s, b.radius * s, b.vel, _time)
		if b.def.has("field_range") and b.state.get("pulling", false):
			# Flux pulling: static zips out to the foes it's dragging in.
			for o in sim.balls:
				if o.alive() and o.team != b.team and o.pos.distance_to(b.pos) <= b.def.field_range + o.radius:
					var from: Vector2 = ball_pos(b) + (o.pos - b.pos).normalized() * b.radius
					BattleFx.draw_bolt(self, from * s, ball_pos(o) * s, 0.12, float(o.index) + floorf(_time * 14.0), Color("8fb8ff"))
	for b in sim.balls:
		if b.alive() and b.charge_ticks == 0:
			var base_speed: float = b.base.get("speed", b.def.get("speed", b.speed))
			if base_speed > 0.0 and b.type_id in SWIMMERS:
				BattleFx.draw_bubble_trail(self, ball_pos(b) * s, b.radius * s, b.vel, b.vel.length() / base_speed, _time)
			elif base_speed > 0.0:
				BattleFx.draw_speed_blur(self, Color(b.def.color), ball_pos(b) * s, b.radius * s, b.vel, b.vel.length() / base_speed, _time)
	if sim.boss != null and sim.boss.def.id == "prism_wyrm" and sim.boss.alive():
		_draw_wyrm_spine(sim.boss, s)
	for b in sim.balls:
		if b.alive() and b.type_id == "leviathan" and sim.tick < int(b.state.get("dive_until", -1)):
			BattleFx.draw_fin(self, ball_pos(b) * s, b.radius * s, b.vel, _time)
		elif b.alive() and b.state.get("digging", false) and sim.tick < int(b.state.get("phase_until", -1)):
			BattleFx.draw_burrow(self, ball_pos(b) * s, b.radius * s, b.vel, _time)
		elif b.alive():
			var tier := _tier_of(b.index)
			if tier >= 3: # Higher tiers glow; T5 blazes gold.
				BattleFx.draw_tier_aura(self, ball_pos(b) * s, b.radius * s, tier, Color(b.def.color), _time + b.index)
				if tier >= 5:
					BattleFx.draw_ascend_trail(self, ball_pos(b) * s, b.radius * s, b.vel, _time + b.index)
			_draw_critter(b.index, b.def, ball_pos(b) * s, b.radius * s, b.hp, b.max_hp, shake)
			_draw_status(b, s)
		elif b.index == ko_ball:
			_draw_critter(b.index, b.def, ball_pos(b) * s, b.radius * s, 0.0, b.max_hp, shake, true)

	for p in _particles:
		var a: float = 1.0 - p.age / p.life
		var pc: Color = p.get("col", Color.WHITE)
		var ps: float = p.get("size", 2.0)
		Dot.circle(self, p.pos * s, ps * 2.0, Color(pc, a * 0.3))
		Dot.circle(self, p.pos * s, ps, Color(pc, a))
	for k in _chomps:
		BattleFx.draw_chomp(self, k.pos * s, k.dir, k.size * s, k.age)
	for k in _novas:
		BattleFx.draw_nova(self, k.pos * s, k.radius * s, k.age, k.color)
	for k in _fx:
		_draw_fx(k, s)
	for k in _rebirths:
		if k.ball < sim.balls.size():
			var g := sim.balls[k.ball]
			BattleFx.draw_rebirth(self, ball_pos(g) * s, g.radius * s, k.age, _time)
	for k in _bolts:
		if k.has("to"):
			BattleFx.draw_bolt(self, k.from * s, k.to * s, k.age, k.seed)
		else:
			BattleFx.draw_zap_ring(self, k.from * s, k.radius * s, k.age, k.seed)

	for k in _kos:
		CosmeticArt.draw_ko(self, k.item, k.pos * s, k.r * s, k.age / CosmeticArt.KO_LIFE, k.seed)

	# Readability layer: team rings, tags and HP badges sit on top of every
	# cosmetic (design/monetisation.md §1 rule 3).
	_place_tags(s, ko_ball)
	for b in sim.balls:
		if b.alive() or b.index == ko_ball:
			_draw_overlay(b.index, b.def, ball_pos(b) * s, b.radius * s, b.hp, b.max_hp, shake)

	for p in _popups:
		var t: float = p.age / POPUP_LIFE
		var pos: Vector2 = p.pos * s + Vector2(0, -40.0 * t)
		var rise := 40.0 if not A11y.reduced_motion else 16.0
		var grow: float = p.size
		if grow > 1.0 and not A11y.reduced_motion:
			grow *= 1.0 + 0.3 * maxf(0.0, 1.0 - t * 6.0) ## A quick punch-in on big pops.
		_text_centered(pos + Vector2(0, (40.0 - rise) * t), p.text, roundi(A11y.font(26) * grow), Color(p.color, 1.0 - t * t), 6)

	if _banner > 0.0:
		_draw_banner(full)


# --- Floor layer -------------------------------------------------------------

## The arena floor (fill, glow pools, grid and border) only changes when the
## arena's shape or the overtime colour does, so it lives on its own canvas
## item that keeps its drawing between frames instead of being rebuilt every
## frame. Ambient motion and everything on top still draw each frame.
class _FloorLayer extends Node2D:
	func _draw() -> void:
		get_parent()._paint_floor(self)


var _floor: Node2D
var _floor_key := []
var _floor_shape: MatchSim
var _floor_outline := PackedVector2Array()
var _cv: CanvasItem = self ## Where the shared draw helpers draw: this node or the floor layer.


func _paint_floor_if_changed(shape: MatchSim, outline: PackedVector2Array) -> void:
	if _floor == null:
		_floor = _FloorLayer.new()
		_floor.show_behind_parent = true
		add_child(_floor)
	var key := [shape.arena_id, outline, shape.in_overtime(), view_scale, shape.arena_scale()]
	_floor_shape = shape
	_floor_outline = outline
	if key != _floor_key:
		_floor_key = key
		_floor.queue_redraw()


func _paint_floor(cv: CanvasItem) -> void:
	if _floor_shape == null:
		return
	_cv = cv
	var s := view_scale
	var shape := _floor_shape
	var full := Rect2(Vector2.ZERO, Vector2.ONE * MatchSim.ARENA_SIZE * s)
	var r := shape.arena_rect()
	var arena := Rect2(r.position * s, r.size * s)
	var overtime := shape.in_overtime()
	if overtime:
		_rounded_rect(full, 14.0, Color(0.35, 0.05, 0.12, 0.35))
	var theme := ArenaTheme.get_theme(shape.arena_id)
	var border := OVERTIME_BORDER if overtime else Color(theme.border)
	var fill := Color(theme.fill)
	_grid = Color(Color(theme.grid), 0.08)
	var outline := _floor_outline
	if outline.size() == 4:
		_rounded_rect(arena, 14.0, fill)
		_draw_glows(theme, shape, PackedVector2Array())
		_draw_grid(arena)
		for i in 4:
			_rounded_rect_outline(arena.grow(i * 2.0), 14.0 + i * 2.0, Color(border, 0.22 - i * 0.05), 4.0)
		_rounded_rect_outline(arena, 14.0, border, 2.5)
	else:
		Dot.poly(cv, outline, fill)
		_draw_glows(theme, shape, outline)
		_draw_grid(arena, outline)
		var closed := outline.duplicate()
		closed.append(outline[0])
		for i in 4:
			Dot.pline(cv, closed, Color(border, 0.22 - i * 0.05), 4.0 + i * 4.0, true)
		Dot.pline(cv, closed, border, 2.5, true)
	_cv = self

## OVERTIME call-out across the arena, so the cue reads with the sound off.
func _draw_banner(full: Rect2) -> void:
	var t := 1.0 - _banner / BANNER_LIFE
	var a := clampf(_banner / 0.4, 0.0, 1.0)
	var pop := 1.0 if A11y.reduced_motion else 1.0 + 0.25 * maxf(0.0, 1.0 - t * 5.0)
	var c := full.get_center() - Vector2(0, full.size.y * 0.3)
	var h := 64.0 * pop
	_rounded_rect(Rect2(c.x - full.size.x * 0.36, c.y - h / 2.0, full.size.x * 0.72, h), h / 2.0, Color(0.1, 0.02, 0.08, 0.8 * a))
	_text_centered(c, "OVERTIME!", roundi(A11y.font(36) * pop), Color(OVERTIME_BORDER, a), 6)

	if finisher_amount > 0.0:
		_draw_finisher_frame()


## Letterbox bars and, once the blow lands, a K.O. banner. Drawn at screen
## size whatever the zoom, over the part of the arena in view.
func _draw_finisher_frame() -> void:
	var s := view_scale
	var half := MatchSim.ARENA_SIZE * s / (2.0 * cam_zoom)
	var c := cam_focus * s
	var view := Rect2(c - Vector2(half, half), Vector2(half, half) * 2.0)
	var bar := view.size.y * 0.09 * finisher_amount
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(view.position, Vector2(view.size.x, bar)), Color(0, 0, 0, 0.85))
	draw_rect(Rect2(Vector2(view.position.x, view.end.y - bar), Vector2(view.size.x, bar)), Color(0, 0, 0, 0.85))
	if ko_ball < 0:
		return
	draw_set_transform(c, 0.0, Vector2.ONE / cam_zoom)
	var pop := minf(1.0, _ko_age / 0.18)
	var size := roundi(lerpf(150.0, 96.0, pop) * view_scale / 0.68)
	_text_centered(Vector2(0, -half * cam_zoom * 0.7), "K.O.!", size, Color(BURST, pop), 14)
	draw_set_transform(Vector2.ZERO)


func _ghost_arrow(b, s: float) -> void:
	var pulse := 0.45 + 0.35 * sin(_time * 4.0)
	var col := Color(1, 1, 1, pulse)
	var from: Vector2 = b.pos + ghost_dir * (b.radius + 30.0)
	var to: Vector2 = b.pos + ghost_dir * (b.radius + 330.0)
	var dash := 0.0
	while dash < 260.0:
		draw_line((from + ghost_dir * dash) * s, (from + ghost_dir * minf(dash + 22.0, 270.0)) * s, col, 6.0, true)
		dash += 38.0
	var side := ghost_dir.orthogonal()
	Dot.poly(self, PackedVector2Array([to * s, (to - ghost_dir * 46.0 + side * 30.0) * s, (to - ghost_dir * 46.0 - side * 30.0) * s]), col)


## Grid lines across `r`, clipped to the convex `clip` outline when given.
func _draw_grid(r: Rect2, clip := PackedVector2Array()) -> void:
	var step := 80.0 * view_scale
	var x := r.position.x + step
	while x < r.end.x - 1.0:
		_grid_line(Vector2(x, r.position.y), Vector2(x, r.end.y), clip)
		x += step
	var y := r.position.y + step
	while y < r.end.y - 1.0:
		_grid_line(Vector2(r.position.x, y), Vector2(r.end.x, y), clip)
		y += step


func _grid_line(a: Vector2, b: Vector2, clip: PackedVector2Array) -> void:
	if clip.is_empty():
		_cv.draw_line(a, b, _grid, 1.0)
		return
	var hits := Geometry2D.clip_polyline_with_polygon(PackedVector2Array([a, b]), clip)
	for part in hits:
		if part.size() >= 2:
			_cv.draw_line(part[0], part[part.size() - 1], _grid, 1.0)


func _draw_obstacles(obstacles: Array[Dictionary]) -> void:
	var s := view_scale
	for o in obstacles:
		if o.has("piece"):
			continue # Placed pieces draw themselves (_draw_piece).
		var p: Vector2 = o.pos * s
		var rad: float = o.radius * s
		if o.kind == "spike":
			_draw_spike_post(p, rad)
		elif o.kind == "bumper":
			var k := _bumper_flash / BUMPER_FLASH_LIFE
			var col := BUMPER.lerp(Color.WHITE, k * 0.7)
			Dot.circle(self, p, rad, Color(BUMPER, 0.16 + 0.3 * k))
			for i in 3:
				Dot.arc(self, p, rad + i * 3.0, 0, TAU, 56, Color(col, 0.3 - i * 0.08), 4.0 + i * 3.0, true)
			Dot.arc(self, p, rad, 0, TAU, 56, col, 2.5, true)
			Dot.circle(self, p, rad * 0.42, col)
		else:
			Dot.circle(self, p + Vector2(3, 5), rad, Color(0, 0, 0, 0.35))
			Dot.circle(self, p, rad, _pillar.darkened(0.6))
			Dot.circle(self, p + Vector2(-0.25, -0.3) * rad, rad * 0.45, Color(_pillar, 0.25))
			Dot.arc(self, p, rad + 3.0, 0, TAU, 56, Color(_pillar.lightened(0.3), 0.25), 6.0, true)
			Dot.arc(self, p, rad, 0, TAU, 56, _pillar.lightened(0.2), 2.5, true)


## Soft pools of light on the floor in the arena's theme colours.
func _draw_glows(theme: Dictionary, shape, clip: PackedVector2Array) -> void:
	var s := view_scale
	var k: float = shape.arena_scale()
	for g in theme.glows:
		var c: Vector2 = (shape.centre + (g[0] - shape.centre) * k) * s
		var r: float = g[1] * k * s
		var col := Color(g[2])
		for i in 5:
			var f := 1.0 - i / 5.0
			var pts := _circle_points(c, r * f, 40)
			if not clip.is_empty():
				var parts := Geometry2D.intersect_polygons(pts, clip)
				for part in parts:
					Dot.poly(_cv, part, Color(col, 0.025))
			else:
				Dot.poly(_cv, pts, Color(col, 0.025))


func _circle_points(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		pts.append(c + Vector2.from_angle(i * TAU / n) * r)
	return pts


## Ambient motion over the floor, from _time alone (no randomness), so it
## never touches the fight. Points outside `clip` (a cut-corner outline) are
## skipped.
func _draw_ambient(kind: String, r: Rect2, clip: PackedVector2Array) -> void:
	if kind == "none":
		return
	var n := 22
	for i in n:
		var u := fmod(i * 0.6180339 + 0.13, 1.0)
		var v := fmod(i * 0.3819660 + 0.71, 1.0)
		var t := _time * (0.6 + 0.4 * fmod(i * 0.77, 1.0))
		var p := Vector2.ZERO
		var col := Color.WHITE
		var size := 2.0
		match kind:
			"snow", "petals", "pollen":
				p = Vector2(u + 0.03 * sin(t * 1.3 + i), fmod(v + t * 0.05, 1.0))
				col = {"snow": Color("e8f6ff"), "petals": Color("ff9ecf"), "pollen": Color("ffe08a")}[kind]
				size = 2.5 if kind == "snow" else 3.0
			"embers", "bubbles":
				p = Vector2(u + 0.02 * sin(t * 2.0 + i), 1.0 - fmod(v + t * 0.07, 1.0))
				col = Color("ff8a3d") if kind == "embers" else Color("bff6ff")
				size = 2.2 if kind == "embers" else 3.5
			"stars":
				p = Vector2(u, v)
				col = Color("fff4d6")
				size = 1.2 + 1.3 * (0.5 + 0.5 * sin(t * 3.0 + i * 1.7))
			"fireflies", "wisps", "sparks":
				p = Vector2(u + 0.04 * sin(t * 0.9 + i * 2.1), v + 0.04 * cos(t * 0.7 + i * 1.3))
				col = {"fireflies": Color("c8ff8a"), "wisps": Color("b8ffd0"), "sparks": Color("ffe28a")}[kind]
				size = 2.2 if kind != "wisps" else 4.0
			"glitch":
				p = Vector2(u, v)
				col = Color("7cff4f") if i % 2 == 0 else Color("ff4fd8")
				if fmod(t * 1.7 + i * 0.37, 1.0) > 0.25:
					continue
				var q := r.position + Vector2(p.x * r.size.x, p.y * r.size.y)
				if clip.is_empty() or Geometry2D.is_point_in_polygon(q, clip):
					draw_rect(Rect2(q, Vector2(18, 6) * view_scale * 1.4), Color(col, 0.35))
				continue
		var at := r.position + Vector2(clampf(p.x, 0.0, 1.0) * r.size.x, clampf(p.y, 0.0, 1.0) * r.size.y)
		if not clip.is_empty() and not Geometry2D.is_point_in_polygon(at, clip):
			continue
		var a := 0.35 + 0.25 * sin(t * 2.3 + i)
		if kind in ["stars", "fireflies", "wisps", "sparks", "embers"]:
			Dot.circle(self, at, size * 2.6, Color(col, a * 0.18))
		Dot.circle(self, at, size, Color(col, a))


## Floor pads: ice, honey, lava, conveyor belts and portals.
func _draw_floors(floors: Array[Dictionary]) -> void:
	var s := view_scale
	var portal_no := 0
	for f in floors:
		match f.kind:
			"ice":
				var c: Vector2 = f.pos * s
				var r: float = f.radius * s
				Dot.circle(self, c, r, Color(ICE, 0.12))
				Dot.arc(self, c, r, 0, TAU, 72, Color(ICE, 0.55), 2.5, true)
				Dot.arc(self, c, r - 6.0, 0, TAU, 72, Color(ICE, 0.15), 6.0, true)
				for j in 6: # Cracks in the ice.
					var a := j * TAU / 6.0 + 0.4
					var mid := c + Vector2.from_angle(a) * r * 0.45 + Vector2.from_angle(a + 1.2) * r * 0.08
					Dot.pline(self, PackedVector2Array([c + Vector2.from_angle(a) * r * 0.12, mid, c + Vector2.from_angle(a + 0.15) * r * 0.85]), Color(ICE, 0.25), 1.5, true)
				var sheen := fmod(_time * 0.25, 1.0) # A glint sweeping across.
				Dot.arc(self, c, r * 0.7, -2.2 + sheen * 2.0, -1.7 + sheen * 2.0, 16, Color(1, 1, 1, 0.3), 3.0, true)
			"goo":
				var c: Vector2 = f.pos * s
				var r: float = f.radius * s
				Dot.circle(self, c, r, Color(GOO, 0.22))
				for j in 7: # Honeycomb cells.
					var off := Vector2.ZERO if j == 0 else Vector2.from_angle(j * TAU / 6.0) * r * 0.5
					var hex := PackedVector2Array()
					for q in 7:
						hex.append(c + off + Vector2.from_angle(q * TAU / 6.0 + TAU / 12.0) * r * 0.27)
					Dot.pline(self, hex, Color(GOO, 0.4), 1.5, true)
				Dot.arc(self, c, r, 0, TAU, 60, Color(GOO, 0.75), 3.0, true)
				for j in 5: # Drips wobbling on the rim.
					var a := j * TAU / 5.0 + _time * 0.2
					Dot.circle(self, c + Vector2.from_angle(a) * r, r * (0.08 + 0.02 * sin(_time * 2.0 + j)), Color(GOO, 0.7))
			"lava":
				_draw_lava(f, s)
			"conveyor":
				var rr: Rect2 = Rect2(f.rect.position * s, f.rect.size * s)
				draw_rect(rr, Color("2a2a33"))
				draw_rect(rr, Color(CONVEYOR, 0.7), false, 2.0)
				var step := 46.0 * s
				var dir: Vector2 = f.dir
				var shift := fmod(_time * 120.0 * s, step)
				var x := rr.position.x - step + (shift if dir.x > 0.0 else step - shift)
				var mid := rr.position.y + rr.size.y / 2.0
				var h := rr.size.y * 0.3
				while x < rr.end.x:
					if x > rr.position.x + 4.0 and x + h * 0.6 < rr.end.x - 4.0:
						var tip := x + h * 0.6 * dir.x
						Dot.pline(self, PackedVector2Array([Vector2(x, mid - h), Vector2(tip, mid), Vector2(x, mid + h)]), Color(CONVEYOR, 0.75), 4.0, true)
					x += step
				for edge in [rr.position.y + 3.0, rr.end.y - 3.0]: # Hazard stripes.
					var sx := rr.position.x
					while sx < rr.end.x - 10.0:
						draw_line(Vector2(sx, edge), Vector2(minf(sx + 10.0, rr.end.x), edge), Color(CONVEYOR, 0.5) if int(sx / 10.0) % 2 == 0 else Color(INK, 0.6), 4.0)
						sx += 10.0
			"portal":
				var c: Vector2 = f.pos * s
				var r: float = f.radius * s
				var col := PORTAL if (portal_no / 2) % 2 == 0 else PORTAL_B
				if portal_no % 2 == 1:
					col = col.lerp(Color.WHITE, 0.25)
				portal_no += 1
				Dot.circle(self, c, r, Color(col.darkened(0.7), 0.85))
				for j in 3:
					var a := _time * (2.0 + j) + j * 2.0
					Dot.arc(self, c, r * (0.45 + j * 0.2), a, a + 4.0, 32, Color(col, 0.6 - j * 0.12), 3.0, true)
				Dot.arc(self, c, r, 0, TAU, 56, col, 3.0, true)
				Dot.arc(self, c, r + 5.0, 0, TAU, 56, Color(col, 0.25), 8.0, true)


func _draw_lava(f: Dictionary, s: float) -> void:
	if f.has("rect"):
		var rr: Rect2 = Rect2(f.rect.position * s, f.rect.size * s)
		draw_rect(rr, Color("5a1405"))
		draw_rect(rr.grow(-3.0), Color(LAVA, 0.55))
		var n := 6
		for j in n:
			var y := rr.position.y + rr.size.y * fmod(j / float(n) + _time * 0.05, 1.0)
			var bub := 0.5 + 0.5 * sin(_time * 3.0 + j * 1.9)
			Dot.circle(self, Vector2(rr.position.x + rr.size.x * (0.3 + 0.4 * fmod(j * 0.618, 1.0)), y), rr.size.x * 0.18 * bub, Color("ffd166", 0.7))
		draw_rect(rr, Color("ffb347"), false, 2.0)
		return
	var c: Vector2 = f.pos * s
	var r: float = f.radius * s
	Dot.circle(self, c, r, Color("5a1405"))
	Dot.circle(self, c, r * 0.92, Color(LAVA, 0.6))
	Dot.circle(self, c, r * 0.6, Color("ff8a3d", 0.5 + 0.1 * sin(_time * 2.0)))
	for j in 7: # Bubbles that swell and pop.
		var ph := fmod(_time * 0.6 + j * 0.37, 1.0)
		var at := c + Vector2.from_angle(j * 2.4) * r * (0.25 + 0.55 * fmod(j * 0.618, 1.0))
		Dot.circle(self, at, r * 0.09 * ph, Color("ffd166", 0.8 * (1.0 - ph)))
		Dot.arc(self, at, r * 0.09 * ph, 0, TAU, 16, Color("fff0b3", 0.6 * (1.0 - ph)), 1.5, true)
	Dot.arc(self, c, r, 0, TAU, 72, Color("ffb347"), 2.5, true)
	Dot.arc(self, c, r + 4.0, 0, TAU, 72, Color(LAVA, 0.3), 8.0, true)


## Gravity wells: a dark core, a spiral swirling in and rings flowing inward.
func _draw_wells(wells: Array[Dictionary]) -> void:
	var s := view_scale
	for w in wells:
		var c: Vector2 = w.pos * s
		var reach: float = w.reach * s
		Dot.circle(self, c, reach, Color(WELL, 0.05))
		Dot.arc(self, c, reach, 0.0, TAU, 72, Color(WELL, 0.22), 2.0, true)
		_draw_inflow(c, w.core * s * 1.4, reach, WELL, 0.35)
		for arm in 3: # A three-armed spiral, turning slowly.
			var pts := PackedVector2Array()
			for j in 24:
				var f := j / 23.0
				var a := arm * TAU / 3.0 + f * 2.6 - _time * 1.4
				pts.append(c + Vector2.from_angle(a) * lerpf(reach * 0.9, w.core * s, f))
			Dot.pline(self, pts, Color(WELL, 0.3), 3.0, true)
		Dot.circle(self, c, w.core * s * 1.6, Color(WELL_CORE, 0.9))
		Dot.arc(self, c, w.core * s * 1.6, 0.0, TAU, 40, WELL, 2.5, true)
		Dot.circle(self, c, w.core * s * 0.7, Color(WELL, 0.25 + 0.15 * sin(_time * 3.0)))


## The spiked stretch of the left and right walls: a row of glowing teeth.
func _draw_spike_walls(shape) -> void:
	var half: float = shape.spike_wall_half()
	if half <= 0.0:
		return
	var s := view_scale
	var r: Rect2 = shape.arena_rect()
	var col := SPIKE.lerp(Color.WHITE, 0.6 * _spike_flash / BUMPER_FLASH_LIFE)
	var teeth := 7
	var tooth := half * 2.0 / teeth
	for side in [-1.0, 1.0]:
		var x: float = r.position.x if side < 0.0 else r.end.x
		var top: float = shape.centre.y - half
		draw_line(Vector2(x, top) * s, Vector2(x, top + half * 2.0) * s, Color(SPIKE, 0.35), 8.0, true)
		for t in teeth:
			var y0 := top + t * tooth
			var tri := PackedVector2Array([Vector2(x, y0) * s, Vector2(x - side * tooth * 0.75, y0 + tooth * 0.5) * s, Vector2(x, y0 + tooth) * s])
			Dot.poly(self, tri, Color(SPIKE.darkened(0.45), 0.95))
			Dot.pline(self, PackedVector2Array([tri[0], tri[1], tri[2]]), col, 2.0, true)


## A Spike Yard post: a dark core ringed with glowing spikes.
func _draw_spike_post(p: Vector2, rad: float) -> void:
	var k := _spike_flash / BUMPER_FLASH_LIFE
	var col := SPIKE.lerp(Color.WHITE, k * 0.6)
	Dot.circle(self, p + Vector2(3, 5), rad, Color(0, 0, 0, 0.35))
	var n := 10
	var spin := _time * 0.25
	for i in n:
		var a := spin + i * TAU / n
		var tip := p + Vector2.from_angle(a) * rad * 1.28
		var l := p + Vector2.from_angle(a - 0.24) * rad * 0.82
		var rr := p + Vector2.from_angle(a + 0.24) * rad * 0.82
		Dot.poly(self, PackedVector2Array([l, tip, rr]), Color(SPIKE.darkened(0.4), 0.95))
		Dot.pline(self, PackedVector2Array([l, tip, rr]), col, 2.0, true)
	Dot.circle(self, p, rad * 0.85, Color("2a0f22"))
	Dot.arc(self, p, rad * 0.85 + 3.0, 0, TAU, 48, Color(SPIKE, 0.2 + 0.3 * k), 6.0, true)
	Dot.arc(self, p, rad * 0.85, 0, TAU, 48, col, 2.5, true)
	Dot.circle(self, p, rad * 0.3, Color(col, 0.6))


## One critter at `pos` (screen space) with radius `r`. Squash, wince, blink
## and eye direction come from the per-ball effect state.
func _draw_critter(i: int, def: Dictionary, pos: Vector2, r: float, hp: float, max_hp: float, shake: Vector2, ko := false) -> void:
	var look: Vector2 = _look[i]
	var ang := look.angle()
	var sq: float = _squash[i] * 1.6
	if ko:
		# Flattened and wobbling, as if it just got bonked.
		sq = 0.12 + 0.05 * sin(_ko_age * 14.0) * exp(-_ko_age * 2.0) * A11y.motion()
	var squash := Transform2D(Vector2(1.0 - sq * 0.6, 0), Vector2(0, 1.0 + sq * 0.5), Vector2.ZERO)
	draw_set_transform_matrix(Transform2D(0, pos + shake) * Transform2D(ang, Vector2.ZERO) * squash * Transform2D(-ang, Vector2.ZERO))

	if def.get("boss", false) or def.get("minion", false):
		if not ko: # A beaten boss is drawn by its KO burst ("boss_death").
			_draw_boss(i, def, r)
		draw_set_transform(shake)
		return
	Dot.circle(self, Vector2(r * 0.08, r * 0.14), r, Color(0, 0, 0, 0.35))
	var phase := fmod(_time + i * 1.7, BLINK_PERIOD)
	var blink := sin(phase / 0.12 * PI) if phase < 0.12 else 0.0
	CritterArt.draw_critter(self, def.id, Vector2.ZERO, r, {"t": _time, "tier": _tier_of(i), "look": look, "blink": blink,
		"hit": minf(_hit[i], 0.12) if A11y.reduced_motion else _hit[i], "eye_flash": _eye_flash[i], "hp_frac": hp / max_hp, "pole_swap": _pole_swap[i], "ko": ko,
		"stacks": int(sim.balls[i].state.get("spikes", 0)) if sim and i < sim.balls.size() else 0, "flash": _grow_flash[i] if i < 2 else 0.0,
		"phased": sim != null and i < sim.balls.size() and sim.tick < int(sim.balls[i].state.get("phase_until", -1)),
		"wind": _art_meter(i, "wind"), "pressure": _art_meter(i, "pressure"),
		"live_stacks": int(sim.balls[i].state.get("stacks", 0)) if sim and i < sim.balls.size() and sim.balls[i].def.has("stack_max") else -1})
	var hat := _cosmetic(_side(i), "hat")
	if not hat.is_empty():
		CosmeticArt.draw_hat(self, hat, Vector2.ZERO, r, _time)
	if ko:
		draw_set_transform(shake)
		_dizzy_stars(pos, r)

	draw_set_transform(shake)


## The Prism Wyrm's body: a crystal band from its head down through its
## scales to the tail, so the separate pieces read as one serpent.
func _draw_wyrm_spine(wyrm, s: float) -> void:
	var pts := PackedVector2Array([ball_pos(wyrm) * s])
	for idx in wyrm.state.get("scales", []):
		if idx < sim.balls.size():
			pts.append(ball_pos(sim.balls[idx]) * s)
	if pts.size() < 2:
		return
	Dot.pline(self, pts, Color("1d3550", 0.85), wyrm.def.segment_radius * s * 1.3, true)
	Dot.pline(self, pts, Color(BossArt.PRISM, 0.35 + 0.15 * sin(_time * 3.0)), maxf(2.0, 6.0 * s), true)


## A farming boss (sim/bosses.gd), posed by what its script is doing.
func _draw_boss(i: int, def: Dictionary, r: float) -> void:
	var b := sim.balls[i]
	var opts := {"t": _time + i, "hit": _hit[i], "hp_frac": b.hp / b.max_hp, "stunned": sim.stunned(b)}
	if b.vel.length() > 1.0:
		opts.face = b.vel.normalized()
	elif def.id == "brood_queen": # She glides by moving her anchor: face along the loop.
		opts.face = Vector2.from_angle(def.glide_start + b.state.clock * def.glide_speed + PI / 2.0)
	if def.id == "pinata_titan": # Its rope, up to where it hangs from.
		opts.pivot = def.pivot - b.pos
	if def.id == "totem_of_nine":
		opts.family = b.state.get("family", "")
	if def.id == "prism_wyrm":
		opts.lit = int(b.state.get("shine", 0)) == 0
		opts.face = (Bosses._wyrm_at(def, b.state.clock + 0.1) - b.pos).normalized()
	elif def.id == "the_glitch":
		opts.phase = Bosses.GLITCH_PHASES[maxi(0, int(b.state.get("phase", 0)))]
	elif def.id == "wyrm_scale" and sim.boss != null:
		opts.lit = int(b.state.get("order", -1)) == int(sim.boss.state.get("shine", 0))
	if b.state.has("hatch_at"):
		opts.hatch = clampf(1.0 - (b.state.hatch_at - sim.tick) / (sim.boss.def.get("egg_hatch", 5.0) * sim.TICK_RATE), 0.0, 1.0) if def.id == "brood_egg" else 1.0
	var act: Dictionary = b.state.get("act", {})
	if act.get("kind", "") == "slam" and act.shot != null:
		opts.swing = clampf(act.shot.age / act.shot.flight, 0.0, 1.0)
	elif act.get("kind", "") == "volley":
		opts.volley = clampf(1.0 - (act.at - b.state.clock) / maxf(def.get("volley_windup", 1.0), 0.01), 0.0, 1.0)
	elif act.get("kind", "") == "quake":
		opts.quake = clampf(1.0 - (act.at - b.state.clock) / maxf(def.get("quake_windup", 1.0), 0.01), 0.0, 1.0)
	elif act.has("at"): # Any other wind-up: the lash, a warp, a pulse.
		var windup: float = def.get({"lash": "lash_windup", "warp": "warp_windup", "gpulse": "pulse_windup"}.get(act.kind, ""), 1.0)
		opts.charge = clampf(1.0 - (act.at - b.state.clock) / maxf(windup, 0.01), 0.0, 1.0)
	if def.id == "brood_queen" and b.state.has("next_feather"): # The last half second before a feather volley.
		opts.charge = clampf(1.0 - (b.state.next_feather - b.state.clock) / 0.5, 0.0, 1.0)
	if def.get("boss", false) and sim.balls[0].alive():
		opts.look = (sim.balls[0].pos - b.pos).normalized()
	BossArt.draw(self, def.id, Vector2.ZERO, r, opts)


## Team ring, tag and HP badge: drawn after everything else (cosmetics
## included), outside the squash so they stay steady and readable.
func _draw_overlay(i: int, def: Dictionary, pos: Vector2, r: float, hp: float, max_hp: float, shake: Vector2) -> void:
	var side := _side(i)
	var team_col: Color = TEAM_COLORS[side]
	draw_set_transform(shake)
	if def.get("id", "") == "wyrm_scale": # Armour: its hits come off the wyrm's own HP.
		return
	if def.get("minion", false): # Eggs and chicks: just their HP, no ring or tag.
		_hp_badge(def, pos, r, hp, max_hp)
		return
	_team_ring(side, pos, r, team_col)
	_text_centered(_tag_at.get(i, pos + Vector2(0, r + 26.0)), team_tags[side], A11y.font(20), Color(team_col, 0.75), 4)
	_hp_badge(def, pos, r, hp, max_hp, 0.4 if _cosmetic(side, "hat") else 0.0)


## Where each ball's YOU/FOE tag goes this frame: under the ball, or above
## its HP badge near the bottom wall, kept inside the arena and nudged apart
## (up/down) where two tags would overlap.
func _place_tags(s: float, ko_ball: int) -> void:
	_tag_at.clear()
	var fs := A11y.font(20)
	var edge := MatchSim.ARENA_SIZE * s
	var list := []
	for b in sim.balls:
		if not (b.alive() or b.index == ko_ball) or b.def.get("minion", false) or b.def.get("id", "") == "wyrm_scale":
			continue
		var pos := ball_pos(b) * s
		var r: float = b.radius * s
		var w := FONT.get_string_size(team_tags[_side(b.index)], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var at := pos + Vector2(0, r + 26.0)
		if at.y + fs * 0.6 > edge: # Too near the bottom wall: above the HP badge instead.
			at.y = pos.y - (b.def.get("badge_top", 1.15) * r + r * 0.62 + 26.0)
		at.x = clampf(at.x, w / 2.0 + 4.0, edge - w / 2.0 - 4.0)
		at.y = clampf(at.y, fs * 0.7, edge - fs * 0.6)
		list.append({"i": b.index, "at": at, "w": w})
	for a in list.size():
		for b in range(a + 1, list.size()):
			var p: Vector2 = list[a].at
			var q: Vector2 = list[b].at
			var need := fs * 1.1 - absf(p.y - q.y)
			if need > 0.0 and absf(p.x - q.x) < (list[a].w + list[b].w) / 2.0 + 6.0:
				var up := -1.0 if p.y <= q.y else 1.0
				list[a].at.y += up * need / 2.0
				list[b].at.y -= up * need / 2.0
	for t in list:
		_tag_at[t.i] = t.at


## Cogs' wind-up or Fizz's pressure as 0-1, for the critter art.
func _art_meter(i: int, key: String) -> float:
	if sim == null or i >= sim.balls.size():
		return 0.0
	var b := sim.balls[i]
	if key == "wind" and b.def.has("wind_step") and b.mods.has("wind"):
		return minf(1.0, b.def.wind_step * int(b.state.get("wind", 0)) / b.def.wind_cap)
	if key == "pressure" and b.def.has("fizz_at"):
		return int(b.state.get("pressure", 0)) / float(b.def.fizz_at)
	return 0.0


## The cosmetic `slot` worn by side `i`, as a catalog entry, or {}.
func _cosmetic(i: int, slot: String) -> Dictionary:
	if i < 0 or i >= loadouts.size():
		return {}
	return Catalog.item(str(loadouts[i].get(slot, "")))


## Solid ring for the player (index 0); dashed ring with four outward ticks
## for the foe. Shape, not just hue, tells the sides apart. Kept thin and
## faint so the critter art underneath stays the star.
func _team_ring(i: int, pos: Vector2, r: float, col: Color) -> void:
	var a := TEAM_RING_ALPHA
	if i == 0:
		Dot.arc(self, pos, r + 5.0, 0, TAU, 64, Color(col, a), 2.0, true)
		return
	var dashes := 16
	var gap := TAU / dashes
	for k in dashes:
		Dot.arc(self, pos, r + 5.0, k * gap, k * gap + gap * 0.5, 6, Color(col, a), 2.0, true)
	for k in 4:
		var d := Vector2.from_angle(PI / 4.0 + k * PI / 2.0)
		var side := d.orthogonal()
		var base := pos + d * (r + 4.0)
		Dot.poly(self, PackedVector2Array([base + side * 3.5, base + d * 9.0, base - side * 3.5]), Color(col, a))


## A field (Flux's magnet): faint rings flowing in (Pull) or out (Push) so
## players can read the rhythm. Inner rings are brighter, like its strength.
func _draw_field(m, s: float) -> void:
	var reach: float = m.def.field_range * 0.75
	var pulling: bool = m.state.get("pulling", true)
	var col := FIELD_PULL if pulling else FIELD_PUSH
	for k in 3:
		var f := fmod(_time * 0.9 + k / 3.0, 1.0)
		if pulling:
			f = 1.0 - f
		var rad: float = lerpf(m.radius * 1.3, reach, f)
		Dot.arc(self, m.pos * s, rad * s, 0.0, TAU, 64, Color(col, 0.28 * (1.0 - f)), 3.0, true)


## Floor zones: mines blink until they blow; trails and patches fade out.
func _draw_zone(z, s: float) -> void:
	var fade: float = clampf(1.0 - z.age / z.life, 0.0, 1.0)
	var p: Vector2 = z.pos * s
	match z.kind:
		"mine" when z.owner >= 0 and z.owner < sim.balls.size() and sim.balls[z.owner].type_id == "bomber":
			BattleFx.draw_bomb(self, p, s, z.armed(), z.blast_radius, z.age, z.pos.x * 0.01, _time)
		"mine" when z.owner >= 0 and z.owner < sim.balls.size() and sim.balls[z.owner].type_id == "blizz":
			BattleFx.draw_ice_mine(self, p, s, z.armed(), z.blast_radius, z.age, z.pos.y * 0.01, _time)
		"afterimage":
			var col: Color = sim.balls[z.owner].def.color if z.owner >= 0 and z.owner < sim.balls.size() else Color.WHITE
			BattleFx.draw_afterimage(self, p, z.radius * s, fade, col)
		"lava":
			BattleFx.draw_lava(self, p, z.radius * s, fade, fmod(z.pos.x * 0.07 + z.pos.y * 0.11, 6.28), _time)
		"inkpool":
			BattleFx.draw_ink(self, p, z.radius * s, fade, fmod(z.pos.x * 0.09 + z.pos.y * 0.05, 6.28), _time)
		"ice":
			BattleFx.draw_ice(self, p, z.radius * s, fade, fmod(z.pos.x * 0.13 + z.pos.y * 0.07, 6.28), _time)
		"honey":
			BattleFx.draw_honey(self, p, z.radius * s, fade, fmod(z.pos.x * 0.07 + z.pos.y * 0.03, 6.28), _time)
		"ember":
			BattleFx.draw_embers(self, p, z.radius * s, fade, fmod(z.pos.x * 0.11 + z.pos.y * 0.05, 6.28), _time)
		"mine":
			var armed: bool = z.armed()
			if armed:
				Dot.arc(self, p, z.blast_radius * s, 0.0, TAU, 40, Color(MINE, 0.12), 2.0, true)
			Dot.circle(self, p, 16.0 * s, Color("2b3a67"))
			Dot.arc(self, p, 16.0 * s, 0.0, TAU, 20, Color("10162b"), 2.0, true)
			var on := armed and fmod(_time * 3.0 + z.pos.x * 0.01, 1.0) < 0.5
			Dot.circle(self, p, 6.0 * s, MINE if on else Color(MINE, 0.35))
		"ring":
			Dot.arc(self, p, z.radius * s, 0.0, TAU, 64, Color(ZONE_COLORS.ring, 0.6 * fade), 10.0 * s, true)
		"stink":
			# Rides on Whiff: lumpy green puffs with stink lines rising.
			BattleFx.draw_stink(self, p, z.radius * s, _time)
		"rain":
			var col: Color = ZONE_COLORS.rain
			if not z.armed():
				# The warning: a dark circle with a dashed rim.
				Dot.circle(self, p, z.radius * s, Color(0.0, 0.0, 0.08, 0.35))
				for k in 12:
					var a := k * TAU / 12.0 + _time
					Dot.arc(self, p, z.radius * s, a, a + TAU / 24.0, 4, Color(col, 0.8), 2.0, true)
			else:
				BattleFx.draw_rain(self, p, z.radius * s, fade, fmod(z.pos.x * 0.05, 6.28), _time, col)
		"stardust":
			BattleFx.draw_stardust(self, p, z.radius * s, fade, fmod(z.pos.x * 0.07 + z.pos.y * 0.03, TAU), _time)
		"paint":
			# Wet rainbow paint: the hue walks along the trail.
			var col := Color.from_hsv(fmod((z.pos.x + z.pos.y) * 0.0015, 1.0), 0.65, 1.0)
			Dot.circle(self, p, z.radius * s, Color(col, 0.3 * fade))
			Dot.circle(self, p, z.radius * 0.5 * s, Color(col, 0.25 * fade))
		"pixel":
			# Pixel's bomb: a chunky square that flickers between frames.
			var on: bool = z.armed() and fmod(_time * 4.0 + z.pos.y * 0.01, 1.0) < 0.5
			var half: float = 14.0 * s
			if z.armed():
				Dot.arc(self, p, z.blast_radius * s, 0.0, TAU, 40, Color("7cff4f", 0.12), 2.0, true)
			draw_rect(Rect2(p - Vector2(half, half), Vector2(half, half) * 2.0), Color("1f4d12"))
			draw_rect(Rect2(p - Vector2(half, half) * 0.5, Vector2(half, half)), Color("7cff4f") if on else Color("7cff4f", 0.35))
		"quake": # The Anvil King winding up a quake: a throbbing ring to get outside.
			var pulse := 0.5 + 0.5 * absf(sin(_time * 9.0))
			Dot.circle(self, p, z.radius * s, Color(RING_COLORS.quake, 0.05 + 0.05 * pulse))
			for k in 24:
				var a := k * TAU / 24.0 - _time * 0.8
				Dot.arc(self, p, z.radius * s, a, a + TAU / 48.0, 4, Color(RING_COLORS.quake, 0.5 + 0.4 * pulse), 4.0, true)
		"rot": # Corrupted floor where The Glitch was: jittery pixel squares.
			var rot_fade := clampf(z.life - z.age, 0.0, 1.0)
			Dot.circle(self, p, z.radius * s, Color("7cff4f", 0.12 * rot_fade))
			for k in 6:
				var a := k * TAU / 6.0 + floorf(_time * 6.0) * 0.7
				var q: Vector2 = p + Vector2.from_angle(a) * z.radius * 0.55 * s
				var half := 9.0 * s
				draw_rect(Rect2(q - Vector2(half, half), Vector2(half, half) * 2.0), Color("ff4fd8" if k % 2 else "7cff4f", 0.5 * rot_fade))
		"warp": # The Glitch about to blink here.
			if fmod(_time * 10.0, 1.0) < 0.6:
				Dot.arc(self, p, z.radius * s, 0.0, TAU, 24, Color("ff4fd8", 0.8), 4.0, true)
		"lash": # The Prism Wyrm's tail about to lash: get clear.
			var flick := 0.5 + 0.5 * absf(sin(_time * 14.0))
			Dot.circle(self, p, z.radius * s, Color("7af0ff", 0.06 + 0.06 * flick))
			Dot.arc(self, p, z.radius * s, 0.0, TAU, 40, Color("7af0ff", 0.5 + 0.4 * flick), 4.0, true)
		"spirit": # The Totem of Nine's heads glowing before a volley.
			var glow := 0.5 + 0.5 * absf(sin(_time * 12.0))
			Dot.arc(self, p, z.radius * s, 0.0, TAU, 40, Color("c9a6ff", 0.4 + 0.5 * glow), 5.0, true)
		"clod":
			var land: float = clampf(z.age / maxf(z.arm, 0.01), 0.0, 1.0)
			Dot.circle(self, p, z.radius * s * (0.4 + 0.6 * land), Color(ZONE_COLORS.clod, 0.25 + 0.5 * land))
		_:
			if z.follow >= 0:
				return # A clinging slow: the ball's own slow ring shows it.
			var col: Color = ZONE_COLORS.get(z.kind, Color.WHITE)
			Dot.circle(self, p, z.radius * s, Color(col, 0.28 * fade))
			Dot.circle(self, p, z.radius * 0.55 * s, Color(col, 0.22 * fade))


## Wind streaks flowing outward (Gust); `speed` quickens them during a huff.
func _draw_outflow(c: Vector2, inner: float, reach: float, col: Color, alpha: float, speed: float) -> void:
	for k in 3:
		var f := fmod(_time * speed + k / 3.0, 1.0)
		var r := lerpf(inner * 1.1, reach, f)
		for j in 4:
			var a := j * TAU / 4.0 + k * 0.5 + _time * 0.3
			Dot.arc(self, c, r, a, a + 0.7, 12, Color(col, alpha * (1.0 - f)), 3.0, true)


## Projectiles in the owner's colour with a bright core. A lobbed shot arcs
## over a shadow toward a blinking target ring where it will land.
func _draw_shot(shot, s: float) -> void:
	var col: Color = sim.balls[shot.owner].def.color.lightened(0.25)
	var p: Vector2 = shot.pos * s
	var r: float = shot.radius * s
	if shot.lob:
		var t: float = clampf(shot.age / shot.flight, 0.0, 1.0)
		var land: Vector2 = shot.land * s
		var reach: float = maxf(shot.land_radius, shot.zone.get("radius", 40.0)) * s
		var blink := 0.35 + 0.35 * absf(sin(_time * 10.0))
		Dot.arc(self, land, reach, 0.0, TAU, 48, Color(RING_COLORS.get(shot.kind, BURST), blink), 3.0, true)
		Dot.arc(self, land, reach * 0.25 * (1.0 - t) + 6.0, 0.0, TAU, 24, Color(RING_COLORS.get(shot.kind, BURST), blink), 2.0, true)
		Dot.circle(self, p, 9.0 * s, Color(0, 0, 0, 0.35))
		var lift := Vector2(0, -sin(PI * t) * 150.0 * s)
		if shot.kind == "shell" and sim.balls[shot.owner].type_id == "mortar":
			BattleFx.draw_cannonball(self, p + lift, 15.0 * s, _time)
			return
		if shot.kind == "hammer": # The Anvil King's hammer, tumbling end over end.
			_draw_hammer(p + lift, 26.0 * s, t * TAU * 1.5)
			return
		if shot.kind == "blob" and sim.balls[shot.owner].type_id == "brewster":
			var liquid: Color = BattleFx.POTIONS.get(shot.zone.get("kind", "goo"), BattleFx.POTIONS.goo)
			BattleFx.draw_potion(self, p + lift, (20.0 if shot.zone.get("kind", "") == "brew" else 13.0) * s, liquid, t * TAU * 1.5 + shot.land.x)
			return
		Dot.circle(self, p + lift, 22.0 * s, Color(col, 0.35))
		Dot.circle(self, p + lift, 15.0 * s, col)
		Dot.circle(self, p + lift + Vector2(-3, -3) * s, 4.0 * s, Color.WHITE)
		return
	if shot.kind == "spike":
		BattleFx.draw_spike_shot(self, p, maxf(r, 6.0), shot.vel)
		return
	if shot.kind == "feather": # The Brood Queen's feathers.
		var d: Vector2 = shot.vel.normalized()
		var sd := d.orthogonal()
		Dot.poly(self, PackedVector2Array([p + d * r * 1.8, p + sd * r * 0.6, p - d * r * 1.8, p - sd * r * 0.6]), BossArt.HEN_HI)
		draw_line(p - d * r * 2.2, p + d * r * 1.8, BossArt.HEN, 2.0, true)
		return
	if shot.kind == "stinger" and sim.balls[shot.owner].type_id == "zing":
		BattleFx.draw_stinger(self, p, maxf(r, 5.0), shot.vel)
		return
	if shot.kind == "pearl":
		BattleFx.draw_pearl(self, p, maxf(r, 5.0), _time)
		return
	var back: Vector2 = -shot.vel.normalized() if shot.vel.length() > 0.001 else Vector2.ZERO
	if shot.kind in ["rocket", "stinger"]:
		draw_line(p, p + back * r * 3.0, Color(Color("ffb347") if shot.kind == "rocket" else col, 0.6), r * 0.9, true)
	else:
		draw_line(p, p + back * r * 2.0, Color(col, 0.25), r * 1.2, true)
	Dot.circle(self, p, r * 1.6, Color(col, 0.25))
	Dot.circle(self, p, r, col)
	Dot.circle(self, p + Vector2(-0.3, -0.3) * r, r * 0.4, Color.WHITE)


func _draw_hammer(at: Vector2, r: float, spin: float) -> void:
	var dir := Vector2.from_angle(spin)
	var side := dir.orthogonal()
	Dot.pline(self, PackedVector2Array([at - dir * r, at + dir * r * 0.6]), Color("b07a45"), maxf(3.0, r * 0.25), true)
	var head := at + dir * r * 0.6
	Dot.poly(self, PackedVector2Array([head + side * r * 0.55 - dir * r * 0.25, head + side * r * 0.55 + dir * r * 0.25,
		head - side * r * 0.55 + dir * r * 0.25, head - side * r * 0.55 - dir * r * 0.25]), BossArt.STEEL)
	Dot.circle(self, head - side * r * 0.55, r * 0.18, BossArt.HOT)


## One orbiter or attachment (sim/abilities.gd, batch E), by its look.
func _draw_orb(b, item: Dictionary, s: float) -> void:
	var p: Vector2 = item.pos * s
	var r: float = item.size * s
	var col: Color = b.def.color
	if item.look == "tentacle" and item.has("from"):
		BattleFx.draw_tentacle(self, item.from * s, p, r, col, _time, (item.pos - b.pos).angle())
		return
	if item.has("from"):
		if item.look == "wreck":
			BattleFx.draw_chain(self, item.from * s, p, 9.0 * s * 1.6)
		else:
			draw_line(item.from * s, p, Color(col.lightened(0.25), 0.85), 4.0 * s, true)
	if item.look == "candy" and b.type_id == "jawbreaker":
		BattleFx.draw_jawbreaker(self, p, r, int(item.get("hue", 0)), _time)
		return
	match item.look:
		"bug":
			Dot.circle(self, p, r * 2.2, Color("eaff6a", 0.18 + 0.1 * sin(_time * 8.0)))
			Dot.circle(self, p, r, Color("eaff6a"))
			Dot.circle(self, p + Vector2(-r * 0.3, -r * 0.3), r * 0.4, Color.WHITE)
		"candy":
			var hues := [Color("ff5fa2"), Color("ffd23f"), Color("6ee7ff"), Color("a6ff6e")]
			Dot.circle(self, p, r * 1.3, Color(hues[int(item.get("hue", 0)) % 4], 0.25))
			Dot.circle(self, p, r, hues[int(item.get("hue", 0)) % 4])
			Dot.arc(self, p, r * 0.6, _time * 4.0, _time * 4.0 + PI, 12, Color.WHITE, 2.0, true)
		"wreck":
			var big: bool = item.get("big", false)
			Dot.circle(self, p, r * 1.25, Color("ffe066", 0.35 if big else 0.12))
			Dot.circle(self, p, r, Color("3a3f45"))
			Dot.arc(self, p, r, 0.0, TAU, 24, Color("ffe066"), 2.5, true)
			Dot.circle(self, p + Vector2(-r * 0.3, -r * 0.3), r * 0.25, Color(1, 1, 1, 0.6))
		"bee":
			var flying: bool = item.get("flying", false)
			var dir: Vector2 = (item.pos - b.pos).orthogonal() # Circling the hive.
			if flying:
				var f = sim.nearest_foe(b)
				dir = (f.pos - item.pos) if f != null else dir
			BattleFx.draw_bee(self, p, r, dir, _time + item.pos.x * 0.01, flying)
		"tentacle":
			Dot.circle(self, p, r, col.lightened(0.25))
			Dot.circle(self, p, r * 0.45, Color("ffd6f5", 0.8))
		"segment":
			Dot.circle(self, p, r * 1.3, Color("5ff0e6", 0.18))
			Dot.circle(self, p, r, col.lightened(0.15))
			Dot.arc(self, p, r * 0.7, 0.0, TAU, 20, Color("5ff0e6", 0.85), 2.5, true)
		"yoyo":
			Dot.circle(self, p, r, Color(col, 0.55))
			Dot.arc(self, p, r, 0.0, TAU, 24, Color("7ff3ff", 0.8), 2.0, true)
		_:
			Dot.circle(self, p, r + 4.0 * s, Color("d9d4ff", 0.25))
			Dot.circle(self, p, r, Color("d9d4ff"))
			Dot.circle(self, p + Vector2(-3, -3) * s, r * 0.4, Color.WHITE)


## Clods of dirt thrown up (Mole digging in or bursting out).
func _dirt_spray(at: Vector2, n: int) -> void:
	for q in n:
		var dir := Vector2.from_angle(_fx_rng.randf() * TAU)
		_particles.append({"pos": at, "vel": dir * _fx_rng.randf_range(120.0, 380.0) + Vector2(0, -120.0), "age": 0.0, "life": _fx_rng.randf_range(0.4, 0.8), "col": BattleFx.DIRT if q % 2 else BattleFx.DIRT.lightened(0.25), "size": _fx_rng.randf_range(4.0, 7.0)})


## One-off effects from _fx.
func _draw_fx(k: Dictionary, s: float) -> void:
	match k.kind:
		"boss_death":
			BossArt.draw_death(self, k.id, k.pos * s, k.r * s, k.age)
		"hook":
			var a := sim.balls[k.ball]
			var f := sim.balls[k.target]
			var reel: float = k.age / k.life
			var tip: Vector2 = ball_pos(f).lerp(ball_pos(a), reel * reel)
			BattleFx.draw_hook(self, ball_pos(a) * s, tip * s, reel, _time)
		"avalanche":
			BattleFx.draw_avalanche(self, k.pos * s, k.radius * s, k.age, k.seed)
		"sonar":
			BattleFx.draw_sonar(self, k.pos * s, k.radius * s, k.age)
		"mitosis":
			if k.twin < sim.balls.size():
				var g := sim.balls[k.ball]
				BattleFx.draw_mitosis(self, ball_pos(g) * s, ball_pos(sim.balls[k.twin]) * s, g.radius * s, k.age, g.def.color)
		"sunfire":
			BattleFx.draw_sunfire(self, k.pos * s, k.radius * s, k.age, k.seed)
		"honey_lob":
			BattleFx.draw_honey_lob(self, k.from * s, k.pos * s, 12.0 * s, k.age)
		"clock":
			BattleFx.draw_clock_ring(self, k.pos * s, k.radius * s, k.age)
		"splash":
			BattleFx.draw_splash(self, k.pos * s, k.radius * s, k.age, k.seed)
		"rewind":
			var g := sim.balls[k.ball]
			BattleFx.draw_rewind(self, k.from * s, ball_pos(g) * s, g.radius * s, k.age, k.life)
		"eclipse":
			var g := sim.balls[k.ball]
			BattleFx.draw_eclipse_flip(self, ball_pos(g) * s, g.radius * s, g.def.get("flip_radius", 160.0) * s, k.age, k.moon)


## Leviathan's dive: a swirl where it went down and a shrinking ring where it
## will burst up.
func _draw_dive(b, s: float) -> void:
	for k in 3:
		var a := _time * 6.0 + k * TAU / 3.0
		Dot.arc(self, b.pos * s, b.radius * s * (0.6 + 0.2 * k), a, a + PI * 0.9, 16, Color("5ff0e6", 0.6), 3.0, true)
	var t: Vector2 = b.state.get("dive_target", b.pos)
	var left: float = (int(b.state.dive_until) - sim.tick) / float(MatchSim.TICK_RATE)
	var reach: float = b.def.get("wave_radius", 200.0)
	Dot.arc(self, t * s, reach * s, 0.0, TAU, 48, Color("5ff0e6", 0.25), 2.0, true)
	Dot.arc(self, t * s, reach * s * clampf(left / 1.2, 0.1, 1.0), 0.0, TAU, 48, Color("5ff0e6", 0.7), 3.0, true)


## A piece a critter placed: pillars grow up out of the floor (dashed while a
## ball still stands on them, as they don't block yet) and sink as they end;
## Foxfire's illusions are see-through copies of it with no HP badge.
func _draw_piece(p, s: float, shake: Vector2) -> void:
	var grow: float = clampf(p.age / maxf(p.grow, 0.15), 0.0, 1.0)
	var sink: float = clampf((p.life - p.age) / 0.3, 0.0, 1.0)
	var k := minf(grow, sink)
	var pos: Vector2 = p.pos * s
	var rad: float = p.radius * s * (0.35 + 0.65 * k)
	if p.kind == "illusion":
		var owner = sim.balls[p.owner]
		var look: Vector2 = p.vel.normalized() if p.vel.length() > 0.001 else Vector2.RIGHT
		draw_set_transform(pos + shake)
		CritterArt.draw_critter(self, owner.def.id, Vector2.ZERO, p.radius * s, {"t": _time, "tier": tiers[p.owner], "look": look})
		draw_set_transform(shake)
		Dot.circle(self, pos, p.radius * s * 1.04, Color(ARENA_FILL, 0.45))
		for f in 5:
			var a := _time * 5.0 + f * TAU / 5.0
			Dot.circle(self, pos + Vector2(cos(a), sin(a)) * p.radius * s * 0.95, 5.0, Color("6fb7ff", 0.7 * sink))
		return
	var cols: Array = PIECE_COLORS.get(p.kind, [PILLAR.darkened(0.6), PILLAR.lightened(0.2)])
	if p.kind == "seed":
		BattleFx.draw_sapling(self, pos, p.radius * s, k, _time)
		return
	if p.kind in ["root", "vine", "ice"]:
		var seed := fmod(p.pos.x * 0.013 + p.pos.y * 0.007, TAU)
		match p.kind:
			"root": BattleFx.draw_tree(self, pos, p.radius * s, k, seed, _time)
			"vine": BattleFx.draw_vine_pillar(self, pos, p.radius * s, k, seed, _time)
			"ice": BattleFx.draw_crystal_pillar(self, pos, p.radius * s, k, seed, _time)
		if not p.blocking: # Still see-through: a dashed rim.
			for d in 10:
				Dot.arc(self, pos, rad, d * TAU / 10.0, (d + 0.5) * TAU / 10.0, 4, Color(cols[1], 0.8), 2.0, true)
		return
	Dot.circle(self, pos + Vector2(3, 5) * k, rad, Color(0, 0, 0, 0.3 * k))
	Dot.circle(self, pos, rad, Color(cols[0], 0.5 + 0.5 * k))
	Dot.circle(self, pos + Vector2(-0.25, -0.3) * rad, rad * 0.45, Color(cols[1], 0.25))
	if p.blocking:
		Dot.arc(self, pos, rad, 0, TAU, 40, cols[1], 2.5, true)
	else:
		for d in 10:
			Dot.arc(self, pos, rad, d * TAU / 10.0, (d + 0.5) * TAU / 10.0, 4, Color(cols[1], 0.8), 2.0, true)
	match p.kind:
		"seed", "vine":
			for l in 2:
				var a := -PI / 2.0 + (l - 0.5) * 1.1
				_ellipse(pos + Vector2(cos(a), sin(a)) * rad * 0.55, rad * 0.32, rad * 0.18, Color(cols[1], 0.9))
		"ice":
			_star(pos, rad * 0.7, rad * 0.25, 6, Color(cols[1], 0.85))
		"root":
			for l in 3:
				var a := l * TAU / 3.0 + 0.4
				draw_line(pos, pos + Vector2(cos(a), sin(a)) * rad * 0.8, Color(cols[1], 0.8), 3.0, true)


## Ivy's lash: a taut vine from the lashed foe to each vine pillar.
func _draw_lash(b, s: float) -> void:
	var lash: Dictionary = b.state.get("lash", {})
	if lash.is_empty():
		return
	var f = sim.balls[lash.target]
	for a in lash.anchors:
		BattleFx.draw_lash_vine(self, a.piece.pos * s, f.pos * s, _time)


## Jackpot's next payout, shown where it will land before it fires: a dashed
## cross through the locked spot, or a ring of coin marks round itself.
func _draw_prize_tells(b, s: float) -> void:
	for p in b.state.get("prizes", []):
		var blink := 0.35 + 0.35 * sin(_time * 18.0)
		if p.prize == "cross":
			var r := sim.arena_rect()
			var c: Vector2 = p.spot
			_dashed(Vector2(r.position.x, c.y) * s, Vector2(r.end.x, c.y) * s, Color(BEAM, blink))
			_dashed(Vector2(c.x, r.position.y) * s, Vector2(c.x, r.end.y) * s, Color(BEAM, blink))
		elif p.prize == "coins":
			Dot.arc(self, b.pos * s, (b.radius + b.def.prize_coin_reach) * s, 0.0, TAU, 64, Color(RAY_COLORS.coin, blink * 0.6), 2.0, true)


func _dashed(a: Vector2, b: Vector2, col: Color) -> void:
	var length := a.distance_to(b)
	var dir := (b - a) / maxf(length, 0.001)
	var d := 0.0
	while d < length:
		draw_line(a + dir * d, a + dir * minf(d + 12.0, length), col, 2.0, true)
		d += 22.0


## Flow lines drifting inward: a pull field (Orbit) or a collapse (Void).
func _draw_inflow(c: Vector2, inner: float, reach: float, col: Color, alpha: float) -> void:
	for k in 3:
		var f := 1.0 - fmod(_time * 0.9 + k / 3.0, 1.0)
		Dot.arc(self, c, lerpf(inner * 1.3, reach, f), 0.0, TAU, 64, Color(col, alpha * (1.0 - f)), 3.0, true)


## Per-ball status on top of the critter: phased (faded), shield, burning.
func _draw_status(b, s: float) -> void:
	var p: Vector2 = ball_pos(b) * s
	var r: float = b.radius * s
	if sim.tick < int(b.state.get("phase_until", -1)) and b.type_id != "leviathan":
		Dot.circle(self, p, r * 1.05, Color(ARENA_FILL, 0.6))
	if b.shield > 0.0 and b.type_id == "vampire":
		BattleFx.draw_blood_shield(self, p, r, _time)
	elif b.shield > 0.0 and b.type_id == "megabot":
		BattleFx.draw_hex_shield(self, p, r, _time, clampf(b.shield / maxf(1.0, b.def.get("salvo_shield", 10.0)), 0.0, 1.0))
	elif b.shield > 0.0:
		Dot.arc(self, p, r * 1.12, 0.0, TAU, 48, Color("7fe6ff", 0.85), 4.0, true)
		Dot.arc(self, p, r * 1.18, 0.0, TAU, 48, Color("7fe6ff", 0.25), 6.0, true)
	if not b.dots.is_empty():
		BattleFx.draw_dots(self, BattleFx.dot_kinds(sim, b), p, r, _time)
	match b.type_id:
		"clam": # The shell clamps shut, then springs open.
			var open_ticks: int = sim.tick - int(b.state.get("shut_until", -1000))
			if open_ticks < 0: # Snaps shut over the first few frames.
				var shut_ticks: float = b.def.get("shut_secs", 1.0) * MatchSim.TICK_RATE + open_ticks
				BattleFx.draw_clam_shell(self, p, r, minf(1.0, shut_ticks / (0.12 * MatchSim.TICK_RATE)), _time)
			elif open_ticks < int(0.3 * MatchSim.TICK_RATE):
				BattleFx.draw_clam_shell(self, p, r, 1.0 - open_ticks / (0.3 * MatchSim.TICK_RATE), _time)
		"brewster":
			BattleFx.draw_cauldron(self, p, r, _time)
		"drako":
			BattleFx.draw_stoke(self, p, r, int(b.state.get("stacks", 0)) / maxf(1.0, b.def.get("stack_max", 4)), b.vel, _time)
		"gearbox":
			BattleFx.draw_cog(self, p, r, int(b.state.get("gear", 0)), int(b.def.get("gear_max", 3)), _time)
		"mammoth":
			BattleFx.draw_fur(self, p, r, BattleFx.FUR_BROWN, _time)
			BattleFx.draw_tusks(self, p, r, b.vel, _time)
		"yeti":
			BattleFx.draw_fur(self, p, r, BattleFx.FUR_SNOW, _time)
			if b.hp < b.max_hp * 0.5: # Frosty breath once it's angry.
				BattleFx.draw_frost_breath(self, p, r, b.vel, _time)
		"swarm":
			BattleFx.draw_hive(self, p, r)
		"comet":
			BattleFx.draw_comet_tail(self, p, r, b.vel, _time)
		"mortar":
			var f = sim.nearest_foe(b)
			BattleFx.draw_barrel(self, p, r, (f.pos - b.pos) if f != null else Vector2.UP, 0.0)
		"painter":
			BattleFx.draw_paint_drips(self, p, r, _time)
		"sonar":
			BattleFx.draw_bat_wings(self, p, r, _time)
		"zing":
			BattleFx.draw_wasp(self, p, r, _time)
		"zigzag":
			if b.state.has("zz"): # Charged after a hit.
				BattleFx.draw_charged(self, p, r, _time)
	if b.slow > 0.0 and not sim.stunned(b):
		BattleFx.draw_slow(self, BattleFx.slow_goo(sim, b), b.slow, p, r, _time)
	if b.def.get("grow_armor", 0.0) > 0.0 and b.mods.has("grow"): # Shelly tucked in.
		BattleFx.draw_shell(self, p, r, Color(b.def.color), _time)
	elif b.type_id == "puff" and b.mods.has("grow"): # Puffed up.
		BattleFx.draw_spines(self, p, r, Color(b.def.color), _time)
	if b.state.get("regrowing", false) and b.hp < b.max_hp: # Mossy's sparkles.
		for k in 3:
			var f := fmod(_time * 0.8 + k / 3.0, 1.0)
			Dot.circle(self, p + Vector2((k - 1) * r * 0.45, -r * (0.6 + 0.8 * f)), 4.0, Color(POP_HEAL, 0.8 * (1.0 - f)))
	var meter := 0.0 # Cogs' wind-up or Fizz's pressure: a filling arc.
	if b.mods.has("wind"):
		meter = minf(1.0, b.def.wind_step * int(b.state.get("wind", 0)) / b.def.wind_cap)
	elif b.def.has("fizz_at"):
		meter = int(b.state.get("pressure", 0)) / b.def.fizz_at
	if meter > 0.0:
		Dot.arc(self, p, r * 1.16, -PI / 2.0, -PI / 2.0 + TAU * meter, 48, Color(b.def.color, 0.9).lightened(0.35), 4.0, true)
	if not b.statuses.is_empty() and sim.vulnerable(b) > 0.0 and _soured_by(b, "pucker"):
		BattleFx.draw_sour(self, p, r, _time)
	elif not b.statuses.is_empty() and sim.vulnerable(b) > 0.0:
		for k in 5:
			var a := k * TAU / 5.0 + 0.6
			Dot.circle(self, p + Vector2(cos(a), sin(a)) * r * 0.62, r * 0.09, Color(VULNERABLE, 0.55 + 0.3 * sin(_time * 6.0 + k)))
	for key in b.statuses: # Frostfang's frost creeping over the foe.
		if str(key).begins_with("bite:") and b.statuses[key].has("stacks"):
			var src = sim.balls[int(b.statuses[key].source)]
			BattleFx.draw_frost_stacks(self, p, r, int(b.statuses[key].stacks), int(src.def.get("bite_max", 2)), _time)
	var wrapped := false
	for o in sim.balls: # Bonbon's gift wrap while it holds.
		var w: Dictionary = o.state.get("wrap", {})
		if not w.is_empty() and int(w.target) == b.index and sim.tick < int(w.pop):
			wrapped = true
			BattleFx.draw_wrap(self, p, r, _time, (int(w.pop) - sim.tick) / maxf(1.0, o.def.get("wrap_hold", 0.5) * MatchSim.TICK_RATE))
	if b.def.has("hunt_accel"): # Frostfang hunting a foe it froze.
		for o in sim.foes(b):
			if sim.stunned(o) and int(o.state.get("stun_source", -1)) == b.index:
				BattleFx.draw_frost_breath(self, p, r, b.vel, _time)
				break
	if b.type_id == "eclipse" and int(b.state.get("mode", 0)) == 1:
		BattleFx.draw_moonlight(self, p, r, _time)
	var slam: Dictionary = b.state.get("slam", {})
	if not slam.is_empty() and int(slam.get("source", -1)) >= 0 and sim.balls[int(slam.source)].type_id == "puppeteer":
		BattleFx.draw_thrown(self, p, r, b.vel, _time)
	if sim.stunned(b) and not wrapped:
		var block := Rect2(p - Vector2(r, r) * 1.1, Vector2(r, r) * 2.2)
		_rounded_rect(block, r * 0.25, Color(FROZEN, 0.35))
		_rounded_rect_outline(block, r * 0.25, Color(FROZEN, 0.9), 3.0)
		draw_line(block.position + Vector2(r * 0.3, r * 0.4), block.position + Vector2(r * 0.7, r * 0.2), Color.WHITE, 3.0, true)
	if sim.tick < int(b.state.get("marked_until", -1)):
		# Pounce's target ring: a crosshair that tightens.
		var k := 1.25 + 0.1 * sin(_time * 10.0)
		Dot.arc(self, p, r * k, 0.0, TAU, 48, Color(MARK, 0.85), 3.0, true)
		for q in 4:
			var d := Vector2.from_angle(q * TAU / 4.0)
			draw_line(p + d * r * (k - 0.2), p + d * r * (k + 0.15), Color(MARK, 0.85), 3.0, true)
	if sim.tick < int(b.state.get("heard_until", -1)): # Sonar T5 can hear it: sound arcs pulse on it.
		for q in 2:
			var f := fmod(_time * 1.5 + q * 0.5, 1.0)
			Dot.arc(self, p, r * (1.1 + 0.5 * f), -PI * 0.35, PI * 0.35, 12, Color(BattleFx.SONAR, 0.8 * (1.0 - f)), 3.0, true)
			Dot.arc(self, p, r * (1.1 + 0.5 * f), PI * 0.65, PI * 1.35, 12, Color(BattleFx.SONAR, 0.8 * (1.0 - f)), 3.0, true)
	if sim.tick < int(b.state.get("dizzy_until", -1)):
		_dizzy_stars(p, r, _time)
	if b.charge_ticks > 0 and b.vel.length() > 0.001:
		# Speed streaks behind a charging ball.
		var back: Vector2 = -b.vel.normalized()
		for q in 3:
			var side: Vector2 = back.orthogonal() * r * (q - 1) * 0.5
			draw_line(p + back * r + side, p + back * r * 2.0 + side, Color(1, 1, 1, 0.45), 3.0, true)
	if b.def.has("gear_step"):
		_pips(p + Vector2(0, r + 38.0), int(b.state.get("gear", 0)), int(b.def.gear_max), Color("a7c957"))
	if b.def.has("bulb_max"):
		BattleFx.draw_pinball(self, p, r, int(b.state.get("lit", 0)), int(b.def.bulb_max), _time)

	_draw_forms(b, p, r, s)


## Whether a live vulnerable status on `b` came from a `type_id` critter.
func _soured_by(b, type_id: String) -> bool:
	for key in b.statuses:
		var st: Dictionary = b.statuses[key]
		if st.kind == "vulnerable" and sim.tick < st.until and st.source >= 0 and st.source < sim.balls.size() and sim.balls[st.source].type_id == type_id:
			return true
	return false


## Stacks and forms: stack pips over the head (bites, faces, scoops, stokes,
## swell), Bubbles' bubble, Supernova's pre-blast flicker, Eclipse's corona
## and Kaleido's mode, and a chilled or frozen foe.
func _draw_forms(b, p: Vector2, r: float, s: float) -> void:
	var n := int(b.state.get("stacks", 0))
	var full: int = int(b.def.get("stack_max", 0))
	if full > 0 and full <= 6:
		for k in full:
			var at := p + Vector2((k - (full - 1) / 2.0) * 13.0, r + 52.0) # Under the team tag.
			Dot.circle(self, at, 4.5, Color(b.def.color, 0.9).lightened(0.4) if k < n else Color(1, 1, 1, 0.18))
		if b.def.has("fire_count") and n >= full: # Drako's throat glows.
			Dot.circle(self, p + _look[b.index] * r * 0.55, r * 0.28, Color(ZONE_COLORS.fire, 0.45 + 0.3 * sin(_time * 18.0)))
	if b.state.get("bubble", 0.0) > 0.0 and sim.tick < int(b.state.get("bubble_until", -1)):
		var left: float = (int(b.state.bubble_until) - sim.tick) / maxf(1.0, b.def.bubble_secs * sim.TICK_RATE)
		BattleFx.draw_bubble(self, p, r, _time, left)
	if b.state.get("nova_warn", false):
		var k := 0.5 + 0.5 * sin(_time * 30.0)
		Dot.circle(self, p, r * 1.3, Color("fff3c4", 0.25 + 0.35 * k))
		Dot.arc(self, p, b.def.nova_radius * s, 0.0, TAU, 72, Color("ffd6a5", 0.3 * k), 3.0, true)
	if MODE_COLORS.has(b.type_id) and (b.state.has("mode") or b.type_id == "eclipse"):
		var m := int(b.state.get("mode", 0))
		var col: Color = MODE_COLORS[b.type_id][m]
		var both: bool = sim.tick < int(b.state.get("total_until", -1))
		if b.type_id == "eclipse" and (m == 0 or both):
			var reach: float = (b.radius + b.def.sun_radius) * s
			Dot.circle(self, p, reach, Color(col, 0.08))
			for k in 12:
				var a := _time * 0.6 + k * TAU / 12.0
				draw_line(p + Vector2.from_angle(a) * r * 1.08, p + Vector2.from_angle(a) * reach, Color(col, 0.35), 3.0, true)
		Dot.arc(self, p, r * 1.07, 0.0, TAU, 48, Color(col, 0.7), 3.0, true)


## A row of meter lights under a ball: Gearbox's gears, Pinball's bulbs.
func _pips(c: Vector2, lit: int, total: int, col: Color) -> void:
	for q in total:
		var at := c + Vector2((q - (total - 1) / 2.0) * 13.0, 0)
		Dot.circle(self, at, 5.0, Color(col, 0.95) if q < lit else Color(INK, 0.8))
		Dot.arc(self, at, 5.0, 0.0, TAU, 12, Color(col, 0.6), 1.5, true)


## Puppeteer's string: a sagging glowing line from the owner to the foe.
func _draw_string(a: Vector2, b: Vector2) -> void:
	var pts := PackedVector2Array()
	var sag := minf(a.distance_to(b) * 0.12, 30.0)
	for q in 13:
		var t := q / 12.0
		pts.append(a.lerp(b, t) + Vector2(0, sag * sin(t * PI)))
	Dot.pline(self, pts, Color(STRING, 0.3), 7.0, true)
	Dot.pline(self, pts, STRING, 2.5, true)


## Stars circling the head of a knocked-out critter.
func _dizzy_stars(pos: Vector2, r: float, clock := -1.0) -> void:
	for k in 3:
		var a := (_ko_age if clock < 0.0 else clock) * 4.0 * A11y.motion() + k * TAU / 3.0
		var p := pos + Vector2(cos(a) * r * 0.75, -r * 1.05 + sin(a) * r * 0.22)
		_star(p, r * 0.16, r * 0.07, 5, Color(BURST, 0.6 + 0.4 * sin(a)))


func _hp_badge(def: Dictionary, pos: Vector2, r: float, hp: float, max_hp: float, lift := 0.0) -> void:
	var rarity: String = def.get("rarity", "common")
	var rim: Color = RARITY_COLORS.get(rarity, RARITY_COLORS.common)
	var top: float = (def.get("badge_top", 1.15) + lift) * r
	var fs := A11y.font(roundi(minf(r, 80.0) * 0.42 if def.get("boss", false) else r * 0.42))
	var text := str(maxi(0, ceili(hp)))
	var tw := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var mark_w := fs * 0.8 ## Rarity shape before the HP number.
	var w := fs * 0.45 + mark_w + tw + fs * 0.5
	var h := fs * 1.45
	var rect := Rect2(pos.x - w / 2.0, pos.y - top - h - 4.0, w, h)
	if rarity != "common":
		_rounded_rect(rect.grow(3.0), h / 2.0 + 3.0, Color(rim, 0.25))
	_rounded_rect(rect, h / 2.0, Color(10 / 255.0, 8 / 255.0, 30 / 255.0, 0.88))
	_rounded_rect_outline(rect, h / 2.0, rim, 1.0 if rarity == "common" else 2.0)
	var low := hp > 0.0 and hp < max_hp * LOW_HP_SHARE
	if low:
		# Visual twin of the low-HP heartbeat: a red pulse (steady with reduced motion).
		var beat := 1.0 if A11y.reduced_motion else 0.55 + 0.45 * absf(sin(_time * PI / 0.85))
		_rounded_rect_outline(rect.grow(4.0), h / 2.0 + 4.0, Color(POP_DAMAGE, beat), 3.0)
	var x := rect.position.x + fs * 0.45
	RarityMark.draw(self, rarity, Vector2(x + mark_w * 0.45, rect.position.y + h / 2.0), fs * 0.62, rim)
	x += mark_w
	draw_string(FONT, Vector2(x, rect.position.y + h / 2.0 + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, POP_DAMAGE.lightened(0.25) if low else Color.WHITE)


# --- Shape helpers ------------------------------------------------------------

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	var pts := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	Dot.poly(self, pts, col)


func _star(c: Vector2, r_out: float, r_in: float, points: int, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in points * 2:
		var rr := r_in if k % 2 == 1 else r_out
		var a := k * PI / points - PI / 2.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	Dot.poly(self, pts, col)


func _rounded_rect_points(r: Rect2, radius: float) -> PackedVector2Array:
	var rad := minf(radius, minf(r.size.x, r.size.y) / 2.0)
	var pts := PackedVector2Array()
	var corners := [
		[r.end - Vector2(rad, rad), 0.0], [Vector2(r.position.x + rad, r.end.y - rad), PI / 2.0],
		[r.position + Vector2(rad, rad), PI], [Vector2(r.end.x - rad, r.position.y + rad), PI * 1.5]]
	for c in corners:
		for k in 7:
			var a: float = c[1] + (PI / 2.0) * k / 6.0
			var q: Vector2 = c[0] + Vector2(cos(a), sin(a)) * rad
			# Pills have zero-length straight edges; duplicate points break triangulation.
			if pts.is_empty() or pts[pts.size() - 1].distance_to(q) > 0.01:
				pts.append(q)
	if pts.size() > 1 and pts[0].distance_to(pts[pts.size() - 1]) <= 0.01:
		pts.remove_at(pts.size() - 1)
	return pts


func _rounded_rect(r: Rect2, radius: float, col: Color) -> void:
	Dot.poly(_cv, _rounded_rect_points(r, radius), col)


func _rounded_rect_outline(r: Rect2, radius: float, col: Color, width: float) -> void:
	var pts := _rounded_rect_points(r, radius)
	pts.append(pts[0])
	Dot.pline(_cv, pts, col, width, true)


func _text_centered(pos: Vector2, text: String, size: int, color: Color, outline: int) -> void:
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline := pos + Vector2(-width / 2.0, size * 0.35)
	draw_string_outline(FONT, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(Color("0b0a1f"), color.a))
	draw_string(FONT, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
