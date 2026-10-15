## Draws a MatchSim in the Neon Critters style (design/critters.md). Holds no
## game rules: everything it shows comes from the sim's state and the events
## of each step. Effects use their own RNG and never feed back into the sim.
extends Node2D

const MatchSim := preload("res://sim/match_sim.gd")
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
	"shell": Color("ffb347"), "blob": Color("7cff6b"),
	"shards": Color("cdf3ff"), "paint": Color("ffd23f"), "confetti": Color("f15bb5"), "thunder": Color("8ecbff"),
	"bugflare": Color("e8ff7a"), "candy": Color("ff9de2"), "inkslam": Color("b36bff"), "wave": Color("5ff0e6"), "quasar": Color("e0b3ff"),
	"glitch": Color("7cff4f"), "ping": Color("b48cff"), "dirt": Color("b08968"),
	"petal": Color("ff9ecf"), "tick": Color("ffd166"), "root": Color("a5743a")}
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
const FIELD_PUSH := Color("ff4d6a")
const RARITY_COLORS := Roster.RARITY_COLORS
## Side markers so mirror matches stay readable: index 0 is always the player.
## Colour is never the only cue: the player's ring is solid, the foe's is
## dashed with four spikes, so red-green colourblind players can tell them apart.
const TEAM_COLORS := [Color("45f5a6"), Color("ff5a7a")]
const TEAM_TAGS := ["YOU", "FOE"]

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
var team_tags: Array = TEAM_TAGS ## Labels under each ball; a shared replay uses P1/P2.
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
## Field pole spin: eases 0 (Pull) <-> 1 (Push) after each flip.
var _pole_swap := [0.0, 0.0]
var _fx_rng := RandomNumberGenerator.new()
var _ko_age := 0.0
var _banner := 0.0 ## Seconds left on the OVERTIME banner.
var _was_overtime := false
var _trails: Array = [[], []] ## Recent world positions per ball, oldest first.
var _kos: Array[Dictionary] = []
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
	_trails = [[], []]
	_wisps.clear()
	_shake = 0.0
	_hit = [0.0, 0.0]
	_squash = [0.0, 0.0]
	_eye_flash = [0.0, 0.0]
	_bumper_flash = 0.0
	_pole_swap = [0.0, 0.0]
	_banner = 0.0
	_was_overtime = false
	if sim:
		for b in sim.balls:
			_look[b.index] = b.vel.normalized()


## Turns the events of the latest sim step into visual effects.
func consume_events(events: Array[Dictionary]) -> void:
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
			"heal":
				var b := sim.balls[e.target]
				_add_popup(b.pos + Vector2(48, -b.radius - 40), "+%d" % ceili(e.amount), POP_HEAL)
				var victim := sim.balls[1 - e.target]
				for i in 8:
					_wisps.append({"from": victim.pos + _rand_dir() * victim.radius * 0.5, "to": e.target, "age": -i * 0.03, "life": 0.45})
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
				_rings.append({"pos": e.pos, "radius": e.radius, "color": RING_COLORS.get(e.get("kind", "boom"), BURST), "age": 0.0})
				if e.type == "boom" or e.get("kind", "") in ["nova", "fire", "bigzap", "drum"]:
					_shake = maxf(_shake, 8.0 * A11y.motion())
					_spawn_particles(e.pos, 14)
			"reflect":
				_flashes.append({"from": e.from, "to": e.to, "age": 0.0})
			"phase":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-30, -g.radius - 34), "BOO!", POP_SNAP)
			"ambush":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-50, -g.radius - 34), "AMBUSH!", POP_SNAP)
			"copy":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-30, -g.radius - 34), "COPY!", POP_SNAP)
			"revive":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-50, -g.radius - 40), "REBORN!", POP_SNAP)
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
				var words := {"yoyo": "SWING!", "fling": "WALK THE DOG!", "hug": "HUG!", "dive": "DIVE!"}
				_add_popup(g.pos + Vector2(-40, -g.radius - 34), words[e.type], POP_SNAP)
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
				_shake = maxf(_shake, 7.0 * A11y.motion())
			"unwind":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-56, -g.radius - 34), "UNWIND!", POP_SNAP)
			"pop":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-30, -g.radius - 34), "POP!", POP_SNAP)
				_spawn_particles(g.pos, 10)
			"stun":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-40, -g.radius - 34), "FROZEN!", FROZEN)
				_spawn_particles(g.pos, 8)
			"wrap":
				var g := sim.balls[e.ball]
				_flashes.append({"from": e.from, "to": e.pos, "age": 0.0})
				_add_popup(g.pos + Vector2(-44, -g.radius - 60), "WRAPPED!", RING_COLORS.confetti)
			"wrap_pop":
				_spawn_particles(e.pos, 16)
			"shatter":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-44, -g.radius - 60), "SHATTER!", FROZEN, 1.2)
				_shake = maxf(_shake, 9.0 * A11y.motion())
				_spawn_particles(e.pos, 18)
			"storm":
				var m := sim.balls[e.ball]
				if e.sparks >= 3:
					_add_popup(m.pos + Vector2(-34, -m.radius - 34), "ZAP!", RING_COLORS.thunder)
			"stack":
				# Stacks and forms: a little squash per stack gained.
				if e.up:
					_squash[e.ball] = maxf(_squash[e.ball], 0.15)
			"burp", "breath", "shout", "roar":
				var g := sim.balls[e.ball]
				var call: String = {"burp": "BURP!", "breath": "FWOOSH!", "shout": "HOO!", "roar": "ROAR!"}[e.type]
				_add_popup(g.pos + Vector2(-48, -g.radius - 34), call, POP_SNAP)
				_shake = maxf(_shake, (8.0 if e.type == "roar" else 5.0) * A11y.motion())
			"mode":
				var g := sim.balls[e.ball]
				var names: Array = MODE_NAMES.get(g.type_id, [])
				if e.mode < names.size():
					_add_popup(g.pos + Vector2(-44, -g.radius - 34), names[e.mode], MODE_COLORS[g.type_id][e.mode])
			"bubble_pop":
				var g := sim.balls[e.ball]
				_add_popup(g.pos + Vector2(-30, -g.radius - 34), "POP!", Color("9ff3f6"))
				_rings.append({"pos": g.pos, "radius": g.radius * 1.3, "color": Color("9ff3f6"), "age": 0.0})
				_spawn_particles(g.pos, 12)
			"teleport":
				var g := sim.balls[e.ball]
				_flashes.append({"from": e.from, "to": e.to, "age": 0.0})
				_spawn_particles(e.from, 10)
				_spawn_particles(e.to, 10)
				_bursts.append({"pos": e.to, "age": 0.0, "spark": {}, "seed": 0.0})
				_squash[g.index] = 0.25
			"yank":
				_flashes.append({"from": e.from, "to": e.to, "age": 0.0})
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
				_add_popup(g.pos + Vector2(-46, -g.radius - 40), "REWIND!", POP_SNAP)
				_flashes.append({"from": e.from, "to": e.pos, "age": 0.0})
			"swap":
				_flashes.append({"from": e.from, "to": e.pos, "age": 0.0})
				_spawn_particles(e.pos, 10)
			"spin":
				var g := sim.balls[e.ball]
				var text: String = "JACKPOT!" if e.prizes.size() > 1 else PRIZE_TEXT.get(e.prizes[0], "")
				_add_popup(g.pos + Vector2(-40, -g.radius - 40), text, POP_CRIT if e.prizes.size() > 1 else POP_SNAP, 1.2 if e.prizes.size() > 1 else 1.0)
			"end":
				for b in sim.balls:
					if not b.alive():
						_spawn_particles(b.pos, 36)
						_shake = 10.0 * A11y.motion()
						var ko := _cosmetic(1 - b.index, "ko")
						if not ko.is_empty():
							_kos.append({"pos": b.pos, "r": b.radius, "item": ko, "age": 0.0, "seed": _fx_rng.randf() * 10.0})


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
	for i in 2:
		_hit[i] = maxf(0.0, _hit[i] - delta)
		_squash[i] = maxf(0.0, _squash[i] - delta)
		_eye_flash[i] = maxf(0.0, _eye_flash[i] - delta)
	_bumper_flash = maxf(0.0, _bumper_flash - delta)
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
	_bursts = _bursts.filter(func(k): return k.age < (CosmeticArt.SPARK_LIFE if k.spark else BURST_LIFE))
	for k in _kos:
		k.age += delta
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


func _rand_dir() -> Vector2:
	return Vector2.from_angle(_fx_rng.randf() * TAU)


# --- Drawing ----------------------------------------------------------------

func _draw() -> void:
	var s := view_scale
	var shake := Vector2(_fx_rng.randf_range(-1, 1), _fx_rng.randf_range(-1, 1)) * _shake if _shake > 0.0 else Vector2.ZERO
	draw_set_transform(shake)
	var full := Rect2(Vector2.ZERO, Vector2.ONE * MatchSim.ARENA_SIZE * s)
	# The menu has no fight yet; a fresh sim gives the arena's starting shape.
	var shape: MatchSim = sim if sim else MatchSim.new({"arena": preview_arena})
	var r := shape.arena_rect()
	var arena := Rect2(r.position * s, r.size * s)
	var overtime := shape.in_overtime()
	if overtime:
		_rounded_rect(full, 14.0, Color(0.35, 0.05, 0.12, 0.35))
	var border := OVERTIME_BORDER if overtime else BORDER
	var outline := shape.arena_outline()
	if outline.size() == 4:
		_rounded_rect(arena, 14.0, ARENA_FILL)
		_draw_grid(arena)
		for i in 4:
			_rounded_rect_outline(arena.grow(i * 2.0), 14.0 + i * 2.0, Color(border, 0.22 - i * 0.05), 4.0)
		_rounded_rect_outline(arena, 14.0, border, 2.5)
	else:
		for i in outline.size():
			outline[i] *= s
		draw_colored_polygon(outline, ARENA_FILL)
		_draw_grid(arena, outline)
		var closed := outline.duplicate()
		closed.append(outline[0])
		for i in 4:
			draw_polyline(closed, Color(border, 0.22 - i * 0.05), 4.0 + i * 4.0, true)
		draw_polyline(closed, border, 2.5, true)
	_draw_obstacles(shape.obstacles())

	if sim == null:
		for i in 2:
			var def := Modifiers.apply_to_def(BallDefs.get_def(preview_types[i]), preview_modifier)
			_draw_critter(i, def, MatchSim.START_CORNERS[i] * s, def.radius * s, def.hp, def.hp, shake)
		for i in 2:
			var def := BallDefs.get_def(preview_types[i])
			_draw_overlay(i, def, MatchSim.START_CORNERS[i] * s, def.radius * s, def.hp, def.hp, shake)
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
		if b.state.get("collapsing", false):
			_draw_inflow(ball_pos(b) * s, b.radius * s, b.def.collapse_range * s, Color("c58bff"), 0.45)
		if sim.tick < int(b.state.get("dive_until", -1)):
			_draw_dive(b, s)
		for item in Abilities.orb_items(sim, b):
			_draw_orb(b, item, s)

	for k in _rings:
		var t: float = k.age / RING_LIFE
		draw_arc(k.pos * s, k.radius * s * (0.3 + 0.7 * sqrt(t)), 0.0, TAU, 64, Color(k.color, 0.8 * (1.0 - t)), 6.0 * (1.0 - t) + 1.0, true)
	for k in _rays:
		var t: float = k.age / k.life
		var col: Color = RAY_COLORS.get(k.kind, BEAM)
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
		var trail := _cosmetic(b.index, "trail")
		if not trail.is_empty():
			CosmeticArt.draw_trail(self, trail, _trails[b.index].map(func(p): return p * s), b.radius * s, _time)

	for k in _bursts:
		if k.spark:
			CosmeticArt.draw_spark(self, k.spark, k.pos * s, k.age / CosmeticArt.SPARK_LIFE, 1.0, k.seed)
			continue
		var t: float = k.age / BURST_LIFE
		var grow := 70.0 if not A11y.reduced_motion else 25.0
		_star(k.pos * s, 10.0 + t * grow, 5.0 + t * grow * 0.43, 8, Color(BURST, 1.0 - t))

	if aim_dir != Vector2.ZERO:
		var b := sim.balls[0]
		for i in 12:
			draw_circle(b.pos * s + aim_dir * (b.radius + 40.0 + i * 38.0) * s, 5.0, Color(TEAM_COLORS[0], 1.0 - i / 12.0))

	if ghost_dir != Vector2.ZERO:
		_ghost_arrow(sim.balls[0], s)

	for w in _wisps:
		if w.age < 0.0:
			continue
		var t: float = w.age / w.life
		var target: Vector2 = ball_pos(sim.balls[w.to])
		var p: Vector2 = w.from.lerp(target, t * t)
		draw_circle(p * s, 6.0 * (1.0 - t) + 2.0, Color(1.0, 0.2, 0.35, 0.8 * (1.0 - t)))

	for b in sim.balls:
		if b.alive():
			_draw_critter(b.index, b.def, ball_pos(b) * s, b.radius * s, b.hp, b.max_hp, shake)
			_draw_status(b, s)
		elif b.index == ko_ball:
			_draw_critter(b.index, b.def, ball_pos(b) * s, b.radius * s, 0.0, b.max_hp, shake, true)

	for p in _particles:
		var a: float = 1.0 - p.age / p.life
		draw_circle(p.pos * s, 4.0, Color(1, 1, 1, a * 0.3))
		draw_circle(p.pos * s, 2.0, Color(1, 1, 1, a))

	for k in _kos:
		CosmeticArt.draw_ko(self, k.item, k.pos * s, k.r * s, k.age / CosmeticArt.KO_LIFE, k.seed)

	# Readability layer: team rings, tags and HP badges sit on top of every
	# cosmetic (design/monetisation.md §1 rule 3).
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
	draw_colored_polygon(PackedVector2Array([to * s, (to - ghost_dir * 46.0 + side * 30.0) * s, (to - ghost_dir * 46.0 - side * 30.0) * s]), col)


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
		draw_line(a, b, GRID, 1.0)
		return
	var hits := Geometry2D.clip_polyline_with_polygon(PackedVector2Array([a, b]), clip)
	for part in hits:
		if part.size() >= 2:
			draw_line(part[0], part[part.size() - 1], GRID, 1.0)


func _draw_obstacles(obstacles: Array[Dictionary]) -> void:
	var s := view_scale
	for o in obstacles:
		if o.has("piece"):
			continue # Placed pieces draw themselves (_draw_piece).
		var p: Vector2 = o.pos * s
		var rad: float = o.radius * s
		if o.kind == "bumper":
			var k := _bumper_flash / BUMPER_FLASH_LIFE
			var col := BUMPER.lerp(Color.WHITE, k * 0.7)
			draw_circle(p, rad, Color(BUMPER, 0.16 + 0.3 * k))
			for i in 3:
				draw_arc(p, rad + i * 3.0, 0, TAU, 56, Color(col, 0.3 - i * 0.08), 4.0 + i * 3.0, true)
			draw_arc(p, rad, 0, TAU, 56, col, 2.5, true)
			draw_circle(p, rad * 0.42, col)
		else:
			draw_circle(p + Vector2(3, 5), rad, Color(0, 0, 0, 0.35))
			draw_circle(p, rad, PILLAR.darkened(0.6))
			draw_circle(p + Vector2(-0.25, -0.3) * rad, rad * 0.45, Color(PILLAR, 0.25))
			draw_arc(p, rad + 3.0, 0, TAU, 56, Color(BORDER, 0.2), 6.0, true)
			draw_arc(p, rad, 0, TAU, 56, PILLAR.lightened(0.2), 2.5, true)


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

	draw_circle(Vector2(r * 0.08, r * 0.14), r, Color(0, 0, 0, 0.35))
	var phase := fmod(_time + i * 1.7, BLINK_PERIOD)
	var blink := sin(phase / 0.12 * PI) if phase < 0.12 else 0.0
	CritterArt.draw_critter(self, def.id, Vector2.ZERO, r, {"t": _time, "tier": tiers[i], "look": look, "blink": blink,
		"hit": minf(_hit[i], 0.12) if A11y.reduced_motion else _hit[i], "eye_flash": _eye_flash[i], "hp_frac": hp / max_hp, "pole_swap": _pole_swap[i], "ko": ko})
	var hat := _cosmetic(i, "hat")
	if not hat.is_empty():
		CosmeticArt.draw_hat(self, hat, Vector2.ZERO, r, _time)
	if ko:
		draw_set_transform(shake)
		_dizzy_stars(pos, r)

	draw_set_transform(shake)


## Team ring, tag and HP badge: drawn after everything else (cosmetics
## included), outside the squash so they stay steady and readable.
func _draw_overlay(i: int, def: Dictionary, pos: Vector2, r: float, hp: float, max_hp: float, shake: Vector2) -> void:
	var team_col: Color = TEAM_COLORS[i]
	draw_set_transform(shake)
	_team_ring(i, pos, r, team_col)
	_text_centered(pos + Vector2(0, r + 30.0), team_tags[i], A11y.font(20), team_col, 5)
	_hp_badge(def, pos, r, hp, max_hp, 0.4 if _cosmetic(i, "hat") else 0.0)


## The cosmetic `slot` worn by side `i`, as a catalog entry, or {}.
func _cosmetic(i: int, slot: String) -> Dictionary:
	if i < 0 or i >= loadouts.size():
		return {}
	return Catalog.item(str(loadouts[i].get(slot, "")))


## Solid ring for the player (index 0); dashed ring with four outward spikes
## for the foe. Shape, not just hue, tells the sides apart.
func _team_ring(i: int, pos: Vector2, r: float, col: Color) -> void:
	draw_arc(pos, r + 9.0, 0, TAU, 64, Color(col, 0.18), 9.0, true)
	if i == 0:
		draw_arc(pos, r + 7.0, 0, TAU, 64, Color(col, 0.9), 3.5, true)
		return
	var dashes := 16
	var gap := TAU / dashes
	for k in dashes:
		draw_arc(pos, r + 7.0, k * gap, k * gap + gap * 0.55, 6, Color(col, 0.9), 3.5, true)
	for k in 4:
		var d := Vector2.from_angle(PI / 4.0 + k * PI / 2.0)
		var side := d.orthogonal()
		var base := pos + d * (r + 6.0)
		draw_colored_polygon(PackedVector2Array([base + side * 6.0, base + d * 14.0, base - side * 6.0]), Color(col, 0.9))


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
		draw_arc(m.pos * s, rad * s, 0.0, TAU, 64, Color(col, 0.28 * (1.0 - f)), 3.0, true)


## Floor zones: mines blink until they blow; trails and patches fade out.
func _draw_zone(z, s: float) -> void:
	var fade: float = clampf(1.0 - z.age / z.life, 0.0, 1.0)
	var p: Vector2 = z.pos * s
	match z.kind:
		"mine":
			var armed: bool = z.armed()
			if armed:
				draw_arc(p, z.blast_radius * s, 0.0, TAU, 40, Color(MINE, 0.12), 2.0, true)
			draw_circle(p, 16.0 * s, Color("2b3a67"))
			draw_arc(p, 16.0 * s, 0.0, TAU, 20, Color("10162b"), 2.0, true)
			var on := armed and fmod(_time * 3.0 + z.pos.x * 0.01, 1.0) < 0.5
			draw_circle(p, 6.0 * s, MINE if on else Color(MINE, 0.35))
		"ring":
			draw_arc(p, z.radius * s, 0.0, TAU, 64, Color(ZONE_COLORS.ring, 0.6 * fade), 10.0 * s, true)
		"stink":
			# Rides on Whiff: lumpy green puffs drifting round it.
			for k in 6:
				var a := _time * 0.6 + k * TAU / 6.0
				draw_circle(p + Vector2(cos(a), sin(a)) * z.radius * 0.55 * s, z.radius * 0.45 * s, Color(ZONE_COLORS.stink, 0.07))
			draw_arc(p, z.radius * s, 0.0, TAU, 48, Color(ZONE_COLORS.stink, 0.25), 2.0, true)
		"rain":
			var col: Color = ZONE_COLORS.rain
			if not z.armed():
				# The warning: a dark circle with a dashed rim.
				draw_circle(p, z.radius * s, Color(0.0, 0.0, 0.08, 0.35))
				for k in 12:
					var a := k * TAU / 12.0 + _time
					draw_arc(p, z.radius * s, a, a + TAU / 24.0, 4, Color(col, 0.8), 2.0, true)
			else:
				draw_circle(p, z.radius * s, Color(col, 0.22 * fade))
				for k in 8:
					var x: float = fmod(k * 37.0 + z.pos.x, z.radius * 1.4) - z.radius * 0.7
					var y: float = fmod(_time * 500.0 + k * 53.0, z.radius * 1.6) - z.radius * 0.8
					draw_line(p + Vector2(x, y) * s, p + Vector2(x - 3.0, y + 14.0) * s, Color(col, 0.7 * fade), 2.0, true)
		"stardust":
			var col: Color = ZONE_COLORS.stardust
			draw_circle(p, z.radius * 0.6 * s, Color(col, 0.25 * fade))
			_star(p, z.radius * 0.35 * s * fade, z.radius * 0.14 * s * fade, 4, Color(col.lightened(0.4), 0.8 * fade))
		"paint":
			# Wet rainbow paint: the hue walks along the trail.
			var col := Color.from_hsv(fmod((z.pos.x + z.pos.y) * 0.0015, 1.0), 0.65, 1.0)
			draw_circle(p, z.radius * s, Color(col, 0.3 * fade))
			draw_circle(p, z.radius * 0.5 * s, Color(col, 0.25 * fade))
		"pixel":
			# Pixel's bomb: a chunky square that flickers between frames.
			var on: bool = z.armed() and fmod(_time * 4.0 + z.pos.y * 0.01, 1.0) < 0.5
			var half: float = 14.0 * s
			if z.armed():
				draw_arc(p, z.blast_radius * s, 0.0, TAU, 40, Color("7cff4f", 0.12), 2.0, true)
			draw_rect(Rect2(p - Vector2(half, half), Vector2(half, half) * 2.0), Color("1f4d12"))
			draw_rect(Rect2(p - Vector2(half, half) * 0.5, Vector2(half, half)), Color("7cff4f") if on else Color("7cff4f", 0.35))
		"clod":
			var land: float = clampf(z.age / maxf(z.arm, 0.01), 0.0, 1.0)
			draw_circle(p, z.radius * s * (0.4 + 0.6 * land), Color(ZONE_COLORS.clod, 0.25 + 0.5 * land))
		_:
			if z.follow >= 0:
				return # A clinging slow: the ball's own slow ring shows it.
			var col: Color = ZONE_COLORS.get(z.kind, Color.WHITE)
			draw_circle(p, z.radius * s, Color(col, 0.28 * fade))
			draw_circle(p, z.radius * 0.55 * s, Color(col, 0.22 * fade))


## Wind streaks flowing outward (Gust); `speed` quickens them during a huff.
func _draw_outflow(c: Vector2, inner: float, reach: float, col: Color, alpha: float, speed: float) -> void:
	for k in 3:
		var f := fmod(_time * speed + k / 3.0, 1.0)
		var r := lerpf(inner * 1.1, reach, f)
		for j in 4:
			var a := j * TAU / 4.0 + k * 0.5 + _time * 0.3
			draw_arc(c, r, a, a + 0.7, 12, Color(col, alpha * (1.0 - f)), 3.0, true)


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
		draw_arc(land, reach, 0.0, TAU, 48, Color(RING_COLORS.get(shot.kind, BURST), blink), 3.0, true)
		draw_arc(land, reach * 0.25 * (1.0 - t) + 6.0, 0.0, TAU, 24, Color(RING_COLORS.get(shot.kind, BURST), blink), 2.0, true)
		draw_circle(p, 9.0 * s, Color(0, 0, 0, 0.35))
		var lift := Vector2(0, -sin(PI * t) * 150.0 * s)
		draw_circle(p + lift, 22.0 * s, Color(col, 0.35))
		draw_circle(p + lift, 15.0 * s, col)
		draw_circle(p + lift + Vector2(-3, -3) * s, 4.0 * s, Color.WHITE)
		return
	var back: Vector2 = -shot.vel.normalized() if shot.vel.length() > 0.001 else Vector2.ZERO
	if shot.kind in ["rocket", "stinger"]:
		draw_line(p, p + back * r * 3.0, Color(Color("ffb347") if shot.kind == "rocket" else col, 0.6), r * 0.9, true)
	else:
		draw_line(p, p + back * r * 2.0, Color(col, 0.25), r * 1.2, true)
	draw_circle(p, r * 1.6, Color(col, 0.25))
	draw_circle(p, r, col)
	draw_circle(p + Vector2(-0.3, -0.3) * r, r * 0.4, Color.WHITE)


## One orbiter or attachment (sim/abilities.gd, batch E), by its look.
func _draw_orb(b, item: Dictionary, s: float) -> void:
	var p: Vector2 = item.pos * s
	var r: float = item.size * s
	var col: Color = b.def.color
	if item.has("from"):
		var thick := 10.0 if item.look == "tentacle" else 4.0
		draw_line(item.from * s, p, Color(col.lightened(0.25), 0.85), thick * s, true)
		if item.look == "wreck":
			draw_line(item.from * s, p, Color("ffe066", 0.5), 1.5, true)
	match item.look:
		"bug":
			draw_circle(p, r * 2.2, Color("eaff6a", 0.18 + 0.1 * sin(_time * 8.0)))
			draw_circle(p, r, Color("eaff6a"))
			draw_circle(p + Vector2(-r * 0.3, -r * 0.3), r * 0.4, Color.WHITE)
		"candy":
			var hues := [Color("ff5fa2"), Color("ffd23f"), Color("6ee7ff"), Color("a6ff6e")]
			draw_circle(p, r * 1.3, Color(hues[int(item.get("hue", 0)) % 4], 0.25))
			draw_circle(p, r, hues[int(item.get("hue", 0)) % 4])
			draw_arc(p, r * 0.6, _time * 4.0, _time * 4.0 + PI, 12, Color.WHITE, 2.0, true)
		"wreck":
			var big: bool = item.get("big", false)
			draw_circle(p, r * 1.25, Color("ffe066", 0.35 if big else 0.12))
			draw_circle(p, r, Color("3a3f45"))
			draw_arc(p, r, 0.0, TAU, 24, Color("ffe066"), 2.5, true)
			draw_circle(p + Vector2(-r * 0.3, -r * 0.3), r * 0.25, Color(1, 1, 1, 0.6))
		"bee":
			draw_circle(p, r, Color("ffc93c"))
			draw_line(p + Vector2(-r * 0.3, -r), p + Vector2(-r * 0.3, r), Color("2a1d05"), 2.5)
			draw_line(p + Vector2(r * 0.3, -r), p + Vector2(r * 0.3, r), Color("2a1d05"), 2.5)
			draw_circle(p + Vector2(0, -r * 0.9), r * 0.5, Color(1, 1, 1, 0.55))
		"tentacle":
			draw_circle(p, r, col.lightened(0.25))
			draw_circle(p, r * 0.45, Color("ffd6f5", 0.8))
		"segment":
			draw_circle(p, r * 1.3, Color("5ff0e6", 0.18))
			draw_circle(p, r, col.lightened(0.15))
			draw_arc(p, r * 0.7, 0.0, TAU, 20, Color("5ff0e6", 0.85), 2.5, true)
		"yoyo":
			draw_circle(p, r, Color(col, 0.55))
			draw_arc(p, r, 0.0, TAU, 24, Color("7ff3ff", 0.8), 2.0, true)
		_:
			draw_circle(p, r + 4.0 * s, Color("d9d4ff", 0.25))
			draw_circle(p, r, Color("d9d4ff"))
			draw_circle(p + Vector2(-3, -3) * s, r * 0.4, Color.WHITE)


## Leviathan's dive: a swirl where it went down and a shrinking ring where it
## will burst up.
func _draw_dive(b, s: float) -> void:
	for k in 3:
		var a := _time * 6.0 + k * TAU / 3.0
		draw_arc(b.pos * s, b.radius * s * (0.6 + 0.2 * k), a, a + PI * 0.9, 16, Color("5ff0e6", 0.6), 3.0, true)
	var t: Vector2 = b.state.get("dive_target", b.pos)
	var left: float = (int(b.state.dive_until) - sim.tick) / float(MatchSim.TICK_RATE)
	var reach: float = b.def.get("wave_radius", 200.0)
	draw_arc(t * s, reach * s, 0.0, TAU, 48, Color("5ff0e6", 0.25), 2.0, true)
	draw_arc(t * s, reach * s * clampf(left / 1.2, 0.1, 1.0), 0.0, TAU, 48, Color("5ff0e6", 0.7), 3.0, true)


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
		draw_circle(pos, p.radius * s * 1.04, Color(ARENA_FILL, 0.45))
		for f in 5:
			var a := _time * 5.0 + f * TAU / 5.0
			draw_circle(pos + Vector2(cos(a), sin(a)) * p.radius * s * 0.95, 5.0, Color("6fb7ff", 0.7 * sink))
		return
	var cols: Array = PIECE_COLORS.get(p.kind, [PILLAR.darkened(0.6), PILLAR.lightened(0.2)])
	draw_circle(pos + Vector2(3, 5) * k, rad, Color(0, 0, 0, 0.3 * k))
	draw_circle(pos, rad, Color(cols[0], 0.5 + 0.5 * k))
	draw_circle(pos + Vector2(-0.25, -0.3) * rad, rad * 0.45, Color(cols[1], 0.25))
	if p.blocking:
		draw_arc(pos, rad, 0, TAU, 40, cols[1], 2.5, true)
	else:
		for d in 10:
			draw_arc(pos, rad, d * TAU / 10.0, (d + 0.5) * TAU / 10.0, 4, Color(cols[1], 0.8), 2.0, true)
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
		var from: Vector2 = a.piece.pos * s
		var to: Vector2 = f.pos * s
		draw_line(from, to, Color("0b4f37"), 7.0, true)
		draw_line(from, to, Color("2ee59d"), 3.0, true)
		for l in 4:
			var q := from.lerp(to, (l + 0.5) / 4.0)
			_ellipse(q, 5.0, 3.0, Color("ff9ecf"))


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
			draw_arc(b.pos * s, (b.radius + b.def.prize_coin_reach) * s, 0.0, TAU, 64, Color(RAY_COLORS.coin, blink * 0.6), 2.0, true)


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
		draw_arc(c, lerpf(inner * 1.3, reach, f), 0.0, TAU, 64, Color(col, alpha * (1.0 - f)), 3.0, true)


## Per-ball status on top of the critter: phased (faded), shield, burning.
func _draw_status(b, s: float) -> void:
	var p: Vector2 = ball_pos(b) * s
	var r: float = b.radius * s
	if sim.tick < int(b.state.get("phase_until", -1)):
		draw_circle(p, r * 1.05, Color(ARENA_FILL, 0.6))
	if b.shield > 0.0:
		draw_arc(p, r * 1.12, 0.0, TAU, 48, Color("7fe6ff", 0.85), 4.0, true)
		draw_arc(p, r * 1.18, 0.0, TAU, 48, Color("7fe6ff", 0.25), 6.0, true)
	if not b.dots.is_empty():
		for k in 4:
			var a := _time * 3.0 + k * TAU / 4.0
			draw_circle(p + Vector2(cos(a), sin(a) * 0.6 - 0.4) * r * 0.9, 4.0, Color("ff8a1f", 0.8))
	if sim.tick < int(b.state.get("shut_until", -1)):
		draw_arc(p, r * 1.08, 0.0, TAU, 48, Color("f7c6d9", 0.9), 6.0, true)
	if b.slow > 0.0:
		draw_arc(p, r * 1.02, 0.0, TAU, 48, Color("bfe9ff", 0.6), 3.0, true)
	if b.def.get("grow_armor", 0.0) > 0.0 and b.mods.has("grow"): # Shelly tucked in.
		for k in 6:
			var a0 := k * TAU / 6.0
			draw_arc(p, r * 1.1, a0 + 0.08, a0 + TAU / 6.0 - 0.08, 12, Color("b7f5d6", 0.85), 5.0, true)
	if b.state.get("regrowing", false) and b.hp < b.max_hp: # Mossy's sparkles.
		for k in 3:
			var f := fmod(_time * 0.8 + k / 3.0, 1.0)
			draw_circle(p + Vector2((k - 1) * r * 0.45, -r * (0.6 + 0.8 * f)), 4.0, Color(POP_HEAL, 0.8 * (1.0 - f)))
	var meter := 0.0 # Cogs' wind-up or Fizz's pressure: a filling arc.
	if b.mods.has("wind"):
		meter = minf(1.0, b.def.wind_step * int(b.state.get("wind", 0)) / b.def.wind_cap)
	elif b.def.has("fizz_at"):
		meter = int(b.state.get("pressure", 0)) / b.def.fizz_at
	if meter > 0.0:
		draw_arc(p, r * 1.16, -PI / 2.0, -PI / 2.0 + TAU * meter, 48, Color(b.def.color, 0.9).lightened(0.35), 4.0, true)
	if not b.statuses.is_empty() and sim.vulnerable(b) > 0.0:
		for k in 5:
			var a := k * TAU / 5.0 + 0.6
			draw_circle(p + Vector2(cos(a), sin(a)) * r * 0.62, r * 0.09, Color(VULNERABLE, 0.55 + 0.3 * sin(_time * 6.0 + k)))
	if sim.stunned(b):
		var block := Rect2(p - Vector2(r, r) * 1.1, Vector2(r, r) * 2.2)
		_rounded_rect(block, r * 0.25, Color(FROZEN, 0.35))
		_rounded_rect_outline(block, r * 0.25, Color(FROZEN, 0.9), 3.0)
		draw_line(block.position + Vector2(r * 0.3, r * 0.4), block.position + Vector2(r * 0.7, r * 0.2), Color.WHITE, 3.0, true)
	if sim.tick < int(b.state.get("marked_until", -1)):
		# Pounce's target ring: a crosshair that tightens.
		var k := 1.25 + 0.1 * sin(_time * 10.0)
		draw_arc(p, r * k, 0.0, TAU, 48, Color(MARK, 0.85), 3.0, true)
		for q in 4:
			var d := Vector2.from_angle(q * TAU / 4.0)
			draw_line(p + d * r * (k - 0.2), p + d * r * (k + 0.15), Color(MARK, 0.85), 3.0, true)
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
		_pips(p + Vector2(0, r + 38.0), int(b.state.get("lit", 0)), int(b.def.bulb_max), Color("ffe066"))

	_draw_forms(b, p, r, s)


## Stacks and forms: stack pips over the head (bites, faces, scoops, stokes,
## swell), Bubbles' bubble, Supernova's pre-blast flicker, Eclipse's corona
## and Kaleido's mode, and a chilled or frozen foe.
func _draw_forms(b, p: Vector2, r: float, s: float) -> void:
	var n := int(b.state.get("stacks", 0))
	var full: int = int(b.def.get("stack_max", 0))
	if full > 0 and full <= 6:
		for k in full:
			var at := p + Vector2((k - (full - 1) / 2.0) * 13.0, r + 52.0) # Under the team tag.
			draw_circle(at, 4.5, Color(b.def.color, 0.9).lightened(0.4) if k < n else Color(1, 1, 1, 0.18))
		if b.def.has("fire_count") and n >= full: # Drako's throat glows.
			draw_circle(p + _look[b.index] * r * 0.55, r * 0.28, Color(ZONE_COLORS.fire, 0.45 + 0.3 * sin(_time * 18.0)))
	if b.state.get("bubble", 0.0) > 0.0 and sim.tick < int(b.state.get("bubble_until", -1)):
		draw_circle(p, r * 1.22, Color("9ff3f6", 0.12))
		draw_arc(p, r * 1.22, 0.0, TAU, 48, Color.from_hsv(fmod(_time * 0.4, 1.0), 0.35, 1.0, 0.8), 3.0, true)
		draw_circle(p + Vector2(-r * 0.5, -r * 0.7), r * 0.12, Color(1, 1, 1, 0.6))
	if b.state.get("nova_warn", false):
		var k := 0.5 + 0.5 * sin(_time * 30.0)
		draw_circle(p, r * 1.3, Color("fff3c4", 0.25 + 0.35 * k))
		draw_arc(p, b.def.nova_radius * s, 0.0, TAU, 72, Color("ffd6a5", 0.3 * k), 3.0, true)
	if MODE_COLORS.has(b.type_id) and (b.state.has("mode") or b.type_id == "eclipse"):
		var m := int(b.state.get("mode", 0))
		var col: Color = MODE_COLORS[b.type_id][m]
		var both: bool = sim.tick < int(b.state.get("total_until", -1))
		if b.type_id == "eclipse" and (m == 0 or both):
			var reach: float = (b.radius + b.def.sun_radius) * s
			draw_circle(p, reach, Color(col, 0.08))
			for k in 12:
				var a := _time * 0.6 + k * TAU / 12.0
				draw_line(p + Vector2.from_angle(a) * r * 1.08, p + Vector2.from_angle(a) * reach, Color(col, 0.35), 3.0, true)
		draw_arc(p, r * 1.07, 0.0, TAU, 48, Color(col, 0.7), 3.0, true)


## A row of meter lights under a ball: Gearbox's gears, Pinball's bulbs.
func _pips(c: Vector2, lit: int, total: int, col: Color) -> void:
	for q in total:
		var at := c + Vector2((q - (total - 1) / 2.0) * 13.0, 0)
		draw_circle(at, 5.0, Color(col, 0.95) if q < lit else Color(INK, 0.8))
		draw_arc(at, 5.0, 0.0, TAU, 12, Color(col, 0.6), 1.5, true)


## Puppeteer's string: a sagging glowing line from the owner to the foe.
func _draw_string(a: Vector2, b: Vector2) -> void:
	var pts := PackedVector2Array()
	var sag := minf(a.distance_to(b) * 0.12, 30.0)
	for q in 13:
		var t := q / 12.0
		pts.append(a.lerp(b, t) + Vector2(0, sag * sin(t * PI)))
	draw_polyline(pts, Color(STRING, 0.3), 7.0, true)
	draw_polyline(pts, STRING, 2.5, true)


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
	var fs := A11y.font(roundi(r * 0.42))
	var text := str(maxi(0, ceili(hp)))
	var tw := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tier := 1
	var star_w := fs * 0.62
	var mark_w := fs * 0.8 ## Rarity shape before the HP number.
	var w := fs * 0.45 + mark_w + tw + fs * 0.35 + tier * star_w + fs * 0.45
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
	for k in tier:
		_star(Vector2(x + tw + fs * 0.35 + star_w * 0.5 + k * star_w, rect.position.y + h / 2.0), fs * 0.3, fs * 0.13, 5, rim)


# --- Shape helpers ------------------------------------------------------------

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	var pts := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)


func _star(c: Vector2, r_out: float, r_in: float, points: int, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in points * 2:
		var rr := r_in if k % 2 == 1 else r_out
		var a := k * PI / points - PI / 2.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)


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
	draw_colored_polygon(_rounded_rect_points(r, radius), col)


func _rounded_rect_outline(r: Rect2, radius: float, col: Color, width: float) -> void:
	var pts := _rounded_rect_points(r, radius)
	pts.append(pts[0])
	draw_polyline(pts, col, width, true)


func _text_centered(pos: Vector2, text: String, size: int, color: Color, outline: int) -> void:
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline := pos + Vector2(-width / 2.0, size * 0.35)
	draw_string_outline(FONT, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(Color("0b0a1f"), color.a))
	draw_string(FONT, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
