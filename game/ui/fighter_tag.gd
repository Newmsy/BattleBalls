## A critter in a lineup with its tier and Power Rating: a "T3" pill on the
## icon's corner and the power under it. Every screen that shows who fights in
## a progression mode (your trio, Arena Ghosts, Spire floors, campaign stages,
## the Ghost Arena fight intro) uses this, so you can size a foe up at a glance.
## Practice modes (Quick fight, Bracket, Rival) fight at equal stats, so they
## don't show it.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Lineup := preload("res://sim/lineup.gd")
const Power := preload("res://sim/power.gd")
const GOLD := Color("ffc23d")


## Power Rating of a lineup slot ({critter, tier, level, gear}): the number
## on the critter's detail screen (Profile.power_of) for the same setup.
static func rating(slot: Dictionary) -> int:
	var s := Lineup.clean(slot)
	return roundi(1000.0 * Lineup.power(s) * (1.0 + Power.GEAR_STEP * s.gear.size()))


## Icon with the tier pill, power underneath.
static func make(critter: String, tier: int, power: int, side: float, power_color := Kit.FG, silhouette := false) -> Control:
	var font := 20 if side < 100.0 else 22
	var p := Kit.power(power, font, power_color)
	p.alignment = BoxContainer.ALIGNMENT_CENTER
	return Kit.vbox(0, [icon(critter, tier, side, silhouette), p])


## A lineup slot as make() shows it.
static func of_slot(slot: Dictionary, side: float, power_color := Kit.FG) -> Control:
	var s := Lineup.clean(slot)
	return make(s.critter, s.tier, rating(s), side, power_color)


## The critter icon with only the tier pill, for rows that show power elsewhere.
static func icon(critter: String, tier: int, side: float, silhouette := false) -> Control:
	var art := CritterIcon.make(critter, tier, side, false, silhouette)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var col := GOLD if tier >= Lineup.MAX_TIER else Kit.FG
	var st := Kit.box(Color("0b0a1f", .85), col.darkened(.25), 999, 2, 0)
	st.content_margin_left = 8
	st.content_margin_right = 8
	var pill := Kit.panel(Kit.label("T%d" % tier, 18, col), st)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(pill)
	pill.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	return art


## "T2 Optic · 1,250 power", for text-only spots like the fight scene.
static func text(name: String, tier: int, power: int) -> String:
	return "T%d %s · %s power" % [tier, name, Kit.commas(power)]
