## The Rift Gate (design/dyes-rift-keys.md, project files), off the Adventure
## hub: pick a family, spend a Rift Key and fight three of its critters in a
## row for copies of its critters and Spark Dye drops. The hero is the picked
## family's home painting (game/ui/art/families) with the Glitch tear hanging
## in it (home_art/rift_tear.png); in a run the round's foe stands in front of
## the tear. Rules live in meta/family_rift.gd; this only shows them. Fits one
## phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Painted := preload("res://game/ui/painted.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const BossCard := preload("res://game/ui/boss_card.gd")
const ResultPopup := preload("res://game/ui/result_popup.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Roster := preload("res://game/ui/roster.gd")
const Families := preload("res://sim/families.gd")
const Campaign := preload("res://meta/campaign.gd")
const FamilyRift := preload("res://meta/family_rift.gd")
const Dyes := preload("res://game/glow/dyes.gd")

const RIFT := Color("5ce1ff")
const GLITCH := Color("ff4fb8")
const TEAR := "res://game/ui/home_art/rift_tear.png"


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(16)
	root.add_child(shell.title_row("Rifts", {"eyebrow": "Adventure", "eyebrow_color": RIFT, "info_mark": "rift_info",
		"extra": [Kit.amount("key", p.rift_keys(), 26, Kit.FG, RIFT)], "info": [
		"The Glitch tears rifts into each family's home. A Rift Key opens one: pick a family, then beat three of its critters in a row.",
		"Every win pays copies of that family's critters (wishlisted ones come up twice as often) and Spark Dye drops. The Rift Boss adds a copy that is Rare or better.",
		"Foes are measured against your strongest critter. Bring one whose family has the edge.",
		"Lose and the Rift closes, but you keep what you won. No energy: the key is the cost.",
		"Keys drop from each zone boss's first clear, Spire floors 20 and 40 and the Glow Pass free track. You can hold %d." % p.RIFT_KEY_CAP]}))
	ResultPopup.boss_result(shell, params, _result_row(params.get("xp", {})) if params.has("notice") else null)
	if FamilyRift.in_run(p):
		_run(shell, p, root)
	else:
		_gate(shell, p, root, str(params.get("family", _default_family(p))))
	return root


## The family to show first: your fighter's, else the first family.
static func _default_family(p) -> String:
	var fam := Families.of(Campaign.fighter_for(p))
	return fam if fam != "" else Families.ids()[0]


# --- Picking a family ---------------------------------------------------------

static func _gate(shell, p, root: VBoxContainer, family: String) -> void:
	var drops := Kit.hbox(6, [], BoxContainer.ALIGNMENT_BEGIN)
	var members: Array = FamilyRift.members(family)
	members.sort_custom(func(a, b): return int(p.on_wishlist(a)) > int(p.on_wishlist(b)) or (p.on_wishlist(a) == p.on_wishlist(b) and Roster.RARITIES.find(Roster.get_critter(a).rarity) > Roster.RARITIES.find(Roster.get_critter(b).rarity)))
	for id in members.slice(0, 7):
		drops.add_child(_wish_icon(p, id, 58))
	var name := Kit.hbox(10, [FamilyIcon.make(family, 44), Kit.label("%s Rift" % Families.info(family).name, 34)], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(_hero(family, Kit.vbox(8, [name, drops]), null))

	var fams := Kit.hbox(6, [], BoxContainer.ALIGNMENT_CENTER)
	for f in Families.ids():
		var on: bool = f == family
		var col := FamilyIcon.color(f)
		var b := Kit.card_button(_center(FamilyIcon.make(f, 52)), func(): shell.refresh_with({"family": f}),
			col if on else Kit.LINE, Color(col, .22) if on else Kit.PANEL, 22, 6)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.x = 0
		shell.mark("rift_family_" + f, b)
		fams.add_child(b)
	root.add_child(fams)
	root.add_child(_path(-1))

	var keys: int = p.rift_keys()
	var open := Kit.cost_button("Open Rift", 1, "key", func(): _open(shell, family), "go", 30, 92)
	open.disabled = keys <= 0 or not FamilyRift.is_unlocked(p)
	shell.mark("rift_open", open)
	root.add_child(open)
	if not FamilyRift.is_unlocked(p):
		root.add_child(Kit.label("Beat the Zone 1 boss to open Rifts.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
	elif keys <= 0:
		root.add_child(Kit.label("Rift Keys drop from zone bosses, Spire floors 20 and 40 and the Glow Pass.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))


static func _open(shell, family: String) -> void:
	var r: Dictionary = FamilyRift.open(shell.profile, family, int(Time.get_unix_time_from_system()))
	if r.has("error"):
		shell.toast({"key": "No Rift Keys left.", "locked": "Beat the Zone 1 boss to open Rifts.", "run": "Finish the open Rift first."}.get(r.error, "That Rift won't open."))
		return
	shell.toast("The %s Rift is open!" % Families.info(family).name)
	shell.refresh_with({})


# --- A run ------------------------------------------------------------------

static func _run(shell, p, root: VBoxContainer) -> void:
	var run: Dictionary = p.rift
	var round := int(run.round)
	var family := str(run.family)
	var foe := str(run.foes[round])
	var r: Dictionary = FamilyRift.ROUNDS[round]
	var fp := FamilyRift.foe_power(p, round)
	var boss: bool = r.get("boss", false)
	var face := CritterIcon.make(foe, fp.tier, 210 if boss else 176, true)
	var stand := Kit.vbox(0, [face], )
	stand.alignment = BoxContainer.ALIGNMENT_END
	if boss:
		stand.add_child(Kit.hbox(0, [Kit.chip("Rift Boss", Glyph.GOLD, 20)], BoxContainer.ALIGNMENT_CENTER))
	var title := Kit.hbox(10, [FamilyIcon.make(family, 40), Kit.label("%s Rift" % Families.info(family).name, 30), Kit.spacer(),
		Kit.chip("Round %d of %d" % [round + 1, FamilyRift.ROUNDS.size()], RIFT, 20)], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(_hero(family, title, stand))
	root.add_child(_path(round))

	if not run.copies.is_empty():
		var won := Kit.hbox(6, [Kit.caption("Won so far")], BoxContainer.ALIGNMENT_CENTER)
		for id in run.copies:
			won.add_child(CritterIcon.make(id, 1, 46))
		if not run.dyes.is_empty():
			won.add_child(Kit.amount("dye", run.dyes.size(), 22, Kit.FG, GLITCH))
		root.add_child(won)

	var fighter: String = Campaign.fighter_for(p)
	root.add_child(BossCard.fighter(shell, fighter, "rift", [], 80))
	var v := BossCard.verdict(p.power_of(fighter), fp.rating, "It's")
	var info := Kit.vbox(4, [Kit.label("%s · %s" % [r.name, Roster.get_critter(foe).name], 26), _pay_row(r, 22), Kit.label(v[0], 20, v[1])])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var foe_tag := Kit.vbox(0, [FighterTag.icon(foe, fp.tier, 76), Kit.power(fp.rating, 20, v[1])])
	foe_tag.alignment = BoxContainer.ALIGNMENT_CENTER
	var go := Kit.button("Fight", func(): _fight(shell, round, fighter), "go", 30, 84)
	go.custom_minimum_size.x = 170
	shell.mark("rift_go", go)
	root.add_child(Kit.panel(Kit.hbox(12, [foe_tag, info, go], BoxContainer.ALIGNMENT_CENTER), Kit.box(Kit.PANEL, Color(RIFT, .5), 30, 2, 12)))
	var leave := Kit.button("Leave the Rift", func(): _leave_sheet(shell), "ghost", 22, 64)
	shell.mark("rift_leave", leave)
	root.add_child(leave)


static func _fight(shell, round: int, fighter: String) -> void:
	var cfg: Dictionary = FamilyRift.start(shell.profile, round, fighter, int(Time.get_unix_time_from_system()))
	BossCard.start(shell, cfg, round, fighter, "rift", "This Rift has closed.", "Beat the Zone 1 boss to open Rifts.")


static func _leave_sheet(shell) -> void:
	var p = shell.profile
	var n: int = p.rift.copies.size()
	var stay := Kit.button("Stay", shell.close_overlay, "ghost", 26, 84)
	var go := Kit.button("Leave", func():
		FamilyRift.leave(p)
		shell.close_overlay()
		shell.refresh_with({}), "primary", 26, 84)
	shell.mark("rift_leave_yes", go)
	for b in [stay, go]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.sheet(Kit.vbox(18, [Kit.label("Leave the Rift?", 34),
		Kit.label("It closes for good. You keep the %d cop%s you won." % [n, "y" if n == 1 else "ies"] if n > 0 else "It closes for good, and the key is spent.", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
		Kit.hbox(14, [stay, go])]))


# --- Shared parts ------------------------------------------------------------

## The family's home painting with the tear hanging in it, `top` over its top
## edge and `front` (the foe) standing in front of the tear.
static func _hero(family: String, top: Control, front: Control) -> Control:
	var stage := PanelContainer.new()
	stage.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.custom_minimum_size.y = 380
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(Painted.make("families/" + family, {"focus": Vector2(390, 260), "radius": 30.0, "top_dark": 0.7, "bottom_dark": 0.55}))
	var tear := TextureRect.new()
	tear.texture = load(TEAR)
	tear.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tear.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tear.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tear.modulate = Color(1, 1, 1, .55 if front != null else 1.0)
	var tm := MarginContainer.new()
	tm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for s in ["top", "bottom"]:
		tm.add_theme_constant_override("margin_" + s, 40)
	tm.add_child(tear)
	stage.add_child(tm)
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", Kit.box(Color(0, 0, 0, 0), Color(FamilyIcon.color(family), .6), 30, 3, 0))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(frame)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Foe in front of the tear, or name and drops along the bottom.
	var col := Kit.vbox(0, [top, gap, Kit.hbox(0, [front], BoxContainer.ALIGNMENT_CENTER)] if front != null else [gap, top])
	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 22)
	m.add_child(col)
	stage.add_child(m)
	return stage


## The three rounds as cards: what each pays, the round you're on lit, done ones ticked.
static func _path(current: int) -> Control:
	var row := Kit.hbox(10, [], BoxContainer.ALIGNMENT_CENTER)
	for i in FamilyRift.ROUNDS.size():
		var r: Dictionary = FamilyRift.ROUNDS[i]
		var boss: bool = r.get("boss", false)
		var done := current > i
		var head := Kit.hbox(6, [Kit.glyph("crown", 22, Glyph.GOLD)] if boss else [], BoxContainer.ALIGNMENT_CENTER)
		head.add_child(Kit.label("Done" if done else r.name, 20, Kit.GOOD if done else (Glyph.GOLD if boss else Kit.FG)))
		var cell := Kit.vbox(4, [head, _pay_row(r, 18)])
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		var lit := current == i
		var border: Color = RIFT if lit else (Color(Glyph.GOLD, .6) if boss else Kit.LINE)
		var card := Kit.panel(cell, Kit.box(Color(RIFT, .14) if lit else Kit.PANEL, border, 22, 2, 8))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.modulate = Color(1, 1, 1, .55) if done else Color.WHITE
		row.add_child(card)
	return row


## What a round pays: copies (a critter face) and dye drops, as icons and numbers.
static func _pay_row(r: Dictionary, size: int) -> Control:
	var row := Kit.hbox(8, [Kit.amount("critters", r.copies + r.get("rare", 0), size, Kit.FG, RIFT), Kit.amount("dye", r.dyes, size, Kit.FG, GLITCH)], BoxContainer.ALIGNMENT_CENTER)
	return row


static func _wish_icon(p, id: String, side: float) -> Control:
	var icon := CritterIcon.make(id, 1, side)
	if not p.on_wishlist(id):
		return icon
	var box := Control.new()
	box.custom_minimum_size = Vector2(side, side)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var heart := Glyph.make("heart", side * .38, Kit.WARN)
	heart.position = Vector2(side * .66, -side * .06)
	box.add_child(heart)
	return box


static func _center(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc


# --- Results ------------------------------------------------------------------

## A round's result for the popup (meta/family_rift.gd finish()): what dropped
## as cards, then where the run stands.
static func _result_row(r: Dictionary) -> Control:
	var v := Kit.vbox(12)
	if r.get("won", false):
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		var cards: Array = []
		for id in r.get("copies", []):
			var c := Roster.get_critter(id)
			var card := Kit.panel(Kit.vbox(2, [CritterIcon.make(id, 1, 84), Kit.label(c.name, 18, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)]), Kit.box(Kit.PANEL2, Kit.LINE, 22, 2, 8))
			grid.add_child(card)
			cards.append([card, Roster.RARITY_COLORS.get(c.rarity) if c.rarity in ["rare", "epic", "legendary"] else null])
		for card in extra_cards(0, r.get("dyes", [])):
			grid.add_child(card[0])
			cards.append(card)
		v.add_child(grid)
		ResultPopup.drop_in(cards, null, .5)
		var line := "Rift cleared! The tear seals behind you." if r.get("cleared", false) else "Next: %s" % FamilyRift.ROUNDS[mini(int(r.round) + 1, FamilyRift.ROUNDS.size() - 1)].name
		v.add_child(Kit.label(line, 24, Kit.GOOD if r.get("cleared", false) else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
	else:
		v.add_child(Kit.label("The Rift closes. You keep everything you won.", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
	return v


## Drop cards for Rift Keys and Spark Dye drops ({id, drops, need, unlocked}),
## as [card, glow colour or null] for ResultPopup.drop_in (the campaign
## result popup shows them too).
static func extra_cards(keys: int, dyes: Array) -> Array:
	var out: Array = []
	if keys > 0:
		var cell := Kit.vbox(4, [_center(Glyph.make("key", 72, RIFT)), Kit.label("Rift Key", 20, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)])
		cell.custom_minimum_size.x = 130
		out.append([Kit.panel(cell, Kit.box(Kit.PANEL2, Color(RIFT, .7), 22, 2, 8)), RIFT])
	for d in dyes:
		var dye := Dyes.dye(str(d.id))
		var col := Color(dye.colors[0])
		var cell := Kit.vbox(4, [_center(Glyph.make("dye", 64, col)), Kit.label(dye.name, 18, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
			Kit.label("Unlocked!" if d.unlocked else "%d/%d" % [d.drops, d.need], 16, Kit.GOOD if d.unlocked else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)])
		cell.custom_minimum_size.x = 130
		out.append([Kit.panel(cell, Kit.box(Kit.PANEL2, Color(col, .6), 22, 2, 8)), col if d.unlocked else null])
	return out


## One line summing up a round, for the arena's flash and the popup's notice.
static func result_text(r: Dictionary) -> String:
	if not r.won:
		return "The Rift closes · +%d XP" % r.xp
	var parts: Array[String] = ["got " + ", ".join(r.copies.map(func(id): return Roster.get_critter(id).name))]
	for d in r.dyes:
		parts.append(Dyes.drop_text(d))
	parts.append("+%d XP" % r.xp)
	if r.get("cleared", false):
		parts.append("Rift cleared!")
	return ", ".join(parts)
