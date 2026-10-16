## A short fingerprint of the fight rules: a hash of every script in sim/.
## Two builds with the same sim_version play every fight identically, so live
## matches only pair players on the same one. Exported builds can't read their
## own source (scripts ship compiled), so the export writes it to
## res://sim_version.txt (tools/sim_version.gd) and builds read that.
extends RefCounted

const FILE := "res://sim_version.txt"

static var _cached := ""


static func get_version() -> String:
	if _cached == "":
		_cached = from_source()
		if _cached == "" and FileAccess.file_exists(FILE):
			_cached = FileAccess.get_file_as_string(FILE).strip_edges()
	return _cached


## Hash of sim/**/*.gd in path order, or "" where the source isn't readable
## (exported builds). Works in the editor, headless tools and the live server.
static func from_source() -> String:
	var files: Array[String] = []
	var dirs := ["res://sim"]
	while not dirs.is_empty():
		var d: String = dirs.pop_back()
		for sub in DirAccess.get_directories_at(d):
			dirs.append(d + "/" + sub)
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				files.append(d + "/" + f)
	if files.is_empty():
		return ""
	files.sort()
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	for path in files:
		ctx.update(path.to_utf8_buffer())
		ctx.update(FileAccess.get_file_as_bytes(path))
	return ctx.finish().hex_encode().substr(0, 12)
