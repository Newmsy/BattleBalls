## Friends v1 on the client: friend codes, the overview the server sends, and
## that the Friends screen builds in every state. The server side is tested in
## tests/db/test_friends.sql.
extends "res://tests/test_case.gd"

const Friends := preload("res://game/online/friends.gd")
const Backend := preload("res://game/online/backend.gd")
const Shell := preload("res://game/ui/shell.gd")
const MatchSim := preload("res://sim/match_sim.gd")


func _overview() -> Dictionary:
	return Friends.demo_overview()


func _online_friends() -> Friends:
	var b := Backend.new()
	b.url = "https://example.invalid"
	b.key = "sb_publishable_test"
	var f := Friends.new(b)
	f.apply_overview(_overview())
	return f


func test_codes_are_forgiving_to_type() -> void:
	check_eq(Friends.normalize_code(" abcd-efgh "), "ABCDEFGH", "normalised")
	check(Friends.is_code("abcd efgh"), "spaces and case are fine")
	check(not Friends.is_code("ABCDEFG"), "too short")
	check(not Friends.is_code("ABCDEFG0"), "0 is never in a code")
	check_eq(Friends.format_code("abcdefgh"), "ABCD-EFGH", "formatted")


func test_overview_splits_friends_requests_and_waiting() -> void:
	var f := _online_friends()
	check_eq(f.status, "ready", "ready")
	check_eq(f.friends().size(), 2, "friends")
	check_eq(f.incoming().size(), 1, "incoming")
	check_eq(f.outgoing().size(), 1, "outgoing")
	check_eq(f.attention(), 4, "1 request + 3 gifts")
	check(f.is_friend_code("tttt-hhhh"), "friend code known")


func test_an_invite_from_a_friend_or_yourself_is_dropped() -> void:
	var f := _online_friends()
	f.invite = {"code": "TTTTHHHH"}
	f.apply_overview(_overview())
	check(f.invite.is_empty(), "already friends")
	f.invite = {"code": "ABCDEFGH"}
	f.apply_overview(_overview())
	check(f.invite.is_empty(), "own code")
	f.invite = {"code": "NEWWCODE"}
	f.apply_overview(_overview())
	check(not f.invite.is_empty(), "a stranger's invite stays")


func test_rematch_needs_a_team_this_client_can_fight() -> void:
	var f := _online_friends()
	check_eq(Friends.lead_critter(f.find("c")), "laser", "Theo leads with Optic")
	check_eq(Friends.rematch_blocker(f.find("c")), "", "Theo can be rematched")
	check_eq(Friends.rematch_blocker(f.find("d")), "No team saved yet", "Ola has no team")
	var old: Dictionary = f.find("c").duplicate(true)
	old.lineup.rules = MatchSim.RULES_VERSION + 1
	check_eq(Friends.lead_critter(old), "", "other sim rules")
	check_eq(Friends.rematch_blocker(old), "Team needs a game update", "blocked on rules")


func test_record_and_ping_text() -> void:
	check_eq(Friends.record_text({"wins": 0, "losses": 0, "draws": 0}), "No rematches yet", "empty")
	check_eq(Friends.record_text({"wins": 3, "losses": 1, "draws": 2}), "Rematches: 3 won, 1 lost, 2 drawn", "record")
	var at := Time.get_unix_time_from_datetime_string("2026-10-14T22:00:00")
	check_eq(Friends.ping_text({"preset": 1, "at": "2026-10-14T22:00:00.5+00:00"}, at + 300), "\"Nice shot!\" · 5m ago", "ping")
	check_eq(Friends.ping_text({"preset": 99, "at": ""}, at), "", "unknown preset shows nothing")
	check_eq(Friends.ago("2026-10-14T22:00:00", at + 2 * 86400), "2d ago", "days")


func test_offline_calls_do_nothing() -> void:
	var f := Friends.new()
	check_eq(f.status, "offline", "offline")
	check(not f.enabled(), "not enabled")
	check_eq(f.attention(), 0, "nothing waiting")


func test_friends_screen_builds_offline_and_online() -> void:
	var shell = Shell.new()
	shell.build()
	shell.go("friends")
	check_eq(shell.current, "friends", "offline screen")
	shell.set_friends(_online_friends())
	shell.friends.invite = {"code": "NEWWCODE", "name": "Robin"}
	shell.refresh()
	check_eq(shell.current, "friends", "online screen")
	check_eq(shell.share_targets().size(), 0, "not laid out outside the tree")
	shell.show_tab("play")
	check_eq(shell.current, "play", "play tab with the friends card")
	check(shell._dots.play.visible, "play tab shows the waiting dot")
	shell.free()
