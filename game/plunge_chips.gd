## Chips pinned to the edge of a Critter Plunge race's view when a racer you
## care about is off screen: "Chill leads" when the leader is, "You · 5th"
## when your racer is, each with an arrow toward it. Render only; redraws at
## most 15 times a second and stops once the race is over.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const A11y := preload("res://game/a11y.gd")
const Roster := preload("res://game/ui/roster.gd")

const TICK := 1.0 / 15.0
const BG := Color("0e0c2a")
const YOU := Color("45f5a6")
const LEAD := Color("ffd36b")

var view ## game/plunge_view.gd
var top_pad := 0.0 ## Screen pixels above the course (the standings strip).
var _chips := [] ## [{text, color, down}]
var _wait := 0.0


func _process(delta: float) -> void:
	_wait -= delta
	if view == null or view.sim == null or _wait > 0.0:
		return
	_wait = TICK
	var chips := []
	var sim = view.sim
	if not sim.finished:
		var subj: int = view.subject()
		var lead: int = sim.standings()[0]
		if lead != subj and lead != view.you:
			var side: int = view.screen_side(lead)
			if side != 0:
				var verb := "won" if sim.places[lead] == 1 else "leads"
				chips.append({"text": "%s %s" % [Roster.get_critter(sim.balls[lead].type_id).name, verb], "color": LEAD, "down": side > 0})
		var you: int = view.you
		if you >= 0 and you != subj:
			var side: int = view.screen_side(you)
			if side != 0 or sim.ko_ticks[you] >= 0:
				var where := "OUT" if sim.ko_ticks[you] >= 0 else _ordinal(sim.standings().find(you) + 1)
				chips.append({"text": "You · " + where, "color": YOU, "down": side >= 0})
	if chips != _chips:
		_chips = chips
		queue_redraw()


func _draw() -> void:
	var stack := {true: 0, false: 0}
	for c in _chips:
		var fs := A11y.font(20)
		var tw: float = Kit.FONT.get_string_size(c.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var h := fs * 1.7
		var w := tw + h + 18.0
		var n: int = stack[c.down]
		stack[c.down] = n + 1
		var y: float = size.y - 12.0 - h - n * (h + 8.0) if c.down else top_pad + 12.0 + n * (h + 8.0)
		var r := Rect2((size.x - w) / 2.0, y, w, h)
		draw_rect(r, Color(BG, 0.9))
		draw_rect(r, Color(c.color, 0.8), false, 2.0)
		var ax := r.position.x + h * 0.55
		var ay := r.position.y + h / 2.0
		var d := h * 0.22
		var tip := Vector2(ax, ay + d) if c.down else Vector2(ax, ay - d)
		var base := ay - d if c.down else ay + d
		draw_colored_polygon(PackedVector2Array([tip, Vector2(ax - d * 1.2, base), Vector2(ax + d * 1.2, base)]), c.color)
		draw_string(Kit.FONT, Vector2(r.position.x + h, r.position.y + h / 2.0 + fs * 0.36), c.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Kit.FG)


static func _ordinal(k: int) -> String:
	return str(k) + (["th", "st", "nd", "rd"][k % 10] if k % 10 <= 3 and (k % 100) / 10 != 1 else "th")
