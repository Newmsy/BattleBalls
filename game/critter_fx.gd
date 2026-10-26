## Fight art for the critter cool-factor moves (ideas/critter-cool-factor.md):
## the new shots, pieces, zones and one-off effects. Static draw helpers in
## the arena's own coordinates, like BattleFx; render only.
extends RefCounted

const Dot := preload("res://game/dot.gd")

const GEAR := Color("ffb347")
const GEAR_DARK := Color("8a5a1c")
const THORN := Color("6fbf3a")
const THORN_DARK := Color("2f5d17")
const CANDY := [Color("ff5fa2"), Color("ffd23f"), Color("6ee7ff"), Color("a6ff6e")]
const WOLF := Color("bfe9ff")
const WOLF_GLOW := Color("6fb7ff")
const SHARD_HUES := [Color("ff4d6d"), Color("7fe6ff"), Color("ffe066"), Color("ffffff")]
const ROCK := Color("8a7f72")
const ROCK_HI := Color("c9bba8")
const COOKIE := Color("c68642")
const COOKIE_HI := Color("e8b071")
const CHIP := Color("4a2c17")
const FISH := Color("7fe0ff")
const LAVA := Color("ff5a1f")
const LAVA_CORE := Color("ffd23f")
const TIME := Color("b8c4ff")
const SONIC := Color("e8f6ff")
const LEAF := Color("8ac926")
const BARK := Color("6b4423")


## Cogs' gear tooth: a little spinning cog.
static func draw_gear(ci: CanvasItem, p: Vector2, r: float, spin: float) -> void:
	var pts := PackedVector2Array()
	for k in 12:
		var a := spin + k * TAU / 12.0
		pts.append(p + Vector2.from_angle(a) * r * (1.35 if k % 2 == 0 else 0.95))
	Dot.poly(ci, pts, GEAR)
	Dot.circle(ci, p, r * 0.4, GEAR_DARK)


## Bramble's thorn: a curved green barb, point first.
static func draw_thorn(ci: CanvasItem, p: Vector2, r: float, vel: Vector2) -> void:
	var dir := vel.normalized() if vel.length() > 0.001 else Vector2.RIGHT
	var o := dir.orthogonal()
	Dot.line(ci, p, p - dir * r * 2.5, Color(THORN, 0.3), r * 0.8, true)
	Dot.poly(ci, PackedVector2Array([p + dir * r * 2.0 + o * r * 0.3, p + o * r * 0.7 - dir * r * 0.7, p - o * r * 0.7 - dir * r * 0.7]), THORN)
	Dot.line(ci, p - dir * r * 0.6, p + dir * r * 1.6, THORN_DARK, 1.5, true)


## Jawbreaker's candy shot: a striped hard candy rolling.
static func draw_candy(ci: CanvasItem, p: Vector2, r: float, spin: float, hue: int) -> void:
	var col: Color = CANDY[hue % CANDY.size()]
	Dot.circle(ci, p, r * 1.4, Color(col, 0.25))
	Dot.circle(ci, p, r, col)
	Dot.arc(ci, p, r * 0.65, spin, spin + PI * 0.7, 10, Color.WHITE, r * 0.25, true)
	Dot.arc(ci, p, r * 0.65, spin + PI, spin + PI * 1.7, 10, Color.WHITE, r * 0.25, true)


## Frostfang's spirit wolf: a pale running wolf head with a frosty tail.
static func draw_wolf(ci: CanvasItem, p: Vector2, r: float, vel: Vector2, t: float) -> void:
	var dir := vel.normalized() if vel.length() > 0.001 else Vector2.RIGHT
	var o := dir.orthogonal()
	for k in 4: # The trail of frost.
		Dot.circle(ci, p - dir * r * (1.2 + k * 0.9), r * (0.7 - k * 0.14), Color(WOLF_GLOW, 0.3 - k * 0.06))
	Dot.circle(ci, p, r * 1.6, Color(WOLF_GLOW, 0.2 + 0.1 * sin(t * 12.0)))
	Dot.circle(ci, p, r, WOLF)
	Dot.poly(ci, PackedVector2Array([p + dir * r * 1.8, p + o * r * 0.55 + dir * r * 0.3, p - o * r * 0.55 + dir * r * 0.3]), WOLF) # Snout.
	for e in [-1.0, 1.0]: # Ears.
		Dot.poly(ci, PackedVector2Array([p + o * r * 0.9 * e - dir * r * 0.1, p + o * r * 0.4 * e - dir * r * 0.2, p + o * r * 0.8 * e - dir * r * 1.0]), WOLF)
		Dot.circle(ci, p + dir * r * 0.45 + o * r * 0.35 * e, r * 0.16, WOLF_GLOW)


## Kaleido's shard: a spinning sliver in the colour of its mode.
static func draw_shard(ci: CanvasItem, p: Vector2, r: float, vel: Vector2, hue: int) -> void:
	var dir := vel.normalized() if vel.length() > 0.001 else Vector2.RIGHT
	var o := dir.orthogonal()
	var col: Color = SHARD_HUES[hue % SHARD_HUES.size()]
	Dot.line(ci, p, p - dir * r * 3.0, Color(col, 0.35), r * 0.7, true)
	Dot.poly(ci, PackedVector2Array([p + dir * r * 1.8, p + o * r * 0.55, p - dir * r * 1.2, p - o * r * 0.55]), col)
	Dot.circle(ci, p + dir * r * 0.4, r * 0.25, Color.WHITE)


## Painter's paint balloon in flight: a wobbly balloon on a string.
static func draw_balloon(ci: CanvasItem, p: Vector2, r: float, t: float, hue: float) -> void:
	var col := Color.from_hsv(fmod(hue, 1.0), 0.7, 1.0)
	var wob := 1.0 + 0.08 * sin(t * 18.0)
	Dot.line(ci, p + Vector2(0, r * 1.1), p + Vector2(sin(t * 10.0) * r * 0.4, r * 2.2), Color(1, 1, 1, 0.6), 1.5, true)
	Dot.circle(ci, p, r * wob, col)
	Dot.poly(ci, PackedVector2Array([p + Vector2(0, r * 0.9), p + Vector2(-r * 0.25, r * 1.2), p + Vector2(r * 0.25, r * 1.2)]), col.darkened(0.2))
	Dot.circle(ci, p + Vector2(-r * 0.35, -r * 0.4), r * 0.25, Color(1, 1, 1, 0.75))


## Sundae's flung scoop: ice cream with a cherry.
static func draw_scoop(ci: CanvasItem, p: Vector2, r: float, hue: int) -> void:
	var cols := [Color("fff1d6"), Color("ffb3d1"), Color("7a4a2a")]
	var col: Color = cols[hue % cols.size()]
	Dot.circle(ci, p, r, col)
	for k in 5: # Drippy rim.
		Dot.circle(ci, p + Vector2.from_angle(PI * 0.15 + k * PI * 0.175) * r * 0.85, r * 0.3, col)
	Dot.circle(ci, p + Vector2(0, -r * 0.95), r * 0.3, Color("ff2d55"))
	Dot.circle(ci, p + Vector2(-r * 0.3, -r * 0.35), r * 0.22, Color(1, 1, 1, 0.6))


## Magmo's lava blob in flight: a glowing molten drop.
static func draw_lava_blob(ci: CanvasItem, p: Vector2, r: float, t: float) -> void:
	Dot.circle(ci, p, r * 1.7, Color(LAVA, 0.25))
	Dot.circle(ci, p, r, LAVA)
	Dot.circle(ci, p, r * (0.5 + 0.1 * sin(t * 14.0)), LAVA_CORE)


## Boulder's rock: a chunky lumpy boulder with cracks.
static func draw_rock(ci: CanvasItem, p: Vector2, r: float, k: float, seed: float) -> void:
	if r < 1.0:
		return
	Dot.circle(ci, p + Vector2(3, 6) * k, r, Color(0, 0, 0, 0.3 * k))
	var pts := PackedVector2Array()
	for q in 9:
		var a := q * TAU / 9.0 + seed
		pts.append(p + Vector2.from_angle(a) * r * (0.85 + 0.15 * sin(seed * 3.0 + q * 2.1)))
	Dot.poly(ci, pts, Color(ROCK, 0.4 + 0.6 * k))
	Dot.circle(ci, p + Vector2(-0.3, -0.35) * r, r * 0.35, Color(ROCK_HI, 0.5 * k))
	Dot.line(ci, p + Vector2(-0.2, -0.5) * r, p + Vector2(0.1, 0.0) * r, Color(0, 0, 0, 0.35 * k), 2.0, true)
	Dot.line(ci, p + Vector2(0.1, 0.0) * r, p + Vector2(0.45, 0.3) * r, Color(0, 0, 0, 0.35 * k), 2.0, true)


## Crumb's dropped cookie chunk: a broken-off wedge with chips, bobbing a
## little so it reads as a pickup.
static func draw_crumb(ci: CanvasItem, p: Vector2, r: float, k: float, seed: float, t: float) -> void:
	if r < 1.0:
		return
	var bob := Vector2(0, sin(t * 4.0 + seed) * 2.0 * k)
	var pts := PackedVector2Array()
	for q in 7: # A cookie with a bite out of one side.
		var a := seed + q * TAU * 0.8 / 6.0
		pts.append(p + bob + Vector2.from_angle(a) * r * (0.8 + 0.2 * sin(q * 1.7 + seed)))
	pts.append(p + bob)
	Dot.circle(ci, p + bob, r * 1.5, Color(COOKIE_HI, 0.15 * k))
	Dot.poly(ci, pts, Color(COOKIE, 0.4 + 0.6 * k))
	for c in 3:
		Dot.circle(ci, p + bob + Vector2.from_angle(seed + 0.6 + c * 1.4) * r * 0.45, r * 0.16, Color(CHIP, k))


## Minnow's school fish: a tiny fish facing the way it swims round.
static func draw_fish(ci: CanvasItem, p: Vector2, r: float, dir: Vector2, t: float) -> void:
	var d := dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT
	var o := d.orthogonal()
	var wag := sin(t * 18.0) * 0.4
	var tail := p - d * r * 1.0
	Dot.poly(ci, PackedVector2Array([tail, tail - d * r * 0.8 + o * r * (0.6 + wag), tail - d * r * 0.8 - o * r * (0.6 - wag)]), FISH.darkened(0.15))
	Dot.circle(ci, p, r, FISH)
	Dot.circle(ci, p + d * r * 0.4 + o * r * 0.25, r * 0.18, Color("0d1b2a"))


## Disco's dance floor tile: a lit square whose colour steps with the beat.
static func draw_tile(ci: CanvasItem, p: Vector2, half: float, fade: float, beat: int, seed: int) -> void:
	if half < 1.0:
		return
	var col := Color.from_hsv(fmod((beat + seed) * 0.23, 1.0), 0.7, 1.0)
	var on := (beat + seed) % 2 == 0
	var h := half * 0.92
	Dot.rect(ci, Rect2(p - Vector2(h, h), Vector2(h, h) * 2.0), Color(col, (0.32 if on else 0.14) * fade))
	ci.draw_rect(Rect2(p - Vector2(h, h), Vector2(h, h) * 2.0), Color(col, 0.7 * fade), false, 2.0)


## Bramble's thorn patch: a ring of little spikes on the floor.
static func draw_thorn_patch(ci: CanvasItem, p: Vector2, r: float, fade: float, seed: float) -> void:
	Dot.circle(ci, p, r, Color(THORN_DARK, 0.25 * fade))
	for k in 10:
		var a := seed + k * TAU / 10.0
		var at := p + Vector2.from_angle(a) * r * (0.35 + 0.5 * fmod(k * 0.37, 1.0))
		var up := Vector2.from_angle(a + 1.2)
		Dot.poly(ci, PackedVector2Array([at + up * r * 0.16, at - up.orthogonal() * r * 0.06, at + up.orthogonal() * r * 0.06]), Color(THORN, 0.8 * fade))


## Gust's hunting twister: a leaning funnel of wind rings.
static func draw_twister(ci: CanvasItem, p: Vector2, r: float, fade: float, t: float) -> void:
	for k in 5:
		var f := k / 4.0
		var w := r * (0.3 + 0.7 * f)
		var c := p + Vector2(sin(t * 6.0 + f * 3.0) * r * 0.15, -f * r * 1.2)
		Dot.arc(ci, c, w, t * 8.0 + k, t * 8.0 + k + PI * 1.4, 16, Color(Color("e8fff0"), (0.6 - f * 0.25) * fade), 3.0, true)
	Dot.circle(ci, p, r * 0.25, Color(Color("c7f9cc"), 0.35 * fade))


## One-off effects, drawn from _fx entries. `k.age` runs 0 -> k.life.
static func draw_fx(ci: CanvasItem, k: Dictionary, a: Vector2, b: Vector2, r: float, t: float) -> void:
	var f: float = clampf(k.age / k.life, 0.0, 1.0)
	match k.kind:
		"sonic": # Zip's sonic boom: a cone of shock rings behind it.
			for q in 3:
				var g := clampf(f * 1.4 - q * 0.2, 0.0, 1.0)
				if g > 0.0 and g < 1.0:
					Dot.arc(ci, a, r * (1.0 + g * 2.0), 0.0, TAU, 40, Color(SONIC, 0.7 * (1.0 - g)), 4.0, true)
		"grab": # Kraken's tentacle shooting out and dragging the foe.
			var tip := a.lerp(b, minf(1.0, f * 3.0))
			Dot.line(ci, a, tip, Color("c77dff", 0.9 * (1.0 - f * 0.5)), 10.0, true)
			for q in 4:
				Dot.circle(ci, a.lerp(tip, (q + 1) / 5.0), 4.0, Color("ffd6f5", 0.8))
		"lag": # Pixel's lag glitch: chunky ghost frames from where it was to where it snapped back.
			for q in 4:
				var at := b.lerp(a, q / 3.0)
				var h := r * (0.9 - q * 0.12)
				if h > 1.0:
					var col := Color("7cff4f") if q % 2 == 0 else Color("ff4fd8")
					ci.draw_rect(Rect2(at - Vector2(h, h), Vector2(h, h) * 2.0), Color(col, 0.35 * (1.0 - f)), false, 3.0)
		"coil": # Leviathan coils round the foe: a serpent loop tightening.
			var rad := r * (1.6 - 0.5 * f)
			Dot.arc(ci, b, rad, t * 6.0, t * 6.0 + TAU * 0.85, 40, Color("2ec4b6", 0.9 * (1.0 - f * 0.6)), 9.0, true)
			Dot.arc(ci, b, rad, t * 6.0, t * 6.0 + TAU * 0.85, 40, Color("bff8ff", 0.5 * (1.0 - f)), 3.0, true)
			Dot.circle(ci, b + Vector2.from_angle(t * 6.0 + TAU * 0.85) * rad, 8.0, Color("2ec4b6"))
		"timestop": # Clockwork stops time: a big clock dial with frozen hands.
			var rad := r * (0.6 + 0.4 * minf(1.0, f * 4.0))
			Dot.circle(ci, a, rad, Color(TIME, 0.12 * (1.0 - f)))
			Dot.arc(ci, a, rad, 0.0, TAU, 48, Color(TIME, 0.8 * (1.0 - f)), 4.0, true)
			for q in 12:
				var d := Vector2.from_angle(q * TAU / 12.0)
				Dot.line(ci, a + d * rad * 0.85, a + d * rad * 0.97, Color(TIME, 0.7 * (1.0 - f)), 2.0)
			Dot.line(ci, a, a + Vector2.UP * rad * 0.7, Color(TIME, 0.9 * (1.0 - f)), 4.0)
			Dot.line(ci, a, a + Vector2.from_angle(-PI / 6.0) * rad * 0.45, Color(TIME, 0.9 * (1.0 - f)), 5.0)
		"swat": # Old Oak swings a branch all the way round.
			var sweep := f * TAU
			Dot.arc(ci, a, r, sweep - 1.2, sweep, 16, Color(LEAF, 0.6 * (1.0 - f)), 14.0, true)
			Dot.line(ci, a, a + Vector2.from_angle(sweep) * r, Color(BARK, 1.0 - f), 8.0, true)
			for q in 3:
				Dot.circle(ci, a + Vector2.from_angle(sweep - q * 0.15) * r * (0.7 + q * 0.12), 9.0, Color(LEAF, 1.0 - f))
		"howl": # Frostfang howls: a pale moon and sound rings.
			Dot.circle(ci, a + Vector2(0, -r * 2.2), r * 0.6, Color("eef6ff", 0.8 * (1.0 - f)))
			Dot.circle(ci, a + Vector2(r * 0.25, -r * 2.3), r * 0.5, Color("0c1530", 0.8 * (1.0 - f)))
			for q in 3:
				var g := fmod(f * 2.0 + q / 3.0, 1.0)
				Dot.arc(ci, a, r * (1.1 + g * 1.8), -PI * 0.8, -PI * 0.2, 16, Color(WOLF, 0.7 * (1.0 - g) * (1.0 - f)), 3.0, true)
		"erupt": # Magmo erupts: a fountain of lava.
			for q in 7:
				var ang := -PI / 2.0 + (q - 3) * 0.22
				var h := r * 2.4 * sin(PI * f)
				Dot.circle(ci, a + Vector2.from_angle(ang) * h * (0.6 + 0.1 * (q % 3)), 7.0, Color(LAVA if q % 2 else LAVA_CORE, 1.0 - f))
			Dot.circle(ci, a, r * (1.0 + f), Color(LAVA, 0.25 * (1.0 - f)))
		"lamp_spin": # Beacon's full spin: a bright ring of light.
			Dot.arc(ci, a, r * (1.0 + f * 3.0), 0.0, TAU, 48, Color("fff3b0", 0.8 * (1.0 - f)), 5.0, true)
		"snowball": # Yeti's rolling snowball: a growing ball of snow on it.
			Dot.circle(ci, a, r * (1.05 + 0.25 * sin(PI * f)), Color(Color("eef6ff"), 0.35 * (1.0 - f)))
			Dot.arc(ci, a, r * 1.2, t * 4.0, t * 4.0 + PI, 16, Color(Color.WHITE, 0.7 * (1.0 - f)), 4.0, true)
		"banana": # Sundae's banana split: a banana boat under it.
			var w := r * 1.6
			Dot.arc(ci, a + Vector2(0, -r * 0.3), w, PI * 0.15, PI * 0.85, 20, Color("ffe066", 1.0 - f), 10.0, true)
