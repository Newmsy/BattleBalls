## Touch layer: which control a press lands on (so a drag can scroll the area
## around it) and what a left-edge swipe means on each screen.
extends "res://tests/test_case.gd"

const TouchInput := preload("res://game/ui/touch_input.gd")
const Shell := preload("res://game/ui/shell.gd")


func _rect(c: Control, pos: Vector2, size: Vector2) -> Control:
	c.position = pos
	c.size = size
	return c


func test_a_press_on_a_button_is_found_inside_its_scroll_area() -> void:
	var root := Node.new()
	var low := CanvasLayer.new()
	root.add_child(low)
	var scroll: ScrollContainer = _rect(ScrollContainer.new(), Vector2.ZERO, Vector2(400, 400))
	low.add_child(scroll)
	var list: Control = _rect(Control.new(), Vector2.ZERO, Vector2(400, 1000))
	list.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(list)
	var button: Button = _rect(Button.new(), Vector2(20, 100), Vector2(200, 80))
	list.add_child(button)
	var label: Label = _rect(Label.new(), Vector2(20, 100), Vector2(200, 80))
	button.add_child(label) # Labels are click-through (MOUSE_FILTER_IGNORE).
	var hit := TouchInput.find_control(root, Vector2(50, 130))
	check_eq(hit, button, "the button, not its label")
	check(scroll.is_ancestor_of(hit), "inside the scroll area")
	check_eq(TouchInput.find_control(root, Vector2(300, 300)), list, "between buttons: the list")
	# A higher, visible layer covers it; a hidden one doesn't.
	var high := CanvasLayer.new()
	high.layer = 5
	root.add_child(high)
	var cover: Panel = _rect(Panel.new(), Vector2.ZERO, Vector2(400, 400))
	high.add_child(cover)
	check_eq(TouchInput.find_control(root, Vector2(50, 130)), cover, "covered by the top layer")
	high.visible = false
	check_eq(TouchInput.find_control(root, Vector2(50, 130)), button, "hidden layers don't count")
	# Scrolled out of a clipping parent: not hittable there.
	scroll.clip_contents = true
	check_eq(TouchInput.find_control(root, Vector2(50, 600)), null, "outside the clipped area")
	root.free()


func test_back_sources_newest_first_and_empty_means_nothing() -> void:
	var a := RefCounted.new()
	var b := RefCounted.new()
	var hits := []
	TouchInput.set_back(a, func(): return func(): hits.append("a"))
	TouchInput.set_back(b, func(): return Callable())
	TouchInput.back_action().call()
	check_eq(hits, ["a"], "b has nothing, so a's back runs")
	TouchInput.set_back(b, func(): return func(): hits.append("b"))
	TouchInput.back_action().call()
	check_eq(hits, ["a", "b"], "the newest source wins")
	TouchInput.clear_back(a)
	TouchInput.clear_back(b)
	check(not TouchInput.back_action().is_valid(), "nothing registered")


func test_swiping_back_through_the_shell() -> void:
	var shell = Shell.new()
	shell.build()
	runner.root.add_child(shell) # Sheets slide in with a tween.
	shell.show_tab("critters")
	check(not shell.back_action().is_valid(), "a tab's own screen has no back")
	shell.go("detail", {"id": "vampire"})
	var back: Callable = shell.back_action()
	check(back.is_valid(), "detail goes back")
	back.call()
	check_eq(shell.current, "critters", "back on the critter list")
	shell.sheet(Label.new())
	check(shell.overlay_open(), "sheet open")
	shell.back_action().call()
	check(not shell.overlay_open(), "back closes the sheet")
	shell.overlay(Control.new(), "reveal")
	check(not shell.back_action().is_valid(), "a summon reveal isn't swiped away")
	shell.free()


func test_where_nothing_says_the_swipe_presses_the_back_on_screen() -> void:
	var root := Node.new()
	var page: Control = _rect(Control.new(), Vector2.ZERO, Vector2(400, 800))
	root.add_child(page)
	check_eq(TouchInput.back_button_on_screen(root), null, "no Back on screen")
	var back: Button = _rect(Button.new(), Vector2(20, 700), Vector2(160, 80))
	back.text = "Back"
	page.add_child(back)
	var go: Button = _rect(Button.new(), Vector2(200, 700), Vector2(160, 80))
	go.text = "LAUNCH"
	page.add_child(go)
	check_eq(TouchInput.back_button_on_screen(root), back, "a button reading BACK counts")
	back.disabled = true
	check_eq(TouchInput.back_button_on_screen(root), null, "not while disabled")
	back.disabled = false
	var home: Button = _rect(Button.new(), Vector2(20, 600), Vector2(160, 80))
	home.text = "HOME"
	page.add_child(home)
	back.visible = false
	check_eq(TouchInput.back_button_on_screen(root), null, "HOME isn't a Back unless marked")
	TouchInput.mark_back(home)
	check_eq(TouchInput.back_button_on_screen(root), home, "marked")
	back.visible = true
	# A popup over the page: its Close wins and the page's Backs are covered.
	var layer := CanvasLayer.new()
	layer.layer = 5
	root.add_child(layer)
	var dim: Button = _rect(Button.new(), Vector2.ZERO, Vector2(400, 800))
	layer.add_child(dim)
	check_eq(TouchInput.back_button_on_screen(root), null, "covered by the popup")
	var close: Button = _rect(Button.new(), Vector2(100, 300), Vector2(200, 80))
	close.text = "Close"
	layer.add_child(close)
	check_eq(TouchInput.back_button_on_screen(root), close, "the popup's Close")
	layer.visible = false
	check(TouchInput.back_button_on_screen(root) in [back, home], "popup gone: the page's Back again")
	root.free()
