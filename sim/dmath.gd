## Cross-platform deterministic math for the sim.
##
## Godot's sin/cos/atan2/pow (and Vector2.from_angle/rotated/angle/angle_to,
## which call them) use each platform's C math library, and those differ in
## the last bit between desktop, the web build and phones. One bit is enough
## for a fight to play out differently. Everything here uses only +, -, *, /
## and sqrt, which IEEE 754 makes identical everywhere, and works in doubles.
## Use these instead of the built-ins anywhere in sim/.
extends RefCounted

const PIO2_HI := 1.57079632673412561417e+00 ## First 33 bits of pi/2.
const PIO2_LO := 6.07710050650619224932e-11 ## pi/2 - PIO2_HI.

# fdlibm kernel coefficients for |x| <= pi/4.
const S1 := -1.66666666666666324348e-01
const S2 := 8.33333333332248946124e-03
const S3 := -1.98412698298579493134e-04
const S4 := 2.75573137070700676789e-06
const S5 := -2.50507602534068634195e-08
const S6 := 1.58969099521155010221e-10
const C1 := 4.16666666666666019037e-02
const C2 := -1.38888888888741095749e-03
const C3 := 2.48015872894767294178e-05
const C4 := -2.75573143513906633035e-07
const C5 := 2.08757232129817482790e-09
const C6 := -1.13596475577881948265e-11

const ATAN_HI := [4.63647609000806093515e-01, 7.85398163397448278999e-01, 9.82793723247329054082e-01, 1.57079632679489655800e+00]
const ATAN_LO := [2.26987774529616870924e-17, 3.06161699786838301793e-17, 1.39033110312309984516e-17, 6.12323399573676603587e-17]
const AT := [3.33333333333329318027e-01, -1.99999999998764832476e-01, 1.42857142725034663711e-01,
	-1.11111104054623557880e-01, 9.09088713343650656196e-02, -7.69187620504482999495e-02,
	6.66107313738753120669e-02, -5.83357013379057348645e-02, 4.97687799461593236017e-02,
	-3.65315727442169155270e-02, 1.62858201153657823623e-02]


static func _ksin(x: float) -> float:
	var z := x * x
	return x + x * z * (S1 + z * (S2 + z * (S3 + z * (S4 + z * (S5 + z * S6)))))


static func _kcos(x: float) -> float:
	var z := x * x
	return 1.0 - 0.5 * z + z * z * (C1 + z * (C2 + z * (C3 + z * (C4 + z * (C5 + z * C6)))))


## sin and cos of x at once: Vector2(cos, sin), in doubles.
static func _sincos(x: float) -> Array:
	var k := roundf(x / PI * 2.0)
	var r := (x - k * PIO2_HI) - k * PIO2_LO
	var s := _ksin(r)
	var c := _kcos(r)
	match posmod(int(k), 4):
		0: return [s, c]
		1: return [c, -s]
		2: return [-s, -c]
		_: return [-c, s]


static func sin(x: float) -> float:
	return _sincos(x)[0]


static func cos(x: float) -> float:
	return _sincos(x)[1]


static func atan(x: float) -> float:
	var neg := x < 0.0
	var t := absf(x)
	var id := -1
	if t < 0.4375:
		pass
	elif t < 1.1875:
		if t < 0.6875:
			id = 0
			t = (2.0 * t - 1.0) / (2.0 + t)
		else:
			id = 1
			t = (t - 1.0) / (t + 1.0)
	elif t < 2.4375:
		id = 2
		t = (t - 1.5) / (1.0 + 1.5 * t)
	else:
		id = 3
		t = -1.0 / t
	var z := t * t
	var w := z * z
	var s1: float = z * (AT[0] + w * (AT[2] + w * (AT[4] + w * (AT[6] + w * (AT[8] + w * AT[10])))))
	var s2: float = w * (AT[1] + w * (AT[3] + w * (AT[5] + w * (AT[7] + w * AT[9]))))
	var out: float
	if id < 0:
		out = t - t * (s1 + s2)
	else:
		out = ATAN_HI[id] - ((t * (s1 + s2) - ATAN_LO[id]) - t)
	return -out if neg else out


static func atan2(y: float, x: float) -> float:
	if x > 0.0:
		return atan(y / x)
	if x < 0.0:
		return atan(y / x) + (PI if y >= 0.0 else -PI)
	if y > 0.0:
		return PI / 2.0
	if y < 0.0:
		return -PI / 2.0
	return 0.0


static func asin(x: float) -> float:
	return atan2(x, sqrt(maxf(0.0, 1.0 - x * x)))


## base ^ n for a whole number n, by repeated multiplication.
static func ipow(base: float, n: int) -> float:
	var out := 1.0
	for i in absi(n):
		out *= base
	return out if n >= 0 else 1.0 / out


static func from_angle(a: float) -> Vector2:
	var sc := _sincos(a)
	return Vector2(sc[1], sc[0])


static func rotated(v: Vector2, a: float) -> Vector2:
	var sc := _sincos(a)
	var x := float(v.x)
	var y := float(v.y)
	return Vector2(x * sc[1] - y * sc[0], x * sc[0] + y * sc[1])


static func angle(v: Vector2) -> float:
	return atan2(v.y, v.x)


## Signed angle from a to b, like Vector2.angle_to.
static func angle_to(a: Vector2, b: Vector2) -> float:
	var ax := float(a.x)
	var ay := float(a.y)
	var bx := float(b.x)
	var by := float(b.y)
	return atan2(ax * by - ay * bx, ax * bx + ay * by)
