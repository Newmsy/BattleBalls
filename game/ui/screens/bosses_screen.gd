## The boss hall: every farming boss (design/bosses.md) as one card each,
## with what it farms and the runs left today, or what opens it. Tapping a
## card opens that boss's own screen. One tile on Play leads here, so Home
## stays one tile no matter how many bosses there are. Fits one phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const BossArt := preload("res://game/boss_art.gd")
const Bosses := preload("res://sim/bosses.gd")

## In the order they open: screen, rules script, what it farms (reward glyphs,
## never their names), its glyph, its colour and how to open it.
const HALL := [
	{"screen": "pinata", "rules": preload("res://meta/pinata_party.gd"), "farms": ["coin"], "glyph": "coin", "color": "ffb627", "lock": "Clear stage 1-5"},
	{"screen": "vault", "rules": preload("res://meta/gear_vault.gd"), "farms": ["shell", "hammer"], "glyph": "hammer", "color": "ff8a3d", "lock": "Beat the Zone 1 boss"},
	{"screen": "nest", "rules": preload("res://meta/brood_nest.gd"), "farms": ["egg"], "glyph": "egg", "color": "ff6fae", "lock": "Beat the Zone 2 boss"},
	{"screen": "totem", "rules": preload("res://meta/totem_shrine.gd"), "farms": ["sparkle"], "glyph": "sparkle", "color": "c9a6ff", "lock": "Beat the Zone 3 boss"},
	{"screen": "wyrm", "rules": preload("res://meta/wyrm_rift.gd"), "farms": ["target"], "glyph": "target", "color": "7af0ff", "lock": "Beat the Zone 4 boss"},
	{"screen": "glitch", "rules": preload("res://meta/glitch_core.gd"), "farms": ["egg", "target", "hammer"], "glyph": "sparkle", "color": "7cff4f", "lock": "Beat the Zone 5 boss", "weekly": true},
]


static func any_open(profile) -> bool:
	return HALL.any(func(h): return h.rules.is_unlocked(profile))


## Daily runs left over every open boss (the weekly one isn't counted).
static func runs_left_total(profile, now: int) -> int:
	var n := 0
	for h in HALL:
		if h.rules.is_unlocked(profile) and not h.get("weekly", false):
			n += h.rules.runs_left(profile, now)
	return n


## The Play tab's tile: how many boss runs are left today.
static func tile(shell) -> Control:
	var left := runs_left_total(shell.profile, int(Time.get_unix_time_from_system()))
	var line := "%d runs left today" % left if left > 0 else "Done for today"
	return load("res://game/ui/screens/play_screen.gd").mode_tile(shell, "bosses", "Bosses", line,
		Color("ff8a3d") if left > 0 else Kit.MUTED, func(): shell.go("bosses"), "hammer")


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var now := int(Time.get_unix_time_from_system())
	var root := Kit.vbox(18)
	var head := Kit.vbox(2, [Kit.caption("Daily", Color("ff8a3d")), Kit.label("Bosses", 40)])
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(Kit.hbox(16, [shell.back_button("back"), head, shell.info_button("Bosses", [
		"Each boss has its own map, tricks and reward.",
		"Stuns cancel a boss's wind-up and slows drag out its timers, so pick a critter whose trick fits the boss.",
		"Runs reset every day; The Glitch's tries reset every week."], "bosses_info")], BoxContainer.ALIGNMENT_CENTER))
	for h in HALL:
		root.add_child(_card(shell, p, h, now))
	return root


static func _card(shell, p, h: Dictionary, now: int) -> Control:
	var open: bool = h.rules.is_unlocked(p)
	var accent := Color(h.color)
	var left: int = h.rules.runs_left(p, now) if open else 0
	var weekly: bool = h.get("weekly", false)
	var status: String = h.lock
	if open:
		status = ("%d of %d %s" % [left, h.rules.RUNS_PER_DAY, "tries this week" if weekly else "runs left"]) if left > 0 else ("Beaten this week" if weekly else "Done for today")
	var info := Kit.vbox(4, [Kit.label(Bosses.DEFS[h.rules.BOSS].display_name, 30, Kit.FG if open else Kit.MUTED),
		Kit.label(status, 20, Kit.GOOD if left > 0 else Kit.MUTED)])
	var rewards := Kit.hbox(8, [], BoxContainer.ALIGNMENT_BEGIN)
	for g in h.farms:
		rewards.add_child(Kit.glyph(g, 28, accent if open else Kit.MUTED))
	info.add_child(rewards)
	info.move_child(rewards, 1)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon: Control = BossArt.icon(h.rules.BOSS, 84) if open else Glyph.make("lock", 48, Kit.MUTED)
	if not open:
		icon.custom_minimum_size = Vector2(84, 84)
	var row := Kit.hbox(14, [icon, info], BoxContainer.ALIGNMENT_CENTER)
	var go: Callable = (func(): shell.go(h.screen)) if open else shell.info.bind(Bosses.DEFS[h.rules.BOSS].display_name, [Bosses.DEFS[h.rules.BOSS].description, h.lock + " to open it."])
	var card := Kit.card_button(row, go, accent.darkened(.45) if open else Kit.PANEL2, accent.darkened(.84) if open else Kit.PANEL, 30, 14)
	shell.mark("boss_" + h.screen, card)
	return card
