## TEST MODE: every device plays as test user ID (Newms, 2026-10-15: "hardcode
## my user id as 1 so I can test on multiple devices").
##
## While ID is above 0, devices don't start their own guest: they sign in to
## the shared test account ID (game/online/backend.gd), so its cloud save,
## Ghost Arena trophies and league, friends, friend code and leaderboard
## entries are the same on every device. CI's migrate job makes the account
## and gives it a fresh random password on every deploy
## (tools/supabase_auth_config.mjs); the test_login RPC hands that password
## to the game, so it never sits in the repo.
##
## Anyone who opens the game while this is on plays as the same account. That
## account has exactly a normal player's rights, so it can't touch anyone
## else's data. When real sign-in is ready, set ID to 0: each device is its
## own guest again and real accounts work through the same code.
extends RefCounted

const ID := 1


## The test account this device should use, or 0 for its own guest.
## Automated browsers (the CI smoke test) keep their own guests so test runs
## never play as, or overwrite, the test account.
static func slot() -> int:
	if ID <= 0:
		return 0
	if OS.has_feature("web") and JavaScriptBridge.eval("navigator.webdriver === true", true) == true:
		return 0
	return ID
