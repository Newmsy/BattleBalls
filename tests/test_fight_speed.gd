extends "res://tests/test_case.gd"

const FightSpeed := preload("res://game/fight_speed.gd")


## Sets the speed state without touching user://settings.cfg.
func _state(level: int, pick: int, all := false) -> void:
	FightSpeed._loaded = true
	FightSpeed.account_level = level
	FightSpeed._pick = pick
	FightSpeed.unlock_all = all
	FightSpeed.url_speed = 0.0


func test_speeds_unlock_by_account_level() -> void:
	_state(1, 2)
	check_eq(FightSpeed.current(), 1.0, "level 1 plays at 1x whatever the pick")
	check(not FightSpeed.unlocked(1), "2x locked at level 4")
	check_eq(FightSpeed.label(1), "2x Lv5", "locked speed shows its level")
	_state(5, 2)
	check_eq(FightSpeed.current(), 2.0, "level 5 caps a 4x pick to 2x")
	check(not FightSpeed.unlocked(2), "4x locked at level 9")
	_state(10, 2)
	check_eq(FightSpeed.current(), 4.0, "level 10 plays the 4x pick")
	check_eq(FightSpeed.label(2), "4x", "unlocked speed shows plain")
	_state(1, 2, true)
	check_eq(FightSpeed.current(), 4.0, "Testing switch opens every speed")
	_state(1, 0)
	FightSpeed.url_speed = 4.0
	check_eq(FightSpeed.current(), 4.0, "?speed= plays as given")
	_state(1, 0)


func test_picker_dims_locked_speeds() -> void:
	_state(5, 1)
	var p := FightSpeed.picker()
	check_eq(p.get_child_count(), 3, "one button per speed")
	check(not p.get_child(0).disabled and not p.get_child(1).disabled, "1x and 2x open at level 5")
	check(p.get_child(2).disabled, "4x locked at level 5")
	p.free()
	_state(1, 0)
