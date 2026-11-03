## Chest drop tables (Newms 2026-11-03): each item rolls a range or a chance,
## so opening a chest is a surprise while the average stays the same.
## Entries are Profile.grant() dicts with one of:
##   {kind, n}                 always n
##   {kind, lo, hi, step}      lo..hi in steps (step defaults to 1)
##   {kind, n, pct}            n with a pct% chance, else nothing
## Gear entries also carry `tier`; the caller picks each piece's type.
extends RefCounted

const Rng := preload("res://sim/rng.gd")


## Rolls `table` with `seed_value`, leaving out items that came up empty.
static func roll(table: Array, seed_value: int) -> Array:
	var out: Array = []
	for i in table.size():
		var e: Dictionary = table[i]
		var rng := Rng.new(seed_value + i * 7577)
		var n := int(e.get("n", 1))
		if e.has("lo"):
			var step := int(e.get("step", 1))
			n = int(e.lo) + step * rng.range_int(0, (int(e.hi) - int(e.lo)) / step)
		elif e.has("pct"):
			n = n if rng.range_int(0, 99) < int(e.pct) else 0
		if n <= 0:
			continue
		var g := {"kind": e.kind, "n": n}
		if e.has("tier"):
			g.tier = e.tier
		out.append(g)
	return out


## The average amount of one entry, for tests and balance checks.
static func mean(e: Dictionary) -> float:
	if e.has("lo"):
		return (float(e.lo) + float(e.hi)) / 2.0
	return float(e.get("n", 1)) * float(e.get("pct", 100)) / 100.0


## How an entry reads in a drop table: "200-400", "50%" (for one) or
## "2 · 50%", or plain "3".
static func text(e: Dictionary, commas: Callable) -> String:
	if e.has("lo"):
		return "%s-%s" % [commas.call(int(e.lo)), commas.call(int(e.hi))]
	var n := int(e.get("n", 1))
	if e.has("pct"):
		return ("%d%%" % int(e.pct)) if n == 1 else "%s · %d%%" % [commas.call(n), int(e.pct)]
	return commas.call(n)
