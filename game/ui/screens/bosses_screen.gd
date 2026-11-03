## The boss hall: every farming boss (design/bosses.md) as one card each,
## with what it farms and the runs left today, or what opens it. Tapping a
## card opens that boss's own screen. One tile on Play leads here, so Home
## stays one tile no matter how many bosses there are. Fits one phone screen:
## the painted splash of every boss together (home_art/bosses_hall.png,
## tools/event_art/scenes/bosses_hall.mjs) takes whatever room the cards leave.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const BossArt := preload("res://game/boss_art.gd")
const Bosses := preload("res://sim/bosses.gd")
const HomePainting := preload("res://game/ui/home_painting.gd")
const Idle := preload("res://game/ui/idle.gd")

## The splash never gets shorter than this, so the bosses stay in view.
const SPLASH_MIN := 190
## The painting's height over its width (720x520).
const SPLASH_SHAPE := 520.0 / 720.0

## In the order they open: screen, rules script, what it farms (reward glyphs,
## never their names), its glyph, its colour and how to open it.
const HALL := [
	{"screen": "pinata", "rules": preload("res://meta/pinata_party.gd"), "farms": ["coin"], "glyph": "coin", "color": "ffb627", "lock": "Clear stage 1-5"},
	{"screen": "vault", "rules": preload("res://meta/gear_vault.gd"), "farms": ["shell", "hammer"], "glyph": "hammer", "color": "ff8a3d", "lock": "Beat the Zone 1 boss"},
	{"screen": "nest", "rules": preload("res://meta/brood_nest.gd"), "farms": ["egg"], "glyph": "egg", "color": "ff6fae", "lock": "Beat the Zone 2 boss"},
	{"screen": "totem", "rules": preload("res://meta/totem_shrine.gd"), "farms": ["sparkle"], "glyph": "sparkle", "color": "c9a6ff", "lock": "Beat the Zone 3 boss"},
	{"screen": "wyrm", "rules": preload("res://meta/wyrm_rift.gd"), "farms": ["target"], "glyph": "target", "color": "7af0ff", "lock": "Beat the Zone 3 boss"},
	{"screen": "glitch", "rules": preload("res://meta/glitch_core.gd"), "farms": ["egg", "target", "hammer"], "glyph": "sparkle", "color": "7cff4f", "lock": "Beat the Zone 4 boss", "weekly": true},
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
	var root := Kit.vbox(12)
	root.add_child(shell.title_row("Bosses", {"info_mark": "bosses_info", "info": [
		"Stuns cancel a boss's wind-up and slows drag out its timers.",
		"Runs reset every day; The Glitch's tries reset every week."]}))
	root.add_child(splash())
	for h in HALL:
		root.add_child(_card(shell, p, h, now))
	return root


## Every boss in its hall, filling the room above the cards (never taller
## than the painting's own shape, so its sides are never cropped; a short
## phone shows a band through the bosses) and fading into the page at the
## bottom. Its layers move (living art).
static func splash() -> Control:
	var room := Control.new()
	room.custom_minimum_size.y = SPLASH_MIN
	room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := HomePainting.make("bosses_hall", Vector2(.5, .7), 28.0, Vector4(.06, .5, .8, .9), Kit.BG)
	room.add_child(art)
	room.resized.connect(func():
		var h := minf(room.size.y, room.size.x * SPLASH_SHAPE)
		art.position = Vector2(0, (room.size.y - h) / 2.0)
		art.size = Vector2(room.size.x, h))
	return room


static func _card(shell, p, h: Dictionary, now: int) -> Control:
	var open: bool = h.rules.is_unlocked(p)
	var accent := Color(h.color)
	var left: int = h.rules.runs_left(p, now) if open else 0
	var weekly: bool = h.get("weekly", false)
	var status: String = h.lock
	if open:
		status = ("%d of %d %s" % [left, h.rules.RUNS_PER_DAY, "tries this week" if weekly else "runs left"]) if left > 0 else ("Beaten this week" if weekly else "Done for today")
	var name := Kit.label(Bosses.DEFS[h.rules.BOSS].display_name, 28, Kit.FG if open else Kit.MUTED)
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.clip_text = true
	var info := Kit.vbox(0, [name, Kit.label(status, 19, Kit.GOOD if left > 0 else Kit.MUTED)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rewards := Kit.hbox(6, [], BoxContainer.ALIGNMENT_END)
	for g in h.farms:
		rewards.add_child(Kit.glyph(g, 28, accent if open else Kit.MUTED))
	var icon: Control = BossArt.icon(h.rules.BOSS, 68) if open else Glyph.make("lock", 40, Kit.MUTED)
	if not open:
		icon.custom_minimum_size = Vector2(68, 68)
	elif left > 0:
		Idle.breathe(icon, .08, .55) # Runs left: the boss stirs, waiting for you.
	var row := Kit.hbox(14, [icon, info, rewards], BoxContainer.ALIGNMENT_CENTER)
	var go: Callable = (func(): shell.go(h.screen)) if open else shell.info.bind(Bosses.DEFS[h.rules.BOSS].display_name, [Bosses.DEFS[h.rules.BOSS].description, h.lock + " to open it."])
	var card := Kit.card_button(row, go, accent.darkened(.45) if open else Kit.PANEL2, accent.darkened(.84) if open else Kit.PANEL, 28, 10)
	shell.mark("boss_" + h.screen, card)
	return card
