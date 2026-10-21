## Friends v1: the friends list, requests, daily energy gifts, preset pings and
## rival records (supabase/migrations/*_friends.sql). Holds the last overview
## the server sent so screens can draw straight away, and emits `changed` when
## a call brings news. Offline (or no backend), every call is a no-op and
## `status` stays "offline".
##
## Chat is preset phrases only: a ping sends an index into PRESETS, never text.
extends RefCounted

const GhostLineup := preload("res://game/online/ghost_lineup.gd")
const MatchSim := preload("res://sim/match_sim.gd")

signal changed

## Never reorder or remove: the server stores indexes. Append new ones (max 16).
const PRESETS := ["GG!", "Nice shot!", "Rematch?", "Wow!", "So close!", "Good luck!", "Thanks!", "Haha!"]
const CODE_LENGTH := 8
const CODE_CHARS := "ABCDEFGHJKMNPQRSTUVWXYZ23456789"

var backend ## game/online/backend.gd, or null when there's no online play.
## offline, idle (never loaded), loading, ready, error (first load failed)
var status := "idle"
var me := {} ## {name, code}
var list: Array = [] ## Friend entries from friends_overview (see the migration).
var gifts_claimable := 0
var gift_energy := 2
## A friend code from an invite or challenge link, waiting for the player to
## add it: {code, name} (name once looked up).
var invite := {}
## ?demo=friends: show sample friends with no backend (screenshots, UI work).
var demo := false


func _init(backend_ = null) -> void:
	backend = backend_
	if not enabled():
		status = "offline"


func enabled() -> bool:
	return demo or (backend != null and backend.enabled())


## Fills in sample friends so the screen can be seen without a server.
func show_demo() -> void:
	demo = true
	apply_overview(demo_overview())


func friends() -> Array:
	return list.filter(func(f): return f.state == "friends")


func incoming() -> Array:
	return list.filter(func(f): return f.state == "incoming")


func outgoing() -> Array:
	return list.filter(func(f): return f.state == "outgoing")


## Things waiting on the player: requests to answer and gifts to claim.
func attention() -> int:
	return incoming().size() + gifts_claimable


func find(id: String) -> Dictionary:
	for f in list:
		if f.id == id:
			return f
	return {}


func is_friend_code(code: String) -> bool:
	var c := normalize_code(code)
	return list.any(func(f): return f.code == c)


# --- Server calls -----------------------------------------------------------

func refresh() -> bool:
	if not enabled() or demo:
		return false
	if status != "ready":
		status = "loading"
	var res: Dictionary = await backend.call_rpc("friends_overview", {})
	if not (res.ok and res.data is Dictionary):
		if status == "loading":
			status = "error"
		changed.emit()
		return false
	apply_overview(res.data)
	return true


func apply_overview(data: Dictionary) -> void:
	me = data.get("me", {}) if data.get("me") is Dictionary else {}
	list = data.get("friends", []) if data.get("friends") is Array else []
	gifts_claimable = int(data.get("gifts_claimable", 0))
	gift_energy = int(data.get("gift_energy", gift_energy))
	if not invite.is_empty() and (invite.code == str(me.get("code", "")) or is_friend_code(invite.code)):
		invite = {}
	status = "ready"
	changed.emit()


## Returns the server's {status, friend} (status: requested, friends, already,
## not_found, self, full) or {} when offline.
func add_by_code(code: String) -> Dictionary:
	if not enabled():
		return {}
	var res: Dictionary = await backend.call_rpc("add_friend", {"p_code": normalize_code(code)})
	if not (res.ok and res.data is Dictionary):
		return {}
	if normalize_code(code) == invite.get("code", ""):
		invite = {}
	await refresh()
	return res.data


## Looks up the name behind an invite code so the screen can say who it is.
func set_invite(code: String) -> void:
	var c := normalize_code(code)
	if not is_code(c):
		return
	invite = {"code": c}
	changed.emit()
	if not enabled():
		return
	var res: Dictionary = await backend.rest("GET", "/rest/v1/profiles?select=display_name&friend_code=eq." + c)
	if res.ok and res.data is Array and not res.data.is_empty() and invite.get("code", "") == c:
		invite.name = str(res.data[0].display_name)
		changed.emit()


func answer(id: String, accept: bool) -> void:
	await _call_then_refresh("answer_friend", {"p_friend": id, "p_accept": accept})


func remove(id: String) -> void:
	await _call_then_refresh("remove_friend", {"p_friend": id})


func send_gift(id: String) -> bool:
	if not enabled():
		return false
	var res: Dictionary = await backend.call_rpc("send_energy_gift", {"p_friend": id})
	var f := find(id)
	if res.ok and not f.is_empty():
		f.gift_sent = true
		changed.emit()
	return res.ok and res.data == true


## Claims waiting gifts. Returns the energy to add to the bar (0 if none).
func claim_gifts() -> int:
	if not enabled():
		return 0
	var res: Dictionary = await backend.call_rpc("claim_energy_gifts", {})
	if not (res.ok and res.data is Dictionary):
		return 0
	await refresh()
	return int(res.data.get("energy", 0))


func ping(id: String, preset: int) -> bool:
	if not enabled() or preset < 0 or preset >= PRESETS.size():
		return false
	var res: Dictionary = await backend.call_rpc("send_friend_ping", {"p_friend": id, "p_preset": preset})
	return res.ok and res.data == true


## Records a rival fight (winner from the sim: 0 you, 1 them, -1 draw) and
## returns the new {wins, losses, draws}, or {} offline.
func record_rival(id: String, winner: int) -> Dictionary:
	if not enabled():
		return {}
	var res: Dictionary = await backend.call_rpc("record_rival_fight", {"p_friend": id, "p_winner": winner})
	if not (res.ok and res.data is Dictionary):
		return {}
	var f := find(id)
	if not f.is_empty():
		f.record = res.data
		changed.emit()
	return res.data


func _call_then_refresh(rpc: String, args: Dictionary) -> void:
	if not enabled():
		return
	await backend.call_rpc(rpc, args)
	await refresh()


# --- Pure helpers (tested in tests/test_friends.gd) --------------------------

static func demo_overview() -> Dictionary:
	var lineup := {"v": 1, "rules": MatchSim.RULES_VERSION, "slots": [{"critter": "laser", "tier": 2, "level": 3, "gear": []}], "aim": [-30]}
	var none := {"wins": 0, "losses": 0, "draws": 0}
	return {
		"me": {"name": "Guest-AAAA", "code": "ABCDEFGH"},
		"gift_energy": 2,
		"gifts_claimable": 3,
		"friends": [
			{"id": "b", "name": "Mia", "code": "MMMMNNNN", "state": "incoming", "trophies": 0, "lineup": null,
				"gift_sent": false, "gift_waiting": false, "ping": null, "record": none},
			{"id": "c", "name": "Theo", "code": "TTTTHHHH", "state": "friends", "trophies": 40, "lineup": lineup,
				"gift_sent": true, "gift_waiting": true, "ping": {"preset": 1, "at": "2026-10-14T22:00:00.5+00:00"},
				"record": {"wins": 3, "losses": 1, "draws": 0}},
			{"id": "d", "name": "Ola", "code": "PPPPQQQQ", "state": "friends", "trophies": 0, "lineup": null,
				"gift_sent": false, "gift_waiting": false, "ping": null, "record": none},
			{"id": "e", "name": "Zed", "code": "ZZZZXXXX", "state": "outgoing", "trophies": 0, "lineup": null,
				"gift_sent": false, "gift_waiting": false, "ping": null, "record": none},
		],
	}


## "abcd-efgh " -> "ABCDEFGH". Anything that isn't a letter or digit is dropped.
static func normalize_code(text: String) -> String:
	var out := ""
	for ch in text.to_upper():
		if (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9"):
			out += ch
	return out


static func is_code(text: String) -> bool:
	var c := normalize_code(text)
	if c.length() != CODE_LENGTH:
		return false
	for ch in c:
		if not ch in CODE_CHARS:
			return false
	return true


## "ABCDEFGH" -> "ABCD-EFGH", easier to read out to a friend.
static func format_code(code: String) -> String:
	var c := normalize_code(code)
	return c.left(4) + "-" + c.substr(4) if c.length() == CODE_LENGTH else c


## The critter a friend's saved team leads with, or "" if there's nothing this
## client can fight (no team yet, or saved on different sim rules).
static func lead_critter(f: Dictionary) -> String:
	var lineup = f.get("lineup")
	if not GhostLineup.is_playable(lineup):
		return ""
	return str(lineup.slots[0].critter)


## Why a friend can't be rematched yet, or "" if they can.
static func rematch_blocker(f: Dictionary) -> String:
	if f.get("lineup") == null:
		return "No team saved yet"
	if lead_critter(f) == "":
		return "Team needs a game update"
	return ""


## "3W 1L" head-to-head line for the friends list ("" before the first rematch).
static func record_text(rec) -> String:
	if not rec is Dictionary or int(rec.get("wins", 0)) + int(rec.get("losses", 0)) + int(rec.get("draws", 0)) == 0:
		return ""
	var t := "%dW %dL" % [int(rec.wins), int(rec.losses)]
	if int(rec.get("draws", 0)) > 0:
		t += " %dD" % int(rec.draws)
	return t


## "Nice shot! · 5m ago" for the last preset a friend sent, or "".
static func ping_text(ping, now_unix: int) -> String:
	if not ping is Dictionary:
		return ""
	var i := int(ping.get("preset", -1))
	if i < 0 or i >= PRESETS.size():
		return ""
	return "\"%s\" · %s" % [PRESETS[i], ago(str(ping.get("at", "")), now_unix)]


## Postgres timestamps ("2026-10-14T22:30:00.123+00:00") as "just now", "5m
## ago", "3h ago" or "2d ago".
static func ago(timestamp: String, now_unix: int) -> String:
	if timestamp.length() < 19:
		return ""
	var t := Time.get_unix_time_from_datetime_string(timestamp.left(19))
	var s := maxi(0, now_unix - t)
	if s < 60:
		return "just now"
	if s < 3600:
		return "%dm ago" % (s / 60)
	if s < 86400:
		return "%dh ago" % (s / 3600)
	return "%dd ago" % (s / 86400)
