## Critter Plunge race screen: your fighter and a CPU field drop down a
## marble run (sim/plunge.gd) and fight on the way; you watch. Opened from
## the Plunge screen in Versus (game/ui/screens/plunge_screen.gd), which has
## already spent the energy and left the race in CritterPlunge.pending. The result pops
## up on the shared ResultPopup with coins, XP and the Faction XP ring, paid
## into the game save here (meta/critter_plunge.gd).
## URL params: ?mode=plunge&seed=5&n=8 (a practice race: no rewards, nothing
## spent), &speed=2.
extends Node2D

const Plunge := preload("res://sim/plunge.gd")
const PlungeView := preload("res://game/plunge_view.gd")
const CritterPlunge := preload("res://meta/critter_plunge.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const Sfx := preload("res://game/audio/sfx.gd")
const Main := preload("res://game/main.gd")
const ResultPopup := preload("res://game/ui/result_popup.gd")
const FactionRing := preload("res://game/ui/faction_ring.gd")
const FightSpeed := preload("res://game/fight_speed.gd")
const FightLayout := preload("res://game/fight_layout.gd")
const TouchInput := preload("res://game/ui/touch_input.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const SaveGame := preload("res://game/online/save_game.gd")
const Profile := preload("res://meta/profile.gd")

const SKIP_TICKS := 360 ## Ticks a frame while skipping: fast, never a frozen frame.
const TITLE_H := 64.0

var sim: Plunge
var fighter := ""
var practice := false
var speed := -1.0 ## A ?speed= override, else the Speed pill's pick.
var game_save_path := SaveGame.PATH ## Tests point this elsewhere.
var result := {} ## What finish() paid, once the race is over.

var _accumulator := 0.0
var _skipping := false
var _done := false
var view: PlungeView
var frame: Control
var sfx: Sfx
var ui_root: Control
var title: Label
var _skip: Control
var _speed: Control


func _ready() -> void:
	if view != null:
		return # Tests may start the scene by hand before the tree does.
	TouchInput.ensure(self)
	TouchInput.set_back(self, func(): return _back if _done else Callable())
	var params := _url_params()
	var cfg: Dictionary = CritterPlunge.pending.get("cfg", {})
	fighter = str(CritterPlunge.pending.get("fighter", ""))
	CritterPlunge.pending = {}
	if cfg.is_empty():
		practice = true
		var n := int(params.get("n", "6")) if str(params.get("n", "")).is_valid_int() else 6
		n = n if Plunge.FIELD_SIZES.has(n) else 6
		var seed_value := int(params.seed) if str(params.get("seed", "")).is_valid_int() else randi_range(1, 0x7FFFFFFF)
		cfg = {"seed": seed_value, "racers": Plunge.draw_field(seed_value, n)}
		fighter = str(cfg.racers[0])
	if str(params.get("speed", "")).is_valid_float():
		speed = clampf(float(params.speed), 0.25, 8.0)
	sim = Plunge.new(cfg)
	sfx = Sfx.new()
	add_child(sfx)
	frame = Control.new()
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	view = PlungeView.new()
	frame.add_child(view)
	view.set_sim(sim, -1 if practice else 0)
	_build_ui()
	if is_inside_tree():
		get_viewport().size_changed.connect(_layout)
	_layout()
	sfx.play("go")
	sfx.play_music("fight")
	print("PLUNGE_READY seed=%d n=%d practice=%s racers=%s" % [int(cfg.seed), sim.racers.size(), practice, ",".join(cfg.racers)])


## The back-swipe table outlives the scene, so it must not keep a freed key.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		TouchInput.clear_back(self)


func _process(delta: float) -> void:
	if not _done:
		var rate := speed if speed > 0.0 else FightSpeed.current()
		if _skipping:
			for k in SKIP_TICKS:
				if sim.finished:
					break
				sim.step()
				view.consume_events(sim.events)
		else:
			_accumulator += delta * rate
			var steps := 0
			while _accumulator >= Plunge.DT and steps < 64 and not sim.finished:
				_accumulator -= Plunge.DT
				steps += 1
				sim.step()
				view.consume_events(sim.events)
				_sounds(sim.events)
		if sim.finished:
			_finish()
	view.advance(delta)


func _sounds(events: Array) -> void:
	for e in events:
		match e.type:
			"bumper":
				sfx.play("pinball_ding", -8.0, 1.2)
			"peg":
				sfx.play("wall", -6.0, 1.4)
			"bump":
				sfx.play("hit", -8.0, 1.1)
			"fire":
				sfx.play({"pulse": "nova_boom", "shot": "pew", "drop": "mine_drop", "hook": "reel", "shield": "shield_up"}.get(e.verb, "zap"), -4.0)
			"hit":
				if e.kind == "thorns":
					sfx.play("thorn_snap", -6.0)
				elif e.kind != "bump":
					sfx.play("hit", -4.0)
			"ko":
				sfx.play("ko")
			"finish":
				if e.place == 1:
					sfx.play("tada")


func _skip_race() -> void:
	_skipping = true


func _finish() -> void:
	_done = true
	var me: Plunge.Racer = sim.racers[0]
	var knocked := me.ko_tick >= 0
	var gains: Array = []
	if not practice:
		gains = _pay(me.place, knocked)
	print("PLUNGE_RESULT place=%d of %d ko=%s coins=%d" % [me.place, sim.racers.size(), knocked, int(result.get("coins", 0))])
	sfx.on_result(0 if me.place == 1 else (-1 if me.place <= sim.racers.size() / 2.0 else 1))
	_skip.visible = false
	_speed.visible = false
	sfx.toggle_hidden = true # The popup covers the bottom row of pills.
	sfx.hold_victory(ResultPopup.show_over(ui_root, _result_card(me, knocked, gains)))


## Pays the race into the game save; returns the Faction XP gains for the ring.
func _pay(place: int, knocked: bool) -> Array:
	var save := SaveGame.new(game_save_path)
	save.load_local()
	var d = save.data.get("profile", {})
	if not (d is Dictionary) or d.is_empty():
		return []
	var p = Profile.from_dict(d, int(Time.get_unix_time_from_system()))
	result = CritterPlunge.finish(p, fighter, place, sim.racers.size(), knocked)
	var gains: Array = p.take_faction_gains()
	save.data.profile = p.to_dict()
	save.commit()
	return gains


func _result_card(me: Plunge.Racer, knocked: bool, gains: Array) -> Control:
	var n := sim.racers.size()
	var outcome := ResultPopup.Outcome.WIN if me.place == 1 else (ResultPopup.Outcome.DRAW if me.place <= n / 2.0 and not knocked else ResultPopup.Outcome.LOSE)
	var words := "Knocked out" if knocked else ("1st!" if me.place == 1 else "%s of %d" % [_ordinal(me.place), n])
	var body: Array = [_podium()]
	if not result.is_empty():
		var rewards := Kit.hbox(28, [Kit.amount("coin", "+%d" % result.coins, 30), Kit.label("+%d XP" % result.xp, 26, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)
		body.append(rewards)
		ResultPopup.drop_in(rewards.get_children().map(func(c): return [c, null]), sfx, ResultPopup.SLIDE_SECS + .4)
	if not gains.is_empty():
		body.append(FactionRing.rows(gains, sfx))
	var back := Kit.button("Back", _back, "ghost", 26, 84)
	var again := Kit.button("Race again", _again, "go", 26, 84)
	back.name = "PlungeBack"
	again.name = "PlungeAgain"
	again.size_flags_stretch_ratio = 1.5
	_mark("plunge_back", back, 1.0)
	_mark("plunge_again", again, 1.0)
	return ResultPopup.content("Critter Plunge · %d racers" % n, outcome, body, [back, again], CritterIcon.make(fighter, 1, 72), words)


## The top three, faces and names, so you see who beat you.
func _podium() -> Control:
	var row := Kit.hbox(18, [], BoxContainer.ALIGNMENT_CENTER)
	for k in mini(3, sim.order.size()):
		var r: Plunge.Racer = sim.racers[sim.order[k]]
		if r.ko_tick >= 0:
			break
		var col := Kit.vbox(2, [CritterIcon.make(r.id, 1, 64), Kit.label(_ordinal(k + 1), 20, Color("ffd36b") if k == 0 else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER),
			Kit.label("You" if r.index == 0 and not practice else Roster.get_critter(r.id).name, 18, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)])
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		for c in col.get_children():
			c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		row.add_child(col)
	return row


static func _ordinal(k: int) -> String:
	return str(k) + (["th", "st", "nd", "rd"][k % 10] if k % 10 <= 3 and (k % 100) / 10 != 1 else "th")


## Another race with the same fighter and field size: spends the energy from
## the save, then reloads the scene with the new race.
func _again() -> void:
	if practice:
		get_tree().reload_current_scene()
		return
	var save := SaveGame.new(game_save_path)
	save.load_local()
	var d = save.data.get("profile", {})
	if not (d is Dictionary) or d.is_empty():
		_back()
		return
	var now := int(Time.get_unix_time_from_system())
	var p = Profile.from_dict(d, now)
	var cfg: Dictionary = CritterPlunge.start(p, fighter, sim.racers.size(), now)
	if cfg.has("error"):
		_back() # Out of energy: the Plunge screen says so and offers more.
		return
	save.data.profile = p.to_dict()
	save.commit()
	CritterPlunge.pending = {"cfg": cfg, "fighter": fighter}
	get_tree().reload_current_scene()


func _back() -> void:
	CritterPlunge.reopen = true
	get_tree().change_scene_to_file("res://game/main.tscn")


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = Main._neon_theme()
	layer.add_child(ui_root)
	title = Kit.label("CRITTER PLUNGE · %d RACERS" % sim.racers.size(), 26, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(title)
	# Speed, Skip and Sound: the bottom row of pills every fight screen has.
	_speed = FightSpeed.picker()
	ui_root.add_child(_speed)
	var skip := FightLayout.skip_pill(_skip_race, "PlungeSkip")
	_skip = skip
	ui_root.add_child(skip)
	_mark("plunge_skip", skip.button)


## The title, then the course down to just above the bottom pills, the full
## width (capped so a wide screen keeps a phone-shaped column).
func _layout() -> void:
	var size := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(720, 1280)
	var width := minf(size.x, 760.0)
	var x := (size.x - width) / 2.0
	title.position = Vector2(x, 10)
	title.size = Vector2(width, TITLE_H - 10)
	var bottom := size.y - FightLayout.PILL.y - FightLayout.PILL_MARGIN.y - 10.0
	frame.position = Vector2(x, TITLE_H)
	frame.size = Vector2(width, maxf(200.0, bottom - TITLE_H))
	view.view_size = frame.size
	view.view_scale = width / Plunge.WIDTH
	view.queue_redraw()


## Logs where a control is once it's laid out, for the smoke test ("UI_AT name x y").
func _mark(name: String, c: Control, wait := 0.0) -> void:
	if is_inside_tree():
		_mark_later.call_deferred(name, c, wait)


func _mark_later(name: String, c: Control, wait: float) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if wait > 0.0:
		await get_tree().create_timer(wait).timeout
	if is_instance_valid(c) and c.is_visible_in_tree():
		var at := c.get_global_rect().get_center()
		print("UI_AT %s %d %d" % [name, roundi(at.x), roundi(at.y)])


func _url_params() -> Dictionary:
	var params := {}
	if not OS.has_feature("web"):
		return params
	var query: String = str(JavaScriptBridge.eval("window.location.search", true))
	for pair in query.trim_prefix("?").split("&", false):
		var kv := pair.split("=")
		params[kv[0].uri_decode()] = kv[1].uri_decode() if kv.size() > 1 else ""
	return params
