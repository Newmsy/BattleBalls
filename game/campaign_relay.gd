## A pairs or trios campaign stage (zone 2 on): your team against the stage's
## enemy lineup as a relay, on the Spire's fight screen (game/spire.gd). The
## stage is handed over in `pending`; when it ends the outcome goes into
## `done` and main.gd settles it with Campaign.finish_team() and opens the
## stage list with the results popup.
extends "res://game/spire.gd"

const Campaign := preload("res://meta/campaign.gd")
const Zones := preload("res://meta/zones.gd")

## {zone, stage, picks, config}: set by the campaign screen before the scene loads.
static var pending := {}
## {zone, stage, picks, fight} or {zone, stage, refund: true}: read by main.gd.
static var done := {}

var _last


func _ready() -> void:
	TouchInput.ensure(self)
	TouchInput.set_back(self, func(): return _back if state in [State.INTRO, State.RESULT] else Callable())
	if pending.is_empty():
		_back.call_deferred()
		return
	var st := Zones.stage(pending.zone, pending.stage)
	spec = {"floor": 0, "boss": Zones.is_boss(st)}
	relay = Relay.new(pending.config)
	for i in pending.picks.size():
		aimed.append(false)
	arena = ArenaView.new()
	add_child(arena)
	sfx = Sfx.new()
	add_child(sfx)
	_build_ui()
	title_label.text = "%s · %s" % [Zones.zone(pending.zone).name.to_upper(), Zones.stage_key(pending.zone, pending.stage)]
	get_viewport().size_changed.connect(_layout)
	_layout()
	print("RELAY_STAGE_READY stage=%s seed=%d" % [Zones.stage_key(pending.zone, pending.stage), int(pending.config.seed)])
	_show_intro()


func _show_intro() -> void:
	state = State.INTRO
	sfx.on_menu()
	var st := Zones.stage(pending.zone, pending.stage)
	var foes: Array = relay.sides[1].map(func(e): return BallDefs.get_def(e).display_name)
	var mine: Array = relay.sides[0].map(func(e): return BallDefs.get_def(e).display_name)
	lineup_label.text = "%s  vs  %s" % [" + ".join(mine), " + ".join(foes)]
	info_label.text = "%s%d vs %d on %s. The winner of each round stays in with the HP it has left." % [
		(st.name + "! ") if st.has("name") else "", relay.sides[0].size(), relay.sides[1].size(), Zones.zone(pending.zone).twist.to_lower()]
	sim = MatchSim.new(relay.leg_config())
	arena.sim = sim
	var fight := _button("FIGHT!", _next_leg, 40)
	fight.name = "SpireFight"
	_set_panel([fight, _button("Back", _back, 24)])


func _launch() -> void:
	aimed[relay.slot[0]] = true
	relay.aims[0][relay.slot[0]] = aim
	sfx.play("launch")
	_start_leg()


func _end_leg() -> void:
	_last = sim
	super()


func _show_result() -> void:
	state = State.RESULT
	var fight := Campaign.relay_fight(relay, _last)
	done = {"zone": pending.zone, "stage": pending.stage, "picks": pending.picks, "fight": fight}
	sfx.on_result(0 if relay.winner == 0 else 1)
	var won: bool = relay.winner == 0
	var headline := _label("STAGE CLEARED!" if won else "NOT THIS TIME", 52)
	headline.modulate = Color("45f5a6") if won else Color("ff5a7a")
	info_label.text = "Your rewards are on the stage list." if won else "Try again, or fuse a critter up."
	print("STAGE_END stage=%s won=%s legs=%d hash=%s" % [Zones.stage_key(pending.zone, pending.stage), won, relay.legs.size(), relay.state_hash()])
	var back := _button("Back to the map", _back, 36)
	back.name = "SpireBack"
	_set_panel([headline, back])


func _give_up() -> void:
	var lost := {"winner": 1, "hp": [0.0, 0.0], "max_hp": 1.0, "time": 0.0}
	done = {"zone": pending.zone, "stage": pending.stage, "picks": pending.picks, "fight": lost}
	_back()


func _back() -> void:
	if not pending.is_empty() and done.is_empty():
		# Left before the fight started: the energy comes back.
		done = {"zone": pending.zone, "stage": pending.stage, "refund": true}
	pending = {}
	get_tree().change_scene_to_file("res://game/main.tscn")
