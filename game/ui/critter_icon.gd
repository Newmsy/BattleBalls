## A live critter in a menu: idles, blinks, looks around and squishes when poked.
extends Control

const CritterArt := preload("res://game/ui/critter_art.gd")

var critter_id := "vampire"
var tier := 1
var silhouette := false
var pokeable := false
## Fraction of the smaller side used as the body radius.
var radius_frac := .26

var _t := 0.0
var _phase := 0.0
var _hit := 0.0
var _flash := 0.0
var _squash := 0.0
var _stacks := 0


static func make(id: String, tier_: int, side: float, pokeable_ := false, silhouette_ := false) -> Control:
	var icon = load("res://game/ui/critter_icon.gd").new()
	icon.critter_id = id
	icon.tier = tier_
	icon.pokeable = pokeable_
	icon.silhouette = silhouette_
	icon.custom_minimum_size = Vector2(side, side)
	icon.mouse_filter = Control.MOUSE_FILTER_STOP if pokeable_ else Control.MOUSE_FILTER_IGNORE
	return icon


func _ready() -> void:
	_phase = float(hash(critter_id + str(get_instance_id())) % 1000) / 100.0


func poke() -> void:
	_hit = .3
	_flash = .25
	_squash = .2
	_stacks = mini(6, _stacks + 1)


func _gui_input(event: InputEvent) -> void:
	if pokeable and event is InputEventMouseButton and event.pressed:
		poke()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	_hit = maxf(0.0, _hit - delta)
	_flash = maxf(0.0, _flash - delta)
	_squash = maxf(0.0, _squash - delta)
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	var t := _t + _phase
	var look := Vector2(cos(t * .7), sin(t * 1.1) * .6).normalized()
	var bp := fmod(t, 4.3)
	var blink := sin(bp / .12 * PI) if bp < .12 else 0.0
	var bob := 0.0 if silhouette else sin(t * 2.0) * side * .012
	var centre := Vector2(size.x / 2.0, size.y * .56 + bob)
	var r := side * radius_frac * (1.0 + _squash * .4)
	CritterArt.draw_critter(self, critter_id, centre, r, {"t": 0.0 if silhouette else t, "tier": tier, "look": look,
		"blink": blink, "hit": _hit, "flash": _flash, "stacks": _stacks, "silhouette": silhouette})
