## Idle life for menu controls: a gentle breathe on something you can act on
## right now (a Claim, an Open, points to spend) and a slow drift for a dozing
## "z Z z". It moves only scale, rotation and alpha (never position, so
## containers keep their layout), ticks on the shared idle clock
## (CritterIcon.clock) so every idler redraws on the same frames, rests while
## off screen or scrolling, and holds still with Reduced motion. Render only.
extends Node

const CritterIcon := preload("res://game/ui/critter_icon.gd")
const TouchInput := preload("res://game/ui/touch_input.gd")
const A11y := preload("res://game/a11y.gd")

enum Kind { BREATHE, DRIFT }

var kind := Kind.BREATHE
var amount := .05
var hz := .7
var phase := 0.0
var _tick := -1


## `c` swells to 1 + `amount` and back, `hz` times a second. Returns `c`.
## Without a `phase` (0-1), neighbours fall out of step by themselves.
static func breathe(c: Control, amount := .05, hz := .7, phase := -1.0) -> Control:
	return _attach(c, Kind.BREATHE, amount, hz, phase)


## `c` sways a few degrees and fades in and out a little, like a sleepy "z Z z".
static func drift(c: Control, amount := 6.0, hz := .35) -> Control:
	return _attach(c, Kind.DRIFT, amount, hz, 0.0)


static func _attach(c: Control, kind: Kind, amount: float, hz: float, phase: float) -> Control:
	var n := new()
	n.kind = kind
	n.amount = amount
	n.hz = hz
	n.phase = phase if phase >= 0.0 else float(c.get_instance_id() % 997) / 997.0
	n.name = "Idle"
	c.add_child(n)
	return c


func _process(_delta: float) -> void:
	var c := get_parent() as Control
	if c == null:
		return
	if A11y.reduced_motion:
		if c.scale != Vector2.ONE or c.rotation != 0.0:
			c.scale = Vector2.ONE
			c.rotation = 0.0
		return
	if TouchInput.scrolling() or not c.is_visible_in_tree() or not c.get_global_rect().intersects(c.get_viewport_rect()):
		return
	var tick := CritterIcon.clock()
	if tick == _tick:
		return
	_tick = tick
	var t := Time.get_ticks_msec() / 1000.0 * hz + phase
	c.pivot_offset = c.size / 2.0
	match kind:
		Kind.BREATHE:
			# Eased so it lingers at rest and swells briefly, rather than a constant wobble.
			var s := pow(.5 - .5 * cos(fmod(t, 1.0) * TAU), 2.0)
			c.scale = Vector2.ONE * (1.0 + amount * s)
		Kind.DRIFT:
			c.rotation = deg_to_rad(sin(t * TAU) * amount)
			c.modulate.a = .65 + .35 * (.5 + .5 * sin(t * TAU * .5))
