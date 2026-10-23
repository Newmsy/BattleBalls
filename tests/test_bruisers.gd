## Prickles (spiker), Zip (speedster) and Boulder (juggernaut): their effects
## in sim/abilities.gd do what their critter files say.
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")


func _sim(p1: String, p2: String) -> MatchSim:
	var sim := MatchSim.new({"seed": 1, "p1": p1, "p2": p2, "angles": [null, null], "damage_rolls": false})
	sim.balls[0].pos = Vector2(200, 200)
	sim.balls[1].pos = Vector2(800, 800)
	for b in sim.balls:
		b.vel = Vector2.ZERO
	return sim


## Rams ball 0 into a parked ball 1 and steps until they've collided.
func _ram(sim: MatchSim) -> void:
	var a := sim.balls[0]
	var b := sim.balls[1]
	b.pos = Vector2(500, 500)
	b.vel = Vector2.ZERO
	a.pos = b.pos - Vector2(a.radius + b.radius + 2.0, 0)
	a.vel = Vector2(a.speed, 0)
	for i in 5:
		sim.step()


## The contact damage multiplier ball 0's strike effects give right now.
func _strike_mult(sim: MatchSim) -> float:
	var ctx := {"target": sim.balls[1], "mult": 1.0}
	sim.abilities.fire(sim, "strike", sim.balls[0], ctx)
	return ctx.mult


func test_spiker_grows_spikes_on_hits_up_to_the_cap() -> void:
	var sim := _sim("spiker", "plain")
	var s := sim.balls[0]
	_ram(sim)
	check_eq(s.state.get("spikes", 0), 1, "one spike after one hit")
	check_near(_strike_mult(sim) * s.contact_damage, s.contact_damage + s.def.spike_damage, 0.001, "a spike adds damage")
	s.state.spikes = 100
	check_near(_strike_mult(sim) * s.contact_damage, s.contact_damage + s.def.spike_damage * s.def.spike_max, 0.001, "capped")


func test_speedster_speeds_up_on_bounces_and_resets_when_hit() -> void:
	var sim := _sim("speedster", "plain")
	var z := sim.balls[0]
	z.pos = Vector2(z.radius + 2.0, 500)
	z.vel = Vector2(-z.speed, 0)
	sim.step()
	check(z.speed > z.def.speed, "faster after a bounce")
	check_near(z.vel.length(), z.speed, 0.01, "velocity matches speed")
	for i in 100:
		sim._on_wall_bounce(z, Vector2.ZERO)
	check_near(z.speed, z.def.speed * z.def.max_speed_mult, 0.01, "speed is capped")
	check(_strike_mult(sim) > 1.0, "faster hits harder")
	# The plain ball rams the speedster.
	var p := sim.balls[1]
	z.pos = Vector2(500, 500)
	z.vel = Vector2.ZERO
	p.pos = z.pos + Vector2(z.radius + p.radius + 2.0, 0)
	p.vel = Vector2(-p.speed, 0)
	for i in 5:
		sim.step()
	check_near(z.speed, z.def.speed * (1.0 + z.def.max_speed_mult) / 2.0, 0.01, "top speed's sonic boom guard halves the first reset")
	check(z.state.get("sonic", false) == false, "and the boom is ready again")
	for i in 20: # Past the contact cooldown.
		sim.step()
	z.speed = z.def.speed * 1.4
	z.pos = Vector2(500, 500)
	z.vel = Vector2.ZERO
	p.pos = z.pos + Vector2(z.radius + p.radius + 2.0, 0)
	p.vel = Vector2(-p.speed, 0)
	for i in 30:
		sim.step()
	check_near(z.speed, z.def.speed, 0.01, "reset after being hit")


func test_juggernaut_hit_makes_the_next_wall_bounce_hurt() -> void:
	var sim := _sim("juggernaut", "plain")
	_ram(sim)
	var jug := sim.balls[0]
	var victim := sim.balls[1]
	check(jug.state.get("slam_until", -1) > sim.tick, "a slam is armed")
	var hp := victim.hp
	victim.pos = Vector2(1000 - victim.radius - 1.0, 500)
	victim.vel = Vector2(victim.speed, 0)
	jug.pos = Vector2(200, 200)
	jug.vel = Vector2.ZERO
	sim.step()
	check(sim.events.any(func(e): return e.type == "damage" and e.kind == "slam"), "slam damage event")
	check_near(hp - victim.hp, jug.def.slam_damage, 0.01, "slam damage applied")
	check_eq(jug.state.slam_until, -1, "a slam is used up")


func test_boss_size_scales_radius() -> void:
	var sim := MatchSim.new({"seed": 1, "p1": "plain", "p2": "juggernaut", "sizes": [1.0, 1.5]})
	check_near(sim.balls[1].radius, sim.balls[1].def.radius * 1.5, 0.001, "radius scaled")
