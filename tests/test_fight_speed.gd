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
	check_eq(FightSpeed.SPEEDS, [1.0, 2.0], "only 1x and 2x")
	_state(1, 1)
	check(FightSpeed.unlocked(1), "2x is open from level 1")
	check_eq(FightSpeed.current(), 2.0, "a new player plays the 2x pick")
	check_eq(FightSpeed.label(1), "2x", "unlocked speed shows plain")
	_state(10, 2)
	check_eq(FightSpeed.current(), 2.0, "an old 4x pick plays at 2x")
	_state(1, 1, true)
	check_eq(FightSpeed.current(), 2.0, "Testing switch opens every speed")
	_state(1, 0)
	FightSpeed.url_speed = 4.0
	check_eq(FightSpeed.current(), 4.0, "?speed= plays as given")
	_state(1, 0)


func test_speed_pill_cycles_unlocked_speeds() -> void:
	_state(5, 0)
	check_eq(FightSpeed.next_index(), 1, "1x cycles to 2x at level 5")
	_state(5, 1)
	check_eq(FightSpeed.next_index(), 0, "2x wraps to 1x")
	_state(10, 1)
	check_eq(FightSpeed.next_index(), 0, "no 4x after 2x at level 10")
	_state(1, 0)
	check_eq(FightSpeed.next_index(), 1, "1x cycles to 2x at level 1")
	_state(5, 0)
	var p := FightSpeed.picker()
	check_eq(p.get_node("SpeedPill").text, "Speed: 1x", "pill shows the speed")
	FightSpeed._pick = 1 # Tapping saves the pick; set it directly to keep settings.cfg untouched.
	p.refresh()
	check_eq(p.get_node("SpeedPill").text, "Speed: 2x", "pill follows the pick")
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
	check_eq(reported, [], "4x can't be picked any more")
	FightSpeed.select(1)
	check_eq(reported, [1], "picking a speed reports it for the save")
	FightSpeed.restore(0)
	check_eq(FightSpeed.pick(), 0, "another device's pick is taken")
	check_eq(reported, [1], "and not reported back")
	FightSpeed.restore(2)
	check_eq(FightSpeed.pick(), 1, "another device's old 4x pick comes back as 2x")
	FightSpeed.restore(-1)
	check_eq(FightSpeed.pick(), 1, "an unknown pick is ignored")
	_state(1, 1)
	check_eq(FightSpeed.pick(), 1, "the pick is kept while its speed is locked")
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
