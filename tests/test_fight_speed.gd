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


func test_speed_pill_cycles_unlocked_speeds() -> void:
	_state(5, 0)
	check_eq(FightSpeed.next_index(), 1, "1x cycles to 2x at level 5")
	_state(5, 1)
	check_eq(FightSpeed.next_index(), 0, "2x wraps to 1x while 4x is locked")
	_state(10, 2)
	check_eq(FightSpeed.next_index(), 0, "4x wraps to 1x")
	_state(1, 0)
	check_eq(FightSpeed.next_index(), 0, "nothing to cycle to at level 1")
	_state(5, 0)
	var p := FightSpeed.picker()
	check_eq(p.get_node("SpeedPill").text, "Speed: 1x", "pill shows the speed")
	FightSpeed._pick = 1 # Tapping saves the pick; set it directly to keep settings.cfg untouched.
	p.refresh()
	check_eq(p.get_node("SpeedPill").text, "Speed: 2x", "pill follows the pick")
	_state(1, 0)
	p.refresh()
	check(p.get_node("SpeedPill").modulate.a < 1.0, "pill dimmed with nothing unlocked")
	p.free()
	_state(1, 0)


## The pick follows the player between devices through the save: select()
## reports it, restore() takes another device's without reporting it back.
func test_pick_travels_with_the_save() -> void:
	var before := FileAccess.get_file_as_string(FightSpeed.SETTINGS_PATH) if FileAccess.file_exists(FightSpeed.SETTINGS_PATH) else ""
	var reported: Array = []
	FightSpeed.on_pick = func(i: int): reported.append(i)
	_state(10, 0)
	FightSpeed.select(2)
	check_eq(reported, [2], "picking a speed reports it for the save")
	FightSpeed.restore(1)
	check_eq(FightSpeed.pick(), 1, "another device's pick is taken")
	check_eq(reported, [2], "and not reported back")
	FightSpeed.restore(7)
	check_eq(FightSpeed.pick(), 1, "an unknown pick is ignored")
	_state(1, 2)
	check_eq(FightSpeed.pick(), 2, "the pick is kept while its speed is locked")
	# Another fight scene (Spire, relays, Bounce Run) has no main.gd to report to:
	# the pick waits as unsaved, so main.gd saves it instead of the save's older one.
	FightSpeed.on_pick = Callable()
	FightSpeed.unsaved = false
	_state(10, 0)
	FightSpeed.select(1)
	check(FightSpeed.unsaved, "a pick nobody saved is marked unsaved")
	FightSpeed.unsaved = false
	_state(1, 0)
	if before == "":
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FightSpeed.SETTINGS_PATH))
	else:
		var f := FileAccess.open(FightSpeed.SETTINGS_PATH, FileAccess.WRITE)
		f.store_string(before)
