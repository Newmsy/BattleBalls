## The platform layer (game/platform/): the right provider per build, safe-area
## maths, fight buzzes from sim events, and haptics never touching the fight.
extends "res://tests/test_case.gd"

const Platform := preload("res://game/platform/platform.gd")
const FightHaptics := preload("res://game/platform/fight_haptics.gd")
const MatchSim := preload("res://sim/match_sim.gd")


## Records buzzes instead of vibrating.
class FakePhone extends "res://game/platform/platform.gd":
	var buzzes: Array = []

	func can_vibrate() -> bool:
		return true

	func _buzz(ms: int, strength: float) -> void:
		buzzes.append([ms, strength])


func test_headless_runs_get_the_do_nothing_provider() -> void:
	Platform.use(null)
	var p = Platform.get_current()
	check_eq(p.kind(), "desktop", "headless tests are not a phone")
	check(not p.is_native_app(), "no real money outside the store apps")
	check(not p.can_vibrate(), "nothing to buzz")
	check(not p.haptic("ko"), "a haptic is a no-op")
	check(not p.can_sign_in("google"), "no native sign-in yet")


func test_safe_area_becomes_canvas_insets() -> void:
	# A 1080x2400 phone with a 96 px notch and a 48 px home bar, on the 720-wide canvas.
	var got := Platform.insets_from(Rect2i(0, 96, 1080, 2400 - 96 - 48), Vector2i(1080, 2400), Vector2(720, 1600))
	check_eq(got.top, 64.0, "notch scaled to canvas pixels")
	check_eq(got.bottom, 32.0, "home bar scaled to canvas pixels")
	check_eq(got.left, 0.0, "no side cut-out")
	var none := Platform.insets_from(Rect2i(), Vector2i.ZERO, Vector2(720, 1280))
	check_eq(none.top, 0.0, "no screen info means no insets")


func test_haptics_switch_and_merging() -> void:
	var phone := FakePhone.new()
	var was := Platform.haptics_enabled()
	Platform._haptics_on = true
	Platform._last_buzz = -100000
	check(phone.haptic("big_hit"), "first buzz goes through")
	check(not phone.haptic("hit"), "a buzz right after merges into it")
	check(phone.haptic("ko"), "a KO always buzzes")
	check(not phone.haptic("nope"), "unknown kinds do nothing")
	Platform._haptics_on = false
	Platform._last_buzz = -100000
	check(not phone.haptic("ko"), "the Settings switch turns them off")
	Platform._haptics_on = was
	check_eq(phone.buzzes.size(), 2, "two real buzzes")


func test_fight_buzzes_follow_the_events_and_leave_the_fight_alone() -> void:
	var run := func(phone) -> Array:
		var sim := MatchSim.new({"seed": 42, "p1": "vampire", "p2": "laser", "angles": [-450, 1350]})
		var kinds := {}
		while not sim.finished:
			sim.step()
			for e in sim.events:
				var k := FightHaptics.kind_for(e, sim)
				if k != "":
					kinds[k] = true
			if phone != null:
				FightHaptics.consume(sim.events, sim, phone)
		return [sim.winner, sim.tick, kinds.keys()]
	var plain: Array = run.call(null)
	var phone := FakePhone.new()
	Platform._haptics_on = true
	var buzzed: Array = run.call(phone)
	check_eq(buzzed[0], plain[0], "same winner with haptics")
	check_eq(buzzed[1], plain[1], "same length with haptics")
	check("ko" in plain[2], "a KO fight ends with a KO buzz")
	check(not phone.buzzes.is_empty(), "the phone buzzed")
