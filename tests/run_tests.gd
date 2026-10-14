## Minimal headless test runner. Runs every `test_*` method in every
## `tests/test_*.gd` file and exits non-zero on any failure.
## Usage: godot --headless --script res://tests/run_tests.gd
extends SceneTree

var _failures: Array[String] = []
var _current := ""


func _init() -> void:
	var passed := 0
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
