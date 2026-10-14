## Bag and Summon tabs until their screens land: what they will hold.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")

const INFO := {
	"bag": ["Bag", "Your gear and items.", [
		"Shells and Cores, with who is wearing each one",
		"Tap gear to move it to another critter (always free)",
		"Energy Packs, XP Chips and Summon Orbs",
	], "juggernaut"],
	"summon": ["Summon Portal", "Random Tier 1 critters for Summon Orbs you earn by playing. Orbs are never sold.", [
		"x1 or x10; a x10 always has a Rare or better",
		"Odds always on screen: 70% Common, 25% Rare, 4.5% Epic, 0.5% Legendary",
		"A Legendary is guaranteed within 150 Rare+ rolls, shared with campaign drops",
		"One free summon a day, and a weekly featured critter",
	], "prism"],
}


static func build(shell, _params: Dictionary) -> Control:
	var info: Array = INFO[shell.current]
	var root := Kit.vbox(24, [Kit.label(info[0], 44)])
	var icon := CenterContainer.new()
	icon.add_child(CritterIcon.make(info[3], 3, 300, true))
	root.add_child(icon)
	var list := Kit.vbox(12, [Kit.caption("Coming next", Kit.WARN), Kit.label(info[1], 26, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)])
	for line in info[2]:
		list.add_child(Kit.label("·  " + line, 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	root.add_child(Kit.panel(list, Kit.box(Kit.PANEL, Kit.LINE, 36, 2, 28)))
	return root
