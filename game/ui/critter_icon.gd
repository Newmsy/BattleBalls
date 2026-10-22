## A live critter in a menu: idles, blinks, looks around and squishes when poked.
## Drawing a critter is a lot of GDScript, so a long list stays smooth only
## if most icons don't redraw: an icon scrolled out of view, a silhouette (it
## doesn't move) and every icon while a list is being dragged or flung all
## keep their last drawing.
extends Control

const CritterArt := preload("res://game/ui/critter_art.gd")
const TouchInput := preload("res://game/ui/touch_input.gd")
const CritterPopup := preload("res://game/ui/critter_popup.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")
const Families := preload("res://sim/families.gd")

var critter_id := "vampire"
var tier := 1
var silhouette := false
## Drawn once and never again: a small badge that costs nothing per frame (e.g. on gear cards).
var still := false
var pokeable := false
## Fraction of the smaller side used as the body radius.
var radius_frac := .26
## Tapping the critter opens its mini Critterpedia card (game/ui/critter_popup.gd).
## Inside a button the tap stays the button's, so a long press opens it there.
## Off for silhouettes (not found yet) and pokeable icons (they get poked).
var info := true
var info_level := 0 ## Shown on the card when known.
var info_power := 0
## Shows the critter's family badge (game/ui/family_icon.gd) in a corner. Set before it enters the tree.
var family_badge := false

## Seconds a press inside a button must be held to open the card instead.
const HOLD := .45
const TAP_SLOP := 18.0

## Idle redraws a second, on one clock shared by every animated menu icon
## (critters, bosses, shop cosmetics): the web build draws a frame whenever
## anything changed, so icons that each kept their own beat would add up to a
## full screen redraw for every one of them.
const IDLE_RATE := 15

var _t := 0.0
var _tick := -1
var _phase := 0.0
var _hit := 0.0
var _flash := 0.0
var _squash := 0.0
var _stacks := 0
var _clip: Control ## The nearest scrolling ancestor, if any: off it means off screen.
var _press_at := -1 ## Ticks (ms) of the press that may open the card, -1 for none.
var _press_pos := Vector2.ZERO
var _in_button := false


static func make(id: String, tier_: int, side: float, pokeable_ := false, silhouette_ := false) -> Control:
	var icon = load("res://game/ui/critter_icon.gd").new()
	icon.critter_id = id
	icon.tier = tier_
	icon.pokeable = pokeable_
	icon.silhouette = silhouette_
	icon.custom_minimum_size = Vector2(side, side)
	# PASS: the icon sees taps for its card, and buttons around it still get them.
	icon.mouse_filter = Control.MOUSE_FILTER_STOP if pokeable_ else (Control.MOUSE_FILTER_IGNORE if silhouette_ else Control.MOUSE_FILTER_PASS)
	return icon



## A small face for a line of text that names a critter (rows, sheets,
## toasts): drawn once and filling its box, so long lists stay cheap. Taps
## still open its card.
static func face(id: String, side: float, tier_ := 1) -> Control:
	var icon = make(id, tier_, side)
	icon.still = true
	icon.radius_frac = .44
	return icon

func _ready() -> void:
	if family_badge and Families.of(critter_id) != "":
		add_child(FamilyIcon.corner(Families.of(critter_id)))
	_phase = float(hash(critter_id + str(get_instance_id())) % 1000) / 100.0
	var node := get_parent()
	while node != null and _clip == null:
		if node is ScrollContainer:
			_clip = node
		node = node.get_parent()


func poke() -> void:
	_hit = .3
	_flash = .25
	_squash = .2
	_stacks = mini(6, _stacks + 1)


func _gui_input(event: InputEvent) -> void:
	if pokeable and event is InputEventMouseButton and event.pressed:
		poke()
	if not info or pokeable or silhouette:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_at = Time.get_ticks_msec()
			_press_pos = event.global_position
			_in_button = _button_around() != null
		elif _press_at >= 0:
			_press_at = -1
			if not _in_button and event.global_position.distance_to(_press_pos) < TAP_SLOP and not TouchInput.scrolling():
				_open_card()
	elif event is InputEventMouseMotion and _press_at >= 0 and event.global_position.distance_to(_press_pos) >= TAP_SLOP:
		_press_at = -1


func _button_around() -> BaseButton:
	var n := get_parent()
	while n != null and n is Control:
		if n is BaseButton:
			return n
		n = n.get_parent()
	return null


func _open_card() -> void:
	poke()
	CritterPopup.open(self, critter_id, tier, info_level, info_power)


func _process(delta: float) -> void:
	if _press_at >= 0 and _in_button and Time.get_ticks_msec() - _press_at >= HOLD * 1000.0:
		_press_at = -1
		if not TouchInput.scrolling():
			TouchInput.cancel_press() # The button under the finger lets go untapped.
			_open_card()
	if silhouette or still or not is_visible_in_tree():
		return
	var poked := _hit > 0.0 or _flash > 0.0 or _squash > 0.0
	_hit = maxf(0.0, _hit - delta)
	_flash = maxf(0.0, _flash - delta)
	_squash = maxf(0.0, _squash - delta)
	if not poked and (TouchInput.scrolling() or not on_screen()):
		return
	_t += delta
	# Idling is slow motion: redrawing it 15 times a second looks the same
	# and lets the menu skip most frames (low processor mode only draws on change).
	var tick := clock()
	if poked or tick != _tick:
		_tick = tick
		queue_redraw()


## The shared idle clock: changes IDLE_RATE / every times a second, on the same
## frames for every icon that reads it.
static func clock(every := 1) -> int:
	return Time.get_ticks_msec() * IDLE_RATE / 1000 / every


## True when some of the icon shows: inside its scroll area and the window.
func on_screen() -> bool:
	var r := get_global_rect()
	if is_instance_valid(_clip) and not r.intersects(_clip.get_global_rect()):
		return false
	return r.intersects(get_viewport_rect())


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
