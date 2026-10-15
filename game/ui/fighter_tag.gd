## A critter in a lineup with its tier, level and Power Rating: tier stars
## and "Lv14" above the critter, the power under it. Every screen that shows who fights in
## a progression mode (your trio, Arena Ghosts, Spire floors, campaign stages,
## the Ghost Arena fight intro) uses this, so you can size a foe up at a glance.
## Practice modes (Quick fight, Bracket, Rival) fight at equal stats, so they
## don't show it.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Lineup := preload("res://sim/lineup.gd")
const Power := preload("res://sim/power.gd")
const ART_SHRINK := .7


## Power Rating of a lineup slot ({critter, tier, level, gear}): the number
## on the critter's detail screen (Profile.power_of) for the same setup.
static func rating(slot: Dictionary) -> int:
	var s := Lineup.clean(slot)
	return roundi(1000.0 * Lineup.power(s) * (1.0 + Power.GEAR_STEP * s.gear.size()))


## Icon with tier stars and level above, power underneath. `level` 0 leaves the level out
## (PvE enemies have power but no level).
static func make(critter: String, tier: int, power: int, side: float, power_color := Kit.FG, silhouette := false, level := 0) -> Control:
	var font := 20 if side < 100.0 else 22
	var p := Kit.power(power, font, power_color)
	p.alignment = BoxContainer.ALIGNMENT_CENTER
	return Kit.vbox(0, [icon(critter, tier, side, silhouette, level), p])


## A lineup slot as make() shows it.
static func of_slot(slot: Dictionary, side: float, power_color := Kit.FG) -> Control:
	var s := Lineup.clean(slot)
	return make(s.critter, s.tier, rating(s), side, power_color, false, s.level)


## The critter with its stars and level above it, for rows that show power elsewhere.
## The art box is trimmed to the ball (less empty margin), so the header
## and critter together take about the height the bare icon used to.
static func icon(critter: String, tier: int, side: float, silhouette := false, level := 0) -> Control:
	var art := CritterIcon.make(critter, tier, side * ART_SHRINK, false, silhouette)
	art.radius_frac /= ART_SHRINK
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Tier as gold stars (the same stars as the critter screen), level beside them.
	var head := Kit.hbox(6, [Kit.glyph("stars", 22, Kit.FG, tier)], BoxContainer.ALIGNMENT_CENTER)
	if level > 0:
		head.add_child(Kit.label("Lv%d" % level, 18, Kit.MUTED))
	head.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return Kit.vbox(0, [head, art])


## "T2 Lv14", or "T2" with no level, for text-only lines (the font has no star).
static func pill_text(tier: int, level := 0) -> String:
	return "T%d" % tier + (" Lv%d" % level if level > 0 else "")


## "T2 Lv14 Optic · 1,250 power", for text-only spots like the fight scene.
static func text(name: String, tier: int, power: int, level := 0) -> String:
	return "%s %s · %s power" % [pill_text(tier, level), name, Kit.commas(power)]
