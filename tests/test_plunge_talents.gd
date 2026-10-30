## Critter Plunge race talents (meta/plunge_talents.gd and the boosts in
## sim/plunge.gd): Swift speeds a racer up, every family's signature does what
## it says on any course, only for the racer that has it, old Steady ranks
## carry over, and the summary line reads right.
extends "res://tests/test_case.gd"

const Plunge := preload("res://sim/plunge.gd")
const PlungeCourse := preload("res://sim/plunge_course.gd")
const PlungeTalents := preload("res://meta/plunge_talents.gd")
const Families := preload("res://sim/families.gd")
const Profile := preload("res://meta/profile.gd")

const T0 := 1_800_000_000
const FIELD := ["pip", "honey", "frost", "laser"]


## A race with racer 0 boosted by `boost`, past the gate.
func _race(boost: Dictionary, course := "rocks", seed_value := 3) -> Plunge:
	var p := Plunge.new({"seed": seed_value, "racers": FIELD, "course": course, "boosts": [boost]})
	for k in 70:
		p.step()
	return p


## Puts racer `i` in open air below the course (nothing there to hit).
func _in_the_open(p: Plunge, i: int, vel: Vector2, x := 500.0) -> void:
	p.balls[i].pos = Vector2(x, p.finish_y + 400.0)
	p.balls[i].vel = vel


## Racers 0 and 1 overlapping side by side, closing at `speed` each.
func _bump(p: Plunge, speed := 400.0) -> void:
	_in_the_open(p, 0, Vector2(speed, 0.0), 470.0)
	_in_the_open(p, 1, Vector2(-speed, 0.0), 520.0)


func _talents(p: Plunge, key: String) -> Array:
	return p.events.filter(func(e): return e.type == "talent" and e.talent == key)


func test_every_family_has_three_shared_talents_and_a_signature() -> void:
	for fam in Families.MEMBERS:
		var sig := PlungeTalents.signature(fam)
		check(not sig.is_empty(), "%s has a signature" % fam)
		check(Plunge.SIGNATURES.has(sig.get("id", "")), "%s's signature runs in the race" % fam)
		check_eq(PlungeTalents.talents(fam).size(), 4, "%s: three shared talents and its own" % fam)
		for r in [1, 5, PlungeTalents.MAX_RANK]:
			var text := PlungeTalents.line(sig, r)
			check(not text.contains("%s") and not text.contains("%d"), "%s rank %d reads: %s" % [fam, r, text])
	check_eq(PlungeTalents.line(PlungeTalents.signature("fire"), 6), "Its bumps burn rivals 11 HP/s", "a rank's line")
	check_eq(PlungeTalents.line(PlungeTalents.signature("tech"), 10), "A power rush every 4s", "full rank")
	check_eq(PlungeTalents.line(PlungeTalents.signature("tech"), 1), "A power rush every 8.5s", "rank 1")
	check_eq(PlungeTalents.line(PlungeTalents.signature("nature"), 10), "Heals and breaks free every 1.5s", "Regrowth")
	check_eq(PlungeTalents.line(PlungeTalents.TALENTS[2], 10), "+20% top speed", "Swift at full")


func test_swift_raises_top_speed_and_cuts_drag() -> void:
	var p := _race({"swift": 0.2})
	_in_the_open(p, 0, Vector2(0.0, 2000.0))
	_in_the_open(p, 1, Vector2(0.0, 2000.0), 300.0)
	p._resolve_walls(p.balls[0])
	p._resolve_walls(p.balls[1])
	check_near(p.balls[1].vel.length(), Plunge.MAX_SPEED, 0.01, "a plain racer tops out")
	check_near(p.balls[0].vel.length(), Plunge.MAX_SPEED * 1.2, 0.01, "a Swift racer goes 20% faster")
	_in_the_open(p, 0, Vector2(0.0, 100.0))
	_in_the_open(p, 1, Vector2(0.0, 100.0), 300.0)
	p._resolve_walls(p.balls[0])
	p._resolve_walls(p.balls[1])
	var fall := 100.0 + Plunge.GRAVITY * Plunge.DT
	check_near(p.balls[1].vel.y, fall * (1.0 - Plunge.DRAG * Plunge.DT), 0.001, "plain drag")
	check_near(p.balls[0].vel.y, fall * (1.0 - Plunge.DRAG * (1.0 - 0.2 * Plunge.SWIFT_DRAG) * Plunge.DT), 0.001, "less drag")
	check_eq(PlungeTalents.at_rank("pip", 10).swift, 0.2, "the league's field gets it too")


func test_fire_bumps_set_rivals_burning() -> void:
	var p := _race({"lava": 0.6})
	_bump(p)
	var hits: Array[Dictionary] = []
	p._resolve_ball_collisions(hits)
	check(hits.size() == 2, "a hard bump hits both")
	var burns: Array = p.balls[1].dots.filter(func(d): return d.source == 0)
	check_eq(burns.size(), 1, "the rival burns")
	check_near(burns[0].dps, Plunge.SIGNATURES.lava * 0.6, 0.001, "rank 6's burn")
	check(p.balls[0].dots.is_empty(), "the Fire racer doesn't")
	check_eq(_talents(p, "lava").size(), 1, "the view hears of it")
	var q := _race({})
	_bump(q)
	q._resolve_ball_collisions(hits)
	check(q.balls[1].dots.is_empty(), "a plain bump burns nobody")


func test_frost_skates_every_ramp() -> void:
	var p := _race({"ice": 1.0}, "icicles")
	var plain_ramp: Dictionary = {}
	var icy: Dictionary = {}
	for s in p.course.ramps:
		if s.has("ice") and icy.is_empty():
			icy = s
		elif not s.has("ice") and not s.has("belt") and s.down.y > 0.2 and plain_ramp.is_empty():
			plain_ramp = s
	check(not icy.is_empty() and not plain_ramp.is_empty(), "Icicle Run has icy and plain ramps")
	var b = p.balls[0]
	for ramp in [plain_ramp, icy]:
		# Resting on the ramp, the course says which ramp it touched.
		var mid: Vector2 = (ramp.a + ramp.b) / 2.0
		var n: Vector2 = (ramp.b - ramp.a).orthogonal().normalized()
		if n.y > 0.0:
			n = -n
		b.pos = mid + n * (b.radius + PlungeCourse.RAMP_THICK - 2.0)
		b.vel = Vector2.ZERO
		var hit: Dictionary = p.course.collide(b, Plunge.DT)
		check(hit.get("ramp") == ramp, "the hit names the ramp")
		b.vel = Vector2.ZERO
		p._slide(b, hit)
		var push := PlungeCourse.ICE_ACCEL * Plunge.SIGNATURES.ice * Plunge.DT
		check_near(b.vel.dot(ramp.down), push * (2.0 if ramp.has("ice") else 1.0), 0.001, "pushed on downhill (more on ice)")
		var plain = p.balls[1]
		plain.vel = Vector2.ZERO
		p._slide(plain, hit)
		check_eq(plain.vel, Vector2.ZERO, "others get none")


func test_sea_rides_out_hits() -> void:
	var p := _race({"current": 1.0})
	check_near(p.stagger_keep(p.balls[1]), Plunge.STAGGER, 0.0001, "a hit takes a plain racer's speed")
	check_near(p.stagger_keep(p.balls[0]), Plunge.STAGGER + (1.0 - Plunge.STAGGER) * Plunge.SIGNATURES.current, 0.0001, "a Sea racer keeps more")
	var half := _race({"current": 0.5})
	check(half.stagger_keep(half.balls[0]) > Plunge.STAGGER and half.stagger_keep(half.balls[0]) < p.stagger_keep(p.balls[0]), "rank 5 is in between")
	# A real hit in a step: the Sea racer is slowed less.
	var speeds := []
	for boost in [{}, {"current": 1.0}]:
		var q := _race(boost)
		var b = q.balls[0]
		b.pos = Vector2(500.0, q.finish_y - 600.0)
		b.vel = Vector2(0.0, 300.0)
		q.add_hit(q.balls[2], b, 40.0, "contact", b.pos)
		q.step()
		speeds.append(b.vel.length())
	check(speeds[1] > speeds[0] * 1.2, "Wave Rider keeps its speed: %s" % [speeds])


func test_cosmic_falls_hard_and_shoves() -> void:
	var p := _race({"orbit": 1.0})
	_in_the_open(p, 0, Vector2.ZERO)
	_in_the_open(p, 1, Vector2.ZERO, 300.0)
	p._resolve_walls(p.balls[0])
	p._resolve_walls(p.balls[1])
	check_near(p.balls[0].vel.y, p.balls[1].vel.y * (1.0 + Plunge.SIGNATURES.orbit), 0.001, "more gravity")
	_bump(p)
	var hits: Array[Dictionary] = []
	p._resolve_ball_collisions(hits)
	var heavy: float = absf(p.balls[0].vel.x - 400.0)
	var light: float = absf(p.balls[1].vel.x + 400.0)
	check_near(heavy * (1.0 + Plunge.HEAVY_BUMP), light, 0.01, "the bump moves it less")


func test_tech_overclocks_when_slow() -> void:
	var p := _race({"core": 1.0})
	var b = p.balls[0]
	p._sig_ready[0] = p.tick
	_in_the_open(p, 0, Vector2(0.0, 500.0))
	p._resolve_walls(b)
	check(b.vel.y < 600.0, "no rush while it's fast")
	b.vel = Vector2(0.0, 0.0)
	p._resolve_walls(b)
	check(b.vel.y > Plunge.RUSH, "a rush once it's slow: %s" % b.vel)
	check_eq(p._sig_ready[0], p.tick + int(round(Plunge.SIGNATURES.core * Plunge.TICK_RATE)), "every 4 s at full rank")
	b.vel = Vector2.ZERO
	p._resolve_walls(b)
	check(b.vel.y < Plunge.RUSH, "then it waits")
	check_eq(_talents(p, "core").size(), 1, "the view hears of it")
	var plain = p.balls[1]
	_in_the_open(p, 1, Vector2.ZERO, 300.0)
	p._resolve_walls(plain)
	check(plain.vel.y < Plunge.RUSH, "no rush for the rest")
	check_near(Plunge.every("core", 0.1), 8.5, 0.001, "rank 1 rushes less often")


func test_sweet_shields_twice_and_rushes() -> void:
	var p := _race({"shield": 0.6})
	var start: float = p.balls[0].max_hp * Plunge.SIGNATURES.shield * 0.6
	check_eq(p.balls[1].shield, 0.0, "the field starts bare")
	var b = p.balls[0]
	b.shield = 0.0 # Broken.
	b.vel = Vector2.ZERO
	b.pos.y = lerpf(PlungeCourse.START_Y, p.finish_y, 0.4)
	p._signature_tick(b)
	check_near(b.vel.y, Plunge.RUSH * 0.6, 0.01, "its break gives a sugar rush")
	check_eq(p._rush_until[0], p.tick + int(round(Plunge.SUGAR_SECS * Plunge.TICK_RATE)), "and a higher top speed for a while")
	check_eq(b.shield, 0.0, "no new shield before halfway")
	b.vel = Vector2.ZERO
	p._signature_tick(b)
	check_eq(b.vel, Vector2.ZERO, "one rush a shell")
	b.pos.y = lerpf(PlungeCourse.START_Y, p.finish_y, 0.6)
	p._signature_tick(b)
	check_near(b.shield, start * Plunge.SHIELD_AGAIN, 0.01, "shielded again halfway down")
	p._signature_tick(b)
	check_near(b.shield, start * Plunge.SHIELD_AGAIN, 0.01, "once")
	var q := Plunge.new({"seed": 3, "racers": FIELD, "boosts": [{"shield": 0.6}]})
	check_near(q.balls[0].shield, q.balls[0].max_hp * Plunge.SIGNATURES.shield * 0.6, 0.01, "rank 6's start shield")


func test_spooky_phases_through_bumps() -> void:
	var p := _race({"portal": 1.0})
	p._sig_ready[0] = p.tick
	_bump(p)
	var hits: Array[Dictionary] = []
	p._resolve_ball_collisions(hits)
	check(hits.is_empty(), "no hit")
	check_eq(p.balls[0].vel, Vector2(400.0, 0.0), "it passes straight through")
	check_eq(_talents(p, "portal").size(), 1, "the view hears of it")
	p.tick = p._phase_until[0]
	_bump(p)
	p._resolve_ball_collisions(hits)
	check(not hits.is_empty(), "then it bumps again until its next phase")
	check_near(Plunge.every("portal", 1.0), Plunge.SIGNATURES.portal, 0.001, "every 3 s at full rank")
	var q := _race({})
	_bump(q)
	q._resolve_ball_collisions(hits)
	check(q.balls[0].vel.x < 400.0, "a plain racer bumps")


func test_toybox_springs_off_hard_bounces() -> void:
	var p := _race({"spring": 1.0})
	var b = p.balls[0]
	b.vel = Vector2.ZERO
	p._spring(b, b.pos)
	check_near(b.vel.y, Plunge.MAX_SPEED * Plunge.SIGNATURES.spring, 0.01, "kicked on down")
	b.vel = Vector2(-10.0, 0.0)
	p._spring(b, b.pos)
	check(b.vel.x < -10.0 - 0.4 * Plunge.MAX_SPEED * Plunge.SIGNATURES.spring and b.vel.y > 0.0, "and on the way it was going, never up")
	var plain = p.balls[1]
	plain.vel = Vector2.ZERO
	p._spring(plain, plain.pos)
	check_eq(plain.vel, Vector2.ZERO, "others get none")
	# Wired to the course: a hard bounce off a side wall.
	var q := _race({"spring": 1.0})
	var c = q.balls[0]
	q._bounce_ready[0] = 0
	c.pos = Vector2(c.radius - 5.0, q.finish_y + 400.0)
	c.vel = Vector2(-400.0, 0.0)
	q._resolve_walls(c)
	check(c.vel.y > 0.8 * Plunge.MAX_SPEED * Plunge.SIGNATURES.spring, "a wall bounce springs it: %s" % c.vel)


func test_nature_regrows_and_breaks_free() -> void:
	var p := _race({"thorn": 1.0})
	var b = p.balls[0]
	b.hp = b.max_hp * 0.5
	b.stun_until = p.tick + 120
	p.slow_for(b, 0.5, 2.0)
	p._sig_ready[0] = p.tick
	p._signature_tick(b)
	check_near(b.hp, b.max_hp * (0.5 + Plunge.REGROW_HEAL), 0.001, "heals")
	check(not p.stunned(b) and b.slow_until <= p.tick, "and shakes off its stun and slow")
	check_eq(p._sig_ready[0], p.tick + int(round(Plunge.SIGNATURES.thorn * Plunge.TICK_RATE)), "every 1.5 s at full rank")
	p._signature_tick(b)
	check_near(b.hp, b.max_hp * (0.5 + Plunge.REGROW_HEAL), 0.001, "then it waits")
	b.hp = b.max_hp
	p._sig_ready[0] = p.tick
	p._signature_tick(b)
	check_eq(b.hp, b.max_hp, "never past full")
	var plain = p.balls[1]
	plain.stun_until = p.tick + 120
	p._signature_tick(plain)
	check(p.stunned(plain), "the rest stay stunned")


func test_signatures_call_out_now_and_then() -> void:
	var p := _race({"thorn": 1.0})
	var b = p.balls[0]
	p.events.clear()
	p._talent(b, "thorn", b.pos)
	p._talent(b, "thorn", b.pos)
	check_eq(_talents(p, "thorn").size(), 1, "once per TALENT_GAP")


## A whole race on every course, eight racers with a signature each (the
## nine take turns): every signature fires on any course, not just some.
func test_every_signature_fires_on_every_course() -> void:
	var keys: Array = Plunge.SIGNATURES.keys()
	var raced := {}
	var fired := {}
	for c in PlungeCourse.COURSES.size():
		var boosts := []
		for k in 8:
			boosts.append({keys[(c + k) % keys.size()]: 1.0})
		var p := Plunge.new({"seed": 7 + c, "racers": Plunge.draw_field(7 + c, 8), "course": PlungeCourse.COURSES[c].id, "boosts": boosts})
		var seen := {}
		while not p.finished:
			p.step()
			for e in p.events:
				if e.type == "talent":
					seen[e.talent] = true
		for b in boosts:
			var key: String = b.keys()[0]
			raced[key] = int(raced.get(key, 0)) + 1
			fired[key] = int(fired.get(key, 0)) + (1 if seen.has(key) else 0)
	for key in keys:
		check(fired[key] * 4 >= raced[key] * 3, "%s fires in most races: %d of %d" % [key, fired[key], raced[key]])


func test_steady_ranks_become_the_signature() -> void:
	var d := PlungeTalents.clean({"medals": {"gold": 2}, "talents": {"fire": {"steady": 3, "tough": 2}, "sea": {"steady": 8, "current": 3}}})
	check_eq(d.talents.fire, {"tough": 2, "lava": 3}, "Steady 3 becomes Scorch 3")
	check_eq(d.talents.sea, {"current": 10}, "never past the top rank")
	check_eq(d.medals.gold, 2, "medals kept")
	var p = Profile.new_game(T0)
	var saved: Dictionary = p.to_dict()
	saved["plunge"] = {"talents": {"spooky": {"steady": 2, "swift": 4}}}
	var back = Profile.from_dict(saved, T0)
	check_eq(PlungeTalents.rank(back, "spooky", "portal"), 2, "an old save loads with its ranks")
	check_eq(PlungeTalents.rank(back, "spooky", "swift"), 4, "and Swift's")


func test_signature_buys_into_the_race_and_the_summary() -> void:
	var p = Profile.new_game(T0)
	for k in 4:
		PlungeTalents.add_medal(p, "gold")
	check(PlungeTalents.buy(p, "fire", "lava"), "buys the signature")
	check(not PlungeTalents.buy(p, "fire", "portal"), "not another family's")
	check(PlungeTalents.buy(p, "fire", "tough"), "and a shared one")
	check(PlungeTalents.buy(p, "fire", "swift"), "and Swift")
	check_eq(PlungeTalents.effects(p, "sooty"), {"tough": 0.05, "power": 0.0, "swift": 0.02, "lava": 0.1}, "the race boosts")
	check_eq(PlungeTalents.summary(p, "fire"), "+5% HP · +2% spd · Scorch 1/10", "the summary")
	check_eq(PlungeTalents.short(PlungeTalents.TALENTS[2], 5), "+10% spd", "Swift's short form")
	check_eq(PlungeTalents.summary(p, "sea"), "", "nothing yet")
	check_eq(PlungeTalents.ranks(p, "fire"), 3, "ranks in the tree")
