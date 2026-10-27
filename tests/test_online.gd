extends "res://tests/test_case.gd"

const SaveGame := preload("res://game/online/save_game.gd")
const GhostLineup := preload("res://game/online/ghost_lineup.gd")
const Backend := preload("res://game/online/backend.gd")
const Account := preload("res://game/online/account.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Shell := preload("res://game/ui/shell.gd")

## Per process: tests/run.sh runs shards side by side.
var TEST_SAVE := "user://test_save_%d.json" % OS.get_process_id()


func _fresh_save() -> SaveGame:
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	return SaveGame.new(TEST_SAVE)


func test_save_round_trips_and_marks_unsynced() -> void:
	var s := _fresh_save()
	s.record_fight(0, -30)
	s.record_fight(1, 15)
	var t := SaveGame.new(TEST_SAVE)
	t.load_local()
	check(t.dirty, "unsynced until pushed")
	check_eq(t.base_rev, 0, "never in the cloud")
	check_eq(int(t.data.stats.wins), 1, "wins")
	check_eq(int(t.data.stats.losses), 1, "losses")
	check_eq(t.data.aim_offsets.map(func(a): return int(a)), [-30, 15], "aim history")


func test_format_1_saves_load() -> void:
	var f := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify({"rev": 3, "data": {"stats": {"fights": 3, "wins": 2}}}))
	f.close()
	var s := SaveGame.new(TEST_SAVE)
	s.load_local()
	check(s.dirty, "old local progress still goes up")
	check_eq(s.base_rev, 0, "old device counter isn't a cloud revision")
	check_eq(int(s.data.stats.wins), 2, "data kept")


func test_aim_history_is_capped() -> void:
	var s := _fresh_save()
	for i in SaveGame.AIM_HISTORY + 5:
		s.record_fight(-1, i)
	check_eq(s.data.aim_offsets.size(), SaveGame.AIM_HISTORY, "capped")
	check_eq(int(s.data.aim_offsets[-1]), SaveGame.AIM_HISTORY + 4, "keeps the newest")


## Stands in for Supabase: one user's cloud save with sync_save's rules.
class FakeCloud:
	var me := "user-a"
	var online := true
	var rev := 0
	var data = null
	var pushes := 0

	func ensure_session() -> bool:
		return online

	func user_id() -> String:
		return me

	func rest(_method: String, _path: String, _body = null) -> Dictionary:
		if not online:
			return {"ok": false, "code": 0, "data": null}
		return {"ok": true, "code": 200, "data": [] if rev == 0 else [{"rev": rev, "data": data.duplicate(true)}]}

	func call_rpc(_name: String, args: Dictionary) -> Dictionary:
		if not online:
			return {"ok": false, "code": 0, "data": null}
		pushes += 1
		if int(args.p_base_rev) != rev:
			return {"ok": true, "code": 200, "data": {"saved": false, "rev": rev, "data": data}}
		rev += 1
		data = JSON.parse_string(JSON.stringify(args.p_data))
		return {"ok": true, "code": 200, "data": {"saved": true, "rev": rev}}


func _played(fights: int) -> SaveGame:
	var s := _fresh_save()
	for i in fights:
		s.record_fight(0, 0)
	return s


func test_offline_changes_wait_then_go_up() -> void:
	var cloud := FakeCloud.new()
	cloud.online = false
	var s := _played(2)
	s.sync(cloud)
	check(s.dirty, "still unsynced offline")
	cloud.online = true
	s.sync(cloud)
	check(not s.dirty, "pushed once back online")
	check_eq(cloud.rev, 1, "cloud revision")
	check_eq(int(cloud.data.stats.fights), 2, "cloud has the fights")
	s.record_fight(1, 0)
	s.sync(cloud)
	check_eq([cloud.rev, s.base_rev], [2, 2], "next push builds on the last")


func test_newer_cloud_save_comes_down() -> void:
	var cloud := FakeCloud.new()
	var s := _played(1)
	s.sync(cloud)
	cloud.rev = 7
	cloud.data = {"stats": {"fights": 9, "wins": 9}}
	s.sync(cloud)
	check_eq(s.base_rev, 7, "follows the cloud")
	check_eq(int(s.data.stats.wins), 9, "cloud data")
	check(not s.dirty, "clean")


func test_conflict_keeps_the_further_save_and_backs_up_the_other() -> void:
	var cloud := FakeCloud.new()
	var s := _played(1)
	s.sync(cloud)
	# Another device on this account plays a lot; this one plays a little.
	cloud.rev = 4
	cloud.data = {"stats": {"fights": 20, "wins": 15}}
	var backups := DirAccess.get_files_at(SaveGame.BACKUP_DIR).size() if DirAccess.dir_exists_absolute(SaveGame.BACKUP_DIR) else 0
	s.record_fight(0, 0)
	s.sync(cloud)
	check_eq(int(s.data.stats.fights), 20, "the further save wins")
	check_eq(s.base_rev, 4, "on the cloud revision")
	check(DirAccess.get_files_at(SaveGame.BACKUP_DIR).size() > backups or backups >= SaveGame.MAX_BACKUPS, "the other is backed up")

	# The reverse: this device is further along, so it overwrites on top.
	for i in 30:
		s.record_fight(0, 0)
	cloud.rev = 6
	cloud.data = {"stats": {"fights": 21}}
	s.sync(cloud)
	check_eq(int(cloud.data.stats.fights), 50, "local progress pushed over the cloud")
	check_eq(cloud.rev, 7, "as a new revision")
	check(not s.dirty, "clean")


func test_signing_in_takes_the_accounts_save() -> void:
	var cloud := FakeCloud.new()
	cloud.me = "guest"
	var s := _played(3)
	s.sync(cloud)
	check_eq(s.owner, "guest", "guest owns it")
	# Signs in on this device to an account that already has progress.
	cloud.me = "account"
	cloud.rev = 2
	cloud.data = {"stats": {"fights": 1}}
	s.sync(cloud)
	check_eq(s.owner, "account", "switched")
	check_eq(int(s.data.stats.fights), 1, "the account's save, not the guest's")
	s.reset_for_sign_out()
	check_eq([s.owner, s.base_rev, int(s.data.stats.fights)], ["", 0, 0], "signed out starts fresh")


func test_first_sync_into_an_empty_account_keeps_local_progress() -> void:
	var cloud := FakeCloud.new()
	var s := _played(4)
	s.sync(cloud)
	check_eq(s.owner, "user-a", "owned")
	check_eq(int(cloud.data.stats.fights), 4, "pushed")


const SIDE_FILE := "user://test_side.cfg"


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_side_files_ride_along_and_come_back() -> void:
	if FileAccess.file_exists(SIDE_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SIDE_FILE))
	var cloud := FakeCloud.new()
	var s := _fresh_save()
	s.mirrored = [SIDE_FILE]
	check(not s.capture_files(), "nothing to pick up yet")
	_write(SIDE_FILE, "[stats]\nbest=3\n")
	var edits := s.edits
	check(s.capture_files(), "a changed side file is noticed")
	check(s.dirty and s.edits > edits, "and committed")
	check(not s.capture_files(), "only once")
	s.sync(cloud)
	check_eq(str(cloud.data.files["test_side.cfg"]), "[stats]\nbest=3\n", "the cloud holds the file")

	# Another device improves the record; this one adopts it.
	var other: Dictionary = cloud.data.duplicate(true)
	other.files["test_side.cfg"] = "[stats]\nbest=9\n"
	cloud.rev += 1
	cloud.data = other
	s.sync(cloud)
	check_eq(FileAccess.get_file_as_string(SIDE_FILE), "[stats]\nbest=9\n", "written back to the device")
	check(not s.dirty, "and clean")

	# Older cloud saves without side files leave the device's file alone.
	cloud.rev += 1
	cloud.data = {"stats": {"fights": 1}}
	s.sync(cloud)
	check(FileAccess.file_exists(SIDE_FILE), "legacy cloud copy keeps the file")
	s.reset_for_sign_out()
	check(not FileAccess.file_exists(SIDE_FILE), "signing out clears side files")


func test_devices_share_the_test_account() -> void:
	var cloud := FakeCloud.new()
	cloud.me = "test-account"
	var phone := _played(3)
	phone.owner = "guest-phone"
	phone.base_rev = 1
	phone.dirty = false
	phone.test_mode = true
	phone.sync(cloud)
	check_eq(phone.owner, "test-account", "the phone moves onto the test account")
	check_eq(int(cloud.data.stats.fights), 3, "and fills its empty save")

	# A laptop that played less as its own guest joins and takes the account's save.
	var laptop := SaveGame.new("user://test_save_laptop.json")
	laptop.record_fight(0, 0)
	laptop.owner = "guest-laptop"
	laptop.base_rev = 2
	laptop.dirty = false
	laptop.test_mode = true
	laptop.sync(cloud)
	check_eq(int(laptop.data.stats.fights), 3, "the account's progress comes down")
	check_eq([laptop.owner, laptop.base_rev], ["test-account", cloud.rev], "now on the account")

	laptop.record_fight(0, 0)
	laptop.sync(cloud)
	phone.sync(cloud)
	check_eq(int(phone.data.stats.fights), 4, "the phone sees the laptop's fight")


func test_joining_the_test_account_keeps_the_further_device() -> void:
	var cloud := FakeCloud.new()
	cloud.me = "test-account"
	cloud.rev = 3
	cloud.data = {"stats": {"fights": 2}}
	var s := _played(10)
	s.owner = "test:1" # Synced with the old shared test slot (PR #59).
	s.base_rev = 5
	s.dirty = false
	s.test_mode = true
	s.sync(cloud)
	check_eq(int(cloud.data.stats.fights), 10, "the further device fills the account")
	check_eq(cloud.rev, 4, "on top of the account's revision")


func test_old_saves_gain_new_keys() -> void:
	var up := SaveGame.upgrade({"stats": {"wins": 4}})
	check_eq(int(up.stats.wins), 4, "kept value")
	check_eq(int(up.stats.fights), 0, "filled nested default")
	check(up.has("aim_offsets") and up.has("picks"), "filled top-level defaults")


func test_lineup_shape() -> void:
	var l := GhostLineup.make(["vampire", "laser", "vampire", "laser"], range(20))
	check_eq(l.v, 1, "version")
	check_eq(l.rules, MatchSim.RULES_VERSION, "rules")
	check_eq(l.slots.size(), GhostLineup.MAX_SLOTS, "slots capped")
	check_eq(l.slots[0], {"critter": "vampire", "tier": 1, "level": 1, "gear": []}, "slot")
	check_eq(l.aim.size(), GhostLineup.MAX_AIM, "aim capped")
	check_eq(int(l.aim[-1]), 19, "newest aims kept")
	check(GhostLineup.is_playable(l), "own lineup is playable")
	# Survives a JSON round trip (numbers come back as floats).
	check(GhostLineup.is_playable(JSON.parse_string(JSON.stringify(l))), "playable after JSON")


func test_unplayable_lineups_are_rejected() -> void:
	var good := GhostLineup.make(["laser"], [])
	var other_rules := good.duplicate(true)
	other_rules.rules = MatchSim.RULES_VERSION + 1
	var unknown := good.duplicate(true)
	unknown.slots[0].critter = "not-a-critter"
	var empty := good.duplicate(true)
	empty.slots = []
	for bad in [null, {}, other_rules, unknown, empty]:
		check(not GhostLineup.is_playable(bad), "rejects %s" % str(bad))


func test_ghost_aim_is_deterministic_and_mirrored() -> void:
	var l := GhostLineup.make(["laser"], [-100, 0, 250])
	check_eq(GhostLineup.ghost_angle(l, 7), GhostLineup.ghost_angle(l, 7), "same seed, same aim")
	check_eq(GhostLineup.ghost_angle(l, 2), MatchSim.AIM_AT_CENTRE[1] + 250, "seed picks a habit")
	check_eq(GhostLineup.ghost_angle(GhostLineup.make(["laser"], []), 5), MatchSim.AIM_AT_CENTRE[1], "no habits: centre")
	check_eq(GhostLineup.aim_offset(MatchSim.AIM_AT_CENTRE[0] + 40), 40, "offset")
	check_eq(GhostLineup.aim_offset(MatchSim.AIM_AT_CENTRE[0] + 3590), -10, "offset wraps")


func test_session_from_a_redirect() -> void:
	var p := Backend.parse_fragment("access_token=a.b.c&refresh_token=r%2B1&type=magiclink&error_description=Email+link+is+invalid")
	check_eq(p.refresh_token, "r+1", "decoded")
	check_eq(p.type, "magiclink", "type")
	var body := Marshalls.utf8_to_base64(JSON.stringify({"sub": "abc-123", "is_anonymous": false})).replace("+", "-").replace("/", "_").trim_suffix("=").trim_suffix("=")
	check_eq(Backend.jwt_claims("x.%s.y" % body).get("sub"), "abc-123", "claims")
	check_eq(Backend.jwt_claims("nope"), {}, "not a token")


func test_email_check() -> void:
	for good in ["a@b.co", "  sam.lee+bb@mail.example.org "]:
		check(Account.valid_email(good), good)
	for bad in ["", "a@b", "@b.co", "a b@c.co", "a@b.", "a@.co"]:
		check(not Account.valid_email(bad), bad)


func test_name_check_matches_the_server() -> void:
	check_eq(Account.clean_name("  Bouncy   Bob "), "Bouncy Bob", "trims and collapses spaces")
	var cases := {"Bo": "too_short", "Seventeen letters": "too_long", "Bob!": "bad_chars", "1234": "no_letters",
		"Sh1t Ball": "rude", "f.u.c.k": "rude", "Big Ass": "rude", "Classy Glass": "", "Peacock Dickens": "",
		"Mo_the-Ball.2": "", "Bouncy Bob": ""}
	for n in cases:
		check_eq(Account.name_problem(n), cases[n], n)
	check_eq(Account.check_name("  ok  "), Account.explain_name("too_short"), "checks the cleaned name")
	# The client's word lists are a copy of the server's (tests/db/test_rename.sql runs the same cases).
	var sql := ""
	for f in DirAccess.get_files_at("res://supabase/migrations"):
		if f.ends_with("_rename.sql"):
			sql = FileAccess.get_file_as_string("res://supabase/migrations/" + f)
	check(sql != "", "migration found")
	for w in Account.RUDE_PARTS + Account.RUDE_WORDS:
		check("'%s'" % w in sql, "server has " + w)


func test_account_screen_shows_the_name() -> void:
	var b := Backend.new()
	b.url = "https://example.invalid"
	b.key = "sb_publishable_test"
	var acc := Account.new(b)
	acc.status = "guest"
	acc.display_name = "Bouncy Bob"
	var shell = Shell.new()
	shell.build()
	shell.set_account(acc)
	shell.go("account")
	check_eq(shell.current, "account", "account screen")
	var found := shell.find_children("*", "Label", true, false).any(func(l): return l.text == "Bouncy Bob")
	check(found, "name shown")
	shell.free()
	b.free()


func test_backend_is_offline_without_config() -> void:
	var b := Backend.new()
	if not FileAccess.file_exists(Backend.CONFIG_PATH):
		check(not b.enabled(), "no config, no backend")
	b.url = "https://example.supabase.co"
	b.key = "anon"
	check(b.enabled(), "configured")
	b.disabled = true
	check(not b.enabled(), "?offline=1 wins")
	b.free()
