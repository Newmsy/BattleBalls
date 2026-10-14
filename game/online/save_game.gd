## The player's save: kept on the device (user://, IndexedDB on the web) and
## mirrored to the cloud when signed in.
##
## Every local change bumps `rev`. Syncing keeps whichever copy has the higher
## rev; the server's push_save refuses older revs, so a stale device never
## overwrites newer progress.
extends RefCounted

const PATH := "user://save.json"
const FORMAT := 1
const AIM_HISTORY := 12 ## Launch angles kept for the Ghost Arena AI.

var rev := 0
var data := {}
var path := PATH
var app_version := "" ## Stored with cloud pushes, for support and migrations.


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


func load_local() -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary and parsed.get("data") is Dictionary:
		rev = int(parsed.get("rev", 0))
		data = upgrade(parsed.data)


func save_local() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"rev": rev, "data": data}))


## Call after changing `data`: bumps the revision and writes to disk.
func commit() -> void:
	rev += 1
	save_local()


## Fills in keys added since the save was written (old saves, older clients).
static func upgrade(d: Dictionary) -> Dictionary:
	var out := defaults()
	for k in d:
		if out.get(k) is Dictionary and d[k] is Dictionary:
			out[k].merge(d[k], true)
		else:
			out[k] = d[k]
	return out


## Adopts the cloud copy if it is newer. Returns true when local data changed.
func adopt_if_newer(cloud_rev: int, cloud_data) -> bool:
	if cloud_rev <= rev or not cloud_data is Dictionary:
		return false
	rev = cloud_rev
	data = upgrade(cloud_data)
	save_local()
	return true


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


## Pulls the cloud save, then pushes ours if it is newer. Returns true when
## the local data changed (the caller should refresh what it shows).
func sync(backend) -> bool:
	if not await backend.ensure_session():
		return false
	var got: Dictionary = await backend.rest("GET", "/rest/v1/saves?select=rev,data&user_id=eq." + backend.user_id())
	if not got.ok:
		return false
	var changed := false
	if got.data is Array and not got.data.is_empty():
		changed = adopt_if_newer(int(got.data[0].rev), got.data[0].data)
		if int(got.data[0].rev) >= rev:
			return changed
	if rev == 0:
		return changed # Nothing played yet: nothing worth storing.
	return await push(backend) or changed


## Pushes the local save. The server answers with whatever copy it kept.
func push(backend) -> bool:
	var res: Dictionary = await backend.call_rpc("push_save", {"p_rev": rev, "p_data": data, "p_app_version": app_version})
	if res.ok and res.data is Dictionary:
		return adopt_if_newer(int(res.data.get("rev", 0)), res.data.get("data"))
	return false
