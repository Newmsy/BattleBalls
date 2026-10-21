## Draws any Neon Critter with plain CanvasItem draw calls, for menus and the
## arena alike. Each critter's look is data in its file (sim/critters/<id>.gd,
## the "art" key): a body style, a face (eyes + mouth) and a list of features
## drawn behind ("back") and in front of ("front") the body. New critters mix
## the existing bodies, faces and features; a new feature is one more branch
## in _feature(). Call from a CanvasItem's _draw():
##   CritterArt.draw_critter(self, "vampire", centre, radius, {"t": time, "tier": 2})
## State keys (all optional): t, tier, look (Vector2), blink (0-1), hit, flash,
## stacks, eye_flash, hp_frac, pole_swap (0-1, a magnet mid-flip), silhouette
## (bool: draw as an unfound dark shape).
extends RefCounted

const Dot := preload("res://game/dot.gd")
const CritterDb := preload("res://sim/critter_db.gd")

const INK := Color("1a1530")
## The kit a critter's "art" can use; tests check every critter file against it.
const BODIES := ["gradient", "bomb", "ghost", "chrome", "starfield", "prism", "magnet", "cloud", "pixel", "eclipse"]
const FEATURES := ["cape_collar", "spike_ring", "speed_streaks", "antennae", "ice_crown", "thorn_ring", "wisp_tail", "orbit_ring",
	"swirl_arms", "flame_crest", "rock_band", "headband", "fuse", "frost_freckles", "vines", "seam", "magnet_prongs",
	"antenna2", "bandana", "barrel", "batwings", "beard", "bees", "belly", "beret", "bigtail", "bite", "bloom", "boltant",
	"boltcrest", "bow", "bulbs", "candle", "candyrings", "canopy", "cap", "chainball", "cheeks", "chestlight", "chips", "clamshell",
	"clockface", "coil", "comettail", "controlbar", "core", "corona", "crust", "cup", "door", "dorsal", "drips", "drops", "droptop",
	"drumhead", "ears", "embers", "fantail", "fizz", "flowercrown", "fluke", "foxtail", "frill", "fringe", "fur", "fuzz",
	"gearcrown", "gears", "gearstick", "gills", "glowbelly", "goggles", "hardhat", "hazard", "helmet", "hive", "hook", "horn",
	"horns", "jarlid", "jets", "key", "lamp", "leaves", "lever", "mask", "monocle", "moons", "mushroom", "napkin", "number",
	"panel", "pearl", "pods", "pot", "rears", "reels", "ringpull", "rodball", "rope", "ruff", "scoops", "segments", "shades",
	"shards", "sheen", "shellhex", "shine", "sidefins", "smoke", "snout", "snowflake", "speckles", "spikyhair", "splats", "spots",
	"starnose", "stemleaf", "sticks", "stinger", "stripe", "stripes", "sugar", "tallcrystals", "tentacles", "tiles", "tophat",
	"totemstack", "trunk", "tuft", "tufts", "tusks", "twigs", "vinewrap", "vvisor", "whiskers", "windcurls", "wings", "witchhat",
	"wrapper", "yoyo", "zighair", "zigmark"]
const MOUTHS := ["smile", "grin", "smirk", "flat", "frown", "o", "fangs", "teeth", "pout", "beak", "bigmouth", "none"]
const SILHOUETTE := Color("232052")

static var _sil := false


static func draw_critter(ci: CanvasItem, id: String, c: Vector2, r: float, s: Dictionary = {}) -> void:
	var d := CritterDb.get_critter(id)
	var st := {"t": 0.0, "tier": 1, "look": Vector2.RIGHT, "blink": 0.0, "hit": 0.0, "flash": 0.0, "stacks": 0, "hp_frac": 1.0, "pole_swap": 0.0}
	st.merge(s, true)
	st.art = d.art
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
		if st.get("ko", false):
			_ko_face(ci, c, r)
			_sil = false
			return
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
	Dot.circle(ci, p, rad, _c(col))


static func _ring(ci: CanvasItem, p: Vector2, rad: float, col: Color, w: float) -> void:
	Dot.arc(ci, p, rad, 0.0, TAU, maxi(24, int(rad)), _c(col), w, true)


static func _poly(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	if pts.size() >= 3:
		Dot.poly(ci, pts, _c(col))


static func _pline(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	if pts.size() >= 2:
		Dot.pline(ci, pts, _c(col), w, true)


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
			Dot.circle(ci, c, r * (1.0 + k * .09), Color(.7, .4, 1.0, .1))
	elif rarity == "legendary":
		var pulse := .8 + .2 * sin(t * 4.0)
		for k in 6:
			Dot.circle(ci, c, r * (1.0 + k * .09 * pulse), Color(1.0, .76, .24, .1))
		for i in 2:
			var a := t * 1.5 + i * PI
			var p := c + Vector2(cos(a), sin(a)) * r * 1.35
			Dot.poly(ci, star_pts(p, r * .12, r * .04, 4), Color(1, .95, .77, .6 + .4 * sin(t * 6.0 + i)))


## Body styles: gradient (default), bomb, ghost, chrome, starfield, prism, magnet.
static func _body_for(ci: CanvasItem, style: String, col: Color, c: Vector2, r: float, s: Dictionary) -> void:
	var t: float = s.t
	match style:
		"magnet":
			magnet_body(ci, c, r, col, Color(s.art.get("pole", "2f7bff")), s.pole_swap)
		"bomb":
			_body(ci, c, r, col)
			_ell(ci, c + Vector2(-.42, -.45) * r, r * .18, r * .1, Color(1, 1, 1, .35), -.7)
		"ghost" when s.art.get("tint", false):
			# Kit ghost in the critter's own colour (Bubbles).
			var a := .7 + .2 * sin(t * 2.0)
			_circ(ci, c, r * 1.08, Color(col, .2 * a))
			for k in 8:
				var f := k / 7.0
				_circ(ci, c + Vector2(-.3, -.35) * r * f * .9, r * (1.0 - f * .85), Color(col.lerp(Color.WHITE, f), (.55 + .35 * f) * a))
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
			if s.art.get("tint", false):
				_circ(ci, c, r, Color(col, .25))
			_ring(ci, c, r, Color("4a5466"), maxf(1.5, r * .07))
		"cloud":
			var puffs := [Vector3(-.55, .1, .55), Vector3(.55, .1, .55), Vector3(0, -.3, .65), Vector3(-.3, .35, .5), Vector3(.3, .35, .5)]
			for b in puffs:
				_circ(ci, c + Vector2(b.x, b.y) * r, (b.z + .06) * r, shade(col, -.35))
			for b in puffs:
				_circ(ci, c + Vector2(b.x, b.y) * r, b.z * r, shade(col, .35))
			_circ(ci, c + Vector2(-.2, -.4) * r, .3 * r, Color(1, 1, 1, .35))
		"pixel":
			var px := r * .25
			for y in range(-4, 4):
				for x in range(-4, 4):
					if (x + .5) * (x + .5) + (y + .5) * (y + .5) <= 15.0:
						ci.draw_rect(Rect2(c + Vector2(x, y) * px, Vector2(px + .5, px + .5)), _c(shade(col, .25) if (x + y) % 3 == 0 else col))
		"eclipse":
			_circ(ci, c, r, Color("ff9d3a"))
			for q in Geometry2D.intersect_polygons(ellipse_pts(c + Vector2(.55, -.15) * r, r * .95, r * .95, 0.0, 0.0, TAU, 40), ellipse_pts(c, r, r, 0.0, 0.0, TAU, 48)):
				_poly(ci, q, Color("242046"))
			_circ(ci, c + Vector2(-.4, -.45) * r, r * .3, Color(1, 1, 1, .3))
			_ring(ci, c, r, Color("3a2440"), maxf(1.5, r * .07))
		_ when "bite" in s.art.get("front", []):
			_bitten_body(ci, c, r, col, s.hp_frac)
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
				Dot.arc(ci, c, r, a0, a0 + TAU / segs + .02, 3, _c(Color.from_hsv(h, .7, 1.0)), maxf(2.0, r * .09), true)
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
		"magnet_prongs":
			magnet_prongs(ci, c, r, tier, t, col, Color(s.art.get("pole", "2f7bff")), s.pole_swap)
		"cape_collar":
			var h := 1.05 + .08 * tier
			for k in [-1, 1]:
				_poly(ci, PackedVector2Array([c + Vector2(k * .25, -.9) * r, c + Vector2(k * 1.12, -h) * r, c + Vector2(k * .95, -.15) * r]), shade(col, -.55))
			if tier >= 5:
				for i in 10:
					var a := i * TAU / 10 + t
					Dot.arc(ci, c, r * 1.25, a, a + .35, 4, _c(Color(1, .24, .35, .7)), 2.0, true)
		"spike_ring":
			# Each hit landed (stacks) grows one more spike and makes them all
			# longer and brighter, so a pumped-up Prickles looks it.
			var n := 8 + tier * 2 + int(s.stacks)
			var grown := minf(1.0, s.stacks / 8.0)
			var L: float = r * (.2 + .03 * tier + .45 * grown)
			var spike := Color.WHITE if s.flash > 0.0 else shade(col, -.35).lerp(Color("eaff7a"), grown * .6)
			for i in n:
				var a := float(i) / n * TAU + .2
				var w := PI / n * (.7 + .2 * grown)
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
					Dot.circle(ci, tip, r * .2, Color(.5, .9, 1.0, .3))
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
				Dot.arc(ci, c, r * (1.12 + .08 * (i % 3)), a, a + 1.4, 16, _c(arm), r * .09, true)
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
					Dot.circle(ci, c + Vector2((_hash(i + 3) - .5) * r * 1.4, -r * (.9 + p * 1.1)), r * .04, Color(1, (150 + _hash(i + 9) * 90) / 255.0, .24, 1.0 - p))
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
				Dot.circle(ci, p3, r * .3 * f, Color(1, .8, .23, .3))
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
		_:
			_C = c
			_R = r
			_kit_feature(ci, name, col, t, tier, s)
			_xf = Transform2D.IDENTITY
			_clip = false


# --- Builder-kit features (unit space) -----------------------------------------
# The roster's features are drawn in unit space: body centre (0, 0), body
# radius 1, y down, so a feature reads like its design spec. _xf moves and
# spins a part (gears, snowflakes); _clip keeps a part inside the body
# (bands, spots, stripes).

static var _C := Vector2.ZERO
static var _R := 1.0
static var _xf := Transform2D.IDENTITY
static var _clip := false
static var _clip_pts := PackedVector2Array()


static func _P(a: float, rad: float) -> Vector2:
	return Vector2(cos(a), sin(a)) * rad


static func _to_px(p: Vector2) -> Vector2:
	return _C + (_xf * p) * _R


static func _clip_on() -> void:
	_clip = true
	_clip_pts = ellipse_pts(_C, _R, _R, 0.0, 0.0, TAU, 48)
	_clip_pts.remove_at(_clip_pts.size() - 1)


static func _ufill(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	var sp := PackedVector2Array()
	var inside := true
	for p in pts:
		var q := _to_px(p)
		sp.append(q)
		inside = inside and q.distance_to(_C) <= _R
	if not _clip or inside:
		_poly(ci, sp, col)
		return
	for q in Geometry2D.intersect_polygons(sp, _clip_pts):
		_poly(ci, q, col)


static func _ustroke(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	var sp := PackedVector2Array()
	for p in pts:
		sp.append(_to_px(p))
	var width := maxf(1.0, w * _R)
	if _clip:
		for q in Geometry2D.intersect_polyline_with_polygon(sp, _clip_pts):
			_pline(ci, q, col, width)
		return
	_pline(ci, sp, col, width)
	if col.a > .99 and width > 3.0:
		_circ(ci, sp[0], width / 2.0, col)
		_circ(ci, sp[sp.size() - 1], width / 2.0, col)


## A filled stroke along pts whose width runs from w0 to w1 (tusks, tails).
static func _utaper(ci: CanvasItem, pts: PackedVector2Array, w0: float, w1: float, col: Color) -> void:
	var n := pts.size()
	if n < 2:
		return
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in n:
		var d := pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]
		if d.length() < .0001:
			continue
		var nrm := d.normalized().orthogonal() * lerpf(w0, w1, float(i) / (n - 1)) / 2.0
		left.append(pts[i] + nrm)
		right.append(pts[i] - nrm)
	right.reverse()
	left.append_array(right)
	_ufill(ci, left, col)


static func _uline(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	_ustroke(ci, PackedVector2Array([a, b]), col, w)


static func _ucirc(ci: CanvasItem, p: Vector2, rad: float, col: Color) -> void:
	if _clip:
		_uell(ci, p, rad, rad, col)
	else:
		_circ(ci, _to_px(p), rad * _R, col)


static func _uell(ci: CanvasItem, p: Vector2, rx: float, ry: float, col: Color, rot := 0.0) -> void:
	var pts := ellipse_pts(p, rx, ry, rot, 0.0, TAU, 24)
	pts.remove_at(pts.size() - 1)
	_ufill(ci, pts, col)


## The top half of an ellipse (hats, helmets, shells).
static func _udome(ci: CanvasItem, p: Vector2, rx: float, ry: float, col: Color) -> void:
	_ufill(ci, ellipse_pts(p, rx, ry, 0.0, PI, TAU, 18), col)


static func _urect(ci: CanvasItem, x: float, y: float, w: float, h: float, col: Color, rad := 0.0) -> void:
	if rad <= 0.0:
		_ufill(ci, PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)]), col)
		return
	rad = minf(rad, minf(w, h) / 2.0)
	var pts := PackedVector2Array()
	var corners := [[Vector2(x + w - rad, y + rad), -PI / 2], [Vector2(x + w - rad, y + h - rad), 0.0], [Vector2(x + rad, y + h - rad), PI / 2], [Vector2(x + rad, y + rad), PI]]
	for cn in corners:
		for i in 4:
			pts.append(cn[0] + _P(cn[1] + i * PI / 6.0, rad))
	_ufill(ci, pts, col)


static func _ustar(ci: CanvasItem, p: Vector2, r1: float, r2: float, n: int, col: Color, rot := -PI / 2) -> void:
	_ufill(ci, star_pts(p, r1, r2, n, rot), col)


static func _uarc(ci: CanvasItem, p: Vector2, rad: float, a0: float, a1: float, col: Color, w: float) -> void:
	_ustroke(ci, ellipse_pts(p, rad, rad, 0.0, a0, a1, maxi(6, int(absf(a1 - a0) * 6.0))), col, w)


static func _uring(ci: CanvasItem, p: Vector2, rad: float, col: Color, w: float) -> void:
	_uarc(ci, p, rad, 0.0, TAU, col, w)


static func _utext(ci: CanvasItem, p: Vector2, text: String, size: float, col: Color) -> void:
	var fs := maxi(6, int(size * _R))
	ci.draw_string(ThemeDB.fallback_font, _to_px(p) + Vector2(-fs, fs * .36), text, HORIZONTAL_ALIGNMENT_CENTER, fs * 2, fs, _c(col))


static func _hsl(h: float, s: float, l: float, a := 1.0) -> Color:
	h = fposmod(h, 360.0) / 360.0
	var q := l * (1.0 + s) if l < .5 else l + s - l * s
	var p := 2.0 * l - q
	var ch := func(x: float) -> float:
		x = fposmod(x, 1.0)
		if x < 1.0 / 6.0:
			return p + (q - p) * 6.0 * x
		if x < .5:
			return q
		if x < 2.0 / 3.0:
			return p + (q - p) * (2.0 / 3.0 - x) * 6.0
		return p
	return Color(ch.call(h + 1.0 / 3.0), ch.call(h), ch.call(h - 1.0 / 3.0), a)


## The default body with bites taken out of its right side (Crumb).
## Crumb's cookie: two bites out of it at full health, and a fresh chunk
## missing for every sixth of its health gone.
const CRUMB_BITES := [Vector2(-.95, .45), Vector2(.15, 1.0), Vector2(-.55, -.9), Vector2(.85, .7), Vector2(-1.0, -.2)]


static func _bitten_body(ci: CanvasItem, c: Vector2, r: float, col: Color, hp_frac := 1.0) -> void:
	var bites := [ellipse_pts(c + Vector2(.95, -.55) * r, r * .25, r * .25, 0.0, 0.0, TAU, 20), ellipse_pts(c + Vector2(1.05, -.2) * r, r * .2, r * .2, 0.0, 0.0, TAU, 20)]
	var lost := clampi(int((1.0 - hp_frac) * 6.0), 0, CRUMB_BITES.size())
	for k in lost:
		var at: Vector2 = CRUMB_BITES[k]
		bites.append(ellipse_pts(c + at * r, r * (.3 + .04 * k), r * (.3 + .04 * k), 0.0, 0.0, TAU, 20))
	var cut := func(pts: PackedVector2Array) -> Array:
		var polys: Array = [pts]
		for b in bites:
			var next: Array = []
			for p in polys:
				next.append_array(Geometry2D.clip_polygons(p, b))
			polys = next
		return polys
	var dark := shade(col, -.2)
	var light := shade(col, .45)
	var outline: Array = cut.call(ellipse_pts(c, r, r, 0.0, 0.0, TAU, 48))
	for q in outline:
		_poly(ci, q, dark)
	for k in range(1, 8):
		var f := k / 7.0
		for q in cut.call(ellipse_pts(c + Vector2(-.35, -.4) * r * f * .9, r * (1.0 - f * .82), r * (1.0 - f * .82), 0.0, 0.0, TAU, 40)):
			_poly(ci, q, dark.lerp(light, f))
	for q in outline:
		var loop: PackedVector2Array = q.duplicate()
		loop.append(q[0])
		_pline(ci, loop, shade(col, -.5), maxf(1.5, r * .07))


## Features from the roster's builder kit, in unit space (see _C/_R above).
## `n` is the tier.
static func _kit_feature(ci: CanvasItem, name: String, c: Color, t: float, n: int, s: Dictionary = {}) -> void:
	match name:
		"antenna2":
			for k in [-1, 1]:
				_uline(ci, Vector2(k * .3, -.85), Vector2(k * .55, -1.4), shade(c, -.5), .05)
				_ucirc(ci, Vector2(k * .58, -1.45), .09, Color("f6ff9a"))
		"bandana":
			_clip_on()
			_urect(ci, -1, -.75, 2, .25, Color("1c1c2a"))
			_clip = false
			for i in 6:
				_ucirc(ci, Vector2(-.8 + i * .32, -.63), .04, Color.WHITE)
			_ufill(ci, PackedVector2Array([Vector2(.85, -.65), Vector2(1.25, -.45), Vector2(1.05, -.8)]), Color("1c1c2a"))
		"barrel":
			_urect(ci, -.18, -1.45, .36, .65, Color("4d5a2a"), .06)
			_urect(ci, -.24, -1.5, .48, .14, Color("2f3818"), .04)
		"batwings":
			for k in [-1, 1]:
				_ufill(ci, PackedVector2Array([Vector2(k * .85, -.2), Vector2(k * 1.55, -.5), Vector2(k * 1.4, -.1), Vector2(k * 1.55, .2), Vector2(k * .85, .25)]), shade(c, -.4))
		"beard":
			for i in 6:
				_ufill(ci, PackedVector2Array([Vector2(-.45 + i * .18, .5), Vector2(-.36 + i * .18, 1.05 - absf(i - 2.5) * .1), Vector2(-.27 + i * .18, .5)]), Color("6aa84f"))
		"bees":
			for i in 3:
				var a := t * 1.8 + i * 2.09
				var p := Vector2(cos(a) * 1.4, sin(a) * .7 - .2)
				_uell(ci, p, .14, .1, Color("ffd23f"))
				_uline(ci, p + Vector2(0, -.1), p + Vector2(0, .1), Color("222222"), .04)
				_uell(ci, p + Vector2(0, -.12), .08, .05, Color(1, 1, 1, .8))
		"belly":
			_clip_on()
			_uell(ci, Vector2(0, .75), .7, .45, shade(c, .55))
		"beret":
			_uell(ci, Vector2(-.15, -.82), .7, .3, Color("d6336c"), -.2)
			_ucirc(ci, Vector2(-.15, -1.1), .07, Color("d6336c"))
		"bigtail":
			_uell(ci, Vector2(.75, -.75), .55, .4, Color("efe6ff"), .6)
			_uell(ci, Vector2(.9, -.9), .3, .2, Color.WHITE, .6)
		"bite":
			pass # Cut out of the body itself: see _bitten_body.
		"bloom":
			_clip_on()
			_uell(ci, Vector2(-.3, -.4), .5, .3, Color(1, 1, 1, .18), -.4)
		"boltant":
			_ufill(ci, PackedVector2Array([Vector2(.05, -.85), Vector2(-.15, -1.2), Vector2(.05, -1.2), Vector2(-.1, -1.55), Vector2(.25, -1.1), Vector2(.05, -1.1), Vector2(.2, -.85)]), Color("ffe14a"))
		"boltcrest":
			for i in 3:
				_xf = Transform2D((i - 1) * .45, Vector2.ZERO)
				_ufill(ci, PackedVector2Array([Vector2(.05, -.85), Vector2(-.15, -1.25), Vector2(.05, -1.25), Vector2(-.1, -1.65), Vector2(.25, -1.15), Vector2(.05, -1.15), Vector2(.2, -.85)]), Color("ffe14a") if i == 1 else Color("ffb627"))
		"bow":
			for k in [-1, 1]:
				_ufill(ci, PackedVector2Array([Vector2(0, -1), Vector2(k * .55, -1.35), Vector2(k * .55, -.7)]), Color("ff5c9a"))
			_ucirc(ci, Vector2(0, -1.02), .12, Color("ff8fb8"))
		"bulbs":
			var k := n + 2
			for i in k:
				var a := PI * .15 + float(i) / (k - 1) * PI * .7
				_ucirc(ci, _P(a, .87), .07, Color("ffe14a") if sin(t * 5.0 + i) > 0.0 else Color("7d6a2a"))
		"candle":
			if s.get("phased", false):
				# Faded out: the flame is snuffed, leaving a glowing wick and a curl of smoke.
				_ucirc(ci, Vector2(0, -1.07), .05, Color("ff5a1f"))
				for i in 3:
					var p := fmod(t * .9 + i / 3.0, 1.0)
					_ucirc(ci, Vector2(sin(t * 3.0 + i * 2.0) * .12, -1.15 - p * .7), .07 + p * .12, Color(.75, .72, .8, .55 * (1.0 - p)))
			else:
				var fl := 1.0 + .15 * sin(t * 10.0)
				_uell(ci, Vector2(0, -1.25), .16, .3 * fl, Color("ff8a1f"))
				_uell(ci, Vector2(0, -1.18), .08, .16 * fl, Color("ffe066"))
			_uline(ci, Vector2(0, -.95), Vector2(0, -1.05), INK, .04)
		"candyrings":
			var rings := [.9, .7, .5, .3]
			for i in rings.size():
				_uring(ci, Vector2.ZERO, rings[i], _hsl(i * 70 + 160, .7, .6 + i * .05), .09)
		"canopy":
			var leaves := [Vector3(-.6, -.85, .45), Vector3(.6, -.85, .45), Vector3(0, -1.15, .55), Vector3(-.25, -.95, .4), Vector3(.3, -1.05, .4)]
			for i in leaves.size():
				var b: Vector3 = leaves[i]
				_ucirc(ci, Vector2(b.x, b.y + sin(t + i) * .02), b.z, Color("3f8f3a") if i % 2 else Color("58b04a"))
		"cap":
			_udome(ci, Vector2(0, -.6), .75, .4, Color("3a4a1a"))
			_urect(ci, -.1, -.62, .9, .1, Color("2a3510"), .05)
			_ustar(ci, Vector2(0, -.8), .1, .045, 5, Color("ffd23f"))
		"chainball":
			var e := _P(t * 1.3, 1.7)
			_uline(ci, Vector2.ZERO, e, Color(1, .82, .31, .8), .06)
			_ucirc(ci, e, .35, Color("3c4250"))
			_ucirc(ci, e - Vector2(.1, .1), .1, Color("6b7486"))
		"cheeks":
			for k in [-1, 1]:
				_uell(ci, Vector2(k * .52, .22), .14, .09, Color(1, .47, .59, .6))
		"chestlight":
			_ucirc(ci, Vector2(0, .55), .13, Color("ffe14a"))
			_ucirc(ci, Vector2(0, .55), .22, Color(1, .88, .29, .2 + .15 * sin(t * 3.0)))
		"chips":
			for p in [Vector2(-.55, -.4), Vector2(.6, -.25), Vector2(-.3, .6), Vector2(.45, .55), Vector2(0, -.7), Vector2(-.75, .2)]:
				_uell(ci, p, .09, .07, Color("4a2a14"))
		"clamshell":
			_uline(ci, Vector2(-1, .05), Vector2(1, .05), shade(c, -.45), .07)
			for i in range(-3, 4):
				_uline(ci, Vector2(i * .22, -.9 + absi(i) * .05), Vector2(i * .3, -.05), shade(c, -.25), .04)
				_uline(ci, Vector2(i * .22, .95 - absi(i) * .05), Vector2(i * .3, .15), shade(c, -.25), .04)
		"clockface":
			_ucirc(ci, Vector2(0, .3), .5, Color("fdf3d8"))
			_uring(ci, Vector2(0, .3), .5, Color("7a5a1e"), .05)
			_uline(ci, Vector2(0, .3), Vector2(0, .3) + _P(t, .38), INK, .04)
			_uline(ci, Vector2(0, .3), Vector2(0, .3) + _P(t / 12.0, .25), INK, .05)
		"coil":
			_clip_on()
			for i in range(-3, 4):
				_uarc(ci, Vector2(0, i * .25), 1.05, PI * .15, PI * .85, Color("d98a4a"), .06)
		"comettail":
			for i in 5:
				var y := (i - 2) * .25
				var d := absi(i - 2)
				_uline(ci, Vector2(-.6, y * .9), Vector2(-1.4 - _hash(i) * .4, y * 1.4 + sin(t * 6.0 + i) * .06), Color(c, .5 - d * .1), .2 - d * .04)
		"controlbar":
			var y := -1.75 + sin(t * 2.0) * .05
			_urect(ci, -.6, y, 1.2, .08, Color("c9a46a"))
			_urect(ci, -.04, y - .3, .08, .65, Color("c9a46a"))
			for x in [-.55, .55]:
				_uline(ci, Vector2(x, y + .08), Vector2(x * 1.2, .2), Color(1, .9, .55, .5), .02)
		"core":
			_ucirc(ci, Vector2(0, .35), .22 + .03 * sin(t * 5.0), Color(1, 1, 1, .9))
		"corona":
			for i in 16:
				var a := i * .3927 + t * .3
				var L := 1.25 + .15 * sin(t * 4.0 + i * 2)
				_ufill(ci, PackedVector2Array([_P(a - .12, .95), _P(a, L), _P(a + .12, .95)]), Color(1, .84, .47, .7))
		"crust":
			_clip_on()
			for b in [Vector3(-.6, -.5, .3), Vector3(.5, .4, .35), Vector3(.55, -.6, .2), Vector3(-.4, .6, .22)]:
				_uell(ci, Vector2(b.x, b.y), b.z, b.z * .7, Color(.24, .08, .04, .55))
		"cup":
			_clip_on()
			_urect(ci, -1, .15, 2, 1, Color("e0a85a"))
			for i in range(-4, 5):
				_uline(ci, Vector2(i * .25, .15), Vector2(i * .25 + .4, 1), Color("b87a35"), .03)
				_uline(ci, Vector2(i * .25, .15), Vector2(i * .25 - .4, 1), Color("b87a35"), .03)
		"door":
			_uell(ci, Vector2(0, .55), .17, .2, Color("3a2210"))
		"dorsal":
			_ufill(ci, PackedVector2Array([Vector2(-.35, -.85), Vector2(.15, -1.5), Vector2(.4, -.8)]), shade(c, -.25))
		"drips":
			_clip_on()
			for i in 7:
				_uell(ci, Vector2(-.9 + i * .3, -.5 + (i % 2) * .06), .1, .14 + (i % 3) * .05, shade(c, .3))
		"drops":
			for i in 4:
				var p := fmod(t * .8 + i / 4.0, 1.0)
				_uell(ci, Vector2(-.45 + i * .3, .8 + p * .7), .05, .09, Color(.59, .75, 1.0, 1.0 - p))
		"droptop":
			_ufill(ci, PackedVector2Array([Vector2(-.55, -.8), Vector2(0, -1.6), Vector2(.55, -.8)]), shade(c, -.1))
		"drumhead":
			_clip_on()
			_urect(ci, -1, -1, 2, .45, Color("f6ecd9"))
			_clip = false
			_uline(ci, Vector2(-.84, -.55), Vector2(.84, -.55), Color("c9b48a"), .06)
		"ears":
			for k in [-1, 1]:
				_ufill(ci, PackedVector2Array([Vector2(k * .35, -.8), Vector2(k * .8, -1.45), Vector2(k * .85, -.5)]), shade(c, -.3))
				_ufill(ci, PackedVector2Array([Vector2(k * .45, -.75), Vector2(k * .76, -1.22), Vector2(k * .78, -.6)]), shade(c, .35))
		"embers":
			_clip_on()
			var cracks := [[Vector2(-.7, -.3), Vector2(-.3, -.1), Vector2(-.4, .3)], [Vector2(.5, -.6), Vector2(.3, -.2), Vector2(.6, .1)], [Vector2(-.1, .5), Vector2(.3, .7)]]
			for i in cracks.size():
				_ustroke(ci, PackedVector2Array(cracks[i]), Color(1, (120 + 60 * sin(t * 4.0 + i)) / 255.0, .16, .95), .06)
		"fantail":
			_ufill(ci, PackedVector2Array([Vector2(-.85, 0), Vector2(-1.5, -.55), Vector2(-1.35, 0), Vector2(-1.5, .55)]), shade(c, -.15))
		"fizz":
			# Pressure (0-1) shakes the can up: more, faster bubbles.
			var pr: float = s.get("pressure", 0.0)
			_clip_on()
			for i in 9 + int(pr * 14.0):
				var p := fmod(t * (.4 + 1.8 * pr) + _hash(i), 1.0)
				_ucirc(ci, Vector2((_hash(i + 4) - .5) * 1.4, .9 - p * 1.8), .04 + _hash(i + 7) * .04, Color(1, 1, 1, .55 + .3 * pr))
		"flowercrown":
			for i in 5:
				var p := _P(-PI / 2 + (i - 2) * .38, 1.0)
				for j in 5:
					_ucirc(ci, p + _P(j * 1.256, .1), .08, Color("ffb3d1") if i % 2 else Color("fff1a8"))
				_ucirc(ci, p, .06, Color("ff8a3d"))
		"fluke":
			_ufill(ci, PackedVector2Array([Vector2(.85, .3), Vector2(1.45, .05), Vector2(1.25, .4), Vector2(1.45, .75)]), shade(c, -.2))
		"foxtail":
			_uell(ci, Vector2(-.95, .45), .55, .3, shade(c, -.1), -.5)
			_uell(ci, Vector2(-1.35, .2), .2, .15 + .03 * sin(t * 8.0), Color("5fb7ff"), -.5)
		"frill":
			for i in 5:
				_ufill(ci, PackedVector2Array([_P(-2.4 + i * .22, .9), _P(-2.3 + i * .22, 1.35), _P(-2.2 + i * .22, .9)]), Color("5ee6d0"))
		"fringe":
			_clip_on()
			for i in 9:
				_ufill(ci, PackedVector2Array([Vector2(-1 + i * .25, -1), Vector2(-.88 + i * .25, -.05), Vector2(-.76 + i * .25, -1)]), shade(c, -.08))
		"fur":
			for i in 22:
				var a := i / 22.0 * TAU
				_ufill(ci, PackedVector2Array([_P(a - .15, .9), _P(a, 1.15), _P(a + .15, .9)]), shade(c, -.15))
		"fuzz":
			for i in 26:
				_ucirc(ci, _P(i / 26.0 * TAU, .97), .1, shade(c, -.15))
		"gearcrown":
			var gears := [Vector3(-.4, -1.05, .22), Vector3(0, -1.18, .28), Vector3(.4, -1.05, .22)]
			for i in gears.size():
				var g: Vector3 = gears[i]
				_xf = Transform2D(t * (-1.0 if i % 2 else 1.0), Vector2(g.x, g.y))
				_ustar(ci, Vector2.ZERO, g.z, g.z * .75, 8, Color("e0b04a"), 0.0)
				_ucirc(ci, Vector2.ZERO, g.z * .4, Color("7a5a1e"))
		"gears":
			_xf = Transform2D(t * (.5 + 9.0 * float(s.get("wind", 0.0))), Vector2.ZERO) # Spins faster as Cogs winds up.
			for i in 14:
				var a := i / 14.0 * TAU
				_urect(ci, cos(a) * 1.05 - .09, sin(a) * 1.05 - .09, .18, .18, Color("b8743f"))
		"gearstick":
			_uline(ci, Vector2(0, -.85), Vector2(0, -1.3), Color("666666"), .07)
			_ucirc(ci, Vector2(0, -1.38), .13, Color("222222"))
		"gills":
			for k in [-1, 1]:
				for i in 3:
					_uarc(ci, Vector2(k * .75, .1 + i * .13), .15, 2.4 if k > 0 else -.7, 3.8 if k > 0 else .7, Color("7af5e6"), .035)
		"glowbelly":
			_clip_on()
			_uell(ci, Vector2(0, .8), .9, .55, Color(.92, 1, .47, .55 + .3 * sin(t * 3.0)))
		"goggles":
			_clip_on()
			_urect(ci, -1, -.25, 2, .12, Color("333333"))
			_clip = false
			for k in [-1, 1]:
				_uring(ci, Vector2(k * .3, -.15), .2, Color("555555"), .07)
		"hardhat":
			_udome(ci, Vector2(0, -.5), .9, .55, Color("ffcc1f"))
			_urect(ci, -1, -.52, 2, .1, Color("ffcc1f"))
			_urect(ci, -.75, -.32, 1.5, .26, Color(.16, .78, 1, .75), .1)
		"hazard":
			_clip_on()
			for i in range(-6, 6):
				_ufill(ci, PackedVector2Array([Vector2(i * .25, .45), Vector2(i * .25 + .125, .45), Vector2(i * .25 + .325, .75), Vector2(i * .25 + .2, .75)]), Color("ffcc1f") if i % 2 else Color("1a1a1a"))
			_urect(ci, -1, .44, 2, .02, Color("1a1a1a"))
		"helmet":
			_udome(ci, Vector2(0, -.55), .85, .5, Color("e3b23c"))
			_ucirc(ci, Vector2(0, -.8), .16, Color("fffbd0"))
			_ucirc(ci, Vector2(0, -.8), .3, Color(1, .98, .78, .3))
		"hive":
			_clip_on()
			for i in range(-3, 4):
				_uline(ci, Vector2(-1, i * .28), Vector2(1, i * .28), shade(c, -.3), .05)
		"hook":
			_uline(ci, Vector2(.9, -.3), Vector2(1.3, -.9), Color("b08a5a"), .05)
			_uarc(ci, Vector2(1.25, -1.05), .17, PI * .1, -PI * .7, Color("cfd6e2"), .08)
		"horn":
			_ufill(ci, PackedVector2Array([Vector2(-.08, -.92), Vector2(.55, -1.75), Vector2(.1, -.9)]), Color("f6f1e4"))
			for i in range(1, 5):
				_uline(ci, Vector2(-.02 + i * .12, -.95 - i * .17), Vector2(.1 + i * .12, -.95 - i * .17), Color("c9bfa6"), .03)
		"horns":
			for k in [-1, 1]:
				_ufill(ci, PackedVector2Array([Vector2(k * .3, -.85), Vector2(k * .55, -1.35), Vector2(k * .62, -.75)]), Color("f2e6c8"))
		"jarlid":
			_clip_on()
			_urect(ci, -1, -1, 2, .45, Color("ffd23f"))
			for i in 4:
				_urect(ci, -1 + i * .55, -1, .25, .45, Color("2a2015"))
		"jets":
			for k in [-1, 1]:
				_xf = Transform2D(t * .4, Vector2.ZERO)
				var pts := PackedVector2Array([Vector2(0, -.12), Vector2(k * 1.9, -.25), Vector2(k * 1.9, .25), Vector2(0, .12)])
				var sp := PackedVector2Array()
				for p in pts:
					sp.append(_to_px(p))
				var hot := _c(Color(1, 1, 1, .95))
				var cold := _c(Color(.71, .55, 1, 0))
				ci.draw_polygon(sp, PackedColorArray([hot, cold, cold, hot]))
		"key":
			_xf = Transform2D(t * 2.0, Vector2(1.1, 0))
			_urect(ci, -.25, -.06, .5, .12, Color("d9a35a"))
			_uell(ci, Vector2(-.3, 0), .1, .2, Color("d9a35a"))
			_uell(ci, Vector2(.3, 0), .1, .2, Color("d9a35a"))
			_xf = Transform2D.IDENTITY
			_uline(ci, Vector2(.9, 0), Vector2(1.1, 0), Color("d9a35a"), .08)
		"lamp":
			_urect(ci, -.28, -1.4, .56, .55, Color("d8f6ff"), .06)
			_uline(ci, Vector2(-.28, -1.12), Vector2(.28, -1.12), Color("2a5d5a"), .04)
			_ucirc(ci, Vector2(0, -1.12), .14, Color("fff2a0"))
			_ufill(ci, PackedVector2Array([Vector2(-.36, -1.4), Vector2(0, -1.65), Vector2(.36, -1.4)]), Color("c43c3c"))
			var a := t * 1.5
			_ufill(ci, PackedVector2Array([Vector2(0, -1.12), Vector2(cos(a) * 2.2, -1.32 + sin(a) * .5), Vector2(cos(a) * 2.2, -.92 + sin(a) * .5)]), Color(1, .94, .59, .18))
		"leaves":
			for k in [-1, 1]:
				_uell(ci, Vector2(k * .35, -1.15), .32, .14, Color("3fc45a"), k * -.7)
		"lever":
			_uline(ci, Vector2(.9, 0), Vector2(1.3, -.7), Color("c9ced8"), .07)
			_ucirc(ci, Vector2(1.32, -.75), .13, Color("e0213b"))
		"mask":
			_clip_on()
			_uell(ci, Vector2(0, -.1), .8, .32, shade(c, .55))
		"monocle":
			_uring(ci, Vector2(.3, -.08), .26, Color("e0b04a"), .05)
			_uline(ci, Vector2(.55, -.05), Vector2(.7, .5), Color("e0b04a"), .02)
		"moons":
			for i in n:
				_ucirc(ci, _P(t * (1.0 + i * .3) + i * 1.7, 1.35), .1, _hsl(i * 80, .8, .7))
		"mushroom":
			_urect(ci, .1, -1.15, .12, .3, Color("f3e7d3"))
			_udome(ci, Vector2(.16, -1.15), .32, .22, Color("e0413b"))
			_ucirc(ci, Vector2(.06, -1.25), .05, Color.WHITE)
			_ucirc(ci, Vector2(.28, -1.22), .04, Color.WHITE)
		"napkin":
			_ufill(ci, PackedVector2Array([Vector2(-.45, .55), Vector2(0, 1.05), Vector2(.45, .55)]), Color.WHITE)
			_uline(ci, Vector2(-.45, .55), Vector2(.45, .55), Color("e85d5d"), .06)
		"number":
			_ucirc(ci, Vector2(.55, .45), .22, Color.WHITE)
			_utext(ci, Vector2(.55, .47), "7", .3, INK)
		"panel":
			_urect(ci, -.4, .35, .8, .4, Color(0, 0, 0, .25), .06)
			for p in [Vector2(-.32, .43), Vector2(.32, .43), Vector2(-.32, .67), Vector2(.32, .67)]:
				_ucirc(ci, p, .035, Color("cfe3ff"))
		"pearl":
			_ucirc(ci, Vector2(0, .45), .14, Color("fbf6ff"))
			_ucirc(ci, Vector2(-.04, .41), .04, Color.WHITE)
		"pods":
			for k in [-1, 1]:
				_urect(ci, k * .95 - .22, -.75, .44, .55, Color("5d7699"), .1)
				for j in 2:
					_ucirc(ci, Vector2(k * .95, -.6 + j * .22), .07, Color("ff6a3d"))
		"pot":
			_clip_on()
			_urect(ci, -1, -.95, 2, .35, Color("7dff6a"))
			for i in 4:
				_ucirc(ci, Vector2(-.6 + i * .4, -.62 - absf(sin(t * 3.0 + i)) * .1), .08, Color("b8ff9e"))
			_clip = false
			_uline(ci, Vector2(-.8, -.6), Vector2(.8, -.6), Color("1d2a1d"), .07)
		"rears":
			for k in [-1, 1]:
				_uell(ci, Vector2(k * .95, -.25), .25, .12, Color("c9d0db"), k * .5)
		"reels":
			_urect(ci, -.7, -.35, 1.4, .5, Color("fdf3d8"), .08)
			for i in 3:
				var p := Vector2(-.45 + i * .45, -.1)
				match int(floorf(t * 4.0 + i * 1.3)) % 3:
					0:
						_utext(ci, p, "7", .3, INK)
					1:
						_ustar(ci, p, .13, .055, 5, INK)
					_:
						_ufill(ci, PackedVector2Array([p + Vector2(0, -.13), p + Vector2(.1, 0), p + Vector2(0, .13), p + Vector2(-.1, 0)]), INK)
		"ringpull":
			_uell(ci, Vector2(.15, -1), .25, .14, Color("c8ced8"))
			_uell(ci, Vector2(.15, -1), .12, .06, Color("7d1a4a"))
		"rodball":
			_uline(ci, Vector2(0, -.85), Vector2(0, -1.4), Color("8a6239"), .08)
			_ucirc(ci, Vector2(0, -1.5), .17 + .02 * sin(t * 20.0), Color("b4f2ff"))
			_ucirc(ci, Vector2(0, -1.5), .3, Color(.59, .9, 1, .25))
		"rope":
			_clip_on()
			var pts := PackedVector2Array()
			for i in 11:
				pts.append(Vector2(-1 + i * .2, .2 if i % 2 else .65))
			_ustroke(ci, pts, Color("f6ecd9"), .06)
		"ruff":
			for i in 9:
				_ufill(ci, PackedVector2Array([Vector2(-.9 + i * .225, .45), Vector2(-.79 + i * .225, .8), Vector2(-.68 + i * .225, .45)]), Color("f4f7ff"))
			_clip_on()
			_urect(ci, -1, .62, 2, .5, Color("f4f7ff"))
		"scoops":
			var scoops := [[Color("ffb3c7"), -.35, -.9], [Color("fff1d6"), .35, -.95], [Color("8a5a3a"), 0.0, -1.3]]
			var count := mini(3, 1 + ceili(n / 2.0))
			var live: int = s.get("live_stacks", -1)
			if live >= 0:
				# In a fight: one scoop per stack, piling higher (up to 5).
				var flavours := [Color("ffb3c7"), Color("fff1d6"), Color("8a5a3a"), Color("9be7c4"), Color("c9a7ff")]
				var top := -.9
				for i in mini(live, 5):
					top = -.9 - i * .32
					_ucirc(ci, Vector2(sin(i * 2.1) * .12, top), .4 - i * .03, flavours[i])
					_ucirc(ci, Vector2(sin(i * 2.1) * .12 - .14, top - .12), .07, Color(1, 1, 1, .5))
				_ucirc(ci, Vector2(.05, top - .38), .12, Color("e0213b"))
			else:
				for i in count:
					_ucirc(ci, Vector2(scoops[i][1], scoops[i][2]), .38, scoops[i][0])
				# The cherry sits on the top scoop (the spec floats it at T3+ height).
				_ucirc(ci, Vector2(.05, -1.75 if count >= 3 else -1.38), .12, Color("e0213b"))
		"segments": # A serpent tail out of the back, with glowing stinger rings and a fluke.
			if s.get("live_tail", false):
				return # In a fight the tail follows its path (arena_view draws it from the sim).
			var sway := sin(t * 3.0) * .12
			var tail := _quad(Vector2(-.5, .35), Vector2(-1.35, .95 + sway), Vector2(-1.5, .05 - sway), 12)
			var tip := tail[tail.size() - 1]
			var back := (tip - tail[tail.size() - 2]).normalized()
			for k in [-1, 1]:
				_ufill(ci, PackedVector2Array([tip - back * .05, tip + back.rotated(k * .9) * .38, tip + back.rotated(k * .35) * .22]), Color("5ee6d0"))
			_utaper(ci, tail, .7, .22, shade(c, -.45))
			_utaper(ci, tail, .6, .14, c)
			for i in [4, 7, 10]:
				_uring(ci, tail[i], .16 - i * .008, Color("5ff0e6", .85), .045)
		"shades":
			for k in [-1, 1]:
				_ustar(ci, Vector2(k * .3, -.1), .2, .1, 5, Color("1a1530"))
		"shards":
			_clip_on()
			for i in 8:
				var a := i * .785 + floorf(t / 1.2) * .785
				_ufill(ci, PackedVector2Array([Vector2.ZERO, _P(a, 1.2), _P(a + .785, 1.2)]), _hsl(i * 45 + 300, .8, .65, .45))
		"sheen":
			_uarc(ci, Vector2.ZERO, .8, -2.6, -1.4, _hsl(t * 60.0, .9, .75, .6), .08)
			_uarc(ci, Vector2.ZERO, .7, -2.4, -1.6, _hsl(t * 60.0 + 120.0, .9, .75, .5), .06)
		"shellhex":
			_udome(ci, Vector2(0, -.05), 1.02, .85, shade(c, -.3))
			for i in range(-2, 3):
				_ustar(ci, Vector2(i * .38, -.45 + absi(i) * .12), .17, .17, 3, shade(c, .05), 0.0)
		"shine":
			_uell(ci, Vector2(-.4, -.35), .15, .3, Color(1, 1, 1, .6), .5)
		"sidefins":
			for k in [-1, 1]:
				_ufill(ci, PackedVector2Array([Vector2(k * .9, -.2), Vector2(k * 1.35, .1), Vector2(k * .9, .35)]), shade(c, -.2))
		"smoke":
			for i in 3:
				var p := fmod(t * .5 + i / 3.0, 1.0)
				_ucirc(ci, Vector2(.2 + sin(i * 2.0) * .2, -1 - p * .8), .12 + p * .15, Color(.63, .59, .67, .5 * (1.0 - p)))
		"snout":
			_urect(ci, .62, -.02, .45, .3, shade(c, -.1), .1)
			_uell(ci, Vector2(1.06, .13), .07, .14, INK)
		"snowflake":
			_xf = Transform2D(t * .5, Vector2(0, -1.2))
			for i in 6:
				_uline(ci, Vector2.ZERO, _P(i * 1.047, .4), Color("f2fbff"), .07)
			_ucirc(ci, Vector2.ZERO, .1, Color("f2fbff"))
		"speckles":
			_clip_on()
			for i in 12:
				_ucirc(ci, Vector2((_hash(i) - .5) * 1.8, (_hash(i + 3) - .5) * 1.6), .035, shade(c, -.3))
		"spikyhair":
			for i in 5:
				var x := -.6 + i * .3
				_ufill(ci, PackedVector2Array([Vector2(x - .14, -.75), Vector2(x, -1.3), Vector2(x + .14, -.75)]), shade(c, -.25))
		"splats":
			_clip_on()
			for sp in [[Color("ff5a7a"), -.55, -.5], [Color("45c4ff"), .5, -.1], [Color("7ee36a"), -.2, .6], [Color("ffd23f"), .6, .55]]:
				var p := Vector2(sp[1], sp[2])
				_ucirc(ci, p, .14, sp[0])
				_ucirc(ci, p + Vector2(.12, -.1), .05, sp[0])
		"spots":
			_clip_on()
			for p in [Vector2(-.6, -.5), Vector2(.55, -.6), Vector2(-.7, .4), Vector2(.65, .35), Vector2(0, .75)]:
				_uell(ci, p, .13, .1, shade(c, -.35))
		"starnose":
			_ustar(ci, Vector2(0, .3), .22, .1, 8, Color("ff8fb1"))
			_ucirc(ci, Vector2(0, .3), .08, Color("ff6f9a"))
		"stemleaf":
			_uline(ci, Vector2(0, -.9), Vector2(.05, -1.2), Color("5b3a1e"), .07)
			_uell(ci, Vector2(.25, -1.18), .2, .08, Color("4caf50"), -.4)
		"sticks":
			for k in [-1, 1]:
				_uline(ci, Vector2(k * .3, -.8), Vector2(k * .7, -1.45), Color("d9a35a"), .08)
				_ucirc(ci, Vector2(k * .72, -1.5), .1, Color("f6ecd9"))
		"stinger":
			_ufill(ci, PackedVector2Array([Vector2(-.85, .3), Vector2(-1.3, .55), Vector2(-.8, .55)]), Color("222222"))
		"stripe":
			_clip_on()
			_urect(ci, -.12, -1, .24, 2, Color(1, 1, 1, .85))
		"stripes":
			_clip_on()
			for i in range(-2, 3):
				_urect(ci, -1, i * .42 + .05, 2, .16, Color(.08, .08, .12, .8))
		"sugar":
			_clip_on()
			for i in 18:
				_ucirc(ci, Vector2((_hash(i) - .5) * 1.8, (_hash(i + 9) - .5) * 1.8), .03, Color(1, 1, 1, .75))
		"tallcrystals":
			for i in 5:
				var x := (i - 2) * .22
				var h := .75 if i == 2 else (.5 if i % 2 else .38)
				_ufill(ci, PackedVector2Array([Vector2(x - .09, -.82), Vector2(x, -.85 - h), Vector2(x + .09, -.82)]), Color("f4ecff") if i == 2 else Color("d9ccff"))
		"tentacles":
			for i in 5:
				var x := -.6 + i * .3
				var pts := PackedVector2Array()
				for j in 6:
					pts.append(Vector2(x + sin(t * 3.0 + i + j * .8) * .1, .6 + j * .14))
				_ustroke(ci, pts, shade(c, -.2), .16 - .01 * i)
		"tiles":
			_clip_on()
			for yi in 10:
				for xi in 10:
					var x := -1.0 + xi * .22
					var y := -1.0 + yi * .22
					_urect(ci, x + .01, y + .01, .2, .2, Color(1, 1, 1, .08 + _hash(x * 9.0 + y * 31.0) * .35))
		"tophat":
			_uell(ci, Vector2(0, -.88), .5, .1, Color("1c1622"))
			_urect(ci, -.3, -1.4, .6, .55, Color("1c1622"), .04)
			_urect(ci, -.3, -1, .6, .08, Color("c4364f"))
		"totemstack":
			# A little more compact than the spec (step .55, height .5) so the T3+
			# stack stays inside a collection cell.
			var faces := mini(3, n)
			if s.get("live_stacks", -1) >= 0: # In a fight: one carved face per stack.
				faces = mini(4, int(s.live_stacks))
			for i in faces:
				var y := -1.12 - i * .46
				_urect(ci, -.42, y - .22, .84, .44, Color("ffd23f") if i == 3 else shade(c, -.15 * (i + 1)), .1)
				if s.get("live_stacks", -1) >= 0 and i < 3: # Each face's buff: harder hits, tougher body, faster roll.
					_urect(ci, -.42, y + .14, .84, .08, [Color("ff5a5a"), Color("5ab0ff"), Color("ffe066")][i], .04)
				_ucirc(ci, Vector2(-.17, y - .03), .07, INK)
				_ucirc(ci, Vector2(.17, y - .03), .07, INK)
				_uline(ci, Vector2(-.15, y + .13), Vector2(.15, y + .13), INK, .04)
		"trunk": # Tapers down between the tusks and curls at the tip.
			var trunk := _quad(Vector2(0, .12), Vector2(.1, .85), Vector2(-.16, 1.1), 10)
			_utaper(ci, trunk, .34, .16, shade(c, -.35))
			_utaper(ci, trunk, .27, .1, shade(c, -.08))
			_uring(ci, Vector2(-.22, 1.04), .07, shade(c, -.08), .07)
		"tuft":
			for k in [-1, 1]:
				_uell(ci, Vector2(k * .15, -1.08), .2, .08, Color("2f9e44"), k * -.9)
		"tufts":
			for i in 16:
				var a := i / 16.0 * TAU
				_ufill(ci, PackedVector2Array([_P(a - .15, .9), _P(a, 1.22), _P(a + .15, .9)]), shade(c, .15))
		"tusks": # Thick at the cheek, sweeping out and down, then curling in to a point.
			for k in [-1, 1]:
				var tusk := _quad(Vector2(k * .3, .28), Vector2(k * 1.05, .78), Vector2(k * .42, 1.02), 10)
				_utaper(ci, tusk, .23, .07, Color("a8916a"))
				_utaper(ci, tusk, .16, .02, Color("f5eedb"))
		"twigs":
			_clip_on()
			for i in 9:
				var p := _P(_hash(i) * 3.14 + 1.5, 1.2)
				var dy := _hash(i + 5) - .5
				_uline(ci, Vector2(-p.x, -p.y + dy), Vector2(p.x, p.y + dy), shade(c, -.35), .05)
		"vinewrap":
			_clip_on()
			for j in 2:
				var wave := func(x: float) -> float: return -.1 + j * .6 + sin(x * 3.0 + j) * .2
				var pts := PackedVector2Array()
				for i in 26:
					pts.append(Vector2(-1 + i * .08, wave.call(-1 + i * .08)))
				_ustroke(ci, pts, Color("1f6b3a"), .09)
				for x in [-.7, -.25, .2, .65]:
					_uell(ci, Vector2(x, wave.call(x) - .1), .1, .07, Color("5ee08a"), .5)
		"vvisor":
			_ufill(ci, PackedVector2Array([Vector2(-.75, -.35), Vector2(0, -.05), Vector2(.75, -.35), Vector2(.7, -.15), Vector2(0, .12), Vector2(-.7, -.15)]), Color(.35, .9, 1, .75 + .2 * sin(t * 4.0)))
		"whiskers":
			for k in [-1, 1]:
				for i in range(-1, 2):
					_uline(ci, Vector2(k * .3, .35), Vector2(k * .85, .3 + i * .12), Color(.16, .12, .12, .6), .025)
		"windcurls":
			for i in 3:
				_uarc(ci, _P(t + i * 2.1, 1.35), .2, 0.0, 4.5, Color(.86, 1, .96, .6), .05)
		"wings":
			var f := sin(t * 14.0) * .1
			for k in [-1, 1]:
				_uell(ci, Vector2(k * 1.05, -.3 + f), .45, .22, Color(.86, .94, 1, .75), k * .5)
		"witchhat":
			_uell(ci, Vector2(0, -.82), .75, .14, Color("3b2a5a"))
			_ufill(ci, PackedVector2Array([Vector2(-.4, -.85), Vector2(.15, -1.75), Vector2(.4, -.85)]), Color("3b2a5a"))
			_urect(ci, -.38, -1.02, .76, .1, Color("7dff6a"))
		"wrapper":
			for k in [-1, 1]:
				_ufill(ci, PackedVector2Array([Vector2(k * .85, 0), Vector2(k * 1.55, -.45), Vector2(k * 1.4, 0), Vector2(k * 1.55, .45)]), shade(c, .25))
		"yoyo":
			_uring(ci, Vector2.ZERO, .68, shade(c, -.35), .06)
			_ucirc(ci, Vector2.ZERO, .12, Color("fff8b0"))
			_uline(ci, Vector2.ZERO, Vector2(.2, -1.4), Color(1, .97, .69, .7), .03)
		"zighair":
			var pts := PackedVector2Array([Vector2(-.7, -.6)])
			for i in 8:
				pts.append(Vector2(-.7 + (i + .5) * .175, -.8 if i % 2 else -1.35))
			pts.append(Vector2(.7, -.6))
			_ufill(ci, pts, shade(c, -.2))
		"zigmark":
			_ustroke(ci, PackedVector2Array([Vector2(-.85, -.45), Vector2(-.3, -.25), Vector2(-.45, .05), Vector2(.2, .2)]), Color(.12, .12, .12, .55), .08)


## Flux's two-pole body: red and blue halves split down the middle. `swap`
## runs 0 -> 1 as the poles spin half a turn when the field flips.
static func magnet_body(ci: CanvasItem, c: Vector2, r: float, red: Color, blue: Color, swap: float) -> void:
	var rot := PI * swap
	var halves := [[red, rot + PI / 2], [blue, rot - PI / 2]]
	for h in halves:
		var pts := ellipse_pts(c, r, r, 0.0, h[1], h[1] + PI, 24)
		_poly(ci, pts, shade(h[0], -.12))
	if not _sil:
		for k in range(1, 7):
			var f := k / 6.0
			Dot.circle(ci, c + Vector2(-.35, -.4) * r * f * .9, r * (1.0 - f * .82), Color(1, 1, 1, .07))
	var axis := Vector2(cos(rot + PI / 2), sin(rot + PI / 2)) * r * .97
	_line(ci, c - axis, c + axis, Color("e6ecf5"), maxf(1.5, r * .06))
	_ring(ci, c, r, Color("2a1f4a"), maxf(1.5, r * .07))


## The horseshoe: two silver prongs out of the head with painted pole tips and
## sparks jumping between them (more sparks per tier).
static func magnet_prongs(ci: CanvasItem, c: Vector2, r: float, tier: int, t: float, red: Color, blue: Color, swap: float) -> void:
	var w := maxf(3.0, r * .2)
	var tips: Array[Vector2] = []
	for k in [-1, 1]:
		var base := c + Vector2(k * .42, -.72) * r
		var tip := c + Vector2(k * .55, -1.32) * r
		_line(ci, base, tip, Color("b9c3d3"), w)
		_line(ci, base + Vector2(-k * w * .2, 0), tip + Vector2(-k * w * .2, 0), Color("e9eef6"), w * .35)
		var pole := red if (k < 0) == (swap < .5) else blue
		_line(ci, tip, tip + (tip - base).normalized() * r * .2, pole, w * 1.05)
		tips.append(tip + (tip - base).normalized() * r * .2)
	if _sil:
		return
	for i in mini(1 + tier, 4):
		var seed_ := floorf(t * 14.0) + i * 7.0
		if _hash(seed_) < .35:
			continue
		var pts := PackedVector2Array([tips[0]])
		for j in range(1, 5):
			var f := j / 5.0
			pts.append(tips[0].lerp(tips[1], f) + Vector2(0, (_hash(seed_ + j) - .5) * r * .35 - sin(f * PI) * r * .15))
		pts.append(tips[1])
		Dot.pline(ci, pts, Color(1, .95, .6, .85), maxf(1.0, r * .04), true)


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

## Knocked out (finisher cam): a dim wash, cross eyes and a stunned "o".
static func _ko_face(ci: CanvasItem, c: Vector2, r: float) -> void:
	_circ(ci, c, r, Color(0.1, 0.05, 0.2, 0.25))
	var lw := maxf(2.0, r * .09)
	var e := c + Vector2(0, -r * .08)
	for k in [-1.0, 1.0]:
		var ec: Vector2 = e + Vector2(k * r * .3, 0)
		var d := r * .13
		_line(ci, ec + Vector2(-d, -d), ec + Vector2(d, d), INK, lw)
		_line(ci, ec + Vector2(-d, d), ec + Vector2(d, -d), INK, lw)
	var m := e + Vector2(0, r * .4)
	_ell(ci, m, r * .13, r * .16, INK)
	_ell(ci, m + Vector2(0, r * .05), r * .07, r * .06, Color("ff6b8a"))


## Face keys (art "eyes"): sep, w, h, p (pupil), one, mis (mismatched), lid,
## brow (negative: worried), uni (unibrow), dot, closed, hollow, iris, glow,
## sparkle, wink (right eye closed), square (pixel eyes), swirl (dizzy
## pupils), none (no eyes: a feature is the eyes), visor (no eyes or mouth:
## a feature covers the face), ink, mouth_ink, mouth (MOUTHS).
static func _face(ci: CanvasItem, e: Dictionary, col: Color, c: Vector2, r: float, s: Dictionary) -> void:
	var look: Vector2 = s.look
	var eye := c + look * r * .2 + Vector2(0, -r * .08)
	var ink := Color(e.get("ink", INK.to_html()))
	if e.get("visor", false):
		return
	var no_eyes: bool = e.get("none", false)
	if s.hit > 0.0 and not no_eyes:
		for k in [-1, 1]:
			var ec := eye + Vector2(k * r * .3, 0)
			_pline(ci, PackedVector2Array([ec + Vector2(-k * r * .12, -r * .1), ec + Vector2(k * r * .08, 0), ec + Vector2(-k * r * .12, r * .1)]), ink, maxf(1.6, r * .08))
		_ell(ci, eye + Vector2(0, r * .38), r * .12, r * .09, ink)
		return
	var open := 1.0 - float(s.blink)
	var slots := [] if no_eyes else [[0, 1.0]] if e.get("one", false) else [[-1, 1.25 if e.get("mis", false) else 1.0], [1, .75 if e.get("mis", false) else 1.0]]
	for slot in slots:
		var k: int = slot[0]
		var m: float = slot[1]
		var ec := eye + Vector2(k * r * e.get("sep", 0.0), 0)
		if e.get("dot", false):
			Dot.circle(ci, ec, r * .14, Color(1, 1, 1, .25))
			_ell(ci, ec, r * .07, r * .07 * maxf(.15, open), Color.WHITE)
			continue
		if e.get("closed", false):
			Dot.arc(ci, ec + Vector2(0, -r * .02), r * e.w, .15 * PI, .85 * PI, 10, INK, maxf(1.5, r * .07), true)
			continue
		if e.get("wink", false) and k > 0:
			Dot.arc(ci, ec + Vector2(0, r * .05), r * .14, 1.15 * PI, 1.85 * PI, 10, INK, maxf(1.5, r * .07), true)
			continue
		if e.get("square", false):
			var sq := maxf(.08, open)
			ci.draw_rect(Rect2(ec - Vector2(.12, .12 * sq) * r, Vector2(.24, .24 * sq) * r), Color.WHITE)
			ci.draw_rect(Rect2(ec + (Vector2(-.05, -.05 * sq) + look * .05) * r, Vector2(.1, .1 * sq) * r), INK)
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
			Dot.circle(ci, pupil, minf(r * p * 1.7 * m, minf(w, h) * .95), Color(e.iris))
		Dot.circle(ci, pupil, minf(r * p * m, h * .9), INK)
		Dot.circle(ci, pupil - Vector2(1, 1) * r * p * .4, r * p * .35, Color.WHITE)
		if e.get("sparkle", false):
			Dot.poly(ci, star_pts(pupil + Vector2(.5, .3) * r * p, r * .06, r * .02, 4), Color.WHITE)
		if e.get("swirl", false):
			Dot.arc(ci, ec, w * .55, 0.0, 4.5, 12, Color("c0257a"), maxf(1.0, r * .04), true)
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
		Dot.pline(ci, _quad(eye + Vector2(-.42, -.2) * r, eye + Vector2(0, -.08) * r, eye + Vector2(.42, -.2) * r, 10), INK, maxf(2.5, r * .13), true)
	_mouth(ci, e.get("mouth", "smile"), r, eye + Vector2(0, r * .34), float(s.hp_frac), Color(e.get("mouth_ink", INK.to_html())), c)


## `c` is the body centre, for mouths drawn on the body rather than under the eyes.
static func _mouth(ci: CanvasItem, kind: String, r: float, m: Vector2, hp_frac: float, ink: Color, c: Vector2) -> void:
	var lw := maxf(1.4, r * .065)
	if hp_frac < .35:
		var pts := PackedVector2Array([m + Vector2(-r * .16, 0)])
		for i in range(1, 5):
			pts.append(m + Vector2(-r * .16 + i * r * .08, -r * .05 if i % 2 else 0.0))
		Dot.pline(ci, pts, ink, lw, true)
		return
	match kind:
		"smile":
			Dot.arc(ci, m + Vector2(0, -r * .06), r * .13, .2 * PI, .8 * PI, 10, ink, lw, true)
		"grin":
			var pts := ellipse_pts(m + Vector2(0, -r * .04), r * .17, r * .17, 0.0, 0.0, PI, 12)
			Dot.poly(ci, pts, ink)
			Dot.poly(ci, ellipse_pts(m + Vector2(0, r * .08), r * .07, r * .07, 0.0, PI, TAU, 8), Color("ff6f8a"))
		"smirk":
			Dot.pline(ci, _quad(m + Vector2(-r * .13, 0), m + Vector2(r * .02, r * .08), m + Vector2(r * .15, -r * .05), 8), ink, lw, true)
		"flat":
			ci.draw_line(m + Vector2(-r * .12, r * .02), m + Vector2(r * .12, r * .02), ink, lw, true)
		"frown":
			Dot.arc(ci, m + Vector2(0, r * .12), r * .12, 1.2 * PI, 1.8 * PI, 10, ink, lw, true)
		"o":
			Dot.poly(ci, ellipse_pts(m + Vector2(0, r * .02), r * .06, r * .08, 0.0, 0.0, TAU - .01, 12), ink)
		"fangs":
			Dot.arc(ci, m + Vector2(0, -r * .07), r * .14, .2 * PI, .8 * PI, 10, ink, lw, true)
			for k in [-1, 1]:
				var x: float = m.x + k * r * .1
				Dot.poly(ci, PackedVector2Array([Vector2(x - r * .035, m.y + r * .03), Vector2(x + r * .035, m.y + r * .03), Vector2(x, m.y + r * .15)]), Color.WHITE)
		"teeth":
			Dot.poly(ci, ellipse_pts(m + Vector2(0, -r * .06), r * .2, r * .2, 0.0, .05 * PI, .95 * PI, 12), ink)
			ci.draw_rect(Rect2(m + Vector2(-.17, -.03) * r, Vector2(.34, .06) * r), Color.WHITE)
		"pout":
			Dot.poly(ci, ellipse_pts(m + Vector2(0, r * .02), r * .08, r * .05, 0.0, 0.0, TAU - .01, 12), Color("d9567a"))
		"beak":
			Dot.poly(ci, PackedVector2Array([m + Vector2(-.08, -.02) * r, m + Vector2(.08, -.02) * r, m + Vector2(0, .12) * r]), Color("f2b134"))
		"bigmouth":
			Dot.poly(ci, ellipse_pts(c + Vector2(0, .35) * r, r * .6, r * .42, 0.0, 0.0, PI, 16), Color("3a0f1a"))
			for i in range(-2, 3):
				ci.draw_rect(Rect2(c + Vector2(i * .2 - .07, .33) * r, Vector2(.14, .12) * r), Color.WHITE)


static func _hash(i: float) -> float:
	var x := sin(i * 127.1) * 43758.5453
	return x - floorf(x)
