## A critter's XP gain as a row: icon, name and level, and a bar that fills
## from the old XP to the new, popping LEVEL UP! each time it wraps. Takes
## Profile.gain_xp()'s {id, tier, xp, from_level, from_xp, to_level, to_xp,
## cap}. Render-only: one tween that stops with the bar, so no per-frame cost after.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Roster := preload("res://game/ui/roster.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Profile := preload("res://meta/profile.gd")
const A11y := preload("res://game/a11y.gd")

const GOLD := Color("ffd166")


static func _frac(level: int, xp: int, cap: int) -> float:
	return 1.0 if level >= cap else clampf(xp / float(Profile.xp_to_next(level)), 0.0, 1.0)


static func _level_text(level: int, cap: int) -> String:
	return "Lv %d%s" % [level, " · MAX" if level >= cap else ""]


## The row. `sfx` (game/audio/sfx.gd, may be null) chimes on level-ups;
## `delay` waits for the popup to slide in first.
static func make(g: Dictionary, sfx = null, delay := 0.35) -> Control:
	var cap: int = g.get("cap", 10)
	var c: Dictionary = Roster.get_critter(g.id)
	var art := CritterIcon.make(g.id, g.get("tier", 1), 72)
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name := Kit.label(str(c.name), 24)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.clip_text = true
	var lv := Kit.label(_level_text(g.from_level, cap), 24, Kit.FG, HORIZONTAL_ALIGNMENT_RIGHT)
	var bar := Kit.bar(_frac(g.from_level, g.from_xp, cap), Kit.GOOD, 20)
	var gained := Kit.label("+%d XP" % g.xp, 20, Kit.MUTED)
	gained.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pop := Kit.label("LEVEL UP!", 22, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	pop.modulate.a = 0.0
	var info := Kit.vbox(4, [Kit.hbox(8, [name, lv]), bar, Kit.hbox(8, [gained, pop])])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(14, [art, info])
	row.ready.connect(_play.bind(row, g, art, lv, bar, pop, sfx, delay), CONNECT_ONE_SHOT)
	return row


static func _play(row: Control, g: Dictionary, art: Control, lv: Label, bar: ProgressBar, pop: Label, sfx, delay: float) -> void:
	var cap: int = g.get("cap", 10)
	var ups: int = g.to_level - g.from_level
	# The whole gain as one number: whole levels plus the fraction into the
	# next. One eased tween runs it, so the bar glides at one speed through
	# every wrap instead of stopping and starting at each level.
	if g.from_level >= cap:
		return # Already maxed: the bar just stays full.
	var capped: bool = g.to_level >= cap
	var start := _frac(g.from_level, g.from_xp, cap)
	var total: float = ups + (0.0 if capped else _frac(g.to_level, g.to_xp, cap))
	var seconds := clampf(1.0 + 0.4 * ups, 1.0, 3.0)
	var calm := A11y.reduced_motion
	var reached := [0]
	var show := func(p: float) -> void:
		var whole := int(p + 0.0001) # The eased end lands a hair under a whole level.
		while reached[0] < mini(whole, ups):
			reached[0] += 1
			var level: int = g.from_level + reached[0]
			_level_up(row, art, lv, bar, pop, level, cap, sfx, calm)
		# At the cap it ends full instead of wrapping to an empty bar.
		bar.value = 1.0 if capped and p >= total - 0.0001 else p - whole
	var tw := row.create_tween()
	tw.tween_interval(delay)
	tw.tween_method(show, start, total, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(show.bind(total))


static func _level_up(row: Control, art: Control, lv: Label, bar: ProgressBar, pop: Label, level: int, cap: int, sfx, calm: bool) -> void:
	lv.text = _level_text(level, cap)
	lv.add_theme_color_override("font_color", GOLD)
	if sfx != null:
		sfx.play("twinkle", 0.0, 1.0 + 0.06 * (level % 6))
	var n: int = int(pop.get_meta("n", 0)) + 1
	pop.set_meta("n", n)
	pop.text = "LEVEL UP!" if n == 1 else "LEVEL UP! x%d" % n
	pop.modulate.a = 1.0
	if calm:
		return
	# A quick pop on the critter, the label and a gold flash on the bar.
	var tw := row.create_tween().set_parallel()
	for c: Control in [art, pop, lv]:
		c.pivot_offset = c.size / 2.0
		c.scale = Vector2(1.3, 1.3)
		tw.tween_property(c, "scale", Vector2.ONE, .28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bar.modulate = Color(2.0, 1.7, 0.9)
	tw.tween_property(bar, "modulate", Color.WHITE, .35)


## Every critter's row from a result's `critters` (Campaign.give_xp), under
## an XP caption, or null when the result has none (an older saved result).
static func rows(result: Dictionary, sfx = null) -> Control:
	var gains: Array = result.get("critters", [])
	if gains.is_empty():
		return null
	var box := Kit.vbox(10, [Kit.caption("XP")])
	for k in gains.size():
		box.add_child(make(gains[k], sfx, 0.35 + 0.15 * k))
	return box
