## Painted gear pieces (tools/event_art/scenes/gear_pieces.mjs): one picture
## per gear type and tier. The slot sets the shape (shield, orb, pendant), the
## type the emblem, and the enamel behind it is the tier's rarity colour. Used
## wherever a piece of gear is shown, so it looks the same everywhere.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const ART := "res://game/ui/gear_art/gear_%s_%d.png"


## The piece on its own, `side` units square. An unknown type shows the
## generic gear glyph.
static func piece(type: String, tier: int, side: float, color := Color.WHITE) -> Control:
	var path := ART % [type, clampi(tier, 1, 5)]
	if not ResourceLoader.exists(path):
		return Glyph.make("gear", side, color)
	var t := TextureRect.new()
	t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(side, side)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## The piece on a matte rounded tile with a thin rim in the tier colour (Bag rows).
static func tile(type: String, tier: int, side: float, color: Color) -> Control:
	var p := Kit.panel(piece(type, tier, side, color), Kit.box(Color("1a1840"), Color(color, .9), roundi(side * .24), 2, 0))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p
