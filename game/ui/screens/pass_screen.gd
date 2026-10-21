## The Glow Pass (design/monetisation.md §4): season progress, today's
## bounties and the weekly chest, then all 50 levels with the free and premium
## rewards side by side. Levels come from play only and are never sold.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const A11y := preload("res://game/a11y.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Catalog := preload("res://game/glow/catalog.gd")
const GlowPass := preload("res://game/glow/glow_pass.gd")
const CosmeticIcon := preload("res://game/glow/cosmetic_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const LiveOps := preload("res://game/liveops.gd")
const ShopScreen := preload("res://game/ui/screens/shop_screen.gd")
const BagScreen := preload("res://game/ui/screens/bag_screen.gd")
const Gear := preload("res://sim/gear.gd")

const GLOW := Color("ffd36b")
const PREMIUM := Color("b366ff")


static func build(shell, _params: Dictionary) -> Control:
	var glow = shell.glow
	var t := LiveOps.now()
	var root := Kit.vbox(24)
	var back: Control = shell.back_button("pass_back")
	var how: Control = shell.info_button("How the Glow Pass works", [
		"Pass XP comes from play: fights give 10-30 XP, solving the Daily Trick Shot gives %d, and bounties give more." % GlowPass.TRICK_XP,
		"Finish %d bounties in a week to open the weekly chest (+%s XP)." % [GlowPass.CHEST_AFTER, Kit.commas(GlowPass.CHEST_XP)],
		"The free track has every power reward. Premium adds looks and Glow Gems only, never power. Buying later unlocks everything you've already reached.",
		"Past level 50: a bonus box every %s XP (Coins and a few gems), up to %d." % [Kit.commas(GlowPass.BONUS_XP), GlowPass.BONUS_MAX],
	], "pass_info")
	root.add_child(Kit.hbox(14, [back, Kit.label("Glow Pass", 40), Kit.spacer(), how], BoxContainer.ALIGNMENT_CENTER))
	var season: Dictionary = glow.season(t)
	if season.is_empty():
		root.add_child(Kit.panel(Kit.label("The next season's pass opens soon. Everything you earned stays yours.", 26, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
			Kit.box(Kit.PANEL, Kit.LINE, 36, 2, 28)))
		return root
	var ps: Dictionary = glow.pass_state(t)
	var level: int = glow.pass_level(t)
	var prog := GlowPass.progress(int(ps.xp))

	# Header: season, level and XP.
	var lvl := Kit.panel(Kit.label(str(level), 40, Kit.BG, HORIZONTAL_ALIGNMENT_CENTER), Kit.box(GLOW, Color("fff2b0"), 999, 3, 0))
	lvl.custom_minimum_size = Vector2(92, 92)
	(lvl.get_child(0) as Label).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var bar_text := ("Bonus box: %d / %d XP" if level >= GlowPass.LEVELS else "%d / %d XP to level %d") % ([prog.x, prog.y] if level >= GlowPass.LEVELS else [prog.x, prog.y, level + 1])
	var info := Kit.vbox(6, [Kit.label("%s · week %d of %d" % [season.name, season.week, season.weeks], 24, GLOW),
		Kit.bar(float(prog.x) / prog.y, GLOW, 22), Kit.label(bar_text, 22, Kit.MUTED),
		Kit.label("Ends in " + LiveOps.countdown(t, season.ends), 20, Kit.MUTED)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if GlowPass.xp_multiplier(season, t) > 1:
		info.add_child(Kit.label("Finale weekend: double pass XP!", 22, Kit.GOOD))
	root.add_child(Kit.panel(Kit.hbox(18, [lvl, info], BoxContainer.ALIGNMENT_CENTER), Kit.box(Color("221a3a"), Color("6b5520"), 40, 2, 26)))

	# Premium unlock.
	if not ps.premium:
		var store = glow.store
		var buy := Kit.button("Unlock · " + store.price("glow_pass"), func(): store.purchase("glow_pass"), "primary", 28, 88)
		shell.mark("pass_buy", buy)
		var with_gems := Kit.cost_button("", Catalog.PASS_GEMS, "gem", func():
			var err: String = glow.buy_pass_with_gems(t)
			if err == "Not enough Glow Gems.":
				ShopScreen.gem_sheet(shell)
			else:
				shell.toast(err if err != "" else "Glow Pass unlocked! Your premium rewards are ready to claim.")
				shell.refresh(), "ghost", 26, 88)
		shell.mark("pass_gems", with_gems)
		var n_cos := 0
		var n_gems := 0
		for l in range(1, GlowPass.LEVELS + 1):
			var r := GlowPass.premium_reward(l)
			if r.get("kind") == "cosmetic":
				n_cos += 1
			elif r.get("kind") == "gems":
				n_gems += int(r.n)
		root.add_child(Kit.panel(Kit.vbox(12, [Kit.caption("Premium track", PREMIUM),
			Kit.hbox(8, [Kit.label("%d looks and %s" % [n_cos, Kit.commas(n_gems)], 24), Kit.glyph("gem", 26, Kit.FG), Kit.label("this season", 24)], BoxContainer.ALIGNMENT_CENTER),
			Kit.hbox(12, [buy, with_gems])]), Kit.box(Color("1f1440"), Color(PREMIUM, .6), 36, 2, 24)))

	# Today's bounties and the weekly chest.
	var bv := Kit.vbox(12, [Kit.hbox(0, [Kit.caption("Today's bounties"), Kit.spacer(),
		Kit.label("New in " + LiveOps.countdown(t, LiveOps.day_start(t) + LiveOps.DAY), 20, Kit.MUTED)])])
	for b in glow.bounties(t):
		var txt := Kit.vbox(4, [Kit.label(b.text, 24, Kit.MUTED if b.done else Kit.FG), Kit.bar(float(b.progress) / b.goal, Kit.GOOD if b.done else Kit.ACCENT, 14)])
		txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var right: Control = Kit.chip("Done", Kit.GOOD) if b.done else Kit.label("%s/%s · +%d XP" % [Kit.commas(b.progress), Kit.commas(b.goal), b.xp], 20, Kit.MUTED)
		bv.add_child(Kit.hbox(14, [txt, right], BoxContainer.ALIGNMENT_CENTER))
	var w: Dictionary = glow.week_state(t)
	var chest_text := Kit.label("Weekly chest: %d / %d bounties · +%s XP" % [mini(int(w.count), GlowPass.CHEST_AFTER), GlowPass.CHEST_AFTER, Kit.commas(GlowPass.CHEST_XP)], 22,
		Kit.GOOD if glow.chest_ready(t) else Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	chest_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var chest_row := Kit.hbox(12, [chest_text], BoxContainer.ALIGNMENT_CENTER)
	if glow.chest_ready(t):
		var open := Kit.button("Open", func(): glow.open_chest(t); shell.toast("+%s pass XP from the weekly chest!" % Kit.commas(GlowPass.CHEST_XP)); shell.refresh(), "go", 24, 70)
		open.custom_minimum_size.x = 150
		open.size_flags_horizontal = Control.SIZE_SHRINK_END
		shell.mark("open_chest", open)
		chest_row.add_child(open)
	elif w.chest:
		chest_row.add_child(Kit.chip("Opened", Kit.GOOD))
	bv.add_child(chest_row)
	root.add_child(Kit.panel(bv, Kit.box(Kit.PANEL, Kit.LINE, 36, 2, 24)))

	# Claim all.
	var n: int = glow.claimable_count(t)
	if n > 0:
		var all := Kit.button("Claim all (%d)" % n, func():
			var got: Array = glow.claim_all(t)
			shell.toast("Claimed %d reward%s!" % [got.size(), "" if got.size() == 1 else "s"])
			shell.refresh(), "go", 30, 92)
		shell.mark("claim_all", all)
		root.add_child(all)

	# The levels.
	var head := Kit.hbox(12, [_head("Lv", 70), _head("Free", 0), _head("Premium", 0, PREMIUM)])
	var list := Kit.vbox(10, [head])
	for l in range(1, GlowPass.LEVELS + 1):
		list.add_child(_level_row(shell, l, level, t))
	if level >= GlowPass.LEVELS:
		list.add_child(Kit.label("Bonus boxes opened: %d of %d." % [ps.boxes, GlowPass.BONUS_MAX], 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	root.add_child(list)
	return root


static func _head(text: String, width: float, color := Kit.MUTED) -> Control:
	var l := Kit.caption(text, color)
	if width > 0:
		l.custom_minimum_size.x = width
	else:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func _level_row(shell, l: int, level: int, t: int) -> Control:
	var reached := l <= level
	var num := Kit.panel(Kit.label(str(l), 26, Kit.BG if reached else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.box(GLOW if reached else Kit.PANEL2, Color(0, 0, 0, 0), 999, 0, 0))
	num.custom_minimum_size = Vector2(70, 70)
	(num.get_child(0) as Label).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# The track's spine: a bar through the level badges, lit up to your level.
	var spine := Control.new()
	spine.custom_minimum_size = Vector2(70, 70)
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := ColorRect.new()
	bar.color = GLOW if l <= level else Kit.PANEL2
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.anchor_left = .5
	bar.anchor_right = .5
	bar.anchor_bottom = 1.0
	bar.offset_left = -4
	bar.offset_right = 4
	bar.offset_top = -10.0 if l > 1 else 35.0 # Up through the gap to the row above.
	bar.offset_bottom = 0.0 if l < GlowPass.LEVELS else -35.0
	spine.add_child(bar)
	var mid := CenterContainer.new()
	mid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(num)
	spine.add_child(mid)
	return Kit.hbox(12, [spine, _cell(shell, l, "free", t), _cell(shell, l, "premium", t)])


static func _cell(shell, l: int, track: String, t: int) -> Control:
	var glow = shell.glow
	var r: Dictionary = glow.reward(l, track, t)
	var accent := GLOW if track == "free" else PREMIUM
	if r.is_empty():
		var empty := Control.new()
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return empty
	var state := ""
	if glow.claimed(l, track, t):
		state = "Claimed"
	elif glow.can_claim(l, track, t):
		state = "Claim"
	elif track == "premium" and not glow.pass_state(t).premium:
		state = "locked"
	var icon := reward_icon(shell, r, 64)
	var text := Kit.vbox(2, [Kit.label(reward_text(r, true), 22, Kit.FG if state != "Claimed" else Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])
	var badge: Control = null
	if state == "Claim":
		badge = Kit.chip("Claim", Kit.GOOD, 16)
		_pulse_once(badge)
	elif state == "Claimed":
		badge = Kit.chip("Got it", Kit.MUTED, 16)
	elif state == "locked":
		badge = Glyph.make("lock", 22, Kit.MUTED)
	if badge:
		badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		text.add_child(badge)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	var row := Kit.hbox(8, [icon, text], BoxContainer.ALIGNMENT_CENTER)
	# Premium cards wear a gold frame; anything you can claim is green.
	var frame: Color = Color(Glyph.GOLD, .55) if track == "premium" else Kit.LINE
	var border := Kit.GOOD if state == "Claim" else (Color(accent, .35) if l <= glow.pass_level(t) and track == "free" else frame)
	var card := Kit.card_button(row, func():
		if state == "Claim":
			glow.claim(l, track, t)
			shell.toast("Got %s!" % reward_text(r))
			shell.refresh()
		elif r.kind == "cosmetic":
			ShopScreen.item_sheet(shell, r.id)
		elif state == "locked":
			shell.toast("Unlock the Glow Pass to claim premium rewards.")
		elif state == "":
			shell.toast("Reach level %d to claim this." % l), border, Kit.PANEL, 24, 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.modulate = Color(1, 1, 1, .55) if state == "locked" else Color.WHITE
	shell.mark("claim_%s_%d" % [track, l], card)
	return card


## `beside_icon`: the currency's icon is right there, so show just the number.
static func reward_text(r: Dictionary, beside_icon := false) -> String:
	var n := int(r.get("n", 1))
	if beside_icon and r.kind in ["gems", "orbs", "coins", "energy"]:
		return Kit.commas(n)
	match r.kind:
		"cosmetic":
			return Catalog.item(r.id).get("name", r.id)
		"gems":
			return "%d Glow Gems" % n
		"orbs":
			return "%d Summon Egg%s" % [n, "" if n == 1 else "s"]
		"coins":
			return "%s Coins" % Kit.commas(n)
		"energy":
			return "%d Energy" % n
		"xp_chip":
			return "%d XP Chip%s" % [n, "" if n == 1 else "s"]
		"copies":
			return "%s copy" % Roster.get_critter(r.id).name
		"gear":
			return "%d-star %s" % [int(r.tier), Gear.PIECES[r.type].name]
	return r.kind


static func reward_icon(shell, r: Dictionary, side: float) -> Control:
	var g: Control
	match r.kind:
		"cosmetic":
			g = CosmeticIcon.make(r.id, shell.profile.lineup, side)
		"gems":
			g = Glyph.make("gem", side * .7)
		"orbs":
			g = Glyph.make("orb", side * .7)
		"coins":
			g = Glyph.make("coin", side * .7)
		"energy":
			g = Glyph.make("energy", side * .7)
		"copies":
			var CritterIcon = load("res://game/ui/critter_icon.gd")
			g = CritterIcon.make(r.id, 1, side)
		"gear":
			g = Glyph.make(Gear.PIECES[r.type].glyph, side * .7, BagScreen.tier_color(int(r.tier)))
		_:
			g = Glyph.make("bolt", side * .7, Kit.GOOD)
	var cc := CenterContainer.new()
	cc.custom_minimum_size = Vector2(side, side)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(g)
	return cc


## A claim chip swells once when it appears, then sits still (no per-frame cost).
static func _pulse_once(c: Control) -> void:
	if A11y.reduced_motion:
		return
	c.ready.connect(func():
		c.pivot_offset = c.size / 2.0
		var tw := c.create_tween()
		tw.tween_property(c, "scale", Vector2(1.18, 1.18), .25).set_trans(Tween.TRANS_SINE)
		tw.tween_property(c, "scale", Vector2.ONE, .3).set_trans(Tween.TRANS_SINE))
