## Batch G: stacking counters (Abilities.set_stacks), mode switching
## (Abilities.next_mode) and the critters built on them.
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Abilities := preload("res://sim/abilities.gd")


func _sim(p1: String, p2 := "plain", tiers := [1, 1]) -> MatchSim:
	return MatchSim.new({"rarity_potency": false, "seed": 5, "p1": p1, "p2": p2, "tiers": tiers, "damage_rolls": false})


func _steps(sim: MatchSim, n: int) -> void:
	for i in n:
		sim.step()


## Fires `b`'s "hit" effects as if its contact hit just landed.
func _hit(sim: MatchSim, b) -> void:
	sim.abilities.fire(sim, "hit", b, {"target": sim.balls[1 - b.index], "amount": 5.0, "heals": []})


## Lands `amount` of `kind` damage on `b` from its foe, through guard and hurt.
func _hurt(sim: MatchSim, b, amount: float, kind := "contact") -> void:
	sim.deal(sim.balls[1 - b.index], b, amount, kind)
	sim._apply_hits(sim._hits)


func test_stack_fights_replay_and_leave_old_hashes_alone() -> void:
	for id in ["munch", "totem", "sundae", "kaleido", "drako", "eclipse", "supernova", "yeti", "bubbles", "blizz"]:
		var a := MatchSim.new({"rarity_potency": false, "seed": 9, "p1": id, "p2": "vampire", "tiers": [5, 1]}).run_to_end()
		var b := MatchSim.new({"rarity_potency": false, "seed": 9, "p1": id, "p2": "vampire", "tiers": [5, 1]}).run_to_end()
		check_eq(a.hash, b.hash, "%s replays exactly" % id)


func test_munch_bites_grow_it_and_heal() -> void:
	var sim := _sim("munch")
	var b := sim.balls[0]
	b.hp = 50.0
	for i in 7:
		_hit(sim, b)
	check_eq(Abilities.stacks(b), 5, "max 5 bites")
	check_near(b.radius, b.def.radius * 1.25, 0.001, "+5% size a bite")
	check_near(b.contact_damage, b.def.contact_damage + 5.0, 0.001, "+1 damage a bite")
	check_near(b.hp, 50.0 + 7 * 3.0, 0.001, "every bite heals 3, full or not")
	var t3 := _sim("munch", "plain", [3, 1])
	var g := {"source": t3.balls[1], "kind": "contact", "mult": 1.0}
	for i in 5:
		_hit(t3, t3.balls[0])
	t3.abilities.fire(t3, "guard", t3.balls[0], g)
	check_near(g.mult, 0.85, 0.001, "T3 full size: 15% armour")
	var t5 := _sim("munch", "plain", [5, 1])
	var m := t5.balls[0]
	for i in 6:
		_hit(t5, m)
	check_eq(Abilities.stacks(m), 2, "T5 burps at 6 bites and drops to 2")


func test_totem_stacks_faces_on_bumps_and_loses_them_to_big_hits() -> void:
	var sim := _sim("totem")
	var b := sim.balls[0]
	for i in 4:
		sim.abilities.fire(sim, "bump", b, {"other": sim.balls[1]})
	check_eq(Abilities.stacks(b), 3, "three faces")
	check_near(b.contact_damage, b.def.contact_damage + 2.0, 0.001, "first face: +2 damage")
	check_near(b.speed, b.def.speed * 1.15, 0.001, "third face: +15% speed")
	var before := b.hp
	_hurt(sim, b, 10.0)
	check_near(before - b.hp, 8.5, 0.001, "second face: 15% armour")
	check_eq(Abilities.stacks(b), 3, "a small hit keeps the faces")
	_hurt(sim, b, 30.0)
	check_eq(Abilities.stacks(b), 2, "a big hit knocks the top face off")
	check_near(b.speed, b.def.speed, 0.001, "and its speed with it")
	var t3 := _sim("totem", "plain", [3, 1])
	t3.step()
	check_eq(Abilities.stacks(t3.balls[0]), 1, "T3 starts with a face")


func test_sundae_scoops_and_splats() -> void:
	var sim := _sim("sundae")
	var b := sim.balls[0]
	for i in 3:
		_hit(sim, b)
	check_near(b.contact_damage, b.def.contact_damage + 6.0, 0.001, "+2 a scoop")
	_hurt(sim, b, 30.0)
	check_eq(Abilities.stacks(b), 2, "a big hit knocks a scoop off")
	var splats := sim.zones.filter(func(z): return z.kind == "splat")
	check_eq(splats.size(), 1, "into a sticky splat")
	_hurt(sim, b, 10.0)
	check_eq(Abilities.stacks(b), 2, "only hits that big count")
	var t5 := _sim("sundae", "plain", [5, 1])
	for i in 4:
		_hit(t5, t5.balls[0])
	check(t5.beams.is_empty(), "no sprinkles below 5 scoops")
	_hit(t5, t5.balls[0])
	check_eq(t5.beams.size(), 6, "T5 at 5 scoops: hits shower sprinkles")


func test_kaleido_clicks_through_its_modes() -> void:
	var sim := _sim("kaleido")
	var b := sim.balls[0]
	sim.step()
	check_eq(b.state.mode, 0, "starts in spikes")
	check_near(b.contact_damage, b.def.contact_damage + 3.0, 0.001, "spikes: +3")
	_steps(sim, 240)
	check_eq(b.state.mode, 1, "then shield")
	check_near(b.shield, 12.0, 0.001, "a 12 shield")
	check_near(b.contact_damage, b.def.contact_damage, 0.001, "spikes gone")
	_steps(sim, 240)
	check_eq(b.state.mode, 2, "then speed")
	check_near(b.shield, 0.0, 0.001, "the shield goes with its mode")
	check_near(b.speed, b.def.speed * 1.3, 0.001, "+30% speed")
	var t5 := _sim("kaleido", "plain", [5, 1])
	t5.balls[0].state.mode = 2
	t5.abilities.fx_kaleido(t5, t5.balls[0], {})
	check_eq(t5.balls[0].state.mode, 3, "T5 prism mode")
	check_near(t5.balls[0].contact_damage, t5.balls[0].def.contact_damage + t5.balls[0].def.mode_damage * 0.5, 0.001, "half spikes")
	check_near(t5.balls[0].shield, t5.balls[0].def.mode_shield * 0.5, 0.001, "half shield")


func test_drako_breathes_on_the_hit_after_its_throat_fills() -> void:
	var sim := _sim("drako")
	var b := sim.balls[0]
	var foe := sim.balls[1]
	foe.pos = b.pos + Vector2(b.radius + foe.radius, 0)
	for i in 4:
		_hit(sim, b)
	check_eq(Abilities.stacks(b), 4, "four stokes")
	check_near(b.contact_damage, b.def.contact_damage + 4.0, 0.001, "+1 damage a stoke")
	var before := foe.hp
	_hit(sim, b)
	sim._apply_hits(sim._hits)
	check_eq(Abilities.stacks(b), 0, "the breath starts it again")
	check_near(before - foe.hp, 25.0, 0.001, "five fireballs at point blank land this tick")
	check(not foe.dots.is_empty(), "and burn")
	check_eq(sim.beams.size(), 5, "drawn as five bolts")


func test_eclipse_flips_between_sun_and_moon() -> void:
	var sim := _sim("eclipse")
	var b := sim.balls[0]
	var foe := sim.balls[1]
	foe.pos = b.pos + Vector2(b.radius + foe.radius + 10.0, 0)
	foe.vel = Vector2.ZERO
	b.vel = Vector2.ZERO
	sim.tick = 30
	sim.abilities.fx_corona(sim, b, {})
	check(not foe.dots.is_empty(), "Sun: the corona burns a foe beside it")
	sim.abilities.fx_eclipse(sim, b, {})
	check_eq(b.state.mode, 1, "flips to Moon")
	check(foe.vel.length() > 0.0, "the flip pushes the foe away")
	b.hp = 50.0
	sim.tick = 60
	sim.abilities.fx_corona(sim, b, {})
	check_near(b.hp, 50.0 + b.def.moon_hps * 0.5, 0.001, "Moon heals")
	var t5 := _sim("eclipse", "plain", [5, 1])
	t5.abilities.fx_eclipse(t5, t5.balls[0], {})
	check(t5.balls[0].shield > 0.0, "T3+ Moon arrives with a shield")
	check(t5.balls[0].state.total_until > t5.tick, "T5: a Total Eclipse after the flip")


func test_supernova_swells_then_blows() -> void:
	var sim := _sim("supernova")
	var b := sim.balls[0]
	var foe := sim.balls[1]
	_steps(sim, 2 * 60 * 5 + 1)
	check_eq(Abilities.stacks(b), 5, "a swell step every 2s")
	check(b.radius > b.def.radius, "bigger")
	_steps(sim, int(b.def.nova_every) * 60 - sim.tick)
	check(b.state.nova_warn, "flickers before it blows")
	foe.pos = b.pos + Vector2(200, 0)
	var before := foe.hp
	_steps(sim, 2)
	check(foe.hp < before, "the nova hits")
	check(not foe.dots.is_empty(), "and burns")
	check(Abilities.stacks(b) <= 1, "and starts small again")


func test_yeti_roars_at_half_hp() -> void:
	var sim := _sim("yeti", "plain", [5, 1])
	var b := sim.balls[0]
	var foe := sim.balls[1]
	check(b.radius > 64.0, "big and furry")
	foe.pos = b.pos + Vector2(200, 0)
	b.hp = b.max_hp * 0.49
	sim.step()
	sim.step()
	check(foe.hp < foe.max_hp, "the avalanche hurts")
	check(not sim.status(foe, "chill:0").is_empty(), "and chills")
	sim.step()
	check(foe.slow > 0.0, "the chill slows it")
	check_eq(sim.zones.filter(func(z): return z.kind == "frost").size(), 3, "T5 snowdrifts")


func test_bubbles_bubble_soaks_one_hit() -> void:
	var sim := _sim("bubbles", "plain", [5, 1])
	var b := sim.balls[0]
	sim.abilities.fx_bubble(sim, b, {})
	var before := b.hp
	_hurt(sim, b, 8.0)
	check_near(b.hp, before, 0.001, "a small hit is soaked whole")
	check_eq(b.state.bubble, 0.0, "and pops it")
	check(sim.beams.size() == 4, "T5 sprays 4 bubbles")
	_hurt(sim, b, 8.0)
	check_near(b.hp, before - 8.0, 0.001, "the next hit lands")
	sim.abilities.fx_bubble(sim, b, {})
	_hurt(sim, b, 20.0)
	check_near(b.hp, before - 8.0 - (20.0 - b.def.bubble_size), 0.001, "a big hit only loses the bubble's share")


func test_blizz_mines_leave_frost_and_two_patches_freeze() -> void:
	var sim := _sim("blizz", "plain", [5, 1])
	var b := sim.balls[0]
	var foe := sim.balls[1]
	sim.abilities.fx_snow_mine(sim, b, {})
	var mine = sim.zones[0]
	mine.age = mine.arm
	foe.pos = mine.pos
	sim._update_zones()
	check_eq(sim.zones.size(), 1, "the blast leaves one patch")
	check_eq(sim.zones[0].kind, "snow", "of frost")
	sim.add_zone(b, foe.pos, {"kind": "snow", "radius": 100.0, "life": 3.0, "slow": 0.4})
	sim.abilities.fx_snow_freeze(sim, b, {})
	check(sim.stunned(foe), "two patches freeze it")
