## Batch A: the grow/shrink stat modifiers on a ball (MatchSim.set_mod) and
## the self-buff critters built on them.
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")


func _sim(p1: String, p2 := "plain", tiers := [1, 1]) -> MatchSim:
	return MatchSim.new({"seed": 5, "p1": p1, "p2": p2, "tiers": tiers, "damage_rolls": false})


func _steps(sim: MatchSim, n: int) -> void:
	for i in n:
		sim.step()


func test_mods_scale_stats_stack_and_expire() -> void:
	var sim := _sim("plain")
	var b := sim.balls[0]
	sim.set_mod(b, "a", {"radius": 1.5, "speed": 0.5, "add": 4.0}, 1.0)
	sim.set_mod(b, "b", {"radius": 2.0, "damage": 2.0})
	check_near(b.radius, 64.0 * 3.0, 0.001, "radius multipliers stack")
	check_near(b.speed, 200.0, 0.001, "speed scales")
	check_near(b.vel.length(), 200.0, 0.001, "velocity follows the new speed at once")
	check_near(b.contact_damage, 10.0 * 2.0 + 4.0, 0.001, "damage multiplier then flat add")
	_steps(sim, 61)
	check(not sim.has_mod(b, "a"), "a timed mod expires")
	check_near(b.speed, 400.0, 0.001, "speed comes back")
	check_near(b.radius, 128.0, 0.001, "the rest-of-fight mod stays")
	sim.clear_mod(b, "b")
	check_near(b.radius, 64.0, 0.001, "clearing restores the base")


func test_unused_mods_leave_the_hash_alone() -> void:
	var a := _sim("plain", "vampire").run_to_end()
	var b := _sim("plain", "vampire").run_to_end()
	check_eq(a.hash, b.hash, "deterministic")
	var sim := _sim("crumb", "vampire")
	var s := sim.run_to_end()
	check_eq(s.hash, _sim("crumb", "vampire").run_to_end().hash, "a grown fight replays exactly")


func test_crumb_shrinks_and_speeds_up_per_bite() -> void:
	var sim := _sim("crumb")
	var b := sim.balls[0]
	b.hp = 60.0 # Below two-thirds.
	sim.step()
	check_near(b.radius, b.def.radius * 0.9, 0.001, "first bite shrinks 10%")
	check_near(b.speed, b.def.speed * 1.12, 0.001, "+12% speed")
	b.hp = 30.0
	sim.step()
	check_near(b.speed, b.def.speed * 1.12 * 1.12, 0.001, "second bite stacks")
	var t5 := _sim("crumb", "plain", [5, 1])
	t5.balls[0].hp = 1.0 # Two heals of 5 still leave it under 15%.
	t5.step()
	check_eq(t5.balls[0].mods.size(), 3, "T5 bites three times")
	check(t5.beams.size() > 0, "T5 bites spray crumbs")


func test_shelly_tucks_in_below_30_percent() -> void:
	var sim := _sim("shelly")
	var b := sim.balls[0]
	var hp: float = b.def.hp
	b.hp = hp * 0.29
	sim.step()
	check_near(b.speed, b.def.speed * 0.8, 0.001, "slower in its shell")
	var before := b.hp
	sim.deal(sim.balls[1], b, 10.0, "mine")
	sim._apply_hits(sim._hits)
	check_near(before - b.hp, 6.0, 0.001, "40% armour")


func test_puff_puffs_up_when_hurt_then_deflates() -> void:
	var sim := _sim("puff", "plain", [5, 1])
	var b := sim.balls[0]
	sim.balls[1].vel = Vector2.ZERO # Stay apart, so nothing refreshes the puff.
	b.vel = Vector2.ZERO
	sim.deal(sim.balls[1], b, 1.0, "mine")
	sim._apply_hits(sim._hits)
	check_near(b.radius, b.def.radius * 1.3, 0.001, "puffs up 30%")
	check_near(b.contact_damage, b.def.contact_damage + b.def.grow_add, 0.001, "spikier")
	_steps(sim, int(b.def.grow_secs * 60) + 1)
	check_near(b.radius, b.def.radius, 0.001, "deflates")
	check(sim.beams.size() >= 6, "T5 deflating sprays spines")


func test_fin_bites_every_fourth_hit() -> void:
	var sim := _sim("fin")
	var b := sim.balls[0]
	var mults: Array = []
	for i in 8:
		mults.append(sim._strike(b, sim.balls[1]))
	check_eq(mults, [1.0, 1.0, 1.0, 2.5, 1.0, 1.0, 1.0, 2.5], "x2.5 on every 4th")


func test_tumble_grows_on_bounces_and_drops_when_hurt() -> void:
	var sim := _sim("tumble")
	var b := sim.balls[0]
	for i in 10:
		sim._on_wall_bounce(b, b.pos)
	check_near(b.radius, b.def.radius * 1.3, 0.001, "max 6 twigs")
	check_near(b.contact_damage, b.def.contact_damage + 6.0, 0.001, "+1 damage each")
	sim.deal(sim.balls[1], b, 1.0, "mine")
	sim._apply_hits(sim._hits)
	check_near(b.radius, b.def.radius * 1.3, 0.001, "chip from abilities doesn't")
	sim.deal(sim.balls[1], b, 1.0, "contact")
	sim._apply_hits(sim._hits)
	check_near(b.radius, b.def.radius, 0.001, "a hit knocks them all off")
	var t3 := _sim("tumble", "plain", [3, 1])
	for i in 8:
		t3._on_wall_bounce(t3.balls[0], t3.balls[0].pos)
	t3.deal(t3.balls[1], t3.balls[0], 1.0, "contact")
	t3._apply_hits(t3._hits)
	check_eq(t3.balls[0].state.twigs, 4, "T3 keeps half")


func test_mossy_regrows_only_when_left_alone() -> void:
	var sim := _sim("mossy")
	var b := sim.balls[0]
	sim.balls[1].pos = Vector2(900, 100) # Keep the foe away.
	sim.balls[1].vel = Vector2.ZERO
	b.vel = Vector2.ZERO
	b.hp = 50.0
	_steps(sim, 3 * 60 + 61)
	check(b.hp > 50.0, "regrows after 3s unhurt")
	sim.add_burn(sim.balls[1], b, 1.0, 10.0)
	var burning := b.hp
	_steps(sim, 120)
	check(b.hp < burning, "a burn stops the regrowth")


func test_cogs_winds_up_and_unwinds() -> void:
	var sim := _sim("cogs", "plain", [5, 1])
	var b := sim.balls[0]
	sim.deal(sim.balls[1], b, 1.0, "mine")
	sim._apply_hits(sim._hits)
	check(not sim.has_mod(b, "wind"), "only bumps wind it")
	for i in 10:
		sim.deal(sim.balls[1], b, 1.0, "contact")
		sim._apply_hits(sim._hits)
	check_near(b.speed, b.def.speed * 1.48, 0.001, "T5 winds to +48%")
	check_near(sim._strike(b, sim.balls[1]), 2.0, 0.001, "the full wind unwinds into a crit")
	check_near(b.speed, b.def.speed, 0.001, "and resets")
	sim.add_burn(sim.balls[1], b, 4.0, 3.0)
	_steps(sim, 40)
	check(not sim.has_mod(b, "wind"), "burns don't wind it")


func test_fizz_pops_after_enough_bounces() -> void:
	var sim := _sim("fizz")
	var b := sim.balls[0]
	for i in int(b.def.fizz_at) - 1:
		sim._on_wall_bounce(b, b.pos)
	check_near(b.speed, b.def.speed, 0.001, "no pop yet")
	sim._on_wall_bounce(b, b.pos)
	check_near(b.speed, b.def.speed * 1.4, 0.001, "pops for speed")
	check_near(b.contact_damage, b.def.contact_damage + b.def.fizz_damage, 0.001, "and a harder hit")
	sim._strike(b, sim.balls[1])
	check_near(b.contact_damage, b.def.contact_damage, 0.001, "the hit spends it")


func test_flicker_fades_after_a_hit() -> void:
	var sim := _sim("flicker")
	var b := sim.balls[0]
	sim.abilities.fire(sim, "hit", b, {"target": sim.balls[1], "amount": 5.0, "heals": []})
	var g := {"source": sim.balls[1], "kind": "contact", "mult": 1.0}
	sim.abilities.fire(sim, "guard", b, g)
	check_near(g.mult, 1.0, 0.001, "the foe's hit from the same bump lands in full")
	sim.tick += 1
	g.mult = 1.0
	sim.abilities.fire(sim, "guard", b, g)
	check_near(g.mult, b.def.phase_guard, 0.001, "faded: takes less")


func test_minnow_panics_at_half_hp() -> void:
	var sim := _sim("minnow")
	var b := sim.balls[0]
	check(b.radius < 64.0, "small")
	b.hp = b.max_hp * 0.49
	sim.step()
	check_near(b.speed, b.def.speed * 1.35, 0.001, "+35% speed")
