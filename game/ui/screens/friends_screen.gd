## Friends: your friend code and invite link, waiting energy gifts, requests,
## and each friend with a rematch against their saved team, a daily energy
## gift and preset pings (no free text). Data comes from shell.friends
## (game/online/friends.gd); the screen rebuilds when it changes.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const Friends := preload("res://game/online/friends.gd")
const Analytics := preload("res://game/online/analytics.gd")


static func build(shell, _params: Dictionary) -> Control:
	var fr = shell.friends
	var root := Kit.vbox(24)
	root.add_child(shell.title_row("Friends", {"extra": [_count_chip(fr)]}))

	if not fr.enabled():
		root.add_child(_sleepy(shell))
		root.add_child(_note("Offline", "Go online to add friends."))
		return root
	if fr.status == "idle":
		fr.refresh()
	if fr.status in ["idle", "loading"] and fr.list.is_empty() and fr.me.is_empty():
		root.add_child(_note("Loading friends…", ""))
		return root
	if fr.status == "error" and fr.me.is_empty():
		var retry := Kit.button("Try again", func(): fr.status = "idle"; shell.refresh(), "ghost", 26, 80)
		shell.mark("friends_retry", retry)
		root.add_child(Kit.vbox(14, [_sleepy(shell), _note("Couldn't reach your friends", "Check your connection and try again."), retry]))
		return root

	if not fr.invite.is_empty():
		root.add_child(_invite_card(shell, fr))
	root.add_child(_code_card(shell, fr))
	if fr.gifts_claimable > 0:
		root.add_child(_gifts_card(shell, fr))

	var incoming: Array = fr.incoming()
	if not incoming.is_empty():
		var col := Kit.vbox(12, [Kit.caption("Friend requests")])
		for f in incoming:
			col.add_child(_request_row(shell, fr, f))
		root.add_child(col)

	var mine: Array = fr.friends()
	var list := Kit.vbox(14, [Kit.hbox(0, [Kit.caption("Your friends"), Kit.spacer(),
		Kit.label("Unranked", 20, Kit.MUTED)])])
	if mine.is_empty():
		list.add_child(_note("No friends yet", "Share your invite link."))
	for f in mine:
		list.add_child(_friend_card(shell, fr, f))
	root.add_child(list)

	var outgoing: Array = fr.outgoing()
	if not outgoing.is_empty():
		var col := Kit.vbox(10, [Kit.caption("Sent")])
		for f in outgoing:
			var cancel := Kit.button("Cancel", func(): fr.remove(f.id), "ghost", 20, 60)
			cancel.size_flags_horizontal = Control.SIZE_SHRINK_END
			cancel.custom_minimum_size.x = 150
			var name := Kit.label(f.name, 26)
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			col.add_child(Kit.hbox(12, [name, cancel], BoxContainer.ALIGNMENT_CENTER))
		root.add_child(col)
	return root


static func _count_chip(fr) -> Control:
	var n: int = fr.friends().size()
	return Kit.chip("%d friend%s" % [n, "" if n == 1 else "s"], Kit.ACCENT) if fr.status == "ready" else null


## Your fighter, dozing: the empty-state picture. Drawn once (no per-frame cost).
static func _sleepy(shell) -> Control:
	var icon := CritterIcon.make(shell.profile.lineup, 1, 180)
	icon.still = true
	var zzz := Kit.label("z Z z", 34, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var c := CenterContainer.new()
	c.add_child(Kit.vbox(0, [zzz, icon]))
	return c


static func _note(title: String, text: String) -> Control:
	var col := Kit.vbox(8, [Kit.label(title, 30)])
	if text != "":
		col.add_child(Kit.label(text, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	return Kit.panel(col)


static func _invite_card(shell, fr) -> Control:
	var who: String = fr.invite.get("name", Friends.format_code(fr.invite.code))
	var on_add := func():
		var res: Dictionary = await fr.add_by_code(fr.invite.code)
		shell.toast(_add_message(res))
	var add := Kit.button("Add %s" % who, on_add, "go", 28, 88)
	shell.mark("invite_add", add)
	var skip := Kit.button("Not now", func(): fr.invite = {}; shell.refresh(), "ghost", 24, 88)
	skip.size_flags_stretch_ratio = 0.6
	var col := Kit.vbox(12, [Kit.caption("Invite", Kit.GOOD), Kit.label("%s wants to be friends" % who, 32, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true),
		Kit.hbox(14, [add, skip])])
	return Kit.panel(col, Kit.box(Color("17284a"), Color("2f5a55"), 32, 2, 24))


static func _code_card(shell, fr) -> Control:
	var code := Friends.format_code(str(fr.me.get("code", "")))
	var url := "%s?f=%s" % [shell.link_base, Friends.normalize_code(code)]
	var invite := Kit.button("Invite link", func(): shell.share_tapped.emit("f"), "primary", 26, 84)
	shell.mark("invite_link", invite)
	shell.share_link("f", invite, url, "Be my friend in Battle Balls! My code is %s." % code)
	var add := Kit.button("Add by code", func(): _ask_code(shell, fr), "ghost", 26, 84)
	shell.mark("add_code", add)
	var col := Kit.vbox(12, [
		Kit.hbox(0, [Kit.caption("Your friend code"), Kit.spacer(), Kit.label(str(fr.me.get("name", "")), 22, Kit.MUTED)]),
		Kit.label(code, 52, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.hbox(14, [invite, add]),
	])
	return Kit.panel(col)


static func _gifts_card(shell, fr) -> Control:
	var n: int = fr.gifts_claimable
	var on_claim := func():
		var energy: int = await fr.claim_gifts()
		if energy > 0:
			Analytics.track("energy", {"delta": energy, "source": "friend_gift"})
			shell.profile.energy += energy
			shell.profile.changed.emit()
			shell.toast("+%d energy from your friends!" % energy)
		else:
			shell.toast("Daily limit reached. The rest will wait.")
	var claim := Kit.button("Claim", on_claim, "go", 26, 80)
	claim.size_flags_horizontal = Control.SIZE_SHRINK_END
	claim.custom_minimum_size.x = 170
	shell.mark("claim_gifts", claim)
	var text := Kit.vbox(2, [Kit.label("%d energy gift%s" % [n, "" if n == 1 else "s"], 28),
		Kit.label("+%d each" % fr.gift_energy, 20, Kit.MUTED)])
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bolt := Glyph.make("energy", 56)
	bolt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return Kit.panel(Kit.hbox(16, [bolt, text, claim], BoxContainer.ALIGNMENT_CENTER),
		Kit.box(Kit.PANEL2, Color("5ce1ff"), 32, 2, 20))


static func _request_row(shell, fr, f: Dictionary) -> Control:
	var accept := Kit.button("Accept", func(): fr.answer(f.id, true), "go", 22, 70)
	shell.mark("accept_" + str(f.name), accept)
	var decline := Kit.button("No", func(): fr.answer(f.id, false), "ghost", 22, 70)
	accept.custom_minimum_size.x = 150
	decline.custom_minimum_size.x = 90
	accept.size_flags_horizontal = Control.SIZE_SHRINK_END
	decline.size_flags_horizontal = Control.SIZE_SHRINK_END
	var name := Kit.label(f.name, 28)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return Kit.panel(Kit.hbox(12, [name, decline, accept], BoxContainer.ALIGNMENT_CENTER), Kit.box(Kit.PANEL, Kit.LINE, 28, 2, 16))


static func _friend_card(shell, fr, f: Dictionary) -> Control:
	var lead := Friends.lead_critter(f)
	var icon := CritterIcon.make(lead if lead != "" else "vampire", int(f.lineup.slots[0].get("tier", 1)) if lead != "" else 1, 110, false, lead == "")
	var info := Kit.vbox(2, [Kit.label(f.name, 30)])
	var record := Friends.record_text(f.get("record"))
	if record != "":
		info.add_child(Kit.label(record, 20, Kit.MUTED))
	var ping := Friends.ping_text(f.get("ping"), int(Time.get_unix_time_from_system()))
	if ping != "":
		info.add_child(Kit.label(ping, 20, Kit.GOOD))
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top := Kit.hbox(16, [icon, info], BoxContainer.ALIGNMENT_CENTER)

	var blocker := Friends.rematch_blocker(f)
	var rematch := Kit.button("Rematch" if blocker == "" else blocker, func(): shell.rival_requested.emit(f), "go", 22 if blocker == "" else 18, 72)
	rematch.disabled = blocker != ""
	rematch.size_flags_stretch_ratio = 1.4
	shell.mark("rematch_" + str(f.name), rematch)
	var on_gift := func():
		if await fr.send_gift(f.id):
			shell.toast("Sent %s %d energy." % [f.name, fr.gift_energy])
	var gift := Kit.button("Sent", on_gift, "primary", 22, 72) if f.get("gift_sent", false) else Kit.cost_button("Gift", fr.gift_energy, "energy", on_gift, "primary", 22, 72)
	gift.disabled = f.get("gift_sent", false)
	shell.mark("gift_" + str(f.name), gift)
	var say := Kit.button("Say…", func(): _say_sheet(shell, fr, f), "ghost", 22, 72)
	shell.mark("say_" + str(f.name), say)
	var actions := Kit.hbox(10, [rematch, gift, say])
	var border := Color("5ce1ff") if f.get("gift_waiting", false) else Kit.LINE
	return Kit.panel(Kit.vbox(14, [top, actions]), Kit.box(Kit.PANEL, border, 32, 2, 20))


## Preset phrases only, plus removing the friend (kept here, away from the
## main buttons, so it can't be tapped by accident).
static func _say_sheet(shell, fr, f: Dictionary) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for i in Friends.PRESETS.size():
		var on_say := func():
			shell.close_overlay()
			var ok: bool = await fr.ping(f.id, i)
			shell.toast("Sent \"%s\" to %s." % [Friends.PRESETS[i], f.name] if ok else "Slow down a little, then try again.")
		var b := Kit.button(Friends.PRESETS[i], on_say, "ghost", 24, 76)
		shell.mark("preset_%d" % i, b)
		grid.add_child(b)
	var remove := Kit.button("Remove friend", func(): shell.close_overlay(); fr.remove(f.id), "ghost", 20, 64)
	remove.add_theme_color_override("font_color", Kit.BAD)
	var col := Kit.vbox(16, [Kit.label("Say to %s" % f.name, 34), grid, remove])
	shell.sheet(col)


static func _ask_code(shell, fr) -> void:
	if OS.has_feature("web"):
		var typed = JavaScriptBridge.eval("window.prompt(\"Your friend's code (like ABCD-EFGH):\", \"\")", true)
		if typed is String and typed.strip_edges() != "":
			_add_code(shell, fr, typed)
		return
	var edit := LineEdit.new()
	edit.placeholder_text = "ABCD-EFGH"
	edit.add_theme_font_size_override("font_size", 36)
	edit.custom_minimum_size = Vector2(0, 84)
	edit.max_length = 12
	var add := Kit.button("Add friend", func(): shell.close_overlay(); _add_code(shell, fr, edit.text), "go", 28, 84)
	shell.sheet(Kit.vbox(16, [Kit.label("Add by code", 34), edit, add]))


static func _add_code(shell, fr, text: String) -> void:
	if not Friends.is_code(text):
		shell.toast("Friend codes are 8 letters and numbers, like ABCD-EFGH.")
		return
	shell.toast(_add_message(await fr.add_by_code(text)))


static func _add_message(res: Dictionary) -> String:
	var who: String = res.get("friend", {}).get("name", "them")
	match res.get("status", ""):
		"requested": return "Request sent to %s." % who
		"friends": return "You and %s are friends now!" % who
		"already": return "You've already added %s." % who
		"not_found": return "No one has that code. Check it and try again."
		"self": return "That's your own code!"
		"full": return "Too many open requests right now. Try again later."
	return "Couldn't reach the server. Try again."
