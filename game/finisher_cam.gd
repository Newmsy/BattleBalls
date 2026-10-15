## Finisher cam: the killing blow in slow motion, zoomed in on the critter
## going down, then a beat on its KO face. Render-only: it looks ahead by
## running its own copy of the fight from the same config (the sim is
## deterministic), and only changes how fast and how close the real fight is
## shown, never what happens in it.
extends RefCounted

const MatchSim := preload("res://sim/match_sim.gd")

const LEAD := 0.7 ## Sim seconds before the blow that slow motion starts.
const EASE_IN := 0.2 ## Sim seconds to ease from full speed into slow motion.
const SLOW := 0.22 ## Playback speed (sim seconds per real second) at the blow.
const HOLD := 1.4 ## Real seconds on the KO face after the blow.
const ZOOM := 1.9
const MATE_PULL := 0.35 ## How far the camera leans from the loser toward the winner.
## The lean never puts the loser further than this share of the half-view from
## centre, so a long-range blow (a beam from across the arena) still frames it.
const KEEP_IN := 0.4
const FOLLOW := 10.0 ## How quickly the camera catches up with its target (per second).

var ko_tick := -1 ## Tick on which the fight ends by knockout, or -1 (no finisher).
var loser := -1
var winner := -1
var ticks := 0 ## Length of the whole fight.


## Plans the finisher for a fight config. No finisher for draws or time-outs.
static func plan(config: Dictionary):
	var cam = new()
	var look := MatchSim.new(config)
	look.run_to_end()
	cam.ticks = look.tick
	if look.winner >= 0 and look.end_reason in ["knockout", "double_knockout"]:
		cam.ko_tick = look.tick
		cam.winner = look.winner
		cam.loser = 1 - look.winner
	return cam


## Sim seconds from the start of slow motion to the blow, at `tick`; < 0 before it.
## `tick` may be fractional (between two steps) so the zoom moves every frame.
func progress(tick: float) -> float:
	if ko_tick < 0:
		return -1.0
	return (tick - ko_tick) * MatchSim.DT + LEAD


func active(tick: int) -> bool:
	return progress(tick) >= 0.0


## Playback speed at `tick`, easing from the normal `speed` into slow motion
## (so a 4x fight still gets its slow-motion finish).
func time_scale(tick: int, speed := 1.0) -> float:
	var p := progress(tick)
	if p < 0.0:
		return speed
	return lerpf(speed, SLOW, smoothstep(0.0, EASE_IN, p))


## Zoom at `tick`, plus `hold` real seconds after the blow.
func zoom(tick: float, hold := 0.0) -> float:
	var p := progress(tick)
	if p < 0.0:
		return 1.0
	var z := lerpf(1.0, ZOOM, smoothstep(0.0, LEAD, p))
	# A small push-in on the KO face.
	return z + 0.15 * smoothstep(0.0, HOLD, hold)


## World point to centre the camera on: the loser, leaning toward the winner
## but never so far that the loser leaves the middle of the view, kept so the
## zoomed view never leaves the arena. Positions are the drawn (interpolated) ones.
func focus(loser_pos: Vector2, winner_pos: Vector2, zoom_value: float) -> Vector2:
	var half := MatchSim.ARENA_SIZE / (2.0 * zoom_value)
	var lean := ((winner_pos - loser_pos) * MATE_PULL).limit_length(half * KEEP_IN)
	var f := loser_pos + lean
	return f.clamp(Vector2(half, half), Vector2.ONE * (MatchSim.ARENA_SIZE - half))


## Eases the camera from `current` toward `target` over `delta` real seconds.
static func follow(current: Vector2, target: Vector2, delta: float) -> Vector2:
	return current.lerp(target, 1.0 - exp(-FOLLOW * delta))
