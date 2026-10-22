extends Control
## The fighters' plates (game/fight_layout.gd): the foe's above the arena,
## yours below it, one per fighter out (a full-width plate in a 1v1 or relay,
## two or three side by side in a 2v2 or 3v3). Each has the face, name, tier,
## level and power, what its ability does (not in a 3v3: tap for the card) and
## a ring around the face that fills toward a timed ability's next go; in a
## relay the bench waits beside it. game/fight_hud.gd draws the health bars
## along the plates' bottoms. It covers the whole screen and draws only
## where the layout says.
## Render-only: reads the sim, never changes it. Static text; only the
## cooldown ring moves, so it redraws every frame only when a ring is shown.

const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")
const A11y := preload("res://game/a11y.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const BossArt := preload("res://game/boss_art.gd")
const AbilityText := preload("res://game/ui/ability_text.gd")
const CritterPopup := preload("res://game/ui/critter_popup.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")
const FamilyEdge := preload("res://game/ui/family_edge.gd")
const Families := preload("res://sim/families.gd")
const FightLayout := preload("res://game/fight_layout.gd")

const TEAM_COLORS := [Color("45f5a6"), Color("ff5a7a")]
const PANEL := Color(27 / 255.0, 24 / 255.0, 66 / 255.0, 0.92)
const TEXT := Color("f0eeff")
const MUTED := Color("a29fc9")

## Ball on each card: 0 = the viewer's side, 1 = the foe's, then (2v2) the
## viewer's mate and the foe's mate (and in a 3v3 the third of each).
var _ball := [-1, -1, -1, -1, -1, -1]
var _card := [{}, {}, {}, {}, {}, {}]
var _n := 2
var _sim = null
var _you_side := 0
var _timed := false
## Where things go: FightLayout.rects() for this screen (FightLayout.place_plates).
var layout := {}
## The line under each side's name, like "T5 · Lv25 · 5,481 power" (empty:
## the tier and role). Index 0 is the viewer's side.
var stats: Array = ["", ""]:
	set(v):
		stats = v
		queue_redraw()
## Only the foe's plates (aiming: the room under the arena holds the controls).
var foe_only := false:
	set(v):
		if v != foe_only:
			foe_only = v
			queue_redraw()
## A relay's bench per side (viewer's first): [{"id", "out"}] for each
## teammate not fighting now, knocked out or still to come.
var bench: Array = [[], []]:
	set(v):
		if v != bench:
			bench = v
			queue_redraw()


## Shows the fight `sim` from `you_side`'s view; null hides it.
func show_fight(sim, you_side := 0) -> void:
	if sim == null or sim.balls.size() < 2:
		if _sim != null:
			_sim = null
			queue_redraw()
		return
	var changed: bool = _sim != sim or _you_side != you_side
	_sim = sim
	_you_side = you_side
	var starters: int = sim.get("starters") if sim.get("starters") != null else 2
	_n = starters if starters in [4, 6] and sim.balls.size() >= starters else 2
	for k in _n:
		var idx: int = k ^ you_side
		if idx != _ball[k] or changed:
			_ball[k] = idx
			_card[k] = _describe(sim, idx)
			changed = true
	_timed = false
	for k in _n:
		_timed = _timed or _card[k].get("every", 0) > 0
	if changed or _timed:
		queue_redraw()


## Card `k`'s family edge on the cards across from it, 0 when edges are off.
func _edge(k: int) -> int:
	if _sim == null or not _sim.get("family_edges") or _card[k].is_empty() or _card[k].boss:
		return 0
	var foes := []
	for j in _n:
		if j % 2 != k % 2 and not _card[j].is_empty() and not _card[j].boss:
			foes.append(_card[j].id)
	return FamilyEdge.team([_card[k].id], foes)


func _describe(sim, i: int) -> Dictionary:
	var b = sim.balls[i]
	var def: Dictionary = b.def
	var id := str(b.type_id)
	var ts: Array = sim.config.get("tiers", [])
	var tier := int(ts[i]) if i < ts.size() else 1
	var card := {"id": id, "name": str(def.get("display_name", id)), "tier": tier, "boss": def.get("boss", false), "color": Color(def.get("color", "ffffff"))}
	if CritterDb.has(id):
		var c := CritterDb.get_critter(id)
		card.line = "T%d · %s" % [tier, c.get("role", "")]
		# The ability as it is at this tier (T2-T4 numbers, not T1's); at T5 the
		# signature follows on its own line, since alone it doesn't say what the
		# critter does.
		card.text = AbilityText.now(id, tier)
		if card.text == "":
			card.text = str(c.get("description", ""))
		var t5 := AbilityText.change(id, 5) if tier >= 5 else ""
		if t5 != "" and t5 != card.text and not card.text.contains(t5):
			card.text += "\nT5: " + t5
	else:
		card.line = "Boss"
		card.text = _boss_line(def)
	for e in def.get("effects", []):
		if e.get("on") == "every":
			var secs: float = def.get(e.secs, 0.0) if e.secs is String else float(e.secs)
			card.every = maxi(1, int(round(secs * sim.TICK_RATE)))
			break
	return card


## A boss card's one line: its short line if it has one, else the first
## sentence of its description.
static func _boss_line(def: Dictionary) -> String:
	if def.has("short"):
		return str(def.short)
	var d := str(def.get("description", ""))
	var cut := d.find(". ")
	return d.substr(0, cut + 1) if cut >= 0 else d


func _process(_delta: float) -> void:
	if _sim != null and _timed:
		queue_redraw()


func _draw() -> void:
	if _sim == null or layout.is_empty():
		return
	for k in _n:
		var r := _rect(k)
		if r.size.y >= 90.0 and not (foe_only and k % 2 == 0):
			_draw_card(k, r)


func _rect(k: int) -> Rect2:
	return FightLayout.plate(layout, k, _n)


## Tapping a card opens that critter's mini Critterpedia card (the fight runs
## on). Read in _input: the fight screen's own boxes sit over the strip.
var _press := Vector2(-1, -1)


func _input(event: InputEvent) -> void:
	# Aiming, a tap anywhere is the aim (FightAim), not a card.
	if _sim == null or foe_only or not is_visible_in_tree() or CritterPopup.current() != null:
		_press = Vector2(-1, -1)
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var at: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
	if event.pressed:
		_press = at
		return
	var from := _press
	_press = Vector2(-1, -1)
	if from.distance_to(at) > 24.0:
		return
	for k in _n:
		var card: Dictionary = _card[k]
		if not card.is_empty() and not card.boss and not (foe_only and k % 2 == 0) and _rect(k).has_point(at):
			CritterPopup.open(self, card.id, card.tier)
			get_viewport().set_input_as_handled()
			return


func _draw_card(k: int, r: Rect2) -> void:
	var card: Dictionary = _card[k]
	if card.is_empty():
		return
	var col: Color = TEAM_COLORS[k % 2]
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL
	box.border_color = Color(col, 0.6)
	box.set_border_width_all(2)
	box.set_corner_radius_all(18)
	draw_style_box(box, r)
	var bar := FightLayout.plate_bar(r, _n)
	var bottom := bar.position.y - 10.0 # The text stops short of the health bar.
	# Its family edge on the other side: green up / red down, top right.
	var edge := _edge(k)
	var badge_w := 0.0
	if edge != 0:
		var bh := 24.0 if _n == 2 else 22.0
		badge_w = FamilyEdge.badge_width(edge, bh)
		FamilyEdge.draw_badge(self, Rect2(r.end.x - badge_w - 12.0, r.position.y + 12.0, badge_w, bh), edge)
	if _n == 6: # A trio: the face over the name and tier, centred; tap for the ability.
		var fr := clampf((bottom - r.position.y - 76.0) / 2.0, 20.0, 44.0)
		var face := Vector2(r.get_center().x, r.position.y + 12.0 + fr)
		_draw_face(k, face, fr)
		var nfs := A11y.font(20)
		var y := face.y + fr + 10.0 + nfs
		draw_string(FONT, Vector2(r.position.x + 8.0, y), card.name, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16.0, nfs, col)
		if y + nfs + 4.0 <= bottom:
			draw_string(FONT, Vector2(r.position.x + 8.0, y + nfs + 4.0), _line(k), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16.0, A11y.font(18), MUTED)
		return
	var big := _n == 2 and r.size.y >= 300.0
	var fr := clampf(r.size.y * (0.16 if _n == 2 else 0.13), 24.0, 56.0 if big else 40.0)
	var fs := A11y.font(32 if big else 22)
	var sfs := A11y.font(24 if big else 20)
	var afs := A11y.font(26 if big else 20)
	# The face, name and ability sit in the middle of the room above the bar.
	var lines := 0
	if card.text != "":
		lines = mini(int((bottom - r.position.y - 28.0 - 2.0 * fr - 12.0) / (afs + 4.0)), _lines_of(card.text, r.size.x - 32.0, afs))
	var block := 2.0 * fr + (12.0 + lines * (afs + 4.0) if lines > 0 else 0.0)
	var pad := maxf(16.0, (bottom - r.position.y - block) / 2.0)
	var face := r.position + Vector2(16.0 + fr, pad + fr)
	_draw_face(k, face, fr)
	var tx := face.x + fr + 16.0
	var tw := r.end.x - tx - 16.0
	var head := face.y - (fs + sfs + 6.0) / 2.0 # The name and its line, centred on the face.
	var bench_w := 0.0
	var team: Array = bench[k % 2] if _n == 2 else []
	if not team.is_empty(): # A relay's bench, right of the line under the name.
		var br := clampf(fr * 0.4, 14.0, 20.0)
		bench_w = team.size() * (br * 2.0 + 8.0)
		for j in team.size():
			var c := Vector2(r.end.x - 16.0 - br - j * (br * 2.0 + 8.0), head + fs + 6.0 + sfs * 0.5)
			_draw_bench(team[team.size() - 1 - j], c, br)
	draw_string(FONT, Vector2(tx, head + fs), card.name, HORIZONTAL_ALIGNMENT_LEFT, tw - (badge_w + 8.0 if badge_w > 0.0 else 0.0), fs, col)
	draw_string(FONT, Vector2(tx, head + fs + 6.0 + sfs), _line(k), HORIZONTAL_ALIGNMENT_LEFT, tw - bench_w, sfs, MUTED)
	var top := face.y + fr + 12.0
	if lines > 0:
		draw_multiline_string(FONT, Vector2(r.position.x + 16.0, top + afs), card.text, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 32.0, afs, lines, TEXT)


## How many lines `text` wraps to at `width` (so short text can be centred).
func _lines_of(text: String, width: float, fs: int) -> int:
	var n := 0
	for para in text.split("\n"):
		n += maxi(1, ceili(FONT.get_string_size(para, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x / maxf(1.0, width * 0.92)))
	return n


## The line under a fighter's name: its side's stats line in a 1v1 (tier,
## level and power where the mode knows them), else its tier and role.
func _line(k: int) -> String:
	var line: String = _card[k].line
	if _n == 2 and k < 2 and str(stats[k]) != "":
		line = str(stats[k])
	return line


func _draw_face(k: int, face: Vector2, fr: float) -> void:
	var card: Dictionary = _card[k]
	var col: Color = TEAM_COLORS[k % 2]
	if card.boss:
		BossArt.draw(self, card.id, face, fr * 0.9, {})
	elif CritterDb.has(card.id):
		CritterArt.draw_critter(self, card.id, face, fr * 0.85, {"tier": card.tier})
	else:
		draw_circle(face, fr * 0.85, card.color)
	draw_arc(face, fr + 5.0, 0.0, TAU, 40, Color(col, 0.2), 4.0, true)
	var every: int = card.get("every", 0)
	if every > 0:
		var b = _sim.balls[_ball[k]]
		var frac := float(_sim.tick % every) / every if b.alive() else 0.0
		draw_arc(face, fr + 5.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 40, col, 4.0, true)
	if not card.boss and Families.of(card.id) != "":
		FamilyIcon.draw(self, Families.of(card.id), face + Vector2(-fr, fr) * .78, maxf(16.0, fr * .7))


## A benched relay teammate: its face, greyed out and crossed once it's out.
func _draw_bench(mate: Dictionary, c: Vector2, r: float) -> void:
	var id := str(mate.get("id", ""))
	if CritterDb.has(id):
		CritterArt.draw_critter(self, id, c, r * 0.85, {})
	draw_arc(c, r + 2.0, 0.0, TAU, 28, Color(MUTED, 0.5), 2.0, true)
	if mate.get("out", false):
		draw_circle(c, r + 1.0, Color(PANEL, 0.7))
		var d := r * 0.5
		draw_line(c + Vector2(-d, -d), c + Vector2(d, d), TEAM_COLORS[1], 3.0, true)
		draw_line(c + Vector2(-d, d), c + Vector2(d, -d), TEAM_COLORS[1], 3.0, true)
