extends "res://tests/test_case.gd"
## The Quick fight wait screen (game/ui/live_wait_scene.gd): the two critters
## run in, meet in the middle and bounce apart again.

const LiveWaitScene := preload("res://game/ui/live_wait_scene.gd")


func test_the_critters_meet_in_the_middle_and_bounce_apart() -> void:
	var s := LiveWaitScene.new()
	s.set_anchors_preset(Control.PRESET_TOP_LEFT)
	s.size = Vector2(700, 700)
	s.setup("laser", 3)
	var gap := func(): return s._foe.position.x - s._you.position.x
	s._place(0.0)
	var start: float = gap.call()
	s._place(LiveWaitScene.BONK_AT - 0.001)
	var met: float = gap.call()
	check(met < s._you.size.x * 0.7, "they touch at the bonk (gap %d)" % met)
	check(start > met * 3.0, "they start well apart")
	s._place(LiveWaitScene.BONK_AT + (1.0 - LiveWaitScene.BONK_AT) * 0.5)
	check(s._you.position.y < s._foe.position.y + 1.0 and gap.call() > met, "knocked back in an arc")
	s.free()
