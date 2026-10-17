## A grid cell that builds its real tile only when it scrolls near the
## screen. Long critter lists (the Critters tab has a card per copy, often
## hundreds) used to build and draw every card on open, freezing phones for
## a second or more. The first `eager` cells of a grid still build at once,
## so what you see on open (and the smoke test's marks) is there straight
## away; the rest are empty cells the height of the first tile until they
## come within a screen of view, a few per frame.
extends MarginContainer

## Cells built per frame at most, so a fast fling never stalls a frame.
const PER_FRAME := 3

static var _frame := -1
static var _built_this_frame := 0

var _make: Callable


static func wrap(make: Callable, index: int, eager := 12) -> Control:
	if index < eager:
		return make.call()
	var cell = load("res://game/ui/lazy_tile.gd").new()
	cell._make = make
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cell


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	var first := get_parent().get_child(0) as Control if get_parent() else null
	if first != null and first != self and custom_minimum_size.y != first.size.y:
		custom_minimum_size.y = first.size.y
	var view := get_viewport_rect()
	if not get_global_rect().intersects(view.grow_individual(0, view.size.y, 0, view.size.y)):
		return
	var f := Engine.get_process_frames()
	if f != _frame:
		_frame = f
		_built_this_frame = 0
	if _built_this_frame >= PER_FRAME:
		return
	_built_this_frame += 1
	set_process(false)
	custom_minimum_size.y = 0.0
	add_child(_make.call())
