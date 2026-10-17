## Daily run counts for the later farming bosses (Piñata Titan and on), kept
## in profile.boss_days under each boss's key: {day, runs}. A new UTC day
## starts every count again.
extends RefCounted

const DAY_SECONDS := 86400


static func day_number(now: int) -> int:
	return int(now / DAY_SECONDS)


static func runs_left(profile, key: String, per_day: int, now: int) -> int:
	var d: Dictionary = profile.boss_days.get(key, {})
	if int(d.get("day", -1)) != day_number(now):
		return per_day
	return maxi(0, per_day - int(d.get("runs", 0)))


## Uses `n` runs (or gives them back when negative).
static func use(profile, key: String, per_day: int, now: int, n: int) -> void:
	var day := day_number(now)
	var d: Dictionary = profile.boss_days.get(key, {})
	if int(d.get("day", -1)) != day:
		d = {"day": day, "runs": 0}
	d.runs = clampi(int(d.runs) + n, 0, per_day)
	profile.boss_days[key] = d
	profile.changed.emit()
