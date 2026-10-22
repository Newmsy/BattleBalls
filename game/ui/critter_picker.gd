## The one critter picker: a sheet with a grid of the player's critters
## (strongest first, tinted by rarity, stars, level and power on each), tap
## one to pick it. Every screen that picks a critter for a lineup slot opens
## this instead of cycling through critters one tap at a time. open_team() is
## its team mode: your picks sit in numbered slots at the top and glow in the
## grid, a tap toggles a critter in or out, and Confirm saves the team.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const LazyTile := preload("res://game/ui/lazy_tile.gd")
const Roster := preload("res://game/ui/roster.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const FamilyEdge := preload("res://game/ui/family_edge.gd")

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
## text under the tile, e.g. "#2"}), locked ({id: true}: those tiles are dimmed
## with a lock and a tap only toasts `locked_toast` % name), on_pick (Callable(id)),
## foes (critter ids you'll fight, when known: each tile gets its family-edge badge).
static func open(shell, ids: Array, opts := {}) -> void:
	var p = shell.profile
	var tags: Dictionary = opts.get("tags", {})
	var locked: Dictionary = opts.get("locked", {})
	var locked_toast: String = opts.get("locked_toast", "%s can't take this yet.")
	var current: String = opts.get("current", "")
	var on_pick: Callable = opts.get("on_pick", Callable())
	var foes: Array = opts.get("foes", [])
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for id in ids:
		grid.add_child(LazyTile.wrap(func(): return _with_edge(_cell(shell, id, tags, current, on_pick, locked.has(id), locked_toast), id, foes), grid.get_child_count(), 16))
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


static func _cell(shell, id: String, tags: Dictionary, current: String, on_pick: Callable, lock := false, lock_toast := "") -> Control:
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
	if lock:
		cell.add_child(Kit.hbox(0, [Kit.glyph("lock", 24, Kit.FG)], BoxContainer.ALIGNMENT_CENTER))
	else:
		cell.add_child(Kit.label(tag, 16, Kit.ACCENT if tag != "" else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var picked: bool = id == current
	var tile := Kit.card_button(cell, func():
		if lock:
			shell.toast(lock_toast % str(c.name), id)
			return
		shell.close_overlay()
		if on_pick.is_valid():
			on_pick.call(id), Kit.ACCENT if picked else Color(rare, .3 if lock else .7),
		Color(Kit.ACCENT, .22) if picked else Color(rare, .04 if lock else .10), 20, 6)
	if lock:
		cell.modulate = Color(1, 1, 1, .5)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("pick_" + id, tile)
	return tile


## A tile with its family-edge badge against `foes`, beside the critter.
static func _with_edge(tile: Button, id: String, foes: Array) -> Button:
	FamilyEdge.attach(tile, [id], foes)
	return tile


## Team mode: pick `size` different critters. opts: title, hint, size,
## current (the team now, in order), on_confirm (Callable(team: Array)),
## foes (as in open()). Your
## picks fill the slots in the order you tap them (that's the fight order);
## tap a pick again to take it out. A full team takes no more until you do.
static func open_team(shell, ids: Array, opts := {}) -> void:
	var size: int = opts.get("size", 3)
	var picks: Array = []
	for id in opts.get("current", []):
		if id in ids and not id in picks and picks.size() < size:
			picks.append(id)
	var tiles := {}
	var slots := Kit.hbox(10, [], BoxContainer.ALIGNMENT_CENTER)
	var confirm := Kit.button("Confirm", func():
		shell.close_overlay()
		var on_confirm: Callable = opts.get("on_confirm", Callable())
		if on_confirm.is_valid():
			on_confirm.call(picks.duplicate()), "go", 26, 72)
	shell.mark("pick_confirm", confirm)
	var refresh := func() -> void:
		for c in slots.get_children():
			slots.remove_child(c) # Out now, or the row lays out old and new slots together for a frame.
			c.queue_free()
		for k in size:
			slots.add_child(_slot(shell, picks[k] if k < picks.size() else "", k))
		for id in tiles:
			_restyle(tiles[id], id, picks.find(id))
		confirm.disabled = picks.size() < size
		confirm.text = "CONFIRM" if picks.size() >= size else "PICK %d MORE" % (size - picks.size())
	var toggle := func(id: String) -> void:
		var at := picks.find(id)
		if at != -1:
			picks.remove_at(at)
		elif picks.size() < size:
			picks.append(id)
		else:
			shell.toast("Team full. Tap a pick to swap it out.")
			return
		refresh.call()
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for id in ids:
		grid.add_child(LazyTile.wrap(func():
			var t := _with_edge(_team_cell(shell, id, toggle), id, opts.get("foes", []))
			tiles[id] = t
			_restyle(t, id, picks.find(id))
			return t, grid.get_child_count(), 16))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rows := ceili(ids.size() / float(COLUMNS))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = minf(rows * 196.0, maxf(360.0, shell.size.y * .5))
	scroll.add_child(grid)
	var v := Kit.vbox(12, [Kit.label(opts.get("title", "Your team"), 34),
		Kit.label(opts.get("hint", "Slot 1 fights first."), 20, Kit.MUTED), slots, scroll])
	var close := Kit.button("Cancel", shell.close_overlay, "ghost", 24, 72)
	shell.mark("pick_cancel", close)
	close.size_flags_stretch_ratio = .6
	v.add_child(Kit.hbox(12, [close, confirm]))
	refresh.call()
	shell.sheet(v)


## A team slot at the top of the team picker: the pick's face and number, or an empty ring.
static func _slot(shell, id: String, k: int) -> Control:
	var p = shell.profile
	var face: Control
	if id == "":
		face = Kit.panel(Kit.label("%d" % (k + 1), 28, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER), Kit.box(Kit.PANEL, Kit.LINE, 999, 2, 18))
		face.custom_minimum_size = Vector2(84, 84)
	else:
		var b: Dictionary = p.best(id)
		face = FighterTag.icon(id, b.get("tier", 1), 84, false, b.get("level", 0))
	var name := Kit.label("%d · %s" % [k + 1, Roster.get_critter(id).name] if id != "" else "Empty", 16, Kit.FG if id != "" else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var v := Kit.vbox(2, [face, name])
	v.custom_minimum_size.x = 110
	face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return v


static func _team_cell(shell, id: String, toggle: Callable) -> Button:
	var p = shell.profile
	var b: Dictionary = p.best(id)
	var c: Dictionary = Roster.get_critter(id)
	var name := Kit.label(str(c.name), 16, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var pow := Kit.power(p.power_of(id), 16)
	pow.alignment = BoxContainer.ALIGNMENT_CENTER
	var tag := Kit.label("", 16, Kit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	var tile := Kit.card_button(Kit.vbox(0, [FighterTag.icon(id, b.get("tier", 1), 76, false, b.get("level", 0)), name, pow, tag]),
		toggle.bind(id), Kit.LINE, Kit.PANEL, 20, 6)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.set_meta("tag", tag)
	tile.set_meta("rare", Roster.RARITY_COLORS.get(c.rarity, Kit.LINE))
	shell.mark("pick_" + id, tile)
	return tile


## A team-picker tile picked (slot `at`, glowing, "#2 ✓") or not (`at` = -1).
static func _restyle(tile: Button, _id: String, at: int) -> void:
	if not is_instance_valid(tile):
		return
	var rare: Color = tile.get_meta("rare")
	var st := Kit.box(Color(Kit.ACCENT, .30) if at != -1 else Color(rare, .10), Kit.ACCENT if at != -1 else Color(rare, .7), 20, 5 if at != -1 else 3, 6)
	for s in ["normal", "hover", "focus", "pressed", "hover_pressed"]:
		tile.add_theme_stylebox_override(s, st)
	(tile.get_meta("tag") as Label).text = "#%d" % (at + 1) if at != -1 else ""
