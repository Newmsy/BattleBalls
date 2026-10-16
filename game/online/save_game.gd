## The player's save: kept on the device (user://, IndexedDB on the web) and
## mirrored to the cloud when online.
##
## Sync is compare-and-swap (supabase/migrations/*_save_sync.sql). `base_rev`
## is the cloud revision the local data grew from and `dirty` marks local
## changes not in the cloud yet. A push only lands if the cloud is still at
## base_rev; the server numbers revisions, so devices never need to agree on
## a counter. When another device got there first, the copy with more
## progress wins and the other goes to a backup file: nothing is thrown away.
##
## Offline, changes just stay dirty on the device and go up on the next sync
## (main.gd syncs on start, on any change, on resume and on a retry timer).
##
## Older features keep their own files next to save.json (MIRRORED). Their
## text rides along in data.files, so the cloud holds the whole game, and
## adopting a cloud copy writes them back. The fight speed pick is in
## data.settings (main.gd); other device settings (sound, accessibility),
## the sign-in session and caches stay on the device.
##
## In test mode (game/online/test_user.gd) every device signs in to one test
## account, so they all share its cloud save; the sync rules are the same.
extends RefCounted

## Local or cloud data changed (adopted a newer copy, switched account):
## whatever shows save data should redraw.
signal changed

const PATH := "user://save.json"
const FORMAT := 2
const AIM_HISTORY := 12 ## Launch angles kept for the Ghost Arena AI.
const BACKUP_DIR := "user://save_backups"
const MAX_BACKUPS := 8
const MIRRORED := [
	"user://ghost_arena.cfg", # game/pvp/arena_store.gd
	"user://spire.json", # meta/spire_climb.gd
	"user://bounce_run.cfg", # game/bounce_run.gd
	"user://trick_shot.cfg", # game/trick_shot.gd
	"user://this_week.cfg", # game/ui/screens/week_screen.gd (Fight of the Day)
	"user://legends.cfg", # game/legends.gd
	"user://onboarding.cfg", # game/onboarding.gd
]

var data := {}
var base_rev := 0 ## Cloud revision `data` is based on (0: never in the cloud).
var dirty := false ## Changed since base_rev.
var owner := "" ## Account base_rev belongs to ("" until the first sync).
var path := PATH
var app_version := "" ## Stored with cloud pushes, for support and migrations.
var mirrored: Array = [] ## Side files carried in data.files (main.gd sets MIRRORED).
var test_mode := false ## Devices joining the shared test account: the further one wins.
var edits := 0 ## Counts commits, so main.gd can sync as soon as something changes.

var _syncing := false
var _sync_again := false


func _init(file_path := PATH) -> void:
	path = file_path
	data = defaults()


static func defaults() -> Dictionary:
	return {
		"format": FORMAT,
		"picks": {"player": "vampire", "opponent": "random", "speed": 0},
		"stats": {"fights": 0, "wins": 0, "losses": 0, "draws": 0},
		"aim_offsets": [], ## Recent launches, tenths of a degree off the centre line.
		"published_lineup": "", ## JSON of the last Ghost Arena lineup sent, to skip repeats.
	}


## How far along a save is, to pick a winner when two devices disagree.
## Grows with progression (account level, critters) as those get saved.
static func progress(d) -> int:
	if not d is Dictionary:
		return -1
	var stats = d.get("stats", {})
	var n := int(stats.get("fights", 0)) if stats is Dictionary else 0
	var profile = d.get("profile", {})
	if profile is Dictionary:
		n += int(profile.get("runs", 0)) # Campaign runs (meta/profile.gd).
	# Glow Gems, cosmetics and pass progress (game/glow): every grant or
	# spend is a ledger line, so a purchase alone still counts as progress.
	var glow = d.get("glow", {})
	if glow is Dictionary and glow.get("ledger") is Array:
		n += glow.ledger.size()
	# Side files (data.files) grow a line per day played, record or run.
	var files = d.get("files", {})
	if files is Dictionary:
		for text in files.values():
			n += str(text).count("\n")
	return n


func load_local() -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary and parsed.get("data") is Dictionary):
		return
	data = upgrade(parsed.data)
	if parsed.has("base_rev"):
		base_rev = int(parsed.base_rev)
		dirty = bool(parsed.get("dirty", false))
		owner = str(parsed.get("owner", ""))
	else:
		# Format 1 kept a device counter (`rev`); anything played is unsynced.
		base_rev = 0
		dirty = int(parsed.get("rev", 0)) > 0
		owner = ""


func save_local() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"base_rev": base_rev, "dirty": dirty, "owner": owner, "data": data}))


## Call after changing `data`: marks it unsynced and writes to disk.
func commit() -> void:
	dirty = true
	edits += 1
	save_local()


## Picks up changes the older features wrote to their own files. Cheap enough
## to call every few seconds; returns true (and commits) when any changed.
func capture_files() -> bool:
	if mirrored.is_empty():
		return false
	var files: Dictionary = data.files.duplicate() if data.get("files") is Dictionary else {}
	var any := false
	for p in mirrored:
		var name: String = p.get_file()
		var text := FileAccess.get_file_as_string(p) if FileAccess.file_exists(p) else ""
		if str(files.get(name, "")) == text:
			continue
		any = true
		if text == "":
			files.erase(name)
		else:
			files[name] = text
	if any:
		data["files"] = files
		commit()
	return any


## Writes a cloud copy's side files to the device. Saves from before side
## files were mirrored have no "files" and leave the device's files alone.
func _restore_files(d: Dictionary) -> void:
	if not d.get("files") is Dictionary:
		return
	for p in mirrored:
		var text := str(d.files.get(p.get_file(), ""))
		if text != "":
			var f := FileAccess.open(p, FileAccess.WRITE)
			if f != null:
				f.store_string(text)
		elif FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


## Fills in keys added since the save was written (old saves, older clients).
static func upgrade(d: Dictionary) -> Dictionary:
	var out := defaults()
	for k in d:
		if out.get(k) is Dictionary and d[k] is Dictionary:
			out[k].merge(d[k], true)
		else:
			out[k] = d[k]
	out.format = FORMAT
	return out


func record_fight(winner: int, aim_offset: int) -> void:
	var stats: Dictionary = data.stats
	stats.fights = int(stats.fights) + 1
	var outcome := "draws"
	if winner == 0:
		outcome = "wins"
	elif winner == 1:
		outcome = "losses"
	stats[outcome] = int(stats[outcome]) + 1
	var aims: Array = data.aim_offsets
	aims.append(aim_offset)
	while aims.size() > AIM_HISTORY:
		aims.pop_front()
	commit()


## Copies the current data to a backup file (newest MAX_BACKUPS kept).
func backup(reason: String, d = null) -> void:
	if d == null:
		d = data
	DirAccess.make_dir_recursive_absolute(BACKUP_DIR)
	var name := "%s/%d-%s.json" % [BACKUP_DIR, int(Time.get_unix_time_from_system() * 1000.0), reason]
	var f := FileAccess.open(name, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"reason": reason, "owner": owner, "base_rev": base_rev, "data": d}))
	var files := Array(DirAccess.get_files_at(BACKUP_DIR))
	files.sort()
	while files.size() > MAX_BACKUPS:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP_DIR + "/" + files.pop_front()))


## Replaces local data with a cloud copy.
func adopt(rev: int, d: Dictionary, account: String) -> void:
	_restore_files(d)
	data = upgrade(d)
	base_rev = rev
	dirty = false
	owner = account
	save_local()
	changed.emit()


## Signing out: keep a backup, then start this device fresh (the account's
## progress stays in the cloud for the next sign-in).
func reset_for_sign_out() -> void:
	capture_files()
	if progress(data) > 0:
		backup("signed-out")
	for p in mirrored:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	data = defaults()
	base_rev = 0
	dirty = false
	owner = ""
	save_local()
	changed.emit()


## Brings the device and the cloud in step. Safe to call often and from
## several places: overlapping calls fold into one extra pass.
func sync(backend) -> void:
	if _syncing:
		_sync_again = true
		return
	_syncing = true
	_sync_again = true
	capture_files()
	var passes := 0
	while _sync_again and passes < 4:
		_sync_again = false
		passes += 1
		await _sync_once(backend)
	_syncing = false


func _sync_once(backend) -> void:
	if not await backend.ensure_session():
		return
	var me: String = backend.user_id()
	if owner != me:
		await _join_account(backend, me)
	elif dirty:
		await _push(backend, me)
	else:
		var cloud := await _fetch(backend, me)
		if cloud.is_empty():
			return
		if cloud.rev > base_rev:
			adopt(cloud.rev, cloud.data, me)
		elif cloud.rev == 0 and base_rev > 0:
			# The cloud lost our save (project reset): put it back.
			base_rev = 0
			dirty = true
			await _push(backend, me)


## First sync with this account on this device: the account's cloud save and
## the local one may both hold progress.
func _join_account(backend, me: String) -> void:
	var cloud := await _fetch(backend, me)
	if cloud.is_empty():
		return
	if cloud.rev == 0:
		# A fresh account (a new guest, or a sign-in with nothing saved yet):
		# it takes this device's progress.
		owner = me
		base_rev = 0
		dirty = dirty or progress(data) > 0
		save_local()
		if dirty:
			await _push(backend, me)
		return
	if (owner == "" or test_mode) and progress(data) > progress(cloud.data):
		# Never synced from this device (or joining the shared test account),
		# and it is further along.
		backup("cloud-replaced", cloud.data)
		owner = me
		base_rev = cloud.rev
		dirty = true
		save_local()
		await _push(backend, me)
		return
	# The account's save wins (signing in on a device someone played as a guest).
	if progress(data) > 0 and (dirty or test_mode):
		backup("before-sign-in")
	adopt(cloud.rev, cloud.data, me)


func _push(backend, me: String) -> void:
	var res: Dictionary = await backend.call_rpc("sync_save", {"p_base_rev": base_rev, "p_data": data, "p_app_version": app_version})
	if not (res.ok and res.data is Dictionary):
		return # Offline or a server hiccup: stay dirty and retry later.
	var r: Dictionary = res.data
	if r.get("saved", false):
		base_rev = int(r.rev)
		dirty = false
		owner = me
		save_local()
		return
	# Another device saved first.
	var cloud_data = r.get("data")
	if cloud_data is Dictionary and progress(cloud_data) >= progress(data):
		backup("conflict-lost")
		adopt(int(r.rev), cloud_data, me)
		return
	if cloud_data is Dictionary:
		backup("conflict-cloud", cloud_data)
	base_rev = int(r.rev)
	save_local()
	_sync_again = true # Push again on top of the cloud copy we just saw.


## The account's cloud save as {rev, data}, {rev: 0} when there is none, or
## {} when the call failed.
func _fetch(backend, me: String) -> Dictionary:
	var got: Dictionary = await backend.rest("GET", "/rest/v1/saves?select=rev,data&user_id=eq." + me)
	if not got.ok or not got.data is Array:
		return {}
	if got.data.is_empty():
		return {"rev": 0, "data": null}
	return {"rev": int(got.data[0].rev), "data": got.data[0].data}
