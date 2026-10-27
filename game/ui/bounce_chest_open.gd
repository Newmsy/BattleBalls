## Opening a Bounce Run chest (meta/bounce_chest.gd), over the whole shell
## (from the Daily board) or over the Bounce Run screen when it opens:
## the painted chest drops in and wobbles, a tap shakes it harder and harder
## until the lid bursts off in a flash of light, then each reward card leaps
## out of the chest one by one, arcs over and lands in its slot with a
## bounce. Collect grants them: coins and orbs fly to the top bar, the rest
## to the Bag. A tap while it shakes bursts it open at once; a tap while the
## cards fly lands them all. Render-only, tweens only.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const Motion := preload("res://game/ui/motion.gd")
const ChestArt := preload("res://game/ui/chest_art.gd")
const BounceChest := preload("res://meta/bounce_chest.gd")
const Dot := preload("res://game/dot.gd")
const PassScreen := preload("res://game/ui/screens/pass_screen.gd")

const CHEST_H := 320.0
const CARD := 112.0 ## Reward card side.

enum Phase { ARRIVING, WAITING, OPENING, SPILLING, OPEN }

const SPILL_GAP := .32 ## Between one card leaving the chest and the next.
const ARC_SECS := .62
const PILLS := {"coins": "coin", "orbs": "orb", "energy": "energy"} ## Reward kind -> its top bar pill.

var shell ## The menus' shell, or null over the Bounce Run screen.
var host ## The Bounce Run screen (game/bounce_run.gd) when there's no shell.
var profile
var sfx
var on_done := Callable() ## Over the Bounce Run screen: called with the rewards once collected.
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
var _flyers := {} ## Card index -> its card in flight.
var _landed := 0


## Shows chest `c` (BounceChest.pending()) on `shell`'s overlay layer.
static func show_on(shell_, c: Dictionary) -> Control:
	var v = load("res://game/ui/bounce_chest_open.gd").new()
	v.shell = shell_
	v.profile = shell_.profile
	v.sfx = shell_.sfx
	v._setup(c)
	shell_.overlay(v, "bounce_chest")
	v._arrive.call_deferred()
	return v


## Shows chest `c` over `layer` of the Bounce Run screen `host_`. Collect
## grants it into `profile_` and calls `done` with the rewards.
static func show_in(host_, layer: Control, c: Dictionary, profile_, sfx_, done: Callable) -> Control:
	var v = load("res://game/ui/bounce_chest_open.gd").new()
	v.host = host_
	v.profile = profile_
	v.sfx = sfx_
	v.on_done = done
	v._setup(c)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(v)
	v._arrive.call_deferred()
	v._reported.call_deferred()
	return v


func _setup(c: Dictionary) -> void:
	chest = c
	rewards = BounceChest.rewards(int(c.tier), int(c.day))
	tier = BounceChest.TIERS[int(c.tier)]
	_build()
	print("UI_BOUNCE_CHEST day=%d tier=%s" % [int(c.day), tier.id])


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
	elif host != null:
		host._mark("bounce_chest_collect", _collect)
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
	if not is_inside_tree():
		return
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
		Phase.ARRIVING, Phase.WAITING:
			_open()
		Phase.OPENING:
			_burst()
		Phase.SPILLING:
			_land_all()
	accept_event()


## Three shakes, each harder, then the lid flies off and the rewards spill out.
func _open() -> void:
	phase = Phase.OPENING
	_kill()
	_art.rotation = 0.0
	_art.scale = Vector2.ONE
	_art.modulate.a = 1.0
	_rays.modulate.a = maxf(_rays.modulate.a, .35)
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
	if phase == Phase.SPILLING or phase == Phase.OPEN:
		return
	phase = Phase.SPILLING
	_kill()
	_art.rotation = 0.0
	_art.scale = Vector2.ONE
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


## Each reward card leaps out of the open chest, one after another: it
## starts small in the chest's mouth, spins up over the chest and drops
## into its slot, which takes it with a bounce and a spray of sparks.
func _spill() -> void:
	var base := get_global_rect().position
	var mouth := _art.get_global_rect().get_center() - Vector2(0, _art.size.y * .15) - base
	for i in _cards.size():
		var card: Control = _cards[i]
		var r: Dictionary = rewards[i]
		var fly := _card(r)
		fly.visible = false
		add_child(fly)
		_flyers[i] = fly
		var land := card.get_global_rect().get_center() - base
		var top := Vector2(lerpf(mouth.x, land.x, .45), minf(mouth.y, land.y) - _art.size.y * .55)
		var spin := (1.0 if land.x >= mouth.x else -1.0) * TAU * .5
		var tw := fly.create_tween()
		tw.tween_interval(SPILL_GAP * i)
		tw.tween_callback(func() -> void:
			fly.visible = true
			fly.size = card.size
			fly.pivot_offset = fly.size / 2.0
			Motion.bump(_art, 1.06, .16, true)
			_sound("clunk", -10.0, 1.4 + .06 * i))
		tw.tween_method(func(t: float) -> void:
			# A quadratic arc: up out of the chest, over, down into the slot.
			var p := mouth.lerp(top, t).lerp(top.lerp(land, t), t)
			fly.position = p - fly.size / 2.0
			fly.scale = Vector2.ONE * lerpf(.2, 1.0, minf(1.0, t * 1.6))
			fly.rotation = spin * (1.0 - t), 0.0, 1.0, ARC_SECS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(_land.bind(i))


## Card `i` lands in its slot (once, whether it flew or was skipped there).
func _land(i: int) -> void:
	var fly: Control = _flyers.get(i)
	if fly == null:
		return
	_flyers.erase(i)
	fly.queue_free()
	var card: Control = _cards[i]
	card.modulate.a = 1.0
	card.scale = Vector2.ONE
	if phase == Phase.SPILLING:
		Motion.pop(card, .75, .3)
		_sparks(card)
		_sound("twinkle", -6.0, 1.0 + .08 * i)
	_landed += 1
	if _landed == _cards.size():
		_show_collect()


## A tap while the cards fly: every one still to come lands now.
func _land_all() -> void:
	for i in _flyers.keys():
		_land(i)


## A little ring of sparks round a card that has just landed, drawn by one
## node that frees itself.
func _sparks(card: Control) -> void:
	var s := _Sparks.new()
	s.color = tier.color
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.size = card.size * 1.8
	s.position = card.get_global_rect().get_center() - get_global_rect().position - s.size / 2.0
	add_child(s)
	var tw := s.create_tween()
	tw.tween_method(func(t: float) -> void:
		s.t = t
		s.queue_redraw(), 0.0, 1.0, .4).set_ease(Tween.EASE_OUT)
	tw.tween_callback(s.queue_free)


## Makes a reward's flying icon without holding on to this view, which is
## gone by the time the icons reach the top bar.
static func _icon_maker(shell_, r: Dictionary) -> Callable:
	return func() -> Control:
		var icon: Control = PassScreen.reward_icon(shell_, r, 72.0)
		icon.custom_minimum_size = Vector2(72, 72)
		return icon


func _show_collect() -> void:
	phase = Phase.OPEN
	_collect.visible = true
	Motion.pop(_collect, .5, .3)
	_reported()


## Tells the shell (and the smoke test) where Collect is now that it shows.
func _reported() -> void:
	if shell != null and shell.is_inside_tree() and shell.has_method("_report"):
		shell._report("bounce_chest")
	elif host != null and host.is_inside_tree():
		host._report("bounce_chest")


## Skip straight to the open chest with every reward out.
func _open_now() -> void:
	_kill()
	for f in _flyers.values():
		f.queue_free()
	_flyers.clear()
	_landed = _cards.size()
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
	if Motion.calm():
		Motion.cascade(_cards) # Reduced motion: the cards fade in in turn.
	_collect.visible = true
	_collect.modulate.a = 1.0
	_collect.scale = Vector2.ONE
	_reported()


func _kill() -> void:
	if _tw != null and _tw.is_valid():
		_tw.kill()


func _on_collect() -> void:
	if profile == null:
		return
	var got := BounceChest.open(profile, chest)
	print("UI_BOUNCE_CHEST_COLLECT day=%d n=%d" % [int(chest.day), got.size()])
	_sound("coins")
	if shell == null:
		_leave(got)
		return
	# Coins and orbs fly into their pills from their own cards, the rest into the Bag.
	for i in _cards.size():
		var r: Dictionary = rewards[i]
		var card: Control = _cards[i]
		if r.kind in PILLS:
			shell.reward_from(card, PILLS[r.kind])
		else:
			shell.fly_to_tab(_icon_maker(shell, r), card.get_global_rect().get_center(), "bag", .08 * i)
	shell.close_overlay()
	shell.refresh()


## Over the Bounce Run screen (no top bar): the rewards are reported (and
## saved) at once, then the cards lift away and the view fades.
func _leave(got: Array) -> void:
	_collect.disabled = true
	if on_done.is_valid():
		on_done.call(got)
	if Motion.calm() or not is_inside_tree():
		queue_free()
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in _cards.size():
		var c: Control = _cards[i]
		var ct := c.create_tween().set_parallel()
		ct.tween_property(c, "position:y", c.position.y - 160.0, .32).set_delay(.04 * i).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		ct.tween_property(c, "modulate:a", 0.0, .26).set_delay(.04 * i + .06)
	var tw := create_tween()
	tw.tween_interval(.2)
	tw.tween_property(self, "modulate:a", 0.0, .22)
	tw.tween_callback(queue_free)


func _sound(id: String, db := 0.0, pitch := 1.0) -> void:
	if sfx != null:
		sfx.play(id, db, pitch)


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
			draw_colored_polygon(pts, Color(color, .1))
		Dot.glow(self, c, r * .34, Color(color, .47), .3)


## The sparks round a landed card: eight dots flying out and fading, `t` 0..1.
class _Sparks extends Control:
	var color := Color.WHITE
	var t := 0.0

	func _draw() -> void:
		var c := size / 2.0
		var r := size.x * (.3 + .2 * t)
		var col := Color(color.lightened(.4), 1.0 - t)
		for i in 8:
			Dot.circle(self, c + Vector2.from_angle(TAU * i / 8.0 + .2) * r, 5.0 * (1.0 - t * .6), col)
