## The parts every daily boss screen (Brood Queen, Anvil King, Totem, Prism
## Wyrm, Piñata, Glitch) shares: the fighter card (tap to pick another critter
## in the picker), the fight card (boss face and power, what a win pays, the
## Fight button) and start(), which turns a boss's start() error into the
## energy sheet or a toast. Each screen only says what is its own.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Roster := preload("res://game/ui/roster.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const CritterPicker := preload("res://game/ui/critter_picker.gd")
const EnergySheet := preload("res://game/ui/energy_sheet.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const BossArt := preload("res://game/boss_art.gd")


## Your fighter: face, name, power (or `lines` in its place) and Change, which
## opens the critter picker; a pick becomes your lineup critter. Marks `<prefix>_fighter`.
static func fighter(shell, id: String, prefix: String, lines := [], icon := 92) -> Control:
	var p = shell.profile
	var b: Dictionary = p.best(id)
	var info := Kit.vbox(4, [Kit.caption("Your fighter"), Kit.label(Roster.get_critter(id).name, 30)])
	for l in (lines if not lines.is_empty() else [Kit.power(p.power_of(id), 24)]):
		info.add_child(l)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(14, [FighterTag.icon(id, b.tier, icon, false, b.level), info, Kit.chip("Change", Kit.ACCENT)], BoxContainer.ALIGNMENT_CENTER)
	var pick := func() -> void:
		CritterPicker.open(shell, CritterPicker.by_power(p, BallDefs.PLAYABLE), {"title": "Your fighter", "current": id,
			"on_pick": func(picked: String) -> void:
				p.set_lineup(picked)
				shell.refresh()})
	var card := Kit.card_button(row, pick, Color("3a3480"), Kit.PANEL2, 32, 14)
	shell.mark(prefix + "_fighter", card)
	return card


## What a win of the picked level pays, big, near the top of a boss screen:
## `title` ("Level 13 prizes") over a row of `items` (prize() each) and the
## win's XP. Marks `<prefix>_prizes`.
static func prizes(shell, title: String, accent: Color, items: Array, xp: int, prefix: String) -> Control:
	var row := Kit.hbox(22, [], BoxContainer.ALIGNMENT_CENTER)
	for c in items:
		row.add_child(c)
	if xp > 0:
		row.add_child(Kit.label("+%d XP" % xp, 26, Kit.MUTED))
	var col := Kit.vbox(6, [Kit.caption(title, accent), row])
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.get_child(0).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var card := Kit.panel(col, Kit.box(Color(accent, .1), Color(accent, .45), 28, 2, 12))
	shell.mark(prefix + "_prizes", card)
	return card


## One prize: its glyph and the amount ("3", "1+", "500 to 9,000").
static func prize(kind: String, value, tint := Color.WHITE) -> Control:
	return Kit.amount(kind, value, 32, Kit.FG, tint)


## How your power stacks up against `rec`: [text, colour].
static func verdict(mine: int, rec: int, foe := "It's") -> Array:
	if mine >= rec:
		return ["You're stronger", Kit.GOOD]
	if mine * 1.15 >= rec:
		return ["Close fight", Kit.WARN]
	return ["%s stronger" % foe, Kit.BAD]


## The card with the one Fight button. opts: boss (id), accent, rec (boss
## power, -1 hides it), mine (your power), foe ("It's" / "She's" / ...),
## title (e.g. "Lv 3"), pay (Controls: what a win gives), cost, left (runs
## left), on_fight, label ("Fight"), mark, height (of the button, 72). Out of energy, the button says so
## and opens the energy sheet.
static func fight(shell, opts: Dictionary) -> Control:
	var p = shell.profile
	var accent: Color = opts.accent
	var rec: int = opts.get("rec", -1)
	var info := Kit.vbox(4)
	if opts.has("title"):
		info.add_child(Kit.label(opts.title, 28))
	for c in opts.get("pay", []):
		info.add_child(c)
	var icon: Control = BossArt.icon(opts.boss, 76 if rec >= 0 else 96)
	if rec >= 0:
		var v := verdict(opts.mine, rec, opts.get("foe", "It's"))
		info.add_child(Kit.label(v[0], 20, v[1]))
		var p_tag := Kit.power(rec, 20, v[1])
		p_tag.alignment = BoxContainer.ALIGNMENT_CENTER
		icon = Kit.vbox(0, [icon, p_tag])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var left: int = opts.left
	var cost: int = opts.cost
	var button: Button
	if left > 0 and not EnergySheet.has(p, cost):
		# Short on energy: still tappable, but it reads as short and opens the energy sheet.
		var ink: Color = Kit.BUTTON_STYLES["go"][2]
		button = Kit.button("", func(): EnergySheet.open(shell), "go", 24, opts.get("height", 72))
		var out := Kit.hbox(6, [Kit.label("OUT OF", 24, ink), Kit.glyph("energy", 26, ink)], BoxContainer.ALIGNMENT_CENTER)
		out.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		out.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(out)
		button.modulate = Color(1, 1, 1, .75)
	else:
		button = Kit.cost_button(opts.get("label", "Fight"), cost, "energy", opts.on_fight, "go", 24, opts.get("height", 72))
		button.disabled = left <= 0
	button.custom_minimum_size.x = 160
	shell.mark(opts.mark, button)
	var row := Kit.hbox(12, [icon, info, button], BoxContainer.ALIGNMENT_CENTER)
	return Kit.panel(row, Kit.box(Kit.PANEL, Color(accent, .5), 30, 2, 12))


## Starts a boss fight from `cfg` (the boss's start() result), or explains why
## not: no energy opens the energy sheet; `done` is the out-of-runs toast and
## `locked` the not-unlocked-yet one.
static func start(shell, cfg: Dictionary, d: int, id: String, kind: String, done: String, locked: String) -> void:
	if cfg.has("error"):
		shell.refresh()
		if cfg.error == "energy":
			EnergySheet.open(shell)
			return
		shell.toast({"runs": done, "no_ball": "Pick a critter that can fight first.", "level": "Beat the level before it first."}.get(cfg.error, locked))
		return
	shell.boss_requested.emit(cfg, d, id, kind)
