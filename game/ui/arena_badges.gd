## Arena win streak and revenge badges (Newms 2026-11-05), shared by a
## mode's page, its opponent rows and both modes' result popups.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")

const FLAME := Color("ff8a2a")
const REVENGE := Color("ff4a5e")


## A flame and "N in a row": shown from ArenaStore.STREAK_FROM wins.
static func streak(n: int, font := 20) -> Control:
	var row := Kit.hbox(4, [Kit.glyph("flame", font * 1.4, Color.WHITE), Kit.label("%d in a row" % n, font, FLAME)], BoxContainer.ALIGNMENT_CENTER)
	var p := Kit.panel(row, Kit.box(Color(FLAME, .14), FLAME, 999, 2, 4))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## "REVENGE" with the trophy multiplier, for a raider's row.
static func revenge(font := 16) -> Control:
	var c := Kit.chip("REVENGE x%s" % str(ArenaStore.REVENGE_MULT), REVENGE, font)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return c


## What a finished attack's history entry earns a result popup: the streak
## flame with its bonus, and a revenge mark. Empty when neither.
static func result_row(entry: Dictionary) -> Control:
	var bits: Array = []
	if bool(entry.get("won", false)) and int(entry.get("streak", 0)) >= ArenaStore.STREAK_FROM:
		var s := streak(int(entry.streak), 24)
		bits.append(s)
		if int(entry.get("bonus", 0)) > 0:
			bits.append(Kit.label("+%d bonus" % int(entry.bonus), 22, FLAME))
	if bool(entry.get("revenge", false)):
		bits.append(revenge(20) if bool(entry.get("won", false)) else Kit.chip("Revenge failed", Kit.MUTED, 20))
	if bits.is_empty():
		return null
	return Kit.hbox(10, bits, BoxContainer.ALIGNMENT_CENTER)
