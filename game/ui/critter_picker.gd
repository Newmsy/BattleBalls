## The one critter picker: a sheet with a grid of the player's critters
## (strongest first, tinted by rarity, stars, level and power on each), tap
## one to pick it. Every screen that picks a critter for a lineup slot opens
## this instead of cycling through critters one tap at a time.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const LazyTile := preload("res://game/ui/lazy_tile.gd")
const Roster := preload("res://game/ui/roster.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")

const COLUMNS := 4


## Owned critters from `ids`, strongest first (Profile.power_of).
static func by_power(profile, ids: Array) -> Array:
	var out: Array = ids.filter(func(id): return profile.owns(id))
	out.sort_custom(func(a, b):
		var pa: int = profile.power_of(a)
		var pb: int = profile.power_of(b)
		return pa > pb if pa != pb else str(a) < str(b))
	return out


## Opens the picker. `ids`: the critters to offer (already filtered and
## sorted). opts: title, hint, current (id shown as picked), tags ({id: short
## text under the tile, e.g. "#2"}), on_pick (Callable(id)).
static func open(shell, ids: Array, opts := {}) -> void:
	var p = shell.profile
	var tags: Dictionary = opts.get("tags", {})
	var current: String = opts.get("current", "")
	var on_pick: Callable = opts.get("on_pick", Callable())
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for id in ids:
		grid.add_child(LazyTile.wrap(func(): return _cell(shell, id, tags, current, on_pick), grid.get_child_count(), 16))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rows := ceili(ids.size() / float(COLUMNS))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = minf(rows * 196.0, maxf(400.0, shell.size.y * .6))
	scroll.add_child(grid)
	var v := Kit.vbox(12, [Kit.label(opts.get("title", "Pick a critter"), 34)])
	if opts.has("hint"):
		v.add_child(Kit.label(opts.hint, 20, Kit.MUTED))
	v.add_child(scroll)
	var close := Kit.button("Cancel", shell.close_overlay, "ghost", 24, 72)
	shell.mark("pick_cancel", close)
	v.add_child(close)
	shell.sheet(v)


static func _cell(shell, id: String, tags: Dictionary, current: String, on_pick: Callable) -> Control:
	var p = shell.profile
	var b: Dictionary = p.best(id)
	var c: Dictionary = Roster.get_critter(id)
	var rare: Color = Roster.RARITY_COLORS.get(c.rarity, Kit.LINE)
	var name := Kit.label(str(c.name), 16, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var pow := Kit.power(p.power_of(id), 16)
	pow.alignment = BoxContainer.ALIGNMENT_CENTER
	var cell := Kit.vbox(0, [FighterTag.icon(id, b.get("tier", 1), 76, false, b.get("level", 0)), name, pow])
	var tag: String = tags.get(id, "")
	cell.add_child(Kit.label(tag, 16, Kit.ACCENT if tag != "" else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var picked: bool = id == current
	var tile := Kit.card_button(cell, func():
		shell.close_overlay()
		if on_pick.is_valid():
			on_pick.call(id), Kit.ACCENT if picked else Color(rare, .7),
		Color(Kit.ACCENT, .22) if picked else Color(rare, .10), 20, 6)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("pick_" + id, tile)
	return tile
