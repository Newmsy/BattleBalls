## Accessibility settings: readable font floor, reduced motion stops the shake,
## and none of it touches the fight itself.
extends "res://tests/test_case.gd"

const A11y := preload("res://game/a11y.gd")
const ArenaView := preload("res://game/arena_view.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const SettingsSheet := preload("res://game/ui/screens/settings_sheet.gd")
const Shell := preload("res://game/ui/shell.gd")


func test_fonts_never_drop_below_the_floor() -> void:
	A11y.reset()
	check_eq(A11y.font(12), A11y.MIN_FONT, "tiny text is raised")
	check_eq(A11y.font(30), 30, "normal text is unchanged")
	A11y.large_text = true
	check_eq(A11y.font(30), 36, "larger text scales up")
	A11y.reset()


func test_reduced_motion_stops_the_shake() -> void:
	A11y.reset()
	var events: Array[Dictionary] = [{"type": "collide", "a": 0, "b": 1, "pos": Vector2(500, 500)}]
	var view := ArenaView.new()
	view.sim = MatchSim.new({"seed": 7, "p1": "vampire", "p2": "laser", "angles": [-450, 1350]})
	view.consume_events(events)
	check(view._shake > 0.0, "collisions shake by default")
	A11y.reduced_motion = true
	view.clear_effects()
	view.consume_events(events)
	check_eq(view._shake, 0.0, "no shake with reduced motion")
	view.free()
	A11y.reset()


func test_settings_do_not_change_the_fight() -> void:
	var outcome := func() -> Array:
		var sim := MatchSim.new({"seed": 42, "p1": "vampire", "p2": "laser", "angles": [-450, 1350]})
		var view := ArenaView.new()
		view.sim = sim
		while not sim.finished:
			sim.step()
			view.consume_events(sim.events)
			view.advance_effects(1.0 / 60.0)
		view.free()
		return [sim.winner, sim.tick, sim.balls[0].hp, sim.balls[1].hp]
	A11y.reset()
	var normal: Array = outcome.call()
	A11y.reduced_motion = true
	A11y.large_text = true
	A11y.sound_cues = false
	check_eq(outcome.call(), normal, "same winner, length and HP")
	A11y.reset()


func test_settings_sheet_builds() -> void:
	A11y.reset()
	var shell = Shell.new()
	shell.build()
	var sheet: Control = SettingsSheet.build(shell)
	# No sound row here: tests have no sfx (main.gd sets shell.sfx).
	var testing := 1 if SettingsSheet.Dev.TOOLS_ENABLED else 0
	check(sheet.get_child_count() == SettingsSheet.OPTIONS.size() + 4 + testing, "title, a row per option, play stats, the Testing section when on, the note and the music credit")
	check(shell._marks.has("dev_refill_energy") == SettingsSheet.Dev.TOOLS_ENABLED, "Testing buttons only when dev tools are on")
	sheet.free()
	shell.free()
