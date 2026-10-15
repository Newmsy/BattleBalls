## Bounce Derby: a no-combat marble race. Critters drop from a starting gate
## and bounce down a course of pegs, bumpers, ramps and funnels; first over
## the finish line wins. Players only predict the winner, so nothing here is
## a fight and nothing reads ball_defs.gd stats: every racer has the same size
## and weight, and one "race trick" that fires when it stalls.
##
## Deterministic like MatchSim: the same config always gives the same race,
## so a race replays from its seed (plus the racer list when it was pinned).
## No trig, no engine physics, no clock: only +, *, sqrt and sim/rng.gd, so
## every platform agrees.
##
## Config: { seed: int, racers: [ids]? } — racers default to RACERS critters
## drawn from the roster by the seed.
extends RefCounted

const Rng := preload("res://sim/rng.gd")

## Bump whenever a change alters race outcomes, so old share links can say
## they no longer replay.
const RULES_VERSION := 1
const TICK_RATE := 60
const SUBSTEPS := 3
const DT := 1.0 / TICK_RATE
const WIDTH := 1000.0
const RACERS := 6
const RADIUS := 30.0
const GRAVITY := 900.0
const MAX_SPEED := 1100.0
const DRAG := 0.35 ## Fraction of speed lost per second in the air.
const WALL_BOUNCE := 0.55
const PEG_BOUNCE := 0.6
const RAMP_BOUNCE := 0.25
const RAMP_GRIP := 0.12 ## Fraction of sliding speed lost per second on a ramp.
const BUMPER_KICK := 620.0 ## Minimum speed a bumper sends you away at.
const RACER_BOUNCE := 0.8
const START_Y := 90.0
const GATE_SECONDS := 1.0 ## Racers hang in the gate this long before the drop.
const TIME_LIMIT := 120.0
const AFTER_WIN := 12.0 ## Seconds the race runs on after the winner, for places.
const BAND := 100.0 ## Height of a collision bucket.

## Race tricks: each fires when its racer has been slow for STALL seconds,
## then rests for COOLDOWN. All three are worth about the same (the fairness
## test in tests/test_derby.gd holds every critter to a fair share of wins).
const STALL_SPEED := 120.0
const STALL := 0.5
const COOLDOWN := 4.0
const BOOST_KICK := 420.0 ## "boost": a straight shove down.
const PHASE_TIME := 0.6 ## "phase": ghost through pegs and bumpers.
const HOP_UP := 380.0 ## "hop": a jump up and towards the middle.
const HOP_SIDE := 260.0
const TRICK_NAMES := {"boost": "Boost", "phase": "Phase", "hop": "Hop"}
const TRICK_TEXT := {
	"boost": "Shoves itself downhill when it stalls.",
	"phase": "Ghosts through pegs when it stalls.",
	"hop": "Hops out of jams when it stalls.",
}
## Every Neon Critter, with the trick that suits it. A critter missing here
## (a new one) gets a trick from its id.
const TRICKS := {
	"vampire": "hop", "juggernaut": "boost", "spiker": "hop", "speedster": "boost",
	"laser": "boost", "bomber": "boost", "frost": "phase", "thorns": "hop",
	"splitter": "hop", "ghost": "phase", "gravity": "phase", "mirror": "phase",
	"blackhole": "phase", "phoenix": "boost", "prism": "hop",
}
const POOL := ["vampire", "juggernaut", "spiker", "speedster", "laser", "bomber", "frost", "thorns",
	"splitter", "ghost", "gravity", "mirror", "blackhole", "phoenix", "prism"]
const SECTIONS := ["pegs", "funnel", "zigzag", "bumpers", "split"]


class Racer:
	var index: int
	var id: String
	var trick: String
	var pos: Vector2
	var vel := Vector2.ZERO
	var slow := 0.0 ## Seconds spent under STALL_SPEED.
	var rest := 0.0 ## Trick cooldown left.
	var phase := 0.0 ## Phase time left.
	var place := 0 ## 1 = winner; 0 while racing.
	var finish_tick := -1
	var tricks_used := 0


var config: Dictionary
var rng: Rng
var racers: Array[Racer] = []
var pegs: Array = [] ## [{pos, r, bumper}]
var ramps: Array = [] ## [{a, b}] solid line segments, RAMP_THICK wide.
var sections: Array = [] ## [{kind, y0, y1}] for the renderer.
var finish_y := 0.0
var tick := 0
var finished := false
var order: Array[int] = [] ## Racer indexes by finishing place.
## Events from the last step(): {type: "peg"|"bumper"|"trick"|"finish"|"bump", racer, pos, ...}.
var events: Array[Dictionary] = []

const RAMP_THICK := 6.0
## Pegs keep this far from walls and dividers: the gap beats a racer's width.
const CLEAR := 100.0
var _bands := {} ## band index -> obstacle refs [kind, i]
var _win_tick := -1


func _init(cfg: Dictionary) -> void:
	config = cfg
	rng = Rng.new(int(cfg.get("seed", 1)))
	var ids: Array = cfg.get("racers", [])
	if ids.is_empty():
		ids = draw_racers(int(cfg.get("seed", 1)))
	# Lanes are shuffled by the seed so nobody always gets the same gate.
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
		r.id = ids[i]
		r.trick = trick_of(r.id)
		r.pos = Vector2(lane_w * (lanes[i] + 0.5), START_Y)
		r.vel = Vector2(rng.range_int(-90, 90), rng.range_int(0, 60))
		racers.append(r)
	_build_course()


## The racers for a seed: RACERS different critters from POOL.
static func draw_racers(seed_value: int) -> Array:
	var rng := Rng.new(seed_value * 31 + 7)
	var pool: Array = POOL.duplicate()
	var out := []
	while out.size() < RACERS:
		out.append(pool.pop_at(rng.range_int(0, pool.size() - 1)))
	return out


static func trick_of(id: String) -> String:
	if TRICKS.has(id):
		return TRICKS[id]
	return ["boost", "phase", "hop"][posmod(id.hash(), 3)]


func time() -> float:
	return tick * DT


## How far down the course a racer is, 0 at the gate to 1 at the finish.
func progress(r: Racer) -> float:
	return 1.0 if r.place > 0 else clampf((r.pos.y - START_Y) / (finish_y - START_Y), 0.0, 1.0)


## Racer indexes in race order: finished racers by place, then the rest by
## how far down they are.
func standings() -> Array[int]:
	var out: Array[int] = order.duplicate()
	var rest: Array = racers.filter(func(r): return r.place == 0)
	rest.sort_custom(func(a, b): return a.pos.y > b.pos.y if a.pos.y != b.pos.y else a.index < b.index)
	for r in rest:
		out.append(r.index)
	return out


func winner() -> int:
	return order[0] if not order.is_empty() else -1


func step() -> void:
	if finished:
		return
	events.clear()
	tick += 1
	if time() < GATE_SECONDS:
		return
	var dt := DT / SUBSTEPS
	for s in SUBSTEPS:
		for r in racers:
			if r.place > 0:
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
			if r.place == 0 and r.pos.y >= finish_y:
				_finish(r)
	for r in racers:
		if r.place > 0:
			continue
		r.phase = maxf(0.0, r.phase - DT)
		r.rest = maxf(0.0, r.rest - DT)
		r.slow = r.slow + DT if r.vel.length() < STALL_SPEED else 0.0
		if r.slow >= STALL and r.rest <= 0.0:
			_trick(r)
	if order.size() == racers.size() or time() >= TIME_LIMIT or (_win_tick >= 0 and tick - _win_tick >= int(AFTER_WIN * TICK_RATE)):
		# Whoever is still on the course is placed by how far down they got.
		for i in standings():
			if racers[i].place == 0:
				racers[i].place = order.size() + 1
				order.append(i)
		finished = true


## Runs the race to the end and returns {order, time, ticks}.
func run() -> Dictionary:
	while not finished:
		step()
	return {"order": order.duplicate(), "time": time(), "win_time": _win_tick * DT if _win_tick >= 0 else time()}


func _finish(r: Racer) -> void:
	order.append(r.index)
	r.place = order.size()
	r.finish_tick = tick
	if _win_tick < 0:
		_win_tick = tick
	events.append({"type": "finish", "racer": r.index, "place": r.place, "pos": r.pos})


func _trick(r: Racer) -> void:
	r.rest = COOLDOWN
	r.slow = 0.0
	r.tricks_used += 1
	match r.trick:
		"boost":
			r.vel.y += BOOST_KICK
		"phase":
			r.phase = PHASE_TIME
		"hop":
			r.vel.y -= HOP_UP
			r.vel.x += HOP_SIDE if r.pos.x < WIDTH / 2.0 else -HOP_SIDE
	events.append({"type": "trick", "racer": r.index, "trick": r.trick, "pos": r.pos})


# --- Collisions ------------------------------------------------------------------

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
	var b0 := int(floorf((r.pos.y - RADIUS - 60.0) / BAND))
	var b1 := int(floorf((r.pos.y + RADIUS + 60.0) / BAND))
	var seen := {}
	for band in range(b0, b1 + 1):
		for ref in _bands.get(band, []):
			if seen.has(ref):
				continue
			seen[ref] = true
			if ref >= 0:
				if r.phase <= 0.0:
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
	# Sliding along it loses a little speed.
	var tangent := r.vel - n * r.vel.dot(n)
	r.vel -= tangent * minf(1.0, RAMP_GRIP * dt)


func _collide_racers() -> void:
	for i in racers.size():
		var a := racers[i]
		if a.place > 0:
			continue
		for j in range(i + 1, racers.size()):
			var b := racers[j]
			if b.place > 0:
				continue
			var d := b.pos - a.pos
			var dist2 := d.length_squared()
			if dist2 >= 4.0 * RADIUS * RADIUS or dist2 < 0.0001:
				continue
			var dist := sqrt(dist2)
			var n := d / dist
			var overlap := 2.0 * RADIUS - dist
			a.pos -= n * overlap * 0.5
			b.pos += n * overlap * 0.5
			var vn := (b.vel - a.vel).dot(n)
			if vn < 0.0:
				var impulse := -vn * (1.0 + RACER_BOUNCE) * 0.5
				a.vel -= n * impulse
				b.vel += n * impulse
				if -vn > 250.0:
					events.append({"type": "bump", "racer": i, "other": j, "pos": (a.pos + b.pos) * 0.5})


# --- Course ----------------------------------------------------------------------

## Five sections drawn from the seed (no kind twice in a row), between a peg
## field under the gate and a peg field before the finish.
func _build_course() -> void:
	var y := START_Y + 120.0
	y = _section("pegs", y, 1)
	var last := "pegs"
	for k in 5:
		var kind: String = SECTIONS[rng.range_int(0, SECTIONS.size() - 1)]
		while kind == last:
			kind = SECTIONS[rng.range_int(0, SECTIONS.size() - 1)]
		y = _section(kind, y, k + 2)
		last = kind
	y = _section("pegs", y, 7)
	finish_y = y + 80.0
	for i in pegs.size():
		var p: Dictionary = pegs[i]
		_bucket(i, p.pos.y - p.r, p.pos.y + p.r)
	for i in ramps.size():
		var s: Dictionary = ramps[i]
		_bucket(-i - 1, minf(s.a.y, s.b.y) - RAMP_THICK, maxf(s.a.y, s.b.y) + RAMP_THICK)


func _bucket(ref: int, y0: float, y1: float) -> void:
	for band in range(int(floorf(y0 / BAND)), int(floorf(y1 / BAND)) + 1):
		if not _bands.has(band):
			_bands[band] = []
		_bands[band].append(ref)


func _peg(x: float, y: float, r := 12.0, bumper := false) -> void:
	pegs.append({"pos": Vector2(x, y), "r": r, "bumper": bumper})


## Pegs from `lo` to `hi`, `gap` apart, starting `offset` in. `lo`/`hi`
## already keep CLEAR from any wall, so nobody wedges against one.
func _peg_row(lo: float, hi: float, y: float, gap: float, offset: float) -> void:
	var x := lo + offset
	while x <= hi:
		_peg(x, y)
		x += gap


func _ramp(ax: float, ay: float, bx: float, by: float) -> void:
	ramps.append({"a": Vector2(ax, ay), "b": Vector2(bx, by)})


## Adds one section starting at `y0` and returns where the next one starts.
func _section(kind: String, y0: float, _n: int) -> float:
	var h := 0.0
	match kind:
		"pegs":
			# Staggered rows: the classic marble-run board.
			var rows := rng.range_int(5, 7)
			var gap := float(rng.range_int(110, 130))
			for row in rows:
				_peg_row(CLEAR, WIDTH - CLEAR, y0 + 40.0 + row * 96.0, gap, (gap / 2.0 if row % 2 == 1 else 0.0) + rng.range_int(0, 20))
			h = rows * 96.0 + 40.0
		"funnel":
			# Two walls squeeze everyone through one gap: jams and shoves.
			var mouth := float(rng.range_int(150, 190))
			var cx := float(rng.range_int(380, 620))
			var depth := float(rng.range_int(300, 380))
			_ramp(0.0, y0, cx - mouth / 2.0, y0 + depth)
			_ramp(WIDTH, y0, cx + mouth / 2.0, y0 + depth)
			_peg(cx, y0 + depth + 130.0, 20.0, true)
			h = depth + 230.0
		"zigzag":
			# Switchback ramps: long rolls where the lead can change.
			var turns := rng.range_int(3, 4)
			var drop := float(rng.range_int(150, 175))
			for t in turns:
				var ty := y0 + 40.0 + t * drop
				if t % 2 == 0:
					_ramp(0.0, ty, WIDTH - 190.0, ty + drop * 0.55)
				else:
					_ramp(WIDTH, ty, 190.0, ty + drop * 0.55)
			h = turns * drop + 120.0
		"bumpers":
			# A garden of bumpers that fling racers about.
			var count := rng.range_int(5, 7)
			var placed: Array[Vector2] = []
			var tries := 0
			h = 640.0
			while placed.size() < count and tries < 200:
				tries += 1
				var p := Vector2(rng.range_int(110, 890), y0 + rng.range_int(90, int(h) - 90))
				if placed.all(func(q): return q.distance_to(p) >= 210.0):
					placed.append(p)
					_peg(p.x, p.y, 36.0, true)
		"split":
			# A divider: a quick peg lane on one side, a long ramp on the other.
			var left_fast := rng.range_int(0, 1) == 0
			h = 640.0
			_ramp(WIDTH / 2.0, y0 + 40.0, WIDTH / 2.0, y0 + h - 60.0)
			var lo := 0.0 if left_fast else WIDTH / 2.0
			for row in 5:
				_peg_row(lo + CLEAR, lo + WIDTH / 2.0 - CLEAR, y0 + 110.0 + row * 100.0, 105.0, 52.0 if row % 2 == 1 else 0.0)
			if left_fast:
				_ramp(WIDTH, y0 + 140.0, WIDTH / 2.0 + 120.0, y0 + 300.0)
				_ramp(WIDTH / 2.0, y0 + 420.0, WIDTH - 120.0, y0 + 560.0)
			else:
				_ramp(0.0, y0 + 140.0, WIDTH / 2.0 - 120.0, y0 + 300.0)
				_ramp(WIDTH / 2.0, y0 + 420.0, 120.0, y0 + 560.0)
	sections.append({"kind": kind, "y0": y0, "y1": y0 + h})
	return y0 + h
