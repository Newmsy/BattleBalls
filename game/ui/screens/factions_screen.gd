## Factions: the nine faction talent trees as a 3x3 grid. Each tile shows the
## Faction Rank, points waiting to be spent and progress to the next rank.
## Tap one to open its tree (faction_screen.gd). Rules live in sim/talents.gd
## and meta/profile.gd; this only shows them. Fits one phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Idle := preload("res://game/ui/idle.gd")
const Talents := preload("res://sim/talents.gd")
const Painted := preload("res://game/ui/painted.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(20)
	root.add_child(shell.title_row("Factions", {"eyebrow": "Talent trees", "info_mark": "factions_info", "info": info_text()}))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	# The tiles share the page's height, so tall phones show more of each painting.
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for f in Talents.FACTIONS:
		grid.add_child(_tile(shell, p, f))
	root.add_child(grid)
	return root


static func info_text() -> Array:
	return [
		"Each faction has one talent tree, shared by all its critters.",
		"Every fight gives Faction XP to the families of your critters that fought, more for a win, and Totem of Nine wins give extra to the day's faction. Each full ring is a point, and a faction's first critter at each of 2-5 stars gives one too. Max %d per tree; every rank past that gives an Ascension Spark." % Talents.MAX_POINTS,
		"A critter uses the rows its stars unlock: 1 star row 1, up to 4 stars row 4, and 5 stars the capstone. Resetting a tree is free, any time.",
		"Rows open after %s points spent." % _and_list(Talents.ROW_GATE.slice(1).map(func(g): return str(g))),
	]


## "5, 12, 20 and 26".
static func _and_list(words: Array) -> String:
	if words.size() < 2:
		return "".join(words)
	return ", ".join(words.slice(0, -1)) + " and " + str(words[-1])


static func _tile(shell, p, f: String) -> Control:
	var col: Color = Talents.COLORS[f]
	var rank: int = p.faction_rank(f)
	var free: int = p.talent_points_free(f)
	var next: Dictionary = p.faction_xp_rank(f)
	var lv: Dictionary = p.faction_level(f)
	var owned := 0
	for id in Talents.MEMBERS[f]:
		if p.owns(id):
			owned += 1
	var v := Kit.vbox(4, [
		Kit.label(Talents.NAMES[f], 26, col.lightened(.25), HORIZONTAL_ALIGNMENT_CENTER),
		Kit.label("Rank %d" % maxi(rank, int(lv.level)), 21, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
		# Past 30 the bar fills toward the next level and its Ascension Spark.
		Kit.bar(float(lv.xp) / float(lv.need) if rank >= Talents.MAX_POINTS else float(next.xp) / float(next.need), Color("b46cff") if rank >= Talents.MAX_POINTS else col, 10),
		Kit.label("%d/%d critters" % [owned, Talents.MEMBERS[f].size()], 17, Color("cfcdf0"), HORIZONTAL_ALIGNMENT_CENTER),
	])
	# The words sit on a dark glass card at the foot, so they read over any painting.
	var words := Kit.panel(v, Kit.box(Color(0.04, 0.03, 0.12, .74), Color(0, 0, 0, 0), 20, 0, 6))
	words.size_flags_vertical = Control.SIZE_SHRINK_END
	var badge := Kit.label("%d to spend" % free if free > 0 else " ", 17, Kit.GOOD, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(badge)
	if free > 0:
		Idle.breathe(badge, .12, .6)
	# The family's painted home behind the words, darkest at the foot where they sit.
	var stack := MarginContainer.new()
	stack.custom_minimum_size.y = 196
	if ResourceLoader.exists(Painted.ART % ("families/" + f)):
		stack.add_child(Painted.make("families/" + f, {"radius": 26.0, "bottom_dark": .85, "top_dark": .1}))
	var icon := FamilyIcon.make(f, 40)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var inner := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		inner.add_theme_constant_override("margin_" + side, 8)
	inner.add_child(words)
	stack.add_child(inner)
	var corner := MarginContainer.new()
	for side in ["left", "top"]:
		corner.add_theme_constant_override("margin_" + side, 8)
	corner.add_child(icon)
	stack.add_child(corner)
	var t := Kit.card_button(stack, func(): shell.go("faction", {"id": f}), Color(col, .8 if free > 0 else .45), Kit.PANEL, 28, 3)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.mark("faction_" + f, t)
	return t
