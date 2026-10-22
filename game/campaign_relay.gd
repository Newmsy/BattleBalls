## A pairs or trios campaign stage (zone 2 on): your team against the stage's
## enemy lineup as a relay, on the shared relay fight screen
## (game/relay_fight.gd). The stage is handed over in `pending`; when it ends
## the outcome goes into `done` and main.gd settles it with
## Campaign.finish_team() and opens the stage list with the result popup.
extends "res://game/relay_fight.gd"

const Campaign := preload("res://meta/campaign.gd")
const Zones := preload("res://meta/zones.gd")

## {zone, stage, picks, config}: set by the campaign screen before the scene loads.
static var pending := {}
## {zone, stage, picks, fight} or {zone, stage, refund: true}: read by main.gd.
static var done := {}

var _last


func _ready() -> void:
	if pending.is_empty():
		_back.call_deferred()
		return
	print("RELAY_STAGE_READY stage=%s seed=%d" % [Zones.stage_key(pending.zone, pending.stage), int(pending.config.seed)])
	start(Relay.new(pending.config))


func _end_leg() -> void:
	_last = sim
	super()


func _show_result() -> void:
	var fight := Campaign.relay_fight(relay, _last)
	done = {"zone": pending.zone, "stage": pending.stage, "picks": pending.picks, "fight": fight}
	sfx.on_result(0 if relay.winner == 0 else 1)
	print("STAGE_END stage=%s won=%s legs=%d hash=%s" % [Zones.stage_key(pending.zone, pending.stage), relay.winner == 0, relay.legs.size(), relay.state_hash()])
	# Its result popup (stars, drops, XP) opens on the stage list, as for
	# every campaign stage: a beat on the last knockout, then straight there.
	await get_tree().create_timer(1.1).timeout
	if is_inside_tree() and state == State.RESULT:
		_back()


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
