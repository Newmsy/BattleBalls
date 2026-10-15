## Settings sheet behind the gear in the top bar: the accessibility options
## from game/a11y.gd. Each switch says ON or OFF in words, not just colour.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const A11y := preload("res://game/a11y.gd")
const Analytics := preload("res://game/online/analytics.gd")

const OPTIONS := [
	["reduced_motion", "Reduced motion", "No screen shake, softer hit flashes, no finisher zoom."],
	["large_text", "Larger text", "Bigger text on every screen."],
	["sound_cues", "Sound cues on screen", "Shows OVERTIME and low-HP alerts that are otherwise only heard."],
]


static func open(shell) -> void:
	shell.sheet(build(shell))


static func build(shell) -> Control:
	var v := Kit.vbox(22, [Kit.label("Settings", 40)])
	for o in OPTIONS:
		v.add_child(_row(shell, o[0], o[1], o[2]))
	v.add_child(_stats_row(shell))
	var note := Kit.label("Colourblind-friendly marks are always on: your critter has a solid ring, the foe a dashed spiky one, and every rarity has its own shape.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	# The sheet measures itself before layout, so wrapped text needs a real width.
	note.custom_minimum_size.x = 600
	v.add_child(note)
	var clear := Control.new() ## Room for the sound toggle in the corner.
	clear.custom_minimum_size.y = 40
	v.add_child(clear)
	return v


static func _row(shell, key: String, title: String, text: String) -> Control:
	var on := A11y.get_value(key)
	var sw := Kit.button("On" if on else "Off", func(): _toggle(shell, key), "go" if on else "ghost", 26, 72)
	sw.custom_minimum_size.x = 132
	sw.size_flags_horizontal = Control.SIZE_SHRINK_END
	shell.mark("a11y_" + key, sw)
	var desc := Kit.label(text, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	desc.custom_minimum_size.x = 440
	var words := Kit.vbox(4, [Kit.label(title, 30), desc])
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return Kit.hbox(16, [words, sw])


## Anonymous play stats (game/online/analytics.gd), on by default. Turning
## them off also deletes what was already sent.
static func _stats_row(shell) -> Control:
	var on := not Analytics.opted_out()
	var flip := func():
		Analytics.set_opt_out(on)
		shell.toast("Play stats off. Anything already sent is deleted." if on else "Thanks! Anonymous play stats are on.")
		open(shell)
	var sw := Kit.button("On" if on else "Off", flip, "go" if on else "ghost", 26, 72)
	sw.custom_minimum_size.x = 132
	sw.size_flags_horizontal = Control.SIZE_SHRINK_END
	shell.mark("stats_toggle", sw)
	var desc := Kit.label("Anonymous stats on how fights and the tutorial go, so we can balance critters. No names, no ads.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	desc.custom_minimum_size.x = 440
	var words := Kit.vbox(4, [Kit.label("Play stats", 30), desc])
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return Kit.hbox(16, [words, sw])


static func _toggle(shell, key: String) -> void:
	A11y.set_value(key, not A11y.get_value(key))
	if key == "large_text":
		A11y.apply_fonts(shell.get_tree().root)
		shell.refresh()
	open(shell)
