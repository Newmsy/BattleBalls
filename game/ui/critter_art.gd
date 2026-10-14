## Draws any Neon Critter with plain CanvasItem draw calls, for menus and the
## arena alike. Each critter's look is data in its file (sim/critters/<id>.gd,
## the "art" key): a body style, a face (eyes + mouth) and a list of features
## drawn behind ("back") and in front of ("front") the body. New critters mix
## the existing bodies, faces and features; a new feature is one more branch
## in _feature(). Call from a CanvasItem's _draw():
##   CritterArt.draw_critter(self, "vampire", centre, radius, {"t": time, "tier": 2})
## State keys (all optional): t, tier, look (Vector2), blink (0-1), hit, flash,
## stacks, silhouette (bool: draw as an unfound dark shape).
extends RefCounted

const CritterDb := preload("res://sim/critter_db.gd")

const INK := Color("1a1530")
## The kit a critter's "art" can use; tests check every critter file against it.
const BODIES := ["gradient", "bomb", "ghost", "chrome", "starfield", "prism"]
const FEATURES := ["cape_collar", "spike_ring", "speed_streaks", "antennae", "ice_crown", "thorn_ring", "wisp_tail", "orbit_ring",
	"swirl_arms", "flame_crest", "rock_band", "headband", "fuse", "frost_freckles", "vines", "seam"]
const MOUTHS := ["smile", "grin", "smirk", "flat", "frown", "o", "fangs", "teeth", "none"]
const SILHOUETTE := Color("232052")

static var _sil := false


static func draw_critter(ci: CanvasItem, id: String, c: Vector2, r: float, s: Dictionary = {}) -> void:
	var d := CritterDb.get_critter(id)
	var st := {"t": 0.0, "tier": 1, "look": Vector2.RIGHT, "blink": 0.0, "hit": 0.0, "flash": 0.0, "stacks": 0, "hp_frac": 1.0}
	st.merge(s, true)
	_sil = st.get("silhouette", false)
	var art: Dictionary = d.art
	var col := Color(d.color)
	r *= art.get("scale", 1.0)
	if not _sil:
		_aura(ci, d.rarity, c, r, st.t)
	for f in art.get("back", []):
		_feature(ci, f, true, col, c, r, st)
	_body_for(ci, art.get("body", "gradient"), col, c, r, st)
	for f in art.get("front", []):
		_feature(ci, f, false, col, c, r, st)
	if not _sil:
		if st.hit > 0.0:
			_circ(ci, c, r, Color(1, 1, 1, minf(.85, st.hit * 2.4)))
		_face(ci, art.get("eyes", {}), col, c, r, st)
	_sil = false


# --- Primitives (every colour passes through _c for silhouettes) -------------

static func _c(col: Color) -> Color:
	return Color(SILHOUETTE, col.a) if _sil else col


static func shade(col: Color, amt: float) -> Color:
	return col.lightened(amt) if amt >= 0.0 else col.darkened(-amt)


static func _circ(ci: CanvasItem, p: Vector2, rad: float, col: Color) -> void:
	ci.draw_circle(p, rad, _c(col))


static func _ring(ci: CanvasItem, p: Vector2, rad: float, col: Color, w: float) -> void:
	ci.draw_arc(p, rad, 0.0, TAU, maxi(24, int(rad)), _c(col), w, true)


static func _poly(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	if pts.size() >= 3:
		ci.draw_colored_polygon(pts, _c(col))


static func _pline(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	if pts.size() >= 2:
		ci.draw_polyline(pts, _c(col), w, true)


static func _line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	ci.draw_line(a, b, _c(col), w, true)


static func ellipse_pts(p: Vector2, rx: float, ry: float, rot := 0.0, a0 := 0.0, a1 := TAU, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(p + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


static func _ell(ci: CanvasItem, p: Vector2, rx: float, ry: float, col: Color, rot := 0.0) -> void:
	if rx > 0.3 and ry > 0.3:
		var pts := ellipse_pts(p, rx, ry, rot)
		pts.remove_at(pts.size() - 1)
		_poly(ci, pts, col)


static func star_pts(p: Vector2, r1: float, r2: float, n: int, rot := -PI / 2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var rr := r2 if i % 2 else r1
		var a := rot + i * PI / n
		pts.append(p + Vector2(cos(a), sin(a)) * rr)
	return pts


static func _star(ci: CanvasItem, p: Vector2, r1: float, r2: float, n: int, col: Color) -> void:
	_poly(ci, star_pts(p, r1, r2, n), col)


static func _quad(a: Vector2, ctrl: Vector2, b: Vector2, n := 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
	return pts


## The part of a circle (centre c, radius R) between local heights y1 < y2.
static func _band(ci: CanvasItem, c: Vector2, rad: float, y1: float, y2: float, col: Color) -> void:
	y1 = clampf(y1, -rad, rad)
	y2 = clampf(y2, -rad, rad)
	if y2 - y1 < 0.5:
		return
	var pts := PackedVector2Array()
	var n := 8
	for i in n + 1:
		var y := lerpf(y1, y2, float(i) / n)
		pts.append(c + Vector2(sqrt(maxf(0.0, rad * rad - y * y)), y))
	for i in n + 1:
		var y := lerpf(y2, y1, float(i) / n)
		pts.append(c + Vector2(-sqrt(maxf(0.0, rad * rad - y * y)), y))
	_poly(ci, pts, col)


static func _chord_x(rad: float, y: float) -> float:
	return sqrt(maxf(0.0, rad * rad - y * y))


# --- Body, aura ---------------------------------------------------------------

## A radial gradient approximated with stacked circles, lit from the top left.
static func _body(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var dark := shade(col, -.2)
	var light := shade(col, .45)
	_circ(ci, c, r, dark)
	for k in range(1, 8):
		var f := k / 7.0
		_circ(ci, c + Vector2(-.35, -.4) * r * f * .9, r * (1.0 - f * .82), dark.lerp(light, f))
	_ring(ci, c, r, shade(col, -.5), maxf(1.5, r * .07))


static func _aura(ci: CanvasItem, rarity: String, c: Vector2, r: float, t: float) -> void:
	if rarity == "epic":
		for k in 5:
			ci.draw_circle(c, r * (1.0 + k * .09), Color(.7, .4, 1.0, .1))
	elif rarity == "legendary":
		var pulse := .8 + .2 * sin(t * 4.0)
		for k in 6:
			ci.draw_circle(c, r * (1.0 + k * .09 * pulse), Color(1.0, .76, .24, .1))
		for i in 2:
			var a := t * 1.5 + i * PI
			var p := c + Vector2(cos(a), sin(a)) * r * 1.35
			ci.draw_colored_polygon(star_pts(p, r * .12, r * .04, 4), Color(1, .95, .77, .6 + .4 * sin(t * 6.0 + i)))


## Body styles: gradient (default), bomb, ghost, chrome, starfield, prism.
static func _body_for(ci: CanvasItem, style: String, col: Color, c: Vector2, r: float, s: Dictionary) -> void:
	var t: float = s.t
	match style:
		"bomb":
			_body(ci, c, r, col)
			_ell(ci, c + Vector2(-.42, -.45) * r, r * .18, r * .1, Color(1, 1, 1, .35), -.7)
		"ghost":
			var a := .75 + .2 * sin(t * 2.0)
			_circ(ci, c, r * 1.08, Color(.79, .71, 1.0, .25 * a))
			_circ(ci, c, r, Color(.78, .7, 1.0, .6 * a))
			for k in range(1, 6):
				var f := k / 5.0
				_circ(ci, c + Vector2(-.3, -.35) * r * f * .9, r * (1.0 - f * .8), Color(.85 + .15 * f, .8 + .2 * f, 1.0, (.6 + .35 * f) * a))
		"chrome":
			var cols := [Color("f7f9fd"), Color("c4ccd8"), Color("8a95a8"), Color("e9eef5"), Color("aab4c3"), Color("5f6a7d")]
			for i in cols.size():
				_band(ci, c, r, -r + i * r * 2.0 / cols.size(), -r + (i + 1) * r * 2.0 / cols.size() + 1.0, cols[i])
			var n := 1 + int(s.tier / 2)
			for i in n:
				var x := (fmod(t * .6 + i * .37, 1.6) - .8) * r * 2.0
				if absf(x) < r * .8:
					_ell(ci, c + Vector2(x, 0), r * (.09 - .025 * i), _chord_x(r, x) * .92, Color(1, 1, 1, .55), -.6)
			_ring(ci, c, r, Color("4a5466"), maxf(1.5, r * .07))
		"starfield":
			_circ(ci, c, r * 1.12, Color(.56, .36, 1.0, .25))
			_circ(ci, c, r, Color("07060d"))
			for i in 14:
				var a := _hash(i) * TAU
				var rr := sqrt(_hash(i + 20)) * r * .85
				_circ(ci, c + Vector2(cos(a), sin(a)) * rr, r * .025 + _hash(i + 40) * r * .02, Color(1, 1, 1, .3 + .5 * absf(sin(t * 2.0 + i))))
			_ring(ci, c, r, Color("7b4dff"), maxf(1.5, r * .07))
		"prism":
			var n := 5 + int(s.tier)
			var hub := c + Vector2(-.15, -.2) * r
			var spd: float = 40.0 * (1.0 + .25 * s.tier)
			for i in n:
				var pts := PackedVector2Array([hub])
				pts.append_array(ellipse_pts(c, r, r, 0.0, i * TAU / n, (i + 1) * TAU / n, 6))
				var h := fmod(i * 360.0 / n + t * spd, 360.0) / 360.0
				_poly(ci, pts, Color.from_hsv(h, .45 if i % 2 else .55, 1.0))
			_circ(ci, c + Vector2(-.3, -.4) * r, r * .35, Color(1, 1, 1, .35))
			for i in n:
				var a := i * TAU / n
				_line(ci, hub, c + Vector2(cos(a), sin(a)) * r, Color(1, 1, 1, .6), 1.0)
			var segs := 24
			for i in segs:
				var a0 := i * TAU / segs
				var h := fmod(float(i) / segs + t * .32, 1.0)
				ci.draw_arc(c, r, a0, a0 + TAU / segs + .02, 3, _c(Color.from_hsv(h, .7, 1.0)), maxf(2.0, r * .09), true)
		_:
			_body(ci, c, r, col)


# --- Back and front features --------------------------------------------------

## One named feature from a critter's art "back"/"front" lists. `back` says
## which layer is drawing, for features that wrap around the body.
static func _feature(ci: CanvasItem, name: String, back: bool, col: Color, c: Vector2, r: float, s: Dictionary) -> void:
	var t: float = s.t
	var tier: int = s.tier
	var look: Vector2 = s.look
	match name:
		"cape_collar":
			var h := 1.05 + .08 * tier
			for k in [-1, 1]:
				_poly(ci, PackedVector2Array([c + Vector2(k * .25, -.9) * r, c + Vector2(k * 1.12, -h) * r, c + Vector2(k * .95, -.15) * r]), shade(col, -.55))
			if tier >= 5:
				for i in 10:
					var a := i * TAU / 10 + t
					ci.draw_arc(c, r * 1.25, a, a + .35, 4, _c(Color(1, .24, .35, .7)), 2.0, true)
		"spike_ring":
			var n := 8 + tier * 2
			var L: float = r * (.22 + .04 * tier + minf(.25, s.stacks * .04))
			var spike := Color.WHITE if s.flash > 0.0 else shade(col, -.35)
			for i in n:
				var a := float(i) / n * TAU + .2
				var w := PI / n * .7
				_poly(ci, PackedVector2Array([c + Vector2(cos(a - w), sin(a - w)) * r * .92, c + Vector2(cos(a), sin(a)) * (r + L), c + Vector2(cos(a + w), sin(a + w)) * r * .92]), spike)
		"speed_streaks":
			var n := 1 + tier
			var perp := Vector2(-look.y, look.x)
			for i in n:
				var o := (i - (n - 1) / 2.0) * r * .3
				var len := r * (.6 + .25 * _hash(i + 3) + .12 * tier)
				var a := c - look * r * 1.05 + perp * o
				_line(ci, a, a - look * len, Color(1, .75, .24, .3 + .35 * _hash(i)), maxf(1.5, r * .08))
			var anchor := c - look * r * .8 + Vector2(0, -.45 * r)
			for k in [0, 1]:
				var w := sin(t * 12.0 + k * 2) * r * .15
				var ctrl := anchor - look * r * .4 + Vector2(w, -w + k * r * .15)
				var tip := anchor - look * r * .75 + Vector2(0, k * r * .25 + w)
				_pline(ci, _quad(anchor, ctrl, tip), Color("e8344a"), maxf(2.0, r * .12))
		"antennae":
			var ants := [-.45, 0.0, .45] if tier >= 5 else ([-.3, .3] if tier >= 3 else [0.0])
			for a in ants:
				var base := c + Vector2(sin(a), -cos(a)) * r * .8
				var tip := c + Vector2(sin(a), -cos(a)) * r * 1.45
				_line(ci, base, tip, shade(col, -.5), maxf(1.5, r * .07))
				var on := sin(t * 5.0 + a * 3.0) > -.2
				if on and not _sil:
					ci.draw_circle(tip, r * .2, Color(.5, .9, 1.0, .3))
				_circ(ci, tip, r * .1, Color("bff4ff") if on else Color("3b6f80"))
		"ice_crown":
			var n := 2 + tier
			for i in n:
				var a := -PI / 2 + (i - (n - 1) / 2.0) * .32
				var L := r * (.3 if i % 2 else .42)
				var dir := Vector2(cos(a), sin(a))
				var nrm := Vector2(-dir.y, dir.x) * r * .08
				var b := c + dir * r * .9
				var tip := c + dir * (r + L)
				var mid := (b + tip) / 2.0
				var pts := PackedVector2Array([b + nrm, mid + nrm * 1.4, tip, mid - nrm * 1.4, b - nrm])
				_poly(ci, pts, Color("eafaff"))
				pts.append(b + nrm)
				_pline(ci, pts, Color("7cc7ea"), 1.0)
		"thorn_ring":
			var n := 4 + tier
			for i in n:
				var a := float(i) / n * TAU + .5
				_poly(ci, PackedVector2Array([c + Vector2(cos(a - .12), sin(a - .12)) * r * .95, c + Vector2(cos(a), sin(a)) * r * 1.25, c + Vector2(cos(a + .12), sin(a + .12)) * r * .95]), Color("2e4a1f"))
		"wisp_tail":
			var L := r * (.6 + .18 * tier)
			var perp := Vector2(-look.y, look.x)
			for i in 3:
				var o := (i - 1) * r * .4
				var start := c - look * r * .6 + perp * o
				var pts := PackedVector2Array([start])
				for j in range(1, 7):
					var f := j / 6.0
					pts.append(start - look * L * f + perp * sin(t * 5.0 + j + i) * r * .12 * f)
				_pline(ci, pts, Color(.89, .84, 1.0, .6), r * (.22 - .04 * absi(i - 1)))
		"orbit_ring":
			_orbit_ring(ci, c, r, tier, t, back)
		"swirl_arms":
			var n := 1 + tier
			for i in n:
				var a := t * 1.4 + i * TAU / n
				var arm := Color(1, .35, .78, .75) if i % 2 else Color(.59, .43, 1.0, .8)
				ci.draw_arc(c, r * (1.12 + .08 * (i % 3)), a, a + 1.4, 16, _c(arm), r * .09, true)
		"flame_crest":
			var n := 2 + tier
			for i in n:
				var a := -PI / 2 + (i - (n - 1) / 2.0) * .36
				var fl := 1.0 + .18 * sin(t * 9.0 + i * 1.7)
				var L := r * (.55 + .06 * tier) * fl * (1.0 - .15 * absf(i - (n - 1) / 2.0) / n)
				_flame(ci, c + Vector2(cos(a), sin(a)) * r * .75, a, L, r * .2)
			if not _sil:
				for i in 5:
					var p := fmod(t * .6 + _hash(i), 1.0)
					ci.draw_circle(c + Vector2((_hash(i + 3) - .5) * r * 1.4, -r * (.9 + p * 1.1)), r * .04, Color(1, (150 + _hash(i + 9) * 90) / 255.0, .24, 1.0 - p))
		"rock_band":
			for crack in [[Vector2(-.7, -.5), Vector2(-.5, -.35), Vector2(-.55, -.15)], [Vector2(.55, -.65), Vector2(.42, -.45), Vector2(.6, -.3)]]:
				_pline(ci, PackedVector2Array(crack.map(func(v): return c + v * r)), shade(col, -.45), maxf(1.0, r * .04))
			var gold := tier >= 5
			_band(ci, c, r * .97, r * .58, r * .82, Color("d9a32a") if gold else Color("4b5260"))
			for i in tier:
				_circ(ci, c + Vector2((i - (tier - 1) / 2.0) * r * .32, r * .7), r * .055, Color("fff1b8") if gold else Color("a9b2c2"))
		"headband":
			_band(ci, c, r * .97, -r * .66, -r * .46, Color("e8344a"))
		"fuse":
			var cap := Rect2(c + Vector2(-.2, -1.08) * r, Vector2(.4, .2) * r)
			_poly(ci, PackedVector2Array([cap.position, cap.position + Vector2(cap.size.x, 0), cap.end, cap.position + Vector2(0, cap.size.y)]), Color("6b7280"))
			var L := 1.25 + .07 * tier
			var p0 := c + Vector2(0, -1.06) * r
			var p1 := c + Vector2(.05, -1.3) * r
			var p2 := c + Vector2(.45, -1.2) * r
			var p3 := c + Vector2(.4, -L) * r
			var pts := PackedVector2Array()
			for i in 13:
				var u := i / 12.0
				pts.append(p0 * pow(1 - u, 3) + p1 * 3 * u * pow(1 - u, 2) + p2 * 3 * u * u * (1 - u) + p3 * pow(u, 3))
			_pline(ci, pts, Color("c9b48a"), maxf(1.5, r * .07))
			var f := .75 + .35 * sin(t * 30.0) * sin(t * 7.0)
			if not _sil:
				ci.draw_circle(p3, r * .3 * f, Color(1, .8, .23, .3))
			_star(ci, p3, r * (.16 + .03 * tier) * f, r * .06, 6, Color("ffe066"))
			_circ(ci, p3, r * .05, Color("ff7a1a"))
		"frost_freckles":
			for k in [-1, 1]:
				for i in 3:
					_circ(ci, c + Vector2(k * r * (.5 + i * .08), r * .18 + (i % 2) * r * .07), r * .03, Color(1, 1, 1, .8))
		"vines":
			for row in [[-.8, 0.0], [.75, 2.0]]:
				var y0: float = row[0] * r
				var pts := PackedVector2Array()
				var x := -r
				while x <= r:
					var y := y0 + sin(x / r * 4.0 + row[1]) * r * .08
					if absf(x) <= _chord_x(r * .97, y):
						pts.append(c + Vector2(x, y))
					x += r * .1
				_pline(ci, pts, Color("2e4a1f"), maxf(2.0, r * .1))
				if row[0] < 0:
					var tx := -r * .8
					while tx <= r * .8:
						var ty := y0 + sin(tx / r * 4.0) * r * .08
						if absf(tx) <= _chord_x(r * .9, ty):
							_poly(ci, PackedVector2Array([c + Vector2(tx - r * .05, ty), c + Vector2(tx, ty - r * .13), c + Vector2(tx + r * .05, ty)]), Color("d9e8b0"))
						tx += r * .4
		"seam":
			var seam := _quad(c + Vector2(0, -.97) * r, c + Vector2(.08, 0) * r, c + Vector2(0, .97) * r, 24)
			for i in range(0, seam.size() - 1, 2):
				_line(ci, seam[i], seam[i + 1], shade(col, -.4), maxf(1.2, r * .05))
			var n := tier + 2
			for i in n:
				var y := -r * .75 + i * r * 1.5 / (n - 1)
				if absf(y + r * .08) < r * .22:
					continue
				_line(ci, c + Vector2(-r * .08, y - r * .03), c + Vector2(r * .1, y + r * .03), shade(col, -.4), maxf(1.2, r * .05))


static func _orbit_ring(ci: CanvasItem, c: Vector2, r: float, tier: int, t: float, back: bool) -> void:
	var rot := -.35
	var a0 := PI if back else 0.0
	_pline(ci, ellipse_pts(c, r * 1.55, r * .38, rot, a0, a0 + PI, 20), Color(.66, .61, 1.0, .55 + .08 * tier), maxf(2.0, r * .11))
	var n := 1 + int(tier / 2)
	for i in n:
		var a := t * (1.2 + i * .4) + i * 2.1
		if (sin(a) < 0) != back:
			continue
		_circ(ci, c + Vector2(cos(a) * r * 1.55, sin(a) * r * .38).rotated(rot), r * (.12 - .02 * i), Color("ffd9a8") if i % 2 else Color("d9d4ff"))


static func _flame(ci: CanvasItem, p: Vector2, a: float, L: float, w: float) -> void:
	var dir := Vector2(cos(a), sin(a))
	var nrm := Vector2(-dir.y, dir.x)
	for layer in [[Color("e8341c"), 1.0], [Color("ff8a1f"), .7], [Color("ffe066"), .4]]:
		var f: float = layer[1]
		var tip := p + dir * L * (.4 + .6 * f)
		var pts := _quad(p + nrm * w * f, p + dir * L * .5 * f + nrm * w * f, tip, 6)
		pts.append_array(_quad(tip, p + dir * L * .5 * f - nrm * w * f, p - nrm * w * f, 6))
		_poly(ci, pts, layer[0])


# --- Face -------------------------------------------------------------------

## Face keys (art "eyes"): sep, w, h, p (pupil), one, mis (mismatched), lid,
## brow, uni (unibrow), dot, closed, hollow, iris, glow, sparkle, ink,
## mouth_ink, mouth (smile, grin, smirk, flat, frown, o, fangs, teeth, none).
static func _face(ci: CanvasItem, e: Dictionary, col: Color, c: Vector2, r: float, s: Dictionary) -> void:
	var look: Vector2 = s.look
	var eye := c + look * r * .2 + Vector2(0, -r * .08)
	var ink := Color(e.get("ink", INK.to_html()))
	if s.hit > 0.0:
		for k in [-1, 1]:
			var ec := eye + Vector2(k * r * .3, 0)
			_pline(ci, PackedVector2Array([ec + Vector2(-k * r * .12, -r * .1), ec + Vector2(k * r * .08, 0), ec + Vector2(-k * r * .12, r * .1)]), ink, maxf(1.6, r * .08))
		_ell(ci, eye + Vector2(0, r * .38), r * .12, r * .09, ink)
		return
	var open := 1.0 - float(s.blink)
	var slots := [[0, 1.0]] if e.get("one", false) else [[-1, 1.25 if e.get("mis", false) else 1.0], [1, .75 if e.get("mis", false) else 1.0]]
	for slot in slots:
		var k: int = slot[0]
		var m: float = slot[1]
		var ec := eye + Vector2(k * r * e.get("sep", 0.0), 0)
		if e.get("dot", false):
			ci.draw_circle(ec, r * .14, Color(1, 1, 1, .25))
			_ell(ci, ec, r * .07, r * .07 * maxf(.15, open), Color.WHITE)
			continue
		if e.get("closed", false):
			ci.draw_arc(ec + Vector2(0, -r * .02), r * e.w, .15 * PI, .85 * PI, 10, INK, maxf(1.5, r * .07), true)
			continue
		var w: float = r * e.w * m
		var h: float = r * e.h * m * maxf(.08, open)
		if e.get("hollow", false):
			_ell(ci, ec, w, h, Color("2a1f4a"))
			continue
		if e.has("glow"):
			_ell(ci, ec, w * 1.25, h * 1.25, Color(Color(e.glow), minf(1.0, .35 + float(s.get("eye_flash", 0.0)) * 1.5)))
		_ell(ci, ec, w, h, Color.WHITE)
		var p: float = e.p
		var pupil := ec + Vector2(look.x * w * .45, look.y * h * .45)
		if e.has("iris"):
			ci.draw_circle(pupil, minf(r * p * 1.7 * m, minf(w, h) * .95), Color(e.iris))
		ci.draw_circle(pupil, minf(r * p * m, h * .9), INK)
		ci.draw_circle(pupil - Vector2(1, 1) * r * p * .4, r * p * .35, Color.WHITE)
		if e.get("sparkle", false):
			ci.draw_colored_polygon(star_pts(pupil + Vector2(.5, .3) * r * p, r * .06, r * .02, 4), Color.WHITE)
		if e.has("lid"):
			var lid: float = e.lid
			var phi := asin(clampf(-1.0 + 2.0 * lid, -1.0, 1.0))
			var cap := ellipse_pts(ec, w, h, 0.0, PI - phi, TAU + phi, 16)
			_poly(ci, cap, shade(col, .05))
			ci.draw_line(cap[0], cap[cap.size() - 1], shade(col, -.45), maxf(1.0, r * .05), true)
		if e.has("brow"):
			var a: float = e.brow * r
			var top := ec.y - h - r * .08
			ci.draw_line(Vector2(ec.x + k * w * 1.1, top - a * .5), Vector2(ec.x - k * w * .9, top + a * .5), INK, maxf(1.6, r * .08), true)
	if e.get("uni", false):
		ci.draw_polyline(_quad(eye + Vector2(-.42, -.2) * r, eye + Vector2(0, -.08) * r, eye + Vector2(.42, -.2) * r, 10), INK, maxf(2.5, r * .13), true)
	_mouth(ci, e.get("mouth", "smile"), r, eye + Vector2(0, r * .34), float(s.hp_frac), Color(e.get("mouth_ink", INK.to_html())))


static func _mouth(ci: CanvasItem, kind: String, r: float, m: Vector2, hp_frac: float, ink: Color) -> void:
	var lw := maxf(1.4, r * .065)
	if hp_frac < .35:
		var pts := PackedVector2Array([m + Vector2(-r * .16, 0)])
		for i in range(1, 5):
			pts.append(m + Vector2(-r * .16 + i * r * .08, -r * .05 if i % 2 else 0.0))
		ci.draw_polyline(pts, ink, lw, true)
		return
	match kind:
		"smile":
			ci.draw_arc(m + Vector2(0, -r * .06), r * .13, .2 * PI, .8 * PI, 10, ink, lw, true)
		"grin":
			var pts := ellipse_pts(m + Vector2(0, -r * .04), r * .17, r * .17, 0.0, 0.0, PI, 12)
			ci.draw_colored_polygon(pts, ink)
			ci.draw_colored_polygon(ellipse_pts(m + Vector2(0, r * .08), r * .07, r * .07, 0.0, PI, TAU, 8), Color("ff6f8a"))
		"smirk":
			ci.draw_polyline(_quad(m + Vector2(-r * .13, 0), m + Vector2(r * .02, r * .08), m + Vector2(r * .15, -r * .05), 8), ink, lw, true)
		"flat":
			ci.draw_line(m + Vector2(-r * .12, r * .02), m + Vector2(r * .12, r * .02), ink, lw, true)
		"frown":
			ci.draw_arc(m + Vector2(0, r * .12), r * .12, 1.2 * PI, 1.8 * PI, 10, ink, lw, true)
		"o":
			ci.draw_colored_polygon(ellipse_pts(m + Vector2(0, r * .02), r * .06, r * .08, 0.0, 0.0, TAU - .01, 12), ink)
		"fangs":
			ci.draw_arc(m + Vector2(0, -r * .07), r * .14, .2 * PI, .8 * PI, 10, ink, lw, true)
			for k in [-1, 1]:
				var x: float = m.x + k * r * .1
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x - r * .035, m.y + r * .03), Vector2(x + r * .035, m.y + r * .03), Vector2(x, m.y + r * .15)]), Color.WHITE)
		"teeth":
			ci.draw_colored_polygon(ellipse_pts(m + Vector2(0, -r * .06), r * .2, r * .2, 0.0, .05 * PI, .95 * PI, 12), ink)
			ci.draw_rect(Rect2(m + Vector2(-.17, -.03) * r, Vector2(.34, .06) * r), Color.WHITE)


static func _hash(i: float) -> float:
	var x := sin(i * 127.1) * 43758.5453
	return x - floorf(x)
