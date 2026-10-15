## A critter in a lineup with its tier, level and Power Rating: a "T3 Lv14"
## pill above the critter and the power under it. Every screen that shows who fights in
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
const ART_SHRINK := .7


## Power Rating of a lineup slot ({critter, tier, level, gear}): the number
## on the critter's detail screen (Profile.power_of) for the same setup.
static func rating(slot: Dictionary) -> int:
	var s := Lineup.clean(slot)
	return roundi(1000.0 * Lineup.power(s) * (1.0 + Power.GEAR_STEP * s.gear.size()))


## Icon with the tier pill, power underneath. `level` 0 leaves the level out
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


## The critter with its pill above it, for rows that show power elsewhere.
## The art box is trimmed to the ball (less empty margin), so pill and
## critter together take about the height the bare icon used to.
static func icon(critter: String, tier: int, side: float, silhouette := false, level := 0) -> Control:
	var art := CritterIcon.make(critter, tier, side * ART_SHRINK, false, silhouette)
	art.radius_frac /= ART_SHRINK
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var col := GOLD if tier >= Lineup.MAX_TIER else Kit.FG
	var st := Kit.box(Color("0b0a1f", .85), col.darkened(.25), 999, 2, 0)
	st.content_margin_left = 8
	st.content_margin_right = 8
	var pill := Kit.panel(Kit.label(pill_text(tier, level), 18, col), st)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return Kit.vbox(0, [pill, art])


## "T2 Lv14", or "T2" with no level.
static func pill_text(tier: int, level := 0) -> String:
	return "T%d" % tier + (" Lv%d" % level if level > 0 else "")


## "T2 Lv14 Optic · 1,250 power", for text-only spots like the fight scene.
static func text(name: String, tier: int, power: int, level := 0) -> String:
	return "%s %s · %s power" % [pill_text(tier, level), name, Kit.commas(power)]
