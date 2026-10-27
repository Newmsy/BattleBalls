## The Adventure hub, opened from the Adventure door on Play: the campaign,
## the Spire and the farming bosses, each on its own painting. The campaign
## card is the current zone's painting (the same one as the Home door); the
## Spire and the bosses sit under it on two tall paintings. A new PvE mode
## adds one card here.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const PlayScreen := preload("res://game/ui/screens/play_screen.gd")
const BossesScreen := preload("res://game/ui/screens/bosses_screen.gd")
const HomePainting := preload("res://game/ui/home_painting.gd")
const LiveOps := preload("res://game/liveops.gd")
const Spire := preload("res://sim/spire.gd")
const SpireClimb := preload("res://meta/spire_climb.gd")
const FamilyRift := preload("res://meta/family_rift.gd")
const Families := preload("res://sim/families.gd")

## The Spire painting's lit floors step up with the week's climb (0-3).
const SPIRE_STEPS := 4


static func build(shell, _params: Dictionary) -> Control:
	var root := Kit.vbox(18)
	root.add_child(shell.title_row("Adventure", {"back_mark": "adventure_back", "info_mark": "adventure_info", "info": [
		"Campaign: the Neon Circuit, zone by zone. Stages drop critter copies, Summon Orbs and gear.",
		"The Spire: 50 floors, one critter per floor, resets every week.",
		"Bosses: farm coins, gear, Hammers and eggs. They open from stage 1-5.",
		"Rifts: spend a Rift Key for three fights against one family and copies of its critters."]}))
	# The cards share the room under the title, so a tall phone shows more painting.
	var campaign := _campaign_card(shell)
	var now := LiveOps.now()
	var climb = SpireClimb.load_file(now)
	var spire := _tall_card(shell, "hub_spire", "adventure_spire_%d" % spire_step(climb.cleared), "The Spire",
		"Floor %d/%d" % [climb.cleared, Spire.FLOORS], "Resets in " + LiveOps.countdown(now, Spire.week_end(climb.week)),
		PlayScreen.DAILY, Color("7a6a30"), func(): shell.go("spire"))
	var bosses := _bosses_card(shell)
	var pair := Kit.hbox(14, [spire, bosses])
	pair.size_flags_vertical = Control.SIZE_EXPAND_FILL
	campaign.size_flags_vertical = Control.SIZE_EXPAND_FILL
	campaign.size_flags_stretch_ratio = 1.05
	root.add_child(campaign)
	root.add_child(pair)
	root.add_child(_rift_card(shell))
	return root


## Rifts: a wide painted band (a Glitch tear in dusk ruins) with your keys, or
## the run you have open. Dimmed until the Zone 1 boss is beaten.
static func _rift_card(shell) -> Control:
	var p = shell.profile
	var open: bool = FamilyRift.is_unlocked(p)
	var status: String
	if not open:
		status = "Opens after the Zone 1 boss"
	elif FamilyRift.in_run(p):
		status = "%s Rift · round %d of %d" % [Families.info(p.rift.family).name, int(p.rift.round) + 1, FamilyRift.ROUNDS.size()]
	else:
		status = "Copies from the family you pick"
	var title := Kit.hbox(12, [Kit.label("Rifts", 32), Kit.amount("key", p.rift_keys(), 24, Kit.FG, Color("5ce1ff"))], BoxContainer.ALIGNMENT_BEGIN)
	var st := Kit.label(status, 20, Color("5ce1ff") if open else Kit.MUTED)
	st.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	st.clip_text = true
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.custom_minimum_size.y = 36
	var v := Kit.vbox(2, [title, gap, st])
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PlayScreen._on_art(v)
	var card := _painted(HomePainting.make("adventure_rift", Vector2(.62, .5), 30.0, Vector4(.18, .45, .74, .85), Kit.BG), v, Color("6a2a7a"), 16)
	var go: Callable = (func(): shell.go("rift")) if open else (func(): shell.toast("Beat the Zone 1 boss to open Rifts."))
	card.custom_minimum_size.y = 168
	var b := Kit.card_button(card, go, Color(0, 0, 0, 0), Color(0, 0, 0, 0), 32, 0)
	if not open:
		b.modulate = Color(1, 1, 1, .6)
	elif FamilyRift.in_run(p) or p.rift_keys() > 0:
		b.add_child(PlayScreen.red_dot())
	shell.mark("rift", b)
	return b


## Which Spire painting: the floors lit go up in four steps over the 50 floors.
static func spire_step(cleared: int) -> int:
	return clampi(ceili(float(cleared) * (SPIRE_STEPS - 1) / Spire.FLOORS), 0, SPIRE_STEPS - 1)


## The campaign card: the zone's painting with where you stand and Continue.
static func _campaign_card(shell) -> Control:
	var c := PlayScreen.campaign_state(shell.profile)
	var go := Kit.button("Continue", func(): shell.go("world"), "go", 32, 92)
	shell.mark("campaign", go)
	var name := Kit.label(c.zone.name, 40)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var room := Control.new()
	room.custom_minimum_size.y = 90
	room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := Kit.vbox(8, [
		Kit.caption("Campaign · Zone %d" % (c.z + 1), PlayScreen.ADVENTURE),
		Kit.hbox(10, [name, Kit.glyph("crown", 26, Kit.FG), Kit.label("%d/%d" % [c.stars, c.max_stars], 24, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER),
		room, c.next_row, go])
	PlayScreen._on_art(v)
	return Kit.tap_card(_painted(HomePainting.make("home_zone_" + c.zone.id, Vector2(.68, .45), 30.0, Vector4(.26, .55, .45, .95), Kit.BG),
		v, Color("2f6a5a"), 18), func(): shell.go("world"))


## A tall painted card, the whole card one button: title at the top, status at the bottom.
static func _tall_card(shell, mark: String, art: String, title: String, status: String, line: String, accent: Color, border: Color, on_press: Callable, dot := false) -> Control:
	var st := Kit.label(status, 24, accent)
	var ln := Kit.label(line, 19, Kit.MUTED)
	for l in [st, ln]:
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.clip_text = true
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.custom_minimum_size.y = 120
	var v := Kit.vbox(2, [Kit.label(title, 32), gap, st, ln])
	PlayScreen._on_art(v)
	var card := _painted(HomePainting.make(art, Vector2(.5, .5), 30.0, Vector4(.18, .45, .74, .85), Kit.BG), v, border, 16)
	var b := Kit.card_button(card, on_press, Color(0, 0, 0, 0), Color(0, 0, 0, 0), 32, 0)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.x = 0
	if dot:
		b.add_child(PlayScreen.red_dot())
	shell.mark(mark, b)
	return b


## Bosses: today's runs left, or what opens them (dimmed) before stage 1-5.
static func _bosses_card(shell) -> Control:
	if not BossesScreen.any_open(shell.profile):
		var locked := _tall_card(shell, "locked_dailies", "adventure_bosses", "Bosses", "Locked", "Opens after stage 1-5",
			Kit.MUTED, Color("3a3460"), PlayScreen._bosses_locked_info(shell))
		locked.modulate = Color(1, 1, 1, .6)
		return locked
	var left := BossesScreen.runs_left_total(shell.profile, int(Time.get_unix_time_from_system()))
	return _tall_card(shell, "bosses", "adventure_bosses", "Bosses", "%d runs left" % left if left > 0 else "Done for today",
		"Coins, gear, Hammers, eggs", PlayScreen.BOSS if left > 0 else Kit.MUTED, Color("7a4024"), func(): shell.go("bosses"), left > 0)


## A painting under `content` (padded), inside a rounded 2px border.
static func _painted(art: Control, content: Control, border: Color, pad: int) -> Control:
	var st := Kit.box(Kit.BG, border, 32, 2, 2)
	var stack := MarginContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(art)
	var m := PlayScreen._padded(content, pad, pad)
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	stack.add_child(m)
	return Kit.panel(stack, st)
