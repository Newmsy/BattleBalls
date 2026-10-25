## The Spire fight: your picks against the floor's enemy lineup as a relay
## (sim/relay.gd, design/spire.md), on the shared relay fight screen
## (game/relay_fight.gd). Enemy aims come from the floor seed. The result is
## settled into the climb file (meta/spire_climb.gd), then it's back to the
## Spire screen.
extends "res://game/relay_fight.gd"

const Spire := preload("res://sim/spire.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const SpireClimb := preload("res://meta/spire_climb.gd")
const SpireScreen := preload("res://game/ui/screens/spire_screen.gd")
const LiveOps := preload("res://game/liveops.gd")
const GlowState := preload("res://game/glow/glow_state.gd")

var climb
var spec: Dictionary


func _ready() -> void:
	climb = SpireClimb.load_file(LiveOps.now())
	if climb.pending.is_empty() or int(climb.pending.floor) != climb.next_floor():
		climb.pending = {}
		_back.call_deferred()
		return
	spec = climb.floor_spec()
	print("SPIRE_READY week=%d floor=%d seed=%d" % [climb.week, spec.floor, spec.seed])
	start(Relay.new(Spire.relay_config(spec, climb.pending.picks)))


## Saved at every launch, so closing the app mid-floor still costs Stamina.
func _on_launched() -> void:
	climb.pending.launched = aimed.count(true)
	climb.save_file()


func _show_result() -> void:
	var r: Dictionary = climb.settle(relay)
	climb.save_file()
	GlowState.note_fight(0 if r.won else 1, 0.0)
	if r.won:
		GlowState.note("spire")
	sfx.on_result(0 if r.won else 1)
	print("SPIRE_RESULT floor=%d won=%s hash=%s" % [r.floor, r.won, relay.state_hash()])
	# Who spent stamina, as faces: the names alone were a wall of text.
	var spent := Kit.hbox(10, [Kit.label("Stamina used", 24, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)
	for id in r.spent:
		spent.add_child(CritterIcon.face(id, 48))
	var body: Array = [_reward_row(r.floor)] if r.won else []
	if not r.spent.is_empty():
		body.append(spent)
	var back := Kit.button("Continue", _back, "go", 26, 84)
	_mark("SpireBack", back, ResultPopup.SLIDE_SECS)
	_popup("The Spire · Floor %d%s" % [r.floor, " · Boss" if spec.boss else ""], body, [back])


## The floor's reward as icons and numbers; it's added to your stock back on the Spire screen.
func _reward_row(floor_no: int) -> Control:
	var rw := Spire.reward(floor_no)
	var row := Kit.hbox(10, [Kit.glyph("coin", 34, Glyph.GOLD), Kit.label(Kit.commas(rw.coins), 30)], BoxContainer.ALIGNMENT_CENTER)
	if rw.orbs > 0:
		row.add_child(Kit.glyph("egg", 34, Kit.FG))
		row.add_child(Kit.label(str(rw.orbs), 30))
	if rw.xp_chips > 0: # The XP Chip's Bag glyph.
		row.add_child(Kit.glyph("bolt", 34, Kit.GOOD))
		row.add_child(Kit.label(str(rw.xp_chips), 30))
	if not rw.gear.is_empty(): # The piece's glyph and stars; its name is on the Spire screen.
		row.add_child(Kit.glyph(str(rw.gear.type), 34, Kit.GOOD))
		row.add_child(Kit.glyph("stars", 22, Kit.GOOD, int(rw.gear.tier)))
	return row


func _give_up() -> void:
	climb.settle(relay, aimed.count(true))
	climb.save_file()
	_back()


func _back() -> void:
	if climb and not climb.pending.is_empty() and unlaunched():
		climb.pending = {} # Nothing launched yet: no Stamina spent.
		climb.save_file()
	SpireScreen.reopen = true
	get_tree().change_scene_to_file("res://game/main.tscn")
