## One look for every fight screen (Quick fight, campaign, bosses, replays,
## onboarding, the Spire and campaign trios, Ghost Arena, Bounce Run): "your
## side, their side". The foe's fighters sit in plates above the arena and
## yours below it, by your thumb; each plate holds the fighter's face, name,
## tier, level and power, what its ability does and its health bar. The clock
## notches into the arena's top edge, and the Speed · Skip · Sound pills sit
## in one row along the bottom. Each screen asks here where things go, so
## they can't drift apart. Render-only.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")

const TOP := 124.0 ## The health bars' room above the arena (a screen with a tall control panel).
const ARENA_PIXELS := 680.0
const INFO_HEIGHT := 100.0 ## Two lines of the info text.
const CONTROLS_HEIGHT := 452.0 ## Tallest control panel (the menu).
const BOTTOM_MARGIN := 90.0 ## Clears the bottom pills.
const PILL := Vector2(164, 56) ## Every bottom pill: Speed, Skip, Sound.
const PILL_MARGIN := Vector2(16, 18)
const CARDS_MAX := 240.0
const EDGE := 14.0 ## Room at the screen's top and between the plates and the arena.
const PLATE_MIN := 200.0 ## The shortest a side's plates get before the arena shrinks.
const PLATE_MAX := 420.0
const PLATE_GAP := 14.0 ## Between plates on the same side.


## Where the fight goes on a screen of `size`: "arena" (a square Rect2),
## "foe" and "you" (the bands for each side's plates, above and below the
## arena), "hud" (the foe's band, for older callers), "panel" (the room under
## the arena for an info line and controls before and after the fight: x,
## width and top) and "pills_top" (the y the bottom pills start at).
## `panel_h` > 0 keeps that much room for a tall control panel under the
## arena (the Quick fight menu): the bars go back on top and the plates aren't
## shown.
static func rects(size: Vector2, panel_h := 0.0) -> Dictionary:
	var pills_top := size.y - PILL.y - PILL_MARGIN.y
	if size.x >= size.y:
		# The arena takes the full height on the left (clear of the pills);
		# the foe's plates, the controls and yours stack on the right.
		var panel_width := 680.0
		var side := minf(size.y - 40.0 - PILL.y - PILL_MARGIN.y, size.x - panel_width - 100.0)
		var left := maxf(20.0, (size.x - side - panel_width - 40.0) / 2.0)
		var px := left + side + 40.0
		var band := clampf((pills_top - 16.0 - EDGE) / 3.0, 140.0, PLATE_MAX)
		var foe := Rect2(px, EDGE, panel_width, band)
		return {
			"landscape": true,
			"arena": Rect2(Vector2(left, 20.0), Vector2(side, side)),
			"foe": foe,
			"you": Rect2(px, pills_top - 16.0 - band, panel_width, band),
			"hud": foe,
			"panel": Rect2(Vector2(px, foe.end.y + 12.0), Vector2(panel_width, maxf(0.0, size.y - foe.end.y - 12.0 - BOTTOM_MARGIN))),
			"pills_top": pills_top,
		}
	var width := minf(ARENA_PIXELS, size.x - 40.0)
	var x := (size.x - width) / 2.0
	if panel_h > 0.0:
		var side := clampf(size.y - TOP - panel_h - BOTTOM_MARGIN, 300.0, width)
		var top := TOP
		var py := top + side + 12.0
		return {
			"landscape": false,
			"arena": Rect2(Vector2((size.x - side) / 2.0, top), Vector2(side, side)),
			"foe": Rect2(x, 8.0, width, TOP - 10.0),
			"you": Rect2(x, py, width, 0.0),
			"hud": Rect2((size.x - side) / 2.0, 8.0, side, TOP - 10.0),
			"panel": Rect2(Vector2(x, py), Vector2(width, maxf(0.0, size.y - py - BOTTOM_MARGIN))),
			"pills_top": pills_top,
		}
	# The arena as wide as it can be, the two sides' plates sharing what's left.
	var room := pills_top - 16.0 - EDGE * 3.0
	var arena_side := clampf(room - 2.0 * PLATE_MIN, 300.0, width)
	var plate := minf(PLATE_MAX, (room - arena_side) / 2.0)
	var top := EDGE + plate + EDGE
	var foe := Rect2(x, EDGE, width, plate)
	var you := Rect2(x, top + arena_side + EDGE, width, plate)
	return {
		"landscape": false,
		"arena": Rect2(Vector2((size.x - arena_side) / 2.0, top), Vector2(arena_side, arena_side)),
		"foe": foe,
		"you": you,
		"hud": foe,
		"panel": Rect2(you.position, Vector2(width, maxf(0.0, size.y - you.position.y - BOTTOM_MARGIN))),
		"pills_top": pills_top,
	}


## Plate `k` (0 your first fighter, 1 the foe's, 2 your second, 3 theirs, then
## the thirds) when `n` balls fight at once (2, 4 or 6): side by side in its
## side's band.
static func plate(r: Dictionary, k: int, n: int) -> Rect2:
	var band: Rect2 = r.you if k % 2 == 0 else r.foe
	var per := maxi(1, n / 2)
	var w := (band.size.x - PLATE_GAP * (per - 1)) / per
	return Rect2(band.position.x + (k / 2) * (w + PLATE_GAP), band.position.y, w, band.size.y)


## The health bar inside a plate: along its bottom edge.
static func plate_bar(p: Rect2, n: int) -> Rect2:
	var h := clampf(p.size.y * 0.14, 26.0, 44.0) if n == 2 else clampf(p.size.y * 0.12, 24.0, 32.0)
	var pad := 16.0 if n < 6 else 12.0
	return Rect2(p.position.x + pad, p.end.y - pad - h, p.size.x - pad * 2.0, h)


## Puts the health bars (`hud`, game/fight_hud.gd) and the fighters' plates
## (`strip`, game/fighter_strip.gd) over the whole screen: both draw into the
## plates rects() lays out, so they always line up.
static func place_plates(hud: Control, strip: Control, r: Dictionary, size: Vector2) -> void:
	# The bars draw over the plates.
	if strip.get_parent() == hud.get_parent() and strip.get_index() > hud.get_index():
		strip.get_parent().move_child(strip, hud.get_index())
	for c in [hud, strip]:
		c.position = Vector2.ZERO
		c.size = size
		c.set("layout", r)
		c.queue_redraw()


## Where bottom pill `slot` goes: -1 left (Speed), 0 middle (Skip), 1 right (Sound).
static func pill_position(viewport_size: Vector2, slot: int) -> Vector2:
	var y := viewport_size.y - PILL.y - PILL_MARGIN.y
	match slot:
		-1:
			return Vector2(PILL_MARGIN.x, y)
		1:
			return Vector2(viewport_size.x - PILL.x - PILL_MARGIN.x, y)
	return Vector2((viewport_size.x - PILL.x) / 2.0, y)


## The fight's Skip pill, in the middle of the bottom row. Like the Speed
## pill it stays out of whatever row it's added to (top_level) and shows and
## hides with it.
static func skip_pill(on_press: Callable, button_name := "Skip") -> Pill:
	return Pill.new("Skip", on_press, 0, button_name)


class Pill extends Control:
	var button: Button
	var _slot := 0

	func _init(text: String, on_press: Callable, slot: int, button_name := "") -> void:
		_slot = slot
		top_level = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		button = Kit.button(text, on_press, "ghost", 20, int(FightLayoutRef.PILL.y))
		if button_name != "":
			button.name = button_name
		button.clip_text = true
		button.add_theme_font_override("font", Kit.FONT)
		button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(button)

	func _ready() -> void:
		get_viewport().size_changed.connect(place)
		place()

	func place() -> void:
		size = FightLayoutRef.PILL
		global_position = FightLayoutRef.pill_position(get_viewport().get_visible_rect().size, _slot)


const FightLayoutRef := preload("res://game/fight_layout.gd")
