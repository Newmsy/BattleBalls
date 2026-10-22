## One faction's talent tree: three columns (Core, the faction's own, Ability)
## over four rows, plus the capstone. Tap a node for what it does with +/-
## buttons; Reset gives every point back for free. Fits one phone screen.
## params: {id: faction}.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Talents := preload("res://sim/talents.gd")
const FactionsScreen := preload("res://game/ui/screens/factions_screen.gd")

const COLUMNS := ["Core", "Faction", "Ability"]


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var f: String = params.get("id", "fire")
	if not f in Talents.FACTIONS:
		f = "fire"
	var col: Color = Talents.COLORS[f]
	var picks: Dictionary = p.talent_picks(f)
	var root := Kit.vbox(16)
	root.add_child(shell.title_row(Talents.NAMES[f], {"eyebrow": "Faction talents", "eyebrow_color": col, "info_title": "Factions", "info_mark": "faction_info", "info": FactionsScreen.info_text()}))

	var free: int = p.talent_points_free(f)
	var status := Kit.label("Rank %d  ·  %d point%s to spend" % [p.faction_rank(f), free, "" if free == 1 else "s"], 24, Kit.GOOD if free > 0 else Kit.MUTED)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var reset := Kit.card_button(Kit.label("Reset", 20, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER), func():
		p.reset_talents(f)
		shell.refresh(), Kit.LINE, Kit.PANEL, 999, 10)
	shell.mark("talent_reset", reset)
	var auto := Kit.card_button(Kit.label("Suggest", 20, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER), func():
		_suggest(p, f)
		shell.refresh(), Kit.LINE, Kit.PANEL, 999, 10)
	shell.mark("talent_suggest", auto)
	root.add_child(Kit.hbox(10, [status, auto, reset], BoxContainer.ALIGNMENT_CENTER))

	var labels := Kit.hbox(10)
	for c in COLUMNS:
		var l := Kit.label(c.to_upper() if c != "Faction" else Talents.NAMES[f].to_upper(), 18, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		labels.add_child(l)
	root.add_child(labels)

	for row in range(1, 6):
		var line := Kit.hbox(10)
		var open := Talents.row_open(f, picks, row)
		if row == 5: # The capstone sits in the middle column.
			line.add_child(Kit.spacer())
		for n in Talents.tree(f):
			if n.row == row:
				line.add_child(_node(shell, p, f, n, picks, open, col))
		if row == 5:
			line.add_child(Kit.spacer())
		if row > 1:
			root.add_child(_links(row, Talents.row_open(f, picks, row), col))
		root.add_child(line)
	return root


## The short lines from one row down to the next: lit once that row is open.
## Row 5 is the lone capstone, so only the middle column links to it.
static func _links(row: int, open: bool, col: Color) -> Control:
	var h := Kit.hbox(10)
	for i in 3:
		var c := CenterContainer.new()
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if row < 5 or i == 1:
			var bar := ColorRect.new()
			bar.color = col if open else Color(Kit.LINE, .6)
			bar.custom_minimum_size = Vector2(4, 12)
			c.add_child(bar)
		h.add_child(c)
	h.add_theme_constant_override("separation", 10)
	return h


static func _node(shell, p, f: String, n: Dictionary, picks: Dictionary, open: bool, col: Color) -> Control:
	var rank := int(picks.get(n.id, 0))
	var name := Kit.label(n.name, 20, Kit.FG if open else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	var node := _Node.new()
	node.kind = "crown" if n.row == 5 else ["shield", "sparkle", "bolt"][int(n.get("col", 1))]
	node.rank = rank
	node.most = 1 if n.row == 5 else int(n.max)
	node.col = col
	node.custom_minimum_size = Vector2(72, 72)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mid := CenterContainer.new()
	mid.add_child(node)
	var v := Kit.vbox(2, [mid, name])
	if n.row == 5 and rank == 0:
		v.add_child(Kit.label("%d pts" % n.cost, 18, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var b := Kit.card_button(v, _sheet.bind(shell, p, f, n), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 24, 2)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not open:
		b.modulate = Color(1, 1, 1, .55)
	shell.mark("talent_" + n.id, b)
	return b


static func _sheet(shell, p, f: String, n: Dictionary) -> void:
	var rank := int(p.talent_picks(f).get(n.id, 0))
	var v := Kit.vbox(16, [Kit.label(n.name, 36, Talents.COLORS[f])])
	# The talent once, with every rank's value in it ("+1%/2%/3% ability damage").
	var lines: Array[String] = [rank_text(n)]
	if n.max > 1:
		lines.append("Rank %d/%d" % [rank, n.max])
	if n.row == 5:
		lines.append("Capstone · %d pts · 5-star only" % n.cost)
	else:
		lines.append("For every critter" if n.row == 1 else "For %d-star+ critters" % n.row)
	for t in lines:
		var l := Kit.label(t, 23, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
		l.custom_minimum_size.x = minf(640.0, shell.size.x - 80.0)
		v.add_child(l)
	var minus := Kit.button("Remove", func():
		if not p.remove_talent(f, n.id):
			shell.toast("Higher rows still need these points.")
		shell.close_overlay()
		shell.refresh(), "ghost", 24, 80)
	minus.disabled = rank <= 0
	var plus := Kit.button("Add", func():
		p.add_talent(f, n.id)
		shell.close_overlay()
		shell.refresh(), "go", 24, 80)
	plus.disabled = not p.can_add_talent(f, n.id)
	shell.mark("talent_minus", minus)
	shell.mark("talent_plus", plus)
	v.add_child(Kit.hbox(14, [minus, plus]))
	shell.sheet(v)


## One line for a node with each rank's value split by "/": the part that
## changes between Talents.describe(n, 1..max), never cutting a number.
static func rank_text(n: Dictionary) -> String:
	var all: Array[String] = []
	for r in range(1, maxi(1, int(n.max)) + 1):
		all.append(Talents.describe(n, r))
	if all.size() == 1 or all.all(func(t): return t == all[0]):
		return all[0]
	var first: String = all[0]
	var pre := 0
	while pre < first.length() and all.all(func(t): return t.length() > pre and t[pre] == first[pre]):
		pre += 1
	var suf := 0
	while suf < first.length() - pre and all.all(func(t): return t.length() - suf - 1 >= pre and t[t.length() - suf - 1] == first[first.length() - suf - 1]):
		suf += 1
	while pre > 0 and _numeric(first[pre - 1]):
		pre -= 1
	while suf > 0 and _numeric(first[first.length() - suf]):
		suf -= 1
	var mids: Array[String] = []
	for t in all:
		mids.append(t.substr(pre, t.length() - pre - suf))
	return first.substr(0, pre) + "/".join(mids) + first.substr(first.length() - suf)


static func _numeric(ch: String) -> bool:
	return ch == "." or (ch >= "0" and ch <= "9")


## Spends free points along the suggested build (sim/talents.gd), in tree order.
static func _suggest(p, f: String) -> void:
	var target := Talents.suggested(f)
	var progress := true
	while progress:
		progress = false
		for n in Talents.tree(f):
			if int(p.talent_picks(f).get(n.id, 0)) < int(target.get(n.id, 0)) and p.add_talent(f, n.id):
				progress = true


## A talent node: a disc with its column's glyph and a ring of pips, one per
## rank, lit as points go in. Drawn once (it never animates).
class _Node extends Control:
	const Kit := preload("res://game/ui/ui_kit.gd")
	const Glyph := preload("res://game/ui/glyph.gd")
	var kind := "shield"
	var rank := 0
	var most := 3
	var col := Color.WHITE
	var _icon: Control

	func _ready() -> void:
		var side := custom_minimum_size.x
		_icon = Glyph.make(kind, side * .42, col if rank > 0 else Kit.MUTED)
		_icon.size = _icon.custom_minimum_size
		_icon.position = (Vector2(side, side) - _icon.size) / 2.0
		add_child(_icon)

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 6.0
		draw_circle(c, r - 6.0, Color(col, .18) if rank > 0 else Kit.PANEL)
		var gap := .18
		var seg := TAU / most
		for i in most:
			var a0 := -PI / 2 + i * seg + gap / 2.0
			draw_arc(c, r, a0, a0 + seg - gap, 24, col if i < rank else Color(Kit.LINE, .9), 6.0, true)
