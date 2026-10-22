extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Sfx := preload("res://game/audio/sfx.gd")


func _sfx() -> Sfx:
	var sfx := Sfx.new()
	runner.root.add_child(sfx)
	return sfx


func test_every_sound_and_music_track_loads() -> void:
	var sfx := _sfx()
	for name in sfx.sound_names():
		check(not sfx._variants[name].is_empty(), "no audio file for sound '%s'" % name)
	for track in Sfx.MUSIC:
		var path: String = Sfx.AUDIO_DIR + Sfx.MUSIC[track][0] + ".ogg"
		check(load(path) is AudioStreamOggVorbis, "music track missing: %s" % path)
	sfx.free()


## Sound only reads the sim: a fight with sound must end exactly like one without.
func test_sound_does_not_change_the_fight() -> void:
	var cfg := {"seed": 11, "p1": "vampire", "p2": "laser", "angles": [null, null]}
	var quiet := MatchSim.new(cfg)
	quiet.run_to_end()
	var sfx := _sfx()
	var loud := MatchSim.new(cfg)
	sfx.on_fight_start(loud)
	var events_seen := 0
	while not loud.finished:
		loud.step()
		events_seen += loud.events.size()
		sfx.consume_events(loud.events, loud)
		sfx._process(MatchSim.DT)
	sfx.on_result(loud.winner)
	check(events_seen > 0, "fight produced no events to play")
	check_eq(loud.state_hash(), quiet.state_hash(), "state hash with sound")
	sfx.free()


func test_caps_limit_simultaneous_copies_of_a_sound() -> void:
	var sfx := _sfx()
	sfx.mode = "all" ## Settings saved by other runs must not mute the test.
	for i in 10:
		sfx._clock += Sfx.RULES["hit"][1] + 0.001 ## Past the min gap, so only the cap can stop it.
		sfx.play("hit")
	var playing := sfx.playing_count("hit")
	check_eq(playing, Sfx.RULES["hit"][0], "copies of hit playing")
	sfx.free()


## Godot 4.3's web build drops the route to the speakers when buses are added
## at runtime, so every sound must stay on the Master bus.
func test_sounds_stay_on_the_master_bus() -> void:
	var buses_before := AudioServer.bus_count
	var sfx := _sfx()
	check_eq(AudioServer.bus_count, buses_before, "bus count after creating Sfx")
	for p in sfx._players:
		check_eq(p.bus, &"Master", "sound player bus")
	check_eq(sfx._music.bus, &"Master", "music player bus")
	check_eq(sfx._music_out.bus, &"Master", "fading music player bus")
	sfx.free()


## The intro plays once and hands over to the menu loop; a win plays the
## victory tune until its popup closes; overtime switches to the faster theme.
func test_music_flow() -> void:
	var sfx := _sfx()
	sfx.mode = "all"
	Sfx._intro_played = false
	Sfx._audio_unlocked = true
	sfx.on_menu()
	check_eq(sfx._music_track, "intro", "first menu music")
	sfx.on_menu()
	check_eq(sfx._music_track, "intro", "intro is not cut by another menu")
	sfx._on_music_finished(sfx._music)
	check_eq(sfx._music_track, "menu", "after the intro")
	var sim := MatchSim.new({"seed": 3, "p1": "vampire", "p2": "laser", "angles": [null, null]})
	sfx.on_fight_start(sim)
	check_eq(sfx._music_track, "fight", "fight music")
	sfx.on_result(0)
	check_eq(sfx._music_track, "victory", "after a win")
	var popup := Control.new()
	runner.root.add_child(popup)
	sfx.on_menu()
	sfx.hold_victory(popup)
	sfx._process(Sfx.VICTORY_GRACE + 0.1)
	check_eq(sfx._music_track, "victory", "victory while its popup is up")
	popup.free()
	sfx._process(0.1)
	check_eq(sfx._music_track, "menu", "menu once the popup closes")
	sfx.on_fight_start(sim)
	sfx.on_result(1)
	check_eq(sfx._music_track, "menu", "after a loss")
	sfx.on_result(0)
	sfx.on_menu()
	sfx._process(Sfx.VICTORY_GRACE + 0.1)
	check_eq(sfx._music_track, "menu", "menu after a win with no popup")
	sfx.free()
