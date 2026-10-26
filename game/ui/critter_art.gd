## Draws any Neon Critter with plain CanvasItem draw calls, for menus and the
## arena alike. Each critter's look is data in its file (sim/critters/<id>.gd,
## the "art" key): a body style, a face (eyes + mouth) and a list of features
## drawn behind ("back") and in front of ("front") the body. New critters mix
## the existing bodies, faces and features; a new feature is one more branch
## in _feature(). Call from a CanvasItem's _draw():
##   CritterArt.draw_critter(self, "vampire", centre, radius, {"t": time, "tier": 2})
## State keys (all optional): t, tier, look (Vector2), blink (0-1), hit, flash,
## stacks, eye_flash, hp_frac, pole_swap (0-1, a magnet mid-flip), silhouette
## (bool: draw as an unfound dark shape), grey (bool: drawn in greyscale, as
## Echo wears a critter it is copying).
extends RefCounted

const Dot := preload("res://game/dot.gd")
const CritterDb := preload("res://sim/critter_db.gd")

const INK := Color("1a1530")
## The kit a critter's "art" can use; tests check every critter file against it.
const BODIES := ["gradient", "bomb", "ghost", "chrome", "starfield", "prism", "magnet", "cloud", "pixel", "eclipse", "mirror", "chomper", "gumdrop"]
const FEATURES := ["stormbelly", "sparks", "gustswirl", "frostmarks", "cape_collar", "spike_ring", "speed_streaks", "antennae", "ice_crown", "wisp_tail", "orbit_ring",
	"swirl_arms", "flame_crest", "rock_band", "headband", "fuse", "frost_freckles", "seam", "magnet_prongs",
	"antenna2", "bandana", "barrel", "batwings", "beard", "bees", "belly", "beret", "bigtail", "bite", "bloom", "boltant",
	"boltcrest", "bow", "bulbs", "candle", "candyrings", "canopy", "cap", "chainball", "cheeks", "chestlight", "chips", "clamshell",
	"clockface", "coil", "comettail", "controlbar", "core", "corona", "crust", "cup", "door", "dorsal", "drips", "drops", "droptop",
	"drumhead", "ears", "embers", "fantail", "fizz", "flowercrown", "fluke", "foxtail", "frill", "fringe", "fur", "fuzz",
	"gearcrown", "gears", "gearstick", "gills", "glowbelly", "goggles", "hardhat", "hazard", "helmet", "hive", "hook", "horn",
	"horns", "jarlid", "jets", "key", "lamp", "leaves", "lever", "mask", "monocle", "moons", "mushroom", "napkin", "number",
	"panel", "pearl", "pods", "pot", "rears", "reels", "ringpull", "rodball", "rope", "ruff", "scoops", "segments", "shades",
	"shards", "sheen", "shellhex", "shine", "sidefins", "smoke", "snout", "snowflake", "speckles", "spikyhair", "splats", "spots",
	"stemleaf", "sticks", "stinger", "stripe", "stripes", "sugar", "tallcrystals", "tentacles", "tiles", "tophat",
	"totemstack", "trunk", "tuft", "tusks", "twigs", "vinewrap", "vvisor", "whiskers", "windcurls", "wings", "witchhat",
	"wrapper", "yoyo", "zighair", "zigmark", "scales", "lens", "squid", "squidspots", "moss", "paws", "molesnout", "bramble", "dandelion"]
const MOUTHS := ["smile", "grin", "smirk", "flat", "frown", "o", "fangs", "teeth", "pout", "beak", "bigmouth", "none"]
const SILHOUETTE := Color("232052")
## Tier looks: from T3 a critter gets a small step up on its own body, and at T5
## its full "T5 look" (see the project's ideas/critter-cool-factor.md). Below T3
## every critter draws exactly as it always did.
const GOLD := Color("ffd23f")
const GOLD_LIGHT := Color("fff1b0")

static var _sil := false
static var _grey := false
## The outline (pixels) of a body that isn't a circle, for the hit flash.
static var _hit_shape := PackedVector2Array()


static func draw_critter(ci: CanvasItem, id: String, c: Vector2, r: float, s: Dictionary = {}) -> void:
	var d := CritterDb.get_critter(id)
	var st := {"t": 0.0, "tier": 1, "look": Vector2.RIGHT, "blink": 0.0, "hit": 0.0, "flash": 0.0, "stacks": 0, "hp_frac": 1.0, "pole_swap": 0.0}
	st.merge(s, true)
	st.art = d.art
	st.id = id
	_sil = st.get("silhouette", false)
	_grey = st.get("grey", false)
	_hit_shape = PackedVector2Array()
	var art: Dictionary = d.art
	var col := Color(d.color)
	r *= art.get("scale", 1.0)
	if not _sil:
		_aura(ci, d.rarity, c, r, st.t)
	# A hit jolts the loose parts behind the body (ears, horns, wings, props).
	# Hits under 0.12 (all of them with reduced motion on) don't shake.
	var jolt := clampf((st.hit - .12) * 4.0, 0.0, 1.0)
	var back_c := c + Vector2(sin(st.t * 71.0), cos(st.t * 53.0)) * r * .07 * jolt if jolt > 0.0 and not _sil else c
	for f in art.get("back", []):
		_feature(ci, f, true, col, back_c, r, st)
	_body_for(ci, art.get("body", "gradient"), col, c, r, st)
	for f in art.get("front", []):
		_feature(ci, f, false, col, c, r, st)
	if not _sil:
		if st.get("ko", false):
			_ko_face(ci, c, r)
			_sil = false
			_grey = false
			return
		if st.hit > 0.0:
			var flash := Color(1, 1, 1, minf(.85, st.hit * 2.4))
			if _hit_shape.size() > 2:
				_poly(ci, _hit_shape, flash)
			else:
				_circ(ci, c, r, flash)
		var eyes: Dictionary = art.get("eyes", {})
		_face(ci, eyes, col, c + Vector2(0, eyes.get("dy", 0.0) * r), r, st)
	_sil = false
	_grey = false


# --- Primitives (every colour passes through _c for silhouettes) -------------

static func _c(col: Color) -> Color:
	if _sil:
		return Color(SILHOUETTE, col.a)
	if _grey: # A cool silver grey, so a copy still reads as Echo's mirror.
		var l := col.get_luminance()
		return Color(l * .95, l, minf(1.0, l * 1.06 + .03), col.a)
	return col


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
	Dot.line(ci, a, b, _c(col), w, true)


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


## A twinkling four-point glint (tier looks), in pixels.
static func _glint(ci: CanvasItem, p: Vector2, size: float, t: float, phase := 0.0, col := Color.WHITE) -> void:
	var k := .55 + .45 * sin(t * 5.0 + phase)
	if size * k > .5:
		_poly(ci, star_pts(p, size * k, size * k * .28, 4), col)


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

## A smooth radial gradient lit from the top left: the dark disc, then the
## light colour through a baked shading texture (one quad, so it batches
## like Dot circles).
static func _body(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var dark := shade(col, -.2)
	var light := shade(col, .45)
	_circ(ci, c, r, dark)
	Dot.quad(ci, "shade", Rect2(c.x - r, c.y - r, r * 2.0, r * 2.0), _c(light))
	_gloss(ci, c, r, col)
	_ring(ci, c, r, shade(col, -.5), maxf(1.5, r * .07))


## A body that isn't a circle (Gumdrop, Munch's head and jaw): the same
## smooth shading as _body, mapped onto the outline `pts` (pixels) as if it
## were a ball of radius r centred on c.
static func _shaped(ci: CanvasItem, pts: PackedVector2Array, c: Vector2, r: float, col: Color) -> void:
	var uv := PackedVector2Array()
	for p in pts:
		uv.append((p - c) / (r * 2.0) + Vector2(.5, .5))
	Dot.poly(ci, pts, _c(shade(col, -.2)))
	Dot.tex_poly(ci, pts, uv, _c(shade(col, .45)), "shade")
	Dot.tex_poly(ci, pts, uv, _c(Color(shade(col, -.6), .55)), "core")
	Dot.tex_poly(ci, pts, uv, _c(Color(1, 1, 1, .5)), "sheen")
	var ring := pts.duplicate()
	ring.append(pts[0])
	_pline(ci, ring, shade(col, -.5), maxf(1.5, r * .07))


## The round-ball finish over a body: a shadow wrapping the side away from
## the light (skipped when core is false, e.g. see-through ghosts) and a gloss.
static func _gloss(ci: CanvasItem, c: Vector2, r: float, col: Color, core := true) -> void:
	var box := Rect2(c.x - r, c.y - r, r * 2.0, r * 2.0)
	if core:
		Dot.quad(ci, "core", box, _c(Color(shade(col, -.6), .55)))
	Dot.quad(ci, "sheen", box, _c(Color(1, 1, 1, .5)))


static func _aura(ci: CanvasItem, rarity: String, c: Vector2, r: float, t: float) -> void:
	if rarity == "epic":
		Dot.glow(ci, c, r * 1.42, Color(.7, .4, 1.0, .42), .7)
	elif rarity == "legendary":
		var pulse := .8 + .2 * sin(t * 4.0)
		Dot.glow(ci, c, r * (1.0 + .52 * pulse), Color(1.0, .76, .24, .48), .65)
		for i in 2:
			var a := t * 1.5 + i * PI
			var p := c + Vector2(cos(a), sin(a)) * r * 1.35
			Dot.poly(ci, star_pts(p, r * .12, r * .04, 4), Color(1, .95, .77, .6 + .4 * sin(t * 6.0 + i)))


## Body styles: gradient (default), bomb, ghost, chrome, starfield, prism, magnet.
static func _body_for(ci: CanvasItem, style: String, col: Color, c: Vector2, r: float, s: Dictionary) -> void:
	var t: float = s.t
	var tier: int = s.tier
	_C = c
	_R = r
	if _sil and style == "ghost": # See-through ghosts still make a solid shadow.
		_circ(ci, c, r, Color.WHITE)
		return
	match style:
		"magnet":
			magnet_body(ci, c, r, col, Color(s.art.get("pole", "2f7bff")), s.pole_swap, tier)
		"bomb":
			_body(ci, c, r, col)
			_ell(ci, c + Vector2(-.42, -.45) * r, r * .18, r * .1, Color(1, 1, 1, .35), -.7)
		"ghost" when s.art.get("tint", false):
			# Kit ghost in the critter's own colour (Bubbles).
			var a := .7 + .2 * sin(t * 2.0)
			_circ(ci, c, r * 1.08, Color(col, .2 * a))
			_circ(ci, c, r, Color(col, .85 * a))
			Dot.quad(ci, "shade", Rect2(c.x - r, c.y - r, r * 2.0, r * 2.0), _c(Color(col.lerp(Color.WHITE, .8), .95 * a)))
			Dot.quad(ci, "shade", Rect2(c.x - r * .7, c.y - r * .75, r * 1.2, r * 1.2), _c(Color(1, 1, 1, .9 * a)))
			_gloss(ci, c, r, col, false)
		"ghost":
			var a := .75 + .2 * sin(t * 2.0)
			_circ(ci, c, r * 1.08, Color(.79, .71, 1.0, .25 * a))
			_circ(ci, c, r, Color(.78, .7, 1.0, .6 * a))
			Dot.quad(ci, "shade", Rect2(c.x - r, c.y - r, r * 2.0, r * 2.0), _c(Color(1, 1, 1, .9 * a)))
			_gloss(ci, c, r, Color.WHITE, false)
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
		"mirror":
			mirror_body(ci, c, r, t, tier)
		"chomper":
			_chomper(ci, col, c, r, t, tier)
		"gumdrop":
			if tier >= 5: # Gumdrop's T5: a little lime gumdrop bobs on its head.
				_shaped(ci, _gum_pts(c + Vector2(.05, -1.12 + .04 * sin(t * 3.0)) * r, r * .42), c + Vector2(.05, -1.12) * r, r * .42, Color("5fd38a"))
			_hit_shape = _gum_pts(c, r)
			_shaped(ci, _hit_shape, c, r, col)
		"cloud":
			var puffs := [Vector3(-.55, .1, .55), Vector3(.55, .1, .55), Vector3(0, -.3, .65), Vector3(-.3, .35, .5), Vector3(.3, .35, .5)]
			for b in puffs:
				_circ(ci, c + Vector2(b.x, b.y) * r, (b.z + .06) * r, shade(col, -.35))
			for b in puffs:
				_circ(ci, c + Vector2(b.x, b.y) * r, b.z * r, shade(col, .35))
			_circ(ci, c + Vector2(-.2, -.4) * r, .3 * r, Color(1, 1, 1, .35))
			if s.get("id", "") == "drizzle" and tier >= 3:
				# Drizzle: a dark storm belly at T3, lightning flickering inside at T5.
				for b in [Vector3(-.3, .38, .42), Vector3(.3, .38, .42)]:
					_circ(ci, c + Vector2(b.x, b.y) * r, b.z * r, Color(.25, .27, .42, .35))
				if tier >= 5:
					var flick := .45 + .55 * clampf(sin(t * 7.0) * sin(t * 2.3) * 3.0 + .5, 0.0, 1.0)
					_ufill(ci, PackedVector2Array([Vector2(.65, -.25), Vector2(.45, .15), Vector2(.6, .15), Vector2(.48, .55), Vector2(.82, .08), Vector2(.66, .08), Vector2(.8, -.25)]), Color(1, .95, .5, flick))
		"pixel":
			var px := r * .25
			if tier >= 5:
				# Pixel's T5: a glitchy RGB split, one row strip per colour.
				var jit := floorf(t * 6.0)
				for y in range(-4, 4):
					var d := sqrt(15.0 - (y + .5) * (y + .5))
					var x0 := ceilf(-d - .5)
					var w := (floorf(d - .5) - x0 + 1.0) * px
					var sh := px * (.25 + .35 * _hash(jit + y))
					Dot.rect(ci, Rect2(c + Vector2(x0 * px - sh, y * px), Vector2(w, px + .5)), _c(Color(1, .2, .35, .5)))
					Dot.rect(ci, Rect2(c + Vector2(x0 * px + sh, y * px), Vector2(w, px + .5)), _c(Color(.2, .95, 1, .5)))
			for y in range(-4, 4):
				for x in range(-4, 4):
					if (x + .5) * (x + .5) + (y + .5) * (y + .5) <= 15.0:
						Dot.rect(ci, Rect2(c + Vector2(x, y) * px, Vector2(px + .5, px + .5)), _c(shade(col, .25) if (x + y) % 3 == 0 else col))
			if tier >= 3:
				# Pixel: stray pixels float off it (T3+), and scanlines roll over it at T5.
				for i in 3:
					var a := i * 2.1 + t * .6
					var q := c + Vector2(cos(a), sin(a)) * r * (1.3 + .08 * sin(t * 3.0 + i))
					Dot.rect(ci, Rect2(q - Vector2(px, px) * .3, Vector2(px, px) * .6), _c(shade(col, .25 if i % 2 else -.1)))
				if tier >= 5:
					for k in 2:
						var y := (fmod(t * .5 + k * .5, 1.0) * 2.0 - 1.0) * r * .9
						var half := _chord_x(r * .95, y)
						Dot.rect(ci, Rect2(c + Vector2(-half, y), Vector2(half * 2.0, maxf(1.0, r * .07))), _c(Color(1, 1, 1, .3)))
		"eclipse":
			if tier >= 3:
				# Eclipse: a corona flares round the disc (longer at T5).
				for i in 12:
					var a := i * TAU / 12 + t * .2
					var L := r * (1.22 + .1 * sin(t * 3.0 + i * 1.7) + (.18 if tier >= 5 else 0.0))
					_poly(ci, PackedVector2Array([c + Vector2(cos(a - .13), sin(a - .13)) * r * .95, c + Vector2(cos(a), sin(a)) * L, c + Vector2(cos(a + .13), sin(a + .13)) * r * .95]), Color(1, .8, .45, .55))
			_circ(ci, c, r, Color("ff9d3a"))
			for q in Geometry2D.intersect_polygons(ellipse_pts(c + Vector2(.55, -.15) * r, r * .95, r * .95, 0.0, 0.0, TAU, 40), ellipse_pts(c, r, r, 0.0, 0.0, TAU, 48)):
				_poly(ci, q, Color("242046"))
			_circ(ci, c + Vector2(-.4, -.45) * r, r * .3, Color(1, 1, 1, .3))
			_ring(ci, c, r, Color("3a2440"), maxf(1.5, r * .07))
			if tier >= 5:
				# Eclipse's T5: the diamond ring, a blazing point where the moon's edge leaves the sun.
				var dp := c + Vector2(.11, -.99) * r
				_circ(ci, dp, r * .28, Color(1, .95, .8, .45))
				_glint(ci, dp, r * .6, t, 0.0, Color(1, 1, .92))
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
			if tier >= 3:
				# Spectra: a rainbow fans out of the prism at T3; at T5 a white beam comes in and six colours spread wide.
				var rays := 6 if tier >= 5 else 3
				if tier >= 5:
					_line(ci, c + Vector2(-2.0, -.75) * r, c, Color(1, 1, 1, .75), r * .12)
				for i in rays:
					var a := .3 + (i - (rays - 1) / 2.0) * .17
					var L := r * (1.8 + .12 * sin(t * 3.0 + i))
					_poly(ci, PackedVector2Array([c + Vector2(cos(a), sin(a)) * r * .5, c + Vector2(cos(a - .08), sin(a - .08)) * L, c + Vector2(cos(a + .08), sin(a + .08)) * L]), Color.from_hsv(float(i) / rays * .8, .75, 1.0, .65))
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
	var id: String = s.get("id", "")
	_C = c
	_R = r
	match name:
		"magnet_prongs":
			magnet_prongs(ci, c, r, tier, t, col, Color(s.art.get("pole", "2f7bff")), s.pole_swap)
		"cape_collar":
			var h := 1.05 + .08 * tier
			var ice := id == "glacia"
			var lining := Color(.56, .89, 1.0, .6) if ice else Color("b3122e")
			if tier >= 5 and not ice:
				# Count Nibbles' T5: a bat-wing cape wrapping round the ball.
				for k in [-1, 1]:
					var wing := PackedVector2Array()
					for v in [Vector2(.6, -.75), Vector2(1.6, -.55), Vector2(1.32, -.08), Vector2(1.62, .3), Vector2(1.25, .5), Vector2(1.35, .95), Vector2(.55, .8)]:
						wing.append(c + Vector2(k * v.x, v.y) * r)
					_poly(ci, wing, shade(col, -.6))
					for v in [Vector2(1.32, -.08), Vector2(1.25, .5)]:
						_line(ci, c + Vector2(k * .85, -.3) * r, c + Vector2(k * v.x, v.y) * r, Color("e8344a"), maxf(1.0, r * .05))
			for k in [-1, 1]:
				var panel := PackedVector2Array([c + Vector2(k * .25, -.9) * r, c + Vector2(k * 1.12, -h) * r, c + Vector2(k * .95, -.15) * r])
				# Shaded like cloth: catches light at the tip, falls dark behind the ball.
				Dot.tri_colors(ci, panel, PackedColorArray([_c(shade(col, -.5)), _c(shade(col, -.15)), _c(shade(col, -.72))]))
				_line(ci, panel[0], panel[1], Color(shade(col, .3), .7), maxf(1.0, r * .035))
				if tier >= 3:
					_poly(ci, PackedVector2Array([c + Vector2(k * .35, -.86) * r, c + Vector2(k * 1.02, -h + .1) * r, c + Vector2(k * .9, -.3) * r]), lining)
			if tier >= 5:
				for i in 10:
					var a := i * TAU / 10 + t
					Dot.arc(ci, c, r * 1.25, a, a + .35, 4, _c(Color(.6, .92, 1.0, .7) if ice else Color(1, .24, .35, .7)), 2.0, true)
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
				var bl := c + Vector2(cos(a - w), sin(a - w)) * r * .92
				var tip := c + Vector2(cos(a), sin(a)) * (r + L * (1.0 + .22 * sin(t * 2.5 + i * 1.3))) # Idle: the spikes ripple.
				var br := c + Vector2(cos(a + w), sin(a + w)) * r * .92
				_poly(ci, PackedVector2Array([bl, tip, br]), spike)
				if (tier >= 5 or (tier >= 3 and i % 2 == 0)) and s.flash <= 0.0:
					# Prickles' spikes get gold tips: every other one at T3, all at T5.
					_poly(ci, PackedVector2Array([bl.lerp(tip, .6), tip, br.lerp(tip, .6)]), GOLD if tier >= 5 else Color(GOLD_LIGHT, .85))
		"speed_streaks":
			var n := 1 + tier
			var perp := Vector2(-look.y, look.x)
			for i in n:
				var o := (i - (n - 1) / 2.0) * r * .3
				var len := r * (.6 + .25 * _hash(i + 3) + .12 * tier)
				var a := c - look * r * 1.05 + perp * o
				var streak := Color(1, .42, .14) if tier >= 3 and i % 2 == 0 else Color(1, .75, .24)
				_line(ci, a, a - look * len, Color(streak, .3 + .35 * _hash(i)), maxf(1.5, r * .08))
			if tier >= 5:
				# Zip's T5: a mach cone off the nose and flame tongues out the back.
				var dir := look.normalized() if look.length() > .01 else Vector2.RIGHT
				var side := Vector2(-dir.y, dir.x)
				var nose := c + dir * r * 1.4
				var cone := Color(1, 1, 1, .5 + .2 * sin(t * 18.0))
				for k in [-1, 1]:
					_pline(ci, _quad(nose, c + dir * r * 1.05 + side * k * r * 1.15, c - dir * r * .4 + side * k * r * 1.55, 8), cone, maxf(1.5, r * .08))
					_flame(ci, c - dir * r * .85 + side * k * r * .35, (-dir).angle() + k * .2, r * (.85 + .12 * sin(t * 14.0 + k)), r * .2)
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
				if (tier >= 5 and i % 2 == 0) or (tier >= 3 and i == n / 2):
					_glint(ci, tip, r * .16, t, i * 1.3, Color("bff0ff"))
		"wisp_tail":
			var L := r * (.6 + .18 * tier)
			var perp := Vector2(-look.y, look.x)
			# Wisp: ecto blobs on the tail ends at T3, five ectoplasm wisps at T5.
			var tails := 5 if tier >= 5 else 3
			var mid := (tails - 1) / 2.0
			for i in tails:
				var o := (i - mid) * r * (.4 if tails == 3 else .26)
				var start := c - look * r * .6 + perp * o
				var pts := PackedVector2Array([start])
				for j in range(1, 7):
					var f := j / 6.0
					pts.append(start - look * L * f + perp * sin(t * 5.0 + j + i) * r * .12 * f)
				var wisp := Color(.89, .84, 1.0, .6) if tier < 5 or i % 2 else Color(.62, 1.0, .82, .55)
				_pline(ci, pts, wisp, r * (.22 - .04 * absf(i - mid) * (1.0 if tails == 3 else .55)))
				if tier >= 3:
					_circ(ci, pts[pts.size() - 1], r * (.11 + .03 * sin(t * 4.0 + i)), Color(.62, 1.0, .82, .55))
		"orbit_ring":
			_orbit_ring(ci, c, r, tier, t, back)
		"swirl_arms":
			var n := 1 + tier
			if tier >= 5:
				# Void's T5: a burning ring of light round the event horizon.
				var burn := .65 + .3 * sin(t * 5.0)
				_ring(ci, c, r * 1.42, Color(1, .55, .2, .22 * burn), r * .22)
				_ring(ci, c, r * 1.42, Color(1, .8, .45, .85 * burn), r * .07)
				_ring(ci, c, r * 1.42, Color(1, 1, .9, .9), maxf(1.0, r * .025))
			for i in n:
				var a := t * 1.4 + i * TAU / n
				var arm := Color(1, .35, .78, .75) if i % 2 else Color(.59, .43, 1.0, .8)
				Dot.arc(ci, c, r * (1.12 + .08 * (i % 3)), a, a + 1.4, 16, _c(arm), r * .09, true)
			if tier >= 3:
				_ring(ci, c, r * 1.22, Color(1, .86, .6, .55), maxf(1.0, r * .03))
			if tier >= 5:
				for i in 3:
					var a := -t * 2.0 + i * TAU / 3
					_glint(ci, c + Vector2(cos(a), sin(a)) * r * 1.42, r * .2, t, i * 2.0, Color(1, .95, .8))
		"flame_crest":
			var n := 2 + tier
			if tier >= 3:
				# Ember's fire wings: a small pair at T3, spread wide at T5.
				var wing_angles := [1.25, 1.8] if tier >= 5 else [1.35]
				for k in [-1, 1]:
					for j in wing_angles.size():
						var wa: float = -PI / 2 + k * wing_angles[j]
						var wl := r * ((.95 - .18 * j) if tier >= 5 else .5) * (1.0 + .12 * sin(t * 8.0 + j + k))
						_flame(ci, c + Vector2(cos(wa), sin(wa)) * r * .7, wa, wl, r * (.22 if tier >= 5 else .17))
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
			var cracks := [[Vector2(-.7, -.5), Vector2(-.5, -.35), Vector2(-.55, -.15)], [Vector2(.55, -.65), Vector2(.42, -.45), Vector2(.6, -.3)]]
			if tier >= 5:
				cracks += [[Vector2(-.85, .05), Vector2(-.62, .2), Vector2(-.7, .45)], [Vector2(.82, .02), Vector2(.62, .18), Vector2(.72, .42)]]
			for j in cracks.size():
				var crack_pts := PackedVector2Array(cracks[j].map(func(v): return c + v * r))
				_pline(ci, crack_pts, shade(col, -.45), maxf(1.0, r * .04))
				if tier >= 3:
					# Boulder's glowing seams: a faint ember line at T3, molten at T5.
					var glow := .55 + .35 * sin(t * 3.0 + j * 1.7)
					if tier >= 5:
						_pline(ci, crack_pts, Color(1, .45, .1, .35 * glow), r * .13)
					_pline(ci, crack_pts, Color(1, .72, .28, glow), maxf(1.0, r * .025))
			var gold := tier >= 5
			_band(ci, c, r * .97, r * .58, r * .82, Color("d9a32a") if gold else Color("4b5260"))
			for i in tier:
				_circ(ci, c + Vector2((i - (tier - 1) / 2.0) * r * .32, r * .7), r * .055, Color("fff1b8") if gold else Color("a9b2c2"))
		"headband":
			_band(ci, c, r * .97, -r * .66, -r * .46, Color("e8344a"))
		"fuse":
			var cap := Rect2(c + Vector2(-.2, -1.08) * r, Vector2(.4, .2) * r)
			# Fuse: a brass cap and flying sparks at T3, a gold riveted cap and a red-hot spark at T5.
			var cap_col := Color("6b7280") if tier < 3 else (GOLD if tier >= 5 else Color("c9a24a"))
			_poly(ci, PackedVector2Array([cap.position, cap.position + Vector2(cap.size.x, 0), cap.end, cap.position + Vector2(0, cap.size.y)]), cap_col)
			if tier >= 5:
				for i in 3:
					_circ(ci, cap.position + Vector2(cap.size.x * (.2 + .3 * i), cap.size.y * .5), r * .025, Color("8a6a1a"))
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
			if tier >= 5 and not _sil:
				Dot.circle(ci, p3, r * .5 * f, Color(1, .45, .15, .25))
			_star(ci, p3, r * (.16 + .03 * tier) * f, r * .06, 6, Color("ffe066"))
			_circ(ci, p3, r * .05, Color("ff7a1a"))
			if tier >= 3:
				for i in 5 if tier >= 5 else 3:
					var q := fmod(t * 1.6 + _hash(i + 11), 1.0)
					var a := -PI / 2 + (_hash(i + 2) - .5) * 2.4
					_circ(ci, p3 + Vector2(cos(a), sin(a)) * r * (.15 + q * .45), r * .035 * (1.0 - q), Color(1, .85 - .4 * q, .3, 1.0 - q))
			if tier >= 3:
				# Fuse: a riveted iron band round its middle (T3); at T5 it's gold with a red danger stripe.
				_C = c
				_R = r
				_clip_on()
				_urect(ci, -1, .38, 2, .22, Color("c9a24a") if tier < 5 else GOLD)
				if tier >= 5:
					_urect(ci, -1, .45, 2, .08, Color("e8344a"))
				_clip = false
				for i in 5:
					_ucirc(ci, Vector2(-.72 + i * .36, .49), .035, Color("6b5420"))
		"frost_freckles":
			for k in [-1, 1]:
				for i in 3:
					_circ(ci, c + Vector2(k * r * (.5 + i * .08), r * .18 + (i % 2) * r * .07), r * .03, Color(1, 1, 1, .8))
			if id == "frost" and tier >= 3:
				# Chill's frost breath: a few drifting snowflakes, a full cone at T5.
				var m := c + look * r * .2 + Vector2(0, r * .26)
				var dir := look.normalized() if look.length() > .01 else Vector2.RIGHT
				var side := Vector2(-dir.y, dir.x)
				for i in 6 if tier >= 5 else 2:
					var q := fmod(t * .7 + i / 6.0, 1.0)
					var fp := m + dir * r * (.25 + q * 1.1) + side * sin(t * 3.0 + i * 2.0) * r * .3 * q
					var big := 1.4 if tier >= 5 else 1.0
					_poly(ci, star_pts(fp, r * (.07 + .04 * q) * big, r * .03 * big, 6, t + i), Color(.92, .98, 1.0, 1.0 - q * .7))
		"seam":
			if tier >= 3:
				# Dupe: its halves drift apart in colour (T3), clearly two-tone at T5.
				_C = c
				_R = r
				_clip_on()
				_urect(ci, .06, -1, 1, 2, Color(1, 1, 1, .2 if tier < 5 else .32))
				_urect(ci, -1, -1, 1.06, 2, Color(0, 0, 0, .12 if tier < 5 else .22))
				_clip = false
			var gy := fmod(t * .45, 1.0) # Idle: a glint runs down the seam (skipping the eyes).
			if not _sil and absf(gy * 1.8 - .9 + .08) > .32:
				_star(ci, c + Vector2(.06, gy * 1.8 - .9) * r, r * .12, r * .035, 4, Color(1, 1, 1, .8))
			var seam := _quad(c + Vector2(0, -.97) * r, c + Vector2(.08, 0) * r, c + Vector2(0, .97) * r, 24)
			for i in range(0, seam.size() - 1, 2):
				if absf(seam[i].y - c.y + r * .08) > r * .32: # Stops short of the eyes.
					_line(ci, seam[i], seam[i + 1], shade(col, -.4), maxf(1.2, r * .05))
			var n := tier + 2
			for i in n:
				var y := -r * .75 + i * r * 1.5 / (n - 1)
				if absf(y + r * .08) < r * .22:
					continue
				_line(ci, c + Vector2(-r * .08, y - r * .03), c + Vector2(r * .1, y + r * .03), GOLD if tier >= 3 else shade(col, -.4), maxf(1.2, r * .05))
			if tier >= 5:
				# Dupe's T5: each half wears a mini crown.
				for k in [-1, 1]:
					_xf = Transform2D(k * .35, Vector2(k * .5, -.92))
					_ufill(ci, PackedVector2Array([Vector2(-.2, 0), Vector2(-.22, -.24), Vector2(-.1, -.1), Vector2(0, -.3), Vector2(.1, -.1), Vector2(.22, -.24), Vector2(.2, 0)]), GOLD)
					_ucirc(ci, Vector2(0, -.06), .05, Color("e8344a"))
				_xf = Transform2D.IDENTITY
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


## A unit-space length in pixels.
static func r_px(u: float) -> float:
	return u * _R


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


## A twinkling four-point glint (tier looks), in unit space.
static func _uglint(ci: CanvasItem, p: Vector2, size: float, t: float, phase := 0.0, col := Color.WHITE) -> void:
	var k := .55 + .45 * sin(t * 5.0 + phase)
	_ustar(ci, p, size * k, size * k * .28, 4, col)


## Cold breath puffing from the mouth along the look direction (Yeti, Frostfang), in unit space.
static func _ubreath(ci: CanvasItem, s: Dictionary, t: float, col: Color) -> void:
	var look: Vector2 = s.get("look", Vector2.RIGHT)
	var m := look * .2 + Vector2(0, .26)
	var dir := look.normalized() if look.length() > .01 else Vector2.RIGHT
	for i in 3:
		var q := fmod(t * .6 + i / 3.0, 1.0)
		_ucirc(ci, m + dir * (.4 + q * .85) + Vector2(0, -q * .15), .1 + q * .17, Color(col, col.a * (1.0 - q * .7)))


## Chocolate sauce over a scoop centred at p with radius rad (Sundae's T5), in unit space.
static func _usauce(ci: CanvasItem, p: Vector2, rad: float) -> void:
	var pts := ellipse_pts(p, rad * 1.04, rad * 1.04, 0.0, PI * 1.1, PI * 1.9, 10)
	for i in 7:
		pts.append(p + Vector2(lerpf(.82, -.82, i / 6.0), -.15 + (.3 if i % 2 else 0.0)) * rad)
	_ufill(ci, pts, Color("5a2e1a"))


## A five-petal flower (tier looks: blooms), in unit space.
static func _uflower(ci: CanvasItem, p: Vector2, size: float, petal: Color, heart := Color("ffd23f")) -> void:
	_ustar(ci, p, size, size * .55, 5, petal)
	_ucirc(ci, p, size * .35, heart)


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
	# Same shading as _body, through the bitten outline (UVs map the ball's box).
	var layers := [["shade", light], ["core", Color(shade(col, -.6), .55)], ["sheen", Color(1, 1, 1, .5)]]
	for q in outline:
		var uv := PackedVector2Array()
		for p in q:
			uv.append((p - c) / (r * 2.0) + Vector2(.5, .5))
		for layer in layers:
			Dot.tex_poly(ci, q, uv, _c(layer[1]), layer[0])
	for q in outline:
		var loop: PackedVector2Array = q.duplicate()
		loop.append(q[0])
		_pline(ci, loop, shade(col, -.5), maxf(1.5, r * .07))


## Features from the roster's builder kit, in unit space (see _C/_R above).
## `n` is the tier.
static func _kit_feature(ci: CanvasItem, name: String, c: Color, t: float, n: int, s: Dictionary = {}) -> void:
	var id: String = s.get("id", "")
	match name:
		"antenna2":
			for k in [-1, 1]:
				_uline(ci, Vector2(k * .3, -.85), Vector2(k * .55, -1.4), shade(c, -.5), .05)
				if n >= 5:
					_ucirc(ci, Vector2(k * .58, -1.45), .2, Color(.96, 1, .6, .3 + .15 * sin(t * 4.0 + k)))
				_ucirc(ci, Vector2(k * .58, -1.45), .09, Color("f6ff9a"))
			if n >= 3:
				# Glowbug: fireflies orbit it (two at T3, a swarm of four at T5).
				var flies := 4 if n >= 5 else 2
				for i in flies:
					var a := t * 1.3 + i * TAU / flies
					var p := Vector2(cos(a) * 1.45, sin(a) * .55 - .35)
					var on := .5 + .5 * sin(t * 6.0 + i * 1.7)
					_ucirc(ci, p, .17, Color(.92, 1, .47, .25 * on))
					_ucirc(ci, p, .06, Color(.95, 1, .6, .6 + .4 * on))
		"bandana":
			_clip_on()
			_urect(ci, -1, -.75, 2, .25, Color("1c1c2a"))
			_clip = false
			for i in 6:
				_ucirc(ci, Vector2(-.8 + i * .32, -.63), .04, Color.WHITE)
			_ufill(ci, PackedVector2Array([Vector2(.85, -.65), Vector2(1.25, -.45), Vector2(1.05, -.8)]), Color("1c1c2a"))
			if n >= 3:
				# Hook: a gold earring (T3); at T5 a tricorn captain's hat with a skull badge.
				_uring(ci, Vector2(-.93, .1), .1, GOLD, .04)
			if n >= 5:
				_ufill(ci, PackedVector2Array([Vector2(-1.15, -.62), Vector2(-.5, -1.42), Vector2(0, -1.15), Vector2(.5, -1.42), Vector2(1.15, -.62), Vector2(0, -.82)]), Color("1c1c2a"))
				_ustroke(ci, PackedVector2Array([Vector2(-1.15, -.62), Vector2(0, -.82), Vector2(1.15, -.62)]), GOLD, .05)
				_ucirc(ci, Vector2(0, -1.08), .11, Color("f4f1e8"))
				for k in [-1, 1]:
					_ucirc(ci, Vector2(k * .04, -1.1), .025, INK)
		"barrel":
			if n >= 5:
				# Mortar's T5: a triple barrel for the barrage.
				for k in [-1, 1]:
					_xf = Transform2D(k * .42, Vector2.ZERO)
					_urect(ci, -.15, -1.38, .3, .58, Color("3f4a22"), .06)
					_urect(ci, -.2, -1.43, .4, .12, Color("2f3818"), .04)
				_xf = Transform2D.IDENTITY
			_urect(ci, -.18, -1.45, .36, .65, Color("4d5a2a"), .06)
			_urect(ci, -.24, -1.5, .48, .14, Color("2f3818"), .04)
			# Mortar: a wisp of smoke from the barrel (more puffs at T3 and T5).
			for i in 3 if n >= 5 else (2 if n >= 3 else 1):
				var p := fmod(t * .6 + i / 3.0, 1.0)
				_ucirc(ci, Vector2(sin(t * 2.0 + i) * .1, -1.6 - p * .6), .1 + p * .14, Color(.75, .72, .7, .55 * (1.0 - p)))
		"batwings":
			var big := 1.3 if n >= 5 else 1.0
			for k in [-1, 1]:
				var wing := PackedVector2Array([Vector2(k * .85, -.2), Vector2(k * (.85 + .7 * big), -.5 * big), Vector2(k * (.85 + .55 * big), -.1), Vector2(k * (.85 + .7 * big), .2 * big), Vector2(k * .85, .25)])
				_ufill(ci, wing, shade(c, -.4))
				if n >= 3:
					# Sonar: wing bones at T3; at T5 the wings flare open and sonar rings pulse up.
					for j in [1, 3]:
						_uline(ci, Vector2(k * .9, .02), wing[j], shade(c, .2), .04)
			if n >= 5:
				for i in 2:
					var q := fmod(t * .8 + i * .5, 1.0)
					_uarc(ci, Vector2(0, -1.1), .3 + q * .6, -PI * .8, -PI * .2, Color(.7, .95, 1, .7 * (1.0 - q)), .045)
		"beard":
			for i in 6:
				_ufill(ci, PackedVector2Array([Vector2(-.45 + i * .18, .5), Vector2(-.36 + i * .18, 1.05 - absf(i - 2.5) * .1), Vector2(-.27 + i * .18, .5)]), Color("6aa84f"))
		"bees":
			# Swarm: four bees at T3, six with dotted flight lines at T5.
			var nb := 3 if n < 3 else (4 if n < 5 else 6)
			for i in nb:
				var a := t * 1.8 + (i * 2.09 if nb == 3 else i * TAU / nb)
				var p := Vector2(cos(a) * 1.4, sin(a) * .7 - .2)
				if n >= 5:
					for j in 2:
						_ucirc(ci, Vector2(cos(a - .3 - j * .25) * 1.4, sin(a - .3 - j * .25) * .7 - .2), .03, Color(1, .85, .3, .6))
				_uell(ci, p, .14, .1, Color("ffd23f"))
				_uline(ci, p + Vector2(0, -.1), p + Vector2(0, .1), Color("222222"), .04)
				_uell(ci, p + Vector2(0, -.12), .08, .05, Color(1, 1, 1, .8))
		"belly":
			_clip_on()
			_uell(ci, Vector2(0, .75), .7, .45, shade(c, .55))
			if id == "drako" and n >= 3:
				# Drako: belly scales (gold at T5).
				for i in 3:
					for j in 4 - i % 2:
						_uarc(ci, Vector2(-.45 + j * .3 + (i % 2) * .15, .48 + i * .18), .14, .3, PI - .3, shade(c, .1) if n < 5 else GOLD, .04)
				_clip = false
				# Drako: smoke curls from the nostrils (glowing embers in them at T5).
				var look: Vector2 = s.get("look", Vector2.RIGHT)
				for k in [-1, 1]:
					var base := look * .2 + Vector2(k * .09, .14)
					for i in 2:
						var q := fmod(t * .7 + i * .5 + (k + 1) * .25, 1.0)
						_ucirc(ci, base + Vector2(k * 1.1, -.5) * q + Vector2(0, sin(t * 3.0 + i + k) * .04), .07 + q * .14, Color(.85, .84, .88, .75 * (1.0 - q)))
					if n >= 5:
						_ucirc(ci, base, .035, Color(1, .55, .15, .9))
			if id == "fin" and n >= 3:
				_clip = false
				# Fin: gill slits on its cheek.
				for i in 3:
					_uarc(ci, Vector2(-.95 + i * .13, .05), .22, -.6, .6, shade(c, -.4), .035)
		"beret":
			if n >= 3:
				# Painter: a brush tucked in the beret.
				_uline(ci, Vector2(.2, -.95), Vector2(.72, -1.45), Color("c98a3a"), .06)
				_uell(ci, Vector2(.78, -1.52), .07, .12, _hsl(t * 60.0, .85, .6), .75)
			_uell(ci, Vector2(-.15, -.82), .7, .3, Color("d6336c"), -.2)
			_ucirc(ci, Vector2(-.15, -1.1), .07, Color("d6336c"))
		"bigtail":
			if n >= 5:
				# Whiff's T5: the tail fluffs up huge.
				_uell(ci, Vector2(.95, -.95), .7, .5, Color("efe6ff"), .6)
				_uell(ci, Vector2(1.1, -1.1), .38, .26, Color.WHITE, .6)
			if n >= 5:
				# Whiff's T5: a sickly purple-green stink cloud round the tail.
				for i in 4:
					var q := fmod(t * .4 + i * .25, 1.0)
					_ucirc(ci, Vector2(.75 + sin(i * 2.3) * .5, -1.0 - q * .55), .2 + q * .15, Color(.72, .55, .95, .6 * (1.0 - q)) if i % 2 else Color(.62, .92, .38, .6 * (1.0 - q)))
			_uell(ci, Vector2(.75, -.75), .55, .4, Color("efe6ff"), .6)
			_uell(ci, Vector2(.9, -.9), .3, .2, Color.WHITE, .6)
			if n >= 3:
				# Whiff: wavy stink lines rise off the tail (and two flies buzz round it at T5).
				for i in 2:
					var pts := PackedVector2Array()
					for j in 6:
						pts.append(Vector2(.6 + i * .4 + sin(t * 4.0 + j * 1.2 + i) * .06, -1.2 - j * .1))
					_ustroke(ci, pts, Color(.55, .8, .35, .8), .035)
				if n >= 5:
					for i in 2:
						var a := t * 6.0 + i * PI
						var fp := Vector2(.8 + cos(a) * .45, -1.05 + sin(a * 1.3) * .25)
						_uell(ci, fp + Vector2(0, -.05), .05, .03, Color(1, 1, 1, .75))
						_ucirc(ci, fp, .045, INK)
		"bite":
			pass # Cut out of the body itself: see _bitten_body.
		"bloom":
			_clip_on()
			_uell(ci, Vector2(-.3, -.4), .5, .3, Color(1, 1, 1, .18), -.4)
			if n >= 3:
				# Pucker: a dusty plum bloom over its lower half (T3+).
				_uell(ci, Vector2(.1, .55), .9, .45, Color(.85, .8, 1, .2 if n < 5 else .3))
			if n >= 5:
				_clip = false
				# Pucker's T5: purple juice runs down its sides, with a sour glint.
				for i in 2:
					var q := fmod(t * .45 + i * .5, 1.0)
					_uell(ci, Vector2((-.8 + i * 1.6) * (1.0 - q * .12), -.3 + q * .9), .09, .13, Color(.62, .3, .9, .95 * (1.0 - q * .5)))
				for i in 3:
					_uglint(ci, _P(-PI / 2 + (i - 1) * .9, 1.2), .22, t, i * 2.1, Color(.9, .8, 1.0))
			if n >= 3:
				for i in 10 if n < 5 else 16:
					_ucirc(ci, Vector2((_hash(i + 70) - .5) * 1.5, (_hash(i + 80) - .5) * 1.5), .035, Color(1, 1, 1, .8)) # sour sugar coat
		"boltant":
			var bolt := PackedVector2Array([Vector2(.05, -.85), Vector2(-.15, -1.2), Vector2(.05, -1.2), Vector2(-.1, -1.55), Vector2(.25, -1.1), Vector2(.05, -1.1), Vector2(.2, -.85)])
			if n >= 3:
				# Bolt: its antenna buzzes with a glow (T3); at T5 twin side bolts crackle.
				_ucirc(ci, Vector2(.05, -1.2), .32, Color(1, .9, .3, .2 + .1 * sin(t * 8.0)))
			if n >= 5:
				for k in [-1, 1]:
					_xf = Transform2D(k * .5, Vector2.ZERO)
					_ufill(ci, bolt, Color("ffb627"))
				_xf = Transform2D.IDENTITY
				var ta := Vector2(-.1, -1.55).rotated(-.5)
				var tb := Vector2(-.1, -1.55).rotated(.5)
				var zap := PackedVector2Array([ta])
				for j in range(1, 5):
					zap.append(ta.lerp(tb, j / 5.0) + Vector2(0, (_hash(floorf(t * 14.0) + j) - .5) * .25 - .12))
				zap.append(tb)
				_ustroke(ci, zap, Color(.8, .95, 1, .85), .03)
			_ufill(ci, bolt, Color("ffe14a"))
		"boltcrest":
			if n >= 3:
				# Stormwing: the crest glows (T3); at T5 it burns white-gold with a crackle between the bolts.
				_ucirc(ci, Vector2(0, -1.3), .45, Color(1, .9, .3, .18 + .1 * sin(t * 6.0)))
			for i in 3:
				_xf = Transform2D((i - 1) * .45, Vector2.ZERO)
				var bolt_col := Color("ffe14a") if i == 1 else Color("ffb627")
				if n >= 5:
					bolt_col = Color("fff8d0") if i == 1 else GOLD
				_ufill(ci, PackedVector2Array([Vector2(.05, -.85), Vector2(-.15, -1.25), Vector2(.05, -1.25), Vector2(-.1, -1.65), Vector2(.25, -1.15), Vector2(.05, -1.15), Vector2(.2, -.85)]), bolt_col)
			_xf = Transform2D.IDENTITY
			if n >= 5:
				var ta := Vector2(-.1, -1.65).rotated(-.45)
				var tb := Vector2(-.1, -1.65).rotated(.45)
				var zap := PackedVector2Array([ta])
				for j in range(1, 5):
					zap.append(ta.lerp(tb, j / 5.0) + Vector2(0, (_hash(floorf(t * 14.0) + j) - .5) * .25 - .15))
				zap.append(tb)
				_ustroke(ci, zap, Color(.85, .95, 1, .9), .03)
		"bow":
			# Bonbon: ribbon tails at T3, a gold bow at T5.
			var bow_col := GOLD if n >= 5 else Color("ff5c9a")
			for k in [-1, 1]:
				if n >= 3:
					_ufill(ci, PackedVector2Array([Vector2(k * .05, -1.0), Vector2(k * .3, -1.62 + sin(t * 4.0 + k) * .04), Vector2(k * .42, -1.5)]), shade(bow_col, -.2))
				_ufill(ci, PackedVector2Array([Vector2(0, -1), Vector2(k * .55, -1.35), Vector2(k * .55, -.7)]), bow_col)
			_ucirc(ci, Vector2(0, -1.02), .12, GOLD_LIGHT if n >= 5 else Color("ff8fb8"))
			if n >= 5:
				_uglint(ci, Vector2(.32, -1.15), .16, t)
		"bulbs":
			var k := n + 2
			if n >= 3:
				# Pinball: a gold rim (T3); at T5 two flippers flick under it.
				_uring(ci, Vector2.ZERO, .98, Color(GOLD, .8), .05)
			for i in k:
				var a := PI * .15 + float(i) / (k - 1) * PI * .7
				_ucirc(ci, _P(a, .87), .07, Color("ffe14a") if sin(t * 5.0 + i) > 0.0 else Color("7d6a2a"))
			if n >= 5:
				for side in [-1, 1]:
					var flick := .35 * maxf(0.0, sin(t * 4.0 + side * 1.5))
					var root := Vector2(side * .78, .95)
					var tip := root + Vector2(-side * .5, .2).rotated(-side * flick)
					_utaper(ci, PackedVector2Array([root, tip]), .22, .1, Color("e0213b"))
					_ucirc(ci, root, .09, Color("f6f1e4"))
		"candle":
			if s.get("phased", false):
				# Faded out: the flame is snuffed, leaving a glowing wick and a curl of smoke.
				_ucirc(ci, Vector2(0, -1.07), .05, Color("ff5a1f"))
				for i in 3:
					var p := fmod(t * .9 + i / 3.0, 1.0)
					_ucirc(ci, Vector2(sin(t * 3.0 + i * 2.0) * .12, -1.15 - p * .7), .07 + p * .12, Color(.75, .72, .8, .55 * (1.0 - p)))
			elif n >= 5:
				# Flicker's T5: a tall blue-white flame.
				var fl := 1.0 + .15 * sin(t * 10.0)
				_uell(ci, Vector2(0, -1.35), .36, .55 * fl, Color(.55, .75, 1.0, .2))
				_uell(ci, Vector2(0, -1.33), .2, .4 * fl, Color("6fa8ff"))
				_uell(ci, Vector2(0, -1.24), .11, .23 * fl, Color("eef6ff"))
			elif n >= 3:
				# Flicker: a bigger flame with a blue heart.
				var fl := 1.0 + .15 * sin(t * 10.0)
				_uell(ci, Vector2(0, -1.28), .19, .36 * fl, Color("ff8a1f"))
				_uell(ci, Vector2(0, -1.2), .1, .2 * fl, Color("ffe066"))
				_uell(ci, Vector2(0, -1.08), .07, .05, Color("6fa8ff"))
			else:
				var fl := 1.0 + .15 * sin(t * 10.0)
				_uell(ci, Vector2(0, -1.25), .16, .3 * fl, Color("ff8a1f"))
				_uell(ci, Vector2(0, -1.18), .08, .16 * fl, Color("ffe066"))
			_uline(ci, Vector2(0, -.95), Vector2(0, -1.05), INK, .04)
		"candyrings":
			# Jawbreaker: five layers at T3, a full rainbow shell of seven that cycles at T5.
			var rings := [.9, .7, .5, .3]
			if n >= 5:
				rings = [.92, .79, .66, .53, .4, .27, .14]
			elif n >= 3:
				rings = [.9, .74, .58, .42, .26]
			for i in rings.size():
				if n >= 5:
					_uring(ci, Vector2.ZERO, rings[i], _hsl(i * 51 + t * 40.0, .8, .62 + i * .03), .1)
				else:
					_uring(ci, Vector2.ZERO, rings[i], _hsl(i * 70 + 160, .7, .6 + i * .05), .09)
			if n >= 5:
				_uglint(ci, Vector2(-.42, -.45), .2, t)
		"canopy":
			var leaves := [Vector3(-.6, -.85, .45), Vector3(.6, -.85, .45), Vector3(0, -1.15, .55), Vector3(-.25, -.95, .4), Vector3(.3, -1.05, .4)]
			for i in leaves.size():
				var b: Vector3 = leaves[i]
				var leaf := Color("3f8f3a") if i % 2 else Color("58b04a")
				if n >= 5:
					leaf = [Color("e0a030"), Color("d9682b"), Color("f2c14e")][i % 3]
				elif n >= 3 and i >= 3:
					leaf = Color("e0a030") if i == 3 else Color("d9682b")
				_ucirc(ci, Vector2(b.x, b.y + sin(t + i) * .02), b.z, leaf)
			if n >= 3:
				# Old Oak: autumn creeps in with an acorn (T3); at T5 an autumn-gold canopy sheds leaves.
				_uell(ci, Vector2(1.0, -.5), .1, .12, Color("a8702a"))
				_udome(ci, Vector2(1.0, -.56), .12, .08, Color("6b4a22"))
			if n >= 5:
				for i in 4:
					var q := fmod(t * .35 + i / 4.0, 1.0)
					var side := -1.0 if i % 2 else 1.0
					_uell(ci, Vector2(side * (1.2 + .15 * sin(t * 2.0 + i)), -.7 + q * 1.9), .12, .065, Color(GOLD if i < 2 else Color("e0a030"), 1.0 - q * .6), t * 3.0 + i)
		"cap":
			_udome(ci, Vector2(0, -.6), .75, .4, Color("3a4a1a"))
			_urect(ci, -.1, -.62, .9, .1, Color("2a3510"), .05)
			# Mortar: a bigger star at T3, three stars at T5.
			if n >= 5:
				for k in [-1, 1]:
					_ustar(ci, Vector2(k * .32, -.72), .07, .03, 5, GOLD)
			if n >= 3:
				_ustar(ci, Vector2(0, -.8), .14, .06, 5, GOLD)
			else:
				_ustar(ci, Vector2(0, -.8), .1, .045, 5, Color("ffd23f"))
			if n >= 3:
				# Mortar: camo patches (T3); at T5 a medal on its chest.
				_clip_on()
				for p in [Vector2(-.7, .1), Vector2(.75, -.1), Vector2(-.35, .75), Vector2(.45, .7), Vector2(.05, .95)]:
					_uell(ci, p, .24, .14, Color("3a4a1a", .55), p.x * 2.0)
				_clip = false
				if n >= 5:
					_ufill(ci, PackedVector2Array([Vector2(-.66, .35), Vector2(-.46, .35), Vector2(-.5, .6), Vector2(-.62, .6)]), Color("c4364f"))
					_ustar(ci, Vector2(-.56, .68), .12, .06, 5, GOLD)
		"chainball":
			var e := _P(t * 1.3, 1.7)
			if n >= 5:
				# Wrecker's T5: the wind-up lap blurs behind the ball.
				for k in range(3, 0, -1):
					_ucirc(ci, _P(t * 1.3 - k * .22, 1.7), .33, Color(.3, .32, .38, .4 - k * .1))
			_uline(ci, Vector2.ZERO, e, Color(1, .82, .31, .8), .06)
			if n >= 3:
				# Wrecker: a spiked wrecking ball.
				for i in 6:
					var a := i * TAU / 6 + t * 2.0
					_ufill(ci, PackedVector2Array([e + _P(a - .3, .32), e + _P(a, .5), e + _P(a + .3, .32)]), Color("6b7486"))
			_ucirc(ci, e, .35, Color("3c4250"))
			_ucirc(ci, e - Vector2(.1, .1), .1, Color("6b7486"))
		"cheeks":
			for k in [-1, 1]:
				_uell(ci, Vector2(k * .52, .22), .14, .09, Color(1, .47, .59, .6))
			if id == "blizz" and n >= 3:
				# Blizz: icicles hang off its chin (more, and longer, at T5).
				var k_ := 5 if n < 5 else 9
				for i in k_:
					var a := PI * .25 + (i + .5) / k_ * PI * .5
					var ln := (1.25 if n < 5 else 1.42) + .06 * (i % 2)
					_ufill(ci, PackedVector2Array([_P(a - .1, .93), _P(a, ln), _P(a + .1, .93)]), Color("dff6ff"))
				if n >= 5:
					_clip_on()
					for p in [Vector2(-.55, -.45), Vector2(.6, -.35), Vector2(.15, -.75)]:
						_uell(ci, p, .22, .12, Color(1, 1, 1, .35), .5)
					_clip = false
		"chestlight":
			_ucirc(ci, Vector2(0, .55), .13, Color("ffe14a"))
			_ucirc(ci, Vector2(0, .55), .22, Color(1, .88, .29, .2 + .15 * sin(t * 3.0)))
		"chips":
			# Idle: crumbs drop off it now and then.
			_clip = false
			for i in 2:
				var q := fmod(t * .5 + i * .5, 1.0)
				_ucirc(ci, Vector2(.3 + i * .3, .85 + q * .6), .07, Color(shade(c, -.2), 1.0 - q))
			for p in [Vector2(-.55, -.4), Vector2(.6, -.25), Vector2(-.3, .6), Vector2(.45, .55), Vector2(0, -.7), Vector2(-.75, .2)]:
				if n >= 5:
					_ucirc(ci, p, .16, Color(1, .6, .2, .28 + .12 * sin(t * 3.0 + p.x * 5.0)))
				_uell(ci, p, .09, .07, Color("4a2a14"))
				if n >= 3:
					# Crumb: the chips melt (T3) and glow (T5).
					_ucirc(ci, p + Vector2(.02, .085), .045, Color("4a2a14"))
					_ucirc(ci, p + Vector2(-.03, -.025), .022, Color(1, 1, 1, .5))
			if n >= 5:
				# Crumb's T5: gold foil along the bite edge.
				_uarc(ci, Vector2(.95, -.55), .27, 2.618 - 1.25, 2.618 + 1.25, GOLD, .06)
				_uarc(ci, Vector2(1.05, -.2), .22, 2.95 - 1.15, 2.95 + 1.15, GOLD, .06)
			if n >= 5:
				# Crumb's T5: pink icing on top with sprinkles.
				_clip_on()
				var icing := PackedVector2Array([Vector2(-1, -1)])
				for i in 11:
					var x := -1 + i * .2
					icing.append(Vector2(x, -.3 + (.18 if i % 2 else 0.0)))
				icing.append(Vector2(1, -1))
				_ufill(ci, icing, Color("ff9ccc"))
				for i in 9:
					_xf = Transform2D(_hash(i + 40) * 3.0, Vector2((_hash(i + 20) - .5) * 1.4, -.55 - _hash(i + 30) * .35))
					_urect(ci, -.06, -.02, .12, .04, Color.from_hsv(_hash(i + 50), .7, 1.0))
				_xf = Transform2D.IDENTITY
				_clip = false
		"clamshell":
			# Clam: an opal shimmer on the shell's seam (T3), a gold seam at T5.
			# The seam runs under the eyes, the pearl just below it.
			_uline(ci, Vector2(-1, .32), Vector2(1, .32), GOLD if n >= 5 else (_hsl(t * 60.0, .7, .75) if n >= 3 else shade(c, -.45)), .07)
			for i in range(-3, 4):
				_uline(ci, Vector2(i * .22, -.9 + absi(i) * .05), Vector2(i * .3, .22), shade(c, -.25), .04)
				_uline(ci, Vector2(i * .2, .95 - absi(i) * .03), Vector2(i * .26, .42), shade(c, -.25), .04)
		"clockface":
			_ucirc(ci, Vector2(0, .3), .5, Color("fdf3d8"))
			_uring(ci, Vector2(0, .3), .5, GOLD if n >= 3 else Color("7a5a1e"), .07 if n >= 3 else .05) # Clockwork: a gold bezel from T3.
			if n >= 5:
				for i in 4:
					_uline(ci, Vector2(0, .3) + _P(i * PI / 2, .38), Vector2(0, .3) + _P(i * PI / 2, .46), Color("b8860b"), .05)
			_uline(ci, Vector2(0, .3), Vector2(0, .3) + _P(t, .38), INK, .04)
			_uline(ci, Vector2(0, .3), Vector2(0, .3) + _P(t / 12.0, .25), INK, .05)
		"coil":
			_clip_on()
			for i in range(-3, 4):
				_uarc(ci, Vector2(0, i * .25), 1.05, PI * .15, PI * .85, Color("d98a4a"), .06)
			if n >= 3:
				# Zapper: the coil heats up bright copper (T3) and glows electric blue at T5.
				for i in range(-3, 4):
					var hot := Color(.55, .9, 1.0, .75 + .25 * sin(t * 9.0 + i)) if n >= 5 else Color("ffb070")
					_uarc(ci, Vector2(0, i * .25), 1.05, PI * .15, PI * .85, hot, .1 if n >= 5 else .07)
		"comettail":
			if n >= 5:
				_ucirc(ci, Vector2.ZERO, 1.28, Color(c.lightened(.4), .22 + .08 * sin(t * 4.0)))
			for i in 5:
				var y := (i - 2) * .25
				var d := absi(i - 2)
				var end := Vector2(-1.4 - _hash(i) * .4 - (.5 if n >= 5 else 0.0), y * 1.4 + sin(t * 6.0 + i) * .06)
				_uline(ci, Vector2(-.6, y * .9), end, Color(c, .5 - d * .1), .2 - d * .04)
				if n >= 3:
					# Comet: white-hot cores and star sparkles in the tail (longer, with a halo, at T5).
					_uline(ci, Vector2(-.6, y * .9), Vector2(-.6, y * .9).lerp(end, .7), Color(1, 1, 1, .45 - d * .1), .07)
			if n >= 3:
				for i in 4 if n >= 5 else 2:
					var q := fmod(t * .9 + i / 4.0, 1.0)
					_uglint(ci, Vector2(-1.1 - q * (1.2 if n >= 5 else .8), (_hash(i + 7) - .5) * .9), .2 * (1.0 - q * .4), t, i * 1.7, Color(1, 1, .85))
		"controlbar":
			var y := -1.75 + sin(t * 2.0) * .05
			var bar := GOLD if n >= 5 else Color("c9a46a")
			_urect(ci, -.6, y, 1.2, .08, bar)
			_urect(ci, -.04, y - .3, .08, .65, bar)
			for x in [-.55, .55]:
				# Puppeteer: brighter strings at T3, gold strings and a sparkling bar at T5.
				var string := Color(1, .9, .55, .5)
				if n >= 5:
					string = Color(GOLD, .95)
				elif n >= 3:
					string = Color(1, .92, .6, .8)
				_uline(ci, Vector2(x, y + .08), Vector2(x * 1.2, .2), string, .03 if n >= 5 else .02)
				if n >= 5:
					_uglint(ci, Vector2(x * 1.1, y + .04), .16, t, x * 4.0)
			if n >= 3:
				# Puppeteer: a little puppet dangles off the bar (it dances at T5).
				var sw := .15 * sin(t * (4.0 if n >= 5 else 2.0))
				var pp := Vector2(1.05 + sw, -.95)
				_uline(ci, Vector2(.6, y + .04), pp + Vector2(0, -.18), Color(1, .9, .55, .7), .02)
				_ucirc(ci, pp, .18 if n >= 5 else .14, Color("f2c94c") if n >= 5 else Color("d9b38c"))
				_uline(ci, pp + Vector2(-.12, .2), pp + Vector2(.12, .2), Color("8a5a3a"), .05)
				_ucirc(ci, pp + Vector2(-.05, -.02), .025, INK)
				_ucirc(ci, pp + Vector2(.05, -.02), .025, INK)
		"core":
			_ucirc(ci, Vector2(0, .35), .22 + .03 * sin(t * 5.0), Color(1, 1, 1, .9))
			if n >= 3:
				# Quasar: a ring round the core (prismatic at T5).
				_uring(ci, Vector2(0, .35), .34, _hsl(t * 120.0, .9, .72, .85) if n >= 5 else Color(1, 1, 1, .5), .04)
		"corona":
			if n >= 5:
				# Supernova's T5: eight long flares turn slowly round it.
				for i in 8:
					var a := i * TAU / 8.0 - t * .15
					var fl := 1.75 + .12 * sin(t * 3.0 + i)
					_ufill(ci, PackedVector2Array([_P(a - .2, .9), _P(a, fl), _P(a + .2, .9)]), Color(1, .72, .35, .75))
			if n >= 5:
				# Supernova's T5: a shockwave halo keeps rolling off it.
				var q := fmod(t * .5, 1.0)
				_uring(ci, Vector2.ZERO, 1.35 + q * .55, Color(1, .85, .5, .6 * (1.0 - q)), .07)
				_uring(ci, Vector2.ZERO, 1.42, Color(1, .9, .6, .2), .16)
			for i in 16:
				var a := i * .3927 + t * .3
				var L := 1.25 + .15 * sin(t * 4.0 + i * 2)
				_ufill(ci, PackedVector2Array([_P(a - .12, .95), _P(a, L), _P(a + .12, .95)]), Color(1, .84, .47, .7))
			if n >= 3:
				# Supernova: a second, white-hot ring of rays.
				for i in 16:
					var a := i * .3927 + .196 - t * .2
					var L := 1.14 + .08 * sin(t * 5.0 + i)
					_ufill(ci, PackedVector2Array([_P(a - .08, .95), _P(a, L), _P(a + .08, .95)]), Color(1, 1, .85, .8))
		"crust":
			_clip_on()
			for b in [Vector3(-.6, -.5, .3), Vector3(.5, .4, .35), Vector3(.55, -.6, .2), Vector3(-.4, .6, .22)]:
				if n >= 3:
					# Magmo: the crust glows at its edges (T3) and bubbles with lava at T5.
					_uell(ci, Vector2(b.x, b.y), b.z + .1, (b.z + .1) * .72, Color(1, .62, .15, .65 + .25 * sin(t * 3.0 + b.x * 4.0)))
				_uell(ci, Vector2(b.x, b.y), b.z, b.z * .7, Color(.24, .08, .04, .55))
			if n >= 5:
				for i in 3:
					var q := fmod(t * .7 + i / 3.0, 1.0)
					var p: Vector2 = [Vector2(-.6, -.5), Vector2(.5, .42), Vector2(-.4, .6)][i]
					_ucirc(ci, p, .05 + q * .1, Color(1, .6 + .3 * q, .2, .9 * (1.0 - q * q)))
		"cup":
			_clip_on()
			_urect(ci, -1, .15, 2, 1, Color("e0a85a"))
			for i in range(-4, 5):
				_uline(ci, Vector2(i * .25, .15), Vector2(i * .25 + .4, 1), Color("b87a35"), .03)
				_uline(ci, Vector2(i * .25, .15), Vector2(i * .25 - .4, 1), Color("b87a35"), .03)
		"door":
			if n >= 3:
				# Swarm: a honey-gold rim round the hive door (dripping at T5).
				_uell(ci, Vector2(0, .55), .22, .25, GOLD if n >= 5 else Color("e0a030"))
			_uell(ci, Vector2(0, .55), .17, .2, Color("3a2210"))
			if n >= 5:
				_ucirc(ci, Vector2(.08, .78), .045, GOLD)
				_uell(ci, Vector2(.08, .84 + .03 * sin(t * 3.0)), .045, .07, GOLD)
				_uglint(ci, Vector2(-.15, .36), .12, t)
		"dorsal":
			if n >= 5:
				# Fin's T5: a second fin, and the dorsal cuts a foamy wake.
				_ufill(ci, PackedVector2Array([Vector2(-.95, -.4), Vector2(-.82, -1.18), Vector2(-.5, -.82)]), shade(c, -.35))
				for i in 3:
					var q := fmod(t * 1.5 + i / 3.0, 1.0)
					_uarc(ci, Vector2(-.3 - q * .7, -1.05 - q * .1), .12 + q * .12, PI * .5, PI * 1.5, Color(1, 1, 1, .7 * (1.0 - q)), .04)
			_ufill(ci, PackedVector2Array([Vector2(-.35, -.85), Vector2(.15, -1.5), Vector2(.4, -.8)]), shade(c, -.25))
			if n >= 3:
				# Fin: white battle stripes across the fin.
				_uline(ci, Vector2(-.18, -.98), Vector2(.3, -1.0), Color(1, 1, 1, .8), .07)
				_uline(ci, Vector2(-.02, -1.18), Vector2(.22, -1.2), Color(1, 1, 1, .8), .06)
			if n >= 5:
				# Fin's T5: a big shark tail fin behind it.
				_ufill(ci, PackedVector2Array([Vector2(-.85, .1), Vector2(-1.65, -.55), Vector2(-1.4, .2), Vector2(-1.7, .8), Vector2(-.85, .45)]), shade(c, -.3))
		"drips":
			_clip_on()
			for i in 7:
				# Each drip hangs from the band and slowly stretches.
				var L := .14 + (i % 3) * .07 + .04 * sin(t * 1.5 + i * 1.3)
				var x := -.9 + i * .3
				_urect(ci, x - .06, -.62, .12, L + .06, shade(c, .3), .06)
				_ucirc(ci, Vector2(x, -.56 + L), .085, shade(c, .3))
				if id == "honey" and n >= 3 and i % 2 == 0:
					# Honey: glossy drips.
					_ucirc(ci, Vector2(x - .03, -.58 + L), .03, Color(1, 1, 1, .6))
			if id == "flicker" and n >= 3:
				# Flicker: wax trails run down the candle (long ones at T5).
				for i in 4 if n >= 5 else 2:
					_uell(ci, Vector2(-.75 + i * .5, -.25 + (i % 2) * .12), .07, .32 if n >= 5 else .2, shade(c, .3))
		"drops":
			for i in 4:
				var p := fmod(t * .8 + i / 4.0, 1.0)
				_uell(ci, Vector2(-.45 + i * .3, .8 + p * .7), .05, .09, Color(.59, .75, 1.0, 1.0 - p))
		"droptop":
			_ufill(ci, PackedVector2Array([Vector2(-.55, -.8), Vector2(0, -1.6), Vector2(.55, -.8)]), shade(c, -.1))
			if n >= 5:
				# Ripple's T5: a wave curls over like a breaker on its side.
				var crest := _quad(Vector2(-.98, -.2), Vector2(-1.05, -1.35), Vector2(-.3, -1.2), 12)
				_utaper(ci, crest, .32, .05, Color(.5, .82, 1.0, .9))
				_utaper(ci, crest, .14, .02, Color(.85, .97, 1.0, .9))
				for i in 4:
					_ucirc(ci, crest[3 * i] + Vector2(-.08, -.08 + sin(t * 5.0 + i) * .03), .05, Color.WHITE)
		"drumhead":
			_clip_on()
			_urect(ci, -1, -1, 2, .45, Color("f6ecd9"))
			_clip = false
			_uline(ci, Vector2(-.84, -.55), Vector2(.84, -.55), Color("c9b48a"), .06)
		"ears":
			if id == "frostfang" and n >= 5:
				# Frostfang's T5: an ice-crystal mane.
				for i in 7:
					var a := -PI / 2 + (i - 3) * .42
					_ufill(ci, PackedVector2Array([_P(a - .12, .85), _P(a, 1.45 if i % 2 == 0 else 1.3), _P(a + .12, .85)]), Color("dff6ff") if i % 2 else Color("9fe0ff"))
			for k in [-1, 1]:
				var tw := Vector2(k * .06, .1) if fmod(t + (k + 1) * .9, 3.3) < .18 else Vector2.ZERO # Idle: an ear twitches now and then.
				_ufill(ci, PackedVector2Array([Vector2(k * .35, -.8), Vector2(k * .8, -1.45) + tw, Vector2(k * .85, -.5)]), shade(c, -.3))
				_ufill(ci, PackedVector2Array([Vector2(k * .45, -.75), Vector2(k * .76, -1.22) + tw * .8, Vector2(k * .78, -.6)]), shade(c, .35))
				if n < 3:
					continue
				var tip := Vector2(k * .8, -1.45) + tw
				match id:
					"foxfire": # Blue fox-fire wisps on the ear tips (bigger at T5).
						var big := 1.4 if n >= 5 else 1.0
						_uell(ci, tip + Vector2(0, -.1 * big), .08 * big, (.15 + .03 * sin(t * 9.0 + k)) * big, Color("5fb7ff", .85))
						if n >= 5:
							_uell(ci, tip + Vector2(0, -.1), .04, .08, Color("e6f4ff"))
					"pounce": # Lynx tufts.
						_ufill(ci, PackedVector2Array([tip + Vector2(-.06, .05), tip + Vector2(k * .08, -.38), tip + Vector2(.06, .06)]), INK)
						if n >= 5 and k > 0:
							# Pounce's T5: a long snow-leopard tail curls up behind it.
							var tail := _quad(Vector2(-.7, .55), Vector2(-1.75, .55), Vector2(-1.3, -.55), 12)
							_utaper(ci, tail, .32, .2, shade(c, -.05))
							for j in [4, 7, 10]:
								_ucirc(ci, tail[j], .09, shade(c, -.5))
							_ucirc(ci, tail[tail.size() - 1], .1, shade(c, -.5))
					"frostfang": # Frosted ear tips.
						_ufill(ci, PackedVector2Array([Vector2(k * .68, -1.22), tip, Vector2(k * .84, -1.2)]), Color("dff6ff"))
		"embers":
			_clip_on()
			var cracks := [[Vector2(-.7, -.3), Vector2(-.3, -.1), Vector2(-.4, .3)], [Vector2(.5, -.6), Vector2(.3, -.2), Vector2(.6, .1)], [Vector2(-.1, .5), Vector2(.3, .7)]]
			if n >= 3:
				# Sooty: more lava cracks, and at T5 they split wider and glow as it gets hurt.
				cracks += [[Vector2(-.8, .35), Vector2(-.55, .45), Vector2(-.6, .7)], [Vector2(.75, .3), Vector2(.5, .45), Vector2(.65, .65)]]
			if n >= 5:
				var hurt := 1.0 - float(s.get("hp_frac", 1.0))
				cracks += [[Vector2(-.2, -.85), Vector2(0, -.65), Vector2(.15, -.8)]]
				for i in cracks.size():
					_ustroke(ci, PackedVector2Array(cracks[i]), Color(1, .4, .1, .3 + .4 * hurt), .14 + .1 * hurt)
			for i in cracks.size():
				_ustroke(ci, PackedVector2Array(cracks[i]), Color(1, (120 + 60 * sin(t * 4.0 + i)) / 255.0, .16, .95), .06)
		"fantail":
			if n >= 5:
				# Minnow's T5: the school grows to three fish.
				for i in 2:
					var a := t * 1.1 + i * PI
					var p := Vector2(cos(a) * 1.55, sin(a) * .6 + .2)
					var dir := -1.0 if sin(a) > 0.0 else 1.0
					_ufill(ci, PackedVector2Array([p + Vector2(-dir * .15, 0), p + Vector2(-dir * .36, -.13), p + Vector2(-dir * .36, .13)]), shade(c, -.15))
					_uell(ci, p, .2, .12, shade(c, .1))
					_ucirc(ci, p + Vector2(dir * .09, -.03), .035, INK)
			_ufill(ci, PackedVector2Array([Vector2(-.85, 0), Vector2(-1.5, -.55), Vector2(-1.35, 0), Vector2(-1.5, .55)]), shade(c, -.15))
			if n >= 3:
				# Minnow: a shimmer runs over the tail.
				for k in [-1, 1]:
					_uline(ci, Vector2(-1.0, k * .1), Vector2(-1.38, k * .42), _hsl(t * 80.0 + k * 60, .8, .8, .75), .04)
		"scales": # Minnow's shimmering scales: nothing below T3, one row at T3, two at T5.
			if n >= 3:
				for row in 2 if n >= 5 else 1:
					for i in 4 - row:
						var p := Vector2(-.45 + i * .3 + row * .15, .5 + row * .2)
						_uarc(ci, p, .14, .25, PI - .25, _hsl(t * 90.0 + i * 50 + row * 90, .8, .82, .8), .04)
		"ringpull":
			if n >= 5:
				# Fizz's T5: the cap pops off on top of a tall geyser column.
				for i in 6:
					var q := float(i) / 5.0
					_ucirc(ci, Vector2(.12 + sin(t * 9.0 + i) * .05, -1.0 - q * .75), .2 - q * .07, Color(1, 1, 1, .85) if i % 2 else Color(.85, .95, 1, .85))
				_xf = Transform2D(.5 + .15 * sin(t * 4.0), Vector2(.4, -1.95 + .05 * sin(t * 6.0)))
				_uell(ci, Vector2.ZERO, .25, .14, Color("c8ced8"))
				_uell(ci, Vector2.ZERO, .12, .06, Color("7d1a4a"))
				_xf = Transform2D.IDENTITY
			else:
				_uell(ci, Vector2(.15, -1), .25, .14, Color("c8ced8"))
				_uell(ci, Vector2(.15, -1), .12, .06, Color("7d1a4a"))
				if n >= 3:
					# Fizz: spray hisses out of the ring pull.
					for i in 3:
						var q := fmod(t * 1.2 + i / 3.0, 1.0)
						_ucirc(ci, Vector2(.15 + (i - 1) * .3 * q, -1.12 - q * .65), .08 * (1.0 - q * .4), Color(1, 1, 1, .9 * (1.0 - q)))
		"fizz":
			# Pressure (0-1) shakes the can up: more, faster bubbles.
			var pr: float = s.get("pressure", 0.0)
			_clip_on()
			for i in 9 + int(pr * 14.0):
				var p := fmod(t * (.4 + 1.8 * pr) + _hash(i), 1.0)
				_ucirc(ci, Vector2((_hash(i + 4) - .5) * 1.4, .9 - p * 1.8), .04 + _hash(i + 7) * .04, Color(1, 1, 1, .55 + .3 * pr))
			if n >= 3:
				# Fizz: a printed label round the can (T3); at T5 it's gold with stars.
				_urect(ci, -1, .3, 2, .34, Color("ffd23f") if n >= 5 else Color("f4f1ea"))
				_urect(ci, -1, .3, 2, .05, shade(c, -.35))
				_urect(ci, -1, .59, 2, .05, shade(c, -.35))
				for i in 3:
					_ustar(ci, Vector2(-.5 + i * .5, .47), .1, .045, 5, shade(c, -.2) if n < 5 else Color("e8344a"))
			_clip = false
		"flowercrown":
			for i in 5:
				var p := _P(-PI / 2 + (i - 2) * .38, 1.0)
				for j in 5:
					_ucirc(ci, p + _P(j * 1.256, .1), .08, Color("ffb3d1") if i % 2 else Color("fff1a8"))
				_ucirc(ci, p, .06, Color("ff8a3d"))
		"fluke":
			_ufill(ci, PackedVector2Array([Vector2(.85, .3), Vector2(1.45, .05), Vector2(1.25, .4), Vector2(1.45, .75)]), shade(c, -.2))
			if n >= 3:
				# Narwhal: a bigger, gold-edged tail (T5) and a water spout from its blowhole.
				if n >= 5:
					_ustroke(ci, PackedVector2Array([Vector2(1.45, .05), Vector2(1.25, .4), Vector2(1.45, .75)]), GOLD, .06)
				var h := .5 if n < 5 else .8
				for k in [-1, 1]:
					var arc := _quad(Vector2(-.3, -.95), Vector2(-.3 + k * .25, -.95 - h * 1.2), Vector2(-.3 + k * .55, -1.0 - h * .4), 10)
					_ustroke(ci, arc, Color(.75, .93, 1.0, .85), .07)
				for i in 3:
					_ucirc(ci, Vector2(-.3 + (i - 1) * .3, -1.05 - h - .05 * sin(t * 5.0 + i)), .07, Color(.85, .97, 1.0, .9))
		"foxtail":
			if n >= 3:
				# Foxfire: a second tail at T3, three blue-fire tails at T5.
				for rot in ([.6, -.6] if n >= 5 else [.6]):
					_xf = Transform2D(rot, Vector2.ZERO)
					_uell(ci, Vector2(-.95, .45), .5, .27, shade(c, -.2), -.5)
					_uell(ci, Vector2(-1.33, .22), .19, .14 + .03 * sin(t * 8.0 + rot), Color("5fb7ff"), -.5)
					if n >= 5:
						_uell(ci, Vector2(-1.37, .19), .08, .06, Color("e6f4ff"), -.5)
				_xf = Transform2D.IDENTITY
			_uell(ci, Vector2(-.95, .45), .55, .3, shade(c, -.1), -.5)
			_uell(ci, Vector2(-1.35, .2), .2, .15 + .03 * sin(t * 8.0), Color("5fb7ff"), -.5)
			if n >= 5:
				_uell(ci, Vector2(-1.38, .18), .09, .07, Color("e6f4ff"), -.5)
		"frill":
			if n >= 5:
				# Leviathan's T5: whirlpool spirals turn round it.
				for k in 2:
					var spiral := PackedVector2Array()
					for j in 16:
						var f := j / 15.0
						spiral.append(_P(t * 1.5 + k * PI + f * 3.5, 1.15 + f * .55))
					_ustroke(ci, spiral, Color(.5, .95, 1.0, .5), .05)
			for i in 5:
				_ufill(ci, PackedVector2Array([_P(-2.4 + i * .22, .9), _P(-2.3 + i * .22, 1.35), _P(-2.2 + i * .22, .9)]), Color("5ee6d0"))
				if n >= 3:
					_ucirc(ci, _P(-2.3 + i * .22, 1.35), .05, Color("dffff8")) # Leviathan: glowing frill tips.
		"fringe":
			_clip_on()
			for i in 9:
				_ufill(ci, PackedVector2Array([Vector2(-1 + i * .25, -1), Vector2(-.88 + i * .25, -.05), Vector2(-.76 + i * .25, -1)]), shade(c, -.08))
			if n >= 5:
				_clip = false
				_ubreath(ci, s, t, Color(.85, .97, 1.0, .3)) # Yeti's T5: icy breath.
			if n >= 3:
				# Yeti: frost settles on its head (T3); at T5 a thick cap of snow.
				_clip_on()
				var depth := .2 if n < 5 else .42
				var cap := PackedVector2Array([Vector2(-1, -1.05)])
				for i in 11:
					cap.append(Vector2(-1 + i * .2, -1 + depth + (.09 if i % 2 else 0.0)))
				cap.append(Vector2(1, -1.05))
				_ufill(ci, cap, Color(.92, .98, 1, .85) if n < 5 else Color("f8fdff"))
				if n >= 5:
					_uell(ci, Vector2(-.3, -.78), .2, .05, Color(1, 1, 1, .9), -.25)
				_clip = false
		"fur":
			for i in 22:
				var a := i / 22.0 * TAU
				_ufill(ci, PackedVector2Array([_P(a - .15, .9), _P(a, 1.15), _P(a + .15, .9)]), shade(c, -.15))
				if n >= 3 and i % 2 == 0:
					# Mammoth: frost on the fur tips (from T3).
					_ufill(ci, PackedVector2Array([_P(a - .06, 1.04), _P(a, 1.17), _P(a + .06, 1.04)]), Color("e6f6ff"))
		"fuzz":
			for i in 26:
				_ucirc(ci, _P(i / 26.0 * TAU, .97), .1, shade(c, -.15))
		"gearcrown":
			# Clockwork: the gears spin faster (T3, with a ruby hub), and at T5 two more join, bright gold.
			var spin := t * (1.0 if n < 3 else (2.0 if n < 5 else 3.5))
			var gears := [Vector3(-.4, -1.05, .22), Vector3(0, -1.18, .28), Vector3(.4, -1.05, .22)]
			if n >= 5:
				gears += [Vector3(-.8, -.92, .2), Vector3(.8, -.92, .2)]
			for i in gears.size():
				var g: Vector3 = gears[i]
				_xf = Transform2D(spin * (-1.0 if i % 2 else 1.0), Vector2(g.x, g.y))
				_ustar(ci, Vector2.ZERO, g.z, g.z * .75, 8, Color("ffd86a") if n >= 5 else Color("e0b04a"), 0.0)
				_ucirc(ci, Vector2.ZERO, g.z * .4, Color("7a5a1e"))
				if n >= 3 and i == 1:
					_ucirc(ci, Vector2.ZERO, .07, Color("e8344a"))
		"gears":
			_xf = Transform2D(t * (.5 + 9.0 * float(s.get("wind", 0.0))), Vector2.ZERO) # Spins faster as Cogs winds up.
			if n >= 3:
				# Cogs: a brass ring under the teeth (T3); every other tooth gold at T5.
				_uring(ci, Vector2.ZERO, 1.03, GOLD if n >= 5 else Color("e0b04a"), .06)
			for i in 14:
				var a := i / 14.0 * TAU
				_urect(ci, cos(a) * 1.05 - .09, sin(a) * 1.05 - .09, .18, .18, GOLD if n >= 5 and i % 2 == 0 else Color("b8743f"))
		"gearstick":
			if n >= 3:
				# Gearbox: an exhaust pipe that puffs smoke (T3) and blows a blue turbo flame at T5.
				_urect(ci, -1.28, .42, .5, .16, Color("8a8f99"), .05)
				if n >= 5:
					var fl := 1.0 + .2 * sin(t * 20.0)
					_uell(ci, Vector2(-1.5, .5), .3 * fl, .11, Color(.35, .6, 1.0, .85))
					_uell(ci, Vector2(-1.42, .5), .14 * fl, .05, Color(.85, .95, 1.0, .95))
				else:
					for i in 2:
						var q := fmod(t * .7 + i * .5, 1.0)
						_ucirc(ci, Vector2(-1.38 - q * .4, .45 - q * .3), .08 + q * .1, Color(.6, .6, .65, .5 * (1.0 - q)))
			var knob := Vector2(sin(t * 4.0) * .08, -1.38) # Idle: the gear stick jiggles.
			_uline(ci, Vector2(0, -.85), knob + Vector2(0, .08), Color("666666"), .07)
			_ucirc(ci, knob, .13, Color("222222"))
			if n >= 5:
				_uring(ci, knob, .13, GOLD, .04)
		"gills":
			for k in [-1, 1]:
				for i in 3:
					_uarc(ci, Vector2(k * .75, .1 + i * .13), .15, 2.4 if k > 0 else -.7, 3.8 if k > 0 else .7, Color("7af5e6"), .035)
		"glowbelly":
			_clip_on()
			_uell(ci, Vector2(0, .8), .9, .55, Color(.92, 1, .47, .55 + .3 * sin(t * 3.0)))
			if n >= 5:
				_uell(ci, Vector2(0, .85), .5, .3, Color(1, 1, .8, .35 + .25 * sin(t * 3.0)))
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
			if n >= 3:
				# Wrecker: a warning light on the hard hat (T3); at T5 it spins and the hat gets hazard stripes.
				if n >= 5:
					for i in 5:
						_urect(ci, -.7 + i * .3, -.92, .14, .38, Color("1a1a1a"))
					_urect(ci, -1, -.52, 2, .1, Color("1a1a1a"))
					_urect(ci, -.75, -.32, 1.5, .26, Color(.16, .78, 1, .75), .1)
				_urect(ci, -.18, -1.12, .36, .12, Color("555555"), .03)
				_udome(ci, Vector2(0, -1.1), .16, .2, Color("ff5a1f"))
				var sweep := sin(t * (8.0 if n >= 5 else 3.0))
				_ucirc(ci, Vector2(sweep * .08, -1.2), .06, Color(1, .9, .6, .9))
		"hazard":
			_clip_on()
			for i in range(-6, 6):
				_ufill(ci, PackedVector2Array([Vector2(i * .25, .45), Vector2(i * .25 + .125, .45), Vector2(i * .25 + .325, .75), Vector2(i * .25 + .2, .75)]), Color("ffcc1f") if i % 2 else Color("1a1a1a"))
			_urect(ci, -1, .44, 2, .02, Color("1a1a1a"))
		"helmet":
			var lamp := Vector2(0, -.8)
			if n >= 3 and not _sil:
				# Mole: the helmet lamp throws a light cone that fades out (brighter at T5).
				var beam := PackedVector2Array([_to_px(lamp), _to_px(Vector2(1.6, -1.55)), _to_px(Vector2(1.45, -.5))])
				var warm := Color(1, .97, .7, .38 if n >= 5 else .24)
				Dot.tri_colors(ci, beam, PackedColorArray([warm, Color(warm, 0.0), Color(warm, 0.0)]))
			_udome(ci, Vector2(0, -.55), .85, .5, GOLD if n >= 5 else Color("e3b23c"))
			if n >= 5:
				for x in [-.62, -.32, .32, .62]:
					_ucirc(ci, Vector2(x, -.62), .035, Color("a87f1e"))
				# Mole's T5: a spinning gold drill on top of the helmet.
				_ufill(ci, PackedVector2Array([Vector2(-.2, -1.02), Vector2(.2, -1.02), Vector2(0, -1.55)]), GOLD)
				var spin := fmod(t * 3.0, 1.0)
				for j in 3:
					var y := -1.08 - (j + spin) * .14
					if y > -1.46:
						var w := .2 * (1.55 + y) / .53
						_uline(ci, Vector2(-w, y + .035), Vector2(w, y - .035), Color("b8860b"), .035)
			if not _sil:
				Dot.glow(ci, _to_px(lamp), r_px(.42), _c(Color(1, .96, .7, .75)))
			_ucirc(ci, lamp, .15, Color("fffbd0"))
			if n >= 3:
				# Mole: digging goggles pushed up on the helmet (T3); at T5 their lenses glint.
				_urect(ci, -.78, -.6, 1.56, .1, Color("5a3a24"), .05)
				for k in [-1, 1]:
					_ucirc(ci, Vector2(k * .3, -.58), .17, Color("5a3a24"))
					_ucirc(ci, Vector2(k * .3, -.58), .11, Color("7fd3ff") if n >= 5 else Color("9ab8c8"))
					if n >= 5:
						_uglint(ci, Vector2(k * .3 - .03, -.62), .08, t, k)
		"hive":
			_clip_on()
			for i in range(-3, 4):
				_uline(ci, Vector2(-1, i * .28), Vector2(1, i * .28), shade(c, -.3), .05)
			if n >= 3:
				# Swarm: honey-gold hive bands (T3); at T5 honey oozes off the top.
				for i in range(-3, 4, 2):
					_urect(ci, -1, i * .28 - .04, 2, .08, Color("e0a030") if n < 5 else GOLD)
				if n >= 5:
					# Swarm's T5: honey runs down from the top of the hive.
					for i in 4:
						var x := -.54 + i * .36
						var dl := .3 + .12 * _hash(i + 3) + .05 * sin(t * 1.5 + i)
						_urect(ci, x - .06, -1.1, .12, .1 + dl, Color("f4a81d"), .06)
						_ucirc(ci, Vector2(x, -1.0 + dl), .085, Color("f4a81d"))
					_urect(ci, -1, -1.1, 2, .22, Color("f4a81d"))
		"hook":
			# Idle: the hook swings gently from its shoulder.
			var piv := Vector2(.9, -.3)
			_xf = Transform2D(.12 * sin(t * 2.0), piv) * Transform2D(0.0, -piv)
			if n >= 3:
				# Hook: a chain of links instead of the rope (T3); at T5 a glinting gold hook.
				var a := Vector2(.9, -.3)
				var b := Vector2(1.3, -.9)
				var ang := (b - a).angle()
				for i in 4:
					var p := a.lerp(b, (i + .5) / 4.0)
					_ustroke(ci, ellipse_pts(p, .085, .045, ang + (PI / 2 if i % 2 else 0.0), 0.0, TAU, 10), GOLD if n >= 5 else Color("cfd6e2"), .025)
			else:
				_uline(ci, Vector2(.9, -.3), Vector2(1.3, -.9), Color("b08a5a"), .05)
			_uarc(ci, Vector2(1.25, -1.05), .17, PI * .1, -PI * .7, GOLD if n >= 5 else Color("cfd6e2"), .08)
			if n >= 5:
				_uglint(ci, Vector2(1.25, -1.05) + _P(-PI * .7, .17), .18, t)
			_xf = Transform2D.IDENTITY
		"horn":
			# Narwhal: the horn grows at T3 and T5.
			var horn_tip := Vector2(.55, -1.75) if n < 3 else (Vector2(.62, -1.9) if n < 5 else Vector2(.7, -2.05))
			_ufill(ci, PackedVector2Array([Vector2(-.08, -.92), horn_tip, Vector2(.1, -.9)]), Color("f6f1e4"))
			# Narwhal: gold spiral grooves at T3; at T5 a rainbow glint runs up the horn.
			for i in range(1, 5):
				var groove := Color("c9bfa6")
				if n >= 5:
					groove = _hsl(t * 120.0 + i * 70, .9, .62)
				elif n >= 3:
					groove = Color("e0b04a")
				_uline(ci, Vector2(-.02 + i * .12, -.95 - i * .17), Vector2(.1 + i * .12, -.95 - i * .17), groove, .03 if n < 3 else .045)
			if n >= 5:
				_uline(ci, Vector2(.04, -1.0), Vector2(.6, -1.88), Color(1, 1, 1, .55), .03)
			if n >= 3:
				_uglint(ci, horn_tip, .26 if n >= 5 else .15, t)
		"horns":
			for k in [-1, 1]:
				_ufill(ci, PackedVector2Array([Vector2(k * .3, -.85), Vector2(k * .55, -1.35), Vector2(k * .62, -.75)]), Color("f2e6c8"))
				if n < 3:
					continue
				var tip_a := Vector2(k * .4, -1.02)
				var tip_b := Vector2(k * .6, -.98)
				if id == "yeti":
					# Yeti: frosted horn tips (T3), with icicles and a sparkle at T5.
					_ufill(ci, PackedVector2Array([tip_a, Vector2(k * .55, -1.35), tip_b]), Color("dff6ff"))
					if n >= 5:
						_ufill(ci, PackedVector2Array([Vector2(k * .58, -.95), Vector2(k * .66, -.68), Vector2(k * .62, -.85)]), Color("bfeaff"))
						_uglint(ci, Vector2(k * .55, -1.35), .14, t, k)
				elif n >= 5:
					_ufill(ci, PackedVector2Array([tip_a, Vector2(k * .55, -1.35), tip_b]), GOLD) # Drako's T5: gold-tipped horns.
		"jarlid":
			_clip_on()
			_urect(ci, -1, -1, 2, .45, Color("ffd23f"))
			for i in 4:
				_urect(ci, -1 + i * .55, -1, .25, .45, Color("2a2015"))
			_clip = false
			if n >= 3:
				# Honey: a honey dipper in the jar (T3); a bee buzzes round it at T5.
				_uline(ci, Vector2(.3, -.85), Vector2(.85, -1.45), Color("c98a3a"), .06)
				_uell(ci, Vector2(.93, -1.56), .13, .17, Color("e0a030"), .7)
				_uline(ci, Vector2(.8, -1.6), Vector2(1.0, -1.45), Color("a8702a"), .03)
			if n >= 5:
				var a := t * 2.2
				var p := Vector2(cos(a) * 1.45, sin(a) * .35 - 1.0)
				_uell(ci, p, .13, .09, Color("ffd23f"))
				_uline(ci, p + Vector2(0, -.09), p + Vector2(0, .09), Color("222222"), .04)
				_uell(ci, p + Vector2(0, -.11), .08, .05, Color(1, 1, 1, .8))
			if n >= 5:
				# Honey's T5: the jar overflows, honey pouring down over the lid.
				_clip_on()
				var pour := PackedVector2Array([Vector2(-1, -1)])
				for i in 11:
					var x := -1 + i * .2
					pour.append(Vector2(x, -.62 + (.28 if i % 3 == 1 else .08) + .03 * sin(t * 2.0 + i)))
				pour.append(Vector2(1, -1))
				_ufill(ci, pour, Color("f4a81d"))
				_uell(ci, Vector2(-.4, -.8), .22, .05, Color(1, 1, 1, .45), -.1)
				_clip = false
		"jets":
			# Quasar: a white core line in each jet (T3); at T5 a prismatic spinning cross of four.
			var arms := [0.0, PI / 2] if n >= 5 else [0.0]
			for j in arms.size():
				for k in [-1, 1]:
					_xf = Transform2D(t * .4 + arms[j], Vector2.ZERO)
					var pts := PackedVector2Array([Vector2(0, -.12), Vector2(k * 1.9, -.25), Vector2(k * 1.9, .25), Vector2(0, .12)])
					var sp := PackedVector2Array()
					for p in pts:
						sp.append(_to_px(p))
					var hot := _c(Color(1, 1, 1, .95) if n < 5 else _hsl(t * 90.0 + j * 120 + k * 60, 1.0, .78, .95))
					var cold := _c(Color(.71, .55, 1, 0))
					Dot.tri_colors(ci, PackedVector2Array([sp[0], sp[1], sp[2]]), PackedColorArray([hot, cold, cold]))
					Dot.tri_colors(ci, PackedVector2Array([sp[0], sp[2], sp[3]]), PackedColorArray([hot, cold, hot]))
					if n >= 3:
						_uline(ci, Vector2.ZERO, Vector2(k * 1.7, 0), Color(1, 1, 1, .7), .03)
		"key":
			# Cogs' T5: a gold double key, spinning faster.
			var key_col := GOLD if n >= 5 else Color("d9a35a")
			for off in ([0.0, PI / 2] if n >= 5 else [0.0]):
				_xf = Transform2D(t * (3.5 if n >= 5 else 2.0) + off, Vector2(1.1, 0))
				_urect(ci, -.25, -.06, .5, .12, key_col)
				_uell(ci, Vector2(-.3, 0), .1, .2, key_col)
				_uell(ci, Vector2(.3, 0), .1, .2, key_col)
			_xf = Transform2D.IDENTITY
			_uline(ci, Vector2(.9, 0), Vector2(1.1, 0), key_col, .08)
		"lamp":
			if n >= 3:
				# Beacon: the lamp glows (T3); at T5 a gold roof and a double sweeping light cone.
				_ucirc(ci, Vector2(0, -1.12), .45 if n >= 5 else .32, Color(1, .94, .6, .22 + .1 * sin(t * 3.0)))
			_urect(ci, -.28, -1.4, .56, .55, Color("d8f6ff"), .06)
			_uline(ci, Vector2(-.28, -1.12), Vector2(.28, -1.12), Color("2a5d5a"), .04)
			_ucirc(ci, Vector2(0, -1.12), .14, Color("fff2a0"))
			_ufill(ci, PackedVector2Array([Vector2(-.36, -1.4), Vector2(0, -1.65), Vector2(.36, -1.4)]), GOLD if n >= 5 else Color("c43c3c"))
			var a := t * 1.5
			var reach := 2.6 if n >= 5 else 2.2
			var beam := Color(1, .94, .59, .18 if n < 3 else .28)
			for b in ([a, a + PI] if n >= 5 else [a]):
				_ufill(ci, PackedVector2Array([Vector2(0, -1.12), Vector2(cos(b) * reach, -1.32 + sin(b) * .5), Vector2(cos(b) * reach, -.92 + sin(b) * .5)]), beam)
		"leaves":
			if n >= 3:
				# Sprout: a bud on a stem (T3); at T5 it flowers and seeds pop out like popcorn.
				_uline(ci, Vector2(0, -.9), Vector2(0, -1.3), Color("3a8a3a"), .05)
				if n >= 5:
					for i in 3:
						var q := fmod(t * 1.1 + i / 3.0, 1.0)
						_uell(ci, Vector2((i - 1) * .55 * (.4 + q), -1.3 - sin(q * PI) * .6), .06, .045, Color("f6e7b0", 1.0 - q * .3))
				else:
					_ucirc(ci, Vector2(0, -1.36), .1, Color("ff8fb8"))
			for k in [-1, 1]:
				_uell(ci, Vector2(k * .35, -1.15), .32, .14, Color("3fc45a"), k * -.7)
			if n >= 5:
				_uline(ci, Vector2(0, -1.25), Vector2(0, -1.45), Color("3a8a3a"), .05)
				_uflower(ci, Vector2(0, -1.5), .27, Color("fff6d8"), Color("ffb627"))
		"lever":
			_uline(ci, Vector2(.9, 0), Vector2(1.3, -.7), Color("c9ced8"), .07)
			_ucirc(ci, Vector2(1.32, -.75), .13, GOLD if n >= 3 else Color("e0213b")) # Jackpot: a gold knob from T3.
			if n >= 5:
				_uglint(ci, Vector2(1.38, -.82), .14, t)
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
			if n >= 3:
				# Mossy: a second mushroom sprouts (T3); at T5 the caps glow and spores drift off.
				_urect(ci, -.42, -1.22, .09, .3, Color("f3e7d3"))
				_udome(ci, Vector2(-.375, -1.22), .22, .16, Color("e0413b"))
				if n >= 5:
					for p in [Vector2(-.375, -1.3), Vector2(.16, -1.27)]:
						_uglint(ci, p, .16, t, p.x * 5.0, Color(.85, 1, .6))
				_ucirc(ci, Vector2(-.42, -1.3), .035, Color.WHITE)

			_urect(ci, .1, -1.15, .12, .3, Color("f3e7d3"))
			_udome(ci, Vector2(.16, -1.15), .32, .22, Color("e0413b"))
			_ucirc(ci, Vector2(.06, -1.25), .05, Color.WHITE)
			_ucirc(ci, Vector2(.28, -1.22), .04, Color.WHITE)
			if n >= 5:
				for i in 6:
					var q := fmod(t * .35 + _hash(i), 1.0)
					var p := Vector2((_hash(i + 5) - .5) * 2.2 + sin(t + i) * .1, -1.0 - q * 1.0)
					_ucirc(ci, p, .13, Color(.7, 1, .5, .35 * (1.0 - q)))
					_ucirc(ci, p, .06, Color(.88, 1, .62, 1.0 - q * .7))
		"napkin":
			_xf = Transform2D(0.0, Vector2(0, _munch_drop(t))) # Tied on the jaw, so it chomps too.
			if n >= 3:
				# Munch: a big tied-on bib (T3); at T5 it has a gold edge and a gold crest.
				for k in [-1, 1]:
					_ufill(ci, PackedVector2Array([Vector2(k * .5, .56), Vector2(k * .85, .36), Vector2(k * .8, .68)]), Color.WHITE)
				_ufill(ci, PackedVector2Array([Vector2(-.62, .55), Vector2(0, 1.32), Vector2(.62, .55)]), Color.WHITE)
				_uline(ci, Vector2(-.31, .94), Vector2(0, 1.32), GOLD if n >= 5 else Color("e85d5d"), .05)
				_uline(ci, Vector2(.31, .94), Vector2(0, 1.32), GOLD if n >= 5 else Color("e85d5d"), .05)
			else:
				_ufill(ci, PackedVector2Array([Vector2(-.45, .55), Vector2(0, 1.05), Vector2(.45, .55)]), Color.WHITE)
			_uline(ci, Vector2(-.45, .55), Vector2(.45, .55), GOLD if n >= 5 else Color("e85d5d"), .06)
			if n >= 5:
				_ufill(ci, PackedVector2Array([Vector2(-.15, .86), Vector2(.15, .86), Vector2(.15, .99), Vector2(0, 1.13), Vector2(-.15, .99)]), GOLD)
				_ustar(ci, Vector2(0, .96), .07, .03, 5, Color("b8860b"))
		"number":
			_ucirc(ci, Vector2(.55, .45), .22, Color.WHITE)
			_utext(ci, Vector2(.55, .47), "7", .3, INK)
			if n >= 3:
				# Gearbox: twin racing stripes (white at T3, gold at T5).
				_clip_on()
				for x in [-.2, .08]:
					_urect(ci, x, -1, .12, .62, Color.WHITE if n < 5 else GOLD)
					_urect(ci, x, .22, .12, .8, Color.WHITE if n < 5 else GOLD)
				_clip = false
				_ucirc(ci, Vector2(.55, .45), .22, Color.WHITE)
				_utext(ci, Vector2(.55, .47), "7", .3, INK if n < 5 else Color("c4364f"))
		"panel":
			_urect(ci, -.4, .35, .8, .4, Color(0, 0, 0, .25), .06)
			var lights := [Vector2(-.32, .43), Vector2(.32, .43), Vector2(-.32, .67), Vector2(.32, .67)]
			for i in lights.size():
				_ucirc(ci, lights[i], .035, _hsl(t * 120.0 + i * 90, .9, .65) if n >= 5 else Color("cfe3ff")) # Bolt's T5: blinking lights.
			if n >= 3:
				# Bolt: circuit traces run over its casing (T3); at T5 they glow gold.
				_clip_on()
				var tr := Color("9fd0ff", .7) if n < 5 else Color(GOLD, .75 + .2 * sin(t * 5.0))
				for k in [-1, 1]:
					_ustroke(ci, PackedVector2Array([Vector2(k * .4, .55), Vector2(k * .65, .55), Vector2(k * .8, .3), Vector2(k * 1.0, .3)]), tr, .035)
					_ustroke(ci, PackedVector2Array([Vector2(k * .2, -.45), Vector2(k * .2, -.7), Vector2(k * .55, -.7), Vector2(k * .7, -.95)]), tr, .035)
					_ucirc(ci, Vector2(k * .2, -.45), .05, tr)
					_ucirc(ci, Vector2(k * .65, .55), .05, tr)
				_clip = false
		"pearl":
			if n >= 5:
				# Clam's T5: a golden pearl between two opal ones.
				for k in [-1, 1]:
					_ucirc(ci, Vector2(k * .3, .62), .09, _hsl(t * 50.0 + k * 90, .7, .88))
				_ucirc(ci, Vector2(0, .56), .19, GOLD)
				_ucirc(ci, Vector2(-.05, .51), .06, Color.WHITE)
				_uglint(ci, Vector2(.1, .43), .14, t)
			elif n >= 3:
				# Clam: an opalescent pearl.
				_ucirc(ci, Vector2(0, .56), .16, Color("fbf6ff"))
				_uring(ci, Vector2(0, .56), .11, _hsl(t * 60.0, .8, .75, .8), .04)
				_ucirc(ci, Vector2(-.04, .52), .04, Color.WHITE)
			else:
				_ucirc(ci, Vector2(0, .56), .14, Color("fbf6ff"))
				_ucirc(ci, Vector2(-.04, .52), .04, Color.WHITE)
				_uglint(ci, Vector2(.07, .49), .1, t) # Idle: the pearl twinkles.
		"pods":
			for k in [-1, 1]:
				_urect(ci, k * .95 - .22, -.75, .44, .55, Color("5d7699"), .1)
				if n >= 3:
					# Megabot: the pod hatches flip open on rocket noses (T3), venting steam at T5.
					_urect(ci, k * .95 - .22 + k * .12, -.98, .44, .1, Color("8aa0c0"), .04)
					_ufill(ci, PackedVector2Array([Vector2(k * .95 - .08, -.75), Vector2(k * .95, -.92), Vector2(k * .95 + .08, -.75)]), Color("ff6a3d"))
				for j in 2:
					_ucirc(ci, Vector2(k * .95, -.6 + j * .22), .07, Color("ff6a3d"))
				if n >= 5:
					for i in 2:
						var q := fmod(t * .8 + i * .5 + k * .25, 1.0)
						_ucirc(ci, Vector2(k * (1.25 + q * .3), -.45 - q * .4), .08 + q * .12, Color(.9, .92, .95, .55 * (1.0 - q)))
		"pot":
			_clip_on()
			_urect(ci, -1, -.95, 2, .35, Color("7dff6a"))
			for i in 4:
				_ucirc(ci, Vector2(-.6 + i * .4, -.62 - absf(sin(t * 3.0 + i)) * .1), .08, Color("b8ff9e"))
			_clip = false
			_uline(ci, Vector2(-.8, -.6), Vector2(.8, -.6), Color("1d2a1d"), .07)
			if n >= 5:
				# Brewster's T5: the cauldron boils over in green steam.
				for i in 3:
					var q := fmod(t * .6 + i / 3.0, 1.0)
					_ucirc(ci, Vector2(-.5 + i * .5 + sin(t * 2.0 + i) * .08, -.75 - q * .8), .1 + q * .15, Color(.75, 1, .7, .45 * (1.0 - q)))
			if n >= 3:
				# Brewster: potion drips down from the brim (longer at T5).
				for i in 3:
					var x := -.55 + i * .55
					var dl := (.25 if n < 5 else .45) + .05 * sin(t * 2.0 + i)
					_urect(ci, x - .06, -.62, .12, dl, Color("7dff6a"), .06)
		"rears":
			for k in [-1, 1]:
				_uell(ci, Vector2(k * .95, -.25), .25, .12, Color("c9d0db"), k * .5)
		"reels":
			if n >= 3:
				_urect(ci, -.76, -.41, 1.52, .62, GOLD, .1) # Jackpot: a gold frame from T3.
			_urect(ci, -.7, -.35, 1.4, .5, Color("fdf3d8"), .08)
			var jackpot := n >= 5 and fmod(t, 2.0) < 1.0
			if n >= 5:
				# Jackpot's T5: the reels land on 777 every other second, and coins rain past.
				for i in 3:
					var q := fmod(t * .6 + i / 3.0, 1.0)
					var p := Vector2([-1.3, 1.3, -1.1][i], -1.2 + q * 2.4)
					var w := .13 * absf(cos(t * 4.0 + i)) + .03
					_uell(ci, p, w + .02, .15, Color("b8860b"))
					_uell(ci, p, w, .13, GOLD)
			for i in 3:
				var p := Vector2(-.45 + i * .45, -.1)
				if jackpot:
					_utext(ci, p, "7", .3, Color("e0213b"))
					continue
				match int(floorf(t * 4.0 + i * 1.3)) % 3:
					0:
						_utext(ci, p, "7", .3, INK)
					1:
						_ustar(ci, p, .13, .055, 5, INK)
					_:
						_ufill(ci, PackedVector2Array([p + Vector2(0, -.13), p + Vector2(.1, 0), p + Vector2(0, .13), p + Vector2(-.1, 0)]), INK)

		"rodball":
			_uline(ci, Vector2(0, -.85), Vector2(0, -1.4), Color("8a6239"), .08)
			if n >= 3:
				# Zapper: an arc jumps from the ball (three round a white-hot core at T5).
				var seed_ := floorf(t * 12.0)
				var arcs := 3 if n >= 5 else 1
				for j in arcs:
					var end := _P(-PI / 2 + (j - (arcs - 1) / 2.0) * .9 + (.5 if arcs == 1 else 0.0), .98)
					var zap := PackedVector2Array([Vector2(0, -1.5)])
					for m in range(1, 4):
						zap.append(Vector2(0, -1.5).lerp(end, m / 4.0) + Vector2((_hash(seed_ + m + j * 5) - .5) * .25, 0))
					zap.append(end)
					_ustroke(ci, zap, Color(.75, .95, 1.0, .9), .035)
			if n >= 5:
				_ucirc(ci, Vector2(0, -1.5), .45, Color(.59, .9, 1, .2))
			_ucirc(ci, Vector2(0, -1.5), .17 + .02 * sin(t * 20.0), Color("b4f2ff"))
			_ucirc(ci, Vector2(0, -1.5), .3, Color(.59, .9, 1, .25))
			if n >= 5:
				_ucirc(ci, Vector2(0, -1.5), .09, Color.WHITE)
		"rope":
			_clip_on()
			var pts := PackedVector2Array()
			for i in 11:
				pts.append(Vector2(-1 + i * .2, .2 if i % 2 else .65))
			_ustroke(ci, pts, Color("f6ecd9"), .06)
			if n >= 3:
				# Drum: hoop rims top and bottom (gold at T5), studs round the top hoop.
				var hoop := GOLD if n >= 5 else Color("f6ecd9")
				_urect(ci, -1, -.56, 2, .1, hoop)
				_urect(ci, -1, .85, 2, .1, hoop)
				for i in 7:
					_ucirc(ci, Vector2(-.75 + i * .25, -.51), .035, Color("8a6a2a"))
		"ruff":
			for i in 9:
				_ufill(ci, PackedVector2Array([Vector2(-.9 + i * .225, .45), Vector2(-.79 + i * .225, .8), Vector2(-.68 + i * .225, .45)]), Color("f4f7ff"))
			_clip_on()
			_urect(ci, -1, .62, 2, .5, Color("f4f7ff"))
			_clip = false
			if n >= 3:
				# Frostfang: ice shards in the ruff (T3), and a blue breath mist at T5.
				for i in 3:
					var x := -.5 + i * .5
					_ufill(ci, PackedVector2Array([Vector2(x - .08, .55), Vector2(x, .92), Vector2(x + .08, .55)]), Color("9fe0ff"))
			if n >= 5:
				_ubreath(ci, s, t, Color(.6, .85, 1.0, .5))
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
				if n >= 5 and live > 0:
					_usauce(ci, Vector2(sin((mini(live, 5) - 1) * 2.1) * .12, top), .4 - (mini(live, 5) - 1) * .03)
				_ucirc(ci, Vector2(.05, top - .38), .12, Color("e0213b"))
			else:
				for i in count:
					_ucirc(ci, Vector2(scoops[i][1], scoops[i][2]), .38, scoops[i][0])
				if n >= 3:
					# Sundae: sprinkles (T3); at T5 chocolate sauce and a cherry with a stem.
					for i in 6:
						var p := Vector2(-.5 + i * .2, -.95 - (i % 3) * .12)
						_uline(ci, p, p + _P(i * 1.3, .08), [Color("ff5c9a"), Color("5fb7ff"), Color("ffe14a")][i % 3], .035)
				if n >= 5:
					_usauce(ci, Vector2(0, -1.3), .38)
				# The cherry sits on the top scoop (the spec floats it at T3+ height).
				var cherry := Vector2(.05 + sin(t * 3.0) * .05, -1.75 if count >= 3 else -1.38) # Idle: the cherry wobbles.
				if n >= 5:
					_ustroke(ci, _quad(cherry + Vector2(0, -.08), cherry + Vector2(.05, -.25), cherry + Vector2(.2, -.32), 6), Color("4a7a2a"), .03)
				_ucirc(ci, cherry, .12, Color("e0213b"))
				if n >= 5:
					_uglint(ci, cherry + Vector2(-.04, -.04), .1, t)
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
				if n >= 3:
					# Leviathan: the stinger rings glow (white-hot at T5).
					_ucirc(ci, tail[i], .2 - i * .008, Color(.37, .94, .9, .22 + .12 * sin(t * 4.0 + i)))
				_uring(ci, tail[i], .16 - i * .008, Color("bffff8") if n >= 5 else Color("5ff0e6", .85), .045)
		"shades":
			for k in [-1, 1]:
				if n >= 5:
					_ustar(ci, Vector2(k * .3, -.1), .25, .13, 5, GOLD) # Disco's T5: gold-rimmed shades.
				_ustar(ci, Vector2(k * .3, -.1), .2, .1, 5, Color("1a1530"))
				if n >= 3:
					_uglint(ci, Vector2(k * .3 - .06, -.16), .08, t, k * 2.0)
		"shards":
			_clip_on()
			for i in 8:
				var a := i * .785 + floorf(t / 1.2) * .785
				_ufill(ci, PackedVector2Array([Vector2.ZERO, _P(a, 1.2), _P(a + .785, 1.2)]), _hsl(i * 45 + 300, .8, .65, .45))
			_clip = false
			if n >= 3:
				# Kaleido: mirror shards turn round it in a kaleidoscope ring (four at T3, eight at T5).
				var k := 8 if n >= 5 else 4
				for i in k:
					var a := t * .8 + i * TAU / k
					var p := _P(a, 1.38)
					_ufill(ci, PackedVector2Array([p + _P(a + t * 2.0, .16), p + _P(a + t * 2.0 + 2.1, .16), p + _P(a + t * 2.0 + 4.2, .16)]), _hsl(i * 360.0 / k + t * 60.0, .85, .7, .85))
		"sheen":
			_uarc(ci, Vector2.ZERO, .8, -2.6, -1.4, _hsl(t * 60.0, .9, .75, .6), .08)
			_uarc(ci, Vector2.ZERO, .7, -2.4, -1.6, _hsl(t * 60.0 + 120.0, .9, .75, .5), .06)
			if n >= 3:
				# Bubbles: little bubbles float up beside it; at T5 a rainbow soap-film ring wraps it.
				for i in 3 if n >= 5 else 2:
					var q := fmod(t * .4 + i / 3.0, 1.0)
					_uring(ci, Vector2(1.05 + sin(t * 2.0 + i * 2.0) * .12 - i * .1, .5 - q * 1.6), .1 + .04 * i, Color(1, 1, 1, .75 * (1.0 - q)), .03)
			if n >= 5:
				for i in 6:
					var a := i * TAU / 6 + t * .5
					_uarc(ci, Vector2.ZERO, 1.1, a, a + TAU / 6 + .05, _hsl(i * 60 + t * 90.0, .9, .75, .55), .06)
		"shellhex":
			if n >= 3:
				# Shelly: knobs on the shell rim (T3) that become spikes at T5.
				var spikes := 7 if n >= 5 else 4
				var rim := func(a: float, k: float) -> Vector2: return Vector2(cos(a) * 1.02 * k, -.05 + sin(a) * .85 * k)
				for i in spikes:
					var a := PI + (i + .5) / spikes * PI
					_ufill(ci, PackedVector2Array([rim.call(a - .14, .97), rim.call(a, 1.3 if n >= 5 else 1.17), rim.call(a + .14, .97)]), Color("f2e6c8") if n >= 5 else shade(c, .3))
			_udome(ci, Vector2(0, -.05), 1.02, .85, shade(c, -.3))
			if n >= 3:
				# Shelly: a pale rim round the shell (T3), gold at T5.
				_ustroke(ci, ellipse_pts(Vector2(0, -.05), .96, .8, 0.0, PI, TAU, 18), Color("f2e6c8") if n < 5 else GOLD, .08)
			_uglint(ci, Vector2(sin(t * .9) * .7, -.62 + absf(sin(t * .9)) * .2), .16, t) # Idle: light slides over the shell.
			for i in range(-2, 3):
				_ustar(ci, Vector2(i * .38, -.45 + absi(i) * .12), .17, .17, 3, (GOLD if i == 0 else Color("e0b85a")) if n >= 5 else shade(c, .05), 0.0)
		"shine":
			if n >= 3:
				# Ripple: a wave line rolls across its lower half.
				_clip_on()
				var wave := PackedVector2Array()
				for i in 13:
					var x := -1.0 + i / 6.0
					wave.append(Vector2(x, .62 + sin(x * 5.0 + t * 3.0) * .06))
				_ustroke(ci, wave, Color(1, 1, 1, .55), .06)
				_clip = false
			_uell(ci, Vector2(-.4, -.35), .15, .3, Color(1, 1, 1, .6), .5)
		"sidefins":
			if n >= 3:
				# Puff: spines pop out all round (longer and gold-tipped at T5).
				var k_ := 16 if n >= 5 else 10
				var L := (1.38 if n >= 5 else 1.22) + .05 * sin(t * 2.2) # Idle: it puffs up and down.
				for i in k_:
					var a := i * TAU / k_ + .15
					_ufill(ci, PackedVector2Array([_P(a - .09, .92), _P(a, L), _P(a + .09, .92)]), Color("f4efd6"))
					if n >= 5:
						_ufill(ci, PackedVector2Array([_P(a - .03, L - .13), _P(a, L), _P(a + .03, L - .13)]), GOLD)
			for k in [-1, 1]:
				_ufill(ci, PackedVector2Array([Vector2(k * .9, -.2), Vector2(k * (1.35 + .1 * sin(t * 6.0 + k)), .1), Vector2(k * .9, .35)]), shade(c, -.2)) # Idle: the fins paddle.
		"smoke":
			# Sooty: the plume grows with tier (with rising embers at T5).
			var puffs := 3 if n < 3 else (4 if n < 5 else 5)
			var grow := 1.0 if n < 3 else (1.15 if n < 5 else 1.35)
			for i in puffs:
				var p := fmod(t * .5 + i / float(puffs), 1.0)
				_ucirc(ci, Vector2(.2 + sin(i * 2.0) * .2, -1 - p * .8 * grow), (.12 + p * .15) * grow, Color(.63, .59, .67, .5 * (1.0 - p)))
			if n >= 5:
				for i in 3:
					var p := fmod(t * .7 + i / 3.0, 1.0)
					_ucirc(ci, Vector2(.1 + sin(t * 3.0 + i * 2.0) * .3, -.95 - p * 1.0), .04, Color(1, .55, .15, 1.0 - p))
		"snout":
			_urect(ci, .62, -.02, .45, .3, shade(c, -.1), .1)
			if n >= 5:
				# Pip's T5: a gold-banded triple muzzle.
				_urect(ci, .98, -.05, .1, .36, GOLD, .04)
				for y in [.02, .13, .24]:
					_uell(ci, Vector2(1.07, y), .035, .045, INK)
			else:
				_uell(ci, Vector2(1.06, .13), .07, .14, INK)
				if n >= 3:
					_urect(ci, .82, -.03, .07, .32, shade(c, -.35), .03) # Pip: a muzzle band.
		"snowflake":
			_xf = Transform2D(t * .5, Vector2(0, -1.2))
			for i in 6:
				_uline(ci, Vector2.ZERO, _P(i * 1.047, .4), Color("f2fbff"), .07)
				if n >= 3:
					# Blizz: the flake grows branches (T3); two mini flakes orbit it at T5.
					var at := _P(i * 1.047, .24)
					for side in [-1, 1]:
						_uline(ci, at, at + _P(i * 1.047 + side * .8, .12), Color("f2fbff"), .04)
			_ucirc(ci, Vector2.ZERO, .1, Color("f2fbff"))
			_xf = Transform2D.IDENTITY
			if n >= 5:
				for j in 2:
					_ustar(ci, Vector2(0, -1.2) + _P(t * 1.2 + j * PI, .78), .2, .06, 6, Color("dff6ff"), t)
				_uglint(ci, Vector2(0, -1.2), .2, t)
		"speckles":
			_clip_on()
			# Narwhal: its speckles turn pearly (T3) and gold at T5, and spread.
			for i in 12 if n < 3 else 20:
				var sp := shade(c, -.3) if n < 3 else (Color("f4fbff") if n < 5 else GOLD)
				_ucirc(ci, Vector2((_hash(i) - .5) * 1.8, (_hash(i + 3) - .5) * 1.6), .035 if n < 3 else .05, sp)
		"spikyhair":
			# Zigzag: the spikes grow taller (T3), and gold and taller again at T5.
			var top := -1.3 if n < 3 else (-1.45 if n < 5 else -1.62)
			for i in 5:
				var x := -.6 + i * .3
				_ufill(ci, PackedVector2Array([Vector2(x - .14, -.75), Vector2(x, top), Vector2(x + .14, -.75)]), shade(c, -.25) if n < 5 else GOLD)
				if n >= 5:
					_ucirc(ci, Vector2(x, top), .07, Color(1, .95, .4, .55 + .35 * sin(t * 9.0 + i))) # Zigzag's T5: charged tips.
		"splats":
			if n >= 5:
				# Painter's T5: a rainbow paint trail.
				var look: Vector2 = s.get("look", Vector2.RIGHT)
				var dir := look.normalized() if look.length() > .01 else Vector2.RIGHT
				var side := Vector2(-dir.y, dir.x)
				var paint := [Color("ff5a7a"), Color("ffd23f"), Color("7ee36a"), Color("45c4ff")]
				for i in 4:
					var a := -dir * .95 + side * (i - 1.5) * .17
					_uline(ci, a, a - dir * (.7 + .15 * sin(t * 6.0 + i)), Color(paint[i], .85), .16)
			_clip_on()
			for sp in [[Color("ff5a7a"), -.55, -.5], [Color("45c4ff"), .5, -.1], [Color("7ee36a"), -.2, .6], [Color("ffd23f"), .6, .55]]:
				var p := Vector2(sp[1], sp[2])
				_ucirc(ci, p, .14, sp[0])
				_ucirc(ci, p + Vector2(.12, -.1), .05, sp[0])
		"spots":
			_clip_on()
			for p in [Vector2(-.6, -.5), Vector2(.55, -.6), Vector2(-.7, .4), Vector2(.65, .35), Vector2(0, .75)]:
				if id == "pounce" and n >= 5:
					# Pounce's T5: snow-leopard rosettes.
					_uell(ci, p, .17, .13, shade(c, -.5))
					_uell(ci, p, .09, .06, shade(c, -.1))
				elif id == "puff" and n >= 3:
					# Puff: bolder spots (T3), gold at T5.
					_uell(ci, p, .19, .15, GOLD if n >= 5 else shade(c, -.45))
				else:
					_uell(ci, p, .13, .1, shade(c, -.35))
		"stemleaf":
			_uline(ci, Vector2(0, -.9), Vector2(.05, -1.2), Color("5b3a1e"), .07)
			_uell(ci, Vector2(.25, -1.18), .2, .08, Color("4caf50"), -.4)
			if n >= 3:
				# Pucker: a second leaf and a bead of juice (T3+).
				_uell(ci, Vector2(-.2, -1.14), .2, .08, Color("66bb6a"), .5)
				_uell(ci, Vector2(.28, -1.02), .07, .1, Color(.75, .45, 1.0, .9))
			if id == "pucker" and n >= 5:
				# Pucker's T5: plum blossom on the stem.
				for p in [Vector2(-.42, -1.32), Vector2(.48, -1.36), Vector2(.05, -1.5)]:
					_uflower(ci, p, .15, Color("ffc2dc"), Color("ff6fa3"))
		"sticks":
			if n >= 5:
				# Drum's T5: a gold cymbal on a stand.
				_uline(ci, Vector2(1.15, -.2), Vector2(1.15, -.95), Color("8a8f99"), .05)
				_uell(ci, Vector2(1.15, -.98), .36, .09, GOLD, -.15 + .06 * sin(t * 9.0))
				_uell(ci, Vector2(1.15, -1.0), .1, .04, GOLD_LIGHT, -.15)
				_uglint(ci, Vector2(1.32, -1.06), .14, t)
			for k in [-1, 1]:
				var tap := Vector2(0, .14 * absf(sin(t * 4.0 + k * 1.6))) # Idle: the sticks tap out a beat.
				_uline(ci, Vector2(k * .3, -.8), Vector2(k * .7, -1.45) + tap, Color("d9a35a"), .08)
				_ucirc(ci, Vector2(k * .72, -1.5) + tap, .1, Color("e8344a") if n >= 3 else Color("f6ecd9")) # Drum: red-wrapped sticks from T3.
		"stinger":
			# Zing: a longer, gold-tipped stinger (T3), all gold with a glint at T5.
			var sa := Vector2(-.85, .3)
			var sb := Vector2(-.8, .55)
			var tip := Vector2(-1.5, .64) if n >= 3 else Vector2(-1.3, .55)
			_ufill(ci, PackedVector2Array([sa, tip, sb]), Color("222222"))
			if n >= 3:
				_ufill(ci, PackedVector2Array([sa.lerp(tip, .55), tip, sb.lerp(tip, .55)]), GOLD if n >= 5 else Color("e0b04a"))
			if n >= 5:
				_uglint(ci, tip, .16, t)
		"stripe":
			_clip_on()
			_urect(ci, -.12, -1, .24, 2, Color(1, 1, 1, .85))
			if id == "whiff" and n >= 3:
				# Whiff: two more stripes down its sides.
				for k in [-1, 1]:
					_ufill(ci, PackedVector2Array([Vector2(k * .5, -1), Vector2(k * .62, -1), Vector2(k * .78, 1), Vector2(k * .66, 1)]), Color(1, 1, 1, .7))
		"stripes":
			_clip_on()
			for i in range(-2, 3):
				_urect(ci, -1, i * .42 + .05, 2, .16, Color(.08, .08, .12, .8))
			if id == "beacon" and n >= 3:
				_clip = false
				# Beacon: a railed gallery under the lamp (T3); at T5 gold rails and a life ring.
				var rail := GOLD if n >= 5 else Color("d8f6ff")
				_urect(ci, -.62, -.92, 1.24, .07, rail)
				_urect(ci, -.62, -1.06, 1.24, .05, rail)
				for i in 5:
					_urect(ci, -.6 + i * .29, -1.06, .04, .2, rail)
				if n >= 5:
					_uring(ci, Vector2(.95, .35), .24, Color("e8344a"), .12)
					for i in 4:
						_uarc(ci, Vector2(.95, .35), .24, i * PI / 2, i * PI / 2 + .45, Color.WHITE, .12)
		"sugar":
			# Gumdrop: sugar crystals frost its dome.
			for i in 24:
				var q := Vector2((_hash(i) - .5) * 1.7, (_hash(i + 9) - .5) * 1.6 - .05)
				var inside := q.y > .25 and absf(q.x) < .8 and q.y < .72 or q.y <= .25 and (q.x / .9) ** 2 + ((q.y - .25) / 1.08) ** 2 < 1.0
				if inside:
					_xf = Transform2D(_hash(i + 30) * 1.5, q)
					_urect(ci, -.035, -.035, .07, .07, Color(1, 1, 1, .7))
			_xf = Transform2D.IDENTITY
			if n >= 3:
				# Gumdrop: sugar crystals sparkle (more, with a glossy shine, at T5).
				for i in 3 if n < 5 else 6:
					_uglint(ci, Vector2((_hash(i + 50) - .5) * 1.4, (_hash(i + 60) - .5) * 1.4), .2 if n < 5 else .26, t, i * 1.9)
				if n >= 5:
					_uell(ci, Vector2(-.45, -.45), .12, .28, Color(1, 1, 1, .4), .6)
		"tallcrystals":
			# Glacia: the crown sparkles (T3); at T5 it grows taller with two more crystals.
			var crystals := 7 if n >= 5 else 5
			var mid := crystals / 2
			for i in crystals:
				var x := (i - mid) * .22
				var h := .75 if i == mid else (.5 if (i - mid) % 2 else .38)
				if n >= 5:
					h *= 1.25 if i == mid else 1.1
				_ufill(ci, PackedVector2Array([Vector2(x - .09, -.82 + absf(x) * .15), Vector2(x, -.85 - h + absf(x) * .15), Vector2(x + .09, -.82 + absf(x) * .15)]) if n >= 5 else PackedVector2Array([Vector2(x - .09, -.82), Vector2(x, -.85 - h), Vector2(x + .09, -.82)]), Color("f4ecff") if i == mid else Color("d9ccff"))
				if (n >= 3 and i == mid) or (n >= 5 and absi(i - mid) == 2):
					_uglint(ci, Vector2(x, -.85 - h + (absf(x) * .15 if n >= 5 else 0.0)), .2 if i == mid else .13, t, i)
		"tentacles":
			var kraken := id == "kraken" and n >= 5
			if kraken:
				# Kraken's T5: two big suckered arms curl up its sides.
				for k in [-1, 1]:
					var arm := _quad(Vector2(k * .8, .35), Vector2(k * 1.75, .3 + sin(t * 2.0 + k) * .1), Vector2(k * 1.4, -.65), 10)
					_utaper(ci, arm, .3, .07, shade(c, -.2))
					for j in [3, 5, 7]:
						_ucirc(ci, arm[j], .045, shade(c, .35))
			var nt := 7 if kraken else 5
			for i in nt:
				var x := -.6 + i * .3 if nt == 5 else -.75 + i * .25
				var pts := PackedVector2Array()
				for j in 6:
					pts.append(Vector2(x + sin(t * 3.0 + i + j * .8) * .1, .6 + j * (.17 if kraken else .14)))
				_ustroke(ci, pts, shade(c, -.2), (.16 - .01 * i) * (1.3 if kraken else 1.0))
				if n >= 3:
					# Kraken: suckers on the tentacles (T3+).
					for j in [3, 5]:
						_ucirc(ci, pts[j], .05 * (1.3 if kraken else 1.0), shade(c, .45) if kraken else Color("d9b8ff"))
		"squid":
			# Ink: a squid. Arrowhead fins over the top, two long feeding tentacles and a
			# fringe of short arms that wave; tentacle tips glow from T3, and at T5 the
			# fins glow and puffs of ink trail off behind it.
			if n >= 5:
				for i in 3:
					var k := fmod(t * .5 + i / 3.0, 1.0)
					_ucirc(ci, Vector2(-1.15 - k * .7, .5 - i * .45), .22 + k * .3, Color(.3, .24, .5, .5 * (1.0 - k)))
			var tip := Color("7fe8ff") if n >= 3 else shade(c, .15)
			for k in [-1, 1]:
				var arm := PackedVector2Array()
				for i in 9:
					var u := i / 8.0
					arm.append(Vector2(k * (.4 + u * .7 + .15 * sin(t * 3.0 + u * 4.0 + k) * u), .6 + u * .85 - .35 * u * u))
				_utaper(ci, arm, .3, .1, shade(c, -.3))
				_ucirc(ci, arm[8], .15 if n >= 5 else .12, tip)
			for i in 6:
				var x := -.5 + i * .2
				var arm := PackedVector2Array()
				for j in 5:
					var u := j / 4.0
					arm.append(Vector2(x * (1.0 + u * .35) + .12 * sin(t * 4.0 + i + u * 3.0) * u, .6 + u * .62))
				_utaper(ci, arm, .24, .08, shade(c, -.15))
			_ufill(ci, PackedVector2Array([Vector2(-1.02, -.05), Vector2(0, -1.75), Vector2(1.02, -.05)]), shade(c, -.25))
			_ufill(ci, PackedVector2Array([Vector2(-.7, -.4), Vector2(0, -1.5), Vector2(.7, -.4)]), shade(c, .1))
			if n >= 5:
				_ustroke(ci, PackedVector2Array([Vector2(-1.02, -.05), Vector2(0, -1.75), Vector2(1.02, -.05)]), Color(.5, .91, 1.0, .5 + .3 * sin(t * 4.0)), .05)
		"squidspots":
			# Ink: spots on the mantle, dull at T1, cyan from T3, more and pulsing at T5.
			var spots := [Vector2(-.55, -.55), Vector2(.5, -.6), Vector2(-.7, .25), Vector2(.65, .3), Vector2(0, -.92), Vector2(-.25, .62), Vector2(.3, .64), Vector2(-.82, -.15), Vector2(.84, -.1), Vector2(.12, .8)]
			for i in (10 if n >= 5 else 7):
				var on := .6 + .4 * sin(t * 5.0 + i) if n >= 5 else 1.0
				_ucirc(ci, spots[i], .07, Color(Color("7fe8ff") if n >= 3 else shade(c, .3), on))
			if n >= 3:
				# Ink: chromatophore bands ripple across it (T3); brighter at T5.
				_clip_on()
				for i in 3:
					var y := -.55 + i * .55 + .05 * sin(t * 2.0 + i)
					_urect(ci, -1, y, 2, .1, _hsl(260 + 30 * sin(t * 1.5 + i), .7, .65, .35 if n < 5 else .6))
				_clip = false
		"paws":
			# Mole: big digging paws that paddle as it goes; the claws turn gold at T5.
			var claw := GOLD if n >= 5 else Color("f6eee2")
			for k in [-1, 1]:
				_xf = Transform2D(k * .22 * sin(t * 4.0), Vector2(k * .95, .45))
				var paw := ellipse_pts(Vector2.ZERO, .36, .27, -.35 * k, 0.0, TAU, 20)
				_ufill(ci, paw, Color("f2a6b8"))
				_ustroke(ci, paw, Color("c26f86"), .04)
				for f in 3:
					var d := Vector2(k * cos(-.55 + f * .55), sin(-.55 + f * .55))
					var o := d.orthogonal() * .07
					_ufill(ci, PackedVector2Array([d * .26 + o, d * .56, d * .26 - o]), claw)
			_xf = Transform2D.IDENTITY
		"molesnout":
			# Mole: a pink snout with nostrils and whiskers.
			_uell(ci, Vector2(0, .32), .24, .17, Color("f2a6b8"))
			_uell(ci, Vector2(-.06, .27), .08, .04, Color(1, 1, 1, .45))
			for k in [-1, 1]:
				_ucirc(ci, Vector2(k * .07, .35), .03, Color("8a3550"))
				for j in 2:
					_uline(ci, Vector2(k * .22, .31 + j * .07), Vector2(k * .62, .25 + j * .15), Color(1, 1, 1, .55), .022)
		"bramble":
			# Bramble: thorny canes creep round it and hooked thorns stick out of its
			# edge; blackberries ripen on the canes at T3 and red roses bloom at T5.
			var cane := Color("5a3a24")
			for i in 6:
				var a := i * TAU / 6.0 + .4
				_ufill(ci, PackedVector2Array([_P(a - .13, .93), _P(a + .1, 1.32), _P(a + .14, .93)]), shade(cane, -.2))
			var creep := t * .9
			var wave := func(x: float, j: int) -> float: return -.74 + j * 1.3 + sin(x * 2.6 + j * 2.0 + creep) * .1 # Over the brow and under the chin, clear of the face.
			_clip_on()
			for j in 2:
				var pts := PackedVector2Array()
				for i in 26:
					pts.append(Vector2(-1 + i * .08, wave.call(-1 + i * .08, j)))
				_ustroke(ci, pts, cane, .1)
				for i in 5:
					var x := -.8 + i * .4
					var y: float = wave.call(x, j)
					var up := -1.0 if (i + j) % 2 == 0 else 1.0
					_ufill(ci, PackedVector2Array([Vector2(x - .05, y), Vector2(x + .04, y + up * .15), Vector2(x + .05, y)]), Color("d8c39a"))
			for b in [Vector2(-.45, 0), Vector2(.4, 1)]:
				_uell(ci, Vector2(b.x, wave.call(b.x, int(b.y)) - .1), .12, .07, Color("6fae4a"), .6)
			_clip = false
			if n >= 3:
				var spots := [Vector2(.25, 0), Vector2(-.2, 1)] if n < 5 else [Vector2(.25, 0), Vector2(-.2, 1), Vector2(.5, 1)]
				for b in spots:
					var p := Vector2(b.x, wave.call(b.x, int(b.y)) + (.12 if b.y < 1 else -.14))
					for q in [Vector2(-.05, 0), Vector2(.05, 0), Vector2(0, .08)]:
						_ucirc(ci, p + q, .06, Color("3b1d4f"))
					_ucirc(ci, p + Vector2(-.04, -.02), .02, Color(1, 1, 1, .7))
			if n >= 5:
				for b in [Vector2(-.55, 0), Vector2(.6, 0), Vector2(-.5, 1)]:
					_uflower(ci, Vector2(b.x, wave.call(b.x, int(b.y))), .17, Color("e8344a"), GOLD)
			if n >= 3:
				# Bramble: leaves sprout along the canes (T3), thick with them at T5.
				_clip_on()
				for j in 2:
					for i in (4 if n < 5 else 8):
						var x := -.75 + i * (1.5 / (3 if n < 5 else 7))
						var y: float = wave.call(x, j)
						var up := -1.0 if i % 2 == 0 else 1.0
						_uell(ci, Vector2(x, y + up * .13), .15, .08, Color("3f8a3a"), up * .6)
						_uline(ci, Vector2(x, y + up * .05), Vector2(x, y + up * .2), Color("2a6128"), .02)
				_clip = false
		"dandelion":
			# Pollen: a dandelion clock. Seeds on fine stalks make its fuzzy edge and
			# sway; one by one they float off (two at T3, four at T5, gold at T5), and
			# at T5 little flowers open among them.
			var seed := GOLD_LIGHT if n >= 5 else Color(1, 1, 1, .92)
			for i in 18:
				var a := i / 18.0 * TAU + .05 * sin(t * 2.0 + i)
				_uline(ci, _P(a, .9), _P(a, 1.14), Color(1, 1, 1, .45), .022)
				if n >= 5 and i % 6 == 1:
					_uflower(ci, _P(a, 1.2), .14, Color("fff1a8"), Color("ff8a3d"))
				else:
					_ustar(ci, _P(a, 1.18), .1, .035, 6, seed, a)
			var away := 1 if n < 3 else (2 if n < 5 else 4)
			for i in away:
				var q := fmod(t * .3 + float(i) / away, 1.0)
				var a := -.8 + i * .9
				var p := _P(a, 1.18 + q * 1.1) + Vector2(sin(t * 2.0 + i) * .1, -q * .5)
				var fade := Color(seed, seed.a * (1.0 - q))
				_uline(ci, p, p + _P(a + PI, .3), Color(1, 1, 1, .45 * (1.0 - q)), .022)
				_ustar(ci, p, .1, .035, 6, fade, a)
			if n >= 3:
				# Pollen: dusted with pollen (gold and thicker at T5).
				_clip_on()
				for i in (14 if n < 5 else 26):
					var p := Vector2((_hash(i + 60) - .5) * 1.8, (_hash(i + 90) - .5) * 1.8)
					_ucirc(ci, p, .035 + _hash(i + 5) * .03, Color("ffe066") if n < 5 else GOLD)
				_clip = false
		"stormbelly":
			if n < 3:
				return
			# Stormwing: a storm-cloud belly (T3) with a gold lightning flash at T5.
			_clip_on()
			_uell(ci, Vector2(0, .85), .85, .42, Color("5a6478"))
			for k in [-.45, 0.0, .45]:
				_ucirc(ci, Vector2(k, .52), .22, Color("6c768c"))
			if n >= 5:
				_ufill(ci, PackedVector2Array([Vector2(.05, .45), Vector2(-.12, .75), Vector2(.02, .75), Vector2(-.08, 1.0), Vector2(.2, .66), Vector2(.06, .66), Vector2(.16, .45)]), GOLD)
			_clip = false
		"sparks":
			if n < 3:
				return
			# Static: sparks crackle over its fur (T3), and a lot more of them at T5.
			_clip_on()
			for i in (3 if n < 5 else 6):
				var sd := floorf(t * 8.0) + i * 13.0
				var a := Vector2((_hash(sd) - .5) * 1.6, (_hash(sd + 1) - .5) * 1.6)
				if absf(a.y + .05) < .3:
					a.y = .6 * signf(a.y + .05 + .001)
				var pts := PackedVector2Array([a, a + Vector2(.1, -.12), a + Vector2(.05, .02), a + Vector2(.18, -.06)])
				_ustroke(ci, pts, Color(1, .96, .5, .85) if n < 5 else Color(.8, .95, 1, .95), .03)
			_clip = false
		"gustswirl":
			if n < 3:
				return
			# Gust: little whirls blow across it (T3); frosty and doubled at T5.
			for i in (2 if n < 5 else 4):
				var p := Vector2(-.5 + (i % 2) * 1.0, .55 if i < 2 else -.6)
				_uarc(ci, p, .2, t * 3.0 + i, t * 3.0 + i + 4.0, shade(c, -.3), .06)
				_uarc(ci, p, .09, t * 3.0 + i + 1.0, t * 3.0 + i + 4.5, shade(c, -.3), .05)
				if n >= 5:
					_ustar(ci, p + Vector2(.25, -.15), .08, .03, 6, Color("dff6ff"), t)
		"frostmarks":
			# Frostfang: frost on its brow (T3) and ice-blue cheek marks at T5.
			if n >= 3:
				_clip_on()
				var frost := PackedVector2Array([Vector2(-1, -1.05)])
				for i in 11:
					frost.append(Vector2(-1 + i * .2, -.72 + (.08 if i % 2 else 0.0)))
				frost.append(Vector2(1, -1.05))
				_ufill(ci, frost, Color(.86, .96, 1, .7))
				if n >= 5:
					for k in [-1, 1]:
						for j in 2:
							_ufill(ci, PackedVector2Array([Vector2(k * (.98 - j * .02), .0 + j * .2), Vector2(k * (.55 - j * .05), .08 + j * .2), Vector2(k * (.98 - j * .02), .14 + j * .2)]), Color("6fd3ff"))
				_clip = false
		"moss":
			if n < 3:
				return
			# Mossy: moss creeps over it (T3), thick and starred with tiny flowers at T5.
			_clip_on()
			var patches := [Vector2(-.55, .45), Vector2(.6, .5), Vector2(.0, .85)] if n < 5 else [Vector2(-.55, .45), Vector2(.6, .5), Vector2(.0, .85), Vector2(-.75, -.2), Vector2(.75, -.15)]
			for p in patches:
				_uell(ci, p, .38, .24, Color("4f8a2e"))
				_uell(ci, p + Vector2(-.05, -.06), .26, .14, Color("6fae4a"))
			_clip = false
			if n >= 5:
				for p in patches:
					_uflower(ci, p + Vector2(.1, -.05), .08, Color.WHITE, GOLD)
		"tiles":
			_clip_on()
			for yi in 10:
				for xi in 10:
					var x := -1.0 + xi * .22
					var y := -1.0 + yi * .22
					_urect(ci, x + .01, y + .01, .2, .2, Color(1, 1, 1, .08 + _hash(x * 9.0 + y * 31.0) * .35) if n < 5 else Color.from_hsv(fmod(_hash(x * 9.0 + y * 31.0) + t * .1, 1.0), .55, 1.0, .3 + _hash(x * 5.0 + y) * .3)) # Disco's T5: rainbow tiles.
			_clip = false
			if n >= 3:
				# Disco: a glint sweeps the mirror tiles (T3); at T5 coloured light spots turn round it.
				_uglint(ci, Vector2(sin(t * 1.3) * .6, .5), .32, t)
				_uglint(ci, Vector2(-.5, -.55), .2, t, 2.5)
			if n >= 5:
				for i in 4:
					var a := t * .9 + i * TAU / 4
					_ucirc(ci, _P(a, 1.45), .13, _hsl(i * 90 + t * 60.0, .9, .7, .6))
		"tophat":
			_uell(ci, Vector2(0, -.88), .5, .1, Color("1c1622"))
			_urect(ci, -.3, -1.4, .6, .55, Color("1c1622"), .04)
			_urect(ci, -.3, -1, .6, .08, GOLD if n >= 5 else Color("c4364f")) # Puppeteer's T5: a gold hatband.
			if n >= 3:
				# Puppeteer: a playing card tucked in the hatband (T3); at T5 a gold buckle too.
				_xf = Transform2D(.25, Vector2(.22, -1.12))
				_urect(ci, -.1, -.14, .2, .28, Color.WHITE, .03)
				_ucirc(ci, Vector2(0, 0), .05, Color("e8344a"))
				_xf = Transform2D.IDENTITY
				if n >= 5:
					_urect(ci, -.1, -1.02, .14, .12, Color("8a6a2a"), .02)
		"totemstack":
			# A little more compact than the spec (step .55, height .5) so the T3+
			# stack stays inside a collection cell.
			var faces := mini(3, n)
			if s.get("live_stacks", -1) >= 0: # In a fight: one carved face per stack.
				faces = mini(4, int(s.live_stacks))
			for i in faces:
				var y := -1.12 - i * .46
				var live_totem: bool = s.get("live_stacks", -1) >= 0
				var gold_face := i == 3 or (n >= 5 and not live_totem and i == faces - 1)
				_urect(ci, -.42, y - .22, .84, .44, Color("ffd23f") if gold_face else shade(c, -.15 * (i + 1)), .1)
				if s.get("live_stacks", -1) >= 0 and i < 3: # Each face's buff: harder hits, tougher body, faster roll.
					_urect(ci, -.42, y + .14, .84, .08, [Color("ff5a5a"), Color("5ab0ff"), Color("ffe066")][i], .04)
				_ucirc(ci, Vector2(-.17, y - .03), .07, INK)
				_ucirc(ci, Vector2(.17, y - .03), .07, INK)
				if gold_face and n >= 5 and not live_totem:
					# Totem's T5: the golden top face shouts, with shout rings off both sides.
					_uell(ci, Vector2(0, y + .12), .08, .07, INK)
					for side in [0.0, PI]:
						for j in 2:
							var q := fmod(t * 1.2 + j * .5, 1.0)
							_uarc(ci, Vector2(0, y), .5 + q * .35, side - .55, side + .55, Color(1, .85, .3, .85 * (1.0 - q)), .05)
				else:
					_uline(ci, Vector2(-.15, y + .13), Vector2(.15, y + .13), INK, .04)
		"trunk": # Tapers down between the tusks and curls at the tip.
			var sw := sin(t * 1.8) * .14 # Idle: the trunk swings.
			var trunk := _quad(Vector2(0, .12), Vector2(.1 + sw * .5, .85), Vector2(-.16 + sw, 1.1), 10)
			_utaper(ci, trunk, .34, .16, shade(c, -.35))
			_utaper(ci, trunk, .27, .1, shade(c, -.08))
			_uring(ci, Vector2(-.22 + sw, 1.04), .07, shade(c, -.08), .07)
			if n >= 5:
				# Mammoth's T5: a cap of snow on its head, icicles dripping off it.
				_udome(ci, Vector2(0, -.72), .78, .42, Color("f2fbff"))
				_uell(ci, Vector2(-.25, -.95), .2, .07, Color(1, 1, 1, .8), -.3)
				for x in [-.55, -.15, .3, .62]:
					_ufill(ci, PackedVector2Array([Vector2(x - .06, -.74), Vector2(x, -.52), Vector2(x + .06, -.74)]), Color("cdeeff"))
		"tuft":
			if n >= 3:
				# Pip: a third leaf (T3), and a golden pea bud on top at T5.
				_uell(ci, Vector2(0, -1.2), .08, .2, Color("3fb85a"))
			for k in [-1, 1]:
				_uell(ci, Vector2(k * .15, -1.08), .2, .08, Color("2f9e44"), k * -.9)
			if n >= 5:
				_ucirc(ci, Vector2(0, -1.42), .11, GOLD)
				_uglint(ci, Vector2(.05, -1.47), .14, t)
		"tusks": # Thick at the cheek, sweeping out and down, then curling in to a point.
			for k in [-1, 1]:
				var tusk := _quad(Vector2(k * .3, .28), Vector2(k * 1.05, .78), Vector2(k * .42, 1.02), 10)
				_utaper(ci, tusk, .23, .07, Color("a8916a"))
				_utaper(ci, tusk, .16, .02, Color("f5eedb"))
				if n >= 3:
					# Mammoth: gold tusk bands (T3) and icy tusk tips (T5).
					var across := (tusk[4] - tusk[2]).normalized().orthogonal() * .12
					_uline(ci, tusk[3] - across, tusk[3] + across, GOLD, .06)
				if n >= 5:
					_utaper(ci, tusk.slice(7), .09, .02, Color("bfeaff"))
		"twigs":
			_clip_on()
			_xf = Transform2D(t * .5, Vector2.ZERO) # Idle: it rolls like a tumbleweed.
			for i in 9:
				var p := _P(_hash(i) * 3.14 + 1.5, 1.2)
				var dy := _hash(i + 5) - .5
				_uline(ci, Vector2(-p.x, -p.y + dy), Vector2(p.x, p.y + dy), shade(c, -.35), .05)
			_xf = Transform2D.IDENTITY
			_clip = false
			if n >= 3:
				# Tumble: new twigs sprout out of it (in leaf at T5).
				var sprouts := 6 if n >= 5 else 3
				for i in sprouts:
					var a := i * TAU / sprouts + .4
					_uline(ci, _P(a, .85), _P(a + .15, 1.35), shade(c, -.35), .05)
					if n >= 5:
						_uell(ci, _P(a + .15, 1.38), .1, .05, Color("6fbf4a"), a)
			if n >= 3:
				# Tumble: leaves caught in its twigs (T3); at T5 wildflowers too.
				_clip_on()
				for i in (5 if n < 5 else 8):
					var p := Vector2((_hash(i + 11) - .5) * 1.5, (_hash(i + 17) - .5) * 1.5)
					if absf(p.y + .05) < .3:
						p.y += .5 * signf(p.y + .05 + .001)
					_uell(ci, p, .14, .07, Color("8bbf4a") if i % 2 else Color("c99a3a"), _hash(i) * 3.0)
					if n >= 5 and i % 2 == 0:
						_uflower(ci, p + Vector2(.12, .05), .1, Color("ffd6e8"), GOLD)
				_clip = false
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
			_clip = false
			if n >= 3:
				# Ivy: flowers bloom along the vines (two at T3, five at T5).
				var blooms := [Vector2(-.45, 0), Vector2(.45, 1)] if n < 5 else [Vector2(-.75, 0), Vector2(.75, 0), Vector2(-.6, 1), Vector2(0, 1), Vector2(.6, 1)]
				for b in blooms:
					var y: float = -.1 + b.y * .6 + sin(b.x * 3.0 + b.y) * .2
					_uflower(ci, Vector2(b.x, y), .14, Color("ff8fc8") if b.y > 0 else Color("fff1a8"), Color("ff8a3d"))
			if n >= 3:
				# Ivy: leaves grow out past its edge (three at T3, seven at T5).
				var k_ := 3 if n < 5 else 7
				for i in k_:
					var a := -PI * .9 + i * TAU / 7.0 + .05 * sin(t * 2.0 + i)
					var p := _P(a, 1.12)
					_uell(ci, p, .22, .13, Color("2f8f4a"), a)
					_uline(ci, _P(a, .98), _P(a, 1.28), Color("1f6b3a"), .025)
		"vvisor":
			# Megabot: a scan line sweeps the visor (T3); in T5 overdrive it glows red.
			var visor := Color(1, .22, .2, .8 + .15 * sin(t * 6.0)) if n >= 5 else Color(.35, .9, 1, .75 + .2 * sin(t * 4.0))
			_ufill(ci, PackedVector2Array([Vector2(-.75, -.35), Vector2(0, -.05), Vector2(.75, -.35), Vector2(.7, -.15), Vector2(0, .12), Vector2(-.7, -.15)]), visor)
			if n >= 3:
				var sx := sin(t * 2.0) * .6
				_uline(ci, Vector2(sx, -.05 - .4 * absf(sx)), Vector2(sx, .12 - .386 * absf(sx)), Color(1, 1, 1, .7), .04)
		"wings":
			var f := sin(t * 14.0) * .1
			if id == "zing" and n >= 5:
				# Zing's T5: a second pair of wings in a blur.
				for k in [-1, 1]:
					_uell(ci, Vector2(k * 1.15, .25 - f), .42, .2, Color(.86, .94, 1, .55), k * -.45)
			for k in [-1, 1]:
				_uell(ci, Vector2(k * 1.05, -.3 + f), .45, .22, Color(.86, .94, 1, .75), k * .5)
				if n < 3:
					continue
				var wtip := Vector2(k * 1.45, -.52 + f)
				match id:
					"drako": # Drako: wing spines (T3), gold claws at T5.
						_uline(ci, Vector2(k * .7, -.15 + f), wtip, shade(c, -.3), .04)
						_uline(ci, Vector2(k * .7, -.15 + f), Vector2(k * 1.45, -.1 + f), shade(c, -.3), .04)
						if n >= 5:
							_ufill(ci, PackedVector2Array([wtip + Vector2(-k * .06, .02), wtip + Vector2(k * .12, -.12), wtip + Vector2(k * .06, .06)]), GOLD)
					"stormwing": # Stormwing: a spark on each wing tip (T3); arcs crackle along the wings at T5.
						_uglint(ci, wtip, .17, t, k, Color("fff27a"))
						if n >= 5:
							var zap := PackedVector2Array()
							for j in 5:
								zap.append(Vector2(k * .75, -.2 + f).lerp(wtip, j / 4.0) + Vector2(0, (_hash(floorf(t * 14.0) + j + k * 3) - .5) * .18))
							_ustroke(ci, zap, Color(1, .95, .55, .85), .03)
		"lens": # Optic's lens ring round its eye: nothing below T3, gold with sight ticks at T5.
			if n >= 3:
				var look: Vector2 = s.get("look", Vector2.RIGHT)
				var eye := look * .2 + Vector2(0, -.08)
				_uring(ci, eye, .52, GOLD if n >= 5 else Color(.5, .9, 1.0, .7), .06)
				if n >= 5:
					for i in 4:
						var a := i * PI / 2 + t * .5
						_uline(ci, eye + _P(a, .52), eye + _P(a, .68), GOLD, .06)
		"whiskers":
			for k in [-1, 1]:
				for i in range(-1, 2):
					_uline(ci, Vector2(k * .3, .35), Vector2(k * .85, .3 + i * .12), Color(.16, .12, .12, .6), .025)
		"windcurls":
			for i in 3:
				_uarc(ci, _P(t + i * 2.1, 1.35), .2, 0.0, 4.5, Color(.86, 1, .96, .6), .05)
			if n >= 3:
				# Gust: a snowflake caught in the wind (an icy twister full of them at T5).
				_ustar(ci, _P(t + 1.05, 1.35), .17, .05, 6, Color("eafaff"), t * 2.0)
			if n >= 5:
				for j in 5:
					var w := .42 - j * .07
					var p := Vector2(-1.55 + sin(t * 5.0 + j) * .06, -.75 + j * .26)
					_ustroke(ci, ellipse_pts(p, w, w * .3, 0.0, t * 6.0 + j, t * 6.0 + j + 4.2, 10), Color(.8, .95, 1.0, .75), .045)
				for i in 2:
					_ustar(ci, Vector2(-1.55 + sin(t * 4.0 + i * 3.0) * .22, -.65 + fmod(t * .5 + i * .5, 1.0) * .95), .08, .03, 6, Color.WHITE, t)

		"witchhat":
			if n >= 5:
				# Brewster's T5: a broomstick slung behind it.
				_uline(ci, Vector2(-1.35, -.95), Vector2(1.15, .75), Color("8a5a2b"), .1)
				_ufill(ci, PackedVector2Array([Vector2(1.05, .6), Vector2(1.6, .85), Vector2(1.45, 1.25), Vector2(1.0, .95)]), Color("e0b04a"))
				for j in 3:
					_uline(ci, Vector2(1.1 + j * .1, .75 + j * .04), Vector2(1.38 + j * .07, 1.15 - j * .06), Color("b8862a"), .03)
			_uell(ci, Vector2(0, -.82), .75, .14, Color("3b2a5a"))
			_ufill(ci, PackedVector2Array([Vector2(-.4, -.85), Vector2(.15, -1.75), Vector2(.4, -.85)]), Color("3b2a5a"))
			_urect(ci, -.38, -1.02, .76, .1, Color("7dff6a"))
			if n >= 3:
				# Brewster: a gold buckle on the hat (T3); at T5 gold stars and a potion-green glow on the tip.
				_urect(ci, -.14, -1.14, .28, .22, GOLD, .03)
				_urect(ci, -.07, -1.08, .14, .1, Color("3b2a5a"))
			if n >= 5:
				_ustar(ci, Vector2(.0, -1.33), .12, .05, 5, GOLD)
				_ustar(ci, Vector2(.14, -1.55), .08, .035, 5, GOLD_LIGHT)
				_ucirc(ci, Vector2(.15, -1.75), .16, Color(.5, 1, .45, .3 + .15 * sin(t * 4.0)))
				_ucirc(ci, Vector2(.15, -1.75), .06, Color("b8ff9e"))
		"wrapper":
			for k in [-1, 1]:
				_ufill(ci, PackedVector2Array([Vector2(k * .85, 0), Vector2(k * 1.55, -.45), Vector2(k * 1.4, 0), Vector2(k * 1.55, .45)]), GOLD if n >= 5 else shade(c, .25))
				if n >= 3:
					# Bonbon: twist pleats on the wrapper (T3); gold wrapper ends at T5.
					for y in [-.25, .25]:
						_uline(ci, Vector2(k * .95, 0), Vector2(k * 1.48, y), shade(GOLD if n >= 5 else c, -.15), .03)
				if n >= 5:
					_uglint(ci, Vector2(k * 1.4, -.3), .14, t, k)
		"yoyo":
			if n >= 3:
				# Yo-Yo: spokes spin inside its rim (T3); at T5 the rim is gold.
				for i in 6:
					var a := i * TAU / 6.0 + t * 4.0
					_uline(ci, _P(a, .15), _P(a, .62), Color(1, .97, .69, .35 if n < 5 else .6), .05)
			_uring(ci, Vector2.ZERO, .68, shade(c, -.35) if n < 5 else GOLD, .06 if n < 5 else .09)
			_ucirc(ci, Vector2.ZERO, .12, Color("fff8b0"))
			if n >= 3:
				# Yo-Yo: a glowing string (T3); at T5 a second string in a cat's cradle.
				_uline(ci, Vector2(0, -.68), Vector2(.2, -1.4), Color(1, .97, .69, .3), .09)
				_uglint(ci, _P(t * 3.0, .68), .12, t)
			_uline(ci, Vector2(0, -.68), Vector2(.2, -1.4), Color(1, .97, .69, .7), .03)
			if n >= 5:
				_ustroke(ci, PackedVector2Array([Vector2(-.6, -1.45), Vector2(.75, -.95), Vector2(.6, -1.45), Vector2(-.75, -.95), Vector2(-.6, -1.45)]), Color(1, .97, .69, .85), .03)
				for k in [-1, 1]:
					_ucirc(ci, Vector2(k * .6, -1.45), .06, Color("fff8b0"))
		"zighair":
			# Static: the hair stands up further (T3) and further still, crackling, at T5.
			var spike_y := -1.35 if n < 3 else (-1.5 if n < 5 else -1.68)
			var pts := PackedVector2Array([Vector2(-.7, -.6)])
			for i in 8:
				pts.append(Vector2(-.7 + (i + .5) * .175, -.8 if i % 2 else spike_y))
			pts.append(Vector2(.7, -.6))
			_ufill(ci, pts, shade(c, -.2) if n < 5 else GOLD)
			if n >= 3:
				for i in range(0, 8, 2):
					_ucirc(ci, Vector2(-.7 + (i + .5) * .175, spike_y), .05, Color("fff27a"))
			if n >= 5:
				for i in range(0, 6, 2):
					var a := Vector2(-.7 + (i + .5) * .175, spike_y)
					var b := Vector2(-.7 + (i + 2.5) * .175, spike_y)
					var mid := (a + b) / 2.0 + Vector2(0, (_hash(floorf(t * 14.0) + i) - .5) * .2 - .1)
					_ustroke(ci, PackedVector2Array([a, mid, b]), Color(1, 1, .6, .85), .025)
		"zigmark":
			var mark := PackedVector2Array([Vector2(-.85, -.45), Vector2(-.3, -.25), Vector2(-.45, .05), Vector2(.2, .2)])
			_ustroke(ci, mark, Color(.12, .12, .12, .55), .08)
			if n >= 3:
				# Zigzag: its mark glows electric (and forks at T5).
				_ustroke(ci, mark, Color(1, .97, .45, .75 + .2 * sin(t * 8.0)), .045)
			if n >= 5:
				var fork := PackedVector2Array([Vector2(-.45, .05), Vector2(-.62, .35), Vector2(-.42, .5), Vector2(-.7, .72)])
				_ustroke(ci, fork, Color(.12, .12, .12, .55), .07)
				_ustroke(ci, fork, Color(1, .95, .4, .7), .03)


## Flux's two-pole body: red and blue halves split down the middle. `swap`
## runs 0 -> 1 as the poles spin half a turn when the field flips.
## Echo: a faceted mirror. Glass facets catch a sweep of light (faint at T1,
## blazing at T5), shards poke out of the rim (two at T1, three at T3, five at
## T5), and the rim goes rainbow at T3 and gold at T5.
static func mirror_body(ci: CanvasItem, c: Vector2, r: float, t: float, tier: int) -> void:
	var shards := [-2.3, -.5, 1.9, .75, -1.35]
	for i in (2 if tier < 3 else (3 if tier < 5 else 5)):
		var a: float = shards[i]
		_poly(ci, PackedVector2Array([c + _P(a - .22, r * .92), c + _P(a, r * (1.3 + .04 * i)), c + _P(a + .22, r * .92)]), Color("e8f2ff"))
	var ring := []
	for i in 9:
		ring.append(i * TAU / 9.0 + .2)
	var mids := [c + Vector2(-.35, -.3) * r, c + Vector2(.4, -.25) * r, c + Vector2(.05, .45) * r]
	var facets := []
	for i in 9:
		var pts := PackedVector2Array([mids[floori(i / 3.0)]])
		pts.append_array(ellipse_pts(c, r, r, 0.0, ring[i], ring[(i + 1) % 9] + (TAU if i == 8 else 0.0), 4))
		facets.append(pts)
	for k in 3:
		facets.append(PackedVector2Array([c + _P(ring[(k * 3 + 3) % 9], r), mids[k], mids[(k + 1) % 3]]))
	facets.append(PackedVector2Array(mids))
	var tints := [Color("cfdcf5"), Color("aebfe2"), Color("bfe9f5"), Color("c4bdf0"), Color("dbe5f8"), Color("9fb0d6")]
	var sweep := fmod(t * .6, 1.6) - .3
	var glow := .35 if tier < 3 else (.6 if tier < 5 else 1.0)
	for i in facets.size():
		var pts: PackedVector2Array = facets[i]
		var cen := Vector2.ZERO
		for q in pts:
			cen += q
		cen = (cen / pts.size() - c) / r
		var flash := clampf(1.0 - absf((cen.x + cen.y) * .5 + .5 - sweep) * 4.0, 0.0, 1.0) * glow
		_poly(ci, pts, tints[i % tints.size()].lerp(Color.WHITE, flash))
	for pts in facets:
		var edge: PackedVector2Array = pts.duplicate()
		edge.append(pts[0])
		_pline(ci, edge, Color(1, 1, 1, .4), maxf(1.0, r * .025))
	_gloss(ci, c, r, Color("cfd8e6"), false)
	if tier >= 5:
		_ring(ci, c, r * 1.1, Color(1, 1, 1, .25 + .15 * sin(t * 3.0)), r * .1)
		_ring(ci, c, r, GOLD, maxf(1.5, r * .09))
		_glint(ci, c + Vector2(-.42, -.48) * r, r * .45, t)
		_glint(ci, c + Vector2(.55, .42) * r, r * .22, t, 2.0)
	elif tier >= 3:
		_ring(ci, c, r, Color.from_hsv(fmod(t * .25, 1.0), .45, 1.0), maxf(1.5, r * .08))
	else:
		_ring(ci, c, r, Color("2a3560"), maxf(1.5, r * .07))


## Echo wearing a copy: a silver mirror rim with a glint running round it, over
## the copied critter drawn in grey (state "grey").
static func mirror_rim(ci: CanvasItem, c: Vector2, r: float, t: float) -> void:
	_ring(ci, c, r * 1.04, Color("e8f2ff"), maxf(1.5, r * .09))
	_glint(ci, c + _P(t * 2.0, r * 1.04), r * .3, t)


## How far Munch's jaw hangs open (unit space): it chomps on a loop.
static func _munch_drop(t: float) -> float:
	var open := .5 + .5 * sin(t * 5.0)
	return .05 + .32 * open * open


## Munch: a head and a jaw that chomps open and shut, teeth on both. From T3
## crumbs fly round it (five at T5), and at T5 one top tooth is gold.
static func _chomper(ci: CanvasItem, col: Color, c: Vector2, r: float, t: float, tier: int) -> void:
	var drop := _munch_drop(t) * r
	var lip := .25 * r
	var a0 := asin(.25)
	_ell(ci, c + Vector2(0, lip + drop * .5), r * .78, r * .14 + drop * .55, Color("4a0f14"))
	_ell(ci, c + Vector2(0, lip + drop * .8), r * .4, r * .08 + drop * .25, Color("e2506a"))
	var jaw := ellipse_pts(c + Vector2(0, drop), r, r, 0.0, a0, PI - a0, 20)
	_shaped(ci, jaw, c + Vector2(0, drop), r, shade(col, -.06))
	for i in 5:
		var x := (-.5 + i * .25) * r
		_poly(ci, PackedVector2Array([c + Vector2(x - .1 * r, lip + drop), c + Vector2(x, lip + drop - .13 * r), c + Vector2(x + .1 * r, lip + drop)]), Color.WHITE)
	var head := ellipse_pts(c, r, r, 0.0, PI - a0, TAU + a0, 32)
	_shaped(ci, head, c, r, col)
	for i in 6:
		var x := (-.62 + i * .25) * r
		_poly(ci, PackedVector2Array([c + Vector2(x - .11 * r, lip), c + Vector2(x + .11 * r, lip), c + Vector2(x, lip + .16 * r)]), GOLD if tier >= 5 and i == 3 else Color.WHITE)
	_hit_shape = head.duplicate()
	_hit_shape.append_array(jaw)
	if tier >= 3:
		for i in (5 if tier >= 5 else 2):
			var a := t * 2.0 + i * 1.3
			var p := c + Vector2(cos(a) * 1.3, sin(a) * .45 + .15) * r
			_poly(ci, PackedVector2Array([p + Vector2(-.1, -.07) * r, p + Vector2(.1, -.08) * r, p + Vector2(.09, .07) * r, p + Vector2(-.08, .08) * r]), Color("c98a4b"))


## Gumdrop's outline: a dome on a flat, rounded base.
static func _gum_pts(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 21:
		var a := lerpf(PI, TAU, i / 20.0)
		pts.append(c + Vector2(cos(a) * .98, .25 + sin(a) * 1.18) * r)
	for p in [Vector2(1.0, .55), Vector2(.92, .78), Vector2(.75, .86), Vector2(-.75, .86), Vector2(-.92, .78), Vector2(-1.0, .55)]:
		pts.append(c + p * r)
	return pts


static func magnet_body(ci: CanvasItem, c: Vector2, r: float, red: Color, blue: Color, swap: float, tier := 1) -> void:
	var rot := PI * swap
	var halves := [[red, rot + PI / 2], [blue, rot - PI / 2]]
	for h in halves:
		var pts := ellipse_pts(c, r, r, 0.0, h[1], h[1] + PI, 24)
		_poly(ci, pts, shade(h[0], -.12))
	if not _sil:
		Dot.quad(ci, "shade", Rect2(c.x - r, c.y - r, r * 2.0, r * 2.0), Color(1, 1, 1, .5))
		_gloss(ci, c, r, red.lerp(blue, .5))
	var axis := Vector2(cos(rot + PI / 2), sin(rot + PI / 2)) * r * .97
	if tier >= 3 and not _sil:
		# Flux: a polished steel band round the middle (T3), gold at T5, with rivets.
		var band := Color("c9d2df") if tier < 5 else GOLD
		var n_ := axis.normalized().orthogonal()
		_line(ci, c - axis, c + axis, band, r * .3)
		for i in 5:
			var p := c - axis * .75 + axis * .375 * i
			if absf(i - 2) > 0:
				Dot.circle(ci, p + n_ * r * .09, r * .035, shade(band, -.35))
				Dot.circle(ci, p - n_ * r * .09, r * .035, shade(band, -.35))
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
	if tier >= 3:
		# Flux: field lines loop between the prongs (one at T3, three crackling ones at T5).
		var mid := (tips[0] + tips[1]) / 2.0
		var half := (tips[1].x - tips[0].x) / 2.0
		for k in 3 if tier >= 5 else 1:
			var loop := ellipse_pts(mid, half, r * (.3 + .22 * k), 0.0, PI, TAU, 14)
			if tier >= 5:
				for j in range(1, loop.size() - 1):
					loop[j] += Vector2(0, (_hash(floorf(t * 12.0) + j + k * 5) - .5) * r * .07)
			var line_col := (red if k % 2 == 0 else blue).lightened(.35)
			Dot.pline(ci, loop, Color(line_col, .5 + .2 * sin(t * 4.0 + k)), maxf(1.0, r * .04), true)


static func _orbit_ring(ci: CanvasItem, c: Vector2, r: float, tier: int, t: float, back: bool) -> void:
	var rot := -.35
	var a0 := PI if back else 0.0
	if tier >= 5:
		# Orbit's T5: the ring flares into a bright halo.
		var flare := .6 + .4 * sin(t * 3.0)
		_pline(ci, ellipse_pts(c, r * 1.55, r * .38, rot, a0, a0 + PI, 20), Color(1, .9, .7, .22 * flare), r * .38)
		_pline(ci, ellipse_pts(c, r * 1.85, r * .5, rot, a0, a0 + PI, 20), Color(.95, .9, 1.0, .35 * flare), maxf(1.0, r * .05))
	_pline(ci, ellipse_pts(c, r * 1.55, r * .38, rot, a0, a0 + PI, 20), Color(.66, .61, 1.0, .55 + .08 * tier), maxf(2.0, r * .11))
	if tier >= 3:
		_pline(ci, ellipse_pts(c, r * 1.32, r * .31, rot, a0, a0 + PI, 20), Color(.9, .86, 1.0, .5), maxf(1.0, r * .04))
	if tier >= 5 and not back:
		var ga := fmod(t * .8, PI)
		_glint(ci, c + Vector2(cos(ga) * r * 1.55, sin(ga) * r * .38).rotated(rot), r * .3, t)
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
			Dot.rect(ci, Rect2(ec - Vector2(.12, .12 * sq) * r, Vector2(.24, .24 * sq) * r), Color.WHITE)
			Dot.rect(ci, Rect2(ec + (Vector2(-.05, -.05 * sq) + look * .05) * r, Vector2(.1, .1 * sq) * r), INK)
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
			Dot.line(ci, cap[0], cap[cap.size() - 1], shade(col, -.45), maxf(1.0, r * .05), true)
		if e.has("brow"):
			var a: float = e.brow * r
			var top := ec.y - h - r * .08
			Dot.line(ci, Vector2(ec.x + k * w * 1.1, top - a * .5), Vector2(ec.x - k * w * .9, top + a * .5), INK, maxf(1.6, r * .08), true)
	if e.get("uni", false):
		Dot.pline(ci, _quad(eye + Vector2(-.42, -.2) * r, eye + Vector2(0, -.08) * r, eye + Vector2(.42, -.2) * r, 10), INK, maxf(2.5, r * .13), true)
	_mouth(ci, e.get("mouth", "smile"), r, eye + Vector2(0, r * .34), float(s.hp_frac), Color(e.get("mouth_ink", INK.to_html())), c)


## `c` is the body centre, for mouths drawn on the body rather than under the eyes.
static func _mouth(ci: CanvasItem, kind: String, r: float, m: Vector2, hp_frac: float, ink: Color, c: Vector2) -> void:
	var lw := maxf(1.4, r * .065)
	if kind == "none":
		return
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
			Dot.line(ci, m + Vector2(-r * .12, r * .02), m + Vector2(r * .12, r * .02), ink, lw, true)
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
			Dot.rect(ci, Rect2(m + Vector2(-.17, -.03) * r, Vector2(.34, .06) * r), Color.WHITE)
		"pout":
			Dot.poly(ci, ellipse_pts(m + Vector2(0, r * .02), r * .08, r * .05, 0.0, 0.0, TAU - .01, 12), Color("d9567a"))
		"beak":
			Dot.poly(ci, PackedVector2Array([m + Vector2(-.08, -.02) * r, m + Vector2(.08, -.02) * r, m + Vector2(0, .12) * r]), Color("f2b134"))
		"bigmouth":
			Dot.poly(ci, ellipse_pts(c + Vector2(0, .35) * r, r * .6, r * .42, 0.0, 0.0, PI, 16), Color("3a0f1a"))
			for i in range(-2, 3):
				Dot.rect(ci, Rect2(c + Vector2(i * .2 - .07, .33) * r, Vector2(.14, .12) * r), Color.WHITE)


static func _hash(i: float) -> float:
	var x := sin(i * 127.1) * 43758.5453
	return x - floorf(x)
