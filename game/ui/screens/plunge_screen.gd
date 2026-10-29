## Critter Plunge, opened from its card in Versus: the next race's course is
## the painting with your racer on it, pick how many racers (4 race for coins,
## 6 for medals, 8 for better medals and more coins) and your racer, see what
## its ability does and what the race pays, then Race. Medals buy race
## talents; the stamp album keeps your best medal per course. The race runs in
## game/plunge.tscn; rules and payouts live in meta/critter_plunge.gd and
## sim/plunge.gd. Fits one phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const BossCard := preload("res://game/ui/boss_card.gd")
const CritterPlunge := preload("res://meta/critter_plunge.gd")
const Plunge := preload("res://sim/plunge.gd")
const Families := preload("res://sim/families.gd")
const Talents := preload("res://sim/talents.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Profile := preload("res://meta/profile.gd")
const CourseArt := preload("res://game/ui/plunge_course_art.gd")
const EnergySheet := preload("res://game/ui/energy_sheet.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const PlungeTalents := preload("res://meta/plunge_talents.gd")
const TalentsSheet := preload("res://game/ui/plunge_talents_sheet.gd")
const StampsSheet := preload("res://game/ui/plunge_stamps_sheet.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const CritterPicker := preload("res://game/ui/critter_picker.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const Motion := preload("res://game/ui/motion.gd")

const ACCENT := Color("27c8ff")
const PLACES := ["1st", "2nd", "3rd", "4th", "5th"]

## The field size picked last, kept while the game runs.
static var field := CritterPlunge.DEFAULT_FIELD


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var now := int(Time.get_unix_time_from_system())
	p.update_energy(now)
	var root := Kit.vbox(18)
	root.add_child(shell.title_row("Critter Plunge", {"eyebrow": "Versus ·", "eyebrow_color": ACCENT, "info_mark": "plunge_info", "info": [
		"Your critter races a field of others down a marble run. First to the bottom wins.",
		"Every critter races with its own ability. A hit slows a racer down, and at 0 HP it's knocked out and places last.",
		"Everyone races at your racer's tier, so the drop decides it. Power, level and gear don't count in a race.",
		"Only some critters race for now. More join soon.",
		"4 racers race for coins only. 6 racers win medals on the podium. 8 racers win gold for 1st and 2nd, more medals and %s× coins." % str(CritterPlunge.COINS_8),
		"Your first %d races each day pay coins. Every race gives XP and Faction XP." % CritterPlunge.PRIZE_RACES,
		"Medals drop in races you watch to the end. Spend them on race talents for each family.",
		"The stamp album keeps your best medal on each course."]}))
	var fighter: String = CritterPlunge.racer_for(p)
	var course: Dictionary = CritterPlunge.course_for(CritterPlunge.next_seed(p))
	var hero := MarginContainer.new()
	hero.custom_minimum_size.y = 190
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero.add_child(CourseArt.make_course(course.id, Vector2(.5, .2), 28.0, Vector4(.45, .55, 1.0, 0.0), Kit.BG))
	hero.add_child(_course_name(course))
	if fighter != "":
		hero.add_child(_hero_racer(fighter, int(p.best(fighter).get("tier", 1))))
	root.add_child(hero)
	root.add_child(_field_row(shell))
	root.add_child(_prizes(shell, fighter, now))
	if fighter == "":
		root.add_child(Kit.label("None of your critters race yet. Summon one of the racers to join in.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
		return root
	root.add_child(_fighter_card(shell, fighter))
	root.add_child(_medals(shell, fighter))
	root.add_child(_race_button(shell, fighter))
	return root


## The next course's name at the top of the painting.
static func _course_name(course: Dictionary) -> Control:
	var name := Kit.label(course.name, 28, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	name.add_theme_constant_override("outline_size", 10)
	name.add_theme_color_override("font_outline_color", Color(Kit.BG, .85))
	name.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var box := MarginContainer.new()
	box.add_theme_constant_override("margin_top", 14)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name)
	return box


## Your racer, big, at the foot of the painting, popping in when the screen opens.
static func _hero_racer(fighter: String, tier: int) -> Control:
	var icon := CritterIcon.make(fighter, tier, 150)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_END
	var box := MarginContainer.new()
	box.add_theme_constant_override("margin_bottom", 18)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	Motion.pop(icon, 0.4, .35, .1)
	return box


## What a race pays in this field: coins by place while prize races last, the
## podium's medals, critter XP and Faction XP for the racer's family.
static func _prizes(shell, fighter: String, now: int) -> Control:
	var left := CritterPlunge.prize_races_left(shell.profile, now)
	var items: Array = []
	if left > 0:
		items.append(BossCard.prize("coin", "%d to %d" % [CritterPlunge.coins_for(field, field), CritterPlunge.coins_for(1, field)]))
	var podium: Array = CritterPlunge.PODIUM.get(field, [])
	var k := 0
	while k < podium.size():
		var j := k
		while j + 1 < podium.size() and podium[j + 1] == podium[k]:
			j += 1
		var places: String = PLACES[k] if j == k else "%s-%s" % [PLACES[k], PLACES[j]]
		items.append(Kit.vbox(0, [Kit.glyph("medal_" + podium[k], 38, Color.WHITE), Kit.label(places, 18, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)]))
		k = j + 1
	var xp := Kit.vbox(2, [Kit.label("+%d XP" % CritterPlunge.XP, 22, Kit.MUTED)])
	var fam := Talents.faction_of(fighter)
	if fam != "":
		var fxp: Dictionary = Profile.FACTION_FIGHT_XP
		xp.add_child(Kit.hbox(4, [FamilyIcon.make(fam, 26), Kit.label("+%d-%d" % [fxp.loss, fxp.win], 22, FamilyIcon.color(fam))]))
	xp.alignment = BoxContainer.ALIGNMENT_CENTER
	items.append(xp)
	return BossCard.prizes(shell, "Prize races left: %d" % left, ACCENT, items, 0, "plunge")


## Your racer: tier stars and what its ability does. Change opens the picker:
## owned racers first, then your critters that don't race yet, greyed.
static func _fighter_card(shell, id: String) -> Control:
	var p = shell.profile
	var tier: int = int(p.best(id).get("tier", 1))
	var info := Kit.vbox(4, [Kit.caption("Your racer"), Kit.label(Roster.get_critter(id).name, 30),
		Kit.label(_card(id, tier), 20, ACCENT, HORIZONTAL_ALIGNMENT_LEFT, true)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(14, [FighterTag.icon(id, tier, 92), info, Kit.chip("Change", Kit.ACCENT)], BoxContainer.ALIGNMENT_CENTER)
	var pick := func() -> void:
		var racers := CritterPicker.by_power(p, Plunge.RACERS)
		var others := CritterPicker.by_power(p, BallDefs.PLAYABLE.filter(func(c): return not Plunge.can_race(c)))
		var locked := {}
		for c in others:
			locked[c] = true
		CritterPicker.open(shell, racers + others, {"title": "Your racer", "current": id, "locked": locked,
			"locked_toast": "%s doesn't race yet.", "hint": "Racers: %d of %d" % [Plunge.RACERS.size(), BallDefs.PLAYABLE.size()],
			"on_pick": func(picked: String) -> void:
				CritterPlunge.racer = picked
				shell.refresh()})
	var card := Kit.card_button(row, pick, Color("3a3480"), Kit.PANEL2, 32, 14)
	shell.mark("plunge_fighter", card)
	return card


## Your medals over your racer's family talents in one clipped line, the way
## into race talents and the stamp album.
static func _medals(shell, fighter: String) -> Control:
	var talents := Kit.button("Talents", func(): TalentsSheet.open(shell, fighter), "primary", 24, 72)
	shell.mark("plunge_talents", talents)
	var mine := Kit.vbox(2, [TalentsSheet.medal_row(shell.profile, 26)])
	mine.alignment = BoxContainer.ALIGNMENT_CENTER
	var bonus: String = PlungeTalents.summary(shell.profile, Families.of(fighter))
	if bonus != "":
		var line := Kit.label(bonus, 16, Color("ffd36b"), HORIZONTAL_ALIGNMENT_CENTER)
		line.clip_text = true
		line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		mine.add_child(line)
	var stamps := Kit.button("", func(): StampsSheet.open(shell), "ghost", 24, 72)
	stamps.custom_minimum_size.x = 84
	stamps.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var g := CenterContainer.new()
	g.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.add_child(Kit.glyph("medal_gold", 40, Color.WHITE))
	stamps.add_child(g)
	shell.mark("plunge_stamps", stamps)
	return Kit.hbox(14, [mine, talents, stamps], BoxContainer.ALIGNMENT_CENTER)


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
