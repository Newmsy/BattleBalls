## Cool factor (Newms 2026-10-22, ideas/critter-cool-factor.md): the signature
## move each lagging critter gained.
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Abilities := preload("res://sim/abilities.gd")


func _sim(p1: String, p2 := "plain", tiers := [1, 1]) -> MatchSim:
	return MatchSim.new({"rarity_potency": false, "seed": 5, "p1": p1, "p2": p2, "tiers": tiers, "damage_rolls": false})


func _steps(sim: MatchSim, n: int) -> void:
	for i in n:
		sim.step()


## Both balls still, at `a` and `b`.
func _park(sim: MatchSim, a := Vector2(300, 500), b := Vector2(700, 500)) -> void:
	sim.balls[0].pos = a
	sim.balls[1].pos = b
	sim.balls[0].vel = Vector2.ZERO
	sim.balls[1].vel = Vector2.ZERO


func _hit(sim: MatchSim, b) -> void:
	sim.abilities.fire(sim, "hit", b, {"target": sim.balls[1 - b.index], "amount": 5.0, "heals": []})


func _hurt(sim: MatchSim, b, amount: float, kind := "contact") -> void:
	sim.deal(sim.balls[1 - b.index], b, amount, kind)
	sim._apply_hits(sim._hits)


func _kinds(sim: MatchSim, kind: String) -> int:
	return sim.shots.filter(func(s): return s.kind == kind).size()


func test_new_moves_replay_exactly() -> void:
	for id in ["spiker", "speedster", "juggernaut", "crumb", "cogs", "minnow", "shelly", "fizz", "static", "thorns", "flicker",
			"hook", "jawbreaker", "painter", "gust", "clam", "zigzag", "disco", "magmo", "yeti", "munch", "puppeteer",
			"kaleido", "pixel", "drako", "beacon", "leviathan", "kraken", "frostfang", "clockwork", "narwhal", "ivy", "old_oak", "sundae", "prism"]:
		var a := MatchSim.new({"seed": 21, "p1": id, "p2": "vampire", "tiers": [5, 1]}).run_to_end()
		var b := MatchSim.new({"seed": 21, "p1": id, "p2": "vampire", "tiers": [5, 1]}).run_to_end()
		check_eq(a.hash, b.hash, "%s replays exactly" % id)


func test_prickles_every_third_spike_fires_a_volley() -> void:
	var sim := _sim("spiker")
	var b := sim.balls[0]
	_hit(sim, b)
	_hit(sim, b)
	check_eq(_kinds(sim, "spike"), 0, "no volley yet")
	_hit(sim, b)
	check_eq(_kinds(sim, "spike"), int(b.def.volley_count), "the 3rd spike fires a ring")


func test_zip_booms_at_top_speed() -> void:
	var sim := _sim("speedster")
	_park(sim, Vector2(500, 500), Vector2(600 + 48, 500))
	var z := sim.balls[0]
	z.vel = Vector2(1, 0)
	var hp: float = sim.balls[1].hp
	for i in 20:
		sim.abilities.fire(sim, "wall", z, {"point": Vector2.ZERO})
	sim._apply_hits(sim._hits)
	check_near(hp - sim.balls[1].hp, z.def.sonic_damage, 0.01, "one boom at top speed")


func test_boulder_hits_drop_a_rock_that_slams() -> void:
	var sim := _sim("juggernaut")
	_park(sim, Vector2(400, 500), Vector2(400 + 82 + 64, 500))
	_hit(sim, sim.balls[0])
	var rocks := sim.pieces_of(sim.balls[0], "rock")
	check_eq(rocks.size(), 1, "a rock chunk")
	check(rocks[0].pos.x > sim.balls[1].pos.x, "lands past the foe")
	check_near(rocks[0].damage, sim.balls[0].def.slam_damage, 0.001, "and slams like a wall")
	for i in 3:
		_hit(sim, sim.balls[0])
	check(sim.pieces_of(sim.balls[0], "rock").filter(func(p): return p.life > p.age).size() <= int(sim.balls[0].def.rock_max), "capped")


func test_crumb_eats_its_fallen_pieces_to_heal() -> void:
	var sim := _sim("crumb")
	_park(sim)
	var c := sim.balls[0]
	c.hp = c.max_hp * 0.6
	sim.step()
	var pieces := sim.pieces_of(c, "crumb")
	check_eq(pieces.size(), int(c.def.crumb_pieces), "a bite drops cookie pieces")
	_steps(sim, 40)
	var hp := c.hp
	c.pos = pieces[0].pos
	sim.step()
	check_near(c.hp - hp, c.def.crumb_heal, 0.001, "rolling over one heals")
	check(sim.pieces_of(c, "crumb").size() < int(c.def.crumb_pieces), "and eats it")


func test_minnow_school_nips_and_soaks_a_hit() -> void:
	var sim := _sim("minnow")
	_park(sim)
	var m := sim.balls[0]
	m.hp = m.max_hp * 0.4
	_steps(sim, 2)
	check_eq(int(m.state.school), int(m.def.school_count), "the panic calls the school")
	check_eq(Abilities.orb_items(sim, m).size(), int(m.def.school_count), "fish swim round it")
	var before := m.hp
	_hurt(sim, m, 10.0)
	check_near(before - m.hp, 5.0, 0.001, "a fish soaks half a hit")
	check_eq(int(m.state.school), int(m.def.school_count) - 1, "and swims off")


func test_fizz_bumps_shake_the_can() -> void:
	var sim := _sim("fizz")
	var b := sim.balls[0]
	for i in 3:
		_hurt(sim, b, 1.0)
	check_near(b.speed, b.def.speed * (1.0 + b.def.fizz_speed), 0.001, "3 bumps (6 shakes) burst it")


func test_static_stores_charges_and_arcs_them_on_a_hit() -> void:
	var sim := _sim("static")
	_park(sim)
	var s := sim.balls[0]
	for i in 5:
		sim.abilities.fire(sim, "wall", s, {"point": Vector2(0, 500)})
	check_eq(int(s.state.charges), int(s.def.charge_max), "charges cap")
	var hp: float = sim.balls[1].hp
	_hit(sim, s)
	sim._apply_hits(sim._hits)
	check_near(hp - sim.balls[1].hp, s.def.charge_damage * s.def.charge_max, 0.001, "the hit arcs them all")
	check(sim.stunned(sim.balls[1]), "and stuns")


func test_bramble_every_third_bump_shoots_thorns() -> void:
	var sim := _sim("thorns")
	var b := sim.balls[0]
	_hurt(sim, b, 1.0)
	_hurt(sim, b, 1.0)
	check_eq(_kinds(sim, "thorn"), 0, "not yet")
	_hurt(sim, b, 1.0)
	check_eq(_kinds(sim, "thorn"), int(b.def.thorn_count), "3rd bump: thorns fly")
	check_eq(sim.zones.filter(func(z): return z.kind == "thorn").size(), 1, "and a thorn patch")


func test_flicker_t5_every_third_relight_is_a_nova() -> void:
	var sim := _sim("flicker", "plain", [5, 1])
	var b := sim.balls[0]
	var novas := 0
	for i in 3:
		b.state.phase_until = sim.tick
		sim.abilities.fire(sim, "always", b, {})
		for e in sim.events:
			if e.type == "relight" and e.nova:
				novas += 1
	check_eq(novas, 1, "one nova in three relights")


func test_hook_harpoons_and_reels_the_foe_in() -> void:
	var sim := _sim("hook")
	_park(sim)
	sim.abilities.fx_harpoon(sim, sim.balls[0], {})
	check(sim.balls[0].vel.x > 0.0 and sim.balls[1].vel.x < 0.0, "both reel toward each other")
	check(sim.balls[1].state.has("yanked_by_0"), "a reeled foe takes the bonus on contact")


func test_jawbreaker_fires_a_candy_and_regrows_it() -> void:
	var sim := _sim("jawbreaker")
	_park(sim)
	var j := sim.balls[0]
	_hit(sim, j)
	sim.abilities.fx_candy_shot(sim, j, {})
	check_eq(_kinds(sim, "candy"), 1, "a candy flies at the foe")
	check_eq(int(j.state.candies), 0, "off its orbit")
	_steps(sim, 2 * 60 + 1)
	check_eq(int(j.state.candies), 1, "and grows back")


func test_painter_lobs_a_paint_balloon() -> void:
	var sim := _sim("painter")
	_park(sim)
	sim.abilities.fx_balloon(sim, sim.balls[0], {})
	check_eq(_kinds(sim, "balloon"), 1, "a balloon is lobbed")
	_steps(sim, 40)
	check_near(float(sim.balls[1].statuses.get("zone:0", {}).get("amount", 0.0)), 0.15, 0.001, "its splash paints the foe")


func test_gust_twister_hunts_and_flings_the_foe() -> void:
	var sim := _sim("gust")
	_park(sim, Vector2(300, 500), Vector2(600, 500))
	sim.abilities.fx_huff(sim, sim.balls[0], {})
	var caught := false
	for i in 90:
		sim.step()
		sim.balls[1].vel = Vector2.ZERO if not sim.charging(sim.balls[1]) else sim.balls[1].vel
		for e in sim.events:
			if e.type == "twister":
				caught = true
		if caught:
			break
	check(caught, "the twister reaches the foe")
	check(sim.balls[1].state.has("slam"), "and flings it at a wall to slam")


func test_zigzag_bolts_at_the_foe_after_a_hit() -> void:
	var sim := _sim("zigzag")
	_park(sim)
	_hit(sim, sim.balls[0])
	var n := sim.beams.size()
	_steps(sim, int(sim.balls[0].def.zz_bolt_delay * 60) + 1)
	check_eq(sim.beams.size() - n, 3, "a 3-step bolt")
	check_near(sim.beams.back().b.distance_to(sim.balls[1].pos), 0.0, 1.0, "ending on the foe")


func test_magmo_t5_erupts_every_third_hit() -> void:
	var sim := _sim("magmo", "plain", [5, 1])
	_park(sim)
	for i in 3:
		_hit(sim, sim.balls[0])
	check_eq(_kinds(sim, "blob"), 3, "3 lava blobs")


func test_yeti_t5_roar_rolls_a_snowball() -> void:
	var sim := _sim("yeti", "plain", [5, 1])
	var y := sim.balls[0]
	y.hp = y.max_hp * 0.4
	sim.step()
	check(sim.has_mod(y, "snowball"), "a snowball")
	check(y.radius > y.def.radius * 1.2, "bigger")


func test_kaleido_clicks_shatter_shards() -> void:
	var sim := _sim("kaleido")
	sim.abilities.fx_kaleido(sim, sim.balls[0], {})
	check_eq(_kinds(sim, "shard"), int(sim.balls[0].def.mode_shards), "shards fly")


func test_pixel_bomb_lags_the_foe_back() -> void:
	var sim := _sim("pixel")
	_park(sim, Vector2(200, 200), Vector2(500, 500))
	var f := sim.balls[1]
	f.vel = Vector2(300, 0)
	_steps(sim, 30)
	var then: Vector2 = sim.balls[0].state.lag_hist[1][0]
	sim.add_zone(sim.balls[0], f.pos, {"kind": "pixel", "radius": 18.0, "life": 5.0, "blast": 5.0, "blast_radius": 80.0})
	sim.step()
	check(f.pos.distance_to(then) < 20.0, "blasted back to where it was")


func test_drako_breathes_on_a_timer_too() -> void:
	var sim := _sim("drako")
	_park(sim)
	var hp: float = sim.balls[1].hp
	sim.abilities.fx_breath_timer(sim, sim.balls[0], {})
	sim._apply_hits(sim._hits)
	check(sim.balls[1].hp < hp, "fireballs without a stoke")


func test_beacon_t5_spins_every_third_shine() -> void:
	var sim := _sim("beacon", "plain", [5, 1])
	_park(sim)
	sim.balls[0].vel = Vector2(1, 0)
	var spins := 0
	for i in 3:
		sim.abilities.fx_lamp(sim, sim.balls[0], {})
		for e in sim.events:
			if e.type == "lamp_spin":
				spins += 1
	check_eq(spins, 1, "a full spin on the 3rd shine")


func test_leviathan_tail_coils_a_foe() -> void:
	var sim := _sim("leviathan")
	var l := sim.balls[0]
	_park(sim, Vector2(500, 500), Vector2(800, 800))
	Abilities._coil(sim, l, [sim.balls[1]])
	check(sim.stunned(sim.balls[1]), "coiled")
	sim.balls[1].stun_immune_until = 0
	Abilities._coil(sim, l, [sim.balls[1]])
	check(int(l.state.coil_ready) > sim.tick, "then waits its cooldown")


func test_kraken_slam_grabs_the_foe() -> void:
	var sim := _sim("kraken")
	_park(sim, Vector2(400, 500), Vector2(700, 500))
	sim.step()
	sim.abilities.fx_ink_slam(sim, sim.balls[0], {})
	check(not sim.tether_of(sim.balls[0]).is_empty(), "a tentacle holds the foe")


func test_frostfang_howls_up_wolves() -> void:
	var sim := _sim("frostfang")
	_park(sim)
	sim.abilities.fx_howl(sim, sim.balls[0], {})
	check_eq(_kinds(sim, "wolf"), int(sim.balls[0].def.wolf_count), "ice wolves hunt the foe")


func test_clockwork_stops_time() -> void:
	var sim := _sim("clockwork")
	_park(sim)
	sim.abilities.fx_time_stop(sim, sim.balls[0], {})
	check(sim.stunned(sim.balls[1]), "the foe freezes")


func test_narwhal_charge_skewers_the_foe_to_a_wall() -> void:
	var sim := _sim("narwhal")
	_park(sim)
	var n := sim.balls[0]
	sim.abilities.fx_lance(sim, n, {})
	var ctx := {"target": sim.balls[1], "mult": 1.0}
	sim.abilities.fire(sim, "strike", n, ctx)
	check(sim.balls[1].state.has("slam"), "the next wall pins it")
	check_near(float(sim.balls[1].state.slam.stun), n.def.skewer_stun, 0.001, "for a moment")


func test_ivy_vines_stay_as_walls() -> void:
	var sim := _sim("ivy")
	_park(sim)
	var v := sim.balls[0]
	sim.abilities.fx_vine(sim, v, {})
	_steps(sim, int(v.def.vine_lash * 60) + 2)
	var walls := sim.pieces_of(v, "vine")
	check(walls.size() >= 1 and walls[0].hits == 1, "the snapped vine stays until hit")


func test_old_oak_swats_near_foes() -> void:
	var sim := _sim("old_oak")
	_park(sim, Vector2(400, 500), Vector2(400 + 160, 500))
	var hp: float = sim.balls[1].hp
	sim.abilities.fx_swat(sim, sim.balls[0], {})
	sim._apply_hits(sim._hits)
	check_near(hp - sim.balls[1].hp, sim.balls[0].def.swat_damage, 0.001, "a branch swat")
