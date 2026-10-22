## Tap-to-launch aiming, the same on every fight screen: press anywhere the
## buttons don't take and your ball aims at the finger, drag to adjust, let go to launch. The
## launch angle (plus the seed) is all a fight needs to replay, so this is
## the only input a fight takes. Each fight scene keeps one and feeds it its
## unhandled input while aiming.
extends RefCounted

const MatchSim := preload("res://sim/match_sim.gd")

## How far outside the arena a press still counts as on it (on_arena), in world units.
const REACH := 60.0

var dragging := false


## `from`: your ball's position (world). `on_aim(angle)` gets every new
## angle (tenths of a degree, screen space); `on_launch()` runs on release.
func feed(event: InputEvent, arena, from: Vector2, on_aim: Callable, on_launch: Callable, sfx = null) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Anywhere the buttons don't take: off the arena still points the shot.
			dragging = true
			_aim(arena, event.position, from, on_aim, sfx)
		elif dragging:
			dragging = false
			_aim(arena, event.position, from, on_aim, sfx)
			on_launch.call()
	elif event is InputEventMouseMotion and dragging:
		_aim(arena, event.position, from, on_aim, sfx)


## True when a screen point is on (or just off the edge of) the arena.
static func on_arena(arena, screen_pos: Vector2) -> bool:
	return Rect2(0, 0, MatchSim.ARENA_SIZE, MatchSim.ARENA_SIZE).grow(REACH).has_point(arena.to_world(screen_pos))


static func _aim(arena, screen_pos: Vector2, from: Vector2, on_aim: Callable, sfx) -> void:
	var dir: Vector2 = arena.to_world(screen_pos) - from
	if dir.length() < 10.0:
		return
	if sfx != null:
		sfx.on_aim_drag(dir.length() / 600.0)
	on_aim.call(roundi(rad_to_deg(dir.angle()) * 10.0))
