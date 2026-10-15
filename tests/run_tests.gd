## Minimal headless test runner. Runs every `test_*` method in every
## `tests/test_*.gd` file and exits non-zero on any failure.
## Usage: godot --headless --script res://tests/run_tests.gd [-- --shard=k/n]
##   --shard=k/n  run only every n-th test, starting at the k-th (tests/run.sh
##                runs one shard per CPU core and checks them all)
extends SceneTree

## The slowest tests (each fights the whole roster), spread one per shard
## before the rest are dealt round-robin, so no shard gets two.
const SLOW := ["test_mirror_matches_rarely_draw", "test_every_critter_finishes_on_every_arena",
	"test_every_critter_always_finishes"]

var _failures: Array[String] = []
var _current := ""


func _init() -> void:
	var passed := 0
	var shard := [1, 1]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shard="):
			var parts := arg.split("=")[1].split("/")
			shard = [int(parts[0]), int(parts[1])]
	var index := -1
	var files := DirAccess.get_files_at("res://tests")
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var script = load("res://tests/" + file)
		if script == null:
			_failures.append("%s: failed to load (parse error?)" % file)
			continue
		var suite = script.new()
		suite.runner = self
		for m in suite.get_method_list():
			var name: String = m.name
			if not name.begins_with("test_"):
				continue
			var slot: int = SLOW.find(name)
			if slot < 0:
				index += 1
				slot = SLOW.size() + index
			if slot % shard[1] != shard[0] - 1:
				continue
			_current = "%s::%s" % [file, name]
			var before := _failures.size()
			suite.call(name)
			if _failures.size() == before:
				passed += 1
				print("  ok   ", _current)
			else:
				print("  FAIL ", _current)
	print("")
	if _failures.is_empty():
		print("All %d tests passed." % passed)
		quit(0)
	else:
		for f in _failures:
			printerr(f)
		print("%d passed, %d failed." % [passed, _failures.size()])
		quit(1)


func fail(message: String) -> void:
	_failures.append("%s: %s" % [_current, message])
