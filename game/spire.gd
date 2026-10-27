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
const SaveGame := preload("res://game/online/save_game.gd")
const Profile := preload("res://meta/profile.gd")
const XpBar := preload("res://game/ui/xp_bar.gd")
const GearArt := preload("res://game/ui/gear_art.gd")
const BagScreen := preload("res://game/ui/screens/bag_screen.gd")
const RiftScreen := preload("res://game/ui/screens/rift_screen.gd")
const Gear := preload("res://sim/gear.gd")

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
	# The XP and the floor's reward go straight into the saved profile, so the
	# popup shows what you got (the Spire screen used to add it later).
	var got := _grant(r)
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
	var body: Array = []
	var cards: Array = []
	if r.won:
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 14)
		cards = _reward_cards(r.floor)
		for c in cards:
			grid.add_child(c[0])
		body.append(Kit.vbox(8, [Kit.caption("Rewards"), Kit.hbox(0, [grid], BoxContainer.ALIGNMENT_CENTER)]))
	body.append(_faction_rings())
	body.append(XpBar.rows({"critters": got.critters}, sfx))
	if not r.spent.is_empty():
		body.append(spent)
	var back := Kit.button("Continue", _back, "go", 26, 84)
	_mark("SpireBack", back, ResultPopup.SLIDE_SECS)
	_popup("The Spire · Floor %d%s" % [r.floor, " · Boss" if spec.boss else ""], body, [back])
	ResultPopup.drop_in(cards, sfx, ResultPopup.SLIDE_SECS + .1)


## Adds the climb's owed XP and rewards (this floor's and any left from
## before) to the saved profile and saves it, like Bounce Run's chests.
## Returns {critters: XP bar gains for the balls that just fought}. With no
## saved profile (a demo) it all stays owed for the Spire screen to add.
func _grant(r: Dictionary) -> Dictionary:
	var out := {"critters": []}
	var save := SaveGame.new()
	save.load_local()
	var d = save.data.get("profile")
	if not d is Dictionary:
		return out
	var p = Profile.from_dict(d, LiveOps.now())
	var xp: Dictionary = climb.take_xp()
	for id in xp:
		var mine := int(r.get("xp", 0)) if id in r.get("spent", []) else 0
		if int(xp[id]) > mine:
			p.add_xp(id, int(xp[id]) - mine)
		if mine > 0:
			var g: Dictionary = p.gain_xp(id, mine)
			if not g.is_empty():
				out.critters.append(g)
	SpireScreen.grant(p, climb.take_rewards())
	save.data.profile = p.to_dict()
	save.commit()
	return out


## The floor's reward as cards that pop in: coins, eggs, hammers, the boss
## floor's gear piece and a Rift Key. [[card, glow colour or null], ...]
func _reward_cards(floor_no: int) -> Array:
	var rw := Spire.reward(floor_no)
	var out: Array = [_card(Glyph.make("coin", 72, Glyph.GOLD), Kit.commas(rw.coins), Glyph.GOLD)]
	if rw.orbs > 0:
		out.append(_card(Glyph.make("orb", 72), "%d Summon Egg%s" % [rw.orbs, "" if rw.orbs == 1 else "s"], Color("c77dff")))
	if rw.hammers > 0:
		out.append(_card(Glyph.make("hammer", 72, Kit.FG), str(rw.hammers), Kit.LINE))
	if not rw.gear.is_empty():
		var col := BagScreen.tier_color(int(rw.gear.tier))
		var art := Kit.vbox(2, [GearArt.piece(str(rw.gear.type), int(rw.gear.tier), 64, col),
			Kit.hbox(0, [Glyph.make("stars", 18, col, int(rw.gear.tier))], BoxContainer.ALIGNMENT_CENTER)])
		var gear := _card(art, Gear.PIECES[rw.gear.type].name, Color(col, .6))
		out.append([gear[0], col if int(rw.gear.tier) >= 3 else null])
	if floor_no in SpireClimb.KEY_FLOORS:
		out += RiftScreen.extra_cards(1, [])
	return out


func _card(art: Control, text: String, edge: Color) -> Array:
	var name := Kit.label(text, 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true)
	name.max_lines_visible = 2
	var cell := Kit.vbox(4, [Kit.hbox(0, [art], BoxContainer.ALIGNMENT_CENTER), name])
	cell.custom_minimum_size.x = 130
	return [Kit.panel(cell, Kit.box(Kit.PANEL2, edge, 24, 2, 10)), null]


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
