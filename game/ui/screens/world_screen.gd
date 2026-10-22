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


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(18)
	root.add_child(shell.title_row("The Neon Circuit", {"eyebrow": "Campaign", "eyebrow_color": Color("9be89a"), "info_mark": "world_info", "info": [
		"The Circuit is a ring of glowing arenas. The Glitch has scrambled each zone's champion into a giant boss.",
		"Beat a zone's boss to open the next. Zone 1 is 1v1, Zone 2 is 2v2, then teams of 3: relays, 2v2s and big 3v3 brawls.",
		"Each zone has its own arenas: bumpers, ice, thorns, portals, a shrinking rim, lava.",
		"Purify Magma Core, the last zone, to free the whole Circuit from The Glitch.",
	]}))

	var built: int = Zones.ZONES.size()
	var open := 1
	for z in range(1, built):
		if Campaign.is_unlocked(p, z, 0):
			open = z + 1
	var boss_zone := open - 1
	var glitched := not Campaign.is_cleared(p, boss_zone, Zones.zone(boss_zone).stages.size() - 1)
	# Fill the room between the title row and the pinned button.
	var height := clampf(shell.size.y - 520.0 - (A11y.font(40) - 40) * 2.0, 560.0, 900.0)
	var b: Dictionary = p.best(p.lineup)
	var map := WorldMap.make(Zones.map_zones(), open, glitched, height, _tap.bind(shell, built, open), p.lineup, b.get("tier", 1))
	for i in map.nodes.size():
		shell.mark("zone_%d" % (i + 1), map.nodes[i])
	root.add_child(map)

	var z: int = open - 1
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


static func _tap(i: int, shell, built: int, open: int) -> void:
	if i < open:
		shell.go("campaign", {"zone": i})
		return
	var z: Dictionary = Zones.map_zones()[i]
	if i < built:
		shell.toast("Beat the boss of %s to open %s." % [Zones.map_zones()[i - 1].name, z.name])
	else:
		shell.toast("%s: coming soon!" % z.name)
