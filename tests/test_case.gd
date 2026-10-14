## Base class for test suites, with small assertion helpers.
extends RefCounted

var runner


func check(condition: bool, message: String) -> void:
	if not condition:
		runner.fail(message)


func check_eq(actual, expected, message: String = "") -> void:
	if actual != expected:
		runner.fail("%s expected %s, got %s" % [message, str(expected), str(actual)])


func check_near(actual: float, expected: float, tolerance: float, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		runner.fail("%s expected %s +/- %s, got %s" % [message, expected, tolerance, actual])
