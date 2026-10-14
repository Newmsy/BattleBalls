## Deterministic 32-bit PRNG (mulberry32). Same seed -> same sequence on every
## platform, unlike Godot's RandomNumberGenerator whose algorithm may change.
extends RefCounted

const MASK := 0xFFFFFFFF

var state: int


func _init(seed_value: int) -> void:
	state = seed_value & MASK


func next_u32() -> int:
	state = (state + 0x6D2B79F5) & MASK
	var t := state
	t = ((t ^ (t >> 15)) * (t | 1)) & MASK
	t = (t ^ (t + (((t ^ (t >> 7)) * (t | 61)) & MASK))) & MASK
	return (t ^ (t >> 14)) & MASK


## Float in [0, 1).
func next_float() -> float:
	return float(next_u32()) / 4294967296.0


## Integer in [lo, hi] inclusive.
func range_int(lo: int, hi: int) -> int:
	return lo + int(next_u32() % (hi - lo + 1))
