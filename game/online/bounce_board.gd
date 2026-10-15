## Bounce Run's daily leaderboard client. Posts a finished ranked run once and
## reads the day's board, through the Supabase client in backend.gd and the
## RPCs in supabase/migrations/*_bounce_run.sql.
##
## Offline-first: with no backend (no config, no network, or a build without
## game/online/backend.gd) every call returns not-ok and the run plays on.
extends Node

const BounceRun := preload("res://sim/bounce_run.gd")
const BACKEND_PATH := "res://game/online/backend.gd"
const BOARD_SIZE := 20

var backend: Node


func _ready() -> void:
	if ResourceLoader.exists(BACKEND_PATH):
		backend = load(BACKEND_PATH).new()
		add_child(backend)


func available() -> bool:
	return backend != null and backend.enabled()


## Posts a finished run. True once the server has it (a repeat post of the
## same day is a no-op there, so retries are safe).
func submit(run: Dictionary) -> bool:
	if not available():
		return false
	var s := BounceRun.score(run)
	var res: Dictionary = await backend.call_rpc("submit_bounce_run", {
		"p_day": run.day, "p_floors": s.floors, "p_lives": s.lives, "p_ticks": s.ticks,
		"p_log": {"picks": run.picks, "boons": run.boons, "fights": run.log}, "p_rules": BounceRun.RULES_VERSION,
	})
	print("BOUNCERUN_POST day=%d ok=%s" % [run.day, res.ok])
	return res.ok


## The day's top BOARD_SIZE plus your own row: {ok, rows: [{rank,
## display_name, floors, lives, ticks, is_me}]}.
func fetch(day: int) -> Dictionary:
	if not available():
		return {"ok": false, "rows": []}
	var res: Dictionary = await backend.call_rpc("bounce_run_board", {"p_day": day, "p_limit": BOARD_SIZE})
	var rows: Array = res.data if res.ok and res.data is Array else []
	return {"ok": res.ok, "rows": rows}
