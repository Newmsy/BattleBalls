extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const FinisherCam := preload("res://game/finisher_cam.gd")
const FightLink := preload("res://game/fight_link.gd")
const ClipExport := preload("res://game/clip/clip_export.gd")
const ClipCard := preload("res://game/clip/clip_card.gd")


## A knockout fight (laser vs vampire usually ends in one).
func _ko_config() -> Dictionary:
	for s in range(1, 60):
		var cfg := {"seed": s, "p1": "vampire", "p2": "laser", "angles": [-450, null]}
		var probe := MatchSim.new(cfg)
		probe.run_to_end()
		if probe.end_reason == "knockout":
			return cfg
	return {}


func test_finisher_finds_the_knockout_tick() -> void:
	var cfg := _ko_config()
	check(not cfg.is_empty(), "need a knockout fight to test with")
	var cam = FinisherCam.plan(cfg)
	var sim := MatchSim.new(cfg)
	sim.run_to_end()
	check_eq(cam.ko_tick, sim.tick, "ko tick")
	check_eq(cam.ticks, sim.tick, "fight length")
	check_eq(cam.winner, sim.winner, "winner")
	check_eq(cam.loser, 1 - sim.winner, "loser")


## The finisher only changes how the fight is shown: stepping it at the
## finisher's varying playback speed ends in exactly the same state.
func test_finisher_is_render_only() -> void:
	var cfg := _ko_config()
	var plain := MatchSim.new(cfg).run_to_end()
	var cam = FinisherCam.plan(cfg)
	var sim := MatchSim.new(cfg)
	var clock := 0.0
	var slowest := 4.0
	while not sim.finished:
		var rate: float = cam.time_scale(sim.tick, 4.0)
		slowest = minf(slowest, rate)
		clock += MatchSim.DT / rate
		sim.step()
	check_eq(sim.summary().hash, plain.hash, "same fight under the finisher cam")
	check_near(slowest, FinisherCam.SLOW, 0.01, "reaches slow motion")
	check(clock > sim.time() / 4.0 + FinisherCam.LEAD, "slow motion adds real time")


func test_finisher_speed_and_zoom_curve() -> void:
	var cam = FinisherCam.plan(_ko_config())
	var lead := roundi(FinisherCam.LEAD * MatchSim.TICK_RATE)
	check_eq(cam.time_scale(0, 2.0), 2.0, "normal speed early on")
	check_eq(cam.zoom(0), 1.0, "no zoom early on")
	check(not cam.active(cam.ko_tick - lead - 1), "not active before the lead-in")
	check(cam.active(cam.ko_tick - lead), "active for the lead-in")
	check_near(cam.time_scale(cam.ko_tick), FinisherCam.SLOW, 0.001, "slow at the blow")
	check_near(cam.zoom(cam.ko_tick), FinisherCam.ZOOM, 0.001, "zoomed at the blow")
	check(cam.zoom(cam.ko_tick, FinisherCam.HOLD) > cam.zoom(cam.ko_tick), "pushes in on the KO face")


func test_no_finisher_without_a_knockout() -> void:
	var cam = FinisherCam.new()
	check(not cam.active(100), "an unplanned cam never runs")
	check_eq(cam.time_scale(100, 2.0), 2.0, "keeps the speed setting")
	check_eq(cam.zoom(100), 1.0, "no zoom")


func test_finisher_focus_stays_inside_the_arena() -> void:
	var cfg := _ko_config()
	var cam = FinisherCam.plan(cfg)
	var sim := MatchSim.new(cfg)
	sim.run_to_end()
	sim.balls[cam.loser].pos = Vector2(5, 5)
	sim.balls[cam.winner].pos = Vector2(40, 30)
	var z: float = FinisherCam.ZOOM
	var f: Vector2 = cam.focus(sim, z)
	var half := MatchSim.ARENA_SIZE / (2.0 * z)
	check(f.x >= half - 0.001 and f.y >= half - 0.001, "focus clamped away from the corner: %s" % f)


## A clip replays from the same seed and angles as the share link, so a
## clip and a replay link always show the same fight.
func test_clip_replays_the_shared_fight() -> void:
	var cfg := _ko_config()
	var original := MatchSim.new(cfg)
	var result := original.run_to_end()
	var code := FightLink.replay_code(cfg.p1, cfg.p2, cfg.seed, original.launch_angles[0], original.launch_angles[1])
	var clip := MatchSim.new(original.config)
	check_eq(clip.run_to_end().hash, result.hash, "clip from the fight's config")
	check_eq(MatchSim.new(FightLink.parse_replay(code)).run_to_end().hash, result.hash, "and from its link")


func test_clip_speed_keeps_long_fights_short() -> void:
	check_eq(ClipExport.fight_speed(10.0), 1.0, "short fights play at 1x")
	check_near(ClipExport.fight_speed(48.0), 2.0, 0.001, "48s fight at 2x")
	check_eq(ClipExport.fight_speed(500.0), 3.0, "capped at 3x")
	check_eq(ClipExport.file_name("vampire", "laser"), "battle-balls-vampire-vs-laser", "file name")


func test_clip_layout_fits_the_vertical_frame() -> void:
	check_eq(ClipCard.SIZE, Vector2(ClipExport.WIDTH, ClipExport.HEIGHT), "card matches the video size")
	var arena := Rect2(ClipCard.ARENA_POS, Vector2.ONE * ClipCard.ARENA_SIDE)
	check(Rect2(Vector2.ZERO, ClipCard.SIZE).encloses(arena), "arena inside the frame")
	check(ClipCard.GO_TIME < ClipCard.TITLE_TIME, "FIGHT! flashes before the title card ends")
