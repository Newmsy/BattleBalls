## Critter Plunge race talents, a sheet over the Plunge screen: your medals,
## the nine families (yours picked first) and the picked family's three
## talents, each with its rank, what the next rank costs and Buy
## (meta/plunge_talents.gd). Fits one phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const PlungeTalents := preload("res://meta/plunge_talents.gd")
const Families := preload("res://sim/families.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")

## The family on show, kept while the game runs.
static var family := ""


static func open(shell, racer: String) -> void:
	if family == "" or not Families.MEMBERS.has(family):
		family = Families.of(racer) if racer != "" else "nature"
	shell.sheet(_build(shell, racer))


static func _build(shell, racer: String) -> Control:
	var p = shell.profile
	var v := Kit.vbox(16, [Kit.label("Race talents", 36, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)])
	v.add_child(medal_row(p, 30))
	v.add_child(Kit.label("Medals from podium finishes buy talents for a family's racers. 1 gold = 2 silver = 4 bronze.", 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
	var fams := Kit.hbox(4, [], BoxContainer.ALIGNMENT_CENTER)
	for fam in Families.MEMBERS:
		var on: bool = fam == family
		var b := Kit.button("", func():
			family = fam
			shell.close_overlay()
			open(shell, racer), "go" if on else "ghost", 18, 58)
		b.custom_minimum_size.x = 58
		var icon := FamilyIcon.make(fam, 36, false)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		b.add_child(icon)
		shell.mark("plunge_fam_" + fam, b)
		fams.add_child(b)
	v.add_child(fams)
	v.add_child(Kit.label(Families.info(family).name, 28, FamilyIcon.color(family), HORIZONTAL_ALIGNMENT_CENTER))
	for tal in PlungeTalents.TALENTS:
		v.add_child(_talent_row(shell, racer, tal))
	var close := Kit.button("Close", shell.close_overlay, "ghost", 26, 80)
	shell.mark("plunge_talents_close", close)
	v.add_child(close)
	return v


## Your gold, silver and bronze medals side by side.
static func medal_row(p, size: int) -> Control:
	var m: Dictionary = PlungeTalents.medals(p)
	var row := Kit.hbox(26, [], BoxContainer.ALIGNMENT_CENTER)
	for k in PlungeTalents.MEDALS:
		row.add_child(Kit.amount("medal_" + k, int(m.get(k, 0)), size))
	return row


static func _talent_row(shell, racer: String, tal: Dictionary) -> Control:
	var p = shell.profile
	var r := PlungeTalents.rank(p, family, tal.id)
	var info := Kit.vbox(4, [Kit.label("%s  %d/%d" % [tal.name, r, PlungeTalents.MAX_RANK], 24),
		Kit.label(PlungeTalents.line(tal, maxi(1, r)) + ("" if r > 0 else " at rank 1"), 20, Kit.ACCENT if r > 0 else Kit.MUTED)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(12, [info], BoxContainer.ALIGNMENT_CENTER)
	var cost := PlungeTalents.price(r)
	if cost.is_empty():
		row.add_child(Kit.label("Maxed", 22, Kit.MUTED))
	else:
		var price := Kit.hbox(8, [], BoxContainer.ALIGNMENT_CENTER)
		for k in PlungeTalents.MEDALS:
			if int(cost.get(k, 0)) > 0:
				price.add_child(Kit.amount("medal_" + k, int(cost[k]), 20))
		var can := PlungeTalents.can_buy(p, family, tal.id)
		var buy := Kit.button("Buy", func():
			if PlungeTalents.buy(p, family, tal.id):
				shell.toast("%s rank %d" % [tal.name, r + 1])
			shell.close_overlay()
			open(shell, racer), "go" if can else "ghost", 22, 64)
		buy.disabled = not can
		shell.mark("plunge_buy_" + tal.id, buy)
		row.add_child(Kit.vbox(4, [price, buy]))
	return Kit.panel(row, Kit.box(Kit.PANEL2, Color(FamilyIcon.color(family), .4), 22, 2, 12))
