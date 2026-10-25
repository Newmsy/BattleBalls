## Opening a Bounce Run chest (meta/bounce_chest.gd), over the whole shell:
## the painted chest drops in and wobbles, a tap shakes it harder and harder
## until the lid bursts off in a flash of light, then each reward arcs out of
## the chest into its slot. Collect grants them and they fly to the top bar.
## Any tap during the show skips to the end. Render-only, tweens only.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const Motion := preload("res://game/ui/motion.gd")
const ChestArt := preload("res://game/ui/chest_art.gd")
const BounceChest := preload("res://meta/bounce_chest.gd")
const PassScreen := preload("res://game/ui/screens/pass_screen.gd")

const CHEST_H := 320.0
const CARD := 112.0 ## Reward card side.

enum Phase { ARRIVING, WAITING, OPENING, OPEN }

var shell
var chest: Dictionary ## From BounceChest.pending().
var rewards: Array
var phase := Phase.ARRIVING
var tier: Dictionary

var _art: Control
var _rays: Control
var _flash: ColorRect
var _hint: Label
var _cards: Array = []
var _row: HBoxContainer
var _collect: Button
var _tw: Tween


## Shows chest `c` (BounceChest.pending()) on `shell`'s overlay layer.
static func show_on(shell_, c: Dictionary) -> Control:
	var v = load("res://game/ui/bounce_chest_open.gd").new()
	v.shell = shell_
	v.chest = c
	v.rewards = BounceChest.rewards(int(c.tier), int(c.day))
	v.tier = BounceChest.TIERS[int(c.tier)]
	v._build()
	shell_.overlay(v, "bounce_chest")
	print("UI_BOUNCE_CHEST day=%d tier=%s" % [int(c.day), v.tier.id])
	v._arrive.call_deferred()
	return v


func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color("0d0826")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_rays = _Rays.new()
	_rays.color = tier.color
	_rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rays.modulate.a = 0.0
	add_child(_rays)
	var col := Kit.vbox(22)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	col.add_child(Kit.caption("BOUNCE RUN · BEST CLIMB FLOOR %d" % int(chest.floor), Kit.MUTED))
	col.add_child(Kit.label(str(tier.name).to_upper(), 52, tier.color))
	for c in col.get_children():
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(0, CHEST_H + 20)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art = ChestArt.make(str(tier.id), CHEST_H)
	holder.add_child(_art)
	col.add_child(holder)
	_row = Kit.hbox(12, [], BoxContainer.ALIGNMENT_CENTER)
	_row.custom_minimum_size.y = CARD + 40
	for r in rewards:
		var card := _card(r)
		card.modulate.a = 0.0
		_cards.append(card)
		_row.add_child(card)
	col.add_child(_row)
	_hint = Kit.label("Tap to open", 28, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	_hint.modulate.a = 0.0
	_collect = Kit.button("Collect", _on_collect, "go", 30, 96)
	_collect.custom_minimum_size.x = 320
	_collect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_collect.visible = false
	if shell != null:
		shell.mark("bounce_chest_collect", _collect)
	var foot := Kit.vbox(0, [_hint, _collect])
	foot.custom_minimum_size.y = 110
	col.add_child(foot)
	_flash = ColorRect.new()
	_flash.color = Color(1, .97, .9, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)


## One reward: its icon over its amount (gear shows the piece alone).
func _card(r: Dictionary) -> Control:
	var icon: Control = PassScreen.reward_icon(shell, r, CARD * (.9 if r.kind == "gear" else .7))
	var bits: Array = [icon]
	if r.kind != "gear":
		bits.append(Kit.label(Kit.commas(int(r.get("n", 1))), 28, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER))
	var v := Kit.vbox(2, bits)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var p := Kit.panel(v, Kit.box(Color("1d1648"), Color(tier.color, .6), 24, 2, 8))
	p.custom_minimum_size = Vector2(CARD, CARD + 30)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## The rays sit behind the chest wherever the layout put it.
func _place_rays() -> void:
	var at := _art.get_global_rect().get_center() - get_global_rect().position
	_rays.size = Vector2(900, 900)
	_rays.pivot_offset = _rays.size / 2.0
	_rays.position = at - _rays.size / 2.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _art != null and is_inside_tree():
		_place_rays.call_deferred()


func _arrive() -> void:
	await get_tree().process_frame
	_place_rays()
	if Motion.calm():
		_open_now()
		return
	_art.pivot_offset = _art.size / 2.0
	_art.scale = Vector2(.4, .4)
	_art.modulate.a = 0.0
	_tw = create_tween()
	_tw.tween_property(_art, "modulate:a", 1.0, .15)
	_tw.parallel().tween_property(_art, "scale", Vector2(1.08, .92), .28).set_ease(Tween.EASE_OUT)
	_tw.tween_property(_art, "scale", Vector2.ONE, .3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tw.parallel().tween_property(_rays, "modulate:a", .35, .4)
	_tw.parallel().tween_property(_hint, "modulate:a", 1.0, .3)
	_tw.tween_callback(_wait)
	_sound("clunk", -4.0, .8)


## Until it's tapped the chest gives a little hop and wiggle now and then.
func _wait() -> void:
	phase = Phase.WAITING
	_tw = create_tween().set_loops()
	_tw.tween_interval(.9)
	_tw.tween_property(_art, "rotation", .05, .08)
	_tw.tween_property(_art, "rotation", -.05, .1)
	_tw.tween_property(_art, "rotation", 0.0, .08)
	var spin := _rays.create_tween().set_loops()
	spin.tween_property(_rays, "rotation", TAU, 24.0).from(0.0)


func _gui_input(event: InputEvent) -> void:
	if not ((event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed):
		return
	match phase:
		Phase.WAITING:
			_open()
		Phase.ARRIVING, Phase.OPENING:
			_open_now()
	accept_event()


## Three shakes, each harder, then the lid flies off and the rewards spill out.
func _open() -> void:
	phase = Phase.OPENING
	_kill()
	_art.rotation = 0.0
	_hint.modulate.a = 0.0
	_tw = create_tween()
	for i in 3:
		var a := .05 + .035 * i
		_tw.tween_callback(_sound.bind("clunk", -6.0 + 2.0 * i, 1.0 + .15 * i))
		_tw.tween_property(_art, "rotation", a, .05)
		_tw.tween_property(_art, "rotation", -a, .08)
		_tw.tween_property(_art, "rotation", 0.0, .05)
		_tw.parallel().tween_property(_art, "scale", Vector2(1.0 + .04 * (i + 1), 1.0 - .04 * (i + 1)), .05)
		_tw.tween_property(_art, "scale", Vector2.ONE, .1)
		_tw.tween_interval(.18 - .04 * i)
	_tw.tween_callback(_burst)


func _burst() -> void:
	_sound("summon_pop", 0.0, .9)
	var lid: TextureRect = _art.lid
	_tw = create_tween()
	_tw.tween_property(lid, "rotation", -1.35, .32).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tw.parallel().tween_property(lid, "position", Vector2(-_art.size.x * .28, -_art.size.y * .42), .32).set_ease(Tween.EASE_OUT)
	_tw.parallel().tween_property(lid, "modulate:a", 0.0, .3).set_delay(.12)
	_tw.parallel().tween_property(_flash, "color:a", .85, .06)
	_tw.parallel().tween_property(_rays, "modulate:a", 1.0, .2)
	_tw.parallel().tween_property(_rays, "scale", Vector2(1.25, 1.25), .3).from(Vector2(.6, .6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tw.tween_property(_flash, "color:a", 0.0, .35)
	_tw.tween_callback(_spill)


## Each reward arcs from the open chest into its card, one after another.
func _spill() -> void:
	var from := _art.get_global_rect().get_center() - Vector2(0, _art.size.y * .1)
	for i in _cards.size():
		var card: Control = _cards[i]
		var r: Dictionary = rewards[i]
		var t := get_tree().create_timer(.16 * i)
		t.timeout.connect(func() -> void:
			if phase != Phase.OPENING or not is_instance_valid(card):
				return
			Motion.fly(self, func(): return _flyer(r), from, card.get_global_rect().get_center(), 1, func(_k: int) -> void:
				if phase != Phase.OPENING:
					return
				Motion.pop(card, .3, .32)
				_sound("twinkle", -6.0, 1.0 + .08 * i)
				if i == _cards.size() - 1:
					_show_collect()))


func _flyer(r: Dictionary) -> Control:
	var icon: Control = PassScreen.reward_icon(shell, r, 72.0)
	icon.custom_minimum_size = Vector2(72, 72)
	return icon


func _show_collect() -> void:
	phase = Phase.OPEN
	_collect.visible = true
	Motion.pop(_collect, .5, .3)


## Skip straight to the open chest with every reward out.
func _open_now() -> void:
	_kill()
	phase = Phase.OPEN
	_art.rotation = 0.0
	_art.scale = Vector2.ONE
	_art.modulate.a = 1.0
	_art.lid.visible = false
	_hint.modulate.a = 0.0
	_flash.color.a = 0.0
	_rays.modulate.a = 1.0
	for c in _cards:
		c.modulate.a = 1.0
		c.scale = Vector2.ONE
	_collect.visible = true
	_collect.modulate.a = 1.0
	_collect.scale = Vector2.ONE


func _kill() -> void:
	if _tw != null and _tw.is_valid():
		_tw.kill()


func _on_collect() -> void:
	if shell == null:
		return
	var got := BounceChest.open(shell.profile, chest)
	print("UI_BOUNCE_CHEST_COLLECT day=%d n=%d" % [int(chest.day), got.size()])
	_sound("coins")
	shell.reward_from(_art)
	shell.close_overlay()
	shell.refresh()


func _sound(id: String, db := 0.0, pitch := 1.0) -> void:
	if shell != null and shell.sfx != null:
		shell.sfx.play(id, db, pitch)


## Soft light rays in the chest's colour, drawn once; the node turns.
class _Rays extends Control:
	var color := Color.WHITE

	func _draw() -> void:
		var c := size / 2.0
		var r := size.x / 2.0
		for i in 12:
			var a := TAU * i / 12.0
			var w := .11
			var pts := PackedVector2Array([c, c + Vector2.from_angle(a - w) * r, c + Vector2.from_angle(a + w) * r])
			draw_colored_polygon(pts, Color(color, .16))
		for k in 4:
			draw_circle(c, r * (.32 - .07 * k), Color(color, .07 + .05 * k))
