## Profile (the level badge): your Friends, then the account: save a
## guest's progress to an account (email code now, Apple and Google once
## switched on), sign in on another device, sign out, or delete the account
## and its progress for good. Data and calls live in
## game/online/account.gd (shell.account); the screen rebuilds when it changes.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const PlayScreen := preload("res://game/ui/screens/play_screen.gd")
const VersusScreen := preload("res://game/ui/screens/versus_screen.gd")

## What the player has typed, kept across rebuilds.
static var _draft := {"email": "", "code": ""}


static func build(shell, params: Dictionary) -> Control:
	var acc = shell.account
	var root := Kit.vbox(24)
	var chip: Control = null
	if acc != null and acc.status == "guest":
		chip = Kit.chip("Guest", Kit.WARN)
	elif acc != null and acc.status == "linked":
		chip = Kit.chip("Saved", Kit.GOOD)
	root.add_child(shell.title_row("Profile", {"extra": [chip]}))
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

	if acc.status == "linked":
		root.add_child(_linked_card(shell, acc))
	elif not acc.pending.is_empty():
		root.add_child(_code_card(shell, acc))
	elif params.get("mode", "") == "signin":
		root.add_child(_signin_card(shell, acc))
	else:
		root.add_child(_save_card(shell, acc))

	if acc.message != "":
		root.add_child(Kit.label(acc.message, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	if acc.pending.is_empty():
		var del := Kit.button("Delete account", func(): _confirm_delete(shell, acc), "ghost", 20, 64)
		del.disabled = acc.busy
		shell.mark("account_delete", del)
		root.add_child(del)
	return root


## Friends, behind your profile (Newms 2026-10-26): a painted card with
## what's new, opening the Friends screen.
static func friends_card(shell) -> Control:
	var fr = shell.friends
	var news: bool = fr.attention() > 0
	var card: Button = VersusScreen.painted(shell, "friends", "vs_friends", Vector2(.5, .75), "Friends", PlayScreen._friends_line(fr),
		Kit.GOOD if news else PlayScreen.VERSUS, func(): shell.go("friends"), true)
	card.custom_minimum_size.y = 160
	if news:
		card.add_child(PlayScreen.red_dot())
	return card


static func _save_card(shell, acc) -> Control:
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
	var other := Kit.vbox(10, [
		Kit.caption("Played before on another device?"),
		Kit.button("Sign in instead", func(): acc.message = ""; shell.refresh_with({"mode": "signin"}), "ghost", 24, 76),
	])
	return Kit.vbox(28, [Kit.panel(col), other])


static func _signin_card(shell, acc) -> Control:
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
	var back := Kit.button("Save instead", func(): acc.message = ""; shell.refresh_with({}), "ghost", 24, 76)
	return Kit.vbox(28, [Kit.panel(col), back])


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


static func _linked_card(shell, acc) -> Control:
	var how: Array = acc.linked_providers.filter(func(p): return p != "anonymous")
	var col := Kit.vbox(14, [
		Kit.label("Your progress is saved", 30),
		Kit.label(acc.email if acc.email != "" else "Signed in with " + ", ".join(how.map(func(p): return p.capitalize())), 24),
		Kit.label("Syncs when online. Sign in anywhere to carry on.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
	])
	var out := Kit.button("Sign out", func(): _confirm_sign_out(shell, acc), "ghost", 24, 76)
	return Kit.vbox(28, [Kit.panel(col), out])


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
		_draft = {"email": "", "code": ""}
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
