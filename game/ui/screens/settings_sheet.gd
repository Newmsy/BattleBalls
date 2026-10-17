## Settings sheet behind the gear in the top bar: sound and the accessibility
## options from game/a11y.gd. Each switch says ON or OFF in words, not just colour.
extends RefCounted

const Intro := preload("res://game/ui/intro.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const A11y := preload("res://game/a11y.gd")
const Dev := preload("res://game/dev.gd")
const FightSpeed := preload("res://game/fight_speed.gd")
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
	if shell.sfx != null:
		v.add_child(_sound_row(shell))
	for o in OPTIONS:
		v.add_child(_row(shell, o[0], o[1], o[2]))
	v.add_child(_stats_row(shell))
	if Dev.TOOLS_ENABLED:
		v.add_child(_testing(shell))
	var note := Kit.label("Colourblind-friendly marks are always on: your critter has a solid ring, the foe a dashed spiky one, and every rarity has its own shape.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	# The sheet measures itself before layout, so wrapped text needs a real width.
	note.custom_minimum_size.x = 600
	v.add_child(note)
	return v


## Sound: all, effects only (music off), or off. The same switch as the
## corner toggle in fights.
static func _sound_row(shell) -> Control:
	var sfx = shell.sfx
	var words: Dictionary = {"all": "On", "sfx": "No music", "off": "Off"}
	var sw := Kit.button(words[sfx.mode], func():
		sfx.cycle_mode()
		open(shell), "go" if sfx.mode != "off" else "ghost", 24, 72)
	sw.custom_minimum_size.x = 170
	sw.size_flags_horizontal = Control.SIZE_SHRINK_END
	shell.mark("sound_mode", sw)
	var desc := Kit.label("Music and sound effects, effects only, or silent.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	desc.custom_minimum_size.x = 400
	var text := Kit.vbox(4, [Kit.label("Sound", 30), desc])
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return Kit.hbox(16, [text, sw])


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


## Playtest shortcuts on the real save. Hidden when Dev.TOOLS_ENABLED is off.
static func _testing(shell) -> Control:
	var energy := Kit.button("Refill energy", func(): _refill_energy(shell), "primary", 26, 72)
	shell.mark("dev_refill_energy", energy)
	var orbs := Kit.button("+10 eggs", func(): _add_orbs(shell), "ghost", 26, 72)
	shell.mark("dev_add_orbs", orbs)
	for b in [energy, orbs]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var free := Dev.free_summons()
	var sw := Kit.button("On" if free else "Off", func(): Dev.set_free_summons(not free); open(shell), "go" if free else "ghost", 26, 72)
	sw.custom_minimum_size.x = 132
	shell.mark("dev_free_summons", sw)
	var words := Kit.label("Unlimited summons", 30)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var all := FightSpeed.all_unlocked()
	var speeds := Kit.button("On" if all else "Off", func(): FightSpeed.set_unlock_all(not all); open(shell), "go" if all else "ghost", 26, 72)
	speeds.custom_minimum_size.x = 132
	shell.mark("dev_all_speeds", speeds)
	var speed_words := Kit.label("All fight speeds", 30)
	speed_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Quick fight's FIGHT! finds a real player on the live server (server/).
	var live_on := Dev.live_fights()
	var live := Kit.button("On" if live_on else "Off", func(): Dev.set_live_fights(not live_on); open(shell), "go" if live_on else "ghost", 26, 72)
	live.custom_minimum_size.x = 132
	live.disabled = Dev.live_url() == ""
	shell.mark("dev_live_fights", live)
	var live_words := Kit.label("Live Quick fights" if Dev.live_url() != "" else "Live fights (no server yet)", 30)
	live_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The new player's guided first fights (game/ui/intro.gd) on this save.
	var restart := Kit.button("Replay intro", func(): _set_intro(shell, 0), "ghost", 24, 72)
	shell.mark("dev_intro_restart", restart)
	var finish := Kit.button("Unlock all", func(): _set_intro(shell, Intro.DONE), "ghost", 24, 72)
	shell.mark("dev_intro_done", finish)
	for b in [restart, finish]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var intro_words := Kit.label("New player unlocks · step %d/%d" % [Intro.step(shell.profile), Intro.DONE], 22, Kit.MUTED)
	return Kit.vbox(8, [Kit.label("Testing", 30), Kit.hbox(16, [energy, orbs]), Kit.hbox(16, [words, sw]), Kit.hbox(16, [speed_words, speeds]),
		Kit.hbox(16, [live_words, live]),
		intro_words, Kit.hbox(16, [restart, finish])])


## Replay intro: back to just out of the tutorial (stages 1-1 to 1-3 replay
## to open each part again). Unlock all: everything open.
static func _set_intro(shell, step: int) -> void:
	var p = shell.profile
	p.intro = step
	Intro.arena_fought = false
	p.changed.emit()
	shell.close_overlay()
	shell.show_tab("play")
	shell.toast("New player flow restarted: win stage 1-1." if step == 0 else "Everything unlocked.")


static func _refill_energy(shell) -> void:
	var p = shell.profile
	p.energy = maxi(p.energy, p.energy_max)
	p.energy_time = int(Time.get_unix_time_from_system())
	p.changed.emit() # main.gd saves the profile on changed.
	shell.toast("Energy full")
	shell.refresh()


static func _add_orbs(shell) -> void:
	shell.profile.orbs += 10
	shell.profile.changed.emit()
	shell.toast("+10 eggs")
	shell.refresh()
