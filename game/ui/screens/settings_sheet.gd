## Settings sheet behind the gear in the top bar: sound and the accessibility
## options from game/a11y.gd. Each switch says ON or OFF in words, not just colour.
extends RefCounted

const Intro := preload("res://game/ui/intro.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const A11y := preload("res://game/a11y.gd")
const Dev := preload("res://game/dev.gd")
const FightSpeed := preload("res://game/fight_speed.gd")
const Analytics := preload("res://game/online/analytics.gd")
const Platform := preload("res://game/platform/platform.gd")
const Motion := preload("res://game/ui/motion.gd")

const SWITCH_W := 136.0

const OPTIONS := [
	["reduced_motion", "Reduced motion", "No screen shake, softer hit flashes, no finisher zoom."],
	["large_text", "Larger text", ""],
	["sound_cues", "Sound cues on screen", "Shows OVERTIME and low-HP alerts that are otherwise only heard."],
]

## Privacy policy, terms and support pages (site/, served next to the web build).
const SITE := "https://battleballs.vercel.app/"
const LINKS := [["Privacy", "privacy.html"], ["Terms", "terms.html"], ["Support", "support.html"]]

const MUSIC_CREDIT := "Music: \"Crypto\" by Kevin MacLeod (incompetech.com), licensed under Creative Commons: By Attribution 4.0."


static func open(shell) -> void:
	shell.sheet(build(shell))


static func build(shell) -> Control:
	var v := Kit.vbox(18, [Kit.label("Settings", 40)])
	# Sound and feel, then accessibility, then play stats: one card each,
	# rows split by hairlines, every switch the same pill in the same column.
	var feel: Array = []
	if shell.sfx != null:
		feel.append(_sound_row(shell))
	if Platform.get_current().can_vibrate():
		feel.append(_vibration_row(shell))
	feel.append(_stats_row(shell))
	v.add_child(_group(feel))
	var access: Array = []
	for o in OPTIONS:
		access.append(_row(shell, o[0], o[1], o[2]))
	v.add_child(_group(access))
	v.add_child(_links(shell))
	if Dev.tools_enabled():
		v.add_child(_testing(shell))
	# CC-BY 4.0 asks for this credit wherever the music is used.
	v.add_child(Kit.label(MUSIC_CREDIT, 20, Color(Kit.MUTED, .7), HORIZONTAL_ALIGNMENT_LEFT, true))
	if shell.build_stamp != "":
		v.add_child(_version(shell))
	return v


## Rows in one card, a hairline between each.
static func _group(rows: Array) -> Control:
	var col := Kit.vbox(12)
	for i in rows.size():
		if i > 0:
			var line := ColorRect.new()
			line.color = Kit.LINE
			line.custom_minimum_size.y = 2
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			col.add_child(line)
		col.add_child(rows[i])
	return Kit.panel(col, Kit.box(Kit.PANEL2, Kit.LINE, 26, 2, 18))


## An on/off switch: a pill with a knob that sits right and lights green when
## on, left and dark when off, with ON or OFF in words beside the knob.
static func switch(on: bool, on_press: Callable, word := "") -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(SWITCH_W, 60)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st := Kit.box(Kit.GOOD if on else Color("0f0d2a"), Color(0, 0, 0, 0) if on else Kit.LINE, 999, 2, 0)
	for s in ["normal", "hover", "focus", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, st)
	b.add_theme_stylebox_override("disabled", Kit.box(Color(st.bg_color, .35), Kit.LINE, 999, 2, 0))
	b.pressed.connect(on_press)
	Motion.press(b)
	var knob := Panel.new()
	knob.custom_minimum_size = Vector2(46, 46)
	knob.add_theme_stylebox_override("panel", Kit.box(Kit.BG if on else Kit.MUTED, Color(0, 0, 0, 0), 999, 0, 0))
	knob.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var text := Kit.label(word if word != "" else ("ON" if on else "OFF"), 20, Kit.BG if on else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(4, [text, knob] if on else [knob, text], BoxContainer.ALIGNMENT_CENTER)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 7)
	m.add_child(row)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in [row, knob, text]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(m)
	return b


## A setting's words on the left, its switch on the right.
static func _line(title: String, text: String, sw: Control) -> Control:
	var words := Kit.vbox(2, [Kit.label(title, 28)])
	if text != "":
		var desc := Kit.label(text, 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
		desc.custom_minimum_size.x = 380
		words.add_child(desc)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	return Kit.hbox(16, [words, sw], BoxContainer.ALIGNMENT_CENTER)


## Sound: all, effects only (music off), or off. The same switch as the
## corner toggle in fights.
static func _sound_row(shell) -> Control:
	var sfx = shell.sfx
	var seg := Kit.hbox(6)
	for m in [["all", "On"], ["sfx", "No music"], ["off", "Off"]]:
		var lit: bool = sfx.mode == m[0]
		var b := Kit.button(m[1], func():
			while sfx.mode != m[0]:
				sfx.cycle_mode()
			open(shell), "go" if lit else "ghost", 20, 60)
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		b.custom_minimum_size.x = 150 if m[0] == "sfx" else 92
		seg.add_child(b)
	shell.mark("sound_mode", seg.get_child(0))
	return _line("Sound", "", seg)


static func _row(shell, key: String, title: String, text: String) -> Control:
	var sw := switch(A11y.get_value(key), func(): _toggle(shell, key))
	shell.mark("a11y_" + key, sw)
	return _line(title, text, sw)


## Anonymous play stats (game/online/analytics.gd), on by default. Turning
## them off also deletes what was already sent.
static func _stats_row(shell) -> Control:
	var on := not Analytics.opted_out()
	var flip := func():
		Analytics.set_opt_out(on)
		shell.toast("Play stats off. Anything already sent is deleted." if on else "Thanks! Anonymous play stats are on.")
		open(shell)
	var sw := switch(on, flip)
	shell.mark("stats_toggle", sw)
	return _line("Play stats", "Anonymous. Helps balance critters.", sw)


## Vibration on hits and KOs (game/platform/fight_haptics.gd). Only shown on
## devices that can buzz.
static func _vibration_row(shell) -> Control:
	var on := Platform.haptics_enabled()
	var flip := func():
		Platform.set_haptics_enabled(not on)
		Platform.get_current().haptic("tap")
		open(shell)
	var sw := switch(on, flip)
	shell.mark("haptics_toggle", sw)
	return _line("Vibration", "", sw)


static func _toggle(shell, key: String) -> void:
	A11y.set_value(key, not A11y.get_value(key))
	if key == "large_text":
		A11y.apply_fonts(shell.get_tree().root)
		shell.refresh()
	open(shell)


## Account, then the privacy policy, terms and support pages.
static func _links(shell) -> Control:
	var row := Kit.hbox(10)
	var acc := Kit.button("Account", func(): shell.close_overlay(); shell.go("account"), "ghost", 20, 64)
	shell.mark("settings_account", acc)
	row.add_child(acc)
	for l in LINKS:
		var b := Kit.button(l[0], func(): OS.shell_open(SITE + l[1]), "ghost", 20, 64)
		shell.mark("settings_" + l[1].get_basename(), b)
		row.add_child(b)
	return row


## The version line. Tapping it Dev.TAP_TO_UNLOCK times shows or hides Testing.
static func _version(shell) -> Control:
	var l := Kit.label("Battle Balls " + shell.build_stamp, 20, Color(Kit.MUTED, .7))
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	l.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and Dev.tap_version():
			shell.toast("Testing on." if Dev.tools_enabled() else "Testing off.")
			open(shell))
	shell.mark("version", l)
	return l


## Playtest shortcuts on the real save. Hidden unless Dev.tools_enabled().
static func _testing(shell) -> Control:
	var energy := Kit.button("Refill energy", func(): _refill_energy(shell), "primary", 26, 72)
	shell.mark("dev_refill_energy", energy)
	var orbs := Kit.button("+10 eggs", func(): _add_orbs(shell), "ghost", 26, 72)
	shell.mark("dev_add_orbs", orbs)
	var sparks := Kit.button("+10 Sparks", func():
		shell.profile.grant({"kind": "spark", "n": 10})
		shell.toast("+10 Ascension Sparks")
		shell.refresh(), "ghost", 26, 72)
	shell.mark("dev_add_sparks", sparks)
	for b in [energy, orbs, sparks]:
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
	# A Bounce Run chest to open on Home's Bounce Run door, as if yesterday's best was that floor.
	var chest_words := Kit.label("Bounce Run chest", 30)
	chest_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var chests := Kit.hbox(8, [chest_words])
	for f in [15, 25]:
		var b := Kit.button("F%d" % f, func(): _bounce_chest(shell, f), "ghost", 24, 72)
		b.custom_minimum_size.x = 96
		shell.mark("dev_bounce_chest_%d" % f, b)
		chests.add_child(b)
	# Two 5-star pieces and the hammers to forge them (Emberforged gear).
	var forge_words := Kit.label("Forge test", 30)
	forge_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var forge := Kit.button("+2 5★ gear", func():
		var p = shell.profile
		var type: String = ["spike_core", "iron_shell", "phoenix_charm", "echo_core"][p.gear.size() % 4]
		p.add_gear(type, 5)
		p.add_gear(type, 5)
		p.hammers += 100
		shell.toast("+2 5-star gear, +100 hammers")
		shell.refresh(), "ghost", 24, 72)
	shell.mark("dev_forge_gear", forge)
	return Kit.vbox(8, [Kit.label("Testing", 30), Kit.hbox(16, [energy, orbs, sparks]), Kit.hbox(16, [words, sw]), Kit.hbox(16, [speed_words, speeds]),
		Kit.hbox(16, [live_words, live]), chests, Kit.hbox(16, [forge_words, forge]),
		intro_words, Kit.hbox(16, [restart, finish])])


static func _bounce_chest(shell, best_floor: int) -> void:
	var BounceChest = load("res://meta/bounce_chest.gd")
	var yesterday: int = load("res://sim/bounce_run.gd").day_number(Time.get_unix_time_from_system()) - 1
	BounceChest.set_best(yesterday, best_floor)
	shell.profile.bounce_chest = mini(shell.profile.bounce_chest, yesterday - 1)
	shell.profile.changed.emit()
	shell.close_overlay()
	shell.show_tab("play")


## Replay intro: back to just out of the tutorial (stages 1-1 to 1-3 replay
## to open each part again). Unlock all: everything open.
static func _set_intro(shell, step: int) -> void:
	var p = shell.profile
	p.intro = step
	p.paced = step < Intro.DONE
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
