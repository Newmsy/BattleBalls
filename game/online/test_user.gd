## TEST MODE: every device plays as test user ID (Newms, 2026-10-15: "hardcode
## my user id as 1 so I can test on multiple devices").
##
## While ID is above 0, the save doesn't go to the signed-in account's row but
## to test save slot ID (public.test_saves, *_test_saves.sql), which every
## device shares, so progress follows Newms from phone to laptop. Each device
## still signs in as its own guest underneath for PvP, friends and analytics;
## nothing server-side reads the test slot, so it can't touch anyone else's
## save, trophies or PvP.
##
## Anyone who opens the game while this is on shares the same slot. That's
## fine while Newms is the only tester. When real sign-in is ready, set ID to
## 0: each account then syncs its own save through the same SaveGame code.
extends RefCounted

const ID := 1


## The slot this device should sync with, or 0 for its own account's save.
## Automated browsers (the CI smoke test) keep their own guest save so test
## runs never overwrite the shared slot.
static func slot() -> int:
	if ID <= 0:
		return 0
	if OS.has_feature("web") and JavaScriptBridge.eval("navigator.webdriver === true", true) == true:
		return 0
	return ID
