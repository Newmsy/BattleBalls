## The mini Critterpedia card: it opens from a tapped critter, builds for
## every critter and tier, and a tap inside a button
## stays the button's (a long press opens the card there).
extends "res://tests/test_case.gd"

const Roster := preload("res://game/ui/roster.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const CritterPopup := preload("res://game/ui/critter_popup.gd")


func _tap(icon: Control) -> void:
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		icon._gui_input(e)


func test_every_card_builds() -> void:
	# Ability lines are kept short by CritterDb.validate, so the card fits a
	# phone (checked in the browser; Godot can't measure wrapped text off screen).
	for c in Roster.CRITTERS:
		for tier in [1, 5]:
			var popup = CritterPopup.new()
			popup.build(c.id, tier, 12, 1500, null, 680.0)
			check(popup.card != null, "%s T%d card builds" % [c.id, tier])
			popup.free()


func test_tapping_a_critter_opens_its_card_but_not_inside_a_button() -> void:
	var host := Control.new()
	var icon := CritterIcon.make("frost", 3, 80)
	host.add_child(icon)
	CritterPopup.last_asked = ""
	_tap(icon)
	check_eq(CritterPopup.last_asked, "frost", "a tap on a lone critter opens its card")
	var button := Button.new()
	host.add_child(button)
	var inner := CritterIcon.make("frost", 3, 80)
	button.add_child(inner)
	CritterPopup.last_asked = ""
	_tap(inner)
	check_eq(CritterPopup.last_asked, "", "a tap in a button stays the button's")
	var shadow := CritterIcon.make("frost", 1, 80, false, true)
	host.add_child(shadow)
	_tap(shadow)
	check_eq(CritterPopup.last_asked, "", "a silhouette (not found yet) keeps its secret")
	host.free()
