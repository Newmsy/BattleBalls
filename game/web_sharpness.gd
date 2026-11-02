## Web only: how sharp the game draws on high-density phones. Menus draw at
## up to 3 canvas pixels per CSS pixel (crisp text and paintings on a 3x
## iPhone); while a fight arena is on screen it drops to 2, because a fight
## redraws every frame and 2.25x the pixels would cost battery. The page's
## devicePixelRatio getter (export_presets.cfg head_include) reads
## window.bbDprCap, and Godot picks up the new size on its next frame.
## Render only.
extends RefCounted

const MENU_CAP := 3
const FIGHT_CAP := 2

static var _showing := {} ## Instance ids of fight arenas on screen now.


## Called by an arena when it enters or leaves the screen.
static func arena_showing(arena: CanvasItem, on: bool) -> void:
	var id := arena.get_instance_id()
	if on == _showing.has(id):
		return
	if on:
		_showing[id] = true
	else:
		_showing.erase(id)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.bbDprCap = %d" % (FIGHT_CAP if not _showing.is_empty() else MENU_CAP), true)
