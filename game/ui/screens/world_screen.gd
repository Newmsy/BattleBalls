## Campaign world map: the Neon Circuit's zones on a path (design/pve.md
## section 3). Tap a zone you can play to open its stage list; later zones
## show as "coming soon" until they're built. Fits one screen, no scrolling.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const WorldMap := preload("res://game/ui/world_map.gd")
const Campaign := preload("res://meta/campaign.gd")
const Zones := preload("res://meta/zones.gd")
const A11y := preload("res://game/a11y.gd")

## The difficulty the map shows (Zones.DIFFICULTIES); -1 picks the hardest
## one that's open.
static var shown := -1
## Button style per difficulty tab.
const TAB_STYLES := ["go", "gold", "purple"]


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(18)
	root.add_child(shell.title_row("The Neon Circuit", {"eyebrow": "Campaign", "eyebrow_color": Color("9be89a"), "info_mark": "world_info", "info": [
		"The Circuit is a ring of glowing arenas. The Glitch has scrambled each zone's champion into a giant boss.",
		"Beat a zone's boss to open the next. Zone 1 is 1v1, Zone 2 is 2v2, then teams of 3: relays, 2v2s and big 3v3 brawls.",
		"Purify Magma Core, the last zone, to free the whole Circuit from The Glitch.",
	]}))

	var diff := shown
	if diff < 0 or not Campaign.difficulty_open(p, diff):
		diff = 0
		for d in Zones.DIFFICULTIES.size():
			if Campaign.difficulty_open(p, d):
				diff = d
	shown = diff
	if Campaign.difficulty_open(p, 1):
		root.add_child(_difficulty_tabs(shell, p, diff))
	var built: int = Zones.ZONES.size()
	var open := 1
	for z in range(1, built):
		if Campaign.is_unlocked(p, Zones.index(z, diff), 0):
			open = z + 1
	var boss_zone := Zones.index(open - 1, diff)
	var glitched := not Campaign.is_cleared(p, boss_zone, Zones.zone(boss_zone).stages.size() - 1)
	# Fill the room between the title row and the pinned button.
	# A new player's hint line (Intro.coach) takes room under the screen too.
	var hint := 80.0 if preload("res://game/ui/intro.gd").coach(p, "world") != "" else 0.0
	var height := clampf(shell.size.y - 480.0 - hint - (A11y.font(40) - 40) * 2.0 - (90.0 if Campaign.difficulty_open(p, 1) else 0.0), 520.0, 1000.0)
	var b: Dictionary = p.best(p.lineup)
	var map := WorldMap.make(Zones.map_zones(), open, glitched, height, _tap.bind(shell, built, open, diff), p.lineup, b.get("tier", 1))
	map.bleed = shell.bleed()
	for i in map.nodes.size():
		shell.mark("zone_%d" % (i + 1), map.nodes[i])
	root.add_child(map)

	var z: int = Zones.index(open - 1, diff)
	var stars := 0
	var stages: Array = Zones.zone(z).stages
	for i in stages.size():
		stars += Campaign.stars_of(p, z, i)
	var go := Kit.button("Play %s" % Zones.zone(z).name, func(): shell.go("campaign", {"zone": z}), "go", 30, 84)
	shell.mark("enter_zone", go)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var star_box := Kit.hbox(6, [Glyph.make("crown", 26, Kit.FG, 1), Kit.label("%d/%d" % [stars, stages.size() * 3], 24, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)
	shell.pin(Kit.hbox(16, [go, star_box], BoxContainer.ALIGNMENT_CENTER))
	return root


static func _tap(i: int, shell, built: int, open: int, diff := 0) -> void:
	if i < open:
		shell.go("campaign", {"zone": Zones.index(i, diff)})
		return
	var z: Dictionary = Zones.map_zones()[i]
	if i < built:
		shell.toast("Beat the boss of %s to open %s." % [Zones.map_zones()[i - 1].name, z.name])
	else:
		shell.toast("%s: coming soon!" % z.name)


## Normal / Hard / Nightmare, once Hard is open. A locked one says what opens it.
static func _difficulty_tabs(shell, p, diff: int) -> Control:
	var row := Kit.hbox(10, [], BoxContainer.ALIGNMENT_CENTER)
	for d in Zones.DIFFICULTIES.size():
		var open: bool = Campaign.difficulty_open(p, d)
		var name: String = Zones.DIFFICULTY_NAMES[d]
		var b := Kit.button(name, func():
			if not open:
				shell.toast("Beat %s on %s to open %s." % [Zones.zone(Zones.ZONES.size() - 1).boss, Zones.DIFFICULTY_NAMES[d - 1], name])
				return
			shown = d
			shell.refresh(), TAB_STYLES[d] if d == diff else "ghost", 24, 64)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not open:
			b.modulate = Color(1, 1, 1, .5)
		shell.mark("difficulty_%s" % Zones.DIFFICULTIES[d], b)
		row.add_child(b)
	return row
