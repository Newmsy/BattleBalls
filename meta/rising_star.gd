## Rising Star: catch-up XP for new players (ideas.md Y2).
##
## For the first 30 days, an account below the median player's level earns
## double account XP and +50% critter XP, so a late joiner closes the gap to
## the players they meet in Ghost Arena instead of falling further behind.
## It stops at the median level or after 30 days, whichever comes first. It is
## never bought: it only scales XP the player earned by playing.
##
## The median comes from the server (rising_star_median, cached in the
## profile with when it was fetched). Offline, or before the first fetch, the
## last cached value is used, else FALLBACK_MEDIAN. Pure logic: `now` is unix
## seconds, passed in.
extends RefCounted

const ACCOUNT_XP_MULT := 2.0
const CRITTER_XP_MULT := 1.5
const WINDOW_DAYS := 30
const DAY := 86400
## The median's stand-in until the server has answered once. About two weeks
## of steady play (account XP is energy spent; see Profile.account_xp_to_next).
const FALLBACK_MEDIAN := 15
## A cached median older than this is still used, but refetched when online.
const STALE_SECONDS := 6 * 3600


## The level Rising Star lifts a player to.
static func target_level(profile) -> int:
	return profile.rising_median if profile.rising_median > 0 else FALLBACK_MEDIAN


## Whole days left in the 30-day window (0 when it has ended or the start is
## unknown, as on the sample profile).
static func days_left(profile, now: int) -> int:
	if profile.started <= 0:
		return 0
	var age := maxi(0, now - profile.started)
	return maxi(0, WINDOW_DAYS - age / DAY)


static func active(profile, now: int) -> bool:
	return days_left(profile, now) > 0 and profile.account_level < target_level(profile)


## Boosted XP, rounded up so a small grant still gains something.
static func account_xp(profile, amount: int, now: int) -> int:
	return ceili(amount * ACCOUNT_XP_MULT) if active(profile, now) else amount


static func critter_xp(profile, amount: int, now: int) -> int:
	return ceili(amount * CRITTER_XP_MULT) if active(profile, now) else amount


static func needs_refresh(profile, now: int) -> bool:
	return days_left(profile, now) > 0 and now - profile.rising_median_at >= STALE_SECONDS


## The banner line, or "" when Rising Star is off.
static func banner_text(profile, now: int) -> String:
	if not active(profile, now):
		return ""
	var d := days_left(profile, now)
	return "Double account XP and +50%% critter XP until you reach level %d. %d day%s left." % [
		target_level(profile), d, "" if d == 1 else "s"]


## Applies the server's answer: {median, players, joined}. `median` is null
## while too few players are active to trust it. `joined` (unix seconds) is
## when the account was made; the earlier of it and the local start wins, so
## starting a fresh local game on an old account doesn't restart the window.
static func apply_server(profile, res, now: int) -> void:
	if not res is Dictionary:
		return
	if res.get("median") != null:
		profile.rising_median = clampi(int(res.median), 1, 999)
	var joined := int(res.get("joined", 0) if res.get("joined") != null else 0)
	if joined > 0 and (profile.started <= 0 or joined < profile.started):
		profile.started = joined
	profile.rising_median_at = now
	profile.changed.emit()
