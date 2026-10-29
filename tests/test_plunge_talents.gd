## Critter Plunge race talents (meta/plunge_talents.gd and the boosts in
## sim/plunge.gd): every family's signature talent does what it says to its
## course piece, only for the racer that has it, old Steady ranks carry over,
## and the summary line reads right.
extends "res://tests/test_case.gd"

const Plunge := preload("res://sim/plunge.gd")
const PlungeCourse := preload("res://sim/plunge_course.gd")
const PlungeTalents := preload("res://meta/plunge_talents.gd")
const Families := preload("res://sim/families.gd")
const Profile := preload("res://meta/profile.gd")

const T0 := 1_800_000_000
const FIELD := ["pip", "honey", "frost", "laser"]


## A race on `course` with racer 0 boosted by `boost`, past the gate.
func _race(course: String, boost: Dictionary, seed_value := 3) -> Plunge:
	var p := Plunge.new({"seed": seed_value, "racers": FIELD, "course": course, "boosts": [boost]})
	for k in 70:
		p.step()
	return p


## The first floor pad of `kind` (with an exit, for a portal).
func _pad(p: Plunge, kind: String) -> Dictionary:
	for f in p.floors():
		if f.kind == kind and (kind != "portal" or f.has("to")):
			return f
	return {}


func test_every_family_has_a_signature() -> void:
	for fam in Families.MEMBERS:
		var sig := PlungeTalents.signature(fam)
		check(not sig.is_empty(), "%s has a signature" % fam)
		check(Plunge.SIGNATURES.has(sig.get("id", "")), "%s's signature runs in the race" % fam)
		check_eq(PlungeTalents.talents(fam).size(), 3, "%s: two shared talents and its own" % fam)
	check_eq(PlungeTalents.line(PlungeTalents.signature("fire"), 3), "Lava burns it 60% less", "a rank's line")
	check_eq(PlungeTalents.line(PlungeTalents.signature("fire"), 5), "Lava can't burn it", "full rank")


func test_fire_rolls_through_lava() -> void:
	var taken := []
	for share in [0.0, 0.6, 1.0]:
		var p := _race("lava", {"lava": share})
		var b = p.balls[0]
		var pool: Vector2 = _pad(p, "lava").pos
		for k in 60 * 3:
			b.pos = pool
			b.vel = Vector2.ZERO
			p.step()
		taken.append(b.hazard_taken)
	check(taken[0] > 0.0, "lava burns a plain racer")
	check_near(taken[1], taken[0] * 0.4, 0.01, "rank 3 takes 60% off")
	check_eq(taken[2], 0.0, "a rank 5 Fire racer takes no lava damage")


func test_cosmic_is_pulled_less() -> void:
	var pulls := []
	for share in [0.0, 1.0]:
		var p := _race("rocks", {"orbit": share})
		var w: Dictionary = p.wells()[0]
		var b = p.balls[0]
		b.pos = w.pos + Vector2(w.reach * 0.5, 0.0)
		b.vel = Vector2.ZERO
		p._update_wells()
		pulls.append(b.vel.length())
	check(pulls[0] > 0.0, "a well pulls")
	check_near(pulls[1], pulls[0] * (1.0 - Plunge.SIGNATURES.orbit), 0.001, "a Cosmic racer is pulled less")


func test_sea_swims_goo_and_wind() -> void:
	for kind in ["goo", "wind"]:
		var course := "honey" if kind == "goo" else "kelp"
		var moved := []
		for share in [0.0, 1.0]:
			var p := _race(course, {"current": share})
			var f := _pad(p, kind)
			var b = p.balls[0]
			b.pos = f.rect.get_center() if f.has("rect") else f.pos
			b.vel = Vector2(0.0, 200.0)
			p._update_floors()
			moved.append((b.vel - Vector2(0.0, 200.0)).length())
		check(moved[0] > 0.0, "%s acts on a plain racer" % kind)
		check_near(moved[1], moved[0] * (1.0 - Plunge.SIGNATURES.current), 0.5, "%s pushes a Sea racer less" % kind)


func test_frost_skates_icy_ramps() -> void:
	var p := _race("icicles", {"ice": 1.0})
	var ramp: Dictionary = {}
	for s in p.course.ramps:
		if s.has("ice"):
			ramp = s
			break
	check(not ramp.is_empty(), "Icicle Run has icy ramps")
	# Resting on the ramp, the course says which ramp it touched.
	var b = p.balls[0]
	var mid: Vector2 = (ramp.a + ramp.b) / 2.0
	var n: Vector2 = (ramp.b - ramp.a).orthogonal().normalized()
	if n.y > 0.0:
		n = -n
	b.pos = mid + n * (b.radius + PlungeCourse.RAMP_THICK - 2.0)
	b.vel = Vector2.ZERO
	var hit: Dictionary = p.course.collide(b, Plunge.DT)
	check(hit.get("ramp") == ramp, "the hit names the icy ramp")
	b.vel = Vector2.ZERO
	p._slide(b, hit)
	check_near(b.vel.dot(ramp.down), PlungeCourse.ICE_ACCEL * Plunge.SIGNATURES.ice * Plunge.DT, 0.001, "a Frost racer gets more push")
	var plain = p.balls[1]
	plain.vel = Vector2.ZERO
	p._slide(plain, hit)
	check_eq(plain.vel, Vector2.ZERO, "others get none")


func test_tech_core_rushes_harder() -> void:
	var rush := []
	for share in [0.0, 1.0]:
		var found := false
		for seed_value in range(1, 40):
			var p := _race("crystal", {"core": share}, seed_value)
			var cores: Array = p.cores().filter(func(c): return c.kind == "core")
			if cores.is_empty():
				continue
			var b = p.balls[0]
			b.pos = cores[0].pos
			b.vel = Vector2.ZERO
			p._update_cores()
			rush.append(b.vel.y)
			found = true
			break
		check(found, "a course with a power core")
	check_near(rush[0], Plunge.RUSH, 0.01, "the plain rush")
	check_near(rush[1], Plunge.RUSH * (1.0 + Plunge.SIGNATURES.core), 0.01, "a Tech racer rushes harder")


func test_sweet_starts_shielded() -> void:
	var p := Plunge.new({"seed": 3, "racers": FIELD, "boosts": [{"shield": 0.6}]})
	check_near(p.balls[0].shield, p.balls[0].max_hp * Plunge.SIGNATURES.shield * 0.6, 0.01, "rank 3's shield")
	check_eq(p.balls[1].shield, 0.0, "the field starts bare")


func test_spooky_shoots_out_of_portals() -> void:
	var p := _race("nebula", {"portal": 1.0})
	var b = p.balls[0]
	b.pos = _pad(p, "portal").pos
	b.vel = Vector2(0.0, 50.0)
	b.portal_ready = 0
	p._update_floors()
	check_near(b.vel.y, 50.0 + Plunge.SIGNATURES.portal * Plunge.MAX_SPEED, 0.01, "a Spooky racer leaves a portal fast")
	check(p.events.any(func(e): return e.type == "talent" and e.talent == "portal"), "the view hears of it")


func test_toybox_kicks_further() -> void:
	var kicks := []
	for share in [0.0, 1.0]:
		var p := _race("clouds", {"spring": share})
		var f := _pad(p, "launch")
		var b = p.balls[0]
		b.pos = f.pos
		b.vel = Vector2(0.0, 50.0)
		b.launch_ready = 0
		p._update_floors()
		kicks.append(b.vel.length())
	check_near(kicks[1], kicks[0] * (1.0 + Plunge.SIGNATURES.spring), 0.01, "a bigger launch-pad kick")
	var p := _race("rocks", {"spring": 1.0})
	var b = p.balls[0]
	b.vel = Vector2.ZERO
	p._spring(b, Vector2(1.0, -1.0), b.pos)
	check_near(b.vel.x, PlungeCourse.BUMPER_KICK * Plunge.SIGNATURES.spring * sqrt(0.5), 0.01, "bumpers fling it sideways")
	check_eq(b.vel.y, 0.0, "never higher")


func test_nature_shrugs_off_thorns() -> void:
	var p := _race("graves", {"thorn": 1.0})
	var b = p.balls[0]
	p._spike(b, b.pos)
	check_eq(b.hazard_taken, 0.0, "a rank 5 Nature racer takes no thorn damage")
	var plain = p.balls[1]
	p._spike(plain, plain.pos)
	check(plain.hazard_taken > 0.0, "thorns hurt the rest")


func test_steady_ranks_become_the_signature() -> void:
	var d := PlungeTalents.clean({"medals": {"gold": 2}, "talents": {"fire": {"steady": 3, "tough": 2}, "sea": {"steady": 4, "current": 3}}})
	check_eq(d.talents.fire, {"tough": 2, "lava": 3}, "Steady 3 becomes Lava-proof 3")
	check_eq(d.talents.sea, {"current": 5}, "never past the top rank")
	check_eq(d.medals.gold, 2, "medals kept")
	var p = Profile.new_game(T0)
	var saved: Dictionary = p.to_dict()
	saved["plunge"] = {"talents": {"spooky": {"steady": 2}}}
	var back = Profile.from_dict(saved, T0)
	check_eq(PlungeTalents.rank(back, "spooky", "portal"), 2, "an old save loads with its ranks")


func test_signature_buys_into_the_race_and_the_summary() -> void:
	var p = Profile.new_game(T0)
	for k in 4:
		PlungeTalents.add_medal(p, "gold")
	check(PlungeTalents.buy(p, "fire", "lava"), "buys the signature")
	check(not PlungeTalents.buy(p, "fire", "portal"), "not another family's")
	check(PlungeTalents.buy(p, "fire", "tough"), "and a shared one")
	check_eq(PlungeTalents.effects(p, "sooty"), {"tough": 0.05, "power": 0.0, "lava": 0.2}, "the race boosts")
	check_eq(PlungeTalents.summary(p, "fire"), "+5% HP · Lava-proof 1/5", "the summary")
	check_eq(PlungeTalents.summary(p, "sea"), "", "nothing yet")
	check_eq(PlungeTalents.ranks(p, "fire"), 2, "ranks in the tree")
