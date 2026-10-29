## The Critter Plunge stamp album, a sheet over the Plunge screen: a tile per
## course in its arena's colours, with the best medal you've won there
## (meta/critter_plunge.gd stamps). Fits one phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const CritterPlunge := preload("res://meta/critter_plunge.gd")
const PlungeCourse := preload("res://sim/plunge_course.gd")
const ArenaTheme := preload("res://game/arena_theme.gd")

const COLUMNS := 4


static func open(shell) -> void:
	shell.sheet(_build(shell))


## How many courses have a stamp.
static func count(p) -> int:
	return PlungeCourse.COURSES.filter(func(c): return CritterPlunge.stamp(p, c.id) != "").size()


static func _build(shell) -> Control:
	var p = shell.profile
	var v := Kit.vbox(14, [Kit.label("Stamp album", 36, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.label("Your best medal on each course. %d of %d" % [count(p), PlungeCourse.COURSES.size()], 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)])
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for c in PlungeCourse.COURSES:
		grid.add_child(_tile(shell, c))
	v.add_child(grid)
	var close := Kit.button("Close", shell.close_overlay, "ghost", 26, 80)
	shell.mark("plunge_stamps_close", close)
	v.add_child(close)
	return v


## One course: its name over its stamp (or an empty ring), in its arena's colours.
static func _tile(shell, c: Dictionary) -> Control:
	var theme: Dictionary = ArenaTheme.get_theme(c.art)
	var edge := Color(theme.border)
	var medal := CritterPlunge.stamp(shell.profile, c.id)
	var name := Kit.label(c.name, 16, Kit.FG if medal != "" else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var mark: Control = Kit.glyph("medal_" + medal, 44, Color.WHITE) if medal != "" else _empty(edge)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var col := Kit.vbox(4, [mark, name])
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var tile := Kit.panel(col, Kit.box(Color(theme.fill), Color(edge, .8 if medal != "" else .35), 18, 2, 8))
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.custom_minimum_size.y = 96
	shell.mark("plunge_stamp_" + c.id, tile)
	return tile


## The ring a stamp will fill.
static func _empty(col: Color) -> Control:
	var ring := Control.new()
	ring.custom_minimum_size = Vector2(44, 44)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.draw.connect(func(): ring.draw_arc(ring.size / 2.0, 17.0, 0.0, TAU, 32, Color(col, .45), 3.0, true))
	return ring
