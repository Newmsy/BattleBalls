## A small shape per rarity so rarity never relies on colour alone:
## common = hollow ring, uncommon = triangle, rare = diamond, epic = hexagon
## gem, legendary = crown. Drawn on any CanvasItem, centred on `c`.
extends RefCounted

const SHAPES := {"common": "ring", "uncommon": "triangle", "rare": "diamond", "epic": "hexagon", "legendary": "crown"}


static func draw(ci: CanvasItem, rarity: String, c: Vector2, size: float, col: Color) -> void:
	var h := size / 2.0
	var ink := Color("0b0a1f")
	match SHAPES.get(rarity, "ring"):
		"ring":
			ci.draw_arc(c, h * 0.6, 0, TAU, 20, col, maxf(1.5, size * 0.14), true)
		"triangle":
			_poly(ci, c, h, 3, -PI / 2.0, col)
		"diamond":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -h), c + Vector2(h * 0.72, 0), c + Vector2(0, h), c + Vector2(-h * 0.72, 0)]), col)
		"hexagon":
			_poly(ci, c, h, 6, -PI / 2.0, col)
			_poly(ci, c, h * 0.42, 6, -PI / 2.0, Color(ink, 0.55))
		"crown":
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(-h, h * 0.7), c + Vector2(-h, -h * 0.55), c + Vector2(-h * 0.45, -h * 0.05),
				c + Vector2(0, -h * 0.85), c + Vector2(h * 0.45, -h * 0.05), c + Vector2(h, -h * 0.55), c + Vector2(h, h * 0.7)]), col)


static func _poly(ci: CanvasItem, c: Vector2, r: float, sides: int, start: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in sides:
		var a := start + TAU * k / sides
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	ci.draw_colored_polygon(pts, col)
