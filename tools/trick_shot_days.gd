## Builds the coming days' 2-star and 3-star Trick Shots (sim/trick_shot.gd)
## and writes them to TrickShot.BUNDLED, which the export bundles: they're
## judged with the real sim, a few seconds each here and far longer on a
## phone. The puzzles are exactly what the device would build itself; a day
## the file lacks is built on the device. Run by tools/ci/export_web.sh.
##   godot --headless --script res://tools/trick_shot_days.gd -- [--days=14] [--shard=1/4]
##   godot --headless --script res://tools/trick_shot_days.gd -- --merge=4
## A shard writes its days to BUNDLED.<k>; --merge=<n> joins the n parts.
extends SceneTree

const TrickShot := preload("res://sim/trick_shot.gd")

const BEHIND := 2 ## Days kept before today (time zones, a late build).


func _init() -> void:
	var days := 14
	var shard := [1, 1]
	var merge := 0
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		match kv[0]:
			"days": days = int(kv[1])
			"shard": shard = Array(kv[1].split("/")).map(func(v): return int(v))
			"merge": merge = int(kv[1])
	if merge > 0:
		var out := {}
		for k in range(1, merge + 1):
			var part := "%s.%d" % [TrickShot.BUNDLED, k]
			if FileAccess.file_exists(part):
				var d = JSON.parse_string(FileAccess.get_file_as_string(part))
				if d is Dictionary:
					out.merge(d)
				DirAccess.remove_absolute(ProjectSettings.globalize_path(part))
		_write(TrickShot.BUNDLED, out)
		print("Trick Shot days: %d puzzles bundled" % out.size())
		quit(0)
		return
	var today := TrickShot.day_number(Time.get_date_dict_from_system())
	var out := {}
	for day in range(maxi(1, today - BEHIND), today + days + 1):
		if day % shard[1] != shard[0] - 1:
			continue
		for level in range(2, TrickShot.LEVELS + 1):
			var t0 := Time.get_ticks_msec()
			var p := TrickShot.generate(day, "", level)
			if p.is_empty():
				print("day %d level %d: no puzzle" % [day, level])
				continue
			out["%d-%d" % [day, level]] = TrickShot.to_json(p)
			print("day %d level %d: %s %d solutions (%d ms)" % [day, level, p.get("arena", p.p1), p.solutions.size(), Time.get_ticks_msec() - t0])
	_write(TrickShot.BUNDLED if shard[1] == 1 else "%s.%d" % [TrickShot.BUNDLED, shard[0]], out)
	quit(0)


func _write(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
