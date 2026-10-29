## Critter Plunge, opened from its card in Versus: pick how many racers (4,
## 6 or 8) and your racer, see what its ability does and what a race pays,
## then Race. The race runs in game/plunge.tscn; rules and payouts live in
## meta/critter_plunge.gd and sim/plunge.gd. Fits one phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const BossCard := preload("res://game/ui/boss_card.gd")
const CritterPlunge := preload("res://meta/critter_plunge.gd")
const Plunge := preload("res://sim/plunge.gd")
const HomePainting := preload("res://game/ui/home_painting.gd")
const EnergySheet := preload("res://game/ui/energy_sheet.gd")
const PlayScreen := preload("res://game/ui/screens/play_screen.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const PlungeTalents := preload("res://meta/plunge_talents.gd")
const TalentsSheet := preload("res://game/ui/plunge_talents_sheet.gd")

const ACCENT := Color("27c8ff")
const ART := "res://game/ui/versus_art/%s.png"

## The field size picked last, kept while the game runs.
static var field := CritterPlunge.DEFAULT_FIELD


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	p.update_energy(int(Time.get_unix_time_from_system()))
	var root := Kit.vbox(18)
	root.add_child(shell.title_row("Critter Plunge", {"eyebrow": "Versus ·", "eyebrow_color": ACCENT, "info_mark": "plunge_info", "info": [
		"Your critter races a field of others down a marble run. First to the bottom wins.",
		"Every critter races with its own ability. A hit slows a racer down, and at 0 HP it's knocked out and places last.",
		"Everyone races at your racer's tier, so the drop decides it.",
		"Only some critters race for now. More join soon.",
		"1st pays %d coins, last pays %d. Every race also gives XP and Faction XP." % [CritterPlunge.WIN_COINS, CritterPlunge.LAST_COINS],
		"A podium finish wins a medal. Spend medals on race talents for each family."]}))
	var hero := MarginContainer.new()
	hero.custom_minimum_size.y = 190
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero.add_child(HomePainting.make("vs_plunge", Vector2(.7, .5), 28.0, Vector4(.45, .55, 1.0, 0.0), Kit.BG, ART))
	root.add_child(hero)
	root.add_child(_field_row(shell))
	root.add_child(BossCard.prizes(shell, "Prizes", ACCENT, [BossCard.prize("coin", "%d to %d" % [CritterPlunge.LAST_COINS, CritterPlunge.WIN_COINS])], CritterPlunge.XP, "plunge"))
	var fighter: String = CritterPlunge.racer_for(p)
	if fighter == "":
		root.add_child(Kit.label("None of your critters race yet. Summon one of the racers to join in.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
		return root
	var tier: int = int(p.best(fighter).get("tier", 1))
	root.add_child(BossCard.fighter(shell, fighter, "plunge", [Kit.power(p.power_of(fighter), 22),
		Kit.label(_card(fighter, tier), 20, ACCENT, HORIZONTAL_ALIGNMENT_LEFT, true)], 92, Plunge.RACERS,
		func(picked: String) -> void: CritterPlunge.racer = picked))
	root.add_child(_medals(shell, fighter))
	root.add_child(_race_button(shell, fighter))
	return root


## Your medals and the way into race talents.
static func _medals(shell, fighter: String) -> Control:
	var talents := Kit.button("Talents", func(): TalentsSheet.open(shell, fighter), "primary", 24, 72)
	shell.mark("plunge_talents", talents)
	var row := Kit.hbox(16, [TalentsSheet.medal_row(shell.profile, 26), talents], BoxContainer.ALIGNMENT_CENTER)
	return row


## What the critter's ability does at `tier`, in plain words.
static func _card(id: String, tier: int) -> String:
	var line := ""
	var tiers: Array = CritterDb.get_critter(id).get("tiers", [])
	for k in mini(tier, tiers.size()):
		line = str(tiers[k].get("card", line))
	return line


## 4, 6 or 8 racers, side by side.
static func _field_row(shell) -> Control:
	var row := Kit.hbox(12, [Kit.label("Racers", 26, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)
	for n in CritterPlunge.FIELD_SIZES:
		var on: bool = n == field
		var b := Kit.button(str(n), func():
			field = n
			shell.refresh(), "go" if on else "ghost", 28, 72)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("plunge_field_%d" % n, b)
		row.add_child(b)
	return row


static func _race_button(shell, fighter: String) -> Control:
	var p = shell.profile
	var b: Button
	if not EnergySheet.has(p, CritterPlunge.ENERGY_COST):
		b = Kit.button("Out of energy", func(): EnergySheet.open(shell), "go", 26, 88)
		b.modulate = Color(1, 1, 1, .75)
	else:
		b = Kit.cost_button("Race", CritterPlunge.ENERGY_COST, "energy", func(): _race(shell, fighter), "go", 28, 88)
	shell.mark("plunge_go", b)
	return b


static func _race(shell, fighter: String) -> void:
	var cfg: Dictionary = CritterPlunge.start(shell.profile, fighter, field, int(Time.get_unix_time_from_system()))
	if cfg.has("error"):
		if cfg.error == "energy":
			EnergySheet.open(shell)
		else:
			shell.toast("Pick a critter that can race first.")
		shell.refresh()
		return
	CritterPlunge.pending = {"cfg": cfg, "fighter": fighter}
	shell.get_tree().change_scene_to_file("res://game/plunge.tscn")
