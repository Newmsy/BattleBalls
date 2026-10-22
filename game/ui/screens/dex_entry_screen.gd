## One Critterpedia page: the critter's art, number, rarity, family, role,
## base stats and what every tier adds, on one phone screen. The vibe, the
## full ability text and how fusing works sit behind the "i". Pinned: Wishlist, and View mine once found.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const Families := preload("res://sim/families.gd")
const DetailScreen := preload("res://game/ui/screens/detail_screen.gd")
const AbilityText := preload("res://game/ui/ability_text.gd")

## Base stats with the roster's top value, so the bars compare critters.
const STATS := [["HP", "hp", 140.0], ["DMG", "contact_damage", 23.0], ["SPEED", "speed", 440.0], ["SIZE", "radius", 82.0]]


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var c := Roster.get_critter(params.id)
	var d := CritterDb.get_critter(c.id)
	var owned: bool = p.owns(c.id)
	var rcol: Color = Roster.RARITY_COLORS[c.rarity]
	var root := Kit.vbox(18)
	var more := [c.vibe, AbilityText.full(c.id), "You own %d." % p.total_copies(c.id) if owned else "Summon it or win it in the campaign.",
		"Starts at T1. Fuse 3 → next tier."]
	var info: Control = shell.info_button(c.name, more, "dex_info")
	root.add_child(DetailScreen.header(shell, c.name, Kit.hbox(12, [Kit.chip(Roster.RARITY_NAMES[c.rarity], rcol), info], BoxContainer.ALIGNMENT_CENTER)))

	# Hero: the art, then number, type, family and role.
	var tags := Kit.hbox(8)
	var fam := Families.of(c.id)
	if fam != "":
		var fi: Dictionary = Families.info(fam)
		tags.add_child(Kit.chip(fi.name, Color(fi.color)))
	tags.add_child(Kit.chip(c.role, Kit.MUTED))
	var found := Kit.label("Found" if owned else "Not found yet", 22, Kit.GOOD if owned else Kit.MUTED)
	var side := Kit.vbox(10, [Kit.label("#%03d" % d.no, 26, Kit.MUTED), Kit.label(c.type, 30, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true), tags, found])
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(Kit.hbox(16, [CritterIcon.make(c.id, p.best(c.id).get("tier", 1), 190, true), side], BoxContainer.ALIGNMENT_CENTER))

	# Base stats at T1 level 1, with bars against the roster's best.
	var stats := Kit.hbox(14)
	for st in STATS:
		var v: float = d.stats[st[1]]
		var col := Kit.vbox(4, [Kit.label(st[0], 18, Kit.MUTED), Kit.label(_num(v), 26), Kit.bar(clampf(v / st[2], 0.0, 1.0), rcol, 10)])
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats.add_child(col)
	root.add_child(Kit.panel(Kit.vbox(10, [Kit.caption("Base stats"), stats]), Kit.box(Kit.PANEL, Kit.LINE, 28, 2, 18)))

	# Ability: what each tier adds, T1 to T5.
	var head := Kit.hbox(10, [Kit.caption("Ability")])
	if not c.live:
		head.add_child(Kit.chip("Coming soon", Kit.WARN, 16))
	var ladder := Kit.vbox(8, [head])
	for i in Roster.MAX_TIER:
		var tag := Kit.panel(Kit.label("T%d" % (i + 1), 20, Kit.BG, HORIZONTAL_ALIGNMENT_CENTER), Kit.box(Kit.ACCENT if i < 4 else Glyph.GOLD, Color(0, 0, 0, 0), 12, 0, 3))
		tag.custom_minimum_size = Vector2(56, 0)
		tag.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var l := Kit.label(AbilityText.change(c.id, i + 1), 21, Kit.FG if i == 0 else Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ladder.add_child(Kit.hbox(12, [tag, l]))
	root.add_child(Kit.panel(ladder, Kit.box(Kit.PANEL, Kit.LINE, 28, 2, 18)))

	var row := Kit.hbox(16)
	if c.live:
		var wished: bool = p.on_wishlist(c.id)
		var wish := Kit.button("Wishlisted" if wished else "+ Wishlist", func():
			if p.toggle_wishlist(c.id):
				shell.toast("%s %s your wishlist." % [c.name, "left" if wished else "is on"], c.id)
			else:
				shell.toast("Wishlist full (3/3).")
			shell.refresh(), "ghost", 26, 90)
		shell.mark("dex_wish", wish)
		row.add_child(wish)
	var mine := Kit.button("View mine", func(): shell.go("detail", {"id": c.id}), "go", 26, 90)
	mine.disabled = not owned
	shell.mark("dex_mine", mine)
	row.add_child(mine)
	for b in row.get_children():
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.pin(row)
	return root


static func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v
