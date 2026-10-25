## Fusion Lab: pick a ready critter from the jars on the shelf, see what
## improves, press Fuse. The three copies stand on the painted chamber's pads,
## spiral into its core, flash, and the next tier pops out.
## The paintings come from tools/event_art/scenes/fuse_*.mjs (game/ui/fuse_art).
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const Analytics := preload("res://game/online/analytics.gd")
const A11y := preload("res://game/a11y.gd")
const AbilityText := preload("res://game/ui/ability_text.gd")
const UpgradePopup := preload("res://game/ui/upgrade_popup.gd")
const LivingArt := preload("res://game/bounce_run/living_art.gd")

const ART := "res://game/ui/fuse_art/%s.png"
const LAB := Color("5ce1ff")
const STAGE := Color("8f7bff")
const BAND_H := 200.0
## The chamber painting's size and where its pads and core sit
## (fuse_chamber.mjs PADS and CORE): x, y, pad scale.
const CHAMBER := Vector2(720, 680)
const PADS := [Vector3(360, 462, .82), Vector3(184, 586, 1.0), Vector3(536, 586, 1.0)]
const CORE := Vector2(360, 532)
## How much of the painting's faded floor hides under the result pill.
const FLOOR_CUT := 30.0
const SLOT := 112.0
const JAR := Vector2(150, 200) ## A jar picture (180x240 art) as drawn.
const SHELF_H := 232.0


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var ready := sorted(p.ready_to_fuse())
	var sel: Dictionary = {}
	var at := find(ready, params.get("id", ""), params.get("tier", 0))
	if at >= 0:
		sel = ready[at]
	elif not ready.is_empty():
		sel = ready[0]

	var root := Kit.vbox(16)
	var shelf := _shelf(shell, ready, sel, params)
	root.add_child(shelf.door)

	var lab := _lab(sel, 280.0)
	lab.set_meta("ready", ready)
	if shelf.scroll != null:
		lab.set_meta("scroll", shelf.scroll)
	var stage := Kit.vbox(0, [lab])
	if not sel.is_empty():
		stage.add_child(_result(shell, sel))
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var stage_door := _door(stage, STAGE)
	# The stage takes the rest of the screen: a tall phone sees more of the lab.
	stage_door.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(stage_door)

	if not sel.is_empty():
		var btn := Kit.button("Fuse", func(): pass, "go", 34, 96)
		btn.pressed.connect(func(): _do_fuse(shell, lab, btn, sel))
		shell.mark("fuse", btn)
		shell.pin(btn)
	return root


## A painted door like the Play tab's: dark tint of its accent, clipped corners.
static func _door(content: Control, accent: Color) -> Control:
	var d := Kit.panel(content, Kit.box(accent.darkened(.88), accent.darkened(.45), 30, 2, 0))
	d.clip_contents = true
	return d


## The top door: the lab wall band with the title on it, and the ready
## critters floating in specimen jars (tinted by rarity) on a shelf.
static func _shelf(shell, ready: Array, sel: Dictionary, params: Dictionary) -> Dictionary:
	var band := LivingArt.make("fuse_band", ART % "fuse_band")
	band.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	band.custom_minimum_size.y = BAND_H
	band.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var fade := _fade(LAB.darkened(.88), BAND_H)

	var head: Control = shell.title_row("Fusion Lab", {"back": false, "eyebrow": "3 of a kind → next tier", "eyebrow_color": Color("cfcbe8"), "info_title": "How fusing works", "info_mark": "fuse_info", "info": [
		"3 of a kind → 1 of the next tier, up to T5.",
		"The new copy keeps the highest level of the three, and its level cap goes up.",
		"Its gear stays on."]})
	var title: Label = _find_label(head, "Fusion Lab")
	if title:
		title.add_theme_color_override("font_color", LAB)

	var shelf := Control.new()
	shelf.custom_minimum_size.y = SHELF_H
	shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plank := Panel.new()
	var pst := Kit.box(Color("241e62"), Color("7a70d0"), 0, 0, 0)
	pst.border_width_top = 2
	pst.shadow_color = Color(0, 0, 0, .5)
	pst.shadow_size = 10
	pst.shadow_offset = Vector2(0, 6)
	plank.add_theme_stylebox_override("panel", pst)
	plank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plank.set_anchors_preset(Control.PRESET_TOP_WIDE)
	plank.offset_left = -24
	plank.offset_right = 24
	plank.offset_top = JAR.y * .64
	plank.offset_bottom = JAR.y * .64 + 22
	shelf.add_child(plank)

	var scroll: ScrollContainer = null
	if ready.is_empty():
		var none := Kit.label("Nothing to fuse. Get 3 of a kind.", 23, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
		none.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		none.offset_top = JAR.y * .64 - 50
		shelf.add_child(none)
	else:
		scroll = ScrollContainer.new()
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var row := Kit.hbox(6, [], BoxContainer.ALIGNMENT_CENTER)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sel_jar: Control = null
		for s in ready:
			var jar := _jar(s, s == sel, func(): shell.refresh_with({"id": s.id, "tier": s.tier, "x": scroll.scroll_horizontal}))
			if s == sel:
				sel_jar = jar
			shell.mark("ready_%s_%d" % [s.id, s.tier], jar)
			row.add_child(jar)
		scroll.add_child(row)
		shelf.add_child(scroll)
		# Keep your place in a long list: same scroll as before, selected jar in view.
		scroll.ready.connect(func(): _restore_x(scroll, int(params.get("x", 0)), sel_jar))

	var body := Kit.vbox(4, [head, shelf])
	var pad := MarginContainer.new()
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, 20)
	pad.add_theme_constant_override("margin_top", 14)
	pad.add_theme_constant_override("margin_bottom", 8)
	pad.add_child(body)
	var stack := Control.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in [band, fade]:
		stack.add_child(c)
		c.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		c.offset_bottom = BAND_H
	var door := _door(stack, LAB)
	door.add_child(pad)
	# The band sits behind the title and the jars' lids; the shelf hangs below it.
	return {"door": door, "scroll": scroll}


## A gradient from clear to `col` over the bottom of a band of height `h`.
static func _fade(col: Color, h: float) -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, .5, 1.0])
	g.colors = PackedColorArray([Color(col, 0), Color(col, 0), col])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	var t := TextureRect.new()
	t.texture = gt
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.custom_minimum_size.y = h
	return t


static func _find_label(n: Node, text: String) -> Label:
	if n is Label and n.text == text:
		return n
	for c in n.get_children():
		var l := _find_label(c, text)
		if l:
			return l
	return null


## One ready stack: its critter and tier stars floating in a jar tinted by its
## rarity, the count on the jar's base and its name under it. The picked
## jar glows green.
static func _jar(s: Dictionary, on: bool, pick: Callable) -> Button:
	var c := Roster.get_critter(s.id)
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "focus", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.custom_minimum_size = Vector2(JAR.x, SHELF_H)
	b.pressed.connect(pick)
	var k := JAR.x / 180.0
	if on:
		var glow := Panel.new()
		var gs := Kit.box(Color(Kit.GOOD, .12), Kit.GOOD, 30, 3, 0)
		gs.shadow_color = Color(Kit.GOOD, .45)
		gs.shadow_size = 14
		glow.add_theme_stylebox_override("panel", gs)
		glow.position = Vector2(24, 36) * k
		glow.size = Vector2(132, 164) * k
		b.add_child(glow)
	var art := TextureRect.new()
	art.texture = load(ART % ("jar_" + c.rarity))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.size = JAR
	b.add_child(art)
	var icon := CritterIcon.make(s.id, s.tier, 80)
	icon.position = Vector2(JAR.x / 2.0 - 40, 112 * k - 40)
	b.add_child(icon)
	var n := Kit.label("x%d" % s.count, 18, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	n.position = Vector2(0, 207 * k - 13)
	n.size = Vector2(JAR.x, 26)
	b.add_child(n)
	var stars := _center(Glyph.make("stars", 16, Color("ffd36b"), s.tier))
	stars.position = Vector2(0, 168 * k - 10)
	stars.size = Vector2(JAR.x, 20)
	b.add_child(stars)
	var tag := Kit.label(c.name, 18, Kit.GOOD if on else Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	tag.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tag.clip_text = true
	tag.position = Vector2(-4, JAR.y + 4)
	tag.size = Vector2(JAR.x + 8, 26)
	b.add_child(tag)
	for ch in b.get_children():
		if ch is Control and ch != icon:
			ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## The stage: the painted chamber (cropped to its dais) with the three copies
## standing on its pads.
static func _lab(sel: Dictionary, h: float) -> Control:
	var lab := Control.new()
	lab.custom_minimum_size = Vector2(0, h)
	lab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.clip_contents = true
	var art := LivingArt.make("fuse_chamber", ART % "fuse_chamber")
	lab.add_child(art)
	lab.set_meta("art", art)
	var slots: Array = []
	for k in 3:
		var slot: Control
		var side: float = SLOT * PADS[k].z
		if sel.is_empty():
			slot = Control.new()
		else:
			slot = CritterIcon.make(sel.id, sel.tier, side)
		slot.size = Vector2(side, side)
		slot.set_meta("pad", k)
		lab.add_child(slot)
		slots.append(slot)
	lab.set_meta("slots", slots)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.add_child(flash)
	lab.set_meta("flash", flash)
	lab.resized.connect(func(): _place_slots(lab))
	return lab


## The painting's scale and top-left corner inside a lab of `sz`: full width
## (or taller than the lab on a very tall phone, cropping the sides), its
## faded floor tucked under the result pill.
static func _frame(sz: Vector2) -> Rect2:
	var k := maxf(sz.x / CHAMBER.x, (sz.y + FLOOR_CUT) / CHAMBER.y)
	return Rect2((sz.x - CHAMBER.x * k) / 2.0, sz.y + FLOOR_CUT - CHAMBER.y * k, k, k)


## A point of the painting in the lab's space.
static func _at(f: Rect2, p: Vector2) -> Vector2:
	return f.position + p * f.size.x


## Where the three copies meet, in the lab's space.
## Sparks pulled in from all round into the core during the build-up.
static func _sparks(lab: Control, centre: Vector2, col: Color) -> void:
	for k in 12:
		var a := TAU * k / 12.0 + randf() * .4
		var from := centre + Vector2.from_angle(a) * randf_range(150.0, 220.0)
		var sp := Panel.new()
		sp.add_theme_stylebox_override("panel", Kit.box(col.lerp(Color.WHITE, .6), Color(0, 0, 0, 0), 999, 0, 0))
		sp.size = Vector2(9, 9)
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sp.position = from - sp.size / 2.0
		lab.add_child(sp)
		var tw := sp.create_tween()
		tw.tween_interval(.025 * k)
		tw.tween_property(sp, "position", centre - sp.size / 2.0, .3).set_ease(Tween.EASE_IN)
		tw.tween_callback(sp.queue_free)


## A ring of the rarity colour bursting out of the core as the new tier lands.
static func _ring(lab: Control, centre: Vector2, col: Color) -> void:
	if A11y.reduced_motion:
		return
	var ring := Panel.new()
	ring.add_theme_stylebox_override("panel", Kit.box(Color(0, 0, 0, 0), col.lerp(Color.WHITE, .3), 999, 6, 0))
	ring.size = Vector2(120, 120)
	ring.position = centre - ring.size / 2.0
	ring.pivot_offset = ring.size / 2.0
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.add_child(ring)
	var tw := ring.create_tween().set_parallel()
	tw.tween_property(ring, "scale", Vector2(3.4, 3.4), .6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(ring, "modulate:a", 0.0, .6)
	tw.chain().tween_callback(ring.queue_free)


static func core(lab: Control) -> Vector2:
	return _at(_frame(lab.size), CORE)


static func _place_slots(lab: Control) -> void:
	var f := _frame(lab.size)
	var art: Control = lab.get_meta("art")
	art.position = f.position
	art.size = CHAMBER * f.size.x
	if lab.get_meta("fusing", false):
		return
	# The copies grow with the painting, so a tall phone's bigger lab isn't empty.
	var grow := clampf(f.size.x / .92, 1.0, 1.4)
	for s in lab.get_meta("slots"):
		var pad: Vector3 = PADS[s.get_meta("pad")]
		s.pivot_offset = s.size / 2.0
		s.scale = Vector2.ONE * grow
		# Feet on the pad: the icon's bottom sits a little below the pad's centre.
		s.position = _at(f, Vector2(pad.x, pad.y)) - Vector2(0, s.size.y * grow * .36) - s.size / 2.0


## What this fuse gives: name and tier, power before → after and the new
## ability line, with the rest behind the "i".
static func _result(shell, sel: Dictionary) -> Control:
	var c := Roster.get_critter(sel.id)
	var pv: Dictionary = shell.profile.fuse_preview(sel.id, sel.tier)
	var lines := ["Max level %d → %d" % [pv.cap_before, pv.cap_after]]
	if pv.level > 1:
		lines.append("Keeps Lv %d" % pv.level)
	lines.append("T%d adds: %s" % [pv.tier, AbilityText.change(sel.id, pv.tier, pv.level)])
	lines.append(AbilityText.EVERY_TIER)
	var more: Control = shell.info_button("%s T%d" % [c.name, pv.tier], lines, "fuse_result_info")
	var top := Kit.hbox(8, [Kit.label("%s T%d" % [c.name, pv.tier], 26), Kit.glyph("stars", 22, Color("ffd36b"), pv.tier)], BoxContainer.ALIGNMENT_CENTER)
	var power := Kit.hbox(6, [Kit.glyph("power", 20, Kit.WARN), Kit.label("%s →" % Kit.commas(pv.power_before), 21, Kit.MUTED), Kit.label(Kit.commas(pv.power_after), 21, Kit.GOOD)], BoxContainer.ALIGNMENT_CENTER)
	var gain := Kit.label(AbilityText.change(sel.id, pv.tier, pv.level), 21, Kit.GOOD, HORIZONTAL_ALIGNMENT_CENTER, true)
	var info := Kit.vbox(2, [top, power, gain])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pill := Kit.panel(Kit.hbox(8, [info, more], BoxContainer.ALIGNMENT_CENTER), Kit.box(Color(Kit.BG, .88), Color(LAB, .45), 24, 2, 12))
	var pad := MarginContainer.new()
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, 16)
	pad.add_theme_constant_override("margin_top", -26)
	pad.add_theme_constant_override("margin_bottom", 14)
	pad.add_child(pill)
	return pad


static func _do_fuse(shell, lab: Control, btn: Button, sel: Dictionary) -> void:
	btn.disabled = true
	lab.set_meta("fusing", true)
	var centre := core(lab)
	var rarity: Color = Roster.RARITY_COLORS.get(Roster.get_critter(sel.id).rarity, LAB)
	var flash: ColorRect = lab.get_meta("flash")
	var tw := lab.create_tween().set_parallel(true)
	if not A11y.reduced_motion:
		# The build-up: the chamber glows in the critter's rarity colour and the
		# copies tremble while sparks are pulled into the core.
		if shell.sfx != null:
			shell.sfx.play("summon_charge", -4.0)
		flash.color = Color(rarity, 0.0)
		tw.tween_property(flash, "color:a", .28, .4).set_ease(Tween.EASE_IN)
		for s in lab.get_meta("slots"):
			var shake := lab.create_tween()
			for k in 6:
				shake.tween_property(s, "rotation", .09 if k % 2 == 0 else -.09, .066)
		_sparks(lab, centre, rarity)
		tw.chain()
	for s in lab.get_meta("slots"):
		tw.tween_property(s, "position", centre - s.size / 2.0, .6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_property(s, "rotation", TAU, .6).set_ease(Tween.EASE_IN)
		tw.tween_property(s, "scale", s.scale * .5, .6).set_ease(Tween.EASE_IN)
	var pv: Dictionary = shell.profile.fuse_preview(sel.id, sel.tier)
	tw.chain().tween_callback(func():
		var result: Dictionary = shell.profile.fuse(sel.id, sel.tier)
		shell.glow.record("fuse")
		for s in lab.get_meta("slots"):
			s.visible = false
		flash.color = Color(rarity.lerp(Color.WHITE, .55), .95)
		lab.create_tween().tween_property(flash, "color:a", 0.0, .55)
		_ring(lab, centre, rarity)
		# Just the new critter pops out over the painting; its power counts up
		# in the popup that follows, where it reads clearly.
		var big := 150 if lab.size.y > 340.0 else 110
		var out := CritterIcon.make(sel.id, result.tier, big, true)
		lab.add_child(out)
		lab.move_child(out, lab.get_child_count() - 2)
		out.position = Vector2(centre.x, lab.size.y / 2.0) - out.size / 2.0
		out.pivot_offset = out.size / 2.0
		out.scale = Vector2(.2, .2)
		lab.create_tween().tween_property(out, "scale", Vector2.ONE, .45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		print("UI_FUSED %s T%d" % [sel.id, result.tier])
		Analytics.track("fuse", {"critter": sel.id, "tier": result.tier})
		btn.text = "CONTINUE"
		btn.disabled = false
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)
		var old: Array = lab.get_meta("ready", [])
		var go_on := func():
			var sc: ScrollContainer = lab.get_meta("scroll", null)
			var next := pick_after_fuse(old, sorted(shell.profile.ready_to_fuse()), sel)
			next["x"] = sc.scroll_horizontal if is_instance_valid(sc) else 0
			shell.refresh_with(next)
		btn.pressed.connect(go_on)
		# Then what changed, once the new critter has popped out.
		lab.get_tree().create_timer(.3 if A11y.reduced_motion else 1.1).timeout.connect(func():
			if is_instance_valid(lab) and lab.is_inside_tree():
				UpgradePopup.critter(shell, pv, go_on)))


## Rarest first, then the highest tier (a fuse to T3 before the same critter's fuse to T2), then by name.
static func sorted(ready: Array) -> Array:
	var out := ready.duplicate()
	out.sort_custom(func(a, b):
		var ra := Roster.RARITIES.find(Roster.get_critter(a.id).rarity)
		var rb := Roster.RARITIES.find(Roster.get_critter(b.id).rarity)
		if ra != rb:
			return ra > rb
		if a.tier != b.tier:
			return a.tier > b.tier
		return Roster.get_critter(a.id).name < Roster.get_critter(b.id).name)
	return out


## Index of the id/tier stack in a ready list, or -1.
static func find(ready: Array, id: String, tier: int) -> int:
	for i in ready.size():
		if ready[i].id == id and ready[i].tier == tier:
			return i
	return -1


## Which stack to select after fusing `sel`: the same one while it still has
## 3+ copies, else the one that came after it in the list, else the one now at
## its old place (the end of the list if it was last).
static func pick_after_fuse(old: Array, now: Array, sel: Dictionary) -> Dictionary:
	if now.is_empty():
		return {}
	if find(now, sel.id, sel.tier) >= 0:
		return {"id": sel.id, "tier": sel.tier}
	var i := find(old, sel.id, sel.tier)
	for j in range(i + 1, old.size()):
		var k := find(now, old[j].id, old[j].tier)
		if k >= 0:
			return {"id": now[k].id, "tier": now[k].tier}
	var s: Dictionary = now[clampi(i, 0, now.size() - 1)]
	return {"id": s.id, "tier": s.tier}


static func _restore_x(scroll: ScrollContainer, at: int, card: Control) -> void:
	await scroll.get_tree().process_frame
	await scroll.get_tree().process_frame
	if not is_instance_valid(scroll):
		return
	scroll.scroll_horizontal = at
	if is_instance_valid(card):
		scroll.ensure_control_visible(card)


static func _center(c: Control) -> Control:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc
