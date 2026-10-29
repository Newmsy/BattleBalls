## Critter Plunge: a marble-run race where critters fight on the way down.
## 4, 6 or 8 critters drop from a gate through a seeded course of pegs,
## funnels, bumpers, forks and switchbacks; first over the line wins. Each
## critter has one race verb (VERBS) that fires on its own timer and hurts the
## racers near it. A hit staggers its target (it loses speed), which is how
## damage changes places; a racer at 0 HP is knocked out and places last.
##
## Built on the Bounce Derby race (parked PR #45). Course rules that keep the
## start fair: half-bumpers on the walls kick racers back in (a clear gutter
## let wall gates free-fall), peg rows are centred, and the seed mirrors each
## middle section. Nothing lets a racer skip course pieces (a peg-phasing
## shield won 2.4x its share). Plan and prototype numbers:
## /mnt/project-files/plunge/ (check with tools/plunge_stats.gd).
##
## Deterministic like MatchSim: the same config always gives the same race.
## Only +, *, sqrt and sim/rng.gd, so every platform agrees.
##
## Config: {seed: int, racers: [ids], powers: [float]?}. Powers (sim/power.gd
## multipliers) scale HP and race damage by their 4th root each, so HP x damage
## scales by sqrt(power): progression counts, the drop counts more.
extends RefCounted

const Rng := preload("res://sim/rng.gd")
const CritterDb := preload("res://sim/critter_db.gd")

## Bump whenever a change alters race outcomes.
const RULES_VERSION := 1
const TICK_RATE := 60
const SUBSTEPS := 3
const DT := 1.0 / TICK_RATE
const WIDTH := 1000.0
const FIELD_SIZES := [4, 6, 8]
const RADIUS := 30.0
const GRAVITY := 900.0
const MAX_SPEED := 1100.0
const DRAG := 0.35 ## Fraction of speed lost per second in the air.
const WALL_BOUNCE := 0.55
const PEG_BOUNCE := 0.6
const RAMP_BOUNCE := 0.25
const RAMP_GRIP := 0.12
const BUMPER_KICK := 620.0 ## Minimum speed a bumper sends you away at.
const RACER_BOUNCE := 0.8
const START_Y := 90.0
const GATE_SECONDS := 1.0
const TIME_LIMIT := 120.0
const AFTER_WIN := 12.0 ## Seconds the race runs on after the winner, for places.
const CELL := 100.0 ## Collision grid cell size; more than a racer's reach.
const RAMP_THICK := 6.0
const CLEAR := 100.0 ## Peg rows keep this far from the walls.
const KICKER_R := 34.0 ## The half-bumpers on the walls, one each side per peg row.

## Every racer has Derby's stall hop, so nobody wedges and loses to the course.
const STALL_SPEED := 120.0
const STALL := 0.5
const HOP_COOLDOWN := 4.0
const HOP_UP := 380.0
const HOP_SIDE := 260.0

## Damage.
const HP := 100.0
const BUMP_MIN := 260.0 ## Closing speed before a racer-on-racer bump hurts.
const BUMP_DAMAGE := 2.5 ## Per 100 px/s of closing speed over BUMP_MIN.
const STAGGER := 0.55 ## Speed kept when an ability hits you.
## The knockout knob: most damage happens in jams, so crowded fields need
## less of it. Tuned for about 1 racer in 4 knocked out.
const DAMAGE_BY_FIELD := {4: 1.25, 6: 0.9, 8: 0.68}
## In a small field a Shot usually has the leader to itself, so it hits less.
const SHOT_BY_FIELD := {4: 0.8}

## The eight race verbs. Each fires every `every` seconds (the first one
## after 40-100% of that, from the seed) unless it works on bumps.
const VERB_STATS := {
	"pulse": {"every": 4.5, "damage": 15.0, "radius": 260.0, "push": 320.0},
	"shot": {"every": 3.2, "damage": 12.0, "speed": 950.0, "range": 700.0, "life": 1.2},
	"drop": {"every": 2.8, "damage": 10.0, "life": 7.0, "pop": 250.0},
	"ram": {"damage": 11.0, "rest": 1.2},
	"hook": {"every": 4.0, "damage": 6.0, "range": 420.0, "yank": 150.0, "sling": 1.7},
	"shield": {"every": 6.0, "secs": 2.0, "block": 0.75},
	"thorns": {"damage": 8.0, "reflect": 0.6, "block": 0.15},
	"drain": {"damage": 6.0, "heal": 0.5, "regen": 0.15},
}
const VERB_NAMES := {"pulse": "Pulse", "shot": "Shot", "drop": "Drop", "ram": "Ram", "hook": "Hook",
	"shield": "Shield", "thorns": "Thorns", "drain": "Drain"}
const VERB_TEXT := {
	"pulse": "Blasts everyone near it every few seconds.",
	"shot": "Fires at the nearest racer ahead.",
	"drop": "Leaves mines for whoever comes behind.",
	"ram": "Hits hard when it bumps, and shrugs bumps off.",
	"hook": "Grabs the racer ahead and slings past.",
	"shield": "Puts up a bubble that blocks hits and knocks.",
	"thorns": "Hurts whoever hurts it.",
	"drain": "Heals off the racers it bumps.",
}
## Each critter's race verb, from what its real ability does. A critter
## missing here (a new one) gets a verb from its id; a test lists them.
const VERBS := {
	"blackhole": "pulse", "supernova": "pulse", "glacia": "pulse", "yeti": "pulse", "disco": "pulse",
	"eclipse": "pulse", "quasar": "pulse", "clockwork": "pulse", "kaleido": "pulse", "magmo": "pulse",
	"beacon": "pulse", "ripple": "pulse",
	"laser": "shot", "pip": "shot", "zing": "shot", "mortar": "shot", "sonar": "shot", "narwhal": "shot",
	"megabot": "shot", "prism": "shot", "zapper": "shot", "stormwing": "shot", "jawbreaker": "shot",
	"zigzag": "shot", "static": "shot", "painter": "shot", "pollen": "shot",
	"bomber": "drop", "frost": "drop", "sooty": "drop", "honey": "drop", "blizz": "drop", "sprout": "drop",
	"comet": "drop", "drizzle": "drop", "brewster": "drop", "tumble": "drop", "ivy": "drop", "whiff": "drop",
	"gumdrop": "drop", "swarm": "drop",
	"juggernaut": "ram", "mammoth": "ram", "wrecker": "ram", "speedster": "ram", "pinball": "ram",
	"bolt": "ram", "gearbox": "ram", "pounce": "ram", "drako": "ram", "crumb": "ram", "leviathan": "ram",
	"fizz": "ram",
	"hook": "hook", "gravity": "hook", "puppeteer": "hook", "magnet": "hook", "kraken": "hook",
	"bonbon": "hook", "yoyo": "hook", "cogs": "hook", "frostfang": "hook", "gust": "hook",
	"bubbles": "shield", "clam": "shield", "ghost": "shield", "flicker": "shield", "mole": "shield",
	"totem": "shield", "minnow": "shield", "foxfire": "shield", "pixel": "shield", "splitter": "shield",
	"shelly": "shield", "glowbug": "shield",
	"thorns": "thorns", "mirror": "thorns", "spiker": "thorns", "pucker": "thorns", "mossy": "thorns",
	"ink": "thorns", "puff": "thorns", "jackpot": "thorns", "drum": "thorns",
	"vampire": "drain", "phoenix": "drain", "munch": "drain", "old_oak": "drain", "fin": "drain",
	"sundae": "drain",
}
const SECTIONS := ["pegs", "funnel", "zigzag", "bumpers", "split"]


class Racer:
	var index: int
	var id: String
	var verb: String
	var lane: int
	var pos: Vector2
	var vel := Vector2.ZERO
	var hp := HP
	var max_hp := HP
	var potency := 1.0 ## Its race damage multiplier, from its power.
	var slow := 0.0 ## Seconds spent under STALL_SPEED.
	var rest := 0.0 ## Stall-hop cooldown left.
	var timer := 0.0 ## Seconds to its verb's next firing.
	var every := 0.0 ## Its verb's timer, 0 for verbs that work on bumps.
	var shield := 0.0 ## Shield seconds left.
	var ram_rest := 0.0
	var place := 0 ## 1 = winner; 0 while racing.
	var finish_tick := -1
	var ko_tick := -1
	var dealt := 0.0
	var taken := 0.0
	var kos := 0 ## Racers it knocked out.

	func racing() -> bool:
		return place == 0 and ko_tick < 0


var config: Dictionary
var rng: Rng
var racers: Array[Racer] = []
var pegs: Array = [] ## [{pos, r, bumper}]
var ramps: Array = [] ## [{a, b}] solid line segments, RAMP_THICK wide.
var sections: Array = [] ## [{kind, y0, y1}] for the renderer.
var shots: Array = [] ## [{pos, vel, owner, life}]
var mines: Array = [] ## [{pos, owner, life}]
var finish_y := 0.0
var tick := 0
var finished := false
var damage_scale := 1.0
var shot_scale := 1.0
var order: Array[int] = [] ## Racer indexes by place, once finished.
var kos: Array[int] = [] ## Racer indexes in the order they were knocked out.
## Events from the last step(): {type, racer, pos, ...}. Types: peg, bumper,
## bump, hop, fire (verb), hit (by, amount, kind), ko (by), finish (place).
var events: Array[Dictionary] = []

var _cells := {} ## grid cell (CELL square) -> obstacle refs (peg index, or -1 - ramp index)
var _near := {} ## grid cell -> every ref in it and the 8 cells round it, once each
const _NONE: Array = []
var _peg_pos := PackedVector2Array()
var _peg_r := PackedFloat64Array()
var _win_tick := -1


func _init(cfg: Dictionary) -> void:
	config = cfg
	var seed_value := int(cfg.get("seed", 1))
	rng = Rng.new(seed_value)
	var ids: Array = cfg.get("racers", [])
	if ids.is_empty():
		ids = draw_field(seed_value, 6)
	var powers: Array = cfg.get("powers", [])
	damage_scale = field_damage(ids.size())
	shot_scale = SHOT_BY_FIELD.get(ids.size(), 1.0)
	# Gates are shuffled by the seed so nobody picks a lane.
	var lanes := range(ids.size())
	for i in range(lanes.size() - 1, 0, -1):
		var j: int = rng.range_int(0, i)
		var t = lanes[i]
		lanes[i] = lanes[j]
		lanes[j] = t
	var lane_w := WIDTH / ids.size()
	for i in ids.size():
		var r := Racer.new()
		r.index = i
		r.id = str(ids[i])
		r.verb = verb_of(r.id)
		r.lane = lanes[i]
		r.pos = Vector2(lane_w * (lanes[i] + 0.5), START_Y)
		r.vel = Vector2(-90.0 + 180.0 * rng.next_float(), 60.0 * rng.next_float())
		var power: float = float(powers[i]) if i < powers.size() else 1.0
		var k := sqrt(sqrt(maxf(0.01, power)))
		r.max_hp = HP * k
		r.hp = r.max_hp
		r.potency = k
		r.every = float(VERB_STATS[r.verb].get("every", 0.0))
		r.timer = r.every * (0.4 + 0.6 * rng.next_float())
		racers.append(r)
	_build_course(Rng.new(seed_value * 7919 + 1))


static func verb_of(id: String) -> String:
	if VERBS.has(id):
		return VERBS[id]
	return VERB_STATS.keys()[posmod(id.hash(), VERB_STATS.size())]


## The damage multiplier for a field of `n` racers (between the tuned sizes
## it is interpolated).
static func field_damage(n: int) -> float:
	if DAMAGE_BY_FIELD.has(n):
		return DAMAGE_BY_FIELD[n]
	if n <= 4:
		return DAMAGE_BY_FIELD[4]
	if n >= 8:
		return DAMAGE_BY_FIELD[8]
	var lo := 4 if n < 6 else 6
	var hi := 6 if n < 6 else 8
	return lerpf(DAMAGE_BY_FIELD[lo], DAMAGE_BY_FIELD[hi], float(n - lo) / float(hi - lo))


## `n` different critters for a seed, never one in `exclude`.
static func draw_field(seed_value: int, n: int, exclude: Array = []) -> Array:
	var r := Rng.new(seed_value * 31 + 7)
	var pool: Array = []
	for id in CritterDb.live_ids():
		if not exclude.has(id):
			pool.append(id)
	var out := []
	while out.size() < n and not pool.is_empty():
		out.append(pool.pop_at(r.range_int(0, pool.size() - 1)))
	return out


func time() -> float:
	return tick * DT


## How far down the course a racer is, 0 at the gate to 1 at the finish.
func progress(r: Racer) -> float:
	return 1.0 if r.place > 0 and r.ko_tick < 0 else clampf((r.pos.y - START_Y) / (finish_y - START_Y), 0.0, 1.0)


## Racer indexes in race order: finished racers by place, then those still
## racing by how far down they are, then the knocked out (latest first).
func standings() -> Array[int]:
	if finished:
		return order.duplicate()
	var out: Array[int] = order.duplicate()
	var rest: Array = racers.filter(func(r): return r.racing())
	rest.sort_custom(func(a, b): return a.pos.y > b.pos.y if a.pos.y != b.pos.y else a.index < b.index)
	for r in rest:
		out.append(r.index)
	for i in range(kos.size() - 1, -1, -1):
		out.append(kos[i])
	return out


func winner() -> int:
	return order[0] if not order.is_empty() else -1


func step() -> void:
	if finished:
		return
	events.clear()
	tick += 1
	if time() >= GATE_SECONDS:
		var dt := DT / SUBSTEPS
		for s in SUBSTEPS:
			for r in racers:
				if not r.racing():
					continue
				r.vel.y += GRAVITY * dt
				r.vel *= 1.0 - DRAG * dt
				var sp := r.vel.length()
				if sp > MAX_SPEED:
					r.vel *= MAX_SPEED / sp
				r.pos += r.vel * dt
				_collide_walls(r)
				_collide_course(r, dt)
			_collide_racers()
			for r in racers:
				if r.racing() and r.pos.y >= finish_y:
					_finish(r)
		_move_shots()
		_move_mines()
		for r in racers:
			if not r.racing():
				continue
			r.shield = maxf(0.0, r.shield - DT)
			r.ram_rest -= DT
			if r.verb == "drain":
				r.hp = minf(r.max_hp, r.hp + VERB_STATS.drain.regen * DT)
			r.rest = maxf(0.0, r.rest - DT)
			r.slow = r.slow + DT if r.vel.length() < STALL_SPEED else 0.0
			if r.slow >= STALL and r.rest <= 0.0:
				r.rest = HOP_COOLDOWN
				r.slow = 0.0
				r.vel.y -= HOP_UP
				r.vel.x += HOP_SIDE if r.pos.x < WIDTH / 2.0 else -HOP_SIDE
				events.append({"type": "hop", "racer": r.index, "pos": r.pos})
			if r.every > 0.0:
				r.timer -= DT
				if r.timer <= 0.0:
					r.timer = r.every
					_fire(r)
	if order.size() + kos.size() == racers.size() or time() >= TIME_LIMIT or (_win_tick >= 0 and tick - _win_tick >= int(AFTER_WIN * TICK_RATE)):
		_settle()


## Runs the race to the end and returns {order, kos, time, win_time}.
func run() -> Dictionary:
	while not finished:
		step()
	return {"order": order.duplicate(), "kos": kos.duplicate(), "time": time(), "win_time": _win_tick * DT if _win_tick >= 0 else time()}


## Places everyone left: those still racing by how far down they got, then
## the knocked out, the latest knockout highest.
func _settle() -> void:
	var rest: Array = racers.filter(func(r): return r.racing())
	rest.sort_custom(func(a, b): return a.pos.y > b.pos.y if a.pos.y != b.pos.y else a.index < b.index)
	for r in rest:
		order.append(r.index)
		r.place = order.size()
	for i in range(kos.size() - 1, -1, -1):
		order.append(kos[i])
		racers[kos[i]].place = order.size()
	finished = true


func _finish(r: Racer) -> void:
	order.append(r.index)
	r.place = order.size()
	r.finish_tick = tick
	if _win_tick < 0:
		_win_tick = tick
	events.append({"type": "finish", "racer": r.index, "place": r.place, "pos": r.pos})


# --- Damage --------------------------------------------------------------------

## `amount` before the field's damage scale; `raw` skips it (a reflection,
## already scaled once).
func _hurt(v: Racer, amount: float, by: Racer, kind: String, raw := false) -> void:
	if not v.racing() or amount <= 0.0:
		return
	if not raw:
		amount *= damage_scale
	if v.shield > 0.0:
		amount *= 1.0 - VERB_STATS.shield.block
	if v.verb == "thorns":
		amount *= 1.0 - VERB_STATS.thorns.block
	v.hp -= amount
	v.taken += amount
	events.append({"type": "hit", "racer": v.index, "by": by.index if by != null else -1, "amount": amount, "kind": kind, "pos": v.pos})
	if by != null:
		by.dealt += amount
		if by.verb == "drain" and kind == "bump" and by.racing():
			by.hp = minf(by.max_hp, by.hp + amount * VERB_STATS.drain.heal)
		if v.verb == "thorns" and kind != "thorns" and by.racing():
			_hurt(by, amount * VERB_STATS.thorns.reflect, v, "thorns", true)
	if kind != "bump" and v.shield <= 0.0:
		v.vel *= STAGGER
	if v.hp <= 0.0 and v.ko_tick < 0:
		v.hp = 0.0
		v.ko_tick = tick
		kos.append(v.index)
		if by != null:
			by.kos += 1
		events.append({"type": "ko", "racer": v.index, "by": by.index if by != null else -1, "pos": v.pos})


func _fire(r: Racer) -> void:
	var st: Dictionary = VERB_STATS[r.verb]
	var others: Array = racers.filter(func(o): return o != r and o.racing())
	if others.is_empty():
		return
	match r.verb:
		"pulse":
			events.append({"type": "fire", "racer": r.index, "verb": r.verb, "pos": r.pos, "radius": st.radius})
			for o in others:
				var d: Vector2 = o.pos - r.pos
				var dist := d.length()
				if dist < st.radius + RADIUS:
					_hurt(o, st.damage * r.potency, r, "pulse")
					if dist > 1.0:
						var n := d / dist
						o.vel += Vector2(n.x, n.y * 0.5) * st.push
		"shot":
			var ahead: Array = others.filter(func(o): return o.pos.y > r.pos.y)
			var o: Racer = _nearest(r, ahead if not ahead.is_empty() else others)
			var d: Vector2 = o.pos - r.pos
			var dist := d.length()
			if dist < st.range and dist > 1.0:
				shots.append({"pos": r.pos, "vel": d / dist * st.speed + o.vel * 0.5, "owner": r.index, "life": st.life})
				events.append({"type": "fire", "racer": r.index, "verb": r.verb, "pos": r.pos, "target": o.index})
		"drop":
			mines.append({"pos": r.pos + Vector2(0, -10), "owner": r.index, "life": st.life})
			events.append({"type": "fire", "racer": r.index, "verb": r.verb, "pos": r.pos})
		"hook":
			var ahead: Array = others.filter(func(o): return o.pos.y > r.pos.y)
			if ahead.is_empty():
				return
			var o: Racer = _nearest(r, ahead)
			var d: Vector2 = r.pos - o.pos
			var dist := d.length()
			if dist < st.range and dist > 1.0:
				var n := d / dist
				events.append({"type": "fire", "racer": r.index, "verb": r.verb, "pos": r.pos, "target": o.index})
				_hurt(o, st.damage * r.potency, r, "hook")
				o.vel += n * st.yank
				r.vel -= n * st.yank * st.sling
		"shield":
			r.shield = st.secs
			events.append({"type": "fire", "racer": r.index, "verb": r.verb, "pos": r.pos})


func _nearest(r: Racer, pool: Array) -> Racer:
	var best: Racer = pool[0]
	var best_d := INF
	for o in pool:
		var dd: float = (o.pos - r.pos).length_squared()
		if dd < best_d:
			best_d = dd
			best = o
	return best


func _move_shots() -> void:
	var keep: Array = []
	for s in shots:
		s.pos += s.vel * DT
		s.life -= DT
		var hit: Racer = null
		for o in racers:
			if o.index != s.owner and o.racing() and (o.pos - s.pos).length_squared() < (RADIUS + 10.0) * (RADIUS + 10.0):
				hit = o
				break
		if hit != null:
			var owner: Racer = racers[s.owner]
			_hurt(hit, VERB_STATS.shot.damage * shot_scale * owner.potency, owner, "shot")
		elif s.life > 0.0 and s.pos.x >= 0.0 and s.pos.x <= WIDTH:
			keep.append(s)
	shots = keep


func _move_mines() -> void:
	var keep: Array = []
	for m in mines:
		m.life -= DT
		var hit: Racer = null
		for o in racers:
			if o.index != m.owner and o.racing() and (o.pos - m.pos).length_squared() < (RADIUS + 16.0) * (RADIUS + 16.0):
				hit = o
				break
		if hit != null:
			var owner: Racer = racers[m.owner]
			_hurt(hit, VERB_STATS.drop.damage * owner.potency, owner, "drop")
			hit.vel.y -= VERB_STATS.drop.pop
		elif m.life > 0.0:
			keep.append(m)
	mines = keep


# --- Collisions ----------------------------------------------------------------

func _collide_walls(r: Racer) -> void:
	if r.pos.x < RADIUS:
		r.pos.x = RADIUS
		r.vel.x = absf(r.vel.x) * WALL_BOUNCE
	elif r.pos.x > WIDTH - RADIUS:
		r.pos.x = WIDTH - RADIUS
		r.vel.x = -absf(r.vel.x) * WALL_BOUNCE
	if r.pos.y < RADIUS:
		r.pos.y = RADIUS
		r.vel.y = absf(r.vel.y)


func _collide_course(r: Racer, dt: float) -> void:
	for ref in _near.get(_cell(int(floorf(r.pos.x / CELL)), int(floorf(r.pos.y / CELL))), _NONE):
		if ref >= 0:
			# Most pegs in reach of the band are not touching: a cheap test first.
			var reach: float = RADIUS + _peg_r[ref]
			var d := r.pos - _peg_pos[ref]
			if d.x >= reach or d.x <= -reach or d.y >= reach or d.y <= -reach:
				continue
			_hit_peg(r, pegs[ref])
		else:
			_hit_ramp(r, ramps[-ref - 1], dt)


func _hit_peg(r: Racer, p: Dictionary) -> void:
	var d: Vector2 = r.pos - p.pos
	var reach: float = RADIUS + p.r
	var dist2 := d.length_squared()
	if dist2 >= reach * reach or dist2 < 0.0001:
		return
	var dist := sqrt(dist2)
	var n := d / dist
	r.pos = p.pos + n * reach
	var vn := r.vel.dot(n)
	if vn >= 0.0:
		return
	if p.bumper:
		var out := maxf(-vn * PEG_BOUNCE, BUMPER_KICK)
		r.vel += n * (out - vn)
		events.append({"type": "bumper", "racer": r.index, "pos": p.pos})
	else:
		r.vel -= n * vn * (1.0 + PEG_BOUNCE)
		if -vn > 200.0:
			events.append({"type": "peg", "racer": r.index, "pos": p.pos})


func _hit_ramp(r: Racer, s: Dictionary, dt: float) -> void:
	var a: Vector2 = s.a
	var ab: Vector2 = s.b - a
	var t := clampf((r.pos - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var closest := a + ab * t
	var d := r.pos - closest
	var reach := RADIUS + RAMP_THICK
	var dist2 := d.length_squared()
	if dist2 >= reach * reach or dist2 < 0.0001:
		return
	var dist := sqrt(dist2)
	var n := d / dist
	r.pos = closest + n * reach
	var vn := r.vel.dot(n)
	if vn < 0.0:
		r.vel -= n * vn * (1.0 + RAMP_BOUNCE)
	var tangent := r.vel - n * r.vel.dot(n)
	r.vel -= tangent * minf(1.0, RAMP_GRIP * dt)


func _collide_racers() -> void:
	for i in racers.size():
		var a := racers[i]
		if not a.racing():
			continue
		for j in range(i + 1, racers.size()):
			var b := racers[j]
			if not b.racing():
				continue
			var d := b.pos - a.pos
			if d.x >= 2.0 * RADIUS or d.x <= -2.0 * RADIUS or d.y >= 2.0 * RADIUS or d.y <= -2.0 * RADIUS:
				continue
			var dist2 := d.length_squared()
			if dist2 >= 4.0 * RADIUS * RADIUS or dist2 < 0.0001:
				continue
			var dist := sqrt(dist2)
			var n := d / dist
			var overlap := 2.0 * RADIUS - dist
			a.pos -= n * overlap * 0.5
			b.pos += n * overlap * 0.5
			var vn := (b.vel - a.vel).dot(n)
			if vn >= 0.0:
				continue
			var impulse := -vn * (1.0 + RACER_BOUNCE) * 0.5
			a.vel -= n * impulse
			b.vel += n * impulse
			var over := -vn - BUMP_MIN
			if over <= 0.0:
				continue
			events.append({"type": "bump", "racer": i, "other": j, "pos": (a.pos + b.pos) * 0.5})
			var base := BUMP_DAMAGE * over / 100.0
			_bump(a, b, base)
			_bump(b, a, base)


## `x` bumps `y` hard: the bump's damage plus x's verb on bumps.
func _bump(x: Racer, y: Racer, base: float) -> void:
	var extra := 0.0
	if x.verb == "ram" and x.ram_rest <= 0.0:
		extra = VERB_STATS.ram.damage
		x.ram_rest = VERB_STATS.ram.rest
	elif x.verb == "drain" or x.verb == "thorns":
		extra = VERB_STATS[x.verb].damage
	_hurt(y, base * (0.5 if y.verb == "ram" else 1.0) + extra * x.potency, x, "bump")


# --- Course --------------------------------------------------------------------

## A peg field under the gate, five seeded sections (no kind twice in a row,
## each mirrored left-right on a coin flip) and a peg field before the finish.
func _build_course(crng: Rng) -> void:
	var y := START_Y + 120.0
	y = _section(crng, "pegs", y)
	var last := "pegs"
	for k in 5:
		var kind: String = SECTIONS[crng.range_int(0, SECTIONS.size() - 1)]
		while kind == last:
			kind = SECTIONS[crng.range_int(0, SECTIONS.size() - 1)]
		var p0 := pegs.size()
		var r0 := ramps.size()
		y = _section(crng, kind, y)
		last = kind
		if crng.range_int(0, 1) == 1:
			for q in range(p0, pegs.size()):
				pegs[q].pos = Vector2(WIDTH - pegs[q].pos.x, pegs[q].pos.y)
			for q in range(r0, ramps.size()):
				ramps[q].a = Vector2(WIDTH - ramps[q].a.x, ramps[q].a.y)
				ramps[q].b = Vector2(WIDTH - ramps[q].b.x, ramps[q].b.y)
	y = _section(crng, "pegs", y)
	finish_y = y + 80.0
	for i in pegs.size():
		var p: Dictionary = pegs[i]
		_bucket(i, p.pos - Vector2.ONE * p.r, p.pos + Vector2.ONE * p.r)
		_peg_pos.append(p.pos)
		_peg_r.append(p.r)
	for i in ramps.size():
		var s: Dictionary = ramps[i]
		_bucket(-i - 1, Vector2(minf(s.a.x, s.b.x), minf(s.a.y, s.b.y)) - Vector2.ONE * RAMP_THICK, Vector2(maxf(s.a.x, s.b.x), maxf(s.a.y, s.b.y)) + Vector2.ONE * RAMP_THICK)
	# A racer touches what is within RADIUS of it: one cell all round covers it.
	for key in _cells:
		var cx: int = key % 64 - 8
		var cy: int = key / 64
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				var k := _cell(cx + dx, cy + dy)
				if not _near.has(k):
					_near[k] = []
				for ref in _cells[key]:
					if not _near[k].has(ref):
						_near[k].append(ref)


func _bucket(ref: int, lo: Vector2, hi: Vector2) -> void:
	for cy in range(int(floorf(lo.y / CELL)), int(floorf(hi.y / CELL)) + 1):
		for cx in range(int(floorf(lo.x / CELL)), int(floorf(hi.x / CELL)) + 1):
			var k := _cell(cx, cy)
			if not _cells.has(k):
				_cells[k] = []
			_cells[k].append(ref)


static func _cell(cx: int, cy: int) -> int:
	return cy * 64 + cx + 8


func _peg(x: float, y: float, r := 12.0, bumper := false) -> void:
	pegs.append({"pos": Vector2(x, y), "r": r, "bumper": bumper})


## A row of pegs `gap` apart between `lo` and `hi`, centred between them so
## both sides get the same gap; `half` rows sit half a gap over.
func _peg_row(lo: float, hi: float, y: float, gap: float, half: bool) -> void:
	var c := (lo + hi) / 2.0
	var m := 0.5 if half else 0.0
	var q := -int((hi - lo) / gap) - 1
	while q <= int((hi - lo) / gap) + 1:
		var x := c + (q + m) * gap
		if x >= lo and x <= hi:
			_peg(x, y)
		q += 1


## Adds one section starting at `y0` and returns where the next one starts.
func _section(crng: Rng, kind: String, y0: float) -> float:
	var h := 0.0
	match kind:
		"pegs":
			# Staggered rows, with a half-bumper on each wall per row.
			var rows := crng.range_int(5, 7)
			var gap := float(crng.range_int(110, 130))
			for row in rows:
				var ry := y0 + 40.0 + row * 96.0
				_peg_row(CLEAR, WIDTH - CLEAR, ry, gap, row % 2 == 1)
				_peg(0.0, ry, KICKER_R, true)
				_peg(WIDTH, ry, KICKER_R, true)
			h = rows * 96.0 + 40.0
		"funnel":
			# Two walls squeeze everyone through one gap: jams and shoves.
			var mouth := float(crng.range_int(150, 190))
			var cx := float(crng.range_int(380, 620))
			var depth := float(crng.range_int(300, 380))
			_ramp(0.0, y0, cx - mouth / 2.0, y0 + depth)
			_ramp(WIDTH, y0, cx + mouth / 2.0, y0 + depth)
			_peg(cx, y0 + depth + 130.0, 20.0, true)
			h = depth + 230.0
		"zigzag":
			# Switchback ramps: long rolls where the lead can change.
			var turns := crng.range_int(3, 4)
			var drop := float(crng.range_int(150, 175))
			for t in turns:
				var ty := y0 + 40.0 + t * drop
				if t % 2 == 0:
					_ramp(0.0, ty, WIDTH - 190.0, ty + drop * 0.55)
				else:
					_ramp(WIDTH, ty, 190.0, ty + drop * 0.55)
			h = turns * drop + 120.0
		"bumpers":
			# A garden of bumpers that fling racers about.
			var count := crng.range_int(5, 7)
			var placed: Array[Vector2] = []
			var tries := 0
			h = 640.0
			while placed.size() < count and tries < 200:
				tries += 1
				var p := Vector2(crng.range_int(110, 890), y0 + crng.range_int(90, int(h) - 90))
				if placed.all(func(q): return q.distance_to(p) >= 210.0):
					placed.append(p)
					_peg(p.x, p.y, 36.0, true)
		"split":
			# A divider: a quick peg lane on one side, a long ramp on the other.
			var left_fast := crng.range_int(0, 1) == 0
			h = 640.0
			_ramp(WIDTH / 2.0, y0 + 40.0, WIDTH / 2.0, y0 + h - 60.0)
			var lo := 0.0 if left_fast else WIDTH / 2.0
			for row in 5:
				_peg_row(lo + CLEAR, lo + WIDTH / 2.0 - CLEAR, y0 + 110.0 + row * 100.0, 105.0, row % 2 == 1)
			if left_fast:
				_ramp(WIDTH, y0 + 140.0, WIDTH / 2.0 + 120.0, y0 + 300.0)
				_ramp(WIDTH / 2.0, y0 + 420.0, WIDTH - 120.0, y0 + 560.0)
			else:
				_ramp(0.0, y0 + 140.0, WIDTH / 2.0 - 120.0, y0 + 300.0)
				_ramp(WIDTH / 2.0, y0 + 420.0, 120.0, y0 + 560.0)
	sections.append({"kind": kind, "y0": y0, "y1": y0 + h})
	return y0 + h


func _ramp(ax: float, ay: float, bx: float, by: float) -> void:
	ramps.append({"a": Vector2(ax, ay), "b": Vector2(bx, by)})
