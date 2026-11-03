## Profile (the level badge): your Friends, then the account: change your
## name, save a guest's progress to an account (email code now, Apple and
## Google once switched on), sign in on another device, sign out, or delete
## the account and its progress for good. Data and calls live in
## game/online/account.gd (shell.account); the screen rebuilds when it changes.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const PlayScreen := preload("res://game/ui/screens/play_screen.gd")
const VersusScreen := preload("res://game/ui/screens/versus_screen.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const Painted := preload("res://game/ui/painted.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const Zones := preload("res://meta/zones.gd")
const Campaign := preload("res://meta/campaign.gd")

## What the player has typed, kept across rebuilds.
static var _draft := {"email": "", "code": "", "name": ""}


static func build(shell, params: Dictionary) -> Control:
	var acc = shell.account
	var root := Kit.vbox(18)
	var chip: Control = null
	if acc != null and acc.status == "guest":
		chip = Kit.chip("Guest", Kit.WARN)
	elif acc != null and acc.status == "linked":
		chip = Kit.chip("Saved", Kit.GOOD)
	root.add_child(shell.title_row("Profile", {"extra": [chip]}))
	root.add_child(hero_card(shell, acc))
	root.add_child(friends_card(shell))

	if acc == null or not acc.enabled():
		root.add_child(_note("Offline", "Progress is on this device. Go online to back it up."))
		return root
	if acc.status == "loading":
		acc.refresh()
		root.add_child(_note("Checking your account…", ""))
		return root
	if acc.status == "error":
		var retry := Kit.button("Try again", func(): acc.status = "loading"; shell.refresh(), "ghost", 26, 80)
		root.add_child(Kit.vbox(14, [_note("Couldn't reach your account", "Check your connection and try again."), retry]))
		return root

	# Each card's other way out (sign out, sign in instead...) shares a row
	# with Delete account under it, so the page fits a small phone.
	var card: Array
	if acc.status == "linked":
		card = _linked_card(shell, acc)
	elif not acc.pending.is_empty():
		card = [_code_card(shell, acc), null]
	elif params.get("mode", "") == "signin":
		card = _signin_card(shell, acc)
	else:
		card = _save_card(shell, acc)
	root.add_child(card[0])

	if acc.message != "":
		root.add_child(Kit.label(acc.message, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	if acc.pending.is_empty():
		var del := Kit.button("Delete account", func(): _confirm_delete(shell, acc), "ghost", 20, 72)
		del.disabled = acc.busy
		del.add_theme_color_override("font_color", Kit.MUTED)
		shell.mark("account_delete", del)
		var row := Kit.hbox(14, [card[1], del] if card[1] != null else [del])
		for b in row.get_children():
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		root.add_child(row)
	return root


## Who you are at a glance: your fighter standing in its family's home,
## your name (Change beside it once online), account level with its XP, and
## three tiles: critters found, Arena trophies, campaign crowns.
static func hero_card(shell, acc) -> Control:
	var p = shell.profile
	var lead: String = p.lineup if p.owns(p.lineup) else Roster.ids()[0]
	var b: Dictionary = p.best(lead) if p.owns(lead) else {"tier": 1}
	var face := CritterIcon.make(lead, b.tier, 200 if shell.size.y >= 1400.0 else 150, true)
	var online: bool = acc != null and acc.enabled() and acc.status in ["guest", "linked"]
	var named: String = acc.display_name if online and acc.display_name != "" else ""
	var head := Kit.label(named if named != "" else "Level %d" % p.account_level, 34)
	head.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.clip_text = true
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_row := Kit.hbox(10, [head], BoxContainer.ALIGNMENT_CENTER)
	if online:
		var change := Kit.card_button(Kit.chip("Change", Kit.ACCENT), func(): _change_name(shell, acc), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 999, 0)
		change.disabled = acc.busy or acc.display_name == ""
		shell.mark("account_rename", change)
		name_row.add_child(change)
	var need: int = p.account_xp_to_next()
	var level := Kit.hbox(8, [Kit.spacer(), Kit.label("%s / %s XP" % [Kit.commas(p.account_xp), Kit.commas(need)], 19, PlayScreen.ON_ART_MUTED)], BoxContainer.ALIGNMENT_CENTER)
	if named != "": # The level moves off the heading to make room for the name.
		level.add_child(Kit.chip("Level %d" % p.account_level, Kit.ACCENT, 18))
		level.move_child(level.get_child(2), 0)
	var side := Kit.vbox(10, [name_row, level, Kit.bar(clampf(float(p.account_xp) / need, 0.0, 1.0), Kit.ACCENT, 14)])
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	var top := Kit.hbox(14, [face, side], BoxContainer.ALIGNMENT_CENTER)

	var store = ArenaStore.open()
	var crowns := 0
	var crowns_max := 0
	for z in Zones.ZONES.size():
		var n: int = Zones.zone(z).stages.size()
		crowns_max += n * 3
		for i in n:
			crowns += Campaign.stars_of(p, z, i)
	var tiles := Kit.hbox(10)
	for t in [["critters", Kit.FG, "%d/%d" % [p.found_count(), Roster.ids().size()], "Critters"],
			["trophy", PlayScreen.DAILY, Kit.commas(store.trophies), Ladder.league_label(store.trophies)],
			["crown", Kit.FG, "%d/%d" % [crowns, crowns_max], "Campaign"]]:
		var tile := Kit.panel(Kit.vbox(2, [
			Kit.hbox(6, [Glyph.make(t[0], 26, t[1], 1), Kit.label(t[2], 24)], BoxContainer.ALIGNMENT_CENTER),
			Kit.label(t[3], 17, PlayScreen.ON_ART_MUTED, HORIZONTAL_ALIGNMENT_CENTER)]),
			Kit.box(Color(0.05, 0.03, 0.16, 0.72), Color(1, 1, 1, 0.08), 20, 2, 10))
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tiles.add_child(tile)

	var col := Kit.vbox(12, [top, tiles])
	col.alignment = BoxContainer.ALIGNMENT_END
	var stack := Painted.stage(lead, col, {"top_dark": 0.0, "bottom_dark": 0.6})
	stack.custom_minimum_size.y = 400 if shell.size.y >= 1400.0 else 0
	# The whole card opens your fighter's page.
	var card := Kit.tap_card(stack, func(): shell.go_from("detail", {"id": lead}, face), 30)
	shell.mark("profile_hero", card)
	return card


## Friends, behind your profile (Newms 2026-10-26): a painted card with
## what's new, opening the Friends screen.
static func friends_card(shell) -> Control:
	var fr = shell.friends
	var news: bool = fr.attention() > 0
	var card: Button = VersusScreen.painted(shell, "friends", "vs_friends", Vector2(.5, .75), "Friends", PlayScreen._friends_line(fr),
		Kit.GOOD if news else PlayScreen.VERSUS, func(): shell.go("friends"), true)
	for c in card.get_children():
		if c is MarginContainer: # A card button's minimum follows its content.
			c.custom_minimum_size.y = 120
	if news:
		card.add_child(PlayScreen.red_dot())
	return card


static func _save_card(shell, acc) -> Array:
	var col := Kit.vbox(16, [
		Kit.label("Your progress is only on this device", 30),
		Kit.label("Back it up so a new phone never loses your critters.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
	])
	col.add_child(_field(shell, "email", "Your email"))
	var send := Kit.button("Email me a code", func(): _send(shell, acc, "save"), "primary", 28, 88)
	send.disabled = acc.busy
	shell.mark("account_send", send)
	col.add_child(send)
	for p in acc.PROVIDERS:
		if acc.provider_ready(p):
			col.add_child(Kit.button("Continue with %s" % p.capitalize(), func(): acc.use_provider(p, "save"), "ghost", 26, 84))
	var other := Kit.button("Sign in instead", func(): acc.message = ""; shell.refresh_with({"mode": "signin"}), "ghost", 22, 72)
	return [Kit.panel(col), other]


static func _signin_card(shell, acc) -> Array:
	var col := Kit.vbox(16, [
		Kit.label("Sign in to your account", 30),
		Kit.label("Your guest save is kept as a backup.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
	])
	col.add_child(_field(shell, "email", "Your email"))
	var send := Kit.button("Email me a code", func(): _send(shell, acc, "signin"), "primary", 28, 88)
	send.disabled = acc.busy
	col.add_child(send)
	for p in acc.PROVIDERS:
		if acc.provider_ready(p):
			col.add_child(Kit.button("Sign in with %s" % p.capitalize(), func(): acc.use_provider(p, "signin"), "ghost", 26, 84))
	var back := Kit.button("Save instead", func(): acc.message = ""; shell.refresh_with({}), "ghost", 22, 72)
	return [Kit.panel(col), back]


static func _code_card(shell, acc) -> Control:
	var col := Kit.vbox(16, [
		Kit.label("Enter the code", 30),
		Kit.label("Code sent to %s." % acc.pending.email, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
	])
	col.add_child(_field(shell, "code", "6-digit code"))
	var ok := Kit.button("Confirm", func(): _verify(shell, acc), "go", 28, 88)
	ok.disabled = acc.busy
	col.add_child(ok)
	col.add_child(Kit.hbox(14, [
		Kit.button("Send again", func(): _send(shell, acc, acc.pending.mode), "ghost", 22, 72),
		Kit.button("Change email", func(): _draft.code = ""; acc.cancel_code(), "ghost", 22, 72),
	]))
	return Kit.panel(col)


static func _linked_card(shell, acc) -> Array:
	var how: Array = acc.linked_providers.filter(func(p): return p != "anonymous")
	var col := Kit.vbox(14, [
		Kit.label("Your progress is saved", 30),
		Kit.label(acc.email if acc.email != "" else "Signed in with " + ", ".join(how.map(func(p): return p.capitalize())), 24),
		Kit.label("Syncs when online. Sign in anywhere to carry on.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
	])
	var out := Kit.button("Sign out", func(): _confirm_sign_out(shell, acc), "ghost", 22, 72)
	return [Kit.panel(col), out]


## Web: the browser's own prompt (Godot can't raise the phone keyboard there).
## Native: a popup with a text box.
static func _change_name(shell, acc) -> void:
	_draft.name = acc.display_name
	if OS.has_feature("web"):
		var got = JavaScriptBridge.eval("prompt(%s, %s)" % [JSON.stringify("Your new name"), JSON.stringify(_draft.name)], true)
		if got != null and str(got).strip_edges() != acc.display_name:
			_save_name(shell, acc, str(got))
		return
	var err := Kit.label("", 20, Kit.WARN, HORIZONTAL_ALIGNMENT_LEFT, true)
	var e := LineEdit.new()
	e.text = _draft.name
	e.max_length = acc.NAME_MAX
	e.custom_minimum_size = Vector2(0, 84)
	e.add_theme_font_size_override("font_size", 26)
	e.text_changed.connect(func(t): _draft.name = t; err.text = acc.check_name(t))
	shell.mark("account_name", e)
	var save := Kit.button("Save", func():
		err.text = acc.check_name(_draft.name)
		if err.text == "":
			shell.close_overlay()
			_save_name(shell, acc, _draft.name), "go", 28, 88)
	shell.mark("account_name_save", save)
	shell.sheet(Kit.vbox(18, [
		Kit.label("Change your name", 32),
		Kit.label("%d to %d letters or numbers." % [acc.NAME_MIN, acc.NAME_MAX], 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
		e, err, save,
		Kit.button("Cancel", shell.close_overlay, "ghost", 24, 76),
	]))
	e.grab_focus.call_deferred()


static func _save_name(shell, acc, text: String) -> void:
	if await acc.rename(text):
		shell.toast("You're now %s." % acc.display_name)
	else:
		shell.refresh()


static func _confirm_sign_out(shell, acc) -> void:
	var col := Kit.vbox(18, [
		Kit.label("Sign out on this device?", 32),
		Kit.label("Your progress stays on your account. This device starts again as a new guest until you sign back in.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
		Kit.button("Sign out", func(): shell.close_overlay(); acc.sign_out(), "primary", 28, 88),
		Kit.button("Cancel", shell.close_overlay, "ghost", 24, 76),
	])
	shell.sheet(col)


static func _confirm_delete(shell, acc) -> void:
	var what := "your account (%s) and all its progress" % acc.email if acc.email != "" else "all your progress"
	var del := Kit.button("Delete for good", func(): shell.close_overlay(); acc.delete_account(), "danger", 28, 88)
	shell.mark("account_delete_confirm", del)
	var col := Kit.vbox(18, [
		Kit.label("Delete account?", 32),
		Kit.label("This deletes %s: critters, gear, trophies, friends and purchases. It can't be undone." % what, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
		del,
		Kit.button("Cancel", shell.close_overlay, "ghost", 24, 76),
	])
	shell.sheet(col)


static func _send(shell, acc, mode: String) -> void:
	_draft.code = ""
	await acc.send_code(_draft.email, mode)


static func _verify(shell, acc) -> void:
	if await acc.verify_code(_draft.code):
		_draft = {"email": "", "code": "", "name": ""}
		shell.refresh_with({})


## A text field. The web build asks with the browser's own prompt (Godot's
## text input can't raise the phone keyboard there); native builds type in place.
static func _field(shell, key: String, placeholder: String) -> Control:
	if OS.has_feature("web"):
		var shown: String = _draft[key] if _draft[key] != "" else placeholder
		var b := Kit.card_button(Kit.label(shown, 26, Kit.FG if _draft[key] != "" else Kit.MUTED), func():
			var got = JavaScriptBridge.eval("prompt(%s, %s)" % [JSON.stringify(placeholder), JSON.stringify(_draft[key])], true)
			if got != null:
				_draft[key] = str(got).strip_edges()
				shell.refresh(), Kit.LINE, Kit.PANEL2, 22, 22)
		shell.mark("account_" + key, b)
		return b
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.text = _draft[key]
	e.custom_minimum_size = Vector2(0, 84)
	e.add_theme_font_size_override("font_size", 26)
	e.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS if key == "email" else LineEdit.KEYBOARD_TYPE_NUMBER
	e.text_changed.connect(func(t): _draft[key] = t)
	shell.mark("account_" + key, e)
	return e


static func _note(title: String, text: String) -> Control:
	var col := Kit.vbox(8, [Kit.label(title, 30)])
	if text != "":
		col.add_child(Kit.label(text, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	return col
