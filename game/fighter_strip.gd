extends Control
## The fighters under the arena (two cards in a 1v1, a compact pair per side
## in a 2v2): face, name, tier and role, what
## their ability does, and a ring around the face that fills toward a timed
## ability's next go. It uses the room below the speed row that used to sit
## empty, and teaches abilities without opening the Critterpedia.
## Render-only: reads the sim, never changes it. Static text; only the
## cooldown ring moves, so it redraws every frame only when a ring is shown.

const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")
const A11y := preload("res://game/a11y.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const BossArt := preload("res://game/boss_art.gd")

const TEAM_COLORS := [Color("45f5a6"), Color("ff5a7a")]
const PANEL := Color(27 / 255.0, 24 / 255.0, 66 / 255.0, 0.92)
const TEXT := Color("f0eeff")
const MUTED := Color("a29fc9")

## Ball on each card: 0 = the viewer's side, 1 = the foe's, then (2v2) the
## viewer's mate and the foe's mate.
var _ball := [-1, -1, -1, -1]
var _card := [{}, {}, {}, {}]
var _n := 2
var _sim = null
var _you_side := 0
var _timed := false


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
	_n = 4 if sim.get("starters") == 4 and sim.balls.size() >= 4 else 2
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


func _describe(sim, i: int) -> Dictionary:
	var b = sim.balls[i]
	var def: Dictionary = b.def
	var id := str(b.type_id)
	var ts: Array = sim.config.get("tiers", [])
	var tier := int(ts[i]) if i < ts.size() else 1
	var card := {"id": id, "name": str(def.get("display_name", id)), "tier": tier, "boss": def.get("boss", false), "color": Color(def.get("color", "ffffff"))}
	if CritterDb.has(id):
		var c := CritterDb.get_critter(id)
		var tiers: Array = c.get("tiers", [])
		card.line = "T%d · %s" % [tier, c.get("role", "")]
		# The T5 upgrade is the critter's signature; below that, its base ability.
		card.text = str(tiers[4].text) if tier >= 5 and tiers.size() >= 5 else (str(tiers[0].text) if not tiers.is_empty() else str(c.get("description", "")))
	else:
		card.line = "Boss"
		card.text = str(def.get("description", ""))
	for e in def.get("effects", []):
		if e.get("on") == "every":
			var secs: float = def.get(e.secs, 0.0) if e.secs is String else float(e.secs)
			card.every = maxi(1, int(round(secs * sim.TICK_RATE)))
			break
	return card


func _process(_delta: float) -> void:
	if _sim != null and _timed:
		queue_redraw()


func _draw() -> void:
	if _sim == null or size.y < 90.0:
		return
	var gap := 12.0
	var w := (size.x - gap) / 2.0
	if _n == 4: # Viewer's pair on the left, the foes on the right.
		var h := (size.y - gap) / 2.0
		for k in 4:
			_draw_card(k, Rect2((k % 2) * (w + gap), (k / 2) * (h + gap), w, h))
		return
	for k in 2:
		_draw_card(k, Rect2(k * (w + gap), 0.0, w, size.y))


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
	var fr := minf(34.0, r.size.y * (0.3 if _n == 4 else 0.22))
	var face := r.position + Vector2(14.0 + fr, 14.0 + fr)
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
	var fs := A11y.font(22)
	var tx := face.x + fr + 14.0
	var tw := r.end.x - tx - 10.0
	draw_string(FONT, Vector2(tx, r.position.y + 14.0 + fs), card.name, HORIZONTAL_ALIGNMENT_LEFT, tw, fs, col)
	var sfs := A11y.font(20)
	if _n == 4: # Compact: the ability text runs beside the face, under the name.
		var room := int((r.end.y - (r.position.y + 18.0 + fs) - 8.0) / (sfs + 4.0))
		if room > 0 and card.text != "":
			draw_multiline_string(FONT, Vector2(tx, r.position.y + 18.0 + fs + sfs), card.text, HORIZONTAL_ALIGNMENT_LEFT, tw, sfs, room, TEXT)
		return
	draw_string(FONT, Vector2(tx, r.position.y + 18.0 + fs + sfs), card.line, HORIZONTAL_ALIGNMENT_LEFT, tw, sfs, MUTED)
	var top := r.position.y + 28.0 + 2.0 * fr
	var lines := int((r.end.y - top - 8.0) / (sfs + 4.0))
	if lines > 0 and card.text != "":
		draw_multiline_string(FONT, Vector2(r.position.x + 14.0, top + sfs), card.text, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 28.0, sfs, lines, TEXT)
