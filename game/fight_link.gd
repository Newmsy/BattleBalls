## Share links. The sim is deterministic, so a whole fight fits in a short
## URL code and the receiving browser re-simulates it; no server, no video.
##
## Replay:    ?r=1.<p1>.<p2>.<seed>.<a1>.<a2>  plays one exact fight.
## Challenge: ?c=1.<ball>.<seed>.<aim>         the challenger's ball and shot,
##            aimed from the player corner. The friend plays the player
##            corner, so the shot is mirrored onto the opponent corner.
##
## The leading "1" is the link format. Links outlive sim changes: after a
## balance change an old replay link replays under the new rules.
extends RefCounted

const BallDefs := preload("res://sim/ball_defs.gd")

const FORMAT := "1"
const HOME := "https://battleballs.vercel.app/"
const MAX_SEED := 999999999


static func replay_code(p1: String, p2: String, seed_value: int, a1: int, a2: int) -> String:
	return ".".join([FORMAT, p1, p2, str(seed_value), str(a1), str(a2)])


static func challenge_code(ball: String, seed_value: int, aim: int) -> String:
	return ".".join([FORMAT, ball, str(seed_value), str(aim)])


## Returns {p1, p2, seed, angles: [a1, a2]}, or {} if the code is not valid.
static func parse_replay(code: String) -> Dictionary:
	var f := code.strip_edges().split(".")
	if f.size() != 6 or f[0] != FORMAT:
		return {}
	if not (_is_ball(f[1]) and _is_ball(f[2]) and _is_seed(f[3]) and _is_angle(f[4]) and _is_angle(f[5])):
		return {}
	return {"p1": f[1], "p2": f[2], "seed": int(f[3]), "angles": [int(f[4]), int(f[5])]}


## Returns {ball, seed, aim}, or {} if the code is not valid.
static func parse_challenge(code: String) -> Dictionary:
	var f := code.strip_edges().split(".")
	if f.size() != 4 or f[0] != FORMAT:
		return {}
	if not (_is_ball(f[1]) and _is_seed(f[2]) and _is_angle(f[3])):
		return {}
	return {"ball": f[1], "seed": int(f[2]), "aim": int(f[3])}


## The start corners are mirror images through the centre, so turning a shot
## half way round makes the same shot from the other corner.
static func mirror_angle(aim: int) -> int:
	return posmod(aim + 3600, 3600) - 1800


static func url(base: String, kind: String, code: String) -> String:
	return "%s?%s=%s" % [base, kind, code]


static func _is_ball(id: String) -> bool:
	return id in BallDefs.PLAYABLE


static func _is_seed(s: String) -> bool:
	return s.is_valid_int() and int(s) >= 0 and int(s) <= MAX_SEED


static func _is_angle(s: String) -> bool:
	return s.is_valid_int() and absi(int(s)) <= 3600
