## One look for every fight screen (Quick fight, campaign, bosses, replays,
## onboarding, the Spire and campaign trios, Ghost Arena, Bounce Run):
## the health bars along the top, the arena under them, an info line, the
## fighters' cards, and the Speed · Skip · Sound pills in one row along the
## bottom. Each screen asks here where things go, so they can't drift apart.
## Render-only.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")

const TOP := 124.0 ## The health bars' room above the arena.
const ARENA_PIXELS := 680.0
const INFO_HEIGHT := 100.0 ## Two lines of the info text.
const CONTROLS_HEIGHT := 452.0 ## Tallest control panel (the menu).
const BOTTOM_MARGIN := 90.0 ## Clears the bottom pills.
const PILL := Vector2(164, 56) ## Every bottom pill: Speed, Skip, Sound.
const PILL_MARGIN := Vector2(16, 18)
const CARDS_MAX := 240.0


## Where the fight goes on a screen of `size`: "arena" (a square Rect2),
## "hud" (the health bars), "panel" (the column under the arena, or beside
## it on a wide screen: x, width and top), and "pills_top" (the y the bottom
## pills start at, which the fighters' cards stop short of).
static func rects(size: Vector2) -> Dictionary:
	var panel_width := 680.0
	var side: float
	var left: float
	var panel_pos: Vector2
	var top := TOP
	var landscape := size.x >= size.y
	if landscape:
		# The arena takes the full height on the left (clear of the pills);
		# the bars, info and controls stack in the panel on the right.
		side = minf(size.y - 40.0 - PILL.y - PILL_MARGIN.y, size.x - panel_width - 100.0)
		left = maxf(20.0, (size.x - side - panel_width - 40.0) / 2.0)
		panel_pos = Vector2(left + side + 40.0, top)
	else:
		side = clampf(size.y - top - INFO_HEIGHT - CONTROLS_HEIGHT - BOTTOM_MARGIN, 300.0, minf(ARENA_PIXELS, size.x - 40.0))
		left = (size.x - side) / 2.0
		panel_width = maxf(side, minf(ARENA_PIXELS, size.x - 40.0))
		panel_pos = Vector2((size.x - panel_width) / 2.0, top + side + 12.0)
	return {
		"landscape": landscape,
		"arena": Rect2(Vector2(left, 20.0 if landscape else top), Vector2(side, side)),
		"hud": Rect2(panel_pos.x, 8.0, panel_width, TOP - 10.0) if landscape else Rect2(left, 8.0, side, TOP - 10.0),
		"panel": Rect2(panel_pos, Vector2(panel_width, maxf(0.0, size.y - panel_pos.y - BOTTOM_MARGIN))),
		"pills_top": size.y - PILL.y - PILL_MARGIN.y,
	}


## The fighters' cards under an info line `info_h` tall at the top of the panel.
static func cards_rect(r: Dictionary, info_h: float) -> Rect2:
	var top: float = r.panel.position.y + info_h
	return Rect2(r.panel.position.x, top, r.panel.size.x, clampf(r.pills_top - 16.0 - top, 0.0, CARDS_MAX))


## Places the health bars: two bars sit a little lower than four or six.
static func place_hud(hud: Control, r: Dictionary, tall := false) -> void:
	var box: Rect2 = r.hud
	hud.position = box.position + (Vector2.ZERO if tall else Vector2(0, 16))
	hud.size = box.size - (Vector2.ZERO if tall else Vector2(0, 20))


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
