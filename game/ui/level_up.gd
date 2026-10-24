## The account level up moment, in the Bounce Run TIER UP style: a gold
## burst, a card that bounces in with "LEVEL 5!", the energy bar sweeping to
## full and anything the level opens sliding up under it. It celebrates
## without getting in the way: taps go straight through to the screen (and
## send it off early), and it leaves by itself after a couple of seconds.
## Render-only, tweens only.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const A11y := preload("res://game/a11y.gd")
const FightSpeed := preload("res://game/fight_speed.gd")

const GOLD := Color("ffd166")
const STAY := 2.6 ## Seconds before it goes by itself.

var _leaving := false


## Over `layer` (the shell's top layer), for reaching account `level`.
static func show_on(layer: Control, level: int, sfx = null) -> Control:
	print("UI_LEVEL_UP %d" % level)
	return celebrate(layer, {"caption": "ACCOUNT", "head": "LEVEL %d!" % level, "bar": "ENERGY REFILLED", "perk": perk(level)}, sfx)


## The same moment for anything else worth it (a new arena league). opts:
## caption, head, color (gold), bar (caption under an energy bar that fills;
## none without it), perk (a NEW chip).
static func celebrate(layer: Control, opts: Dictionary, sfx = null) -> Control:
	var u = load("res://game/ui/level_up.gd").new()
	u.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	u.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(u)
	u._build(opts, sfx)
	return u


## What a level opens, if anything (a new fight speed).
static func perk(level: int) -> String:
	var i := FightSpeed.UNLOCK_LEVELS.find(level)
	return "%dx fight speed" % int(FightSpeed.SPEEDS[i]) if i > 0 else ""


func _build(opts: Dictionary, sfx) -> void:
	var gold: Color = opts.get("color", GOLD)
	var dim := ColorRect.new()
	dim.color = Color(.02, .015, .06, .55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var burst := Panel.new()
	burst.add_theme_stylebox_override("panel", Kit.box(Color(gold, .5), Color(0, 0, 0, 0), 999, 0, 0))
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.size = Vector2(180, 180)
	add_child(burst)
	var head := Kit.label(str(opts.get("head", "")), 64, gold, HORIZONTAL_ALIGNMENT_CENTER)
	var lines: Array = [Kit.caption(str(opts.get("caption", "")), gold), head]
	var bar: ProgressBar = null
	if opts.has("bar"):
		bar = Kit.bar(.25, Color("5ce1ff"), 22)
		bar.custom_minimum_size.x = 380
		bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lines.append_array([bar, Kit.caption(str(opts.bar))])
	var new_line: Control = null
	var perk_text: String = opts.get("perk", "")
	if perk_text != "":
		new_line = Kit.chip("NEW · " + perk_text.to_upper(), Kit.GOOD, 22)
		new_line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lines.append(new_line)
	var v := Kit.vbox(14, lines)
	for c in v.get_children():
		if c is Label:
			c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var card := Kit.panel(v, Kit.box(Color("221c46"), gold, 36, 4, 34))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(card)
	if sfx != null:
		sfx.play("twinkle", 0.0, .9)
	await get_tree().process_frame
	if not is_instance_valid(card):
		return
	burst.position = card.get_global_rect().get_center() - get_global_rect().position - burst.size / 2.0
	burst.pivot_offset = burst.size / 2.0
	var tw := create_tween()
	if A11y.motion() == 0.0:
		burst.visible = false
		modulate.a = 0.0
		if bar != null:
			bar.value = 1.0
		tw.tween_property(self, "modulate:a", 1.0, .15)
		tw.tween_interval(STAY)
		tw.tween_callback(leave)
		return
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2(.7, .7)
	dim.modulate.a = 0.0
	if new_line != null:
		new_line.modulate.a = 0.0
	tw.tween_property(dim, "modulate:a", 1.0, .2)
	tw.parallel().tween_property(card, "scale", Vector2.ONE, .35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(burst, "scale", Vector2(6, 6), .7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(burst, "modulate:a", 0.0, .7)
	tw.tween_callback(func(): head.pivot_offset = head.size / 2.0)
	tw.tween_property(head, "scale", Vector2(1.22, 1.22), .16).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(head, "modulate", Color(1.4, 1.3, 1.0), .16)
	tw.tween_property(head, "scale", Vector2.ONE, .22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(head, "modulate", Color.WHITE, .3)
	if bar != null:
		tw.tween_property(bar, "value", 1.0, .45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if new_line != null:
		tw.tween_callback(func():
			new_line.modulate.a = 1.0
			new_line.pivot_offset = new_line.size / 2.0
			new_line.scale = Vector2(.6, .6)
			if sfx != null:
				sfx.play("summon_pop", -4.0, 1.2))
		tw.tween_property(new_line, "scale", Vector2.ONE, .26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(STAY)
	tw.tween_callback(leave)


## Any press sends it off early; the press itself still lands on the screen.
func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		leave()


func leave() -> void:
	if _leaving or not is_inside_tree():
		return
	_leaving = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, .2)
	tw.tween_callback(queue_free)
