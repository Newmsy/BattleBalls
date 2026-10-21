## Daily run counts for the later farming bosses (Piñata Titan and on), kept
## in profile.boss_days under each boss's key: {day, runs}. A new UTC day
## (or week, for a weekly boss: "day" then holds the week number) starts
## every count again.
extends RefCounted

const DAY_SECONDS := 86400


static func day_number(now: int) -> int:
	return int(now / DAY_SECONDS)


## The week number, for weekly bosses (`weekly` below).
static func week_number(now: int) -> int:
	return int(now / (DAY_SECONDS * 7))


static func _period(now: int, weekly: bool) -> int:
	return week_number(now) if weekly else day_number(now)


static func runs_left(profile, key: String, per_day: int, now: int, weekly := false) -> int:
	var d: Dictionary = profile.boss_days.get(key, {})
	if int(d.get("day", -1)) != _period(now, weekly):
		return per_day
	return maxi(0, per_day - int(d.get("runs", 0)))


## Uses `n` runs (or gives them back when negative).
static func use(profile, key: String, per_day: int, now: int, n: int, weekly := false) -> void:
	var day := _period(now, weekly)
	var d: Dictionary = profile.boss_days.get(key, {})
	if int(d.get("day", -1)) != day:
		d = {"day": day, "runs": 0}
	d.runs = clampi(int(d.runs) + n, 0, per_day)
	profile.boss_days[key] = d
	profile.changed.emit()
