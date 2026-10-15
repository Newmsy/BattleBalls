## Batch B critters (zones, pulses and wind): Static, Drum, Magmo, Comet, Gust,
## Sooty, Honey, Ink, Whiff and Drizzle.
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Gear := preload("res://sim/gear.gd")
const BallDefs := preload("res://sim/ball_defs.gd")


func _sim(p1: String, p2 := "plain", tier := 1) -> MatchSim:
	return MatchSim.new({"seed": 1, "p1": p1, "p2": p2, "angles": [null, null], "damage_rolls": false, "tiers": [tier, 1]})


## Parks both balls far apart and motionless so a test can stage one event.
func _park(sim: MatchSim) -> void:
	sim.balls[0].pos = Vector2(200, 200)
	sim.balls[1].pos = Vector2(800, 800)
	for b in sim.balls:
		b.vel = Vector2.ZERO


## Sends ball 0 into the left wall at (66, y) this tick.
func _bounce_left(sim: MatchSim, y := 500.0) -> void:
	sim.balls[0].pos = Vector2(sim.balls[0].radius + 2.0, y)
	sim.balls[0].vel = Vector2(-sim.balls[0].speed, 0)


func _damage(sim: MatchSim, target: int, kind: String) -> float:
	var total := 0.0
	for e in sim.events:
		if e.type == "damage" and e.target == target and e.kind == kind:
			total += e.amount
	return total


func _zones(sim: MatchSim, kind: String) -> Array:
	return sim.zones.filter(func(z): return z.kind == kind)


func test_static_zaps_near_foes_on_a_wall_bounce() -> void:
	var sim := _sim("static")
	_park(sim)
	_bounce_left(sim)
	sim.balls[1].pos = Vector2(220, 500) # Within 110 + its radius.
	sim.step()
	sim.step() # The zap is queued after this tick's hits, so it lands next tick.
	check(sim.balls[1].hp < sim.balls[1].max_hp, "a foe near the wall is zapped")
	var far := _sim("static")
	_park(far)
	_bounce_left(far)
	far.step()
	far.step()
	check_eq(far.balls[1].hp, far.balls[1].max_hp, "a foe across the arena is not")


func test_static_t3_zap_chills_and_t5_big_zap_every_fourth_bounce() -> void:
	var sim := _sim("static", "plain", 5)
	_park(sim)
	sim.balls[1].pos = Vector2(260, 500)
	_bounce_left(sim)
	sim.step()
	sim.step()
	check_near(sim.balls[1].slow, 0.2, 0.001, "the zap slows 20%")
	sim.balls[0].state.zaps = 3
	_bounce_left(sim)
	sim.step()
	check(sim.events.any(func(e): return e.type == "pulse" and e.kind == "bigzap" and e.radius == 220.0), "the 4th bounce is a big zap")


func test_drum_hit_booms_foes_away() -> void:
	var sim := _sim("drum")
	_park(sim)
	var d := sim.balls[0]
	var foe := sim.balls[1]
	d.pos = Vector2(400, 500)
	foe.pos = Vector2(520, 500)
	d.vel = Vector2(400, 0)
	foe.vel = Vector2(0, 400)
	sim.step()
	check(sim.events.any(func(e): return e.type == "pulse" and e.kind == "drum"), "the hit booms")
	check(foe.vel.normalized().dot((foe.pos - d.pos).normalized()) > 0.999, "the boom knocks the foe straight away")
	check_eq(_damage(sim, 1, "drum"), d.def.boom_damage, "the boom adds its damage")


func test_magmo_hit_splashes_capped_lava() -> void:
	var sim := _sim("magmo")
	_park(sim)
	var m := sim.balls[0]
	m.pos = Vector2(400, 500)
	sim.balls[1].pos = Vector2(520, 500)
	m.vel = Vector2(400, 0)
	sim.step()
	var lava := _zones(sim, "lava")
	check_eq(lava.size(), 1, "one puddle per hit")
	check_near(lava[0].pos.x, 460.0, 6.0, "the puddle lands at the impact point")
	for k in 6:
		sim.abilities.fx_lava(sim, m, {"target": sim.balls[1]})
	check_eq(_zones(sim, "lava").size(), int(m.def.lava_max), "puddles are capped")


func test_magmo_t5_armour_in_its_own_lava() -> void:
	var sim := _sim("magmo", "plain", 5)
	_park(sim)
	var m := sim.balls[0]
	var ctx := {"source": sim.balls[1], "kind": "contact", "mult": 1.0}
	sim.abilities.fire(sim, "guard", m, ctx)
	check_eq(ctx.mult, 1.0, "no armour away from lava")
	sim.add_zone(m, m.pos, {"kind": "lava", "radius": 60.0, "life": 2.0, "dps": 5.0})
	sim.abilities.fire(sim, "guard", m, ctx)
	check_near(ctx.mult, 0.8, 0.001, "20% armour standing in it")


func test_comet_trail_stings_and_t5_flicks_a_star() -> void:
	var sim := _sim("comet", "plain", 5)
	_park(sim)
	sim.balls[0].vel = Vector2(420, 0)
	for k in 30:
		sim.step()
	check(_zones(sim, "stardust").size() > 0, "it leaves stardust")
	sim.tick = 3 * MatchSim.TICK_RATE
	sim.step()
	check(sim.events.any(func(e): return e.type == "beam" and e.owner == 0), "every 3s a star flies at the foe")


func test_gust_wind_pushes_foes_away_and_keeps_speed() -> void:
	var sim := _sim("gust")
	_park(sim)
	var g := sim.balls[0]
	var foe := sim.balls[1]
	g.pos = Vector2(400, 500)
	foe.pos = Vector2(550, 500)
	foe.vel = Vector2(0, -400)
	sim.step()
	check(foe.vel.x > 0.0, "the wind turns the foe away")
	check_near(foe.vel.length(), foe.speed, 0.001, "wind bends, never slows")
	var far := _sim("gust")
	_park(far)
	far.balls[1].vel = Vector2(0, -400)
	far.step()
	check_eq(far.balls[1].vel.x, 0.0, "no wind out of range")


func test_gust_t3_huff_blows_harder() -> void:
	var push := []
	for tier in [1, 3]:
		var sim := _sim("gust", "plain", tier)
		_park(sim)
		sim.balls[0].pos = Vector2(400, 500)
		sim.balls[1].pos = Vector2(550, 500)
		sim.balls[1].vel = Vector2(0, -400)
		sim.tick = 5 * MatchSim.TICK_RATE
		sim.step() # The huff fires at 5s ...
		sim.balls[1].vel = Vector2(0, -400)
		sim.step() # ... and blows on the next tick.
		push.append(sim.balls[1].vel.x)
	check(push[1] > push[0] * 2.0, "the huff pushes much harder than the breeze")


func test_echo_does_not_borrow_wind() -> void:
	var sim := _sim("mirror", "gust")
	_park(sim)
	sim.abilities.fire(sim, "hurt", sim.balls[0], {"source": sim.balls[1], "amount": 5.0, "kind": "contact"})
	check(sim.balls[0].state.has("copy_until"), "Echo copies Gust")
	check(not sim.balls[0].def.effects.any(func(e): return e.do == "gale"), "but not its wind")


func test_sooty_drops_patches_and_t5_flares_each_once() -> void:
	var sim := _sim("sooty", "plain", 5)
	_park(sim)
	sim.tick = 3 * MatchSim.TICK_RATE # T4: a patch every 3s.
	sim.step()
	check_eq(_zones(sim, "ember").size(), 1, "a hot patch drops")
	var hurt := {"source": sim.balls[1], "amount": 5.0, "kind": "contact"}
	sim.abilities.fire(sim, "hurt", sim.balls[0], hurt)
	var flares := sim.events.filter(func(e): return e.type == "pulse" and e.kind == "fire").size()
	sim.abilities.fire(sim, "hurt", sim.balls[0], hurt)
	check_eq(flares, 1, "hurting Sooty flares the patch")
	check_eq(sim.events.filter(func(e): return e.type == "pulse" and e.kind == "fire").size(), 1, "each patch flares only once")


func test_honey_puddles_slow_are_capped_and_t5_merge() -> void:
	var sim := _sim("honey")
	_park(sim)
	var h := sim.balls[0]
	for y in [100.0, 300.0, 500.0, 700.0, 900.0]:
		sim.abilities.fx_honey(sim, h, {"point": Vector2(0, y)})
	check_eq(_zones(sim, "honey").size(), 4, "at most 4 puddles")
	sim.balls[1].pos = Vector2(60, 900)
	sim.step()
	check_near(sim.balls[1].slow, 0.35, 0.001, "honey slows 35%")
	var t5 := _sim("honey", "plain", 5)
	_park(t5)
	t5.abilities.fx_honey(t5, t5.balls[0], {"point": Vector2(0, 500)})
	t5.abilities.fx_honey(t5, t5.balls[0], {"point": Vector2(0, 560)})
	var pools := _zones(t5, "honey")
	check_eq(pools.size(), 1, "touching puddles merge")
	check_eq(pools[0].radius, 90.0, "into a big pool")


func test_ink_squirts_on_hurt_with_a_cooldown() -> void:
	var sim := _sim("ink", "plain", 3)
	_park(sim)
	var ink := sim.balls[0]
	ink.vel = Vector2(400, 0)
	var hurt := {"source": sim.balls[1], "amount": 5.0, "kind": "contact"}
	sim.abilities.fire(sim, "hurt", ink, hurt)
	sim.abilities.fire(sim, "hurt", ink, hurt)
	check_eq(_zones(sim, "ink").size(), 1, "one cloud per cooldown")
	check(ink.vel.length() > ink.speed, "T3: a speed burst after squirting")


func test_whiff_stink_rides_along_and_hurts() -> void:
	var sim := _sim("whiff")
	_park(sim)
	sim.balls[1].pos = Vector2(350, 200)
	for k in 40:
		sim.step()
		sim.balls[0].pos = Vector2(200, 200)
		sim.balls[1].pos = Vector2(350, 200)
	check_eq(_zones(sim, "stink").size(), 1, "one cloud")
	check(sim.balls[1].hp < sim.balls[1].max_hp, "the stink hurts a close foe")
	sim.balls[0].pos = Vector2(600, 600)
	sim.step()
	check_eq(_zones(sim, "stink")[0].pos, Vector2(600, 600), "the cloud follows Whiff")


func test_echo_is_not_kept_copying_by_an_aura() -> void:
	var sim := _sim("mirror", "whiff")
	_park(sim)
	sim.abilities.fire(sim, "hurt", sim.balls[0], {"source": sim.balls[1], "amount": 1.0, "kind": "stink"})
	check(not sim.balls[0].state.has("copy_until"), "stink ticks don't trigger a copy")


func test_drizzle_rain_warns_then_falls_and_t5_thunders() -> void:
	var sim := _sim("drizzle", "plain", 5)
	_park(sim)
	var foe := sim.balls[1]
	sim.balls[0].state.showers = 2
	sim.tick = 4 * MatchSim.TICK_RATE # T4: every 4s.
	sim.step()
	var rain := _zones(sim, "rain")
	check_eq(rain.size(), 1, "rain lands on the foe's spot")
	check_eq(rain[0].pos, foe.pos, "at the foe")
	sim.step()
	check_eq(foe.hp, foe.max_hp, "no damage during the warning")
	var thunder := false
	for k in 40:
		sim.step()
		thunder = thunder or sim.events.any(func(e): return e.type == "pulse" and e.kind == "bigzap")
	check(thunder, "the third shower is a thunderstorm")
	check(foe.hp < foe.max_hp - 10.0, "rain and lightning hurt")


func test_gear_cooldown_reads_a_named_every_param() -> void:
	var def := Gear.apply_def(BallDefs.get_def("sooty"), {"cooldown": 0.25})
	var every: Dictionary = def.effects.filter(func(e): return e.on == "every")[0]
	check_near(float(every.secs), 4.0 / 1.25, 0.001, "\"secs\" naming a param is scaled, not zeroed")


func test_new_state_is_cleaned_up_with_the_cloud() -> void:
	# A copied stink cloud must not outlive the copy.
	var sim := _sim("mirror", "whiff")
	_park(sim)
	var m := sim.balls[0]
	sim.abilities.fire(sim, "hurt", m, {"source": sim.balls[1], "amount": 5.0, "kind": "contact"})
	sim.step()
	check(sim.zones.any(func(z): return z.kind == "stink" and z.owner == 0), "Echo borrows the stink")
	sim.tick = int(m.state.copy_until)
	for k in 20:
		sim.step()
	check(not sim.zones.any(func(z): return z.kind == "stink" and z.owner == 0), "and it fades when the copy ends")
